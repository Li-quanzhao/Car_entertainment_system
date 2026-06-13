"""LLM Agent 核心 - 对话管理与路由

使用 LangChain 1.3.9+ 的 create_agent API (LangGraph based)。
无 API Key 时自动降级到模拟回复模式。
"""

import logging

from langchain.agents import create_agent
from langchain_core.messages import HumanMessage, AIMessage

from .session import session_store
from .tools import ALL_TOOLS
from .chain import SYSTEM_PROMPT
from .config import (
    OPENAI_API_KEY,
    OPENAI_BASE_URL,
    OPENAI_MODEL,
    OLLAMA_BASE_URL,
    OLLAMA_MODEL,
    PREFER_CLOUD,
    MAX_HISTORY_TURNS,
)

logger = logging.getLogger(__name__)


class CarAgent:
    """车载 AI Agent"""

    def __init__(self):
        self._use_mock = False
        self._graph = None

        # 尝试创建真实 LLM Agent
        llm = self._create_llm()
        if llm is not None:
            try:
                self._graph = create_agent(
                    model=llm,
                    tools=ALL_TOOLS,
                    system_prompt=SYSTEM_PROMPT,
                    debug=False,
                )
                logger.info("LLM Agent 初始化成功")
            except Exception as e:
                logger.warning(f"create_agent 失败: {e}，使用模拟模式")
                self._use_mock = True
        else:
            self._use_mock = True

        if self._use_mock:
            logger.info("使用模拟 LLM 模式（无 API Key 或 LLM 不可用）")

    def _create_llm(self):
        """创建 LLM 实例，云端优先"""
        if PREFER_CLOUD and OPENAI_API_KEY:
            try:
                from langchain_openai import ChatOpenAI
                kwargs = dict(
                    model=OPENAI_MODEL,
                    api_key=OPENAI_API_KEY,
                    temperature=0.7,
                    max_tokens=1024,
                )
                if OPENAI_BASE_URL:
                    kwargs["base_url"] = OPENAI_BASE_URL
                return ChatOpenAI(**kwargs)
            except Exception as e:
                logger.warning(f"OpenAI 初始化失败: {e}")

        # 降级到本地 Ollama
        if OLLAMA_BASE_URL:
            try:
                from langchain_ollama import ChatOllama
                return ChatOllama(
                    model=OLLAMA_MODEL,
                    base_url=OLLAMA_BASE_URL,
                    temperature=0.7,
                )
            except ImportError:
                logger.warning("langchain-ollama 未安装")
            except Exception as e:
                logger.warning(f"Ollama 初始化失败: {e}")

        return None

    def chat(self, session_id: str, message: str) -> str:
        """处理用户消息，返回 AI 回复"""
        # 保存用户消息
        session_store.add_user_message(session_id, message)

        try:
            if self._use_mock or self._graph is None:
                reply = self._mock_reply(message)
            else:
                # 获取历史消息（按轮次裁剪）
                history = session_store.get_history(session_id, MAX_HISTORY_TURNS)
                # invoke 需要 messages 列表
                result = self._graph.invoke({
                    "messages": list(history),
                })
                # 结果中提取最后一个 AI 消息
                reply = self._extract_reply(result)
        except Exception as e:
            logger.error(f"Agent 执行错误: {e}", exc_info=True)
            reply = f"抱歉，我遇到了一些问题: {str(e)}"

        # 保存 AI 回复
        session_store.add_ai_message(session_id, reply)
        return reply

    def _extract_reply(self, result: dict) -> str:
        """从 Agent 结果中提取 AI 回复文本"""
        messages = result.get("messages", [])
        if not messages:
            return "抱歉，我没有得到有效回复。"

        # 取最后一条 AI 消息
        for msg in reversed(messages):
            if isinstance(msg, AIMessage):
                return msg.content or ""
        return str(messages[-1]) if messages else ""

    def _mock_reply(self, message: str) -> str:
        """模拟回复 - 无 API Key 时的降级方案"""
        if "导航" in message or "去" in message:
            return "已为您规划导航路线，请在导航页面查看详情。"
        elif "音乐" in message or "歌" in message or "播放" in message:
            return "好的，正在为您播放音乐。您可以在音乐页面控制播放。"
        elif "温度" in message or "空调" in message or "热" in message or "冷" in message:
            return "已调节空调温度到合适的设置。"
        elif "油" in message or "续航" in message:
            return "当前油量 72%，续航约 480 公里，建议在油量低于 15% 时加油。"
        elif "你好" in message or "hi" in message.lower() or "hello" in message.lower():
            return "你好！我是你的车载 AI 助手，可以帮你导航、播放音乐、查询车辆信息等，有什么需要吗？"
        else:
            return f"收到您的消息：'{message}'。我是车载 AI 助手，可以帮您导航、播放音乐、查询车辆信息或调节空调等。请尝试告诉我具体需求。"


# 全局单例
car_agent = CarAgent()
