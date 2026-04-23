# Dify 后端 JSON 字段结构清单（当前代码版）

> 用途：让开发直接知道复杂 JSON 字段怎么存、怎么回、默认值是什么。  
> 原则：以 `api/models`、`api/fields`、控制器 payload 为真相。

---

## 1. Dataset 模块

### 1.1 `datasets.retrieval_model`

**来源**

1. `api/fields/dataset_fields.py`
2. `api/models/dataset.py`

**结构**

```json
{
  "search_method": "semantic_search | keyword_search | full_text_search | hybrid_search",
  "reranking_enable": false,
  "reranking_mode": "reranking_model | weighted_score",
  "reranking_model": {
    "reranking_provider_name": "",
    "reranking_model_name": ""
  },
  "weights": {
    "weight_type": "customized",
    "keyword_setting": {
      "keyword_weight": 0.3
    },
    "vector_setting": {
      "vector_weight": 0.7,
      "embedding_model_name": "text-embedding-3-large",
      "embedding_provider_name": "openai"
    }
  },
  "top_k": 2,
  "score_threshold_enabled": false,
  "score_threshold": 0.0
}
```

**默认值**

```json
{
  "search_method": "semantic_search",
  "reranking_enable": false,
  "reranking_model": {
    "reranking_provider_name": "",
    "reranking_model_name": ""
  },
  "top_k": 2,
  "score_threshold_enabled": false
}
```

**说明**

1. `weights` 只在加权模式下有意义。
2. `reranking_model` 只有 `reranking_enable=true` 时需要完整填写。
3. `score_threshold` 只有 `score_threshold_enabled=true` 时生效。

### 1.2 `datasets.summary_index_setting`

**结构**

```json
{
  "enable": true,
  "model_name": "gpt-4.1-mini",
  "model_provider_name": "openai",
  "summary_prompt": "请总结文档重点..."
}
```

**说明**

1. `enable=false` 时后面三个字段可为空。
2. 开启后会触发摘要任务，与文档 `need_summary` / 摘要状态联动。

### 1.3 `datasets.external_retrieval_model`

**结构**

```json
{
  "top_k": 2,
  "score_threshold": 0.0,
  "score_threshold_enabled": false
}
```

**默认值**

```json
{
  "top_k": 2,
  "score_threshold": 0.0
}
```

### 1.4 `datasets.icon_info`

**结构**

```json
{
  "icon_type": "emoji | image | icon",
  "icon": "📚 或文件 key",
  "icon_background": "#EFF1F5",
  "icon_url": "签名 URL"
}
```

**说明**

1. `icon_url` 多为服务端返回字段，不是前端保存时必填。
2. `image` 场景下 `icon` 一般是文件存储 key。

### 1.5 `dataset_process_rules.rules`

**来源**

1. `api/models/dataset.py`
2. `api/controllers/console/datasets/datasets_document.py`

**自动规则结构**

```json
{
  "pre_processing_rules": [
    {
      "id": "remove_extra_spaces",
      "enabled": true
    },
    {
      "id": "remove_urls_emails",
      "enabled": false
    }
  ],
  "segmentation": {
    "delimiter": "\n",
    "max_tokens": 500,
    "chunk_overlap": 50
  }
}
```

**说明**

1. `mode` 常见值：`automatic` `custom` `hierarchical`。
2. 前端“分段规则”“预处理规则”页，最终都落这里。

### 1.6 `documents.data_source_info`

**上传文件**

```json
{
  "upload_file_id": "uuid"
}
```

**Notion / 网站**

```json
{
  "workspace_name": "xxx",
  "page_id": "xxx",
  "url": "https://..."
}
```

**说明**

1. `data_source_type` 决定该 JSON 的解释方式。
2. 渲染详情时，服务端会用它反查 `upload_files`。

### 1.7 `documents.doc_metadata`

**结构**

```json
{
  "source": "website",
  "department": "技术部",
  "version": "v1.2",
  "publish_date": "1717411200"
}
```

**说明**

1. 动态 key，key 集合由 `dataset_metadata` 定义。
2. 内置字段不一定直接保存在这里，也可能由服务端拼装。

---

## 2. App Model Config 模块

### 2.1 `app_model_configs` 总对象

**来源**

1. `api/models/model.py -> AppModelConfigDict`
2. `api/fields/app_fields.py -> model_config_fields`
3. `api/controllers/console/app/model_config.py`

**完整结构**

```json
{
  "opening_statement": "欢迎语",
  "suggested_questions": ["问题1", "问题2"],
  "suggested_questions_after_answer": {
    "enabled": false
  },
  "speech_to_text": {
    "enabled": false
  },
  "text_to_speech": {
    "enabled": false
  },
  "retriever_resource": {
    "enabled": false
  },
  "annotation_reply": {
    "enabled": false
  },
  "more_like_this": {
    "enabled": false
  },
  "sensitive_word_avoidance": {
    "enabled": false,
    "type": "keywords",
    "config": {}
  },
  "external_data_tools": [],
  "model": {
    "provider": "openai",
    "name": "gpt-4.1-mini",
    "mode": "chat",
    "completion_params": {}
  },
  "user_input_form": [],
  "dataset_query_variable": null,
  "pre_prompt": "系统提示词",
  "agent_mode": {
    "enabled": false,
    "strategy": null,
    "tools": [],
    "prompt": null
  },
  "prompt_type": "simple",
  "chat_prompt_config": {},
  "completion_prompt_config": {},
  "dataset_configs": {
    "retrieval_model": "multiple"
  },
  "file_upload": {
    "image": {
      "enabled": false,
      "number_limits": 3,
      "detail": "high",
      "transfer_methods": ["remote_url", "local_file"]
    }
  }
}
```

### 2.2 `suggested_questions_after_answer`

```json
{
  "enabled": true
}
```

### 2.3 `speech_to_text`

```json
{
  "enabled": true
}
```

### 2.4 `text_to_speech`

> `api/models/model.py` 的 TypedDict 默认写法较简化；`api/core/app/app_config/entities.py` 里有扩展形态。

**常见形态**

```json
{
  "enabled": true,
  "voice": "alloy",
  "language": "en"
}
```

### 2.5 `agent_mode`

**结构**

```json
{
  "enabled": true,
  "strategy": "function_call | react | plan_and_execute",
  "tools": [
    {
      "provider_type": "builtin | api | workflow | mcp",
      "provider_id": "google",
      "tool_name": "search",
      "tool_parameters": {
        "api_key": "******",
        "safe_search": "off"
      },
      "plugin_unique_identifier": "optional",
      "credential_id": "optional"
    }
  ],
  "prompt": "Agent 补充提示词"
}
```

**说明**

1. `tool_parameters` 中的密钥字段会被服务端加密后存储。
2. 编辑时如果前端传的是掩码值，服务端会尝试回填原值后再重新加密。

### 2.6 `dataset_configs`

**结构**

```json
{
  "retrieval_model": "single | multiple",
  "datasets": {
    "dataset_ids": ["uuid1", "uuid2"]
  },
  "top_k": 5,
  "score_threshold": 0.5,
  "score_threshold_enabled": true,
  "reranking_model": {
    "reranking_provider_name": "cohere",
    "reranking_model_name": "rerank-v3.5"
  },
  "weights": {
    "weight_type": "customized",
    "keyword_setting": {
      "keyword_weight": 0.3
    },
    "vector_setting": {
      "vector_weight": 0.7,
      "embedding_model_name": "text-embedding-3-large",
      "embedding_provider_name": "openai"
    }
  },
  "reranking_enabled": true,
  "reranking_mode": "reranking_model",
  "metadata_filtering_mode": "disabled | automatic | manual",
  "metadata_model_config": null,
  "metadata_filtering_conditions": null
}
```

**默认值**

```json
{
  "retrieval_model": "multiple"
}
```

### 2.7 `file_upload`

**默认结构**

```json
{
  "image": {
    "enabled": false,
    "number_limits": 3,
    "detail": "high",
    "transfer_methods": ["remote_url", "local_file"]
  }
}
```

**说明**

1. 这个结构直接决定聊天输入区是否允许传图。
2. `transfer_methods` 常见值：`remote_url` `local_file`。

### 2.8 `chat_prompt_config`

```json
{
  "prompt": [
    {
      "text": "你是一个助手",
      "role": "system"
    },
    {
      "text": "{{query}}",
      "role": "user"
    }
  ]
}
```

### 2.9 `completion_prompt_config`

```json
{
  "prompt": {
    "text": "请根据以下输入生成内容：{{input}}"
  },
  "conversation_histories_role": {
    "user_prefix": "Human",
    "assistant_prefix": "Assistant"
  }
}
```

---

## 3. Workflow 模块

### 3.1 Draft Sync Payload

**来源**

1. `api/controllers/console/app/workflow.py`
2. `api/fields/workflow_fields.py`

**结构**

```json
{
  "graph": {
    "nodes": [],
    "edges": []
  },
  "features": {
    "opening_statement": "",
    "suggested_questions": [],
    "file_upload": {},
    "speech_to_text": {},
    "text_to_speech": {}
  },
  "hash": "workflow-content-hash",
  "environment_variables": [
    {
      "id": "uuid",
      "name": "API_KEY",
      "value": "******",
      "value_type": "secret",
      "description": "外部 API Key"
    }
  ],
  "conversation_variables": [
    {
      "id": "uuid",
      "name": "city",
      "value_type": "string",
      "value": "Beijing",
      "description": "会话变量"
    }
  ]
}
```

### 3.2 `workflow.features`

**说明**

1. `features` 不是固定单一结构，会承载文件上传、欢迎语、推荐问题、语音能力等应用级附加能力。
2. 在 Workflow App 下，它承担了“流程图之外的 UI 配置”。

### 3.3 `workflow.environment_variables`

**结构**

```json
{
  "id": "uuid",
  "name": "BASE_URL",
  "value": "https://api.example.com",
  "value_type": "string | number | secret",
  "description": "环境变量说明"
}
```

### 3.4 `workflow.rag_pipeline_variables`

**结构**

```json
{
  "label": "文件",
  "variable": "file",
  "type": "file",
  "belong_to_node_id": "node_1",
  "max_length": 10,
  "required": true,
  "unit": "",
  "default_value": null,
  "options": [],
  "placeholder": "请上传文件",
  "tooltips": "仅支持 pdf/docx",
  "allowed_file_types": ["document"],
  "allow_file_extension": [".pdf", ".docx"],
  "allow_file_upload_methods": ["local_file", "remote_url"]
}
```

### 3.5 Workflow Run 调试 Payload

**普通 Workflow**

```json
{
  "inputs": {
    "topic": "AI"
  },
  "files": []
}
```

**Advanced Chat Workflow**

```json
{
  "inputs": {
    "language": "zh-CN"
  },
  "query": "帮我总结这份资料",
  "conversation_id": "optional",
  "parent_message_id": "optional",
  "files": []
}
```

---

## 4. Provider / Plugin 模块

### 4.1 Provider Credential Payload

**创建**

```json
{
  "credentials": {
    "api_key": "sk-xxx",
    "base_url": "https://api.openai.com/v1"
  },
  "name": "生产环境"
}
```

**更新**

```json
{
  "credential_id": "uuid",
  "credentials": {
    "api_key": "sk-xxx"
  },
  "name": "生产环境-主账号"
}
```

**切换**

```json
{
  "credential_id": "uuid"
}
```

### 4.2 Plugin 权限配置

```json
{
  "install_permission": "everyone | admin_only",
  "debug_permission": "everyone | admin_only"
}
```

### 4.3 Plugin 自动升级配置

```json
{
  "strategy_setting": "fix_only | latest",
  "upgrade_time_of_day": 0,
  "upgrade_mode": "exclude | include",
  "exclude_plugins": ["plugin-a", "plugin-b"],
  "include_plugins": []
}
```

### 4.4 Plugin 偏好总对象

```json
{
  "permission": {
    "install_permission": "everyone",
    "debug_permission": "everyone"
  },
  "auto_upgrade": {
    "strategy_setting": "fix_only",
    "upgrade_time_of_day": 0,
    "upgrade_mode": "exclude",
    "exclude_plugins": [],
    "include_plugins": []
  }
}
```

### 4.5 Plugin 动态选项请求

```json
{
  "plugin_id": "plugin-id",
  "provider": "notion",
  "action": "list_pages",
  "parameter": "page_id",
  "credential_id": "optional",
  "provider_type": "tool | trigger"
}
```

### 4.6 Plugin 动态选项（带凭证）

```json
{
  "plugin_id": "plugin-id",
  "provider": "notion",
  "action": "list_pages",
  "parameter": "page_id",
  "credential_id": "uuid",
  "credentials": {
    "access_token": "******"
  }
}
```

---

## 5. Message / Conversation 结构

### 5.1 `conversations.inputs`

```json
{
  "query_language": "zh-CN",
  "attachments": [
    {
      "dify_model_identity": "__dify__file__",
      "id": "file-id",
      "name": "test.pdf"
    }
  ]
}
```

### 5.2 `messages.inputs`

与 `conversations.inputs` 同形态，运行时会把文件映射转换成 `File` 对象。

### 5.3 `messages.message_metadata`

```json
{
  "usage": {
    "prompt_tokens": 123,
    "completion_tokens": 456
  },
  "retriever_resources": [],
  "tool_calls": []
}
```

> 该字段是动态对象，强依赖运行时返回；前端渲染时应允许未知 key。

