---
trigger: glob
glob:
  - "**/*Test.java"
  - "**/src/test/**"
stack: java
description: Java 测试栈硬约束（JUnit5 + Mockito + AssertJ + Spring Boot Test）；触碰 Java 测试代码时自动注入，中立测试纪律见 core testing 规则。
---
# Java 测试栈硬约束（stack java）

中立测试纪律（GWT/覆盖优先级/零装饰/回归单例）见 core `testing.md`；本规则只写 Java 栈设施与陷阱。

## 结构与断言设施
- 多组数据用 `@ParameterizedTest`；测试类 = 被测类名 + Test。
- AssertJ 流式断言；异常用 `assertThatThrownBy`；金额比较用 `isEqualByComparingTo`。

## 隔离与分层设施
- 纯逻辑用 `@ExtendWith(MockitoExtension.class)`，禁止单元测试启动 Spring 容器；集成测试 `@SpringBootTest` 分层放置，数据库按项目既有测试约定（不引入 H2/JPA 专属设施）。
- 只 Mock 直接依赖，禁止 `@Spy` 被测类跳过逻辑；`verify` 只验证关键交互，不过度验证内部实现细节。

## 并发编排
- 并发竞态用 CountDownLatch 编排，禁止 sleep。