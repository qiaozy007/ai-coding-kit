# Design: improve-merge-coding-skills

## 功能点

- FP-01 单一编码入口：/senior-dev 承载后端/前端/全栈任务，内部按"任务轨道 × 方法模式"判定，用户无需在三个技能间选择。
- FP-02 门禁与契约不降级：TDD 铁律（测试先行/最小步长/最小实现/重构不增行为/零装饰测试等）在 TDD 模式下逐字保留并强制生效；前端双轨选型、交付前自查清单、前后端交接契约（contract.md 落盘与逐字段核对）语义完整保留。
- FP-03 清单与交叉引用同步：技能清单 11 → 9，lint/沙箱断言、README、AGENTS.md×2、PORTING.md 及技能间引用全部同步，lint.ps1 与 verify-sandbox.ps1 全绿。

## 架构决策

- 保留 senior-dev 名而非新造 /dev：上游 5 个技能对 /senior-dev 的引用全部免改，变更面最小；tdd、ui-dev 旧名进入 lint.ps1 $LegacyNames 防止残留复活。
- 技能内部结构：公共工作规则（原 senior-dev 六条）→ 轨道与模式判定 → TDD 模式节（原 tdd 铁律/循环/按场景工作法）→ 前端轨道节（原 ui-dev 双轨/内部推演/轨道A 工作流/自查清单）→ 前后端链式协作（改为内部轨道切换：命中触发条件即切后端轨道继续实施，contract.md 落盘与回归核对不变；豁免须声明原因）→ Bug 修复/重构工作法 → 统一交付模板（TDD 循环记录与前端验证步骤为条件节）。
- 模式判定条件（命中任一即 TDD 模式，铁律永久生效）：① 用户显式要求 TDD；② 核心业务逻辑（金额/状态流转/数据转换/并发编排）；③ Bug 修复需回归锁定；④ 重构前需特征测试保护。未命中走默认模式，仍受 core testing 规则约束。
- 措辞纪律：合并后正文与所有被 lint 扫描的文件（skills/rules/templates/README）不得出现小写旧名 tdd、ui-dev（$LegacyNames 为子串匹配），统一用大写 TDD 与"前端轨道"表述；斜杠命令只允许 /senior-dev。
- 脚本编码：lint.ps1 编辑后必须保持 UTF-8 带 BOM，并用 PowerShell Parser 验证零错误（PORTING.md 第 4 节硬约束）。

## 验证口径

- `powershell -NoProfile -ExecutionPolicy Bypass -File adapters\lint.ps1` 全绿（exit=0）。
- `powershell -NoProfile -ExecutionPolicy Bypass -File adapters\verify-sandbox.ps1` 全绿（exit=0）。
- 本变更为纯流程/文档变更，无 SP 规则新增/修改/废弃，归档时走 `--no-delta`。
