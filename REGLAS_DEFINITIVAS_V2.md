# 🔥 SISCONBOL_FLORERIA — REGLAS DEFINITIVAS DEL PROYECTO
## Actualizado después de implementar MasterPage

**Fecha:** Mayo 2026  
**Versión:** 2.0 (Post-MasterPage)

---

## 📚 ÍNDICE

1. [Stack Tecnológico](#stack)
2. [Arquitectura del Proyecto](#arquitectura)
3. [Reglas de MasterPage](#masterpage)
4. [Reglas VB.NET](#vbnet)
5. [Reglas ASPX](#aspx)
6. [Reglas JavaScript](#javascript)
7. [Reglas SQL Server](#sql)
8. [Reglas de Archivos CSS/JS](#archivos)
9. [Estructura de Carpetas](#carpetas)
10. [Patrón de Páginas](#patron)
11. [Checklist Obligatorio](#checklist)
12. [Errores Comunes](#errores)

---

## <a name="stack"></a>📦 1. STACK TECNOLÓGICO

```
Frontend:    ASP.NET Web Forms + MasterPage
Backend:     VB.NET (.NET Framework 4.8)
Base Datos:  SQL Server 2019
IDE:         Visual Studio 2022 Insiders
Servidor:    Somee.com (producción)
Estilos:     CSS personalizado (sin Bootstrap)
Iconos:      Tabler Icons
```

---

## <a name="arquitectura"></a>🏗️ 2. ARQUITECTURA DEL PROYECTO

### **Patrón Implementado:**

```
Site.Master (Layout base)
    ├─ Sidebar (menú dinámico desde BD)
    ├─ Topbar (usuario + avatar menu)
    └─ ContentPlaceHolder (contenido de cada página)

Estilos/site.css (todos los estilos globales)
Scripts/site.js (funciones compartidas)
App_Code/SesionHelper.vb (lógica de sesión)
```

### **Flujo de una página:**

1. Usuario accede a `Productos.aspx`
2. `Site.Master.vb` verifica sesión con `SesionHelper`
3. Si sesión válida, carga menú dinámico
4. Renderiza contenido de `Productos.aspx` dentro del layout
5. Carga `site.css` y `site.js` automáticamente

---

## <a name="masterpage"></a>🎨 3. REGLAS DE MASTERPAGE

### **REGLA #1: TODAS las páginas internas usan Site.Master**

**Excepción:** Login.aspx, Error.aspx, CambiarPassword.aspx (páginas standalone)

```vb
' ✅ CORRECTO
<%@ Page Language="VB" MasterPageFile="~/Site.Master" 
         AutoEventWireup="false" 
         CodeBehind="Productos.aspx.vb" 
         Inherits="SISCONBOL_FLORERIA.Modulos_Catalogo_Productos" %>

' ❌ INCORRECTO
<%@ Page Language="VB" AutoEventWireup="false" CodeFile="..." %>
<!DOCTYPE html>
<html>
...
```

---

### **REGLA #2: Estructura obligatoria de cada página**

```vb
<%@ Page ... MasterPageFile="~/Site.Master" ... %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Título de la Página
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    Título en Topbar
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <!-- AQUÍ VA TODO EL CONTENIDO DE LA PÁGINA -->
    
    <!-- Hidden fields necesarios -->
    <input type="hidden" id="hdAccion" name="hdAccion" value=""/>
    
    <!-- Botones ASP (OBLIGATORIOS si se usa postback) -->
    <asp:Button ID="btnPostBack" runat="server" Text="" 
                Style="display:none" OnClick="btnAccion_Click"/>
</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck
// JavaScript específico de esta página
</script>
</asp:Content>
```

---

### **REGLA #3: NO duplicar layout en páginas**

**❌ NUNCA INCLUIR EN UNA PÁGINA:**
- `<html>`, `<head>`, `<body>`, `<form runat="server">`
- `<style>` con CSS del layout (sidebar, topbar, etc.)
- Sidebar completo
- Topbar completo
- Menú de navegación
- Botón cerrar sesión del sidebar

**✅ SOLO INCLUIR:**
- Contenido específico de la página dentro de `<asp:Content>`
- Hidden fields necesarios para esa página
- Botones ASP específicos (btnPostBack, etc.)
- JavaScript específico en ScriptsContent

---

### **REGLA #4: Code-behind simplificado**

**❌ YA NO NECESITAS en el .aspx.vb:**

```vb
' ELIMINAR ESTO:
Public Property MenuHtml As String = ""

If Not SesionHelper.VerificarSesion(...) Then
    Response.Redirect("~/Login.aspx")
    Return
End If

MenuHtml = SesionHelper.GenerarMenuHtml(HttpContext.Current, Me)

Protected Sub btnCerrarSesion_Click(...)
    ' ...
End Sub
```

**✅ SOLO MANTENER:**

```vb
Imports System.Data
Imports System.Data.SqlClient
Imports System.Web

Partial Public Class Modulos_Catalogo_Productos
    Inherits System.Web.UI.Page

    ' Propiedades específicas de la página
    Public Property TablaHtml As String = ""
    
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' La verificación de sesión la hace Site.Master
        ' Solo código específico de esta página
        If Not IsPostBack Then
            CargarDatos()
        End If
    End Sub
    
    Protected Sub btnPostBack_Click(ByVal sender As Object, ByVal e As EventArgs)
        ' Lógica de postback
    End Sub
    
    ' Métodos privados específicos
    Private Sub CargarDatos()
        '...
    End Sub
End Class
```

---

### **REGLA #5: Acceso a SesionHelper**

Aunque Site.Master maneja la verificación, puedes seguir usando SesionHelper:

```vb
' ✅ PERMITIDO en cualquier página
Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
Dim cadena As String = SesionHelper.ObtenerCadena()
```

---

## <a name="vbnet"></a>🔧 4. REGLAS VB.NET (SIN CAMBIOS)

### **4.1 Sin operador ??**
```vb
' ❌ MAL
Dim ip As String = Request.ServerVariables("REMOTE_ADDR") ?? ""

' ✅ BIEN
Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
If ip Is Nothing Then ip = ""
```

### **4.2 Sin operador ?.**
```vb
' ❌ MAL
Dim n As String = usuario?.nombre

' ✅ BIEN
Dim n As String = ""
If usuario IsNot Nothing Then n = usuario.nombre
```

### **4.3 Siempre declarar tipos**
```vb
' ❌ MAL
Dim x = cmd.ExecuteScalar()

' ✅ BIEN
Dim x As Object = cmd.ExecuteScalar()
```

### **4.4 Verificar Nothing antes de usar**
```vb
' ❌ MAL
Session("token").ToString()

' ✅ BIEN
If Session("token") IsNot Nothing Then
    Dim token As String = Session("token").ToString()
End If
```

### **4.5 Leer formularios con Request.Form**
```vb
' ✅ BIEN
Dim valor As String = Request.Form("hdAccion")
If valor Is Nothing Then valor = ""
valor = valor.Trim()
```

### **4.6 Siempre Partial Public Class**
```vb
' ❌ MAL (solo funciona local)
Partial Class MiClase

' ✅ BIEN (funciona en Somee)
Partial Public Class MiClase
```

### **4.7 NUNCA agregar Namespace manualmente**
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

---

## <a name="aspx"></a>📄 5. REGLAS ASPX

### **5.1 SIEMPRE CodeBehind (nunca CodeFile)**
```vb
' ❌ MAL (solo local)
<%@ Page CodeFile="Productos.aspx.vb" Inherits="Modulos_Catalogo_Productos" %>

' ✅ BIEN (funciona en Somee)
<%@ Page CodeBehind="Productos.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Catalogo_Productos" %>
```

### **5.2 Inherits SIEMPRE con namespace**
```vb
' ❌ MAL
Inherits="Productos"

' ✅ BIEN
Inherits="SISCONBOL_FLORERIA.Modulos_Catalogo_Productos"
```

### **5.3 Controles dentro de form runat=server**

**NOTA:** Site.Master ya tiene el `<form id="form1" runat="server">`, NO lo agregues en las páginas.

```vb
<!-- ✅ BIEN - dentro de asp:Content -->
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <input type="hidden" id="hdAccion" name="hdAccion"/>
    <asp:Button ID="btnPostBack" runat="server" OnClick="btnAccion_Click"/>
</asp:Content>
```

### **5.4 HTML puro + hidden fields**
```html
<!-- ✅ PATRÓN RECOMENDADO -->
<input type="text" id="txNombre" name="txNombre"/>
<input type="hidden" id="hdId" name="hdId"/>
<asp:Button ID="btnPostBack" runat="server" Style="display:none" OnClick="btnAccion_Click"/>
```

### **5.5 Propiedades públicas para contenido dinámico**
```vb
' En .aspx.vb
Public Property TablaHtml As String = ""

' En .aspx
<div id="divTabla"><%=TablaHtml%></div>
```

---

## <a name="javascript"></a>⚡ 6. REGLAS JAVASCRIPT

### **6.1 SIEMPRE // @ts-nocheck**
```javascript
<script type="text/javascript">
// @ts-nocheck
function miFunc() { ... }
</script>
```

### **6.2 Verificar null en getElementById**
```javascript
// ❌ MAL
document.getElementById('miDiv').textContent = 'hola';

// ✅ BIEN
var el = document.getElementById('miDiv');
if (el) { el.textContent = 'hola'; }
```

### **6.3 Castear a HTMLInputElement**
```javascript
// ❌ MAL
var val = document.getElementById('txNombre').value;

// ✅ BIEN
var inp = /** @type {HTMLInputElement} */ (document.getElementById('txNombre'));
if (inp) { var val = inp.value; }
```

### **6.4 Tipar parámetros**
```javascript
// ❌ MAL
function toggleHijos(id) { ... }

// ✅ BIEN
function toggleHijos(/** @type {string} */ id) { ... }
```

### **6.5 Solo var (no const/let)**
```javascript
// ✅ BIEN
var nombre = 'valor';
```

### **6.6 Funciones globales disponibles en site.js**

Ya NO necesitas copiar estas funciones en cada página:
- `abrirSidebar()`
- `cerrarSidebar()`
- `toggleHijos(id)`
- `toggleAvatarMenu()`
- `mostrarAlerta(idAlerta, mostrar)`
- `marcarError(idCampo, idError, esError)`
- `validarRequerido(idCampo, idError)`
- `formatearBs(monto)`

**Solo escribe funciones específicas de tu página.**

---

## <a name="sql"></a>🗄️ 7. REGLAS SQL SERVER (SIN CAMBIOS)

### **7.1 GO entre procedures**
```sql
CREATE OR ALTER PROCEDURE FLORERIA_sp_Login ...
AS BEGIN ... END;
GO

CREATE OR ALTER PROCEDURE FLORERIA_sp_OtraCosa ...
AS BEGIN ... END;
GO
```

### **7.2 Solo Stored Procedures**
```vb
' ❌ MAL
Dim cmd As New SqlCommand("SELECT * FROM FLORERIA_Usuario WHERE carnet='" & carnet & "'", conn)

' ✅ BIEN
Dim cmd As New SqlCommand("FLORERIA_sp_Login", conn)
cmd.CommandType = Data.CommandType.StoredProcedure
cmd.Parameters.AddWithValue("@carnet", carnet)
```

### **7.3 Prefijo FLORERIA_**
- Tablas: `FLORERIA_Usuario`
- Procedures: `FLORERIA_sp_Login`
- Funciones: `FLORERIA_fn_GenerarCodigo`

### **7.4 Hash SHA256 + salt**
```sql
DECLARE @salt VARCHAR(50) = 'FLORERIA2026'
DECLARE @hash VARCHAR(200) = UPPER(CONVERT(VARCHAR(200),
    HASHBYTES('SHA2_256', 'password' + 'FLORERIA2026'), 2))
```

### **7.5 Campos UNIQUE opcionales = NULL**
```vb
' ❌ MAL
cmd.Parameters.AddWithValue("@token_web", "")

' ✅ BIEN
cmd.Parameters.AddWithValue("@token_web", DBNull.Value)
```

---

## <a name="archivos"></a>📁 8. REGLAS DE ARCHIVOS CSS/JS

### **8.1 Ubicación de archivos**

```
SISCONBOL_FLORERIA/
  ├─ Estilos/
  │  └─ site.css           ← TODO el CSS global aquí
  ├─ Scripts/
  │  └─ site.js            ← Funciones compartidas aquí
  ├─ Site.Master           ← Layout base
  └─ Site.Master.vb        ← Lógica del layout
```

### **8.2 NUNCA duplicar CSS**

**❌ NO HAGAS ESTO:**
```html
<asp:Content ...>
<style>
.panel{background:white;...}
.btn{padding:7px...}
</style>
</asp:Content>
```

**✅ HAZ ESTO:**
- Si es CSS global → agrégalo a `Estilos/site.css`
- Si es CSS específico de UNA página → crea `Estilos/productos.css` y referéncialo en HeadContent

```vb
<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Estilos/productos.css") %>">
</asp:Content>
```

### **8.3 Funciones JavaScript compartidas**

Si una función la usas en 2+ páginas → muévela a `Scripts/site.js`

**Ejemplo:** `toggleHijos()`, `marcarError()`, `validarRequerido()`

---

## <a name="carpetas"></a>📂 9. ESTRUCTURA DE CARPETAS

```
SISCONBOL_FLORERIA/
├─ App_Code/
│  └─ SesionHelper.vb          ← Clase compartida sesión
│
├─ Estilos/
│  └─ site.css                 ← CSS global
│
├─ Scripts/
│  └─ site.js                  ← JS compartido
│
├─ Imagenes/
│  ├─ logo.png
│  └─ productos/               ← Imágenes de productos
│
├─ Modulos/
│  ├─ Catalogo/
│  │  ├─ Productos.aspx
│  │  ├─ Productos.aspx.vb
│  │  ├─ Categorias.aspx
│  │  ├─ Categorias.aspx.vb
│  │  ├─ ProductoEditar.aspx
│  │  └─ ProductoEditar.aspx.vb
│  │
│  ├─ Pedidos/
│  │  ├─ Lista.aspx
│  │  ├─ PrePedidos.aspx
│  │  └─ Mostrador.aspx
│  │
│  ├─ Delivery/
│  │  └─ Lista.aspx
│  │
│  ├─ Finanzas/
│  │  ├─ Caja.aspx
│  │  └─ Gastos.aspx
│  │
│  └─ Config/
│     ├─ Usuarios.aspx
│     ├─ Zonas.aspx
│     └─ Campanas.aspx
│
├─ Site.Master                 ← MasterPage principal
├─ Site.Master.vb
├─ Login.aspx                  ← Sin MasterPage
├─ Default.aspx                ← Con MasterPage
├─ Error.aspx                  ← Sin MasterPage
├─ CambiarPassword.aspx        ← Sin MasterPage
├─ Web.config
└─ Global.asax
```

---

## <a name="patron"></a>📐 10. PATRÓN DE PÁGINA COMPLETA

### **10.1 Archivo .ASPX**

```vb
<%@ Page Language="VB" MasterPageFile="~/Site.Master" 
         AutoEventWireup="false" 
         CodeBehind="MiPagina.aspx.vb" 
         Inherits="SISCONBOL_FLORERIA.Modulos_Seccion_MiPagina" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Mi Página
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    Mi Página
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    
    <!-- Alertas -->
    <div class="alerta" id="divAlerta"></div>
    
    <!-- Panel principal -->
    <div class="panel">
        <div class="panel-head">
            <div class="panel-title">Título</div>
            <button type="button" class="btn btn-primary" onclick="abrirFormNuevo()">
                <i class="ti ti-plus"></i> Nuevo
            </button>
        </div>
        <div class="panel-body">
            <!-- Contenido aquí -->
        </div>
    </div>
    
    <!-- Hidden fields -->
    <input type="hidden" id="hdAccion" name="hdAccion" value=""/>
    <input type="hidden" id="hdId" name="hdId" value="0"/>
    
    <!-- Botón postback oculto -->
    <asp:Button ID="btnPostBack" runat="server" Text="" 
                Style="display:none" OnClick="btnPostBack_Click"/>
                
</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

function abrirFormNuevo() {
    // Lógica aquí
}

function guardar() {
    var elHd = /** @type {HTMLInputElement} */ (document.getElementById('hdAccion'));
    if (elHd) { elHd.value = 'GUARDAR'; }
    
    var elBtn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (elBtn) { elBtn.click(); }
}
</script>
</asp:Content>
```

### **10.2 Archivo .ASPX.VB**

```vb
Imports System.Data
Imports System.Data.SqlClient
Imports System.Web

Partial Public Class Modulos_Seccion_MiPagina
    Inherits System.Web.UI.Page

    ' Propiedades públicas para datos dinámicos
    Public Property TablaHtml As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' La verificación de sesión la hace Site.Master
        
        If Not IsPostBack Then
            CargarDatos()
        End If
    End Sub

    Protected Sub btnPostBack_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""

        Select Case accion
            Case "GUARDAR" : ProcesarGuardar()
            Case "ELIMINAR" : ProcesarEliminar()
        End Select

        CargarDatos()
    End Sub

    Private Sub CargarDatos()
        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_MiConsulta", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@usuario_id", usuarioId)
                    
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        Dim sb As New System.Text.StringBuilder()
                        While dr.Read()
                            ' Construir HTML
                        End While
                        TablaHtml = sb.ToString()
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR: " & ex.Message)
        End Try
    End Sub

    Private Sub ProcesarGuardar()
        Dim campo As String = Request.Form("txCampo")
        If campo Is Nothing Then campo = ""
        campo = campo.Trim()
        
        ' Lógica aquí
    End Sub

End Class
```

---

## <a name="checklist"></a>✅ 11. CHECKLIST OBLIGATORIO

### **Antes de crear una página nueva:**

- [ ] ¿La página usa `MasterPageFile="~/Site.Master"`?
- [ ] ¿El `Inherits` incluye el namespace `SISCONBOL_FLORERIA.`?
- [ ] ¿Usé `CodeBehind` en lugar de `CodeFile`?
- [ ] ¿El contenido está dentro de `<asp:Content>` placeholders?
- [ ] ¿NO incluí `<html>`, `<head>`, `<style>` del layout?
- [ ] ¿NO incluí sidebar, topbar, menú?
- [ ] ¿Agregué los hidden fields necesarios?
- [ ] ¿Agregué el botón `btnPostBack` si uso postback?
- [ ] ¿El JavaScript está en `ScriptsContent`?
- [ ] ¿Agregué `// @ts-nocheck` al inicio del script?

### **En el code-behind (.vb):**

- [ ] ¿Usé `Partial Public Class`?
- [ ] ¿NO agregué `Namespace` manualmente?
- [ ] ¿Eliminé `MenuHtml` y la verificación de sesión?
- [ ] ¿Importé System.Data y System.Data.SqlClient?
- [ ] ¿Verifico `If valor Is Nothing` antes de usar?
- [ ] ¿Leo formularios con `Request.Form("nombreCampo")`?
- [ ] ¿Uso SesionHelper para obtener usuario_id y cadena?

---

## <a name="errores"></a>❌ 12. ERRORES COMUNES Y SOLUCIONES

### **Error 1: 'btnPostBack' no está declarado**

**Causa:** Olvidaste agregar el botón ASP en el .aspx

**Solución:**
```html
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <!-- Tu contenido -->
    
    <!-- AGREGAR ESTO -->
    <asp:Button ID="btnPostBack" runat="server" Style="display:none" OnClick="btnPostBack_Click"/>
</asp:Content>
```

---

### **Error 2: 'MenuHtml' no está declarado**

**Causa:** Dejaste `<%=MenuHtml%>` en el .aspx o `MenuHtml = ...` en el .vb

**Solución:**
- En .aspx: ELIMINA `<%=MenuHtml%>` (Site.Master ya lo maneja)
- En .vb: ELIMINA `Public Property MenuHtml` y cualquier asignación

---

### **Error 3: Could not load type 'SISCONBOL_FLORERIA.X'**

**Causa:** El `Inherits` no coincide con el nombre de la clase

**Solución:**
```vb
' .aspx
Inherits="SISCONBOL_FLORERIA.Modulos_Catalogo_Productos"

' .vb
Partial Public Class Modulos_Catalogo_Productos
```

Ambos deben coincidir exactamente.

---

### **Error 4: The control must be placed inside a form tag with runat=server**

**Causa:** Pusiste un `<form runat="server">` dentro de tu Content

**Solución:** Site.Master ya tiene el form, NO lo agregues en las páginas.

---

### **Error 5: 'X' is not accessible because it is 'Friend'**

**Causa:** Olvidaste el `Public` en la clase

**Solución:**
```vb
' ❌ MAL
Partial Class MiClase

' ✅ BIEN
Partial Public Class MiClase
```

---

### **Error 6: TS2339 / TS7006 (TypeScript warnings)**

**Causa:** Falta `// @ts-nocheck`

**Solución:**
```javascript
<script type="text/javascript">
// @ts-nocheck  ← AGREGAR ESTO
function miFunc() { ... }
</script>
```

---

## 📌 RESUMEN RÁPIDO

### **LO MÁS IMPORTANTE:**

1. ✅ **TODAS las páginas usan Site.Master** (excepto Login, Error, CambiarPassword)
2. ✅ **CodeBehind + namespace** en Inherits (nunca CodeFile)
3. ✅ **Partial Public Class** (nunca solo Partial Class)
4. ✅ **NO duplicar layout** (sidebar, topbar, CSS global)
5. ✅ **SesionHelper ya verifica sesión** (no lo hagas en cada página)
6. ✅ **site.css y site.js** tienen TODO lo compartido
7. ✅ **// @ts-nocheck** en todos los scripts
8. ✅ **Request.Form("nombre")** para leer campos
9. ✅ **Stored Procedures** siempre (nunca SQL directo)
10. ✅ **Prefijo FLORERIA_** en todo

---

**Actualizado:** Mayo 2026  
**Proyecto:** SISCONBOL_FLORERIA  
**Autor:** Sistema de Documentación
