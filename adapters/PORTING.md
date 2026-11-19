# PORTING.md — IDE 映射、降级契约与手动核验清单

本文件登记 ai-coding-kit 适配器（adapters/）的映射语义、能力降级契约，以及 headless 验证无法覆盖、必须在真实 IDE 里手动核验的项目。**适配器只转格式不改语义**：技能正文与规则条款在安装前后逐字一致（Cursor 仅 frontmatter 格式转换与技能 frontmatter 剥离）。

## 1. IDE 映射表

| IDE | skills 落点 | rules 落点 | glob/栈处理 |
|---|---|---|---|
| Qoder | `<target>/.qoder/skills/<name>/SKILL.md` 原样复制 | `<target>/.qoder/rules/<file>.md` 原样复制（core+stack 全量） | 原生 glob 隔离 |
| Cursor | `<target>/.cursor/commands/<name>.md`（剥离 frontmatter，手动 /name 与 trigger: manual 语义对齐） | `<target>/.cursor/rules/<file>.mdc`（frontmatter 转换，全量） | 原生 globs 隔离 |
| Claude Code | `<target>/.claude/skills/<name>/SKILL.md` 原样复制 | CLAUDE.md 标记块 import（core 全量 + `-Stack` 选中栈，默认 java,vue） | 无 glob，安装期挑选 |

### Frontmatter 转换细则（Cursor mdc）

- core `trigger: always_on` → `alwaysApply: true`（description 若有则保留）。
- core `trigger: model_decision` → `description` + `alwaysApply: false`。
- stack `trigger: glob` → `globs`（取自 glob 列表）+ `alwaysApply: false` + `description`。
- kit 自定义键 `stack:` 仅供适配器挑选栈规则，转换产物不携带该键。

### CLAUDE.md 标记块契约

- 块边界：`<!-- ai-coding-kit:begin -->` 与 `<!-- ai-coding-kit:end -->`。
- 块内逐行 `@<kit相对路径>/rules/<file>.md` import；core 全量 + `-Stack` 选中栈。
- 块外内容不碰；重复安装整块替换（幂等）；卸载 = 整段移除标记块。

## 2. 降级契约（能力缺失时的行为约定）

| 缺失能力 | 降级行为 |
|---|---|
| 无 Skill 工具自动链式调用 | 退化为手动按序输入斜杠命令（技能链顺序见 AGENTS.md 模板），链式语义与门禁不变；senior-dev 的前端→后端链式为技能内部轨道切换，不依赖跨技能调用，无需降级 |
| 无记忆机制 | 跨会话交接仅依赖 docs 交接三件套（已完成/进行中/下一步 + 验证证据回写 tasks.md 或 implementation.md）；retro 的"记忆→条款"分工行跳过 |
| 无 glob 规则注入（Claude Code） | 由适配器按 `-Stack` 参数在安装期挑选栈规则写入 CLAUDE.md import 块；换栈 = 换参数重装 |
| 无 model_decision 触发语义 | Cursor 转为 description + alwaysApply: false（Agent 按需请求），语义近似；差异列入下方手动核验 |

## 3. 手动核验清单（headless 不可验，须在真实 IDE 执行）

沙箱验证（verify-sandbox.ps1）只覆盖**结构与格式**；以下运行时行为必须在真实 IDE 逐项核验并记录结果：

- [ ] Qoder：打开 `.java` 文件时 java-backend 规则被注入；打开 `.py` 文件时 python-backend 注入而 java-backend 不注入（glob 共存隔离的运行时证据）。
- [ ] Qoder：frontmatter 自定义键 `stack:` 不导致规则加载报错（未知键容忍度待真机核验）。
- [ ] Qoder：`trigger: model_decision` 规则带非空 description 时可被模型按需引用。
- [ ] Cursor：`.cursor/rules/*.mdc` 的 globs 在触碰匹配文件时生效；alwaysApply: true 的 core 规则常驻。
- [ ] Cursor：`.cursor/commands/<name>.md` 可通过 /name 手动唤起，正文完整。
- [ ] Claude Code：CLAUDE.md 标记块内 `@path` import 被实际加载；`.claude/skills/` 技能可被唤起。
- [ ] 三家：技能链手动按序执行时，产物落盘路径与 `/spec` 契约一致。

## 4. 版本下限与环境假设

- PowerShell 5.1+（install.ps1 / lint.ps1 / verify-sandbox.ps1）；PowerShell 7 也兼容。
- bash 4+（install.sh，macOS/Linux；Windows 下经 Git Bash 运行）。
- Qoder：支持项目级 `.qoder/skills` 与 `.qoder/rules`（trigger: always_on/manual/model_decision/glob）的版本。
- Cursor：支持 `.cursor/rules/*.mdc`（globs/alwaysApply/description）与 `.cursor/commands` 的版本；旧版 `.cursorrules` 单文件布局不在首批适配范围。
- Claude Code：支持 CLAUDE.md `@path` import 与 `.claude/skills` 的版本。
- 编码：规则/技能/模板等 Markdown 产物 UTF-8 无 BOM；**三个 ps1 脚本必须保存为 UTF-8 带 BOM**（PS 5.1 对无 BOM 文件按 ANSI 解析，中文乱码会直接导致 ParserError，已实测）；PowerShell 捕获含中文命令输出前先置 `[Console]::OutputEncoding=UTF8`。

## 5. 已知限制登记

- 本仓库自举（dogfooding）采用 NTFS Junction 直连源目录：`.qoder/skills → skills/`、`.qoder/rules → rules/`，改动实时生效、不入库（见根 `.gitignore`）；install.ps1 仅用于对外项目分发，不在本仓库内运行。
- Junction 删除与回退：删除 Junction 必须用 `cmd /c rmdir`（只删链接不动源目录）；禁止对 Junction 使用 `Remove-Item -Recurse`（PS 5.1 会跟进目标删掉源文件）。若 Junction 下运行时加载异常，回退为实体目录镜像：`cmd /c rmdir .qoder\skills`、`cmd /c rmdir .qoder\rules` 后执行 `robocopy skills .qoder\skills /MIR`、`robocopy rules .qoder\rules /MIR`；回退后每次改完 kit 需重跑两条 robocopy，`.gitignore` 排除项不变。
- 运行时注入行为 headless 不可验，本文件第 3 节为唯一核验口径；不得以沙箱通过声称"注入已验证"。
- Qoder 对未知 frontmatter 键（stack）的容忍度未真机核验前，保持"结构证据 + 待核验"状态。
- 首批栈示例仅 java / vue / python；其他语言按 README「换语言」指引增补 stack 规则，不改技能正文。