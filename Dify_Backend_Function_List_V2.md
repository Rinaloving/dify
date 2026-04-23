# Dify Backend 功能模块总表（基于 `api/` 代码深度补全）

> 这份文档按“可复刻产品后端”的目标整理，不是简单的目录说明。  
> 目标是：拿到这份文档，研发团队可以按模块拆分并逐步开发出一套接近 Dify 的后端系统。

---

## 1. 项目本质

Dify 后端本质上是一套 **多租户 AI 应用平台后端**，不是单一聊天 API。

它同时解决 5 类问题：

1. **平台管理**：账号、租户、成员、权限、计费、企业能力。
2. **AI 应用开发**：应用创建、模型配置、Prompt、知识库、工作流、Agent、工具。
3. **运行时服务**：Web 终端、开放 API、MCP、Webhook、文件、音频。
4. **扩展生态**：插件、模型提供商、工具提供商、外部数据源。
5. **生产基础设施**：DB、Redis、Celery、对象存储、向量库、Sandbox、Plugin Daemon、SSRF Proxy。

---

## 2. 总体架构

### 2.1 代码分层

| 层 | 目录 | 作用 |
| --- | --- | --- |
| 接口层 | `api/controllers/` | 暴露 HTTP / REST / MCP / Trigger 接口，做鉴权、参数校验、响应序列化 |
| 服务层 | `api/services/` | 编排业务逻辑，连接模型、知识库、工作流、插件、计费等 |
| 核心引擎层 | `api/core/` | 工作流引擎、RAG、Prompt、模型运行时、工具、插件运行边界 |
| 数据层 | `api/models/`, `api/repositories/`, `api/core/repositories/` | ORM 模型、仓储、执行记录持久化 |
| 基础设施层 | `api/extensions/`, `api/configs/`, `api/libs/` | DB、Redis、Celery、Storage、登录态、Sentry、OTel、SSRF |
| 异步层 | `api/tasks/`, `api/schedule/` | 文档索引、工作流后台执行、清理任务、定时任务 |

### 2.2 对外接口面

| 接口面 | 前缀 | 作用 |
| --- | --- | --- |
| Console API | `/console/api` | 后台控制台管理接口 |
| Web API | `/api` | WebApp 最终用户运行时接口 |
| Service API | `/v1` | 第三方系统调用接口 |
| Files API | `/files` | 文件上传、预览、签名访问 |
| Inner API | `/inner/api` | 内部服务/插件/企业同步接口 |
| Trigger API | `/triggers` | Webhook 与插件入口 |
| MCP API | `/mcp` | MCP Server 协议接口 |

---

## 3. 基础平台能力

### 3.1 账号、租户、权限

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| 账号体系 | 邮箱登录/登出 | 控制台登录、会话态保持、退出登录 |
| 账号体系 | 邮箱注册 | 注册、验证码、初始化工作区 |
| 账号体系 | 忘记密码 | 邮件验证码、重置密码 |
| OAuth 登录 | GitHub / Google | 第三方登录接入 |
| 数据源 OAuth | Notion 等 | 外部数据源授权 |
| 多租户 | Tenant / Workspace | 工作区隔离应用、知识库、模型、成员 |
| 成员体系 | Owner / Admin / Editor | 成员角色与工作区权限 |
| API Token | App Token / Dataset Token | 应用与知识库对外调用令牌 |
| Web 身份 | EndUser / Passport | WebApp 终端用户身份 |

### 3.2 系统初始化与平台配置

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| 系统初始化 | Setup / Init Validate | 检查是否已初始化、是否允许安装 |
| 系统信息 | Version / Ping / Feature / Spec | 版本、健康检查、功能开关、接口文档 |
| 通知中心 | Notification / Dismiss | 当前用户站内通知获取与关闭 |
| 标签体系 | Tags | 给应用/对象做分类与组织 |
| 文件系统配置 | Upload Config | 文件大小、批量数、格式限制 |

---

## 4. 控制台后台功能（Console）

### 4.1 应用管理

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| App 基础 | 创建应用 | 创建聊天、生成、工作流等应用 |
| App 基础 | 修改应用 | 名称、图标、描述、模式、可见性 |
| App 基础 | 删除应用 | 删除应用及其关联资源 |
| Model Config | 模型配置 | 模型、参数、系统提示词、功能开关 |
| Prompt | 高级提示模板 | 复杂 Prompt 模板管理 |
| DSL | 导入 / 导出 | 应用配置跨环境迁移 |
| Site | 发布站点配置 | WebApp 名称、品牌、访问设置 |
| Generator | 控制台调试运行 | 在后台直接调试聊天/生成 |
| Annotation | 标注与纠错 | 对回答进行标注修正 |
| Statistics | 应用统计 | 调用量、Token、消息、会话等 |
| Logs | 工作流/应用日志 | 查看运行轨迹与执行历史 |
| Variables | 对话/流程变量 | 配置与查看变量 |
| Agent | Agent 能力配置 | 应用级 Agent 能力设置 |
| MCP Server | 应用 MCP 配置 | 为应用暴露 MCP Server 能力 |

### 4.2 Explore / Trial

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| 推荐应用 | Recommended Apps | 推荐应用列表与详情 |
| Trial | 试用运行 | 未完整接入前先试跑聊天/工作流/音频 |
| Banner | 引导位 | 探索页推荐和引导 |
| Installed App | 已安装能力 | 查看已启用能力 |

### 4.3 工作区管理

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| Workspace | 工作区信息 | 工作区配置读取与更新 |
| Members | 成员管理 | 邀请、删除、角色变更 |
| Models | 模型列表 | 当前租户可用模型 |
| Provider Credentials | 模型凭证配置 | 配置 API Key / Endpoint / Region |
| Load Balancing | 多 Key / 多部署轮询 | 同模型多个配置的分流与容灾 |
| Tool Providers | 工具管理 | 内置/API/工作流/MCP 工具提供商 |
| Trigger Providers | 触发器管理 | 触发器种类与配置 |
| Endpoint | 插件/服务入口 | 统一管理外部 endpoint |
| Plugins | 插件管理 | 安装、删除、启停、升级、配置 |

### 4.4 扩展与管理能力

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| API-Based Extension | API 扩展 | 通过 API Endpoint + Key 注册扩展 |
| Code-Based Extension | 代码扩展查询 | 查询本地/代码型扩展能力 |
| Files | 上传与预览 | 控制台文件上传、文本预览、格式限制 |
| Remote Files | 远程文件 | 管理远端文件代理与导入 |
| API Keys | 应用 / 知识库 Key | 创建、查看、删除 API Key |

### 4.5 商业化与企业能力

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| Billing | 订阅购买 | 专业版/团队版订阅入口 |
| Billing | Invoices | 发票记录查询 |
| Billing | Partner Sync | 合作伙伴租户绑定同步 |
| Compliance | 合规文档下载 | 合规下载链接与审计记录 |
| Enterprise | 企业工作区同步 | 企业工作区、ownerless 租户管理 |
| Enterprise | 应用 DSL 管理 | 企业环境导入/导出应用 DSL |

---

## 5. 运行时能力（Web / Service API）

### 5.1 WebApp 运行时

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| Access Mode | Web 访问模式 | 公开访问、受限访问、登录要求 |
| Passport | Web 身份票据 | 终端用户访问票据 |
| Login | Web 登录/状态/退出 | Web 用户认证 |
| App Meta | Parameters / Meta / Site | 获取应用参数、元信息、站点配置 |
| Chat | Chat Messages | 聊天消息提交、流式返回、停止生成 |
| Completion | Completion Messages | 非对话式文本生成 |
| Conversations | 会话管理 | 新建、列表、重命名、删除 |
| Messages | 消息管理 | 详情、历史、反馈、建议问题 |
| Saved Messages | 收藏消息 | 保存重要回复 |
| Files | 附件上传 | 上传图片/文档/附件 |
| Remote Files | 远程文件导入 | 用链接导入外部文件 |
| Audio | STT / TTS | 音频转文本、文本转语音 |
| Workflow | Workflow Run / Stop | 运行工作流、停止任务 |
| Workflow Events | 事件流回放 | 返回节点级执行事件 |
| Human Input Form | 人工补录表单 | 暂停后由用户继续完成流程 |

### 5.2 Service API

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| App Runtime | Chat / Completion | 第三方系统调用应用 |
| Runtime Meta | Parameters / Info / Meta | 获取运行参数与应用信息 |
| Conversations | 会话管理 | 管理会话生命周期 |
| Messages | 消息管理 | 查询消息、历史、详情 |
| Workflow | Workflow 执行 | 跑工作流、停止任务 |
| Files | 上传与预览 | 文件上传与预览接口 |
| Audio | STT / TTS | 音频能力对外开放 |
| Site | 发布站点信息 | 获取 WebApp 站点信息 |
| End User | 终端用户对象 | 识别/读取最终用户 |
| Dataset API | 数据集/文档/切片/元数据 | 通过 Token 暴露知识库能力 |
| Hit Testing | 检索调试 | 仅调试召回结果 |
| RAG Pipeline | RAG 流程接口 | 对外开放知识处理流水线 |

---

## 6. 应用运行时核心

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| App Generate Service | 统一生成编排 | 聊天、补全、工作流统一生成入口 |
| Prompt Engine | Prompt 渲染 | 系统 Prompt、历史消息、变量渲染 |
| Queue Control | 应用级队列控制 | 控制应用高并发任务顺序与冲突 |
| Streaming | 流式响应 | SSE / Token 级输出 |
| Suggested Questions | 建议问题 | 回答后生成追问建议 |
| Feedback | 点赞 / 点踩 | 收集运行时用户反馈 |
| Conversation Variables | 会话变量 | 会话级状态持久化 |

---

## 7. 知识库与 RAG

### 7.1 数据集与文档

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| Dataset | 创建 / 删除 / 配置 | 知识库基本信息与检索配置 |
| Document | 文档上传 | 文件入库、状态跟踪 |
| Process Rule | 文档处理规则 | chunk size、overlap、separator 等 |
| Segment | 切片管理 | 文本 chunk 与子 chunk |
| Metadata | 元数据管理 | 文档/切片标签过滤 |
| App-Dataset Join | 应用绑定知识库 | 应用可挂多个知识库 |

### 7.2 数据处理与索引

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| Extractor | 多格式抽取 | PDF、Word、Markdown、网页等 |
| Cleaner | 文本清洗 | 标准化、去噪、过滤 |
| Splitter | 切片 | 按 Token / 段落切分 |
| Embedding | 向量化 | 调用 embedding 模型 |
| Index Processor | 索引写入 | 构建、更新、删除向量索引 |
| Summary Index | 摘要索引 | 生成摘要型索引辅助检索 |

### 7.3 检索与调试

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| Retrieval | 检索召回 | 向量检索、关键词检索、混合检索 |
| Rerank | 重排序 | 对召回结果重新排序 |
| Hit Testing | 命中测试 | 不走 LLM，只调检索结果 |
| Website Import | 网站抓取 | 抓取网页并转知识文档 |
| External Knowledge | 外部知识系统 | 对接第三方知识源 |
| Datasource Provider | 数据源接入 | 如 Notion 等外部源 |

### 7.4 RAG Pipeline

| 模块 | 功能点 | 说明 |
| --- | --- | --- |
| Pipeline DSL | 流程定义 | 将知识处理流程抽象成 DSL |
| Pipeline Templates | 模板体系 | 内置模板、数据库模板、远端模板、自定义模板 |
| Pipeline Generate | 流程执行 | 跑一条 RAG 处理流水线 |
| Pipeline Transform | 结构转换 | 前后端结构与运行时结构转换 |
