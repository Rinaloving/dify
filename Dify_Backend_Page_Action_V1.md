# Dify 页面原型动作清单（按钮 / 动作 / 落表版）

> 用途：把后台页面按“原型动作”写清楚。  
> 目标：开发看到后，能直接知道每个页面有哪些按钮、按钮调什么接口、最终写哪些表。

---

## 1. App 页面

### 1.1 应用列表页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 新建应用 | 弹窗填写名称、模式、描述、图标后创建 | `POST /apps` | `apps` `app_model_configs`，部分模式初始化 `workflows`/`sites` |
| 搜索应用 | 按名称筛选 | `GET /apps` | 只读 |
| 按模式筛选 | Chat / Agent / Workflow / Completion | `GET /apps` | 只读 |
| 复制应用 | 复制当前应用配置为新应用 | `POST /apps/<app_id>/copy` | 新写一份 `apps` + 复制 `app_model_configs`/`workflows` |
| 导出 DSL | 下载应用 DSL | `GET /apps/<app_id>/export` | 只读 |
| 删除应用 | 删除当前应用 | `DELETE /apps/<app_id>` | `apps` 及其关联对象 |

### 1.2 应用基础设置页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 保存基本信息 | 修改名称、描述、图标、答案头像、并发数 | `PUT /apps/<app_id>` | `apps` |
| 校验名称 | 保存前检查重名 | `POST /apps/<app_id>/name` | 只读 `apps` |
| 更新图标 | 单独改图标/背景 | `POST /apps/<app_id>/icon` | `apps.icon` `apps.icon_background` |
| 启用 WebApp | 开关应用站点 | `POST /apps/<app_id>/site-enable` | `apps.enable_site` |
| 启用 API | 开关应用 API | `POST /apps/<app_id>/api-enable` | `apps.enable_api` |
| 开启链路追踪 | 开关 trace provider | `POST /apps/<app_id>/trace` | trace 配置对象 |

### 1.3 模型配置页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 保存模型配置 | 模型、提示词、欢迎语、推荐问题、检索、Agent 工具等一键保存 | `POST /apps/<app_id>/model-config` | 新写 `app_model_configs`，回写 `apps.app_model_config_id` |
| 开启语音转文本 | 勾选后保存 | 同上 | `app_model_configs.speech_to_text` |
| 开启文本转语音 | 配置 voice/language 后保存 | 同上 | `app_model_configs.text_to_speech` |
| 配置推荐问题 | 保存推荐问题数组 | 同上 | `app_model_configs.suggested_questions` |
| 开启回答后推荐问题 | 勾选开关 | 同上 | `app_model_configs.suggested_questions_after_answer` |
| 配置 Agent 工具 | 增删工具、设置参数 | 同上 | `app_model_configs.agent_mode` |
| 配置知识库引用 | 绑定 dataset、多知识库检索配置 | 同上 | `app_model_configs.dataset_configs` |
| 配置图片上传 | 允许上传图片、数量限制、传输方式 | 同上 | `app_model_configs.file_upload` |

### 1.4 站点发布页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 保存站点配置 | 标题、描述、域名、主题色、默认语言、版权信息 | `POST /apps/<app_id>/site` | `sites` |
| 重置访问 Token | 重新生成访问码 | `POST /apps/<app_id>/site/access-token-reset` | `sites.code` |

---

## 2. Conversation / Message 页面

### 2.1 会话列表页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 查看 Completion 会话列表 | 按条件查询 completion 会话 | `GET /apps/<app_id>/completion-conversations` | 只读 `conversations` |
| 查看 Chat 会话列表 | 按条件查询 chat 会话 | `GET /apps/<app_id>/chat-conversations` | 只读 `conversations` |
| 按关键字筛选 | 查询会话摘要/问题 | 同上 | 只读 |
| 按时间筛选 | 起止时间过滤 | 同上 | 只读 |
| 按标注状态筛选 | 已标注/未标注 | 同上 | 只读 `message_annotations` |
| 删除会话 | 删除会话及其关联消息展示 | `DELETE /apps/<app_id>/.../<conversation_id>` | `conversations.is_deleted` / 关联对象 |

### 2.2 消息详情页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 查看消息流 | 滚动加载消息 | `GET /apps/<app_id>/chat-messages` | 只读 `messages` |
| 查看消息详情 | 打开单条消息 | `GET /apps/<app_id>/messages/<message_id>` | 只读 `messages` `message_files` `message_feedbacks` `message_annotations` |
| 提交点赞/点踩 | 管理员对消息反馈 | `POST /apps/<app_id>/feedbacks` | `message_feedbacks` |
| 导出反馈 | 导出 CSV/JSON | `GET /apps/<app_id>/feedbacks/export` | 只读 `message_feedbacks` |
| 查看建议追问 | 获取建议问题列表 | `GET /apps/<app_id>/chat-messages/<message_id>/suggested-questions` | 只读运行结果 |

---

## 3. Workflow 页面

### 3.1 Workflow 编辑器页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 加载草稿 | 打开编辑器时拉取最新草稿 | `GET /apps/<app_id>/workflows/draft` | 只读 `workflows` |
| 保存草稿 | 保存 graph/features/变量/hash | `POST /apps/<app_id>/workflows/draft` | `workflows.graph` `workflows.features` 变量对象 |
| 调试整个流程 | 运行当前 draft | `POST /apps/<app_id>/workflows/draft/run` 或 advanced-chat 对应接口 | `workflow_runs` `workflow_node_executions` |
| 调试单节点 | 运行选中节点 | `POST /apps/<app_id>/workflows/draft/nodes/<node_id>/run` | `workflow_node_executions` |
| 查看节点上次结果 | 打开“Last Run”面板 | `GET /apps/<app_id>/workflows/draft/nodes/<node_id>/last-run` | 只读 |
| 调试循环/迭代节点 | 节点级调试 | `POST /.../iteration...` `/loop...` | `workflow_node_executions` |
| 预览人工输入表单 | 打开 form preview | `POST /.../human-input.../preview` | 只读 graph |
| 测试人工输入提交 | 表单 run | `POST /.../human-input.../run` | `workflow_node_executions` |
| 发布 | 输入标记名/注释后发布 | `POST /apps/<app_id>/workflows/publish` | `workflows` 新发布版本 |
| 查看版本历史 | 打开历史面板 | `GET /apps/<app_id>/workflows` | 只读 `workflows` |
| 恢复某版本 | 将历史版本恢复为当前草稿 | `POST /apps/<app_id>/workflows/<workflow_id>/restore` | 重写 draft workflow |
| 转为 Workflow App | 从其它模式转换成 workflow | `POST /apps/<app_id>/convert-to-workflow` | `apps` `workflows` |
| 停止运行任务 | 强制停止当前任务 | `POST /apps/<app_id>/workflow-runs/tasks/<task_id>/stop` | `workflow_runs.status` |

### 3.2 Workflow Run 列表页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 查看 Run 列表 | 分页看调试/正式运行 | `GET /apps/<app_id>/workflow-runs` | 只读 `workflow_runs` |
| 查看 Run 数量 | 状态统计 | `GET /apps/<app_id>/workflow-runs/count` | 只读 `workflow_runs` |
| 查看节点执行 | 展开某次 run 的节点日志 | `GET /apps/<app_id>/workflow-runs/<run_id>/node-executions` | 只读 `workflow_node_executions` |
| 导出归档 | 生成下载 URL | `GET /apps/<app_id>/workflow-runs/<run_id>/export` | 只读归档记录 |
| 查看暂停详情 | 查看人工输入暂停节点 | `GET /workflow/<workflow_run_id>/pause-details` | 只读 pause context |

---

## 4. Dataset 页面

### 4.1 知识库列表页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 新建知识库 | 填名称、描述、权限、索引方式、来源类型 | `POST /datasets` | `datasets` |
| 新建并立即导入 | 创建知识库并初始化文档 | `POST /datasets/init` | `datasets` `documents` `upload_files` |
| 查看列表 | 分页、搜索、按 tag 筛选 | `GET /datasets` | 只读 `datasets` |
| 查看引用检查 | 删除前检查是否被 App 使用 | `GET /datasets/<dataset_id>/use-check` | 只读 `app_dataset_joins` |
| 删除知识库 | 删除整个知识库 | `DELETE /datasets/<dataset_id>` | `datasets` 及其关联对象 |

### 4.2 知识库设置页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 保存基本信息 | 名称、描述、权限、embedding、多模态、图标 | `PATCH /datasets/<dataset_id>` | `datasets` |
| 保存检索配置 | search_method、重排模型、权重、TopK、阈值 | 同上 | `datasets.retrieval_model` |
| 保存摘要索引配置 | 摘要模型和 Prompt | 同上 | `datasets.summary_index_setting` |
| 保存外部知识配置 | 外部知识库绑定/检索阈值 | 同上 | `datasets` 外部绑定对象 |
| 查看关联 App | 查看谁在用当前知识库 | `GET /datasets/<dataset_id>/related-apps` | 只读 `app_dataset_joins` |
| 查看 API Keys | 打开 API key 面板 | `GET /datasets/api-keys` | 只读 `api_tokens` |
| 新增 API Key | 生成新 token | `POST /datasets/api-keys` | `api_tokens` |
| 删除 API Key | 删除 token | `DELETE /datasets/api-keys/<api_key_id>` | `api_tokens` |
| 启停 API Key | 启用/禁用某知识库 token | `POST /datasets/<dataset_id>/api-keys/<status>` | `api_tokens.enabled` |

### 4.3 文档列表页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 获取处理规则 | 打开导入弹窗时加载默认切片规则 | `GET /datasets/process-rule` | 只读 `dataset_process_rules` |
| 导入文档 | 选择文件/Notion/网站并导入 | `POST /datasets/<dataset_id>/documents` | `upload_files` `documents` `dataset_process_rules` `document_segments` |
| 查看文档列表 | 分页、搜索、按状态、按热度排序 | `GET /datasets/<dataset_id>/documents` | 只读 `documents` |
| 批量删除文档 | 多选后删除 | `DELETE /datasets/<dataset_id>/documents` | 删 `documents` `document_segments` |
| 查看单文档 | 打开详情 | `GET /datasets/<dataset_id>/documents/<document_id>` | 只读 `documents` |
| 删除单文档 | 单条删除 | `DELETE /datasets/<dataset_id>/documents/<document_id>` | 删 `documents` `document_segments` |
| 重命名 | 编辑名称 | `POST /datasets/<dataset_id>/documents/<document_id>/rename` | `documents.name` |
| 下载单文档 | 下载原文件 | `GET /datasets/<dataset_id>/documents/<document_id>/download` | 读 `upload_files` |
| 批量打包下载 | 下载 zip | `POST /datasets/<dataset_id>/documents/download-zip` | 只读 |
| 查看索引状态 | 看 parsing/indexing/completed/error | `GET /datasets/<dataset_id>/documents/<document_id>/indexing-status` | 只读 `documents` |
| 查看批次状态 | 看同批次导入状态 | `GET /datasets/<dataset_id>/batch/<batch>/indexing-status` | 只读 `documents` |
| 索引预估 | 预估 token / 耗时 | `GET /.../indexing-estimate` | 估算 |
| 重试失败文档 | 批量重新入队 | `POST /datasets/<dataset_id>/retry` | 重触发任务 |
| 暂停处理 | 暂停解析/索引 | `PATCH /.../processing/pause` | `documents.is_paused` |
| 恢复处理 | 恢复解析/索引 | `PATCH /.../processing/resume` | `documents.is_paused` |
| 批量启用/禁用/归档 | 批量状态操作 | `PATCH /datasets/<dataset_id>/documents/status/<action>/batch` | `documents.enabled` / `documents.archived` |
| 生成摘要 | 批量摘要 | `POST /datasets/<dataset_id>/documents/generate-summary` | 触发摘要任务 |
| 查看摘要状态 | 查看生成进度 | `GET /datasets/<dataset_id>/documents/<document_id>/summary-status` | 只读摘要状态 |
| 查看网站同步状态 | 网站源文档同步结果 | `GET /datasets/<dataset_id>/documents/<document_id>/website-sync` | 只读网站同步信息 |
| 查看 pipeline 执行日志 | 打开日志抽屉 | `GET /datasets/<dataset_id>/documents/<document_id>/pipeline-execution-log` | 只读 pipeline log |

### 4.4 元数据管理页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 查看元数据字段 | 列表页展示字段定义 | `GET /datasets/<dataset_id>/metadata` | 只读 `dataset_metadata` |
| 新增元数据字段 | 填字段名、字段类型 | `POST /datasets/<dataset_id>/metadata` | `dataset_metadata` |
| 编辑元数据字段 | 修改名称/类型 | `PATCH /datasets/<dataset_id>/metadata/<metadata_id>` | `dataset_metadata` |
| 删除元数据字段 | 删除字段定义 | `DELETE /datasets/<dataset_id>/metadata/<metadata_id>` | `dataset_metadata` / binding |
| 查看内置字段 | 展示系统内置 metadata | `GET /datasets/metadata/built-in` | 只读 |
| 启用/禁用内置字段 | 控制 built-in field | `POST /datasets/<dataset_id>/metadata/built-in/<action>` | `datasets.built_in_field_enabled` |
| 批量编辑文档元数据 | 对文档批量赋值 | `POST /datasets/<dataset_id>/documents/metadata` | `documents.doc_metadata` / binding |

---

## 5. Provider / Plugin 页面

### 5.1 模型提供商页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 查看 provider 列表 | 按模型类型查看 | `GET /workspaces/current/model-providers` | 只读 `providers` `provider_models` |
| 查看凭证详情 | 查看当前/指定凭证 | `GET /.../credentials` | 只读 provider credential |
| 新增凭证 | 填 API Key / Base URL / 名称 | `POST /.../credentials` | provider credential 表 |
| 更新凭证 | 修改 credential 内容 | `PUT /.../credentials` | provider credential 表 |
| 删除凭证 | 删除凭证 | `DELETE /.../credentials` | provider credential 表 |
| 切换当前凭证 | 将某 credential 设为当前 | `POST /.../credentials/switch` | 激活状态 |
| 校验凭证 | 保存前点“测试” | `POST /.../credentials/validate` | 不落库 |
| 设置 preferred provider type | system/custom 切换 | `POST /.../preferred-provider-type` | 偏好表 |

### 5.2 插件中心页

| 按钮/动作 | 页面行为 | 调用接口 | 主要落表 |
| --- | --- | --- | --- |
| 查看插件列表 | 分页查看安装插件 | `GET /workspaces/current/plugin/list` | 只读安装表 |
| 查看最新版本 | 批量查询升级 | `POST /.../list/latest-versions` | 只读 |
| 上传本地插件包 | 上传 `.difypkg` | `POST /.../upload/pkg` | 安装任务 |
| 从 GitHub 上传 | 填 repo/version/package | `POST /.../upload/github` | 安装任务 |
| 上传 bundle | 上传 bundle 文件 | `POST /.../upload/bundle` | 安装任务 |
| 本地安装 | 执行安装 | `POST /.../install/pkg` | `plugin_installations` `install_tasks` |
| GitHub 安装 | 执行安装 | `POST /.../install/github` | `plugin_installations` |
| Marketplace 安装 | 执行安装 | `POST /.../install/marketplace` | `plugin_installations` |
| 卸载插件 | 删除安装 | `POST /.../uninstall` | `plugin_installations` |
| 升级插件 | marketplace/github 升级 | `POST /.../upgrade/...` | `plugin_installations` |
| 查看安装任务 | 查看进度队列 | `GET /.../tasks` | 只读 `install_tasks` |
| 删除任务 | 清理任务 | `POST /.../tasks/.../delete` | `install_tasks` |
| 修改插件权限 | 安装权限/调试权限 | `POST /.../permission/change` | `tenant_plugin_permissions` |
| 查看插件权限 | 当前权限配置 | `GET /.../permission/fetch` | 只读 `tenant_plugin_permissions` |
| 修改插件偏好 | 自动升级策略、纳入/排除列表 | `POST /.../preferences/change` | `tenant_plugin_permissions` `tenant_plugin_auto_upgrade_strategies` |
| 查看插件偏好 | 当前偏好设置 | `GET /.../preferences/fetch` | 只读上两张表 |
| 从自动升级排除 | 单插件加入排除列表 | `POST /.../preferences/autoupgrade/exclude` | 自动升级策略表 |
| 动态选项调试 | 拉取参数 options | `GET /.../parameters/dynamic-options` | 不固定，偏远程调取 |
| 带凭证动态选项调试 | 临时 credentials 下获取 options | `POST /.../parameters/dynamic-options-with-credentials` | 不固定 |
| 查看 README | 打开插件说明 | `GET /.../readme` | 只读 README |

