Imports System.Data.SqlClient
Imports System.Security.Cryptography
Imports System.Text
Imports System.Web

Partial Public Class CambiarPassword
    Inherits System.Web.UI.Page

    Private Const SALT As String = "FLORERIA2026"

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        Dim cookieChk As HttpCookie = Request.Cookies("SISCONBOL_TOKEN")
        If Session("usuario_id") Is Nothing AndAlso (cookieChk Is Nothing OrElse cookieChk.Value = "") Then
            Response.Redirect("~/Login.aspx")
            Return
        End If
    End Sub

    Protected Sub btnGuardar_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim actual As String = Request.Form("hdActual")
        Dim nueva As String = Request.Form("hdNueva")

        If actual Is Nothing Then actual = ""
        If nueva Is Nothing Then nueva = ""

        actual = LimpiarInput(actual)
        nueva = LimpiarInput(nueva)

        ' Validacion en servidor
        If actual = "" OrElse nueva = "" Then
            MostrarAlerta("Datos incompletos.", False)
            Return
        End If

        If nueva.Length < 6 Then
            MostrarAlerta("La nueva contrasena debe tener al menos 6 caracteres.", False)
            Return
        End If

        If nueva = actual Then
            MostrarAlerta("La nueva contrasena no puede ser igual a la actual.", False)
            Return
        End If

        Dim usuarioId As Integer = CInt(Session("usuario_id"))
        Dim hashActual As String = GenerarHash(actual, SALT)
        Dim hashNueva As String = GenerarHash(nueva, SALT)
        Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
        If ip Is Nothing Then ip = ""

        Try
            Dim cadena As String = System.Configuration.ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString
            Using conn As New SqlConnection(cadena)
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Usuario_CambiarPassword", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@usuario_id", usuarioId)
                    cmd.Parameters.AddWithValue("@pwd_actual_hash", hashActual)
                    cmd.Parameters.AddWithValue("@pwd_nueva_hash", hashNueva)
                    cmd.Parameters.AddWithValue("@ip", ip)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            If CBool(dr("ok")) Then
                                Response.Redirect("~/Default.aspx")
                            Else
                                MostrarAlerta(dr("mensaje").ToString(), False)
                            End If
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarAlerta("Error del sistema. Intente nuevamente.", False)
            System.Diagnostics.Debug.WriteLine("ERROR CambiarPwd: " & ex.Message)
        End Try
    End Sub

    Private Function GenerarHash(pwd As String, salt As String) As String
        Dim datos() As Byte = Encoding.UTF8.GetBytes(pwd & salt)
        Dim hash() As Byte = SHA256.Create().ComputeHash(datos)
        Return BitConverter.ToString(hash).Replace("-", "").ToUpper()
    End Function

    Private Function LimpiarInput(valor As String) As String
        If valor Is Nothing Then Return ""
        valor = valor.Trim()
        valor = valor.Replace("<", "").Replace(">", "").Replace("'", "")
        valor = valor.Replace("""", "").Replace(";", "").Replace("--", "")
        Return valor
    End Function

    Private Sub MostrarAlerta(mensaje As String, esOk As Boolean)
        Dim css As String = If(esOk, "alerta alerta-ok show", "alerta alerta-error show")
        Dim js As String = "var d=document.getElementById('divAlerta');" &
                            "if(d){d.innerHTML='" & HttpUtility.JavaScriptStringEncode(mensaje) & "';" &
                            "d.className='" & css & "';}"
        ClientScript.RegisterStartupScript(Me.GetType(), "alerta", js, True)
    End Sub

End Class
