# docs/INDEX.md — 文档唯一入口（ai-coding-kit 模板）

> 会话开始先读本文件。本文件由 `/spec` 技能维护：域清单与活跃变更清单随变更推进更新，禁止手工绕过 `/spec` 直接改状态。
> 安装说明：`-WithTemplates` 仅在目标项目缺失 `docs/INDEX.md` 时生成本骨架；已存在则跳过不覆盖。也可用 `/spec init` 复制 docs 三区骨架。

## 1. 域清单（specs/ 当前真相）

| 域目录 | 显示名 | SP 缩写 | 提炼状态 | 说明 |
|---|---|---|---|---|
| （示例）example | 示例域 | EX | 暂不创建 | 首个变更涉及该域时再提炼 spec.md |

> 域缩写唯一登记在 `specs/_domains.md`；SP 范围注记须与 `specs/<域>/spec.md` 实际编号一致（作废占位号除外）。

## 2. 活跃变更清单（changes/ 进行中）

| 变更名 | 目标 | 产物完成度 | 状态 |
|---|---|---|---|
| （暂无） | | | |

> 产物完成度口径：仅 proposal / proposal+clarification / +delta+design / +tasks / +implementation（齐备）。
> 登记与移除由 `/spec propose`、`/spec archive` 负责；`/spec status` 检出未登记目录或悬空登记。

## 3. 导航

- `specs/`：当前真相，编码前必读对应域 `spec.md`。
- `changes/<变更名>/`：进行中变更，四类产物 proposal → specs(delta)+design → tasks → implementation。
- `archive/<YYYY-MM-DD>-<变更名>/`：已结案，只读，不得作为当前行为依据。
- `GLOSSARY.md`：术语表，术语冲突时以该表为准。
- `reference/`：外部/上游只读资料；`manual/`：面向使用者手册。