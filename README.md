# ai-coding-kit — 通用 AI 协作工作流 kit

一套**语言中立、IDE 可移植**的 AI coding 工作流：把「流程技能 + 纪律规则 + 文档体系」打包成复制到任何项目即可使用的单一源。技能正文只写流程与门禁，语言/框架知识全部外置到 stack 规则，IDE 差异由适配器转换。

## 三层结构

| 层 | 目录 | 职责 |
|---|---|---|
| 流程层 | `skills/`（11 件） | 中立技能：spec / grill-me / requirement-design / architecture-design / senior-dev / tdd / ui-dev / code-review / commit / retro / product-senior |
| 纪律层 | `rules/`（14 件） | core 8 件（always_on/model_decision，语言中立纪律）+ stack 6 件（glob 触发，java/vue/python 硬约束，共存隔离） |
| 适配层 | `adapters/`（5 件） | install.ps1 / install.sh 安装映射，lint.ps1 结构校验，verify-sandbox.ps1 沙箱验证，PORTING.md 映射与降级契约 |

另有 `templates/`（AGENTS.md + docs 三区骨架 4 件），仅 `-WithTemplates` 且目标缺失时生成。

## 技能链

```
/spec propose → /product-senior(可选) → /grill-me → /requirement-design
              → [/architecture-design(有架构决策时)]
              → /ui-dev(前端) ↔ /senior-dev(后端) 或 /tdd(TDD)
              → /code-review(质量门禁) → /spec verify → /spec archive
```

文档体系为 OpenSpec 式三区：`docs/specs/`（当前真相）/ `docs/changes/`（进行中变更）/ `docs/archive/`（已结案）。编号体系 SP-xx ← R-xx → FP-xx → T-xx 全程可追溯。

## 快速安装

把整个 `ai-coding-kit/` 目录复制进目标项目根目录，然后：

```powershell
# Qoder（Windows）
powershell -NoProfile -ExecutionPolicy Bypass -File ai-coding-kit\adapters\install.ps1 -Ide qoder -WithTemplates

# Cursor
powershell -NoProfile -ExecutionPolicy Bypass -File ai-coding-kit\adapters\install.ps1 -Ide cursor

# Claude Code（无 glob 机制，安装期按 -Stack 挑选栈规则，默认 java,vue）
powershell -NoProfile -ExecutionPolicy Bypass -File ai-coding-kit\adapters\install.ps1 -Ide claude-code -Stack python
```

```bash
# macOS / Linux（同语义长选项）
bash ai-coding-kit/adapters/install.sh --ide qoder --with-templates
bash ai-coding-kit/adapters/install.sh --ide claude-code --stack python
```

参数：`-Ide/--ide`（必填，qoder|cursor|claude-code）、`-Stack/--stack`（逗号列表，仅 claude-code 生效）、`-WithTemplates/--with-templates`、`-DryRun/--dry-run`（只报告不写入）、`-Target/--target`（默认 kit 所在项目根）。

安装语义：**同名文件跳过不覆盖并报告**；CLAUDE.md 以 `<!-- ai-coding-kit:begin/end -->` 标记块幂等替换，块外内容不碰；模板仅在目标缺失时生成。docs 三区骨架也可用 `/spec init` 单独建立。

## 换语言（增补 stack 规则即可，技能零改动）

1. 在 `rules/` 新增对应栈规则文件，frontmatter 照抄现有 stack 规则格式：`trigger: glob` + 非空 `glob` 列表 + `stack: <栈名>` + 非空 `description`（如 Go 栈：`glob: ["**/*.go", "go.mod"]`）。
2. 栈规则与既有 java/vue/python 规则**共存不冲突**：按触碰文件类型自动注入，"再加个 Python rules 就可以"字面成立。
3. Claude Code 用户换 `-Stack` 参数重装即可；Qoder/Cursor 无需任何操作。
4. 构建/测试命令口径写在栈规则内（如 java-backend 的 `mvn -o compile/test`、python-backend 的 pytest/ruff），AGENTS.md 与技能只引用"以当前栈 rules 为准"。

## 换 IDE

重跑 install 指定新 `-Ide` 即可；映射细则、降级契约（无自动链/无记忆/无 glob）与版本下限见 `adapters/PORTING.md`。运行时注入行为须在真实 IDE 按 PORTING.md 第 3 节手动核验，沙箱验证只覆盖结构与格式。

## 验证

```powershell
# 结构 lint：frontmatter / 交叉引用 / 清单完整性（失败 exit 1）
powershell -NoProfile -ExecutionPolicy Bypass -File ai-coding-kit\adapters\lint.ps1

# 三 IDE 沙箱安装 + 布局断言 + glob 共存隔离结构断言 + 脚本语法检查（验证后自动清理沙箱）
powershell -NoProfile -ExecutionPolicy Bypass -File ai-coding-kit\adapters\verify-sandbox.ps1
```

## 卸载

- Qoder/Cursor：删除安装产物（`.qoder/skills|rules`、`.cursor/commands|rules` 中来自 kit 的文件）；kit 目录本身可整体删除。
- Claude Code：移除 CLAUDE.md 标记块整段 + `.claude/skills` 中 kit 技能；kit 目录可整体删除。
- 模板生成的 AGENTS.md 与 docs 骨架属项目文档，按需保留。