"""Agent 工具函数测试"""
import json, sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "agent"))

from llm_agent.tools import ALL_TOOLS as tools, _load_mock_data


def test_tools_count():
    """应有 8 个工具"""
    assert len(tools) == 8


def _result(t):
    """执行工具并返回 dict"""
    r = t._run() if t.args_schema is None else t._run(**{})
    return json.loads(r) if isinstance(r, str) else r


def test_get_vehicle_speed():
    t = next(t for t in tools if t.name == "get_vehicle_speed")
    r = _result(t)
    assert r["success"] is True
    assert "speed" in r["data"]


def test_get_fuel_level():
    t = next(t for t in tools if t.name == "get_fuel_level")
    r = _result(t)
    assert r["success"] is True
    assert 0 <= r["data"]["percent"] <= 100


def test_get_mileage():
    t = next(t for t in tools if t.name == "get_mileage")
    r = _result(t)
    assert r["success"] is True
    assert r["data"]["mileage"] > 0


def test_set_temperature_valid():
    t = next(t for t in tools if t.name == "set_temperature")
    r = t._run(temp=26)
    r = json.loads(r) if isinstance(r, str) else r
    assert r["success"] is True
    assert r["data"]["temperature"] == 26


def test_set_temperature_clamps_range():
    t = next(t for t in tools if t.name == "set_temperature")
    r = t._run(temp=50)
    r = json.loads(r) if isinstance(r, str) else r
    assert r["success"] is True
    assert 16 <= r["data"]["temperature"] <= 32


def test_navigate_to():
    t = next(t for t in tools if t.name == "navigate_to")
    r = t._run(destination="天安门", lat=39.9, lon=116.4)
    r = json.loads(r) if isinstance(r, str) else r
    assert r["success"] is True
    assert r["data"]["destination"] == "天安门"


def test_search_poi():
    t = next(t for t in tools if t.name == "search_poi")
    r = t._run(query="加油站")
    r = json.loads(r) if isinstance(r, str) else r
    assert r["success"] is True
    assert len(r["data"]["results"]) > 0


def test_play_music():
    t = next(t for t in tools if t.name == "play_music")
    r = t._run(artist="周杰伦")
    r = json.loads(r) if isinstance(r, str) else r
    assert r["success"] is True


def test_control_media():
    t = next(t for t in tools if t.name == "control_media")
    r = t._run(action="pause")
    r = json.loads(r) if isinstance(r, str) else r
    assert r["success"] is True
    assert r["data"]["action"] == "pause"


def test_mock_data_structure():
    data = _load_mock_data()
    required_keys = {"vehicle_speed", "fuel_level", "mileage", "temperature", "navigation", "pois", "media"}
    assert required_keys.issubset(data.keys())
