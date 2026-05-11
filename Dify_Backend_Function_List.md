# Dify Backend 研发功能清单 (基于 API 目录结构)

> **说明**: 本清单基于 `d:\mygithub\dify\api` 目录结构整理，旨在为后端研发提供明确的模块划分、功能点及关键代码实现路径。

## 1. 核心基础架构 (Infrastructure & Core)

| 模块           | 子模块           | 功能点             | 后端实现细节 / 关键代码路径                                                                             | 备注/优先级 |
| :------------- | :--------------- | :----------------- | :------------------------------------------------------------------------------------------------------ | :---------- |
| **配置管理**   | Config Loader    | 环境变量加载与校验 | `configs/app_config.py`, `configs/middleware/`<br>实现多源配置加载（Env, Remote Settings）。            | P0          |
|                | Feature Flags    | 功能开关控制       | `configs/feature/`<br>控制企业版特性、实验性功能是否开启。                                              | P1          |
| **数据库**     | ORM & Migration  | 数据库连接池管理   | `extensions/ext_database.py`<br>配置 SQLAlchemy Pool Size, Timeout。                                    | P0          |
|                | Schema Migration | 数据库版本迁移     | `migrations/versions/`<br>使用 Alembic 管理表结构变更。                                                 | P0          |
| **缓存与队列** | Redis Client     | 缓存服务封装       | `extensions/ext_redis.py`<br>提供统一的 get/set/del 接口，支持序列化。                                  | P0          |
|                | Celery Worker    | 异步任务调度       | `extensions/ext_celery.py`, `celery_entrypoint.py`<br>配置 Broker (Redis) 和 Backend。                  | P0          |
| **存储抽象**   | Storage Driver   | 多对象存储适配     | `extensions/ext_storage.py`, `core/file/`<br>基于 OpenDAL 或自定义 Adapter 支持 S3, Azure, Local, OSS。 | P0          |
| **安全认证**   | Auth Middleware  | JWT 令牌验证       | `libs/passport.py`, `controllers/console/wraps.py`<br>解析 Header 中的 Bearer Token，验证用户身份。     | P0          |
|                | RBAC             | 角色权限控制       | `models/account.py`, `libs/workspace_permission.py`<br>拦截器检查用户是否为 Owner/Admin/Editor。        | P0          |
|                | Data Encryption  | 敏感数据加密       | `libs/encryption.py`<br>使用 Fernet 对 API Key, Password 进行对称加密存储。                             | P0          |

## 2. 知识库与 RAG 引擎 (Knowledge Base & RAG)

| 模块           | 子模块             | 功能点             | 后端实现细节 / 关键代码路径                                                                                                                                 | 备注/优先级 |
| :------------- | :----------------- | :----------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------- |
| **数据集管理** | Dataset CRUD       | 知识库创建/删除    | `services/dataset_service.py`<br>在 PostgreSQL 创建 [Dataset](file://d:\mygithub\dify\api\models\dataset.py#L116-L386) 记录，初始化向量索引空间。           | P0          |
|                | Document Mgmt      | 文档上传与状态追踪 | `services/dataset_service.py`, `models/dataset.py`<br>创建 [Document](file://d:\mygithub\dify\api\models\dataset.py#L429-L771) 记录，状态标记为 `queuing`。 | P0          |
| **数据处理**   | File Parsing       | 多格式文件解析     | `core/rag/extractor/`<br>实现 PDF, Word, TXT, Markdown 等提取器。集成 Unstructured.io (可选)。                                                              | P1          |
|                | Text Splitting     | 智能文本分段       | `core/rag/splitter/`<br>基于 Token 长度或分隔符切分文本，保留上下文重叠 (Overlap)。                                                                         | P1          |
| **索引构建**   | Embedding          | 向量化计算         | `tasks/document_indexing_task.py` -> `core/indexing_runner.py`<br>异步调用 LLM Provider 的 Embedding 接口。                                                 | P0          |
|                | Vector Storage     | 向量入库           | `core/rag/datasource/vdb/{type}/`<br>将向量及元数据 (segment_id, doc_id) 存入 Weaviate/Qdrant/Pgvector。                                                    | P0          |
| **检索引擎**   | Retrieval Strategy | 混合检索策略       | `core/rag/retrieval/dataset_retrieval.py`<br>组合向量检索 (Vector Search) 和全文检索 (Keyword Search/BM25)。                                                | P1          |
|                | Rerank             | 结果重排序         | `core/rag/rerank/`<br>调用 Rerank 模型对召回的 Top-K 片段重新打分。                                                                                         | P2          |
|                | Hit Testing        | 检索测试接口       | `services/hit_testing_service.py`<br>提供调试接口，返回检索到的片段及分数，不经过 LLM。                                                                     | P1          |

## 3. 工作流引擎 (Workflow Engine)

| 模块         | 子模块            | 功能点         | 后端实现细节 / 关键代码路径                                                                                                                                                  | 备注/优先级 |
| :----------- | :---------------- | :------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------- |
| **编排定义** | Graph Parser      | DSL 解析与校验 | `core/workflow/graph_engine/`<br>解析前端传来的 JSON DAG，校验节点连接合法性，检测循环依赖。                                                                                 | P0          |
| **节点执行** | Node Registry     | 节点类型注册   | `core/workflow/nodes/`<br>注册 Start, End, LLM, Knowledge, Code, If-Else, Loop 等节点类。                                                                                    | P0          |
|              | Variable Context  | 变量上下文传递 | `core/workflow/entities/variable_pool.py`<br>管理节点间的输入输出变量，支持模板渲染 `{{var}}`。                                                                              | P0          |
| **运行时**   | Workflow Executor | 引擎调度执行   | `core/workflow/workflow_engine.py`<br>根据 DAG 拓扑顺序调度节点 [run()](file://d:\mygithub\dify\api\libs\helper.py#L95-L96) 方法，处理并行分支。                             | P0          |
|              | State Persistence | 执行状态持久化 | `repositories/sqlalchemy_workflow_run_repository.py`<br>实时保存每个节点的执行状态、输入、输出到 DB。                                                                        | P1          |
| **特定节点** | LLM Node          | 大模型调用节点 | `core/workflow/nodes/llm/node.py`<br>组装 Prompt，调用 Model Manager，处理流式输出。                                                                                         | P0          |
|              | Code Node         | 代码沙箱执行   | `core/workflow/nodes/code/node.py` -> [sandbox](file://d:\mygithub\dify\web\app\components\billing\type.ts#L1-L1) service<br>将代码发送至 Sandbox 服务执行，限制资源和网络。 | P1          |
|              | Knowledge Node    | 知识检索节点   | `core/workflow/nodes/knowledge_retrieval/node.py`<br>复用 RAG 检索引擎，返回结构化引用。                                                                                     | P1          |

## 4. LLM 模型与提供商 (Model & Provider)

| 模块           | 子模块            | 功能点         | 后端实现细节 / 关键代码路径                                                              | 备注/优先级 |
| :------------- | :---------------- | :------------- | :--------------------------------------------------------------------------------------- | :---------- |
| **提供商管理** | Provider Registry | 模型厂商接入   | `core/provider/`<br>实现 OpenAI, Azure, Anthropic 等 Provider 类，遵循统一接口。         | P0          |
|                | Credential Mgmt   | API Key 管理   | `services/model_provider_service.py`<br>加密存储用户配置的 API Key，支持验证有效性。     | P0          |
| **模型调用**   | Model Manager     | 模型实例化工厂 | `core/model_manager.py`<br>根据模型名称和类型 (Chat, Embedding, TTS) 动态加载对应类。    | P0          |
|                | Load Balancing    | 负载均衡       | `services/model_load_balancing_service.py`<br>支持同一模型配置多个 Key，轮询或加权调用。 | P2 (Ent)    |
| **推理优化**   | Stream Handler    | 流式响应处理   | `core/llm_generator/`<br>使用 Python Generator 封装 SSE 流，实时推送 Token。             | P0          |
|                | Prompt Engine     | 提示词渲染     | `core/prompt/`<br>处理 Jinja2 模板，注入变量、历史消息、上下文。                         | P0          |

## 5. 应用与对话 (App & Conversation)

| 模块         | 子模块            | 功能点        | 后端实现细节 / 关键代码路径                                                                                             | 备注/优先级 |
| :----------- | :---------------- | :------------ | :---------------------------------------------------------------------------------------------------------------------- | :---------- |
| **应用管理** | App CRUD          | 应用创建/配置 | `services/app_service.py`<br>管理 [App](file://d:\mygithub\dify\api\models\model.py#L44-L113) 模型，关联 Model Config。 | P0          |
|              | DSL Import/Export | 应用导入导出  | `services/app_dsl_service.py`<br>将应用配置序列化为 YAML/JSON，支持跨环境迁移。                                         | P1          |
| **对话交互** | Chat Engine       | 对话生成服务  | `services/app_generate_service.py`<br>协调 Message, Conversation, Model 调用，处理流式返回。                            | P0          |
|              | History Mgmt      | 历史记录管理  | `services/conversation_service.py`<br>分页加载历史消息，支持重命名会话。                                                | P1          |
|              | Feedback          | 点赞/点踩     | `services/feedback_service.py`<br>记录用户对回答的反馈，用于后续优化。                                                  | P2          |
| **外部接口** | Service API       | 开放 API 网关 | `controllers/service_api/`<br>提供标准的 RESTful API 供第三方集成，使用 API Token 鉴权。                                | P1          |

## 6. 插件系统 (Plugin System)

| 模块         | 子模块            | 功能点         | 后端实现细节 / 关键代码路径                                                                                                                                                | 备注/优先级 |
| :----------- | :---------------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------- |
| **插件守护** | Daemon Comm       | gRPC/HTTP 通信 | `core/plugin/entities/plugin_daemon.py`<br>与独立的 [plugin_daemon](file://d:\mygithub\dify\api\core\plugin\entities\plugin_daemon.py#L0-L0) 服务通信，下发安装/执行指令。 | P1          |
| **生命周期** | Install/Uninstall | 插件安装管理   | `services/plugin/plugin_service.py`<br>下载插件包，校验签名，通知 Daemon 加载。                                                                                            | P1          |
| **扩展能力** | Tool Provider     | 工具扩展       | `core/plugin/impl/tool.py`<br>将插件声明的工具注册到全局工具列表，供 Agent 调用。                                                                                          | P1          |
|              | Model Provider    | 模型扩展       | `core/plugin/impl/model.py`<br>允许插件提供新的模型接入方式。                                                                                                              | P2          |

## 7. 运维与监控 (Ops & Monitoring)

| 模块          | 子模块             | 功能点         | 后端实现细节 / 关键代码路径                                                             | 备注/优先级   |
| :------------ | :----------------- | :------------- | :-------------------------------------------------------------------------------------- | :------------ |
| **日志追踪**  | Sentry Integration | 异常上报       | `extensions/ext_sentry.py`<br>捕获未处理异常，上报堆栈信息。                            | P1            |
|               | OTEL Tracing       | 分布式链路追踪 | `extensions/ext_otel.py`<br>记录请求链路，监控 LLM 调用耗时。                           | P2            |
| **定时任务**  | Scheduler          | 清理与维护     | `schedule/`<br>Celery Beat 触发：清理过期日志、清理未使用数据集、更新 Token 状态。      | P2            |
| **SSRF 防护** | Proxy Filter       | 内部网络保护   | `core/helper/ssrf_proxy.py`<br>所有外部 HTTP 请求必须经过 Squid 代理，禁止访问内网 IP。 | P0 (Security) |

---

### 研发执行建议 (Implementation Notes)

1.  **优先级 P0 (核心链路)**:
    - 完成 [configs](file://d:\mygithub\dify\api\models\model.py#L627-L627) 和 `extensions` 的基础设施搭建，确保 DB, Redis, Storage 连通。
    - 实现 `core/model_manager.py` 和至少一个 Provider (如 OpenAI)，确保能通调 LLM。
    - 实现 `core/rag` 的基本索引和检索流程，打通 "上传->分段->向量->检索" 闭环。
    - 实现 `core/workflow` 的最小可运行子集 (Start -> LLM -> End)。

2.  **优先级 P1 (业务完善)**:
    - 完善 `controllers/console` 的所有 CRUD 接口，对接前端管理后台。
    - 实现 `services/dataset_service.py` 的异步索引任务，优化用户体验。
    - 接入 [plugin_daemon](file://d:\mygithub\dify\api\core\plugin\entities\plugin_daemon.py#L0-L0)，支持基础插件安装。

3.  **优先级 P2 (高级特性)**:
    - 实现混合检索 (Hybrid Search) 和 Rerank。
    - 实现工作流的复杂节点 (Loop, Iteration, Variable Aggregation)。
    - 实现负载均衡和多租户配额管理 (Enterprise Features)。

4.  **开发规范**:
    - **新增向量库**: 必须在 `core/rag/datasource/vdb/` 下新建文件夹，实现 `VectorStore` 基类接口，并在 `configs/middleware/vdb/` 添加配置。
    - **新增工作流节点**: 必须在 `core/workflow/nodes/` 下新建节点类，继承 [BaseNode](file://d:\mygithub\dify\web\app\components\workflow\nodes_base\node.tsx#L60-L291)，实现 [\_run](file://d:\mygithub\dify\api\core\workflow\nodes\knowledge_retrieval\knowledge_retrieval_node.py#L81-L160) 方法，并在 [graph_engine](file://d:\mygithub\dify\api\core\workflow\workflow_entry.py#L0-L0) 中注册。
    - **数据库变更**: 必须通过 `flask db migrate` 生成 migration 脚本，严禁手动改表。
