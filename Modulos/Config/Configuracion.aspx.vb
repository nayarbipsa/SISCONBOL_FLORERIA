Imports System.Data
Imports System.Data.SqlClient
Imports System.Net
Imports System.IO
Imports System.Web
Imports System.Text

Partial Public Class Modulos_Config_Configuracion
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' La verificación de sesión la hace Site.Master
    End Sub

    Public Function ValorConfig(ByVal clave As String) As String
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Config_Obtener", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@clave", clave)
                    Dim result As Object = cmd.ExecuteScalar()
                    If result IsNot Nothing AndAlso Not IsDBNull(result) Then
                        Return result.ToString()
                    End If
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ValorConfig: " & ex.Message)
        End Try
        Return ""
    End Function

    Protected Sub btnAccion_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""
        
        Select Case accion
            Case "GUARDAR" : ProcesarGuardar()
            Case "PROBAR" : ProcesarProbarConexion()
        End Select
    End Sub

    Private Sub ProcesarGuardar()
        Dim url As String = LimpiarInput(Request.Form("hdWcUrl"))
        Dim key As String = LimpiarInput(Request.Form("hdConsumerKey"))
        Dim secret As String = LimpiarInput(Request.Form("hdConsumerSecret"))
        Dim webhook As String = LimpiarInput(Request.Form("hdWebhookSecret"))
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)

        If url = "" OrElse key = "" OrElse secret = "" Then
            MostrarAlerta("Faltan datos obligatorios.", "error")
            Return
        End If

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                GuardarClave(conn, "WC_URL", url, uid)
                GuardarClave(conn, "WC_CONSUMER_KEY", key, uid)
                GuardarClave(conn, "WC_CONSUMER_SECRET", secret, uid)
                If webhook <> "" Then
                    GuardarClave(conn, "WC_WEBHOOK_SECRET", webhook, uid)
                End If
            End Using
            MostrarAlerta("Credenciales guardadas correctamente.", "ok")
        Catch ex As Exception
            MostrarAlerta("Error al guardar: " & ex.Message, "error")
            System.Diagnostics.Debug.WriteLine("ERROR Guardar: " & ex.Message)
        End Try
    End Sub

    Private Sub GuardarClave(conn As SqlConnection, clave As String, valor As String, uid As Integer)
        Using cmd As New SqlCommand("FLORERIA_sp_Config_Guardar", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@clave", clave)
            cmd.Parameters.AddWithValue("@valor", valor)
            
            Dim uidParam As Object = DBNull.Value
            If uid > 0 Then
                uidParam = CObj(uid)
            End If
            cmd.Parameters.AddWithValue("@modificado_por", uidParam)
            
            cmd.ExecuteNonQuery()
        End Using
    End Sub

    Private Sub ProcesarProbarConexion()
        Dim url As String = ValorConfig("WC_URL")
        Dim key As String = ValorConfig("WC_CONSUMER_KEY")
        Dim secret As String = ValorConfig("WC_CONSUMER_SECRET")

        If url = "" OrElse key = "" OrElse secret = "" Then
            MostrarAlerta("Guarda las credenciales primero.", "warn")
            Return
        End If

        Try
            Dim apiUrl As String = url.TrimEnd("/"c) & "/wp-json/wc/v3/system_status"
            ServicePointManager.ServerCertificateValidationCallback = Function(s, c, ch, e) True
            
            Dim req As HttpWebRequest = CType(WebRequest.Create(apiUrl), HttpWebRequest)
            req.Method = "GET"
            req.Timeout = 10000
            req.Headers.Add("Authorization", "Basic " &
                Convert.ToBase64String(Encoding.UTF8.GetBytes(key & ":" & secret)))

            Dim resp As HttpWebResponse = CType(req.GetResponse(), HttpWebResponse)
            If resp.StatusCode = HttpStatusCode.OK Then
                MostrarAlerta("Conexión exitosa con WooCommerce.", "ok")
            Else
                MostrarAlerta("WooCommerce respondió: " & resp.StatusCode.ToString(), "warn")
            End If
            resp.Close()
        Catch ex As WebException
            Dim msg As String = "Error de conexión: " & ex.Message
            If ex.Response IsNot Nothing Then
                Dim resp As HttpWebResponse = CType(ex.Response, HttpWebResponse)
                If resp.StatusCode = HttpStatusCode.Unauthorized Then
                    msg = "Credenciales incorrectas. Verifica Key y Secret."
                ElseIf CInt(resp.StatusCode) = 403 Then
                    msg = "El servidor bloqueó la petición (WAF). Esto es normal en local."
                End If
            End If
            MostrarAlerta(msg, "error")
        Catch ex As Exception
            MostrarAlerta("Error: " & ex.Message, "error")
        End Try
    End Sub

    Private Function LimpiarInput(v As String) As String
        If v Is Nothing Then Return ""
        Return v.Trim().Replace("<", "").Replace(">", "").Replace("'", "").Replace("""", "")
    End Function

    Private Sub MostrarAlerta(mensaje As String, tipo As String)
        Dim mensajeLimpio As String = mensaje.Replace("'", "")
        Dim js As String = "mostrarAlerta('" & mensajeLimpio & "', '" & tipo & "');"
        ClientScript.RegisterStartupScript(Me.GetType(), "alerta", js, True)
    End Sub

End Class
