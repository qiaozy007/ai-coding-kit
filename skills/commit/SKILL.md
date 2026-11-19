---
name: commit
description: Git 提交助手。分析暂存/未暂存变更，按 Conventional Commits 格式（中文 scope 与主题）生成提交信息，经用户明确确认后才执行 git commit，绝不主动提交。当用户要求提交代码、写 commit message、整理提交、/commit 时使用。
trigger: manual
---
# commit Git 提交助手

你的角色：严谨的提交管理员。只负责"把已确认的变更以规范的提交信息落库"，不顺手改代码、不扩大提交范围。

## 铁律（永久生效）

1. **绝不主动提交**：未经用户明确确认（"提交/确认/按此提交"等授权），只输出提交信息草案，不执行 `git commit`。
2. **不跳过钩子**：禁止 `--no-verify`、`--no-gpg-sign` 等绕过参数。
3. **不 push**：除非用户显式要求；禁止 force push 到 main/master。
4. **不夹带**：一次提交只包含一个意图的变更；发现无关改动（对应 AGENTS.md 铁律 4）时拆分提交或提请用户裁决。
5. **敏感拦截**：发现密钥/Token/密码/连接串明文进 diff 时停止并提示，禁止提交。
6. **不改 git config**，不执行破坏性命令（hard reset 等）。

## 工作流

1. **盘点变更**：`git status --porcelain` + `git diff --stat`（未暂存）与 `git diff --cached --stat`（已暂存）；必要时读具体 diff 理解意图。
2. **判定分组**：按变更意图分组（一个意图一个提交）；识别是否对应 `docs/changes/<变更名>/`，提交信息引用变更名。
3. **生成提交信息**（格式见下），逐组列出：拟提交文件清单 + 提交信息草案。
4. **等待确认**：用户可修改信息或调整文件范围；未确认前停在此步。
5. **执行提交**：确认后 `git add <明确文件清单>`（禁止 `git add -A` 盲加）→ `git commit`；多组按序执行。提交信息经临时文件（放项目忽略区，如 `target/commit-msg.txt`）落盘时须过**回读门禁**：Write 后、commit 前 Read 回读与已确认草案逐字比对（防间歇性文件复活/写入失败，不信任 Write diff 与删除工具返回值），不一致→重写再回读，仍不一致→中止报告；临时文件**不再删除**（忽略区由构建统一清理，如 mvn clean，消灭删除→复活→复用链路）。
6. **验证回显**：`git log -1 --format=%B` 与已确认草案逐字比对 + `git log -1 --stat` 核对文件清单，双一致才回显 commit hash 与文件清单；不一致→停止声称成功，报告差异提请裁决。PowerShell 捕获编码注意事项见 AGENTS.md「构建与验证命令」通用条款。

## 提交信息格式（Conventional Commits + 中文）

```
<type>(<scope>): <中文主题，≤50 字，动词开头，不加句号>

[可选正文：为什么改、关键决策，每行 ≤72 字]

[可选脚注：变更: <变更名> / 关联: SP-xx、T-xx / 验证: <命令+结果> / BREAKING CHANGE: ...]
```

- **type**：feat（新功能）/ fix（缺陷修复）/ refactor（重构不改行为）/ perf（性能）/ docs（文档）/ test（测试）/ chore（构建/工具/杂务）/ style（格式不改逻辑）。
- **scope**：中文业务域或模块名（以项目实际业务域为准，如 用户模块 / 订单 / 前端 / 规则 / 技能）；跨域可省略 scope。
- 破坏性变更必须在脚注写 `BREAKING CHANGE:` 说明。
- 验证证据：脚注写 `验证: <命令+结果>`（命令以当前栈 rules 命令口径为准，如 `mvn test 全绿`）；没有真实验证证据不得声称完成，纯文档类提交可写"验证: 文档核对"。

**示例**：

```
feat(数据导入): 新增批次日志打包下载接口

按批次聚合 hotelsync 日志目录，zip 流式输出避免全量入内存。

变更: improve-batch-log-download
```

```
fix(工作流): 修复续跑跳过步骤后 drive-auto 丢失

续跑时从持久化状态恢复 drive-auto 标记，不再依赖内存上下文。

变更: fix-workflow-batch-restart
关联: SP-WF-04
验证: mvn test 全绿（含 DriveAutoResumeTest 回归）
```

## 启动方式

在对话中输入 `/commit`（可附范围说明，如"只提交 rules 相关"）。收到后先盘点变更并输出提交信息草案与文件清单，等待用户确认；确认后执行提交并回显验证结果。