param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("status", "capabilities", "target", "list", "show", "prepare-update", "inspect", "validate", "install", "remove", "start", "latest", "debug", "next", "stop")]
    [string]$Action,
    [string]$Target,
    [string]$Executable,
    [string]$DevelopmentRoot = (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "屏幕自动化小助手\流程开发"),
    [int]$Count,
    [int]$Limit = 10,
    [double]$Timeout = 30
)

$ErrorActionPreference = "Stop"

function Resolve-HelperExecutable {
    param([string]$RequestedPath)

    $candidates = [System.Collections.Generic.List[string]]::new()
    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        $candidates.Add($RequestedPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($env:SCREEN_AUTOMATION_HELPER_EXE)) {
        $candidates.Add($env:SCREEN_AUTOMATION_HELPER_EXE)
    }

    $environmentKey = "HKCU:\Environment"
    if (Test-Path -LiteralPath $environmentKey) {
        $registeredEnvironment = (Get-ItemProperty -LiteralPath $environmentKey -Name "SCREEN_AUTOMATION_HELPER_EXE" -ErrorAction SilentlyContinue).SCREEN_AUTOMATION_HELPER_EXE
        if (-not [string]::IsNullOrWhiteSpace($registeredEnvironment)) {
            $candidates.Add($registeredEnvironment)
        }
    }

    $appPathKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\ScreenAutomationHelper.exe"
    if (Test-Path -LiteralPath $appPathKey) {
        $registeredAppPath = (Get-Item -LiteralPath $appPathKey).GetValue("")
        if (-not [string]::IsNullOrWhiteSpace($registeredAppPath)) {
            $candidates.Add([string]$registeredAppPath)
        }
    }

    $uninstallKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{F174BA6D-570B-4F87-A453-84AA66C4A0CB}_is1"
    if (Test-Path -LiteralPath $uninstallKey) {
        $installLocation = (Get-ItemProperty -LiteralPath $uninstallKey -ErrorAction SilentlyContinue).InstallLocation
        if (-not [string]::IsNullOrWhiteSpace($installLocation)) {
            $candidates.Add((Join-Path $installLocation "ScreenAutomationHelper.exe"))
        }
    }

    $candidates.Add((Join-Path $env:LOCALAPPDATA "Programs\Xiaozs\ScreenAutomationHelper\ScreenAutomationHelper.exe"))

    $command = Get-Command "ScreenAutomationHelper.exe" -ErrorAction SilentlyContinue
    if ($null -ne $command -and -not [string]::IsNullOrWhiteSpace($command.Source)) {
        $candidates.Add($command.Source)
    }

    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }
        $fullPath = [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($candidate))
        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            return $fullPath
        }
    }

    throw '未找到屏幕自动化小助手 Windows。请先安装并启动桌面端；如安装在特殊位置，可设置 SCREEN_AUTOMATION_HELPER_EXE，或使用 -Executable 指定程序路径。'
}

function Require-Target {
    param([string]$Value, [string]$ActionName)
    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "操作 $ActionName 需要提供 -Target。"
    }
}

$resolvedExecutable = Resolve-HelperExecutable -RequestedPath $Executable

switch ($Action) {
    "status" {
        $desktopStatus = (& $resolvedExecutable cli status | Out-String | ConvertFrom-Json)
        [ordered]@{
            ok = $true
            executable = $resolvedExecutable
            desktop = $desktopStatus
        } | ConvertTo-Json -Depth 12
    }
    "capabilities" { & $resolvedExecutable cli capabilities }
    "target" {
        if ($Timeout -le 0) {
            throw "等待时间必须大于 0 秒。"
        }
        & $resolvedExecutable cli window wait-selection --timeout $Timeout
    }
    "list" { & $resolvedExecutable cli workflow list }
    "show" {
        Require-Target -Value $Target -ActionName $Action
        & $resolvedExecutable cli workflow show $Target
    }
    "prepare-update" {
        Require-Target -Value $Target -ActionName $Action
        $workflow = (& $resolvedExecutable cli workflow show $Target | Out-String | ConvertFrom-Json)
        $source = [string]$workflow._meta.package_dir
        if ([string]::IsNullOrWhiteSpace($source) -or -not (Test-Path -LiteralPath $source -PathType Container)) {
            throw "无法取得自动化流程 $Target 的已安装程序包目录。"
        }

        New-Item -ItemType Directory -Path $DevelopmentRoot -Force | Out-Null
        $safeId = ([string]$workflow.id) -replace '[^A-Za-z0-9._-]', '-'
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $destination = Join-Path $DevelopmentRoot "$safeId-$stamp"
        New-Item -ItemType Directory -Path $destination | Out-Null
        Get-ChildItem -LiteralPath $source -Force | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $destination -Recurse -Force
        }

        [ordered]@{
            ok = $true
            action = "prepare-update"
            workflow_id = $workflow.id
            current_version = $workflow.version
            development_path = $destination
            instruction = "只修改 development_path 中的副本；完成后提升版本号，再执行 inspect、install 和受监督验收。"
        } | ConvertTo-Json -Depth 8
    }
    "inspect" {
        Require-Target -Value $Target -ActionName $Action
        & $resolvedExecutable cli workflow inspect $Target
    }
    "validate" {
        Require-Target -Value $Target -ActionName $Action
        if (Test-Path -LiteralPath $Target) {
            & $resolvedExecutable cli workflow inspect $Target
        } else {
            & $resolvedExecutable cli workflow validate $Target
        }
    }
    "install" {
        Require-Target -Value $Target -ActionName $Action
        & $resolvedExecutable cli workflow install $Target
    }
    "remove" {
        Require-Target -Value $Target -ActionName $Action
        & $resolvedExecutable cli workflow remove $Target
    }
    "start" {
        Require-Target -Value $Target -ActionName $Action
        $startArgs = @("cli", "start-workflow", $Target)
        if ($PSBoundParameters.ContainsKey("Count")) {
            $startArgs += @("--count", $Count)
        }
        & $resolvedExecutable @startArgs
    }
    "latest" {
        & $resolvedExecutable cli latest --limit $Limit
    }
    "debug" {
        Require-Target -Value $Target -ActionName $Action
        & $resolvedExecutable cli start-workflow $Target --debug --step-mode
    }
    "next" { & $resolvedExecutable cli debug-next }
    "stop" { & $resolvedExecutable cli stop }
}
exit $LASTEXITCODE
