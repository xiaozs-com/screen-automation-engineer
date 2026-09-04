param(
    [string]$Version = "1.1.16",
    [switch]$ChineseName
)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
$distDir = Join-Path $repoRoot "dist"
$packageSuffix = if ($ChineseName) { "-skillhub-cn" } else { "" }
$zipPath = Join-Path $distDir "screen-automation-engineer-$Version$packageSuffix.zip"
$skillhubDir = Join-Path $env:USERPROFILE ".skillhub"
$skillhubCli = Join-Path $skillhubDir "skills_store_cli.py"
$packBridge = Join-Path $repoRoot "tools\skillhub_pack.py"
$stagingDir = Join-Path ([System.IO.Path]::GetTempPath()) ("screen-automation-engineer-package-" + [guid]::NewGuid().ToString("N"))

if (-not (Get-Command skillhub -ErrorAction SilentlyContinue)) {
    throw "未找到 SkillHub CLI：skillhub"
}
if (-not (Test-Path -LiteralPath $skillhubCli -PathType Leaf)) {
    throw "未找到 SkillHub CLI 程序：$skillhubCli"
}

try {
    New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot "SKILL.md") -Destination $stagingDir
    foreach ($name in @("agents", "references", "scripts")) {
        Copy-Item -LiteralPath (Join-Path $repoRoot $name) -Destination $stagingDir -Recurse
    }

    if ($ChineseName) {
        # SkillHub 市场沿用中文 name；仅改临时副本，源码仍保持跨平台 kebab-case 标识。
        $skillPath = Join-Path $stagingDir "SKILL.md"
        $skillContent = Get-Content -LiteralPath $skillPath -Raw
        $skillContent = [regex]::Replace(
            $skillContent,
            '(?s)\A(---\r?\n)name:[^\r\n]*(\r?\n)',
            '$1name: 屏幕自动化工程师$2',
            1
        )
        Set-Content -LiteralPath $skillPath -Value $skillContent -Encoding utf8NoBOM
    }

    & skillhub publish $stagingDir --version $Version --dry-run --json
    if ($LASTEXITCODE -ne 0) {
        throw "SkillHub 源目录预检失败"
    }

    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
    & python $packBridge $skillhubCli $stagingDir $zipPath
    if ($LASTEXITCODE -ne 0) {
        throw "SkillHub ZIP 生成失败"
    }

    & skillhub publish $zipPath --version $Version --dry-run --json
    if ($LASTEXITCODE -ne 0) {
        throw "SkillHub ZIP 预检失败"
    }

    Get-Item -LiteralPath $zipPath
    Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath
}
finally {
    if (Test-Path -LiteralPath $stagingDir) {
        Remove-Item -LiteralPath $stagingDir -Recurse -Force
    }
}
