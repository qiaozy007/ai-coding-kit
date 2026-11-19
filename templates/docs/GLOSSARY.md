# docs/GLOSSARY.md — 术语表（ai-coding-kit 模板）

> 术语冲突时以本表为准；新术语由 `/grill-me` 术语收尾环节登记，禁止同一概念在 proposal/delta/design/tasks 中用词漂移（`/spec verify` 做术语漂移检测）。
> 安装说明：`-WithTemplates` 仅在目标项目缺失 `docs/GLOSSARY.md` 时生成本骨架；已存在则跳过不覆盖。

## kit 基础术语

| 术语 | 定义 |
|---|---|
| core 规则 | 语言中立、与流程无关的纪律与通用硬约束规则，always_on/model_decision 触发 |
| stack 规则 | 绑定特定语言/框架的硬约束规则，glob 触发共存隔离，frontmatter 带 stack 键 |
| 适配器 | 把 kit 单一源转换为目标 IDE 布局与 frontmatter 格式的安装映射层，只转格式不改语义 |
| Delta | 变更目录 `changes/<变更名>/specs/<域>/spec.md` 中的行为契约增量（新增/修改/废弃），归档时合并回 `specs/` 当前真相 |
| 交接三件套 | 跨会话交接内容：已完成 / 进行中 / 下一步 + 验证证据，回写 tasks.md 备注或 implementation.md |

## 编号体系术语

| 术语 | 定义 |
|---|---|
| SP-xx | specs 内原子规则编号，跨变更长期唯一；域缩写登记于 `specs/_domains.md`，一次分配不重复、永不复用 |
| R-xx | 需求澄清条目编号（`/grill-me` 产出） |
| FP-xx | 功能点编号（`/requirement-design` 产出） |
| T-xx | 开发任务编号（tasks.md），须回溯到 FP 或 SP |

## 项目业务术语（安装后按项目填写）

| 术语 | 定义 |
|---|---|
| （暂无） | |