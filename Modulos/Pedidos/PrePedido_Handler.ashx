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
                Case "VALIDAR_PARA_LINK"
                    ValidarParaLink(context)
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

            ' ----- VALIDACION OBLIGATORIA: bloquear envio si hay entregas incompletas -----
            ' Esto previene que el cliente reciba un link y vea "Link invalido"
            ' por campos faltantes.
            Dim jsonInc As String = ObtenerJsonEntregasIncompletas(conn, ppId)
            If jsonInc <> "" Then
                context.Response.Write("{""ok"":false,""msg"":""Hay entregas incompletas. Complete los campos faltantes antes de enviar el link al cliente."",""entregas_incompletas"":" & jsonInc & "}")
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

    ' ============================================================
    ' VALIDAR_PARA_LINK
    ' Recibe: prepedido_id
    ' Devuelve: ok=true si todo esta listo, ok=false con lista detallada si faltan campos.
    ' ============================================================
    Private Sub ValidarParaLink(context As HttpContext)
        Dim ppId As Integer = 0
        Integer.TryParse(context.Request.Form("prepedido_id"), ppId)

        If ppId <= 0 Then
            context.Response.Write("{""ok"":false,""msg"":""prepedido_id invalido""}")
            Return
        End If

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Dim jsonInc As String = ObtenerJsonEntregasIncompletas(conn, ppId)
            If jsonInc = "" Then
                context.Response.Write("{""ok"":true,""msg"":""Listo para enviar""}")
            Else
                context.Response.Write("{""ok"":false,""msg"":""Hay entregas incompletas"",""entregas_incompletas"":" & jsonInc & "}")
            End If
        End Using
    End Sub

    ' ============================================================
    ' ObtenerJsonEntregasIncompletas
    ' Devuelve el JSON array de entregas incompletas, o "" si todas estan completas.
    ' Construye el JSON manualmente para evitar dependencias adicionales.
    '
    ' Reglas (solo lo que el AGENTE debe llenar antes de enviar el link):
    '   - Fecha de entrega
    '   - Slot/Horario
    '   - Ciudad
    '   - Si tipo_entrega = 'DOMICILIO': zona_id
    '   - Si tipo_entrega = 'RECOJO_SUCURSAL': sucursal_id
    '   - Al menos 1 producto en FLORERIA_PrePedido_Entrega_Detalle
    '
    ' NO se valida (lo llena el cliente final):
    '   - receptor_nombre, receptor_celular, direccion
    ' ============================================================
    Private Function ObtenerJsonEntregasIncompletas(conn As SqlConnection, prepedidoId As Integer) As String
        Dim sql As String = "SELECT e.prepedido_entrega_id, e.receptor_nombre, " & _
            "e.tipo_entrega, e.fecha_entrega, e.slot_id, " & _
            "e.ciudad_id, e.zona_id, e.sucursal_id, " & _
            "ISNULL((SELECT COUNT(*) FROM FLORERIA_PrePedido_Entrega_Detalle d " & _
            "        WHERE d.prepedido_entrega_id = e.prepedido_entrega_id), 0) AS cant_productos " & _
            "FROM FLORERIA_PrePedido_Entrega e " & _
            "WHERE e.prepedido_id = @id AND e.estado = 'BORRADOR' " & _
            "ORDER BY e.prepedido_entrega_id"

        Dim json As New System.Text.StringBuilder()
        json.Append("[")

        Dim numero As Integer = 0
        Dim primero As Boolean = True
        Dim hayIncompletas As Boolean = False

        Using cmd As New SqlCommand(sql, conn)
            cmd.Parameters.AddWithValue("@id", prepedidoId)
            Using dr As SqlDataReader = cmd.ExecuteReader()
                While dr.Read()
                    numero = numero + 1
                    Dim eId As Integer = CInt(dr("prepedido_entrega_id"))
                    Dim receptor As String = ""
                    If Not IsDBNull(dr("receptor_nombre")) Then receptor = dr("receptor_nombre").ToString().Trim()
                    Dim tipoEntrega As String = "DOMICILIO"
                    If Not IsDBNull(dr("tipo_entrega")) Then tipoEntrega = dr("tipo_entrega").ToString()

                    Dim faltantes As New System.Collections.Generic.List(Of String)

                    If IsDBNull(dr("fecha_entrega")) Then faltantes.Add("Fecha de entrega")
                    If IsDBNull(dr("slot_id")) Then faltantes.Add("Horario")
                    If IsDBNull(dr("ciudad_id")) Then faltantes.Add("Ciudad")

                    If tipoEntrega = "DOMICILIO" Then
                        If IsDBNull(dr("zona_id")) Then faltantes.Add("Zona")
                    ElseIf tipoEntrega = "RECOJO_SUCURSAL" Then
                        If IsDBNull(dr("sucursal_id")) Then faltantes.Add("Sucursal de recojo")
                    End If

                    If CInt(dr("cant_productos")) = 0 Then faltantes.Add("Sin productos (al menos 1)")

                    If faltantes.Count > 0 Then
                        hayIncompletas = True
                        If receptor = "" Then receptor = "Sin destinatario"
                        If Not primero Then json.Append(",")
                        primero = False
                        json.Append("{""numero"":" & numero)
                        json.Append(",""entrega_id"":" & eId)
                        json.Append(",""receptor"":""" & EscapeJson(receptor) & """")
                        json.Append(",""faltantes"":[")
                        For i As Integer = 0 To faltantes.Count - 1
                            If i > 0 Then json.Append(",")
                            json.Append("""" & EscapeJson(faltantes(i)) & """")
                        Next
                        json.Append("]}")
                    End If
                End While
            End Using
        End Using

        ' Caso especial: no hay ninguna entrega
        If numero = 0 Then
            hayIncompletas = True
            json.Append("{""numero"":0,""entrega_id"":0,""receptor"":""-"",""faltantes"":[""No hay ninguna entrega creada""]}")
        End If

        json.Append("]")

        If hayIncompletas Then
            Return json.ToString()
        Else
            Return ""
        End If
    End Function

    ' Helper: escapar caracteres especiales para JSON
    Private Function EscapeJson(s As String) As String
        If s Is Nothing Then Return ""
        Dim r As String = s
        r = r.Replace("\", "\\")
        r = r.Replace("""", "\""")
        r = r.Replace(vbCrLf, " ")
        r = r.Replace(vbLf, " ")
        r = r.Replace(vbCr, " ")
        r = r.Replace(vbTab, " ")
        Return r
    End Function

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
