# install.ps1 — ai-coding-kit 安装器（Windows / PowerShell 5.1+）
# 语义：把 kit 单一源（skills/ + rules/）转换为目标 IDE 布局；只转格式不改语义。
# 同名文件跳过不覆盖并报告；CLAUDE.md 以标记块幂等替换；模板仅在 -WithTemplates 且目标缺失时生成。
# 用法示例：
#   powershell -NoProfile -ExecutionPolicy Bypass -File ai-coding-kit\adapters\install.ps1 -Ide qoder
#   powershell -NoProfile -ExecutionPolicy Bypass -File ai-coding-kit\adapters\install.ps1 -Ide claude-code -Stack python -WithTemplates
#   powershell -NoProfile -ExecutionPolicy Bypass -File ai-coding-kit\adapters\install.ps1 -Ide cursor -DryRun -Target D:\some-project

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('qoder', 'cursor', 'claude-code')]
    [string]$Ide,

    [string]$Stack = 'java,vue',

    [switch]$WithTemplates,

    [switch]$DryRun,

    [string]$Target
)

$ErrorActionPreference = 'Stop'

$KitRoot = Split-Path -Parent $PSScriptRoot
if (-not $Target) { $Target = Split-Path -Parent $KitRoot }
$Target = (Resolve-Path -LiteralPath $Target).Path

$SelectedStacks = @($Stack -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
foreach ($s in $SelectedStacks) {
    if ($s -notin @('java', 'vue', 'python')) {
        throw "非法栈名 '$s'：-Stack 仅支持 java,vue,python 的逗号列表"
    }
}

$Report = [ordered]@{ copied = @(); skipped = @(); planned = @() }

function Write-Utf8NoBom([string]$Path, [string]$Text) {
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($false)))
}

function Read-Text([string]$Path) {
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

# 解析 kit frontmatter：返回 @{ Meta = 哈希表（列表值为数组）; Body = 正文 }
function Split-Frontmatter([string]$Text) {
    $lines = $Text -split "`r?`n"
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') {
        return @{ Meta = @{}; Body = $Text }
    }
    $meta = @{}
    $currentKey = $null
    $i = 1
    while ($i -lt $lines.Count -and $lines[$i].Trim() -ne '---') {
        $line = $lines[$i]
        if ($line -match '^\s+-\s+(.+)$' -and $currentKey) {
            $meta[$currentKey] = @($meta[$currentKey]) + $matches[1].Trim().Trim('"')
        }
        elseif ($line -match '^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$') {
            $currentKey = $matches[1]
            $val = $matches[2].Trim()
            if ($val -eq '') { $meta[$currentKey] = @() } else { $meta[$currentKey] = $val.Trim('"') }
        }
        $i++
    }
    $body = ''
    if ($i + 1 -lt $lines.Count) { $body = ($lines[($i + 1)..($lines.Count - 1)]) -join "`n" }
    return @{ Meta = $meta; Body = $body }
}

# 落盘一个产物：已存在→skipped；DryRun→planned；否则写入→copied
function Install-Content([string]$Dest, [string]$Content) {
    if (Test-Path -LiteralPath $Dest) {
        $Report.skipped += $Dest
        return
    }
    if ($DryRun) {
        $Report.planned += $Dest
        return
    }
    Write-Utf8NoBom -Path $Dest -Text $Content
    $Report.copied += $Dest
}

# Cursor mdc frontmatter 转换（只转格式不改语义；不携带 kit 自定义 stack 键）
function ConvertTo-CursorMdc([hashtable]$Meta, [string]$Body) {
    $trigger = [string]$Meta['trigger']
    $desc = [string]$Meta['description']
    $fm = @('---')
    if ($trigger -eq 'always_on') {
        if ($desc) { $fm += "description: $desc" }
        $fm += 'alwaysApply: true'
    }
    elseif ($trigger -eq 'model_decision') {
        $fm += "description: $desc"
        $fm += 'alwaysApply: false'
    }
    elseif ($trigger -eq 'glob') {
        $fm += "description: $desc"
        $fm += 'globs:'
        foreach ($g in @($Meta['glob'])) { $fm += "  - `"$g`"" }
        $fm += 'alwaysApply: false'
    }
    else {
        throw "未知 trigger '$trigger'，无法转换为 Cursor mdc"
    }
    $fm += '---'
    return (($fm -join "`n") + "`n" + $Body)
}

$SkillDirs = @(Get-ChildItem -LiteralPath (Join-Path $KitRoot 'skills') -Directory | Sort-Object Name)
$RuleFiles = @(Get-ChildItem -LiteralPath (Join-Path $KitRoot 'rules') -Filter '*.md' | Sort-Object Name)

# ---------- skills 安装 ----------
foreach ($dir in $SkillDirs) {
    $src = Join-Path $dir.FullName 'SKILL.md'
    $text = Read-Text $src
    if ($Ide -eq 'qoder') {
        Install-Content -Dest (Join-Path $Target ".qoder\skills\$($dir.Name)\SKILL.md") -Content $text
    }
    elseif ($Ide -eq 'claude-code') {
        Install-Content -Dest (Join-Path $Target ".claude\skills\$($dir.Name)\SKILL.md") -Content $text
    }
    elseif ($Ide -eq 'cursor') {
        $parsed = Split-Frontmatter $text
        Install-Content -Dest (Join-Path $Target ".cursor\commands\$($dir.Name).md") -Content $parsed.Body
    }
}

# ---------- rules 安装 ----------
$ClaudeImports = @()
$KitRel = $KitRoot
if ($KitRoot.StartsWith($Target, [System.StringComparison]::OrdinalIgnoreCase)) {
    $KitRel = $KitRoot.Substring($Target.Length).TrimStart('\', '/') -replace '\\', '/'
}
foreach ($file in $RuleFiles) {
    $text = Read-Text $file.FullName
    $parsed = Split-Frontmatter $text
    $meta = $parsed.Meta
    if ($Ide -eq 'qoder') {
        Install-Content -Dest (Join-Path $Target ".qoder\rules\$($file.Name)") -Content $text
    }
    elseif ($Ide -eq 'cursor') {
        $mdc = ConvertTo-CursorMdc -Meta $meta -Body $parsed.Body
        $mdcName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + '.mdc'
        Install-Content -Dest (Join-Path $Target ".cursor\rules\$mdcName") -Content $mdc
    }
    elseif ($Ide -eq 'claude-code') {
        # 无 glob 机制：安装期按 -Stack 挑选；core（无 stack 键）全量，stack 规则仅选中栈
        $stackKey = [string]$meta['stack']
        if (-not $stackKey -or $stackKey -in $SelectedStacks) {
            $ClaudeImports += "@$KitRel/rules/$($file.Name)"
        }
    }
}

# ---------- claude-code：CLAUDE.md 标记块幂等替换 ----------
if ($Ide -eq 'claude-code') {
    $begin = '<!-- ai-coding-kit:begin -->'
    $end = '<!-- ai-coding-kit:end -->'
    $block = $begin + "`n" + ($ClaudeImports -join "`n") + "`n" + $end
    $claudePath = Join-Path $Target 'CLAUDE.md'
    if (Test-Path -LiteralPath $claudePath) {
        $existing = Read-Text $claudePath
        $pattern = '(?s)' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end)
        if ($existing -match [regex]::Escape($begin)) {
            $updated = [regex]::Replace($existing, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $block })
        }
        else {
            $updated = $existing.TrimEnd() + "`n`n" + $block + "`n"
        }
        if ($DryRun) { $Report.planned += $claudePath }
        elseif ($updated -ne $existing) {
            Write-Utf8NoBom -Path $claudePath -Text $updated
            $Report.copied += $claudePath
        }
        else { $Report.skipped += $claudePath }
    }
    else {
        Install-Content -Dest $claudePath -Content ($block + "`n")
    }
}

# ---------- templates（仅 -WithTemplates 且目标缺失时生成） ----------
if ($WithTemplates) {
    $templateMap = @(
        @{ Src = 'AGENTS.md';                 Dest = 'AGENTS.md' },
        @{ Src = 'docs\INDEX.md';             Dest = 'docs\INDEX.md' },
        @{ Src = 'docs\GLOSSARY.md';          Dest = 'docs\GLOSSARY.md' },
        @{ Src = 'docs\specs\_domains.md';    Dest = 'docs\specs\_domains.md' }
    )
    foreach ($t in $templateMap) {
        $src = Join-Path $KitRoot ("templates\" + $t.Src)
        Install-Content -Dest (Join-Path $Target $t.Dest) -Content (Read-Text $src)
    }
}

# ---------- 报告 ----------
Write-Output "ai-coding-kit install: Ide=$Ide Target=$Target Stack=$Stack DryRun=$([bool]$DryRun) WithTemplates=$([bool]$WithTemplates)"
Write-Output ("copied  ({0}):" -f $Report.copied.Count)
$Report.copied | ForEach-Object { Write-Output "  $_" }
Write-Output ("skipped ({0}, 同名不覆盖):" -f $Report.skipped.Count)
$Report.skipped | ForEach-Object { Write-Output "  $_" }
if ($DryRun) {
    Write-Output ("planned ({0}, DryRun 未写入):" -f $Report.planned.Count)
    $Report.planned | ForEach-Object { Write-Output "  $_" }
}
exit 0