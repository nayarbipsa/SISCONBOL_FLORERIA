Imports System.Web
Imports System.Data.SqlClient

' ============================================================
' SISCONBOL - Link DUAL cliente/agente (pp.aspx)
' URL: https://floreria.somee.com/pp.aspx?c=PRE-000123
'
' Comportamiento:
'   - SIN sesion de agente (cliente): redirige directo al formulario
'     publico cliente/index.aspx?t=<token> (sin login, sin pantalla
'     intermedia). El token_web se asegura (reusa/genera) en el helper.
'   - CON sesion de agente: muestra una pantalla de eleccion inline
'     (ver como AGENTE o ver como CLIENTE), sin redirect automatico.
'
' La deteccion de agente usa SesionHelper.VerificarSesion (no logica propia).
' ============================================================
Partial Public Class pp
    Inherits System.Web.UI.Page

    ' --- Propiedades para la pantalla de eleccion (solo agentes) ---
    Public Property MostrarEleccion As Boolean = False
    Public Property Codigo As String = ""
    Public Property ClienteNombre As String = ""
    Public Property LinkAgente As String = ""
    Public Property LinkCliente As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' --- DIAGNOSTICO TEMPORAL: pp.aspx?c=...&dbg=1 ---
        ' Quitar este bloque cuando se confirme la deteccion de sesion.
        If Request.QueryString("dbg") = "1" Then
            MostrarDebugSesion()
            Return
        End If

        ' --- 1. Validar codigo ---
        Dim codigo As String = Request.QueryString("c")
        If String.IsNullOrEmpty(codigo) Then
            IrAInvalido()
            Return
        End If

        codigo = codigo.Trim().ToUpper()
        If Not codigo.StartsWith("PRE-") OrElse codigo.Length < 8 Then
            IrAInvalido()
            Return
        End If

        ' --- 2. Detectar si hay un AGENTE logueado ---
        Dim esAgente As Boolean = SesionHelper.VerificarSesion(HttpContext.Current)
        Dim uid As Integer = If(esAgente, SesionHelper.ObtenerUsuarioId(HttpContext.Current), 0)

        ' --- LOG TEMPORAL DE DIAGNOSTICO (quitar cuando se confirme) ---
        RegistrarDebugPP(codigo, esAgente, uid)

        ' --- 3. Resolver pre-pedido + asegurar token_web vigente ---
        Dim info As PrePedidoLink.Info = PrePedidoLink.AsegurarTokenPorCodigo(codigo, uid)
        If Not info.Encontrado OrElse info.Token = "" Then
            IrAInvalido()
            Return
        End If

        ' --- 4. CLIENTE: directo al formulario (sin pantalla intermedia) ---
        If Not esAgente Then
            Response.Redirect(ResolveUrl("~/cliente/index.aspx?t=" & info.Token), False)
            HttpContext.Current.ApplicationInstance.CompleteRequest()
            Return
        End If

        ' --- 5. AGENTE: pantalla de eleccion (sin redirect automatico) ---
        MostrarEleccion = True
        Codigo = info.Codigo
        ClienteNombre = info.ClienteNombre
        LinkAgente = ResolveUrl("~/Modulos/Pedidos/PrePedido_Detalle.aspx?id=" & info.PrePedidoId)
        ' El link del cliente que se muestra al agente usa URL_PUBLICA_BASE (config)
        LinkCliente = PrePedidoLink.UrlPublicaBase() & "/cliente/index.aspx?t=" & info.Token
    End Sub

    ' --- DIAGNOSTICO TEMPORAL: muestra que ve pp.aspx respecto a la sesion ---
    Private Sub MostrarDebugSesion()
        Dim ctx As HttpContext = HttpContext.Current
        Dim sb As New System.Text.StringBuilder()

        Dim sessionTokenLen As Integer = 0
        Try
            If ctx.Session IsNot Nothing AndAlso ctx.Session("token") IsNot Nothing Then
                sessionTokenLen = ctx.Session("token").ToString().Length
            End If
        Catch
        End Try

        Dim ck As HttpCookie = ctx.Request.Cookies("SISCONBOL_TOKEN")
        Dim cookieLen As Integer = If(ck IsNot Nothing AndAlso ck.Value IsNot Nothing, ck.Value.Length, 0)

        Dim todasCookies As String = ""
        For Each nombre As String In ctx.Request.Cookies.AllKeys
            todasCookies &= nombre & " "
        Next

        Dim esAgente As Boolean = SesionHelper.VerificarSesion(ctx)
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(ctx)

        sb.Append("HOST = " & ctx.Request.Url.Host & vbCrLf)
        sb.Append("URL  = " & ctx.Request.Url.AbsoluteUri & vbCrLf)
        sb.Append("Session existe       = " & (ctx.Session IsNot Nothing) & vbCrLf)
        sb.Append("Session token len    = " & sessionTokenLen & vbCrLf)
        sb.Append("Cookie SISCONBOL_TOKEN len = " & cookieLen & vbCrLf)
        sb.Append("Cookies presentes    = [" & todasCookies.Trim() & "]" & vbCrLf)
        sb.Append("VerificarSesion()    = " & esAgente & vbCrLf)
        sb.Append("usuario_id           = " & uid & vbCrLf)

        ctx.Response.ContentType = "text/plain; charset=utf-8"
        ctx.Response.Write(sb.ToString())
        ctx.Response.End()
    End Sub

    ' --- LOG TEMPORAL: registra en FLORERIA_PP_Debug que vio pp.aspx ---
    Private Sub RegistrarDebugPP(codigo As String, esAgente As Boolean, uid As Integer)
        Try
            Dim ctx As HttpContext = HttpContext.Current
            Dim ck As HttpCookie = ctx.Request.Cookies("SISCONBOL_TOKEN")
            Dim cookieLen As Integer = If(ck IsNot Nothing AndAlso ck.Value IsNot Nothing, ck.Value.Length, 0)
            Dim sLen As Integer = 0
            Try
                If ctx.Session IsNot Nothing AndAlso ctx.Session("token") IsNot Nothing Then sLen = ctx.Session("token").ToString().Length
            Catch
            End Try
            Dim cookiesPres As String = ""
            For Each n As String In ctx.Request.Cookies.AllKeys
                cookiesPres &= n & " "
            Next
            Dim ua As String = If(ctx.Request.UserAgent, "")

            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand(
                    "INSERT INTO FLORERIA_PP_Debug(host,url,cookie_token_len,session_token_len,cookies_presentes,verificar_sesion,usuario_id,codigo,user_agent) " &
                    "VALUES(@h,@u,@cl,@sl,@cp,@v,@uid,@c,@ua)", conn)
                    cmd.Parameters.AddWithValue("@h", ctx.Request.Url.Host)
                    cmd.Parameters.AddWithValue("@u", Left(ctx.Request.Url.AbsoluteUri, 400))
                    cmd.Parameters.AddWithValue("@cl", cookieLen)
                    cmd.Parameters.AddWithValue("@sl", sLen)
                    cmd.Parameters.AddWithValue("@cp", Left(cookiesPres.Trim(), 400))
                    cmd.Parameters.AddWithValue("@v", esAgente)
                    cmd.Parameters.AddWithValue("@uid", uid)
                    cmd.Parameters.AddWithValue("@c", If(codigo Is Nothing, "", codigo))
                    cmd.Parameters.AddWithValue("@ua", Left(ua, 400))
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch
            ' nunca debe romper el flujo
        End Try
    End Sub

    ' Pantalla amigable "Link no valido" reutilizando el area publica del cliente
    Private Sub IrAInvalido()
        Response.Redirect(ResolveUrl("~/cliente/index.aspx?t="), False)
        HttpContext.Current.ApplicationInstance.CompleteRequest()
    End Sub

End Class
