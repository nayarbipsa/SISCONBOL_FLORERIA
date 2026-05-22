# ⚠️ CHECKLIST OBLIGATORIO ANTES DE GENERAR CÓDIGO VB.NET

## 🔴 VALIDAR ESTO EN **CADA ARCHIVO .VB** ANTES DE PRESENTAR:

### 1. ❌ BUSCAR "New With" - PROHIBIDO
```vb
' SI ENCUENTRO ESTO:
Dim x As New With { ... }

' DEBO CAMBIARLO A:
Public Class MiClase
    Public Property prop1 As String
    Public Property prop2 As Integer
End Class

Dim x As New MiClase()
x.prop1 = "valor"
x.prop2 = 123
```

### 2. ❌ BUSCAR "??" - PROHIBIDO
```vb
' SI ENCUENTRO ESTO:
Dim x As String = valor ?? ""

' DEBO CAMBIARLO A:
Dim x As String = valor
If x Is Nothing Then x = ""
```

### 3. ❌ BUSCAR "?." - PROHIBIDO
```vb
' SI ENCUENTRO ESTO:
Dim x As String = objeto?.propiedad

' DEBO CAMBIARLO A:
Dim x As String = ""
If objeto IsNot Nothing Then x = objeto.propiedad
```

### 4. ✅ VERIFICAR "Imports System.Data" AL INICIO
```vb
' DEBE ESTAR SIEMPRE:
Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization
```

### 5. ❌ BUSCAR "window.onload" EN ASPX - PROHIBIDO
```javascript
// SI ENCUENTRO ESTO:
window.onload = function() { ... }

// DEBO CAMBIARLO A:
window.addEventListener('DOMContentLoaded', function() { ... });
```

### 6. ❌ BUSCAR INYECCIÓN DIRECTA DE JSON - PROHIBIDO
```vb
' SI ENCUENTRO ESTO:
Dim script As String = "<script>var datos = " & json & ";</script>"
ClientScript.RegisterStartupScript(...)

' DEBO CAMBIARLO A:
' En VB:
Public Property JsonData As String = ""
JsonData = serializer.Serialize(lista)

' En ASPX:
' <div id="jsonData" style="display:none;"><%=JsonData%></div>

' En JS:
' var datos = JSON.parse(document.getElementById('jsonData').textContent);
```

### 7. ✅ VERIFICAR CLASES ANTES DE LISTAS
```vb
' SI VOY A USAR:
Dim lista As New List(Of MiClase)()

' DEBO VERIFICAR QUE LA CLASE EXISTE:
Public Class MiClase
    Public Property id As Integer
    Public Property nombre As String
End Class
```

---

## 🔥 PROCESO OBLIGATORIO:

```
1. ESCRIBIR código VB.NET
2. BUSCAR cada patrón prohibido (New With, ??, ?., etc)
3. SI ENCUENTRO ALGUNO → REESCRIBIR antes de presentar
4. VERIFICAR Imports al inicio
5. VERIFICAR clases declaradas antes de usar
6. SOLO ENTONCES → Presentar archivo al usuario
```

---

## 💀 SI ME EQUIVOCO DE NUEVO:

El usuario tiene derecho a:
- ✅ Recordarme esta lista
- ✅ Pedirme que valide el código ANTES de presentar
- ✅ Exigir que siga mis propias reglas

---

## 🎯 COMPROMISO:

**DE AHORA EN ADELANTE:**

Antes de presentar **CUALQUIER archivo .VB**, voy a:

1. ✅ Buscar "New With" → Reemplazar con clase
2. ✅ Buscar "??" → Reemplazar con If Nothing
3. ✅ Buscar "?." → Reemplazar con IsNot Nothing
4. ✅ Verificar Imports System.Data
5. ✅ Verificar que no inyecto JSON directo

**SOLO DESPUÉS de validar esto, te presento el código.**

---

## 📝 USO:

Cada vez que vaya a generar un .VB:

```
[GENERAR CÓDIGO]
    ↓
[BUSCAR PATRONES PROHIBIDOS]
    ↓
[¿ENCONTRÉ ALGUNO?]
    ↓ SÍ
[REESCRIBIR ANTES DE PRESENTAR]
    ↓ NO
[PRESENTAR AL USUARIO]
```

---

**Esto garantiza que NUNCA más cometa estos errores.**
