# Dify Backend 功能明细补充（字段级 / 原型级）

> 本文是对 [Dify_Backend_Function_List_V3.md](file:///D:/mygithub/dify/Dify_Backend_Function_List_V3.md) 的细化补充。  
> 目标是让开发看到后，能接近“看原型 + 看数据字典”的感觉，直接拆接口、拆表、拆流程。

---

## 1. 知识库与 RAG：字段级功能明细

## 1.1 创建知识库（Console）

### 接口意图

创建一个知识库 Dataset，支持平台内置向量化模式和外部知识库模式。

### 创建请求字段

来源：`api/controllers/console/datasets/datasets.py`

| 字段                        | 类型           | 必填 | 默认值    | 说明                                                 |
| --------------------------- | -------------- | ---- | --------- | ---------------------------------------------------- |
| `name`                      | string         | 是   | -         | 知识库名称，1~40 字符                                |
| `description`               | string         | 否   | `""`      | 描述，最多 400 字符                                  |
| `indexing_technique`        | string \| null | 否   | `null`    | 索引技术，允许值：`high_quality`、`economy`、`null`  |
| `permission`                | enum           | 否   | `only_me` | 权限，默认仅自己可见                                 |
| `provider`                  | string         | 否   | `vendor`  | 知识来源提供方，允许值：`vendor`、`external`、`null` |
| `external_knowledge_api_id` | string \| null | 否   | `null`    | 外部知识 API 配置 ID                                 |
| `external_knowledge_id`     | string \| null | 否   | `null`    | 外部知识源 ID                                        |

### 创建时开发注意点

1. `provider=vendor` 表示平台内部知识库。
2. `provider=external` 时，必须补齐 `external_knowledge_api_id` 和 `external_knowledge_id`。
3. `indexing_technique` 在代码中受严格校验，不能写任意值。
4. 权限默认是 `only_me`，说明知识库从安全角度默认是私有的。

### Dataset 表核心字段

来源：`api/models/dataset.py`

| 字段                       | 说明                     |
| -------------------------- | ------------------------ |
| `id`                       | 知识库主键               |
| `tenant_id`                | 所属工作区               |
| `name`                     | 名称                     |
| `description`              | 描述                     |
| `provider`                 | `vendor` / `external`    |
| `permission`               | 可见范围                 |
| `data_source_type`         | 数据源类型               |
| `indexing_technique`       | 高质量 / 经济模式        |
| `index_struct`             | 索引结构 JSON            |
| `embedding_model`          | 当前 embedding 模型名    |
| `embedding_model_provider` | embedding 提供商         |
| `keyword_number`           | 关键词抽取数，默认 10    |
| `collection_binding_id`    | 向量集合绑定 ID          |
| `retrieval_model`          | 检索配置 JSON            |
| `summary_index_setting`    | 摘要索引配置 JSON        |
| `built_in_field_enabled`   | 是否启用内置字段         |
| `icon_info`                | 图标配置                 |
| `runtime_mode`             | 运行模式，默认 `general` |
| `pipeline_id`              | 关联的 RAG Pipeline      |
| `chunk_structure`          | chunk 结构标识           |
| `enable_api`               | 是否允许 API 访问        |
| `is_multimodal`            | 是否多模态               |

### 知识库统计派生能力

代码里 Dataset 自带以下统计属性，前端常需要直接展示：

1. `total_documents`
2. `total_available_documents`
3. `app_count`
4. `document_count`
5. `available_document_count`
6. `available_segment_count`

这意味着知识库详情页通常至少需要：文档总数、可用文档数、切片数、被多少 App 引用。

---

## 1.2 更新知识库

### 更新请求字段

| 字段                        | 类型               | 说明                |
| --------------------------- | ------------------ | ------------------- |
| `name`                      | string \| null     | 名称，1~40 字符     |
| `description`               | string \| null     | 描述，最多 400 字符 |
| `permission`                | enum \| null       | 权限范围            |
| `indexing_technique`        | string \| null     | 索引技术            |
| `embedding_model`           | string \| null     | embedding 模型      |
| `embedding_model_provider`  | string \| null     | embedding 提供商    |
| `retrieval_model`           | dict \| null       | 检索配置            |
| `summary_index_setting`     | dict \| null       | 摘要索引配置        |
| `partial_member_list`       | list[dict] \| null | 部分成员可见名单    |
| `external_retrieval_model`  | dict \| null       | 外部检索配置        |
| `external_knowledge_id`     | string \| null     | 外部知识源 ID       |
| `external_knowledge_api_id` | string \| null     | 外部知识 API ID     |
| `icon_info`                 | dict \| null       | 图标信息            |
| `is_multimodal`             | bool \| null       | 是否多模态          |

### 更新时注意点

1. 这不是简单“改名称”，它本质上也是知识库检索参数管理接口。
2. `retrieval_model`、`summary_index_setting`、`external_retrieval_model` 都是 JSON 配置，前端应做结构化表单。
3. `partial_member_list` 说明知识库权限不仅有公开/私有，还存在“部分成员可见”模型。

---

## 1.3 索引规则（DatasetProcessRule）

### 规则表字段

| 字段         | 说明                                        |
| ------------ | ------------------------------------------- |
| `dataset_id` | 所属知识库                                  |
| `mode`       | 模式：`automatic`、`custom`、`hierarchical` |
| `rules`      | 规则 JSON                                   |
| `created_by` | 创建者                                      |
| `created_at` | 创建时间                                    |

### 自动规则默认值

代码里内置了自动模式默认规则：

1. 预处理规则：
   - `remove_extra_spaces = true`
   - `remove_urls_emails = false`
2. 切片规则：
   - `delimiter = "\n"`
   - `max_tokens = 500`
   - `chunk_overlap = 50`

### 预处理规则枚举

1. `remove_stopwords`
2. `remove_extra_spaces`
3. `remove_urls_emails`

### 开发注意点

1. `hierarchical` 模式不是普通切片，它会影响 `child_chunks` 是否启用。
2. 规则要作为版本快照保留，不能只保存“当前知识库配置”。

---

## 1.4 文档（Document）

### 核心表字段

| 字段                      | 说明                            |
| ------------------------- | ------------------------------- |
| `tenant_id`               | 工作区                          |
| `dataset_id`              | 所属知识库                      |
| `position`                | 文档序号                        |
| `data_source_type`        | 数据来源类型                    |
| `data_source_info`        | 数据来源详情 JSON               |
| `dataset_process_rule_id` | 使用的处理规则 ID               |
| `batch`                   | 批次号                          |
| `name`                    | 文档名称                        |
| `created_from`            | 文档创建来源                    |
| `file_id`                 | 文件 ID                         |
| `word_count`              | 字数                            |
| `tokens`                  | token 数                        |
| `indexing_latency`        | 索引耗时                        |
| `indexing_status`         | 状态机字段                      |
| `enabled`                 | 是否启用                        |
| `archived`                | 是否归档                        |
| `doc_type`                | 文档类型                        |
| `doc_metadata`            | 元数据 JSON                     |
| `doc_form`                | 文档结构类型，默认 `text_model` |
| `doc_language`            | 文档语言                        |
| `need_summary`            | 是否需要摘要                    |

### 文档状态显示逻辑

后端有一层显示状态映射，前端应该按这个思路渲染：

| 原始条件                                 | 显示状态    |
| ---------------------------------------- | ----------- |
| `indexing_status = waiting`              | `queuing`   |
| 正在 parsing/cleaning/splitting/indexing | `indexing`  |
| 处理中且 `is_paused = true`              | `paused`    |
| `indexing_status = error`                | `error`     |
| 已完成 + 启用 + 未归档                   | `available` |
| 已完成 + 禁用                            | `disabled`  |
| 已完成 + 已归档                          | `archived`  |

### 数据来源类型

代码里明确支持：

1. `upload_file`
2. `notion_import`
3. `website_crawl`

### 开发注意点

1. 文档有完整处理流水：开始处理 -> 解析 -> 清洗 -> 切片 -> 建索引 -> 完成。
2. 每个阶段都有时间字段，所以管理页可以展示分阶段进度。
3. `data_source_info` 对不同数据源格式不同，建模时不要写死一种结构。

---

## 1.5 切片（DocumentSegment）

### 创建 / 更新字段

来源：`datasets_segments.py`

| 操作 | 字段                      | 说明             |
| ---- | ------------------------- | ---------------- |
| 创建 | `content`                 | 切片正文         |
| 创建 | `answer`                  | 标准答案，可为空 |
| 创建 | `keywords`                | 关键词数组       |
| 创建 | `attachment_ids`          | 附件 ID 列表     |
| 更新 | `content`                 | 切片正文         |
| 更新 | `answer`                  | 标准答案         |
| 更新 | `keywords`                | 关键词数组       |
| 更新 | `regenerate_child_chunks` | 是否重建子切片   |
| 更新 | `attachment_ids`          | 附件 ID          |
| 更新 | `summary`                 | 摘要索引内容     |

### Segment 表核心字段

| 字段              | 说明                   |
| ----------------- | ---------------------- |
| `dataset_id`      | 所属知识库             |
| `document_id`     | 所属文档               |
| `position`        | 在文档中的顺序         |
| `content`         | 内容正文               |
| `answer`          | 答案/补充答案          |
| `word_count`      | 字数                   |
| `tokens`          | token 数               |
| `keywords`        | 关键词                 |
| `index_node_id`   | 向量库节点 ID          |
| `index_node_hash` | 向量内容签名           |
| `hit_count`       | 命中次数               |
| `enabled`         | 是否启用               |
| `status`          | waiting / completed 等 |
| `indexing_at`     | 开始索引时间           |
| `completed_at`    | 完成时间               |
| `error`           | 错误信息               |

### 子切片（Child Chunks）

如果 `DatasetProcessRule.mode = hierarchical`，则 segment 还会有子 chunk。

这意味着前端至少要支持两种编辑方式：

1. 普通切片编辑
2. 分层切片编辑（父 chunk + 子 chunk）

---

## 1.6 命中测试（Hit Testing）

### 请求字段

| 字段                       | 类型                 | 说明                    |
| -------------------------- | -------------------- | ----------------------- |
| `query`                    | string               | 查询语句，最大 250 字符 |
| `retrieval_model`          | object \| null       | 检索配置                |
| `external_retrieval_model` | dict \| null         | 外部检索配置            |
| `attachment_ids`           | list[string] \| null | 附件过滤                |

### 行为说明

1. 只做检索，不走 LLM 最终生成。
2. 默认返回 top 10 召回记录。
3. 如果索引未初始化，直接返回知识库未初始化错误。
4. 如果 embedding / rerank 模型没配好，会返回 provider 初始化错误。

### 检索配置注意点

从模型代码可以确定，外部检索默认至少有：

1. `top_k`
2. `score_threshold`

---

## 1.7 网站抓取

### 创建抓取请求字段

| 字段       | 类型   | 说明                                      |
| ---------- | ------ | ----------------------------------------- |
| `provider` | enum   | `firecrawl` / `watercrawl` / `jinareader` |
| `url`      | string | 要抓取的网址                              |
| `options`  | dict   | 抓取参数                                  |

### 查询抓取状态字段

| 字段       | 类型        | 说明           |
| ---------- | ----------- | -------------- |
| `provider` | enum        | 抓取服务提供方 |
| `job_id`   | path string | 任务 ID        |

### 开发注意点

1. 网站抓取是异步任务模型，不是同步返回正文。
2. 前端必须实现：发起抓取 -> 轮询状态 -> 导入结果。

---

## 1.8 外部知识库

### 外部知识 API 创建字段

| 字段       | 类型   | 说明                  |
| ---------- | ------ | --------------------- |
| `name`     | string | API 模板名，1~40 字符 |
| `settings` | dict   | 外部 API 连接配置     |

### 外部数据集创建字段

| 字段                        | 类型           | 说明                   |
| --------------------------- | -------------- | ---------------------- |
| `external_knowledge_api_id` | string         | 外部知识 API ID        |
| `external_knowledge_id`     | string         | 外部知识源 ID          |
| `name`                      | string         | 数据集名称，1~100 字符 |
| `description`               | string \| null | 描述，最多 400 字符    |
| `external_retrieval_model`  | dict \| null   | 外部检索配置           |

---

## 2. 应用（App）字段级功能明细

## 2.1 创建应用

来源：`controllers/console/app/app.py`

| 字段              | 类型           | 必填 | 说明                                                                |
| ----------------- | -------------- | ---- | ------------------------------------------------------------------- |
| `name`            | string         | 是   | 应用名称，至少 1 字符                                               |
| `description`     | string \| null | 否   | 描述，最多 400 字符                                                 |
| `mode`            | enum           | 是   | `chat` / `agent-chat` / `advanced-chat` / `workflow` / `completion` |
| `icon_type`       | enum \| null   | 否   | 图标类型                                                            |
| `icon`            | string \| null | 否   | 图标内容                                                            |
| `icon_background` | string \| null | 否   | 图标背景色                                                          |

### App 表核心字段

| 字段                                     | 说明                 |
| ---------------------------------------- | -------------------- |
| `tenant_id`                              | 所属工作区           |
| `name`                                   | 名称                 |
| `description`                            | 描述                 |
| `mode`                                   | 应用模式             |
| `icon_type` / `icon` / `icon_background` | 图标体系             |
| `app_model_config_id`                    | 当前模型配置         |
| `workflow_id`                            | 当前工作流           |
| `status`                                 | 状态，默认 `normal`  |
| `enable_site`                            | 是否启用站点         |
| `enable_api`                             | 是否启用 API         |
| `api_rpm` / `api_rph`                    | API 限流             |
| `is_demo` / `is_public` / `is_universal` | 发布与可见性标记     |
| `tracing`                                | 追踪配置             |
| `max_active_requests`                    | 最大并发请求数       |
| `use_icon_as_answer_icon`                | 回复是否沿用应用图标 |

### 开发注意点

1. 应用创建不是“只存一条 App”，还会联动生成 `AppModelConfig`、`Workflow`、`Site` 等关联对象。
2. `mode` 直接决定应用后续可见的功能模块。

---

## 2.2 更新应用

| 字段                      | 类型           | 说明                 |
| ------------------------- | -------------- | -------------------- |
| `name`                    | string         | 名称                 |
| `description`             | string \| null | 描述                 |
| `icon_type`               | enum \| null   | 图标类型             |
| `icon`                    | string \| null | 图标                 |
| `icon_background`         | string \| null | 图标背景             |
| `use_icon_as_answer_icon` | bool \| null   | 回复头像使用应用图标 |
| `max_active_requests`     | int \| null    | 最大活跃请求数       |

---

## 2.3 AppModelConfig（应用配置核心）

这是应用最关键的配置表之一，本质是“应用能力总装配”。

### 核心字段

| 字段                               | 说明                     |
| ---------------------------------- | ------------------------ |
| `provider` / `model_id`            | 当前主模型               |
| `configs`                          | 通用 JSON 配置           |
| `opening_statement`                | 开场白                   |
| `suggested_questions`              | 初始建议问题             |
| `suggested_questions_after_answer` | 回复后建议问题开关和配置 |
| `speech_to_text`                   | 语音转文本配置           |
| `text_to_speech`                   | 文本转语音配置           |
| `more_like_this`                   | 类似问题推荐配置         |
| `model`                            | 模型配置 JSON            |
| `user_input_form`                  | 用户输入表单定义         |
| `dataset_query_variable`           | 检索变量绑定字段         |
| `pre_prompt`                       | 预设 Prompt              |
| `agent_mode`                       | Agent 模式配置           |
| `sensitive_word_avoidance`         | 敏感词规避策略           |
| `retriever_resource`               | 检索资源配置             |
| `prompt_type`                      | `simple` 等提示词模式    |
| `chat_prompt_config`               | Chat Prompt 配置         |
| `completion_prompt_config`         | Completion Prompt 配置   |
| `dataset_configs`                  | 数据集检索配置           |
| `external_data_tools`              | 外部数据工具配置         |
| `file_upload`                      | 文件上传能力配置         |

### 说明

开发时可以把它理解为应用配置中心，前端一个“应用设置”页，大概率就是映射这张表。

---

## 2.4 站点配置（Site）

来源：`controllers/console/app/site.py`

| 字段                        | 类型           | 说明                           |
| --------------------------- | -------------- | ------------------------------ |
| `title`                     | string \| null | 站点标题                       |
| `icon_type`                 | string \| null | 图标类型                       |
| `icon`                      | string \| null | 图标                           |
| `icon_background`           | string \| null | 图标背景                       |
| `description`               | string \| null | 站点描述                       |
| `default_language`          | string \| null | 默认语言，必须是支持语言       |
| `chat_color_theme`          | string \| null | 聊天气泡主题色                 |
| `chat_color_theme_inverted` | bool \| null   | 是否反转色                     |
| `customize_domain`          | string \| null | 自定义域名                     |
| `copyright`                 | string \| null | 版权信息                       |
| `privacy_policy`            | string \| null | 隐私政策                       |
| `custom_disclaimer`         | string \| null | 自定义免责声明                 |
| `customize_token_strategy`  | enum \| null   | `must` / `allow` / `not_allow` |
| `prompt_public`             | bool \| null   | 是否公开 prompt                |
| `show_workflow_steps`       | bool \| null   | 是否展示工作流步骤             |
| `use_icon_as_answer_icon`   | bool \| null   | 回复图标是否继承应用图标       |

---

## 3. 工作流字段级功能明细

## 3.1 草稿同步

来源：`controllers/console/app/workflow.py`

| 字段                     | 类型           | 说明           |
| ------------------------ | -------------- | -------------- |
| `graph`                  | dict           | 画布图结构     |
| `features`               | dict           | 工作流特性配置 |
| `hash`                   | string \| null | 图结构哈希     |
| `environment_variables`  | list[dict]     | 环境变量       |
| `conversation_variables` | list[dict]     | 会话变量       |

### 说明

这说明前端工作流编辑器保存时，不只是保存 nodes/edges，还要同时保存 features 和变量定义。

## 3.2 运行工作流

| 场景                       | 字段                                                               |
| -------------------------- | ------------------------------------------------------------------ |
| Draft Workflow Run         | `inputs`, `files`                                                  |
| Draft Workflow Node Run    | `inputs`, `query`, `files`                                         |
| Advanced Chat Workflow Run | `inputs`, `query`, `conversation_id`, `parent_message_id`, `files` |

### 注意点

1. `conversation_id`、`parent_message_id` 都按 UUID 校验。
2. `files` 会走文件访问控制和上传配置转换，不是裸数组透传。

## 3.3 发布工作流

| 字段             | 类型           | 说明                     |
| ---------------- | -------------- | ------------------------ |
| `marked_name`    | string \| null | 发布标记名，最多 20 字符 |
| `marked_comment` | string \| null | 发布备注，最多 100 字符  |

## 3.4 Workflow 表核心字段

| 字段                             | 说明                   |
| -------------------------------- | ---------------------- |
| `tenant_id`                      | 工作区                 |
| `app_id`                         | 所属应用               |
| `type`                           | `workflow` 或 `chat`   |
| `version`                        | 版本号，草稿为 `draft` |
| `marked_name` / `marked_comment` | 发布标记               |
| `graph`                          | 画布 JSON              |
| `features`                       | 功能配置 JSON          |
| `environment_variables`          | 环境变量 JSON          |
| `conversation_variables`         | 会话变量 JSON          |
| `rag_pipeline_variables`         | RAG pipeline 变量      |

## 3.5 WorkflowRun 表核心字段

| 字段               | 说明                                           |
| ------------------ | ---------------------------------------------- |
| `workflow_id`      | 所属工作流                                     |
| `triggered_from`   | 触发来源，如 `debugging` / `app-run`           |
| `version`          | 运行时版本                                     |
| `graph`            | 运行时图快照                                   |
| `inputs`           | 输入参数                                       |
| `status`           | `running` / `succeeded` / `failed` / `stopped` |
| `outputs`          | 输出 JSON                                      |
| `error`            | 错误信息                                       |
| `elapsed_time`     | 总耗时                                         |
| `total_tokens`     | 总 token 消耗                                  |
| `total_steps`      | 总步骤数                                       |
| `created_by_role`  | 发起角色：`account` / `end_user`               |
| `created_by`       | 发起人 ID                                      |
| `exceptions_count` | 异常次数                                       |

---

## 4. 模型提供商与凭证字段

## 4.1 Provider 表

| 字段            | 说明                |
| --------------- | ------------------- |
| `tenant_id`     | 租户                |
| `provider_name` | 提供商名            |
| `provider_type` | `system` / `custom` |
| `is_valid`      | 是否可用            |
| `credential_id` | 当前凭证            |
| `quota_type`    | 配额类型            |
| `quota_limit`   | 配额上限            |
| `quota_used`    | 已用配额            |
| `last_used`     | 最近使用时间        |

## 4.2 ProviderModel 表

| 字段            | 说明     |
| --------------- | -------- |
| `tenant_id`     | 租户     |
| `provider_name` | 提供商名 |
| `model_name`    | 模型名   |
| `model_type`    | 模型类型 |
| `credential_id` | 凭证 ID  |
| `is_valid`      | 是否有效 |

## 4.3 Provider 凭证管理请求字段

来源：`workspace/model_providers.py`

| 操作                         | 字段                                      |
| ---------------------------- | ----------------------------------------- |
| 创建 provider 凭证           | `credentials`, `name`                     |
| 更新 provider 凭证           | `credential_id`, `credentials`, `name`    |
| 删除 provider 凭证           | `credential_id`                           |
| 切换当前 provider 凭证       | `credential_id`                           |
| 校验凭证                     | `credentials`                             |
| 设置 preferred provider type | `preferred_provider_type = system/custom` |

## 4.4 Model 级凭证与负载均衡字段

来源：`workspace/models.py`

| 操作          | 字段                                                          |
| ------------- | ------------------------------------------------------------- |
| 获取/设置模型 | `model`, `model_type`, `config_from`, `credential_id`         |
| 创建模型凭证  | `model`, `model_type`, `name`, `credentials`                  |
| 更新模型凭证  | `model`, `model_type`, `credential_id`, `credentials`, `name` |
| 删除模型凭证  | `model`, `model_type`, `credential_id`                        |
| 负载均衡      | `load_balancing = { enabled, configs[] }`                     |

---

## 5. 插件、工具、Endpoint、MCP 配置字段

## 5.1 插件偏好设置

来源：`workspace/plugin.py`

| 模块     | 字段                  | 说明             |
| -------- | --------------------- | ---------------- |
| 安装权限 | `install_permission`  | 谁能安装插件     |
| 调试权限 | `debug_permission`    | 谁能调试插件     |
| 自动升级 | `strategy_setting`    | 默认 `FIX_ONLY`  |
| 自动升级 | `upgrade_time_of_day` | 每日升级时间     |
| 自动升级 | `upgrade_mode`        | `EXCLUDE` 等模式 |
| 自动升级 | `exclude_plugins`     | 排除插件列表     |
| 自动升级 | `include_plugins`     | 包含插件列表     |

## 5.2 Plugin Endpoint

来源：`workspace/endpoint.py`

| 字段                       | 类型   | 说明          |
| -------------------------- | ------ | ------------- |
| `plugin_unique_identifier` | string | 插件唯一标识  |
| `settings`                 | dict   | endpoint 配置 |
| `name`                     | string | endpoint 名称 |

更新时额外带：

| 字段          | 说明          |
| ------------- | ------------- |
| `endpoint_id` | endpoint 主键 |

## 5.3 工具提供商

来源：`workspace/tool_providers.py`

### Builtin Tool 凭证

| 字段            | 说明            |
| --------------- | --------------- |
| `credentials`   | 工具凭证        |
| `name`          | 凭证名称        |
| `type`          | 凭证类型        |
| `credential_id` | 更新/删除时使用 |

### API Tool Provider

| 字段                | 说明                  |
| ------------------- | --------------------- |
| `credentials`       | 凭证                  |
| `schema_type`       | schema 类型           |
| `schema`            | OpenAPI / schema 原文 |
| `provider`          | provider 名称         |
| `icon`              | 图标配置              |
| `privacy_policy`    | 隐私政策              |
| `labels`            | 标签数组              |
| `custom_disclaimer` | 自定义免责声明        |

### Workflow Tool

| 字段                                   | 说明                       |
| -------------------------------------- | -------------------------- |
| `name`                                 | 工具英文名，只允许字母数字 |
| `label`                                | 显示名                     |
| `description`                          | 描述                       |
| `icon`                                 | 图标                       |
| `parameters`                           | 参数配置数组               |
| `privacy_policy`                       | 隐私政策                   |
| `labels`                               | 标签                       |
| `workflow_app_id` / `workflow_tool_id` | 创建/更新标识              |

### MCP Provider

| 字段                | 说明         |
| ------------------- | ------------ |
| `server_url`        | MCP 服务地址 |
| `name`              | 名称         |
| `icon`              | 图标         |
| `icon_type`         | 图标类型     |
| `icon_background`   | 图标背景     |
| `server_identifier` | 服务标识     |
| `configuration`     | 配置         |
| `headers`           | 自定义请求头 |
| `authentication`    | 鉴权配置     |

## 5.4 应用级 MCP Server

来源：`app/mcp_server.py`

| 操作 | 字段                                        |
| ---- | ------------------------------------------- |
| 创建 | `description`, `parameters`                 |
| 更新 | `id`, `description`, `parameters`, `status` |

### 注意点

1. 创建时如果没传 `description`，会回退到应用描述。
2. 服务创建后默认状态是 `ACTIVE`。

---

## 6. 给开发团队的实现建议

如果你要继续把这份文档做到“研发看完就能开做”，下一步建议按下面方式继续细化：

1. **每个核心模块补接口清单**：URL、Method、入参、出参、权限。
2. **每个核心对象补状态机**：如 Document、WorkflowRun、Message。
3. **每个配置型 JSON 补结构定义**：如 `retrieval_model`、`agent_mode`、`file_upload`。
4. **每个页面补操作流**：创建、编辑、发布、删除、调试、停用。
5. **每个对象补表关系图**：App -> AppModelConfig -> Workflow -> WorkflowRun；Dataset -> Document -> Segment。

如果继续做，我建议下一轮直接按这 5 个大模块逐个落：

1. 应用 App 全量规格
2. 知识库/RAG 全量规格
3. 工作流全量规格
4. 模型/插件/工具全量规格
5. Web/Service 运行时全量规格
