"""Agent 工具函数定义 - 车载场景

所有工具返回 JSON-serializable 的 dict:
    {"success": bool, "data": any, "message": str}

Mock 数据从 mock_data.json 加载，支持随机化。
"""

import json
import os
import random
from typing import Optional, Type
from pydantic import BaseModel, Field
from langchain_core.tools import BaseTool


# ============================================================
# Mock 数据加载
# ============================================================

_MOCK_DATA_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "mock_data.json",
)


def _load_mock_data() -> dict:
    """加载 mock 数据配置"""
    try:
        with open(_MOCK_DATA_PATH, encoding="utf-8") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        # 兜底返回默认数据
        return {"_comment": f"加载失败: {e}"}


def _rand_value(cfg: dict) -> int | float:
    """根据配置生成随机值"""
    if cfg.get("randomize", False):
        return round(random.uniform(cfg["min"], cfg["max"]), 1)
    return cfg["default"]


# ============================================================
# 参数 Schema
# ============================================================

class NavigateToSchema(BaseModel):
    destination: str = Field(description="导航目的地名称")
    lat: float = Field(description="纬度")
    lon: float = Field(description="经度")

class SearchPoiSchema(BaseModel):
    query: str = Field(description="搜索关键词")
    category: Optional[str] = Field(default=None, description="类别过滤")

class SetTemperatureSchema(BaseModel):
    temp: int = Field(description="目标温度 (16-32)")

class PlayMusicSchema(BaseModel):
    song: Optional[str] = Field(default=None, description="歌曲名称")
    artist: Optional[str] = Field(default=None, description="歌手名称")

class ControlMediaSchema(BaseModel):
    action: str = Field(description="控制动作: play/pause/next/prev")

# ============================================================
# 工具函数
# ============================================================

def _get_mock_data() -> dict:
    """获取 mock 配置（惰性加载）"""
    if not hasattr(_get_mock_data, "_cache"):
        _get_mock_data._cache = _load_mock_data()
    return _get_mock_data._cache


def _get_vehicle_speed() -> dict:
    """获取当前车速"""
    cfg = _get_mock_data().get("vehicle_speed", {})
    speed = _rand_value(cfg)
    unit = cfg.get("unit", "km/h")
    return {
        "success": True,
        "data": {"speed": f"{speed} {unit}", "unit": unit},
        "message": f"当前车速 {speed} {unit}",
    }

def _get_fuel_level() -> dict:
    """获取油量信息"""
    cfg = _get_mock_data().get("fuel_level", {})
    level = _rand_value(cfg)
    percent = int(level * 100)
    rng = cfg.get("range_km", 480)
    return {
        "success": True,
        "data": {"level": level, "percent": percent},
        "message": f"油量 {percent}%，续航约 {rng} 公里",
    }

def _get_mileage() -> dict:
    """获取总里程"""
    cfg = _get_mock_data().get("mileage", {})
    mileage = int(_rand_value(cfg))
    unit = cfg.get("unit", "km")
    return {
        "success": True,
        "data": {"mileage": mileage, "unit": unit},
        "message": f"总里程 {mileage} {unit}",
    }

def _navigate_to(destination: str, lat: float, lon: float) -> dict:
    """导航到目的地"""
    cfg = _get_mock_data().get("navigation", {})
    eta = cfg.get("default_eta_minutes", 25)
    dist = cfg.get("default_distance_km", 18.5)
    return {
        "success": True,
        "data": {
            "destination": destination, "lat": lat, "lon": lon,
            "eta_minutes": eta, "distance_km": dist,
        },
        "message": f"已规划到 {destination} 的路线，预计 {eta} 分钟到达",
    }

def _search_poi(query: str, category: Optional[str] = None) -> dict:
    """搜索兴趣点"""
    pois_cfg = _get_mock_data().get("pois", {})
    results = pois_cfg.get(query, [{"name": f"{query}(模拟)", "address": "示例地址", "distance": "~"}])
    return {
        "success": True,
        "data": {"query": query, "results": results},
        "message": f"找到 {len(results)} 个结果",
    }

def _set_temperature(temp: int) -> dict:
    """设置空调温度"""
    cfg = _get_mock_data().get("temperature", {})
    clamped = max(cfg.get("min", 16), min(cfg.get("max", 32), temp))
    return {
        "success": True,
        "data": {"temperature": clamped},
        "message": f"空调温度已设为 {clamped}°C",
    }

def _play_music(song: Optional[str] = None, artist: Optional[str] = None) -> dict:
    """播放音乐"""
    parts = []
    if song:
        parts.append(song)
    if artist:
        parts.append(artist)
    desc = " ".join(parts) if parts else "随机音乐"
    cfg = _get_mock_data().get("media", {})
    prefix = cfg.get("play_prefix", "正在播放")
    return {
        "success": True,
        "data": {"song": song, "artist": artist},
        "message": f"{prefix}: {desc}",
    }

def _control_media(action: str) -> dict:
    """控制媒体播放"""
    action_map = {"play": "播放", "pause": "暂停", "next": "下一首", "prev": "上一首"}
    desc = action_map.get(action, action)
    return {
        "success": True,
        "data": {"action": action},
        "message": f"已执行: {desc}",
    }


# ============================================================
# LangChain Tool 定义
# ============================================================

class GetVehicleSpeedTool(BaseTool):
    name: str = "get_vehicle_speed"
    description: str = "获取当前车速"
    args_schema: Type[BaseModel] = None

    def _run(self, **kwargs) -> dict:
        return _get_vehicle_speed()

class GetFuelLevelTool(BaseTool):
    name: str = "get_fuel_level"
    description: str = "获取当前油量"
    args_schema: Type[BaseModel] = None

    def _run(self, **kwargs) -> dict:
        return _get_fuel_level()

class GetMileageTool(BaseTool):
    name: str = "get_mileage"
    description: str = "获取总里程"
    args_schema: Type[BaseModel] = None

    def _run(self, **kwargs) -> dict:
        return _get_mileage()

class NavigateToTool(BaseTool):
    name: str = "navigate_to"
    description: str = "导航到指定目的地"
    args_schema: Type[BaseModel] = NavigateToSchema

    def _run(self, destination: str, lat: float, lon: float) -> dict:
        return _navigate_to(destination, lat, lon)

class SearchPoiTool(BaseTool):
    name: str = "search_poi"
    description: str = "搜索附近的兴趣点，如加油站、停车场、餐厅等"
    args_schema: Type[BaseModel] = SearchPoiSchema

    def _run(self, query: str, category: Optional[str] = None) -> dict:
        return _search_poi(query, category)

class SetTemperatureTool(BaseTool):
    name: str = "set_temperature"
    description: str = "设置空调温度"
    args_schema: Type[BaseModel] = SetTemperatureSchema

    def _run(self, temp: int) -> dict:
        return _set_temperature(temp)

class PlayMusicTool(BaseTool):
    name: str = "play_music"
    description: str = "播放音乐，可按歌曲名或歌手搜索"
    args_schema: Type[BaseModel] = PlayMusicSchema

    def _run(self, song: Optional[str] = None, artist: Optional[str] = None) -> dict:
        return _play_music(song, artist)

class ControlMediaTool(BaseTool):
    name: str = "control_media"
    description: str = "控制媒体播放，支持 play/pause/next/prev"
    args_schema: Type[BaseModel] = ControlMediaSchema

    def _run(self, action: str) -> dict:
        return _control_media(action)


# 所有工具的列表
ALL_TOOLS = [
    GetVehicleSpeedTool(),
    GetFuelLevelTool(),
    GetMileageTool(),
    NavigateToTool(),
    SearchPoiTool(),
    SetTemperatureTool(),
    PlayMusicTool(),
    ControlMediaTool(),
]

TOOL_NAME_MAP = {t.name: t for t in ALL_TOOLS}


def execute_tool(tool_name: str, args: dict) -> dict:
    """根据名称和参数执行工具，供 Server 层调用"""
    tool = TOOL_NAME_MAP.get(tool_name)
    if not tool:
        return {"success": False, "error": f"未知工具: {tool_name}"}
    try:
        return tool._run(**args)
    except Exception as e:
        return {"success": False, "error": str(e)}
