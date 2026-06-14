# TASKS - 车载娱乐系统原子任务拆分

## 任务依赖图

```mermaid
graph TD
    subgraph "HMI 侧 (C++ Qt)"
        T1[T1: 项目骨架+HMI构建] --> T3[T3: Infrastructure层 C++]
        T1 --> T2[T2: HTTP AgentClient]
        T3 --> T5[T5: Service层 C++]
        T2 --> T4[T4: ViewModel层 C++]
        T4 --> T6[T6: QML主框架]
        T5 --> T6
        T6 --> T7[T7: 播放器UI+VM]
        T6 --> T8[T8: 导航UI+VM]
        T6 --> T9[T9: 蓝牙UI+VM]
        T6 --> T10[T10: 车辆信息UI+VM]
        T6 --> T11[T11: 设置UI+VM]
        T6 --> T12[T12: Agent对话UI]
        T2 --> T12
    end

    subgraph "Agent 侧 (Python)"
        TA1[TA1: Agent项目骨架] --> TA2[TA2: FastAPI HTTP Server]
        TA2 --> TA3[TA3: LLM Agent核心]
        TA3 --> TA4[TA4: 工具链定义]
    end

    subgraph "集成"
        T7 --> T13[T13: 集成联调]
        T8 --> T13
        T9 --> T13
        T10 --> T13
        T11 --> T13
        T12 --> T13
        TA4 --> T13
    end

    subgraph "质量"
        T3 --> T14[T14: HMI单元测试]
        T5 --> T14
        TA3 --> T15[T15: Agent单元测试]
        T14 --> T13
        T15 --> T13
        T13 --> T16[T16: 端到端联调+验收]
    end

    subgraph "P2 增强 (已完成)"
        T13 --> P21[P2-1: 英文翻译]
        T13 --> P22[P2-2: gRPC升级]
        T13 --> P23[P2-3: 生产部署]
    end
```

## 任务概览

| 编号 | 名称 | 技术栈 | 状态 |
|------|------|--------|:----:|
| **T1** | 项目骨架 + HMI 构建系统 | CMake + Qt6 | ✅ |
| **T2** | Agent HTTP Client (Qt Network) | C++ + Qt Network | ✅ |
| **T3** | Infrastructure 基础设施层 | C++ Qt Modules + Win32 API | ✅ |
| **T4** | ViewModel 层 | C++ QObject | ✅ |
| **T5** | Service 业务服务层 | C++ | ✅ |
| **T6** | QML 主框架 | QML + Qt Quick | ✅ |
| **T7** | 音乐播放器 (UI+VM) | QML + C++ | ✅ |
| **T8** | 导航系统 (UI+VM) | QML + C++ | ✅ |
| **T9** | 蓝牙电话 (UI+VM) | QML + C++ | ✅ |
| **T10** | 车辆信息 (UI+VM) | QML + C++ | ✅ |
| **T11** | 系统设置 (UI+VM) | QML + C++ | ✅ |
| **T12** | Agent 对话页面 | QML + C++ AgentClient | ✅ |
| **TA1** | Agent 项目骨架 | Python | ✅ |
| **TA2** | Agent FastAPI HTTP Server | Python FastAPI + uvicorn | ✅ |
| **TA3** | LLM Agent 核心 | Python LangChain | ✅ |
| **TA4** | 工具链定义 | Python | ✅ |
| **T14** | HMI 单元测试 | Qt Test | ✅ |
| **T15** | Agent 单元测试 | pytest | ✅ |
| **T13** | 集成联调 | C++ + Python | ✅ |
| **T16** | 端到端验收 | - | ✅ |
| **P2-1** | **英文翻译** | Qt lrelease | ✅ |
| **P2-2** | **gRPC 升级** | protobuf + grpcio | ✅ |
| **P2-3** | **生产部署增强** | PowerShell + NSSM | ✅ |

---
