# ESTRUCTURA REAL DE LA BASE DE DATOS EN SOMEE

**Servidor:** SISCONBOL.mssql.somee.com  
**Base de datos:** SISCONBOL  
**Fecha actualización:** 2025-05-24

---

## ⚠️ ADVERTENCIA CRÍTICA

**LA ESTRUCTURA EN SOMEE ES DIFERENTE A LA DE GITHUB**

Este archivo contiene la estructura **REAL** de la base de datos en producción (Somee).

**REGLA OBLIGATORIA:** Antes de escribir cualquier SQL que use estas tablas, **SIEMPRE** consultar este archivo para verificar los nombres de columnas correctos.

**📖 DOCUMENTACIÓN COMPLETA:** Ver [DOCUMENTACION_COMPLETA_BD.md](DOCUMENTACION_COMPLETA_BD.md) para:
- Stored Procedures (56 SPs)
- Foreign Keys (67 relaciones)
- Índices (51)
- Descripción detallada de todas las tablas

---

## TABLAS

### 1. FLORERIA_Slot_Horario

| Columna | Tipo | Nullable | Max Length | Notas |
|---------|------|----------|------------|-------|
| slot_id | smallint | NO | NULL | PK, IDENTITY |
| ciudad_id | smallint | NO | NULL | ⚠️ NO EXISTE EN GITHUB |
| etiqueta | varchar | NO | 60 | GitHub: 50, Somee: 60 |
| hora_inicio | time | NO | NULL | ✅ Igual |
| hora_fin | time | NO | NULL | ✅ Igual |
| duracion_minutos | smallint | NO | NULL | ⚠️ NO EXISTE EN GITHUB |
| recargo_bs | decimal | NO | NULL | ✅ Igual |
| es_express | bit | NO | NULL | ⚠️ NO EXISTE EN GITHUB |
| activo | bit | NO | NULL | ✅ Igual |
| orden_display | tinyint | NO | NULL | ⚠️ GitHub usa `orden` |
| wc_slot_value | varchar | YES | 50 | ⚠️ NO EXISTE EN GITHUB |
| creado_en | datetime | NO | NULL | ⚠️ NO EXISTE EN GITHUB |

**COLUMNAS QUE GITHUB TIENE PERO SOMEE NO:**
- `recargo_usd` (decimal)

---

### 2. FLORERIA_Ciudad

| Columna | Tipo | Nullable | Max Length | Notas |
|---------|------|----------|------------|-------|
| ciudad_id | smallint | NO | NULL | PK, IDENTITY |
| depto_id | smallint | NO | NULL | FK |
| nombre | varchar | NO | 100 | ✅ Igual |
| codigo | varchar | NO | 10 | ✅ Igual |
| activo | bit | NO | NULL | ✅ Igual |
| creado_en | datetime | NO | NULL | ⚠️ NO EXISTE EN GITHUB |

**COLUMNAS QUE GITHUB TIENE PERO SOMEE NO:**
- Ninguna (Somee tiene todo + creado_en)

---

### 3. FLORERIA_Zona

| Columna | Tipo | Nullable | Max Length | Notas |
|---------|------|----------|------------|-------|
| zona_id | int | NO | NULL | PK, IDENTITY |
| ciudad_id | smallint | NO | NULL | FK |
| nombre | varchar | NO | 150 | ✅ Igual |
| codigo | varchar | NO | 20 | ✅ Igual |
| tipo | varchar | NO | 20 | ✅ Igual |
| latitud_ref | decimal | YES | NULL | ✅ Igual |
| longitud_ref | decimal | YES | NULL | ✅ Igual |
| wc_zone_id | int | YES | NULL | ⚠️ NO EXISTE EN GITHUB |
| wc_zone_code | varchar | YES | 20 | ⚠️ NO EXISTE EN GITHUB |
| activo | bit | NO | NULL | ✅ Igual |
| orden_display | smallint | NO | NULL | ⚠️ GitHub usa `orden` |
| creado_en | datetime | NO | NULL | ⚠️ NO EXISTE EN GITHUB |

**COLUMNAS QUE GITHUB TIENE PERO SOMEE NO:**
- `orden` (tinyint) - Somee usa `orden_display`

---

### 4. FLORERIA_Sucursal

| Columna | Tipo | Nullable | Max Length | Notas |
|---------|------|----------|------------|-------|
| sucursal_id | smallint | NO | NULL | PK, IDENTITY |
| ciudad_id | smallint | NO | NULL | FK |
| codigo | varchar | NO | 10 | ✅ Igual |
| nombre | varchar | NO | 100 | ✅ Igual |
| direccion | varchar | YES | 200 | ✅ Igual |
| telefono | varchar | YES | 20 | ✅ Igual |
| email | varchar | YES | 100 | ✅ Igual |
| latitud | decimal | YES | NULL | ✅ Igual |
| longitud | decimal | YES | NULL | ✅ Igual |
| hora_apertura | time | NO | NULL | ✅ Igual |
| hora_cierre | time | NO | NULL | ✅ Igual |
| dias_operacion | varchar | NO | 20 | ✅ Igual |
| fondo_fijo_bs | decimal | NO | NULL | ✅ Igual |
| wc_zone_id | int | YES | NULL | ⚠️ NO EXISTE EN GITHUB |
| wc_zone_code | varchar | YES | 20 | ⚠️ NO EXISTE EN GITHUB |
| activo | bit | NO | NULL | ✅ Igual |
| creado_en | datetime | NO | NULL | ⚠️ NO EXISTE EN GITHUB |

**COLUMNAS QUE GITHUB TIENE PERO SOMEE NO:**
- Ninguna (Somee tiene todo + campos WooCommerce)

---

### 5. FLORERIA_Pedido

| Columna | Tipo | Nullable | Max Length | Notas |
|---------|------|----------|------------|-------|
| pedido_id | int | NO | NULL | PK, IDENTITY |
| prepedido_id | int | YES | NULL | FK |
| codigo | varchar | NO | 20 | ✅ Igual |
| receptor_nombre | varchar | NO | 200 | ✅ Igual |
| receptor_celular | varchar | NO | 20 | ✅ Igual |
| ciudad_id | smallint | NO | NULL | FK |
| zona_id | int | YES | NULL | FK |
| sucursal_id | smallint | YES | NULL | FK |
| tipo_entrega | varchar | NO | 20 | ✅ Igual |
| direccion | varchar | YES | 300 | ✅ Igual |
| latitud | decimal | YES | NULL | ✅ Igual |
| longitud | decimal | YES | NULL | ✅ Igual |
| referencia | varchar | YES | 300 | ✅ Igual |
| fecha_entrega | date | NO | NULL | ✅ Igual |
| slot_id | smallint | YES | NULL | FK |
| es_express | bit | NO | NULL | ✅ Igual |
| dedicatoria | nvarchar | YES | 500 | ✅ Igual |
| firma_tarjeta | varchar | YES | 100 | ✅ Igual |
| subtotal_productos_bs | decimal | NO | NULL | ✅ Igual |
| subtotal_productos_usd | decimal | NO | NULL | ✅ Igual |
| envio_bs | decimal | NO | NULL | ✅ Igual |
| envio_usd | decimal | NO | NULL | ✅ Igual |
| recargo_express_bs | decimal | NO | NULL | ✅ Igual |
| recargo_express_usd | decimal | NO | NULL | ✅ Igual |
| recargo_horario_bs | decimal | NO | NULL | ✅ Igual |
| recargo_horario_usd | decimal | NO | NULL | ✅ Igual |
| total_bs | decimal | NO | NULL | ✅ Igual |
| total_usd | decimal | NO | NULL | ✅ Igual |
| anticipo_bs | decimal | NO | NULL | ✅ Igual |
| saldo_bs | decimal | NO | NULL | ✅ Igual |
| estado_pago | varchar | NO | 20 | ✅ Igual |
| wc_order_id | int | YES | NULL | ⚠️ NO EXISTE EN GITHUB |
| wc_order_number | varchar | YES | 30 | ⚠️ NO EXISTE EN GITHUB |
| wc_order_url | varchar | YES | 300 | ⚠️ NO EXISTE EN GITHUB |
| wc_sync_estado | varchar | NO | 20 | ⚠️ NO EXISTE EN GITHUB |
| wc_sync_fecha | datetime | YES | NULL | ⚠️ NO EXISTE EN GITHUB |
| observaciones | nvarchar | YES | 500 | ✅ Igual |
| creado_por | int | YES | NULL | ✅ Igual |
| creado_en | datetime | NO | NULL | ✅ Igual |
| modificado_por | int | YES | NULL | ✅ Igual |
| modificado_en | datetime | YES | NULL | ✅ Igual |

**COLUMNAS QUE GITHUB TIENE PERO SOMEE NO:**
- Ninguna (Somee tiene todo + campos WooCommerce)

---

### 6. FLORERIA_PrePedido

| Columna | Tipo | Nullable | Max Length | Notas |
|---------|------|----------|------------|-------|
| prepedido_id | int | NO | NULL | PK, IDENTITY |
| codigo | varchar | NO | 20 | ✅ Igual |
| token_web | varchar | YES | 100 | ✅ Igual |
| tipo_registro | varchar | NO | 20 | ✅ Igual |
| cliente_celular | varchar | NO | 20 | ✅ Igual |
| cliente_nombre | varchar | YES | 200 | ✅ Igual |
| cliente_apellidos | varchar | YES | 200 | ✅ Igual |
| cliente_email | varchar | YES | 100 | ✅ Igual |
| cliente_pais_id | tinyint | YES | NULL | ✅ Igual |
| cliente_ciudad_id | smallint | YES | NULL | ✅ Igual |
| estado | varchar | NO | 30 | ✅ Igual |
| total_general_bs | decimal | NO | NULL | ✅ Igual |
| total_general_usd | decimal | NO | NULL | ✅ Igual |
| tasa_cambio | decimal | NO | NULL | ✅ Igual |
| moneda_formulario | char | NO | 3 | ✅ Igual |
| descuento_bs | decimal | NO | NULL | ✅ Igual |
| descuento_usd | decimal | NO | NULL | ✅ Igual |
| descuento_motivo | varchar | YES | 300 | ✅ Igual |
| agente_actual_id | int | NO | NULL | ✅ Igual |
| fecha_limite_pago | datetime | YES | NULL | ✅ Igual |
| token_expira | datetime | YES | NULL | ✅ Igual |
| observaciones | nvarchar | YES | 500 | ✅ Igual |
| creado_por | int | NO | NULL | ✅ Igual |
| creado_en | datetime | NO | NULL | ✅ Igual |
| modificado_por | int | YES | NULL | ✅ Igual |
| modificado_en | datetime | YES | NULL | ✅ Igual |

**COLUMNAS QUE GITHUB TIENE PERO SOMEE NO:**
- Ninguna (100% coincidente)

---

## RESUMEN DE DIFERENCIAS CRÍTICAS

### ⚠️ COLUMNAS QUE EXISTEN EN SOMEE PERO NO EN GITHUB:

**FLORERIA_Slot_Horario:**
- `ciudad_id` (smallint)
- `duracion_minutos` (smallint)
- `es_express` (bit)
- `orden_display` (tinyint) - GitHub usa `orden`
- `wc_slot_value` (varchar 50)
- `creado_en` (datetime)

**FLORERIA_Ciudad:**
- `creado_en` (datetime)

**FLORERIA_Zona:**
- `wc_zone_id` (int)
- `wc_zone_code` (varchar 20)
- `orden_display` (smallint) - GitHub usa `orden`
- `creado_en` (datetime)

**FLORERIA_Sucursal:**
- `wc_zone_id` (int)
- `wc_zone_code` (varchar 20)
- `creado_en` (datetime)

**FLORERIA_Pedido:**
- `wc_order_id` (int)
- `wc_order_number` (varchar 30)
- `wc_order_url` (varchar 300)
- `wc_sync_estado` (varchar 20)
- `wc_sync_fecha` (datetime)

### ❌ COLUMNAS QUE EXISTEN EN GITHUB PERO NO EN SOMEE:

**FLORERIA_Slot_Horario:**
- `recargo_usd` (decimal)
- `orden` (tinyint) - Somee usa `orden_display`

**FLORERIA_Zona:**
- `orden` (tinyint) - Somee usa `orden_display`

---

## CÓMO USAR ESTE ARCHIVO

1. **Antes de escribir SQL:** Consultar este archivo
2. **Verificar nombres de columnas:** NO asumir basándose en GitHub
3. **ORDER BY:** Usar columnas que SÍ existan en Somee
4. **Actualizar:** Si descubres nuevas diferencias, actualizar este archivo

---

**Última verificación:** 2025-05-24 por Claude (asistente IA) + Bryan (usuario)
