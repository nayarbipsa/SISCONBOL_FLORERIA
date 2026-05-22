# 🔥 SISCONBOL_FLORERIA — REGLAS DEFINITIVAS DEL PROYECTO
## Versión 3.0 — Post-Seguridad y Consolidación

**Fecha:** Mayo 2026  
**Versión:** 3.0 (Post-Seguridad + CSS/JS Consolidados)  
**Autor:** Equipo SISCONBOL

---

## 📚 ÍNDICE RÁPIDO

1. [Stack y Arquitectura](#stack)
2. [Seguridad (NUEVO)](#seguridad)
3. [MasterPage](#masterpage)
4. [VB.NET](#vbnet)
5. [ASPX](#aspx)
6. [JavaScript](#javascript)
7. [SQL Server](#sql)
8. [CSS/JS Consolidados](#archivos)
9. [Estructura de Carpetas](#carpetas)
10. [Patrón de Código](#patron)
11. [Checklist](#checklist)

---

## <a name="stack"></a>📦 1. STACK Y ARQUITECTURA

### **Stack Tecnológico**
```
Frontend:    ASP.NET Web Forms + MasterPage
Backend:     VB.NET (.NET Framework 4.8)
Base Datos:  SQL Server 2019
IDE:         Visual Studio 2022 Insiders
Servidor:    Somee.com
Estilos:     CSS consolidado v2.0
Scripts:     JavaScript consolidado v2.0
Seguridad:   Global.asax + Error.aspx (v3.0)
```

### **Arquitectura (4 capas de seguridad)**
```
┌─────────────────────────────────────┐
│ Global.asax                         │ ← Bloquea acceso sin sesión
├─────────────────────────────────────┤
│ Web.config                          │ ← Headers, CustomErrors
├─────────────────────────────────────┤
│ Site.Master + SesionHelper          │ ← Verificación por página
├─────────────────────────────────────┤
│ Base de Datos (Stored Procedures)   │ ← Bloqueo fuerza bruta
└─────────────────────────────────────┘
```

---

## <a name="seguridad"></a>🔒 2. SEGURIDAD DEL PROYECTO (NUEVO EN V3.0)

### **Global.asax — Control de Acceso Global**

**Ubicación:** Raíz del proyecto

✅ **Funciones:**
- Bloquea acceso a .aspx sin sesión
- Permite: `/login.aspx`, `/error.aspx`, `/estilos/`, `/scripts/`, `/imagenes/`
- Bloquea: `/app_code/`, `/bin/`, `/obj/`
- Remueve headers que revelan tecnología
- Manejo centralizado de errores → Error.aspx

### **Error.aspx — Página de Errores**

**Códigos manejados:**
- **403** - Acceso denegado
- **404** - Página no encontrada  
- **500** - Error del servidor

✅ Diseño profesional con iconos Tabler  
✅ Logging con ID único  
✅ Detalles solo en desarrollo

### **Protección Contra Ataques**

| Ataque | Protección | Implementado en |
|---|---|---|
| **Fuerza Bruta** | 3 intentos → bloqueo 5 min<br>6+ intentos → bloqueo permanente | FLORERIA_sp_Login |
| **SQL Injection** | Solo Stored Procedures | Todo el código |
| **XSS** | LimpiarInput() + HtmlEncode() | Code-behind |
| **Session Hijacking** | Token + validación IP | SesionHelper |
| **Clickjacking** | X-Frame-Options: SAMEORIGIN | Web.config |
| **Acceso no autorizado** | Global.asax verifica sesión | Toda la app |

### **Headers de Seguridad (Web.config)**
```xml
<httpProtocol>
  <customHeaders>
    <remove name="X-Powered-By"/>
    <add name="X-Frame-Options" value="SAMEORIGIN"/>
    <add name="X-Content-Type-Options" value="nosniff"/>
    <add name="X-XSS-Protection" value="1; mode=block"/>
  </customHeaders>
</httpProtocol>
```

---

## <a name="masterpage"></a>🎨 3. REGLAS DE MASTERPAGE

### **REGLA #1: TODAS las páginas usan Site.Master**

**Excepciones:** Login.aspx, Error.aspx

```vb
<%@ Page Language="VB" MasterPageFile="~/Site.Master" 
         CodeBehind="MiPagina.aspx.vb" 
         Inherits="SISCONBOL_FLORERIA.Modulos_MiModulo_MiPagina" %>
```

### **REGLA #2: NO duplicar código de Site.Master**

❌ **NUNCA incluir en páginas:**
- `VerificarSesion()` privada
- `Public Property MenuHtml`
- `btnCerrarSesion_Click`
- `<form runat="server">`

✅ **SÍ usar:**
```vb
Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
Dim cadena As String = SesionHelper.ObtenerCadena()
```

### **REGLA #3: Estructura obligatoria**

```vb
<%@ Page Language="VB" MasterPageFile="~/Site.Master" ... %>

<asp:Content ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Mi Página
</asp:Content>

<asp:Content ContentPlaceHolderID="PageTitleContent" runat="server">
    Mi Página
</asp:Content>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
    <!-- CONTENIDO -->
    <input type="hidden" id="hdAccion" name="hdAccion"/>
    <asp:Button ID="btnPostBack" runat="server" Style="display:none" OnClick="btnAccion_Click"/>
</asp:Content>

<asp:Content ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck
// JavaScript específico
</script>
</asp:Content>
```

### **ContentPlaceHolders disponibles:**
1. **TitleContent** - `<title>`
2. **HeadContent** - CSS/meta adicionales
3. **PageTitleContent** - Título topbar
4. **MainContent** - Contenido principal
5. **ScriptsContent** - JavaScript específico

---

## <a name="vbnet"></a>💻 4. REGLAS VB.NET

### **4.1 Operadores NO permitidos**

```vb
' ❌ MAL - ?? no existe en VB.NET
Dim ip As String = Request.ServerVariables("REMOTE_ADDR") ?? ""

' ✅ BIEN
Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
If ip Is Nothing Then ip = ""

' ❌ MAL - ?. no existe en VB.NET 4.8
Dim n As String = usuario?.nombre

' ✅ BIEN
Dim n As String = ""
If usuario IsNot Nothing Then n = usuario.nombre
```

### **4.2 Declaración de tipos**

```vb
' ❌ MAL - tipo implícito
Dim x = cmd.ExecuteScalar()

' ✅ BIEN - tipo explícito
Dim x As Object = cmd.ExecuteScalar()
```

### **4.3 Verificar Nothing**

```vb
' ❌ MAL
Session("token").ToString()

' ✅ BIEN
If Session("token") IsNot Nothing Then
    Dim token As String = Session("token").ToString()
End If
```

### **4.4 Leer formularios**

```vb
' ✅ BIEN
Dim valor As String = Request.Form("hdAccion")
If valor Is Nothing Then valor = ""
valor = valor.Trim()
```

### **4.5 Clase siempre Partial Public**

```vb
' ✅ BIEN
Partial Public Class Modulos_Catalogo_Productos
    Inherits System.Web.UI.Page
End Class
```

### **4.6 NO agregar Namespace manual**

```vb
' ❌ MAL
Namespace SISCONBOL_FLORERIA
    Partial Public Class Login
    End Class
End Namespace

' ✅ BIEN (el .vbproj ya lo agrega)
Partial Public Class Login
    Inherits System.Web.UI.Page
End Class
```

### **4.7 Función para limpiar inputs (SEGURIDAD)**

```vb
Private Function LimpiarInput(v As String) As String
    If v Is Nothing Then Return ""
    v = v.Trim()
    v = v.Replace("<", "").Replace(">", "")
    v = v.Replace("'", "").Replace("""", "")
    Return v
End Function
```

---

## <a name="aspx"></a>📄 5. REGLAS ASPX

### **5.1 CodeBehind (nunca CodeFile)**

```vb
' ✅ BIEN
<%@ Page CodeBehind="Productos.aspx.vb" 
         Inherits="SISCONBOL_FLORERIA.Modulos_Catalogo_Productos" %>
```

### **5.2 Inherits con namespace completo**

```vb
' ✅ BIEN
Inherits="SISCONBOL_FLORERIA.Modulos_Catalogo_Productos"
```

### **5.3 NO agregar <form runat=server>**

Site.Master ya lo tiene.

### **5.4 Patrón HTML + hidden fields**

```html
<asp:Content ContentPlaceHolderID="MainContent" runat="server">
    <input type="text" id="txNombre" name="txNombre"/>
    <input type="hidden" id="hdAccion" name="hdAccion"/>
    <asp:Button ID="btnPostBack" runat="server" Style="display:none" OnClick="btnAccion_Click"/>
</asp:Content>
```

### **5.5 Propiedades públicas para HTML dinámico**

```vb
' En .aspx.vb
Public Property TablaHtml As String = ""

' En .aspx
<div><%=TablaHtml%></div>
```

---

## <a name="javascript"></a>⚡ 6. REGLAS JAVASCRIPT

### **6.1 Siempre // @ts-nocheck**

```javascript
<script type="text/javascript">
// @ts-nocheck
function miFunc() { ... }
</script>
```

### **6.2 Verificar null**

```javascript
// ✅ BIEN
var el = document.getElementById('miDiv');
if (el) { el.textContent = 'hola'; }
```

### **6.3 Castear a HTMLInputElement**

```javascript
// ✅ BIEN
var inp = /** @type {HTMLInputElement} */ (document.getElementById('txNombre'));
if (inp) { var val = inp.value; }
```

### **6.4 Tipar parámetros (JSDoc)**

```javascript
// ✅ BIEN
function toggleHijos(/** @type {string} */ id) { ... }
```

### **6.5 Solo var (no const/let)**

```javascript
// ✅ BIEN
var nombre = 'valor';
```

### **6.6 Funciones en site.js v2.0 (NO duplicar)**

**Ya disponibles globalmente:**

- `abrirSidebar()`, `cerrarSidebar()`
- `toggleHijos(id)`, `toggleAvatarMenu()`
- `cerrarSesion()`
- `mostrarAlerta(mensaje, tipo)`, `ocultarAlerta()`
- `marcarError(idCampo, idError, esError)`
- `limpiarErrores()`
- `validarRequerido(idCampo, idError)`
- `validarEmail(email)`, `validarCampoEmail(idCampo, idError)`
- `formatearFecha(fecha)`, `formatearBs(monto)`, `formatearUsd(monto)`
- `obtenerValor(idCampo, default)`, `establecerValor(idCampo, valor)`
- `limpiarCampo(idCampo)`, `habilitarCampo(idCampo)`, `deshabilitarCampo(idCampo)`
- `deshabilitarBotonConSpinner(idBoton, texto)`
- `habilitarBoton(idBoton, texto, icono)`
- `scrollTop()`, `scrollToElement(id)`
- `confirmar(mensaje)`
- `toggleFilaDetalle(idFila)`
- `mostrarVista(idVista)`, `activarPestana(idPestana, idContenido)`
- `abrirModal(idModal)`, `cerrarModal(idModal)`
- `previsualizarImagen(idInput, idImagen)`
- `capitalizar(str)`, `truncar(str, maxLength)`

---

## <a name="sql"></a>🗄️ 7. REGLAS SQL SERVER

### **7.1 GO entre procedures**

```sql
CREATE OR ALTER PROCEDURE FLORERIA_sp_Login ...
AS BEGIN ... END;
GO

CREATE OR ALTER PROCEDURE FLORERIA_sp_Otro ...
AS BEGIN ... END;
GO
```

### **7.2 SOLO Stored Procedures**

```vb
' ✅ BIEN
Using cmd As New SqlCommand("FLORERIA_sp_Login", conn)
    cmd.CommandType = CommandType.StoredProcedure
    cmd.Parameters.AddWithValue("@carnet", carnet)
End Using
```

### **7.3 Prefijo FLORERIA_**

- Tablas: `FLORERIA_Usuario`
- Procedures: `FLORERIA_sp_Login`
- Funciones: `FLORERIA_fn_Generar`

### **7.4 Hash SHA256 + salt 'FLORERIA2026'**

```sql
-- SQL Server
DECLARE @hash VARCHAR(200) = UPPER(CONVERT(VARCHAR(200),
    HASHBYTES('SHA2_256', @password + 'FLORERIA2026'), 2))
```

```vb
' VB.NET - DEBE COINCIDIR EXACTAMENTE
Dim datos() As Byte = Encoding.UTF8.GetBytes(pwd & "FLORERIA2026")
Dim hash() As Byte = SHA256.Create().ComputeHash(datos)
Return BitConverter.ToString(hash).Replace("-", "").ToUpper()
```

### **7.5 Parámetros SIEMPRE**

```vb
' ❌ MAL - SQL Injection
"WHERE carnet='" & carnet & "'"

' ✅ BIEN
cmd.Parameters.AddWithValue("@carnet", carnet)
```

---

## <a name="archivos"></a>📁 8. CSS/JS CONSOLIDADOS (v2.0)

### **Archivos globales**

```
Estilos/site.css  ← v2.0 CONSOLIDADO (sin duplicados)
Scripts/site.js   ← v2.0 CONSOLIDADO (60+ funciones)
```

### **Cambios en v2.0:**

✅ Eliminadas funciones JS duplicadas  
✅ Eliminadas clases CSS duplicadas  
✅ Corregido `marcarError()` → usa `.campo-error`  
✅ Agregadas 30+ funciones nuevas  
✅ Agregadas 50+ clases CSS nuevas

### **NUNCA duplicar CSS**

❌ **NO hagas:**
```html
<style>
.panel { background:white; }
</style>
```

✅ **Haz:**
- Global → `Estilos/site.css`
- Específico → `Estilos/mipagina.css` en HeadContent

---

## <a name="carpetas"></a>📂 9. ESTRUCTURA DE CARPETAS

```
SISCONBOL_FLORERIA/
├─ App_Code/
│  └─ SesionHelper.vb
├─ Estilos/
│  └─ site.css (v2.0)
├─ Scripts/
│  └─ site.js (v2.0)
├─ Imagenes/
├─ Modulos/
│  ├─ Catalogo/
│  ├─ Pedidos/
│  ├─ Delivery/
│  ├─ Finanzas/
│  └─ Config/
├─ Site.Master
├─ Site.Master.vb
├─ Global.asax (v3.0)
├─ Login.aspx
├─ Default.aspx
├─ Error.aspx (v3.0)
├─ Error.aspx.vb
├─ Web.config
├─ REGLAS_DEFINITIVAS_V3.md
└─ SEGURIDAD_PROYECTO.md
```

---

## <a name="patron"></a>📐 10. PATRÓN DE CÓDIGO

### **Template .aspx.vb**

```vb
Imports System.Data.SqlClient
Imports System.Text

Partial Public Class Modulos_MiModulo_MiPagina
    Inherits System.Web.UI.Page

    Public Property TablaHtml As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' NO verificar sesión - Site.Master ya lo hace
        If Not IsPostBack Then
            CargarDatos()
        End If
    End Sub

    Protected Sub btnAccion_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""

        Select Case accion
            Case "GUARDAR" : ProcesarGuardar()
        End Select

        CargarDatos()
    End Sub

    Private Sub CargarDatos()
        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Consulta", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@usuario_id", usuarioId)
                    
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        Dim sb As New StringBuilder()
                        While dr.Read()
                            sb.Append(HttpUtility.HtmlEncode(dr("campo").ToString()))
                        End While
                        TablaHtml = sb.ToString()
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR: " & ex.Message)
        End Try
    End Sub

    Private Function LimpiarInput(v As String) As String
        If v Is Nothing Then Return ""
        v = v.Trim()
        v = v.Replace("<", "").Replace(">", "")
        v = v.Replace("'", "").Replace("""", "")
        Return v
    End Function

End Class
```

---

## <a name="checklist"></a>✅ 11. CHECKLIST OBLIGATORIO

### **Estructura:**
- [ ] ¿Usa `MasterPageFile="~/Site.Master"`?
- [ ] ¿Usa `CodeBehind` (no `CodeFile`)?
- [ ] ¿`Inherits` incluye `SISCONBOL_FLORERIA.`?
- [ ] ¿Contenido en `<asp:Content>`?
- [ ] ¿NO incluye `<html>`, `<form runat=server>`?

### **Code-behind:**
- [ ] ¿`Partial Public Class`?
- [ ] ¿NO tiene `Namespace` manual?
- [ ] ¿NO tiene `VerificarSesion()` privada?
- [ ] ¿Usa `SesionHelper.ObtenerUsuarioId()`?
- [ ] ¿Usa `SesionHelper.ObtenerCadena()`?

### **Seguridad:**
- [ ] ¿Limpia inputs con `LimpiarInput()`?
- [ ] ¿Encodea salidas con `HtmlEncode()`?
- [ ] ¿Solo Stored Procedures?
- [ ] ¿Usa `AddWithValue()` en parámetros?

### **JavaScript:**
- [ ] ¿Tiene `// @ts-nocheck`?
- [ ] ¿Verifica `null` en `getElementById`?
- [ ] ¿Usa funciones de site.js v2.0?

### **CSS:**
- [ ] ¿NO duplica estilos de site.css?

---

## 🎯 RESUMEN V3.0

### **NUEVO:**
✅ Global.asax (control de acceso)  
✅ Error.aspx (página de errores)  
✅ 4 capas de seguridad  
✅ Protección contra 7 ataques  
✅ Bloqueo de fuerza bruta  
✅ Headers de seguridad  
✅ Logging de errores  

### **MANTENIDO:**
✅ Site.Master sólido  
✅ SesionHelper centralizado  
✅ site.css v2.0 consolidado  
✅ site.js v2.0 (60+ funciones)  

---

## 📊 CHECKLIST PRODUCCIÓN

**Web.config:**
- [ ] `debug="false"`
- [ ] `customErrors mode="On"`
- [ ] Password BD actualizada
- [ ] HTTPS configurado

**Testing:**
- [ ] Login con 3 intentos fallidos (bloqueo 5 min)
- [ ] Acceso sin sesión (redirect Login)
- [ ] Páginas de error (403, 404, 500)

---

**Versión:** 3.0  
**Fecha:** Mayo 2026  
**Equipo:** SISCONBOL
