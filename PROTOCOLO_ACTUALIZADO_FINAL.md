# ⚠️ PROTOCOLO OBLIGATORIO SISCONBOL - LÉEME PRIMERO

## 🚫 ANTES DE GENERAR **CUALQUIER** CÓDIGO:

### PASO 1: CLONAR GITHUB (SIEMPRE)
```bash
cd /tmp && rm -rf SISCONBOL_FLORERIA
git clone https://github.com/nayarbipsa/SISCONBOL_FLORERIA.git
cd SISCONBOL_FLORERIA
```

### PASO 2: LEER ARCHIVOS RELEVANTES

**Para CUALQUIER archivo SQL:**
```bash
# Leer la tabla REAL
view /tmp/SISCONBOL_FLORERIA/01_CREAR_TODAS_LAS_TABLAS.sql

# Buscar la tabla específica
grep -n "CREATE TABLE nombre_tabla" 01_CREAR_TODAS_LAS_TABLAS.sql

# Ver SPs existentes como REFERENCIA
grep -A 20 "INSERT INTO nombre_tabla" 03_TODOS_LOS_SPS.sql
```

**Para archivos .aspx/.vb:**
```bash
# Ver el archivo que voy a modificar
view /tmp/SISCONBOL_FLORERIA/ruta/del/archivo

# Ver App_Code/SesionHelper.vb
view /tmp/SISCONBOL_FLORERIA/App_Code/SesionHelper.vb

# Ver Site.Master si es página
view /tmp/SISCONBOL_FLORERIA/Site.Master
```

### PASO 3: VERIFICAR ESTRUCTURA ANTES DE USAR

**Ejemplo SQL:**
```sql
-- ❌ NUNCA INVENTAR CAMPOS
-- ✅ SIEMPRE verificar primero qué campos EXISTEN

-- Si voy a hacer INSERT en FLORERIA_Auditoria:
-- 1. Ver la tabla REAL (línea 130 del archivo)
-- 2. Ver ejemplos REALES en 03_TODOS_LOS_SPS.sql
-- 3. COPIAR la estructura, no inventar
```

---

## 📋 CHECKLIST OBLIGATORIO:

Antes de generar código, SIEMPRE responder:

- [ ] ¿Cloné el repositorio GitHub?
- [ ] ¿Leí el archivo que voy a modificar/crear?
- [ ] ¿Verifiqué la estructura de las tablas involucradas?
- [ ] ¿Leí SesionHelper.vb si es archivo .vb?
- [ ] ¿Revisé los nombres EXACTOS de los campos HTML (name="txCelular" NO "txtCelular")?
- [ ] ¿Vi ejemplos REALES en el código existente?

**Si la respuesta a CUALQUIERA es NO → NO GENERAR CÓDIGO**

---

## 🎯 LECCIONES APRENDIDAS - SISTEMA PRE-PEDIDOS

### ❌ ERROR COMÚN #1: ExecuteNonQuery vs ExecuteReader
**NUNCA usar `ExecuteNonQuery()` cuando el SP retorna un SELECT:**

```vb
' ❌ MAL - NO lee el resultado
cmd.ExecuteNonQuery()
prepedidoId = Convert.ToInt32(pId.Value)

' ✅ BIEN - Lee el SELECT que retorna el SP
Using dr As SqlDataReader = cmd.ExecuteReader()
    If dr.Read() Then
        prepedidoId = Convert.ToInt32(dr("prepedido_id"))
        yaExistia = Convert.ToBoolean(dr("ya_existia"))
    End If
End Using
```

### ❌ ERROR COMÚN #2: Nombres de campos HTML
**SIEMPRE verificar el atributo `name=""` en el HTML:**

```aspx
<!-- HTML tiene: name="txCelular" (sin la 't') -->
<input type="text" name="txCelular" />
```

```vb
' ❌ MAL
Dim celular As String = Request.Form("txtCelular")  ' No existe

' ✅ BIEN
Dim celular As String = Request.Form("txCelular")  ' Correcto
```

**COMANDO PARA VERIFICAR:**
```bash
grep -n 'name="' archivo.aspx | grep -i celular
```

### ❌ ERROR COMÚN #3: Scope de variables
**Declarar variables ANTES del Try/Using si se usan después:**

```vb
' ❌ MAL - yaExistia NO visible fuera del Using
Try
    Using conn As New SqlConnection(...)
        Dim yaExistia As Boolean = False
        ...
    End Using
    ' Aquí yaExistia NO existe
    If yaExistia Then  ' ERROR DE COMPILACIÓN
End Try

' ✅ BIEN - Declarar ANTES del Try
Dim yaExistia As Boolean = False
Try
    Using conn As New SqlConnection(...)
        yaExistia = Convert.ToBoolean(dr("ya_existia"))
    End Using
    If yaExistia Then  ' ✅ Funciona
End Try
```

### ❌ ERROR COMÚN #4: Asumir estructura del SP
**NUNCA asumir qué columnas retorna un SP - SIEMPRE verificar:**

```bash
# Ver qué SELECT retorna el SP
grep -A 10 "SELECT.*FROM FLORERIA_PrePedido" 03_TODOS_LOS_SPS.sql

# Buscar OUTPUT parameters
grep -B 5 "OUTPUT" 03_TODOS_LOS_SPS.sql
```

### ❌ ERROR COMÚN #5: Archivos no sincronizados
**SIEMPRE verificar que el archivo en GitHub coincida con el local:**

```powershell
# Verificar que el código local tiene la lógica esperada
Select-String -Path "archivo.vb" -Pattern "yaExistia"

# Si NO retorna resultados → El archivo está desactualizado
# Copiar el archivo correcto y rebuild
```

---

## 🎯 FLUJO CORRECTO:

```
USUARIO: "Crea el SP para X"
         ↓
TÚ:      1. git clone (SIEMPRE)
         2. view tabla relevante
         3. grep ejemplos existentes
         4. VERIFICAR names de campos HTML
         5. VERIFICAR qué retorna el SP (SELECT vs OUTPUT)
         6. COPIAR estructura real
         7. Generar código
         ↓
USUARIO: ✅ Funciona a la primera
```

## 🚫 FLUJO INCORRECTO:

```
USUARIO: "Crea el SP para X"
         ↓
TÚ:      "Aquí está el SP" (INVENTADO)
         ↓
USUARIO: ❌ Error: campo no existe
         ❌ Error: ExecuteNonQuery no lee el resultado
         ❌ Error: txtCelular no existe (es txCelular)
         ❌ Error: yaExistia no declarado
         ↓
TÚ:      "Ups, aquí corregido" (x4 veces)
         ↓
USUARIO: 😡 FRUSTRACIÓN
```

---

## 💡 REGLA DE ORO:

**"Si no lo VEO en el código, NO EXISTE"**

- NO asumir nombres de campos
- NO asumir estructura de tablas
- NO asumir qué retorna un SP
- NO asumir nombres de controles HTML
- NO inventar nada

**VER → COPIAR → ADAPTAR**

---

## 🔍 COMANDOS ÚTILES DE VERIFICACIÓN:

```bash
# Ver nombres EXACTOS de campos HTML
grep -n 'name="' archivo.aspx

# Ver qué columnas retorna un SP
grep -A 20 "PROCEDURE nombre_sp" 03_TODOS_LOS_SPS.sql | grep SELECT

# Ver estructura de tabla
grep -A 30 "CREATE TABLE nombre" 01_CREAR_TODAS_LAS_TABLAS.sql

# Verificar si archivo local tiene código esperado
Select-String -Path "archivo.vb" -Pattern "palabra_clave"
```

---

## 📊 ESTADÍSTICAS DE ERRORES COMUNES:

| Error | Veces cometido | Solución |
|-------|----------------|----------|
| Inventar nombres de campos | 🔴🔴🔴🔴 | `view` tabla ANTES |
| ExecuteNonQuery en lugar de Reader | 🔴🔴🔴 | Ver qué retorna SP |
| Asumir nombres controles HTML | 🔴🔴🔴 | `grep 'name='` |
| Scope de variables | 🔴🔴 | Declarar antes Try |
| Archivo desactualizado | 🔴🔴 | Verificar con grep |

**Objetivo:** Reducir TODOS a cero. ✅

---

## 🎯 SISTEMA PRE-PEDIDOS - ARQUITECTURA CORRECTA

### Flujo completo funcionando:

```
1. PrePedido_Crear.aspx
   - Formulario con campos: txCelular, txNombre, txApellidos, txEmail
   - JavaScript detecta ENTER → establece hdAccion='CREAR'
   
2. PrePedido_Crear.aspx.vb
   - Lee Request.Form("txCelular") ← SIN txt
   - Llama SP con ExecuteReader() ← NO ExecuteNonQuery
   - Lee dr("ya_existia") del resultado
   - Si yaExistia=True → redirige con &existia=1
   
3. SP_PrePedido_Crear
   - Busca celular activo
   - Si existe → Retorna existente con ya_existia=1
   - Si NO existe → Crea nuevo con ya_existia=0
   
4. PrePedido_Links.aspx.vb
   - Lee Request.QueryString("existia")
   - Pasa yaExistia a CargarDatos()
   - Mensaje WhatsApp condicional
   
5. PrePedido_Links.aspx
   - If Request.QueryString("existia")="1" Then
   - Muestra "Ya tienes pre-pedido activo"
   - Else "Pre-Pedido creado exitosamente"
```

---

## 📚 REFERENCIAS:

- GitHub: https://github.com/nayarbipsa/SISCONBOL_FLORERIA
- Ruta local: C:\Users\GOV_1009\source\repos\SISCONBOL_FLORERIA\SISCONBOL_FLORERIA
- BD: SISCONBOL en SISCONBOL.mssql.somee.com
- WhatsApp: 59163198342

---

**ÚLTIMA ACTUALIZACIÓN:** 24/05/2026 - Sistema pre-pedidos sin duplicados funcionando ✅
