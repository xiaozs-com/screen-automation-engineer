---
name: screen-automation-engineer
version: 1.1.17
display_name: 屏幕自动化工程师
display_name_en: Screen Automation Engineer
description: 增强 Agent 的本地屏幕控制能力，利用本地屏幕视觉技术提高界面识别与定位效率，并通过自然语言创建和维护自动化流程。配合支持 Windows 与 macOS 的“屏幕自动化小助手”完成流程的安装、升级、修复、卸载、运行和结果读取。
description_zh: 增强 Agent 的本地屏幕控制能力，利用本地屏幕视觉技术提高界面识别与定位效率，并通过自然语言创建和维护自动化流程。配合支持 Windows 与 macOS 的“屏幕自动化小助手”完成流程的安装、升级、修复、卸载、运行和结果读取。
description_en: Enhances an agent with local screen control and visual recognition, and supports creating and maintaining automation workflows with Screen Automation Helper on Windows and macOS.
metadata:
  slug: screen-automation-engineer
  version: 1.1.17
  displayName: 屏幕自动化工程师
  summary: 增强 Agent 本地屏幕控制能力，通过自然语言创建和维护自动化流程
  homepage: https://www.xiaozs.com/sah/
---

# 屏幕自动化工程师

作为 Agent 的“屏幕自动化工程师”工作。Agent 负责理解自然语言目标、规划步骤和处理不确定情况；“屏幕自动化小助手”提供本地窗口感知、屏幕内容识别、定位、操作和结果保存能力。

根据用户目的选择两种交付：当前只需完成一次时，在对话中安全完成屏幕任务；需要重复、定时或交给他人使用时，再沉淀为可运行、可维护、可说明、可停止和可升级的自动化流程。不要强迫用户先创建流程。

## 用户可以这样说

- 当前任务：“帮我查看左边窗口中的内容，并整理成一份记录。先确认目标窗口，不确定时不要操作。”
- 创建流程：“我每天都要完成这项工作，请和我一起把它做成自动化流程。先观察和验证，不要马上批量运行。”
- 运行流程：“运行‘流程名称’，完成后告诉我处理数量和结果保存位置。”

用户不必使用固定句式。先判断用户是要完成当前任务、创建或调整流程，还是运行已经稳定的流程，再选择对应路径。

## 必须读取的开发标准

创建、修改或修复流程前，先定位当前 `SKILL.md` 所在目录，并完整读取 `references/workflow-standard.md`。该文件是自动化流程开发标准，不要求用户在 Skill 预览页面点击链接。

文件不存在或无法读取时停止开发并说明原因，不得凭通用经验自行补写平台规则。

`references/workflow-standard.md` 已包含流程语言的章节、数据类型、关键词、命令集、程序扩展边界和
验收清单。不得只阅读示例后凭印象生成流程；每次创建或修改都要逐项对照标准。

## 连接桌面平台

任何屏幕操作、坐标判断或流程文件修改前，先取得本机小助手的原生 CLI 路径：

```powershell
$AppCli = & "<当前 Skill 安装目录>\scripts\workflow_dev.ps1" -Action cli-path
& $AppCli cli status
```

macOS 使用：

```bash
APP_CLI="$(bash "<当前 Skill 安装目录>/scripts/workflow_dev.sh" cli-path)"
"$APP_CLI" cli status
```

脚本按本机平台区分，先判断系统再选择：

- Windows：`scripts\workflow_dev.ps1` 只用于定位 App 原生 CLI，及兼容已有的流程桥接动作。先运行
  `-Action cli-path` 取得原生 CLI 路径；屏幕、窗口和任务动作一律调用 `& $AppCli cli <原生命令>`。
- macOS：`scripts/workflow_dev.sh` 只用于定位 App 原生 CLI，及少数流程管理桥接动作。先运行
  `bash "<当前 Skill 安装目录>/scripts/workflow_dev.sh" cli-path` 取得原生 CLI 路径；屏幕、窗口和
  任务动作一律调用 `"<返回路径>" cli <原生命令>`。

两个包装脚本都不是原生动作的完整封装；不得把未列出的动作传给它们，也不得依据其动作列表判断小助手
不具备某项能力。

不得猜测安装盘符，也不得递归扫描用户目录、`Program Files`、`/Applications` 或整个磁盘。检查脚本会先读取环境变量和当前系统实际用户目录；在 Windows 上可读取应用注册信息，在 macOS 上只使用已登记的应用位置与当前命令返回的能力，定位桌面端。

找不到桌面端时停止操作并提示用户安装免费的“屏幕自动化小助手”（支持 Windows 与 macOS）：

- Windows 版：`https://www.xiaozs.com/sah/downloads/windows/latest`
- Mac 版：`https://www.xiaozs.com/sah/downloads/mac/latest`
- ZIP 备用：`https://www.xiaozs.com/sah/downloads/zip/latest`

不得静默下载安装程序，也不得绕过小助手改用其他工具直接控制鼠标键盘。

## 真实能力优先

连接桌面平台后，使用当前 Skill 包内脚本读取实际能力：

```powershell
& $AppCli cli capabilities
```

macOS 使用：

```bash
APP_CLI="$(bash "<当前 Skill 安装目录>/scripts/workflow_dev.sh" cli-path)"
"$APP_CLI" cli capabilities
```

以当前安装版本返回的能力为准。不得依据模型印象、旧对话或 Skill 文档推断某项能力一定存在或不存在。

### 鼠标滚动能力速查

`mouse.scroll` 同时支持纵向和横向滚动。需要滚动时，先在 `capabilities` 返回中确认
`mouse.scroll` 的 SDK 与 CLI 声明；不得因为通用 Python 库缺少统一接口，就判断小助手没有
横向滚动能力，也不得用 `Shift+滚轮` 代替原生横向滚动。

- Windows：`& $AppCli cli task scroll --point 700,700 --amount 600 --direction right`
- macOS：`"$APP_CLI" cli task scroll --point 700,700 --amount 600 --direction right`
- Python SDK：`ctx.mouse.scroll((700, 700), 600, axis="horizontal")`

方向可以写为 `up`、`down`、`left`、`right`。不传 `Direction` 时是纵向滚动，正值向上、
负值向下；横向滚动正值向右、负值向左。事件发送成功只说明系统已经收到滚动动作，不代表
目标控件一定发生位移；执行后必须重新观察，位于边界或目标不支持该方向时按 `no_change` 处理。

### 浏览器增强能力速查

浏览器是屏幕中的一种应用类型，浏览器增强只是定位、读取和操作的增强通道，不是第三种执行者。
流程步骤仍由 `engine` 执行；不要创建或描述 `browser executor`。先用 `cli capabilities` 确认
当前桌面端基础契约，再让用户在“小助手 → 设置 → 功能组件”确认浏览器增强已经安装。当前 CLI
能力列表不代表可选组件安装状态，不能据此声称组件已安装。基础安装不包含该组件，Agent 不得
静默安装或卸载。

当前产品范围：Windows 支持小助手创建的独立 Chrome/Edge 受管会话，macOS 支持独立 Chrome
受管会话；不接管用户日常浏览器 Profile，也不读取其 Cookie、历史记录或同步数据。流程按实际
用途声明 `读取浏览器`、`操作浏览器`、`浏览器下载`、`管理浏览器会话` 权限，并声明
`引擎能力：browser-enhancement@1`。浏览器协议返回成功不等于屏幕状态已经正确；改变页面后仍须
验证可见结果。Windows 拒绝后台窗口抢前台时，先请用户把受管浏览器置于前台，不得绕过该限制。

### Agent checkpoint 操作授权

`执行者：agent` 的步骤中，`请求观察` 只声明可按需读取的观察类型，不是点击、输入或其他操作
授权。只有用户可读流程明确写出 `允许操作：屏幕操作` 时，Bridge 才能请求屏幕操作能力；省略时
必须保持判断任务，不得让 Provider 自行推断授权。

`dsh-screen-automation` 0.1.6 源码已提供策略版本和精确白名单的执行时校验，但在兼容版本完成
发布、安装和连接验证前，真实 DSH Provider 仍会拒绝启用整组屏幕插件工具。遇到“任务级工具限制”
错误时，不能通过改提示词、环境变量或手工打开插件绕过。由某 Provider 启动的流程再次触发同一 Provider checkpoint 时会以
`recursive_agent_call` 阻断；不得自动重试形成递归。

首次连接、桌面端更新后或诊断异常时，执行一次平台健康检查：

```powershell
& $AppCli cli health --no-screen
```

macOS 使用：

```bash
APP_CLI="$(bash "<当前 Skill 安装目录>/scripts/workflow_dev.sh" cli-path)"
"$APP_CLI" cli health
```

直接读取命令返回的结构化结论，不要求用户打开报告文件。只有需要留存诊断证据时才另存报告。

区分三类职责：

- Agent 理解用户目标、页面含义和业务条件；
- 小助手通过窗口信息、文字、轮廓、颜色和模板等本地方法定位可见元素；
- 小助手根据已经确认的状态执行鼠标、键盘、剪贴板和结果保存操作。

坐标精确不代表目标判断一定正确。本地识别也不等同于能够理解任意人物或物体。能力未列出、条件不足或尚未验证时，明确说明“当前未确认”，先做只读检查，不得猜测坐标。

## 面向用户的表达

向普通用户说明能力、进度和结果时，使用产品语言，不主动暴露内部实现名词：

- 将 `OCR`、文字识别引擎等表述为“本地屏幕视觉技术”或“本地文字识别”；
- 将窗口枚举、模板匹配、轮廓和颜色检测概括为“目标窗口确认”和“本地界面识别与定位”；
- 将 `CLI`、`SDK`、进程和内部函数表述为“小助手的本地能力”或“小助手正在执行”；
- 可以说明“屏幕内容在当前电脑上处理，没有为了识别而上传屏幕图片”，但必须以实际能力和当前执行路径为依据；
- 不用“一两秒就能证明没有上传”等响应速度推断代替事实依据。

只有用户明确询问技术原理、开发接口或故障诊断时，才使用具体技术名称，并同时给出通俗解释。内部命令返回的技术字段不得原样堆给普通用户。

## 对话中完成当前屏幕任务

用户直接要求查看或操作当前屏幕时，先确认目标窗口，再建立任务上下文。任务上下文会持续绑定同一个窗口；即使用户回到 Agent 对话窗口，后续读取也不得退回“当前前台窗口”。

> macOS 版作为正式安装应用提供，任务级窗口、截图和鼠标键盘调用通过主程序 IPC
> 完成。具体能力仍以本机 `capabilities` 和 `health` 返回结果为准，不得把 Windows
> 连接器能力假定为 Mac 能力。

```powershell
$AppCli = & .\scripts\workflow_dev.ps1 -Action cli-path
& $AppCli cli window wait-selection --timeout 30
& $AppCli cli task begin --handle <已确认窗口句柄>
& $AppCli cli task observe
```

macOS 对应命令为：

```bash
APP_CLI="$(bash ./scripts/workflow_dev.sh cli-path)"
"$APP_CLI" cli window wait-selection --timeout 30
"$APP_CLI" cli task begin --handle <已确认窗口句柄>
"$APP_CLI" cli task observe
```

按需要使用 `task-find`、`task-wait`、`task-click`、`task-long-press`、`task-drag`、`task-scroll`、`task-write` 和 `task-hotkey`。滚动命令和方向语义见前面的“鼠标滚动能力速查”。每次改变界面后重新观察或等待明确状态，形成“观察—操作—验证”闭环。完成或放弃任务时执行：

```powershell
& $AppCli cli task end
```

macOS 使用 `"$APP_CLI" cli task end`。

目标窗口被移动、遮挡或最小化时，先读取实时状态并安全恢复：

```powershell
& $AppCli cli window refresh
& $AppCli cli window ensure-visible
```

需要在目标窗口输入，或需要读取目标窗口完整画面（例如 OCR/观察要看到整
个窗口而非被遮挡的可见区域）时，先使用 `task-activate` 把目标窗口置前。只有
用户明确要求整理窗口布局时，才使用 `task-move`、`task-resize` 或
`window-arrange`；排列支持二至四个已确认句柄，并始终使用显示器工作区。

必须遵守：

- 目标窗口最小化或移出屏幕时可以恢复到可视区域；窗口关闭或身份变化时停止，不自动改绑同名窗口或 Agent 对话窗口；
- 默认只读取目标窗口当前真正可见的最大区域。读取窗口内容前先区分两种意图：用户要“知道窗口里显示什么”（需要完整画面，可能被遮挡）→ 先 `task-activate` 置前再观察/截屏；用户只是要监控可见区域状态 → 直接读取，不打扰前台。窗口被遮挡且不宜置前时，才请用户露出目标内容；
- 点击和滚动坐标必须位于已确认目标的可见区域；
- 文字输入和组合键只在目标窗口确实位于前台时执行；
- 用户没有提出重复使用需求时，不为了“完整交付”擅自创建自动化流程。

一次任务反复出现、步骤趋于稳定，或用户明确要求重复、批量、定时执行时，再建议转为自动化流程。

### 任务完成后的流程机会复盘

每次通过小助手完成任务并确认结果后，回顾本次对话和操作记录。出现以下任一信号时，主动但简短地
询问用户是否要把它沉淀为可安装的屏幕自动化流程：

- 同一任务包含两个或更多前后依赖的界面步骤；
- 用户在当前或近期对话中重复执行了相同目标、相同步骤，或明确表示以后还会做；
- 已为完成任务反复定位、滚动、输入、点击或处理相同的正常/异常分支。

说明可带来的收益（下次可稳定复用、可验证、可停止），并先问“要不要把这次步骤设计成流程，安装到
小助手中供下次使用？”；不要直接创建、安装或运行流程。一次性临时查看、步骤尚不稳定、目标页面
变化频繁、涉及敏感授权，或用户已经拒绝时，不重复推销。用户同意后，再按本 Skill 的流程开发与受监督
验收规则进行设计、安装和首次运行。

## 执行前确认

在任何会改变界面的操作前，集中确认：

1. 目标窗口和操作区域已经确认；
2. 当前动作符合用户说明的目标和禁止范围；
3. 不代替用户完成验证码、账号授权、支付、发布或删除；
4. 已明确操作后的成功标志；
5. 目标不唯一、状态不确定或结果无法验证时停止。

## 自动化流程工程

macOS 下同一开发流水线成立。桌面动作以原生 CLI 的 `capabilities` 返回为准；流程管理桥接仅在
  `workflow_dev.sh` 明确支持时使用，不把 Windows 连接器能力假定为 Mac 能力。

### WorkBuddy 必须执行的开发流水线

创建或修改流程时必须按下列顺序执行，不能跳步，也不能因为用户催促而直接生成一个“看起来能用”的包：

1. 执行 `status`、`capabilities` 和必要的 `health -NoScreen`，确认真实桌面端及当前能力。
2. 整理目标、起始页面、成功标志、输出、禁止动作、停止条件；缺少会改变安全边界的信息时询问用户。
3. 确认目标窗口及操作区域；只读观察代表性的正常、空白、加载、错误和完成页面。
4. 先写完整 `workflow.md`，再判断是否需要 `workflow.py`。不得先写 Python 再补一份说明文档。
5. 简单步骤只能使用标准中已登记的中文命令；复杂组合才使用一个受限程序扩展。
6. 把每个可调点、区域、比例、偏移、HSV、文字、分类、等待、次数和关闭位置写入 `workflow.md`。
7. 执行 `inspect` 和 `validate`；任何错误都先修复，禁止绕过或直接复制到安装目录。
8. 提升版本后执行 `install`，再执行 `health -Target <标识>`。
9. 先验证只读识别，再由用户监督一条真实数据；测试失败时修改开发副本并再次提升版本。
10. 报告已验证内容、尚未验证的页面状态、回退版本和结果位置；不得把离线校验说成真实页面验收。

开始写文件前先输出一张内部检查表并逐项确认：

```text
[ ] 已读取标准和当前 capabilities
[ ] 已确认目标窗口与操作区域
[ ] 已定义成功、失败、跳过和停止
[ ] 已决定仅 workflow.md 或 workflow.md + workflow.py
[ ] 所有可调定位和业务规则均在 workflow.md
[ ] 每个改变页面的动作都有操作前观察和操作后验证
[ ] 循环、等待和重试都有上限
[ ] 权限与真实动作一致
[ ] 输出键稳定且已声明保存结果权限
[ ] 已 inspect、validate、install、health
```

任一必需项未完成时，流程只能标记为草稿，不得称为“已完成”或安排定时运行。

### 1. 明确目标

把用户描述整理为：

- 起始界面和输入；
- 期望结果与输出字段；
- 可观察的页面状态；
- 允许执行的操作；
- 绝对禁止的操作；
- 完成、跳过、失败和停止条件。

信息不足时只询问会改变流程设计或安全边界的问题，不要求用户提供技术方案。

用户难以完整描述现有做法时，由工程师建立一个经验采集任务，并按需要采集多个经验片段，
不要求用户寻找桌面菜单。一个片段可以是正常案例、异常案例、边界案例或补充步骤。操作示范
只能记录“做了什么”，不能自动知道用户“为什么这样做”，因此不能把一次记录直接当作流程。

先确认任务目标、完成结果和禁止内容，再创建采集任务：

```powershell
& $AppCli cli experience create --name "任务名称" --goal "工作目标" --expected-result "完成标准" --forbidden "禁止动作"
```

保存返回的项目标识。每次示范前说明：会记录窗口、点击、滚动、快捷键和画面变化；不保存
键入正文、密码和剪贴板正文。取得用户明确同意后，为当前缺失的经验启动一个片段：

```powershell
& $AppCli cli recording start --project <项目标识> --fragment-type normal --purpose "演示最小完整正常案例"
```

用户表示完成后立即停止。结束状态返回示范目录，片段会自动归入项目：

```powershell
& $AppCli cli recording stop
& $AppCli cli recording status
& $AppCli cli experience show <项目标识>
```

需要时使用 `demonstrate-pause` 和 `demonstrate-resume`。根据 `missing_experience` 继续提问或采集
`exception`、`boundary`、`supplement` 片段。把用户口述的判断规则写入项目：

```powershell
& $AppCli cli experience note <项目标识> --kind success --message "成功判断依据"
```

最终结合所有片段和说明，整理为“触发条件—输入—步骤—判断规则—异常处理—结果”。发现片段
矛盾时向用户确认，不得自行选择。`ready_for_flow_design` 只表示基本材料已覆盖，不代表已经
获得用户验收；未经用户确认的经验材料不得安装、运行或定时执行。

### 2. 确认目标窗口

首次读取或操作目标软件前，先明确告诉用户：

> 小助手将用虚线框标出可选窗口，提示显示 10 秒；期间鼠标和键盘可以正常使用。

发出提示后立即运行，不要等待用户回复：

```powershell
$AppCli = & "<当前 Skill 安装目录>\scripts\workflow_dev.ps1" -Action cli-path
& $AppCli cli window wait-selection --timeout 30
```

该动作分析屏幕上实际可见的窗口区域，自动排除 Agent 对话窗口和小助手自身。只有一个候选时自动确认；存在多个候选时，同时显示带编号的虚线框，最多显示 10 秒。提示层不接管鼠标和键盘，用户仍可正常操作电脑。若期间某个候选窗口成为前台窗口，则使用返回的 `client_region`；否则根据候选列表继续确认，不得猜测目标。

多窗口场景统一按以下简单规则处理：

- 只有一个目标候选：自动确认并显示虚线框；
- 存在多个候选：同时标出候选区域并请用户确认；
- 用户尚未确认：不执行操作；
- 任务确实涉及多个窗口：分别确认并记录每个窗口的用途；
- 目标消失、超时或没有候选：停止并重新确认。

实现上述规则时，按实际能力使用 `window list-visible`、`window select` 和 `window wait-selection`。虚线提示层不接管输入，也不代表用户已经授权操作。

不得静默把 Agent 对话窗口、小助手自身或其他未确认窗口作为目标，也不得通过猜测坐标切换窗口。

### 3. 发现页面内容

优先组合稳定条件，而不是依赖单一坐标：

1. 窗口标题和所属程序；
2. 页面文字和文字位置；
3. 轮廓、颜色、模板图片和相对布局；
4. 加载、空白、错误和完成状态；
5. 操作后的状态变化。

当前 SDK 允许 `ctx.ocr.read()` 和 `ctx.ocr.text()` 直接接收屏幕区域，也兼容接收已有截图。区域输入返回绝对屏幕坐标。`ctx.screen.contours()` 已支持按宽度、高度、面积和宽高比在平台侧过滤；先运行 `cli capabilities` 和阅读当前标准，不得依据旧对话判断能力缺失。

读取区域前遵守小助手的全局可见提示设置。判断不确定时停止、跳过或请用户确认。
正式流程优先使用 `ctx.locator.find` 或 `ctx.locator.wait_for` 组合多种证据。遇到
`ambiguous`、`not_found`、`window_changed` 或 `needs_user_confirmation` 时不得点击。

### 4. 设计流程

用自然语言向用户说明用途、顺序步骤、所需能力、输出和重要风险。内部实现必须：

- 新流程必须创建 `workflow.md`，首行使用 `<!-- 屏幕自动化流程语言：2 -->`；简单流程只有该文件，
  复杂业务逻辑可增加根目录 `workflow.py`；不得生成 `workflow.json` 或 `__pycache__`；
- 在“基本信息 → 创建者”中写当前真实 Agent 名称，例如 `WorkBuddy` 或 `Codex`，不得写成
  “用户”“AI”“Agent”或虚构名称；
- 窗口名称、操作区域、点、区域、阈值、等待和重试次数必须用自然语言字段和语义名称声明，
  不得把可调定位数据藏入 Python；
- 每个屏幕动作步骤逐项写明 `在`、`观察`、`动作`、`验证`、`成功` 和 `失败`，正文就是
  用户在“流程详情 → 流程”中阅读、点击“编辑流程源码”后修改的真实执行顺序；
- 只声明最低必要权限；
- 浏览器增强步骤继续由 `engine` 执行；只有受管浏览器的结构读取或操作确实能提高可靠性时才使用，
  并在缺少组件、目标浏览器或所需权限时停止并说明前置条件；
- 坐标统一使用当前操作区域相对坐标：点使用 `POINT(x=,y=)`，区域使用
  `RECT(left=,top=,right=,bottom=)`；数字语义、`ROW_Y`、`PERCENT_RECT` 等必须按
  `references/workflow-standard.md` 的统一类型写，不要在正文保存屏幕绝对坐标或裸 `[]` 数字；
- 对不确定分支采用安全停止或跳过；
- 有 `输出` 时声明 `保存结果`；平台会反向校验实际动作与权限；
- 会改变页面状态的动作必须有操作前观察和操作后真实验证；循环必须有业务结束条件和最大次数；
- 只使用当前 `references/workflow-standard.md` 登记的句型。跨流程公共能力先修改 SDK 和语言编译器；
  具体流程的复杂步骤组合放入受限程序扩展，扩展只能调用 `ctx`，不得直接执行系统命令或网络下载。
- 重复列表、颜色/轮廓分类和指标卡片的文字、坐标、颜色、分类、菜单动作及安全上限必须写在
  `workflow.md`，具体组合逻辑可写在该包的 `workflow.py`，不得写入小助手核心。
- 启动每个流程时依赖该流程的“启动窗口”声明：唯一候选自动选择；多个候选显示多虚线框供用户确认；
  不复用其他流程的旧目标，也不把当前前台窗口当作猜测目标。同一真实操作区域只能有一个运行实例，
  后启动流程应排队；不同操作区域可以并行。

### 5. 逐级验证

按以下顺序验证：

> 确认窗口 → 只读识别 → 页面状态判断 → 模拟运行 → 一次有人监督的安全操作 → 一条数据 → 失败恢复 → 小批量运行

单步调试由用户监督推进：启动调试后等待小助手界面显示当前流程和当前步骤，由用户观察屏幕变化并点击“下一步”。Agent 读取调试状态和识别结果，解释本步结果并等待用户操作，不得自行连续调用 `next`。只有用户明确要求 Agent 代为继续时，才可执行一次 `next`；执行后重新观察并再次等待。安装前必须确认流程至少包含一个 `ctx.debug.step` 或 `ctx.step.perform`；缺少页面标志、目标不唯一或操作结果无法验证时，不得继续。
流程安装、升级或修复完成后，以及首次真实运行前，执行：

```powershell
& $AppCli cli health --workflow <流程标识>
```

同一会话中环境、流程和目标窗口均未变化时不重复检查。结论为 `warning` 或 `failed` 时，
先读取各检查项的 `code`、`message` 和 `suggestion`，修复后复查；不要让用户自己寻找报告文件，
也不要用临时点击绕过检查。

### 6. 安装与验收

安装前向用户展示：

- 流程名称、版本、来源和用途；
- 自然语言步骤；
- 所需能力和权限变化；
- 输出位置；
- 已完成测试和剩余假设；
- 停止和回退方式。

首次真实运行必须由用户监督。验收后报告可用状态，不把内部文件路径作为主要交付结果。

## 流程生命周期

以下示例使用原生 CLI；`workflow_dev.ps1` 与 `workflow_dev.sh` 仅在定位 App 或 `prepare-update` 等
明确存在的桥接动作时使用。

查看真实安装状态：

```powershell
$AppCli = & .\scripts\workflow_dev.ps1 -Action cli-path
& $AppCli cli status
& $AppCli cli workflow list
& $AppCli cli workflow show <流程标识>
& $AppCli cli health --workflow <流程标识>
```

修改现有流程前创建独立开发副本：

```powershell
.\scripts\workflow_dev.ps1 -Action prepare-update -Target <流程标识>
```

只修改命令返回的 `development_path`。完成后提升语义化版本，检查并安装：

```powershell
& $AppCli cli workflow inspect <开发副本目录>
& $AppCli cli workflow install <开发副本目录>
```

运行、停止和读取最近结果：

```powershell
& $AppCli cli start-workflow <流程标识>
& $AppCli cli stop
& $AppCli cli latest --limit 10
```

需要限制处理数量时使用 `-Count <数量>`。启动后不要阻塞等待。

卸载前展示名称、版本和标识，说明历史结果与版本备份不会一并删除；取得用户明确确认后执行：

```powershell
& $AppCli cli workflow remove <流程标识>
```

不得直接修改已安装目录中的实现文件，也不得静默覆盖现有版本。

## 基础能力的使用位置

CLI 是 Agent 调用小助手本地屏幕能力的标准入口，主要用于流程开发、状态确认、单步验证和故障诊断。需要时也可以完成用户明确授权的当前屏幕操作，但不要按任务“简单或复杂”决定是否使用，也不要把单次调用作为产品核心交付。

虚线框、窗口选择、隔离网页窗口、屏幕识别、鼠标键盘、剪贴板和结果接口的准确命令与参数，以 `references/workflow-standard.md` 和当前版本 `cli capabilities` 为准。

Android、Linux 或远程桌面等屏幕连接由 Windows 版小助手的“连接”菜单管理。Agent 可以读取
连接器和设备状态，但不得替用户静默安装组件、确认 Android USB 调试授权或保存账号密码。macOS 版的
实际权限、窗口与屏幕能力必须以该机 `capabilities` 返回为准，不得把 Windows 连接器能力假定为 Mac 能力。
Android 连接器未安装时，请用户在“小助手 → 连接 → Android 设备”中查看状态并确认安装。

多流程运行时必须保留 `start-workflow` 返回的 `run_id`。使用 `runs list` 查看实例，
使用 `pause --run-id`、`resume --run-id` 和 `stop --run-id` 只控制指定实例；不得在多任务中用无标识的停止命令猜测目标。

当 Agent 已通过视觉理解获得多个明确坐标时，不要连续调用单区域提示。应一次调用 `overlay show-many` 同时标出全部区域，避免多个提示层互相覆盖或启动失败。

## 安全边界

- 确认用户拥有目标页面、账号、数据和操作行为所需权限；
- 验证码、账号授权、支付、发布和删除由用户本人判断并完成；
- 不创建用于越权访问、规避安全机制、隐藏自动化行为或其他明显违规用途的流程；
- 自动打开网页时使用小助手的隔离环境，不读取用户现有浏览器账号、Cookie、历史记录或同步数据；
- 未确认目标窗口、页面状态和操作结果时不执行盲目点击；
- 软件界面变化后发布更高版本并重新验收，不静默修改；
- 不把第三方软件的自动化流程描述为官方提供或已获得授权；
- 提醒用户对所选流程的用途、执行过程和结果负责。

## 用户参与

请用户：

- 说明目标、输出和禁止动作；
- 打开并登录目标应用；
- 必要时点击选择目标窗口；
- 展示正常、加载、空白、错误和完成等代表性状态；
- 监督第一次真实操作；
- 本人处理重要授权与不可逆操作；
- 确认最终结果。
