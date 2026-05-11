-- Dify数据库表结构定义 (第一部分)
-- 包含基础表和用户相关表

-- 设置客户端编码和标准字符串
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- 扩展和自定义类型定义
--

-- pg_stat_statements扩展 - 用于跟踪SQL语句的规划和执行统计信息
CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';

-- 向量扩展 - 用于向量运算的数据类型
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;
COMMENT ON EXTENSION vector IS 'data type for vector operations';

-- 嵌入向量域定义
CREATE DOMAIN public.embedding AS public.vector
	CONSTRAINT embedding_dims_check CHECK ((public.vec_dims(VALUE) <= 10000))
	CONSTRAINT embedding_not_null_check CHECK (VALUE IS NOT NULL);

ALTER DOMAIN public.embedding OWNER TO root;

-- 枚举类型定义
CREATE TYPE public.account_status AS ENUM (
    'active',   -- 活跃
    'pending',  -- 待定
    'banned'    -- 禁用
);

ALTER TYPE public.account_status OWNER TO root;

CREATE TYPE public.code_based_app_type AS ENUM (
    'workflow', -- 工作流
    'agent'     -- 智能体
);

ALTER TYPE public.code_based_app_type OWNER TO root;

CREATE TYPE public.dataset_document_indexing_status AS ENUM (
    'waiting',    -- 等待
    'parsing',    -- 解析中
    'cleaning',   -- 清洗中
    'splitting',  -- 分割中
    'indexing',   -- 索引中
    'completed',  -- 完成
    'error',      -- 错误
    'paused'      -- 暂停
);

ALTER TYPE public.dataset_document_indexing_status OWNER TO root;

CREATE TYPE public.dataset_document_status AS ENUM (
    'uploading',  -- 上传中
    'uploaded',   -- 已上传
    'available',  -- 可用
    'enabled',    -- 已启用
    'disabled',   -- 已禁用
    'error',      -- 错误
    'deleted'     -- 已删除
);

ALTER TYPE public.dataset_document_status OWNER TO root;

CREATE TYPE public.dataset_status AS ENUM (
    'setup',    -- 设置中
    'indexing', -- 索引中
    'normal',   -- 正常
    'archived'  -- 归档
);

ALTER TYPE public.dataset_status OWNER TO root;

CREATE TYPE public.dataset_type AS ENUM (
    'normal',    -- 普通
    'retrieval'  -- 检索
);

ALTER TYPE public.dataset_type OWNER TO root;

CREATE TYPE public.file_type AS ENUM (
    'image',      -- 图片
    'audio',      -- 音频
    'video',      -- 视频
    'document',   -- 文档
    'spreadsheet',-- 表格
    'code',       -- 代码
    'text',       -- 文本
    'html',       -- HTML
    'xml',        -- XML
    'json',       -- JSON
    'csv',        -- CSV
    'other'       -- 其他
);

ALTER TYPE public.file_type OWNER TO root;

CREATE TYPE public.notification_status AS ENUM (
    'unread', -- 未读
    'read'    -- 已读
);

ALTER TYPE public.notification_status OWNER TO root;

CREATE TYPE public.notification_type AS ENUM (
    'info',     -- 信息
    'success',  -- 成功
    'warning',  -- 警告
    'error'     -- 错误
);

ALTER TYPE public.notification_type OWNER TO root;

CREATE TYPE public.plan_type AS ENUM (
    'basic',        -- 基础版
    'pro',          -- 专业版
    'team',         -- 团队版
    'enterprise'    -- 企业版
);

ALTER TYPE public.plan_type OWNER TO root;

CREATE TYPE public.site_access_mode AS ENUM (
    'invite_only',  -- 仅邀请
    'public'        -- 公开
);

ALTER TYPE public.site_access_mode OWNER TO root;

CREATE TYPE public.site_status AS ENUM (
    'normal',       -- 正常
    'maintenance'   -- 维护中
);

ALTER TYPE public.site_status OWNER TO root;

CREATE TYPE public.task_status AS ENUM (
    'running',  -- 运行中
    'success',  -- 成功
    'failed'    -- 失败
);

ALTER TYPE public.task_status OWNER TO root;

CREATE TYPE public.tenant_account_role AS ENUM (
    'owner',    -- 所有者
    'admin',    -- 管理员
    'member'    -- 成员
);

ALTER TYPE public.tenant_account_role OWNER TO root;

CREATE TYPE public.workflow_node_execution_status AS ENUM (
    'running',      -- 运行中
    'succeeded',    -- 成功
    'failed'        -- 失败
);

ALTER TYPE public.workflow_node_execution_status OWNER TO root;

CREATE TYPE public.workflow_run_status AS ENUM (
    'running',      -- 运行中
    'succeeded',    -- 成功
    'failed',       -- 失败
    'stopped'       -- 已停止
);

ALTER TYPE public.workflow_run_status OWNER TO root;

CREATE TYPE public.workflow_type AS ENUM (
    'advanced-byob',    -- 高级BYOB
    'simple'            -- 简单
);

ALTER TYPE public.workflow_type OWNER TO root;

SET default_tablespace = '';
SET default_table_access_method = heap;

--
-- 账户表 - 存储用户账户信息
--
CREATE TABLE public.accounts (
    id uuid NOT NULL,                                           -- 账户唯一标识符
    name character varying(255) NOT NULL,                       -- 用户姓名
    email character varying(255) NOT NULL,                      -- 用户邮箱
    password character varying(255),                            -- 密码（加密存储）
    avatar character varying(255),                              -- 头像URL
    interface_language character varying(255),                  -- 界面语言
    interface_theme character varying(255),                     -- 界面主题
    timezone character varying(255),                            -- 时区
    last_login_at timestamp with time zone,                     -- 最后登录时间
    last_login_ip inet,                                         -- 最后登录IP地址
    status public.account_status DEFAULT 'active'::public.account_status NOT NULL, -- 账户状态
    initialized_at timestamp with time zone,                    -- 初始化时间
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    password_updated_at timestamp with time zone,               -- 密码更新时间
    provider character varying(16) DEFAULT 'dify'::character varying NOT NULL, -- 认证提供商
    provider_account_id character varying(255),                 -- 认证提供商账户ID
    invite_from_account_id uuid,                                -- 邀请人账户ID
    email_validated boolean DEFAULT false NOT NULL              -- 邮箱是否已验证
);

COMMENT ON TABLE public.accounts IS '账户表 - 存储用户账户信息';
COMMENT ON COLUMN public.accounts.id IS '账户唯一标识符';
COMMENT ON COLUMN public.accounts.name IS '用户姓名';
COMMENT ON COLUMN public.accounts.email IS '用户邮箱';
COMMENT ON COLUMN public.accounts.password IS '密码（加密存储）';
COMMENT ON COLUMN public.accounts.avatar IS '头像URL';
COMMENT ON COLUMN public.accounts.interface_language IS '界面语言';
COMMENT ON COLUMN public.accounts.interface_theme IS '界面主题';
COMMENT ON COLUMN public.accounts.timezone IS '时区';
COMMENT ON COLUMN public.accounts.last_login_at IS '最后登录时间';
COMMENT ON COLUMN public.accounts.last_login_ip IS '最后登录IP地址';
COMMENT ON COLUMN public.accounts.status IS '账户状态';
COMMENT ON COLUMN public.accounts.initialized_at IS '初始化时间';
COMMENT ON COLUMN public.accounts.created_at IS '创建时间';
COMMENT ON COLUMN public.accounts.updated_at IS '更新时间';
COMMENT ON COLUMN public.accounts.password_updated_at IS '密码更新时间';
COMMENT ON COLUMN public.accounts.provider IS '认证提供商';
COMMENT ON COLUMN public.accounts.provider_account_id IS '认证提供商账户ID';
COMMENT ON COLUMN public.accounts.invite_from_account_id IS '邀请人账户ID';
COMMENT ON COLUMN public.accounts.email_validated IS '邮箱是否已验证';

--
-- API请求记录表 - 存储API调用历史
--
CREATE TABLE public.api_requests (
    id uuid NOT NULL,                                           -- 请求记录唯一标识符
    app_id uuid,                                                -- 应用ID
    tenant_id uuid NOT NULL,                                    -- 租户ID
    api_key_id uuid,                                            -- API密钥ID
    type character varying(16) NOT NULL,                        -- 请求类型
    path character varying(255) NOT NULL,                       -- 请求路径
    request_headers jsonb,                                      -- 请求头
    request_body jsonb,                                         -- 请求体
    response_status integer NOT NULL,                           -- 响应状态码
    response_headers jsonb,                                     -- 响应头
    response_body jsonb,                                        -- 响应体
    ip inet NOT NULL,                                           -- 客户端IP地址
    country character varying(16),                              -- 国家
    region character varying(64),                               -- 地区
    city character varying(64),                                 -- 城市
    latitude double precision,                                  -- 纬度
    longitude double precision,                                 -- 经度
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.api_requests IS 'API请求记录表 - 存储API调用历史';
COMMENT ON COLUMN public.api_requests.id IS '请求记录唯一标识符';
COMMENT ON COLUMN public.api_requests.app_id IS '应用ID';
COMMENT ON COLUMN public.api_requests.tenant_id IS '租户ID';
COMMENT ON COLUMN public.api_requests.api_key_id IS 'API密钥ID';
COMMENT ON COLUMN public.api_requests.type IS '请求类型';
COMMENT ON COLUMN public.api_requests.path IS '请求路径';
COMMENT ON COLUMN public.api_requests.request_headers IS '请求头';
COMMENT ON COLUMN public.api_requests.request_body IS '请求体';
COMMENT ON COLUMN public.api_requests.response_status IS '响应状态码';
COMMENT ON COLUMN public.api_requests.response_headers IS '响应头';
COMMENT ON COLUMN public.api_requests.response_body IS '响应体';
COMMENT ON COLUMN public.api_requests.ip IS '客户端IP地址';
COMMENT ON COLUMN public.api_requests.country IS '国家';
COMMENT ON COLUMN public.api_requests.region IS '地区';
COMMENT ON COLUMN public.api_requests.city IS '城市';
COMMENT ON COLUMN public.api_requests.latitude IS '纬度';
COMMENT ON COLUMN public.api_requests.longitude IS '经度';
COMMENT ON COLUMN public.api_requests.created_at IS '创建时间';
COMMENT ON COLUMN public.api_requests.updated_at IS '更新时间';

--
-- 应用注释表 - 存储应用相关的注释信息
--
CREATE TABLE public.app_annotations (
    id uuid NOT NULL,                                           -- 注释唯一标识符
    app_id uuid NOT NULL,                                       -- 应用ID
    question character varying(2048) NOT NULL,                  -- 问题内容
    content text NOT NULL,                                      -- 注释内容
    hit_count integer DEFAULT 0 NOT NULL,                       -- 命中次数
    created_by uuid NOT NULL,                                   -- 创建者ID
    updated_by uuid,                                            -- 更新者ID
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.app_annotations IS '应用注释表 - 存储应用相关的注释信息';
COMMENT ON COLUMN public.app_annotations.id IS '注释唯一标识符';
COMMENT ON COLUMN public.app_annotations.app_id IS '应用ID';
COMMENT ON COLUMN public.app_annotations.question IS '问题内容';
COMMENT ON COLUMN public.app_annotations.content IS '注释内容';
COMMENT ON COLUMN public.app_annotations.hit_count IS '命中次数';
COMMENT ON COLUMN public.app_annotations.created_by IS '创建者ID';
COMMENT ON COLUMN public.app_annotations.updated_by IS '更新者ID';
COMMENT ON COLUMN public.app_annotations.created_at IS '创建时间';
COMMENT ON COLUMN public.app_annotations.updated_at IS '更新时间';

--
-- 应用注释设置表 - 存储应用注释的相关配置
--
CREATE TABLE public.app_annotation_settings (
    id uuid NOT NULL,                                           -- 设置唯一标识符
    app_id uuid NOT NULL,                                       -- 应用ID
    score_threshold double precision DEFAULT 0.9 NOT NULL,      -- 分数阈值
    retrival_score_threshold double precision DEFAULT 0.0 NOT NULL, -- 检索分数阈值
    annotation_reply_setting character varying(16) DEFAULT 'substitute'::character varying NOT NULL, -- 注释回复设置
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.app_annotation_settings IS '应用注释设置表 - 存储应用注释的相关配置';
COMMENT ON COLUMN public.app_annotation_settings.id IS '设置唯一标识符';
COMMENT ON COLUMN public.app_annotation_settings.app_id IS '应用ID';
COMMENT ON COLUMN public.app_annotation_settings.score_threshold IS '分数阈值';
COMMENT ON COLUMN public.app_annotation_settings.retrival_score_threshold IS '检索分数阈值';
COMMENT ON COLUMN public.app_annotation_settings.annotation_reply_setting IS '注释回复设置';
COMMENT ON COLUMN public.app_annotation_settings.created_at IS '创建时间';
COMMENT ON COLUMN public.app_annotation_settings.updated_at IS '更新时间';

--
-- 应用模型配置表 - 存储应用的模型配置信息
--
CREATE TABLE public.app_model_configs (
    id uuid NOT NULL,                                           -- 配置唯一标识符
    app_id uuid NOT NULL,                                       -- 应用ID
    provider character varying(255) NOT NULL,                   -- 模型提供商
    model_id character varying(255) NOT NULL,                   -- 模型ID
    configs jsonb DEFAULT '{}'::jsonb NOT NULL,                 -- 配置信息
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    opening_statement text,                                     -- 开场白
    suggested_questions jsonb,                                  -- 建议问题
    suggested_questions_after_answer jsonb,                     -- 回答后的建议问题
    more_like_this jsonb,                                       -- 更多类似
    model jsonb,                                                -- 模型配置
    user_input_form jsonb,                                      -- 用户输入表单
    pre_prompt text,                                            -- 预提示
    agent_mode jsonb,                                           -- 智能体模式
    retriever_resource jsonb,                                   -- 检索资源
    prompt_type character varying(255) DEFAULT 'simple'::character varying, -- 提示类型
    llm_top_k integer DEFAULT 1,                                -- LLM Top K
    llm_score_threshold double precision DEFAULT 0.0,           -- LLM分数阈值
    external_data_tools jsonb,                                  -- 外部数据工具
    data_sources jsonb,                                         -- 数据源
    model_dict jsonb,                                           -- 模型字典
    strategy character varying(255) DEFAULT 'default'::character varying, -- 策略
    retriever_from character varying(255) DEFAULT 'dataset'::character varying, -- 检索来源
    vision jsonb,                                               -- 视觉配置
    image_file_ids jsonb,                                       -- 图片文件ID
    image_file_number_limit integer,                            -- 图片文件数量限制
    image_file_size_limit integer,                              -- 图片文件大小限制
    image_formats jsonb,                                        -- 图片格式
    image_quality character varying(255) DEFAULT 'high'::character varying, -- 图片质量
    image_detail character varying(255) DEFAULT 'auto'::character varying, -- 图片细节
    image_transfer_methods jsonb,                               -- 图片传输方法
    citation jsonb,                                             -- 引用
    speech_to_text jsonb,                                       -- 语音转文本
    retriever_change_prompt jsonb,                              -- 检索变更提示
    sensitive_word_avoidance jsonb,                             -- 敏感词规避
    text_to_speech jsonb,                                       -- 文本转语音
    annotation_reply jsonb,                                     -- 注释回复
    agent_config jsonb,                                         -- 智能体配置
    dataset_configs jsonb,                                      -- 数据集配置
    file_upload jsonb,                                          -- 文件上传
    code_interpreter_tools jsonb,                               -- 代码解释器工具
    workflow jsonb,                                             -- 工作流
    memory jsonb,                                               -- 记忆
    text_to_image jsonb,                                        -- 文本转图片
    tool_icons jsonb,                                           -- 工具图标
    file_reader jsonb,                                          -- 文件阅读器
    rerank_config jsonb,                                        -- 重排序配置
    moderation_config jsonb,                                    -- 内容审核配置
    file_upload_config jsonb                                    -- 文件上传配置
);

COMMENT ON TABLE public.app_model_configs IS '应用模型配置表 - 存储应用的模型配置信息';
COMMENT ON COLUMN public.app_model_configs.id IS '配置唯一标识符';
COMMENT ON COLUMN public.app_model_configs.app_id IS '应用ID';
COMMENT ON COLUMN public.app_model_configs.provider IS '模型提供商';
COMMENT ON COLUMN public.app_model_configs.model_id IS '模型ID';
COMMENT ON COLUMN public.app_model_configs.configs IS '配置信息';
COMMENT ON COLUMN public.app_model_configs.created_at IS '创建时间';
COMMENT ON COLUMN public.app_model_configs.updated_at IS '更新时间';
COMMENT ON COLUMN public.app_model_configs.opening_statement IS '开场白';
COMMENT ON COLUMN public.app_model_configs.suggested_questions IS '建议问题';
COMMENT ON COLUMN public.app_model_configs.suggested_questions_after_answer IS '回答后的建议问题';
COMMENT ON COLUMN public.app_model_configs.more_like_this IS '更多类似';
COMMENT ON COLUMN public.app_model_configs.model IS '模型配置';
COMMENT ON COLUMN public.app_model_configs.user_input_form IS '用户输入表单';
COMMENT ON COLUMN public.app_model_configs.pre_prompt IS '预提示';
COMMENT ON COLUMN public.app_model_configs.agent_mode IS '智能体模式';
COMMENT ON COLUMN public.app_model_configs.retriever_resource IS '检索资源';
COMMENT ON COLUMN public.app_model_configs.prompt_type IS '提示类型';
COMMENT ON COLUMN public.app_model_configs.llm_top_k IS 'LLM Top K';
COMMENT ON COLUMN public.app_model_configs.llm_score_threshold IS 'LLM分数阈值';
COMMENT ON COLUMN public.app_model_configs.external_data_tools IS '外部数据工具';
COMMENT ON COLUMN public.app_model_configs.data_sources IS '数据源';
COMMENT ON COLUMN public.app_model_configs.model_dict IS '模型字典';
COMMENT ON COLUMN public.app_model_configs.strategy IS '策略';
COMMENT ON COLUMN public.app_model_configs.retriever_from IS '检索来源';
COMMENT ON COLUMN public.app_model_configs.vision IS '视觉配置';
COMMENT ON COLUMN public.app_model_configs.image_file_ids IS '图片文件ID';
COMMENT ON COLUMN public.app_model_configs.image_file_number_limit IS '图片文件数量限制';
COMMENT ON COLUMN public.app_model_configs.image_file_size_limit IS '图片文件大小限制';
COMMENT ON COLUMN public.app_model_configs.image_formats IS '图片格式';
COMMENT ON COLUMN public.app_model_configs.image_quality IS '图片质量';
COMMENT ON COLUMN public.app_model_configs.image_detail IS '图片细节';
COMMENT ON COLUMN public.app_model_configs.image_transfer_methods IS '图片传输方法';
COMMENT ON COLUMN public.app_model_configs.citation IS '引用';
COMMENT ON COLUMN public.app_model_configs.speech_to_text IS '语音转文本';
COMMENT ON COLUMN public.app_model_configs.retriever_change_prompt IS '检索变更提示';
COMMENT ON COLUMN public.app_model_configs.sensitive_word_avoidance IS '敏感词规避';
COMMENT ON COLUMN public.app_model_configs.text_to_speech IS '文本转语音';
COMMENT ON COLUMN public.app_model_configs.annotation_reply IS '注释回复';
COMMENT ON COLUMN public.app_model_configs.agent_config IS '智能体配置';
COMMENT ON COLUMN public.app_model_configs.dataset_configs IS '数据集配置';
COMMENT ON COLUMN public.app_model_configs.file_upload IS '文件上传';
COMMENT ON COLUMN public.app_model_configs.code_interpreter_tools IS '代码解释器工具';
COMMENT ON COLUMN public.app_model_configs.workflow IS '工作流';
COMMENT ON COLUMN public.app_model_configs.memory IS '记忆';
COMMENT ON COLUMN public.app_model_configs.text_to_image IS '文本转图片';
COMMENT ON COLUMN public.app_model_configs.tool_icons IS '工具图标';
COMMENT ON COLUMN public.app_model_configs.file_reader IS '文件阅读器';
COMMENT ON COLUMN public.app_model_configs.rerank_config IS '重排序配置';
COMMENT ON COLUMN public.app_model_configs.moderation_config IS '内容审核配置';
COMMENT ON COLUMN public.app_model_configs.file_upload_config IS '文件上传配置';

--
-- 应用模型配置版本表 - 存储应用模型配置的历史版本
--
CREATE TABLE public.app_model_config_versions (
    id uuid NOT NULL,                                           -- 版本记录唯一标识符
    app_id uuid NOT NULL,                                       -- 应用ID
    app_model_config_id uuid NOT NULL,                          -- 应用模型配置ID
    version character varying(255) NOT NULL,                    -- 版本号
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.app_model_config_versions IS '应用模型配置版本表 - 存储应用模型配置的历史版本';
COMMENT ON COLUMN public.app_model_config_versions.id IS '版本记录唯一标识符';
COMMENT ON COLUMN public.app_model_config_versions.app_id IS '应用ID';
COMMENT ON COLUMN public.app_model_config_versions.app_model_config_id IS '应用模型配置ID';
COMMENT ON COLUMN public.app_model_config_versions.version IS '版本号';
COMMENT ON COLUMN public.app_model_config_versions.created_at IS '创建时间';
COMMENT ON COLUMN public.app_model_config_versions.updated_at IS '更新时间';

--
-- 应用操作日志表 - 存储应用的操作日志
--
CREATE TABLE public.app_operation_logs (
    id uuid NOT NULL,                                           -- 日志唯一标识符
    app_id uuid NOT NULL,                                       -- 应用ID
    account_id uuid NOT NULL,                                   -- 操作账户ID
    operation character varying(255) NOT NULL,                  -- 操作类型
    content jsonb,                                              -- 操作内容
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 创建时间
);

COMMENT ON TABLE public.app_operation_logs IS '应用操作日志表 - 存储应用的操作日志';
COMMENT ON COLUMN public.app_operation_logs.id IS '日志唯一标识符';
COMMENT ON COLUMN public.app_operation_logs.app_id IS '应用ID';
COMMENT ON COLUMN public.app_operation_logs.account_id IS '操作账户ID';
COMMENT ON COLUMN public.app_operation_logs.operation IS '操作类型';
COMMENT ON COLUMN public.app_operation_logs.content IS '操作内容';
COMMENT ON COLUMN public.app_operation_logs.created_at IS '创建时间';

--
-- 应用表 - 存储应用的基本信息
--
CREATE TABLE public.apps (
    id uuid NOT NULL,                                           -- 应用唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    name character varying(255) NOT NULL,                       -- 应用名称
    mode character varying(16) NOT NULL,                        -- 应用模式
    icon character varying(255),                                -- 应用图标
    icon_background character varying(16),                      -- 图标背景色
    enable_site boolean DEFAULT true NOT NULL,                  -- 是否启用网站
    enable_api boolean DEFAULT false NOT NULL,                  -- 是否启用API
    api_rpm integer DEFAULT 0 NOT NULL,                         -- API每分钟请求次数限制
    api_rph integer DEFAULT 0 NOT NULL,                         -- API每小时请求次数限制
    is_public boolean DEFAULT false NOT NULL,                   -- 是否公开
    is_demo boolean DEFAULT false NOT NULL,                     -- 是否演示应用
    demo_html text,                                             -- 演示页面HTML
    copyright character varying(255),                           -- 版权信息
    privacy_policy text,                                        -- 隐私政策
    custom_disclaimer text,                                     -- 自定义免责声明
    uninstall_feedbacks jsonb,                                  -- 卸载反馈
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    workflow_version integer DEFAULT 1 NOT NULL,                -- 工作流版本
    code_based_app_type public.code_based_app_type,             -- 基于代码的应用类型
    status character varying(255) DEFAULT 'normal'::character varying NOT NULL -- 状态
);

COMMENT ON TABLE public.apps IS '应用表 - 存储应用的基本信息';
COMMENT ON COLUMN public.apps.id IS '应用唯一标识符';
COMMENT ON COLUMN public.apps.tenant_id IS '租户ID';
COMMENT ON COLUMN public.apps.name IS '应用名称';
COMMENT ON COLUMN public.apps.mode IS '应用模式';
COMMENT ON COLUMN public.apps.icon IS '应用图标';
COMMENT ON COLUMN public.apps.icon_background IS '图标背景色';
COMMENT ON COLUMN public.apps.enable_site IS '是否启用网站';
COMMENT ON COLUMN public.apps.enable_api IS '是否启用API';
COMMENT ON COLUMN public.apps.api_rpm IS 'API每分钟请求次数限制';
COMMENT ON COLUMN public.apps.api_rph IS 'API每小时请求次数限制';
COMMENT ON COLUMN public.apps.is_public IS '是否公开';
COMMENT ON COLUMN public.apps.is_demo IS '是否演示应用';
COMMENT ON COLUMN public.apps.demo_html IS '演示页面HTML';
COMMENT ON COLUMN public.apps.copyright IS '版权信息';
COMMENT ON COLUMN public.apps.privacy_policy IS '隐私政策';
COMMENT ON COLUMN public.apps.custom_disclaimer IS '自定义免责声明';
COMMENT ON COLUMN public.apps.uninstall_feedbacks IS '卸载反馈';
COMMENT ON COLUMN public.apps.created_at IS '创建时间';
COMMENT ON COLUMN public.apps.updated_at IS '更新时间';
COMMENT ON COLUMN public.apps.workflow_version IS '工作流版本';
COMMENT ON COLUMN public.apps.code_based_app_type IS '基于代码的应用类型';
COMMENT ON COLUMN public.apps.status IS '状态';

--
-- 应用表（旧版） - 旧版应用信息表
--
CREATE TABLE public.apps_old (
    id uuid NOT NULL,                                           -- 应用唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    name character varying(255) NOT NULL,                       -- 应用名称
    mode character varying(255) NOT NULL,                       -- 应用模式
    icon character varying(255),                                -- 应用图标
    icon_background character varying(255),                     -- 图标背景色
    enable_site boolean DEFAULT true NOT NULL,                  -- 是否启用网站
    enable_api boolean DEFAULT false NOT NULL,                  -- 是否启用API
    api_rpm integer DEFAULT 0 NOT NULL,                         -- API每分钟请求次数限制
    api_rph integer DEFAULT 0 NOT NULL,                         -- API每小时请求次数限制
    is_public boolean DEFAULT false NOT NULL,                   -- 是否公开
    is_demo boolean DEFAULT false NOT NULL,                     -- 是否演示应用
    demo_html text,                                             -- 演示页面HTML
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.apps_old IS '应用表（旧版） - 旧版应用信息表';
COMMENT ON COLUMN public.apps_old.id IS '应用唯一标识符';
COMMENT ON COLUMN public.apps_old.tenant_id IS '租户ID';
COMMENT ON COLUMN public.apps_old.name IS '应用名称';
COMMENT ON COLUMN public.apps_old.mode IS '应用模式';
COMMENT ON COLUMN public.apps_old.icon IS '应用图标';
COMMENT ON COLUMN public.apps_old.icon_background IS '图标背景色';
COMMENT ON COLUMN public.apps_old.enable_site IS '是否启用网站';
COMMENT ON COLUMN public.apps_old.enable_api IS '是否启用API';
COMMENT ON COLUMN public.apps_old.api_rpm IS 'API每分钟请求次数限制';
COMMENT ON COLUMN public.apps_old.api_rph IS 'API每小时请求次数限制';
COMMENT ON COLUMN public.apps_old.is_public IS '是否公开';
COMMENT ON COLUMN public.apps_old.is_demo IS '是否演示应用';
COMMENT ON COLUMN public.apps_old.demo_html IS '演示页面HTML';
COMMENT ON COLUMN public.apps_old.created_at IS '创建时间';
COMMENT ON COLUMN public.apps_old.updated_at IS '更新时间';

--
-- 计费订阅表 - 存储租户的计费订阅信息
--
CREATE TABLE public.billing_subscriptions (
    id uuid NOT NULL,                                           -- 订阅唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    plan_id character varying(255) NOT NULL,                    -- 计划ID
    status character varying(255) NOT NULL,                     -- 订阅状态
    interval_unit character varying(255) NOT NULL,              -- 间隔单位
    interval_count integer NOT NULL,                            -- 间隔计数
    cancel_at_period_end boolean DEFAULT false NOT NULL,        -- 是否在周期结束时取消
    canceled_at timestamp with time zone,                       -- 取消时间
    cancel_at timestamp with time zone,                         -- 计划取消时间
    current_period_start_at timestamp with time zone NOT NULL,  -- 当前周期开始时间
    current_period_end_at timestamp with time zone NOT NULL,    -- 当前周期结束时间
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.billing_subscriptions IS '计费订阅表 - 存储租户的计费订阅信息';
COMMENT ON COLUMN public.billing_subscriptions.id IS '订阅唯一标识符';
COMMENT ON COLUMN public.billing_subscriptions.tenant_id IS '租户ID';
COMMENT ON COLUMN public.billing_subscriptions.plan_id IS '计划ID';
COMMENT ON COLUMN public.billing_subscriptions.status IS '订阅状态';
COMMENT ON COLUMN public.billing_subscriptions.interval_unit IS '间隔单位';
COMMENT ON COLUMN public.billing_subscriptions.interval_count IS '间隔计数';
COMMENT ON COLUMN public.billing_subscriptions.cancel_at_period_end IS '是否在周期结束时取消';
COMMENT ON COLUMN public.billing_subscriptions.canceled_at IS '取消时间';
COMMENT ON COLUMN public.billing_subscriptions.cancel_at IS '计划取消时间';
COMMENT ON COLUMN public.billing_subscriptions.current_period_start_at IS '当前周期开始时间';
COMMENT ON COLUMN public.billing_subscriptions.current_period_end_at IS '当前周期结束时间';
COMMENT ON COLUMN public.billing_subscriptions.created_at IS '创建时间';
COMMENT ON COLUMN public.billing_subscriptions.updated_at IS '更新时间';

ALTER TABLE public.accounts OWNER TO root;
ALTER TABLE public.api_requests OWNER TO root;
ALTER TABLE public.app_annotations OWNER TO root;
ALTER TABLE public.app_annotation_settings OWNER TO root;
ALTER TABLE public.app_model_configs OWNER TO root;
ALTER TABLE public.app_model_config_versions OWNER TO root;
ALTER TABLE public.app_operation_logs OWNER TO root;
ALTER TABLE public.apps OWNER TO root;
ALTER TABLE public.apps_old OWNER TO root;
ALTER TABLE public.billing_subscriptions OWNER TO root;
-- Dify数据库表结构定义 (第二部分)
-- 包含组件、会话、数据集相关表

-- 组件凭证表 - 存储组件的认证凭据
CREATE TABLE public.component_credentials (
    id uuid NOT NULL,                                           -- 凭证唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    name character varying(255) NOT NULL,                       -- 凭证名称
    encrypt_mode character varying(16) NOT NULL,                -- 加密模式
    encrypted_credential jsonb NOT NULL,                        -- 加密后的凭证信息
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.component_credentials IS '组件凭证表 - 存储组件的认证凭据';
COMMENT ON COLUMN public.component_credentials.id IS '凭证唯一标识符';
COMMENT ON COLUMN public.component_credentials.tenant_id IS '租户ID';
COMMENT ON COLUMN public.component_credentials.name IS '凭证名称';
COMMENT ON COLUMN public.component_credentials.encrypt_mode IS '加密模式';
COMMENT ON COLUMN public.component_credentials.encrypted_credential IS '加密后的凭证信息';
COMMENT ON COLUMN public.component_credentials.created_at IS '创建时间';
COMMENT ON COLUMN public.component_credentials.updated_at IS '更新时间';

-- 会话消息表 - 存储会话中的消息记录
CREATE TABLE public.conversation_messages (
    id uuid NOT NULL,                                           -- 消息唯一标识符
    conversation_id uuid NOT NULL,                              -- 会话ID
    app_id uuid NOT NULL,                                       -- 应用ID
    message_id uuid NOT NULL,                                   -- 消息ID
    parent_message_id uuid,                                     -- 父消息ID
    inputs jsonb,                                              -- 输入数据
    query text,                                                 -- 查询内容
    answer text,                                                -- 回答内容
    message_metadata jsonb,                                     -- 消息元数据
    provider character varying(255),                            -- 提供商
    model character varying(255),                               -- 模型
    latency double precision,                                   -- 延迟
    tokens jsonb,                                              -- 令牌信息
    currency character varying(3),                              -- 货币单位
    price double precision,                                     -- 价格
    from_source character varying(16) NOT NULL,                 -- 来源
    from_end_user_id uuid,                                      -- 终端用户ID
    from_account_id uuid,                                       -- 账户ID
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    annotation_id uuid,                                         -- 注释ID
    override_model_configs jsonb,                               -- 覆盖模型配置
    agent_thoughts jsonb,                                       -- 智能体思考
    retriever_resources jsonb,                                  -- 检索资源
    message_files jsonb,                                        -- 消息文件
    feedbacks jsonb,                                            -- 反馈
    message_state character varying(255) DEFAULT 'normal'::character varying NOT NULL, -- 消息状态
    suggested_questions jsonb,                                  -- 建议问题
    message_tokens integer DEFAULT 0 NOT NULL,                  -- 消息令牌数
    answer_tokens integer DEFAULT 0 NOT NULL,                   -- 回答令牌数
    message_price double precision DEFAULT 0.0 NOT NULL,        -- 消息价格
    answer_price double precision DEFAULT 0.0 NOT NULL,         -- 回答价格
    cached boolean DEFAULT false NOT NULL,                      -- 是否缓存
    annotated_by_human boolean DEFAULT false NOT NULL,          -- 是否人工注释
    model_parameters jsonb,                                     -- 模型参数
    rating character varying(16)                                -- 评分
);

COMMENT ON TABLE public.conversation_messages IS '会话消息表 - 存储会话中的消息记录';
COMMENT ON COLUMN public.conversation_messages.id IS '消息唯一标识符';
COMMENT ON COLUMN public.conversation_messages.conversation_id IS '会话ID';
COMMENT ON COLUMN public.conversation_messages.app_id IS '应用ID';
COMMENT ON COLUMN public.conversation_messages.message_id IS '消息ID';
COMMENT ON COLUMN public.conversation_messages.parent_message_id IS '父消息ID';
COMMENT ON COLUMN public.conversation_messages.inputs IS '输入数据';
COMMENT ON COLUMN public.conversation_messages.query IS '查询内容';
COMMENT ON COLUMN public.conversation_messages.answer IS '回答内容';
COMMENT ON COLUMN public.conversation_messages.message_metadata IS '消息元数据';
COMMENT ON COLUMN public.conversation_messages.provider IS '提供商';
COMMENT ON COLUMN public.conversation_messages.model IS '模型';
COMMENT ON COLUMN public.conversation_messages.latency IS '延迟';
COMMENT ON COLUMN public.conversation_messages.tokens IS '令牌信息';
COMMENT ON COLUMN public.conversation_messages.currency IS '货币单位';
COMMENT ON COLUMN public.conversation_messages.price IS '价格';
COMMENT ON COLUMN public.conversation_messages.from_source IS '来源';
COMMENT ON COLUMN public.conversation_messages.from_end_user_id IS '终端用户ID';
COMMENT ON COLUMN public.conversation_messages.from_account_id IS '账户ID';
COMMENT ON COLUMN public.conversation_messages.created_at IS '创建时间';
COMMENT ON COLUMN public.conversation_messages.updated_at IS '更新时间';
COMMENT ON COLUMN public.conversation_messages.annotation_id IS '注释ID';
COMMENT ON COLUMN public.conversation_messages.override_model_configs IS '覆盖模型配置';
COMMENT ON COLUMN public.conversation_messages.agent_thoughts IS '智能体思考';
COMMENT ON COLUMN public.conversation_messages.retriever_resources IS '检索资源';
COMMENT ON COLUMN public.conversation_messages.message_files IS '消息文件';
COMMENT ON COLUMN public.conversation_messages.feedbacks IS '反馈';
COMMENT ON COLUMN public.conversation_messages.message_state IS '消息状态';
COMMENT ON COLUMN public.conversation_messages.suggested_questions IS '建议问题';
COMMENT ON COLUMN public.conversation_messages.message_tokens IS '消息令牌数';
COMMENT ON COLUMN public.conversation_messages.answer_tokens IS '回答令牌数';
COMMENT ON COLUMN public.conversation_messages.message_price IS '消息价格';
COMMENT ON COLUMN public.conversation_messages.answer_price IS '回答价格';
COMMENT ON COLUMN public.conversation_messages.cached IS '是否缓存';
COMMENT ON COLUMN public.conversation_messages.annotated_by_human IS '是否人工注释';
COMMENT ON COLUMN public.conversation_messages.model_parameters IS '模型参数';
COMMENT ON COLUMN public.conversation_messages.rating IS '评分';

-- 会话表 - 存储会话的基本信息
CREATE TABLE public.conversations (
    id uuid NOT NULL,                                           -- 会话唯一标识符
    app_id uuid NOT NULL,                                       -- 应用ID
    app_model_config_id uuid NOT NULL,                          -- 应用模型配置ID
    from_source character varying(16) NOT NULL,                 -- 来源
    from_end_user_id uuid,                                      -- 终端用户ID
    from_account_id uuid,                                       -- 账户ID
    name character varying(255) NOT NULL,                       -- 会话名称
    summary text,                                               -- 会话摘要
    status character varying(16) DEFAULT 'normal'::character varying NOT NULL, -- 会话状态
    system_instruction text,                                    -- 系统指令
    introduction text,                                          -- 介绍
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    read_at timestamp with time zone,                           -- 阅读时间
    suggested_questions_after_answer jsonb,                     -- 回答后的建议问题
    retrieved_semantic_ids jsonb,                               -- 检索到的语义ID
    more_like_this jsonb,                                       -- 更多类似
    suggested_response jsonb,                                   -- 建议响应
    external_retrieval_resources jsonb,                         -- 外部检索资源
    in_debug_mode boolean DEFAULT false NOT NULL,               -- 是否调试模式
    workflow_run_id uuid,                                       -- 工作流运行ID
    code_executions jsonb                                       -- 代码执行
);

COMMENT ON TABLE public.conversations IS '会话表 - 存储会话的基本信息';
COMMENT ON COLUMN public.conversations.id IS '会话唯一标识符';
COMMENT ON COLUMN public.conversations.app_id IS '应用ID';
COMMENT ON COLUMN public.conversations.app_model_config_id IS '应用模型配置ID';
COMMENT ON COLUMN public.conversations.from_source IS '来源';
COMMENT ON COLUMN public.conversations.from_end_user_id IS '终端用户ID';
COMMENT ON COLUMN public.conversations.from_account_id IS '账户ID';
COMMENT ON COLUMN public.conversations.name IS '会话名称';
COMMENT ON COLUMN public.conversations.summary IS '会话摘要';
COMMENT ON COLUMN public.conversations.status IS '会话状态';
COMMENT ON COLUMN public.conversations.system_instruction IS '系统指令';
COMMENT ON COLUMN public.conversations.introduction IS '介绍';
COMMENT ON COLUMN public.conversations.created_at IS '创建时间';
COMMENT ON COLUMN public.conversations.updated_at IS '更新时间';
COMMENT ON COLUMN public.conversations.read_at IS '阅读时间';
COMMENT ON COLUMN public.conversations.suggested_questions_after_answer IS '回答后的建议问题';
COMMENT ON COLUMN public.conversations.retrieved_semantic_ids IS '检索到的语义ID';
COMMENT ON COLUMN public.conversations.more_like_this IS '更多类似';
COMMENT ON COLUMN public.conversations.suggested_response IS '建议响应';
COMMENT ON COLUMN public.conversations.external_retrieval_resources IS '外部检索资源';
COMMENT ON COLUMN public.conversations.in_debug_mode IS '是否调试模式';
COMMENT ON COLUMN public.conversations.workflow_run_id IS '工作流运行ID';
COMMENT ON COLUMN public.conversations.code_executions IS '代码执行';

-- 数据集文档索引任务表 - 存储数据集文档的索引任务信息
CREATE TABLE public.dataset_document_index_tasks (
    id uuid NOT NULL,                                           -- 任务唯一标识符
    dataset_document_id uuid NOT NULL,                          -- 数据集文档ID
    endpoint character varying(255) NOT NULL,                   -- 端点
    worker character varying(255),                              -- 工作者
    status public.dataset_document_indexing_status DEFAULT 'waiting'::public.dataset_document_indexing_status NOT NULL, -- 索引状态
    reason text,                                                -- 原因
    started_at timestamp with time zone,                        -- 开始时间
    completed_at timestamp with time zone,                      -- 完成时间
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.dataset_document_index_tasks IS '数据集文档索引任务表 - 存储数据集文档的索引任务信息';
COMMENT ON COLUMN public.dataset_document_index_tasks.id IS '任务唯一标识符';
COMMENT ON COLUMN public.dataset_document_index_tasks.dataset_document_id IS '数据集文档ID';
COMMENT ON COLUMN public.dataset_document_index_tasks.endpoint IS '端点';
COMMENT ON COLUMN public.dataset_document_index_tasks.worker IS '工作者';
COMMENT ON COLUMN public.dataset_document_index_tasks.status IS '索引状态';
COMMENT ON COLUMN public.dataset_document_index_tasks.reason IS '原因';
COMMENT ON COLUMN public.dataset_document_index_tasks.started_at IS '开始时间';
COMMENT ON COLUMN public.dataset_document_index_tasks.completed_at IS '完成时间';
COMMENT ON COLUMN public.dataset_document_index_tasks.created_at IS '创建时间';
COMMENT ON COLUMN public.dataset_document_index_tasks.updated_at IS '更新时间';

-- 数据集文档表 - 存储数据集中的文档信息
CREATE TABLE public.dataset_documents (
    id uuid NOT NULL,                                           -- 文档唯一标识符
    dataset_id uuid NOT NULL,                                   -- 数据集ID
    position integer DEFAULT 0 NOT NULL,                        -- 位置
    data_source_type character varying(255) NOT NULL,           -- 数据源类型
    data_source_info jsonb,                                     -- 数据源信息
    dataset_process_rule_id uuid NOT NULL,                      -- 数据集处理规则ID
    name character varying(255) NOT NULL,                       -- 文档名称
    created_from character varying(255) NOT NULL,               -- 创建来源
    created_by uuid NOT NULL,                                   -- 创建者ID
    created_api_request_id uuid,                                -- 创建API请求ID
    processing_started_at timestamp with time zone,             -- 处理开始时间
    processing_completed_at timestamp with time zone,           -- 处理完成时间
    parsing_completed_at timestamp with time zone,              -- 解析完成时间
    cleaning_completed_at timestamp with time zone,             -- 清洗完成时间
    splitting_completed_at timestamp with time zone,            -- 分割完成时间
    indexing_completed_at timestamp with time zone,             -- 索引完成时间
    completed_at timestamp with time zone,                      -- 完成时间
    paused_by uuid,                                             -- 暂停者ID
    paused_at timestamp with time zone,                         -- 暂停时间
    error text,                                                 -- 错误信息
    stopped_at timestamp with time zone,                        -- 停止时间
    archived_reason character varying(255),                     -- 归档原因
    archived_by uuid,                                           -- 归档者ID
    archived_at timestamp with time zone,                       -- 归档时间
    enabled_at timestamp with time zone,                        -- 启用时间
    disabled_at timestamp with time zone,                       -- 禁用时间
    status public.dataset_document_status DEFAULT 'uploading'::public.dataset_document_status NOT NULL, -- 文档状态
    indexing_status public.dataset_document_indexing_status DEFAULT 'waiting'::public.dataset_document_indexing_status NOT NULL, -- 索引状态
    completed_segments integer DEFAULT 0 NOT NULL,              -- 完成的段落数
    total_segments integer DEFAULT 0 NOT NULL,                  -- 总段落数
    word_count jsonb,                                           -- 字数统计
    hit_count integer DEFAULT 0 NOT NULL,                       -- 命中次数
    document_metadata jsonb,                                    -- 文档元数据
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    batch character varying(255) DEFAULT '1'::character varying NOT NULL, -- 批次
    processing_type public.dataset_document_word_count_status DEFAULT 'calculating'::public.dataset_document_word_count_status NOT NULL, -- 处理类型
    doc_form character varying(255) DEFAULT 'text_model'::character varying NOT NULL, -- 文档形式
    doc_language character varying(255) DEFAULT 'zh'::character varying NOT NULL, -- 文档语言
    index_failures integer DEFAULT 0 NOT NULL,                  -- 索引失败次数
    custom_page_number integer,                                 -- 自定义页码
    segment_position character varying(255) DEFAULT '0'::character varying NOT NULL, -- 段落位置
    doc_type character varying(255) DEFAULT 'pre_processing'::character varying NOT NULL  -- 文档类型
);

COMMENT ON TABLE public.dataset_documents IS '数据集文档表 - 存储数据集中的文档信息';
COMMENT ON COLUMN public.dataset_documents.id IS '文档唯一标识符';
COMMENT ON COLUMN public.dataset_documents.dataset_id IS '数据集ID';
COMMENT ON COLUMN public.dataset_documents.position IS '位置';
COMMENT ON COLUMN public.dataset_documents.data_source_type IS '数据源类型';
COMMENT ON COLUMN public.dataset_documents.data_source_info IS '数据源信息';
COMMENT ON COLUMN public.dataset_documents.dataset_process_rule_id IS '数据集处理规则ID';
COMMENT ON COLUMN public.dataset_documents.name IS '文档名称';
COMMENT ON COLUMN public.dataset_documents.created_from IS '创建来源';
COMMENT ON COLUMN public.dataset_documents.created_by IS '创建者ID';
COMMENT ON COLUMN public.dataset_documents.created_api_request_id IS '创建API请求ID';
COMMENT ON COLUMN public.dataset_documents.processing_started_at IS '处理开始时间';
COMMENT ON COLUMN public.dataset_documents.processing_completed_at IS '处理完成时间';
COMMENT ON COLUMN public.dataset_documents.parsing_completed_at IS '解析完成时间';
COMMENT ON COLUMN public.dataset_documents.cleaning_completed_at IS '清洗完成时间';
COMMENT ON COLUMN public.dataset_documents.splitting_completed_at IS '分割完成时间';
COMMENT ON COLUMN public.dataset_documents.indexing_completed_at IS '索引完成时间';
COMMENT ON COLUMN public.dataset_documents.completed_at IS '完成时间';
COMMENT ON COLUMN public.dataset_documents.paused_by IS '暂停者ID';
COMMENT ON COLUMN public.dataset_documents.paused_at IS '暂停时间';
COMMENT ON COLUMN public.dataset_documents.error IS '错误信息';
COMMENT ON COLUMN public.dataset_documents.stopped_at IS '停止时间';
COMMENT ON COLUMN public.dataset_documents.archived_reason IS '归档原因';
COMMENT ON COLUMN public.dataset_documents.archived_by IS '归档者ID';
COMMENT ON COLUMN public.dataset_documents.archived_at IS '归档时间';
COMMENT ON COLUMN public.dataset_documents.enabled_at IS '启用时间';
COMMENT ON COLUMN public.dataset_documents.disabled_at IS '禁用时间';
COMMENT ON COLUMN public.dataset_documents.status IS '文档状态';
COMMENT ON COLUMN public.dataset_documents.indexing_status IS '索引状态';
COMMENT ON COLUMN public.dataset_documents.completed_segments IS '完成的段落数';
COMMENT ON COLUMN public.dataset_documents.total_segments IS '总段落数';
COMMENT ON COLUMN public.dataset_documents.word_count IS '字数统计';
COMMENT ON COLUMN public.dataset_documents.hit_count IS '命中次数';
COMMENT ON COLUMN public.dataset_documents.document_metadata IS '文档元数据';
COMMENT ON COLUMN public.dataset_documents.created_at IS '创建时间';
COMMENT ON COLUMN public.dataset_documents.updated_at IS '更新时间';
COMMENT ON COLUMN public.dataset_documents.batch IS '批次';
COMMENT ON COLUMN public.dataset_documents.processing_type IS '处理类型';
COMMENT ON COLUMN public.dataset_documents.doc_form IS '文档形式';
COMMENT ON COLUMN public.dataset_documents.doc_language IS '文档语言';
COMMENT ON COLUMN public.dataset_documents.index_failures IS '索引失败次数';
COMMENT ON COLUMN public.dataset_documents.custom_page_number IS '自定义页码';
COMMENT ON COLUMN public.dataset_documents.segment_position IS '段落位置';
COMMENT ON COLUMN public.dataset_documents.doc_type IS '文档类型';

-- 数据集实体表 - 存储数据集中的实体信息
CREATE TABLE public.dataset_entities (
    id uuid NOT NULL,                                           -- 实体唯一标识符
    dataset_id uuid NOT NULL,                                   -- 数据集ID
    hash character varying(255) NOT NULL,                       -- 哈希值
    name character varying(255) NOT NULL,                       -- 实体名称
    description text,                                           -- 实体描述
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.dataset_entities IS '数据集实体表 - 存储数据集中的实体信息';
COMMENT ON COLUMN public.dataset_entities.id IS '实体唯一标识符';
COMMENT ON COLUMN public.dataset_entities.dataset_id IS '数据集ID';
COMMENT ON COLUMN public.dataset_entities.hash IS '哈希值';
COMMENT ON COLUMN public.dataset_entities.name IS '实体名称';
COMMENT ON COLUMN public.dataset_entities.description IS '实体描述';
COMMENT ON COLUMN public.dataset_entities.created_at IS '创建时间';
COMMENT ON COLUMN public.dataset_entities.updated_at IS '更新时间';

-- 数据集关键词索引段表 - 存储数据集的关键词索引段信息
CREATE TABLE public.dataset_keyword_index_segments (
    id uuid NOT NULL,                                           -- 索引段唯一标识符
    dataset_id uuid NOT NULL,                                   -- 数据集ID
    document_id uuid NOT NULL,                                  -- 文档ID
    segment_id uuid NOT NULL,                                   -- 段落ID
    keywords jsonb NOT NULL,                                    -- 关键词
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 创建时间
);

COMMENT ON TABLE public.dataset_keyword_index_segments IS '数据集关键词索引段表 - 存储数据集的关键词索引段信息';
COMMENT ON COLUMN public.dataset_keyword_index_segments.id IS '索引段唯一标识符';
COMMENT ON COLUMN public.dataset_keyword_index_segments.dataset_id IS '数据集ID';
COMMENT ON COLUMN public.dataset_keyword_index_segments.document_id IS '文档ID';
COMMENT ON COLUMN public.dataset_keyword_index_segments.segment_id IS '段落ID';
COMMENT ON COLUMN public.dataset_keyword_index_segments.keywords IS '关键词';
COMMENT ON COLUMN public.dataset_keyword_index_segments.created_at IS '创建时间';

-- 数据集处理规则表 - 存储数据集的处理规则
CREATE TABLE public.dataset_process_rules (
    id uuid NOT NULL,                                           -- 规则唯一标识符
    dataset_id uuid NOT NULL,                                   -- 数据集ID
    mode character varying(255) NOT NULL,                       -- 模式
    rules jsonb,                                                -- 规则内容
    created_by uuid NOT NULL,                                   -- 创建者ID
    updated_by uuid,                                            -- 更新者ID
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.dataset_process_rules IS '数据集处理规则表 - 存储数据集的处理规则';
COMMENT ON COLUMN public.dataset_process_rules.id IS '规则唯一标识符';
COMMENT ON COLUMN public.dataset_process_rules.dataset_id IS '数据集ID';
COMMENT ON COLUMN public.dataset_process_rules.mode IS '模式';
COMMENT ON COLUMN public.dataset_process_rules.rules IS '规则内容';
COMMENT ON COLUMN public.dataset_process_rules.created_by IS '创建者ID';
COMMENT ON COLUMN public.dataset_process_rules.updated_by IS '更新者ID';
COMMENT ON COLUMN public.dataset_process_rules.created_at IS '创建时间';
COMMENT ON COLUMN public.dataset_process_rules.updated_at IS '更新时间';

-- 数据集查询表 - 存储数据集的查询记录
CREATE TABLE public.dataset_queries (
    id uuid NOT NULL,                                           -- 查询唯一标识符
    dataset_id uuid NOT NULL,                                   -- 数据集ID
    content text NOT NULL,                                      -- 查询内容
    source character varying(255) NOT NULL,                     -- 查询来源
    created_by_role character varying(16) NOT NULL,             -- 创建者角色
    created_by uuid NOT NULL,                                   -- 创建者ID
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.dataset_queries IS '数据集查询表 - 存储数据集的查询记录';
COMMENT ON COLUMN public.dataset_queries.id IS '查询唯一标识符';
COMMENT ON COLUMN public.dataset_queries.dataset_id IS '数据集ID';
COMMENT ON COLUMN public.dataset_queries.content IS '查询内容';
COMMENT ON COLUMN public.dataset_queries.source IS '查询来源';
COMMENT ON COLUMN public.dataset_queries.created_by_role IS '创建者角色';
COMMENT ON COLUMN public.dataset_queries.created_by IS '创建者ID';
COMMENT ON COLUMN public.dataset_queries.created_at IS '创建时间';
COMMENT ON COLUMN public.dataset_queries.updated_at IS '更新时间';

-- 数据集相关应用表 - 存储数据集与应用的关联关系
CREATE TABLE public.dataset_related_apps (
    id uuid NOT NULL,                                           -- 关联唯一标识符
    dataset_id uuid NOT NULL,                                   -- 数据集ID
    app_id uuid NOT NULL,                                       -- 应用ID
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 创建时间
);

COMMENT ON TABLE public.dataset_related_apps IS '数据集相关应用表 - 存储数据集与应用的关联关系';
COMMENT ON COLUMN public.dataset_related_apps.id IS '关联唯一标识符';
COMMENT ON COLUMN public.dataset_related_apps.dataset_id IS '数据集ID';
COMMENT ON COLUMN public.dataset_related_apps.app_id IS '应用ID';
COMMENT ON COLUMN public.dataset_related_apps.created_at IS '创建时间';

-- 数据集表 - 存储数据集的基本信息
CREATE TABLE public.datasets (
    id uuid NOT NULL,                                           -- 数据集唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    name character varying(255) NOT NULL,                       -- 数据集名称
    description text,                                           -- 数据集描述
    provider character varying(255) DEFAULT 'vendor'::character varying NOT NULL, -- 提供商
    permission character varying(255) DEFAULT 'only_me'::character varying NOT NULL, -- 权限
    data_source_type character varying(255),                    -- 数据源类型
    indexing_technique character varying(255),                  -- 索引技术
    chunk_size integer,                                         -- 分块大小
    embedding_model character varying(255),                     -- 嵌入模型
    embedding_model_provider character varying(255),            -- 嵌入模型提供商
    conversation_dataset_process_rule_id uuid,                  -- 对话数据集处理规则ID
    retrieval_model jsonb,                                      -- 检索模型
    external_knowledge_api_based_configs jsonb,                 -- 基于API的外部知识配置
    created_by uuid NOT NULL,                                   -- 创建者ID
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    status public.dataset_status DEFAULT 'setup'::public.dataset_status NOT NULL, -- 数据集状态
    type public.dataset_type DEFAULT 'normal'::public.dataset_type NOT NULL, -- 数据集类型
    author character varying(255) DEFAULT ''::character varying NOT NULL, -- 作者
    indexing_latency double precision,                          -- 索引延迟
    word_count integer DEFAULT 0 NOT NULL,                      -- 字数
    embedding_available boolean DEFAULT false NOT NULL,         -- 嵌入是否可用
    retrieval_setting jsonb,                                    -- 检索设置
    external_retrieval_setting jsonb,                           -- 外部检索设置
    qdrant_collection_name character varying(255),              -- Qdrant集合名称
    original_separator character varying(255) DEFAULT '###\n'::character varying NOT NULL, -- 原始分隔符
    pre_processing_separator character varying(255) DEFAULT '###\n'::character varying NOT NULL, -- 预处理分隔符
    custom_pre_processing_separator character varying(255) DEFAULT ''::character varying NOT NULL  -- 自定义预处理分隔符
);

COMMENT ON TABLE public.datasets IS '数据集表 - 存储数据集的基本信息';
COMMENT ON COLUMN public.datasets.id IS '数据集唯一标识符';
COMMENT ON COLUMN public.datasets.tenant_id IS '租户ID';
COMMENT ON COLUMN public.datasets.name IS '数据集名称';
COMMENT ON COLUMN public.datasets.description IS '数据集描述';
COMMENT ON COLUMN public.datasets.provider IS '提供商';
COMMENT ON COLUMN public.datasets.permission IS '权限';
COMMENT ON COLUMN public.datasets.data_source_type IS '数据源类型';
COMMENT ON COLUMN public.datasets.indexing_technique IS '索引技术';
COMMENT ON COLUMN public.datasets.chunk_size IS '分块大小';
COMMENT ON COLUMN public.datasets.embedding_model IS '嵌入模型';
COMMENT ON COLUMN public.datasets.embedding_model_provider IS '嵌入模型提供商';
COMMENT ON COLUMN public.datasets.conversation_dataset_process_rule_id IS '对话数据集处理规则ID';
COMMENT ON COLUMN public.datasets.retrieval_model IS '检索模型';
COMMENT ON COLUMN public.datasets.external_knowledge_api_based_configs IS '基于API的外部知识配置';
COMMENT ON COLUMN public.datasets.created_by IS '创建者ID';
COMMENT ON COLUMN public.datasets.created_at IS '创建时间';
COMMENT ON COLUMN public.datasets.updated_at IS '更新时间';
COMMENT ON COLUMN public.datasets.status IS '数据集状态';
COMMENT ON COLUMN public.datasets.type IS '数据集类型';
COMMENT ON COLUMN public.datasets.author IS '作者';
COMMENT ON COLUMN public.datasets.indexing_latency IS '索引延迟';
COMMENT ON COLUMN public.datasets.word_count IS '字数';
COMMENT ON COLUMN public.datasets.embedding_available IS '嵌入是否可用';
COMMENT ON COLUMN public.datasets.retrieval_setting IS '检索设置';
COMMENT ON COLUMN public.datasets.external_retrieval_setting IS '外部检索设置';
COMMENT ON COLUMN public.datasets.qdrant_collection_name IS 'Qdrant集合名称';
COMMENT ON COLUMN public.datasets.original_separator IS '原始分隔符';
COMMENT ON COLUMN public.datasets.pre_processing_separator IS '预处理分隔符';
COMMENT ON COLUMN public.datasets.custom_pre_processing_separator IS '自定义预处理分隔符';

-- 数据集表（旧版） - 旧版数据集信息表
CREATE TABLE public.datasets_old (
    id uuid NOT NULL,                                           -- 数据集唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    name character varying(255) NOT NULL,                       -- 数据集名称
    description text,                                           -- 数据集描述
    provider character varying(255) DEFAULT 'vendor'::character varying NOT NULL, -- 提供商
    permission character varying(255) DEFAULT 'only_me'::character varying NOT NULL, -- 权限
    data_source_type character varying(255),                    -- 数据源类型
    indexing_technique character varying(255),                  -- 索引技术
    chunk_size integer,                                         -- 分块大小
    embedding_model character varying(255),                     -- 嵌入模型
    embedding_model_provider character varying(255),            -- 嵌入模型提供商
    conversation_dataset_process_rule_id uuid,                  -- 对话数据集处理规则ID
    retrieval_model jsonb,                                      -- 检索模型
    created_by uuid NOT NULL,                                   -- 创建者ID
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    status character varying(255) DEFAULT 'setup'::character varying NOT NULL, -- 数据集状态
    type character varying(255) DEFAULT 'normal'::character varying NOT NULL  -- 数据集类型
);

COMMENT ON TABLE public.datasets_old IS '数据集表（旧版） - 旧版数据集信息表';
COMMENT ON COLUMN public.datasets_old.id IS '数据集唯一标识符';
COMMENT ON COLUMN public.datasets_old.tenant_id IS '租户ID';
COMMENT ON COLUMN public.datasets_old.name IS '数据集名称';
COMMENT ON COLUMN public.datasets_old.description IS '数据集描述';
COMMENT ON COLUMN public.datasets_old.provider IS '提供商';
COMMENT ON COLUMN public.datasets_old.permission IS '权限';
COMMENT ON COLUMN public.datasets_old.data_source_type IS '数据源类型';
COMMENT ON COLUMN public.datasets_old.indexing_technique IS '索引技术';
COMMENT ON COLUMN public.datasets_old.chunk_size IS '分块大小';
COMMENT ON COLUMN public.datasets_old.embedding_model IS '嵌入模型';
COMMENT ON COLUMN public.datasets_old.embedding_model_provider IS '嵌入模型提供商';
COMMENT ON COLUMN public.datasets_old.conversation_dataset_process_rule_id IS '对话数据集处理规则ID';
COMMENT ON COLUMN public.datasets_old.retrieval_model IS '检索模型';
COMMENT ON COLUMN public.datasets_old.created_by IS '创建者ID';
COMMENT ON COLUMN public.datasets_old.created_at IS '创建时间';
COMMENT ON COLUMN public.datasets_old.updated_at IS '更新时间';
COMMENT ON COLUMN public.datasets_old.status IS '数据集状态';
COMMENT ON COLUMN public.datasets_old.type IS '数据集类型';

-- 文档段落表 - 存储文档的段落信息
CREATE TABLE public.document_segments (
    id uuid NOT NULL,                                           -- 段落唯一标识符
    dataset_id uuid NOT NULL,                                   -- 数据集ID
    document_id uuid NOT NULL,                                  -- 文档ID
    position integer NOT NULL,                                  -- 位置
    content text NOT NULL,                                      -- 段落内容
    answer text,                                                -- 答案
    character_count integer NOT NULL,                           -- 字符数
    token_count integer NOT NULL,                               -- 令牌数
    keywords jsonb,                                             -- 关键词
    index_node_id character varying(255),                       -- 索引节点ID
    index_node_hash character varying(255),                     -- 索引节点哈希
    hit_count integer DEFAULT 0 NOT NULL,                       -- 命中次数
    enabled boolean DEFAULT true NOT NULL,                      -- 是否启用
    disabled_at timestamp with time zone,                       -- 禁用时间
    disabled_by uuid,                                           -- 禁用者ID
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    status character varying(255) DEFAULT 'completed'::character varying NOT NULL, -- 状态
    error text,                                                 -- 错误信息
    stopped_at timestamp with time zone,                        -- 停止时间
    custom_meta_data jsonb,                                     -- 自定义元数据
    segment_metadata jsonb,                                     -- 段落元数据
    doc_form character varying(255) DEFAULT 'text_model'::character varying NOT NULL, -- 文档形式
    doc_language character varying(255) DEFAULT 'zh'::character varying NOT NULL, -- 文档语言
    doc_type character varying(255) DEFAULT 'pre_processing'::character varying NOT NULL, -- 文档类型
    hit_question text,                                          -- 命中问题
    entity_extraction_result jsonb,                             -- 实体抽取结果
    relationship_extraction_result jsonb,                       -- 关系抽取结果
    embedding public.embedding                                  -- 嵌入向量
);

COMMENT ON TABLE public.document_segments IS '文档段落表 - 存储文档的段落信息';
COMMENT ON COLUMN public.document_segments.id IS '段落唯一标识符';
COMMENT ON COLUMN public.document_segments.dataset_id IS '数据集ID';
COMMENT ON COLUMN public.document_segments.document_id IS '文档ID';
COMMENT ON COLUMN public.document_segments.position IS '位置';
COMMENT ON COLUMN public.document_segments.content IS '段落内容';
COMMENT ON COLUMN public.document_segments.answer IS '答案';
COMMENT ON COLUMN public.document_segments.character_count IS '字符数';
COMMENT ON COLUMN public.document_segments.token_count IS '令牌数';
COMMENT ON COLUMN public.document_segments.keywords IS '关键词';
COMMENT ON COLUMN public.document_segments.index_node_id IS '索引节点ID';
COMMENT ON COLUMN public.document_segments.index_node_hash IS '索引节点哈希';
COMMENT ON COLUMN public.document_segments.hit_count IS '命中次数';
COMMENT ON COLUMN public.document_segments.enabled IS '是否启用';
COMMENT ON COLUMN public.document_segments.disabled_at IS '禁用时间';
COMMENT ON COLUMN public.document_segments.disabled_by IS '禁用者ID';
COMMENT ON COLUMN public.document_segments.created_at IS '创建时间';
COMMENT ON COLUMN public.document_segments.updated_at IS '更新时间';
COMMENT ON COLUMN public.document_segments.status IS '状态';
COMMENT ON COLUMN public.document_segments.error IS '错误信息';
COMMENT ON COLUMN public.document_segments.stopped_at IS '停止时间';
COMMENT ON COLUMN public.document_segments.custom_meta_data IS '自定义元数据';
COMMENT ON COLUMN public.document_segments.segment_metadata IS '段落元数据';
COMMENT ON COLUMN public.document_segments.doc_form IS '文档形式';
COMMENT ON COLUMN public.document_segments.doc_language IS '文档语言';
COMMENT ON COLUMN public.document_segments.doc_type IS '文档类型';
COMMENT ON COLUMN public.document_segments.hit_question IS '命中问题';
COMMENT ON COLUMN public.document_segments.entity_extraction_result IS '实体抽取结果';
COMMENT ON COLUMN public.document_segments.relationship_extraction_result IS '关系抽取结果';
COMMENT ON COLUMN public.document_segments.embedding IS '嵌入向量';

-- 域名白名单表 - 存储租户的域名白名单
CREATE TABLE public.domain_white_lists (
    id uuid NOT NULL,                                           -- 白名单唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    domain character varying(255) NOT NULL,                     -- 域名
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 创建时间
);

COMMENT ON TABLE public.domain_white_lists IS '域名白名单表 - 存储租户的域名白名单';
COMMENT ON COLUMN public.domain_white_lists.id IS '白名单唯一标识符';
COMMENT ON COLUMN public.domain_white_lists.tenant_id IS '租户ID';
COMMENT ON COLUMN public.domain_white_lists.domain IS '域名';
COMMENT ON COLUMN public.domain_white_lists.created_at IS '创建时间';

-- 结束通知表 - 存储结束类型的通知信息
CREATE TABLE public.ended_at_notifications (
    id uuid NOT NULL,                                           -- 通知唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    account_id uuid NOT NULL,                                   -- 账户ID
    type character varying(255) NOT NULL,                       -- 通知类型
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.ended_at_notifications IS '结束通知表 - 存储结束类型的通知信息';
COMMENT ON COLUMN public.ended_at_notifications.id IS '通知唯一标识符';
COMMENT ON COLUMN public.ended_at_notifications.tenant_id IS '租户ID';
COMMENT ON COLUMN public.ended_at_notifications.account_id IS '账户ID';
COMMENT ON COLUMN public.ended_at_notifications.type IS '通知类型';
COMMENT ON COLUMN public.ended_at_notifications.created_at IS '创建时间';
COMMENT ON COLUMN public.ended_at_notifications.updated_at IS '更新时间';

-- 事件表 - 存储系统事件信息
CREATE TABLE public.events (
    id uuid NOT NULL,                                           -- 事件唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    account_id uuid,                                            -- 账户ID
    type character varying(255) NOT NULL,                       -- 事件类型
    payload jsonb,                                              -- 事件负载
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 创建时间
);

COMMENT ON TABLE public.events IS '事件表 - 存储系统事件信息';
COMMENT ON COLUMN public.events.id IS '事件唯一标识符';
COMMENT ON COLUMN public.events.tenant_id IS '租户ID';
COMMENT ON COLUMN public.events.account_id IS '账户ID';
COMMENT
-- Dify数据库表结构定义 (第三部分)
-- 包含文件、通知、模型等相关表

-- 文件密钥表 - 存储文件的密钥信息
CREATE TABLE public.file_keys (
    id uuid NOT NULL,                                           -- 文件密钥唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    type public.file_type NOT NULL,                             -- 文件类型
    file_name character varying(255) NOT NULL,                  -- 文件名
    file_extension character varying(255) NOT NULL,             -- 文件扩展名
    file_size integer NOT NULL,                                 -- 文件大小
    upload_file_id uuid,                                        -- 上传文件ID
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    used_by_app_template boolean DEFAULT false NOT NULL         -- 是否被应用模板使用
);

COMMENT ON TABLE public.file_keys IS '文件密钥表 - 存储文件的密钥信息';
COMMENT ON COLUMN public.file_keys.id IS '文件密钥唯一标识符';
COMMENT ON COLUMN public.file_keys.tenant_id IS '租户ID';
COMMENT ON COLUMN public.file_keys.type IS '文件类型';
COMMENT ON COLUMN public.file_keys.file_name IS '文件名';
COMMENT ON COLUMN public.file_keys.file_extension IS '文件扩展名';
COMMENT ON COLUMN public.file_keys.file_size IS '文件大小';
COMMENT ON COLUMN public.file_keys.upload_file_id IS '上传文件ID';
COMMENT ON COLUMN public.file_keys.created_at IS '创建时间';
COMMENT ON COLUMN public.file_keys.updated_at IS '更新时间';
COMMENT ON COLUMN public.file_keys.used_by_app_template IS '是否被应用模板使用';

-- 已安装应用表 - 存储租户已安装的应用信息
CREATE TABLE public.installed_apps (
    id uuid NOT NULL,                                           -- 已安装应用唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    app_id uuid NOT NULL,                                       -- 应用ID
    is_pinned boolean DEFAULT false NOT NULL,                   -- 是否置顶
    position integer,                                           -- 位置
    uninstall_feedbacks jsonb,                                  -- 卸载反馈
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.installed_apps IS '已安装应用表 - 存储租户已安装的应用信息';
COMMENT ON COLUMN public.installed_apps.id IS '已安装应用唯一标识符';
COMMENT ON COLUMN public.installed_apps.tenant_id IS '租户ID';
COMMENT ON COLUMN public.installed_apps.app_id IS '应用ID';
COMMENT ON COLUMN public.installed_apps.is_pinned IS '是否置顶';
COMMENT ON COLUMN public.installed_apps.position IS '位置';
COMMENT ON COLUMN public.installed_apps.uninstall_feedbacks IS '卸载反馈';
COMMENT ON COLUMN public.installed_apps.created_at IS '创建时间';
COMMENT ON COLUMN public.installed_apps.updated_at IS '更新时间';

-- 邀请账户表 - 存储被邀请的账户信息
CREATE TABLE public.invited_accounts (
    id uuid NOT NULL,                                           -- 邀请记录唯一标识符
    email character varying(255) NOT NULL,                      -- 邮箱
    tenant_id uuid NOT NULL,                                    -- 租户ID
    inviter_account_id uuid NOT NULL,                           -- 邀请人账户ID
    role public.tenant_account_role DEFAULT 'member'::public.tenant_account_role NOT NULL, -- 角色
    token character varying(255) NOT NULL,                      -- 邀请令牌
    expired_at timestamp with time zone NOT NULL,               -- 过期时间
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 创建时间
);

COMMENT ON TABLE public.invited_accounts IS '邀请账户表 - 存储被邀请的账户信息';
COMMENT ON COLUMN public.invited_accounts.id IS '邀请记录唯一标识符';
COMMENT ON COLUMN public.invited_accounts.email IS '邮箱';
COMMENT ON COLUMN public.invited_accounts.tenant_id IS '租户ID';
COMMENT ON COLUMN public.invited_accounts.inviter_account_id IS '邀请人账户ID';
COMMENT ON COLUMN public.invited_accounts.role IS '角色';
COMMENT ON COLUMN public.invited_accounts.token IS '邀请令牌';
COMMENT ON COLUMN public.invited_accounts.expired_at IS '过期时间';
COMMENT ON COLUMN public.invited_accounts.created_at IS '创建时间';

-- 消息智能体思维表 - 存储消息中智能体的思考过程
CREATE TABLE public.message_agent_thoughts (
    id uuid NOT NULL,                                           -- 思维记录唯一标识符
    message_id uuid NOT NULL,                                   -- 消息ID
    message_chain_id uuid,                                      -- 消息链ID
    thought text,                                               -- 思考内容
    tool_info jsonb,                                            -- 工具信息
    observation text,                                           -- 观察结果
    files jsonb,                                                -- 文件
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    steps jsonb,                                                -- 步骤
    rating character varying(16)                                -- 评分
);

COMMENT ON TABLE public.message_agent_thoughts IS '消息智能体思维表 - 存储消息中智能体的思考过程';
COMMENT ON COLUMN public.message_agent_thoughts.id IS '思维记录唯一标识符';
COMMENT ON COLUMN public.message_agent_thoughts.message_id IS '消息ID';
COMMENT ON COLUMN public.message_agent_thoughts.message_chain_id IS '消息链ID';
COMMENT ON COLUMN public.message_agent_thoughts.thought IS '思考内容';
COMMENT ON COLUMN public.message_agent_thoughts.tool_info IS '工具信息';
COMMENT ON COLUMN public.message_agent_thoughts.observation IS '观察结果';
COMMENT ON COLUMN public.message_agent_thoughts.files IS '文件';
COMMENT ON COLUMN public.message_agent_thoughts.created_at IS '创建时间';
COMMENT ON COLUMN public.message_agent_thoughts.updated_at IS '更新时间';
COMMENT ON COLUMN public.message_agent_thoughts.steps IS '步骤';
COMMENT ON COLUMN public.message_agent_thoughts.rating IS '评分';

-- 消息链表 - 存储消息链的信息
CREATE TABLE public.message_chains (
    id uuid NOT NULL,                                           -- 消息链唯一标识符
    message_id uuid NOT NULL,                                   -- 消息ID
    prompt text,                                                -- 提示
    tokens integer,                                             -- 令牌数
    tool_process_data jsonb,                                    -- 工具处理数据
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.message_chains IS '消息链表 - 存储消息链的信息';
COMMENT ON COLUMN public.message_chains.id IS '消息链唯一标识符';
COMMENT ON COLUMN public.message_chains.message_id IS '消息ID';
COMMENT ON COLUMN public.message_chains.prompt IS '提示';
COMMENT ON COLUMN public.message_chains.tokens IS '令牌数';
COMMENT ON COLUMN public.message_chains.tool_process_data IS '工具处理数据';
COMMENT ON COLUMN public.message_chains.created_at IS '创建时间';
COMMENT ON COLUMN public.message_chains.updated_at IS '更新时间';

-- 模型配置表 - 存储模型配置信息
CREATE TABLE public.model_configurations (
    id uuid NOT NULL,                                           -- 配置唯一标识符
    provider_name public.provider_name NOT NULL,                -- 提供商名称
    model_name character varying(255) NOT NULL,                 -- 模型名称
    model_type public.model_type NOT NULL,                      -- 模型类型
    features public.provider_model_feature[],                   -- 功能
    model_properties jsonb,                                     -- 模型属性
    deprecated boolean DEFAULT false NOT NULL,                  -- 是否废弃
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    credentials jsonb,                                          -- 认证信息
    is_system_provider boolean DEFAULT false NOT NULL           -- 是否系统提供商
);

COMMENT ON TABLE public.model_configurations IS '模型配置表 - 存储模型配置信息';
COMMENT ON COLUMN public.model_configurations.id IS '配置唯一标识符';
COMMENT ON COLUMN public.model_configurations.provider_name IS '提供商名称';
COMMENT ON COLUMN public.model_configurations.model_name IS '模型名称';
COMMENT ON COLUMN public.model_configurations.model_type IS '模型类型';
COMMENT ON COLUMN public.model_configurations.features IS '功能';
COMMENT ON COLUMN public.model_configurations.model_properties IS '模型属性';
COMMENT ON COLUMN public.model_configurations.deprecated IS '是否废弃';
COMMENT ON COLUMN public.model_configurations.created_at IS '创建时间';
COMMENT ON COLUMN public.model_configurations.updated_at IS '更新时间';
COMMENT ON COLUMN public.model_configurations.credentials IS '认证信息';
COMMENT ON COLUMN public.model_configurations.is_system_provider IS '是否系统提供商';

-- 模型提供商表 - 存储模型提供商信息
CREATE TABLE public.model_providers (
    id uuid NOT NULL,                                           -- 提供商唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    provider_name public.provider_name NOT NULL,                -- 提供商名称
    encrypted_config jsonb,                                     -- 加密配置
    is_valid boolean DEFAULT false NOT NULL,                    -- 是否有效
    is_enabled boolean DEFAULT false NOT NULL,                  -- 是否启用
    last_used timestamp with time zone,                         -- 最后使用时间
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.model_providers IS '模型提供商表 - 存储模型提供商信息';
COMMENT ON COLUMN public.model_providers.id IS '提供商唯一标识符';
COMMENT ON COLUMN public.model_providers.tenant_id IS '租户ID';
COMMENT ON COLUMN public.model_providers.provider_name IS '提供商名称';
COMMENT ON COLUMN public.model_providers.encrypted_config IS '加密配置';
COMMENT ON COLUMN public.model_providers.is_valid IS '是否有效';
COMMENT ON COLUMN public.model_providers.is_enabled IS '是否启用';
COMMENT ON COLUMN public.model_providers.last_used IS '最后使用时间';
COMMENT ON COLUMN public.model_providers.created_at IS '创建时间';
COMMENT ON COLUMN public.model_providers.updated_at IS '更新时间';

-- 租户通知表 - 存储租户的通知信息
CREATE TABLE public.notifications (
    id uuid NOT NULL,                                           -- 通知唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    account_id uuid NOT NULL,                                   -- 账户ID
    type public.notification_type NOT NULL,                     -- 通知类型
    status public.notification_status DEFAULT 'unread'::public.notification_status NOT NULL, -- 通知状态
    subject character varying(255) NOT NULL,                    -- 主题
    content text NOT NULL,                                      -- 内容
    meta_data jsonb,                                            -- 元数据
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.notifications IS '租户通知表 - 存储租户的通知信息';
COMMENT ON COLUMN public.notifications.id IS '通知唯一标识符';
COMMENT ON COLUMN public.notifications.tenant_id IS '租户ID';
COMMENT ON COLUMN public.notifications.account_id IS '账户ID';
COMMENT ON COLUMN public.notifications.type IS '通知类型';
COMMENT ON COLUMN public.notifications.status IS '通知状态';
COMMENT ON COLUMN public.notifications.subject IS '主题';
COMMENT ON COLUMN public.notifications.content IS '内容';
COMMENT ON COLUMN public.notifications.meta_data IS '元数据';
COMMENT ON COLUMN public.notifications.created_at IS '创建时间';
COMMENT ON COLUMN public.notifications.updated_at IS '更新时间';

-- 计划表 - 存储订阅计划信息
CREATE TABLE public.plans (
    id uuid NOT NULL,                                           -- 计划唯一标识符
    name character varying(255) NOT NULL,                       -- 计划名称
    type public.plan_type NOT NULL,                             -- 计划类型
    price jsonb,                                                -- 价格
    quota jsonb,                                                -- 配额
    features jsonb,                                             -- 功能
    is_public boolean DEFAULT false NOT NULL,                   -- 是否公开
    is_available boolean DEFAULT true NOT NULL,                 -- 是否可用
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.plans IS '计划表 - 存储订阅计划信息';
COMMENT ON COLUMN public.plans.id IS '计划唯一标识符';
COMMENT ON COLUMN public.plans.name IS '计划名称';
COMMENT ON COLUMN public.plans.type IS '计划类型';
COMMENT ON COLUMN public.plans.price IS '价格';
COMMENT ON COLUMN public.plans.quota IS '配额';
COMMENT ON COLUMN public.plans.features IS '功能';
COMMENT ON COLUMN public.plans.is_public IS '是否公开';
COMMENT ON COLUMN public.plans.is_available IS '是否可用';
COMMENT ON COLUMN public.plans.created_at IS '创建时间';
COMMENT ON COLUMN public.plans.updated_at IS '更新时间';

-- 预留配额表 - 存储预留配额信息
CREATE TABLE public.quota_limits (
    id uuid NOT NULL,                                           -- 配额限制唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    resource character varying(255) NOT NULL,                   -- 资源
    limit_value integer NOT NULL,                               -- 限制值
    period_unit character varying(255) NOT NULL,                -- 周期单位
    period_count integer NOT NULL,                              -- 周期计数
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.quota_limits IS '预留配额表 - 存储预留配额信息';
COMMENT ON COLUMN public.quota_limits.id IS '配额限制唯一标识符';
COMMENT ON COLUMN public.quota_limits.tenant_id IS '租户ID';
COMMENT ON COLUMN public.quota_limits.resource IS '资源';
COMMENT ON COLUMN public.quota_limits.limit_value IS '限制值';
COMMENT ON COLUMN public.quota_limits.period_unit IS '周期单位';
COMMENT ON COLUMN public.quota_limits.period_count IS '周期计数';
COMMENT ON COLUMN public.quota_limits.created_at IS '创建时间';
COMMENT ON COLUMN public.quota_limits.updated_at IS '更新时间';

-- 推荐步骤表 - 存储推荐步骤信息
CREATE TABLE public.recommended_steps (
    id uuid NOT NULL,                                           -- 推荐步骤唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    type public.recommended_step_type NOT NULL,                 -- 步骤类型
    is_completed boolean DEFAULT false NOT NULL,                -- 是否完成
    completed_at timestamp with time zone,                      -- 完成时间
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.recommended_steps IS '推荐步骤表 - 存储推荐步骤信息';
COMMENT ON COLUMN public.recommended_steps.id IS '推荐步骤唯一标识符';
COMMENT ON COLUMN public.recommended_steps.tenant_id IS '租户ID';
COMMENT ON COLUMN public.recommended_steps.type IS '步骤类型';
COMMENT ON COLUMN public.recommended_steps.is_completed IS '是否完成';
COMMENT ON COLUMN public.recommended_steps.completed_at IS '完成时间';
COMMENT ON COLUMN public.recommended_steps.created_at IS '创建时间';
COMMENT ON COLUMN public.recommended_steps.updated_at IS '更新时间';

-- 站点表 - 存储站点配置信息
CREATE TABLE public.sites (
    id uuid NOT NULL,                                           -- 站点唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    title character varying(255) NOT NULL,                      -- 站点标题
    icon character varying(255),                                -- 站点图标
    icon_background character varying(16),                      -- 图标背景
    description text,                                           -- 站点描述
    default_language character varying(16) NOT NULL,            -- 默认语言
    customize_domain character varying(255),                   -- 自定义域名
    default_model jsonb,                                        -- 默认模型
    copyright character varying(255),                           -- 版权信息
    privacy_policy text,                                        -- 隐私政策
    access_mode public.site_access_mode DEFAULT 'invite_only'::public.site_access_mode NOT NULL, -- 访问模式
    status public.site_status DEFAULT 'normal'::public.site_status NOT NULL, -- 站点状态
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.sites IS '站点表 - 存储站点配置信息';
COMMENT ON COLUMN public.sites.id IS '站点唯一标识符';
COMMENT ON COLUMN public.sites.tenant_id IS '租户ID';
COMMENT ON COLUMN public.sites.title IS '站点标题';
COMMENT ON COLUMN public.sites.icon IS '站点图标';
COMMENT ON COLUMN public.sites.icon_background IS '图标背景';
COMMENT ON COLUMN public.sites.description IS '站点描述';
COMMENT ON COLUMN public.sites.default_language IS '默认语言';
COMMENT ON COLUMN public.sites.customize_domain IS '自定义域名';
COMMENT ON COLUMN public.sites.default_model IS '默认模型';
COMMENT ON COLUMN public.sites.copyright IS '版权信息';
COMMENT ON COLUMN public.sites.privacy_policy IS '隐私政策';
COMMENT ON COLUMN public.sites.access_mode IS '访问模式';
COMMENT ON COLUMN public.sites.status IS '站点状态';
COMMENT ON COLUMN public.sites.created_at IS '创建时间';
COMMENT ON COLUMN public.sites.updated_at IS '更新时间';

-- 任务表 - 存储异步任务信息
CREATE TABLE public.tasks (
    id uuid NOT NULL,                                           -- 任务唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    type character varying(255) NOT NULL,                       -- 任务类型
    status public.task_status NOT NULL,                         -- 任务状态
    parameters jsonb,                                           -- 任务参数
    result jsonb,                                               -- 任务结果
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    started_at timestamp with time zone,                        -- 开始时间
    completed_at timestamp with time zone                       -- 完成时间
);

COMMENT ON TABLE public.tasks IS '任务表 - 存储异步任务信息';
COMMENT ON COLUMN public.tasks.id IS '任务唯一标识符';
COMMENT ON COLUMN public.tasks.tenant_id IS '租户ID';
COMMENT ON COLUMN public.tasks.type IS '任务类型';
COMMENT ON COLUMN public.tasks.status IS '任务状态';
COMMENT ON COLUMN public.tasks.parameters IS '任务参数';
COMMENT ON COLUMN public.tasks.result IS '任务结果';
COMMENT ON COLUMN public.tasks.created_at IS '创建时间';
COMMENT ON COLUMN public.tasks.updated_at IS '更新时间';
COMMENT ON COLUMN public.tasks.started_at IS '开始时间';
COMMENT ON COLUMN public.tasks.completed_at IS '完成时间';

-- 租户表 - 存储租户信息
CREATE TABLE public.tenants (
    id uuid NOT NULL,                                           -- 租户唯一标识符
    name character varying(255) NOT NULL,                       -- 租户名称
    plan public.plan_type DEFAULT 'basic'::public.plan_type NOT NULL, -- 计划类型
    status character varying(16) DEFAULT 'normal'::character varying NOT NULL, -- 租户状态
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.tenants IS '租户表 - 存储租户信息';
COMMENT ON COLUMN public.tenants.id IS '租户唯一标识符';
COMMENT ON COLUMN public.tenants.name IS '租户名称';
COMMENT ON COLUMN public.tenants.plan IS '计划类型';
COMMENT ON COLUMN public.tenants.status IS '租户状态';
COMMENT ON COLUMN public.tenants.created_at IS '创建时间';
COMMENT ON COLUMN public.tenants.updated_at IS '更新时间';

-- 租户账户表 - 存储租户与账户的关联关系
CREATE TABLE public.tenant_accounts (
    id uuid NOT NULL,                                           -- 关联唯一标识符
    tenant_id uuid NOT NULL,                                    -- 租户ID
    account_id uuid NOT NULL,                                   -- 账户ID
    role public.tenant_account_role NOT NULL,                   -- 角色
    invited_by uuid,                                            -- 邀请人ID
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL  -- 更新时间
);

COMMENT ON TABLE public.tenant_accounts IS '租户账户表 - 存储租户与账户的关联关系';
COMMENT ON COLUMN public.tenant_accounts.id IS '关联唯一标识符';
COMMENT ON COLUMN public.tenant_accounts.tenant_id IS '租户ID';
COMMENT ON COLUMN public.tenant_accounts.account_id IS '账户ID';
COMMENT ON COLUMN public.tenant_accounts.role IS '角色';
COMMENT ON COLUMN public.tenant_accounts.invited_by IS '邀请人ID';
COMMENT ON COLUMN public.tenant_accounts.created_at IS '创建时间';
COMMENT ON COLUMN public.tenant_accounts.updated_at IS '更新时间';

-- 工作流节点执行表 - 存储工作流节点执行信息
CREATE TABLE public.workflow_node_executions (
    id uuid NOT NULL,                                           -- 节点执行唯一标识符
    workflow_run_id uuid NOT NULL,                              -- 工作流运行ID
    node_id character varying(255) NOT NULL,                    -- 节点ID
    node_type character varying(255) NOT NULL,                  -- 节点类型
    node_config jsonb,                                          -- 节点配置
    status public.workflow_node_execution_status NOT NULL,      -- 执行状态
    error jsonb,                                                -- 错误信息
    inputs jsonb,                                               -- 输入
    outputs jsonb,                                              -- 输出
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    started_at timestamp with time zone,                        -- 开始时间
    completed_at timestamp with time zone                       -- 完成时间
);

COMMENT ON TABLE public.workflow_node_executions IS '工作流节点执行表 - 存储工作流节点执行信息';
COMMENT ON COLUMN public.workflow_node_executions.id IS '节点执行唯一标识符';
COMMENT ON COLUMN public.workflow_node_executions.workflow_run_id IS '工作流运行ID';
COMMENT ON COLUMN public.workflow_node_executions.node_id IS '节点ID';
COMMENT ON COLUMN public.workflow_node_executions.node_type IS '节点类型';
COMMENT ON COLUMN public.workflow_node_executions.node_config IS '节点配置';
COMMENT ON COLUMN public.workflow_node_executions.status IS '执行状态';
COMMENT ON COLUMN public.workflow_node_executions.error IS '错误信息';
COMMENT ON COLUMN public.workflow_node_executions.inputs IS '输入';
COMMENT ON COLUMN public.workflow_node_executions.outputs IS '输出';
COMMENT ON COLUMN public.workflow_node_executions.created_at IS '创建时间';
COMMENT ON COLUMN public.workflow_node_executions.updated_at IS '更新时间';
COMMENT ON COLUMN public.workflow_node_executions.started_at IS '开始时间';
COMMENT ON COLUMN public.workflow_node_executions.completed_at IS '完成时间';

-- 工作流运行表 - 存储工作流运行信息
CREATE TABLE public.workflow_runs (
    id uuid NOT NULL,                                           -- 运行唯一标识符
    workflow_id uuid NOT NULL,                                  -- 工作流ID
    trigger_from character varying(16) NOT NULL,                -- 触发来源
    version integer NOT NULL,                                   -- 版本
    graph jsonb,                                                -- 图
    inputs jsonb,                                               -- 输入
    status public.workflow_run_status NOT NULL,                 -- 运行状态
    error jsonb,                                                -- 错误信息
    outputs jsonb,                                              -- 输出
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 创建时间
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL, -- 更新时间
    started_at timestamp with time zone,                        -- 开始时间
    completed_at timestamp with time zone                       -- 完成时间
);

COMMENT ON TABLE public.workflow_runs IS '工作流运行表 - 存储工作流运行信息';
COMMENT ON COLUMN public.workflow_runs.id IS '运行唯一标识符';
COMMENT ON COLUMN public.workflow_runs.workflow_id IS '工作流ID';
COMMENT ON COLUMN public.workflow_runs.trigger_from IS '触发来源';
COMMENT ON COLUMN public.workflow_runs.version IS '版本';
COMMENT ON COLUMN public.workflow_runs.graph IS '图';
COMMENT ON COLUMN public.workflow_runs.inputs IS '输入';
COMMENT ON COLUMN public.workflow_runs.status IS '运行状态';
COMMENT ON COLUMN public.workflow_runs.error IS '错误信息';
COMMENT ON COLUMN public.workflow_runs.outputs IS '输出';
COMMENT ON COLUMN public.workflow_runs.created_at IS '创建时间';
COMMENT ON COLUMN public.workflow_runs.updated_at IS '更新时间';
COMMENT ON COLUMN public.workflow_runs.started_at IS '开始时间';
COMMENT ON COLUMN public.workflow_runs.completed_at IS '完成时间';

-- 添加主键约束
ALTER TABLE ONLY public.accounts ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.api_requests ADD CONSTRAINT api_requests_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.app_annotations ADD CONSTRAINT app_annotations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.app_annotation_settings ADD CONSTRAINT app_annotation_settings_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.app_model_configs ADD CONSTRAINT app_model_configs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.app_model_config_versions ADD CONSTRAINT app_model_config_versions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.app_operation_logs ADD CONSTRAINT app_operation_logs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.apps ADD CONSTRAINT apps_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.apps_old ADD CONSTRAINT apps_old_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.billing_subscriptions ADD CONSTRAINT billing_subscriptions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.component_credentials ADD CONSTRAINT component_credentials_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.conversation_messages ADD CONSTRAINT conversation_messages_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.conversations ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.dataset_document_index_tasks ADD CONSTRAINT dataset_document_index_tasks_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.dataset_documents ADD CONSTRAINT dataset_documents_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.dataset_entities ADD CONSTRAINT dataset_entities_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.dataset_keyword_index_segments ADD CONSTRAINT dataset_keyword_index_segments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.dataset_process_rules ADD CONSTRAINT dataset_process_rules_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.dataset_queries ADD CONSTRAINT dataset_queries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.dataset_related_apps ADD CONSTRAINT dataset_related_apps_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.datasets ADD CONSTRAINT datasets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.datasets_old ADD CONSTRAINT datasets_old_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.document_segments ADD CONSTRAINT document_segments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.domain_white_lists ADD CONSTRAINT domain_white_lists_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.ended_at_notifications ADD CONSTRAINT ended_at_notifications_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.events ADD CONSTRAINT events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.file_keys ADD CONSTRAINT file_keys_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.installed_apps ADD CONSTRAINT installed_apps_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.invited_accounts ADD CONSTRAINT invited_accounts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.message_agent_thoughts ADD CONSTRAINT message_agent_thoughts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.message_chains ADD CONSTRAINT message_chains_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.model_configurations ADD CONSTRAINT model_configurations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.model_providers ADD CONSTRAINT model_providers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.notifications ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.plans ADD CONSTRAINT plans_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.quota_limits ADD CONSTRAINT quota_limits_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.recommended_steps ADD CONSTRAINT recommended_steps_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.sites ADD CONSTRAINT sites_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.tasks ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.tenants ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.tenant_accounts ADD CONSTRAINT tenant_accounts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.workflow_node_executions ADD CONSTRAINT workflow_node_executions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.workflow_runs ADD CONSTRAINT workflow_runs_pkey PRIMARY KEY (id);

-- 添加唯一约束
ALTER TABLE ONLY public.accounts ADD CONSTRAINT accounts_email_key UNIQUE (email);
ALTER TABLE ONLY public.apps ADD CONSTRAINT apps_name_tenant_id_key UNIQUE (name, tenant_id);
ALTER TABLE ONLY public.datasets ADD CONSTRAINT datasets_name_tenant_id_key UNIQUE (name, tenant_id);
ALTER TABLE ONLY public.sites ADD CONSTRAINT sites_tenant_id_key UNIQUE (tenant_id);

-- 添加外键约束
ALTER TABLE ONLY public.accounts ADD CONSTRAINT accounts_invite_from_account_id_fkey FOREIGN KEY (invite_from_account_id) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.api_requests ADD CONSTRAINT api_requests_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(id);
ALTER TABLE ONLY public.api_requests ADD CONSTRAINT api_requests_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.app_annotations ADD CONSTRAINT app_annotations_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(id);
ALTER TABLE ONLY public.app_annotations ADD CONSTRAINT app_annotations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.app_annotations ADD CONSTRAINT app_annotations_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.app_annotation_settings ADD CONSTRAINT app_annotation_settings_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(id);
ALTER TABLE ONLY public.app_model_configs ADD CONSTRAINT app_model_configs_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(id);
ALTER TABLE ONLY public.app_model_config_versions ADD CONSTRAINT app_model_config_versions_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(id);
ALTER TABLE ONLY public.app_model_config_versions ADD CONSTRAINT app_model_config_versions_app_model_config_id_fkey FOREIGN KEY (app_model_config_id) REFERENCES public.app_model_configs(id);
ALTER TABLE ONLY public.app_operation_logs ADD CONSTRAINT app_operation_logs_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.app_operation_logs ADD CONSTRAINT app_operation_logs_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(id);
ALTER TABLE ONLY public.apps ADD CONSTRAINT apps_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.billing_subscriptions ADD CONSTRAINT billing_subscriptions_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.component_credentials ADD CONSTRAINT component_credentials_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.conversation_messages ADD CONSTRAINT conversation_messages_account_id_fkey FOREIGN KEY (from_account_id) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.conversation_messages ADD CONSTRAINT conversation_messages_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(id);
ALTER TABLE ONLY public.conversation_messages ADD CONSTRAINT conversation_messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);
ALTER TABLE ONLY public.conversation_messages ADD CONSTRAINT conversation_messages_end_user_id_fkey FOREIGN KEY (from_end_user_id) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.conversations ADD CONSTRAINT conversations_account_id_fkey FOREIGN KEY (from_account_id) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.conversations ADD CONSTRAINT conversations_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(id);
ALTER TABLE ONLY public.conversations ADD CONSTRAINT conversations_app_model_config_id_fkey FOREIGN KEY (app_model_config_id) REFERENCES public.app_model_configs(id);
ALTER TABLE ONLY public.conversations ADD CONSTRAINT conversations_end_user_id_fkey FOREIGN KEY (from_end_user_id) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.dataset_document_index_tasks ADD CONSTRAINT dataset_document_index_tasks_dataset_document_id_fkey FOREIGN KEY (dataset_document_id) REFERENCES public.dataset_documents(id);
ALTER TABLE ONLY public.dataset_documents ADD CONSTRAINT dataset_documents_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.datasets(id);
ALTER TABLE ONLY public.dataset_documents ADD CONSTRAINT dataset_documents_dataset_process_rule_id_fkey FOREIGN KEY (dataset_process_rule_id) REFERENCES public.dataset_process_rules(id);
ALTER TABLE ONLY public.dataset_documents ADD CONSTRAINT dataset_documents_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.dataset_entities ADD CONSTRAINT dataset_entities_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.datasets(id);
ALTER TABLE ONLY public.dataset_keyword_index_segments ADD CONSTRAINT dataset_keyword_index_segments_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.datasets(id);
ALTER TABLE ONLY public.dataset_keyword_index_segments ADD CONSTRAINT dataset_keyword_index_segments_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.dataset_documents(id);
ALTER TABLE ONLY public.dataset_process_rules ADD CONSTRAINT dataset_process_rules_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.dataset_process_rules ADD CONSTRAINT dataset_process_rules_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.datasets(id);
ALTER TABLE ONLY public.dataset_process_rules ADD CONSTRAINT dataset_process_rules_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.dataset_queries ADD CONSTRAINT dataset_queries_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.dataset_queries ADD CONSTRAINT dataset_queries_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.datasets(id);
ALTER TABLE ONLY public.dataset_related_apps ADD CONSTRAINT dataset_related_apps_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(id);
ALTER TABLE ONLY public.dataset_related_apps ADD CONSTRAINT dataset_related_apps_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.datasets(id);
ALTER TABLE ONLY public.datasets ADD CONSTRAINT datasets_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.datasets ADD CONSTRAINT datasets_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.document_segments ADD CONSTRAINT document_segments_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES public.datasets(id);
ALTER TABLE ONLY public.document_segments ADD CONSTRAINT document_segments_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.dataset_documents(id);
ALTER TABLE ONLY public.domain_white_lists ADD CONSTRAINT domain_white_lists_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.ended_at_notifications ADD CONSTRAINT ended_at_notifications_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.ended_at_notifications ADD CONSTRAINT ended_at_notifications_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.events ADD CONSTRAINT events_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.events ADD CONSTRAINT events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.file_keys ADD CONSTRAINT file_keys_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.installed_apps ADD CONSTRAINT installed_apps_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(id);
ALTER TABLE ONLY public.installed_apps ADD CONSTRAINT installed_apps_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.invited_accounts ADD CONSTRAINT invited_accounts_inviter_account_id_fkey FOREIGN KEY (inviter_account_id) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.invited_accounts ADD CONSTRAINT invited_accounts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.message_agent_thoughts ADD CONSTRAINT message_agent_thoughts_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.conversation_messages(id);
ALTER TABLE ONLY public.message_chains ADD CONSTRAINT message_chains_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.conversation_messages(id);
ALTER TABLE ONLY public.model_providers ADD CONSTRAINT model_providers_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.notifications ADD CONSTRAINT notifications_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.notifications ADD CONSTRAINT notifications_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.quota_limits ADD CONSTRAINT quota_limits_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.recommended_steps ADD CONSTRAINT recommended_steps_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.sites ADD CONSTRAINT sites_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.tasks ADD CONSTRAINT tasks_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.tenant_accounts ADD CONSTRAINT tenant_accounts_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.tenant_accounts ADD CONSTRAINT tenant_accounts_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.accounts(id);
ALTER TABLE ONLY public.tenant_accounts ADD CONSTRAINT tenant_accounts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id);
ALTER TABLE ONLY public.workflow_node_executions ADD CONSTRAINT workflow_node_executions_workflow_run_id_fkey FOREIGN KEY (workflow_run_id) REFERENCES public.workflow_runs(id);
ALTER TABLE ONLY public.workflow_runs ADD CONSTRAINT workflow_runs_workflow
-- Dify数据库表结构定义 (第四部分)
-- 包含索引和所有权设置

-- 添加索引
CREATE INDEX idx_accounts_email ON public.accounts USING btree (email);
CREATE INDEX idx_api_requests_tenant_id ON public.api_requests USING btree (tenant_id);
CREATE INDEX idx_api_requests_app_id ON public.api_requests USING btree (app_id);
CREATE INDEX idx_app_annotations_app_id ON public.app_annotations USING btree (app_id);
CREATE INDEX idx_app_annotations_created_by ON public.app_annotations USING btree (created_by);
CREATE INDEX idx_app_annotation_settings_app_id ON public.app_annotation_settings USING btree (app_id);
CREATE INDEX idx_app_model_configs_app_id ON public.app_model_configs USING btree (app_id);
CREATE INDEX idx_app_model_config_versions_app_id ON public.app_model_config_versions USING btree (app_id);
CREATE INDEX idx_app_model_config_versions_app_model_config_id ON public.app_model_config_versions USING btree (app_model_config_id);
CREATE INDEX idx_app_operation_logs_app_id ON public.app_operation_logs USING btree (app_id);
CREATE INDEX idx_app_operation_logs_account_id ON public.app_operation_logs USING btree (account_id);
CREATE INDEX idx_apps_tenant_id ON public.apps USING btree (tenant_id);
CREATE INDEX idx_billing_subscriptions_tenant_id ON public.billing_subscriptions USING btree (tenant_id);
CREATE INDEX idx_component_credentials_tenant_id ON public.component_credentials USING btree (tenant_id);
CREATE INDEX idx_conversation_messages_conversation_id ON public.conversation_messages USING btree (conversation_id);
CREATE INDEX idx_conversation_messages_app_id ON public.conversation_messages USING btree (app_id);
CREATE INDEX idx_conversation_messages_account_id ON public.conversation_messages USING btree (from_account_id);
CREATE INDEX idx_conversations_app_id ON public.conversations USING btree (app_id);
CREATE INDEX idx_conversations_account_id ON public.conversations USING btree (from_account_id);
CREATE INDEX idx_dataset_document_index_tasks_dataset_doc_id ON public.dataset_document_index_tasks USING btree (dataset_document_id);
CREATE INDEX idx_dataset_documents_dataset_id ON public.dataset_documents USING btree (dataset_id);
CREATE INDEX idx_dataset_documents_created_by ON public.dataset_documents USING btree (created_by);
CREATE INDEX idx_dataset_entities_dataset_id ON public.dataset_entities USING btree (dataset_id);
CREATE INDEX idx_dataset_keyword_index_segments_dataset_id ON public.dataset_keyword_index_segments USING btree (dataset_id);
CREATE INDEX idx_dataset_keyword_index_segments_document_id ON public.dataset_keyword_index_segments USING btree (document_id);
CREATE INDEX idx_dataset_process_rules_dataset_id ON public.dataset_process_rules USING btree (dataset_id);
CREATE INDEX idx_dataset_process_rules_created_by ON public.dataset_process_rules USING btree (created_by);
CREATE INDEX idx_dataset_queries_dataset_id ON public.dataset_queries USING btree (dataset_id);
CREATE INDEX idx_dataset_queries_created_by ON public.dataset_queries USING btree (created_by);
CREATE INDEX idx_dataset_related_apps_app_id ON public.dataset_related_apps USING btree (app_id);
CREATE INDEX idx_dataset_related_apps_dataset_id ON public.dataset_related_apps USING btree (dataset_id);
CREATE INDEX idx_datasets_tenant_id ON public.datasets USING btree (tenant_id);
CREATE INDEX idx_datasets_created_by ON public.datasets USING btree (created_by);
CREATE INDEX idx_document_segments_dataset_id ON public.document_segments USING btree (dataset_id);
CREATE INDEX idx_document_segments_document_id ON public.document_segments USING btree (document_id);
CREATE INDEX idx_domain_white_lists_tenant_id ON public.domain_white_lists USING btree (tenant_id);
CREATE INDEX idx_ended_at_notifications_tenant_id ON public.ended_at_notifications USING btree (tenant_id);
CREATE INDEX idx_ended_at_notifications_account_id ON public.ended_at_notifications USING btree (account_id);
CREATE INDEX idx_events_tenant_id ON public.events USING btree (tenant_id);
CREATE INDEX idx_events_account_id ON public.events USING btree (account_id);
CREATE INDEX idx_file_keys_tenant_id ON public.file_keys USING btree (tenant_id);
CREATE INDEX idx_installed_apps_tenant_id ON public.installed_apps USING btree (tenant_id);
CREATE INDEX idx_installed_apps_app_id ON public.installed_apps USING btree (app_id);
CREATE INDEX idx_invited_accounts_tenant_id ON public.invited_accounts USING btree (tenant_id);
CREATE INDEX idx_invited_accounts_inviter_account_id ON public.invited_accounts USING btree (inviter_account_id);
CREATE INDEX idx_message_agent_thoughts_message_id ON public.message_agent_thoughts USING btree (message_id);
CREATE INDEX idx_message_chains_message_id ON public.message_chains USING btree (message_id);
CREATE INDEX idx_model_providers_tenant_id ON public.model_providers USING btree (tenant_id);
CREATE INDEX idx_notifications_tenant_id ON public.notifications USING btree (tenant_id);
CREATE INDEX idx_notifications_account_id ON public.notifications USING btree (account_id);
CREATE INDEX idx_quota_limits_tenant_id ON public.quota_limits USING btree (tenant_id);
CREATE INDEX idx_recommended_steps_tenant_id ON public.recommended_steps USING btree (tenant_id);
CREATE INDEX idx_sites_tenant_id ON public.sites USING btree (tenant_id);
CREATE INDEX idx_tasks_tenant_id ON public.tasks USING btree (tenant_id);
CREATE INDEX idx_tenant_accounts_tenant_id ON public.tenant_accounts USING btree (tenant_id);
CREATE INDEX idx_tenant_accounts_account_id ON public.tenant_accounts USING btree (account_id);
CREATE INDEX idx_workflow_node_executions_workflow_run_id ON public.workflow_node_executions USING btree (workflow_run_id);
CREATE INDEX idx_workflow_runs_workflow_id ON public.workflow_runs USING btree (workflow_id);

-- 设置表所有权
ALTER TABLE public.accounts OWNER TO root;
ALTER TABLE public.api_requests OWNER TO root;
ALTER TABLE public.app_annotations OWNER TO root;
ALTER TABLE public.app_annotation_settings OWNER TO root;
ALTER TABLE public.app_model_configs OWNER TO root;
ALTER TABLE public.app_model_config_versions OWNER TO root;
ALTER TABLE public.app_operation_logs OWNER TO root;
ALTER TABLE public.apps OWNER TO root;
ALTER TABLE public.apps_old OWNER TO root;
ALTER TABLE public.billing_subscriptions OWNER TO root;
ALTER TABLE public.component_credentials OWNER TO root;
ALTER TABLE public.conversation_messages OWNER TO root;
ALTER TABLE public.conversations OWNER TO root;
ALTER TABLE public.dataset_document_index_tasks OWNER TO root;
ALTER TABLE public.dataset_documents OWNER TO root;
ALTER TABLE public.dataset_entities OWNER TO root;
ALTER TABLE public.dataset_keyword_index_segments OWNER TO root;
ALTER TABLE public.dataset_process_rules OWNER TO root;
ALTER TABLE public.dataset_queries OWNER TO root;
ALTER TABLE public.dataset_related_apps OWNER TO root;
ALTER TABLE public.datasets OWNER TO root;
ALTER TABLE public.datasets_old OWNER TO root;
ALTER TABLE public.document_segments OWNER TO root;
ALTER TABLE public.domain_white_lists OWNER TO root;
ALTER TABLE public.ended_at_notifications OWNER TO root;
ALTER TABLE public.events OWNER TO root;
ALTER TABLE public.file_keys OWNER TO root;
ALTER TABLE public.installed_apps OWNER TO root;
ALTER TABLE public.invited_accounts OWNER TO root;
ALTER TABLE public.message_agent_thoughts OWNER TO root;
ALTER TABLE public.message_chains OWNER TO root;
ALTER TABLE public.model_configurations OWNER TO root;
ALTER TABLE public.model_providers OWNER TO root;
ALTER TABLE public.notifications OWNER TO root;
ALTER TABLE public.plans OWNER TO root;
ALTER TABLE public.quota_limits OWNER TO root;
ALTER TABLE public.recommended_steps OWNER TO root;
ALTER TABLE public.sites OWNER TO root;
ALTER TABLE public.tasks OWNER TO root;
ALTER TABLE public.tenants OWNER TO root;
ALTER TABLE public.tenant_accounts OWNER TO root;
ALTER TABLE public.workflow_node_executions OWNER TO root;
ALTER TABLE public.workflow_runs OWNER TO root;

-- 完整的Dify数据库表结构定义结束
