<%@ WebHandler Language="VB" Class="PrePedido_Handler" %>

Imports System
Imports System.Web
Imports System.Data
Imports System.Data.SqlClient

' ============================================================
' SISCONBOL - Handler de Pre-Pedido (acciones a nivel pre-pedido)
' Archivo: Modulos/Pedidos/PrePedido_Handler.ashx
'
' Acciones:
'   GENERAR_TOKEN  -> Crea o reutiliza token_web para link al cliente
'   COPIAR_LINK    -> Igual a GENERAR_TOKEN pero indica que solo se copia
' ============================================================
Public Class PrePedido_Handler
    Implements IHttpHandler
    Implements System.Web.SessionState.IRequiresSessionState

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json"

        ' Validar sesion
        If Not SesionHelper.VerificarSesion(context) Then
            context.Response.Write("{""ok"":false,""msg"":""Sesion expirada""}")
            Return
        End If

        Dim accion As String = context.Request.Form("accion")
        If accion Is Nothing Then accion = ""

        Try
            Select Case accion
                Case "GENERAR_TOKEN"
                    GenerarToken(context)
                Case Else
                    context.Response.Write("{""ok"":false,""msg"":""Accion no valida""}")
            End Select
        Catch ex As Exception
            context.Response.Write("{""ok"":false,""msg"":""" & ex.Message.Replace("""", "'") & """}")
        End Try
    End Sub

    ' ============================================================
    ' GENERAR_TOKEN
    ' Recibe: prepedido_id
    ' Devuelve: url, token, celular_cliente, ya_existia
    '
    ' Logica:
    ' - Si ya hay token vigente (< 24h) -> reutiliza
    ' - Si expirado o NULL -> genera nuevo, marca token_expira = ahora + 24h
    ' ============================================================
    Private Sub GenerarToken(context As HttpContext)
        Dim ppId As Integer = 0
        Integer.TryParse(context.Request.Form("prepedido_id"), ppId)

        If ppId <= 0 Then
            context.Response.Write("{""ok"":false,""msg"":""prepedido_id invalido""}")
            Return
        End If

        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()

            ' ----- Validar que el pre-pedido existe y leer estado actual del token -----
            Dim tokenExistente As String = ""
            Dim tokenExpira As DateTime = DateTime.MinValue
            Dim celularCliente As String = ""
            Dim existe As Boolean = False

            Using cmdLeer As New SqlCommand(
                "SELECT token_web, token_expira, cliente_celular " &
                "FROM FLORERIA_PrePedido WHERE prepedido_id = @id", conn)
                cmdLeer.Parameters.AddWithValue("@id", ppId)
                Using dr As SqlDataReader = cmdLeer.ExecuteReader()
                    If dr.Read() Then
                        existe = True
                        If Not IsDBNull(dr("token_web")) Then tokenExistente = dr("token_web").ToString()
                        If Not IsDBNull(dr("token_expira")) Then tokenExpira = CDate(dr("token_expira"))
                        If Not IsDBNull(dr("cliente_celular")) Then celularCliente = dr("cliente_celular").ToString()
                    End If
                End Using
            End Using

            If Not existe Then
                context.Response.Write("{""ok"":false,""msg"":""El pre-pedido no existe""}")
                Return
            End If

            ' ----- Decidir reusar o generar nuevo -----
            Dim token As String
            Dim yaExistia As Boolean = False
            Dim ahora As DateTime = DateTime.Now

            Dim vigente As Boolean = (tokenExistente <> "" AndAlso tokenExpira > ahora)

            If vigente Then
                token = tokenExistente
                yaExistia = True
            Else
                ' Generar GUID sin guiones
                token = Guid.NewGuid().ToString("N")
                Dim nuevaExpira As DateTime = ahora.AddHours(24)

                Using cmdUpd As New SqlCommand(
                    "UPDATE FLORERIA_PrePedido " &
                    "SET token_web = @t, token_expira = @exp, " &
                    "    token_abierto_en = NULL, token_confirmado_por_cliente_en = NULL, " &
                    "    modificado_por = @uid, modificado_en = GETDATE() " &
                    "WHERE prepedido_id = @id", conn)
                    cmdUpd.Parameters.AddWithValue("@t", token)
                    cmdUpd.Parameters.AddWithValue("@exp", nuevaExpira)
                    cmdUpd.Parameters.AddWithValue("@uid", usuarioId)
                    cmdUpd.Parameters.AddWithValue("@id", ppId)
                    cmdUpd.ExecuteNonQuery()
                End Using
            End If

            ' ----- Construir URL completa -----
            Dim req As HttpRequest = context.Request
            Dim baseUrl As String = req.Url.GetLeftPart(UriPartial.Authority)
            Dim appPath As String = HttpRuntime.AppDomainAppVirtualPath
            If appPath = "/" Then appPath = ""
            Dim url As String = baseUrl & appPath & "/cliente/index.aspx?t=" & token

            ' ----- Limpiar celular cliente para wa.me -----
            Dim celularLimpio As String = ""
            For Each c As Char In celularCliente
                If Char.IsDigit(c) Then celularLimpio &= c
            Next
            If celularLimpio.Length = 8 AndAlso (celularLimpio.StartsWith("6") OrElse celularLimpio.StartsWith("7")) Then
                celularLimpio = "591" & celularLimpio
            End If

            ' ----- Respuesta JSON -----
            Dim sb As New System.Text.StringBuilder()
            sb.Append("{""ok"":true")
            sb.Append(",""token"":""" & token & """")
            sb.Append(",""url"":""" & url.Replace("""", "\""") & """")
            sb.Append(",""celular_cliente"":""" & celularLimpio & """")
            sb.Append(",""ya_existia"":" & If(yaExistia, "true", "false"))
            sb.Append("}")
            context.Response.Write(sb.ToString())
        End Using
    End Sub

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
