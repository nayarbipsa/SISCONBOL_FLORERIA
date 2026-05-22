Imports System.Web

Partial Public Class ErrorPage
    Inherits System.Web.UI.Page

    ' Propiedades públicas para la vista
    Public Property CodigoError As String = "500"
    Public Property TituloError As String = "Error del servidor"
    Public Property MensajeError As String = "Ha ocurrido un error inesperado."
    Public Property IconClass As String = "e500"
    Public Property IconoTabler As String = "ti ti-alert-triangle"
    Public Property ErrorId As String = ""
    Public Property FechaError As String = ""
    Public Property MostrarDetalles As Boolean = False

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' Obtener código de error desde query string
        Dim codigoParam As String = Request.QueryString("e")
        If String.IsNullOrEmpty(codigoParam) Then
            codigoParam = "500"
        End If

        ' Generar ID único del error
        ErrorId = Guid.NewGuid().ToString("N").Substring(0, 8).ToUpper()
        FechaError = DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss")

        ' Determinar si mostrar detalles (solo en desarrollo)
        ' En producción, cambiar esto a False
        MostrarDetalles = (HttpContext.Current.Request.Url.Host = "localhost" OrElse
                          HttpContext.Current.Request.Url.Host = "127.0.0.1")

        ' Configurar mensajes según el código de error
        Select Case codigoParam
            Case "403"
                ConfigurarError403()
            Case "404"
                ConfigurarError404()
            Case "500"
                ConfigurarError500()
            Case Else
                ConfigurarErrorGenerico()
        End Select

        ' Registrar el error en el log
        RegistrarError(codigoParam)

        ' Establecer código de respuesta HTTP
        Try
            Response.StatusCode = Integer.Parse(codigoParam)
        Catch
            Response.StatusCode = 500
        End Try
    End Sub

    Private Sub ConfigurarError403()
        CodigoError = "403"
        TituloError = "Acceso denegado"
        MensajeError = "No tienes permisos suficientes para acceder a este recurso. Si crees que esto es un error, contacta al administrador del sistema."
        IconClass = "e403"
        IconoTabler = "ti ti-lock"
    End Sub

    Private Sub ConfigurarError404()
        CodigoError = "404"
        TituloError = "Página no encontrada"
        MensajeError = "La página que buscas no existe o ha sido movida. Verifica la URL o usa el menú de navegación para encontrar lo que necesitas."
        IconClass = "e404"
        IconoTabler = "ti ti-error-404"
    End Sub

    Private Sub ConfigurarError500()
        CodigoError = "500"
        TituloError = "Error del servidor"
        MensajeError = "Ha ocurrido un error inesperado en el servidor. Nuestro equipo ha sido notificado y estamos trabajando para solucionarlo."
        IconClass = "e500"
        IconoTabler = "ti ti-alert-triangle"
    End Sub

    Private Sub ConfigurarErrorGenerico()
        CodigoError = "Error"
        TituloError = "Algo salió mal"
        MensajeError = "Ha ocurrido un error inesperado. Por favor, intenta nuevamente más tarde."
        IconClass = "e500"
        IconoTabler = "ti ti-alert-circle"
    End Sub

    Private Sub RegistrarError(codigo As String)
        Try
            ' Obtener información del contexto
            Dim urlOriginal As String = If(Request.UrlReferrer IsNot Nothing, Request.UrlReferrer.ToString(), "Desconocida")
            Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
            Dim userAgent As String = Request.ServerVariables("HTTP_USER_AGENT")
            
            If String.IsNullOrEmpty(ip) Then ip = "N/A"
            If String.IsNullOrEmpty(userAgent) Then userAgent = "N/A"

            ' Obtener usuario si está en sesión
            Dim usuarioId As String = "N/A"
            If Session("usuario_id") IsNot Nothing Then
                usuarioId = Session("usuario_id").ToString()
            End If

            ' Log completo del error
            Dim mensajeLog As String = String.Format(
                "ERROR {0} | ID: {1} | Usuario: {2} | IP: {3} | URL Origen: {4} | UserAgent: {5} | Fecha: {6}",
                codigo,
                ErrorId,
                usuarioId,
                ip,
                urlOriginal,
                userAgent,
                FechaError
            )

            ' Escribir en Debug (aparece en Output de Visual Studio)
            System.Diagnostics.Debug.WriteLine("═══════════════════════════════════════")
            System.Diagnostics.Debug.WriteLine(mensajeLog)
            System.Diagnostics.Debug.WriteLine("═══════════════════════════════════════")

            ' TODO: Aquí puedes agregar logging a BD si lo necesitas
            ' RegistrarErrorEnBD(codigo, ErrorId, usuarioId, ip, urlOriginal, userAgent)

        Catch ex As Exception
            ' Si falla el logging, no hacer nada para no generar más errores
            System.Diagnostics.Debug.WriteLine("ERROR AL REGISTRAR ERROR: " & ex.Message)
        End Try
    End Sub

    ' Método opcional para registrar en BD
    ' Private Sub RegistrarErrorEnBD(codigo As String, errorId As String, usuarioId As String, ip As String, urlOrigen As String, userAgent As String)
    '     Try
    '         Using conn As New SqlConnection(System.Configuration.ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
    '             conn.Open()
    '             Using cmd As New SqlCommand("FLORERIA_sp_Registrar_Error", conn)
    '                 cmd.CommandType = CommandType.StoredProcedure
    '                 cmd.Parameters.AddWithValue("@codigo", codigo)
    '                 cmd.Parameters.AddWithValue("@error_id", errorId)
    '                 cmd.Parameters.AddWithValue("@usuario_id", If(usuarioId = "N/A", DBNull.Value, CInt(usuarioId)))
    '                 cmd.Parameters.AddWithValue("@ip", ip)
    '                 cmd.Parameters.AddWithValue("@url_origen", urlOrigen)
    '                 cmd.Parameters.AddWithValue("@user_agent", userAgent)
    '                 cmd.ExecuteNonQuery()
    '             End Using
    '         End Using
    '     Catch ex As Exception
    '         System.Diagnostics.Debug.WriteLine("ERROR AL GUARDAR EN BD: " & ex.Message)
    '     End Try
    ' End Sub

End Class
