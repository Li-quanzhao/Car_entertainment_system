"""Car Agent gRPC Server

提供与 FastAPI HTTP Server 等价的 gRPC 服务，运行在独立端口 :50051。
可单独启动或与 HTTP Server 并行运行。
"""

import json
import logging
import os
import sys
import time
from collections import OrderedDict
from concurrent import futures
from typing import Optional

import grpc
try:
    from grpc_reflection.v1alpha import reflection
    _HAS_REFLECTION = True
except Exception:
    _HAS_REFLECTION = False

# ── Agent 模块导入 ────────────────────────────────────────────
_agent_dir = os.path.dirname(os.path.abspath(__file__))
if _agent_dir not in sys.path:
    sys.path.insert(0, _agent_dir)
from llm_agent.agent import car_agent
from llm_agent.tools import execute_tool, ALL_TOOLS
from config import HOST, GRPC_PORT

# ── gRPC 生成代码导入 ──────────────────────────────────────────
_proto_dir = os.path.join(_agent_dir, "proto")
if _proto_dir not in sys.path:
    sys.path.insert(0, _proto_dir)

import car_assistant_pb2 as pb2
import car_assistant_pb2_grpc as pb2_grpc


# ═══════════════════════════════════════════════════════════════
# 结构化日志
# ═══════════════════════════════════════════════════════════════

class StructuredFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        log = OrderedDict()
        log["ts"] = self.formatTime(record, "%Y-%m-%d %H:%M:%S")
        log["level"] = record.levelname
        log["logger"] = record.name
        log["msg"] = record.getMessage()
        if hasattr(record, "extra"):
            log.update(record.extra)
        return json.dumps(log, ensure_ascii=False)

_handler = logging.StreamHandler(sys.stdout)
_handler.setFormatter(StructuredFormatter())
logging.basicConfig(level=logging.INFO, handlers=[_handler])
logger = logging.getLogger("agent.grpc")


# ═══════════════════════════════════════════════════════════════
# gRPC Servicer
# ═══════════════════════════════════════════════════════════════

class CarAssistantServicer(pb2_grpc.CarAssistantServicer):
    """实现 proto 定义的 CarAssistant 服务"""

    # ── 健康检查 ──────────────────────────────────────────────
    def GetHealth(self, request, context):
        try:
            llm_available = bool(car_agent._graph is not None) if hasattr(car_agent, "_graph") else False
            tools_count = len(ALL_TOOLS)
            return pb2.HealthResponse(
                status="ok",
                llm_available=llm_available,
                tools_count=tools_count,
                version="1.0.0",
            )
        except Exception as e:
            logger.error("health_error", extra={"extra": {"error": str(e)}})
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return pb2.HealthResponse()

    # ── 单次对话 ──────────────────────────────────────────────
    def ChatQuery(self, request, context):
        session_id = request.session_id or "default"
        message = request.message

        logger.info("chat_request", extra={"extra": {
            "session_id": session_id, "message_len": len(message),
        }})

        t0 = time.monotonic()
        try:
            reply = car_agent.chat(session_id, message)
            elapsed = time.monotonic() - t0
            logger.info("chat_ok", extra={"extra": {
                "session_id": session_id, "latency_s": round(elapsed, 3), "reply_len": len(reply),
            }})
            return pb2.ChatResponse(reply=reply, session_id=session_id)
        except Exception as e:
            logger.error("chat_error", extra={"extra": {"session_id": session_id, "error": str(e)}})
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return pb2.ChatResponse(reply="", session_id=session_id, error=str(e))

    # ── 流式对话（gRPC Server-Side Streaming）────────────────
    def StreamChat(self, request, context):
        session_id = request.session_id or "default"
        message = request.message

        logger.info("stream_request", extra={"extra": {
            "session_id": session_id, "message_len": len(message),
        }})

        t0 = time.monotonic()
        try:
            full_reply = car_agent.chat(session_id, message)
        except Exception as e:
            logger.error("stream_error", extra={"extra": {"session_id": session_id, "error": str(e)}})
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return

        # 模拟逐字推送
        import re
        chunks = re.split(r'([，。！？、；：\n])', full_reply)
        buffer = ""
        for chunk in chunks:
            if not chunk:
                continue
            buffer += chunk
            yield pb2.ChatResponse(reply=chunk, session_id=session_id, is_streaming=True)
            time.sleep(0.02)  # 模拟流式延迟

        elapsed = time.monotonic() - t0
        logger.info("stream_ok", extra={"extra": {
            "session_id": session_id, "latency_s": round(elapsed, 3), "reply_len": len(full_reply),
        }})
        yield pb2.ChatResponse(reply="", session_id=session_id, is_streaming=False)

    # ── 工具执行 ──────────────────────────────────────────────
    def ExecuteTool(self, request, context):
        tool_name = request.tool_name
        parameters = dict(request.parameters)

        logger.info("tool_request", extra={"extra": {"tool": tool_name, "params": parameters}})

        t0 = time.monotonic()
        try:
            result = execute_tool(tool_name, parameters)
            elapsed = time.monotonic() - t0
            logger.info("tool_ok", extra={"extra": {
                "tool": tool_name, "latency_s": round(elapsed, 3),
            }})
            data_json = json.dumps(result.get("data", {}), ensure_ascii=False)
            return pb2.ToolResponse(
                success=result.get("success", False),
                data=data_json,
            )
        except Exception as e:
            logger.error("tool_error", extra={"extra": {"tool": tool_name, "error": str(e)}})
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return pb2.ToolResponse(success=False, error=str(e))


# ═══════════════════════════════════════════════════════════════
# 启动
# ═══════════════════════════════════════════════════════════════

def serve(host: str = "0.0.0.0", port: int = 50051):
    server = grpc.server(
        futures.ThreadPoolExecutor(max_workers=10),
        maximum_concurrent_rpcs=100,
    )

    pb2_grpc.add_CarAssistantServicer_to_server(CarAssistantServicer(), server)

    # 启用 gRPC 反射（便于调试工具如 grpcurl）
    if _HAS_REFLECTION:
        SERVICE_NAMES = (
            'car_assistant.CarAssistant',
            reflection.SERVICE_NAME,
        )
        reflection.enable_server_reflection(SERVICE_NAMES, server)
    else:
        logger.warning("gRPC reflection disabled (protobuf version mismatch)")

    server.add_insecure_port(f"{host}:{port}")
    logger.info("grpc_server_started", extra={"extra": {"host": host, "port": port}})

    server.start()
    server.wait_for_termination()


def main():
    host = os.getenv("GRPC_HOST", "0.0.0.0")
    port = int(os.getenv("GRPC_PORT", "50051"))
    logger.info("grpc_server_booting", extra={"extra": {"host": host, "port": port}})
    serve(host, port)


if __name__ == "__main__":
    main()
