---
trigger: glob
glob:
  - "**/*.java"
stack: java
description: Java 数据栈陷阱（SQL Server 连接串 Unicode 隐式转换/Hibernate IDENTITY 批处理/H2 存量库 DDL）；触碰 Java 源码时自动注入，中立数据纪律见 core sql-data 规则。
---
# Java 数据栈陷阱（stack java）

中立 SQL/索引/批处理/DDL 基线见 core `sql-data.md`；本规则只写已验证的方言与 ORM 陷阱。

## 查询与索引
- **SQL Server 连接串必须 `sendStringParametersAsUnicode=false`**：默认 true 使 VARCHAR 列按 nvarchar 隐式转换，索引失效。

## 写入与批处理
- **IDENTITY 主键下 Hibernate 禁用 JDBC 批处理**：批量写入用 `JdbcTemplate.batchUpdate`（驱动层批量提交），不要指望 saveAll+`hibernate.jdbc.batch_size`；超大规模分批提交防事务日志膨胀。

## DDL 与模型
- **H2 存量库 `ddl-auto: update` 添加 NOT NULL 列必须指定 DEFAULT**，否则启动失败。
- Entity 不出数据访问边界，跨层 DTO/Projection，避免 JPA 懒加载序列化泄漏。