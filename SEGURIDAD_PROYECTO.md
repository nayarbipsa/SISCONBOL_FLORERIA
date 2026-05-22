# 🔒 SEGURIDAD DEL PROYECTO SISCONBOL_FLORERIA

**Fecha:** Mayo 2026  
**Versión:** 1.0

---

## 📋 ÍNDICE

1. [Capas de Seguridad Implementadas](#capas)
2. [Protección contra Ataques](#ataques)
3. [Control de Acceso](#acceso)
4. [Sesiones y Tokens](#sesiones)
5. [Validación de Datos](#validacion)
6. [Logging y Auditoría](#logging)
7. [Configuración de Producción](#produccion)
8. [Checklist de Seguridad](#checklist)

---

## <a name="capas"></a>🛡️ 1. CAPAS DE SEGURIDAD IMPLEMENTADAS

### **Capa 1: Global.asax (Nivel Aplicación)**
```
✅ Bloquea acceso a páginas sin sesión
✅ Protege carpetas sensibles (App_Code, bin, obj)
✅ Remueve headers que revelan tecnología
✅ Agrega headers de seguridad
✅ Manejo centralizado de errores
```

### **Capa 2: Web.config (Nivel Servidor)**
```
✅ Sesión con timeout de 30 minutos
✅ Autenticación por formularios
✅ CustomErrors habilitado
✅ Headers de seguridad (X-Frame-Options, etc.)
✅ Compresión GZIP
✅ Cache de archivos estáticos
```

### **Capa 3: Site.Master (Nivel Layout)**
```
✅ Verifica sesión en CADA request
✅ Usa SesionHelper.VerificarSesion()
✅ Redirige a Login si no válida
✅ Carga menú según permisos
```

### **Capa 4: Base de Datos (Nivel Datos)**
```
✅ Solo Stored Procedures (NO SQL directo)
✅ Parámetros en TODAS las consultas
✅ Intentos fallidos de login
✅ Bloqueo temporal (5 min) y permanente
✅ Auditoría de cambios críticos
✅ Tokens de sesión con expiración
```

---

## <a name="ataques"></a>⚔️ 2. PROTECCIÓN CONTRA ATAQUES

### **2.1 Ataques de Fuerza Bruta**

**IMPLEMENTADO:**
```sql
-- En FLORERIA_Usuario
intentos_fallidos TINYINT DEFAULT 0
bloqueado_hasta DATETIME NULL  -- Bloqueo temporal 5 min
bloqueado BIT DEFAULT 0         -- Bloqueo permanente

-- Reglas:
- 3 intentos fallidos → bloqueado_hasta = GETDATE() + 5 minutos
- 6+ intentos → bloqueado = 1 (requiere admin para desbloquear)
- Login exitoso → intentos_fallidos = 0
```

**Cómo funciona:**
1. Usuario ingresa credenciales incorrectas
2. `FLORERIA_sp_Login` incrementa `intentos_fallidos`
3. Al llegar a 3, establece `bloqueado_hasta`
4. Usuario no puede loguearse hasta que pasen 5 minutos
5. Si sigue intentando, al llegar a 6 se bloquea permanente

**RECOMENDACIÓN ADICIONAL:**
- Implementar CAPTCHA después de 2 intentos fallidos
- Agregar delay progresivo (1s, 2s, 4s, 8s...)

---

### **2.2 SQL Injection**

**PROTECCIÓN:**
```vb
' ❌ NUNCA HACER ESTO
Dim sql As String = "SELECT * FROM Usuario WHERE carnet='" & carnet & "'"

' ✅ SIEMPRE HACER ESTO
Using cmd As New SqlCommand("FLORERIA_sp_Login", conn)
    cmd.CommandType = CommandType.StoredProcedure
    cmd.Parameters.AddWithValue("@carnet", carnet)
    cmd.Parameters.AddWithValue("@password_hash", hash)
End Using
```

**REGLAS:**
1. ✅ **NUNCA** concatenar strings para consultas SQL
2. ✅ **SOLO** usar Stored Procedures
3. ✅ **SIEMPRE** usar parámetros (`@param`)
4. ✅ Validar y limpiar inputs en VB.NET antes de enviar a BD

---

### **2.3 Cross-Site Scripting (XSS)**

**PROTECCIÓN:**
```vb
' En VB.NET - Limpiar inputs
Private Function LimpiarInput(v As String) As String
    If v Is Nothing Then Return ""
    v = v.Trim()
    v = v.Replace("<", "").Replace(">", "")
    v = v.Replace("'", "").Replace("""", "")
    Return v
End Function

' En HTML - Encode al mostrar
sb.Append("<td>").Append(HttpUtility.HtmlEncode(nombre)).Append("</td>")
```

**HEADERS DE SEGURIDAD (Web.config):**
```xml
<add name="X-XSS-Protection" value="1; mode=block"/>
<add name="X-Content-Type-Options" value="nosniff"/>
```

---

### **2.4 Cross-Site Request Forgery (CSRF)**

**PROTECCIÓN PARCIAL:**
```vb
' En Login y páginas críticas, verificar origen del request
Dim referer As String = Request.ServerVariables("HTTP_REFERER")
If referer IsNot Nothing AndAlso Not referer.Contains(Request.Url.Host) Then
    ' Request viene de otro sitio - posible CSRF
    Return False
End If
```

**RECOMENDACIÓN:**
- Agregar token anti-CSRF en formularios críticos
- ViewState con MAC habilitado (ya está por defecto en .NET 4.8)

---

### **2.5 Session Hijacking**

**PROTECCIÓN:**
```vb
' Validar IP en cada request
Public Shared Function VerificarSesion(context As HttpContext) As Boolean
    ' ...
    cmd.Parameters.AddWithValue("@ip", context.Request.ServerVariables("REMOTE_ADDR"))
    ' Si la IP cambió, sesión inválida
End Function
```

**ADICIONAL:**
- Cookie con HttpOnly (evita acceso desde JavaScript)
- Regenerar token después de login
- Expiración de sesión a las 23:59:59 del día

---

### **2.6 Clickjacking**

**PROTECCIÓN (Web.config):**
```xml
<add name="X-Frame-Options" value="SAMEORIGIN"/>
```

Esto previene que tu sitio sea embebido en un iframe de otro dominio.

---

## <a name="acceso"></a>🚪 3. CONTROL DE ACCESO

### **3.1 Verificación de Sesión en CADA Página**

**Site.Master.vb:**
```vb
Protected Sub Page_Load(...)
    ' 1. SIEMPRE primero: verificar sesión
    If Not SesionHelper.VerificarSesion(HttpContext.Current) Then
        Response.Redirect("~/Login.aspx")
        Return
    End If
    ' ...
End Sub
```

**Global.asax (Respaldo):**
```vb
Sub Application_BeginRequest(...)
    ' Si intenta acceder a .aspx sin sesión → redirect Login
    If rutaActual.EndsWith(".aspx") AndAlso Not esPublica Then
        If Session("token") Is Nothing Then
            ' Verificar cookie...
        End If
    End If
End Sub
```

---

### **3.2 Control de Permisos por Página**

**FLORERIA_Usuario_Menu:**
- Cada usuario tiene permisos específicos por menú
- `puede_ver`, `puede_crear`, `puede_editar`, `puede_eliminar`
- Se valida en `FLORERIA_sp_CargarMenu`

**Uso en VB.NET:**
```vb
' En cada página que permite crear/editar/eliminar
Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
' Verificar permiso con SP antes de procesar
```

---

### **3.3 Páginas Públicas vs Privadas**

| Página | Requiere Sesión | Verifica en |
|---|---|---|
| Login.aspx | ❌ NO | — |
| Error.aspx | ❌ NO | — |
| CambiarPassword.aspx | ✅ SÍ | Code-behind |
| Default.aspx | ✅ SÍ | Site.Master |
| Todas en Modulos/* | ✅ SÍ | Site.Master |

---

## <a name="sesiones"></a>🎫 4. SESIONES Y TOKENS

### **4.1 Flujo de Sesión**

```
1. Usuario hace login → FLORERIA_sp_Login
2. SP valida credenciales, genera token (GUID doble)
3. Token se guarda en:
   - FLORERIA_Sesion (BD)
   - Session("token") (ASP.NET)
   - Cookie SISCONBOL_TOKEN (navegador, HttpOnly)
4. En cada request → SesionHelper.VerificarSesion()
   - Lee token de Session o Cookie
   - Valida contra BD (FLORERIA_sp_ValidarSesion)
   - Verifica IP, expiración, activa=1
5. Si válido → actualiza ultimo_acceso
6. Si inválido → redirect Login
```

### **4.2 Expiración de Token**

```sql
-- Tokens expiran a las 23:59:59 del día de creación
expira_en DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME) + '23:59:59'

-- Al validar:
IF GETDATE() > expira_en OR activa = 0
    RETURN 'Token expirado'
```

### **4.3 Cierre de Sesión**

```vb
' Site.Master.vb
Protected Sub btnCerrarSesion_Click(...)
    ' 1. Invalidar en BD
    FLORERIA_sp_CerrarSesion(@token)
    
    ' 2. Eliminar cookies
    Dim cookie As New HttpCookie("SISCONBOL_TOKEN", "")
    cookie.Expires = DateTime.Now.AddDays(-1)
    Response.Cookies.Add(cookie)
    
    ' 3. Abandonar Session
    Session.Abandon()
    
    ' 4. Redirect
    Response.Redirect("~/Login.aspx")
End Sub
```

---

## <a name="validacion"></a>✅ 5. VALIDACIÓN DE DATOS

### **5.1 Validación en Frontend (JavaScript)**

```javascript
// En Login.aspx
function validarLogin() {
    var carnet = obtenerValor('txCarnet', '');
    var pwd = obtenerValor('txPassword', '');
    
    if (!/^\d{7,8}$/.test(carnet)) {
        mostrarAlerta('Carnet debe ser 7-8 dígitos', 'error');
        return false;
    }
    
    if (pwd.length < 6) {
        mostrarAlerta('Contraseña mínimo 6 caracteres', 'error');
        return false;
    }
    
    return true;
}
```

### **5.2 Validación en Backend (VB.NET)**

```vb
' SIEMPRE validar en servidor (el cliente no es confiable)
Protected Sub btnLogin_Click(...)
    Dim carnet As String = Request.Form("hdCarnet")
    If carnet Is Nothing Then carnet = ""
    carnet = carnet.Trim()
    
    ' Validar formato
    If Not Regex.IsMatch(carnet, "^\d{7,8}$") Then
        Return
    End If
    
    ' Limpiar para prevenir XSS
    carnet = LimpiarInput(carnet)
    
    ' Procesar...
End Sub
```

### **5.3 Validación en Base de Datos**

```sql
CREATE PROCEDURE FLORERIA_sp_Login
    @carnet VARCHAR(20),
    @password_hash VARCHAR(200),
    ...
AS BEGIN
    -- Validar longitud
    IF LEN(@carnet) < 7 OR LEN(@carnet) > 8
        RETURN 'Carnet inválido'
    
    -- Validar que sea numérico
    IF @carnet NOT LIKE '[0-9]%'
        RETURN 'Carnet debe ser numérico'
    
    -- Procesar...
END
```

---

## <a name="logging"></a>📝 6. LOGGING Y AUDITORÍA

### **6.1 Auditoría de Cambios (FLORERIA_Auditoria)**

**Se auditan:**
- Creación/modificación/eliminación de usuarios
- Cambios de permisos
- Bloqueos/desbloqueos
- Cambios de contraseña
- Operaciones financieras (caja, pagos, liquidaciones)
- Modificaciones de productos/precios

**Estructura:**
```sql
INSERT INTO FLORERIA_Auditoria (
    usuario_id, tabla, registro_id, accion,
    valor_anterior, valor_nuevo, motivo, ip
) VALUES (...)
```

### **6.2 Logging de Errores**

**Error.aspx.vb:**
```vb
Private Sub RegistrarError(codigo As String)
    Dim mensajeLog As String = String.Format(
        "ERROR {0} | ID: {1} | Usuario: {2} | IP: {3} | ...",
        codigo, ErrorId, usuarioId, ip
    )
    
    System.Diagnostics.Debug.WriteLine(mensajeLog)
    ' TODO: Guardar en BD si es necesario
End Sub
```

### **6.3 Logging de Intentos de Login**

```sql
-- En FLORERIA_sp_Login
IF @password_hash <> u.password_hash
BEGIN
    -- Incrementar intentos fallidos
    UPDATE FLORERIA_Usuario 
    SET intentos_fallidos = intentos_fallidos + 1
    WHERE usuario_id = @uid
    
    -- Registrar en auditoría
    INSERT INTO FLORERIA_Auditoria (...)
END
```

---

## <a name="produccion"></a>🚀 7. CONFIGURACIÓN DE PRODUCCIÓN

### **7.1 Web.config - Producción**

```xml
<!-- CAMBIAR ANTES DE SUBIR A PRODUCCIÓN -->
<compilation debug="false" targetFramework="4.8"/>

<customErrors mode="On" defaultRedirect="~/Error.aspx">
  <error statusCode="403" redirect="~/Error.aspx?e=403"/>
  <error statusCode="404" redirect="~/Error.aspx?e=404"/>
  <error statusCode="500" redirect="~/Error.aspx?e=500"/>
</customErrors>

<!-- ACTIVAR HTTPS (cuando tengas certificado SSL) -->
<rewrite>
  <rules>
    <rule name="Redirect to HTTPS" stopProcessing="true">
      <match url="(.*)" />
      <conditions>
        <add input="{HTTPS}" pattern="off" />
      </conditions>
      <action type="Redirect" url="https://{HTTP_HOST}/{R:1}" redirectType="Permanent" />
    </rule>
  </rules>
</rewrite>
```

### **7.2 Somee.com - Configuración Específica**

**Connection String:**
```xml
<add name="SISCONBOL" 
     connectionString="workstation id=SISCONBOL.mssql.somee.com;
                       packet size=4096;
                       user id=usuariofloreria;
                       pwd=TU_PASSWORD_REAL_AQUI;
                       data source=SISCONBOL.mssql.somee.com;
                       persist security info=False;
                       initial catalog=SISCONBOL" 
     providerName="System.Data.SqlClient"/>
```

**IMPORTANTE:**
- ❌ NO subir a GitHub con la contraseña real
- ✅ Usar variables de entorno o archivo separado
- ✅ Agregar `.gitignore` con `Web.config`

---

## <a name="checklist"></a>✅ 8. CHECKLIST DE SEGURIDAD

### **Antes de subir a producción:**

**Configuración:**
- [ ] `debug="false"` en Web.config
- [ ] `customErrors mode="On"`
- [ ] Password de BD actualizada (no la de prueba)
- [ ] HTTPS configurado y funcionando
- [ ] Headers de seguridad verificados

**Código:**
- [ ] TODAS las consultas usan Stored Procedures
- [ ] TODOS los inputs se limpian con `LimpiarInput()`
- [ ] TODAS las salidas se encodean con `HttpUtility.HtmlEncode()`
- [ ] Verificación de sesión en TODAS las páginas

**Base de Datos:**
- [ ] Bloqueo por intentos fallidos funcionando
- [ ] Auditoría activada en tablas críticas
- [ ] Tokens con expiración correcta
- [ ] Permisos de menú configurados

**Testing:**
- [ ] Probar login con credenciales incorrectas (verificar bloqueo)
- [ ] Intentar acceder a páginas sin sesión
- [ ] Verificar que cookies sean HttpOnly
- [ ] Probar cierre de sesión
- [ ] Verificar redirección a Login al expirar sesión

---

## 📊 RESUMEN DE SEGURIDAD

| Amenaza | Protección | Estado |
|---|---|---|
| Fuerza Bruta | Bloqueo temporal/permanente | ✅ IMPLEMENTADO |
| SQL Injection | Solo SPs + parámetros | ✅ IMPLEMENTADO |
| XSS | Limpiar input + encode output | ✅ IMPLEMENTADO |
| CSRF | Validar referer | ⚠️ PARCIAL |
| Session Hijacking | Validar IP + token | ✅ IMPLEMENTADO |
| Clickjacking | X-Frame-Options | ✅ IMPLEMENTADO |
| Acceso no autorizado | Verificación en cada request | ✅ IMPLEMENTADO |

---

## 🎯 RECOMENDACIONES ADICIONALES

1. **CAPTCHA:** Agregar después de 2 intentos fallidos
2. **2FA:** Implementar autenticación de dos factores (SMS/Email)
3. **Rate Limiting:** Limitar requests por IP (prevenir DoS)
4. **WAF:** Considerar Web Application Firewall (Cloudflare)
5. **Pentesting:** Contratar pruebas de penetración profesionales
6. **Monitoreo:** Implementar alertas de actividad sospechosa
7. **Backups:** Backups automáticos diarios de BD

---

**Última actualización:** Mayo 2026  
**Responsable:** Equipo de Desarrollo SISCONBOL
