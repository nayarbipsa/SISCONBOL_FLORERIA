# 🎯 SISCONBOL - Módulo Creación de Pre-Pedido

**Fecha:** 2026-05-23  
**Módulo:** Modulos/Pedidos/PrePedido_Crear.aspx  
**Estado:** ✅ REESCRITO CON ARQUITECTURA MASTERPAGE CORRECTA

---

## 📋 CAMBIOS REALIZADOS

### ❌ ANTES (INCORRECTO)
```
- Página SIN MasterPage (layout completo duplicado)
- Verificación manual de sesión en Page_Load
- Generación manual de menú (MenuHtml)
- Manejo manual de cierre de sesión
- CSS duplicado (400+ líneas inline)
- JavaScript duplicado (sidebar, menú, sesión)
- CodeFile en vez de CodeBehind
- Inherits sin namespace completo
```

### ✅ DESPUÉS (CORRECTO)
```
- Página CON Site.Master
- NO verifica sesión (lo hace Site.Master)
- NO genera menú (lo hace Site.Master)
- NO maneja cierre sesión (lo hace Site.Master)
- CSS mínimo específico (solo estilos de país badge)
- JavaScript específico (solo detección país + submit)
- CodeBehind correcto
- Inherits con namespace: SISCONBOL_FLORERIA.Modulos_Pedidos_PrePedido_Crear
```

---

## 📂 ESTRUCTURA DE ARCHIVOS

### PrePedido_Crear.aspx
```aspx
<%@ Page Title="Crear Pre-Pedido" 
         Language="VB" 
         MasterPageFile="~/Site.Master" 
         AutoEventWireup="false" 
         CodeBehind="PrePedido_Crear.aspx.vb" 
         Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_PrePedido_Crear" %>

<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
    <!-- Solo CSS específico de esta página -->
</asp:Content>

<asp:Content ID="ContentTitle" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-shopping-cart-plus"></i> Crear Pre-Pedido
</asp:Content>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">
    <!-- Formulario -->
</asp:Content>

<asp:Content ID="ContentScripts" ContentPlaceHolderID="ScriptsContent" runat="server">
    <!-- Solo JS específico de esta página -->
</asp:Content>
```

### PrePedido_Crear.aspx.vb
```vb
Partial Public Class Modulos_Pedidos_PrePedido_Crear
    Inherits System.Web.UI.Page

    ' Propiedades públicas para binding
    Public Property MensajeAlerta As String = ""
    Public Property ValorCelular As String = ""
    Public Property ValorNombre As String = ""
    Public Property ValorApellidos As String = ""
    Public Property ValorEmail As String = ""

    ' Page_Load - NO verifica sesión (lo hace Site.Master)
    Protected Sub Page_Load(...)
        ' Solo lógica de negocio
    End Sub

    ' Manejador de acción
    Protected Sub btnAccion_Click(...)
        Dim accion As String = Request.Form("hdAccion")
        If accion = "CREAR" Then
            CrearPrePedido()
        End If
    End Sub

    ' Lógica específica
    Private Sub CrearPrePedido()
        ' 1. Leer formulario
        ' 2. Validar
        ' 3. Llamar SP: FLORERIA_sp_PrePedido_Crear
        ' 4. Llamar SP: FLORERIA_sp_PrePedido_ActualizarCliente
        ' 5. Mostrar mensaje
    End Sub
End Class
```

---

## 🎨 CLASES CSS USADAS (de site.css)

### Estructura
- `.panel` - Contenedor blanco con borde
- `.panel-head` - Header del panel
- `.panel-title` - Título con ícono
- `.panel-body` - Cuerpo del panel

### Formulario
- `.form-group` - Contenedor de campo
- `.form-label` - Etiqueta del campo
- `.form-label-required` - Etiqueta con asterisco rojo
- `.form-control` - Input/select estilizado
- `.form-help` - Texto de ayuda gris pequeño

### Layout
- `.grid-2` - Grid de 2 columnas responsive

### Botones
- `.btn` - Botón base
- `.btn-primary` - Botón rosa principal

### Alertas
- `.alerta` - Contenedor alerta (hidden por defecto)
- `.alerta.show` - Mostrar alerta
- `.alerta-success` - Alerta verde
- `.alerta-error` - Alerta roja

### Específicas de esta página
- `.pais-badge` - Badge de país detectado
- `.pais-bolivia` - Badge amarillo Bolivia
- `.pais-peru` - Badge rojo Perú
- `.pais-intl` - Badge azul Internacional

---

## 🔧 STORED PROCEDURES USADOS

### 1. FLORERIA_sp_PrePedido_Crear
**Parámetros IN:**
- `@tipo_registro` VARCHAR(20) - 'PRE_PEDIDO', 'VENTA_TIENDA', 'VENTA_ANTIGUA'
- `@cliente_celular` VARCHAR(20) - Teléfono del cliente
- `@agente_id` INT - Usuario que crea
- `@ip` VARCHAR(50) - IP del cliente

**Parámetros OUT:**
- `@prepedido_id` INT - ID generado
- `@codigo` VARCHAR(20) - Código PRE-000001

**Lógica:**
1. Verifica que no exista pre-pedido activo para ese celular
2. Genera código secuencial PRE-000001
3. Define estado según tipo_registro
4. Inserta registro base
5. Retorna ID y código

### 2. FLORERIA_sp_PrePedido_ActualizarCliente
**Parámetros IN:**
- `@prepedido_id` INT
- `@cliente_nombre` VARCHAR(200) - Nullable
- `@cliente_apellidos` VARCHAR(200) - Nullable
- `@cliente_email` VARCHAR(100) - Nullable
- `@cliente_pais_id` SMALLINT - Nullable
- `@cliente_ciudad_id` SMALLINT - Nullable
- `@modificado_por` INT
- `@ip` VARCHAR(50)

**Lógica:**
1. Actualiza campos opcionales del cliente
2. Registra modificación en auditoría

---

## 📊 FLUJO DE DATOS

```
Usuario ingresa datos
    ↓
JavaScript detectarPais()
    ↓ (actualiza hdPaisId)
Usuario click "Crear Pre-Pedido"
    ↓
JavaScript enviarFormulario()
    ↓ (valida celular)
    ↓ (hdAccion = "CREAR")
PostBack → btnAccion_Click
    ↓
CrearPrePedido()
    ↓
Leer Request.Form
    ↓
Normalizar nulls y trim
    ↓
Validar celular obligatorio
    ↓
Detectar país (fallback VB si JS falló)
    ↓
SP: FLORERIA_sp_PrePedido_Crear
    ↓ (retorna ID y código)
SP: FLORERIA_sp_PrePedido_ActualizarCliente
    ↓
Éxito: Mensaje + limpiar formulario
Error: Mensaje + mantener valores
```

---

## 🔍 DETECCIÓN DE PAÍS

### JavaScript (Preferido)
```javascript
function detectarPais() {
    var tel = input.value.trim().replace(/[\s\-()]/g, '');
    
    // Bolivia: +591 o números que empiezan con 6/7
    if (tel.match(/^\+?591\d{7,8}$/)) → paisId = 1
    if (tel.match(/^[67]\d{6,7}$/)) → paisId = 1
    
    // Peru: +51 seguido de 9 dígitos
    if (tel.match(/^\+?51\d{9}$/)) → paisId = 2
    
    // Internacional: +código país + número
    if (tel.match(/^\+\d{1,4}\d{7,15}$/)) → paisId = ''
}
```

### VB.NET (Fallback)
```vb
If celular.StartsWith("+591") OrElse celular.StartsWith("591") Then
    paisId = 1
ElseIf celular.StartsWith("+51") OrElse celular.StartsWith("51") Then
    paisId = 2
ElseIf (celular.StartsWith("6") OrElse celular.StartsWith("7")) AndAlso _
       (celular.Length = 7 OrElse celular.Length = 8) Then
    paisId = 1
End If
```

---

## ✅ CHECKLIST CUMPLIDO

- [x] MasterPageFile="~/Site.Master"
- [x] CodeBehind (NO CodeFile)
- [x] Inherits con namespace completo
- [x] Partial Public Class
- [x] NO verifica sesión manualmente
- [x] NO genera menú manualmente
- [x] NO maneja cierre sesión manualmente
- [x] Solo CSS específico en HeadContent
- [x] Solo JS específico en ScriptsContent
- [x] Usa clases de site.css
- [x] Hidden fields dentro MainContent
- [x] asp:Button con OnClick
- [x] JavaScript con // @ts-nocheck
- [x] Verificar null antes de usar
- [x] Solo var (no const/let)
- [x] Tipar parámetros con JSDoc
- [x] Castear HTMLInputElement
- [x] Stored Procedures (NO SQL directo)
- [x] DBNull.Value para campos opcionales

---

## 🎯 PRÓXIMOS PASOS

### 1. Lista de Pre-Pedidos
- Modulos/Pedidos/PrePedido_Lista.aspx
- Tabla con filtros (estado, fecha, celular)
- Paginación
- Acciones: Ver detalle, Generar link, Eliminar

### 2. Detalle de Pre-Pedido
- Modulos/Pedidos/PrePedido_Detalle.aspx
- Ver/editar datos cliente
- Agregar productos/variaciones
- Generar link web
- Crear pedidos (entregas)
- Ver pagos

### 3. Generación de Link
- SP: FLORERIA_sp_PrePedido_GenerarLink
- Generar token único
- Copiar link al portapapeles
- Enviar por WhatsApp

### 4. Agregar Productos
- Modal para buscar productos
- Seleccionar variación
- Especificar cantidad
- Precio unitario (Bs/USD)
- Personalización (texto tarjeta)

### 5. Crear Pedidos desde Pre-Pedido
- Formulario para cada entrega
- Datos receptor
- Dirección + mapa
- Fecha + horario
- Tarjeta + dedicatoria
- Calcular envío

---

## 🐛 ERRORES COMUNES A EVITAR

| Error | Causa Raíz | Solución |
|-------|------------|----------|
| Layout duplicado | Olvidar MasterPageFile | Siempre usar Site.Master |
| Sesión no verificada | Page_Load sin verificar | Site.Master ya lo hace |
| Menú no aparece | Olvidar MenuHtml | Site.Master lo genera |
| CSS no aplicado | CSS inline en página | Usar clases de site.css |
| JS no funciona | Duplicar funciones de site.js | Solo JS específico |
| Namespace incorrecto | Inherits sin namespace | SISCONBOL_FLORERIA.NombreClase |
| Null reference | No verificar null | Siempre verificar antes de usar |
| SQL directo | Concatenar SQL | Solo Stored Procedures |

---

## 📝 NOTAS IMPORTANTES

1. **NUNCA** agregar verificación de sesión en páginas con MasterPage
2. **NUNCA** generar menú manualmente - usa Site.Master
3. **NUNCA** copiar CSS de site.css - referéncialo
4. **NUNCA** usar SQL directo - solo SPs
5. **SIEMPRE** verificar null antes de usar
6. **SIEMPRE** usar DBNull.Value para campos opcionales
7. **SIEMPRE** CodeBehind (NUNCA CodeFile)
8. **SIEMPRE** Inherits con namespace completo

---

**FIN DEL DOCUMENTO**
**Autor:** Claude + Bryan
**Última actualización:** 2026-05-23
