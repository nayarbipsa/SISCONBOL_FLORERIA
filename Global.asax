<%@ Application Language="VB" %>
<%@ Import Namespace="System.Web.Routing" %>

<script runat="server">

    Sub Application_Start(sender As Object, e As EventArgs)
        ' Código que se ejecuta al iniciar la aplicación
        RegisterRoutes(RouteTable.Routes)
    End Sub
    
    Sub RegisterRoutes(routes As RouteCollection)
        ' Registrar rutas personalizadas si es necesario
    End Sub
    
    Sub Application_BeginRequest(sender As Object, e As EventArgs)
        ' ==========================================================
        ' SEGURIDAD: Verificar acceso a páginas protegidas
        ' ==========================================================
        
        Dim rutaActual As String = Request.Path.ToLower()
        
        ' Páginas públicas (sin autenticación)
        Dim paginasPublicas As String() = {
            "/login.aspx",
            "/error.aspx",
            "/estilos/",
            "/scripts/",
            "/imagenes/"
        }
        
        ' Verificar si es una página pública
        Dim esPublica As Boolean = False
        For Each pagina In paginasPublicas
            If rutaActual.Contains(pagina) Then
                esPublica = True
                Exit For
            End If
        Next
        
        ' Si es una página .aspx protegida, verificar sesión
        If rutaActual.EndsWith(".aspx") AndAlso Not esPublica Then
            ' Verificar que tenga sesión o cookie válida
            If Session("token") Is Nothing Then
                Dim cookie As HttpCookie = Request.Cookies("SISCONBOL_TOKEN")
                If cookie Is Nothing OrElse String.IsNullOrEmpty(cookie.Value) Then
                    ' No tiene sesión ni cookie válida
                    Response.Redirect("~/Login.aspx", True)
                    Return
                End If
            End If
        End If
        
        ' ==========================================================
        ' SEGURIDAD: Prevenir acceso directo a carpetas
        ' ==========================================================
        
        ' Bloquear acceso a App_Code, App_Data, bin, obj
        Dim carpetasBloqueadas As String() = {
            "/app_code/",
            "/app_data/",
            "/bin/",
            "/obj/"
        }
        
        For Each carpeta In carpetasBloqueadas
            If rutaActual.Contains(carpeta) Then
                Response.StatusCode = 403
                Response.End()
                Return
            End If
        Next
        
        ' ==========================================================
        ' SEGURIDAD: Headers de seguridad adicionales
        ' ==========================================================
        
        ' Remover headers que revelan información del servidor
        Response.Headers.Remove("Server")
        Response.Headers.Remove("X-AspNet-Version")
        Response.Headers.Remove("X-AspNetMvc-Version")
        
        ' Agregar headers de seguridad (si no están en Web.config)
        If String.IsNullOrEmpty(Response.Headers("X-Frame-Options")) Then
            Response.Headers.Add("X-Frame-Options", "SAMEORIGIN")
        End If
        
        If String.IsNullOrEmpty(Response.Headers("X-Content-Type-Options")) Then
            Response.Headers.Add("X-Content-Type-Options", "nosniff")
        End If
        
        If String.IsNullOrEmpty(Response.Headers("X-XSS-Protection")) Then
            Response.Headers.Add("X-XSS-Protection", "1; mode=block")
        End If
    End Sub

    Sub Application_AuthenticateRequest(sender As Object, e As EventArgs)
        ' Código que se ejecuta al autenticar una solicitud
    End Sub

    Sub Application_Error(sender As Object, e As EventArgs)
        ' ==========================================================
        ' MANEJO CENTRALIZADO DE ERRORES
        ' ==========================================================
        
        Dim lastError As Exception = Server.GetLastError()
        
        If lastError IsNot Nothing Then
            ' Registrar el error en el log de debug
            System.Diagnostics.Debug.WriteLine("ERROR GLOBAL: " & lastError.Message)
            System.Diagnostics.Debug.WriteLine("STACK: " & lastError.StackTrace)
            
            ' Limpiar el error para que no se muestre al usuario
            Server.ClearError()
            
            ' Determinar el código de error
            Dim httpError As HttpException = TryCast(lastError, HttpException)
            Dim codigoError As Integer = 500
            
            If httpError IsNot Nothing Then
                codigoError = httpError.GetHttpCode()
            End If
            
            ' Redirigir a página de error personalizada
            Select Case codigoError
                Case 403
                    Response.Redirect("~/Error.aspx?e=403", False)
                Case 404
                    Response.Redirect("~/Error.aspx?e=404", False)
                Case Else
                    Response.Redirect("~/Error.aspx?e=500", False)
            End Select
        End If
    End Sub

    Sub Session_Start(sender As Object, e As EventArgs)
        ' ==========================================================
        ' INICIALIZACIÓN DE SESIÓN
        ' ==========================================================
        
        ' Configurar tiempo de expiración (30 minutos)
        Session.Timeout = 30
        
        ' Registrar IP y User Agent para seguimiento
        Session("ip_inicial") = Request.ServerVariables("REMOTE_ADDR")
        Session("user_agent_inicial") = Request.ServerVariables("HTTP_USER_AGENT")
    End Sub

    Sub Session_End(sender As Object, e As EventArgs)
        ' ==========================================================
        ' LIMPIEZA AL EXPIRAR SESIÓN
        ' ==========================================================
        
        ' Nota: Este evento solo se ejecuta en modo InProc
        ' Para sesiones en BD o StateServer, usar otro mecanismo
        
        ' Aquí podrías cerrar la sesión en BD si el token está en Session
        ' Pero en InProc no tienes acceso a HttpContext, así que esto
        ' se maneja mejor en SesionHelper.VerificarSesion()
    End Sub

</script>
