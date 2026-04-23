# Dify Backend 功能模块总表（基于 `api/` 代码深度补全）

> 这份文档面向“复刻一个接近 Dify 的后端系统”，重点不是目录解释，而是**产品级功能拆解**。

---

## 1. 项目定位

Dify 后端是一套 **多租户 AI 应用平台后端**，不是单一聊天接口。

它同时覆盖 5 层能力：

1. **平台层**：账号、租户、成员、权限、计费、企业能力。
2. **应用层**：应用、Prompt、模型、知识库、工作流、Agent、工具。
3. **运行时层**：Web、Service API、MCP、Webhook、文件、音频。
4. **扩展层**：插件、模型提供商、工具提供商、外部数据源。
5. **基础设施层**：DB、Redis、Celery、Storage、Vector DB、Sandbox、SSRF、监控。

---

## 2. 总体架构

### 2.1 代码分层

| 层         | 目录                                                         | 职责                                                              |
| ---------- | ------------------------------------------------------------ | ----------------------------------------------------------------- |
| 接口层     | `api/controllers/`                                           | 提供 HTTP / REST / MCP / Trigger 接口，负责鉴权、参数校验、序列化 |
| 服务层     | `api/services/`                                              | 编排业务逻辑，连接模型、知识库、工作流、插件、计费                |
| 核心引擎层 | `api/core/`                                                  | 工作流引擎、RAG、Prompt、模型运行时、工具、插件边界               |
| 数据层     | `api/models/`, `api/repositories/`, `api/core/repositories/` | ORM 模型、仓储、执行记录                                          |
| 基础设施层 | `api/extensions/`, `api/configs/`, `api/libs/`               | DB、Redis、Celery、Storage、登录态、Sentry、OTel、SSRF            |
| 异步层     | `api/tasks/`, `api/schedule/`                                | 索引任务、工作流后台执行、清理任务、定时任务                      |

### 2.2 对外接口面

| 接口面      | 前缀           | 作用                     |
| ----------- | -------------- | ------------------------ |
| Console API | `/console/api` | 后台控制台管理           |
| Web API     | `/api`         | WebApp 最终用户运行时    |
| Service API | `/v1`          | 第三方系统服务端调用     |
| Files API   | `/files`       | 文件上传、预览、签名访问 |
| Inner API   | `/inner/api`   | 内部服务、插件、企业同步 |
| Trigger API | `/triggers`    | Webhook、插件入口        |
| MCP API     | `/mcp`         | MCP Server 协议入口      |

---

## 3. 平台基础能力

### 3.1 账号、租户、权限

| 模块         | 功能点                 | 说明                               |
| ------------ | ---------------------- | ---------------------------------- |
| 账号体系     | 邮箱登录/登出          | 控制台会话态登录和退出             |
| 账号体系     | 邮箱注册               | 注册、验证码、初始化工作区         |
| 账号体系     | 忘记密码               | 验证码、重置密码                   |
| OAuth 登录   | GitHub / Google        | 第三方账号登录                     |
| 数据源 OAuth | Notion 等              | 外部数据源授权                     |
| 多租户       | Tenant / Workspace     | 工作区隔离应用、知识库、模型、成员 |
| 成员体系     | Owner / Admin / Editor | 成员角色权限控制                   |
| API Token    | App / Dataset Token    | 应用与知识库对外调用凭证           |
| Web 身份     | EndUser / Passport     | WebApp 最终用户身份                |

### 3.2 系统初始化与通用配置

| 模块       | 功能点                          | 说明                               |
| ---------- | ------------------------------- | ---------------------------------- |
| 系统初始化 | Setup / Init Validate           | 检查是否初始化、是否允许安装       |
| 系统信息   | Version / Ping / Feature / Spec | 版本、健康检查、功能开关、接口说明 |
| 通知中心   | Notification / Dismiss          | 当前用户站内通知                   |
| 标签体系   | Tags                            | 应用和对象分类                     |
| 文件配置   | Upload Config                   | 文件大小、批量数、格式限制         |

---

## 4. Console 后台功能

### 4.1 应用管理

| 模块         | 功能点          | 说明                             |
| ------------ | --------------- | -------------------------------- |
| App 基础     | 创建应用        | 创建聊天、生成、工作流等应用     |
| App 基础     | 修改应用        | 名称、图标、描述、模式、可见性   |
| App 基础     | 删除应用        | 删除应用及其关联资源             |
| Model Config | 模型配置        | 模型、参数、系统提示词、功能开关 |
| Prompt       | 高级提示模板    | 复杂 Prompt 模板管理             |
| DSL          | 导入 / 导出     | 应用配置跨环境迁移               |
| Site         | 发布站点配置    | WebApp 品牌与访问设置            |
| Generator    | 控制台调试运行  | 后台直接调试聊天/生成            |
| Annotation   | 标注与纠错      | 对回答进行标注修正               |
| Statistics   | 应用统计        | 调用量、Token、消息、会话统计    |
| Logs         | 工作流/应用日志 | 查看运行历史和执行轨迹           |
| Variables    | 对话/流程变量   | 配置和查看变量                   |
| Agent        | Agent 能力配置  | 应用级 Agent 设置                |
| MCP Server   | 应用 MCP 配置   | 应用级 MCP Server 能力           |

### 4.2 Explore / Trial

| 模块          | 功能点           | 说明                         |
| ------------- | ---------------- | ---------------------------- |
| 推荐应用      | Recommended Apps | 推荐应用列表与详情           |
| Trial         | 试用运行         | 先试跑聊天、工作流、音频能力 |
| Banner        | 引导位           | 探索页推荐与引导             |
| Installed App | 已安装能力       | 查看租户已启用能力           |

### 4.3 Workspace 管理

| 模块                 | 功能点              | 说明                         |
| -------------------- | ------------------- | ---------------------------- |
| Workspace            | 工作区信息          | 工作区配置读取与更新         |
| Members              | 成员管理            | 邀请、删除、角色变更         |
| Models               | 模型列表            | 当前租户可用模型             |
| Provider Credentials | 模型凭证配置        | API Key / Endpoint / Region  |
| Load Balancing       | 多 Key / 多部署轮询 | 模型调用分流与容灾           |
| Tool Providers       | 工具管理            | 内置/API/工作流/MCP 工具     |
| Trigger Providers    | 触发器管理          | 触发器种类与配置             |
| Endpoint             | 插件/服务入口       | 管理外部 endpoint            |
| Plugins              | 插件管理            | 安装、删除、启停、升级、配置 |

### 4.4 扩展与周边管理

| 模块                 | 功能点            | 说明                               |
| -------------------- | ----------------- | ---------------------------------- |
| API-Based Extension  | API 扩展          | 用 API Endpoint + Key 注册扩展     |
| Code-Based Extension | 代码扩展查询      | 查询本地代码型扩展能力             |
| Files                | 上传与预览        | 控制台文件上传、文本预览、格式限制 |
| Remote Files         | 远程文件          | 管理远端文件代理与导入             |
| API Keys             | App / Dataset Key | 创建、查看、删除 API Key           |

### 4.5 商业化与企业能力

| 模块       | 功能点         | 说明                            |
| ---------- | -------------- | ------------------------------- |
| Billing    | 订阅购买       | 专业版/团队版订阅入口           |
| Billing    | Invoices       | 发票记录查询                    |
| Billing    | Partner Sync   | 合作伙伴租户绑定同步            |
| Compliance | 合规文档下载   | 下载链接与审计信息              |
| Enterprise | 企业工作区同步 | 企业租户与 ownerless 工作区管理 |
| Enterprise | 应用 DSL 管理  | 企业环境应用导入导出            |

---

## 5. Web / Service 运行时功能

### 5.1 WebApp 运行时

| 模块             | 功能点                   | 说明                           |
| ---------------- | ------------------------ | ------------------------------ |
| Access Mode      | Web 访问模式             | 公开访问、受限访问、登录要求   |
| Passport         | Web 身份票据             | 最终用户访问票据               |
| Login            | Web 登录/状态/退出       | Web 用户认证                   |
| App Meta         | Parameters / Meta / Site | 获取应用参数、元信息、站点配置 |
| Chat             | Chat Messages            | 聊天提交、流式返回、停止生成   |
| Completion       | Completion Messages      | 非对话式文本生成               |
| Conversations    | 会话管理                 | 新建、列表、重命名、删除       |
| Messages         | 消息管理                 | 详情、历史、反馈、建议问题     |
| Saved Messages   | 收藏消息                 | 保存重要回复                   |
| Files            | 附件上传                 | 图片/文档/附件上传             |
| Remote Files     | 远程文件导入             | 用链接导入外部文件             |
| Audio            | STT / TTS                | 音频转文本、文本转语音         |
| Workflow         | Workflow Run / Stop      | 运行工作流、停止任务           |
| Workflow Events  | 事件流回放               | 节点级执行事件流               |
| Human Input Form | 人工补录表单             | 暂停后由用户继续完成流程       |

### 5.2 Service API

| 模块          | 功能点                   | 说明                      |
| ------------- | ------------------------ | ------------------------- |
| App Runtime   | Chat / Completion        | 第三方系统调用应用        |
| Runtime Meta  | Parameters / Info / Meta | 获取参数和应用信息        |
| Conversations | 会话管理                 | 管理会话生命周期          |
| Messages      | 消息管理                 | 查询消息与历史            |
| Workflow      | Workflow 执行            | 跑工作流、停止任务        |
| Files         | 上传与预览               | 文件上传与预览            |
| Audio         | STT / TTS                | 音频能力对外开放          |
| Site          | 发布站点信息             | 获取 WebApp 站点信息      |
| End User      | 终端用户对象             | 识别/读取最终用户         |
| Dataset API   | 数据集/文档/切片/元数据  | 通过 Token 暴露知识库能力 |
| Hit Testing   | 检索调试                 | 仅调试召回结果            |
| RAG Pipeline  | RAG 流程接口             | 对外开放知识处理流水线    |

---

## 6. 应用运行时核心

| 模块                   | 功能点         | 说明                            |
| ---------------------- | -------------- | ------------------------------- |
| App Generate Service   | 统一生成编排   | 聊天、补全、工作流统一生成入口  |
| Prompt Engine          | Prompt 渲染    | 系统 Prompt、历史消息、变量渲染 |
| Queue Control          | 应用级队列控制 | 控制高并发任务顺序              |
| Streaming              | 流式响应       | SSE / Token 级输出              |
| Suggested Questions    | 建议问题       | 回答后生成追问建议              |
| Feedback               | 点赞 / 点踩    | 收集运行时用户反馈              |
| Conversation Variables | 会话变量       | 会话级状态持久化                |

---

## 7. 知识库与 RAG

### 7.1 数据集与文档

| 模块             | 功能点             | 说明                              |
| ---------------- | ------------------ | --------------------------------- |
| Dataset          | 创建 / 删除 / 配置 | 知识库基本信息与检索配置          |
| Document         | 文档上传           | 文件入库、状态跟踪                |
| Process Rule     | 文档处理规则       | chunk size、overlap、separator 等 |
| Segment          | 切片管理           | 文本 chunk 与子 chunk             |
| Metadata         | 元数据管理         | 文档/切片标签过滤                 |
| App-Dataset Join | 应用绑定知识库     | 应用可挂多个知识库                |

### 7.2 数据处理与索引

| 模块            | 功能点     | 说明                        |
| --------------- | ---------- | --------------------------- |
| Extractor       | 多格式抽取 | PDF、Word、Markdown、网页等 |
| Cleaner         | 文本清洗   | 标准化、去噪、过滤          |
| Splitter        | 切片       | 按 Token / 段落切分         |
| Embedding       | 向量化     | 调用 embedding 模型         |
| Index Processor | 索引写入   | 构建、更新、删除向量索引    |
| Summary Index   | 摘要索引   | 生成摘要型索引辅助检索      |

### 7.3 检索与调试

| 模块                | 功能点       | 说明                           |
| ------------------- | ------------ | ------------------------------ |
| Retrieval           | 检索召回     | 向量检索、关键词检索、混合检索 |
| Rerank              | 重排序       | 对召回结果重新排序             |
| Hit Testing         | 命中测试     | 不走 LLM，只调检索结果         |
| Website Import      | 网站抓取     | 抓取网页并转知识文档           |
| External Knowledge  | 外部知识系统 | 对接第三方知识源               |
| Datasource Provider | 数据源接入   | 如 Notion 等外部源             |

### 7.4 RAG Pipeline

| 模块               | 功能点   | 说明                                       |
| ------------------ | -------- | ------------------------------------------ |
| Pipeline DSL       | 流程定义 | 将知识处理流程抽象成 DSL                   |
| Pipeline Templates | 模板体系 | 内置模板、数据库模板、远端模板、自定义模板 |
| Pipeline Generate  | 流程执行 | 跑一条 RAG 处理流水线                      |
| Pipeline Transform | 结构转换 | 前后端结构与运行时结构转换                 |

---

## 8. 工作流引擎

### 8.1 定义与发布

| 模块                | 功能点     | 说明                        |
| ------------------- | ---------- | --------------------------- |
| Workflow Definition | 图结构定义 | 保存工作流画布 JSON         |
| Draft / Publish     | 草稿与发布 | 编辑态与运行态隔离          |
| Converter           | 结构转换   | DSL、节点图、运行图之间转换 |

### 8.2 执行引擎

| 模块             | 功能点       | 说明                         |
| ---------------- | ------------ | ---------------------------- |
| Node Factory     | 节点实例化   | 根据节点类型构造运行时节点   |
| Node Runtime     | 节点执行     | 节点输入、执行、输出封装     |
| Variable Pool    | 变量池       | 节点间变量读写与传递         |
| System Variables | 系统变量注入 | 用户、时间、上下文等         |
| Workflow Outputs | 结果汇总     | 汇总最终输出结果             |
| Queue Dispatcher | 队列分发     | 按执行类型分派到 Celery 队列 |

### 8.3 节点类型

| 节点类型            | 说明                       |
| ------------------- | -------------------------- |
| Start / End         | 流程起止节点               |
| LLM                 | 模型调用节点               |
| Knowledge Retrieval | 知识检索节点               |
| Code                | 沙箱代码执行节点           |
| Tool                | 调工具、插件工具、MCP 工具 |
| Condition / Branch  | 分支判断                   |
| Iteration / Loop    | 循环与批处理               |
| HTTP / Datasource   | 外部请求与数据读取         |
| Human Input         | 等待人工补录               |

### 8.4 可观测性与恢复

| 模块           | 功能点       | 说明                       |
| -------------- | ------------ | -------------------------- |
| WorkflowRun    | 流程执行记录 | 每次运行的状态、输入、输出 |
| NodeExecution  | 节点执行轨迹 | 每个节点的详细日志         |
| Offload        | 大字段卸载   | 超大输入输出落外部存储     |
| Pause / Resume | 暂停恢复     | 支持人工输入等暂停场景     |
| Event Snapshot | 执行事件快照 | 前端可视化回放执行过程     |

---

## 9. 模型提供商与模型运行时

| 模块                  | 功能点              | 说明                                                            |
| --------------------- | ------------------- | --------------------------------------------------------------- |
| Provider Registry     | 提供商注册          | 管理 OpenAI / Azure / Anthropic / Gemini / DeepSeek / Tongyi 等 |
| Credential Management | 凭证配置            | API Key、Endpoint、组织等                                       |
| Model Manager         | 模型实例化          | chat / embedding / rerank / speech 模型统一入口                 |
| Tenant Scope          | 租户级模型权限      | 每个租户可用模型集合                                            |
| Hosting Config        | 平台托管模型        | 平台预置托管模型能力                                            |
| Load Balancing        | 多 Key / 多部署分流 | 配置级别容灾与轮询                                              |
| Plugin Runtime        | 插件模型运行时      | 通过插件增加新模型能力                                          |

### 9.1 必须考虑的模型类型

1. Chat / Completion
2. Embedding
3. Rerank
4. Speech-to-Text
5. Text-to-Speech
6. Moderation

---

## 10. 工具系统、MCP 与 Agent

| 模块           | 功能点       | 说明                                    |
| -------------- | ------------ | --------------------------------------- |
| Builtin Tools  | 内置工具     | 平台内置的基础工具                      |
| API Tools      | API 工具     | 把外部 HTTP 服务包装成工具              |
| Workflow Tools | 工作流工具   | 把工作流封装成可复用工具                |
| MCP Tools      | MCP 工具     | 接入 MCP Server 的工具能力              |
| Tool Labels    | 工具标签分类 | 工具分组、检索、展示                    |
| Tool Transform | 参数转换     | 工具输入输出的结构转换                  |
| Agent Service  | Agent 运行时 | 让模型以 agent 方式调用工具、知识与流程 |

---

## 11. 插件系统

| 模块                | 功能点       | 说明                     |
| ------------------- | ------------ | ------------------------ |
| Plugin Service      | 安装/卸载    | 插件生命周期管理         |
| Plugin Permission   | 权限控制     | 插件对租户/成员的授权    |
| Plugin Parameters   | 参数配置     | 插件配置项与密钥         |
| Plugin OAuth        | 外部授权     | 插件所需授权流程         |
| Endpoint Service    | 插件入口管理 | 插件 endpoint 注册和调用 |
| Auto Upgrade        | 自动升级     | 插件版本管理             |
| Dependency Analysis | 依赖分析     | 依赖冲突与可用性检查     |
| Plugin Migration    | 迁移         | 插件数据与版本迁移       |
| Plugin Daemon       | 运行边界     | 独立守护进程执行插件逻辑 |

---

## 12. Trigger、Webhook 与自动化

| 模块                    | 功能点       | 说明                       |
| ----------------------- | ------------ | -------------------------- |
| Trigger Provider        | 触发器提供商 | 支持的平台触发器类型       |
| App Trigger             | 应用触发     | 让应用被定时/事件驱动      |
| Webhook                 | Webhook 接入 | 接收外部 HTTP 事件         |
| Plugin Endpoint Trigger | 插件触发入口 | 外部系统调用插件 endpoint  |
| Subscription Builder    | 订阅创建     | 构造订阅关系               |
| Subscription Operator   | 订阅启停     | 运维订阅生命周期           |
| Schedule                | 定时触发     | 定时任务与未来执行         |
| Trigger Request         | 请求标准化   | 将外部请求转内部触发上下文 |

---

## 13. 文件、附件与音频

| 模块          | 功能点       | 说明                             |
| ------------- | ------------ | -------------------------------- |
| File Upload   | 文件上传     | 控制台/运行时上传文件            |
| File Preview  | 文件预览     | 文本预览、图片预览、工具文件访问 |
| Upload Config | 上传限制     | 格式、体积、批量数控制           |
| Attachment    | 附件处理     | 消息附件与分片附件能力           |
| Remote Files  | 远程文件导入 | URL 文件代理与保存               |
| Audio STT     | 音频转文本   | 录音输入转文字                   |
| Audio TTS     | 文本转语音   | 回复内容生成音频                 |

---

## 14. 人工输入与暂停恢复

| 模块             | 功能点   | 说明                           |
| ---------------- | -------- | ------------------------------ |
| Human Input Form | 表单定义 | 工作流等待人工输入时的结构定义 |
| Delivery         | 表单送达 | 送给谁、如何送达               |
| Pause            | 流程暂停 | 人工参与时中断流程             |
| Resume           | 流程恢复 | 表单提交后继续执行             |
| Delivery Test    | 送达测试 | 测试人工输入通知链路           |

---

## 15. 运维、监控、安全与合规

| 模块                  | 功能点         | 说明                                       |
| --------------------- | -------------- | ------------------------------------------ |
| Health                | 健康检查       | 健康状态、线程、连接池状态                 |
| Logging               | 请求与应用日志 | 平台日志与问题排查                         |
| Sentry                | 异常上报       | Flask / Celery 异常监控                    |
| OpenTelemetry         | 全链路追踪     | Flask、Celery、Redis、SQLAlchemy、HTTPX 等 |
| Langfuse / Weave      | LLM 观测       | Prompt / 模型调用观测                      |
| SSRF Proxy            | 外网访问防护   | 所有抓取类请求走安全代理                   |
| Swagger / FastOpenAPI | 接口文档       | 运行时接口文档输出                         |
| Compliance            | 合规下载与审计 | 记录下载来源、设备信息                     |

---

## 16. 异步任务与后台作业

| 模块          | 功能点              | 说明                            |
| ------------- | ------------------- | ------------------------------- |
| 文档索引任务  | 异步建索引          | 解析、切片、embedding、入向量库 |
| 工作流任务    | 异步执行            | 复杂流程进入 Celery 队列执行    |
| 执行持久化    | Workflow Storage    | 工作流执行轨迹后台落库          |
| 清理任务      | Retention / Cleanup | 过期消息、历史运行、日志清理    |
| 推荐/同步任务 | 推荐应用、企业同步  | 与云端/伙伴系统交互             |
| 插件任务      | 升级与迁移          | 插件安装后的后台处理            |

---

## 17. 核心数据模型

| 数据模型                                                          | 用途                           |
| ----------------------------------------------------------------- | ------------------------------ |
| `Account` / `Tenant` / `TenantAccountJoin`                        | 控制台用户、工作区、成员关系   |
| `App` / `AppModelConfig` / `Site`                                 | AI 应用、模型配置、发布站点    |
| `Conversation` / `Message` / `MessageFeedback` / `MessageFile`    | 会话、消息、反馈、附件         |
| `EndUser`                                                         | Web/API 最终用户               |
| `ApiToken`                                                        | 应用/知识库令牌                |
| `Dataset` / `Document` / `DocumentSegment` / `DatasetProcessRule` | 知识库、文档、切片、处理规则   |
| `Workflow` / `WorkflowRun` / `WorkflowNodeExecutionModel`         | 工作流定义、运行记录、节点轨迹 |
| `WorkflowPause` / `HumanInputForm`                                | 暂停恢复与人工输入             |
| `Provider` / `ProviderModel`                                      | 模型提供商与模型配置           |
| `Tool*Provider`                                                   | 各类工具提供商                 |
| `Trigger*`                                                        | 触发器、Webhook、订阅          |
| `UploadFile`                                                      | 文件与对象存储映射             |

---

## 18. 开发优先级建议

### 第一阶段：最小可运行

1. 多租户与账号体系
2. 应用 CRUD
3. 一个模型提供商
4. Web / Service API 的聊天与补全
5. 会话与消息存储
6. 文件上传
7. 知识库上传、切片、embedding、检索
8. 基础工作流（Start -> LLM -> End）
9. Celery + Redis 异步执行

### 第二阶段：补齐主产品链路

1. 工作流节点体系
2. Tool / Agent / MCP
3. 多模型提供商
4. 网站导入、元数据过滤、Hit Testing
5. Trial / Explore / 推荐应用
6. Saved Messages、Feedback、Annotation
7. 插件守护进程
8. 音频能力

### 第三阶段：平台化与商业化

1. Load Balancing
2. Trigger / Schedule / Webhook
3. Human Input / Pause Resume
4. Billing / Compliance / Enterprise
5. OTel / Sentry / Langfuse
6. 多 Vector DB / 多 Storage / 多部署拓扑

---

## 19. 最容易漏掉的关键点

1. 不只是聊天接口，还有 Console / Web / Service / Inner / MCP / Trigger 六大接口面。
2. 不只是用户，还要区分 Account、Tenant、EndUser、ApiToken。
3. 知识库不只是上传文件，还包括 metadata、website、hit testing、summary index、pipeline。
4. 工作流不只是 DAG 执行，还包括节点轨迹、事件流、暂停恢复、人工输入。
5. 模型不是单 provider，要做租户级 provider 管理和多模型类型支持。
6. 插件系统是独立守护进程边界，不是简单 Python 模块加载。
7. 代码执行必须经 Sandbox 隔离。
8. 对外 HTTP 抓取必须走 SSRF Proxy。
9. 消息体系还要包含 saved messages、annotation、feedback。
10. 控制台里还有 Trial / Explore / Recommended Apps 等产品化功能。
11. 云版/企业版能力通过 edition / feature / billing 逻辑深入控制层。
12. API Key 不只给应用，也给知识库。
13. MCP 是正式接口面，不是 demo。
14. 文件系统同时服务消息附件、知识库、工具文件、插件文件。
15. 测试体系是 unit / integration / testcontainers 三层，说明系统边界多且复杂。

---

## 20. 关键代码入口速查

| 类型           | 路径                                                        |
| -------------- | ----------------------------------------------------------- |
| Flask 入口     | `api/app.py`                                                |
| 应用工厂       | `api/app_factory.py`                                        |
| Celery 入口    | `api/celery_entrypoint.py`                                  |
| Console API 根 | `api/controllers/console/__init__.py`                       |
| Web API 根     | `api/controllers/web/__init__.py`                           |
| Service API 根 | `api/controllers/service_api/__init__.py`                   |
| Files API 根   | `api/controllers/files/__init__.py`                         |
| Trigger API 根 | `api/controllers/trigger/__init__.py`                       |
| MCP API 根     | `api/controllers/mcp/__init__.py`                           |
| 模型管理       | `api/core/provider_manager.py`, `api/core/model_manager.py` |
| RAG 核心       | `api/core/rag/`                                             |
| Workflow 核心  | `api/core/workflow/`                                        |
| 插件核心       | `api/core/plugin/`, `api/services/plugin/`                  |
| 任务与调度     | `api/tasks/`, `api/schedule/`                               |
| Docker 拓扑    | `docker/docker-compose.yaml`, `docker/.env`                 |

---

## 21. 最终结论

如果你的目标是做一个“和 Dify 接近的后端”，你不能只做聊天接口、模型转发、文件上传和简单向量检索。

你必须同时做出：

1. **平台层**：租户、成员、权限、计费、企业能力；
2. **应用层**：应用、Prompt、模型、工具、知识库、工作流；
3. **运行时层**：Web、Service API、MCP、Webhook、文件、音频；
4. **扩展层**：插件、模型 provider、工具 provider、数据源；
5. **基础设施层**：DB、Redis、Celery、Storage、Vector DB、Sandbox、SSRF、监控。

这 5 层一起成立，才是真正接近 Dify 的后端产品能力。
