# ALIGNMENT - 车载娱乐系统需求对齐

## 项目概述

基于 6A 工作流，从零开始构建一个车载娱乐系统（Car Entertainment System），采用 **C++ Qt (HMI) + Python (LLM Agent)** 混合架构。

## 最终决策

### 技术栈

| 层级                                   | 语言                       | 框架/库                                                       | 构建工具                    |
| ------------------------------------ | ------------------------ | ---------------------------------------------------------- | ----------------------- |
| **HMI (UI+ViewModel+Service+Infra)** | C++17/20                 | Qt 6.11.1 + QML + Qt Quick (MinGW)                         | CMake 4.3.3             |
| **LLM Agent 后端**                     | Python 3.10+             | LangChain + FastAPI                                        | pip                     |
| **通信协议(初期)**                         | HTTP/JSON                | Qt Network (QNetworkAccessManager)                         | FastAPI (uvicorn) :8000 |
| **通信协议(后续升级)**                       | gRPC                     | gRPC C++ Client (vcpkg)                                    | grpcio Server :50051    |
| **数据库**                              | SQLite                   | Qt SQL / Python sqlite3                                    | -                       |
| **音频**                               | Qt Multimedia (C++)      | QMediaPlayer                                               | -                       |
| **蓝牙**                               | Win32 Bluetooth API 手写补齐 | BluetoothFindFirstRadio / WSALookupService / RFCOMM socket | -                       |
| **串口**                               | Win32 API 手写补齐           | CreateFile / SetCommState / ReadFile / WriteFile           | -                       |

### 运行平台

* **目标平台**: Windows/Linux 桌面应用（可部署至车载电脑/工控机）

* **HMI 运行**: 原生 C++ 二进制，无运行时依赖

* **Agent 运行**: Python 3.10+ 解释器，作为独立进程运行

### 核心功能（P0-P1）

| 模块            | 功能描述                                    | 优先级 |
| ------------- | --------------------------------------- | --- |
| **音乐播放器**     | 本地音乐播放、播放列表、歌曲管理、播放控制(上一首/下一首/暂停/进度/音量) | P0  |
| **导航系统**      | 地图显示、路线规划、POI搜索                         | P1  |
| **蓝牙电话**      | 蓝牙连接、通讯录同步、通话记录、拨号盘                     | P1  |
| **车辆信息**      | 车速、转速、油耗、里程等车辆状态信息显示                    | P1  |
| **系统设置**      | 音量、音效、显示主题、语言、时间等设置                     | P0  |
| **LLM Agent** | 自然语言交互、工具调用、车辆问答（通过 Python 后端服务）        | P1  |

### 不包含范围

* 语音唤醒/ASR/TTS（P2，后续版本考虑）

* 收音机（P2，后续版本考虑）

* 视频播放（P2，后续版本考虑）

* 移动端远程控制（P2，后续版本考虑）

## 质量要求

* 模块化设计，HMI 与 Agent 独立可运行

* QML UI 流畅，动画平滑（60FPS）

* 支持多语言（中文/英文）

* 支持主题切换（明亮/黑暗）

* HTTP 通信延迟 < 200ms（初期）；gRPC 通信延迟 < 10ms（后续升级）

* Agent 无网络时可离线降级

## 通信契约（HMI ↔ Agent）

### 初期方案：HTTP/JSON + Qt Network

```json
// POST /api/chat
Request: {
  "session_id": "xxx",
  "message": "导航到天安门",
  "history": [{"role": "user", "content": "..."}]
}
Response: {
  "reply": "好的，正在规划到天安门的路线...",
  "tools": [{"name": "navigate_to", "args": {"destination": "天安门"}}]
}

// POST /api/tool
Request: {"tool_name": "navigate_to", "parameters": {"destination": "天安门"}}
Response: {"success": true, "result": "路线已规划完毕"}

// GET /api/status
Response: {"state": "IDLE", "active_model": "gpt-4o", "is_online": true}
```

### 后期升级：gRPC (C++ Client)

```protobuf
service CarAssistant {
  rpc ChatQuery(QueryRequest) returns (QueryResponse);
  rpc StreamChat(QueryRequest) returns (stream QueryResponse);
  rpc ExecuteTool(ToolRequest) returns (ToolResponse);
}
```

