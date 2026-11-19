# Change: improve-merge-coding-skills

## Why

编码阶段现有三个技能（senior-dev / tdd / ui-dev）职责重叠：senior-dev 管"代码怎么写对"，tdd 管"开发节奏怎么控"（其 SKILL.md 自述两者可叠加），ui-dev 管前端工作流分支；语言/栈硬约束早已全部外置到 glob rules，三者差异均为工作流分支而非语言差异。三入口增加用户选择成本，且 ui-dev → senior-dev 的跨技能自动链式调用是 PORTING.md 降级契约中最脆弱的一环（无 Skill 工具的 IDE 退化为文字提示）。合并为单一编码入口后，技能内部以"任务轨道 × 方法模式"判定承载全部分支，前后端链式变为技能内部轨道切换，降级风险消除。

## What Changes

- 把 tdd、ui-dev 合并进 senior-dev（保留 senior-dev 名，上游技能对其引用免改）：内部"任务轨道（后端/前端/全栈）× 方法模式（默认/TDD）"判定；TDD 铁律与 Red-Green-Refactor 循环、前端双轨选型/自查清单/前后端交接契约（contract.md）语义完整保留。
- 删除 skills/tdd/、skills/ui-dev/；技能总数 11 → 9。
- lint.ps1：$SkillNames 移除 tdd/ui-dev，$LegacyNames 增补 tdd/ui-dev 防旧名残留，清单计数与断言名 11 → 9。
- verify-sandbox.ps1：三处 skills 落点计数断言 11 → 9。
- 同步交叉引用：README.md（三层结构/链图/阶段表/技能清单/推荐用法）、根 AGENTS.md 与 templates/AGENTS.md 链图、adapters/PORTING.md 降级契约措辞、skills/code-review（/tdd 引用）、skills/product-senior（链图）、skills/spec（边界/目录契约/启动方式中的 /tdd、/ui-dev 引用）。

## Impact（影响面：模块 / 表 / 接口 / 调用方）

- skills/：senior-dev/SKILL.md 重写；tdd/、ui-dev/ 删除；code-review、product-senior、spec 引用修订。
- adapters/：lint.ps1、verify-sandbox.ps1 计数与清单；PORTING.md 降级契约行。
- 文档：README.md、AGENTS.md（根）、templates/AGENTS.md。
- 无业务代码、无数据表、无对外接口变更；rules/ 全部条款不动。
- 调用方：上游技能（grill-me/requirement-design/architecture-design）对 /senior-dev 的引用不变；用户侧 /tdd、/ui-dev 斜杠命令失效，统一改用 /senior-dev。

## Non-goals（本次明确不做，供越界拦截比对）

- 不修改任何 rules 条款（core 8 件与 stack 6 件逐字不动）。
- 不改变其他技能的工作流实质（grill-me 拷问维度、requirement-design 八步法、architecture-design 准则、code-review 审查维度、commit/retro/product-senior 流程）。
- 不新增栈规则、不改变 install.ps1/install.sh 安装语义与映射。
- 不处理工作区中待提交的 retro/README 既有改动（独立提交意图，另行裁决）。
- 不填写根 AGENTS.md「项目专属」占位节（属另一任务）。
