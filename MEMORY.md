# User Memories

## 开发习惯
- **不要自动提交 Gitee** — 改完代码让用户自己验证，确认没问题后用户自己提交

## RAG / Weaviate 开发经验
- Weaviate 批量插入：properties 不能有 Schema 外的字段（Id/CreatedAt/UpdatedAt），否则静默返回 FAILED
- C# float 序列化：跨系统必须用 `CultureInfo.InvariantCulture`，中文环境用逗号做小数分隔符
- Weaviate GraphQL：不支持 `... on ClassName` inline fragment，直接写字段名
- Weaviate GraphQL：属性名大小写敏感，不要用 ToSnakeCase
- JsonElement 反序列化：直接用 `.Deserialize<T>()`，不要手动转 Dictionary
- 永远不要写空的 catch 块，至少记录日志
- HTTP 200 ≠ 业务成功，要检查返回体中的业务状态码
- GraphQL 查询必须包含 `_additional { id }`，否则对象 ID 为空
- DashScope Embedding 批量限制 10 条（不是 20）
- DashScope Rerank API 不走兼容模式，用 `/api/v1/services/rerank/text-reranking/text-reranking`
- PostgreSQL UTF-8 不接受空字节（0x00），用 SanitizeText() 清理
- SSE 回调参数顺序必须与函数签名严格一致，新增可选参数放最后
- Parent 块必须带零向量（vectorizer=none 时），否则插入静默失败
- 调用方参数必须与被调用方对齐，特别是布尔开关如 parentChildEnabled
- 空壳方法必须验证返回值，不能只编译通过就认为正确
- UI 默认展示重要信息（来源引用等），不能藏起来
- GraphQL 查询必须包含 `_additional { id }`，否则对象 ID 为空
- DashScope Embedding 批量限制 10 条（不是 20）
- DashScope Rerank API 不走兼容模式，用 `/api/v1/services/rerank/text-reranking/text-reranking`
- PostgreSQL UTF-8 不接受空字节（0x00），用 SanitizeText() 清理
- SSE 回调参数顺序必须与函数签名严格一致，新增可选参数放最后
- Parent 块必须带零向量（vectorizer=none 时），否则插入静默失败
- 调用方参数必须与被调用方对齐，特别是布尔开关如 parentChildEnabled
- 空壳方法必须验证返回值，不能只编译通过就认为正确
- UI 默认展示重要信息（来源引用等），不能藏起来

- 项目周任务管理 (XrProjectWeekTask) 相关文件： 1. api-1772175404085-23wgqu.ts - API 接口定义文件，包含 XrProjectWeekTask 的 CRUD 操作（getList, getInfo, create, update, del, batchDelete, getDetail），API 前缀为 '/api/rb/XrProjectWeekTask' 2. columnList-1772175404108-ea49no.ts - 列表列配置，包含 14 个字段：项目 id(下拉选择，必填)、指派员工 (用户选择，必填)、任务内容 (文本域，必填)、开始日期 (日期选择，必填)、结束日期 (日期选择，必填)、任务状态 (单选：已完成/进行中，必填)、…

## Workflow Engine Development Experience
- JNPF Service namespace: use JNPF.DependencyInjection (not JNPF.Dependency) for ITransient
- JNPF pagination: use ToPagedListAsync + PageResult<T>.SqlSugarPageResult(data) pattern, NOT manual RefAsync<int> + PageResult construction
- PowerShell Set-Content -Encoding UTF8 corrupts Chinese characters - use write tool instead
- Vue Flow (@vue-flow/core) is the chosen canvas library for workflow editor
- npm install may need --legacy-peer-deps in JNPF projects due to pinia peer dependency conflict
- JNPF routes are database-configured, not in code - menu entries must be added via admin panel
- Workflow engine 7-phase plan: Phase 1 (CRUD) ✅, Phase 2 (Canvas) ✅, Phase 3 (Variables), Phase 4 (Execution Engine), Phase 5 (Config UI), Phase 6 (Debug), Phase 7 (Templates)

## JNPF Frontend Import Rules
- **createMessage**: use import { useMessage } from '/@/hooks/web/useMessage' + const { createMessage } = useMessage();
- Do NOT use import { createMessage } from '/@/utils/web/tnfy' — file does not exist
