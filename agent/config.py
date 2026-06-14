"""Agent 配置"""

import os
from dotenv import load_dotenv

load_dotenv()

# HTTP Server
HOST = os.getenv("AGENT_HOST", "0.0.0.0")
PORT = int(os.getenv("AGENT_PORT", "8000"))

# gRPC Server
GRPC_HOST = os.getenv("GRPC_HOST", "0.0.0.0")
GRPC_PORT = int(os.getenv("GRPC_PORT", "50051"))

# 会话历史配置
MAX_HISTORY_TURNS = int(os.getenv("MAX_HISTORY_TURNS", "10"))  # 保留最近 N 轮对话

# LLM 配置
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_BASE_URL = os.getenv("OPENAI_BASE_URL", "")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

# 本地模型（降级方案）
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3")

# 默认使用云端，不可用时降级到本地
PREFER_CLOUD = os.getenv("PREFER_CLOUD", "true").lower() == "true"

# 生产部署鉴权
# 设置后 HMI 请求需在 Header 中携带 X-API-Key: {API_AUTH_KEY}
API_AUTH_KEY = os.getenv("API_AUTH_KEY", "")
