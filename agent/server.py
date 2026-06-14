"""Car Agent HTTP Server

FastAPI 服务，提供对话、流式响应、工具执行等 API。
支持限流、缓存和结构化日志。
"""

import asyncio
import json
import logging
import os
import sys
import time
from collections import OrderedDict
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from threading import Lock
from typing import Optional

# ── 系统包路径（解决 .venv 隔离问题）────────────────────────────
sys.path.insert(0, "E:\\Anoconda\\Lib\\site-packages")

import uvicorn
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, Field

# ── Agent 模块导入 ────────────────────────────────────────────
import os as _os
_agent_dir = _os.path.dirname(_os.path.abspath(__file__))
if _agent_dir not in sys.path:
    sys.path.insert(0, _agent_dir)
from llm_agent.agent import car_agent
from llm_agent.session import session_store
from llm_agent.tools import execute_tool
from config import HOST, PORT, API_AUTH_KEY


# ═══════════════════════════════════════════════════════════════
# 结构化日志
# ═══════════════════════════════════════════════════════════════

class StructuredFormatter(logging.Formatter):
    """JSON 结构化日志格式"""
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
logger = logging.getLogger("agent")


# ═══════════════════════════════════════════════════════════════
# 限流器（滑动窗口）
# ═══════════════════════════════════════════════════════════════

@dataclass
class RateLimiter:
    max_requests: int = 10       # 窗口内最大请求数
    window_seconds: float = 1.0  # 窗口大小（秒）
    _requests: dict = field(default_factory=dict)
    _lock: Lock = field(default_factory=Lock)

    def is_allowed(self, key: str = "default") -> bool:
        now = time.monotonic()
        with self._lock:
            timestamps = self._requests.get(key, [])
            # 清除窗口外的记录
            cutoff = now - self.window_seconds
            timestamps = [t for t in timestamps if t > cutoff]
            if len(timestamps) >= self.max_requests:
                self._requests[key] = timestamps
                return False
            timestamps.append(now)
            self._requests[key] = timestamps
            return True

rate_limiter = RateLimiter()


# ═══════════════════════════════════════════════════════════════
# 响应缓存（TTL）
# ═══════════════════════════════════════════════════════════════

@dataclass
class ResponseCache:
    ttl_seconds: float = 30.0  # 缓存有效期
    _store: dict = field(default_factory=dict)
    _lock: Lock = field(default_factory=Lock)

    def get(self, key: str) -> Optional[str]:
        now = time.monotonic()
        with self._lock:
            entry = self._store.get(key)
            if entry is None:
                return None
            if now - entry["ts"] > self.ttl_seconds:
                del self._store[key]
                return None
            return entry["reply"]

    def set(self, key: str, reply: str) -> None:
        with self._lock:
            self._store[key] = {"reply": reply, "ts": time.monotonic()}

    def clear(self) -> None:
        with self._lock:
            self._store.clear()

response_cache = ResponseCache()


# ═══════════════════════════════════════════════════════════════
# 请求模型
# ═══════════════════════════════════════════════════════════════

class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000, description="用户消息")
    session_id: str = Field(default="default", max_length=64)

class ChatResponse(BaseModel):
    reply: str
    session_id: str

class CommandRequest(BaseModel):
    tool: str = Field(..., description="工具名称")
    args: dict = Field(default_factory=dict, description="工具参数")
    session_id: str = Field(default="default", max_length=64)


# ═══════════════════════════════════════════════════════════════
# FastAPI 应用
# ═══════════════════════════════════════════════════════════════

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("agent_server_started", extra={"extra": {"host": HOST, "port": PORT}})
    yield
    logger.info("agent_server_stopped")

app = FastAPI(title="Car Agent", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── 限流中间件 ────────────────────────────────────────────────

@app.middleware("http")
async def auth_and_rate_limit_middleware(request: Request, call_next):
    # 健康检查不需要鉴权和限流
    if request.url.path == "/api/health":
        return await call_next(request)

    # API 鉴权（若已配置）
    if API_AUTH_KEY:
        client_key = request.headers.get("X-API-Key", "")
        if client_key != API_AUTH_KEY:
            logger.warning("auth_failed", extra={"extra": {"path": request.url.path, "client_ip": request.client.host if request.client else "unknown"}})
            return JSONResponse(
                status_code=401,
                content={"error": "Unauthorized: invalid or missing X-API-Key"},
            )

    # 限流
    if request.url.path in ("/api/chat", "/api/chat/stream", "/api/command"):
        client_ip = request.client.host if request.client else "unknown"
        if not rate_limiter.is_allowed(client_ip):
            logger.warning("rate_limit_exceeded", extra={"extra": {"client_ip": client_ip, "path": request.url.path}})
            return JSONResponse(
                status_code=429,
                content={"error": "请求过于频繁，请稍后再试", "retry_after_seconds": 1.0},
            )
    return await call_next(request)


# ── 健康检查 ──────────────────────────────────────────────────

@app.get("/api/health")
async def health_check():
    from llm_agent.tools import ALL_TOOLS
    from config import OPENAI_API_KEY
    status = {
        "status": "ok",
        "llm_available": bool(car_agent._graph is not None),
        "use_mock": car_agent._use_mock if hasattr(car_agent, "_use_mock") else True,
        "tools_count": len(ALL_TOOLS),
        "tools": [t.name for t in ALL_TOOLS],
    }
    return status


# ── 对话 API ──────────────────────────────────────────────────

@app.post("/api/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    _log_req("chat", req)

    # 尝试命中缓存
    cache_key = f"{req.session_id}:{req.message.strip()}"
    cached = response_cache.get(cache_key)
    if cached:
        logger.info("chat_cache_hit", extra={"extra": {"session_id": req.session_id}})
        return ChatResponse(reply=cached, session_id=req.session_id)

    t0 = time.monotonic()
    try:
        reply = car_agent.chat(req.session_id, req.message)
    except Exception as e:
        logger.error("chat_error", extra={"extra": {"session_id": req.session_id, "error": str(e)}})
        raise HTTPException(status_code=500, detail=str(e))

    elapsed = time.monotonic() - t0
    response_cache.set(cache_key, reply)

    logger.info("chat_ok", extra={"extra": {
        "session_id": req.session_id, "latency_s": round(elapsed, 3), "reply_len": len(reply),
    }})
    return ChatResponse(reply=reply, session_id=req.session_id)


# ── 流式对话 API ──────────────────────────────────────────────

@app.post("/api/chat/stream")
async def chat_stream(req: ChatRequest):
    _log_req("chat_stream", req)

    async def event_generator():
        t0 = time.monotonic()
        try:
            full_reply = car_agent.chat(req.session_id, req.message)
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)}, ensure_ascii=False)}\n\n"
            return

        # 模拟逐字推送（每个标点或空格分段）
        import re
        chunks = re.split(r'([，。！？、；：\n])', full_reply)
        buffer = ""
        for chunk in chunks:
            if not chunk:
                continue
            buffer += chunk
            yield f"data: {json.dumps({'text': chunk}, ensure_ascii=False)}\n\n"
            await asyncio.sleep(0.02)  # 模拟流式延迟

        elapsed = time.monotonic() - t0
        logger.info("chat_stream_ok", extra={"extra": {
            "session_id": req.session_id, "latency_s": round(elapsed, 3), "reply_len": len(full_reply),
        }})
        yield f"data: {json.dumps({'done': True}, ensure_ascii=False)}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


# ── 工具执行 API ─────────────────────────────────────────────

@app.post("/api/command")
async def execute_command(req: CommandRequest):
    _log_req("command", req)
    t0 = time.monotonic()

    try:
        result = execute_tool(req.tool, req.args)
    except Exception as e:
        logger.error("command_error", extra={"extra": {"tool": req.tool, "error": str(e)}})
        raise HTTPException(status_code=500, detail=str(e))

    elapsed = time.monotonic() - t0
    logger.info("command_ok", extra={"extra": {
        "tool": req.tool, "latency_s": round(elapsed, 3),
    }})
    return {"success": result.get("success", False), "data": result.get("data"), "message": result.get("message")}


# ── 辅助函数 ──────────────────────────────────────────────────

def _log_req(endpoint: str, req):
    logger.info(f"{endpoint}_request", extra={"extra": {
        "session_id": req.session_id,
        "message_len": len(getattr(req, "message", "")),
    }})


# ═══════════════════════════════════════════════════════════════
# 入口 — HTTP + gRPC 双协议并行运行
# ═══════════════════════════════════════════════════════════════

def _start_grpc_server():
    """在后台线程启动 gRPC 服务器"""
    import threading
    from config import GRPC_HOST, GRPC_PORT

    def _run():
        import grpc_server
        grpc_server.serve(GRPC_HOST, GRPC_PORT)

    thread = threading.Thread(target=_run, name="grpc-server", daemon=True)
    thread.start()
    logger.info("grpc_server_starting", extra={"extra": {"host": GRPC_HOST, "port": GRPC_PORT}})
    return thread


if __name__ == "__main__":
    # 尝试启动 gRPC 服务器（失败不影响 HTTP 服务）
    try:
        _start_grpc_server()
    except Exception as e:
        logger.warning("grpc_server_failed", extra={"extra": {"error": str(e)}})

    uvicorn.run(app, host=HOST, port=PORT)
