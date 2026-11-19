---
trigger: glob
glob:
  - "**/*.vue"
stack: vue
description: Vue3 前端编码硬约束（含前端通用硬约束：XSS/四态/双层解析/最小 diff）；触碰 .vue 文件时自动注入。
---

# 前端编码规则（stack vue）

总原则：存量代码以项目现状为准、做最小 diff；新增代码按下列规则执行。前端通用硬约束（四态/XSS/双层解析/交互防御）在本规则内一并承载；非 Vue 栈项目自行增补对应栈前端规则。

- **技术栈**：存量页面保持原有技术栈与代码风格；新增页面默认 Vue3 `<script setup lang="ts">` + TypeScript，禁隐式 any；UI 库沿用项目既有（如 Element-Plus），不引入第二套。
- **状态与请求**：Pinia 管跨页状态；axios 封装统一请求层，拦截器处理 loading、错误提示与响应双层解析（业务码与 HTTP 码分离），页面不直接写裸 axios。
- **样式**：SCSS scoped，沿用既有设计语言与变量，不写全局污染样式，不随意操作 DOM。
- **异步四态**：每个数据页面覆盖 loading/success/empty/error 四种状态，禁止只写 happy path。
- **表单**：类型与长度校验齐全；提交按钮防重复点击（loading 或禁用）；后端校验失败要回显到字段。
- **安全**：所有渲染外部内容的路径做 XSS 防护（禁用 v-html 渲染不可信内容，必要时先 sanitize）；敏感信息不进 localStorage 明文存储。
- **交付节奏**：最小 diff，拒绝过度封装与过早抽象；组件拆分以「复用或单文件过长」为依据，不为拆而拆。
- **组件与类型纪律**：SFC 顺序 template → script → style scoped；穿透用 `:deep()`，禁改全局样式；简单 `interface` 建模，禁类型体操；Element-Plus 优先，禁手写 table/modal；全局共享状态进 store，页面状态留 ref。
- **目录与请求层**：`views/`/`components/`/`stores/`/`router/`/`api/` 目录；api 按业务域分文件，函数与后端契约一一对应，禁组件内裸写 URL 字符串。
- **交互防御**：危险操作二次确认（文案含对象与后果），批量确认展示已选清单与数量；输入防抖 300-500ms；`null` 显示 `-`、`0` 是合法值（用 `!= null` 判断）。