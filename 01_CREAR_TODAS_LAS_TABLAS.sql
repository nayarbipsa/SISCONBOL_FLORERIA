-- =============================================
-- SISCONBOL_FLORERIA - CREACIÓN DE TODAS LAS TABLAS
-- Archivo: 01_CREAR_TODAS_LAS_TABLAS.sql
-- Total: 31 Tablas
-- Fecha: 2026-05-25
-- =============================================

/****** Object:  Table [dbo].[FLORERIA_Aliado]    Script Date: 25/05/2026 18:45:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Aliado](
	[aliado_id] [int] IDENTITY(1,1) NOT NULL,
	[ciudad_id] [smallint] NOT NULL,
	[nombre_negocio] [varchar](150) NOT NULL,
	[nombre_contacto] [varchar](100) NULL,
	[telefono] [varchar](20) NOT NULL,
	[whatsapp] [varchar](20) NULL,
	[email] [varchar](100) NULL,
	[direccion] [varchar](200) NULL,
	[moneda] [char](3) NOT NULL,
	[dias_pago] [tinyint] NOT NULL,
	[notas_comercial] [varchar](500) NULL,
	[metodo_aviso] [varchar](20) NOT NULL,
	[usuario_id] [int] NULL,
	[activo] [bit] NOT NULL,
	[creado_por] [int] NULL,
	[creado_en] [datetime] NOT NULL,
	[modificado_por] [int] NULL,
	[modificado_en] [datetime] NULL,
 CONSTRAINT [PK_FLORERIA_Aliado] PRIMARY KEY CLUSTERED 
(
	[aliado_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Aliado_Zona]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Aliado_Zona](
	[aliado_zona_id] [int] IDENTITY(1,1) NOT NULL,
	[aliado_id] [int] NOT NULL,
	[zona_id] [int] NOT NULL,
	[prioridad] [tinyint] NOT NULL,
	[activo] [bit] NOT NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_Aliado_Zona] PRIMARY KEY CLUSTERED 
(
	[aliado_zona_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_FLORERIA_Aliado_Zona] UNIQUE NONCLUSTERED 
(
	[aliado_id] ASC,
	[zona_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Auditoria]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Auditoria](
	[audit_id] [bigint] IDENTITY(1,1) NOT NULL,
	[usuario_id] [int] NULL,
	[usuario_nombre] [varchar](200) NULL,
	[ip] [varchar](50) NULL,
	[es_celular] [bit] NULL,
	[dispositivo] [varchar](100) NULL,
	[tabla] [varchar](100) NOT NULL,
	[registro_id] [varchar](50) NOT NULL,
	[accion] [varchar](10) NOT NULL,
	[valor_anterior] [nvarchar](max) NULL,
	[valor_nuevo] [nvarchar](max) NULL,
	[motivo] [varchar](500) NULL,
	[fecha_hora] [datetime] NOT NULL,
 CONSTRAINT [PK_Auditoria] PRIMARY KEY CLUSTERED 
(
	[audit_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Categoria]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Categoria](
	[categoria_id] [int] IDENTITY(1,1) NOT NULL,
	[padre_id] [int] NULL,
	[nombre] [varchar](150) NOT NULL,
	[descripcion] [varchar](500) NULL,
	[slug] [varchar](160) NULL,
	[orden] [int] NOT NULL,
	[activo] [bit] NOT NULL,
	[wc_category_id] [int] NULL,
	[wc_sync_estado] [varchar](20) NOT NULL,
	[wc_sync_fecha] [datetime] NULL,
	[creado_por] [int] NULL,
	[creado_en] [datetime] NOT NULL,
	[modificado_por] [int] NULL,
	[modificado_en] [datetime] NULL,
 CONSTRAINT [PK_Categoria] PRIMARY KEY CLUSTERED 
(
	[categoria_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Cat_Slug] UNIQUE NONCLUSTERED 
(
	[slug] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Ciudad]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Ciudad](
	[ciudad_id] [smallint] IDENTITY(1,1) NOT NULL,
	[depto_id] [smallint] NOT NULL,
	[nombre] [varchar](100) NOT NULL,
	[codigo] [varchar](10) NOT NULL,
	[activo] [bit] NOT NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_Ciudad] PRIMARY KEY CLUSTERED 
(
	[ciudad_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Config]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Config](
	[config_id] [int] IDENTITY(1,1) NOT NULL,
	[clave] [varchar](100) NOT NULL,
	[valor] [nvarchar](500) NULL,
	[descripcion] [varchar](300) NULL,
	[es_secreto] [bit] NOT NULL,
	[activo] [bit] NOT NULL,
	[modificado_por] [int] NULL,
	[modificado_en] [datetime] NULL,
 CONSTRAINT [PK_Config] PRIMARY KEY CLUSTERED 
(
	[config_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Config] UNIQUE NONCLUSTERED 
(
	[clave] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Departamento]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Departamento](
	[depto_id] [smallint] IDENTITY(1,1) NOT NULL,
	[pais_id] [tinyint] NOT NULL,
	[nombre] [varchar](100) NOT NULL,
	[codigo] [varchar](10) NOT NULL,
	[activo] [bit] NOT NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_Departamento] PRIMARY KEY CLUSTERED 
(
	[depto_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Menu]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Menu](
	[menu_id] [smallint] IDENTITY(1,1) NOT NULL,
	[padre_id] [smallint] NULL,
	[nombre] [varchar](80) NOT NULL,
	[icono] [varchar](50) NULL,
	[ruta] [varchar](200) NULL,
	[orden] [tinyint] NOT NULL,
	[activo] [bit] NOT NULL,
 CONSTRAINT [PK_Menu1] PRIMARY KEY CLUSTERED 
(
	[menu_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Pais]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Pais](
	[pais_id] [tinyint] IDENTITY(1,1) NOT NULL,
	[codigo_iso] [char](2) NOT NULL,
	[nombre] [varchar](80) NOT NULL,
	[moneda_codigo] [char](3) NOT NULL,
	[moneda_simbolo] [varchar](5) NOT NULL,
	[activo] [bit] NOT NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_Pais] PRIMARY KEY CLUSTERED 
(
	[pais_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_FLORERIA_Pais_Codigo] UNIQUE NONCLUSTERED 
(
	[codigo_iso] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Pedido]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Pedido](
	[pedido_id] [int] IDENTITY(1,1) NOT NULL,
	[prepedido_id] [int] NULL,
	[codigo] [varchar](20) NOT NULL,
	[receptor_nombre] [varchar](200) NOT NULL,
	[receptor_celular] [varchar](20) NOT NULL,
	[ciudad_id] [smallint] NOT NULL,
	[zona_id] [int] NULL,
	[sucursal_id] [smallint] NULL,
	[tipo_entrega] [varchar](20) NOT NULL,
	[direccion] [varchar](300) NULL,
	[latitud] [decimal](10, 7) NULL,
	[longitud] [decimal](10, 7) NULL,
	[referencia] [varchar](300) NULL,
	[fecha_entrega] [date] NOT NULL,
	[slot_id] [smallint] NULL,
	[es_express] [bit] NOT NULL,
	[dedicatoria] [nvarchar](500) NULL,
	[firma_tarjeta] [varchar](100) NULL,
	[subtotal_productos_bs] [decimal](10, 2) NOT NULL,
	[subtotal_productos_usd] [decimal](10, 2) NOT NULL,
	[envio_bs] [decimal](10, 2) NOT NULL,
	[envio_usd] [decimal](10, 2) NOT NULL,
	[recargo_express_bs] [decimal](10, 2) NOT NULL,
	[recargo_express_usd] [decimal](10, 2) NOT NULL,
	[recargo_horario_bs] [decimal](10, 2) NOT NULL,
	[recargo_horario_usd] [decimal](10, 2) NOT NULL,
	[total_bs] [decimal](10, 2) NOT NULL,
	[total_usd] [decimal](10, 2) NOT NULL,
	[anticipo_bs] [decimal](10, 2) NOT NULL,
	[saldo_bs] [decimal](10, 2) NOT NULL,
	[estado_pago] [varchar](20) NOT NULL,
	[wc_order_id] [int] NULL,
	[wc_order_number] [varchar](30) NULL,
	[wc_order_url] [varchar](300) NULL,
	[wc_sync_estado] [varchar](20) NOT NULL,
	[wc_sync_fecha] [datetime] NULL,
	[observaciones] [nvarchar](500) NULL,
	[creado_por] [int] NULL,
	[creado_en] [datetime] NOT NULL,
	[modificado_por] [int] NULL,
	[modificado_en] [datetime] NULL,
	[tipo_ocacion] [varchar](30) NULL,
	[descuento_bs] [decimal](10, 2) NOT NULL,
	[descuento_usd] [decimal](10, 2) NOT NULL,
	[descuento_moneda] [char](3) NULL,
	[gps] [varchar](300) NULL,
	[sucursal_prepara_id] [smallint] NULL,
	[nota_floreria] [nvarchar](500) NULL,
	[wc_order_status] [varchar](30) NULL,
	[wc_date_paid] [datetime] NULL,
	[wc_payment_method] [varchar](50) NULL,
	[wc_payment_method_title] [varchar](100) NULL,
	[wc_date_modified] [datetime] NULL,
	[estado_operativo] [varchar](20) NOT NULL,
 CONSTRAINT [PK_FLORERIA_Pedido] PRIMARY KEY CLUSTERED 
(
	[pedido_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_FLORERIA_Pedido_Codigo] UNIQUE NONCLUSTERED 
(
	[codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Pedido_BACKUP_20260525]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Pedido_BACKUP_20260525](
	[pedido_id] [int] IDENTITY(1,1) NOT NULL,
	[prepedido_id] [int] NULL,
	[codigo] [varchar](20) NOT NULL,
	[receptor_nombre] [varchar](200) NOT NULL,
	[receptor_celular] [varchar](20) NOT NULL,
	[ciudad_id] [smallint] NOT NULL,
	[zona_id] [int] NULL,
	[sucursal_id] [smallint] NULL,
	[tipo_entrega] [varchar](20) NOT NULL,
	[direccion] [varchar](300) NULL,
	[latitud] [decimal](10, 7) NULL,
	[longitud] [decimal](10, 7) NULL,
	[referencia] [varchar](300) NULL,
	[fecha_entrega] [date] NOT NULL,
	[slot_id] [smallint] NULL,
	[es_express] [bit] NOT NULL,
	[dedicatoria] [nvarchar](500) NULL,
	[firma_tarjeta] [varchar](100) NULL,
	[subtotal_productos_bs] [decimal](10, 2) NOT NULL,
	[subtotal_productos_usd] [decimal](10, 2) NOT NULL,
	[envio_bs] [decimal](10, 2) NOT NULL,
	[envio_usd] [decimal](10, 2) NOT NULL,
	[recargo_express_bs] [decimal](10, 2) NOT NULL,
	[recargo_express_usd] [decimal](10, 2) NOT NULL,
	[recargo_horario_bs] [decimal](10, 2) NOT NULL,
	[recargo_horario_usd] [decimal](10, 2) NOT NULL,
	[total_bs] [decimal](10, 2) NOT NULL,
	[total_usd] [decimal](10, 2) NOT NULL,
	[anticipo_bs] [decimal](10, 2) NOT NULL,
	[saldo_bs] [decimal](10, 2) NOT NULL,
	[estado_pago] [varchar](20) NOT NULL,
	[wc_order_id] [int] NULL,
	[wc_order_number] [varchar](30) NULL,
	[wc_order_url] [varchar](300) NULL,
	[wc_sync_estado] [varchar](20) NOT NULL,
	[wc_sync_fecha] [datetime] NULL,
	[observaciones] [nvarchar](500) NULL,
	[creado_por] [int] NULL,
	[creado_en] [datetime] NOT NULL,
	[modificado_por] [int] NULL,
	[modificado_en] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Pedido_Detalle]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Pedido_Detalle](
	[detalle_id] [int] IDENTITY(1,1) NOT NULL,
	[pedido_id] [int] NOT NULL,
	[producto_id] [int] NULL,
	[variacion_id] [int] NULL,
	[es_personalizado] [bit] NOT NULL,
	[nombre_producto] [varchar](200) NOT NULL,
	[descripcion] [nvarchar](500) NULL,
	[cantidad] [int] NOT NULL,
	[precio_unitario_bs] [decimal](10, 2) NOT NULL,
	[precio_unitario_usd] [decimal](10, 2) NOT NULL,
	[subtotal_bs] [decimal](10, 2) NOT NULL,
	[subtotal_usd] [decimal](10, 2) NOT NULL,
	[personalizacion] [nvarchar](500) NULL,
	[wc_line_item_id] [bigint] NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_Pedido_Detalle] PRIMARY KEY CLUSTERED 
(
	[detalle_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Pedido_Detalle_BACKUP_20260525]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Pedido_Detalle_BACKUP_20260525](
	[detalle_id] [int] IDENTITY(1,1) NOT NULL,
	[pedido_id] [int] NOT NULL,
	[producto_id] [int] NULL,
	[variacion_id] [int] NULL,
	[es_personalizado] [bit] NOT NULL,
	[nombre_producto] [varchar](200) NOT NULL,
	[descripcion] [nvarchar](500) NULL,
	[cantidad] [int] NOT NULL,
	[precio_unitario_bs] [decimal](10, 2) NOT NULL,
	[precio_unitario_usd] [decimal](10, 2) NOT NULL,
	[subtotal_bs] [decimal](10, 2) NOT NULL,
	[subtotal_usd] [decimal](10, 2) NOT NULL,
	[personalizacion] [nvarchar](500) NULL,
	[wc_line_item_id] [bigint] NULL,
	[creado_en] [datetime] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Pedido_Estado_Log]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Pedido_Estado_Log](
	[log_id] [bigint] IDENTITY(1,1) NOT NULL,
	[pedido_id] [int] NOT NULL,
	[estado_anterior] [varchar](30) NULL,
	[estado_nuevo] [varchar](30) NOT NULL,
	[observaciones] [varchar](500) NULL,
	[usuario_id] [int] NULL,
	[fecha_hora] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_Pedido_Estado_Log] PRIMARY KEY CLUSTERED 
(
	[log_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Pedido_Pago]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Pedido_Pago](
	[pago_id] [int] IDENTITY(1,1) NOT NULL,
	[pedido_id] [int] NOT NULL,
	[prepedido_id] [int] NULL,
	[tipo_pago] [varchar](20) NOT NULL,
	[metodo_pago] [varchar](30) NOT NULL,
	[monto_bs] [decimal](10, 2) NOT NULL,
	[monto_usd] [decimal](10, 2) NOT NULL,
	[referencia] [varchar](100) NULL,
	[comprobante_url] [varchar](300) NULL,
	[estado] [varchar](20) NOT NULL,
	[verificado_por] [int] NULL,
	[verificado_en] [datetime] NULL,
	[observaciones] [varchar](300) NULL,
	[creado_por] [int] NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_Pedido_Pago] PRIMARY KEY CLUSTERED 
(
	[pago_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Pedido_Reprogramacion]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Pedido_Reprogramacion](
	[reprog_id] [int] IDENTITY(1,1) NOT NULL,
	[pedido_id] [int] NOT NULL,
	[fecha_anterior] [date] NOT NULL,
	[slot_anterior_id] [smallint] NULL,
	[fecha_nueva] [date] NOT NULL,
	[slot_nuevo_id] [smallint] NULL,
	[motivo] [varchar](300) NOT NULL,
	[solicitado_por] [varchar](20) NOT NULL,
	[usuario_id] [int] NULL,
	[fecha_hora] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_Pedido_Reprogramacion] PRIMARY KEY CLUSTERED 
(
	[reprog_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_PrePedido]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_PrePedido](
	[prepedido_id] [int] IDENTITY(1,1) NOT NULL,
	[codigo] [varchar](20) NOT NULL,
	[token_web] [varchar](100) NULL,
	[tipo_registro] [varchar](20) NOT NULL,
	[cliente_celular] [varchar](20) NOT NULL,
	[cliente_nombre] [varchar](200) NULL,
	[cliente_apellidos] [varchar](200) NULL,
	[cliente_email] [varchar](100) NULL,
	[cliente_pais_id] [tinyint] NULL,
	[cliente_ciudad_id] [smallint] NULL,
	[estado] [varchar](30) NOT NULL,
	[total_general_bs] [decimal](10, 2) NOT NULL,
	[total_general_usd] [decimal](10, 2) NOT NULL,
	[tasa_cambio] [decimal](10, 4) NOT NULL,
	[moneda_formulario] [char](3) NOT NULL,
	[descuento_bs] [decimal](10, 2) NOT NULL,
	[descuento_usd] [decimal](10, 2) NOT NULL,
	[descuento_motivo] [varchar](300) NULL,
	[agente_actual_id] [int] NOT NULL,
	[fecha_limite_pago] [datetime] NULL,
	[token_expira] [datetime] NULL,
	[observaciones] [nvarchar](500) NULL,
	[creado_por] [int] NOT NULL,
	[creado_en] [datetime] NOT NULL,
	[modificado_por] [int] NULL,
	[modificado_en] [datetime] NULL,
	[token_abierto_en] [datetime] NULL,
	[token_confirmado_por_cliente_en] [datetime] NULL,
	[metodo_pago_cliente] [varchar](30) NULL,
 CONSTRAINT [PK_FLORERIA_PrePedido] PRIMARY KEY CLUSTERED 
(
	[prepedido_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_FLORERIA_PrePedido_Codigo] UNIQUE NONCLUSTERED 
(
	[codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_PrePedido_Agente_Log]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_PrePedido_Agente_Log](
	[log_id] [int] IDENTITY(1,1) NOT NULL,
	[prepedido_id] [int] NOT NULL,
	[agente_anterior_id] [int] NULL,
	[agente_nuevo_id] [int] NOT NULL,
	[motivo] [varchar](300) NOT NULL,
	[fecha_hora] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_PrePedido_Agente_Log] PRIMARY KEY CLUSTERED 
(
	[log_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_PrePedido_BACKUP_20260524]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_PrePedido_BACKUP_20260524](
	[prepedido_id] [int] IDENTITY(1,1) NOT NULL,
	[codigo] [varchar](20) NOT NULL,
	[token_web] [varchar](100) NULL,
	[tipo_registro] [varchar](20) NOT NULL,
	[cliente_celular] [varchar](20) NOT NULL,
	[cliente_nombre] [varchar](200) NULL,
	[cliente_apellidos] [varchar](200) NULL,
	[cliente_email] [varchar](100) NULL,
	[cliente_pais_id] [tinyint] NULL,
	[cliente_ciudad_id] [smallint] NULL,
	[estado] [varchar](30) NOT NULL,
	[total_general_bs] [decimal](10, 2) NOT NULL,
	[total_general_usd] [decimal](10, 2) NOT NULL,
	[tasa_cambio] [decimal](10, 4) NOT NULL,
	[moneda_formulario] [char](3) NOT NULL,
	[descuento_bs] [decimal](10, 2) NOT NULL,
	[descuento_usd] [decimal](10, 2) NOT NULL,
	[descuento_motivo] [varchar](300) NULL,
	[agente_actual_id] [int] NOT NULL,
	[fecha_limite_pago] [datetime] NULL,
	[token_expira] [datetime] NULL,
	[observaciones] [nvarchar](500) NULL,
	[creado_por] [int] NOT NULL,
	[creado_en] [datetime] NOT NULL,
	[modificado_por] [int] NULL,
	[modificado_en] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_PrePedido_BACKUP_20260525]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_PrePedido_BACKUP_20260525](
	[prepedido_id] [int] IDENTITY(1,1) NOT NULL,
	[codigo] [varchar](20) NOT NULL,
	[token_web] [varchar](100) NULL,
	[tipo_registro] [varchar](20) NOT NULL,
	[cliente_celular] [varchar](20) NOT NULL,
	[cliente_nombre] [varchar](200) NULL,
	[cliente_apellidos] [varchar](200) NULL,
	[cliente_email] [varchar](100) NULL,
	[cliente_pais_id] [tinyint] NULL,
	[cliente_ciudad_id] [smallint] NULL,
	[estado] [varchar](30) NOT NULL,
	[total_general_bs] [decimal](10, 2) NOT NULL,
	[total_general_usd] [decimal](10, 2) NOT NULL,
	[tasa_cambio] [decimal](10, 4) NOT NULL,
	[moneda_formulario] [char](3) NOT NULL,
	[descuento_bs] [decimal](10, 2) NOT NULL,
	[descuento_usd] [decimal](10, 2) NOT NULL,
	[descuento_motivo] [varchar](300) NULL,
	[agente_actual_id] [int] NOT NULL,
	[fecha_limite_pago] [datetime] NULL,
	[token_expira] [datetime] NULL,
	[observaciones] [nvarchar](500) NULL,
	[creado_por] [int] NOT NULL,
	[creado_en] [datetime] NOT NULL,
	[modificado_por] [int] NULL,
	[modificado_en] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_PrePedido_Entrega]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_PrePedido_Entrega](
	[prepedido_entrega_id] [int] IDENTITY(1,1) NOT NULL,
	[prepedido_id] [int] NOT NULL,
	[pedido_id] [int] NULL,
	[estado] [varchar](20) NOT NULL,
	[receptor_nombre] [varchar](200) NULL,
	[receptor_celular] [varchar](20) NULL,
	[ciudad_id] [smallint] NULL,
	[zona_id] [int] NULL,
	[sucursal_id] [smallint] NULL,
	[tipo_entrega] [varchar](20) NOT NULL,
	[direccion] [varchar](300) NULL,
	[referencia] [varchar](300) NULL,
	[gps] [varchar](200) NULL,
	[fecha_entrega] [date] NULL,
	[slot_id] [smallint] NULL,
	[es_express] [bit] NOT NULL,
	[dedicatoria] [nvarchar](500) NULL,
	[firma_tarjeta] [varchar](100) NULL,
	[tipo_ocacion] [varchar](30) NULL,
	[sucursal_prepara_id] [smallint] NULL,
	[moneda] [char](3) NOT NULL,
	[descuento_valor] [decimal](10, 2) NOT NULL,
	[descuento_moneda] [char](3) NOT NULL,
	[nota_floreria] [nvarchar](1000) NULL,
	[creado_por] [int] NOT NULL,
	[creado_en] [datetime] NOT NULL,
	[modificado_por] [int] NULL,
	[modificado_en] [datetime] NULL,
	[confirmado_en] [datetime] NULL,
 CONSTRAINT [PK_PrePedido_Entrega] PRIMARY KEY CLUSTERED 
(
	[prepedido_entrega_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_PrePedido_Entrega_Detalle]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_PrePedido_Entrega_Detalle](
	[detalle_id] [int] IDENTITY(1,1) NOT NULL,
	[prepedido_entrega_id] [int] NOT NULL,
	[producto_id] [int] NULL,
	[variacion_id] [int] NULL,
	[es_personalizado] [bit] NOT NULL,
	[nombre_producto] [varchar](200) NOT NULL,
	[descripcion] [nvarchar](500) NULL,
	[cantidad] [int] NOT NULL,
	[precio_unitario_bs] [decimal](10, 2) NOT NULL,
	[precio_unitario_usd] [decimal](10, 2) NOT NULL,
	[subtotal_bs] [decimal](10, 2) NOT NULL,
	[subtotal_usd] [decimal](10, 2) NOT NULL,
	[personalizacion] [nvarchar](500) NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_PPE_Detalle] PRIMARY KEY CLUSTERED 
(
	[detalle_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_PrePedido_Entrega_Pago]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_PrePedido_Entrega_Pago](
	[pago_id] [int] IDENTITY(1,1) NOT NULL,
	[prepedido_entrega_id] [int] NOT NULL,
	[tipo_pago] [varchar](20) NOT NULL,
	[metodo_pago] [varchar](30) NOT NULL,
	[monto_bs] [decimal](10, 2) NOT NULL,
	[monto_usd] [decimal](10, 2) NOT NULL,
	[referencia] [varchar](100) NULL,
	[comprobante_url] [varchar](300) NULL,
	[estado] [varchar](20) NOT NULL,
	[verificado_por] [int] NULL,
	[verificado_en] [datetime] NULL,
	[observaciones] [varchar](300) NULL,
	[creado_por] [int] NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_PPE_Pago] PRIMARY KEY CLUSTERED 
(
	[pago_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Producto]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Producto](
	[producto_id] [int] IDENTITY(1,1) NOT NULL,
	[sku] [varchar](50) NOT NULL,
	[nombre] [varchar](200) NOT NULL,
	[descripcion] [nvarchar](max) NULL,
	[categoria_id] [int] NULL,
	[precio_base_bs] [decimal](10, 2) NOT NULL,
	[precio_base_usd] [decimal](10, 2) NULL,
	[tiene_variaciones] [bit] NOT NULL,
	[wc_product_id] [int] NULL,
	[wc_sync_estado] [varchar](20) NOT NULL,
	[wc_sync_fecha] [datetime] NULL,
	[activo] [bit] NOT NULL,
	[creado_por] [int] NULL,
	[creado_en] [datetime] NOT NULL,
	[modificado_por] [int] NULL,
	[modificado_en] [datetime] NULL,
	[precio_promo_bs] [decimal](10, 2) NULL,
	[precio_promo_usd] [decimal](10, 2) NULL,
	[promo_desde] [date] NULL,
	[promo_hasta] [date] NULL,
	[destacado] [bit] NOT NULL,
	[menu_order] [int] NOT NULL,
	[notas_internas] [nvarchar](500) NULL,
	[stock_actual] [int] NOT NULL,
	[stock_minimo] [int] NOT NULL,
	[imagen_url] [varchar](500) NULL,
 CONSTRAINT [PK_Producto] PRIMARY KEY CLUSTERED 
(
	[producto_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Producto_SKU] UNIQUE NONCLUSTERED 
(
	[sku] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Producto_Categoria]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Producto_Categoria](
	[prodcat_id] [int] IDENTITY(1,1) NOT NULL,
	[producto_id] [int] NOT NULL,
	[categoria_id] [int] NOT NULL,
	[es_principal] [bit] NOT NULL,
	[creado_por] [int] NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_ProdCat] PRIMARY KEY CLUSTERED 
(
	[prodcat_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_ProdCat] UNIQUE NONCLUSTERED 
(
	[producto_id] ASC,
	[categoria_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Producto_Disponibilidad]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Producto_Disponibilidad](
	[disp_id] [int] IDENTITY(1,1) NOT NULL,
	[producto_id] [int] NOT NULL,
	[variacion_id] [int] NULL,
	[sucursal_id] [smallint] NULL,
	[aliado_id] [int] NULL,
	[disponible] [bit] NOT NULL,
	[stock_actual] [int] NOT NULL,
	[stock_minimo] [int] NOT NULL,
	[stock_reservado] [int] NOT NULL,
	[precio_bs] [decimal](10, 2) NULL,
	[precio_usd] [decimal](10, 2) NULL,
	[costo_aliado_bs] [decimal](10, 2) NULL,
	[actualizado_por] [int] NULL,
	[actualizado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_ProdDisp] PRIMARY KEY CLUSTERED 
(
	[disp_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_PD_Ali] UNIQUE NONCLUSTERED 
(
	[producto_id] ASC,
	[variacion_id] ASC,
	[aliado_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_PD_Suc] UNIQUE NONCLUSTERED 
(
	[producto_id] ASC,
	[variacion_id] ASC,
	[sucursal_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Producto_Variacion]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Producto_Variacion](
	[variacion_id] [int] IDENTITY(1,1) NOT NULL,
	[producto_id] [int] NOT NULL,
	[sku_variacion] [varchar](60) NOT NULL,
	[atrib_1_nombre] [varchar](40) NULL,
	[atrib_1_valor] [varchar](80) NULL,
	[atrib_2_nombre] [varchar](40) NULL,
	[atrib_2_valor] [varchar](80) NULL,
	[atrib_3_nombre] [varchar](40) NULL,
	[atrib_3_valor] [varchar](80) NULL,
	[precio_bs] [decimal](10, 2) NULL,
	[precio_usd] [decimal](10, 2) NULL,
	[wc_variation_id] [int] NULL,
	[wc_sync_estado] [varchar](20) NOT NULL,
	[activo] [bit] NOT NULL,
	[creado_por] [int] NULL,
	[creado_en] [datetime] NOT NULL,
	[modificado_por] [int] NULL,
	[modificado_en] [datetime] NULL,
	[precio_promo_bs] [decimal](10, 2) NULL,
	[precio_promo_usd] [decimal](10, 2) NULL,
	[promo_desde] [date] NULL,
	[promo_hasta] [date] NULL,
	[wc_sync_fecha] [datetime] NULL,
 CONSTRAINT [PK_Variacion] PRIMARY KEY CLUSTERED 
(
	[variacion_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Variacion_SKU] UNIQUE NONCLUSTERED 
(
	[sku_variacion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Sesion]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Sesion](
	[sesion_id] [bigint] IDENTITY(1,1) NOT NULL,
	[usuario_id] [int] NOT NULL,
	[token] [varchar](100) NOT NULL,
	[ip] [varchar](50) NULL,
	[user_agent] [varchar](500) NULL,
	[es_celular] [bit] NOT NULL,
	[dispositivo] [varchar](100) NULL,
	[sistema_op] [varchar](50) NULL,
	[navegador] [varchar](50) NULL,
	[inicio] [datetime] NOT NULL,
	[ultimo_acceso] [datetime] NOT NULL,
	[expira_en] [datetime] NOT NULL,
	[activa] [bit] NOT NULL,
	[cerrada_por] [varchar](20) NULL,
 CONSTRAINT [PK_Sesion] PRIMARY KEY CLUSTERED 
(
	[sesion_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Token] UNIQUE NONCLUSTERED 
(
	[token] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Slot_Horario]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Slot_Horario](
	[slot_id] [smallint] IDENTITY(1,1) NOT NULL,
	[ciudad_id] [smallint] NOT NULL,
	[etiqueta] [varchar](60) NOT NULL,
	[hora_inicio] [time](7) NOT NULL,
	[hora_fin] [time](7) NOT NULL,
	[duracion_minutos] [smallint] NOT NULL,
	[recargo_bs] [decimal](10, 2) NOT NULL,
	[es_express] [bit] NOT NULL,
	[activo] [bit] NOT NULL,
	[orden_display] [tinyint] NOT NULL,
	[wc_slot_value] [varchar](50) NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_Slot_Horario] PRIMARY KEY CLUSTERED 
(
	[slot_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Sucursal]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Sucursal](
	[sucursal_id] [smallint] IDENTITY(1,1) NOT NULL,
	[ciudad_id] [smallint] NOT NULL,
	[codigo] [varchar](10) NOT NULL,
	[nombre] [varchar](100) NOT NULL,
	[direccion] [varchar](200) NULL,
	[telefono] [varchar](20) NULL,
	[email] [varchar](100) NULL,
	[latitud] [decimal](10, 7) NULL,
	[longitud] [decimal](10, 7) NULL,
	[hora_apertura] [time](7) NOT NULL,
	[hora_cierre] [time](7) NOT NULL,
	[dias_operacion] [varchar](20) NOT NULL,
	[fondo_fijo_bs] [decimal](10, 2) NOT NULL,
	[wc_zone_id] [int] NULL,
	[wc_zone_code] [varchar](20) NULL,
	[activo] [bit] NOT NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_Sucursal] PRIMARY KEY CLUSTERED 
(
	[sucursal_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_FLORERIA_Sucursal_Codigo] UNIQUE NONCLUSTERED 
(
	[codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Sucursal_Zona]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Sucursal_Zona](
	[suc_zona_id] [int] IDENTITY(1,1) NOT NULL,
	[sucursal_id] [smallint] NOT NULL,
	[zona_id] [int] NOT NULL,
	[prioridad] [tinyint] NOT NULL,
	[activo] [bit] NOT NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_Sucursal_Zona] PRIMARY KEY CLUSTERED 
(
	[suc_zona_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_FLORERIA_Sucursal_Zona] UNIQUE NONCLUSTERED 
(
	[sucursal_id] ASC,
	[zona_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_TipoUsuario]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_TipoUsuario](
	[tipo_id] [smallint] IDENTITY(1,1) NOT NULL,
	[nombre] [varchar](50) NOT NULL,
	[descripcion] [varchar](200) NULL,
	[activo] [bit] NOT NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_TipoUsuario] PRIMARY KEY CLUSTERED 
(
	[tipo_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_TipoUsuario] UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_TipoUsuario_Menu]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_TipoUsuario_Menu](
	[tipomenu_id] [int] IDENTITY(1,1) NOT NULL,
	[tipo_id] [smallint] NOT NULL,
	[menu_id] [smallint] NOT NULL,
	[puede_ver] [bit] NOT NULL,
	[puede_crear] [bit] NOT NULL,
	[puede_editar] [bit] NOT NULL,
	[puede_eliminar] [bit] NOT NULL,
 CONSTRAINT [PK_TipoMenu] PRIMARY KEY CLUSTERED 
(
	[tipomenu_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_TipoMenu] UNIQUE NONCLUSTERED 
(
	[tipo_id] ASC,
	[menu_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Usuario]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Usuario](
	[usuario_id] [int] IDENTITY(1,1) NOT NULL,
	[tipo_id] [smallint] NOT NULL,
	[carnet] [varchar](8) NOT NULL,
	[nombres] [varchar](100) NOT NULL,
	[apellidos] [varchar](100) NOT NULL,
	[celular] [varchar](20) NULL,
	[email] [varchar](100) NULL,
	[direccion] [varchar](200) NULL,
	[fecha_nac] [date] NULL,
	[password_hash] [varchar](200) NOT NULL,
	[password_salt] [varchar](50) NOT NULL,
	[debe_cambiar_pwd] [bit] NOT NULL,
	[vigente_desde] [date] NOT NULL,
	[vigente_hasta] [date] NULL,
	[activo] [bit] NOT NULL,
	[bloqueado] [bit] NOT NULL,
	[intentos_fallidos] [tinyint] NOT NULL,
	[bloqueado_hasta] [datetime] NULL,
	[creado_por] [int] NULL,
	[creado_en] [datetime] NOT NULL,
	[modificado_por] [int] NULL,
	[modificado_en] [datetime] NULL,
 CONSTRAINT [PK_UsuarioFLO] PRIMARY KEY CLUSTERED 
(
	[usuario_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Carnet] UNIQUE NONCLUSTERED 
(
	[carnet] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Usuario_Menu]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Usuario_Menu](
	[usumenu_id] [int] IDENTITY(1,1) NOT NULL,
	[usuario_id] [int] NOT NULL,
	[menu_id] [smallint] NOT NULL,
	[tipo_excepcion] [varchar](10) NOT NULL,
	[puede_ver] [bit] NOT NULL,
	[puede_crear] [bit] NOT NULL,
	[puede_editar] [bit] NOT NULL,
	[puede_eliminar] [bit] NOT NULL,
	[motivo] [varchar](300) NOT NULL,
	[creado_por] [int] NOT NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_UsuMenu] PRIMARY KEY CLUSTERED 
(
	[usumenu_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_UsuMenu] UNIQUE NONCLUSTERED 
(
	[usuario_id] ASC,
	[menu_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Webhook_Log]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Webhook_Log](
	[log_id] [int] IDENTITY(1,1) NOT NULL,
	[tipo] [varchar](30) NOT NULL,
	[wc_order_id] [int] NULL,
	[wc_order_number] [varchar](20) NULL,
	[pedido_id] [int] NULL,
	[payload] [nvarchar](max) NULL,
	[firma_valida] [bit] NULL,
	[mensaje] [nvarchar](500) NULL,
	[ip_origen] [varchar](50) NULL,
	[fecha] [datetime] NOT NULL,
 CONSTRAINT [PK_WebhookLog] PRIMARY KEY CLUSTERED 
(
	[log_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Zona]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Zona](
	[zona_id] [int] IDENTITY(1,1) NOT NULL,
	[ciudad_id] [smallint] NOT NULL,
	[nombre] [varchar](150) NOT NULL,
	[codigo] [varchar](20) NOT NULL,
	[tipo] [varchar](20) NOT NULL,
	[latitud_ref] [decimal](10, 7) NULL,
	[longitud_ref] [decimal](10, 7) NULL,
	[wc_zone_id] [int] NULL,
	[wc_zone_code] [varchar](20) NULL,
	[activo] [bit] NOT NULL,
	[orden_display] [smallint] NOT NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_Zona] PRIMARY KEY CLUSTERED 
(
	[zona_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Zona_Express]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Zona_Express](
	[express_id] [int] IDENTITY(1,1) NOT NULL,
	[zona_id] [int] NOT NULL,
	[minutos_limite] [smallint] NOT NULL,
	[etiqueta] [varchar](30) NOT NULL,
	[recargo_bs] [decimal](10, 2) NOT NULL,
	[activo] [bit] NOT NULL,
	[creado_en] [datetime] NOT NULL,
 CONSTRAINT [PK_FLORERIA_Zona_Express] PRIMARY KEY CLUSTERED 
(
	[express_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_FLORERIA_Zona_Express] UNIQUE NONCLUSTERED 
(
	[zona_id] ASC,
	[minutos_limite] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FLORERIA_Zona_Tarifa]    Script Date: 25/05/2026 18:45:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FLORERIA_Zona_Tarifa](
	[tarifa_id] [int] IDENTITY(1,1) NOT NULL,
	[zona_id] [int] NOT NULL,
	[precio_bs] [decimal](10, 2) NOT NULL,
	[precio_usd] [decimal](10, 2) NULL,
	[vigente_desde] [date] NOT NULL,
	[vigente_hasta] [date] NULL,
	[creado_por] [int] NULL,
	[creado_en] [datetime] NOT NULL,
	[motivo_cambio] [varchar](200) NULL,
 CONSTRAINT [PK_FLORERIA_Zona_Tarifa] PRIMARY KEY CLUSTERED 
(
	[tarifa_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
