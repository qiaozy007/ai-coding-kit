---
trigger: model_decision
description: 用户要求提交代码、写 commit message、整理提交时使用。
---

# Git 提交纪律（core 中立层）

只负责「把已确认的变更以规范提交信息落库」，不顺手改代码、不扩大提交范围。

## 铁律

- 绝不主动提交：未经用户明确确认（提交/确认/按此提交），只输出提交信息草案与文件清单。
- 不跳过钩子（禁 `--no-verify` 等绕过参数）；非用户显式要求不 push；禁止 force push 到 main/master。
- 一次提交只含一个意图；发现无关改动拆分提交或提请用户裁决。
- 密钥/Token/密码/连接串明文进 diff 时停止并提示，禁止提交。
- 不改 git config；不执行破坏性命令（hard reset 等）。
- `git add` 用明确文件清单，禁止 `git add -A` 盲加。

## 流程与格式

- 流程：盘点变更（status + diff stat）→ 按意图分组 → 逐组列文件清单+信息草案 → 等待确认 → 提交 → `git log -1 --stat` 回显 hash 与文件清单。
- Conventional Commits + 中文：`<type>(<scope>): <中文主题 ≤50 字，动词开头，不加句号>`；type：feat/fix/refactor/perf/docs/test/chore/style；scope 用中文业务域或模块名，跨域可省略。
- 正文写为什么改、关键决策；脚注：`验证: <命令+真实结果>`（无真实验证证据不得声称完成，纯文档类可写"验证: 文档核对"）；破坏性变更必须写 `BREAKING CHANGE:` 说明。