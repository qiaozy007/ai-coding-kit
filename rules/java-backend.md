---
trigger: glob
glob:
  - "**/*.java"
  - "pom.xml"
stack: java
description: Java/Spring 后端编码硬约束与构建验证命令口径；触碰 Java 源码或 pom.xml 时自动注入。
---
# Java 后端硬约束（stack java）

> 萃取自源项目已验证的 senior-dev / architecture-design 技能规范章节；工作流与交付模板仍见对应技能。规则与 AGENTS.md 冲突时规则优先。

## 构建与验证命令口径
- 编译：`mvn -o compile`（离线，空输出即通过）；全量回归：`mvn -o test`；定向：`mvn -o test "-Dtest=类名"`。
- 测试全绿才可回写 tasks.md 勾选；既有红测如实登记归属，不夹带修复。

## 铁律
- 零空指针：入参、外部返回值、查询结果一律判空；集合用 `isEmpty()`；`Optional` 只作返回值，不作字段/参数/集合元素。
- 零裸奔异常：`log.error("上下文, key={}", key, e)` 必须带异常对象；禁止空 catch、吞堆栈；业务异常继承项目基类并携带错误码，禁止用异常控制正常流程。
- 零硬编码：配置/密钥/地址/魔术数字统一配置文件、常量类或枚举。
- 重构不改逻辑；改动不得超出 `proposal.md` 的 What Changes / Non-goals 边界。
- 先减后加：新增功能前先移除复杂度（删死代码、合并重复、简化条件），再写新逻辑。
- 完整交付：可编译完整代码，禁止伪代码、TODO 截断、调试垃圾。

## 语言与设计
- 以项目实际 JDK 为准（Java 17：record/var/文本块/模式匹配可用）；金额用 `BigDecimal`（字符串构造、`compareTo` 比较）；时间统一 `java.time`；循环内拼接用 `StringBuilder`。
- 方法超 80 行、类超 500 行视为坏味道主动拆分；参数超 4 个用参数对象；guard clause 替代深层嵌套；if/for/while/try 一律带大括号。
- 命名揭示意图（类大驼峰/方法小驼峰/常量全大写下划线，禁拼音与无意义简写）；类、接口、public 方法写完整文档注释；重写 `equals` 必重写 `hashCode`；优先不可变（record/final/`List.copyOf`）。
- 更新/删除必须校验影响行数，防静默失败（改 0 行却返回成功）。
- 让非法状态不可表示：优先枚举/密封类型/值对象消除非法组合；外部数据只在边界入口解析校验一次，内部信任；禁止压制编译器告警。

## Spring 工程
- 构造器注入（`@RequiredArgsConstructor`），禁止字段 `@Autowired`；单例 Bean 禁止实例字段存请求/任务级状态；ThreadLocal 用完必 `remove()`；监听器/回调注册必须对应注销，大对象引用及时释放。
- 配置用 `@ConfigurationProperties` 类型安全绑定；`@Transactional` 仅 Service 公开方法 + `rollbackFor = Exception.class`，纯查询只读。
- 同类自调用不走代理（事务/@Async 失效）须拆 Bean；事务内禁远程调用/文件 IO/慢查询/发消息；`REQUIRES_NEW` 须说明理由并评估连接池耗尽风险。
- 禁循环单条查库（N+1）：IN/JOIN FETCH/@EntityGraph/批处理；批量写入用 `JdbcTemplate.batchUpdate` 或 saveAll+batch_size（IDENTITY 陷阱与超大规模分批提交纪律见 sql-data-java 规则）。
- 深度 OFFSET 禁用，改 keyset 分页；SQL 一律参数绑定，动态表名列名白名单。

## 并发与防护
- 线程池按用途隔离，`ThreadPoolExecutor` 显式参数+拒绝策略，禁止 `Executors` 快捷无界池；`CompletableFuture` 显式专用池+异常分支（exceptionally/handle）。
- check-then-act 必须加锁或原子类；`volatile` 只保证可见性；加锁顺序全局一致；`synchronized` 锁私有 final 字段；`parallelStream` 禁用于含 IO/共享外部状态。
- 缓存 key 前缀常量化、TTL 集中+随机抖动；Cache-Aside 先更新 DB 再删缓存，禁止事务提交前写缓存。
- 对外调用超时/重试（仅幂等）/限流三件套，HTTP 连接池复用；写接口防重提交（幂等键/唯一约束）；敏感数据后端脱敏，不依赖前端。
- 跨库无分布式事务时用最终一致：本地消息表/状态标记+补偿重试，明确幂等键；大批量流式读取+分批写入，禁止全量入内存。

## 日志
- SLF4J 占位符 `{}`，禁止字符串拼接、`System.out`、`printStackTrace`。
- 分级：ERROR 需人工介入 / WARN 可自愈 / INFO 关键节点 / DEBUG 诊断；循环体内慎打 INFO。
- 敏感信息（密码/Token/手机号/身份证）禁原文输出；关键操作带业务标识（酒店编码/批次号等）。