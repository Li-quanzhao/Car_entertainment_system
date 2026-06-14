---
alwaysApply: true
---
# AI 自我治理与上下文管理规则

> **目的**: 约束 AI 行为边界，管理对话上下文，保持开发一致性。
> **适用范围**: 所有涉及本项目代码的对话和操作。

---

## 第一部分：自我治理（Self-Governance）

### 1.1 行为边界

| 类型 | 允许 | 禁止 |
|------|------|------|
| **文件操作** | 编辑现有文件、创建任务所需的新文件 | 创建 README.md / 文档（除非用户明确要求） |
| **依赖管理** | 使用现有依赖、安装 requirements.txt 中列出的包 | 引入新的第三方依赖（需先询问） |
| **架构变更** | 遵循现有三层架构（Infra/Service/ViewModel） | 引入新架构层、重构已有代码的架构（除非明确要求） |
| **删除操作** | 先询问用户确认后删除 | 任何未经确认的删除行为（详见 6.3 禁止清单） |
| **破坏性操作** | - | 严禁：force push、hard reset、DROP TABLE、删除项目文件（详见 6.3） |
| **git 操作** | 用户要求时执行推送；较大更新后主动建议推送 | 自动 commit / push（必须先询问确认） |
| **推送触发** | 新增文件 ≥2 / 修改文件 ≥4 / 新功能 / Bug修复（详见推送命令.md） | 小调整(1-2文件)、调试代码、仅文档修改不推送 |
| **文档同步** | 每次修改代码后立即同步更新 docs/ | 代码改完文档不动 |
| **探索性行为** | 读取代码理解现有模式 | 运行不确定后果的命令、修改未读取的代码 |

### 1.2 决策自主权等级

```
Level 1 - 自主执行
  ├─ 修复编译错误（CMAKE、语法、类型匹配）
  ├─ 按现有模式补齐代码（如新增 ViewModel 按已有 ViewModel 模式）
  ├─ QML 属性绑定和 UI 调整（不改架构）
  ├─ 主动建议推送（满足推送触发条件时询问用户）
  └─ 添加注释/日志

Level 2 - 需确认后执行
  ├─ 引入新的第三方库/模块
  ├─ 修改现有模块的接口签名
  ├─ 新增文件 > 3 个的任务
  ├─ 执行 git commit / push（必须先确认）
  └─ 删除文件或代码

Level 3 - 必须中断并讨论
  ├─ 架构层面的修改（如引入新架构层、改变通信模式）
  ├─ 涉及安全/鉴权的设计决策
  ├─ 涉及数据持久化格式变更
  └─ 与现有约束冲突的方案
```

### 1.3 避免过度工程清单

禁止以下行为（除非任务明确要求）：
- ❌ 给现有代码添加 docstring / 注释（除非逻辑不清）
- ❌ 重构已有代码（改名、提取函数、模式化）
- ❌ 添加错误处理覆盖不可能发生的路径
- ❌ 创建工具类/辅助函数给一次性操作
- ❌ 预添加未来才需要的功能钩子
- ❌ 添加设计模式抽象（工厂、策略等）给简单逻辑
- ❌ 给已有代码加类型标注/泛型

---

## 第二部分：上下文管理（Context Management）

### 2.1 上下文分层模型

```
Layer 1 - 永久上下文（始终保留）
  ├─ 技术栈限制（Qt 6.11.1 MinGW、Python 3.13、CMake 4.3.3）
  ├─ 项目架构（三层架构、通信协议、目录结构）
  ├─ 编码约定（命名风格、Q_PROPERTY 模式、文件组织）
  └─ 构建命令（Junction 链接、cmake 命令、运行方式）

Layer 2 - 会话上下文（单个开发会话）
  ├─ 当前任务的目标和范围
  ├─ 已读取/修改的文件列表
  ├─ 已做出的架构决策和原因
  └─ 当前阻塞点

Layer 3 - 临时上下文（单步操作）
  ├─ 当前正在编辑的代码片段
  ├─ 当前编译/测试输出
  └─ 当前工具调用结果
```

### 2.2 自动上下文压缩

**触发条件**: 满足以下任一条件时，必须自动触发上下文压缩：

| 触发条件 | 阈值 |
|---------|------|
| 当前对话轮次 | 超过 15 轮对话 |
| 连续工具调用 | 超过 8 次未做摘要 |
| 子任务完成 | 每完成 1 个 TodoWrite 子任务 |
| 文件读取累积 | 读取超过 10 个文件 |
| 用户显式要求 | "/compress" 或 "压缩上下文" |

**自动压缩流程**（无需用户确认，直接执行）：

1. **判定触发条件** — 检查当前对话是否满足上述任一阈值
2. **子任务完成时压缩**（推荐时机）:
   - 标记当前子任务为 completed
   - 在 TodoWrite summary 中写一句话总结本子任务成果
   - 对话继续，之前的 Layer 3 细节随上下文窗口自然淘汰
3. **会话中点压缩**（超 15 轮或 8 次工具调用）:
   - 暂停当前操作
   - 用一句话输出当前进度摘要（已完成什么 / 正在做什么 / 下一步做什么）
   - 输出后继续，Layer 2 上下文替换旧的 Layer 3 细节
4. **紧急压缩**（接近限制时）:
   - 先消除 Layer 3 — 合并连续的工具调用结果，只保留最终输出
   - 再摘要 Layer 2 — 把已完成的任务步骤摘要为一行状态
   - **Layer 1 永不压缩** — 技术栈、架构、编码约定始终保留

**压缩示例输出格式**:
```
[上下文压缩] 已完成: T1 播放器修复 (3 文件修改, 编译通过)
            进行中: T2 蓝牙页面布局调整
            下一步: T3 QML 国际化更新
            已读文件: player_viewmodel.cpp, BluetoothPage.qml, main.qml
```

**压缩后行为**:
- 从 Layer 1 规则文件和 TodoWrite 重建任务上下文
- 如需重新读取文件，压缩后的 Read 调用属于正常操作
- 压缩不影响当前任务进度（TodoWrite 状态保留）

### 2.3 状态跟踪规则

- 每次修改代码前，先读取当前文件的最新内容
- 每次修改后，记录修改了什么文件、为什么修改
- 多步骤任务使用 TodoWrite 跟踪进度
- 每个子任务完成时，在 TodoWrite summary 中记录关键结果

### 2.4 恢复/续接规则

当对话被中断后恢复时：
1. 读取 `.trae/rules/` 下所有规则文件重建上下文
2. 读取最近修改的 3-5 个源文件重建代码状态
3. 检查 `build/` 目录判断编译状态
4. 如存在未完成的 TodoWrite，从中断点继续
5. 如无法确定状态，先询问用户当前进度

---

## 第三部分：代码生态规则（Code Ecosystem）

### 3.1 架构分层与依赖方向

```
┌─────────────────────────────────────────────────────────┐
│  UI Layer (QML)                                         │
│  └─ 只能通过 context property 调用 ViewModel            │
├─────────────────────────────────────────────────────────┤
│  ViewModel Layer (C++ QObject)                          │
│  └─ 调用 Service 层，不能直接访问 Infrastructure        │
│  └─ 通过 Q_PROPERTY + signal 暴露给 QML                 │
├─────────────────────────────────────────────────────────┤
│  Service Layer (C++ QObject)                            │
│  └─ 调用 Infrastructure 层，组合业务逻辑                │
│  └─ 不直接暴露给 QML                                    │
├─────────────────────────────────────────────────────────┤
│  Infrastructure Layer (C++)                             │
│  └─ 封装硬件/系统/第三方接口                            │
│  └─ 不依赖上层                                          │
└─────────────────────────────────────────────────────────┘
```

**依赖规则**:
- UI → ViewModel → Service → Infrastructure（单向依赖）
- 严禁 Infrastructure 层引用 Service 或 ViewModel 的头文件
- 严禁 Service 层引用 ViewModel 的头文件
- ViewModel 不能直接包含 infrastructure/ 下的头文件

### 3.2 C++ 编码约定

| 规则 | 标准 |
|------|------|
| **命名** | 类名 PascalCase, 方法/属性 camelCase, 成员变量 `m_` 前缀 |
| **头文件保护** | `#ifndef CLASSNAME_H` / `#define CLASSNAME_H` / `#endif` |
| **Q_PROPERTY 模式** | `READ getter NOTIFY signal`，可写加 `WRITE setter` |
| **信号连接** | 优先使用 `connect(obj, &Class::signal, this, &Class::slot)` lambda 形式 |
| **成员初始化** | 使用 `= default` 值初始化，而非构造函数初始化列表 |
| **include 顺序** | Qt 头文件 → 标准库 → 项目内部头文件（每组空行分隔） |
| **QML 属性暴露** | `setContextProperty(name, ptr)`，不用 `qmlRegisterType`（现有模式） |

### 3.3 Python 编码约定

| 规则 | 标准 |
|------|------|
| **命名** | 类 PascalCase, 函数/变量 snake_case, 常量 UPPER_SNAKE |
| **导入顺序** | 标准库 → 第三方库 → 项目内部模块（每组空行分隔） |
| **类型提示** | Pydantic model 必须用 Field 标注，函数参数用 typing |
| **配置管理** | `config.py` 集中管理，`os.getenv()` 读取 `.env` |
| **日志** | 使用 `logging.getLogger(__name__)`，不用 print |
| **错误处理** | 不捕获基类 Exception，除非顶层兜底 |

### 3.4 ViewModel 注册规则

新增 ViewModel 时必须：
1. `viewmodel/new_viewmodel.h` — Q_OBJECT + Q_PROPERTY + signals + public slots
2. `viewmodel/new_viewmodel.cpp` — 实现
3. `CMakeLists.txt` — 在 `add_executable` 中添加 .h 和 .cpp
4. `main.cpp` — `#include` + 创建实例 + `setContextProperty`

**模板**（按 [player_viewmodel.h](file:///e:/PyCharmProject/Trae实验/Car_entertainment_system/hmi/src/viewmodel/player_viewmodel.h) 模式）:

```cpp
class NewViewModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(...)
public:
    explicit NewViewModel(QObject *parent = nullptr);
    // getter / setter
public slots:
    // QML 可调用的槽函数
signals:
    // 通知 QML 属性变化
private:
    // m_ 前缀的成员变量
};
```

### 3.5 QML 编码约定

| 规则 | 标准 |
|------|------|
| **导入** | `import QtQuick`, `import QtQuick.Controls`, `import QtQuick.Layouts` |
| **页面结构** | 每个页面是一个独立 `.qml` 文件 |
| **ViewModel 访问** | `viewModelName.propertyName` / `viewModelName.slotName()` |
| **颜色方案** | 通过 `main.qml` 的 `readonly property color` 全局属性 |
| **国际化** | 所有用户可见文本使用 `qsTr()` |
| **布局** | 使用 `ColumnLayout` / `RowLayout`，避免硬编码坐标 |

---

## 第四部分：开发工作流规则（6A 适配）

### 4.1 任务启动检查清单

开始任何开发任务前，必须确认：
- [ ] 已读取技术栈限制（技术栈限制.md）
- [ ] 已读取 AI 自我治理规则（本文件）
- [ ] 已理解任务范围和边界
- [ ] 已检查是否有重复/冲突的现有功能
- [ ] 已知晓当前项目的编译状态和运行状态

### 4.2 文档同步规则

**核心原则**: 代码即文档，文档即代码。每次修改源代码后，必须同步更新技术文档。

**文档更新流程**:
1. 修改源代码文件后，立即检查 `docs/` 目录下对应的文档是否过时
2. 凡是修改涉及的模块，在对应文档中记录变更内容、原因和影响范围
3. 新增功能模块 → 追加至任务拆解文档和验收文档
4. 接口签名变更 → 同步更新设计文档中的接口定义
5. 每次完成一个子任务 → 在 ACCEPTANCE 文档中标记完成状态

**文档优先规则**:
- 在开始编码前，先查阅 `docs/` 下的设计文档和任务文档，以文档为出发点
- 文档内容是最终真相来源（source of truth），代码按文档实现
- 如发现文档与代码不一致，以文档为准修正代码（除非用户另有指示）

**禁止行为**:
- ❌ 代码修改后文档不动
- ❌ 先写代码后补文档（文档应同步迭代）
- ❌ 删除文档文件

### 4.3 文档创建规则

按照用户提供的 6A 工作流（Align → Architect → Atomize → Approve → Automate → Assess），**仅当任务复杂度满足以下任一条件时**才创建新文档：
- 涉及跨层修改（UI + ViewModel + Service + Infrastructure）
- 新增功能模块 > 5 个文件
- 涉及架构决策或技术选型
- 用户明确要求走完整 6A 流程

简单任务（1-3 个文件修改）直接实施，更新已有文档即可。

### 4.4 测试规则

- 现有测试不能破坏（运行通过后缓存结果）
- 新增基础设施模块（Infrastructure 层）必须有单元测试
- ViewModel 层可以通过 Qt Test 验证（如 [test_config.cpp](file:///e:/PyCharmProject/Trae实验/Car_entertainment_system/hmi/tests/test_config.cpp) 模式）
- Agent 新工具函数必须有 pytest 用例（如 [test_tools.py](file:///e:/PyCharmProject/Trae实验/Car_entertainment_system/tests/agent_tests/test_tools.py) 模式）
- 每次代码修改后运行编译验证

### 4.5 停止目标（Stop Goals）

**核心原则**: 任务必须有明确的边界，知道何时停止。不追求完美，追求"刚好够"。

#### 4.5.1 任务完成标准（Done Criteria）

一个任务被认为"完成"，必须同时满足：

| 条件 | 验证方式 |
|------|---------|
| **功能可用** | 核心功能能跑通，不崩溃 |
| **编译通过** | `cmake --build build` 无错误 |
| **文档已同步** | `docs/` 下对应文档已更新变更记录 |
| **TodoWrite 全部 completed** | 所有子任务标记完成 |
| **不引入新 Bug** | 已有测试不降级 |

#### 4.5.2 强制停止条件（Hard Stop）

出现以下任一情况，**立即停止当前操作**，不再尝试：

| 停止条件 | 行为 |
|---------|------|
| **同一操作失败 2 次** | 停止重试，询问用户 |
| **编译错误无法定位** | 停止排查，汇报已排除的方向和剩余疑点 |
| **依赖缺失** | 停止编码，告知缺什么、怎么装 |
| **权限不足** | 停止当前操作，说明需要什么权限 |
| **用户说"停"/"取消"/"不要了"** | 立即停止，不做任何收尾操作 |
| **触及 6.3 禁止清单** | 立即停止，解释为什么这是禁止的 |

#### 4.5.3 截断标准（Enough is Enough）

达到以下状态时必须停止，**不再继续优化**：

| 截断条件 | 理由 |
|---------|------|
| **核心功能跑通 + 编译通过** | 功能已达成，额外优化属于过度工程 |
| **用户需求已满足** | 不擅自扩展范围外的功能 |
| **连续三轮对话无新需求提出** | 用户没有新指示 = 任务结束 |
| **改动超过原计划 50%** | 范围蔓延，需重新评估 |

#### 4.5.4 任务结束输出格式

任务完成后，输出统一的结束摘要：

```
[任务完成] 
  任务: [任务描述]
  修改: [文件1], [文件2] (共 N 个文件)
  编译: ✅ / ❌
  文档: ✅ 已同步 docs/xxx.md
  推送: [建议推送 / 不触发推送]
  残留问题: [有/无，如有则列出]
```

#### 4.5.5 项目最终停止目标：全部修复完成

项目当前存在已知差距（架构连接断裂、Service 空桩、UI 占位），最终停止目标是**所有 P0+P1 修复全部完成**。分三级验收：

| 级别 | 修复项 | 验收标准 | 状态 |
|------|--------|---------|:----:|
| **P0** | PlayerVM 接入 MediaService + AudioEngine | 播放列表从 Database 加载、切歌功能可用 | ❌ |
| **P0** | NavigationPage 重建 UI | POI 搜索 + 结果列表 + 导航信息卡片可交互 | ❌ |
| **P0** | BluetoothPage 重建 UI | 设备列表 + 连接状态 + 拨号盘可交互 | ❌ |
| **P0** | VehiclePage 重建 UI | 速度表盘 + 车辆状态卡片展示真实数据 | ❌ |
| **P0** | SettingsPage 重建 UI + 接入 ConfigManager | 主题/语言/音量设置可持久化 | ❌ |
| **P0** | BluetoothVM 接入 BluetoothService | 设备扫描/连接/断开功能可用 | ❌ |
| **P0** | NavVM 接入 MapService | POI 搜索+地点收藏功能可用 | ❌ |
| **P0** | VehicleVM 接入 VehicleService | 真实车辆数据展示(非随机数) | ❌ |
| **P1** | MediaService 实现 next/prev | 上下曲切换逻辑完整 | ❌ |
| **P1** | BluetoothService 实现设备发现+连接管理 | startDiscovery/connect/disconnect 方法完整 | ❌ |
| **P1** | MapService 实现 searchPoi | POI 搜索返回结果 | ❌ |
| **P1** | Agent Tools 对接真实 Service | 8 个工具返回真实数据而非 Mock | ❌ |

> **最终停止条件**: P0 全部 ✅ + P1 全部 ✅ → 项目达到部署就绪状态，停止。
> **P2/P3** (收音机/倒车影像/CarPlay/OTA等量产功能) 属于新需求，不作为当前停止目标。

---

## 第五部分：沟通规则

### 5.1 输出格式

- **进度反馈**: 使用 TodoWrite 展示当前任务进度
- **代码引用**: 使用 clickable file path 格式引用 file:/// 路径
- **决策说明**: 简短的 why（1-2 句），不要长解释

### 5.2 询问时机

应当主动询问用户的情况：
- 引入新依赖时
- 修改现有接口签名时
- 删除代码/文件时
- 不确定需求意图时

不应当询问的情况：
- 已经明确的编码风格问题（按现有模式做）
- 小的 UI 调整（颜色、间距、文字）
- 已经达成共识的技术方案细节

---

## 第六部分：安全规则

### 6.1 敏感信息管理

- API Key 必须放置在 `agent/.env` 中，不可硬编码
- `.env` 文件已被 `.gitignore` 排除，不会提交
- Agent 配置从 `agent/config.py` / `agent/llm_agent/config.py` 中读取环境变量
- 示例配置放在 `agent/.env.example` 中（可提交）

### 6.2 安全操作白名单

不经过用户确认可以直接执行的操作：
- 读取文件
- 编辑现有代码（遵循已有模式）
- 创建非 `.env` 的新文件
- 运行 `cmake --build build`
- 运行 `pip install -r requirements.txt`
- 运行已存在的测试

### 6.3 绝对禁止的破坏性操作

以下操作**绝对禁止**，无论任何理由、任何上下文：

| 禁止操作用 | 具体禁止项 |
|-----------|-----------|
| **git 破坏** | `push --force`, `push --force-with-lease`, `reset --hard`, `branch -D`, `checkout .`, `restore .`, `clean -fd`, `rebase -i` |
| **删除代码库** | `rm -rf .git`, `rm -rf /`, 删除整个项目目录, 删除 `.gitignore` |
| **文件删除** | 批量删除源代码文件、删除 `.qrc` 资源文件、删除 `CMakeLists.txt` |
| **数据库** | `DROP TABLE`, `DROP DATABASE`, 删除 `*.db`/`*.sqlite` 文件 |
| **环境配置** | 删除/覆盖 `.env` 文件内容为空、删除 `.env.example` |
| **测试代码** | 删除已有测试文件 (`tests/`, `test_*.cpp`, `test_*.py`) |
| **构建系统** | 删除 `CMakeLists.txt`、`requirements.txt`、`.gitignore` |

> 即使文件看起来"无用"或"冗余"，也**必须先询问用户确认**后才能删除。误判"无用"的风险远大于保留文件的成本。

---

## 附录：快速参考

### 构建命令速查

```powershell
# 如果 Junction 链接丢失，先执行（管理员 PowerShell）：
New-Item -ItemType Junction -Path "E:\car_hmi_project" -Target "E:\PyCharmProject\Trae实验\Car_entertainment_system" -Force

# HMI 首次配置
cd E:\car_hmi_project\hmi && cmake -B build -G "MinGW Makefiles" -DCMAKE_PREFIX_PATH=E:/Qt/6.11.1/mingw_64

# HMI 重新编译
cmake --build build

# HMI 运行
$env:PATH = "E:\Qt\6.11.1\mingw_64\bin;$env:PATH" && .\build\car_hmi.exe

# Agent 启动
cd agent && python server.py

# Agent 测试
python -s -m pytest tests/agent_tests/ -v

# 生成 MOC 文件（新增 Q_OBJECT 类后）
E:\Qt\6.11.1\mingw_64\bin\moc.exe src/infrastructure/xxx.h -o src/infrastructure/moc_xxx.cpp
```

### 项目路径
- 真实路径: `E:\PyCharmProject\Trae实验\Car_entertainment_system`
- 编译路径（Junction）: `E:\car_hmi_project`
- Qt 路径: `E:\Qt\6.11.1\mingw_64`
- MinGW 路径: `E:\MinGW-w64\mingw64\bin`
