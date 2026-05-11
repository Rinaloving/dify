# Dify 功能需求明细清单（数据库对照版 / 便于开发与报价）

> 基于 [dify_db_schema_merged.sql](file:///D:/mygithub/dify/dify_db_schema_merged.sql)、[dify_plugin_schema_with_comments.sql](file:///D:/mygithub/dify/dify_plugin_schema_with_comments.sql)、以及 `api/models` / `api/controllers` 当前代码整理。  
> 用途：给开发人员直接拆需求、给老板做模块报价、给产品做字段级验收。

---

## 1. 总结结论：SQL 能不能对上当前功能点？

**结论：能对上大部分主流程，但不能 100% 作为唯一真相。应按“当前代码优先、SQL 辅助补充”使用。**

### 1.1 能直接对上的模块

1. 账号、租户、成员、邀请
2. 应用、应用配置、站点、安装应用
3. 知识库、文档、切片、索引规则、知识库查询
4. 会话、消息运行日志、Agent 思维链
5. 工作流运行、节点执行
6. 计费、套餐、配额、通知、任务、事件
7. 插件安装、插件端点、插件 README、无服务器运行时

### 1.2 对不上或存在“新旧结构差异”的部分

以下对象在 **当前代码里明确存在**，但在你给的 `dify_db_schema_merged.sql` 中**缺失或使用旧表替代**：

| 当前代码真实表                                                | SQL 中情况                         | 说明                                      |
| ------------------------------------------------------------- | ---------------------------------- | ----------------------------------------- |
| `messages`                                                    | 缺失，仅有 `conversation_messages` | 运行时消息表已升级，当前代码字段更完整    |
| `end_users`                                                   | 缺失                               | Web 最终用户体系在 SQL 中未体现           |
| `api_tokens`                                                  | 缺失                               | App / Dataset API Token 表在当前代码存在  |
| `upload_files`                                                | 缺失，仅有 `file_keys`             | 当前代码文件上传对象更细                  |
| `providers`                                                   | 缺失，仅有 `model_providers`       | 当前代码将 Provider 和 ProviderModel 拆分 |
| `provider_models`                                             | 缺失                               | 当前代码单独维护模型级凭证                |
| `workflows`                                                   | 缺失，仅有 `workflow_runs`         | 当前代码存在工作流定义表                  |
| `app_mcp_servers`                                             | 缺失                               | 当前代码新增应用级 MCP Server             |
| `tenant_default_models`                                       | 缺失                               | 当前代码有租户默认模型表                  |
| `message_files` / `message_feedbacks` / `message_annotations` | 缺失                               | 当前消息体系比 SQL 更完整                 |

### 1.3 开发时采用规则

1. **接口字段与行为**：以 `api/controllers` 为准。
2. **当前真实表结构**：以 `api/models` 为准。
3. **报价与模块盘点**：可用这两个 SQL 辅助确认模块广度、状态枚举、约束和历史设计。
4. **不要直接照 `dify_db_schema_merged.sql` 建库后就开发**，否则会漏掉当前代码已经存在的新对象。

---

## 2. 模块与数据库映射总表

| 模块        | 当前代码核心对象/表                                                     | SQL 中可对应表                                                                | 结论                       |
| ----------- | ----------------------------------------------------------------------- | ----------------------------------------------------------------------------- | -------------------------- |
| 账号体系    | `accounts`                                                              | `accounts`                                                                    | 一致                       |
| 工作区/租户 | `tenants`, `tenant_accounts`, `invited_accounts`                        | 同名表                                                                        | 一致                       |
| 应用        | `apps`, `app_model_configs`, `sites`                                    | 同名表                                                                        | 基本一致                   |
| 应用标注    | `app_annotations`, `app_annotation_settings`                            | 同名表                                                                        | 一致                       |
| 会话        | `conversations`                                                         | `conversations`                                                               | 基本一致                   |
| 消息        | `messages`, `message_files`, `message_feedbacks`, `message_annotations` | `conversation_messages`, `message_chains`, `message_agent_thoughts`           | **当前代码更完整**         |
| 最终用户    | `end_users`                                                             | 无                                                                            | **SQL 缺失**               |
| API Token   | `api_tokens`                                                            | 无                                                                            | **SQL 缺失**               |
| 文件上传    | `upload_files`, `file_keys`                                             | 仅 `file_keys`                                                                | **SQL 不完整**             |
| 知识库      | `datasets`, `dataset_process_rules`, `documents`, `document_segments`   | `datasets`, `dataset_process_rules`, `dataset_documents`, `document_segments` | **主流程一致，表名有差异** |
| 知识库扩展  | `dataset_queries`, `dataset_related_apps`, metadata/tag/binding 等      | 有 `dataset_queries`, `dataset_related_apps`                                  | 部分一致                   |
| 工作流定义  | `workflows`                                                             | 无                                                                            | **SQL 缺失**               |
| 工作流运行  | `workflow_runs`, `workflow_node_executions`                             | 同名表                                                                        | 基本一致                   |
| 模型提供商  | `providers`, `provider_models`, `tenant_default_models`                 | `model_providers`, `model_configurations`                                     | **设计已演进**             |
| 插件系统    | 插件安装/Endpoint/README/Runtime                                        | `plugins`, `plugin_installations`, `endpoints` 等                             | 一致                       |
| 计费配额    | `plans`, `billing_subscriptions`, `quota_limits`                        | 同名表                                                                        | 一致                       |
| 运维审计    | `notifications`, `events`, `tasks`, `api_requests`                      | 同名表                                                                        | 一致                       |

---

## 3. 平台基础模块：开发字段与报价明细

## 3.1 账号体系

### 关联表

1. `accounts`
2. `tenant_accounts`
3. `invited_accounts`

### 新增账号时要填写什么

| 字段                     | 来源       | 必填             | 说明                        |
| ------------------------ | ---------- | ---------------- | --------------------------- |
| `name`                   | `accounts` | 是               | 用户名/昵称                 |
| `email`                  | `accounts` | 是               | 唯一邮箱                    |
| `password`               | `accounts` | 视登录方式       | 邮箱密码登录时必填，需加密  |
| `avatar`                 | `accounts` | 否               | 头像 URL                    |
| `interface_language`     | `accounts` | 否               | 默认界面语言                |
| `interface_theme`        | `accounts` | 否               | 主题                        |
| `timezone`               | `accounts` | 否               | 时区                        |
| `provider`               | `accounts` | 是               | `dify` / GitHub / Google 等 |
| `provider_account_id`    | `accounts` | 第三方登录时必填 | 外部账号 ID                 |
| `invite_from_account_id` | `accounts` | 否               | 邀请来源                    |
| `email_validated`        | `accounts` | 否               | 邮箱是否验证                |

### 成员加入工作区时要填写什么

| 字段         | 来源              | 必填 | 说明                         |
| ------------ | ----------------- | ---- | ---------------------------- |
| `tenant_id`  | `tenant_accounts` | 是   | 目标工作区                   |
| `account_id` | `tenant_accounts` | 是   | 加入成员                     |
| `role`       | `tenant_accounts` | 是   | `owner` / `admin` / `member` |
| `invited_by` | `tenant_accounts` | 否   | 邀请人                       |

### 邀请成员时要填写什么

| 字段                 | 来源               | 必填 | 说明          |
| -------------------- | ------------------ | ---- | ------------- |
| `email`              | `invited_accounts` | 是   | 被邀请人邮箱  |
| `tenant_id`          | `invited_accounts` | 是   | 工作区        |
| `inviter_account_id` | `invited_accounts` | 是   | 邀请人        |
| `role`               | `invited_accounts` | 否   | 默认 `member` |
| `token`              | `invited_accounts` | 是   | 邀请令牌      |
| `expired_at`         | `invited_accounts` | 是   | 过期时间      |

### 状态/约束

1. `accounts.email` 唯一。
2. `account_status`: `active` / `pending` / `banned`。
3. `tenant_account_role`: `owner` / `admin` / `member`。

### 报价拆分项

1. 邮箱注册/登录/找回密码
2. 第三方 OAuth 登录
3. 工作区邀请与成员权限
4. 邮箱验证与邀请过期处理

---

## 3.2 工作区 / 套餐 / 配额

### 关联表

1. `tenants`
2. `plans`
3. `billing_subscriptions`
4. `quota_limits`
5. `recommended_steps`

### 新增工作区时要填写什么

| 字段     | 来源      | 必填 | 说明          |
| -------- | --------- | ---- | ------------- |
| `name`   | `tenants` | 是   | 工作区名称    |
| `plan`   | `tenants` | 否   | 默认 `basic`  |
| `status` | `tenants` | 否   | 默认 `normal` |

### 新增套餐时要填写什么

| 字段           | 来源    | 必填 | 说明                                    |
| -------------- | ------- | ---- | --------------------------------------- |
| `name`         | `plans` | 是   | 套餐名                                  |
| `type`         | `plans` | 是   | `basic` / `pro` / `team` / `enterprise` |
| `price`        | `plans` | 否   | 价格 JSON                               |
| `quota`        | `plans` | 否   | 配额 JSON                               |
| `features`     | `plans` | 否   | 功能开关 JSON                           |
| `is_public`    | `plans` | 否   | 是否公开售卖                            |
| `is_available` | `plans` | 否   | 是否可用                                |

### 新增订阅时要填写什么

| 字段                      | 来源                    | 必填 | 说明       |
| ------------------------- | ----------------------- | ---- | ---------- |
| `tenant_id`               | `billing_subscriptions` | 是   | 工作区     |
| `plan_id`                 | `billing_subscriptions` | 是   | 套餐 ID    |
| `status`                  | `billing_subscriptions` | 是   | 订阅状态   |
| `interval_unit`           | `billing_subscriptions` | 是   | 月/年等    |
| `interval_count`          | `billing_subscriptions` | 是   | 计费周期数 |
| `cancel_at_period_end`    | `billing_subscriptions` | 否   | 到期取消   |
| `current_period_start_at` | `billing_subscriptions` | 是   | 周期开始   |
| `current_period_end_at`   | `billing_subscriptions` | 是   | 周期结束   |

### 配额规则要填写什么

| 字段           | 来源           | 必填 | 说明                           |
| -------------- | -------------- | ---- | ------------------------------ |
| `tenant_id`    | `quota_limits` | 是   | 工作区                         |
| `resource`     | `quota_limits` | 是   | 限制资源项，如 API 次数/文档数 |
| `limit_value`  | `quota_limits` | 是   | 限额值                         |
| `period_unit`  | `quota_limits` | 是   | 时间单位                       |
| `period_count` | `quota_limits` | 是   | 周期数                         |

### 报价拆分项

1. 套餐中心
2. 订阅与到期处理
3. 工作区配额控制
4. 新手引导步骤

---

## 4. 应用模块：开发字段与报价明细

## 4.1 App 基础信息

### 关联表

1. `apps`
2. `installed_apps`
3. `sites`
4. `api_requests`

### 创建应用时要填写什么

以 **控制器创建字段 + App 表** 合并为准：

| 字段                | 来源                 | 必填 | 说明                                                                |
| ------------------- | -------------------- | ---- | ------------------------------------------------------------------- |
| `name`              | controller + `apps`  | 是   | 应用名称；同租户下唯一                                              |
| `mode`              | controller + `apps`  | 是   | `chat` / `agent-chat` / `advanced-chat` / `workflow` / `completion` |
| `description`       | controller           | 否   | 应用描述                                                            |
| `icon_type`         | controller / `sites` | 否   | 图标类型                                                            |
| `icon`              | controller + `apps`  | 否   | 图标                                                                |
| `icon_background`   | controller + `apps`  | 否   | 背景色                                                              |
| `enable_site`       | `apps`               | 否   | 是否启用站点                                                        |
| `enable_api`        | `apps`               | 否   | 是否启用 API                                                        |
| `api_rpm`           | `apps`               | 否   | 每分钟限流                                                          |
| `api_rph`           | `apps`               | 否   | 每小时限流                                                          |
| `is_public`         | `apps`               | 否   | 是否公开                                                            |
| `is_demo`           | `apps`               | 否   | 是否演示                                                            |
| `copyright`         | `apps`               | 否   | 版权信息                                                            |
| `privacy_policy`    | `apps`               | 否   | 隐私政策                                                            |
| `custom_disclaimer` | `apps`               | 否   | 自定义免责声明                                                      |

### 安装应用到租户时要填写什么

| 字段                  | 来源             | 必填 | 说明             |
| --------------------- | ---------------- | ---- | ---------------- |
| `tenant_id`           | `installed_apps` | 是   | 安装到哪个工作区 |
| `app_id`              | `installed_apps` | 是   | 安装哪个应用     |
| `is_pinned`           | `installed_apps` | 否   | 是否置顶         |
| `position`            | `installed_apps` | 否   | 排序             |
| `uninstall_feedbacks` | `installed_apps` | 否   | 卸载原因         |

### 约束

1. `apps(name, tenant_id)` 唯一。
2. 应用一旦启用站点或 API，就必须同步补齐对应配置。

### 报价拆分项

1. 应用 CRUD
2. 应用安装/卸载/置顶
3. 应用访问控制与限流
4. 应用访问日志

---

## 4.2 应用配置中心（AppModelConfig）

### 关联表

1. `app_model_configs`
2. `app_model_config_versions`

### 这是报价最大的对象之一

这个对象不是单一“模型设置”，而是应用运行时配置中心，前端一般要拆成多个配置页签。

### 创建/更新应用配置时要填写什么

| 字段                               | 必填 | 说明             |
| ---------------------------------- | ---- | ---------------- |
| `app_id`                           | 是   | 所属应用         |
| `provider`                         | 是   | 模型提供商       |
| `model_id`                         | 是   | 模型 ID          |
| `configs`                          | 否   | 通用配置 JSON    |
| `opening_statement`                | 否   | 开场白           |
| `suggested_questions`              | 否   | 初始推荐问题     |
| `suggested_questions_after_answer` | 否   | 回答后推荐问题   |
| `more_like_this`                   | 否   | 类似问题推荐     |
| `model`                            | 否   | 主模型参数配置   |
| `user_input_form`                  | 否   | 用户输入表单定义 |
| `pre_prompt`                       | 否   | 预提示词         |
| `agent_mode`                       | 否   | Agent 模式配置   |
| `retriever_resource`               | 否   | 检索资源         |
| `prompt_type`                      | 否   | 默认 `simple`    |
| `llm_top_k`                        | 否   | 多候选数         |
| `llm_score_threshold`              | 否   | LLM 分数阈值     |
| `external_data_tools`              | 否   | 外部工具配置     |
| `data_sources`                     | 否   | 数据源绑定       |
| `vision`                           | 否   | 视觉模型能力     |
| `image_file_ids`                   | 否   | 图片样本/素材    |
| `image_file_number_limit`          | 否   | 图片数量限制     |
| `image_file_size_limit`            | 否   | 图片大小限制     |
| `image_formats`                    | 否   | 图片格式限制     |
| `image_quality`                    | 否   | 图片质量         |
| `image_detail`                     | 否   | 图片细节         |
| `image_transfer_methods`           | 否   | 图片传输方式     |
| `citation`                         | 否   | 引用配置         |
| `speech_to_text`                   | 否   | 语音转文本       |
| `text_to_speech`                   | 否   | 文本转语音       |
| `annotation_reply`                 | 否   | 标注命中回复策略 |
| `sensitive_word_avoidance`         | 否   | 敏感词规避       |
| `agent_config`                     | 否   | Agent 细项配置   |
| `dataset_configs`                  | 否   | 知识库检索配置   |
| `file_upload`                      | 否   | 文件上传         |
| `file_upload_config`               | 否   | 文件上传限制     |
| `code_interpreter_tools`           | 否   | 代码解释器工具   |
| `workflow`                         | 否   | 工作流配置       |
| `memory`                           | 否   | 记忆配置         |
| `text_to_image`                    | 否   | 文生图配置       |
| `tool_icons`                       | 否   | 工具图标配置     |
| `file_reader`                      | 否   | 文件阅读器配置   |
| `rerank_config`                    | 否   | 重排配置         |
| `moderation_config`                | 否   | 内容审核配置     |

### 报价拆分项

建议单独按下面子模块报价：

1. 模型参数配置
2. Prompt 与开场白配置
3. 知识库检索配置
4. 文件上传与多模态配置
5. 语音能力配置
6. Agent / Workflow / Memory 配置
7. 审核/重排/安全配置

---

## 4.3 应用站点（Site）

### 当前代码真实表

当前代码中 `sites` 是 **按 App 维度** 配置，不是旧 SQL 那种纯 `tenant_id` 维度。

### 配置站点时要填写什么

| 字段                        | 来源                       | 必填     | 说明                           |
| --------------------------- | -------------------------- | -------- | ------------------------------ |
| `app_id`                    | current model              | 是       | 所属应用                       |
| `title`                     | current model + controller | 是       | 标题                           |
| `icon_type`                 | current model + controller | 否       | 图标类型                       |
| `icon`                      | current model + controller | 否       | 图标                           |
| `icon_background`           | current model + controller | 否       | 图标背景                       |
| `description`               | current model + controller | 否       | 描述                           |
| `default_language`          | current model + controller | 是       | 默认语言                       |
| `chat_color_theme`          | current model + controller | 否       | 聊天主题色                     |
| `chat_color_theme_inverted` | current model + controller | 否       | 是否反色                       |
| `copyright`                 | current model + controller | 否       | 版权信息                       |
| `privacy_policy`            | current model + controller | 否       | 隐私政策                       |
| `show_workflow_steps`       | current model + controller | 否       | 是否显示流程步骤               |
| `use_icon_as_answer_icon`   | current model + controller | 否       | 回答图标策略                   |
| `custom_disclaimer`         | current model + controller | 否       | 免责声明，当前代码限制 <= 512  |
| `customize_domain`          | current model + controller | 否       | 自定义域名                     |
| `customize_token_strategy`  | current model + controller | 是       | `must` / `allow` / `not_allow` |
| `prompt_public`             | current model + controller | 否       | 是否公开 Prompt                |
| `status`                    | current model              | 否       | 站点状态                       |
| `code`                      | current model              | 自动生成 | 外部访问码                     |

### 报价拆分项

1. 站点品牌配置
2. 域名与访问策略
3. 公开/私有访问控制
4. 站点样式与工作流步骤展示

---

## 5. 知识库与 RAG：开发字段与报价明细

## 5.1 知识库基础（Dataset）

### 关联表

1. `datasets`
2. `dataset_process_rules`
3. `dataset_documents` / 当前代码 `documents`
4. `document_segments`
5. `dataset_queries`
6. `dataset_related_apps`
7. `dataset_keyword_index_segments`
8. `dataset_document_index_tasks`

### 创建知识库时要填写什么

| 字段                         | 依据                    | 必填             | 说明                                               |
| ---------------------------- | ----------------------- | ---------------- | -------------------------------------------------- |
| `tenant_id`                  | `datasets`              | 是               | 所属工作区                                         |
| `name`                       | controller + `datasets` | 是               | 名称；同租户唯一                                   |
| `description`                | controller + `datasets` | 否               | 描述                                               |
| `provider`                   | controller + `datasets` | 否               | `vendor` / `external`                              |
| `permission`                 | controller + `datasets` | 否               | `only_me` / `all_team_members` / `partial_members` |
| `data_source_type`           | `datasets`              | 视场景           | 数据源类型                                         |
| `indexing_technique`         | controller + `datasets` | 否               | `high_quality` / `economy`                         |
| `chunk_size`                 | `datasets`              | 否               | 旧结构字段，实际可转化为切片规则                   |
| `embedding_model`            | controller + `datasets` | 否               | 向量模型                                           |
| `embedding_model_provider`   | controller + `datasets` | 否               | 向量模型提供商                                     |
| `retrieval_model`            | controller + `datasets` | 否               | 检索模型 JSON                                      |
| `summary_index_setting`      | current model           | 否               | 摘要索引配置                                       |
| `external_knowledge_api_id`  | controller              | 外部知识库时必填 | 外部 API ID                                        |
| `external_knowledge_id`      | controller              | 外部知识库时必填 | 外部知识源 ID                                      |
| `external_retrieval_setting` | SQL / controller        | 否               | 外部检索配置                                       |
| `icon_info`                  | current model           | 否               | 图标配置                                           |
| `built_in_field_enabled`     | current model           | 否               | 是否启用内置元字段                                 |
| `runtime_mode`               | current model           | 否               | 默认 `general`                                     |
| `enable_api`                 | current model           | 否               | 是否允许 API 访问                                  |
| `is_multimodal`              | current model           | 否               | 是否多模态                                         |

### 功能点说明（按页面动作展开）

#### 1. 功能点：创建 Dataset

这个功能对开发来说不能只理解成“新增一条 `datasets` 记录”。在产品上，它通常拆成两种入口：

1. **创建空知识库**：先创建知识库基础信息，后面再慢慢导入文件。
2. **创建知识库并立即初始化文档**：创建时就上传文件、选 embedding、选切片规则，然后直接开始索引。

#### 1.1 创建空知识库时，页面上用户会填写什么

| 页面操作项 | 对应字段/对象 | 必填 | 说明 |
| --- | --- | --- | --- |
| 填写知识库名称 | `datasets.name` | 是 | 1~40 字，同工作区唯一 |
| 填写知识库说明 | `datasets.description` | 否 | 最多 400 字 |
| 选择知识来源类型 | `datasets.provider` | 否 | 内部知识库 `vendor`；外部知识库 `external` |
| 选择权限范围 | `datasets.permission` | 否 | 仅自己、全员、部分成员 |
| 选择索引模式 | `datasets.indexing_technique` | 否 | 高质量 `high_quality` 或经济模式 `economy` |
| 外部 API 模板 | `external_knowledge_api_id` | 外部知识库时必填 | 选外部知识服务连接模板 |
| 外部知识库 ID | `external_knowledge_id` | 外部知识库时必填 | 填外部系统里的知识库标识 |

#### 1.2 创建空知识库时，数据库会怎么落

| 表/对象 | 写入内容 |
| --- | --- |
| `datasets` | 知识库主记录 |
| 权限关系对象 | 当权限是 `partial_members` 时，保存部分成员可见名单 |
| 外部知识绑定对象 | 当 `provider=external` 时，保存外部知识 API 与外部知识库映射 |

#### 1.3 创建空知识库时的默认值

1. `provider` 默认 `vendor`。
2. `permission` 默认 `only_me`。
3. 如果不立即导入文档，`embedding_model`、`retrieval_model` 等可以先不填。
4. 这一步的核心目标是生成一个可配置、可继续导入内容的 Dataset 容器。

#### 1.4 创建知识库并立即导入文件时，还要填写什么

这个动作对应 `/datasets/init` 或 `/datasets/<dataset_id>/documents`。它本质上是“知识导入配置流程”。

用户会继续操作这些内容：

| 页面操作项 | 对应字段/对象 | 必填 | 说明 |
| --- | --- | --- | --- |
| 选择导入方式 | `data_source_type` / `KnowledgeConfig` | 是 | 上传文件、Notion、网站抓取 |
| 选择文件 | `upload_files.id` / `file_ids` | 上传文件时必填 | 文件要先上传，再引用文件 ID |
| 选择文档结构 | `doc_form` | 否 | 默认 `text_model` |
| 选择文档语言 | `doc_language` | 否 | 用于解析与摘要等流程 |
| 选择切片模式 | `dataset_process_rules.mode` | 是 | 自动 / 自定义 / 分层 |
| 填写切片规则 | `dataset_process_rules.rules` | 是 | 分隔符、最大 token、chunk overlap、清洗规则 |
| 选择索引模式 | `datasets.indexing_technique` | 是 | 高质量 / 经济 |
| 选择 embedding provider | `datasets.embedding_model_provider` | 高质量时必填 | 向量模型提供商 |
| 选择 embedding model | `datasets.embedding_model` | 高质量时必填 | 向量模型名称 |
| 是否摘要索引 | `summary_index_setting.enable` | 否 | 开启后还要配摘要模型 |

#### 1.5 “选择文件”到底落在哪里

你特别提到“选择文件”，这里要明确：

1. 文件本身先落到 `upload_files`。
2. 然后知识库导入配置里传 `file_ids`。
3. 导入成功后会生成：
   - `documents`
   - `document_segments`
   - `dataset_document_index_tasks`
   - 关键词索引
   - 向量索引

也就是说，**“创建知识库并选文件导入”是一个复合动作**，不是单表写入。

#### 1.6 高质量索引时为什么必须选 embedding

当用户选择 `indexing_technique = high_quality` 时，系统必须能真正做向量化，所以必须同时满足：

1. 已配置可用的模型提供商
2. 已选择 `embedding_model_provider`
3. 已选择 `embedding_model`

如果缺其中之一，后端会直接报错，前端不能只让用户选了“高质量”就提交。

#### 2. 功能点：配置 Dataset

这个功能不是简单编辑名称，而是一个知识库配置中心。开发时建议按 6 个页签理解：

1. 基本信息
2. 检索配置
3. 摘要索引配置
4. 元数据配置
5. 权限成员配置
6. 运营统计配置（热度/查询）

#### 2.1 基本信息配置要填写什么

| 页面操作项 | 对应字段 | 说明 |
| --- | --- | --- |
| 修改名称 | `datasets.name` | 1~40 字 |
| 修改描述 | `datasets.description` | 最多 400 字 |
| 修改图标 | `datasets.icon_info` | 包含 `icon_type`、`icon`、`icon_background`、`icon_url` |
| 切换索引模式 | `datasets.indexing_technique` | economy / high_quality |
| 切换 embedding provider | `datasets.embedding_model_provider` | 高质量索引才需要 |
| 切换 embedding model | `datasets.embedding_model` | 高质量索引才需要 |
| 是否允许 API 访问 | `datasets.enable_api` | 决定 Dataset API 是否可调用 |
| 是否多模态 | `datasets.is_multimodal` | 当前代码会结合模型能力自动判断 |

#### 2.2 检索配置到底有哪些字段

这部分不要只写成 `retrieval_model`，应该展开成可配置项：

| 页面操作项 | 对应字段 | 说明 |
| --- | --- | --- |
| 选择检索方式 | `retrieval_model.search_method` | 语义检索 / 全文检索 / 混合检索 |
| 是否启用重排 | `retrieval_model.reranking_enable` | 是否对召回结果再次排序 |
| 选择重排模式 | `retrieval_model.reranking_mode` | 重排执行模式 |
| 选择重排 provider | `retrieval_model.reranking_model.reranking_provider_name` | 重排模型供应商 |
| 选择重排模型 | `retrieval_model.reranking_model.reranking_model_name` | 重排模型名称 |
| 召回条数 TopK | `retrieval_model.top_k` | 一次召回几条 |
| 是否启用分数阈值 | `retrieval_model.score_threshold_enabled` | 是否过滤低相关结果 |
| 分数阈值 | `retrieval_model.score_threshold` | 命中阈值 |
| 权重类型 | `retrieval_model.weights.weight_type` | 混合检索时权重策略 |
| 关键词权重 | `retrieval_model.weights.keyword_setting.keyword_weight` | 全文侧权重 |
| 向量权重 | `retrieval_model.weights.vector_setting.vector_weight` | 向量侧权重 |
| 向量权重说明模型 | `retrieval_model.weights.vector_setting.embedding_model_name` | 展示用 |
| 向量权重说明 provider | `retrieval_model.weights.vector_setting.embedding_provider_name` | 展示用 |

#### 2.3 摘要索引配置要填写什么

| 页面操作项 | 对应字段 | 说明 |
| --- | --- | --- |
| 是否启用摘要索引 | `summary_index_setting.enable` | 开启后文档可生成摘要索引 |
| 选择摘要模型 | `summary_index_setting.model_name` | 摘要生成模型 |
| 选择摘要模型 provider | `summary_index_setting.model_provider_name` | 摘要模型来源 |
| 自定义摘要 Prompt | `summary_index_setting.summary_prompt` | 摘要提示词 |

#### 2.4 外部知识库配置要填写什么

当 Dataset 是外部知识库时，还需要额外配置外部检索参数：

| 页面操作项 | 对应字段 | 说明 |
| --- | --- | --- |
| 外部 TopK | `external_retrieval_model.top_k` | 从外部系统取几条 |
| 是否启用分数阈值 | `external_retrieval_model.score_threshold_enabled` | 是否过滤低分数据 |
| 外部阈值 | `external_retrieval_model.score_threshold` | 命中阈值 |

#### 2.5 元数据配置要填写什么

这部分来自 `/datasets/<uuid:dataset_id>/metadata` 系列接口：

| 页面操作项 | 对应对象 | 说明 |
| --- | --- | --- |
| 新增元数据字段 | Dataset Metadata | 例如“部门”“年份”“知识来源” |
| 修改字段名称 | Metadata.name | 修改展示名 |
| 删除字段 | Metadata 删除接口 | 删除该元数据定义 |
| 启用内置字段 | `datasets.built_in_field_enabled` | 启用 `document_name/uploader/upload_date/last_update_date/source` |
| 批量写文档元数据 | 文档元数据绑定关系 | 给现有文档统一打元数据 |

#### 2.6 权限配置要填写什么

| 页面操作项 | 对应字段 | 说明 |
| --- | --- | --- |
| 仅自己可见 | `datasets.permission = only_me` | 默认值 |
| 全员可见 | `datasets.permission = all_team_members` | 工作区全员 |
| 指定成员可见 | `datasets.permission = partial_members` | 还必须提交 `partial_member_list` |
| 指定成员列表 | `partial_member_list` | 账号 ID 列表 |

#### 2.7 你说的“热度”在 Dataset 模块里怎么体现

当前代码里“热度”主要不是一个手填字段，而是由系统统计出来，开发要做成页面能力：

| 热度维度 | 对应字段/来源 | 页面表现 |
| --- | --- | --- |
| 文档热度 | `Document.hit_count`（由 Segment 聚合） | 文档列表支持按热度排序 |
| 切片热度 | `document_segments.hit_count` | 切片详情展示命中次数 |
| 查询热度 | `dataset_queries` | 看用户经常搜什么 |

在文档列表里，当前代码已经支持：

1. 按 `created_at` 排序
2. 按 `hit_count` 排序

所以产品上应该给出“按创建时间 / 按热度”排序选项，而不是在创建 Dataset 时手填一个“热度”字段。

#### 3. 功能点：删除 Dataset

#### 3.1 删除前要做哪些检查

| 检查项 | 依据 | 说明 |
| --- | --- | --- |
| 用户是否有权限 | controller 权限判断 | 需要编辑权限或知识库操作权限 |
| 知识库是否存在 | `DatasetService.get_dataset` | 不存在直接 404 |
| 是否正在被应用使用 | `/datasets/<id>/use-check` | 在用时通常不能删 |
| 是否存在索引中任务 | 文档/索引任务状态 | 索引中删除要谨慎处理 |

#### 3.2 删除后要清哪些数据

删除知识库不是只删 `datasets` 一张表，通常还要联动清理：

1. `documents`
2. `document_segments`
3. `dataset_process_rules`
4. `dataset_related_apps`
5. 部分成员权限关系
6. 外部知识绑定关系
7. 向量索引集合

#### 3.3 删除为什么要单独报价

因为这个动作至少涉及：

1. 引用检查
2. 资源清理
3. 索引清理
4. 权限清理
5. 异常回滚和幂等

### 规则与状态

1. `datasets(name, tenant_id)` 唯一。
2. `dataset_status`: `setup` / `indexing` / `normal` / `archived`。
3. `dataset_type`: `normal` / `retrieval`。

### 报价拆分项

1. 知识库 CRUD
2. 内部知识库与外部知识库双模式
3. 检索参数与权限配置
4. 知识库-应用绑定
5. 文件导入初始化
6. 元数据配置
7. 热度统计与查询日志
8. 删除前检查与资源清理

---

## 5.2 文档导入（Document）

### 新增文档时要填写什么

| 字段                                 | 来源                              | 必填 | 说明                                              |
| ------------------------------------ | --------------------------------- | ---- | ------------------------------------------------- |
| `dataset_id`                         | `dataset_documents` / `documents` | 是   | 目标知识库                                        |
| `position`                           | `dataset_documents` / `documents` | 是   | 顺序                                              |
| `data_source_type`                   | `dataset_documents` / `documents` | 是   | `upload_file` / `notion_import` / `website_crawl` |
| `data_source_info`                   | `dataset_documents` / `documents` | 否   | 来源详情 JSON                                     |
| `dataset_process_rule_id`            | `dataset_documents` / `documents` | 否   | 处理规则                                          |
| `name`                               | `dataset_documents` / `documents` | 是   | 文档名                                            |
| `created_from`                       | `dataset_documents` / `documents` | 是   | 创建来源                                          |
| `created_by`                         | `dataset_documents` / `documents` | 是   | 创建人                                            |
| `created_api_request_id`             | `dataset_documents` / `documents` | 否   | API 来源时记录                                    |
| `batch`                              | `dataset_documents` / `documents` | 否   | 批次                                              |
| `doc_form`                           | `dataset_documents` / `documents` | 否   | 文档结构形式                                      |
| `doc_language`                       | `dataset_documents` / `documents` | 否   | 语言                                              |
| `doc_type`                           | `dataset_documents` / `documents` | 否   | 文档类型                                          |
| `document_metadata` / `doc_metadata` | SQL / current model               | 否   | 元数据                                            |
| `need_summary`                       | current model                     | 否   | 是否做摘要索引                                    |

### 文档状态要支持什么

1. 上传态：`uploading` / `uploaded`
2. 可用态：`available` / `enabled` / `disabled`
3. 异常态：`error` / `deleted`
4. 索引态：`waiting` / `parsing` / `cleaning` / `splitting` / `indexing` / `completed` / `error` / `paused`

### 报价拆分项

1. 文件上传导入
2. Notion 导入
3. 网站抓取导入
4. 文档处理队列与进度展示
5. 文档归档/启停/错误重试

---

## 5.3 切片（DocumentSegment）

### 新增切片时要填写什么

| 字段               | 来源                             | 必填 | 说明         |
| ------------------ | -------------------------------- | ---- | ------------ |
| `dataset_id`       | `document_segments`              | 是   | 所属知识库   |
| `document_id`      | `document_segments`              | 是   | 所属文档     |
| `position`         | `document_segments`              | 是   | 顺序         |
| `content`          | controller + `document_segments` | 是   | 切片正文     |
| `answer`           | controller + `document_segments` | 否   | 标准答案     |
| `keywords`         | controller + `document_segments` | 否   | 关键词       |
| `attachment_ids`   | controller                       | 否   | 附件         |
| `custom_meta_data` | `document_segments`              | 否   | 自定义元数据 |
| `segment_metadata` | `document_segments`              | 否   | 切片元数据   |
| `doc_form`         | `document_segments`              | 否   | 结构形式     |
| `doc_language`     | `document_segments`              | 否   | 语言         |
| `doc_type`         | `document_segments`              | 否   | 类型         |

### 更新切片时要额外填写什么

1. `regenerate_child_chunks`
2. `summary`
3. `enabled`

### 报价拆分项

1. 切片 CRUD
2. 关键词维护
3. 父子 chunk / hierarchical 模式
4. 切片启停与命中统计
5. 实体/关系抽取增强

---

## 5.4 命中测试、查询日志、应用绑定

### 对应对象

1. `dataset_queries`
2. `dataset_related_apps`
3. `dataset_keyword_index_segments`
4. `dataset_document_index_tasks`

### 功能点与填报字段

| 功能           | 关键字段                                                                 |
| -------------- | ------------------------------------------------------------------------ |
| 命中测试       | `query`, `retrieval_model`, `external_retrieval_model`, `attachment_ids` |
| 查询日志       | `dataset_id`, `content`, `source`, `created_by_role`, `created_by`       |
| 应用绑定知识库 | `dataset_id`, `app_id`                                                   |
| 文档索引任务   | `dataset_document_id`, 任务状态、开始/结束时间                           |

---

## 6. 运行时会话与消息：开发字段与报价明细

## 6.1 会话（Conversation）

### 新增会话时要填写什么

| 字段                               | 来源            | 必填               | 说明                      |
| ---------------------------------- | --------------- | ------------------ | ------------------------- |
| `app_id`                           | `conversations` | 是                 | 所属应用                  |
| `app_model_config_id`              | `conversations` | 是                 | 运行配置                  |
| `from_source`                      | `conversations` | 是                 | 来源：Web / Console / API |
| `from_end_user_id`                 | `conversations` | Web 用户时必填     | 最终用户                  |
| `from_account_id`                  | `conversations` | Console 用户时必填 | 后台账号                  |
| `name`                             | `conversations` | 是                 | 会话标题                  |
| `summary`                          | `conversations` | 否                 | 摘要                      |
| `system_instruction`               | `conversations` | 否                 | 系统指令                  |
| `introduction`                     | `conversations` | 否                 | 介绍                      |
| `suggested_questions_after_answer` | `conversations` | 否                 | 推荐问题                  |
| `external_retrieval_resources`     | `conversations` | 否                 | 外部检索资源              |
| `in_debug_mode`                    | `conversations` | 否                 | 调试模式                  |
| `workflow_run_id`                  | `conversations` | 否                 | 关联工作流执行            |

### 当前代码补充缺失对象

当前代码还存在 `end_users` 表：

| 字段               | 说明         |
| ------------------ | ------------ |
| `tenant_id`        | 工作区       |
| `app_id`           | 所属应用     |
| `type`             | 用户类型     |
| `external_user_id` | 外部用户标识 |
| `name`             | 用户名       |
| `is_anonymous`     | 是否匿名     |
| `session_id`       | 会话标识     |

### 报价拆分项

1. 会话列表与分页
2. 会话来源区分（控制台/最终用户/API）
3. 会话调试模式
4. 终端用户画像

---

## 6.2 消息（Message）

### 重要提醒

SQL 中是 `conversation_messages`，但当前代码真实运行表是 `messages`，并且 **字段更多、关系更完整**。

### 新增消息时要填写什么

| 字段                        | 来源          | 必填   | 说明             |
| --------------------------- | ------------- | ------ | ---------------- |
| `app_id`                    | current model | 是     | 所属应用         |
| `conversation_id`           | current model | 是     | 所属会话         |
| `model_provider`            | current model | 否     | 模型提供商       |
| `model_id`                  | current model | 否     | 模型 ID          |
| `override_model_configs`    | current model | 否     | 覆盖配置         |
| `inputs`                    | current model | 否     | 输入表单值       |
| `query`                     | current model | 是     | 用户问题         |
| `message`                   | current model | 是     | 消息结构         |
| `answer`                    | current model | 是     | 回复内容         |
| `message_tokens`            | current model | 否     | 输入 token       |
| `answer_tokens`             | current model | 否     | 输出 token       |
| `message_unit_price`        | current model | 否     | 输入单价         |
| `answer_unit_price`         | current model | 否     | 输出单价         |
| `total_price`               | current model | 否     | 总价             |
| `currency`                  | current model | 否     | 货币             |
| `parent_message_id`         | current model | 否     | 多轮父消息       |
| `provider_response_latency` | current model | 否     | 响应时延         |
| `status`                    | current model | 否     | 消息状态         |
| `error`                     | current model | 否     | 错误信息         |
| `message_metadata`          | current model | 否     | 检索资源等元数据 |
| `from_source`               | current model | 是     | 来源             |
| `from_end_user_id`          | current model | 视来源 | 终端用户 ID      |
| `from_account_id`           | current model | 视来源 | 后台账号 ID      |
| `agent_based`               | current model | 否     | 是否 Agent 模式  |
| `workflow_run_id`           | current model | 否     | 关联工作流       |
| `app_mode`                  | current model | 否     | 应用模式         |

### 消息扩展对象

| 表                             | 作用                 | 报价意义           |
| ------------------------------ | -------------------- | ------------------ |
| `message_files`                | 消息附件             | 文件问答、图片问答 |
| `message_feedbacks`            | 点赞点踩/评分        | 反馈闭环           |
| `message_annotations`          | 消息标注             | 训练与修正         |
| `app_annotation_hit_histories` | 标注命中历史         | 标注策略命中       |
| `message_chains`               | Prompt / tool 执行链 | 调试与审计         |
| `message_agent_thoughts`       | Agent 思考过程       | Agent 可解释性     |

### 报价拆分项

1. 聊天消息流
2. 流式返回与消息持久化
3. 消息附件
4. 点赞点踩/标注
5. Agent 思考链与工具轨迹
6. Token / 成本统计

---

## 7. 工作流：开发字段与报价明细

## 7.1 工作流定义（Current Code Only）

### 当前代码真实表

1. `workflows`

### 创建工作流时要填写什么

| 字段                     | 来源                       | 必填 | 说明                |
| ------------------------ | -------------------------- | ---- | ------------------- |
| `tenant_id`              | current model              | 是   | 工作区              |
| `app_id`                 | current model              | 是   | 所属应用            |
| `type`                   | current model              | 是   | `workflow` / `chat` |
| `version`                | current model              | 是   | `draft` 或发布版本  |
| `marked_name`            | current model              | 否   | 发布标记名          |
| `marked_comment`         | current model              | 否   | 发布说明            |
| `graph`                  | current model + controller | 是   | 画布 JSON           |
| `features`               | current model + controller | 否   | 功能配置 JSON       |
| `environment_variables`  | current model + controller | 否   | 环境变量            |
| `conversation_variables` | current model + controller | 否   | 会话变量            |
| `rag_pipeline_variables` | current model              | 否   | RAG Pipeline 变量   |
| `created_by`             | current model              | 是   | 创建人              |

### 报价拆分项

1. 画布保存/加载
2. 工作流版本管理
3. 变量系统
4. 发布标记与回滚

---

## 7.2 工作流运行

### 关联表

1. `workflow_runs`
2. `workflow_node_executions`

### 创建运行记录时要填写什么

| 字段                              | 来源                | 必填 | 说明                                           |
| --------------------------------- | ------------------- | ---- | ---------------------------------------------- |
| `tenant_id`                       | current model       | 是   | 工作区                                         |
| `app_id`                          | current model       | 是   | 应用                                           |
| `workflow_id`                     | SQL + current model | 是   | 工作流                                         |
| `type`                            | current model       | 是   | 工作流类型                                     |
| `triggered_from` / `trigger_from` | current model / SQL | 是   | `debugging` / `app-run` 等                     |
| `version`                         | SQL + current model | 是   | 运行版本                                       |
| `graph`                           | SQL + current model | 否   | 运行图快照                                     |
| `inputs`                          | SQL + current model | 否   | 输入                                           |
| `status`                          | SQL + current model | 是   | `running` / `succeeded` / `failed` / `stopped` |
| `outputs`                         | SQL + current model | 否   | 输出                                           |
| `error`                           | SQL + current model | 否   | 错误                                           |
| `elapsed_time`                    | current model       | 否   | 总耗时                                         |
| `total_tokens`                    | current model       | 否   | 总 token                                       |
| `total_steps`                     | current model       | 否   | 总步骤                                         |
| `created_by_role`                 | current model       | 是   | `account` / `end_user`                         |
| `created_by`                      | current model       | 是   | 发起人                                         |
| `finished_at` / `completed_at`    | current model / SQL | 否   | 完成时间                                       |
| `exceptions_count`                | current model       | 否   | 异常次数                                       |

### 节点执行要填写什么

| 字段              | 来源 | 必填 | 说明                               |
| ----------------- | ---- | ---- | ---------------------------------- |
| `workflow_run_id` | SQL  | 是   | 所属运行                           |
| `node_id`         | SQL  | 是   | 节点 ID                            |
| `node_type`       | SQL  | 是   | 节点类型                           |
| `node_config`     | SQL  | 否   | 节点配置                           |
| `status`          | SQL  | 是   | `running` / `succeeded` / `failed` |
| `inputs`          | SQL  | 否   | 输入                               |
| `outputs`         | SQL  | 否   | 输出                               |
| `error`           | SQL  | 否   | 错误                               |
| `started_at`      | SQL  | 否   | 开始时间                           |
| `completed_at`    | SQL  | 否   | 完成时间                           |

### 报价拆分项

1. 草稿调试
2. 正式运行
3. 节点级日志
4. 失败重试与停止
5. 执行成本统计

---

## 8. 模型提供商与凭证：开发字段与报价明细

## 8.1 SQL 历史结构

SQL 中有：

1. `model_providers`
2. `model_configurations`

## 8.2 当前代码真实结构

当前代码已经拆成：

1. `providers`
2. `provider_models`
3. `tenant_default_models`

### 新增 Provider 时要填写什么

| 字段            | 来源          | 必填 | 说明                |
| --------------- | ------------- | ---- | ------------------- |
| `tenant_id`     | current model | 是   | 工作区              |
| `provider_name` | current model | 是   | 提供商名            |
| `provider_type` | current model | 是   | `system` / `custom` |
| `credential_id` | current model | 否   | 默认凭证            |
| `is_valid`      | current model | 否   | 凭证是否校验通过    |
| `quota_type`    | current model | 否   | 配额类型            |
| `quota_limit`   | current model | 否   | 配额上限            |
| `quota_used`    | current model | 否   | 已使用量            |

### 新增 Provider Model 时要填写什么

| 字段            | 来源          | 必填 | 说明         |
| --------------- | ------------- | ---- | ------------ |
| `tenant_id`     | current model | 是   | 工作区       |
| `provider_name` | current model | 是   | 提供商       |
| `model_name`    | current model | 是   | 模型名       |
| `model_type`    | current model | 是   | 模型类型     |
| `credential_id` | current model | 否   | 模型级凭证   |
| `is_valid`      | current model | 否   | 是否校验通过 |

### 租户默认模型要填写什么

| 字段            | 来源          | 必填 | 说明     |
| --------------- | ------------- | ---- | -------- |
| `tenant_id`     | current model | 是   | 工作区   |
| `provider_name` | current model | 是   | 提供商   |
| `model_name`    | current model | 是   | 模型名   |
| `model_type`    | current model | 是   | 模型类型 |

### 报价拆分项

1. Provider 凭证管理
2. 模型级凭证管理
3. 默认模型管理
4. 负载均衡 / 多 Key 容灾

---

## 9. 文件与附件：开发字段与报价明细

## 9.1 当前代码真实对象

1. `upload_files`
2. `file_keys`
3. `message_files`

### 上传文件时要填写什么

| 字段              | 来源           | 必填 | 说明                   |
| ----------------- | -------------- | ---- | ---------------------- |
| `tenant_id`       | `upload_files` | 是   | 工作区                 |
| `storage_type`    | `upload_files` | 是   | 本地 / S3 / OSS 等     |
| `key`             | `upload_files` | 是   | 存储键                 |
| `name`            | `upload_files` | 是   | 文件名                 |
| `size`            | `upload_files` | 是   | 文件大小               |
| `extension`       | `upload_files` | 是   | 后缀                   |
| `mime_type`       | `upload_files` | 否   | MIME 类型              |
| `created_by_role` | `upload_files` | 是   | `account` / `end_user` |
| `created_by`      | `upload_files` | 是   | 创建者                 |
| `hash`            | `upload_files` | 否   | 哈希                   |
| `source_url`      | `upload_files` | 否   | 来源 URL               |

### 文件 Key 管理时要填写什么

| 字段                   | 来源        | 必填 | 说明                             |
| ---------------------- | ----------- | ---- | -------------------------------- |
| `tenant_id`            | `file_keys` | 是   | 工作区                           |
| `type`                 | `file_keys` | 是   | `image/audio/video/document/...` |
| `file_name`            | `file_keys` | 是   | 文件名                           |
| `file_extension`       | `file_keys` | 是   | 扩展名                           |
| `file_size`            | `file_keys` | 是   | 文件大小                         |
| `upload_file_id`       | `file_keys` | 否   | 对应上传文件                     |
| `used_by_app_template` | `file_keys` | 否   | 是否用于模板                     |

### 报价拆分项

1. 文件上传
2. 文件签名访问
3. 消息附件管理
4. 文件权限与存储适配

---

## 10. 插件系统：开发字段与报价明细

插件系统是单独数据库 `dify_plugin`，报价时建议单列。

### 10.1 插件基础信息

| 表                      | 主要字段                                                                                                 | 功能含义   |
| ----------------------- | -------------------------------------------------------------------------------------------------------- | ---------- |
| `plugins`               | `plugin_unique_identifier`, `plugin_id`, `install_type`, `manifest_type`, `source`, `remote_declaration` | 插件元数据 |
| `plugin_declarations`   | `plugin_unique_identifier`, `declaration`                                                                | 声明内容   |
| `plugin_readme_records` | `plugin_unique_identifier`, `language`, `content`                                                        | 多语言说明 |

### 10.2 插件安装与运行

| 表                     | 主要字段                                                                                 | 功能含义       |
| ---------------------- | ---------------------------------------------------------------------------------------- | -------------- |
| `plugin_installations` | `tenant_id`, `plugin_id`, `runtime_type`, `endpoints_setups`, `endpoints_active`, `meta` | 插件安装实例   |
| `install_tasks`        | `status`, `tenant_id`, `total_plugins`, `completed_plugins`, `plugins`                   | 批量安装任务   |
| `serverless_runtimes`  | `plugin_unique_identifier`, `function_url`, `function_name`, `type`, `checksum`          | 无服务器运行时 |
| `tenant_storages`      | `tenant_id`, `plugin_id`, `size`                                                         | 插件存储用量   |

### 10.3 插件端点

| 表          | 新增/编辑时要填写什么                                                                       |
| ----------- | ------------------------------------------------------------------------------------------- |
| `endpoints` | `name`, `hook_id`, `tenant_id`, `user_id`, `plugin_id`, `expired_at`, `enabled`, `settings` |

### 10.4 按能力分类安装表

| 表                             | 含义           |
| ------------------------------ | -------------- |
| `tool_installations`           | 工具类插件     |
| `trigger_installations`        | 触发器类插件   |
| `datasource_installations`     | 数据源类插件   |
| `ai_model_installations`       | 模型类插件     |
| `agent_strategy_installations` | Agent 策略插件 |

### 报价拆分项

1. 插件市场
2. 插件安装/卸载/升级
3. 插件 README / 图标 / 声明展示
4. 插件端点配置
5. 插件运行时与存储统计

---

## 11. 运维、通知、审计：开发字段与报价明细

### 关联表

1. `notifications`
2. `ended_at_notifications`
3. `events`
4. `tasks`
5. `api_requests`

### 关键动作字段

| 模块     | 新增时要填写什么                                                                                                                                     |
| -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| 通知     | `tenant_id`, `account_id`, `type`, `status`, `subject`, `content`, `meta_data`                                                                       |
| 事件     | `tenant_id`, `account_id`, `type`, `payload`                                                                                                         |
| 异步任务 | `tenant_id`, `type`, `status`, `parameters`, `result`, `started_at`, `completed_at`                                                                  |
| API 审计 | `app_id`, `tenant_id`, `api_key_id`, `type`, `path`, `request_headers`, `request_body`, `response_status`, `response_headers`, `response_body`, `ip` |

### 报价拆分项

1. 通知中心
2. 审计日志
3. 异步任务看板
4. API 调用追踪

---

## 12. 给老板报价时的模块拆单建议

建议直接按下面 12 个包报价：

| 报价包            | 包含内容                                    |
| ----------------- | ------------------------------------------- |
| 1. 账号与工作区   | 登录、注册、成员、邀请、权限                |
| 2. 套餐与配额     | 套餐、订阅、限额、引导步骤                  |
| 3. 应用基础       | App CRUD、安装、发布、站点                  |
| 4. 应用配置中心   | 模型、Prompt、Agent、文件、语音、多模态     |
| 5. 知识库基础     | Dataset、权限、外部知识库                   |
| 6. 文档处理链路   | 上传、导入、解析、切片、索引、归档          |
| 7. 检索与命中调试 | Hit Testing、查询日志、知识库应用绑定       |
| 8. 会话与消息     | 会话、消息、反馈、附件、标注、Agent 思维链  |
| 9. 工作流         | 工作流画布、发布、运行、节点执行            |
| 10. 模型提供商    | Provider、ProviderModel、默认模型、负载均衡 |
| 11. 插件系统      | 插件市场、安装、Endpoint、Runtime           |
| 12. 运维审计      | 通知、事件、任务、API 审计                  |

---

## 13. 下一步最值得继续补的内容

如果要做到“研发拿文档就能直接干”，下一轮建议继续补这 4 份：

1. **每个模块接口清单版**：URL、Method、权限、入参、出参
2. **每个 JSON 字段结构版**：如 `retrieval_model`、`agent_mode`、`file_upload_config`
3. **页面原型动作版**：每个页面支持哪些按钮、每个按钮写哪个表
4. **报价 WBS 版**：把 12 个报价包继续拆成人天级工作项
