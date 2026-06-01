-- =============================================
-- SISCONBOL_FLORERIA - MODULO CRM / ANALISIS WOOCOMMERCE
-- Archivo: 06_SPS_WC_CRM.sql
-- Fecha: 2026-05-31
--
-- Modulo INDEPENDIENTE de las tablas operativas.
-- NO toca FLORERIA_Pedido / FLORERIA_PrePedido / FLORERIA_Producto.
--
-- Dos capas:
--   A) ESPEJO CRUDO de WooCommerce  -> prefijo FLORERIA_WC_
--      Copia fiel de orders / products / categories, con json_raw
--      para no perder nada. Se llena por extraccion (por tramos).
--   B) ANALISIS DERIVADO            -> prefijo FLORERIA_CRM_
--      Cliente deduplicado + RFM + hashes Google Ads + segmentos.
--      Se RECALCULA desde la capa A (es desechable).
--
-- Script idempotente: tablas con IF OBJECT_ID, SPs/funciones con
-- CREATE OR ALTER. Se puede correr varias veces.
-- (Este script YA fue aplicado en la base via MCP el 2026-05-31.)
-- =============================================
USE [SISCONBOL]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================================
-- CAPA A - ESPEJO CRUDO DE WOOCOMMERCE
-- =============================================================

-- FLORERIA_WC_Sync_Log : bitacora de cada corrida de extraccion
IF OBJECT_ID('dbo.FLORERIA_WC_Sync_Log','U') IS NULL
CREATE TABLE dbo.FLORERIA_WC_Sync_Log(
  extraccion_id int IDENTITY(1,1) NOT NULL,
  tipo varchar(20) NOT NULL,                 -- ORDERS / PRODUCTS / CATEGORIES
  fecha_desde date NULL,
  fecha_hasta date NULL,
  status_filtro varchar(30) NULL,
  total_descargados int NOT NULL CONSTRAINT DF_WCSync_tot DEFAULT(0),
  nuevos int NOT NULL CONSTRAINT DF_WCSync_new DEFAULT(0),
  actualizados int NOT NULL CONSTRAINT DF_WCSync_upd DEFAULT(0),
  errores int NOT NULL CONSTRAINT DF_WCSync_err DEFAULT(0),
  ultima_pagina_ok int NOT NULL CONSTRAINT DF_WCSync_pag DEFAULT(0),
  usuario_id int NULL,
  iniciado_en datetime NOT NULL CONSTRAINT DF_WCSync_ini DEFAULT(GETDATE()),
  finalizado_en datetime NULL,
  estado varchar(15) NOT NULL CONSTRAINT DF_WCSync_est DEFAULT('EN_PROCESO'), -- EN_PROCESO / OK / ERROR
  log_resumen nvarchar(max) NULL,
  CONSTRAINT PK_FLORERIA_WC_Sync_Log PRIMARY KEY CLUSTERED (extraccion_id ASC));
GO

-- FLORERIA_WC_Order : espejo de /orders (toda fecha, todo estado)
IF OBJECT_ID('dbo.FLORERIA_WC_Order','U') IS NULL
CREATE TABLE dbo.FLORERIA_WC_Order(
  wc_order_id int NOT NULL,                  -- id de WC (clave natural)
  number varchar(30) NULL,
  order_key varchar(60) NULL,
  status varchar(30) NULL,
  currency char(3) NULL,
  date_created datetime NULL,
  date_paid datetime NULL,
  date_modified datetime NULL,
  customer_id int NULL,                      -- 0 = guest checkout
  billing_nombre varchar(150) NULL,
  billing_apellidos varchar(150) NULL,
  billing_email varchar(200) NULL,
  billing_email_norm varchar(200) NULL,      -- LOWER(TRIM(email)) para dedup
  billing_phone varchar(40) NULL,
  billing_phone_norm varchar(40) NULL,       -- solo digitos
  shipping_nombre varchar(200) NULL,
  shipping_phone varchar(40) NULL,
  shipping_direccion varchar(400) NULL,
  shipping_ciudad varchar(100) NULL,
  shipping_state varchar(100) NULL,
  payment_method varchar(50) NULL,
  payment_method_title varchar(120) NULL,
  subtotal decimal(18,2) NOT NULL CONSTRAINT DF_WCOrder_sub DEFAULT(0),
  shipping_total decimal(18,2) NOT NULL CONSTRAINT DF_WCOrder_shp DEFAULT(0),
  discount_total decimal(18,2) NOT NULL CONSTRAINT DF_WCOrder_dsc DEFAULT(0),
  total decimal(18,2) NOT NULL CONSTRAINT DF_WCOrder_tot DEFAULT(0),
  total_usd decimal(18,2) NOT NULL CONSTRAINT DF_WCOrder_usd DEFAULT(0),
  woocs_rate decimal(18,6) NOT NULL CONSTRAINT DF_WCOrder_rt DEFAULT(0),
  delivery_date date NULL,                   -- meta delivery_date / pickup_date
  delivery_time varchar(40) NULL,
  tipo_ocacion varchar(60) NULL,
  cantidad_items int NOT NULL CONSTRAINT DF_WCOrder_cit DEFAULT(0),
  json_raw nvarchar(max) NULL,               -- payload completo de WC
  extraccion_id int NULL,
  creado_en datetime NOT NULL CONSTRAINT DF_WCOrder_cre DEFAULT(GETDATE()),
  actualizado_en datetime NULL,
  CONSTRAINT PK_FLORERIA_WC_Order PRIMARY KEY CLUSTERED (wc_order_id ASC));
GO

-- FLORERIA_WC_Order_Item : line_items de cada orden
IF OBJECT_ID('dbo.FLORERIA_WC_Order_Item','U') IS NULL
CREATE TABLE dbo.FLORERIA_WC_Order_Item(
  order_item_id int IDENTITY(1,1) NOT NULL,
  wc_order_id int NOT NULL,
  wc_line_item_id int NULL,
  wc_product_id int NULL,
  wc_variation_id int NULL,
  nombre varchar(300) NULL,
  sku varchar(100) NULL,
  cantidad int NOT NULL CONSTRAINT DF_WCItem_cant DEFAULT(1),
  precio_unitario decimal(18,2) NOT NULL CONSTRAINT DF_WCItem_pu DEFAULT(0),
  subtotal decimal(18,2) NOT NULL CONSTRAINT DF_WCItem_sub DEFAULT(0),
  total decimal(18,2) NOT NULL CONSTRAINT DF_WCItem_tot DEFAULT(0),
  CONSTRAINT PK_FLORERIA_WC_Order_Item PRIMARY KEY CLUSTERED (order_item_id ASC));
GO

-- FLORERIA_WC_Order_Meta : meta_data key/value de cada orden
IF OBJECT_ID('dbo.FLORERIA_WC_Order_Meta','U') IS NULL
CREATE TABLE dbo.FLORERIA_WC_Order_Meta(
  order_meta_id int IDENTITY(1,1) NOT NULL,
  wc_order_id int NOT NULL,
  meta_key varchar(200) NULL,
  meta_value nvarchar(max) NULL,
  CONSTRAINT PK_FLORERIA_WC_Order_Meta PRIMARY KEY CLUSTERED (order_meta_id ASC));
GO

-- FLORERIA_WC_Product : espejo de /products
IF OBJECT_ID('dbo.FLORERIA_WC_Product','U') IS NULL
CREATE TABLE dbo.FLORERIA_WC_Product(
  wc_product_id int NOT NULL,
  name varchar(300) NULL,
  slug varchar(300) NULL,
  sku varchar(100) NULL,
  type varchar(30) NULL,
  status varchar(20) NULL,
  regular_price decimal(12,2) NOT NULL CONSTRAINT DF_WCProd_rp DEFAULT(0),
  sale_price decimal(12,2) NOT NULL CONSTRAINT DF_WCProd_sp DEFAULT(0),
  stock_status varchar(20) NULL,
  total_sales int NOT NULL CONSTRAINT DF_WCProd_ts DEFAULT(0),
  date_created datetime NULL,
  date_modified datetime NULL,
  json_raw nvarchar(max) NULL,
  extraccion_id int NULL,
  creado_en datetime NOT NULL CONSTRAINT DF_WCProd_cre DEFAULT(GETDATE()),
  actualizado_en datetime NULL,
  CONSTRAINT PK_FLORERIA_WC_Product PRIMARY KEY CLUSTERED (wc_product_id ASC));
GO

-- FLORERIA_WC_Product_Category : espejo de /products/categories
IF OBJECT_ID('dbo.FLORERIA_WC_Product_Category','U') IS NULL
CREATE TABLE dbo.FLORERIA_WC_Product_Category(
  wc_category_id int NOT NULL,
  name varchar(200) NULL,
  slug varchar(200) NULL,
  parent int NOT NULL CONSTRAINT DF_WCCat_par DEFAULT(0),
  count int NOT NULL CONSTRAINT DF_WCCat_cnt DEFAULT(0),
  json_raw nvarchar(max) NULL,
  extraccion_id int NULL,
  creado_en datetime NOT NULL CONSTRAINT DF_WCCat_cre DEFAULT(GETDATE()),
  actualizado_en datetime NULL,
  CONSTRAINT PK_FLORERIA_WC_Product_Category PRIMARY KEY CLUSTERED (wc_category_id ASC));
GO

-- FLORERIA_WC_Product_Cat_Map : producto <-> categoria (N:N)
IF OBJECT_ID('dbo.FLORERIA_WC_Product_Cat_Map','U') IS NULL
CREATE TABLE dbo.FLORERIA_WC_Product_Cat_Map(
  wc_product_id int NOT NULL,
  wc_category_id int NOT NULL,
  CONSTRAINT PK_FLORERIA_WC_Product_Cat_Map PRIMARY KEY CLUSTERED (wc_product_id ASC, wc_category_id ASC));
GO

-- =============================================================
-- CAPA B - ANALISIS DERIVADO (recalculable desde la capa A)
-- =============================================================

-- FLORERIA_CRM_Cliente : cliente deduplicado + RFM + hashes
IF OBJECT_ID('dbo.FLORERIA_CRM_Cliente','U') IS NULL
CREATE TABLE dbo.FLORERIA_CRM_Cliente(
  cliente_crm_id int IDENTITY(1,1) NOT NULL,
  email_norm varchar(200) NOT NULL,          -- clave de dedup
  email_original varchar(200) NULL,
  telefono_norm varchar(40) NULL,
  nombre varchar(150) NULL,
  apellidos varchar(150) NULL,
  ciudad_top varchar(100) NULL,
  zona_top varchar(100) NULL,
  total_pedidos int NOT NULL CONSTRAINT DF_CRMCli_tp DEFAULT(0),
  total_gastado_bs decimal(14,2) NOT NULL CONSTRAINT DF_CRMCli_tg DEFAULT(0),
  ticket_promedio_bs decimal(12,2) NOT NULL CONSTRAINT DF_CRMCli_tk DEFAULT(0),
  primera_compra date NULL,
  ultima_compra date NULL,
  dias_desde_ultima int NULL,
  frecuencia_dias_prom int NULL,
  r_score tinyint NULL,
  f_score tinyint NULL,
  m_score tinyint NULL,
  rfm_segmento varchar(30) NULL,
  ocasion_top varchar(60) NULL,
  producto_top varchar(300) NULL,
  metodo_pago_top varchar(120) NULL,
  email_sha256 char(64) NULL,                -- Google Ads Customer Match (SHA256 hex minuscula)
  telefono_sha256 char(64) NULL,
  actualizado_en datetime NOT NULL CONSTRAINT DF_CRMCli_act DEFAULT(GETDATE()),
  CONSTRAINT PK_FLORERIA_CRM_Cliente PRIMARY KEY CLUSTERED (cliente_crm_id ASC),
  CONSTRAINT UQ_FLORERIA_CRM_Cliente_Email UNIQUE NONCLUSTERED (email_norm ASC));
GO

-- FLORERIA_CRM_Segmento : definicion de segmentos
IF OBJECT_ID('dbo.FLORERIA_CRM_Segmento','U') IS NULL
CREATE TABLE dbo.FLORERIA_CRM_Segmento(
  segmento_id int IDENTITY(1,1) NOT NULL,
  nombre varchar(80) NOT NULL,
  descripcion varchar(300) NULL,
  tipo varchar(15) NOT NULL CONSTRAINT DF_CRMSeg_tipo DEFAULT('RFM'),   -- RFM / MANUAL / FILTRO
  criterio_json nvarchar(max) NULL,
  color varchar(20) NULL,
  activo bit NOT NULL CONSTRAINT DF_CRMSeg_act DEFAULT(1),
  creado_en datetime NOT NULL CONSTRAINT DF_CRMSeg_cre DEFAULT(GETDATE()),
  CONSTRAINT PK_FLORERIA_CRM_Segmento PRIMARY KEY CLUSTERED (segmento_id ASC));
GO

-- FLORERIA_CRM_Cliente_Segmento : membresia N:N
IF OBJECT_ID('dbo.FLORERIA_CRM_Cliente_Segmento','U') IS NULL
CREATE TABLE dbo.FLORERIA_CRM_Cliente_Segmento(
  cliente_crm_id int NOT NULL,
  segmento_id int NOT NULL,
  asignado_en datetime NOT NULL CONSTRAINT DF_CRMCliSeg_asg DEFAULT(GETDATE()),
  CONSTRAINT PK_FLORERIA_CRM_Cliente_Segmento PRIMARY KEY CLUSTERED (cliente_crm_id ASC, segmento_id ASC));
GO

-- FLORERIA_CRM_Export_Log : auditoria de exportaciones
IF OBJECT_ID('dbo.FLORERIA_CRM_Export_Log','U') IS NULL
CREATE TABLE dbo.FLORERIA_CRM_Export_Log(
  export_id int IDENTITY(1,1) NOT NULL,
  segmento_id int NULL,
  formato varchar(20) NOT NULL,              -- CSV_GOOGLEADS / CSV_GENERICO / EXCEL
  total_filas int NOT NULL CONSTRAINT DF_CRMExp_tf DEFAULT(0),
  incluye_hashes bit NOT NULL CONSTRAINT DF_CRMExp_ih DEFAULT(0),
  usuario_id int NULL,
  exportado_en datetime NOT NULL CONSTRAINT DF_CRMExp_exp DEFAULT(GETDATE()),
  CONSTRAINT PK_FLORERIA_CRM_Export_Log PRIMARY KEY CLUSTERED (export_id ASC));
GO

-- =============================================================
-- INDICES
-- =============================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_WC_Order_email_norm')
  CREATE NONCLUSTERED INDEX IX_WC_Order_email_norm ON dbo.FLORERIA_WC_Order(billing_email_norm ASC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_WC_Order_date_created')
  CREATE NONCLUSTERED INDEX IX_WC_Order_date_created ON dbo.FLORERIA_WC_Order(date_created ASC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_WC_Order_status')
  CREATE NONCLUSTERED INDEX IX_WC_Order_status ON dbo.FLORERIA_WC_Order(status ASC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_WC_OrderItem_order')
  CREATE NONCLUSTERED INDEX IX_WC_OrderItem_order ON dbo.FLORERIA_WC_Order_Item(wc_order_id ASC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_WC_OrderItem_product')
  CREATE NONCLUSTERED INDEX IX_WC_OrderItem_product ON dbo.FLORERIA_WC_Order_Item(wc_product_id ASC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_WC_OrderMeta_order')
  CREATE NONCLUSTERED INDEX IX_WC_OrderMeta_order ON dbo.FLORERIA_WC_Order_Meta(wc_order_id ASC);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_CRM_Cliente_rfm')
  CREATE NONCLUSTERED INDEX IX_CRM_Cliente_rfm ON dbo.FLORERIA_CRM_Cliente(rfm_segmento ASC);
GO

-- =============================================================
-- FUNCIONES auxiliares
-- =============================================================

-- Solo digitos de un string (normalizar telefonos)
CREATE OR ALTER FUNCTION dbo.FLORERIA_CRM_fn_SoloDigitos (@texto varchar(100))
RETURNS varchar(100)
AS
BEGIN
    IF @texto IS NULL RETURN NULL;
    DECLARE @out varchar(100) = '';
    DECLARE @i int = 1, @c char(1);
    WHILE @i <= LEN(@texto)
    BEGIN
        SET @c = SUBSTRING(@texto, @i, 1);
        IF @c LIKE '[0-9]' SET @out = @out + @c;
        SET @i = @i + 1;
    END
    RETURN @out;
END
GO

-- Telefono a E.164 Bolivia (+591XXXXXXXX) para Google Ads
CREATE OR ALTER FUNCTION dbo.FLORERIA_CRM_fn_TelefonoE164 (@telefono varchar(100))
RETURNS varchar(40)
AS
BEGIN
    DECLARE @d varchar(100) = dbo.FLORERIA_CRM_fn_SoloDigitos(@telefono);
    IF @d IS NULL OR LEN(@d) = 0 RETURN NULL;
    IF LEFT(@d, 3) = '591' RETURN '+' + @d;          -- ya trae prefijo pais
    IF LEN(@d) = 8 RETURN '+591' + @d;               -- celular boliviano local
    RETURN '+' + @d;                                 -- otro caso: mejor esfuerzo
END
GO

-- SHA256 hex minuscula (Customer Match de Google Ads)
CREATE OR ALTER FUNCTION dbo.FLORERIA_CRM_fn_Sha256Hex (@texto varchar(400))
RETURNS char(64)
AS
BEGIN
    IF @texto IS NULL OR LEN(@texto) = 0 RETURN NULL;
    RETURN LOWER(CONVERT(char(64), HASHBYTES('SHA2_256', CONVERT(varchar(400), @texto)), 2));
END
GO

-- =============================================================
-- SPs - CAPA A : extraccion / upsert del espejo
-- =============================================================

-- Iniciar una corrida de extraccion (devuelve extraccion_id)
CREATE OR ALTER PROCEDURE dbo.FLORERIA_WC_sp_Sync_Iniciar
    @tipo varchar(20),
    @fecha_desde date = NULL,
    @fecha_hasta date = NULL,
    @status_filtro varchar(30) = NULL,
    @usuario_id int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO FLORERIA_WC_Sync_Log (tipo, fecha_desde, fecha_hasta, status_filtro, usuario_id, iniciado_en, estado)
    VALUES (@tipo, @fecha_desde, @fecha_hasta, @status_filtro, @usuario_id, GETDATE(), 'EN_PROCESO');
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS extraccion_id;
END
GO

-- Finalizar una corrida de extraccion
CREATE OR ALTER PROCEDURE dbo.FLORERIA_WC_sp_Sync_Finalizar
    @extraccion_id int,
    @total_descargados int,
    @nuevos int,
    @actualizados int,
    @errores int,
    @ultima_pagina_ok int,
    @estado varchar(15),
    @log_resumen nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE FLORERIA_WC_Sync_Log
    SET total_descargados=@total_descargados, nuevos=@nuevos, actualizados=@actualizados,
        errores=@errores, ultima_pagina_ok=@ultima_pagina_ok, estado=@estado,
        log_resumen=@log_resumen, finalizado_en=GETDATE()
    WHERE extraccion_id=@extraccion_id;
END
GO

-- Upsert de una ORDEN (cabecera). Devuelve 'I' o 'U'.
-- Borra items y meta previos para que el llamador los re-inserte.
CREATE OR ALTER PROCEDURE dbo.FLORERIA_WC_sp_Order_Upsert
    @wc_order_id int,
    @number varchar(30)=NULL, @order_key varchar(60)=NULL, @status varchar(30)=NULL, @currency char(3)=NULL,
    @date_created datetime=NULL, @date_paid datetime=NULL, @date_modified datetime=NULL, @customer_id int=NULL,
    @billing_nombre varchar(150)=NULL, @billing_apellidos varchar(150)=NULL, @billing_email varchar(200)=NULL, @billing_phone varchar(40)=NULL,
    @shipping_nombre varchar(200)=NULL, @shipping_phone varchar(40)=NULL, @shipping_direccion varchar(400)=NULL, @shipping_ciudad varchar(100)=NULL, @shipping_state varchar(100)=NULL,
    @payment_method varchar(50)=NULL, @payment_method_title varchar(120)=NULL,
    @subtotal decimal(18,2)=0, @shipping_total decimal(18,2)=0, @discount_total decimal(18,2)=0, @total decimal(18,2)=0, @woocs_rate decimal(18,6)=0,
    @delivery_date date=NULL, @delivery_time varchar(40)=NULL, @tipo_ocacion varchar(60)=NULL, @cantidad_items int=0,
    @json_raw nvarchar(max)=NULL, @extraccion_id int=NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @email_norm varchar(200) = NULLIF(LOWER(LTRIM(RTRIM(@billing_email))), '');
    DECLARE @phone_norm varchar(40)  = NULLIF(dbo.FLORERIA_CRM_fn_SoloDigitos(@billing_phone), '');
    DECLARE @total_usd decimal(18,2) = CASE WHEN @woocs_rate > 0 THEN ROUND(@total * @woocs_rate, 2) ELSE 0 END;
    DECLARE @accion char(1);
    IF EXISTS (SELECT 1 FROM FLORERIA_WC_Order WHERE wc_order_id=@wc_order_id)
    BEGIN
        UPDATE FLORERIA_WC_Order SET
            number=@number, order_key=@order_key, status=@status, currency=@currency,
            date_created=@date_created, date_paid=@date_paid, date_modified=@date_modified, customer_id=@customer_id,
            billing_nombre=@billing_nombre, billing_apellidos=@billing_apellidos, billing_email=@billing_email, billing_email_norm=@email_norm,
            billing_phone=@billing_phone, billing_phone_norm=@phone_norm,
            shipping_nombre=@shipping_nombre, shipping_phone=@shipping_phone, shipping_direccion=@shipping_direccion, shipping_ciudad=@shipping_ciudad, shipping_state=@shipping_state,
            payment_method=@payment_method, payment_method_title=@payment_method_title,
            subtotal=@subtotal, shipping_total=@shipping_total, discount_total=@discount_total, total=@total, total_usd=@total_usd, woocs_rate=@woocs_rate,
            delivery_date=@delivery_date, delivery_time=@delivery_time, tipo_ocacion=@tipo_ocacion, cantidad_items=@cantidad_items,
            json_raw=@json_raw, extraccion_id=@extraccion_id, actualizado_en=GETDATE()
        WHERE wc_order_id=@wc_order_id;
        SET @accion='U';
    END
    ELSE
    BEGIN
        INSERT INTO FLORERIA_WC_Order (wc_order_id, number, order_key, status, currency, date_created, date_paid, date_modified, customer_id,
            billing_nombre, billing_apellidos, billing_email, billing_email_norm, billing_phone, billing_phone_norm,
            shipping_nombre, shipping_phone, shipping_direccion, shipping_ciudad, shipping_state, payment_method, payment_method_title,
            subtotal, shipping_total, discount_total, total, total_usd, woocs_rate, delivery_date, delivery_time, tipo_ocacion, cantidad_items, json_raw, extraccion_id, creado_en)
        VALUES (@wc_order_id, @number, @order_key, @status, @currency, @date_created, @date_paid, @date_modified, @customer_id,
            @billing_nombre, @billing_apellidos, @billing_email, @email_norm, @billing_phone, @phone_norm,
            @shipping_nombre, @shipping_phone, @shipping_direccion, @shipping_ciudad, @shipping_state, @payment_method, @payment_method_title,
            @subtotal, @shipping_total, @discount_total, @total, @total_usd, @woocs_rate, @delivery_date, @delivery_time, @tipo_ocacion, @cantidad_items, @json_raw, @extraccion_id, GETDATE());
        SET @accion='I';
    END
    DELETE FROM FLORERIA_WC_Order_Item WHERE wc_order_id=@wc_order_id;
    DELETE FROM FLORERIA_WC_Order_Meta WHERE wc_order_id=@wc_order_id;
    SELECT @accion AS accion;
END
GO

-- Insertar un line_item de una orden
CREATE OR ALTER PROCEDURE dbo.FLORERIA_WC_sp_OrderItem_Insert
    @wc_order_id int, @wc_line_item_id int=NULL, @wc_product_id int=NULL, @wc_variation_id int=NULL,
    @nombre varchar(300)=NULL, @sku varchar(100)=NULL, @cantidad int=1, @precio_unitario decimal(18,2)=0, @subtotal decimal(18,2)=0, @total decimal(18,2)=0
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO FLORERIA_WC_Order_Item (wc_order_id, wc_line_item_id, wc_product_id, wc_variation_id, nombre, sku, cantidad, precio_unitario, subtotal, total)
    VALUES (@wc_order_id, @wc_line_item_id, @wc_product_id, @wc_variation_id, @nombre, @sku, @cantidad, @precio_unitario, @subtotal, @total);
END
GO

-- Insertar un meta_data de una orden
CREATE OR ALTER PROCEDURE dbo.FLORERIA_WC_sp_OrderMeta_Insert
    @wc_order_id int, @meta_key varchar(200)=NULL, @meta_value nvarchar(max)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO FLORERIA_WC_Order_Meta (wc_order_id, meta_key, meta_value)
    VALUES (@wc_order_id, @meta_key, @meta_value);
END
GO

-- Upsert de un PRODUCTO. Devuelve 'I' o 'U'.
CREATE OR ALTER PROCEDURE dbo.FLORERIA_WC_sp_Product_Upsert
    @wc_product_id int, @name varchar(300)=NULL, @slug varchar(300)=NULL, @sku varchar(100)=NULL, @type varchar(30)=NULL, @status varchar(20)=NULL,
    @regular_price decimal(12,2)=0, @sale_price decimal(12,2)=0, @stock_status varchar(20)=NULL, @total_sales int=0,
    @date_created datetime=NULL, @date_modified datetime=NULL, @json_raw nvarchar(max)=NULL, @extraccion_id int=NULL, @categorias_csv varchar(max)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @accion char(1);
    IF EXISTS (SELECT 1 FROM FLORERIA_WC_Product WHERE wc_product_id=@wc_product_id)
    BEGIN
        UPDATE FLORERIA_WC_Product SET name=@name, slug=@slug, sku=@sku, type=@type, status=@status,
            regular_price=@regular_price, sale_price=@sale_price, stock_status=@stock_status, total_sales=@total_sales,
            date_created=@date_created, date_modified=@date_modified, json_raw=@json_raw, extraccion_id=@extraccion_id, actualizado_en=GETDATE()
        WHERE wc_product_id=@wc_product_id;
        SET @accion='U';
    END
    ELSE
    BEGIN
        INSERT INTO FLORERIA_WC_Product (wc_product_id, name, slug, sku, type, status, regular_price, sale_price, stock_status, total_sales, date_created, date_modified, json_raw, extraccion_id, creado_en)
        VALUES (@wc_product_id, @name, @slug, @sku, @type, @status, @regular_price, @sale_price, @stock_status, @total_sales, @date_created, @date_modified, @json_raw, @extraccion_id, GETDATE());
        SET @accion='I';
    END
    DELETE FROM FLORERIA_WC_Product_Cat_Map WHERE wc_product_id=@wc_product_id;
    IF @categorias_csv IS NOT NULL AND LTRIM(RTRIM(@categorias_csv)) <> ''
        INSERT INTO FLORERIA_WC_Product_Cat_Map (wc_product_id, wc_category_id)
        SELECT DISTINCT @wc_product_id, TRY_CAST(LTRIM(RTRIM(value)) AS INT)
        FROM STRING_SPLIT(@categorias_csv, ',')
        WHERE TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;
    SELECT @accion AS accion;
END
GO

-- Upsert de una CATEGORIA. Devuelve 'I' o 'U'.
CREATE OR ALTER PROCEDURE dbo.FLORERIA_WC_sp_Category_Upsert
    @wc_category_id int, @name varchar(200)=NULL, @slug varchar(200)=NULL, @parent int=0, @count int=0, @json_raw nvarchar(max)=NULL, @extraccion_id int=NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @accion char(1);
    IF EXISTS (SELECT 1 FROM FLORERIA_WC_Product_Category WHERE wc_category_id=@wc_category_id)
    BEGIN
        UPDATE FLORERIA_WC_Product_Category SET name=@name, slug=@slug, parent=@parent, count=@count, json_raw=@json_raw, extraccion_id=@extraccion_id, actualizado_en=GETDATE()
        WHERE wc_category_id=@wc_category_id;
        SET @accion='U';
    END
    ELSE
    BEGIN
        INSERT INTO FLORERIA_WC_Product_Category (wc_category_id, name, slug, parent, count, json_raw, extraccion_id, creado_en)
        VALUES (@wc_category_id, @name, @slug, @parent, @count, @json_raw, @extraccion_id, GETDATE());
        SET @accion='I';
    END
    SELECT @accion AS accion;
END
GO

-- =============================================================
-- SP - CAPA B : RECALCULAR clientes + RFM desde la capa A
-- Reconstruye FLORERIA_CRM_Cliente por completo.
-- Estados que cuentan: todos menos cancelled/failed/refunded/trash/checkout-draft.
-- =============================================================
CREATE OR ALTER PROCEDURE dbo.FLORERIA_CRM_sp_RecalcularClientes
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @hoy date = CAST(GETDATE() AS date);
    DECLARE @excluidos TABLE (st varchar(30));
    INSERT INTO @excluidos (st) VALUES ('cancelled'),('failed'),('refunded'),('trash'),('checkout-draft');

    ;WITH ordenes AS (
        SELECT * FROM FLORERIA_WC_Order o
        WHERE o.billing_email_norm IS NOT NULL AND o.status NOT IN (SELECT st FROM @excluidos)
    ),
    agg AS (
        SELECT billing_email_norm AS email_norm, MAX(billing_email) AS email_original,
               COUNT(*) AS total_pedidos, SUM(total) AS total_gastado_bs,
               MIN(CAST(date_created AS date)) AS primera_compra, MAX(CAST(date_created AS date)) AS ultima_compra
        FROM ordenes GROUP BY billing_email_norm
    )
    SELECT a.*, CAST(NULL AS varchar(150)) AS nombre, CAST(NULL AS varchar(150)) AS apellidos
    INTO #base FROM agg a;

    IF NOT EXISTS (SELECT 1 FROM #base)
    BEGIN
        DELETE FROM FLORERIA_CRM_Cliente;
        SELECT 0 AS clientes; RETURN;
    END

    ;WITH ult AS (
        SELECT o.billing_email_norm AS email_norm, o.billing_nombre, o.billing_apellidos,
               ROW_NUMBER() OVER (PARTITION BY o.billing_email_norm ORDER BY o.date_created DESC) AS rn
        FROM FLORERIA_WC_Order o
        WHERE o.billing_email_norm IS NOT NULL AND o.status NOT IN (SELECT st FROM @excluidos)
    )
    UPDATE b SET b.nombre=u.billing_nombre, b.apellidos=u.billing_apellidos
    FROM #base b INNER JOIN ult u ON u.email_norm=b.email_norm AND u.rn=1;

    ;WITH rfm AS (
        SELECT email_norm,
               NTILE(5) OVER (ORDER BY ultima_compra ASC) AS r_raw,
               NTILE(5) OVER (ORDER BY total_pedidos ASC) AS f_score,
               NTILE(5) OVER (ORDER BY total_gastado_bs ASC) AS m_score
        FROM #base
    )
    SELECT email_norm, (6 - r_raw) AS r_score, f_score, m_score INTO #rfm FROM rfm;

    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM FLORERIA_CRM_Cliente;
        INSERT INTO FLORERIA_CRM_Cliente (email_norm, email_original, telefono_norm, nombre, apellidos, ciudad_top, zona_top,
            total_pedidos, total_gastado_bs, ticket_promedio_bs, primera_compra, ultima_compra, dias_desde_ultima, frecuencia_dias_prom,
            r_score, f_score, m_score, rfm_segmento, ocasion_top, producto_top, metodo_pago_top, email_sha256, telefono_sha256, actualizado_en)
        SELECT b.email_norm, b.email_original, tel.telefono_norm, b.nombre, b.apellidos, ciu.ciudad_top, zon.zona_top,
            b.total_pedidos, b.total_gastado_bs,
            CASE WHEN b.total_pedidos>0 THEN ROUND(b.total_gastado_bs/b.total_pedidos,2) ELSE 0 END,
            b.primera_compra, b.ultima_compra, DATEDIFF(DAY, b.ultima_compra, @hoy),
            CASE WHEN b.total_pedidos>1 THEN DATEDIFF(DAY, b.primera_compra, b.ultima_compra)/(b.total_pedidos-1) ELSE NULL END,
            r.r_score, r.f_score, r.m_score,
            CASE
                WHEN r.r_score>=4 AND r.f_score>=4 AND r.m_score>=4 THEN 'Campeon'
                WHEN r.f_score>=4 AND r.r_score>=3 THEN 'Leal'
                WHEN r.r_score>=4 AND r.f_score<=2 THEN 'Nuevo/Potencial'
                WHEN r.r_score<=2 AND r.f_score>=3 THEN 'En riesgo'
                WHEN r.r_score=1 THEN 'Perdido'
                ELSE 'Regular'
            END,
            oca.ocasion_top, pro.producto_top, pag.metodo_pago_top,
            dbo.FLORERIA_CRM_fn_Sha256Hex(b.email_norm),
            dbo.FLORERIA_CRM_fn_Sha256Hex(dbo.FLORERIA_CRM_fn_TelefonoE164(tel.telefono_norm)),
            GETDATE()
        FROM #base b
        INNER JOIN #rfm r ON r.email_norm=b.email_norm
        OUTER APPLY (SELECT TOP 1 o.billing_phone_norm AS telefono_norm FROM FLORERIA_WC_Order o WHERE o.billing_email_norm=b.email_norm AND NULLIF(o.billing_phone_norm,'') IS NOT NULL ORDER BY o.date_created DESC) tel
        OUTER APPLY (SELECT TOP 1 o.shipping_ciudad AS ciudad_top FROM FLORERIA_WC_Order o WHERE o.billing_email_norm=b.email_norm AND NULLIF(o.shipping_ciudad,'') IS NOT NULL GROUP BY o.shipping_ciudad ORDER BY COUNT(*) DESC) ciu
        OUTER APPLY (SELECT TOP 1 o.shipping_state AS zona_top FROM FLORERIA_WC_Order o WHERE o.billing_email_norm=b.email_norm AND NULLIF(o.shipping_state,'') IS NOT NULL GROUP BY o.shipping_state ORDER BY COUNT(*) DESC) zon
        OUTER APPLY (SELECT TOP 1 o.tipo_ocacion AS ocasion_top FROM FLORERIA_WC_Order o WHERE o.billing_email_norm=b.email_norm AND NULLIF(o.tipo_ocacion,'') IS NOT NULL GROUP BY o.tipo_ocacion ORDER BY COUNT(*) DESC) oca
        OUTER APPLY (SELECT TOP 1 o.payment_method_title AS metodo_pago_top FROM FLORERIA_WC_Order o WHERE o.billing_email_norm=b.email_norm AND NULLIF(o.payment_method_title,'') IS NOT NULL GROUP BY o.payment_method_title ORDER BY COUNT(*) DESC) pag
        OUTER APPLY (SELECT TOP 1 it.nombre AS producto_top FROM FLORERIA_WC_Order_Item it INNER JOIN FLORERIA_WC_Order o2 ON o2.wc_order_id=it.wc_order_id WHERE o2.billing_email_norm=b.email_norm AND NULLIF(it.nombre,'') IS NOT NULL GROUP BY it.nombre ORDER BY SUM(it.cantidad) DESC) pro;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH

    DROP TABLE #base; DROP TABLE #rfm;
    SELECT COUNT(*) AS clientes FROM FLORERIA_CRM_Cliente;
END
GO

-- =============================================================
-- SPs - CAPA B : listados / dashboard / export
-- =============================================================

-- Listar clientes con filtros
CREATE OR ALTER PROCEDURE dbo.FLORERIA_CRM_sp_Cliente_Listar
    @busqueda varchar(150)=NULL, @segmento varchar(30)=NULL, @ciudad varchar(100)=NULL, @orden varchar(20)='gasto', @top int=500
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@top) cliente_crm_id, email_norm, email_original, telefono_norm, nombre, apellidos, ciudad_top, zona_top,
        total_pedidos, total_gastado_bs, ticket_promedio_bs, primera_compra, ultima_compra, dias_desde_ultima,
        r_score, f_score, m_score, rfm_segmento, ocasion_top, producto_top, metodo_pago_top
    FROM FLORERIA_CRM_Cliente
    WHERE (@busqueda IS NULL OR @busqueda='' OR nombre LIKE '%'+@busqueda+'%' OR apellidos LIKE '%'+@busqueda+'%' OR email_norm LIKE '%'+@busqueda+'%' OR telefono_norm LIKE '%'+@busqueda+'%')
      AND (@segmento IS NULL OR @segmento='' OR rfm_segmento=@segmento)
      AND (@ciudad IS NULL OR @ciudad='' OR ciudad_top=@ciudad)
    ORDER BY
        CASE WHEN @orden='gasto' THEN total_gastado_bs END DESC,
        CASE WHEN @orden='frecuencia' THEN total_pedidos END DESC,
        CASE WHEN @orden='recencia' THEN dias_desde_ultima END ASC,
        CASE WHEN @orden='nombre' THEN nombre END ASC;
END
GO

-- Ficha de un cliente: cabecera + sus pedidos
CREATE OR ALTER PROCEDURE dbo.FLORERIA_CRM_sp_Cliente_Ficha
    @cliente_crm_id int
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @email varchar(200);
    SELECT @email=email_norm FROM FLORERIA_CRM_Cliente WHERE cliente_crm_id=@cliente_crm_id;
    SELECT * FROM FLORERIA_CRM_Cliente WHERE cliente_crm_id=@cliente_crm_id;
    SELECT wc_order_id, number, status, date_created, delivery_date, total, payment_method_title, tipo_ocacion, cantidad_items
    FROM FLORERIA_WC_Order WHERE billing_email_norm=@email ORDER BY date_created DESC;
END
GO

-- Dashboard: KPIs globales + distribucion por segmento
CREATE OR ALTER PROCEDURE dbo.FLORERIA_CRM_sp_Dashboard_KPIs
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(*) AS total_clientes,
        SUM(CASE WHEN total_pedidos>1 THEN 1 ELSE 0 END) AS clientes_recurrentes,
        SUM(CASE WHEN total_pedidos=1 THEN 1 ELSE 0 END) AS clientes_unicos,
        ISNULL(SUM(total_gastado_bs),0) AS ingreso_total_bs,
        ISNULL(AVG(total_gastado_bs),0) AS ltv_promedio_bs,
        ISNULL(AVG(ticket_promedio_bs),0) AS ticket_promedio_bs
    FROM FLORERIA_CRM_Cliente;
    SELECT rfm_segmento, COUNT(*) AS clientes, ISNULL(SUM(total_gastado_bs),0) AS valor_bs
    FROM FLORERIA_CRM_Cliente GROUP BY rfm_segmento ORDER BY valor_bs DESC;
END
GO

-- Dashboard: estacionalidad (ventas por mes) sobre el espejo crudo
CREATE OR ALTER PROCEDURE dbo.FLORERIA_CRM_sp_Dashboard_Estacionalidad
AS
BEGIN
    SET NOCOUNT ON;
    SELECT YEAR(date_created) AS anio, MONTH(date_created) AS mes, COUNT(*) AS pedidos, ISNULL(SUM(total),0) AS total_bs
    FROM FLORERIA_WC_Order
    WHERE date_created IS NOT NULL AND status NOT IN ('cancelled','failed','refunded','trash','checkout-draft')
    GROUP BY YEAR(date_created), MONTH(date_created) ORDER BY anio, mes;
END
GO

-- Dashboard: top productos
CREATE OR ALTER PROCEDURE dbo.FLORERIA_CRM_sp_Dashboard_TopProductos
    @top int=20
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@top) it.nombre, SUM(it.cantidad) AS unidades, SUM(it.total) AS total_bs, COUNT(DISTINCT it.wc_order_id) AS pedidos
    FROM FLORERIA_WC_Order_Item it INNER JOIN FLORERIA_WC_Order o ON o.wc_order_id=it.wc_order_id
    WHERE o.status NOT IN ('cancelled','failed','refunded','trash','checkout-draft') AND NULLIF(it.nombre,'') IS NOT NULL
    GROUP BY it.nombre ORDER BY unidades DESC;
END
GO

-- Export: filas de un segmento (o todos) para CSV / Google Ads
CREATE OR ALTER PROCEDURE dbo.FLORERIA_CRM_sp_Export_Clientes
    @segmento varchar(30)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT email_original, email_norm, email_sha256, telefono_norm, telefono_sha256,
        nombre, apellidos, ciudad_top, zona_top, total_pedidos, total_gastado_bs, ticket_promedio_bs,
        primera_compra, ultima_compra, dias_desde_ultima, rfm_segmento
    FROM FLORERIA_CRM_Cliente
    WHERE (@segmento IS NULL OR @segmento='' OR rfm_segmento=@segmento)
    ORDER BY total_gastado_bs DESC;
END
GO

PRINT 'Modulo CRM/WC creado/actualizado correctamente.';
GO
