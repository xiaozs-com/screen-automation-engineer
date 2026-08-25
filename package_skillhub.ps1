param(
    [string]$Version = "1.1.6"
)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
$distDir = Join-Path $repoRoot "dist"
$zipPath = Join-Path $distDir "screen-automation-engineer-$Version.zip"
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
