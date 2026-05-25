-- =============================================
-- SISCONBOL_FLORERIA - CREACIÓN DE TODAS LAS TABLAS
-- Archivo: 01_CREAR_TODAS_LAS_TABLAS.sql
-- Total: 31 Tablas
-- Fecha: 2026-05-22
-- =============================================

USE [SISCONBOL]
GO
/****** Object:  Table [dbo].[FLORERIA_Aliado]    Script Date: 25/05/2026 0:32:30 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Aliado_Zona]    Script Date: 25/05/2026 0:32:30 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Auditoria]    Script Date: 25/05/2026 0:32:30 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Categoria]    Script Date: 25/05/2026 0:32:30 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Ciudad]    Script Date: 25/05/2026 0:32:30 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Config]    Script Date: 25/05/2026 0:32:30 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Departamento]    Script Date: 25/05/2026 0:32:30 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Menu]    Script Date: 25/05/2026 0:32:30 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Pais]    Script Date: 25/05/2026 0:32:30 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Pedido]    Script Date: 25/05/2026 0:32:30 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Pedido_BACKUP_20260525]    Script Date: 25/05/2026 0:32:30 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Pedido_Detalle]    Script Date: 25/05/2026 0:32:30 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Pedido_Detalle_BACKUP_20260525]    Script Date: 25/05/2026 0:32:30 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Pedido_Estado_Log]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Pedido_Pago]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Pedido_Reprogramacion]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_PrePedido]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_PrePedido_Agente_Log]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_PrePedido_BACKUP_20260524]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_PrePedido_BACKUP_20260525]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Producto]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Producto_Categoria]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Producto_Disponibilidad]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Producto_Variacion]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Sesion]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Slot_Horario]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Sucursal]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Sucursal_Zona]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_TipoUsuario]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_TipoUsuario_Menu]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Usuario]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Usuario_Menu]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Webhook_Log]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Zona]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Zona_Express]    Script Date: 25/05/2026 0:32:31 ******/
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
/****** Object:  Table [dbo].[FLORERIA_Zona_Tarifa]    Script Date: 25/05/2026 0:32:31 ******/
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
ALTER TABLE [dbo].[FLORERIA_Aliado] ADD  DEFAULT ('BOB') FOR [moneda]
GO
ALTER TABLE [dbo].[FLORERIA_Aliado] ADD  DEFAULT ((7)) FOR [dias_pago]
GO
ALTER TABLE [dbo].[FLORERIA_Aliado] ADD  DEFAULT ('WHATSAPP_MANUAL') FOR [metodo_aviso]
GO
ALTER TABLE [dbo].[FLORERIA_Aliado] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Aliado] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Aliado_Zona] ADD  DEFAULT ((1)) FOR [prioridad]
GO
ALTER TABLE [dbo].[FLORERIA_Aliado_Zona] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Aliado_Zona] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Auditoria] ADD  DEFAULT (getdate()) FOR [fecha_hora]
GO
ALTER TABLE [dbo].[FLORERIA_Categoria] ADD  DEFAULT ((0)) FOR [orden]
GO
ALTER TABLE [dbo].[FLORERIA_Categoria] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Categoria] ADD  DEFAULT ('PENDIENTE') FOR [wc_sync_estado]
GO
ALTER TABLE [dbo].[FLORERIA_Categoria] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Ciudad] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Ciudad] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Config] ADD  DEFAULT ((0)) FOR [es_secreto]
GO
ALTER TABLE [dbo].[FLORERIA_Config] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Departamento] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Departamento] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Menu] ADD  DEFAULT ((0)) FOR [orden]
GO
ALTER TABLE [dbo].[FLORERIA_Menu] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Pais] ADD  DEFAULT ('BOB') FOR [moneda_codigo]
GO
ALTER TABLE [dbo].[FLORERIA_Pais] ADD  DEFAULT ('Bs') FOR [moneda_simbolo]
GO
ALTER TABLE [dbo].[FLORERIA_Pais] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Pais] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ('DOMICILIO') FOR [tipo_entrega]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [es_express]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [subtotal_productos_bs]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [subtotal_productos_usd]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [envio_bs]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [envio_usd]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [recargo_express_bs]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [recargo_express_usd]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [recargo_horario_bs]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [recargo_horario_usd]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [total_bs]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [total_usd]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [anticipo_bs]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [saldo_bs]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ('PENDIENTE') FOR [estado_pago]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ('PENDIENTE') FOR [wc_sync_estado]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [descuento_bs]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] ADD  DEFAULT ((0)) FOR [descuento_usd]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Detalle] ADD  DEFAULT ((0)) FOR [es_personalizado]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Detalle] ADD  DEFAULT ((1)) FOR [cantidad]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Detalle] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Estado_Log] ADD  DEFAULT (getdate()) FOR [fecha_hora]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago] ADD  DEFAULT ('TOTAL') FOR [tipo_pago]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago] ADD  DEFAULT ('PENDIENTE') FOR [estado]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Reprogramacion] ADD  DEFAULT (getdate()) FOR [fecha_hora]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] ADD  DEFAULT ('PRE_PEDIDO') FOR [tipo_registro]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] ADD  DEFAULT ('BORRADOR') FOR [estado]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] ADD  DEFAULT ((0)) FOR [total_general_bs]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] ADD  DEFAULT ((0)) FOR [total_general_usd]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] ADD  DEFAULT ((7.0000)) FOR [tasa_cambio]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] ADD  DEFAULT ('BOB') FOR [moneda_formulario]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] ADD  DEFAULT ((0)) FOR [descuento_bs]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] ADD  DEFAULT ((0)) FOR [descuento_usd]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido_Agente_Log] ADD  DEFAULT (getdate()) FOR [fecha_hora]
GO
ALTER TABLE [dbo].[FLORERIA_Producto] ADD  DEFAULT ((0)) FOR [precio_base_bs]
GO
ALTER TABLE [dbo].[FLORERIA_Producto] ADD  DEFAULT ((0)) FOR [tiene_variaciones]
GO
ALTER TABLE [dbo].[FLORERIA_Producto] ADD  DEFAULT ('PENDIENTE') FOR [wc_sync_estado]
GO
ALTER TABLE [dbo].[FLORERIA_Producto] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Producto] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Producto] ADD  DEFAULT ((0)) FOR [destacado]
GO
ALTER TABLE [dbo].[FLORERIA_Producto] ADD  DEFAULT ((0)) FOR [menu_order]
GO
ALTER TABLE [dbo].[FLORERIA_Producto] ADD  DEFAULT ((0)) FOR [stock_actual]
GO
ALTER TABLE [dbo].[FLORERIA_Producto] ADD  DEFAULT ((5)) FOR [stock_minimo]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Categoria] ADD  DEFAULT ((0)) FOR [es_principal]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Categoria] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Disponibilidad] ADD  DEFAULT ((1)) FOR [disponible]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Disponibilidad] ADD  DEFAULT ((0)) FOR [stock_actual]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Disponibilidad] ADD  DEFAULT ((5)) FOR [stock_minimo]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Disponibilidad] ADD  DEFAULT ((0)) FOR [stock_reservado]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Disponibilidad] ADD  DEFAULT (getdate()) FOR [actualizado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Variacion] ADD  DEFAULT ('PENDIENTE') FOR [wc_sync_estado]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Variacion] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Variacion] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Sesion] ADD  DEFAULT ((0)) FOR [es_celular]
GO
ALTER TABLE [dbo].[FLORERIA_Sesion] ADD  DEFAULT (getdate()) FOR [inicio]
GO
ALTER TABLE [dbo].[FLORERIA_Sesion] ADD  DEFAULT (getdate()) FOR [ultimo_acceso]
GO
ALTER TABLE [dbo].[FLORERIA_Sesion] ADD  DEFAULT ((1)) FOR [activa]
GO
ALTER TABLE [dbo].[FLORERIA_Slot_Horario] ADD  DEFAULT ((180)) FOR [duracion_minutos]
GO
ALTER TABLE [dbo].[FLORERIA_Slot_Horario] ADD  DEFAULT ((0)) FOR [recargo_bs]
GO
ALTER TABLE [dbo].[FLORERIA_Slot_Horario] ADD  DEFAULT ((0)) FOR [es_express]
GO
ALTER TABLE [dbo].[FLORERIA_Slot_Horario] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Slot_Horario] ADD  DEFAULT ((0)) FOR [orden_display]
GO
ALTER TABLE [dbo].[FLORERIA_Slot_Horario] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal] ADD  DEFAULT ('08:00') FOR [hora_apertura]
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal] ADD  DEFAULT ('20:00') FOR [hora_cierre]
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal] ADD  DEFAULT ('L,M,X,J,V,S') FOR [dias_operacion]
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal] ADD  DEFAULT ((200.00)) FOR [fondo_fijo_bs]
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal_Zona] ADD  DEFAULT ((1)) FOR [prioridad]
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal_Zona] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal_Zona] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_TipoUsuario] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_TipoUsuario] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_TipoUsuario_Menu] ADD  DEFAULT ((1)) FOR [puede_ver]
GO
ALTER TABLE [dbo].[FLORERIA_TipoUsuario_Menu] ADD  DEFAULT ((0)) FOR [puede_crear]
GO
ALTER TABLE [dbo].[FLORERIA_TipoUsuario_Menu] ADD  DEFAULT ((0)) FOR [puede_editar]
GO
ALTER TABLE [dbo].[FLORERIA_TipoUsuario_Menu] ADD  DEFAULT ((0)) FOR [puede_eliminar]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario] ADD  DEFAULT ((1)) FOR [debe_cambiar_pwd]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario] ADD  DEFAULT (CONVERT([date],getdate())) FOR [vigente_desde]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario] ADD  DEFAULT ((0)) FOR [bloqueado]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario] ADD  DEFAULT ((0)) FOR [intentos_fallidos]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario_Menu] ADD  DEFAULT ((1)) FOR [puede_ver]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario_Menu] ADD  DEFAULT ((0)) FOR [puede_crear]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario_Menu] ADD  DEFAULT ((0)) FOR [puede_editar]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario_Menu] ADD  DEFAULT ((0)) FOR [puede_eliminar]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario_Menu] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Webhook_Log] ADD  DEFAULT (getdate()) FOR [fecha]
GO
ALTER TABLE [dbo].[FLORERIA_Zona] ADD  DEFAULT ('DELIVERY') FOR [tipo]
GO
ALTER TABLE [dbo].[FLORERIA_Zona] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Zona] ADD  DEFAULT ((0)) FOR [orden_display]
GO
ALTER TABLE [dbo].[FLORERIA_Zona] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Zona_Express] ADD  DEFAULT ((0)) FOR [recargo_bs]
GO
ALTER TABLE [dbo].[FLORERIA_Zona_Express] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[FLORERIA_Zona_Express] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Zona_Tarifa] ADD  DEFAULT ((0)) FOR [precio_bs]
GO
ALTER TABLE [dbo].[FLORERIA_Zona_Tarifa] ADD  DEFAULT (CONVERT([date],getdate())) FOR [vigente_desde]
GO
ALTER TABLE [dbo].[FLORERIA_Zona_Tarifa] ADD  DEFAULT (getdate()) FOR [creado_en]
GO
ALTER TABLE [dbo].[FLORERIA_Aliado]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Aliado_Ciudad] FOREIGN KEY([ciudad_id])
REFERENCES [dbo].[FLORERIA_Ciudad] ([ciudad_id])
GO
ALTER TABLE [dbo].[FLORERIA_Aliado] CHECK CONSTRAINT [FK_FLORERIA_Aliado_Ciudad]
GO
ALTER TABLE [dbo].[FLORERIA_Aliado]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Aliado_CreadoPor] FOREIGN KEY([creado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Aliado] CHECK CONSTRAINT [FK_FLORERIA_Aliado_CreadoPor]
GO
ALTER TABLE [dbo].[FLORERIA_Aliado]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Aliado_ModificadoPor] FOREIGN KEY([modificado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Aliado] CHECK CONSTRAINT [FK_FLORERIA_Aliado_ModificadoPor]
GO
ALTER TABLE [dbo].[FLORERIA_Aliado]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Aliado_Usuario] FOREIGN KEY([usuario_id])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Aliado] CHECK CONSTRAINT [FK_FLORERIA_Aliado_Usuario]
GO
ALTER TABLE [dbo].[FLORERIA_Aliado_Zona]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Aliado_Zona_Aliado] FOREIGN KEY([aliado_id])
REFERENCES [dbo].[FLORERIA_Aliado] ([aliado_id])
GO
ALTER TABLE [dbo].[FLORERIA_Aliado_Zona] CHECK CONSTRAINT [FK_FLORERIA_Aliado_Zona_Aliado]
GO
ALTER TABLE [dbo].[FLORERIA_Aliado_Zona]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Aliado_Zona_Zona] FOREIGN KEY([zona_id])
REFERENCES [dbo].[FLORERIA_Zona] ([zona_id])
GO
ALTER TABLE [dbo].[FLORERIA_Aliado_Zona] CHECK CONSTRAINT [FK_FLORERIA_Aliado_Zona_Zona]
GO
ALTER TABLE [dbo].[FLORERIA_Categoria]  WITH CHECK ADD  CONSTRAINT [FK_Cat_CreadoPor] FOREIGN KEY([creado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Categoria] CHECK CONSTRAINT [FK_Cat_CreadoPor]
GO
ALTER TABLE [dbo].[FLORERIA_Categoria]  WITH CHECK ADD  CONSTRAINT [FK_Cat_ModifPor] FOREIGN KEY([modificado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Categoria] CHECK CONSTRAINT [FK_Cat_ModifPor]
GO
ALTER TABLE [dbo].[FLORERIA_Categoria]  WITH CHECK ADD  CONSTRAINT [FK_Cat_Padre] FOREIGN KEY([padre_id])
REFERENCES [dbo].[FLORERIA_Categoria] ([categoria_id])
GO
ALTER TABLE [dbo].[FLORERIA_Categoria] CHECK CONSTRAINT [FK_Cat_Padre]
GO
ALTER TABLE [dbo].[FLORERIA_Ciudad]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Ciudad_Depto] FOREIGN KEY([depto_id])
REFERENCES [dbo].[FLORERIA_Departamento] ([depto_id])
GO
ALTER TABLE [dbo].[FLORERIA_Ciudad] CHECK CONSTRAINT [FK_FLORERIA_Ciudad_Depto]
GO
ALTER TABLE [dbo].[FLORERIA_Config]  WITH CHECK ADD  CONSTRAINT [FK_Cfg_ModifPor] FOREIGN KEY([modificado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Config] CHECK CONSTRAINT [FK_Cfg_ModifPor]
GO
ALTER TABLE [dbo].[FLORERIA_Departamento]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Departamento_Pais] FOREIGN KEY([pais_id])
REFERENCES [dbo].[FLORERIA_Pais] ([pais_id])
GO
ALTER TABLE [dbo].[FLORERIA_Departamento] CHECK CONSTRAINT [FK_FLORERIA_Departamento_Pais]
GO
ALTER TABLE [dbo].[FLORERIA_Menu]  WITH CHECK ADD  CONSTRAINT [FK_Menu_Padre] FOREIGN KEY([padre_id])
REFERENCES [dbo].[FLORERIA_Menu] ([menu_id])
GO
ALTER TABLE [dbo].[FLORERIA_Menu] CHECK CONSTRAINT [FK_Menu_Padre]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Ciudad] FOREIGN KEY([ciudad_id])
REFERENCES [dbo].[FLORERIA_Ciudad] ([ciudad_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Ciudad]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_CreadoPor] FOREIGN KEY([creado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] CHECK CONSTRAINT [FK_FLORERIA_Pedido_CreadoPor]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_ModificadoPor] FOREIGN KEY([modificado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] CHECK CONSTRAINT [FK_FLORERIA_Pedido_ModificadoPor]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Slot] FOREIGN KEY([slot_id])
REFERENCES [dbo].[FLORERIA_Slot_Horario] ([slot_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Slot]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Sucursal] FOREIGN KEY([sucursal_id])
REFERENCES [dbo].[FLORERIA_Sucursal] ([sucursal_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Sucursal]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Zona] FOREIGN KEY([zona_id])
REFERENCES [dbo].[FLORERIA_Zona] ([zona_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Zona]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido]  WITH CHECK ADD  CONSTRAINT [FK_Pedido_SucursalPrepara] FOREIGN KEY([sucursal_prepara_id])
REFERENCES [dbo].[FLORERIA_Sucursal] ([sucursal_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] CHECK CONSTRAINT [FK_Pedido_SucursalPrepara]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Detalle]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Detalle_Pedido] FOREIGN KEY([pedido_id])
REFERENCES [dbo].[FLORERIA_Pedido] ([pedido_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Detalle] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Detalle_Pedido]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Detalle]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Detalle_Producto] FOREIGN KEY([producto_id])
REFERENCES [dbo].[FLORERIA_Producto] ([producto_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Detalle] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Detalle_Producto]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Detalle]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Detalle_Variacion] FOREIGN KEY([variacion_id])
REFERENCES [dbo].[FLORERIA_Producto_Variacion] ([variacion_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Detalle] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Detalle_Variacion]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Estado_Log]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Estado_Log_Pedido] FOREIGN KEY([pedido_id])
REFERENCES [dbo].[FLORERIA_Pedido] ([pedido_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Estado_Log] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Estado_Log_Pedido]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Estado_Log]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Estado_Log_Usuario] FOREIGN KEY([usuario_id])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Estado_Log] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Estado_Log_Usuario]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Pago_CreadoPor] FOREIGN KEY([creado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Pago_CreadoPor]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Pago_Pedido] FOREIGN KEY([pedido_id])
REFERENCES [dbo].[FLORERIA_Pedido] ([pedido_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Pago_Pedido]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Pago_PrePedido] FOREIGN KEY([prepedido_id])
REFERENCES [dbo].[FLORERIA_PrePedido] ([prepedido_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Pago_PrePedido]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Pago_VerificadoPor] FOREIGN KEY([verificado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Pago_VerificadoPor]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Reprogramacion]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Reprogramacion_Pedido] FOREIGN KEY([pedido_id])
REFERENCES [dbo].[FLORERIA_Pedido] ([pedido_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Reprogramacion] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Reprogramacion_Pedido]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Reprogramacion]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Reprogramacion_SlotAnt] FOREIGN KEY([slot_anterior_id])
REFERENCES [dbo].[FLORERIA_Slot_Horario] ([slot_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Reprogramacion] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Reprogramacion_SlotAnt]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Reprogramacion]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Reprogramacion_SlotNuevo] FOREIGN KEY([slot_nuevo_id])
REFERENCES [dbo].[FLORERIA_Slot_Horario] ([slot_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Reprogramacion] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Reprogramacion_SlotNuevo]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Reprogramacion]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Pedido_Reprogramacion_Usuario] FOREIGN KEY([usuario_id])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Reprogramacion] CHECK CONSTRAINT [FK_FLORERIA_Pedido_Reprogramacion_Usuario]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_PrePedido_Agente] FOREIGN KEY([agente_actual_id])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] CHECK CONSTRAINT [FK_FLORERIA_PrePedido_Agente]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_PrePedido_Ciudad] FOREIGN KEY([cliente_ciudad_id])
REFERENCES [dbo].[FLORERIA_Ciudad] ([ciudad_id])
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] CHECK CONSTRAINT [FK_FLORERIA_PrePedido_Ciudad]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_PrePedido_CreadoPor] FOREIGN KEY([creado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] CHECK CONSTRAINT [FK_FLORERIA_PrePedido_CreadoPor]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_PrePedido_ModificadoPor] FOREIGN KEY([modificado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] CHECK CONSTRAINT [FK_FLORERIA_PrePedido_ModificadoPor]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_PrePedido_Pais] FOREIGN KEY([cliente_pais_id])
REFERENCES [dbo].[FLORERIA_Pais] ([pais_id])
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] CHECK CONSTRAINT [FK_FLORERIA_PrePedido_Pais]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido_Agente_Log]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_PrePedido_Agente_Log_AgenteAnt] FOREIGN KEY([agente_anterior_id])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido_Agente_Log] CHECK CONSTRAINT [FK_FLORERIA_PrePedido_Agente_Log_AgenteAnt]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido_Agente_Log]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_PrePedido_Agente_Log_AgenteNuevo] FOREIGN KEY([agente_nuevo_id])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido_Agente_Log] CHECK CONSTRAINT [FK_FLORERIA_PrePedido_Agente_Log_AgenteNuevo]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido_Agente_Log]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_PrePedido_Agente_Log_PrePedido] FOREIGN KEY([prepedido_id])
REFERENCES [dbo].[FLORERIA_PrePedido] ([prepedido_id])
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido_Agente_Log] CHECK CONSTRAINT [FK_FLORERIA_PrePedido_Agente_Log_PrePedido]
GO
ALTER TABLE [dbo].[FLORERIA_Producto]  WITH CHECK ADD  CONSTRAINT [FK_Prod_Categoria] FOREIGN KEY([categoria_id])
REFERENCES [dbo].[FLORERIA_Categoria] ([categoria_id])
GO
ALTER TABLE [dbo].[FLORERIA_Producto] CHECK CONSTRAINT [FK_Prod_Categoria]
GO
ALTER TABLE [dbo].[FLORERIA_Producto]  WITH CHECK ADD  CONSTRAINT [FK_Prod_CreadoPor] FOREIGN KEY([creado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Producto] CHECK CONSTRAINT [FK_Prod_CreadoPor]
GO
ALTER TABLE [dbo].[FLORERIA_Producto]  WITH CHECK ADD  CONSTRAINT [FK_Prod_ModifPor] FOREIGN KEY([modificado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Producto] CHECK CONSTRAINT [FK_Prod_ModifPor]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Categoria]  WITH CHECK ADD  CONSTRAINT [FK_PC_Categoria] FOREIGN KEY([categoria_id])
REFERENCES [dbo].[FLORERIA_Categoria] ([categoria_id])
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Categoria] CHECK CONSTRAINT [FK_PC_Categoria]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Categoria]  WITH CHECK ADD  CONSTRAINT [FK_PC_CreadoPor] FOREIGN KEY([creado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Categoria] CHECK CONSTRAINT [FK_PC_CreadoPor]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Categoria]  WITH CHECK ADD  CONSTRAINT [FK_PC_Producto] FOREIGN KEY([producto_id])
REFERENCES [dbo].[FLORERIA_Producto] ([producto_id])
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Categoria] CHECK CONSTRAINT [FK_PC_Producto]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Disponibilidad]  WITH CHECK ADD  CONSTRAINT [FK_PD_ActualizadoPor] FOREIGN KEY([actualizado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Disponibilidad] CHECK CONSTRAINT [FK_PD_ActualizadoPor]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Disponibilidad]  WITH CHECK ADD  CONSTRAINT [FK_PD_Producto] FOREIGN KEY([producto_id])
REFERENCES [dbo].[FLORERIA_Producto] ([producto_id])
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Disponibilidad] CHECK CONSTRAINT [FK_PD_Producto]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Disponibilidad]  WITH CHECK ADD  CONSTRAINT [FK_PD_Variacion] FOREIGN KEY([variacion_id])
REFERENCES [dbo].[FLORERIA_Producto_Variacion] ([variacion_id])
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Disponibilidad] CHECK CONSTRAINT [FK_PD_Variacion]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Variacion]  WITH CHECK ADD  CONSTRAINT [FK_Var_CreadoPor] FOREIGN KEY([creado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Variacion] CHECK CONSTRAINT [FK_Var_CreadoPor]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Variacion]  WITH CHECK ADD  CONSTRAINT [FK_Var_ModifPor] FOREIGN KEY([modificado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Variacion] CHECK CONSTRAINT [FK_Var_ModifPor]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Variacion]  WITH CHECK ADD  CONSTRAINT [FK_Var_Producto] FOREIGN KEY([producto_id])
REFERENCES [dbo].[FLORERIA_Producto] ([producto_id])
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Variacion] CHECK CONSTRAINT [FK_Var_Producto]
GO
ALTER TABLE [dbo].[FLORERIA_Sesion]  WITH CHECK ADD  CONSTRAINT [FK_Ses_UsuarioFLO] FOREIGN KEY([usuario_id])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Sesion] CHECK CONSTRAINT [FK_Ses_UsuarioFLO]
GO
ALTER TABLE [dbo].[FLORERIA_Slot_Horario]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Slot_Horario_Ciudad] FOREIGN KEY([ciudad_id])
REFERENCES [dbo].[FLORERIA_Ciudad] ([ciudad_id])
GO
ALTER TABLE [dbo].[FLORERIA_Slot_Horario] CHECK CONSTRAINT [FK_FLORERIA_Slot_Horario_Ciudad]
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Sucursal_Ciudad] FOREIGN KEY([ciudad_id])
REFERENCES [dbo].[FLORERIA_Ciudad] ([ciudad_id])
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal] CHECK CONSTRAINT [FK_FLORERIA_Sucursal_Ciudad]
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal_Zona]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Sucursal_Zona_Sucursal] FOREIGN KEY([sucursal_id])
REFERENCES [dbo].[FLORERIA_Sucursal] ([sucursal_id])
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal_Zona] CHECK CONSTRAINT [FK_FLORERIA_Sucursal_Zona_Sucursal]
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal_Zona]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Sucursal_Zona_Zona] FOREIGN KEY([zona_id])
REFERENCES [dbo].[FLORERIA_Zona] ([zona_id])
GO
ALTER TABLE [dbo].[FLORERIA_Sucursal_Zona] CHECK CONSTRAINT [FK_FLORERIA_Sucursal_Zona_Zona]
GO
ALTER TABLE [dbo].[FLORERIA_TipoUsuario_Menu]  WITH CHECK ADD  CONSTRAINT [FK_TM_Menu1] FOREIGN KEY([menu_id])
REFERENCES [dbo].[FLORERIA_Menu] ([menu_id])
GO
ALTER TABLE [dbo].[FLORERIA_TipoUsuario_Menu] CHECK CONSTRAINT [FK_TM_Menu1]
GO
ALTER TABLE [dbo].[FLORERIA_TipoUsuario_Menu]  WITH CHECK ADD  CONSTRAINT [FK_TM_Tipo] FOREIGN KEY([tipo_id])
REFERENCES [dbo].[FLORERIA_TipoUsuario] ([tipo_id])
GO
ALTER TABLE [dbo].[FLORERIA_TipoUsuario_Menu] CHECK CONSTRAINT [FK_TM_Tipo]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario]  WITH CHECK ADD  CONSTRAINT [FK_Usu_Tipo] FOREIGN KEY([tipo_id])
REFERENCES [dbo].[FLORERIA_TipoUsuario] ([tipo_id])
GO
ALTER TABLE [dbo].[FLORERIA_Usuario] CHECK CONSTRAINT [FK_Usu_Tipo]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario_Menu]  WITH CHECK ADD  CONSTRAINT [FK_UM_Menu] FOREIGN KEY([menu_id])
REFERENCES [dbo].[FLORERIA_Menu] ([menu_id])
GO
ALTER TABLE [dbo].[FLORERIA_Usuario_Menu] CHECK CONSTRAINT [FK_UM_Menu]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario_Menu]  WITH CHECK ADD  CONSTRAINT [FK_UM_UsuarioFLO] FOREIGN KEY([usuario_id])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Usuario_Menu] CHECK CONSTRAINT [FK_UM_UsuarioFLO]
GO
ALTER TABLE [dbo].[FLORERIA_Zona]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Zona_Ciudad] FOREIGN KEY([ciudad_id])
REFERENCES [dbo].[FLORERIA_Ciudad] ([ciudad_id])
GO
ALTER TABLE [dbo].[FLORERIA_Zona] CHECK CONSTRAINT [FK_FLORERIA_Zona_Ciudad]
GO
ALTER TABLE [dbo].[FLORERIA_Zona_Express]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Zona_Express_Zona] FOREIGN KEY([zona_id])
REFERENCES [dbo].[FLORERIA_Zona] ([zona_id])
GO
ALTER TABLE [dbo].[FLORERIA_Zona_Express] CHECK CONSTRAINT [FK_FLORERIA_Zona_Express_Zona]
GO
ALTER TABLE [dbo].[FLORERIA_Zona_Tarifa]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Zona_Tarifa_Usuario] FOREIGN KEY([creado_por])
REFERENCES [dbo].[FLORERIA_Usuario] ([usuario_id])
GO
ALTER TABLE [dbo].[FLORERIA_Zona_Tarifa] CHECK CONSTRAINT [FK_FLORERIA_Zona_Tarifa_Usuario]
GO
ALTER TABLE [dbo].[FLORERIA_Zona_Tarifa]  WITH CHECK ADD  CONSTRAINT [FK_FLORERIA_Zona_Tarifa_Zona] FOREIGN KEY([zona_id])
REFERENCES [dbo].[FLORERIA_Zona] ([zona_id])
GO
ALTER TABLE [dbo].[FLORERIA_Zona_Tarifa] CHECK CONSTRAINT [FK_FLORERIA_Zona_Tarifa_Zona]
GO
ALTER TABLE [dbo].[FLORERIA_Auditoria]  WITH CHECK ADD  CONSTRAINT [CK_Accion] CHECK  (([accion]='ELIMINAR' OR [accion]='MODIFICAR' OR [accion]='INSERTAR'))
GO
ALTER TABLE [dbo].[FLORERIA_Auditoria] CHECK CONSTRAINT [CK_Accion]
GO
ALTER TABLE [dbo].[FLORERIA_Categoria]  WITH CHECK ADD CHECK  (([wc_sync_estado]='IGNORAR' OR [wc_sync_estado]='ERROR' OR [wc_sync_estado]='PENDIENTE' OR [wc_sync_estado]='SINCRONIZADO'))
GO
ALTER TABLE [dbo].[FLORERIA_Pedido]  WITH CHECK ADD  CONSTRAINT [CK_FLORERIA_Pedido_EstadoPago] CHECK  (([estado_pago]='REEMBOLSADO' OR [estado_pago]='PAGADO' OR [estado_pago]='ANTICIPO' OR [estado_pago]='PENDIENTE'))
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] CHECK CONSTRAINT [CK_FLORERIA_Pedido_EstadoPago]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido]  WITH CHECK ADD  CONSTRAINT [CK_FLORERIA_Pedido_TipoEntrega] CHECK  (([tipo_entrega]='RECOJO_SUCURSAL' OR [tipo_entrega]='DOMICILIO'))
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] CHECK CONSTRAINT [CK_FLORERIA_Pedido_TipoEntrega]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido]  WITH CHECK ADD  CONSTRAINT [CK_FLORERIA_Pedido_WcSync] CHECK  (([wc_sync_estado]='ACTUALIZADO_WEBHOOK' OR [wc_sync_estado]='RECIBIDO_WEBHOOK' OR [wc_sync_estado]='IGNORAR' OR [wc_sync_estado]='ERROR' OR [wc_sync_estado]='SINCRONIZADO' OR [wc_sync_estado]='PENDIENTE'))
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] CHECK CONSTRAINT [CK_FLORERIA_Pedido_WcSync]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido]  WITH CHECK ADD  CONSTRAINT [CK_Pedido_TipoOcacion] CHECK  (([tipo_ocacion]='OTRO' OR [tipo_ocacion]='GRADUACION' OR [tipo_ocacion]='NACIMIENTO' OR [tipo_ocacion]='AMOR' OR [tipo_ocacion]='AGRADECIMIENTO' OR [tipo_ocacion]='CONDOLENCIAS' OR [tipo_ocacion]='ANIVERSARIO' OR [tipo_ocacion]='CUMPLEANOS'))
GO
ALTER TABLE [dbo].[FLORERIA_Pedido] CHECK CONSTRAINT [CK_Pedido_TipoOcacion]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago]  WITH CHECK ADD  CONSTRAINT [CK_FLORERIA_Pedido_Pago_Estado] CHECK  (([estado]='RECHAZADO' OR [estado]='VERIFICADO' OR [estado]='PENDIENTE'))
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago] CHECK CONSTRAINT [CK_FLORERIA_Pedido_Pago_Estado]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago]  WITH CHECK ADD  CONSTRAINT [CK_FLORERIA_Pedido_Pago_Tipo] CHECK  (([tipo_pago]='TOTAL' OR [tipo_pago]='SALDO' OR [tipo_pago]='ANTICIPO'))
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago] CHECK CONSTRAINT [CK_FLORERIA_Pedido_Pago_Tipo]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago]  WITH CHECK ADD  CONSTRAINT [CK_Pago_Metodo] CHECK  (([metodo_pago]='PIX' OR [metodo_pago]='YAPE' OR [metodo_pago]='CRIPTO' OR [metodo_pago]='PAYPAL' OR [metodo_pago]='PAGOMOVIL' OR [metodo_pago]='TRANSFERENCIA' OR [metodo_pago]='QR' OR [metodo_pago]='TARJETA' OR [metodo_pago]='EFECTIVO'))
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Pago] CHECK CONSTRAINT [CK_Pago_Metodo]
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Reprogramacion]  WITH CHECK ADD  CONSTRAINT [CK_FLORERIA_Pedido_Reprogramacion_Solicitado] CHECK  (([solicitado_por]='SISTEMA' OR [solicitado_por]='AGENTE' OR [solicitado_por]='CLIENTE'))
GO
ALTER TABLE [dbo].[FLORERIA_Pedido_Reprogramacion] CHECK CONSTRAINT [CK_FLORERIA_Pedido_Reprogramacion_Solicitado]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido]  WITH CHECK ADD  CONSTRAINT [CK_FLORERIA_PrePedido_Estado] CHECK  (([estado]='CANCELADO' OR [estado]='CONVERTIDO' OR [estado]='PAGADO' OR [estado]='ESPERANDO_PAGO' OR [estado]='COMPLETADO' OR [estado]='FORM_ENVIADO' OR [estado]='BORRADOR'))
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] CHECK CONSTRAINT [CK_FLORERIA_PrePedido_Estado]
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido]  WITH CHECK ADD  CONSTRAINT [CK_FLORERIA_PrePedido_TipoRegistro] CHECK  (([tipo_registro]='VENTA_ANTIGUA' OR [tipo_registro]='VENTA_TIENDA' OR [tipo_registro]='PRE_PEDIDO'))
GO
ALTER TABLE [dbo].[FLORERIA_PrePedido] CHECK CONSTRAINT [CK_FLORERIA_PrePedido_TipoRegistro]
GO
ALTER TABLE [dbo].[FLORERIA_Producto]  WITH CHECK ADD CHECK  (([wc_sync_estado]='IGNORAR' OR [wc_sync_estado]='ERROR' OR [wc_sync_estado]='PENDIENTE' OR [wc_sync_estado]='SINCRONIZADO'))
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Disponibilidad]  WITH CHECK ADD  CONSTRAINT [CK_PD_Operador] CHECK  (([sucursal_id] IS NOT NULL AND [aliado_id] IS NULL OR [sucursal_id] IS NULL AND [aliado_id] IS NOT NULL))
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Disponibilidad] CHECK CONSTRAINT [CK_PD_Operador]
GO
ALTER TABLE [dbo].[FLORERIA_Producto_Variacion]  WITH CHECK ADD CHECK  (([wc_sync_estado]='IGNORAR' OR [wc_sync_estado]='ERROR' OR [wc_sync_estado]='PENDIENTE' OR [wc_sync_estado]='SINCRONIZADO'))
GO
ALTER TABLE [dbo].[FLORERIA_Sesion]  WITH CHECK ADD  CONSTRAINT [CK_CerradaPor] CHECK  (([cerrada_por]='NUEVA_SESION' OR [cerrada_por]='SISTEMA' OR [cerrada_por]='USUARIO'))
GO
ALTER TABLE [dbo].[FLORERIA_Sesion] CHECK CONSTRAINT [CK_CerradaPor]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario]  WITH CHECK ADD  CONSTRAINT [CK_Carnet] CHECK  ((NOT [carnet] like '%[^0-9]%' AND (len([carnet])>=(7) AND len([carnet])<=(8))))
GO
ALTER TABLE [dbo].[FLORERIA_Usuario] CHECK CONSTRAINT [CK_Carnet]
GO
ALTER TABLE [dbo].[FLORERIA_Usuario_Menu]  WITH CHECK ADD  CONSTRAINT [CK_Excepcion] CHECK  (([tipo_excepcion]='QUITAR' OR [tipo_excepcion]='AGREGAR'))
GO
ALTER TABLE [dbo].[FLORERIA_Usuario_Menu] CHECK CONSTRAINT [CK_Excepcion]
GO
ALTER TABLE [dbo].[FLORERIA_Zona]  WITH CHECK ADD  CONSTRAINT [CK_FLORERIA_Zona_Tipo] CHECK  (([tipo]='SIN_COBERTURA' OR [tipo]='RECOJO_SUCURSAL' OR [tipo]='DELIVERY'))
GO
ALTER TABLE [dbo].[FLORERIA_Zona] CHECK CONSTRAINT [CK_FLORERIA_Zona_Tipo]
GO
