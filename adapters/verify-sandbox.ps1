# verify-sandbox.ps1 — ai-coding-kit 三 IDE 沙箱安装验证
# 用法：powershell -NoProfile -ExecutionPolicy Bypass -File ai-coding-kit\adapters\verify-sandbox.ps1
# 内容（与 docs/changes/add-ai-coding-kit/design.md「沙箱验证」一致）：
#   1. 系统 temp 下建唯一沙箱根，内含样本文件 App.java / app.py / App.vue，复制 kit 进去。
#   2. 分别以 qoder / cursor / claude-code 安装到三个独立沙箱项目（claude-code 用 -Stack python）。
#   3. 布局断言 + glob 共存隔离结构断言 + 同名跳过断言 + CLAUDE.md 幂等替换断言。
#   4. 语法检查：PowerShell Parser 解析三个 ps1 零错误；Git Bash bash -n install.sh 零错误。
#   5. 输出断言清单与退出码；沙箱目录验证后清理。
# 注意：运行时注入行为（IDE 是否真的按 glob 注入）headless 不可验，见 PORTING.md 手动核验清单。

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$KitRoot = Split-Path -Parent $PSScriptRoot

$PassCount = 0
$FailCount = 0
function Check([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) {
        $script:PassCount++
        Write-Output ("通过  {0}" -f $Name)
    }
    else {
        $script:FailCount++
        Write-Output ("失败  {0} —— {1}" -f $Name, $Detail)
    }
}

function Read-Text([string]$Path) {
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

$SandboxRoot = Join-Path $env:TEMP ('ai-kit-sandbox-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
try {
    # ---------- 1. 沙箱与样本 ----------
    New-Item -ItemType Directory -Path $SandboxRoot -Force | Out-Null
    $SandboxKit = Join-Path $SandboxRoot 'ai-coding-kit'
    Copy-Item -LiteralPath $KitRoot -Destination $SandboxKit -Recurse
    $projects = @{}
    foreach ($p in @('proj-qoder', 'proj-cursor', 'proj-claude')) {
        $dir = Join-Path $SandboxRoot $p
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        foreach ($sample in @('App.java', 'app.py', 'App.vue')) {
            [System.IO.File]::WriteAllText((Join-Path $dir $sample), "// sample $sample`n", (New-Object System.Text.UTF8Encoding($false)))
        }
        $projects[$p] = $dir
    }
    Check '沙箱建立（kit 复制 + 三项目样本文件）' (Test-Path -LiteralPath (Join-Path $SandboxKit 'skills\spec\SKILL.md')) '沙箱 kit 复制失败'

    $installScript = Join-Path $SandboxKit 'adapters\install.ps1'

    # ---------- 2. 预置冲突文件（验证同名跳过不覆盖） ----------
    $conflictPath = Join-Path $projects['proj-qoder'] '.qoder\rules\work-discipline.md'
    New-Item -ItemType Directory -Path (Split-Path -Parent $conflictPath) -Force | Out-Null
    $sentinel = 'SENTINEL-既有规则不得被覆盖'
    [System.IO.File]::WriteAllText($conflictPath, $sentinel, (New-Object System.Text.UTF8Encoding($false)))

    # ---------- 3. 三家安装 ----------
    $qoderOut = (& $installScript -Ide qoder -Target $projects['proj-qoder'] -WithTemplates) -join "`n"
    $cursorOut = (& $installScript -Ide cursor -Target $projects['proj-cursor']) -join "`n"
    $claudeOut = (& $installScript -Ide claude-code -Stack python -Target $projects['proj-claude']) -join "`n"

    # ---------- 4. qoder 断言 ----------
    $qRules = Join-Path $projects['proj-qoder'] '.qoder\rules'
    $javaPath = Join-Path $qRules 'java-backend.md'
    $pyPath = Join-Path $qRules 'python-backend.md'
    $coexist = (Test-Path -LiteralPath $javaPath) -and (Test-Path -LiteralPath $pyPath)
    Check 'qoder 栈规则共存（java-backend.md 与 python-backend.md 同在）' $coexist '共存文件缺失'
    if ($coexist) {
        $javaText = Read-Text $javaPath
        $pyText = Read-Text $pyPath
        $fmOk = ($javaText -match '(?m)^trigger: glob') -and ($javaText -match '(?m)^stack: java') -and ($javaText -match '\*\*/\*\.java') `
            -and ($pyText -match '(?m)^trigger: glob') -and ($pyText -match '(?m)^stack: python') -and ($pyText -match '\*\*/\*\.py')
        Check 'qoder glob frontmatter 完整（共存隔离结构证据）' $fmOk 'trigger/stack/glob 字段不完整'
    }
    $qSkills = @(Get-ChildItem -LiteralPath (Join-Path $projects['proj-qoder'] '.qoder\skills') -Directory)
    Check 'qoder skills 落点齐全 11 件' ($qSkills.Count -eq 11) ("实际 $($qSkills.Count) 件")
    Check 'qoder 同名跳过不覆盖（sentinel 保留）' ((Read-Text $conflictPath) -eq $sentinel) '既有文件被覆盖'
    Check 'qoder 安装报告含 skipped' ($qoderOut -match 'skipped \([1-9]') '报告未体现 skipped'
    $tplOk = (Test-Path -LiteralPath (Join-Path $projects['proj-qoder'] 'AGENTS.md')) `
        -and (Test-Path -LiteralPath (Join-Path $projects['proj-qoder'] 'docs\INDEX.md')) `
        -and (Test-Path -LiteralPath (Join-Path $projects['proj-qoder'] 'docs\GLOSSARY.md')) `
        -and (Test-Path -LiteralPath (Join-Path $projects['proj-qoder'] 'docs\specs\_domains.md'))
    Check 'qoder -WithTemplates 生成 4 件骨架' $tplOk '模板缺失'

    # ---------- 5. cursor 断言 ----------
    $cRules = Join-Path $projects['proj-cursor'] '.cursor\rules'
    $javaMdc = Read-Text (Join-Path $cRules 'java-backend.mdc')
    $wdMdc = Read-Text (Join-Path $cRules 'work-discipline.mdc')
    Check 'cursor java-backend.mdc 含 globs 且 alwaysApply: false' (($javaMdc -match '(?m)^globs:') -and ($javaMdc -match '(?m)^alwaysApply: false')) 'mdc 转换不符'
    Check 'cursor work-discipline.mdc alwaysApply: true' ($wdMdc -match '(?m)^alwaysApply: true') 'core always_on 转换不符'
    Check 'cursor mdc 不携带 kit 自定义 stack 键' (-not ($javaMdc -match '(?m)^stack:')) 'stack 键泄漏进 mdc'
    $cCmds = @(Get-ChildItem -LiteralPath (Join-Path $projects['proj-cursor'] '.cursor\commands') -Filter '*.md')
    Check 'cursor commands 落点齐全 11 件' ($cCmds.Count -eq 11) ("实际 $($cCmds.Count) 件")
    $cmdText = Read-Text (Join-Path $projects['proj-cursor'] '.cursor\commands\spec.md')
    Check 'cursor commands 已剥离 frontmatter' (-not ($cmdText.StartsWith('---'))) 'frontmatter 未剥离'

    # ---------- 6. claude-code 断言 ----------
    $claudePath = Join-Path $projects['proj-claude'] 'CLAUDE.md'
    $claudeText = Read-Text $claudePath
    Check 'claude CLAUDE.md 标记块含 testing-python.md' ($claudeText.Contains('testing-python.md')) '-Stack python 未选中 python 栈'
    Check 'claude CLAUDE.md 标记块不含 java-backend.md' (-not $claudeText.Contains('java-backend.md')) '未选中栈泄漏'
    Check 'claude CLAUDE.md core 全量（含 work-discipline.md）' ($claudeText.Contains('work-discipline.md')) 'core 规则缺失'
    $clSkills = @(Get-ChildItem -LiteralPath (Join-Path $projects['proj-claude'] '.claude\skills') -Directory)
    Check 'claude skills 落点齐全 11 件' ($clSkills.Count -eq 11) ("实际 $($clSkills.Count) 件")
    # 幂等替换：换栈重装，标记块整块替换，块数仍为 1
    $null = (& $installScript -Ide claude-code -Stack java -Target $projects['proj-claude']) -join "`n"
    $claudeText2 = Read-Text $claudePath
    $beginCount = ([regex]::Matches($claudeText2, [regex]::Escape('<!-- ai-coding-kit:begin -->'))).Count
    Check 'claude 重复安装标记块幂等（块数=1 且换栈生效）' (($beginCount -eq 1) -and $claudeText2.Contains('java-backend.md') -and (-not $claudeText2.Contains('testing-python.md'))) "块数=$beginCount 或换栈未生效"

    # ---------- 7. 语法检查 ----------
    foreach ($ps1 in @('install.ps1', 'lint.ps1', 'verify-sandbox.ps1')) {
        $path = Join-Path $KitRoot "adapters\$ps1"
        $tokens = $null; $parseErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$parseErrors)
        Check "PowerShell Parser $ps1 零错误" ($parseErrors.Count -eq 0) (($parseErrors | ForEach-Object { $_.Message }) -join '; ')
    }
    $bash = $null
    foreach ($candidate in @('C:\Program Files\Git\bin\bash.exe', 'C:\Program Files\Git\usr\bin\bash.exe')) {
        if (Test-Path -LiteralPath $candidate) { $bash = $candidate; break }
    }
    if (-not $bash) { $bash = (Get-Command bash -ErrorAction SilentlyContinue | Select-Object -First 1).Source }
    if ($bash) {
        & $bash -n (Join-Path $KitRoot 'adapters\install.sh')
        Check 'bash -n install.sh 零错误' ($LASTEXITCODE -eq 0) "退出码 $LASTEXITCODE"
    }
    else {
        Write-Output '跳过  bash -n install.sh（未找到 bash，须按 PORTING.md 手动核验）'
    }
}
finally {
    if (Test-Path -LiteralPath $SandboxRoot) {
        Remove-Item -LiteralPath $SandboxRoot -Recurse -Force
    }
}

Write-Output ("沙箱验证汇总：通过 {0} / 失败 {1}（沙箱已清理）" -f $PassCount, $FailCount)
if ($FailCount -gt 0) { exit 1 } else { exit 0 }