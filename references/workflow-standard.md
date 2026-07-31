# 自动化流程开发标准

本文定义“屏幕自动化小助手”可安装流程的结构、平台能力、安全边界和验收要求。创建、修改或修复流程时以本文和当前安装版本的 `cli capabilities` 为准。

## 目录

- [流程目录](#流程目录)
- [流程描述文件](#流程描述文件)
- [用户可见说明](#用户可见说明)
- [自动化流程上下文](#自动化流程上下文)
- [目标窗口与屏幕区域](#目标窗口与屏幕区域)
- [CLI 基础能力](#cli-基础能力)
- [屏幕识别与定位](#屏幕识别与定位)
- [结果保存与停止](#结果保存与停止)
- [安全与验收](#安全与验收)

## 流程目录

对用户统一称“自动化流程”。实现文件属于 Agent 和小助手管理的内部内容，不作为普通用户的操作入口。

```text
my-workflow/
├── workflow.json
├── workflow.py
└── assets/
    └── target.png
```

流程标识使用 3–64 位小写字母、数字和连字符。版本使用语义化版本。模板图片等资源放在流程目录内并使用相对路径。

## 流程描述文件

```json
{
  "schema_version": 1,
  "id": "my-screen-workflow",
  "name": "示例自动化流程",
  "version": "1.0.0",
  "target": {"os": "windows", "surface": "desktop"},
  "permissions": ["screen.read"],
  "runner": {
    "type": "python-sdk",
    "entry": "workflow.py",
    "sdk": "1.x"
  },
  "presentation": {
    "summary": "用一句自然语言说明这个流程完成什么",
    "steps": ["准备目标界面", "识别并处理内容", "保存结果"]
  },
  "outputs": {
    "format": "markdown-table",
    "columns": [
      {"key": "result", "label": "结果"},
      {"key": "executed_at", "label": "执行时间"}
    ]
  }
}
```

`python-sdk` 是内部运行器标识，不是面向用户的产品名称。坐标、区域和具体页面规则属于流程，不得写入平台公共代码。

## 用户可见说明

每个流程必须提供：

- `presentation.summary`：说明流程完成什么；
- `presentation.steps`：按顺序说明用户会看到的主要步骤；
- 权限：只声明完成任务所需的最低能力；
- 输出：说明结果字段和保存位置；
- 版本：支持升级和回退。

Windows 应用展示自然语言说明，不向普通用户展示内部实现文件或运行器名称。

## 自动化流程上下文

流程入口：

```python
def run(ctx):
    ctx.stop.check()
    yield {
        "result": "完成",
        "executed_at": ctx.clock.now_text(),
    }
```

平台提供：

- `ctx.window`：可见窗口、目标窗口选择；
- `ctx.geometry`：配置区域和坐标；
- `ctx.screen`：截屏、轮廓、颜色和模板定位；
- `ctx.ocr`：读取文字、查找文字元素；
- `ctx.mouse`、`ctx.keyboard`：经过权限检查的屏幕操作；
- `ctx.clipboard`：剪贴板读写；
- `ctx.overlay`、`ctx.app`：区域提示和隔离网页窗口；
- `ctx.wait`、`ctx.stop`：等待与协作停止；
- `ctx.debug`、`ctx.log`：调试状态和日志；
- `ctx.history`、`ctx.output`、`ctx.clock`：查重、结果和时间。

不得自行初始化屏幕操作工具、识别引擎、输出文件、停止信号、子进程、系统命令或网络下载。每个循环和等待都必须响应 `ctx.stop.check()`。

## 目标窗口与屏幕区域

执行屏幕识别前，默认先告诉用户“小助手将用虚线框标出可选窗口，提示显示 10 秒；期间鼠标和键盘可以正常使用”，随后立即运行：

```powershell
.\scripts\workflow_dev.ps1 -Action target
```

该动作分析屏幕上实际可见的窗口区域，排除 Agent 对话窗口和小助手自身。只有一个候选时自动确认；多个候选时同时显示带编号的虚线框，最多显示 10 秒。提示层完全不接管鼠标和键盘。若期间某个候选窗口成为前台窗口，则使用返回的 `client_region`；否则根据候选列表继续确认，不得猜测目标。

仅在用户无法切换前台或需要处理多个窗口关系时，使用高级窗口命令：

```powershell
& $helperExe cli window list-visible
& $helperExe cli window select --title "目标页面" --process "msedge.exe"
& $helperExe cli window select --handle 123456
```

没有筛选条件时，Agent 对话窗口和小助手自身归为辅助窗口，其他应用窗口优先作为目标候选：

- 唯一候选：自动确认并显示虚线框；
- 多个候选：同时标出实际可见的候选区域 10 秒，提示期间不接管用户输入；
- 没有候选：请用户打开目标窗口；
- 超时：停止，不得猜测。

```powershell
& $helperExe cli window wait-selection --timeout 30
```

用户选择成功后，把返回的 `client_region` 作为截屏、识别、查找和等待的显式区域。`window foreground` 只查询当前状态，不代表任务目标。

流程内部对应：

```python
target = ctx.window.select(title="目标页面", process="msedge.exe")
if target["status"] == "needs_user_selection":
    target = ctx.window.wait_for_selection(timeout=30)
if target["status"] != "selected":
    return
region = target["selected"]["client_region"]
```

所有区域统一使用 `left,top,right,bottom`，所有点统一使用 `x,y`。

## CLI 基础能力

CLI 是 Agent 调用小助手本地能力的标准入口，用于流程开发、步骤验证、状态确认和故障诊断。先运行：

```powershell
& $helperExe cli status
& $helperExe cli capabilities
```

主要命令：

```powershell
& $helperExe cli screen capture --region 100,100,500,300
& $helperExe cli screen recognize --region 100,100,500,300
& $helperExe cli screen find --text "确定" --region 100,100,500,300
& $helperExe cli screen wait --text "加载完成" --region 100,100,500,300 --timeout 10
& $helperExe cli screen contours --region 100,100,500,500
& $helperExe cli screen color-regions --region 100,100,500,500 --lower-hsv 70,35,45 --upper-hsv 125,255,255
& $helperExe cli screen match --template target.png --region 100,100,900,800 --threshold 0.85
& $helperExe cli mouse position
& $helperExe cli mouse move --point 300,240
& $helperExe cli mouse click --point 300,240 --button left
& $helperExe cli mouse scroll --point 700,700 --amount -900
& $helperExe cli keyboard hotkey ctrl c
& $helperExe cli keyboard write --text "hello"
& $helperExe cli clipboard read
& $helperExe cli clipboard write --text "待粘贴内容"
& $helperExe cli result write --workflow <流程标识> --data-file result.json
& $helperExe cli result latest --workflow <流程标识> --limit 10
```

涉及点击、输入、滚动或覆盖剪贴板前，必须确认操作与用户目标一致。不得调用小助手之外的屏幕操作工具绕过权限和过程提示。

## 屏幕识别与定位

按稳定性组合使用：

1. 目标窗口和客户区域；
2. 页面文字及其边界；
3. 轮廓、尺寸和相对布局；
4. 颜色区域；
5. 同一缩放比例下的模板图片；
6. 操作前后的页面状态变化。

流程需要轮廓、颜色或模板定位时，使用：

```python
ctx.screen.contours(...)
ctx.screen.color_regions(...)
ctx.screen.match(...)
```

不得直接导入图像处理库或自行截屏。模板匹配不等同于人物或任意物体的语义识别。文字识别、颜色、轮廓和模板均可能受界面缩放、主题、遮挡和软件更新影响，重要操作必须组合状态验证。

读取屏幕前，小助手按照全局设置显示区域提示，默认 1 秒、颜色 `#33cccc`。只有用户在桌面应用设置中关闭后才不显示，单个流程不得绕过。

需要主动说明区域时：

```python
ctx.app.show_screen_region(
    region,
    label="即将读取的区域",
    seconds=2.5,
    color="#33cccc",
)
```

CLI：

```powershell
& $helperExe cli overlay show --region 100,100,500,300 --label "目标区域" --seconds 2.5
```

Agent 已获得多个明确坐标时，使用一个命令同时显示全部虚线框：

```powershell
& $helperExe cli overlay show-many `
  --item "100,100,500,300|窗口一" `
  --item "600,120,1000,520|窗口二" `
  --seconds 10 `
  --color "#33cccc"
```

`--item` 可重复任意次数，格式为 `left,top,right,bottom|标签`。不要连续调用多个 `overlay show` 模拟多区域提示。

## 隔离网页窗口

打开指定网址或本地信息页时，使用：

```python
ctx.app.open_webview(
    url,
    x=0,
    y=0,
    width=860,
    height=680,
)
```

CLI：

```powershell
& $helperExe cli webview open "https://www.xiaozs.com/sah/" --title "产品介绍" --x 0 --y 0 --width 860 --height 680
```

`x` 与 `y` 必须同时提供，也可以使用 `--position top-left` 或 `--position center`。网页窗口使用隔离环境，不读取用户现有浏览器账号、Cookie、历史记录或同步数据。需要登录时由用户在隔离窗口中明确完成。

## 结果保存与停止

流程必须通过 `yield` 或 `ctx.output` 按声明字段逐条保存结果，不得自行打开并重写公共结果文件。平台为不同流程使用独立输出文件，并在异常时备份和恢复有效表头。

长等待、滚动和批量循环必须周期性检查：

```python
ctx.stop.check()
ctx.wait.seconds(1.0)
```

失败分为：

- 当前项目不确定：记录后跳过；
- 页面状态不符：停止当前分支；
- 权限、结构或配置错误：终止流程并报告；
- 用户停止：立即协作退出，不再执行后续操作。

## 安全与验收

只有同时满足以下条件，才可安装并首次真实运行：

- 用户说明用途、目标软件、数据来源、输出和禁止动作；
- 用户拥有目标页面、账号、数据及操作行为所需权限；
- 目标窗口和页面状态可验证；
- 流程只声明最低必要权限；
- 所有屏幕操作都有目标标志或状态依据；
- 读取区域提供可见提示；
- 循环、等待和批量处理响应停止；
- 不确定分支不会继续盲目操作；
- 网页窗口使用隔离环境；
- 验证码、授权、支付、发布和删除保留给用户；
- 安装前展示来源、版本、步骤、权限和输出；
- 首次真实运行由用户监督；
- 结果经过用户确认并记录验收状态。

任一条件无法确认时，保持只读预览、停止开发或请用户补充信息，不得标记为已验收。
