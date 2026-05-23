# SISCONBOL_FLORERIA — REGLAS DEFINITIVAS V3

> **VERSIÓN AUTORITATIVA** — Refleja la arquitectura REAL del repositorio.
> **GitHub:** https://github.com/nayarbipsa/SISCONBOL_FLORERIA

---

## 🛑 REGLA #0 — ANTES DE GENERAR CUALQUIER CÓDIGO

**OBLIGATORIO en este orden:**

1. ✅ Clonar/revisar GitHub
2. ✅ Leer `App_Code/SesionHelper.vb` (corazón del sistema)
3. ✅ Leer `Site.Master` y `Site.Master.vb`
4. ✅ Leer `Estilos/site.css`
5. ✅ Si toca SQL: ejecutar `SELECT` antes de cualquier `UPDATE/INSERT/DELETE`

**NUNCA inventar archivos sin antes consultar lo que ya existe.**

---

## 📦 STACK

- ASP.NET Web Forms + VB.NET
- .NET Framework 4.8
- SQL Server 2019
- Visual Studio Insiders
- Tabler Icons (webfont) — clases `ti ti-xxx`

---

## 🏗️ ARQUITECTURA — MASTERPAGE + SESIONHELPER

### Responsabilidades:

**App_Code/SesionHelper.vb** (corazón):
- `VerificarSesion(context)`
- `GenerarMenuHtml(context, page)`
- `ObtenerCadena()`
- `ObtenerUsuarioId(context)`

**Site.Master.vb** (MÍNIMO):
- Page_Load: llama `SesionHelper.VerificarSesion` y `SesionHelper.GenerarMenuHtml`
- btnCerrarSesion_Click: cierra sesión
- ❌ NO inventar CargarMenu propio
- ❌ NO duplicar verificación de sesión
- ❌ NO tocar Session() directamente

**Páginas internas** (.aspx + .aspx.vb):
- Usan `MasterPageFile="~/Site.Master"`
- Solo lógica propia
- ❌ NO verifican sesión (Site.Master lo hace)
- ❌ NO cargan menú

---

## 📐 SITE.MASTER.VB — TEMPLATE OBLIGATORIO

```vb
Imports System.Data.SqlClient

Partial Public Class Site
    Inherits System.Web.UI.MasterPage

    Public Property MenuHtml As String = ""
    Public Property TituloPagina As String = "SISCONBOL"

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not SesionHelper.VerificarSesion(HttpContext.Current) Then
            Response.Redirect("~/Login.aspx")
            Return
        End If
        MenuHtml = SesionHelper.GenerarMenuHtml(HttpContext.Current, Me.Page)
    End Sub

    Protected Sub btnCerrarSesion_Click(sender As Object, e As EventArgs)
        ' cierre de sesión
    End Sub
End Class
```

---

## 🎨 ICONOS TABLER — REGLA CLAVE

Tabler requiere **DOS clases**:

```html
✅ <i class="ti ti-home"></i>
❌ <i class="ti-home"></i>
❌ <i class="tabler-icon ti-home"></i>
```

**En BD `FLORERIA_Menu`:** guardar solo `ti-home`  
**SesionHelper** agrega el `ti ` adelante al generar HTML.

---

## 📐 REGLAS VB.NET

1. **Sin `??`** (es C#)
2. **Sin `?.`** (no existe en VB.NET 4.8)
3. **Tipos explícitos:** `Dim x As Object = ...`
4. **Verificar Nothing antes de usar**
5. **`Partial Public Class`** (no Namespace manual)
6. **`Inherits` con namespace** en .aspx
7. **`Request.Form("hdX")`** para hidden fields

---

## 📐 REGLAS ASPX

1. **MasterPageFile en TODAS** las páginas internas
2. **Solo Login/Error/CambiarPassword** son standalone
3. **CodeBehind**, NO CodeFile
4. **No mezclar** HTML puro + asp:controles
5. **ContentPlaceHolders:** TitleContent, PageTitleContent, HeadContent, MainContent, ScriptsContent

---

## 📐 REGLAS JAVASCRIPT

1. `// @ts-nocheck` al inicio
2. Verificar null en `getElementById`
3. Castear `HTMLInputElement` para `.value`
4. Tipar parámetros con `/** @type {string} */`
5. Usar `var`, NO `const`/`let`
6. JS global en `Scripts/site.js`

---

## 📐 REGLAS SQL

1. **SELECT antes de UPDATE/INSERT/DELETE**
2. **GO entre CREATE/ALTER PROCEDURE**
3. **Solo Stored Procedures** desde VB
4. **Prefijo `FLORERIA_`** en TODO
5. **Hash SHA256 + salt `FLORERIA2026`** (debe coincidir SQL y VB)
6. **Parameters** siempre, nunca concatenar

### Campos que retornan los SPs clave:
- `FLORERIA_sp_ValidarSesion`: valida, mensaje, usuario_id, nombres, apellidos, tipo_nombre
- `FLORERIA_sp_CargarMenu`: menu_id, padre_id, nombre, icono, ruta, orden, puede_ver, puede_crear, puede_editar, puede_eliminar, tiene_hijos

---

## 📐 REGLAS CSS

1. **Global en `Estilos/site.css`** — NO duplicar
2. **Variables `:root`** (--rosa, --gris, --verde, etc.)
3. **NUNCA modificar clases base:** `.layout`, `.sidebar`, `.main`, `.topbar`, `.content`, `.nav-item`, `.nav-child`, `.avatar-*`, `.sb-*`
4. **Estilos por página:** usar `HeadContent`

---

## 📁 ESTRUCTURA (REAL del repo)

```
SISCONBOL_FLORERIA/
├── App_Code/
│   └── SesionHelper.vb         ← CORAZÓN del sistema
├── Estilos/site.css            ← CSS global
├── Scripts/site.js             ← JS global
├── Imagenes/
├── Modulos/
│   ├── Pedidos/
│   ├── Catalogo/
│   ├── Delivery/
│   ├── Finanzas/
│   ├── Config/
│   └── Reportes/
├── Site.Master                 ← MasterPage HTML
├── Site.Master.vb              ← MÍNIMO (delega a SesionHelper)
├── Default.aspx                ← Dashboard
├── Login.aspx                  ← Standalone
├── CambiarPassword.aspx        ← Standalone
├── Error.aspx                  ← Standalone
├── Web.config
└── Global.asax
```

---

## 📋 TEMPLATE DE PÁGINA NUEVA

### `Modulos/Catalogo/Productos.aspx`:

```aspx
<%@ Page Language="VB" 
         MasterPageFile="~/Site.Master" 
         AutoEventWireup="false" 
         CodeBehind="Productos.aspx.vb" 
         Inherits="SISCONBOL_FLORERIA.Modulos.Catalogo.Productos" %>

<asp:Content ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Productos
</asp:Content>

<asp:Content ContentPlaceHolderID="PageTitleContent" runat="server">
    Productos
</asp:Content>

<asp:Content ContentPlaceHolderID="MainContent" runat="server">
    <div class="panel">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-package"></i>
                Lista de Productos
            </div>
        </div>
        <div class="panel-body">
            <!-- Contenido -->
        </div>
    </div>
</asp:Content>

<asp:Content ContentPlaceHolderID="ScriptsContent" runat="server">
    <script type="text/javascript">
        // @ts-nocheck
        (function() {
            // JS específico
        })();
    </script>
</asp:Content>
```

### `Modulos/Catalogo/Productos.aspx.vb`:

```vb
Imports System.Data.SqlClient

Partial Public Class Productos
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Site.Master ya verificó sesión
        If Not IsPostBack Then
            ' Cargar datos
        End If
    End Sub
End Class
```

---

## ✅ CHECKLIST OBLIGATORIO

### Antes de generar:
- [ ] ¿Revisé GitHub?
- [ ] ¿Leí SesionHelper.vb?
- [ ] ¿Leí Site.Master?
- [ ] ¿Leí site.css?

### Si toca SQL:
- [ ] ¿Hice SELECT primero?
- [ ] ¿Prefijo `FLORERIA_`?
- [ ] ¿GO entre procedures?
- [ ] ¿Parameters (no concat)?

### Si toca .aspx:
- [ ] ¿MasterPageFile?
- [ ] ¿CodeBehind?
- [ ] ¿Inherits con namespace?
- [ ] ¿Íconos `ti ti-xxx`?

### Si toca .vb:
- [ ] ¿Partial Public Class?
- [ ] ¿NO inventé CargarMenu en Site.Master.vb?
- [ ] ¿Verifico Nothing?
- [ ] ¿Tipos explícitos?

### Si toca CSS:
- [ ] ¿NO modifiqué clases base?
- [ ] ¿Uso variables --rosa, --gris?

### Antes de declarar "funciona":
- [ ] ¿Vi la captura con detalle?
- [ ] ¿Bryan confirmó?
- [ ] ¿Sin errores en consola?
- [ ] ¿Sin errores en Output VS?

---

## 🚨 ERRORES COMUNES — CAUSA RAÍZ

| Error | Causa real | Solución |
|-------|-----------|----------|
| `expects parameter '@X'` | SP nuevo parámetro, VB no envía | Agregar Parameters en VB |
| `IndexOutOfRangeException: campo` | SP no retorna ese campo | Modificar SP, NO el VB |
| Menú sin íconos | Falta `ti ` antes de `ti-home` | Corregir BD o SesionHelper |
| Texto menú se ve mal | HTML no coincide con CSS | NO parchar CSS, ALINEAR HTML |
| `Could not load type X` | Inherits ≠ clase .vb | Igualar exactamente |
| Login en bucle | Site.Master.vb duplica lógica | Site.Master.vb MÍNIMO |

---

## 🎯 PROTOCOLO IA + BRYAN

### SIEMPRE:
1. Revisar GitHub primero
2. SELECT antes de modificar BD
3. Verificar capturas con detalle
4. Buscar causa raíz
5. UNA arquitectura

### NUNCA:
1. ❌ Generar sin consultar repo
2. ❌ Suponer contenido de tablas
3. ❌ Declarar "funciona" sin confirmar
4. ❌ Inventar lógica que ya existe
5. ❌ Tocar Site.Master.vb más allá de lo mínimo

---

**VERSIÓN:** 3.0 — Mayo 2026  
**REPO:** https://github.com/nayarbipsa/SISCONBOL_FLORERIA  
**ARQUITECTURA:** MasterPage + SesionHelper
