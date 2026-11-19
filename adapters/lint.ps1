# lint.ps1 — ai-coding-kit 结构 lint（frontmatter / 交叉引用 / 清单完整性）
# 用法：powershell -NoProfile -ExecutionPolicy Bypass -File ai-coding-kit\adapters\lint.ps1
# 规则（与 docs/changes/add-ai-coding-kit/design.md「lint 规则」一致）：
#   1. skills 清单 = 9 个中立名；每个目录含 SKILL.md；name=目录名、description 非空、trigger: manual。
#   2. core 8 件：trigger ∈ {always_on, model_decision}；model_decision 必须非空 description；不得含 stack 键。
#   3. stack 6 件：trigger = glob；glob 列表非空；stack ∈ {java, vue, python}；description 非空。
#   4. 交叉引用：技能正文中的斜杠命令必须存在于 skills 清单；禁止残留旧名。
#   5. 清单完整性：templates 4 件、adapters 5 件（含自身）、README 存在。
#   6. 逐条 通过/失败 + 计数；存在失败 exit 1。

$ErrorActionPreference = 'Stop'
$KitRoot = Split-Path -Parent $PSScriptRoot

$SkillNames = @('spec', 'grill-me', 'requirement-design', 'architecture-design', 'senior-dev', 'code-review', 'commit', 'retro', 'product-senior')
$CoreRules = @('work-discipline.md', 'output-fidelity.md', 'plan-first.md', 'testing.md', 'sql-data.md', 'api-contract.md', 'architecture.md', 'commit.md')
$StackRules = @('java-backend.md', 'testing-java.md', 'sql-data-java.md', 'vue-frontend.md', 'python-backend.md', 'testing-python.md')
$LegacyNames = @('java-requirement-design', 'java-architecture-design', 'java-senior-dev', 'ai-tdd', 'ui-senior-dev', 'tdd', 'ui-dev')
$TemplateFiles = @('templates\AGENTS.md', 'templates\docs\INDEX.md', 'templates\docs\GLOSSARY.md', 'templates\docs\specs\_domains.md')
$AdapterFiles = @('adapters\install.ps1', 'adapters\install.sh', 'adapters\lint.ps1', 'adapters\verify-sandbox.ps1', 'adapters\PORTING.md')

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

# ---------- 规则 1：skills 清单与 frontmatter ----------
$actualSkillDirs = @(Get-ChildItem -LiteralPath (Join-Path $KitRoot 'skills') -Directory | ForEach-Object { $_.Name } | Sort-Object)
$expectedSorted = @($SkillNames | Sort-Object)
$diff = Compare-Object $expectedSorted $actualSkillDirs
Check 'skills 清单 = 9 个中立名' ($null -eq $diff -and $actualSkillDirs.Count -eq 9) ("目录清单与预期不一致: " + (($diff | ForEach-Object { $_.InputObject + $_.SideIndicator }) -join ', '))

foreach ($name in $SkillNames) {
    $path = Join-Path $KitRoot "skills\$name\SKILL.md"
    if (-not (Test-Path -LiteralPath $path)) {
        Check "skills/$name/SKILL.md 存在" $false '文件缺失'
        continue
    }
    $parsed = Split-Frontmatter (Read-Text $path)
    $meta = $parsed.Meta
    Check "skills/$name frontmatter" (($meta['name'] -eq $name) -and ([string]$meta['description']).Trim() -ne '' -and ($meta['trigger'] -eq 'manual')) ("name=$($meta['name']) trigger=$($meta['trigger']) description长度=$(([string]$meta['description']).Length)")
}

# ---------- 规则 2：core 规则 ----------
foreach ($file in $CoreRules) {
    $path = Join-Path $KitRoot "rules\$file"
    if (-not (Test-Path -LiteralPath $path)) {
        Check "core $file 存在" $false '文件缺失'
        continue
    }
    $meta = (Split-Frontmatter (Read-Text $path)).Meta
    $triggerOk = $meta['trigger'] -in @('always_on', 'model_decision')
    $descOk = ($meta['trigger'] -ne 'model_decision') -or (([string]$meta['description']).Trim() -ne '')
    $noStack = -not $meta.ContainsKey('stack')
    Check "core $file frontmatter" ($triggerOk -and $descOk -and $noStack) ("trigger=$($meta['trigger']) description长度=$(([string]$meta['description']).Length) 含stack键=$($meta.ContainsKey('stack'))")
}

# ---------- 规则 3：stack 规则 ----------
foreach ($file in $StackRules) {
    $path = Join-Path $KitRoot "rules\$file"
    if (-not (Test-Path -LiteralPath $path)) {
        Check "stack $file 存在" $false '文件缺失'
        continue
    }
    $meta = (Split-Frontmatter (Read-Text $path)).Meta
    $globList = @($meta['glob'])
    $ok = ($meta['trigger'] -eq 'glob') -and ($globList.Count -gt 0) -and ($meta['stack'] -in @('java', 'vue', 'python')) -and (([string]$meta['description']).Trim() -ne '')
    Check "stack $file frontmatter" $ok ("trigger=$($meta['trigger']) glob数=$($globList.Count) stack=$($meta['stack']) description长度=$(([string]$meta['description']).Length)")
}

# ---------- 规则 4：交叉引用 ----------
$badRefs = @()
foreach ($name in $SkillNames) {
    $path = Join-Path $KitRoot "skills\$name\SKILL.md"
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $body = (Split-Frontmatter (Read-Text $path)).Body
    # 斜杠命令候选：/ 前为行首或空白/反引号/括号/箭头，名称为小写 kebab，后不接 / 或 .（排除路径与文件名）
    $matches2 = [regex]::Matches($body, '(^|[\s`（(→、])/([a-z][a-z0-9-]*)(?![/.])', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    foreach ($m in $matches2) {
        # 尾部连字符属于占位符写法（如 retro-<主题>），剥离后再比对清单
        $ref = $m.Groups[2].Value.TrimEnd('-')
        if ($ref -notin $SkillNames) { $badRefs += "$name → /$ref" }
    }
}
Check '技能斜杠命令均存在于 skills 清单' ($badRefs.Count -eq 0) ($badRefs -join '; ')

$legacyHits = @()
$scanFiles = @(Get-ChildItem -LiteralPath (Join-Path $KitRoot 'skills') -Recurse -Filter '*.md')
$scanFiles += @(Get-ChildItem -LiteralPath (Join-Path $KitRoot 'rules') -Filter '*.md')
$scanFiles += @(Get-ChildItem -LiteralPath (Join-Path $KitRoot 'templates') -Recurse -Filter '*.md')
$scanFiles += @(Get-Item -LiteralPath (Join-Path $KitRoot 'README.md') -ErrorAction SilentlyContinue)
foreach ($f in $scanFiles) {
    if ($null -eq $f) { continue }
    $text = Read-Text $f.FullName
    foreach ($legacy in $LegacyNames) {
        if ($text.Contains($legacy)) { $legacyHits += "$($f.Name) 残留 $legacy" }
    }
}
Check '无旧技能名残留（skills/rules/templates/README）' ($legacyHits.Count -eq 0) ($legacyHits -join '; ')

# ---------- 规则 5：清单完整性 ----------
foreach ($rel in $TemplateFiles) {
    Check "templates 件 $rel" (Test-Path -LiteralPath (Join-Path $KitRoot $rel)) '文件缺失'
}
foreach ($rel in $AdapterFiles) {
    Check "adapters 件 $rel" (Test-Path -LiteralPath (Join-Path $KitRoot $rel)) '文件缺失'
}
Check 'README.md 存在' (Test-Path -LiteralPath (Join-Path $KitRoot 'README.md')) '文件缺失'

# ---------- 汇总 ----------
Write-Output ("lint 汇总：通过 {0} / 失败 {1}" -f $PassCount, $FailCount)
if ($FailCount -gt 0) { exit 1 } else { exit 0 }