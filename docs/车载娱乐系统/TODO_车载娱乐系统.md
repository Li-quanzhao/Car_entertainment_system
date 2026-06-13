# 待办事项 - 车载娱乐系统

## 已完成

### 1. Agent API Key (DeepSeek) ✅
- **状态**: 已配置 DeepSeek API Key，Agent 连接验证通过
- **模型**: `deepseek-chat` (兼容 OpenAI API 格式)
- **Base URL**: `https://api.deepseek.com`
- **配置位置**: `agent/.env`
  ```
  OPENAI_API_KEY=sk-9d3ff9...601a68
  OPENAI_BASE_URL=https://api.deepseek.com
  OPENAI_MODEL=deepseek-chat
  ```
- **相关修改**:
  - `agent/config.py` / `agent/llm_agent/config.py` — 新增 `OPENAI_BASE_URL` 支持
  - `agent/llm_agent/agent.py` — `ChatOpenAI` 传入 `base_url` 参数
  - `agent/__init__.py` — 新建，解决相对导入问题
  - `agent/server.py` — 修复相对导入为绝对导入，添加 Anaconda 系统包路径
- **降级机制**: DeepSeek 不可用时自动降级 Mock 模式

### 2. 目录链接（中文路径问题） ✅
- **当前已创建**: `E:\car_hmi_project` → 指向 `E:\PyCharmProject\Trae实验\Car_entertainment_system`
- **如果链接丢失**, 用管理员 PowerShell 执行:
  ```powershell
  New-Item -ItemType Junction -Path "E:\car_hmi_project" -Target "E:\PyCharmProject\Trae实验\Car_entertainment_system"
  ```

### 3. HMI 编译 + 启动验证 ✅
- **编译**: `[100%] Built target car_hmi`，MinGW 编译成功
- **启动**: `car_hmi.exe` 成功启动并渲染 QML 界面
- **修复**:
  - `main.qml`: `enum Page` → `readonly property int` 常量（QML 跨文件枚举不可见）
  - `NavBar.qml`: `MainPage.X` → 直接整数索引
  - `main.qml` switchPage: `MainPage.X` → 直接整数 case
- **已知非致命问题**: PlayerPage.qml 锚点冲突警告（StackView 过渡期锚点检测，不影响功能）

### 4. Agent Server 端到端验证 ✅
- `GET /api/health` → `{"status":"ok","llm_available":true,"tools_count":8}`
- `POST /api/chat` → 正常返回 AI 回复（DeepSeek 驱动）
- `POST /api/command(get_fuel_level)` → `{"success":true,"data":{"level":0.72,"percent":72}}`

### 5. AgentChatPage 聊天界面 ✅
- **状态**: 已实现完整聊天界面
- **新增文件**:
  - `hmi/src/viewmodel/agent_viewmodel.h` — 封装 `agent_http_client` 的 ViewModel
  - `hmi/src/viewmodel/agent_viewmodel.cpp` — 消息管理、会话管理、异步通信
- **修改文件**:
  - `hmi/CMakeLists.txt` — 添加 agent_viewmodel 源文件
  - `hmi/src/main.cpp` — 创建 AgentViewModel 并注册为 `agentVM` 上下文属性
  - `hmi/src/ui/AgentChatPage.qml` — 重写为完整聊天界面
- **界面功能**:
  - 消息气泡列表（用户右对齐蓝色/助手左对齐灰色）
  - 输入框 + 发送按钮（支持 Enter 键发送）
  - AI 思考中指示器（动画圆点 + 状态文字）
  - 清空对话按钮
  - 连接状态提示条（未连接时显示红色警告）
- **修复**:
  - 气泡文本重叠问题（`Layout.fillWidth` + `anchors.fill` 循环依赖 → 改用 `Column` + 显式高度）
  - 新消息自动滚动（`Connections` 监听 `messagesChanged` 自动 `positionViewAtEnd()`）

### 6. Agent 改进（全部 6 项） ✅

| # | 改进项 | 修改文件 | 说明 |
|---|--------|----------|------|
| 1 | Mock 数据可配置化 | `mock_data.json`（新建）、`tools.py` | 外部 JSON 文件配置随机范围，惰性加载 |
| 2 | 会话历史裁剪 | `config.py`（×2）、`session.py`、`agent.py` | 默认保留最近 10 轮对话 |
| 3 | System Prompt 工具示例 | `chain.py` | 逐条标注 8 个工具的调用触发条件和参数 |
| 4 | 流式响应 SSE | `server.py` | `/api/chat/stream` 端点，模拟逐字推送 |
| 5 | 请求限流 + 缓存 | `server.py` | 滑动窗口限流器 + 30 秒 TTL 缓存 |
| 6 | 结构化日志 | `server.py` | JSON 格式日志（含 latency、session_id） |

### 7. HMI 流式响应接入 ✅

- **修改文件**:
  - `agent_http_client.h` — 新增 `sendChatStream()` 方法和 `chatStreamChunk` / `chatStreamFinished` 信号
  - `agent_http_client.cpp` — SSE 解析实现：`readyRead` 缓冲区 + 按 `\n\n` 分隔事件 + `data:` JSON 解析
  - `agent_viewmodel.h` / `agent_viewmodel.cpp` — 改用流式通道：创建空占位消息，逐块累积，实时更新气泡文本
- **效果**: AI 回复在 HMI 上逐字出现，像真人打字一样

## P1 已完成

### 8. QML 国际化翻译文件 ✅
- 所有 QML 已标注 `qsTr()`
- `hmi/translations/zh_CN.ts` — 中文翻译（29 条，源语言=目标语言）
- `hmi/translations/en.ts` — 英文翻译模板（待翻译）
- 自动加载: `main.cpp` 根据系统 locale 加载 `:/i18n/{locale}.qm`
- 更新翻译: 修改 .ts 文件后运行 `lrelease hmi/translations/zh_CN.ts -qm hmi/translations/zh_CN.qm`

### 9. 单元测试 ✅
- **Agent**: `tests/agent_tests/test_tools.py` — 11 个测试用例，覆盖全部 8 个工具 + mock 数据校验
  - 运行: `python -s -m pytest tests/agent_tests/ -v`
- **HMI**: `hmi/tests/test_config.cpp` — Qt Test，8 个测试用例，覆盖 ConfigManager
  - 编译: `cmake --build build --target test_hmi`
  - 运行: `& "E:\car_hmi_project\hmi\build\test_hmi.exe"`
- Agent 工具链与 HMI 核心基础设施已验证

## P2 待办（未来扩展）

### 10. gRPC 升级
- 需安装 protobuf + grpcio
- `proto/car_assistant.proto` 已占位
- 生成代码: `protoc --cpp_out=hmi/src/infrastructure --python_out=agent proto/car_assistant.proto`

### 11. 生产部署增强
- 安装包打包（NSIS / Inno Setup）
- Agent Server 注册为 Windows 服务（NSSM）
- 开机自启动脚本
- Agent 接口鉴权

## Agent Server 启动方式

```bash
cd E:\PyCharmProject\Trae实验\Car_entertainment_system\agent
python server.py
# FastAPI Server 启动在 http://localhost:8000
```

### API 端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/health` | GET | 健康检查，返回 LLM 状态和工具数量 |
| `/api/chat` | POST | AI 对话，body: `{"message": "...", "session_id": "..."}` |
| `/api/chat/stream` | POST | 流式 AI 对话，返回 SSE 逐字推送 |
| `/api/command` | POST | 执行工具，body: `{"tool": "...", "args": {...}}` |

### 可用工具

`get_vehicle_speed`, `get_fuel_level`, `get_mileage`, `navigate_to`, `search_poi`, `set_temperature`, `play_music`, `control_media`

## HMI 启动方式

```bash
# 确保 Agent Server 先在 :8000 运行
$env:PATH = "E:\Qt\6.11.1\mingw_64\bin;$env:PATH"
& "E:\car_hmi_project\hmi\build\car_hmi.exe"
```
