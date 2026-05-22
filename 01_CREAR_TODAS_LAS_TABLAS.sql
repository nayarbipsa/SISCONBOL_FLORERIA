-- =============================================
-- SISCONBOL_FLORERIA - CREACIÓN DE TODAS LAS TABLAS
-- Archivo: 01_CREAR_TODAS_LAS_TABLAS.sql
-- Total: 31 Tablas
-- Fecha: 2026-05-22
-- =============================================

USE SISCONBOL;
GO

-- =============================================
-- MÓDULO 1: SEGURIDAD Y USUARIOS (7 TABLAS)
-- =============================================

-- Tabla 1: FLORERIA_TipoUsuario
CREATE TABLE FLORERIA_TipoUsuario (
    tipo_id       SMALLINT IDENTITY(1,1) NOT NULL,
    nombre        VARCHAR(50) NOT NULL,
    descripcion   VARCHAR(200) NULL,
    activo        BIT NOT NULL DEFAULT 1,
    creado_en     DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_TipoUsuario PRIMARY KEY (tipo_id),
    CONSTRAINT UQ_TipoUsuario_Nombre UNIQUE (nombre)
);

-- Tabla 2: FLORERIA_Menu
CREATE TABLE FLORERIA_Menu (
    menu_id    SMALLINT IDENTITY(1,1) NOT NULL,
    padre_id   SMALLINT NULL,
    nombre     VARCHAR(80) NOT NULL,
    icono      VARCHAR(50) NULL,
    ruta       VARCHAR(200) NULL,
    orden      TINYINT NOT NULL DEFAULT 0,
    activo     BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Menu PRIMARY KEY (menu_id),
    CONSTRAINT FK_Menu_Padre FOREIGN KEY (padre_id) REFERENCES FLORERIA_Menu(menu_id)
);

-- Tabla 3: FLORERIA_Usuario
CREATE TABLE FLORERIA_Usuario (
    usuario_id         INT IDENTITY(1,1) NOT NULL,
    tipo_id            SMALLINT NOT NULL,
    carnet             VARCHAR(8) NOT NULL,
    nombres            VARCHAR(100) NOT NULL,
    apellidos          VARCHAR(100) NOT NULL,
    celular            VARCHAR(20) NULL,
    email              VARCHAR(100) NULL,
    direccion          VARCHAR(200) NULL,
    fecha_nac          DATE NULL,
    password_hash      VARCHAR(200) NOT NULL,
    password_salt      VARCHAR(50) NOT NULL DEFAULT 'FLORERIA2026',
    debe_cambiar_pwd   BIT NOT NULL DEFAULT 1,
    vigente_desde      DATE NULL,
    vigente_hasta      DATE NULL,
    activo             BIT NOT NULL DEFAULT 1,
    bloqueado          BIT NOT NULL DEFAULT 0,
    intentos_fallidos  TINYINT NOT NULL DEFAULT 0,
    bloqueado_hasta    DATETIME NULL,
    creado_por         INT NULL,
    creado_en          DATETIME NOT NULL DEFAULT GETDATE(),
    modificado_por     INT NULL,
    modificado_en      DATETIME NULL,
    CONSTRAINT PK_Usuario PRIMARY KEY (usuario_id),
    CONSTRAINT UQ_Usuario_Carnet UNIQUE (carnet),
    CONSTRAINT FK_Usuario_Tipo FOREIGN KEY (tipo_id) REFERENCES FLORERIA_TipoUsuario(tipo_id),
    CONSTRAINT FK_Usuario_Creador FOREIGN KEY (creado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT FK_Usuario_Modificador FOREIGN KEY (modificado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT CK_Usuario_Carnet CHECK (carnet NOT LIKE '%[^0-9]%' AND LEN(carnet) BETWEEN 7 AND 8)
);

-- Tabla 4: FLORERIA_Sesion
CREATE TABLE FLORERIA_Sesion (
    sesion_id      BIGINT IDENTITY(1,1) NOT NULL,
    usuario_id     INT NOT NULL,
    token          VARCHAR(100) NOT NULL,
    ip             VARCHAR(50) NULL,
    user_agent     VARCHAR(500) NULL,
    es_celular     BIT NOT NULL DEFAULT 0,
    dispositivo    VARCHAR(100) NULL,
    sistema_op     VARCHAR(50) NULL,
    navegador      VARCHAR(50) NULL,
    inicio         DATETIME NOT NULL DEFAULT GETDATE(),
    ultimo_acceso  DATETIME NOT NULL DEFAULT GETDATE(),
    expira_en      DATETIME NOT NULL,
    activa         BIT NOT NULL DEFAULT 1,
    cerrada_por    VARCHAR(20) NULL,
    CONSTRAINT PK_Sesion PRIMARY KEY (sesion_id),
    CONSTRAINT UQ_Sesion_Token UNIQUE (token),
    CONSTRAINT FK_Sesion_Usuario FOREIGN KEY (usuario_id) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT CK_Sesion_CerradaPor CHECK (cerrada_por IN ('USUARIO', 'SISTEMA', 'NUEVA_SESION'))
);

-- Tabla 5: FLORERIA_TipoUsuario_Menu
CREATE TABLE FLORERIA_TipoUsuario_Menu (
    tipomenu_id    INT IDENTITY(1,1) NOT NULL,
    tipo_id        SMALLINT NOT NULL,
    menu_id        SMALLINT NOT NULL,
    puede_ver      BIT NOT NULL DEFAULT 1,
    puede_crear    BIT NOT NULL DEFAULT 0,
    puede_editar   BIT NOT NULL DEFAULT 0,
    puede_eliminar BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_TipoUsuario_Menu PRIMARY KEY (tipomenu_id),
    CONSTRAINT UQ_TipoUsuario_Menu UNIQUE (tipo_id, menu_id),
    CONSTRAINT FK_TipoUsuario_Menu_Tipo FOREIGN KEY (tipo_id) REFERENCES FLORERIA_TipoUsuario(tipo_id),
    CONSTRAINT FK_TipoUsuario_Menu_Menu FOREIGN KEY (menu_id) REFERENCES FLORERIA_Menu(menu_id)
);

-- Tabla 6: FLORERIA_Usuario_Menu
CREATE TABLE FLORERIA_Usuario_Menu (
    usumenu_id     INT IDENTITY(1,1) NOT NULL,
    usuario_id     INT NOT NULL,
    menu_id        SMALLINT NOT NULL,
    tipo_excepcion VARCHAR(10) NOT NULL,
    puede_ver      BIT NOT NULL DEFAULT 1,
    puede_crear    BIT NOT NULL DEFAULT 0,
    puede_editar   BIT NOT NULL DEFAULT 0,
    puede_eliminar BIT NOT NULL DEFAULT 0,
    motivo         VARCHAR(300) NULL,
    creado_por     INT NOT NULL,
    creado_en      DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Usuario_Menu PRIMARY KEY (usumenu_id),
    CONSTRAINT UQ_Usuario_Menu UNIQUE (usuario_id, menu_id),
    CONSTRAINT FK_Usuario_Menu_Usuario FOREIGN KEY (usuario_id) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT FK_Usuario_Menu_Menu FOREIGN KEY (menu_id) REFERENCES FLORERIA_Menu(menu_id),
    CONSTRAINT FK_Usuario_Menu_Creador FOREIGN KEY (creado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT CK_Usuario_Menu_Excepcion CHECK (tipo_excepcion IN ('AGREGAR', 'QUITAR'))
);

-- Tabla 7: FLORERIA_Auditoria
CREATE TABLE FLORERIA_Auditoria (
    audit_id        BIGINT IDENTITY(1,1) NOT NULL,
    usuario_id      INT NULL,
    usuario_nombre  VARCHAR(200) NULL,
    ip              VARCHAR(50) NULL,
    es_celular      BIT NULL,
    dispositivo     VARCHAR(100) NULL,
    tabla           VARCHAR(100) NOT NULL,
    registro_id     VARCHAR(50) NOT NULL,
    accion          VARCHAR(10) NOT NULL,
    valor_anterior  NVARCHAR(MAX) NULL,
    valor_nuevo     NVARCHAR(MAX) NULL,
    motivo          VARCHAR(500) NULL,
    fecha_hora      DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Auditoria PRIMARY KEY (audit_id),
    CONSTRAINT CK_Auditoria_Accion CHECK (accion IN ('INSERTAR', 'MODIFICAR', 'ELIMINAR'))
);

-- =============================================
-- MÓDULO 2: CONFIGURACIÓN (1 TABLA)
-- =============================================

-- Tabla 8: FLORERIA_Config
CREATE TABLE FLORERIA_Config (
    config_id      INT IDENTITY(1,1) NOT NULL,
    clave          VARCHAR(100) NOT NULL,
    valor          NVARCHAR(500) NULL,
    descripcion    VARCHAR(300) NULL,
    es_secreto     BIT NOT NULL DEFAULT 0,
    activo         BIT NOT NULL DEFAULT 1,
    modificado_por INT NULL,
    modificado_en  DATETIME NULL,
    CONSTRAINT PK_Config PRIMARY KEY (config_id),
    CONSTRAINT UQ_Config_Clave UNIQUE (clave),
    CONSTRAINT FK_Config_Modificador FOREIGN KEY (modificado_por) REFERENCES FLORERIA_Usuario(usuario_id)
);

-- =============================================
-- MÓDULO 3: GEOGRAFÍA (9 TABLAS)
-- =============================================

-- Tabla 9: FLORERIA_Pais
CREATE TABLE FLORERIA_Pais (
    pais_id     TINYINT IDENTITY(1,1) NOT NULL,
    codigo_iso  CHAR(2) NOT NULL,
    nombre      VARCHAR(80) NOT NULL,
    activo      BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Pais PRIMARY KEY (pais_id),
    CONSTRAINT UQ_Pais_CodigoISO UNIQUE (codigo_iso)
);

-- Tabla 10: FLORERIA_Departamento
CREATE TABLE FLORERIA_Departamento (
    dpto_id   TINYINT IDENTITY(1,1) NOT NULL,
    pais_id   TINYINT NOT NULL,
    nombre    VARCHAR(80) NOT NULL,
    activo    BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Departamento PRIMARY KEY (dpto_id),
    CONSTRAINT FK_Departamento_Pais FOREIGN KEY (pais_id) REFERENCES FLORERIA_Pais(pais_id)
);

-- Tabla 11: FLORERIA_Ciudad
CREATE TABLE FLORERIA_Ciudad (
    ciudad_id SMALLINT IDENTITY(1,1) NOT NULL,
    dpto_id   TINYINT NOT NULL,
    nombre    VARCHAR(100) NOT NULL,
    activo    BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Ciudad PRIMARY KEY (ciudad_id),
    CONSTRAINT FK_Ciudad_Departamento FOREIGN KEY (dpto_id) REFERENCES FLORERIA_Departamento(dpto_id)
);

-- Tabla 12: FLORERIA_Zona
CREATE TABLE FLORERIA_Zona (
    zona_id       INT IDENTITY(1,1) NOT NULL,
    ciudad_id     SMALLINT NOT NULL,
    codigo        VARCHAR(20) NOT NULL,
    nombre        VARCHAR(150) NOT NULL,
    descripcion   VARCHAR(300) NULL,
    activo        BIT NOT NULL DEFAULT 1,
    creado_en     DATETIME NOT NULL DEFAULT GETDATE(),
    modificado_en DATETIME NULL,
    CONSTRAINT PK_Zona PRIMARY KEY (zona_id),
    CONSTRAINT UQ_Zona_Codigo UNIQUE (ciudad_id, codigo),
    CONSTRAINT FK_Zona_Ciudad FOREIGN KEY (ciudad_id) REFERENCES FLORERIA_Ciudad(ciudad_id)
);

-- Tabla 13: FLORERIA_Zona_Tarifa
CREATE TABLE FLORERIA_Zona_Tarifa (
    tarifa_id      INT IDENTITY(1,1) NOT NULL,
    zona_id        INT NOT NULL,
    precio_bs      DECIMAL(10, 2) NOT NULL,
    precio_usd     DECIMAL(10, 2) NULL,
    vigente_desde  DATE NOT NULL,
    vigente_hasta  DATE NULL,
    activo         BIT NOT NULL DEFAULT 1,
    creado_por     INT NOT NULL,
    creado_en      DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Zona_Tarifa PRIMARY KEY (tarifa_id),
    CONSTRAINT FK_Zona_Tarifa_Zona FOREIGN KEY (zona_id) REFERENCES FLORERIA_Zona(zona_id),
    CONSTRAINT FK_Zona_Tarifa_Creador FOREIGN KEY (creado_por) REFERENCES FLORERIA_Usuario(usuario_id)
);

-- Tabla 14: FLORERIA_Zona_Express
CREATE TABLE FLORERIA_Zona_Express (
    express_id    INT IDENTITY(1,1) NOT NULL,
    zona_id       INT NOT NULL,
    recargo_bs    DECIMAL(10, 2) NOT NULL,
    recargo_usd   DECIMAL(10, 2) NULL,
    tiempo_min    SMALLINT NOT NULL,
    activo        BIT NOT NULL DEFAULT 1,
    creado_por    INT NOT NULL,
    creado_en     DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Zona_Express PRIMARY KEY (express_id),
    CONSTRAINT FK_Zona_Express_Zona FOREIGN KEY (zona_id) REFERENCES FLORERIA_Zona(zona_id),
    CONSTRAINT FK_Zona_Express_Creador FOREIGN KEY (creado_por) REFERENCES FLORERIA_Usuario(usuario_id)
);

-- Tabla 15: FLORERIA_Slot_Horario
CREATE TABLE FLORERIA_Slot_Horario (
    slot_id      SMALLINT IDENTITY(1,1) NOT NULL,
    etiqueta     VARCHAR(50) NOT NULL,
    hora_inicio  TIME NOT NULL,
    hora_fin     TIME NOT NULL,
    recargo_bs   DECIMAL(10, 2) NOT NULL DEFAULT 0,
    recargo_usd  DECIMAL(10, 2) NULL,
    orden        TINYINT NOT NULL DEFAULT 0,
    activo       BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Slot_Horario PRIMARY KEY (slot_id)
);

-- Tabla 16: FLORERIA_Sucursal
CREATE TABLE FLORERIA_Sucursal (
    sucursal_id    SMALLINT IDENTITY(1,1) NOT NULL,
    ciudad_id      SMALLINT NOT NULL,
    nombre         VARCHAR(100) NOT NULL,
    direccion      VARCHAR(200) NOT NULL,
    telefono       VARCHAR(20) NULL,
    horario        VARCHAR(100) NULL,
    latitud        DECIMAL(10, 7) NULL,
    longitud       DECIMAL(10, 7) NULL,
    activo         BIT NOT NULL DEFAULT 1,
    creado_en      DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Sucursal PRIMARY KEY (sucursal_id),
    CONSTRAINT FK_Sucursal_Ciudad FOREIGN KEY (ciudad_id) REFERENCES FLORERIA_Ciudad(ciudad_id)
);

-- Tabla 17: FLORERIA_Barrio
CREATE TABLE FLORERIA_Barrio (
    barrio_id    INT IDENTITY(1,1) NOT NULL,
    zona_id      INT NOT NULL,
    nombre       VARCHAR(150) NOT NULL,
    activo       BIT NOT NULL DEFAULT 1,
    creado_en    DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Barrio PRIMARY KEY (barrio_id),
    CONSTRAINT FK_Barrio_Zona FOREIGN KEY (zona_id) REFERENCES FLORERIA_Zona(zona_id)
);

-- =============================================
-- MÓDULO 4: ALIADOS (2 TABLAS)
-- =============================================

-- Tabla 18: FLORERIA_Proveedor
CREATE TABLE FLORERIA_Proveedor (
    proveedor_id INT IDENTITY(1,1) NOT NULL,
    nombre       VARCHAR(150) NOT NULL,
    razon_social VARCHAR(200) NULL,
    nit          VARCHAR(20) NULL,
    contacto     VARCHAR(100) NULL,
    telefono     VARCHAR(20) NULL,
    email        VARCHAR(100) NULL,
    direccion    VARCHAR(200) NULL,
    activo       BIT NOT NULL DEFAULT 1,
    creado_en    DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Proveedor PRIMARY KEY (proveedor_id)
);

-- Tabla 19: FLORERIA_Cliente
CREATE TABLE FLORERIA_Cliente (
    cliente_id     INT IDENTITY(1,1) NOT NULL,
    tipo_cliente   VARCHAR(20) NOT NULL DEFAULT 'NATURAL',
    nombres        VARCHAR(100) NULL,
    apellidos      VARCHAR(100) NULL,
    razon_social   VARCHAR(200) NULL,
    nit            VARCHAR(20) NULL,
    celular        VARCHAR(20) NOT NULL,
    email          VARCHAR(100) NULL,
    ciudad_id      SMALLINT NULL,
    direccion      VARCHAR(200) NULL,
    total_compras  DECIMAL(12, 2) NOT NULL DEFAULT 0,
    creado_en      DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Cliente PRIMARY KEY (cliente_id),
    CONSTRAINT FK_Cliente_Ciudad FOREIGN KEY (ciudad_id) REFERENCES FLORERIA_Ciudad(ciudad_id),
    CONSTRAINT CK_Cliente_Tipo CHECK (tipo_cliente IN ('NATURAL', 'JURIDICO'))
);

-- =============================================
-- MÓDULO 5: CATÁLOGO (6 TABLAS)
-- =============================================

-- Tabla 20: FLORERIA_Categoria
CREATE TABLE FLORERIA_Categoria (
    categoria_id    INT IDENTITY(1,1) NOT NULL,
    padre_id        INT NULL,
    nombre          VARCHAR(150) NOT NULL,
    descripcion     VARCHAR(500) NULL,
    slug            VARCHAR(160) NULL,
    orden           SMALLINT NOT NULL DEFAULT 0,
    wc_category_id  INT NULL,
    wc_sync_estado  VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    wc_sync_fecha   DATETIME NULL,
    activo          BIT NOT NULL DEFAULT 1,
    creado_por      INT NOT NULL,
    creado_en       DATETIME NOT NULL DEFAULT GETDATE(),
    modificado_por  INT NULL,
    modificado_en   DATETIME NULL,
    CONSTRAINT PK_Categoria PRIMARY KEY (categoria_id),
    CONSTRAINT FK_Categoria_Padre FOREIGN KEY (padre_id) REFERENCES FLORERIA_Categoria(categoria_id),
    CONSTRAINT FK_Categoria_Creador FOREIGN KEY (creado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT FK_Categoria_Modificador FOREIGN KEY (modificado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT CK_Categoria_WcSync CHECK (wc_sync_estado IN ('PENDIENTE', 'SINCRONIZADO', 'ERROR'))
);

-- Tabla 21: FLORERIA_Producto
CREATE TABLE FLORERIA_Producto (
    producto_id        INT IDENTITY(1,1) NOT NULL,
    sku                VARCHAR(50) NOT NULL,
    nombre             VARCHAR(200) NOT NULL,
    descripcion        NVARCHAR(MAX) NULL,
    categoria_id       INT NULL,
    precio_base_bs     DECIMAL(10, 2) NOT NULL,
    precio_base_usd    DECIMAL(10, 2) NULL,
    precio_promo_bs    DECIMAL(10, 2) NULL,
    precio_promo_usd   DECIMAL(10, 2) NULL,
    promo_desde        DATE NULL,
    promo_hasta        DATE NULL,
    tiene_variaciones  BIT NOT NULL DEFAULT 0,
    destacado          BIT NOT NULL DEFAULT 0,
    menu_order         INT NOT NULL DEFAULT 0,
    notas_internas     NVARCHAR(500) NULL,
    stock_actual       INT NOT NULL DEFAULT 0,
    stock_minimo       INT NOT NULL DEFAULT 5,
    wc_product_id      INT NULL,
    wc_sync_estado     VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    wc_sync_fecha      DATETIME NULL,
    imagen_url         VARCHAR(500) NULL,
    activo             BIT NOT NULL DEFAULT 1,
    creado_por         INT NOT NULL,
    creado_en          DATETIME NOT NULL DEFAULT GETDATE(),
    modificado_por     INT NULL,
    modificado_en      DATETIME NULL,
    CONSTRAINT PK_Producto PRIMARY KEY (producto_id),
    CONSTRAINT UQ_Producto_SKU UNIQUE (sku),
    CONSTRAINT FK_Producto_Categoria FOREIGN KEY (categoria_id) REFERENCES FLORERIA_Categoria(categoria_id),
    CONSTRAINT FK_Producto_Creador FOREIGN KEY (creado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT FK_Producto_Modificador FOREIGN KEY (modificado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT CK_Producto_WcSync CHECK (wc_sync_estado IN ('PENDIENTE', 'SINCRONIZADO', 'ERROR'))
);

-- Tabla 22: FLORERIA_Producto_Variacion
CREATE TABLE FLORERIA_Producto_Variacion (
    variacion_id     INT IDENTITY(1,1) NOT NULL,
    producto_id      INT NOT NULL,
    sku_variacion    VARCHAR(60) NOT NULL,
    atrib_1_nombre   VARCHAR(40) NULL,
    atrib_1_valor    VARCHAR(80) NULL,
    atrib_2_nombre   VARCHAR(40) NULL,
    atrib_2_valor    VARCHAR(80) NULL,
    atrib_3_nombre   VARCHAR(40) NULL,
    atrib_3_valor    VARCHAR(80) NULL,
    precio_bs        DECIMAL(10, 2) NOT NULL,
    precio_usd       DECIMAL(10, 2) NULL,
    precio_promo_bs  DECIMAL(10, 2) NULL,
    precio_promo_usd DECIMAL(10, 2) NULL,
    promo_desde      DATE NULL,
    promo_hasta      DATE NULL,
    wc_variation_id  INT NULL,
    wc_sync_estado   VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    wc_sync_fecha    DATETIME NULL,
    activo           BIT NOT NULL DEFAULT 1,
    creado_por       INT NOT NULL,
    creado_en        DATETIME NOT NULL DEFAULT GETDATE(),
    modificado_por   INT NULL,
    modificado_en    DATETIME NULL,
    CONSTRAINT PK_Producto_Variacion PRIMARY KEY (variacion_id),
    CONSTRAINT UQ_Variacion_SKU UNIQUE (sku_variacion),
    CONSTRAINT FK_Variacion_Producto FOREIGN KEY (producto_id) REFERENCES FLORERIA_Producto(producto_id),
    CONSTRAINT FK_Variacion_Creador FOREIGN KEY (creado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT FK_Variacion_Modificador FOREIGN KEY (modificado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT CK_Variacion_WcSync CHECK (wc_sync_estado IN ('PENDIENTE', 'SINCRONIZADO', 'ERROR'))
);

-- Tabla 23: FLORERIA_Producto_Categoria
CREATE TABLE FLORERIA_Producto_Categoria (
    prod_cat_id   INT IDENTITY(1,1) NOT NULL,
    producto_id   INT NOT NULL,
    categoria_id  INT NOT NULL,
    es_principal  BIT NOT NULL DEFAULT 0,
    creado_por    INT NOT NULL,
    creado_en     DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Producto_Categoria PRIMARY KEY (prod_cat_id),
    CONSTRAINT UQ_Producto_Categoria UNIQUE (producto_id, categoria_id),
    CONSTRAINT FK_ProdCat_Producto FOREIGN KEY (producto_id) REFERENCES FLORERIA_Producto(producto_id),
    CONSTRAINT FK_ProdCat_Categoria FOREIGN KEY (categoria_id) REFERENCES FLORERIA_Categoria(categoria_id),
    CONSTRAINT FK_ProdCat_Creador FOREIGN KEY (creado_por) REFERENCES FLORERIA_Usuario(usuario_id)
);

-- Tabla 24: FLORERIA_Producto_Imagen
CREATE TABLE FLORERIA_Producto_Imagen (
    imagen_id      INT IDENTITY(1,1) NOT NULL,
    producto_id    INT NULL,
    variacion_id   INT NULL,
    url            VARCHAR(500) NOT NULL,
    nombre_archivo VARCHAR(200) NULL,
    orden          TINYINT NOT NULL DEFAULT 0,
    es_principal   BIT NOT NULL DEFAULT 0,
    wc_image_id    INT NULL,
    creado_en      DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Producto_Imagen PRIMARY KEY (imagen_id),
    CONSTRAINT FK_Imagen_Producto FOREIGN KEY (producto_id) REFERENCES FLORERIA_Producto(producto_id),
    CONSTRAINT FK_Imagen_Variacion FOREIGN KEY (variacion_id) REFERENCES FLORERIA_Producto_Variacion(variacion_id)
);

-- Tabla 25: FLORERIA_Stock_Movimiento
CREATE TABLE FLORERIA_Stock_Movimiento (
    movimiento_id   INT IDENTITY(1,1) NOT NULL,
    producto_id     INT NOT NULL,
    variacion_id    INT NULL,
    tipo_movimiento VARCHAR(20) NOT NULL,
    cantidad        INT NOT NULL,
    stock_anterior  INT NOT NULL,
    stock_nuevo     INT NOT NULL,
    motivo          VARCHAR(300) NULL,
    pedido_id       INT NULL,
    usuario_id      INT NOT NULL,
    fecha_hora      DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Stock_Movimiento PRIMARY KEY (movimiento_id),
    CONSTRAINT FK_Stock_Producto FOREIGN KEY (producto_id) REFERENCES FLORERIA_Producto(producto_id),
    CONSTRAINT FK_Stock_Variacion FOREIGN KEY (variacion_id) REFERENCES FLORERIA_Producto_Variacion(variacion_id),
    CONSTRAINT FK_Stock_Usuario FOREIGN KEY (usuario_id) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT CK_Stock_TipoMovimiento CHECK (tipo_movimiento IN ('ENTRADA', 'SALIDA', 'AJUSTE', 'DEVOLUCION'))
);

-- =============================================
-- MÓDULO 6: PRE-PEDIDOS Y PEDIDOS (6 TABLAS)
-- =============================================

-- Tabla 26: FLORERIA_PrePedido
CREATE TABLE FLORERIA_PrePedido (
    prepedido_id       INT IDENTITY(1,1) NOT NULL,
    codigo             VARCHAR(20) NOT NULL,
    tipo_registro      VARCHAR(20) NOT NULL DEFAULT 'PRE_PEDIDO',
    estado             VARCHAR(30) NOT NULL DEFAULT 'BORRADOR',
    tasa_cambio        DECIMAL(10, 4) NOT NULL DEFAULT 7.0000,
    fecha_limite_pago  DATETIME NULL,
    cliente_celular    VARCHAR(20) NOT NULL,
    cliente_nombre     VARCHAR(200) NULL,
    cliente_apellidos  VARCHAR(200) NULL,
    cliente_email      VARCHAR(100) NULL,
    cliente_pais_id    TINYINT NULL,
    cliente_ciudad_id  SMALLINT NULL,
    agente_actual_id   INT NULL,
    total_general_bs   DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_general_usd  DECIMAL(10, 2) NOT NULL DEFAULT 0,
    descuento_bs       DECIMAL(10, 2) NOT NULL DEFAULT 0,
    descuento_usd      DECIMAL(10, 2) NOT NULL DEFAULT 0,
    descuento_motivo   VARCHAR(300) NULL,
    moneda_formulario  CHAR(3) NULL,
    token_web          VARCHAR(100) NULL,
    token_expira       DATETIME NULL,
    notas_internas     NVARCHAR(1000) NULL,
    creado_por         INT NOT NULL,
    creado_en          DATETIME NOT NULL DEFAULT GETDATE(),
    modificado_por     INT NULL,
    modificado_en      DATETIME NULL,
    CONSTRAINT PK_PrePedido PRIMARY KEY (prepedido_id),
    CONSTRAINT UQ_PrePedido_Codigo UNIQUE (codigo),
    CONSTRAINT UQ_PrePedido_Token UNIQUE (token_web),
    CONSTRAINT FK_PrePedido_Pais FOREIGN KEY (cliente_pais_id) REFERENCES FLORERIA_Pais(pais_id),
    CONSTRAINT FK_PrePedido_Ciudad FOREIGN KEY (cliente_ciudad_id) REFERENCES FLORERIA_Ciudad(ciudad_id),
    CONSTRAINT FK_PrePedido_Agente FOREIGN KEY (agente_actual_id) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT FK_PrePedido_Creador FOREIGN KEY (creado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT FK_PrePedido_Modificador FOREIGN KEY (modificado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT CK_PrePedido_Tipo CHECK (tipo_registro IN ('PRE_PEDIDO', 'VENTA_TIENDA', 'VENTA_ANTIGUA')),
    CONSTRAINT CK_PrePedido_Estado CHECK (estado IN ('BORRADOR', 'FORM_ENVIADO', 'FORM_COMPLETADO', 'COMPROBANTE_ENVIADO', 'PAGADO', 'COMPLETADO', 'CANCELADO', 'EXPIRADO')),
    CONSTRAINT CK_PrePedido_Moneda CHECK (moneda_formulario IN ('BOB', 'USD'))
);

-- Tabla 27: FLORERIA_Pedido
CREATE TABLE FLORERIA_Pedido (
    pedido_id              INT IDENTITY(1,1) NOT NULL,
    prepedido_id           INT NOT NULL,
    codigo                 VARCHAR(20) NOT NULL,
    receptor_nombre        VARCHAR(200) NOT NULL,
    receptor_celular       VARCHAR(20) NOT NULL,
    ciudad_id              SMALLINT NOT NULL,
    zona_id                INT NULL,
    sucursal_id            SMALLINT NULL,
    tipo_entrega           VARCHAR(20) NOT NULL,
    direccion              VARCHAR(300) NULL,
    referencia             VARCHAR(300) NULL,
    fecha_entrega          DATE NOT NULL,
    slot_id                SMALLINT NULL,
    es_express             BIT NOT NULL DEFAULT 0,
    dedicatoria            NVARCHAR(500) NULL,
    firma_tarjeta          VARCHAR(100) NULL,
    subtotal_productos_bs  DECIMAL(10, 2) NOT NULL DEFAULT 0,
    subtotal_productos_usd DECIMAL(10, 2) NOT NULL DEFAULT 0,
    envio_bs               DECIMAL(10, 2) NOT NULL DEFAULT 0,
    envio_usd              DECIMAL(10, 2) NOT NULL DEFAULT 0,
    recargo_express_bs     DECIMAL(10, 2) NOT NULL DEFAULT 0,
    recargo_express_usd    DECIMAL(10, 2) NOT NULL DEFAULT 0,
    recargo_horario_bs     DECIMAL(10, 2) NOT NULL DEFAULT 0,
    recargo_horario_usd    DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_bs               DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_usd              DECIMAL(10, 2) NOT NULL DEFAULT 0,
    anticipo_bs            DECIMAL(10, 2) NOT NULL DEFAULT 0,
    saldo_bs               DECIMAL(10, 2) NOT NULL DEFAULT 0,
    estado_pago            VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    wc_order_id            INT NULL,
    wc_sync_estado         VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    wc_sync_fecha          DATETIME NULL,
    creado_por             INT NOT NULL,
    creado_en              DATETIME NOT NULL DEFAULT GETDATE(),
    modificado_por         INT NULL,
    modificado_en          DATETIME NULL,
    CONSTRAINT PK_Pedido PRIMARY KEY (pedido_id),
    CONSTRAINT UQ_Pedido_Codigo UNIQUE (codigo),
    CONSTRAINT FK_Pedido_PrePedido FOREIGN KEY (prepedido_id) REFERENCES FLORERIA_PrePedido(prepedido_id),
    CONSTRAINT FK_Pedido_Ciudad FOREIGN KEY (ciudad_id) REFERENCES FLORERIA_Ciudad(ciudad_id),
    CONSTRAINT FK_Pedido_Zona FOREIGN KEY (zona_id) REFERENCES FLORERIA_Zona(zona_id),
    CONSTRAINT FK_Pedido_Sucursal FOREIGN KEY (sucursal_id) REFERENCES FLORERIA_Sucursal(sucursal_id),
    CONSTRAINT FK_Pedido_Slot FOREIGN KEY (slot_id) REFERENCES FLORERIA_Slot_Horario(slot_id),
    CONSTRAINT FK_Pedido_Creador FOREIGN KEY (creado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT FK_Pedido_Modificador FOREIGN KEY (modificado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT CK_Pedido_TipoEntrega CHECK (tipo_entrega IN ('DOMICILIO', 'RECOJO_SUCURSAL')),
    CONSTRAINT CK_Pedido_EstadoPago CHECK (estado_pago IN ('PENDIENTE', 'PAGADO', 'PARCIAL')),
    CONSTRAINT CK_Pedido_WcSync CHECK (wc_sync_estado IN ('PENDIENTE', 'SINCRONIZADO', 'ERROR'))
);

-- Tabla 28: FLORERIA_Pedido_Detalle
CREATE TABLE FLORERIA_Pedido_Detalle (
    detalle_id           INT IDENTITY(1,1) NOT NULL,
    pedido_id            INT NOT NULL,
    producto_id          INT NULL,
    variacion_id         INT NULL,
    es_personalizado     BIT NOT NULL DEFAULT 0,
    nombre_producto      VARCHAR(200) NOT NULL,
    descripcion          NVARCHAR(500) NULL,
    cantidad             INT NOT NULL DEFAULT 1,
    precio_unitario_bs   DECIMAL(10, 2) NOT NULL,
    precio_unitario_usd  DECIMAL(10, 2) NOT NULL,
    subtotal_bs          DECIMAL(10, 2) NOT NULL,
    subtotal_usd         DECIMAL(10, 2) NOT NULL,
    personalizacion      NVARCHAR(500) NULL,
    creado_en            DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Pedido_Detalle PRIMARY KEY (detalle_id),
    CONSTRAINT FK_Pedido_Detalle_Pedido FOREIGN KEY (pedido_id) REFERENCES FLORERIA_Pedido(pedido_id),
    CONSTRAINT FK_Pedido_Detalle_Producto FOREIGN KEY (producto_id) REFERENCES FLORERIA_Producto(producto_id),
    CONSTRAINT FK_Pedido_Detalle_Variacion FOREIGN KEY (variacion_id) REFERENCES FLORERIA_Producto_Variacion(variacion_id)
);

-- Tabla 29: FLORERIA_Pedido_Pago
CREATE TABLE FLORERIA_Pedido_Pago (
    pago_id        INT IDENTITY(1,1) NOT NULL,
    pedido_id      INT NOT NULL,
    prepedido_id   INT NOT NULL,
    metodo_pago    VARCHAR(30) NOT NULL,
    moneda         CHAR(3) NOT NULL,
    monto          DECIMAL(10, 2) NOT NULL,
    tasa_cambio    DECIMAL(10, 4) NULL,
    fecha_pago     DATETIME NOT NULL DEFAULT GETDATE(),
    referencia     VARCHAR(100) NULL,
    verificado     BIT NOT NULL DEFAULT 0,
    verificado_por INT NULL,
    verificado_en  DATETIME NULL,
    creado_por     INT NOT NULL,
    creado_en      DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Pedido_Pago PRIMARY KEY (pago_id),
    CONSTRAINT FK_Pedido_Pago_Pedido FOREIGN KEY (pedido_id) REFERENCES FLORERIA_Pedido(pedido_id),
    CONSTRAINT FK_Pedido_Pago_PrePedido FOREIGN KEY (prepedido_id) REFERENCES FLORERIA_PrePedido(prepedido_id),
    CONSTRAINT FK_Pedido_Pago_Verificador FOREIGN KEY (verificado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT FK_Pedido_Pago_Creador FOREIGN KEY (creado_por) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT CK_Pago_Metodo CHECK (metodo_pago IN ('EFECTIVO', 'TARJETA', 'QR', 'TRANSFERENCIA', 'PAGOMOVIL')),
    CONSTRAINT CK_Pago_Moneda CHECK (moneda IN ('BOB', 'USD'))
);

-- Tabla 30: FLORERIA_Pedido_Estado_Log
CREATE TABLE FLORERIA_Pedido_Estado_Log (
    log_id       INT IDENTITY(1,1) NOT NULL,
    pedido_id    INT NOT NULL,
    estado_nuevo VARCHAR(30) NOT NULL,
    comentario   VARCHAR(500) NULL,
    usuario_id   INT NOT NULL,
    fecha_hora   DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Pedido_Estado_Log PRIMARY KEY (log_id),
    CONSTRAINT FK_Pedido_Estado_Log_Pedido FOREIGN KEY (pedido_id) REFERENCES FLORERIA_Pedido(pedido_id),
    CONSTRAINT FK_Pedido_Estado_Log_Usuario FOREIGN KEY (usuario_id) REFERENCES FLORERIA_Usuario(usuario_id)
);

-- Tabla 31: FLORERIA_Pedido_Reprogramacion
CREATE TABLE FLORERIA_Pedido_Reprogramacion (
    reprog_id          INT IDENTITY(1,1) NOT NULL,
    pedido_id          INT NOT NULL,
    fecha_anterior     DATE NOT NULL,
    fecha_nueva        DATE NOT NULL,
    slot_anterior_id   SMALLINT NULL,
    slot_nuevo_id      SMALLINT NULL,
    motivo             VARCHAR(300) NOT NULL,
    solicitado_por     VARCHAR(20) NOT NULL,
    usuario_id         INT NULL,
    fecha_hora         DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_Pedido_Reprogramacion PRIMARY KEY (reprog_id),
    CONSTRAINT FK_Pedido_Reprogramacion_Pedido FOREIGN KEY (pedido_id) REFERENCES FLORERIA_Pedido(pedido_id),
    CONSTRAINT FK_Pedido_Reprogramacion_SlotAnterior FOREIGN KEY (slot_anterior_id) REFERENCES FLORERIA_Slot_Horario(slot_id),
    CONSTRAINT FK_Pedido_Reprogramacion_SlotNuevo FOREIGN KEY (slot_nuevo_id) REFERENCES FLORERIA_Slot_Horario(slot_id),
    CONSTRAINT FK_Pedido_Reprogramacion_Usuario FOREIGN KEY (usuario_id) REFERENCES FLORERIA_Usuario(usuario_id),
    CONSTRAINT CK_Reprogramacion_Solicitante CHECK (solicitado_por IN ('CLIENTE', 'AGENTE', 'SISTEMA'))
);

GO

-- =============================================
-- FIN DE CREACIÓN DE TABLAS
-- =============================================