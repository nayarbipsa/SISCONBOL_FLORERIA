# =============================================
# SISCONBOL - SISTEMA INTEGRAL FLORERÍA
# ESTRUCTURA COMPLETA DE BASE DE DATOS
# =============================================

## 📊 RESUMEN GENERAL

```
TABLAS TOTALES:        31
STORED PROCEDURES:     56 TOTAL (48 existentes + 8 nuevos)
FOREIGN KEYS:          67 relaciones
ÍNDICES:               51
VISTAS:                0
```

## ⚠️ ADVERTENCIA CRÍTICA

**LA ESTRUCTURA EN SOMEE DIFIERE DE GITHUB**

Para conocer las diferencias exactas de columnas entre GitHub y Somee, consultar:
**[ESTRUCTURA_BD_REAL_SOMEE.md](ESTRUCTURA_BD_REAL_SOMEE.md)**

Este archivo documenta la estructura **TEÓRICA** basada en los scripts de GitHub.
Siempre verificar con ESTRUCTURA_BD_REAL_SOMEE.md antes de usar columnas en SQL.

---

## 🗄️ SECCIÓN 1: TABLAS EXISTENTES (31 TABLAS)

### 1.1 GESTIÓN DE USUARIOS Y ACCESOS (6 TABLAS)

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

**Constraint:** CK_Carnet: carnet solo dígitos, 7-8 caracteres

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

**Constraint:** UQ_TipoMenu: UNIQUE(tipo_id, menu_id)

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
- UQ_UsuMenu: UNIQUE(usuario_id, menu_id)
- CK_Excepcion: tipo_excepcion IN ('AGREGAR', 'QUITAR')

---

### 1.2 CONFIGURACIÓN Y AUDITORÍA (2 TABLAS)

#### FLORERIA_Config
**Propósito:** Configuraciones del sistema (key-value)
```sql
config_id             INT PK IDENTITY
clave                 VARCHAR(100) UNIQUE
valor                 NVARCHAR(500)
descripcion           VARCHAR(300)
es_secreto            BIT DEFAULT 0
activo                BIT DEFAULT 1
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

**Configuraciones típicas:**
- TASA_CAMBIO_USD = 7.00
- WC_API_URL = https://miss-flores.com/wp-json/wc/v3
- TIMEOUT_SESION = 480 (minutos)

#### FLORERIA_Auditoria
**Propósito:** Log de cambios críticos
```sql
audit_id              BIGINT PK IDENTITY
usuario_id            INT FK → Usuario
usuario_nombre        VARCHAR(200)
ip                    VARCHAR(50)
es_celular            BIT
dispositivo           VARCHAR(100)
tabla                 VARCHAR(100)
registro_id           VARCHAR(50)
accion                VARCHAR(10)          -- INSERTAR, MODIFICAR, ELIMINAR
valor_anterior        NVARCHAR(MAX)        -- JSON
valor_nuevo           NVARCHAR(MAX)        -- JSON
motivo                VARCHAR(500)
fecha_hora            DATETIME DEFAULT GETDATE()
```

---

### 1.3 CATÁLOGO DE PRODUCTOS (5 TABLAS)

#### FLORERIA_Categoria
```sql
categoria_id          INT PK IDENTITY
padre_id              INT FK → Categoria (nullable)
nombre                VARCHAR(150)
descripcion           VARCHAR(500)
slug                  VARCHAR(160) UNIQUE
orden                 INT DEFAULT 0
activo                BIT DEFAULT 1
wc_category_id        INT
wc_sync_estado        VARCHAR(20) DEFAULT 'PENDIENTE'
wc_sync_fecha         DATETIME
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

#### FLORERIA_Producto
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
wc_product_id         INT
wc_sync_estado        VARCHAR(20) DEFAULT 'PENDIENTE'
wc_sync_fecha         DATETIME
activo                BIT DEFAULT 1
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

#### FLORERIA_Producto_Variacion
```sql
variacion_id          INT PK IDENTITY
producto_id           INT FK → Producto
sku_variacion         VARCHAR(60) UNIQUE
atrib_1_nombre        VARCHAR(40)
atrib_1_valor         VARCHAR(80)
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
```sql
prodcat_id            INT PK IDENTITY
producto_id           INT FK → Producto
categoria_id          INT FK → Categoria
es_principal          BIT DEFAULT 0
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
```

**Constraint:** UQ_ProdCat: UNIQUE(producto_id, categoria_id)

#### FLORERIA_Producto_Disponibilidad
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

**Constraints:**
- CK_Operador: (sucursal_id IS NOT NULL AND aliado_id IS NULL) OR (sucursal_id IS NULL AND aliado_id IS NOT NULL)
- UQ_PD_Suc: UNIQUE(producto_id, variacion_id, sucursal_id)
- UQ_PD_Ali: UNIQUE(producto_id, variacion_id, aliado_id)

---

### 1.4 GEOGRAFÍA (9 TABLAS)

#### FLORERIA_Pais
```sql
pais_id               TINYINT PK IDENTITY
codigo_iso            CHAR(2) UNIQUE       -- BO, PE
nombre                VARCHAR(80)
moneda_codigo         CHAR(3) DEFAULT 'BOB'
moneda_simbolo        VARCHAR(5) DEFAULT 'Bs'
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

#### FLORERIA_Departamento
```sql
depto_id              SMALLINT PK IDENTITY
pais_id               TINYINT FK → Pais
nombre                VARCHAR(100)
codigo                VARCHAR(10)          -- LP, CB, SC
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

#### FLORERIA_Ciudad
```sql
ciudad_id             SMALLINT PK IDENTITY
depto_id              SMALLINT FK → Departamento
nombre                VARCHAR(100)
codigo                VARCHAR(10)          -- LPZ, CBB, SCZ
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

#### FLORERIA_Zona
```sql
zona_id               INT PK IDENTITY
ciudad_id             SMALLINT FK → Ciudad
nombre                VARCHAR(150)
codigo                VARCHAR(20)          -- BO100, BO101...
tipo                  VARCHAR(20) DEFAULT 'DELIVERY'
latitud_ref           DECIMAL(10,7)
longitud_ref          DECIMAL(10,7)
wc_zone_id            INT
wc_zone_code          VARCHAR(20)
activo                BIT DEFAULT 1
orden_display         SMALLINT DEFAULT 0
creado_en             DATETIME DEFAULT GETDATE()
```

**Constraint:** CK_Tipo: tipo IN ('DELIVERY', 'RECOJO_SUCURSAL', 'SIN_COBERTURA')

#### FLORERIA_Zona_Tarifa
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

#### FLORERIA_Zona_Express
```sql
express_id            INT PK IDENTITY
zona_id               INT FK → Zona
minutos_limite        SMALLINT             -- 30, 60, 90
etiqueta              VARCHAR(30)
recargo_bs            DECIMAL(10,2) DEFAULT 0
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

**Constraint:** UQ_Zona_Express: UNIQUE(zona_id, minutos_limite)

#### FLORERIA_Sucursal
```sql
sucursal_id           SMALLINT PK IDENTITY
ciudad_id             SMALLINT FK → Ciudad
codigo                VARCHAR(10) UNIQUE
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

#### FLORERIA_Sucursal_Zona
```sql
suc_zona_id           INT PK IDENTITY
sucursal_id           SMALLINT FK → Sucursal
zona_id               INT FK → Zona
prioridad             TINYINT DEFAULT 1
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

**Constraint:** UQ_Sucursal_Zona: UNIQUE(sucursal_id, zona_id)

#### FLORERIA_Slot_Horario
```sql
slot_id               SMALLINT PK IDENTITY
ciudad_id             SMALLINT FK → Ciudad
etiqueta              VARCHAR(60)
hora_inicio           TIME
hora_fin              TIME
duracion_minutos      SMALLINT DEFAULT 180
recargo_bs            DECIMAL(10,2) DEFAULT 0
es_express            BIT DEFAULT 0
activo                BIT DEFAULT 1
orden_display         TINYINT DEFAULT 0
wc_slot_value         VARCHAR(50)
creado_en             DATETIME DEFAULT GETDATE()
```

**⚠️ NOTA:** En GitHub existe columna `orden` (tinyint), pero Somee usa `orden_display`.

---

### 1.5 ALIADOS (2 TABLAS)

#### FLORERIA_Aliado
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
dias_pago             TINYINT DEFAULT 7
notas_comercial       VARCHAR(500)
metodo_aviso          VARCHAR(20) DEFAULT 'WHATSAPP_MANUAL'
usuario_id            INT FK → Usuario (nullable)
activo                BIT DEFAULT 1
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

#### FLORERIA_Aliado_Zona
```sql
aliado_zona_id        INT PK IDENTITY
aliado_id             INT FK → Aliado
zona_id               INT FK → Zona
prioridad             TINYINT DEFAULT 1
activo                BIT DEFAULT 1
creado_en             DATETIME DEFAULT GETDATE()
```

**Constraint:** UQ_Aliado_Zona: UNIQUE(aliado_id, zona_id)

---

### 1.6 PRE-PEDIDOS Y PEDIDOS (7 TABLAS)

#### FLORERIA_PrePedido
```sql
prepedido_id          INT PK IDENTITY
codigo                VARCHAR(20) UNIQUE   -- PRE-000001
token_web             VARCHAR(100) UNIQUE
tipo_registro         VARCHAR(20) DEFAULT 'PRE_PEDIDO'
cliente_celular       VARCHAR(20)
cliente_nombre        VARCHAR(200)
cliente_apellidos     VARCHAR(200)
cliente_email         VARCHAR(100)
cliente_pais_id       TINYINT FK → Pais
cliente_ciudad_id     SMALLINT FK → Ciudad
estado                VARCHAR(30) DEFAULT 'BORRADOR'
fecha_limite_pago     DATETIME
token_expira          DATETIME
total_general_bs      DECIMAL(10,2) DEFAULT 0
total_general_usd     DECIMAL(10,2) DEFAULT 0
tasa_cambio           DECIMAL(10,4) DEFAULT 7.0000
moneda_formulario     CHAR(3) DEFAULT 'BOB'
descuento_bs          DECIMAL(10,2) DEFAULT 0
descuento_usd         DECIMAL(10,2) DEFAULT 0
descuento_motivo      VARCHAR(300)
agente_actual_id      INT FK → Usuario
observaciones         NVARCHAR(500)
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

**Constraints:**
- CK_TipoRegistro: tipo_registro IN ('PRE_PEDIDO', 'VENTA_TIENDA', 'VENTA_ANTIGUA')
- CK_Estado: estado IN ('BORRADOR', 'FORM_ENVIADO', 'FORM_COMPLETADO', 'COMPROBANTE_ENVIADO', 'PAGADO', 'WC_CREADO', 'COMPLETADO', 'EXPIRADO', 'CANCELADO', 'RECHAZADO', 'ERROR_WC')

#### FLORERIA_Pedido
```sql
pedido_id             INT PK IDENTITY
prepedido_id          INT FK → PrePedido (nullable)
codigo                VARCHAR(20) UNIQUE   -- PED-000001
receptor_nombre       VARCHAR(200)
receptor_celular      VARCHAR(20)
ciudad_id             SMALLINT FK → Ciudad
zona_id               INT FK → Zona (nullable)
sucursal_id           SMALLINT FK → Sucursal (nullable)
tipo_entrega          VARCHAR(20) DEFAULT 'DOMICILIO'
direccion             VARCHAR(300)
latitud               DECIMAL(10,7)
longitud              DECIMAL(10,7)
referencia            VARCHAR(300)
fecha_entrega         DATE
slot_id               SMALLINT FK → Slot_Horario
es_express            BIT DEFAULT 0
dedicatoria           NVARCHAR(500)
firma_tarjeta         VARCHAR(100)
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
anticipo_bs           DECIMAL(10,2) DEFAULT 0
saldo_bs              DECIMAL(10,2) DEFAULT 0
estado_pago           VARCHAR(20) DEFAULT 'PENDIENTE'
wc_order_id           INT
wc_order_number       VARCHAR(30)
wc_order_url          VARCHAR(300)
wc_sync_estado        VARCHAR(20) DEFAULT 'PENDIENTE'
wc_sync_fecha         DATETIME
observaciones         NVARCHAR(500)
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
modificado_por        INT FK → Usuario
modificado_en         DATETIME
```

**Constraints:**
- CK_TipoEntrega: tipo_entrega IN ('DOMICILIO', 'RECOJO_SUCURSAL')
- CK_EstadoPago: estado_pago IN ('PENDIENTE', 'ANTICIPO', 'PAGADO', 'REEMBOLSADO')
- CK_WcSync: wc_sync_estado IN ('PENDIENTE', 'SINCRONIZADO', 'ERROR', 'IGNORAR')

#### FLORERIA_Pedido_Detalle
```sql
detalle_id            INT PK IDENTITY
pedido_id             INT FK → Pedido
producto_id           INT FK → Producto (nullable)
variacion_id          INT FK → Producto_Variacion (nullable)
es_personalizado      BIT DEFAULT 0
nombre_producto       VARCHAR(200)
descripcion           NVARCHAR(500)
cantidad              INT DEFAULT 1
precio_unitario_bs    DECIMAL(10,2)
precio_unitario_usd   DECIMAL(10,2)
subtotal_bs           DECIMAL(10,2)
subtotal_usd          DECIMAL(10,2)
personalizacion       NVARCHAR(500)
wc_line_item_id       BIGINT
creado_en             DATETIME DEFAULT GETDATE()
```

#### FLORERIA_Pedido_Pago
```sql
pago_id               INT PK IDENTITY
pedido_id             INT FK → Pedido
prepedido_id          INT FK → PrePedido (nullable)
tipo_pago             VARCHAR(20) DEFAULT 'TOTAL'
metodo_pago           VARCHAR(30)
monto_bs              DECIMAL(10,2)
monto_usd             DECIMAL(10,2)
referencia            VARCHAR(100)
comprobante_url       VARCHAR(300)
estado                VARCHAR(20) DEFAULT 'PENDIENTE'
verificado_por        INT FK → Usuario
verificado_en         DATETIME
observaciones         VARCHAR(300)
creado_por            INT FK → Usuario
creado_en             DATETIME DEFAULT GETDATE()
```

**Constraints:**
- CK_TipoPago: tipo_pago IN ('ANTICIPO', 'SALDO', 'TOTAL')
- CK_Estado: estado IN ('PENDIENTE', 'VERIFICADO', 'RECHAZADO')

#### FLORERIA_Pedido_Estado_Log
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
```sql
reprog_id             INT PK IDENTITY
pedido_id             INT FK → Pedido
fecha_anterior        DATE
slot_anterior_id      SMALLINT FK → Slot_Horario
fecha_nueva           DATE
slot_nuevo_id         SMALLINT FK → Slot_Horario
motivo                VARCHAR(300)
solicitado_por        VARCHAR(20)          -- CLIENTE, AGENTE, SISTEMA
usuario_id            INT FK → Usuario (nullable)
fecha_hora            DATETIME DEFAULT GETDATE()
```

**Constraint:** CK_SolicitadoPor: solicitado_por IN ('CLIENTE', 'AGENTE', 'SISTEMA')

#### FLORERIA_PrePedido_Agente_Log
```sql
log_id                INT PK IDENTITY
prepedido_id          INT FK → PrePedido
agente_anterior_id    INT FK → Usuario (nullable)
agente_nuevo_id       INT FK → Usuario
motivo                VARCHAR(300)
fecha_hora            DATETIME DEFAULT GETDATE()
```

---

## 🔧 STORED PROCEDURES (56 TOTAL)

### AUTENTICACIÓN Y SESIÓN (4 SPs)
```
FLORERIA_sp_Login
FLORERIA_sp_ValidarSesion
FLORERIA_sp_CerrarSesion
FLORERIA_sp_CambiarPassword
```

### USUARIOS (7 SPs)
```
FLORERIA_sp_Usuario_Listar
FLORERIA_sp_Usuario_ObtenerPorId
FLORERIA_sp_Usuario_Crear
FLORERIA_sp_Usuario_Actualizar
FLORERIA_sp_Usuario_CambiarPassword
FLORERIA_sp_Usuario_ResetearPassword
FLORERIA_sp_Usuario_CambiarBloqueo
```

### MENÚ (1 SP)
```
FLORERIA_sp_CargarMenu
```

### CONFIGURACIÓN (3 SPs)
```
FLORERIA_sp_Config_ListarTodas
FLORERIA_sp_Config_Obtener
FLORERIA_sp_Config_Guardar
```

### CATEGORÍAS (16 SPs)
```
FLORERIA_sp_Categoria_Listar
FLORERIA_sp_Categoria_Crear
FLORERIA_sp_Categoria_Actualizar
FLORERIA_sp_Categoria_Eliminar
FLORERIA_sp_Categoria_CambiarOrden
FLORERIA_sp_Categoria_BajaProductos
FLORERIA_sp_Categoria_HabilitarProductos
FLORERIA_sp_Categoria_GuardarWcId
FLORERIA_sp_Categoria_MarcarSincronizada
FLORERIA_sp_Categoria_ListarProductos
FLORERIA_sp_Categoria_ProductosDisponibles
FLORERIA_sp_Categoria_AgregarProductos
FLORERIA_sp_Categoria_QuitarProducto
FLORERIA_sp_Categoria_QuitarProductosMasivo
FLORERIA_sp_Categoria_MarcarPrincipal
FLORERIA_sp_Categoria_ObtenerStats
```

### PRODUCTOS (7 SPs)
```
FLORERIA_sp_Producto_Listar
FLORERIA_sp_Producto_ObtenerPorId
FLORERIA_sp_Producto_Crear
FLORERIA_sp_Producto_Actualizar
FLORERIA_sp_Producto_CambiarEstado
FLORERIA_sp_Producto_GuardarCategorias
FLORERIA_sp_Producto_GuardarVariaciones
```

### VARIACIONES (2 SPs)
```
FLORERIA_sp_Variacion_Guardar
FLORERIA_sp_Variacion_Eliminar
```

### PRE-PEDIDOS (5 SPs)
```
FLORERIA_sp_PrePedido_Crear
FLORERIA_sp_PrePedido_ActualizarCliente
FLORERIA_sp_PrePedido_GenerarLink
FLORERIA_sp_PrePedido_ObtenerPorToken
FLORERIA_sp_PrePedido_Listar
```

### PEDIDOS (3 SPs)
```
FLORERIA_sp_Pedido_Crear
FLORERIA_sp_Pedido_AgregarProducto
FLORERIA_sp_Pedido_CalcularEnvio
```

### GEOGRAFÍA (8 SPs - PENDIENTES)
```
FLORERIA_sp_Ciudad_Listar
FLORERIA_sp_Zona_Listar
FLORERIA_sp_Zona_ObtenerTarifa
FLORERIA_sp_Sucursal_Listar
FLORERIA_sp_Sucursal_Crear
FLORERIA_sp_Sucursal_Actualizar
FLORERIA_sp_Slot_ListarPorCiudad
FLORERIA_sp_Slot_ValidarDisponibilidad
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

**Última actualización:** 2026-05-24  
**Fuente:** Scripts GitHub + Verificación Somee  
**Ver diferencias:** [ESTRUCTURA_BD_REAL_SOMEE.md](ESTRUCTURA_BD_REAL_SOMEE.md)
