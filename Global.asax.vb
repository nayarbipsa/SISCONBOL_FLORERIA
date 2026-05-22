Imports System.Data.SqlClient
Imports System.Web
Imports System.Web.SessionState

Public Class Global_asax
    Inherits HttpApplication

    ' =====================================================
    ' INICIO DE APLICACIÓN
    ' =====================================================
    Sub Application_Start(sender As Object, e As EventArgs)
        ' Se ejecuta UNA VEZ al iniciar la aplicación
        ' Aquí puedes inicializar configuraciones globales
    End Sub

    ' =====================================================
    ' INICIO DE SESIÓN
    ' =====================================================
    Sub Session_Start(sender As Object, e As EventArgs)
        ' Se ejecuta cada vez que un usuario inicia una sesión nueva
        ' Intentar restaurar sesión desde cookie si existe
        Try
            Dim cookie As HttpCookie = Request.Cookies("SISCONBOL_TOKEN")
            If cookie IsNot Nothing AndAlso cookie.Value <> "" Then
                ' Validar token contra BD
                Dim token As String = cookie.Value
                Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
                If ip Is Nothing Then ip = ""

                Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                    conn.Open()
                    Using cmd As New SqlCommand("FLORERIA_sp_ValidarSesion", conn)
                        cmd.CommandType = Data.CommandType.StoredProcedure
                        cmd.Parameters.AddWithValue("@token", token)
                        cmd.Parameters.AddWithValue("@ip", ip)
                        Using dr As SqlDataReader = cmd.ExecuteReader()
                            If dr.Read() Then
                                Dim valida As Boolean = CBool(dr("valida"))
                                If valida Then
                                    ' Restaurar datos en Session
                                    Session("token") = token
                                    Dim uidObj As Object = dr("usuario_id")
                                    If uidObj IsNot Nothing AndAlso Not IsDBNull(uidObj) Then
                                        Dim uid As Integer = CInt(uidObj)
                                        ' Cargar datos del usuario
                                        CargarDatosUsuario(uid)
                                    End If
                                End If
                            End If
                        End Using
                    End Using
                End Using
            End If
        Catch ex As Exception
            ' Log error pero no interrumpir
            System.Diagnostics.Debug.WriteLine("Error Session_Start: " & ex.Message)
        End Try
    End Sub

    ' =====================================================
    ' FIN DE SESIÓN
    ' =====================================================
    Sub Session_End(sender As Object, e As EventArgs)
        ' Se ejecuta cuando expira la sesión (no cuando el usuario cierra el navegador)
        ' Marcar sesión como inactiva en BD si existe token
        Try
            If Session("token") IsNot Nothing Then
                Dim token As String = Session("token").ToString()
                Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                    conn.Open()
                    Using cmd As New SqlCommand("FLORERIA_sp_CerrarSesion", conn)
                        cmd.CommandType = Data.CommandType.StoredProcedure
                        cmd.Parameters.AddWithValue("@token", token)
                        cmd.ExecuteNonQuery()
                    End Using
                End Using
            End If
        Catch ex As Exception
            ' Log error pero no interrumpir
            System.Diagnostics.Debug.WriteLine("Error Session_End: " & ex.Message)
        End Try
    End Sub

    ' =====================================================
    ' ERROR NO CONTROLADO
    ' =====================================================
    Sub Application_Error(sender As Object, e As EventArgs)
        ' Se ejecuta cuando ocurre un error no controlado en la aplicación
        Dim ex As Exception = Server.GetLastError()

        If ex Is Nothing Then Return

        ' Obtener información del error
        Dim errorMessage As String = ex.Message
        Dim errorStack As String = ex.StackTrace
        Dim errorUrl As String = Request.Url.ToString()
        Dim errorType As String = ex.GetType().ToString()

        ' Log en archivo (opcional)
        Try
            LogErrorToFile(errorType, errorMessage, errorStack, errorUrl)
        Catch
            ' Si falla el log, no hacer nada
        End Try

        ' Log en base de datos (si hay sesión)
        Try
            LogErrorToDatabase(errorType, errorMessage, errorStack, errorUrl)
        Catch
            ' Si falla el log, no hacer nada
        End Try

        ' Limpiar error para evitar la página amarilla de ASP.NET
        Server.ClearError()

        ' Redirigir a página de error amigable
        If Not Response.IsRequestBeingRedirected Then
            Response.Redirect("~/Error.aspx?e=500", False)
        End If
    End Sub

    ' =====================================================
    ' HELPERS PRIVADOS
    ' =====================================================

    Private Sub CargarDatosUsuario(uid As Integer)
        Try
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Usuario_ObtenerPorId", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@usuario_id", uid)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Session("usuario_id") = uid
                            Session("nombres") = dr("nombres").ToString()
                            Session("apellidos") = dr("apellidos").ToString()
                            Session("tipo_id") = CInt(dr("tipo_id"))
                            Session("tipo_nombre") = dr("tipo_nombre").ToString()
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Error CargarDatosUsuario: " & ex.Message)
        End Try
    End Sub

    Private Sub LogErrorToFile(errorType As String, errorMessage As String, errorStack As String, errorUrl As String)
        ' Crear carpeta Logs si no existe
        Dim logFolder As String = Server.MapPath("~/App_Data/Logs")
        If Not System.IO.Directory.Exists(logFolder) Then
            System.IO.Directory.CreateDirectory(logFolder)
        End If

        ' Crear archivo de log con fecha
        Dim logFile As String = System.IO.Path.Combine(logFolder, "Error_" & DateTime.Now.ToString("yyyyMMdd") & ".txt")

        ' Escribir error
        Dim sb As New System.Text.StringBuilder()
        sb.AppendLine("====================================")
        sb.AppendLine("FECHA: " & DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"))
        sb.AppendLine("TIPO: " & errorType)
        sb.AppendLine("URL: " & errorUrl)
        sb.AppendLine("MENSAJE: " & errorMessage)
        sb.AppendLine("STACK:")
        sb.AppendLine(errorStack)
        sb.AppendLine("====================================")
        sb.AppendLine("")

        System.IO.File.AppendAllText(logFile, sb.ToString())
    End Sub

    Private Sub LogErrorToDatabase(errorType As String, errorMessage As String, errorStack As String, errorUrl As String)
        ' Obtener datos del usuario si está logueado
        Dim usuarioId As Integer = 0
        Dim usuarioNombre As String = "Anónimo"
        Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
        If ip Is Nothing Then ip = ""

        If Session("usuario_id") IsNot Nothing Then
            usuarioId = CInt(Session("usuario_id"))
            Dim nombres As String = If(Session("nombres") IsNot Nothing, Session("nombres").ToString(), "")
            Dim apellidos As String = If(Session("apellidos") IsNot Nothing, Session("apellidos").ToString(), "")
            usuarioNombre = nombres & " " & apellidos
        End If

        ' Insertar en tabla de errores (crear tabla FLORERIA_ErrorLog si no existe)
        ' TODO: Implementar cuando exista la tabla en BD

        ' Por ahora solo loguear en Debug
        System.Diagnostics.Debug.WriteLine("ERROR GLOBAL: " & errorType & " - " & errorMessage)
    End Sub

End Class
