---
trigger: glob
glob:
  - "**/test_*.py"
  - "**/*_test.py"
  - "**/tests/**"
stack: python
description: Python 测试栈硬约束（pytest + monkeypatch + pytest-cov）；触碰 Python 测试代码时自动注入，中立测试纪律见 core testing 规则。
---
# Python 测试栈硬约束（stack python）

中立测试纪律（GWT/覆盖优先级/零装饰/回归单例）见 core `testing.md`；本规则只写 Python 栈设施与陷阱。

## 结构与断言设施
- 测试文件 `test_<被测模块>.py` 或 `<被测模块>_test.py`；测试函数 `test_<被测名>_<场景>_<期望结果>`。
- 多组数据用 `@pytest.mark.parametrize`；断言用原生 `assert` 配合 pytest 断言重写（禁 unittest 风格 self.assert* 混用）。
- 异常用 `pytest.raises` 并匹配消息/类型；金额比较用 `Decimal` 相等，禁浮点近似断言承载金额。

## 隔离与分层设施
- fixture 管前置/清理（`yield` fixture 保证释放）；临时文件用 `tmp_path`，禁写真实工作目录。
- 外部依赖用 `monkeypatch`/`unittest.mock.patch` 只 Mock 直接依赖，禁止 Mock 被测函数自身跳过逻辑。
- 单元测试不启动应用容器/真实 DB/网络；集成测试按项目既有分层放置（marker 区分，如 `@pytest.mark.integration`）。
- 交互验证只验证关键交互（`mock.assert_called_once_with` 等），不过度验证内部实现细节。

## 并发编排与覆盖
- 并发竞态用 `threading.Event`/`Barrier` 编排，禁止 sleep。
- 覆盖率用 pytest-cov（`pytest --cov=<pkg> --cov-report=term-missing`）；覆盖率门禁阈值以项目约定为准，无约定时核心分支必须有失败路径测试。