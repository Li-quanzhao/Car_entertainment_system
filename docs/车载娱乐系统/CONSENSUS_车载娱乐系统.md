# CONSENSUS - 车载娱乐系统共识文档

## 需求描述

构建一个车载娱乐系统桌面应用，采用 **C++ Qt HMI + Python LLM Agent** 混合架构，包含六大核心模块：音乐播放器、导航系统、蓝牙电话、车辆信息显示、系统设置、LLM Agent。

## 技术方案

| 层级 | 技术选型 |
|------|---------|
| **HMI 语言** | C++17/20 |
| **HMI UI 框架** | Qt 6.11.1 + QML + Qt Quick Controls 2 (MinGW) |
| **HMI 构建系统** | CMake 4.3.3 (MinGW Makefiles) |
| **LLM Agent 语言** | Python 3.10+ |
| **LLM Agent 框架** | LangChain + FastAPI (uvicorn) |
| **跨进程通信(主)** | HTTP/JSON, Qt Network (QNetworkAccessManager) ↔ FastAPI :8000 |
| **跨进程通信(可选)** | gRPC (protobuf), gRPC C++ Client ↔ grpcio Server :50051 |
| **包管理(HMI)** | CMake + vcpkg (可选 gRPC) |
| **包管理(Agent)** | pip + requirements.txt |
| **数据库** | SQLite (Qt SQL for HMI, sqlite3 for Agent) |
| **蓝牙** | Win32 Bluetooth API 手写补齐 (WSALookupService / RFCOMM socket) |
| **串口** | Win32 API 手写补齐 (CreateFile / SetCommState) |

## 系统架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          进程1: C++ Qt HMI                                   │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  QML UI Layer (Player/Nav/BT/Vehicle/Settings/Agent + 国际化)        │  │
│  ├──────────────────────────────────────────────────────────────────────┤  │
│  │  C++ ViewModel Layer (QObject Property/Signal/Slot)                  │  │
│  ├──────────────────────────────────────────────────────────────────────┤  │
│  │  C++ Service Layer (业务逻辑)                                         │  │
│  ├──────────────────────────────────────────────────────────────────────┤  │
│  │  C++ Infrastructure Layer (Audio/Bluetooth/Serial/DB/HTTP/gRPC)     │  │
│  └──────────────────────┬───────────────────────────────────────────────┘  │
│                         │ HTTP/JSON :8000 / gRPC :50051                    │
└─────────────────────────┼──────────────────────────────────────────────────┘
                          │
                          ▼ HTTP REST (localhost:8000) / gRPC (localhost:50051)
┌─────────────────────────────────────────────────────────────────────────────┐
│                          进程2: Python LLM Agent                             │
│  ┌───────────────────┐  ┌──────────────────┐  ┌────────────────────────┐  │
│  │ FastAPI HTTP      │  │ gRPC Server      │  │ LangChain Agent       │  │
│  │ :8000             │  │ :50051           │  │ / Tool Chain / RAG    │  │
│  │ health/chat/cmd   │  │ 4 RPCs + 反射    │  │ LLM Router (云端/本地) │  │
│  └───────────────────┘  └──────────────────┘  └────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 验收标准
1. 所有 HMI 模块可正常编译运行
2. 音乐播放器支持本地音频文件加载、播放控制
3. 导航系统显示地图，支持路线规划
4. 蓝牙电话支持设备搜索、连接、通话
5. 车辆信息模块模拟展示车速/油耗等数据
6. 系统设置支持主题切换、语言切换（中/英）
7. LLM Agent 可通过文本输入与用户对话，调用车载工具
8. HMI 与 Agent 通过 HTTP (Qt Network) 通信正常，端到端延迟 < 200ms
9. Agent 离线时 HMI 核心功能不受影响
10. UI 美观流畅，分辨率自适应
11. gRPC 可选通信（Python Server + C++ 条件编译适配）
12. 生产部署：打包脚本 + Windows 服务注册 + API 鉴权

## 任务边界
- **HMI 侧（C++ Qt）**：6 大模块 + 主界面框架 + 多语言（中/英）+ 主题切换 + Agent HTTP Client + gRPC 条件编译适配
- **Agent 侧（Python）**：FastAPI HTTP Server + gRPC Server + LLM Agent + 工具链
- **不包含**：语音唤醒、收音机、视频播放、移动端远程控制

## 已确认决策

| 决策项 | 选择 |
|--------|------|
| 运行平台 | 桌面应用（车载电脑/工控机） |
| HMI 技术栈 | C++17/20 + Qt 6.11.1 + QML (MinGW) |
| Agent 技术栈 | Python 3.13 + LangChain + FastAPI |
| **跨进程通信(主)** | HTTP/JSON, Qt Network ↔ FastAPI :8000 |
| **跨进程通信(可选)** | gRPC (protobuf) :50051，CMake 条件编译 `CAR_HMI_USE_GRPC` |
| HMI 构建 | CMake 4.3.3 + MinGW Makefiles（Ninja 因中文路径编码问题降级）|
| Agent 包管理 | pip + requirements.txt |
| UI方式 | QML + Qt Quick Controls 2 |
| 开发环境 | Windows + MinGW-w64 (g++ 16.1.0) + Qt 6.11.1 + Python 3.13 |
| 核心模块 | 音乐播放器、导航、蓝牙电话、车辆信息、系统设置、LLM Agent |
| 蓝牙实现 | Win32 Bluetooth API 手写补齐（非 QBluetooth）|
| 串口实现 | Win32 API 手写补齐（非 QSerialPort）|
| 多语言 | 中/英双语，qsTr() + .qm，locale 逐步降级 |
| gRPC 状态 | Python 端完整实现，C++ 端条件编译（需 VS + vcpkg 开启）|
| 部署方式 | PowerShell 打包脚本 + NSSM Windows 服务 |
| 鉴权方式 | HTTP Header `X-API-Key` 验证 |

## 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| HTTP 请求延迟高于 gRPC | 实时性 | HTTP < 200ms 满足需求，可选 gRPC 降至 < 10ms |
| C++ Qt 开发效率低于 Python | 开发周期 | HMI 核心模块用 C++，Agent 侧用 Python 快速迭代 |
| LLM API 依赖网络 | 功能可用性 | 支持本地模型（Ollama）离线降级 |
| 项目路径含中文导致构建问题 | 构建失败 | 使用 MinGW Makefiles 替代 Ninja，或通过 junction 链接 |
| C++ 内存安全问题 | 稳定性 | 使用 RAII、智能指针、Qt 父子对象树管理 |
| VS + vcpkg 安装 gRPC 门槛 | gRPC C++ 编译 | 提供详细文档，默认 HTTP 通信不受影响 |
