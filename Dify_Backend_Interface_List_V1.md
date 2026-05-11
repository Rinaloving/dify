# Dify 后端接口清单（Console 核心模块版）

> 基于 `api/controllers/console` 当前代码整理。  
> 原则：**当前控制器代码优先**，历史 SQL 仅用于补充表结构，不作为接口真相。

---

## 1. 权限标记说明

| 标记 | 含义 |
| --- | --- |
| `setup_required` | 系统已完成初始化 |
| `login_required` | 必须登录后台账号 |
| `account_initialization_required` | 当前账号已完成资料初始化/加入工作区 |
| `edit_permission_required` | 具备应用/知识库编辑权限 |
| `is_admin_or_owner_required` | 工作区管理员或 Owner |
| `plugin_permission_required(install_required=True)` | 允许安装/升级/卸载插件 |
| `plugin_permission_required(debug_required=True)` | 允许插件调试 |
| `get_app_model(...)` | 必须能访问该 App，且 App mode 匹配 |

---

## 2. 模块范围

本版分两层：

1. **详细接口表**：报价和开发最核心的模块。
2. **补充模块索引**：其余控制器按模块归档，便于下一轮继续扩写。

详细接口表已覆盖：

1. App
2. App Model Config / Site
3. Conversation / Message
4. Workflow / Workflow Run
5. Dataset / Document / Metadata
6. Workspace Model Provider
7. Workspace Plugin

---

## 3. App 基础模块

### 3.1 App 基础 CRUD

| URL | Method | 权限 | 主要入参 | 主要出参 | 主要落表 |
| --- | --- | --- | --- | --- | --- |
| `/apps` | GET | `setup_required` + `login_required` + `account_initialization_required` | `page` `limit` `mode` `name` `tag_ids` `is_created_by_me` | App 分页列表 | 读 `apps` `app_model_configs` `workflows` `tag_bindings` |
| `/apps` | POST | 上述 + `edit_permission_required` | `name` `description` `mode` `icon_type` `icon` `icon_background` | 新建 App 详情 | 写 `apps` `app_model_configs`，部分模式会初始化 `workflows` `sites` |
| `/apps/<app_id>` | GET | 上述 + `get_app_model(mode=None)` | Path `app_id` | App 详情 | 读 `apps` `app_model_configs` `sites` `workflows` |
| `/apps/<app_id>` | PUT | 上述 + `get_app_model(mode=None)` + `edit_permission_required` | `name` `description` `icon_type` `icon` `icon_background` `use_icon_as_answer_icon` `max_active_requests` | 更新后 App 详情 | 写 `apps` |
| `/apps/<app_id>` | DELETE | 上述 + `get_app_model` + `edit_permission_required` | Path `app_id` | `{"result":"success"}` | 删/软删 `apps`，并清理关联 `app_model_configs` `sites` `workflows` 等 |
| `/apps/<app_id>/copy` | POST | 上述 + `get_app_model(mode=None)` + `edit_permission_required` | `name` `description` `icon_type` `icon` `icon_background` | 复制后的 App | 写新 `apps`，复制 `app_model_configs`/工作流/站点配置 |
| `/apps/<app_id>/export` | GET | 上述 + `get_app_model` + `edit_permission_required` | `include_secret` `workflow_id` | DSL / 导出文件流 | 读 `apps` `app_model_configs` `workflows` |
| `/apps/<app_id>/name` | POST | 上述 + `get_app_model(mode=None)` + `edit_permission_required` | `name` | 名称校验结果 | 读 `apps` |
| `/apps/<app_id>/icon` | POST | 上述 + `get_app_model(mode=None)` + `edit_permission_required` | `icon` `icon_background` | 更新后 App | 写 `apps` |
| `/apps/<app_id>/site-enable` | POST | 上述 + `get_app_model(mode=None)` + `edit_permission_required` | `enable_site` | 更新后 App | 写 `apps.enable_site`，联动 `sites` |
| `/apps/<app_id>/api-enable` | POST | `setup_required` + `login_required` + `is_admin_or_owner_required` + `account_initialization_required` + `get_app_model(mode=None)` | `enable_api` | 更新后 App | 写 `apps.enable_api` |
| `/apps/<app_id>/trace` | GET | `setup_required` + `login_required` + `account_initialization_required` | Path `app_id` | trace 配置 | 读 trace 配置对象 |
| `/apps/<app_id>/trace` | POST | 上述 + `edit_permission_required` | `enabled` `tracing_provider` | `{"result":"success"}` | 写 trace 配置对象 |

### 3.2 App Model Config

| URL | Method | 权限 | 主要入参 | 主要出参 | 主要落表 |
| --- | --- | --- | --- | --- | --- |
| `/apps/<app_id>/model-config` | POST | `setup_required` + `login_required` + `edit_permission_required` + `account_initialization_required` + `get_app_model(mode=[agent-chat,chat,completion])` | `provider` `model` `configs` `opening_statement` `suggested_questions` `more_like_this` `speech_to_text` `text_to_speech` `retrieval_model` `tools` `dataset_configs` `agent_mode` | `{"result":"success"}` | 新写一条 `app_model_configs`，再回写 `apps.app_model_config_id` |

### 3.3 App Site

| URL | Method | 权限 | 主要入参 | 主要出参 | 主要落表 |
| --- | --- | --- | --- | --- | --- |
| `/apps/<app_id>/site` | POST | `setup_required` + `login_required` + `edit_permission_required` + `account_initialization_required` + `get_app_model` | `title` `icon_type` `icon` `icon_background` `description` `default_language` `chat_color_theme` `chat_color_theme_inverted` `customize_domain` `copyright` `privacy_policy` `custom_disclaimer` `customize_token_strategy` `prompt_public` `show_workflow_steps` `use_icon_as_answer_icon` | Site 配置详情 | 写 `sites` |
| `/apps/<app_id>/site/access-token-reset` | POST | `setup_required` + `login_required` + `is_admin_or_owner_required` + `account_initialization_required` + `get_app_model` | Path `app_id` | 重置后的 Site 配置 | 写 `sites.code` |

---

## 4. Conversation / Message 模块

### 4.1 Conversation

| URL | Method | 权限 | 主要入参 | 主要出参 | 主要落表 |
| --- | --- | --- | --- | --- | --- |
| `/apps/<app_id>/completion-conversations` | GET | `setup_required` + `login_required` + `account_initialization_required` + `get_app_model(mode=completion)` + `edit_permission_required` | `keyword` `start` `end` `annotation_status` `page` `limit` | Completion 会话分页 | 读 `conversations` `messages` `message_annotations` |
| `/apps/<app_id>/completion-conversations/<conversation_id>` | GET | 同上 | Path `conversation_id` | 单个会话详情 | 读 `conversations` `messages` |
| `/apps/<app_id>/completion-conversations/<conversation_id>` | DELETE | 同上 | Path `conversation_id` | `{"result":"success"}` | 写 `conversations.is_deleted` / 删除会话关联 |
| `/apps/<app_id>/chat-conversations` | GET | `setup_required` + `login_required` + `account_initialization_required` + `get_app_model(mode=[chat,agent-chat,advanced-chat])` + `edit_permission_required` | `keyword` `start` `end` `annotation_status` `page` `limit` `sort_by` | Chat 会话分页 | 读 `conversations` `messages` `message_feedbacks` |
| `/apps/<app_id>/chat-conversations/<conversation_id>` | GET | 同上 | Path `conversation_id` | 会话详情 | 读 `conversations` `messages` |
| `/apps/<app_id>/chat-conversations/<conversation_id>` | DELETE | 同上 | Path `conversation_id` | `{"result":"success"}` | 写 `conversations.is_deleted` |
| `/apps/<app_id>/conversation-variables` | GET | `setup_required` + `login_required` + `account_initialization_required` + `get_app_model(mode=advanced-chat)` | `conversation_id` | 当前会话变量列表 | 读 `conversation_variables` |

### 4.2 Message / Feedback / Annotation

| URL | Method | 权限 | 主要入参 | 主要出参 | 主要落表 |
| --- | --- | --- | --- | --- | --- |
| `/apps/<app_id>/chat-messages` | GET | `login_required` + `account_initialization_required` + `setup_required` + `get_app_model(mode=[chat,agent-chat,advanced-chat])` + `edit_permission_required` | `conversation_id` `first_id` `limit` | 消息无限滚动列表 | 读 `messages` `message_files` `message_feedbacks` `message_annotations` |
| `/apps/<app_id>/messages/<message_id>` | GET | `setup_required` + `login_required` + `get_app_model` + `edit_permission_required` | Path `message_id` | 消息详情（含 thought / files / feedback） | 读 `messages` `message_files` `message_feedbacks` `message_annotations` |
| `/apps/<app_id>/feedbacks` | POST | `setup_required` + `login_required` | `message_id` `rating` `content` | 反馈结果 | 写 `message_feedbacks` |
| `/apps/<app_id>/feedbacks/export` | GET | `setup_required` + `login_required` | `from_source` `rating` `has_comment` `start_date` `end_date` `format` | CSV / JSON 导出 | 读 `message_feedbacks` |
| `/apps/<app_id>/annotations/count` | GET | `setup_required` + `login_required` | 无 | 标注数量 | 读 `message_annotations` |
| `/apps/<app_id>/chat-messages/<message_id>/suggested-questions` | GET | `setup_required` + `login_required` | Path `message_id` | 建议追问列表 | 读消息配置、运行结果 |

---

## 5. Workflow 模块

### 5.1 Draft Workflow

| URL | Method | 权限 | 主要入参 | 主要出参 | 主要落表 |
| --- | --- | --- | --- | --- | --- |
| `/apps/<app_id>/workflows/draft` | GET | `setup_required` + `login_required` + `account_initialization_required` + `get_app_model(mode=[advanced-chat,workflow])` + `edit_permission_required` | Path `app_id` | Draft workflow | 读 `workflows` |
| `/apps/<app_id>/workflows/draft` | POST | 同上 | `graph` `features` `hash` `environment_variables[]` `conversation_variables[]` | `result` `hash` `updated_at` | 写 `workflows.graph` `workflows.features` 及变量对象 |
| `/apps/<app_id>/workflows/draft/run` | POST | `setup_required` + `login_required` + `account_initialization_required` + `get_app_model(mode=[workflow])` | `inputs` `files[]` | 调试执行结果 | 写 `workflow_runs` `workflow_node_executions` |
| `/apps/<app_id>/advanced-chat/workflows/draft/run` | POST | `setup_required` + `login_required` + `account_initialization_required` + `get_app_model(mode=[advanced-chat])` | `inputs` `query` `conversation_id` `parent_message_id` `files[]` | 调试执行结果 | 写 `workflow_runs`，并联动 `messages` `conversations` |
| `/apps/<app_id>/workflows/draft/nodes/<node_id>/run` | POST | 同上 | `inputs` `query` `files[]` | 单节点执行结果 | 写 `workflow_node_executions` |
| `/apps/<app_id>/workflows/draft/nodes/<node_id>/last-run` | GET | 同上 | Path `node_id` | 节点最后一次运行结果 | 读 `workflow_node_executions` |
| `/apps/<app_id>/workflows/draft/iteration/nodes/<node_id>/run` | POST | 同上 | `inputs` | 迭代节点调试结果 | 写 `workflow_node_executions` |
| `/apps/<app_id>/workflows/draft/loop/nodes/<node_id>/run` | POST | 同上 | `inputs` | 循环节点调试结果 | 写 `workflow_node_executions` |
| `/apps/<app_id>/workflows/draft/human-input/nodes/<node_id>/form/preview` | POST | 同上 | 当前上下文输入 | 表单预览数据 | 读 workflow graph |
| `/apps/<app_id>/workflows/draft/human-input/nodes/<node_id>/form/run` | POST | 同上 | 表单输入内容 | 人工输入节点执行结果 | 写 `workflow_node_executions` |
| `/apps/<app_id>/workflows/draft/human-input/nodes/<node_id>/delivery-test` | POST | 同上 | 测试参数 | 测试结果 | 不固定，偏调试 |
| `/apps/<app_id>/workflows/draft/trigger/run` | POST | 同上 | `node_id` | Trigger 调试结果 | 写 `workflow_runs` |
| `/apps/<app_id>/workflows/draft/nodes/<node_id>/trigger/run` | POST | 同上 | Path `node_id` | 单 Trigger 调试结果 | 写 `workflow_runs` |
| `/apps/<app_id>/workflows/draft/trigger/run-all` | POST | 同上 | `node_ids[]` | 批量 Trigger 调试结果 | 写 `workflow_runs` |
| `/apps/<app_id>/workflows/publish` | POST | 同上 | `marked_name` `marked_comment` | 发布后的 workflow | 写 `workflows` 版本状态 |
| `/apps/<app_id>/workflows` | GET | 同上 | `page` `limit` `user_id` `named_only` | workflow 历史版本分页 | 读 `workflows` |
| `/apps/<app_id>/workflows/<workflow_id>` | GET | 同上 | Path `workflow_id` | workflow 详情 | 读 `workflows` |
| `/apps/<app_id>/workflows/<workflow_id>` | PATCH | 同上 | `marked_name` `marked_comment` | 更新后 workflow | 写 `workflows` |
| `/apps/<app_id>/workflows/<workflow_id>/restore` | POST | 同上 | Path `workflow_id` | 恢复结果 | 写 draft workflow |
| `/apps/<app_id>/convert-to-workflow` | POST | 同上 | `name` `icon_type` `icon` `icon_background` | 转换后的 app/workflow | 写 `apps` `workflows` |
| `/apps/<app_id>/workflows/default-workflow-block-configs` | GET | 同上 | `q` | block 配置列表 | 读默认配置 |
| `/apps/<app_id>/workflows/default-workflow-block-configs/<block_type>` | GET | 同上 | `block_type` | 某 block 默认配置 | 读默认配置 |
| `/apps/<app_id>/workflow-runs/tasks/<task_id>/stop` | POST | 同上 | Path `task_id` | 停止结果 | 写运行状态 |

### 5.2 Workflow Run

| URL | Method | 权限 | 主要入参 | 主要出参 | 主要落表 |
| --- | --- | --- | --- | --- | --- |
| `/apps/<app_id>/advanced-chat/workflow-runs` | GET | `setup_required` + `login_required` + `account_initialization_required` + `get_app_model(mode=[advanced-chat])` | `last_id` `limit` `status` `triggered_from` | 高级对话 workflow run 列表 | 读 `workflow_runs` |
| `/apps/<app_id>/advanced-chat/workflow-runs/count` | GET | 同上 | `status` `time_range` `triggered_from` | run 计数 | 读 `workflow_runs` |
| `/apps/<app_id>/workflow-runs` | GET | `setup_required` + `login_required` + `account_initialization_required` + `get_app_model(mode=[advanced-chat,workflow])` | `last_id` `limit` `status` `triggered_from` | run 列表 | 读 `workflow_runs` |
| `/apps/<app_id>/workflow-runs/count` | GET | 同上 | `status` `time_range` `triggered_from` | run 计数 | 读 `workflow_runs` |
| `/apps/<app_id>/workflow-runs/<run_id>` | GET | 同上 | Path `run_id` | run 详情 | 读 `workflow_runs` |
| `/apps/<app_id>/workflow-runs/<run_id>/node-executions` | GET | 同上 | `last_id` `limit` | 节点执行列表 | 读 `workflow_node_executions` |
| `/apps/<app_id>/workflow-runs/<run_id>/export` | GET | `setup_required` + `login_required` + `account_initialization_required` + `get_app_model()` | Path `run_id` | 导出下载 URL | 读 `workflow_archive_logs` / 归档文件 |
| `/workflow/<workflow_run_id>/pause-details` | GET | `setup_required` + `login_required` + `account_initialization_required` | Path `workflow_run_id` | 暂停节点、人工输入入口 | 读 `workflow_runs` / pause context |

---

## 6. Dataset 模块

### 6.1 Dataset 基础

| URL | Method | 权限 | 主要入参 | 主要出参 | 主要落表 |
| --- | --- | --- | --- | --- | --- |
| `/datasets` | GET | `setup_required` + `login_required` + `account_initialization_required` | `page` `limit` `keyword` `include_all` `ids[]` `tag_ids[]` | Dataset 分页列表 | 读 `datasets` `tag_bindings` |
| `/datasets` | POST | 同上 | `name` `description` `indexing_technique` `permission` `provider` `external_knowledge_api_id` `external_knowledge_id` | 新建 Dataset | 写 `datasets` |
| `/datasets/<dataset_id>` | GET | 同上 | Path `dataset_id` | Dataset 详情 | 读 `datasets` `dataset_permissions` `dataset_metadata` |
| `/datasets/<dataset_id>` | PATCH | 同上 | `name` `description` `permission` `indexing_technique` `embedding_model` `embedding_model_provider` `retrieval_model` `summary_index_setting` `partial_member_list` `external_retrieval_model` `external_knowledge_id` `external_knowledge_api_id` `icon_info` `is_multimodal` | 更新后 Dataset | 写 `datasets` `dataset_permissions` 外部绑定对象 |
| `/datasets/<dataset_id>` | DELETE | 同上 | Path `dataset_id` | `{"result":"success"}` | 删/禁用 `datasets`，清理 `documents` `document_segments` 权限等 |
| `/datasets/<dataset_id>/use-check` | GET | 同上 | Path `dataset_id` | 是否被 App 使用 | 读 `app_dataset_joins` |
| `/datasets/<dataset_id>/queries` | GET | 同上 | 分页/过滤参数 | 查询命中记录 | 读 `dataset_queries` |
| `/datasets/indexing-estimate` | POST | 同上 | `info_list` `process_rule` `indexing_technique` `doc_form` `dataset_id` `doc_language` | 索引预估 | 不落库或仅临时估算 |
| `/datasets/<dataset_id>/related-apps` | GET | 同上 | Path `dataset_id` | 关联 App 列表 | 读 `app_dataset_joins` `apps` |
| `/datasets/<dataset_id>/indexing-status` | GET | 同上 | Path `dataset_id` | 当前索引状态汇总 | 读 `documents` |
| `/datasets/api-keys` | GET | 同上 | 无 | API key 列表 | 读 `api_tokens` |
| `/datasets/api-keys` | POST | `setup_required` + `login_required` + `is_admin_or_owner_required` + `account_initialization_required` | dataset / token 描述等 | 新 API key | 写 `api_tokens` |
| `/datasets/api-keys/<api_key_id>` | DELETE | 同上 | Path `api_key_id` | 删除结果 | 写 `api_tokens` |
| `/datasets/<dataset_id>/api-keys/<status>` | POST | `setup_required` + `login_required` + `account_initialization_required` | Path `status` | 启停结果 | 写 `api_tokens.enabled` |
| `/datasets/api-base-info` | GET | 同上 | 无 | Dataset API base info | 只读配置 |
| `/datasets/retrieval-setting` | GET | 同上 | 无 | 当前向量库支持的检索模式 | 只读配置 |
| `/datasets/retrieval-setting/<vector_type>` | GET | 同上 | `vector_type` | 指定向量库支持的检索模式 | 只读配置 |
| `/datasets/<dataset_id>/error-docs` | GET | 同上 | Path `dataset_id` | 异常文档列表 | 读 `documents` |
| `/datasets/<dataset_id>/permission-part-users` | GET | 同上 | Path `dataset_id` | 部分成员权限用户列表 | 读 `dataset_permissions` |
| `/datasets/<dataset_id>/auto-disable-logs` | GET | 同上 | Path `dataset_id` | 自动停用日志 | 读禁用日志对象 |

### 6.2 Document / Import / Indexing

| URL | Method | 权限 | 主要入参 | 主要出参 | 主要落表 |
| --- | --- | --- | --- | --- | --- |
| `/datasets/process-rule` | GET | `setup_required` + `login_required` + `account_initialization_required` | `document_id` | 当前切片规则 | 读 `dataset_process_rules` |
| `/datasets/<dataset_id>/documents` | GET | 同上 | `page` `limit` `keyword` `sort` `fetch` `status` | 文档分页列表 | 读 `documents` |
| `/datasets/<dataset_id>/documents` | POST | 同上 | `KnowledgeConfig`（文件、data_source、process_rule、索引方式等） | 新文档列表 | 写 `documents` `upload_files` `dataset_process_rules` `document_segments` |
| `/datasets/<dataset_id>/documents` | DELETE | 同上 | 批量文档参数 | 批量删除结果 | 删 `documents` `document_segments` |
| `/datasets/init` | POST | 同上 | 创建 Dataset + 文档初始化参数 | Dataset + documents | 写 `datasets` `documents` |
| `/datasets/<dataset_id>/documents/<document_id>` | GET | 同上 | Path | 文档详情 | 读 `documents` `document_segments` |
| `/datasets/<dataset_id>/documents/<document_id>` | DELETE | 同上 | Path | 删除结果 | 删 `documents` `document_segments` |
| `/datasets/<dataset_id>/documents/<document_id>/indexing-estimate` | GET | 同上 | Path | 单文档索引预估 | 估算 |
| `/datasets/<dataset_id>/batch/<batch>/indexing-estimate` | GET | 同上 | `batch` | 批次索引预估 | 估算 |
| `/datasets/<dataset_id>/batch/<batch>/indexing-status` | GET | 同上 | `batch` | 批次索引状态 | 读 `documents` |
| `/datasets/<dataset_id>/documents/<document_id>/indexing-status` | GET | 同上 | Path | 文档索引状态 | 读 `documents` |
| `/datasets/<dataset_id>/documents/<document_id>/download` | GET | 同上 | Path | 单文档下载流/URL | 读 `upload_files` |
| `/datasets/<dataset_id>/documents/download-zip` | POST | 同上 | `document_ids[]` | ZIP 下载流 | 读 `documents` `upload_files` |
| `/datasets/<dataset_id>/documents/<document_id>/processing/<action>` | PATCH | 同上 | `action=pause/resume` | 处理状态结果 | 写 `documents.is_paused` / 状态 |
| `/datasets/<dataset_id>/documents/<document_id>/metadata` | PUT | 同上 | metadata 键值 | 更新后文档 | 写 `documents.doc_metadata` / bindings |
| `/datasets/<dataset_id>/documents/status/<action>/batch` | PATCH | 同上 | 文档 ID 列表 + `action=enable/disable/archive/un_archive` | 批量状态结果 | 写 `documents.enabled` `documents.archived` |
| `/datasets/<dataset_id>/documents/<document_id>/processing/pause` | PATCH | 同上 | Path | 暂停结果 | 写 `documents` |
| `/datasets/<dataset_id>/documents/<document_id>/processing/resume` | PATCH | 同上 | Path | 恢复结果 | 写 `documents` |
| `/datasets/<dataset_id>/retry` | POST | 同上 | `document_ids[]` | 重试结果 | 重新触发索引任务 |
| `/datasets/<dataset_id>/documents/<document_id>/rename` | POST | 同上 | `name` | 更新后文档 | 写 `documents.name` |
| `/datasets/<dataset_id>/documents/<document_id>/website-sync` | GET | 同上 | Path | 网站同步信息 | 读网站源配置 |
| `/datasets/<dataset_id>/documents/<document_id>/pipeline-execution-log` | GET | 同上 | Path | pipeline 执行日志 | 读 pipeline log |
| `/datasets/<dataset_id>/documents/generate-summary` | POST | 同上 | `document_list[]` | 任务触发结果 | 写/触发摘要任务 |
| `/datasets/<dataset_id>/documents/<document_id>/summary-status` | GET | 同上 | Path | 摘要生成状态 | 读摘要状态 |

### 6.3 Dataset Metadata

| URL | Method | 权限 | 主要入参 | 主要出参 | 主要落表 |
| --- | --- | --- | --- | --- | --- |
| `/datasets/<dataset_id>/metadata` | GET | `setup_required` + `login_required` + `account_initialization_required` | Path | 元数据字段列表 | 读 `dataset_metadata` |
| `/datasets/<dataset_id>/metadata` | POST | 同上 | `name` `type` | 新元数据字段 | 写 `dataset_metadata` |
| `/datasets/<dataset_id>/metadata/<metadata_id>` | PATCH | 同上 | 字段更新参数 | 更新结果 | 写 `dataset_metadata` |
| `/datasets/<dataset_id>/metadata/<metadata_id>` | DELETE | 同上 | Path | 删除结果 | 删 `dataset_metadata` / binding |
| `/datasets/metadata/built-in` | GET | 同上 | 无 | 内置字段列表 | 只读 |
| `/datasets/<dataset_id>/metadata/built-in/<action>` | POST | 同上 | `action=enable/disable` | 启停结果 | 写 `datasets.built_in_field_enabled` |
| `/datasets/<dataset_id>/documents/metadata` | POST | 同上 | 批量文档元数据修改 | 批量更新结果 | 写 `documents.doc_metadata` / binding |

---

## 7. Workspace Model Provider 模块

| URL | Method | 权限 | 主要入参 | 主要出参 | 主要落表 |
| --- | --- | --- | --- | --- | --- |
| `/workspaces/current/model-providers` | GET | `setup_required` + `login_required` + `account_initialization_required` | `model_type` | provider 列表 | 读 `providers` `provider_models` |
| `/workspaces/current/model-providers/<provider>/credentials` | GET | 同上 | `credential_id` | 某 provider 当前或指定凭证 | 读 provider credential 表 |
| `/workspaces/current/model-providers/<provider>/credentials` | POST | `setup_required` + `login_required` + `is_admin_or_owner_required` + `account_initialization_required` | `credentials{}` `name` | 创建结果 | 写 provider credential 表 |
| `/workspaces/current/model-providers/<provider>/credentials` | PUT | 同上 | `credential_id` `credentials{}` `name` | 更新结果 | 写 provider credential 表 |
| `/workspaces/current/model-providers/<provider>/credentials` | DELETE | 同上 | `credential_id` | 删除结果 | 删 provider credential 表 |
| `/workspaces/current/model-providers/<provider>/credentials/switch` | POST | 同上 | `credential_id` | 切换成功 | 写激活凭证状态 |
| `/workspaces/current/model-providers/<provider>/credentials/validate` | POST | `setup_required` + `login_required` + `account_initialization_required` | `credentials{}` | `success/error` | 只校验，不必落库 |
| `/workspaces/<tenant_id>/model-providers/<provider>/<icon_type>/<lang>` | GET | 无后台权限装饰 | Path | provider 图标文件流 | 只读静态资产 |
| `/workspaces/current/model-providers/<provider>/preferred-provider-type` | POST | `setup_required` + `login_required` + `is_admin_or_owner_required` + `account_initialization_required` | `preferred_provider_type=system/custom` | 切换结果 | 写偏好 provider 类型表 |
| `/workspaces/current/model-providers/<provider>/checkout-url` | GET | `setup_required` + `login_required` + `account_initialization_required` | Path | 支付/开通链接 | 只读 |

---

## 8. Workspace Plugin 模块

| URL | Method | 权限 | 主要入参 | 主要出参 | 主要落表 |
| --- | --- | --- | --- | --- | --- |
| `/workspaces/current/plugin/debugging-key` | GET | `setup_required` + `login_required` + `account_initialization_required` + `plugin_permission_required(debug_required=True)` | 无 | 调试 key / host / port | 读插件调试配置 |
| `/workspaces/current/plugin/list` | GET | `setup_required` + `login_required` + `account_initialization_required` | `page` `page_size` | 插件列表 | 读插件安装信息 |
| `/workspaces/current/plugin/list/latest-versions` | POST | 同上 | `plugin_ids[]` | 最新版本字典 | 读 marketplace / registry |
| `/workspaces/current/plugin/list/installations/ids` | POST | 同上 | `plugin_ids[]` | 安装实例列表 | 读安装记录 |
| `/workspaces/current/plugin/icon` | GET | `setup_required` | `tenant_id` `filename` | 图标流 | 读插件资产 |
| `/workspaces/current/plugin/asset` | GET | `setup_required` + `login_required` + `account_initialization_required` | `plugin_unique_identifier` `file_name` | 二进制资产 | 读插件资产 |
| `/workspaces/current/plugin/upload/pkg` | POST | `setup_required` + `login_required` + `account_initialization_required` + `plugin_permission_required(install_required=True)` | multipart `pkg` | 上传解析结果 | 写安装任务/临时包 |
| `/workspaces/current/plugin/upload/github` | POST | 同上 | `repo` `version` `package` | 上传解析结果 | 写安装任务 |
| `/workspaces/current/plugin/upload/bundle` | POST | 同上 | multipart `bundle` | 上传解析结果 | 写安装任务 |
| `/workspaces/current/plugin/install/pkg` | POST | 同上 | `plugin_unique_identifiers[]` | 安装任务结果 | 写 `plugin_installations` `install_tasks` |
| `/workspaces/current/plugin/install/github` | POST | 同上 | `plugin_unique_identifier` `repo` `version` `package` | 安装结果 | 写 `plugin_installations` |
| `/workspaces/current/plugin/install/marketplace` | POST | 同上 | `plugin_unique_identifiers[]` | 安装结果 | 写 `plugin_installations` |
| `/workspaces/current/plugin/marketplace/pkg` | GET | 同上 | `plugin_unique_identifier` | marketplace manifest | 只读 |
| `/workspaces/current/plugin/fetch-manifest` | GET | 同上 | `plugin_unique_identifier` | manifest | 只读 |
| `/workspaces/current/plugin/tasks` | GET | 同上 | `page` `page_size` | 安装任务列表 | 读 `install_tasks` |
| `/workspaces/current/plugin/tasks/<task_id>` | GET | 同上 | Path | 单任务详情 | 读 `install_tasks` |
| `/workspaces/current/plugin/tasks/<task_id>/delete` | POST | 同上 | Path | 删除任务结果 | 写 `install_tasks` |
| `/workspaces/current/plugin/tasks/delete_all` | POST | 同上 | 无 | 清空任务结果 | 写 `install_tasks` |
| `/workspaces/current/plugin/tasks/<task_id>/delete/<identifier>` | POST | 同上 | Path | 删除单任务项结果 | 写 `install_tasks` |
| `/workspaces/current/plugin/upgrade/marketplace` | POST | 同上 | `original_plugin_unique_identifier` `new_plugin_unique_identifier` | 升级结果 | 写 `plugin_installations` |
| `/workspaces/current/plugin/upgrade/github` | POST | 同上 | `original_plugin_unique_identifier` `new_plugin_unique_identifier` `repo` `version` `package` | 升级结果 | 写 `plugin_installations` |
| `/workspaces/current/plugin/uninstall` | POST | 同上 | `plugin_installation_id` | 卸载结果 | 写/删 `plugin_installations` |
| `/workspaces/current/plugin/permission/change` | POST | `setup_required` + `login_required` + `account_initialization_required` | `install_permission` `debug_permission` | 权限设置结果 | 写 `tenant_plugin_permissions` |
| `/workspaces/current/plugin/permission/fetch` | GET | `setup_required` + `login_required` + `account_initialization_required` | 无 | 当前权限设置 | 读 `tenant_plugin_permissions` |
| `/workspaces/current/plugin/parameters/dynamic-options` | GET | `setup_required` + `login_required` + `is_admin_or_owner_required` + `account_initialization_required` | `plugin_id` `provider` `action` `parameter` `credential_id` `provider_type` | 动态选项数组 | 只读 / 远程调取 |
| `/workspaces/current/plugin/parameters/dynamic-options-with-credentials` | POST | 同上 | `plugin_id` `provider` `action` `parameter` `credential_id` `credentials{}` | 动态选项数组 | 不一定落库 |
| `/workspaces/current/plugin/preferences/change` | POST | `setup_required` + `login_required` + `account_initialization_required` | `permission{}` `auto_upgrade{strategy_setting,upgrade_time_of_day,upgrade_mode,exclude_plugins,include_plugins}` | `{"success":true}` | 写 `tenant_plugin_permissions` `tenant_plugin_auto_upgrade_strategies` |
| `/workspaces/current/plugin/preferences/fetch` | GET | `setup_required` + `login_required` + `account_initialization_required` | 无 | 当前偏好设置 | 读插件权限与自动升级策略表 |
| `/workspaces/current/plugin/preferences/autoupgrade/exclude` | POST | `setup_required` + `login_required` + `account_initialization_required` | `plugin_id` | 排除结果 | 写自动升级排除列表 |
| `/workspaces/current/plugin/readme` | GET | `setup_required` + `login_required` + `account_initialization_required` | `plugin_unique_identifier` `language` | README 内容 | 读插件 README |

---

## 9. 补充模块索引（未逐条展开但已盘点）

### 9.1 Auth / Bootstrap

主要控制器：

1. `auth/login.py`
2. `auth/forgot_password.py`
3. `auth/email_register.py`
4. `auth/activate.py`
5. `auth/oauth.py`
6. `auth/oauth_server.py`
7. `auth/data_source_oauth.py`
8. `auth/data_source_bearer_auth.py`
9. `setup.py`
10. `init_validate.py`

主要路由族：

1. `/login` `/logout` `/refresh-token`
2. `/forgot-password*` `/reset-password*`
3. `/email-register*`
4. `/activate*`
5. `/oauth/login/<provider>` `/oauth/authorize/<provider>`
6. `/oauth/provider/*`
7. `/oauth/data-source/*`
8. `/api-key-auth/data-source/*`
9. `/setup` `/init`

### 9.2 Workspace 其它模块

主要控制器：

1. `workspace/workspace.py`
2. `workspace/members.py`
3. `workspace/tool_providers.py`
4. `workspace/trigger_providers.py`
5. `workspace/endpoint.py`
6. `workspace/agent_providers.py`
7. `workspace/load_balancing_config.py`

主要路由族：

1. `/workspaces` `/workspaces/current` `/workspaces/switch`
2. `/workspaces/current/members*`
3. `/workspaces/current/tool-providers*`
4. `/workspaces/current/triggers*`
5. `/workspaces/current/endpoints*`
6. `/workspaces/current/agent-providers*`
7. `/workspaces/current/model-providers/*/models/load-balancing-configs/*`

### 9.3 Explore / Marketplace Runtime

主要控制器：

1. `explore/banner.py`
2. `explore/installed_app.py`
3. `explore/recommended_app.py`
4. `explore/completion.py`
5. `explore/conversation.py`
6. `explore/message.py`
7. `explore/workflow.py`
8. `explore/saved_message.py`
9. `explore/parameter.py`
10. `explore/audio.py`

主要路由族：

1. `/explore/banners`
2. `/explore/apps*`
3. `/installed-apps*`
4. `/conversations*`
5. `/messages*`
6. `/saved-messages*`
7. `/audio-to-text` `/text-to-audio`

### 9.4 Admin / Notification / Utility

1. `admin.py`：探索区 App/Banner 管理。
2. `notification.py`：通知中心读取/忽略。
3. `feature.py`：功能开关。
4. `spec.py`：schema definition。
5. `ping.py` `version.py`：健康检查/版本。
6. `remote_files.py`：远程文件代理。
7. `human_input_form.py`：人工输入表单运行时。

