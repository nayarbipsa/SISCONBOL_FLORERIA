# ⚠️ VALIDACIONES - REGLA CRÍTICA OBLIGATORIA

**FECHA AGREGADA:** 2026-05-23  
**CAUSA:** Error imperdonable - permitir caracteres peligrosos en inputs

---

## 🔴 REGLA #1: TODA ENTRADA DE USUARIO DEBE VALIDARSE

**NUNCA confíes en datos del usuario. SIEMPRE validar en 3 capas:**

```
1. JavaScript (Frontend)  → Experiencia de usuario
2. VB.NET (Backend)       → Seguridad real
3. SQL Server (BD)        → Última línea de defensa
```

---

## 📚 ARQUITECTURA DE VALIDACIÓN

### **Archivos del Sistema:**

```
SISCONBOL_FLORERIA/
├── App_Code/
│   ├── SesionHelper.vb          ← Sesiones
│   └── Validador.vb              ← ⭐ NUEVO - Validaciones centralizadas
│
├── Scripts/
│   ├── site.js                   ← Funciones globales
│   └── validaciones.js           ← ⭐ NUEVO - Validaciones JS
│
└── 03_TODOS_LOS_SPS.sql
    └── FLORERIA_fn_ValidarTexto    ← ⭐ NUEVO - Función SQL
    └── FLORERIA_fn_ValidarCelular  ← ⭐ NUEVO - Función SQL
```

---

## ✅ CÓMO VALIDAR CORRECTAMENTE

### **1. En JavaScript (validaciones.js)**

```javascript
// ❌ MAL - Sin validación
function enviarFormulario() {
    document.getElementById('btnPostBack').click();
}

// ✅ BIEN - Con validación
function enviarFormulario() {
    var resultado = Validaciones.validarFormularioPrePedido();
    
    if (!resultado.valido) {
        Validaciones.marcarCampoInvalido(resultado.campo, resultado.mensaje);
        return;
    }
    
    document.getElementById('btnPostBack').click();
}
```

**Siempre incluir en HeadContent:**
```html
<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
    <script src="<%= ResolveUrl("~/Scripts/validaciones.js") %>" type="text/javascript"></script>
</asp:Content>
```

---

### **2. En VB.NET (Validador.vb)**

```vb
' ❌ MAL - Sin validación
Dim nombre As String = Request.Form("txNombre")
If nombre Is Nothing Then nombre = ""
nombre = nombre.Trim()

' ✅ BIEN - Con validación
Dim nombre As String = Request.Form("txNombre")
If nombre Is Nothing Then nombre = ""
nombre = nombre.Trim()

' Validar con clase Validador
Dim resultado = Validador.ValidarFormularioPrePedido(celular, nombre, apellidos, email)
If Not resultado.EsValido Then
    MensajeAlerta = resultado.Mensaje
    Return
End If
```

---

### **3. En SQL (Stored Procedures)**

```sql
-- ❌ MAL - Sin validación
CREATE PROCEDURE FLORERIA_sp_Algo
    @nombre VARCHAR(200)
AS
BEGIN
    INSERT INTO Tabla (nombre) VALUES (@nombre);
END;

-- ✅ BIEN - Con validación
CREATE PROCEDURE FLORERIA_sp_Algo
    @nombre VARCHAR(200)
AS
BEGIN
    -- Validar
    IF @nombre IS NOT NULL
    BEGIN
        IF @nombre LIKE '%[^a-zA-ZáéíóúÁÉÍÓÚñÑ ]%'
        BEGIN
            RAISERROR('El nombre solo puede contener letras', 16, 1);
            RETURN;
        END;

        IF dbo.FLORERIA_fn_ValidarTexto(@nombre) = 0
        BEGIN
            RAISERROR('El nombre contiene caracteres peligrosos', 16, 1);
            RETURN;
        END;
    END;

    INSERT INTO Tabla (nombre) VALUES (@nombre);
END;
```

---

## 🎯 FUNCIONES DISPONIBLES

### **JavaScript (Validaciones.js)**

```javascript
// Texto
Validaciones.esTextoValido(texto)           // Solo letras y espacios
Validaciones.esAlfanumericoValido(texto)    // Letras, números, espacios

// Celular
Validaciones.esCelularValido(celular)       // Formato válido
Validaciones.normalizarCelular(celular)     // Quitar formato

// Email
Validaciones.esEmailValido(email)           // Formato válido

// Seguridad
Validaciones.tienePatronPeligroso(texto)    // Detectar SQL injection/XSS

// UI
Validaciones.marcarCampoInvalido(id, msg)   // Marcar campo rojo
Validaciones.limpiarCampoInvalido(id)       // Limpiar marca

// Formularios completos
Validaciones.validarFormularioPrePedido()   // Pre-Pedido completo
```

---

### **VB.NET (Validador.vb)**

```vb
' Texto
Validador.EsTextoValido(texto)              ' Solo letras y espacios
Validador.EsAlfanumericoValido(texto)       ' Letras, números, espacios
Validador.LimpiarTexto(texto)               ' Remover caracteres peligrosos

' Celular
Validador.EsCelularValido(celular)          ' Formato válido
Validador.NormalizarCelular(celular)        ' Quitar formato

' Email
Validador.EsEmailValido(email)              ' Formato válido

' Números
Validador.EsEnteroValido(texto, valor)      ' Parsear entero
Validador.EsDecimalValido(texto, valor)     ' Parsear decimal

' Fechas
Validador.EsFechaValida(texto, fecha)       ' Parsear fecha
Validador.EsFechaFutura(fecha)              ' Validar fecha futura

' Seguridad
Validador.TienePatronPeligroso(texto)       ' Detectar SQL injection

' Formularios completos
Dim resultado = Validador.ValidarFormularioPrePedido(celular, nombre, apellidos, email)
If Not resultado.EsValido Then
    ' Manejar error
End If
```

---

### **SQL (Funciones)**

```sql
-- Validar texto genérico (detectar patrones peligrosos)
IF dbo.FLORERIA_fn_ValidarTexto(@texto) = 0
BEGIN
    RAISERROR('Texto contiene caracteres peligrosos', 16, 1);
    RETURN;
END;

-- Validar celular
IF dbo.FLORERIA_fn_ValidarCelular(@celular) = 0
BEGIN
    RAISERROR('Celular inválido', 16, 1);
    RETURN;
END;
```

---

## 🚨 PATRONES PELIGROSOS DETECTADOS

La clase `Validador` detecta automáticamente:

```
SQL Injection:
- DROP TABLE, DROP DATABASE
- DELETE FROM, INSERT INTO, UPDATE
- UNION SELECT, OR 1=1
- '; DROP, --, /*, */
- EXEC, EXECUTE, XP_, SP_

XSS (Cross-Site Scripting):
- <script>, </script>
- <, >, ', ", ;

Caracteres peligrosos genéricos:
- Símbolos no alfanuméricos raros
- Secuencias de comandos
```

---

## 📋 CHECKLIST OBLIGATORIO

Antes de crear CUALQUIER formulario:

- [ ] Incluir `validaciones.js` en HeadContent
- [ ] Validar en JavaScript antes de submit
- [ ] Validar en VB.NET con clase `Validador`
- [ ] Validar en SP con funciones SQL
- [ ] Probar ingresando: `'; DROP TABLE--`
- [ ] Probar ingresando: `<script>alert('xss')</script>`
- [ ] Probar ingresando: `)(/&%$#"`

Si alguno de estos pasa, **HAY UN ERROR GRAVE**.

---

## 🎯 EJEMPLOS COMPLETOS

### **Formulario de Pre-Pedido**

**JavaScript:**
```javascript
function enviarFormulario() {
    var resultado = Validaciones.validarFormularioPrePedido();
    if (!resultado.valido) {
        Validaciones.marcarCampoInvalido(resultado.campo, resultado.mensaje);
        return;
    }
    // Submit
}
```

**VB.NET:**
```vb
Private Sub CrearPrePedido()
    Dim celular As String = Request.Form("txCelular")
    Dim nombre As String = Request.Form("txNombre")
    
    ' Normalizar
    If celular Is Nothing Then celular = ""
    If nombre Is Nothing Then nombre = ""
    celular = celular.Trim()
    nombre = nombre.Trim()
    
    ' Validar
    Dim resultado = Validador.ValidarFormularioPrePedido(celular, nombre, "", "")
    If Not resultado.EsValido Then
        MensajeAlerta = resultado.Mensaje
        Return
    End If
    
    ' Continuar con lógica...
End Sub
```

**SQL:**
```sql
CREATE PROCEDURE FLORERIA_sp_PrePedido_Crear
    @cliente_celular VARCHAR(20),
    @cliente_nombre  VARCHAR(200)
AS
BEGIN
    -- Validar celular
    IF dbo.FLORERIA_fn_ValidarCelular(@cliente_celular) = 0
    BEGIN
        RAISERROR('Celular inválido', 16, 1);
        RETURN;
    END;
    
    -- Validar nombre
    IF @cliente_nombre IS NOT NULL
    BEGIN
        IF dbo.FLORERIA_fn_ValidarTexto(@cliente_nombre) = 0
        BEGIN
            RAISERROR('Nombre contiene caracteres peligrosos', 16, 1);
            RETURN;
        END;
    END;
    
    -- Insertar...
END;
```

---

## ⚠️ ERRORES COMUNES

| Error | Consecuencia | Solución |
|-------|--------------|----------|
| No validar en JavaScript | Mala UX - error hasta el servidor | Validar antes de submit |
| Solo validar en JavaScript | Inseguro - se puede saltar | Validar SIEMPRE en VB.NET |
| No validar en VB.NET | SQL Injection posible | Usar clase Validador |
| No validar en SQL | Basura en BD | Agregar validaciones en SP |
| Confiar en el usuario | Catástrofe | NUNCA confiar |

---

## 🏆 REGLA DE ORO

```
SI UN DATO VIENE DEL USUARIO → VALIDARLO
SI UN DATO VA A LA BD        → VALIDARLO
SI HAY DUDA                  → VALIDARLO
```

**NO HAY EXCEPCIONES.**

---

**FIN DE LA SECCIÓN DE VALIDACIONES**

Esta sección debe agregarse a `REGLAS_DEFINITIVAS_V3.md` como **Sección 11**.
