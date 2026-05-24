Imports System.ComponentModel.DataAnnotations
Imports System.Data.SqlClient
Imports System.Security.Cryptography
Imports System.Text

Partial Public Class Login
    Inherits System.Web.UI.Page

    Private Const SALT As String = "FLORERIA2026"

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ' Si ya tiene cookie valida, redirigir directo
            Dim cookie As HttpCookie = Request.Cookies("SISCONBOL_TOKEN")
            If cookie IsNot Nothing Then
                Dim token As String = cookie.Value
                If token <> "" AndAlso ValidarToken(token) Then
                    SesionHelper.RedirectSeguro(HttpContext.Current, "~/Default.aspx")
                    Return
                End If
            End If
        End If
    End Sub

    Protected Sub btnLogin_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim carnet As String = Request.Form("hdCarnet")
        Dim pwd As String = Request.Form("hdPassword")

        If carnet Is Nothing Then carnet = ""
        If pwd Is Nothing Then pwd = ""
        carnet = carnet.Trim()

        ' Validaciones básicas
        If carnet = "" OrElse pwd = "" Then
            MostrarAlerta("Datos incompletos.", False) : Return
        End If

        If Not System.Text.RegularExpressions.Regex.IsMatch(carnet, "^\d{7,8}$") Then
            MostrarAlerta("Carnet no valido.", False) : Return
        End If

        ' ============================================================
        ' VALIDACIÓN DE SEGURIDAD - Detectar SQL Injection
        ' ============================================================
        If Validador.TienePatronPeligroso(carnet) Then
            MostrarAlerta("Datos invalidos.", False) : Return
        End If

        If Validador.TienePatronPeligroso(pwd) Then
            MostrarAlerta("Datos invalidos.", False) : Return
        End If

        Dim pwdHash As String = GenerarHash(pwd, SALT)
        Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
        Dim ua As String = Request.ServerVariables("HTTP_USER_AGENT")
        If ip Is Nothing Then ip = ""
        If ua Is Nothing Then ua = ""
        Dim esCelular As Integer = 0
        If ua.ToLower().Contains("mobile") OrElse
           ua.ToLower().Contains("android") OrElse
           ua.ToLower().Contains("iphone") Then
            esCelular = 1
        End If

        Try
            Dim cadena As String = System.Configuration.ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString
            Using conn As New SqlConnection(cadena)
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Login", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@carnet", carnet)
                    cmd.Parameters.AddWithValue("@password_hash", pwdHash)
                    cmd.Parameters.AddWithValue("@ip", ip)
                    cmd.Parameters.AddWithValue("@user_agent", ua)
                    cmd.Parameters.AddWithValue("@es_celular", esCelular)
                    cmd.Parameters.AddWithValue("@dispositivo", DetectarSO(ua) & " - " & DetectarNav(ua))
                    cmd.Parameters.AddWithValue("@sistema_op", DetectarSO(ua))
                    cmd.Parameters.AddWithValue("@navegador", DetectarNav(ua))

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Dim resultado As String = dr("resultado").ToString()
                            Select Case resultado
                                Case "OK"
                                    ' Guardar datos en Session
                                    Session("usuario_id") = CInt(dr("usuario_id"))
                                    Session("token") = dr("token").ToString()
                                    Session("nombres") = dr("nombres").ToString()
                                    Session("apellidos") = dr("apellidos").ToString()
                                    Session("tipo_id") = CInt(dr("tipo_id"))

                                    ' Guardar token en cookie — dura hasta 23:59:59 hora Bolivia (UTC-4)
                                    Dim token As String = dr("token").ToString()
                                    Dim expiraUtc As DateTime = ObtenerExpiraBolivia()
                                    Dim cookie As New HttpCookie("SISCONBOL_TOKEN", token)
                                    cookie.Expires = expiraUtc
                                    cookie.HttpOnly = True
                                    Response.Cookies.Add(cookie)

                                    ' Guardar nombre en cookie para mostrar en pantalla
                                    Dim cookieNombre As New HttpCookie("SISCONBOL_NOMBRE", dr("nombres").ToString() & "|" & dr("apellidos").ToString() & "|" & dr("tipo_id").ToString())
                                    cookieNombre.Expires = expiraUtc
                                    Response.Cookies.Add(cookieNombre)

                                    If CBool(dr("debe_cambiar_pwd")) Then
                                        SesionHelper.RedirectSeguro(HttpContext.Current, "~/CambiarPassword.aspx")
                                        Return
                                    Else
                                        SesionHelper.RedirectSeguro(HttpContext.Current, "~/Default.aspx")
                                        Return
                                    End If

                                Case "BLOQUEADO_TEMP"
                                    MostrarAlerta(dr("mensaje").ToString(), True)
                                Case "VENCIDO"
                                    MostrarAlerta(dr("mensaje").ToString(), True)
                                Case Else
                                    MostrarAlerta(dr("mensaje").ToString(), False)
                            End Select
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarAlerta("Error del sistema. Intente nuevamente.", False)
            System.Diagnostics.Debug.WriteLine("ERROR LOGIN: " & ex.Message)
        End Try
    End Sub

    Private Function ValidarToken(token As String) As Boolean
        Try
            Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
            If ip Is Nothing Then ip = ""
            Dim cadena As String = System.Configuration.ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString
            Using conn As New SqlConnection(cadena)
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_ValidarSesion", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@token", token)
                    cmd.Parameters.AddWithValue("@ip", ip)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then Return CBool(dr("valida"))
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ValidarToken: " & ex.Message)
        End Try
        Return False
    End Function

    Private Function GenerarHash(pwd As String, salt As String) As String
        Dim datos() As Byte = Encoding.UTF8.GetBytes(pwd & salt)
        Dim hash() As Byte = SHA256.Create().ComputeHash(datos)
        Return BitConverter.ToString(hash).Replace("-", "").ToUpper()
    End Function

    Private Function DetectarSO(ua As String) As String
        If ua.Contains("Android") Then Return "Android"
        If ua.Contains("iPhone") Then Return "iOS"
        If ua.Contains("iPad") Then Return "iOS"
        If ua.Contains("Windows") Then Return "Windows"
        Return "Otro"
    End Function

    Private Function DetectarNav(ua As String) As String
        If ua.Contains("Edg") Then Return "Edge"
        If ua.Contains("Chrome") Then Return "Chrome"
        If ua.Contains("Firefox") Then Return "Firefox"
        If ua.Contains("Safari") Then Return "Safari"
        Return "Otro"
    End Function

    Private Sub MostrarAlerta(mensaje As String, esWarn As Boolean)
        Dim css As String = If(esWarn, "alerta alerta-warn", "alerta")
        Dim js As String = "var d=document.getElementById('divAlerta');" &
                            "if(d){d.innerHTML='" & mensaje.Replace("'", "") & "';" &
                            "d.className='" & css & "';" &
                            "d.style.display='block';}"
        ClientScript.RegisterStartupScript(Me.GetType(), "alerta", js, True)
    End Sub

    ''' <summary>
    ''' Calcula las 23:59:59 de HOY en hora de Bolivia (UTC-4)
    ''' y lo devuelve en UTC para asignarlo a la cookie del navegador.
    ''' Esto asegura que la cookie expire a medianoche Bolivia
    ''' sin importar la zona horaria del servidor de Somee.
    ''' </summary>
    Private Function ObtenerExpiraBolivia() As DateTime
        Try
            Dim zonaBolivia As TimeZoneInfo = TimeZoneInfo.FindSystemTimeZoneById("SA Western Standard Time")
            Dim horaBolivia As DateTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, zonaBolivia)
            Dim finDiaBolivia As DateTime = New DateTime(horaBolivia.Year, horaBolivia.Month, horaBolivia.Day, 23, 59, 59)
            Return TimeZoneInfo.ConvertTimeToUtc(finDiaBolivia, zonaBolivia)
        Catch ex As Exception
            ' Fallback: si falla la zona horaria, usar UTC-4 manual
            System.Diagnostics.Debug.WriteLine("ERROR ObtenerExpiraBolivia: " & ex.Message)
            Dim horaBolivia As DateTime = DateTime.UtcNow.AddHours(-4)
            Return New DateTime(horaBolivia.Year, horaBolivia.Month, horaBolivia.Day, 23, 59, 59).AddHours(4)
        End Try
    End Function

End Class