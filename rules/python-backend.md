---
trigger: glob
glob:
  - "**/*.py"
  - "pyproject.toml"
  - "requirements.txt"
stack: python
description: Python 后端编码硬约束与构建验证命令口径；触碰 Python 源码或依赖清单时自动注入。
---
# Python 后端硬约束（stack python）

> 示例栈规则：验证 kit「换语言只加栈规则」机制的正确性用例；条款为 Python 社区主流基线，项目既有约定优先。

## 构建与验证命令口径
- 环境：虚拟环境隔离（venv/uv），依赖锁定（pyproject.toml + lock 文件或 requirements.txt 钉版本），禁止全局装依赖。
-  lint/格式：`ruff check .` 与 `ruff format --check .`（项目既有 flake8/black 等等价工具沿用，不混用两套）。
- 全量回归：`pytest -q`；定向：`pytest -q path/to/test_file.py::test_name`。
- 测试全绿才可回写 tasks.md 勾选；既有红测如实登记归属，不夹带修复。

## 铁律
- 零裸奔异常：禁止空 `except:` 与 `except Exception: pass`；捕获必须记录或重抛（`raise ... from e` 保留 cause 链）；禁止用异常控制正常流程。
- 零硬编码：配置/密钥/地址/魔术数字统一配置对象、常量或枚举（`enum.Enum`）；密钥进环境变量或密钥管理，不进代码与仓库。
- 重构不改逻辑；改动不得超出 `proposal.md` 的 What Changes / Non-goals 边界。
- 完整交付：可运行完整代码，禁止伪代码、TODO 截断、调试垃圾（print 调试残留）。

## 语言与设计
- 公开函数/方法带类型注解（参数与返回值）；数据载体优先 `dataclass`（不可变场景 `frozen=True`）；禁可变默认参数（`def f(x=[])`）。
- 金额用 `decimal.Decimal`（字符串构造），禁浮点承载金额；时间统一 `datetime` 带时区（`zoneinfo`），禁 naive 时间跨边界传输。
- 资源一律上下文管理器（`with`）：文件/连接/锁；生成器流式处理大批量数据，禁止全量入内存。
- 函数超 80 行、模块超 500 行视为坏味道主动拆分；guard clause 替代深层嵌套；命名揭示意图（snake_case 函数/变量、PascalCase 类、UPPER_SNAKE 常量）。
- 更新/删除必须校验影响行数（`cursor.rowcount` 或 ORM 等价物），防静默失败。
- 让非法状态不可表示：优先枚举/字面量类型/值对象消除非法组合；外部数据只在边界入口解析校验一次（pydantic 等等价设施），内部信任。

## 工程与并发
- 依赖注入显式传参或轻量容器，禁模块级可变全局状态承载请求/任务级数据；`threading.local` 用完必清理。
- IO 密集并发用 `asyncio`（显式任务组+异常分支）或线程池（`concurrent.futures` 显式 max_workers+拒绝语义），禁无界创建线程/任务；CPU 密集用进程池。
- check-then-act 必须加锁（`threading.Lock`）或原子设施；锁顺序全局一致；异步代码禁阻塞调用（同步 IO/`time.sleep`）入事件循环。
- 对外调用超时/重试（仅幂等）/限流三件套（httpx/aiohttp 连接池复用）；写接口防重提交（幂等键/唯一约束）。
- 缓存 key 前缀常量化、TTL 集中+随机抖动；Cache-Aside 先更新 DB 再删缓存，禁止事务提交前写缓存。

## 日志
- 标准库 `logging`（或项目既有 structlog 等），禁止 print 承载运行日志；异常日志必带 `exc_info` 或 `logger.exception`。
- 分级：ERROR 需人工介入 / WARN 可自愈 / INFO 关键节点 / DEBUG 诊断；循环体内慎打 INFO。
- 敏感信息（密码/Token/手机号/身份证）禁原文输出；关键操作带业务标识。