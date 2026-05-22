# =============================================
# SISCONBOL - SISTEMA INTEGRAL FLORERÍA
# ESTRUCTURA COMPLETA DE BASE DE DATOS
# =============================================

## 📊 RESUMEN GENERAL

```
TABLAS TOTALES:        31
STORED PROCEDURES:     48 existentes + 8 nuevos = 56 TOTAL
FOREIGN KEYS:          67 relaciones
ÍNDICES:               51
VISTAS:                0
```

---

## 🗄️ SECCIÓN 1: TABLAS EXISTENTES (13 TABLAS BASE)

### 1.1 GESTIÓN DE USUARIOS Y ACCESOS

#### FLORERIA_TipoUsuario
**Propósito:** Tipos de usuario (Admin, Supervisor, Agente, etc.)
```sql
tipo_id               SMALLINT PK IDENTITY
nombre                VARCHAR(50) UNIQUE
descripcion           VARCHAR(200)
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

#### FLORERIA_Usuario
**Propósito:** Usuarios del sistema con autenticación
```sql
usuario_id            INT PK IDENTITY
tipo_id               SMALLINT FK → TipoUsuario
carnet                VARCHAR(8) UNIQUE
nombres               VARCHAR(100)
apellidos             VARCHAR(100)
celular               VARCHAR(20)
email                 VARCHAR(100)
direccion             VARCHAR(200)
fecha_nac             DATE
password_hash         VARCHAR(200)         -- SHA256
password_salt         VARCHAR(50)          -- FLORERIA2026
debe_cambiar_pwd      BIT DEFAULT 1
vigente_desde         DATE
vigente_hasta         DATE
activo                BIT DEFAULT 1
bloqueado             BIT DEFAULT 0
intentos_fallidos     TINYINT DEFAULT 0
bloqueado_hasta       DATETIME
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

**Constraint:** 
```sql
CK_Carnet: carnet solo dígitos, 7-8 caracteres
```

#### FLORERIA_Sesion
**Propósito:** Control de sesiones activas
```sql
sesion_id             BIGINT PK IDENTITY
usuario_id            INT FK → Usuario
token                 VARCHAR(100) UNIQUE
ip                    VARCHAR(50)
user_agent            VARCHAR(500)
es_celular            BIT DEFAULT 0
dispositivo           VARCHAR(100)
sistema_op            VARCHAR(50)
navegador             VARCHAR(50)
inicio                DATETIME DEFAULT GETDATE()
ultimo_acceso         DATETIME DEFAULT GETDATE()
expira_en             DATETIME
activa                BIT DEFAULT 1
cerrada_por           VARCHAR(20)          -- USUARIO, SISTEMA, NUEVA_SESION
```

#### FLORERIA_Menu
**Propósito:** Estructura jerárquica de menús
```sql
menu_id               SMALLINT PK IDENTITY
padre_id              SMALLINT FK → Menu (nullable)
nombre                VARCHAR(80)
icono                 VARCHAR(50)          -- ti-home, ti-package
ruta                  VARCHAR(200)
orden                 TINYINT DEFAULT 0
activo                BIT DEFAULT 1
```

#### FLORERIA_TipoUsuario_Menu
**Propósito:** Permisos por tipo de usuario
```sql
tipomenu_id           INT PK IDENTITY
tipo_id               SMALLINT FK → TipoUsuario
menu_id               SMALLINT FK → Menu
puede_ver             BIT DEFAULT 1
puede_crear           BIT DEFAULT 0
puede_editar          BIT DEFAULT 0
puede_eliminar        BIT DEFAULT 0
```

**Constraint:** 
```sql
UQ_TipoMenu: UNIQUE(tipo_id, menu_id)
```

#### FLORERIA_Usuario_Menu
**Propósito:** Excepciones de permisos individuales
```sql
usumenu_id            INT PK IDENTITY
usuario_id            INT FK → Usuario
menu_id               SMALLINT FK → Menu
tipo_excepcion        VARCHAR(10)          -- AGREGAR, QUITAR
puede_ver             BIT DEFAULT 1
puede_crear           BIT DEFAULT 0
puede_editar          BIT DEFAULT 0
puede_eliminar        BIT DEFAULT 0
motivo                VARCHAR(300)
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
```

**Constraint:** 
```sql
UQ_UsuMenu: UNIQUE(usuario_id, menu_id)
CK_Excepcion: tipo_excepcion IN ('AGREGAR', 'QUITAR')
```

### 1.2 CONFIGURACIÓN Y AUDITORÍA

#### FLORERIA_Config
**Propósito:** Configuraciones del sistema (key-value)
```sql
config_id             INT PK IDENTITY
clave                 VARCHAR(100) UNIQUE
valor                 NVARCHAR(500)
descripcion           VARCHAR(300)
es_secreto            BIT DEFAULT 0        -- Ocultar en UI
activo                BIT DEFAULT 1
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

**Configuraciones típicas:**
```
TASA_CAMBIO_USD     = 7.00
WC_API_URL          = https://miss-flores.com/wp-json/wc/v3
WC_API_KEY          = ck_xxxxxx (secreto)
WC_API_SECRET       = cs_xxxxxx (secreto)
WHATSAPP_API_TOKEN  = xxxxxx (secreto)
CELULAR_RECEPCION   = 59163198342
TIMEOUT_SESION      = 480 (minutos)
```

#### FLORERIA_Auditoria
**Propósito:** Log de cambios críticos
```sql
audit_id              BIGINT PK IDENTITY
usuario_id            INT FK → Usuario
usuario_nombre        VARCHAR(200)
ip                    VARCHAR(50)
es_celular            BIT
dispositivo           VARCHAR(100)
tabla                 VARCHAR(100)         -- Ej: FLORERIA_Producto
registro_id           VARCHAR(50)          -- ID del registro afectado
accion                VARCHAR(10)          -- INSERTAR, MODIFICAR, ELIMINAR
valor_anterior        NVARCHAR(MAX)        -- JSON del registro antes
valor_nuevo           NVARCHAR(MAX)        -- JSON del registro después
motivo                VARCHAR(500)
fecha_hora            DATETIME DEFAULT GETDATE()
```

**Constraint:** 
```sql
CK_Accion: accion IN ('INSERTAR', 'MODIFICAR', 'ELIMINAR')
```

### 1.3 CATÁLOGO DE PRODUCTOS

#### FLORERIA_Categoria
**Propósito:** Categorías jerárquicas de productos
```sql
categoria_id          INT PK IDENTITY
padre_id              INT FK → Categoria (nullable)
nombre                VARCHAR(150)
descripcion           VARCHAR(500)
slug                  VARCHAR(160) UNIQUE
orden                 INT DEFAULT 0
activo                BIT DEFAULT 1
wc_category_id        INT                  -- ID en WooCommerce
wc_sync_estado        VARCHAR(20) DEFAULT 'PENDIENTE'
wc_sync_fecha         DATETIME
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

**Constraint:** 
```sql
CK_WC_Sync: wc_sync_estado IN ('PENDIENTE', 'SINCRONIZADO', 'ERROR', 'IGNORAR')
```

#### FLORERIA_Producto
**Propósito:** Productos principales
```sql
producto_id           INT PK IDENTITY
sku                   VARCHAR(50) UNIQUE
nombre                VARCHAR(200)
descripcion           NVARCHAR(MAX)
categoria_id          INT FK → Categoria (nullable)
precio_base_bs        DECIMAL(10,2) DEFAULT 0
precio_base_usd       DECIMAL(10,2)
precio_promo_bs       DECIMAL(10,2)
precio_promo_usd      DECIMAL(10,2)
promo_desde           DATE
promo_hasta           DATE
tiene_variaciones     BIT DEFAULT 0
destacado             BIT DEFAULT 0
menu_order            INT DEFAULT 0
notas_internas        NVARCHAR(500)
stock_actual          INT DEFAULT 0
stock_minimo          INT DEFAULT 5
imagen_url            VARCHAR(500)
wc_product_id         INT                  -- ID en WooCommerce
wc_sync_estado        VARCHAR(20) DEFAULT 'PENDIENTE'
wc_sync_fecha         DATETIME
activo                BIT DEFAULT 1
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

#### FLORERIA_Producto_Variacion
**Propósito:** Variaciones de productos (talla, color, etc.)
```sql
variacion_id          INT PK IDENTITY
producto_id           INT FK → Producto
sku_variacion         VARCHAR(60) UNIQUE
atrib_1_nombre        VARCHAR(40)          -- Ej: "Talla"
atrib_1_valor         VARCHAR(80)          -- Ej: "Grande"
atrib_2_nombre        VARCHAR(40)
atrib_2_valor         VARCHAR(80)
atrib_3_nombre        VARCHAR(40)
atrib_3_valor         VARCHAR(80)
precio_bs             DECIMAL(10,2)
precio_usd            DECIMAL(10,2)
precio_promo_bs       DECIMAL(10,2)
precio_promo_usd      DECIMAL(10,2)
promo_desde           DATE
promo_hasta           DATE
wc_variation_id       INT
wc_sync_estado        VARCHAR(20) DEFAULT 'PENDIENTE'
wc_sync_fecha         DATETIME
activo                BIT DEFAULT 1
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

#### FLORERIA_Producto_Categoria
**Propósito:** Relación muchos-a-muchos Producto-Categoría
```sql
prodcat_id            INT PK IDENTITY
producto_id           INT FK → Producto
categoria_id          INT FK → Categoria
es_principal          BIT DEFAULT 0        -- Solo 1 por producto
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
```

**Constraint:** 
```sql
UQ_ProdCat: UNIQUE(producto_id, categoria_id)
```

#### FLORERIA_Producto_Disponibilidad
**Propósito:** Stock por sucursal o aliado
```sql
disp_id               INT PK IDENTITY
producto_id           INT FK → Producto
variacion_id          INT FK → Variacion (nullable)
sucursal_id           SMALLINT FK → Sucursal (nullable)
aliado_id             INT FK → Aliado (nullable)
disponible            BIT DEFAULT 1
stock_actual          INT DEFAULT 0
stock_minimo          INT DEFAULT 5
stock_reservado       INT DEFAULT 0
precio_bs             DECIMAL(10,2)
precio_usd            DECIMAL(10,2)
costo_aliado_bs       DECIMAL(10,2)
actualizado_por       INT FK → Usuario
actualizado_en        DATETIME DEFAULT GETDATE()
```

**Constraint:** 
```sql
CK_Operador: (sucursal_id IS NOT NULL AND aliado_id IS NULL) 
          OR (sucursal_id IS NULL AND aliado_id IS NOT NULL)
UQ_PD_Suc: UNIQUE(producto_id, variacion_id, sucursal_id)
UQ_PD_Ali: UNIQUE(producto_id, variacion_id, aliado_id)
```

---

## 🗄️ SECCIÓN 2: TABLAS GEOGRAFÍA (9 TABLAS)

### 2.1 JERARQUÍA GEOGRÁFICA

#### FLORERIA_Pais
**Propósito:** Países donde opera (Bolivia, Perú)
```sql
pais_id               TINYINT PK IDENTITY
codigo_iso            CHAR(2) UNIQUE       -- BO, PE
nombre                VARCHAR(80)
moneda_codigo         CHAR(3) DEFAULT 'BOB'
moneda_simbolo        VARCHAR(5) DEFAULT 'Bs'
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

**Datos semilla:**
```sql
INSERT INTO FLORERIA_Pais VALUES 
(1, 'BO', 'Bolivia', 'BOB', 'Bs', 1, GETDATE()),
(2, 'PE', 'Perú', 'PEN', 'S/', 1, GETDATE());
```

#### FLORERIA_Departamento
**Propósito:** Departamentos/Estados
```sql
depto_id              SMALLINT PK IDENTITY
pais_id               TINYINT FK → Pais
nombre                VARCHAR(100)
codigo                VARCHAR(10)          -- LP, CB, SC
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

**Datos semilla (Bolivia):**
```sql
(1, 1, 'La Paz', 'LP'),
(2, 1, 'Cochabamba', 'CB'),
(3, 1, 'Santa Cruz', 'SC');
```

#### FLORERIA_Ciudad
**Propósito:** Ciudades donde se opera
```sql
ciudad_id             SMALLINT PK IDENTITY
depto_id              SMALLINT FK → Departamento
nombre                VARCHAR(100)
codigo                VARCHAR(10)          -- LPZ, CBB, SCZ
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

**Datos semilla:**
```sql
(1, 1, 'La Paz', 'LPZ'),
(2, 1, 'El Alto', 'ELA'),
(3, 2, 'Cochabamba', 'CBB'),
(4, 3, 'Santa Cruz', 'SCZ');
```

### 2.2 ZONAS Y TARIFAS

#### FLORERIA_Zona
**Propósito:** Zonas de entrega
```sql
zona_id               INT PK IDENTITY
ciudad_id             SMALLINT FK → Ciudad
nombre                VARCHAR(150)
codigo                VARCHAR(20)          -- BO100, BO101...
tipo                  VARCHAR(20) DEFAULT 'DELIVERY'
latitud_ref           DECIMAL(10,7)
longitud_ref          DECIMAL(10,7)
wc_zone_id            INT                  -- ID zona WooCommerce
wc_zone_code          VARCHAR(20)
activo                BIT DEFAULT 1
orden_display         SMALLINT DEFAULT 0
creado_en             DATETIME DEFAULT GETDATE()
```

**Constraint:** 
```sql
CK_Tipo: tipo IN ('DELIVERY', 'RECOJO_SUCURSAL', 'SIN_COBERTURA')
```

**Datos semilla (La Paz):**
```sql
(1, 1, 'Sopocachi', 'BO100', 'DELIVERY', -16.5000, -68.1193, 1, 'BO100', 1, 1),
(2, 1, 'San Miguel', 'BO101', 'DELIVERY', -16.5100, -68.1200, 1, 'BO101', 1, 2),
(3, 1, 'Miraflores', 'BO102', 'DELIVERY', -16.5200, -68.1150, 1, 'BO102', 1, 3),
...
(22, 1, 'Recojo Sopocachi', 'BO121', 'RECOJO_SUCURSAL', -16.5000, -68.1193, 1, 'BO121', 1, 22);
```

#### FLORERIA_Zona_Tarifa
**Propósito:** Tarifas de envío por zona con vigencia
```sql
tarifa_id             INT PK IDENTITY
zona_id               INT FK → Zona
precio_bs             DECIMAL(10,2) DEFAULT 0
precio_usd            DECIMAL(10,2)
vigente_desde         DATE DEFAULT CAST(GETDATE() AS DATE)
vigente_hasta         DATE (nullable)
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
motivo_cambio         VARCHAR(200)
```

**Datos semilla:**
```sql
-- Tarifas vigentes desde 2026-01-01
(1, 1, 35.00, 5.00, '2026-01-01', NULL),  -- Sopocachi
(2, 2, 30.00, 4.29, '2026-01-01', NULL),  -- San Miguel
(3, 3, 35.00, 5.00, '2026-01-01', NULL),  -- Miraflores
...
(22, 22, 0.00, 0.00, '2026-01-01', NULL); -- Recojo (gratis)
```

#### FLORERIA_Zona_Express
**Propósito:** Configuración de entrega express por zona
```sql
express_id            INT PK IDENTITY
zona_id               INT FK → Zona
minutos_limite        SMALLINT             -- 30, 60, 90
etiqueta              VARCHAR(30)          -- "Express 30 min"
recargo_bs            DECIMAL(10,2) DEFAULT 0
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

**Constraint:** 
```sql
UQ_Zona_Express: UNIQUE(zona_id, minutos_limite)
```

**Datos semilla:**
```sql
(1, 1, 30, 'Express 30 min', 100.00, 1),  -- Sopocachi
(2, 2, 30, 'Express 30 min', 100.00, 1),  -- San Miguel
(3, 3, 30, 'Express 30 min', 100.00, 1);  -- Miraflores
```

### 2.3 SUCURSALES

#### FLORERIA_Sucursal
**Propósito:** Puntos de venta físicos
```sql
sucursal_id           SMALLINT PK IDENTITY
ciudad_id             SMALLINT FK → Ciudad
codigo                VARCHAR(10) UNIQUE   -- SUC01, SUC02
nombre                VARCHAR(100)
direccion             VARCHAR(200)
telefono              VARCHAR(20)
email                 VARCHAR(100)
latitud               DECIMAL(10,7)
longitud              DECIMAL(10,7)
hora_apertura         TIME DEFAULT '08:00'
hora_cierre           TIME DEFAULT '20:00'
dias_operacion        VARCHAR(20) DEFAULT 'L,M,X,J,V,S'
fondo_fijo_bs         DECIMAL(10,2) DEFAULT 200.00
wc_zone_id            INT
wc_zone_code          VARCHAR(20)
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

**Datos semilla:**
```sql
(1, 1, 'SUC01', 'Sucursal Sopocachi', 'Av. 20 de Octubre 2050', '2-2345678', 
 'sopocachi@missflores.com', -16.5000, -68.1193, '08:00', '20:00', 
 'L,M,X,J,V,S', 200.00, 1, 'BO121', 1),
 
(2, 1, 'SUC02', 'Sucursal Calacoto', 'Calle 10 Calacoto 7800', '2-2789012',
 'calacoto@missflores.com', -16.5500, -68.0800, '09:00', '19:00',
 'L,M,X,J,V,S', 200.00, 1, 'BO122', 1);
```

#### FLORERIA_Sucursal_Zona
**Propósito:** Zonas atendidas por cada sucursal
```sql
suc_zona_id           INT PK IDENTITY
sucursal_id           SMALLINT FK → Sucursal
zona_id               INT FK → Zona
prioridad             TINYINT DEFAULT 1    -- Orden de preferencia
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

**Constraint:** 
```sql
UQ_Sucursal_Zona: UNIQUE(sucursal_id, zona_id)
```

### 2.4 SLOTS HORARIOS

#### FLORERIA_Slot_Horario
**Propósito:** Horarios de entrega disponibles
```sql
slot_id               SMALLINT PK IDENTITY
ciudad_id             SMALLINT FK → Ciudad
etiqueta              VARCHAR(60)
hora_inicio           TIME
hora_fin              TIME
duracion_minutos      SMALLINT DEFAULT 180 -- 3 horas normal
recargo_bs            DECIMAL(10,2) DEFAULT 0
es_express            BIT DEFAULT 0
activo                BIT DEFAULT 1
orden_display         TINYINT DEFAULT 0
wc_slot_value         VARCHAR(50)          -- Para sincronización WC
creado_en             DATETIME DEFAULT GETDATE()
```

**Datos semilla (La Paz):**
```sql
-- SLOTS NORMALES (3 horas)
(1, 1, '06:00-09:00', '06:00', '09:00', 180, 70.00, 0, 1, 1, 'morning_early'),
(2, 1, '09:00-12:00', '09:00', '12:00', 180, 0.00, 0, 1, 2, 'morning'),
(3, 1, '12:00-15:00', '12:00', '15:00', 180, 0.00, 0, 1, 3, 'afternoon'),
(4, 1, '15:00-18:00', '15:00', '18:00', 180, 0.00, 0, 1, 4, 'evening'),
(5, 1, '18:00-21:00', '18:00', '21:00', 180, 0.00, 0, 1, 5, 'night'),

-- SLOT EXPRESS (30 minutos)
(6, 1, 'Express 30 min', '00:00', '23:59', 30, 0.00, 1, 1, 6, 'express_30');
```

---

## 🗄️ SECCIÓN 3: TABLAS ALIADOS (2 TABLAS)

### FLORERIA_Aliado
**Propósito:** Florerías aliadas para pedidos externos
```sql
aliado_id             INT PK IDENTITY
ciudad_id             SMALLINT FK → Ciudad
nombre_negocio        VARCHAR(150)
nombre_contacto       VARCHAR(100)
telefono              VARCHAR(20)
whatsapp              VARCHAR(20)
email                 VARCHAR(100)
direccion             VARCHAR(200)
moneda                CHAR(3) DEFAULT 'BOB'
dias_pago             TINYINT DEFAULT 7    -- Días crédito
notas_comercial       VARCHAR(500)
metodo_aviso          VARCHAR(20) DEFAULT 'WHATSAPP_MANUAL'
usuario_id            INT FK → Usuario (nullable - si tiene acceso)
activo                BIT DEFAULT 1
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

### FLORERIA_Aliado_Zona
**Propósito:** Zonas atendidas por aliado
```sql
aliado_zona_id        INT PK IDENTITY
aliado_id             INT FK → Aliado
zona_id               INT FK → Zona
prioridad             TINYINT DEFAULT 1
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

**Constraint:** 
```sql
UQ_Aliado_Zona: UNIQUE(aliado_id, zona_id)
```

---

## 🗄️ SECCIÓN 4: TABLAS PRE-PEDIDOS (7 TABLAS)

### 4.1 PRE-PEDIDO PRINCIPAL

#### FLORERIA_PrePedido
**Propósito:** Contenedor de múltiples pedidos
```sql
prepedido_id          INT PK IDENTITY
codigo                VARCHAR(20) UNIQUE   -- PRE-000001
token_web             VARCHAR(100) UNIQUE  -- GUID doble para link
tipo_registro         VARCHAR(20) DEFAULT 'PRE_PEDIDO'

-- CLIENTE PAGADOR
cliente_celular       VARCHAR(20)
cliente_nombre        VARCHAR(200)
cliente_apellidos     VARCHAR(200)
cliente_email         VARCHAR(100)
cliente_pais_id       TINYINT FK → Pais
cliente_ciudad_id     SMALLINT FK → Ciudad

-- ESTADO Y FLUJO
estado                VARCHAR(30) DEFAULT 'BORRADOR'
fecha_limite_pago     DATETIME
token_expira          DATETIME             -- token_web + 48 horas

-- MONTOS GENERALES
total_general_bs      DECIMAL(10,2) DEFAULT 0
total_general_usd     DECIMAL(10,2) DEFAULT 0
tasa_cambio           DECIMAL(10,4) DEFAULT 7.0000
moneda_formulario     CHAR(3) DEFAULT 'BOB'

-- DESCUENTO (solo agente)
descuento_bs          DECIMAL(10,2) DEFAULT 0
descuento_usd         DECIMAL(10,2) DEFAULT 0
descuento_motivo      VARCHAR(300)

-- AGENTE RESPONSABLE
agente_actual_id      INT FK → Usuario
observaciones         NVARCHAR(500)

-- AUDITORÍA
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

**Constraints:**
```sql
CK_TipoRegistro: tipo_registro IN ('PRE_PEDIDO', 'VENTA_TIENDA', 'VENTA_ANTIGUA')
CK_Estado: estado IN ('BORRADOR', 'FORM_ENVIADO', 'FORM_COMPLETADO', 
                       'COMPROBANTE_ENVIADO', 'PAGADO', 'WC_CREADO', 
                       'COMPLETADO', 'EXPIRADO', 'CANCELADO', 'RECHAZADO', 'ERROR_WC')
UQ_Codigo: codigo UNIQUE
UQ_Token: token_web UNIQUE
```

### 4.2 PEDIDOS (ENTREGAS)

#### FLORERIA_Pedido
**Propósito:** Cada entrega individual dentro de un pre-pedido
```sql
pedido_id             INT PK IDENTITY
prepedido_id          INT FK → PrePedido (nullable para legado)
codigo                VARCHAR(20) UNIQUE   -- PED-000001

-- RECEPTOR
receptor_nombre       VARCHAR(200)
receptor_celular      VARCHAR(20)

-- UBICACIÓN
ciudad_id             SMALLINT FK → Ciudad
zona_id               INT FK → Zona (nullable)
sucursal_id           SMALLINT FK → Sucursal (nullable para recojo)
tipo_entrega          VARCHAR(20) DEFAULT 'DOMICILIO'
direccion             VARCHAR(300)
latitud               DECIMAL(10,7)
longitud              DECIMAL(10,7)
referencia            VARCHAR(300)

-- FECHA Y HORARIO
fecha_entrega         DATE
slot_id               SMALLINT FK → Slot_Horario
es_express            BIT DEFAULT 0

-- TARJETA
dedicatoria           NVARCHAR(500)
firma_tarjeta         VARCHAR(100)

-- MONTOS
subtotal_productos_bs DECIMAL(10,2) DEFAULT 0
subtotal_productos_usd DECIMAL(10,2) DEFAULT 0
envio_bs              DECIMAL(10,2) DEFAULT 0
envio_usd             DECIMAL(10,2) DEFAULT 0
recargo_express_bs    DECIMAL(10,2) DEFAULT 0
recargo_express_usd   DECIMAL(10,2) DEFAULT 0
recargo_horario_bs    DECIMAL(10,2) DEFAULT 0
recargo_horario_usd   DECIMAL(10,2) DEFAULT 0
total_bs              DECIMAL(10,2) DEFAULT 0
total_usd             DECIMAL(10,2) DEFAULT 0

-- PAGO (seguimiento interno)
anticipo_bs           DECIMAL(10,2) DEFAULT 0
saldo_bs              DECIMAL(10,2) DEFAULT 0
estado_pago           VARCHAR(20) DEFAULT 'PENDIENTE'

-- WOOCOMMERCE
wc_order_id           INT
wc_order_number       VARCHAR(30)
wc_order_url          VARCHAR(300)
wc_sync_estado        VARCHAR(20) DEFAULT 'PENDIENTE'
wc_sync_fecha         DATETIME

-- OBSERVACIONES
observaciones         NVARCHAR(500)

-- AUDITORÍA
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

**Constraints:**
```sql
CK_TipoEntrega: tipo_entrega IN ('DOMICILIO', 'RECOJO_SUCURSAL')
CK_EstadoPago: estado_pago IN ('PENDIENTE', 'ANTICIPO', 'PAGADO', 'REEMBOLSADO')
CK_WcSync: wc_sync_estado IN ('PENDIENTE', 'SINCRONIZADO', 'ERROR', 'IGNORAR')
UQ_Codigo: codigo UNIQUE
```

#### FLORERIA_Pedido_Detalle
**Propósito:** Productos de cada pedido
```sql
detalle_id            INT PK IDENTITY
pedido_id             INT FK → Pedido
producto_id           INT FK → Producto (nullable si personalizado)
variacion_id          INT FK → Producto_Variacion (nullable)
es_personalizado      BIT DEFAULT 0
nombre_producto       VARCHAR(200)
descripcion           NVARCHAR(500)
cantidad              INT DEFAULT 1
precio_unitario_bs    DECIMAL(10,2)
precio_unitario_usd   DECIMAL(10,2)
subtotal_bs           DECIMAL(10,2)
subtotal_usd          DECIMAL(10,2)
personalizacion       NVARCHAR(500)        -- Observaciones del cliente
wc_line_item_id       BIGINT               -- ID línea en WooCommerce
creado_en             DATETIME DEFAULT GETDATE()
```

### 4.3 PAGOS Y LOGS

#### FLORERIA_Pedido_Pago
**Propósito:** Registro de pagos
```sql
pago_id               INT PK IDENTITY
pedido_id             INT FK → Pedido
prepedido_id          INT FK → PrePedido (nullable - pago general)
tipo_pago             VARCHAR(20) DEFAULT 'TOTAL'
metodo_pago           VARCHAR(30)          -- QR, TRANSFERENCIA, EFECTIVO
monto_bs              DECIMAL(10,2)
monto_usd             DECIMAL(10,2)
referencia            VARCHAR(100)         -- Número transacción
comprobante_url       VARCHAR(300)         -- URL imagen comprobante
estado                VARCHAR(20) DEFAULT 'PENDIENTE'
verificado_por        INT FK → Usuario
verificado_en         DATETIME
observaciones         VARCHAR(300)
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
```

**Constraints:**
```sql
CK_TipoPago: tipo_pago IN ('ANTICIPO', 'SALDO', 'TOTAL')
CK_Estado: estado IN ('PENDIENTE', 'VERIFICADO', 'RECHAZADO')
```

#### FLORERIA_Pedido_Estado_Log
**Propósito:** Historial de cambios de estado
```sql
log_id                BIGINT PK IDENTITY
pedido_id             INT FK → Pedido
estado_anterior       VARCHAR(30)
estado_nuevo          VARCHAR(30)
observaciones         VARCHAR(500)
usuario_id            INT FK → Usuario
fecha_hora            DATETIME DEFAULT GETDATE()
```

#### FLORERIA_Pedido_Reprogramacion
**Propósito:** Cambios de fecha/horario
```sql
reprog_id             INT PK IDENTITY
pedido_id             INT FK → Pedido
fecha_anterior        DATE
slot_anterior_id      SMALLINT FK → Slot_Horario
fecha_nueva           DATE
slot_nuevo_id         SMALLINT FK → Slot_Horario
motivo                VARCHAR(300)
solicitado_por        VARCHAR(20)          -- CLIENTE, AGENTE, SISTEMA
usuario_id            INT FK → Usuario (si fue agente)
fecha_hora            DATETIME DEFAULT GETDATE()
```

**Constraints:**
```sql
CK_SolicitadoPor: solicitado_por IN ('CLIENTE', 'AGENTE', 'SISTEMA')
```

#### FLORERIA_PrePedido_Agente_Log
**Propósito:** Cesiones entre agentes
```sql
log_id                INT PK IDENTITY
prepedido_id          INT FK → PrePedido
agente_anterior_id    INT FK → Usuario (nullable si es asignación inicial)
agente_nuevo_id       INT FK → Usuario
motivo                VARCHAR(300)
fecha_hora            DATETIME DEFAULT GETDATE()
```

---

## 📊 RESUMEN DE FOREIGN KEYS (67 RELACIONES)

```
USUARIO Y ACCESOS:
- Usuario → TipoUsuario
- Sesion → Usuario
- Menu → Menu (padre)
- TipoUsuario_Menu → TipoUsuario, Menu
- Usuario_Menu → Usuario, Menu

CONFIGURACIÓN:
- Config → Usuario (modificado_por)
- Auditoria → Usuario

PRODUCTOS:
- Categoria → Categoria (padre), Usuario (creado/modificado)
- Producto → Categoria, Usuario (creado/modificado)
- Producto_Variacion → Producto, Usuario (creado/modificado)
- Producto_Categoria → Producto, Categoria, Usuario
- Producto_Disponibilidad → Producto, Variacion, Sucursal, Aliado, Usuario

GEOGRAFÍA:
- Departamento → Pais
- Ciudad → Departamento
- Zona → Ciudad
- Zona_Tarifa → Zona, Usuario
- Zona_Express → Zona
- Sucursal → Ciudad
- Sucursal_Zona → Sucursal, Zona
- Slot_Horario → Ciudad

ALIADOS:
- Aliado → Ciudad, Usuario (creado/modificado/vinculado)
- Aliado_Zona → Aliado, Zona

PRE-PEDIDOS:
- PrePedido → Pais, Ciudad, Usuario (agente/creado/modificado)
- Pedido → PrePedido, Ciudad, Zona, Sucursal, Slot_Horario, Usuario
- Pedido_Detalle → Pedido, Producto, Variacion
- Pedido_Pago → Pedido, PrePedido, Usuario (creado/verificado)
- Pedido_Estado_Log → Pedido, Usuario
- Pedido_Reprogramacion → Pedido, Slot_Horario (anterior/nuevo), Usuario
- PrePedido_Agente_Log → PrePedido, Usuario (anterior/nuevo)
```

---

## 🔧 STORED PROCEDURES EXISTENTES (48 SPs)

### AUTENTICACIÓN Y SESIÓN (4 SPs)
```
FLORERIA_sp_Login                    -- Login con hash SHA256
FLORERIA_sp_ValidarSesion            -- Validar token sesión
FLORERIA_sp_CerrarSesion             -- Cerrar sesión
FLORERIA_sp_CambiarPassword          -- Cambiar password usuario logueado
```

### USUARIOS (7 SPs)
```
FLORERIA_sp_Usuario_Listar           -- Listar con filtros
FLORERIA_sp_Usuario_ObtenerPorId     -- Obtener uno
FLORERIA_sp_Usuario_Crear            -- Crear nuevo
FLORERIA_sp_Usuario_Actualizar       -- Actualizar datos
FLORERIA_sp_Usuario_CambiarPassword  -- Cambiar password (admin)
FLORERIA_sp_Usuario_ResetearPassword -- Resetear a default
FLORERIA_sp_Usuario_CambiarBloqueo   -- Bloquear/Desbloquear
```

### MENÚ (1 SP)
```
FLORERIA_sp_CargarMenu               -- Cargar menú por usuario_id
```

### CONFIGURACIÓN (3 SPs)
```
FLORERIA_sp_Config_ListarTodas       -- Listar todas las configs
FLORERIA_sp_Config_Obtener           -- Obtener valor por clave
FLORERIA_sp_Config_Guardar           -- UPSERT configuración
```

### CATEGORÍAS (15 SPs)
```
FLORERIA_sp_Categoria_Listar                  -- Listar árbol
FLORERIA_sp_Categoria_Crear                   -- Crear nueva
FLORERIA_sp_Categoria_Actualizar              -- Actualizar
FLORERIA_sp_Categoria_Eliminar                -- Eliminar (si vacía)
FLORERIA_sp_Categoria_CambiarOrden            -- Drag & drop
FLORERIA_sp_Categoria_BajaProductos           -- Dar baja masiva productos
FLORERIA_sp_Categoria_HabilitarProductos      -- Habilitar masiva productos
FLORERIA_sp_Categoria_GuardarWcId             -- Guardar ID WooCommerce
FLORERIA_sp_Categoria_MarcarSincronizada      -- Marcar sync OK
FLORERIA_sp_Categoria_ListarProductos         -- Productos de categoría
FLORERIA_sp_Categoria_ProductosDisponibles    -- No asignados aún
FLORERIA_sp_Categoria_AgregarProductos        -- Asignar múltiples
FLORERIA_sp_Categoria_QuitarProducto          -- Quitar uno
FLORERIA_sp_Categoria_QuitarProductosMasivo   -- Quitar múltiples
FLORERIA_sp_Categoria_MarcarPrincipal         -- Marcar categoría principal
FLORERIA_sp_Categoria_ObtenerStats            -- Estadísticas categoría
```

### PRODUCTOS (8 SPs)
```
FLORERIA_sp_Producto_Listar              -- Listar con paginación
FLORERIA_sp_Producto_ObtenerPorId        -- Obtener completo (con variaciones)
FLORERIA_sp_Producto_Crear               -- Crear nuevo
FLORERIA_sp_Producto_Actualizar          -- Actualizar
FLORERIA_sp_Producto_CambiarEstado       -- Activar/Desactivar
FLORERIA_sp_Producto_GuardarCategorias   -- Guardar muchos-a-muchos
FLORERIA_sp_Producto_GuardarVariaciones  -- Guardar variaciones (JSON)
```

### VARIACIONES (2 SPs)
```
FLORERIA_sp_Variacion_Guardar            -- Guardar una variación
FLORERIA_sp_Variacion_Eliminar           -- Eliminar variación
```

---

## 🆕 STORED PROCEDURES NUEVOS (8 SPs)

### PRE-PEDIDOS

#### 1. FLORERIA_sp_PrePedido_Crear
**Propósito:** Crear pre-pedido inicial
```sql
CREATE PROCEDURE FLORERIA_sp_PrePedido_Crear
    @tipo_registro       VARCHAR(20),     -- PRE_PEDIDO, VENTA_TIENDA, VENTA_ANTIGUA
    @cliente_celular     VARCHAR(20),
    @agente_id           INT,
    @ip                  VARCHAR(50),
    @prepedido_id        INT OUTPUT,
    @codigo              VARCHAR(20) OUTPUT
```

**Validaciones:**
- Unicidad: 1 cliente = 1 pre-pedido activo
- Genera código: PRE-000001 (auto-increment)
- Estado inicial según tipo

#### 2. FLORERIA_sp_PrePedido_ActualizarCliente
**Propósito:** Actualizar datos del cliente
```sql
CREATE PROCEDURE FLORERIA_sp_PrePedido_ActualizarCliente
    @prepedido_id        INT,
    @cliente_nombre      VARCHAR(200),
    @cliente_apellidos   VARCHAR(200),
    @cliente_email       VARCHAR(100),
    @cliente_pais_id     TINYINT,
    @cliente_ciudad_id   SMALLINT,
    @modificado_por      INT,
    @ip                  VARCHAR(50)
```

#### 3. FLORERIA_sp_PrePedido_GenerarLink
**Propósito:** Generar token único para formulario web
```sql
CREATE PROCEDURE FLORERIA_sp_PrePedido_GenerarLink
    @prepedido_id        INT,
    @moneda_formulario   CHAR(3),         -- BOB, USD
    @descuento_bs        DECIMAL(10,2),
    @descuento_motivo    VARCHAR(300),
    @modificado_por      INT,
    @ip                  VARCHAR(50),
    @token               VARCHAR(100) OUTPUT,
    @url_completa        VARCHAR(500) OUTPUT
```

**Acciones:**
- Genera token: GUID + GUID (100 chars)
- Calcula expiración: +48 horas
- Cambia estado: FORM_ENVIADO
- Retorna URL: `https://miss-flores.com/pedido?t=TOKEN&m=MONEDA`

#### 4. FLORERIA_sp_PrePedido_ObtenerPorToken
**Propósito:** Cargar pre-pedido para formulario web
```sql
CREATE PROCEDURE FLORERIA_sp_PrePedido_ObtenerPorToken
    @token               VARCHAR(100)
```

**Retorna (múltiples resultsets):**
1. Pre-pedido completo
2. Lista de pedidos
3. Productos por pedido
4. Zonas disponibles
5. Slots horarios

**Validaciones:**
- Token existe
- No expirado
- Estado permite edición

#### 5. FLORERIA_sp_PrePedido_Listar
**Propósito:** Listar pre-pedidos con filtros
```sql
CREATE PROCEDURE FLORERIA_sp_PrePedido_Listar
    @agente_id           INT = NULL,      -- NULL = todos
    @estado              VARCHAR(30) = NULL,
    @buscar              VARCHAR(100) = NULL,
    @pagina              INT = 1,
    @por_pagina          INT = 20,
    @total_registros     INT OUTPUT
```

### PEDIDOS

#### 6. FLORERIA_sp_Pedido_Crear
**Propósito:** Crear pedido dentro de pre-pedido
```sql
CREATE PROCEDURE FLORERIA_sp_Pedido_Crear
    @prepedido_id        INT,
    @receptor_nombre     VARCHAR(200),
    @receptor_celular    VARCHAR(20),
    @ciudad_id           SMALLINT,
    @zona_id             INT,
    @sucursal_id         SMALLINT,
    @tipo_entrega        VARCHAR(20),
    @direccion           VARCHAR(300),
    @referencia          VARCHAR(300),
    @fecha_entrega       DATE,
    @slot_id             SMALLINT,
    @es_express          BIT,
    @dedicatoria         NVARCHAR(500),
    @firma_tarjeta       VARCHAR(100),
    @creado_por          INT,
    @ip                  VARCHAR(50),
    @pedido_id           INT OUTPUT,
    @codigo              VARCHAR(20) OUTPUT
```

**Validaciones:**
- Genera código: PED-000001
- Valida tipo_entrega vs zona
- Valida fecha_entrega >= HOY + 2 horas
- Valida dedicatoria sin emojis

#### 7. FLORERIA_sp_Pedido_AgregarProducto
**Propósito:** Agregar productos al pedido
```sql
CREATE PROCEDURE FLORERIA_sp_Pedido_AgregarProducto
    @pedido_id           INT,
    @producto_id         INT,
    @variacion_id        INT,
    @es_personalizado    BIT,
    @nombre_producto     VARCHAR(200),
    @descripcion         NVARCHAR(500),
    @cantidad            INT,
    @precio_unitario_bs  DECIMAL(10,2),
    @precio_unitario_usd DECIMAL(10,2),
    @personalizacion     NVARCHAR(500)
```

**Acciones:**
- Inserta detalle
- Calcula subtotales (cantidad * precio)
- Actualiza total pedido
- Actualiza total pre-pedido

#### 8. FLORERIA_sp_Pedido_CalcularEnvio
**Propósito:** Calcular costo de envío
```sql
CREATE PROCEDURE FLORERIA_sp_Pedido_CalcularEnvio
    @pedido_id           INT,
    @tasa_cambio         DECIMAL(10,4)
```

**Lógica:**
```
1. Obtener tarifa base zona
2. Obtener recargo horario (si aplica 06:00-09:00)
3. Obtener recargo express (si es_express = 1)
4. TOTAL = base + recargo_horario + recargo_express
5. Actualizar campos en Pedido
6. Actualizar total_general en PrePedido
```

---

## 🎯 RESUMEN FINAL

### TOTALES
```
TABLAS EXISTENTES:    31
STORED PROCEDURES:    48 existentes + 8 nuevos = 56 TOTAL
FOREIGN KEYS:         67 relaciones
ÍNDICES:              51
VISTAS:               0
TRIGGERS:             0
```

### MÓDULOS DEL SISTEMA

#### ✅ COMPLETOS (CON SPs)
- Usuarios y Accesos
- Configuración
- Auditoría
- Categorías (CRUD completo)
- Productos (CRUD completo)
- Sesiones

#### 🔨 EN CONSTRUCCIÓN (FALTAN PÁGINAS ASPX)
- Pre-Pedidos (SPs listos, faltan pantallas)
- Pedidos (SPs listos, faltan pantallas)

#### 📋 POR DESARROLLAR
- Sucursales (CRUD)
- Zonas (CRUD)
- Aliados (CRUD)
- Inventario
- Reportes
- WooCommerce Sync

---

## 🚀 PRÓXIMOS PASOS

1. **Crear SPs faltantes** (8 nuevos de Pre-Pedidos)
2. **Crear páginas ASPX:**
   - PrePedidos.aspx (crear nuevo)
   - Lista.aspx (listar)
   - Detalle.aspx (ver/editar)
   - Formulario.aspx (cliente web)
3. **Integración WooCommerce:**
   - Módulo de sincronización
   - Webhooks
4. **Reportes:**
   - Dashboard agentes
   - Reportes financieros

---

**FIN DEL DOCUMENTO MAESTRO**
**Versión:** 2.0
**Fecha:** 2026-05-20
