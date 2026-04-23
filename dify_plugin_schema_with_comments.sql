-- Database: dify_plugin
-- Dify插件系统数据库表结构定义

-- 删除数据库（如存在）
-- DROP DATABASE dify_plugin;

-- 创建数据库
CREATE DATABASE dify_plugin WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';

-- 设置客户端编码
SET client_encoding = 'UTF8';
SET standard_conforming_strings = 'on';
SELECT pg_catalog.set_config('search_path', '', false);

--
-- 表: agent_strategy_installations - 代理策略安装记录表
-- 用途: 记录代理策略类型的插件安装信息
--
CREATE TABLE public.agent_strategy_installations (
    id uuid NOT NULL,                           -- 主键: 记录唯一标识符
    created_at timestamp with time zone,        -- 创建时间: 记录创建的时间戳
    updated_at timestamp with time zone,        -- 更新时间: 记录最后更新的时间戳
    tenant_id uuid NOT NULL,                   -- 租户ID: 所属租户的唯一标识符
    provider character varying(127) NOT NULL,  -- 提供商: 插件提供商名称
    plugin_unique_identifier character varying(255), -- 插件唯一标识符: 插件的唯一标识
    plugin_id character varying(255)            -- 插件ID: 插件的内部ID
);

--
-- 表: ai_model_installations - AI模型安装记录表
-- 用途: 记录AI模型类型的插件安装信息
--
CREATE TABLE public.ai_model_installations (
    id uuid NOT NULL,                           -- 主键: 记录唯一标识符
    created_at timestamp with time zone,        -- 创建时间: 记录创建的时间戳
    updated_at timestamp with time zone,        -- 更新时间: 记录最后更新的时间戳
    provider character varying(127) NOT NULL,  -- 提供商: AI模型提供商名称
    tenant_id uuid NOT NULL,                   -- 租户ID: 所属租户的唯一标识符
    plugin_unique_identifier character varying(255), -- 插件唯一标识符: 插件的唯一标识
    plugin_id character varying(255)            -- 插件ID: 插件的内部ID
);

--
-- 表: datasource_installations - 数据源安装记录表
-- 用途: 记录数据源类型的插件安装信息
--
CREATE TABLE public.datasource_installations (
    id uuid NOT NULL,                           -- 主键: 记录唯一标识符
    created_at timestamp with time zone,        -- 创建时间: 记录创建的时间戳
    updated_at timestamp with time zone,        -- 更新时间: 记录最后更新的时间戳
    tenant_id uuid NOT NULL,                   -- 租户ID: 所属租户的唯一标识符
    provider character varying(127) NOT NULL,  -- 提供商: 数据源提供商名称
    plugin_unique_identifier character varying(255), -- 插件唯一标识符: 插件的唯一标识
    plugin_id character varying(255)            -- 插件ID: 插件的内部ID
);

--
-- 表: endpoints - 端点信息表
-- 用途: 存储插件端点的配置信息
--
CREATE TABLE public.endpoints (
    id uuid NOT NULL,                           -- 主键: 记录唯一标识符
    created_at timestamp with time zone,        -- 创建时间: 记录创建的时间戳
    updated_at timestamp with time zone,        -- 更新时间: 记录最后更新的时间戳
    name character varying(127) DEFAULT 'default'::character varying, -- 名称: 端点名称，默认为'default'
    hook_id character varying(127),             -- 钩子ID: 用于标识特定钩子的ID
    tenant_id character varying(64),           -- 租户ID: 所属租户的标识符
    user_id character varying(64),             -- 用户ID: 所属用户的标识符
    plugin_id character varying(64),           -- 插件ID: 关联插件的ID
    expired_at timestamp with time zone,       -- 过期时间: 端点过期时间
    enabled boolean,                           -- 启用状态: 是否启用该端点
    settings text                              -- 设置: 端点的详细配置信息
);

--
-- 表: install_tasks - 安装任务记录表
-- 用途: 记录插件批量安装任务的状态信息
--
CREATE TABLE public.install_tasks (
    id uuid NOT NULL,                           -- 主键: 记录唯一标识符
    created_at timestamp with time zone,        -- 创建时间: 记录创建的时间戳
    updated_at timestamp with time zone,        -- 更新时间: 记录最后更新的时间戳
    status text NOT NULL,                      -- 状态: 安装任务当前状态
    tenant_id uuid NOT NULL,                   -- 租户ID: 所属租户的唯一标识符
    total_plugins bigint NOT NULL,             -- 总插件数: 需要安装的插件总数
    completed_plugins bigint NOT NULL,         -- 已完成插件数: 已成功安装的插件数量
    plugins text                               -- 插件列表: 参与安装的插件信息
);

--
-- 表: plugin_declarations - 插件声明表
-- 用途: 存储插件的声明信息
--
CREATE TABLE public.plugin_declarations (
    id uuid NOT NULL,                           -- 主键: 记录唯一标识符
    created_at timestamp with time zone,        -- 创建时间: 记录创建的时间戳
    updated_at timestamp with time zone,        -- 更新时间: 记录最后更新的时间戳
    plugin_unique_identifier character varying(255), -- 插件唯一标识符: 插件的唯一标识
    plugin_id character varying(255),          -- 插件ID: 插件的内部ID
    declaration text                           -- 声明: 插件的详细声明内容
);

--
-- 表: plugin_installations - 插件安装记录表
-- 用途: 记录插件的安装状态和配置信息
--
CREATE TABLE public.plugin_installations (
    id uuid NOT NULL,                           -- 主键: 记录唯一标识符
    created_at timestamp with time zone,        -- 创建时间: 记录创建的时间戳
    updated_at timestamp with time zone,        -- 更新时间: 记录最后更新的时间戳
    tenant_id uuid,                            -- 租户ID: 所属租户的唯一标识符
    plugin_id character varying(255),          -- 插件ID: 插件的内部ID
    plugin_unique_identifier character varying(255), -- 插件唯一标识符: 插件的唯一标识
    runtime_type character varying(127),       -- 运行时类型: 插件运行时类型
    endpoints_setups bigint,                   -- 端点设置数: 已设置的端点数量
    endpoints_active bigint,                   -- 活跃端点数: 当前活跃的端点数量
    source character varying(63),              -- 来源: 插件来源渠道
    meta text                                  -- 元数据: 插件的额外元信息
);

--
-- 表: plugin_readme_records - 插件说明文档记录表
-- 用途: 存储插件的README文档内容
--
CREATE TABLE public.plugin_readme_records (
    id uuid NOT NULL,                           -- 主键: 记录唯一标识符
    created_at timestamp with time zone,        -- 创建时间: 记录创建的时间戳
    updated_at timestamp with time zone,        -- 更新时间: 记录最后更新的时间戳
    plugin_unique_identifier character varying(255) NOT NULL, -- 插件唯一标识符: 插件的唯一标识
    language character varying(10) NOT NULL,   -- 语言: 文档的语言代码
    content text NOT NULL                       -- 内容: README文档的具体内容
);

--
-- 表: plugins - 插件基本信息表
-- 用途: 存储插件的基本信息和统计
--
CREATE TABLE public.plugins (
    id uuid NOT NULL,                           -- 主键: 记录唯一标识符
    created_at timestamp with time zone,        -- 创建时间: 记录创建的时间戳
    updated_at timestamp with time zone,        -- 更新时间: 记录最后更新的时间戳
    plugin_unique_identifier character varying(255), -- 插件唯一标识符: 插件的唯一标识
    plugin_id character varying(255),          -- 插件ID: 插件的内部ID
    refers bigint DEFAULT 0,                   -- 引用数: 插件被引用或使用的次数
    install_type character varying(127),       -- 安装类型: 插件的安装方式类型
    manifest_type character varying(127),      -- 清单类型: 插件清单的类型
    remote_declaration text,                   -- 远程声明: 远程插件的声明信息
    source character varying(63) DEFAULT ''::character varying -- 来源: 插件来源渠道，默认为空字符串
);

--
-- 表: serverless_runtimes - 无服务器运行时表
-- 用途: 存储插件的无服务器运行时配置
--
CREATE TABLE public.serverless_runtimes (
    id uuid NOT NULL,                           -- 主键: 记录唯一标识符
    created_at timestamp with time zone,        -- 创建时间: 记录创建的时间戳
    updated_at timestamp with time zone,        -- 更新时间: 记录最后更新的时间戳
    plugin_unique_identifier character varying(255), -- 插件唯一标识符: 插件的唯一标识
    function_url character varying(255),       -- 函数URL: 无服务器函数的访问URL
    function_name character varying(127),      -- 函数名称: 无服务器函数的名称
    type character varying(127),               -- 类型: 运行时类型
    checksum character varying(127)            -- 校验和: 运行时文件的校验和
);

--
-- 表: tenant_storages - 租户存储信息表
-- 用途: 记录各租户的插件存储使用情况
--
CREATE TABLE public.tenant_storages (
    id uuid NOT NULL,                           -- 主键: 记录唯一标识符
    created_at timestamp with time zone,        -- 创建时间: 记录创建的时间戳
    updated_at timestamp with time zone,        -- 更新时间: 记录最后更新的时间戳
    tenant_id character varying(255) NOT NULL, -- 租户ID: 租户的唯一标识符
    plugin_id character varying(255) NOT NULL, -- 插件ID: 插件的唯一标识符
    size bigint NOT NULL                        -- 大小: 存储使用的大小（字节）
);

--
-- 表: tool_installations - 工具安装记录表
-- 用途: 记录工具类型插件的安装信息
--
CREATE TABLE public.tool_installations (
    id uuid NOT NULL,                           -- 主键: 记录唯一标识符
    created_at timestamp with time zone,        -- 创建时间: 记录创建的时间戳
    updated_at timestamp with time zone,        -- 更新时间: 记录最后更新的时间戳
    tenant_id uuid NOT NULL,                   -- 租户ID: 所属租户的唯一标识符
    provider character varying(127) NOT NULL,  -- 提供商: 工具提供商名称
    plugin_unique_identifier character varying(255), -- 插件唯一标识符: 插件的唯一标识
    plugin_id character varying(255)            -- 插件ID: 插件的内部ID
);

--
-- 表: trigger_installations - 触发器安装记录表
-- 用途: 记录触发器类型插件的安装信息
--
CREATE TABLE public.trigger_installations (
    id uuid NOT NULL,                           -- 主键: 记录唯一标识符
    created_at timestamp with time zone,        -- 创建时间: 记录创建的时间戳
    updated_at timestamp with time zone,        -- 更新时间: 记录最后更新的时间戳
    tenant_id uuid NOT NULL,                   -- 租户ID: 所属租户的唯一标识符
    provider character varying(127) NOT NULL,  -- 提供商: 触发器提供商名称
    plugin_unique_identifier character varying(255), -- 插件唯一标识符: 插件的唯一标识
    plugin_id character varying(255)            -- 插件ID: 插件的内部ID
);

-- 添加主键约束
ALTER TABLE ONLY public.agent_strategy_installations ADD CONSTRAINT agent_strategy_installations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.ai_model_installations ADD CONSTRAINT ai_model_installations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.datasource_installations ADD CONSTRAINT datasource_installations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.endpoints ADD CONSTRAINT endpoints_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.install_tasks ADD CONSTRAINT install_tasks_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.plugin_declarations ADD CONSTRAINT plugin_declarations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.plugin_installations ADD CONSTRAINT plugin_installations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.plugin_readme_records ADD CONSTRAINT plugin_readme_records_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.plugins ADD CONSTRAINT plugins_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.serverless_runtimes ADD CONSTRAINT serverless_runtimes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.tenant_storages ADD CONSTRAINT tenant_storages_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.tool_installations ADD CONSTRAINT tool_installations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.trigger_installations ADD CONSTRAINT trigger_installations_pkey PRIMARY KEY (id);

-- 添加唯一约束
ALTER TABLE ONLY public.endpoints ADD CONSTRAINT uni_endpoints_hook_id UNIQUE (hook_id);
ALTER TABLE ONLY public.plugin_declarations ADD CONSTRAINT uni_plugin_declarations_plugin_unique_identifier UNIQUE (plugin_unique_identifier);
ALTER TABLE ONLY public.serverless_runtimes ADD CONSTRAINT uni_serverless_runtimes_plugin_unique_identifier UNIQUE (plugin_unique_identifier);

-- 添加索引
CREATE INDEX idx_agent_strategy_installations_plugin_id ON public.agent_strategy_installations USING btree (plugin_id);
CREATE INDEX idx_agent_strategy_installations_plugin_unique_identifier ON public.agent_strategy_installations USING btree (plugin_unique_identifier);
CREATE INDEX idx_agent_strategy_installations_provider ON public.agent_strategy_installations USING btree (provider);
CREATE INDEX idx_agent_strategy_installations_tenant_id ON public.agent_strategy_installations USING btree (tenant_id);

CREATE INDEX idx_ai_model_installations_plugin_id ON public.ai_model_installations USING btree (plugin_id);
CREATE INDEX idx_ai_model_installations_plugin_unique_identifier ON public.ai_model_installations USING btree (plugin_unique_identifier);
CREATE INDEX idx_ai_model_installations_provider ON public.ai_model_installations USING btree (provider);
CREATE INDEX idx_ai_model_installations_tenant_id ON public.ai_model_installations USING btree (tenant_id);

CREATE INDEX idx_datasource_installations_plugin_id ON public.datasource_installations USING btree (plugin_id);
CREATE INDEX idx_datasource_installations_plugin_unique_identifier ON public.datasource_installations USING btree (plugin_unique_identifier);
CREATE INDEX idx_datasource_installations_provider ON public.datasource_installations USING btree (provider);
CREATE INDEX idx_datasource_installations_tenant_id ON public.datasource_installations USING btree (tenant_id);

CREATE INDEX idx_endpoints_plugin_id ON public.endpoints USING btree (plugin_id);
CREATE INDEX idx_endpoints_tenant_id ON public.endpoints USING btree (tenant_id);
CREATE INDEX idx_endpoints_user_id ON public.endpoints USING btree (user_id);

CREATE INDEX idx_plugin_declarations_plugin_id ON public.plugin_declarations USING btree (plugin_id);
CREATE INDEX idx_plugin_installations_plugin_id ON public.plugin_installations USING btree (plugin_id);
CREATE INDEX idx_plugin_installations_plugin_unique_identifier ON public.plugin_installations USING btree (plugin_unique_identifier);
CREATE INDEX idx_plugin_installations_tenant_id ON public.plugin_installations USING btree (tenant_id);
CREATE UNIQUE INDEX idx_tenant_plugin ON public.plugin_installations USING btree (tenant_id, plugin_id);

CREATE INDEX idx_plugin_readme_records_plugin_unique_identifier ON public.plugin_readme_records USING btree (plugin_unique_identifier);

CREATE INDEX idx_plugins_install_type ON public.plugins USING btree (install_type);
CREATE INDEX idx_plugins_plugin_id ON public.plugins USING btree (plugin_id);
CREATE INDEX idx_plugins_plugin_unique_identifier ON public.plugins USING btree (plugin_unique_identifier);

CREATE INDEX idx_serverless_runtimes_checksum ON public.serverless_runtimes USING btree (checksum);

CREATE INDEX idx_tenant_storages_plugin_id ON public.tenant_storages USING btree (plugin_id);
CREATE INDEX idx_tenant_storages_tenant_id ON public.tenant_storages USING btree (tenant_id);

CREATE INDEX idx_tool_installations_plugin_id ON public.tool_installations USING btree (plugin_id);
CREATE INDEX idx_tool_installations_plugin_unique_identifier ON public.tool_installations USING btree (plugin_unique_identifier);
CREATE INDEX idx_tool_installations_provider ON public.tool_installations USING btree (provider);
CREATE INDEX idx_tool_installations_tenant_id ON public.tool_installations USING btree (tenant_id);

CREATE INDEX idx_trigger_installations_plugin_id ON public.trigger_installations USING btree (plugin_id);
CREATE INDEX idx_trigger_installations_plugin_unique_identifier ON public.trigger_installations USING btree (plugin_unique_identifier);
CREATE INDEX idx_trigger_installations_provider ON public.trigger_installations USING btree (provider);
CREATE INDEX idx_trigger_installations_tenant_id ON public.trigger_installations USING btree (tenant_id);