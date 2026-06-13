"""会话管理 - 维护多轮对话上下文

使用内存 dict 存储会话历史，提供 CRUD 操作。
生产环境可替换为 Redis/数据库 存储。
"""

from typing import Optional
from datetime import datetime
from langchain_core.messages import HumanMessage, AIMessage, BaseMessage


class SessionStore:
    """简单的内存会话存储"""

    def __init__(self):
        self._sessions: dict[str, list[BaseMessage]] = {}
        self._metas: dict[str, dict] = {}

    def create_session(self, session_id: Optional[str] = None) -> str:
        """创建新会话，返回 session_id"""
        if session_id is None:
            import uuid
            session_id = str(uuid.uuid4())[:8]
        self._sessions[session_id] = []
        self._metas[session_id] = {
            "created_at": datetime.now().isoformat(),
            "message_count": 0,
        }
        return session_id

    def get_history(self, session_id: str, max_turns: int = 0) -> list[BaseMessage]:
        """获取会话历史，可选只返回最近 N 轮对话（N=0 返回全部）"""
        history = self._sessions.get(session_id, [])
        if max_turns > 0 and len(history) > max_turns * 2:
            return history[-(max_turns * 2):]
        return history

    def add_message(self, session_id: str, msg: BaseMessage):
        """添加消息到会话"""
        if session_id not in self._sessions:
            self.create_session(session_id)
        self._sessions[session_id].append(msg)
        if session_id in self._metas:
            self._metas[session_id]["message_count"] = len(self._sessions[session_id])

    def add_user_message(self, session_id: str, content: str):
        """添加用户消息"""
        self.add_message(session_id, HumanMessage(content=content))

    def add_ai_message(self, session_id: str, content: str):
        """添加 AI 回复"""
        self.add_message(session_id, AIMessage(content=content))

    def clear_session(self, session_id: str):
        """清空会话"""
        if session_id in self._sessions:
            self._sessions[session_id] = []

    def delete_session(self, session_id: str):
        """删除会话"""
        self._sessions.pop(session_id, None)
        self._metas.pop(session_id, None)

    def get_session_list(self) -> list[dict]:
        """获取所有会话元信息列表"""
        return [
            {"session_id": sid, **meta}
            for sid, meta in self._metas.items()
        ]


# 全局单例
session_store = SessionStore()
