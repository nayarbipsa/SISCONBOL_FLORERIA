# SISCONBOL_FLORERIA — Definiciones de Base de Datos
# Referencia obligatoria antes de generar cualquier código SQL o VB.NET

---

## BASE DE DATOS
- Nombre: `SISCONBOL`
- Motor: SQL Server 2019
- Servidor: `DESKTOP-PEMIFVB\SQL2019`
- Prefijo obligatorio en TODO: `FLORERIA_`

---

## CONVENCIONES

| Objeto | Prefijo | Ejemplo |
|---|---|---|
| Tabla | `FLORERIA_` | `FLORERIA_Usuario` |
| Vista | `FLORERIA_V_` | `FLORERIA_V_UsuarioActivo` |
| Stored Procedure | `FLORERIA_sp_` | `FLORERIA_sp_Login` |
| Función | `FLORERIA_fn_` | `FLORERIA_fn_GenerarCodigo` |

---

## MÓDULO 1 — SEGURIDAD Y USUARIOS

### FLORERIA_TipoUsuario
| Columna | Tipo | Nulo | Default | Descripción |
|---|---|---|---|---|
| tipo_id | SMALLINT IDENTITY | NO | — | PK |
| nombre | VARCHAR(50) | NO | — | Ej: Administrador, Cajero |
| descripcion | VARCHAR(200) | SÍ | — | |
| activo | BIT | NO | 1 | |
| creado_en | DATETIME | NO | GETDATE() | |

**Datos semilla:**
- 1 = Administrador
- 2 = Gerente
- 3 = Cajero
- 4 = Florista
- 5 = Delivery

---

### FLORERIA_Menu
| Columna | Tipo | Nulo | Default | Descripción |
|---|---|---|---|---|
| menu_id | SMALLINT IDENTITY | NO | — | PK |
| padre_id | SMALLINT | SÍ | NULL | FK a FLORERIA_Menu (árbol) |
| nombre | VARCHAR(80) | NO | — | Texto visible en menú |
| icono | VARCHAR(50) | SÍ | — | Clase Tabler: ti-home |
| ruta | VARCHAR(200) | SÍ | — | ~/Modulos/Pedidos/Lista.aspx |
| orden | TINYINT | NO | 0 | Orden de visualización |
| activo | BIT | NO | 1 | |

**Datos semilla (IDs fijos):**
- 1 = Inicio (padre_id NULL)
- 2 = Operacion (padre_id NULL)
- 3 = Catalogo (padre_id NULL)
- 4 = Finanzas (padre_id NULL)
- 5 = Configuracion (padre_id NULL)
- 6 = Reportes (padre_id NULL)
- 7 = Pedidos (padre_id 2)
- 8 = Pre-pedidos (padre_id 2)
- 9 = Mostrador (padre_id 2)
- 10 = Delivery (padre_id 2)
- 11 = Productos (padre_id 3)
- 12 = Categorias (padre_id 3)
- 13 = Inventario (padre_id 3)
- 14 = Caja diaria (padre_id 4)
- 15 = Gastos (padre_id 4) — OJO: en tabla es ID 15 no 16
- 16 = Usuarios (padre_id 5)
- 17 = Zonas (padre_id 5)
- 18 = Campanas (padre_id 5)

---

### FLORERIA_TipoUsuario_Menu
| Columna | Tipo | Nulo | Default | Descripción |
|---|---|---|---|---|
| tipomenu_id | INT IDENTITY | NO | — | PK |
| tipo_id | SMALLINT | NO | — | FK → FLORERIA_TipoUsuario |
| menu_id | SMALLINT | NO | — | FK → FLORERIA_Menu |
| puede_ver | BIT | NO | 1 | |
| puede_crear | BIT | NO | 0 | |
| puede_editar | BIT | NO | 0 | |
| puede_eliminar | BIT | NO | 0 | |

**UQ:** (tipo_id, menu_id)

---

### FLORERIA_Usuario
| Columna | Tipo | Nulo | Default | Descripción |
|---|---|---|---|---|
| usuario_id | INT IDENTITY | NO | — | PK |
| tipo_id | SMALLINT | NO | — | FK → FLORERIA_TipoUsuario |
| carnet | VARCHAR(8) | NO | — | UQ. Solo dígitos 7-8 chars. Es el username |
| nombres | VARCHAR(100) | NO | — | |
| apellidos | VARCHAR(100) | NO | — | |
| celular | VARCHAR(20) | SÍ | — | |
| email | VARCHAR(100) | SÍ | — | |
| direccion | VARCHAR(200) | SÍ | — | |
| fecha_nac | DATE | SÍ | — | |
| password_hash | VARCHAR(200) | NO | — | SHA256(pwd + salt) en UPPER HEX |
| password_salt | VARCHAR(50) | NO | — | Siempre 'FLORERIA2026' |
| debe_cambiar_pwd | BIT | NO | 1 | 1 = obliga cambio en próximo login |
| vigente_desde | DATE | NO | HOY | |
| vigente_hasta | DATE | SÍ | NULL | NULL = permanente |
| activo | BIT | NO | 1 | |
| bloqueado | BIT | NO | 0 | Bloqueo permanente por admin |
| intentos_fallidos | TINYINT | NO | 0 | Reset a 0 en login exitoso |
| bloqueado_hasta | DATETIME | SÍ | NULL | Bloqueo temporal 5 min |
| creado_por | INT | SÍ | — | FK → FLORERIA_Usuario |
| creado_en | DATETIME | NO | GETDATE() | |
| modificado_por | INT | SÍ | — | FK → FLORERIA_Usuario |
| modificado_en | DATETIME | SÍ | — | |

**Reglas de negocio:**
- Contraseña inicial = carnet hasheado con SHA256 + salt 'FLORERIA2026'
- 3 intentos fallidos → bloqueado_hasta = GETDATE() + 5 min
- 6+ intentos → bloqueado = 1 (permanente, requiere admin para desbloquear)
- Admins/Gerentes: vigente_hasta = NULL
- Delivery del día: vigente_hasta = HOY

**Hash SQL:**
```sql
UPPER(CONVERT(VARCHAR(200), HASHBYTES('SHA2_256', @carnet + 'FLORERIA2026'), 2))
```

**Hash VB.NET:**
```vb
Dim datos() As Byte = Encoding.UTF8.GetBytes(pwd & "FLORERIA2026")
Dim hash()  As Byte = SHA256.Create().ComputeHash(datos)
Return BitConverter.ToString(hash).Replace("-", "").ToUpper()
```

---

### FLORERIA_Usuario_Menu
| Columna | Tipo | Nulo | Default | Descripción |
|---|---|---|---|---|
| usumenu_id | INT IDENTITY | NO | — | PK |
| usuario_id | INT | NO | — | FK → FLORERIA_Usuario |
| menu_id | SMALLINT | NO | — | FK → FLORERIA_Menu |
| tipo_excepcion | VARCHAR(10) | NO | — | 'AGREGAR' o 'QUITAR' |
| puede_ver | BIT | NO | 1 | |
| puede_crear | BIT | NO | 0 | |
| puede_editar | BIT | NO | 0 | |
| puede_eliminar | BIT | NO | 0 | |
| motivo | VARCHAR(300) | NO | — | Obligatorio siempre |
| creado_por | INT | NO | — | FK → FLORERIA_Usuario |
| creado_en | DATETIME | NO | GETDATE() | |

**UQ:** (usuario_id, menu_id)

---

### FLORERIA_Sesion
| Columna | Tipo | Nulo | Default | Descripción |
|---|---|---|---|---|
| sesion_id | BIGINT IDENTITY | NO | — | PK |
| usuario_id | INT | NO | — | FK → FLORERIA_Usuario |
| token | VARCHAR(100) | NO | — | UQ. GUID doble generado en SP |
| ip | VARCHAR(50) | SÍ | — | |
| user_agent | VARCHAR(500) | SÍ | — | |
| es_celular | BIT | NO | 0 | |
| dispositivo | VARCHAR(100) | SÍ | — | Ej: Android - Chrome |
| sistema_op | VARCHAR(50) | SÍ | — | Android, iOS, Windows |
| navegador | VARCHAR(50) | SÍ | — | Chrome, Firefox, Edge |
| inicio | DATETIME | NO | GETDATE() | |
| ultimo_acceso | DATETIME | NO | GETDATE() | |
| expira_en | DATETIME | NO | — | 23:59:59 del día de inicio |
| activa | BIT | NO | 1 | |
| cerrada_por | VARCHAR(20) | SÍ | NULL | 'USUARIO', 'SISTEMA', 'NUEVA_SESION' |

**Reglas:**
- Solo 1 sesión activa por usuario
- Al nuevo login → las anteriores se cierran con cerrada_por = 'NUEVA_SESION'
- Expira a las 23:59:59 del mismo día
- SP ValidarSesion actualiza ultimo_acceso en cada request

---

### FLORERIA_Auditoria
| Columna | Tipo | Nulo | Default | Descripción |
|---|---|---|---|---|
| audit_id | BIGINT IDENTITY | NO | — | PK |
| usuario_id | INT | SÍ | — | Quién hizo el cambio |
| usuario_nombre | VARCHAR(200) | SÍ | — | Nombre guardado por si se elimina |
| ip | VARCHAR(50) | SÍ | — | |
| es_celular | BIT | SÍ | — | |
| dispositivo | VARCHAR(100) | SÍ | — | |
| tabla | VARCHAR(100) | NO | — | Tabla afectada |
| registro_id | VARCHAR(50) | NO | — | ID del registro afectado |
| accion | VARCHAR(10) | NO | — | 'INSERTAR', 'MODIFICAR', 'ELIMINAR' |
| valor_anterior | NVARCHAR(MAX) | SÍ | — | JSON del valor antes |
| valor_nuevo | NVARCHAR(MAX) | SÍ | — | JSON del valor después |
| motivo | VARCHAR(500) | SÍ | — | Obligatorio en acciones sensibles |
| fecha_hora | DATETIME | NO | GETDATE() | |

**Reglas:**
- NUNCA se borra — solo INSERT, nunca UPDATE ni DELETE
- Tablas críticas auditadas: Usuario, TipoUsuario_Menu, Usuario_Menu, Sesion, Pedidos, Pagos, Productos, Tarifas, Caja, Liquidaciones

---

## STORED PROCEDURES EXISTENTES

### Módulo Seguridad
| SP | Parámetros clave | Retorna |
|---|---|---|
| `FLORERIA_sp_Login` | @carnet, @password_hash, @ip, @user_agent, @es_celular, @dispositivo, @sistema_op, @navegador | resultado, mensaje, usuario_id, token, debe_cambiar_pwd, nombres, apellidos, tipo_id |
| `FLORERIA_sp_ValidarSesion` | @token, @ip | valida (1/0), mensaje, usuario_id |
| `FLORERIA_sp_CargarMenu` | @usuario_id | menu_id, padre_id, nombre, icono, ruta, orden, puede_ver, puede_crear, puede_editar, puede_eliminar |
| `FLORERIA_sp_CambiarPassword` | @usuario_id, @pwd_actual_hash, @pwd_nueva_hash, @ip | ok, mensaje |
| `FLORERIA_sp_CerrarSesion` | @token | (ninguno) |

### Módulo Usuarios
| SP | Parámetros clave | Retorna |
|---|---|---|
| `FLORERIA_sp_Usuario_Listar` | @buscar, @tipo_id, @estado | lista usuarios con estado_calculado |
| `FLORERIA_sp_Usuario_ObtenerPorId` | @usuario_id | datos completos del usuario |
| `FLORERIA_sp_Usuario_Crear` | @tipo_id, @carnet, @nombres, @apellidos, @email, @celular, @direccion, @fecha_nac, @vigente_hasta, @creado_por | ok, mensaje, usuario_id |
| `FLORERIA_sp_Usuario_Actualizar` | @usuario_id, @tipo_id, @nombres, @apellidos, @email, @celular, @direccion, @fecha_nac, @vigente_hasta, @modificado_por, @motivo | ok, mensaje |
| `FLORERIA_sp_Usuario_CambiarBloqueo` | @usuario_id, @bloquear, @modificado_por, @motivo | ok, mensaje |
| `FLORERIA_sp_Usuario_ResetearPassword` | @usuario_id, @modificado_por, @motivo | ok, mensaje |
| `FLORERIA_sp_Usuario_CambiarPassword` | @usuario_id, @pwd_actual_hash, @pwd_nueva_hash, @ip | ok, mensaje |

---

## MÓDULO 2 — GEOGRAFÍA

### FLORERIA_Pais
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| pais_id | TINYINT IDENTITY | NO | PK |
| codigo_iso | CHAR(2) | NO | UQ. 'BO', 'PE' |
| nombre | VARCHAR(80) | NO | |
| moneda_codigo | CHAR(3) | NO | Default 'BOB' |
| moneda_simbolo | VARCHAR(5) | NO | Default 'Bs' |
| activo | BIT | NO | Default 1 |

**Datos semilla:** 1=Bolivia(BOB/Bs), 2=Perú(PEN/S/)

---

### FLORERIA_Departamento
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| depto_id | SMALLINT IDENTITY | NO | PK |
| pais_id | TINYINT | NO | FK → FLORERIA_Pais |
| nombre | VARCHAR(100) | NO | |
| codigo | VARCHAR(10) | NO | 'LP', 'CB', 'LIM' |
| activo | BIT | NO | Default 1 |

---

### FLORERIA_Ciudad
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| ciudad_id | SMALLINT IDENTITY | NO | PK |
| depto_id | SMALLINT | NO | FK → FLORERIA_Departamento |
| nombre | VARCHAR(100) | NO | |
| codigo | VARCHAR(10) | NO | 'LPZ', 'ELA', 'CBB' |
| activo | BIT | NO | Default 1 |

**Datos semilla:** 1=La Paz(LPZ), 2=El Alto(ELA), 3=Cbba(CBB), 4=SCZ(SCZ), 5=Lima(LIM)

---

### FLORERIA_Sucursal
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| sucursal_id | SMALLINT IDENTITY | NO | PK |
| ciudad_id | SMALLINT | NO | FK → FLORERIA_Ciudad |
| codigo | VARCHAR(10) | NO | UQ. 'SOP', 'CAL' |
| nombre | VARCHAR(100) | NO | |
| direccion | VARCHAR(200) | SÍ | |
| telefono | VARCHAR(20) | SÍ | |
| email | VARCHAR(100) | SÍ | |
| latitud | DECIMAL(10,7) | SÍ | |
| longitud | DECIMAL(10,7) | SÍ | |
| hora_apertura | TIME | NO | Default '08:00' |
| hora_cierre | TIME | NO | Default '20:00' |
| dias_operacion | VARCHAR(20) | NO | Default 'L,M,X,J,V,S' |
| fondo_fijo_bs | DECIMAL(10,2) | NO | Default 200.00 |
| wc_zone_id | INT | SÍ | ID zona WC para recojo |
| wc_zone_code | VARCHAR(20) | SÍ | 'BO100', 'BO200' |
| activo | BIT | NO | Default 1 |

**Datos semilla:** 1=Sopocachi(SOP/BO100), 2=Calacoto(CAL/BO200)

---

### FLORERIA_Zona
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| zona_id | INT IDENTITY | NO | PK |
| ciudad_id | SMALLINT | NO | FK → FLORERIA_Ciudad |
| nombre | VARCHAR(150) | NO | Ej: 'Calacoto', 'Ciudad Satélite' |
| codigo | VARCHAR(20) | NO | UQ por ciudad. 'BO121' |
| tipo | VARCHAR(20) | NO | 'DELIVERY', 'RECOJO_SUCURSAL', 'SIN_COBERTURA' |
| latitud_ref | DECIMAL(10,7) | SÍ | |
| longitud_ref | DECIMAL(10,7) | SÍ | |
| wc_zone_id | INT | SÍ | |
| wc_zone_code | VARCHAR(20) | SÍ | |
| activo | BIT | NO | Default 1 |
| orden_display | SMALLINT | NO | Default 0 |

---

### FLORERIA_Sucursal_Zona
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| suc_zona_id | INT IDENTITY | NO | PK |
| sucursal_id | SMALLINT | NO | FK → FLORERIA_Sucursal |
| zona_id | INT | NO | FK → FLORERIA_Zona |
| prioridad | TINYINT | NO | 1=preferida, 2=backup |
| activo | BIT | NO | Default 1 |

**UQ:** (sucursal_id, zona_id)

---

### FLORERIA_Zona_Tarifa
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| tarifa_id | INT IDENTITY | NO | PK |
| zona_id | INT | NO | FK → FLORERIA_Zona |
| precio_bs | DECIMAL(10,2) | NO | Default 0 |
| precio_usd | DECIMAL(10,2) | SÍ | |
| vigente_desde | DATE | NO | Default HOY |
| vigente_hasta | DATE | SÍ | NULL = vigente indefinido |
| creado_por | INT | SÍ | FK → FLORERIA_Usuario |
| creado_en | DATETIME | NO | GETDATE() |
| motivo_cambio | VARCHAR(200) | SÍ | |

**Regla:** Para tarifa actual usar WHERE vigente_hasta IS NULL

---

### FLORERIA_Zona_Express
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| express_id | INT IDENTITY | NO | PK |
| zona_id | INT | NO | FK → FLORERIA_Zona |
| minutos_limite | SMALLINT | NO | 60, 120, 240 |
| etiqueta | VARCHAR(30) | NO | 'Menos de 1h', 'En 2 horas' |
| recargo_bs | DECIMAL(10,2) | NO | Default 0 |
| activo | BIT | NO | Default 1 |

**UQ:** (zona_id, minutos_limite)

---

### FLORERIA_Slot_Horario
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| slot_id | SMALLINT IDENTITY | NO | PK |
| ciudad_id | SMALLINT | NO | FK → FLORERIA_Ciudad |
| etiqueta | VARCHAR(60) | NO | '09:00 - 12:00' |
| hora_inicio | TIME | NO | |
| hora_fin | TIME | NO | |
| es_express | BIT | NO | Default 0 |
| activo | BIT | NO | Default 1 |
| orden_display | TINYINT | NO | Default 0 |
| wc_slot_value | VARCHAR(50) | SÍ | Valor en WC para mapeo |

**Datos semilla:** 13 slots migrados de WooCommerce (06:00-09:00 hasta 19:00-22:00)

---

## MÓDULO 3 — ALIADOS

### FLORERIA_Aliado
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| aliado_id | INT IDENTITY | NO | PK |
| ciudad_id | SMALLINT | NO | FK → FLORERIA_Ciudad |
| nombre_negocio | VARCHAR(150) | NO | |
| nombre_contacto | VARCHAR(100) | SÍ | |
| telefono | VARCHAR(20) | NO | |
| whatsapp | VARCHAR(20) | SÍ | |
| email | VARCHAR(100) | SÍ | |
| direccion | VARCHAR(200) | SÍ | |
| moneda | CHAR(3) | NO | Default 'BOB' |
| dias_pago | TINYINT | NO | Default 7 |
| notas_comercial | VARCHAR(500) | SÍ | |
| metodo_aviso | VARCHAR(20) | NO | 'WHATSAPP_MANUAL', 'WHATSAPP_AUTO', 'EMAIL_AUTO', 'SMS_AUTO' |
| usuario_id | INT | SÍ | FK → FLORERIA_Usuario (rol ALIADO) |
| activo | BIT | NO | Default 1 |

---

### FLORERIA_Aliado_Zona
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| aliado_zona_id | INT IDENTITY | NO | PK |
| aliado_id | INT | NO | FK → FLORERIA_Aliado |
| zona_id | INT | NO | FK → FLORERIA_Zona |
| prioridad | TINYINT | NO | Default 1 |
| activo | BIT | NO | Default 1 |

---

## MÓDULO 4 — PRODUCTOS

### FLORERIA_Producto
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| producto_id | INT IDENTITY | NO | PK |
| sku | VARCHAR(50) | NO | UQ |
| nombre | VARCHAR(200) | NO | |
| descripcion | NVARCHAR(MAX) | SÍ | |
| categoria_id | INT | SÍ | FK → FLORERIA_Categoria (futura) |
| precio_base_bs | DECIMAL(10,2) | NO | Default 0 |
| precio_base_usd | DECIMAL(10,2) | SÍ | |
| tiene_variaciones | BIT | NO | Default 0 |
| wc_product_id | INT | SÍ | ID en WooCommerce |
| wc_sync_estado | VARCHAR(20) | NO | 'SINCRONIZADO','PENDIENTE','ERROR','IGNORAR' |
| wc_sync_fecha | DATETIME | SÍ | |
| activo | BIT | NO | Default 1 |
| creado_en | DATETIME | NO | GETDATE() |

---

### FLORERIA_Producto_Variacion
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| variacion_id | INT IDENTITY | NO | PK |
| producto_id | INT | NO | FK → FLORERIA_Producto |
| sku_variacion | VARCHAR(60) | NO | UQ. Ej: 'RP24R-ROJO-G' |
| atrib_1_nombre | VARCHAR(40) | SÍ | Ej: 'Color' |
| atrib_1_valor | VARCHAR(80) | SÍ | Ej: 'Rojo' |
| atrib_2_nombre | VARCHAR(40) | SÍ | Ej: 'Tamaño' |
| atrib_2_valor | VARCHAR(80) | SÍ | Ej: 'Grande' |
| atrib_3_nombre | VARCHAR(40) | SÍ | |
| atrib_3_valor | VARCHAR(80) | SÍ | |
| precio_bs | DECIMAL(10,2) | SÍ | Sobreescribe precio base |
| precio_usd | DECIMAL(10,2) | SÍ | |
| wc_variation_id | INT | SÍ | |
| activo | BIT | NO | Default 1 |

---

### FLORERIA_Producto_Disponibilidad
| Columna | Tipo | Nulo | Descripción |
|---|---|---|---|
| disp_id | INT IDENTITY | NO | PK |
| producto_id | INT | NO | FK → FLORERIA_Producto |
| variacion_id | INT | SÍ | FK → FLORERIA_Producto_Variacion |
| sucursal_id | SMALLINT | SÍ | FK → FLORERIA_Sucursal (uno de los dos) |
| aliado_id | INT | SÍ | FK → FLORERIA_Aliado (uno de los dos) |
| disponible | BIT | NO | Default 1 |
| stock_actual | INT | NO | Default 0 (solo sucursales propias) |
| stock_minimo | INT | NO | Default 5 |
| stock_reservado | INT | NO | Default 0 (pedidos pending) |
| precio_bs | DECIMAL(10,2) | SÍ | NULL = usar precio base |
| precio_usd | DECIMAL(10,2) | SÍ | |
| costo_aliado_bs | DECIMAL(10,2) | SÍ | Solo cuando aliado_id IS NOT NULL |
| actualizado_en | DATETIME | NO | GETDATE() |

**CHECK:** Solo uno de sucursal_id o aliado_id puede tener valor

---

## MÓDULO 5 — PLANTILLAS DE MENSAJES

### FLORERIA_Plantilla_Mensaje (pendiente crear)
| Columna | Tipo | Descripción |
|---|---|---|
| plantilla_id | SMALLINT IDENTITY | PK |
| codigo | VARCHAR(50) | UQ. 'CONFIRMACION', 'ENTREGADO', etc. |
| titulo | VARCHAR(100) | Nombre descriptivo |
| contenido | NVARCHAR(1000) | Texto con variables {nombre}, {codigo}, etc. |
| activo | BIT | Default 1 |

**Plantillas definidas:**
- CONFIRMACION_PEDIDO
- SALIDA_DELIVERY
- ENTREGA_EXITOSA
- DEJADO_CON_VECINO
- NO_SE_PUDO_ENTREGAR
- REPROGRAMACION

---

## MÓDULO 6 — DELIVERY Y RUTAS (pendiente SQL)

### Tablas pendientes de crear:
- `FLORERIA_Ruta` — nombre del grupo de zonas (Ruta Sur, Ruta Norte)
- `FLORERIA_Ruta_Zona` — qué zonas pertenecen a qué ruta
- `FLORERIA_Transporte` — a pie, moto, movilidad
- `FLORERIA_Delivery_Transporte` — qué transporte usa el delivery en determinado día
- `FLORERIA_Asignacion` — qué delivery lleva qué pedido en qué fecha
- `FLORERIA_Entrega` — registro de entrega completo con foto, GPS, quién recibió
- `FLORERIA_Entrega_GPS` — historial de ubicaciones

---

## MÓDULO 7 — PEDIDOS (pendiente SQL)

### Tablas pendientes de crear:
- `FLORERIA_Pedido` — pedido principal con 3 estados separados
- `FLORERIA_Pedido_Detalle` — productos del pedido
- `FLORERIA_Pedido_Pago` — pagos y comprobantes
- `FLORERIA_Pedido_Estado_Log` — historial de cambios de estado
- `FLORERIA_Pedido_Reprogramacion` — historial de reprogramaciones
- `FLORERIA_PrePedido` — formularios web pendientes

---

## MÓDULO 8 — SINCRONIZACIÓN WOOCOMMERCE (pendiente SQL)

### Tablas pendientes de crear:
- `FLORERIA_WC_Cola` — pedidos WC pendientes de procesar
- `FLORERIA_WC_Cola_Vigilancia` — pedidos "pending" para verificar

---

## CAMPOS ESTÁNDAR EN TODAS LAS TABLAS

Toda tabla debe tener al menos:
```sql
activo      BIT      NOT NULL DEFAULT 1
creado_en   DATETIME NOT NULL DEFAULT GETDATE()
```

Tablas que permiten modificación deben tener además:
```sql
creado_por     INT NULL  -- FK a FLORERIA_Usuario
modificado_por INT NULL  -- FK a FLORERIA_Usuario
modificado_en  DATETIME NULL
```

---

## PÁGINAS ASPX EXISTENTES

| Archivo | Clase VB | Ubicación |
|---|---|---|
| Login.aspx | Login | Raíz |
| Default.aspx | Default_aspx | Raíz |
| CambiarPassword.aspx | CambiarPassword | Raíz |
| Usuarios.aspx | Modulos_Config_Usuarios | Modulos/Config/ |

---

## SESIÓN — VARIABLES DISPONIBLES

Después del login exitoso, Session contiene:
- `Session("usuario_id")` → Integer
- `Session("token")` → String
- `Session("nombres")` → String
- `Session("apellidos")` → String
- `Session("tipo_id")` → Integer
- `Session("tipo_nombre")` → String (se carga en Default.aspx)

---

## PATRÓN VERIFICAR SESIÓN (obligatorio en cada página)

```vb
Private Function VerificarSesion() As Boolean
    If Session("token") Is Nothing Then Return False
    Dim token As String = Session("token").ToString()
    Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
    If ip Is Nothing Then ip = ""
    Try
        Using conn As New SqlConnection(ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_sp_ValidarSesion", conn)
                cmd.CommandType = Data.CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@token", token)
                cmd.Parameters.AddWithValue("@ip",    ip)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then Return CBool(dr("valida"))
                End Using
            End Using
        End Using
    Catch ex As Exception
        System.Diagnostics.Debug.WriteLine("ERROR Sesion: " & ex.Message)
    End Try
    Return False
End Function

Private Function ObtenerCadena() As String
    Return System.Configuration.ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString
End Function
```


---

## ACTUALIZACIONES — columnas agregadas en desarrollo

### FLORERIA_Producto (columnas adicionales)
| Columna | Tipo | Descripción |
|---|---|---|
| precio_promo_bs | DECIMAL(10,2) | Precio promocional en Bs — debe ser menor al base |
| precio_promo_usd | DECIMAL(10,2) | Precio promocional en USD |
| promo_desde | DATE | Inicio del período de promoción |
| promo_hasta | DATE | Fin del período de promoción |
| destacado | BIT | 1 = aparece como destacado en WC |
| menu_order | INT | Orden de aparición en WooCommerce |
| notas_internas | NVARCHAR(500) | Solo visible en el sistema, no sync con WC |
| stock_actual | INT | Stock actual en sucursal principal |
| stock_minimo | INT | Nivel mínimo para alerta |
| modificado_por | INT | FK → FLORERIA_Usuario |
| modificado_en | DATETIME | Fecha última modificación |

### FLORERIA_Producto_Variacion (columnas adicionales)
| Columna | Tipo | Descripción |
|---|---|---|
| precio_promo_bs | DECIMAL(10,2) | Precio promo de esta variación |
| precio_promo_usd | DECIMAL(10,2) | |
| promo_desde | DATE | Inicio promo de esta variación |
| promo_hasta | DATE | Fin promo de esta variación |
| wc_sync_fecha | DATETIME | Última sync con WC |
| modificado_por | INT | FK → FLORERIA_Usuario |
| modificado_en | DATETIME | |

### FLORERIA_Config (tabla nueva)
| Columna | Tipo | Descripción |
|---|---|---|
| config_id | INT IDENTITY | PK |
| clave | VARCHAR(100) | UQ. Ej: WC_URL, WC_CONSUMER_KEY |
| valor | NVARCHAR(500) | Valor de la configuración |
| descripcion | VARCHAR(300) | Descripción del campo |
| es_secreto | BIT | 1 = se muestra como *** en logs |
| activo | BIT | Default 1 |
| modificado_por | INT | FK → FLORERIA_Usuario |
| modificado_en | DATETIME | |

**Claves registradas:**
- `WC_URL` — URL base de WooCommerce sin barra final
- `WC_CONSUMER_KEY` — ck_xxx
- `WC_CONSUMER_SECRET` — cs_xxx
- `WC_WEBHOOK_SECRET` — clave del bridge PHP
- `WC_API_VERSION` — v3
- `SYNC_ACTIVO` — 1 o 0

### Páginas adicionales
| Archivo | Clase VB | Ubicación |
|---|---|---|
| Configuracion.aspx | Modulos_Config_Configuracion | Modulos/Config/ |
| Categorias.aspx | Modulos_Catalogo_Categorias | Modulos/Catalogo/ |
| Productos.aspx | Modulos_Catalogo_Productos | Modulos/Catalogo/ |

### SPs adicionales de Categorias
| SP | Descripción |
|---|---|
| `FLORERIA_sp_Categoria_Listar` | Lista árbol completo con total_productos |
| `FLORERIA_sp_Categoria_Crear` | Crea categoría, retorna ok+categoria_id |
| `FLORERIA_sp_Categoria_Actualizar` | Actualiza nombre/desc/padre/slug |
| `FLORERIA_sp_Categoria_CambiarOrden` | Drag & drop — cambia padre y orden |
| `FLORERIA_sp_Categoria_BajaProductos` | Desactiva todos los productos de la categoría |
| `FLORERIA_sp_Categoria_HabilitarProductos` | Activa todos los productos inactivos |
| `FLORERIA_sp_Categoria_Eliminar` | Solo si no tiene hijos ni productos |
| `FLORERIA_sp_Categoria_GuardarWcId` | Guarda wc_category_id tras crear en WC |
| `FLORERIA_sp_Categoria_MarcarSincronizada` | Marca wc_sync_estado = SINCRONIZADO |

### SPs de Productos
| SP | Descripción |
|---|---|
| `FLORERIA_sp_Producto_Listar` | Lista completa con filtros, promo_activa_hoy calculada |
| `FLORERIA_sp_Producto_ObtenerPorId` | Retorna 3 resultsets: producto + variaciones + categorías |
| `FLORERIA_sp_Producto_Crear` | Valida SKU único y promo < base |
| `FLORERIA_sp_Producto_Actualizar` | Actualiza y marca PENDIENTE sync |
| `FLORERIA_sp_Producto_CambiarEstado` | Activa/desactiva con motivo obligatorio |
| `FLORERIA_sp_Producto_GuardarCategorias` | Muchos a muchos — borra y reinserta |
| `FLORERIA_sp_Variacion_Guardar` | Crea (id=0) o actualiza variación individual |
| `FLORERIA_sp_Variacion_Eliminar` | Soft delete + marca PENDIENTE |
