# ai-coding-kit — 通用 AI 协作工作流 kit

一套**语言中立、IDE 可移植**的 AI coding 工作流：把「流程技能 + 纪律规则 + 文档体系」打包成复制到任何项目即可使用的单一源。技能正文只写流程与门禁，语言/框架知识全部外置到 stack 规则，IDE 差异由适配器转换。

## 三层结构

| 层 | 目录 | 职责 |
|---|---|---|
| 流程层 | `skills/`（9 件） | 中立技能：spec / grill-me / requirement-design / architecture-design / senior-dev / code-review / commit / retro / product-senior |
| 纪律层 | `rules/`（14 件） | core 8 件（always_on/model_decision，语言中立纪律）+ stack 6 件（glob 触发，java/vue/python 硬约束，共存隔离） |
| 适配层 | `adapters/`（5 件） | install.ps1 / install.sh 安装映射，lint.ps1 结构校验，verify-sandbox.ps1 沙箱验证，PORTING.md 映射与降级契约 |

另有 `templates/`（AGENTS.md + docs 三区骨架 4 件），仅 `-WithTemplates` 且目标缺失时生成。

## 工作流使用

技能用斜杠命令唤起（如 `/grill-me`）；规则无需手动引用，安装后按 frontmatter 的 trigger 自动注入（常驻 / 按需 / 触碰文件触发）。无 Skill 自动链式调用机制的 IDE，按下述顺序手动逐个输入斜杠命令，链式语义与门禁不变（降级契约见 `adapters/PORTING.md`）。

```
/spec propose → /product-senior(可选) → /grill-me → /requirement-design
              → [/architecture-design(有架构决策时)]
              → /senior-dev(编码单一入口：后端/前端/全栈轨道 × 默认/TDD 模式)
              → /code-review(质量门禁) → /spec verify → /spec archive
```

| 阶段 | 命令 | 做什么 | 主要落盘产物 |
|---|---|---|---|
| 登记变更 | `/spec propose` | 创建 `docs/changes/<变更名>/` 脚手架，定义 What Changes / Non-goals | `proposal.md` |
| 产品思考（可选） | `/product-senior` | 用户故事与验收标准、交互评估 | 产品文档 |
| 需求拷问 | `/grill-me` | 一次一问挖掘隐性规则、边界、异常、并发、事务、数据风险 | 需求澄清文档（R-xx） |
| 需求拆解 | `/requirement-design` | 流程拆解、功能点 FP-xx、表/接口设计、技术选型、有序任务清单 T-xx | specs delta + `design.md` + `tasks.md` |
| 架构设计（有决策点时） | `/architecture-design` | 裁决架构决策点，产出实施约束清单 | `design.md`「架构决策」节 |
| 编码 | `/senior-dev`（单一入口） | 按任务轨道（后端/前端/全栈）× 方法模式（默认/TDD）判定；TDD 模式强制先写失败测试再最小实现 | 代码 + 测试 + `implementation.md` |
| 质量门禁 | `/code-review` | 分级审查报告，越界拦截 | 评审报告 |
| 校验归档 | `/spec verify` → `/spec archive` | 四类校验通过后 delta 合入 specs，变更归档 | `specs/` 更新 + `archive/` |

文档体系为 OpenSpec 式三区：`docs/specs/`（当前真相）/ `docs/changes/`（进行中变更）/ `docs/archive/`（已结案）。编号体系 SP-xx ← R-xx → FP-xx → T-xx 全程可追溯。各阶段产物落盘路径由 `/spec` 契约统一规定，不在文件名内嵌日期。

**链路裁剪**：按变更大小裁剪技能链——小改动可跳过产品与架构环节直接进入编码；`/code-review` 只在核心逻辑变更/合并前跑一次；Bug 修复只补 1 个回归用例，新功能才完整覆盖。

## 技能清单（9 件）

| 命令 | 定位与职责 |
|---|---|
| `/spec` | 文档生命周期管理（OpenSpec 式）：变更脚手架创建与初始化、产物状态核对、SP 规则增量合并、归档，以及结构/追溯完整性/归档前置/并行冲突四类校验。不生成业务内容，只管“文档放哪、叫什么、能不能归档”。 |
| `/product-senior` | 资深产品经理：需求分析、用户故事（含验收标准）、产品规划与路线图、交互友好性评估，产出结构化产品文档。 |
| `/grill-me` | 需求拷问专家：编码前挖掘隐性业务规则、边界条件、异常、并发、事务、数据风险；一次只提 1 个问题直到所有维度确认，输出需求澄清文档交接给需求拆解。 |
| `/requirement-design` | 需求拆解与设计：全链路流程拆解与状态机建模、功能点与边界异常场景枚举、领域模型与数据表设计、接口契约、技术选型（事务/缓存/幂等/异步/锁）、变更影响面、有序开发任务清单与风险识别。 |
| `/architecture-design` | 资深架构师（工作流层）：分层与依赖/SOLID/并发/事务/性能/安全核心准则、方案评审与交付模板；产出实施约束清单供编码阶段强制遵循。 |
| `/senior-dev` | 资深开发编码专家（工作流层，编码阶段单一入口）：按任务轨道（后端/前端/全栈）× 方法模式（默认/TDD）判定；编码实现、Bug 修复、重构、前端双轨选型与前后端接口交接契约落地；TDD 模式强制 Red-Green-Refactor 循环。编码与测试硬约束由当前栈 rules 自动注入。 |
| `/code-review` | 资深架构与代码审查：覆盖业务逻辑、架构合理性、并发安全、事务边界、性能隐患、安全漏洞、异常处理、可维护性，输出严重/一般/建议分级报告与可落地修改意见。 |
| `/commit` | Git 提交助手：分析变更按 Conventional Commits（中文 scope 与主题）生成提交信息，经用户明确确认后才提交，绝不主动提交、不跳过钩子、不夹带无关改动。 |
| `/retro` | 会话环境复盘：基于会话真实证据建议改进仓库环境（条款/门禁/导航/技能），按严重度排序，只建议不动手。 |

## 规则清单（14 件）

规则按 frontmatter 的 `trigger` 分三类注入：`always_on` 每次会话常驻；`model_decision` 由模型按 description 判断当前任务相关时引用；`glob` 在触碰匹配文件时自动注入，多栈共存互不干扰。

**core 8 件（语言中立纪律）**：

| 规则 | 触发 | 内容 |
|---|---|---|
| `plan-first.md` | always_on | 先方案后执行：咨询口吻或多方案时先出方案+推荐待确认；明确执行指令直接执行；执行期不打断；分析型问题直接给结论与证据。 |
| `work-discipline.md` | always_on | 提问/执行边界、执行纪律（真实验证、交接三件套）、Credits 节约、命令输出捕获（UTF-8、点目录、agent 终端 git 推送一律 SSH）。 |
| `output-fidelity.md` | always_on | 输出保真：落盘产物不压缩、既有注释不删、否定词与载荷逐字保真；精简只针对聊天解释性文字。 |
| `architecture.md` | model_decision | 架构设计、模块拆分、技术方案评审、plan 阶段设计决策裁决时的语言中立纪律。 |
| `api-contract.md` | model_decision | 接入层端点、对外 API 契约、统一响应封装、SSE 实时日志端点、前后端接口交接契约的语言中立纪律。 |
| `sql-data.md` | model_decision | 编写 SQL、设计表/索引、批量写入、DDL 变更、排查慢查询或索引失效时的语言中立纪律。 |
| `testing.md` | model_decision | 生成/修改测试、设计用例、Bug 修复写回归、重构前建保护网时的语言中立纪律（GWT/测试独立/断言有意义行为）。 |
| `commit.md` | model_decision | 用户要求提交代码、写 commit message、整理提交时注入，与 `/commit` 技能配套。 |

**stack 6 件（glob 触发，换语言只增补本层，技能零改动）**：

| 规则 | 栈 | glob | 内容 |
|---|---|---|---|
| `java-backend.md` | java | `**/*.java`、`pom.xml` | Java/Spring 后端编码硬约束与构建验证命令口径（`mvn -o compile` / `mvn -o test`）。 |
| `sql-data-java.md` | java | `**/*.java` | Java 数据栈陷阱：SQL Server 连接串 Unicode 隐式转换、Hibernate IDENTITY 批处理、H2 存量库 DDL。 |
| `testing-java.md` | java | `**/*Test.java`、`**/src/test/**` | Java 测试栈硬约束（JUnit5 + Mockito + AssertJ + Spring Boot Test）。 |
| `vue-frontend.md` | vue | `**/*.vue` | Vue3 前端硬约束，含前端通用约束：XSS 防护、异步四态、双层解析、最小 diff。 |
| `python-backend.md` | python | `**/*.py`、`pyproject.toml`、`requirements.txt` | Python 后端编码硬约束与构建验证命令口径。 |
| `testing-python.md` | python | `**/test_*.py`、`**/*_test.py`、`**/tests/**` | Python 测试栈硬约束（pytest + monkeypatch + pytest-cov）。 |

## 推荐用法

- **中大型新功能**：走完整技能链。从 `/spec propose` 登记变更开始，需求不清先 `/grill-me` 拷问，有架构决策点才进 `/architecture-design`；编码阶段统一 `/senior-dev`（自动判定轨道与模式），合并前 `/code-review` 一次，最后 `/spec verify` + `/spec archive` 收口。
- **小改动（文案/配置/局部修复）**：裁剪链路，直接 `/senior-dev` 或按规则直接修改，跳过产品/架构/拷问环节；验证仍按当前栈 rules 命令口径真实执行。
- **Bug 修复**：`/senior-dev` 修复并只补 1 个回归用例；先定位根因再动手，不夹带无关重构。
- **纯咨询/评审/排查**：不改文件；plan-first 规则会自动先给方案+推荐或分析结论+证据，确认后才执行。只读咨询建议用 IDE 的只读/Ask 模式省 Credits。
- **跨会话长任务**：会话结束前把交接三件套（已完成/进行中/下一步 + 验证证据）回写 `docs/changes/<变更名>/tasks.md` 或 `implementation.md`；新会话按 `docs/INDEX.md` → changes 产物接管。
- **落地到你的项目**：复制 kit 目录后跑 `install.ps1 -Ide qoder -WithTemplates` 生成 AGENTS.md 与 docs 骨架，按项目实际填写 AGENTS.md「项目专属」节（技术栈版本、栈规则清单、构建命令、忽略区）；文档骨架也可用 `/spec init` 单独建立。
- **会话收尾**：输入 `/retro` 把本次踩坑固化为仓库条款与门禁，让下一个会话不再踩同一个坑。

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

## 远程与推送（本仓库自举环境）

本仓库 `origin` 配置为双 pushurl：fetch 走 Gitee，`git push origin master` 一条命令同时推送 Gitee 与 GitHub。该配置存于本机 `.git/config`（不随仓库版本化），新机器 clone 后需按以下命令重新配置：

```powershell
git remote set-url origin git@gitee.com:qiaozy007/ai-coding-kit.git
git remote set-url --push origin git@gitee.com:qiaozy007/ai-coding-kit.git
git remote set-url --add --push origin git@github.com:qiaozy007/ai-coding-kit.git
git push origin master
```

- 推送一律走 SSH：agent 终端禁用交互提示，HTTPS 推送会因无法弹出凭据登录而失败（`terminal prompts disabled`）。
- SSH 认证回显判别：`Hi <用户名>!` 为账号级密钥（可读写）；`Hi <用户名>/<仓库名>!` 为仓库级 Deploy key（默认只读，推送报 `marked as read only`，需勾选 Allow write access 或改用账号级密钥）。
- 首推前提：两处远程均为空仓库（不要初始化 README），避免非快进冲突。
- 安全注记：若 `git config --global http.sslVerify` 为 `false`，HTTPS 连接不校验证书；除非公司代理有意设置，应恢复为 `true`。本仓库推送已走 SSH，不受影响。

## 卸载

- Qoder/Cursor：删除安装产物（`.qoder/skills|rules`、`.cursor/commands|rules` 中来自 kit 的文件）；kit 目录本身可整体删除。
- 本仓库自举布局例外：`.qoder/skills|rules` 是指向源目录的 Junction，必须用 `cmd /c rmdir .qoder\skills` 只删链接；禁止对 Junction 使用 `Remove-Item -Recurse`（PS 5.1 会跟进目标删掉源目录内容）。
- Claude Code：移除 CLAUDE.md 标记块整段 + `.claude/skills` 中 kit 技能；kit 目录可整体删除。
- 模板生成的 AGENTS.md 与 docs 骨架属项目文档，按需保留。