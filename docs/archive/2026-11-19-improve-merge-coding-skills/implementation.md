# Implementation: improve-merge-coding-skills

## 功能概述

编码阶段三技能（senior-dev / tdd / ui-dev）合并为单一入口 `/senior-dev`（FP-01），内部按"任务轨道（后端/前端/全栈）× 方法模式（默认/TDD）"判定；TDD 铁律与 Red-Green-Refactor 循环、前端双轨选型/自查清单/前后端交接契约语义完整保留（FP-02）；技能清单 11 → 9，lint/沙箱断言与全部交叉引用同步（FP-03）。

## 关键实现说明

- skills/senior-dev/SKILL.md 重写为合并结构：公共工作规则 → 轨道与模式判定 → TDD 模式节（铁律八条逐字保留）→ 前端轨道节（双轨/内部推演/轨道A 工作流/自查清单）→ 前后端链式协作（跨技能调用改为技能内部轨道切换，contract.md 落盘与逐字段回归核对不变）→ Bug 修复/重构工作法 → 统一交付模板（TDD 循环记录、测试清单、前后端链式为条件节）。
- 删除 skills/tdd/SKILL.md、skills/ui-dev/SKILL.md 及空目录；保留 senior-dev 名使上游 5 个技能引用免改。
- lint.ps1：$SkillNames 9 件、$LegacyNames 增补 tdd/ui-dev（子串匹配防残留）、计数断言 9；verify-sandbox.ps1 三处落点计数 9。
- 交叉引用同步：README（三层结构/链图/阶段表/技能清单/推荐用法）、根 AGENTS.md 与 templates/AGENTS.md 链图、PORTING.md 降级契约行（前端→后端链式不再依赖跨技能调用）、code-review（TDD 模式测试清单表述）、product-senior 链图、spec（description/边界/目录契约）。
- 措辞纪律落实：被 lint 扫描文件无小写 tdd/ui-dev 残留，统一大写 TDD 与"前端轨道"表述。

## 验证证据

- `adapters\lint.ps1`：通过 36 / 失败 0，exit=0。
- `adapters\verify-sandbox.ps1`：通过 21 / 失败 0（沙箱已清理），exit=0；三 IDE skills 落点均 9 件，同名跳过/幂等替换/glob 共存断言全过。
- PowerShell Parser：install.ps1 / lint.ps1 / verify-sandbox.ps1 均零错误；bash -n install.sh 零错误。
- BOM 门禁：SearchReplace 编辑剥掉了 lint.ps1 与 verify-sandbox.ps1 的 UTF-8 BOM，已按 PORTING.md 第 4 节检测补回并复验 Parser 零错误（install.ps1 BOM 保持）。
- /spec verify 四类校验：① 结构（proposal 四节齐全、Non-goals 非空、tasks 标准清单语法、无占位符）通过；② 追溯（FP-01/02/03 均被 T 覆盖，T-01~T-07 均回溯 FP，无 delta 故 SP 校验不适用，无悬空引用）通过；③ 归档前置（tasks 全勾选）通过；④ 并行冲突（仅一个活跃变更）通过。

## 边界与风险

- 用户侧 /tdd、/ui-dev 斜杠命令失效，统一改用 /senior-dev；旧名由 lint $LegacyNames 门禁防复活。
- 本变更为纯流程/文档变更，无 SP 规则新增/修改/废弃，归档走 `--no-delta`。
- 运行时注入行为（IDE 是否真的按 glob 注入）headless 不可验，仍按 PORTING.md 第 3 节手动核验清单执行。

## 归档记录

- 结案日：2026-11-19；归档方式：`/spec archive improve-merge-coding-skills --no-delta`。
- --no-delta 留因：本变更为纯流程/文档变更（技能合并与清单/引用同步），未新增/修改/废弃任何 SP 规则，故无 delta 合入 specs/。
- 归档前 verify 四类校验全通过；tasks 7/7 勾选；lint 36/0 与 verify-sandbox 21/0 为结案证据。
