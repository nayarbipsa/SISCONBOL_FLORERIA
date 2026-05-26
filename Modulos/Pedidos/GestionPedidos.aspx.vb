Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

Partial Public Class Modulos_Pedidos_GestionPedidos
    Inherits System.Web.UI.Page

    ' Propiedades para el ASPX
    Public Property TablaPendientesWC As String = ""
    Public Property OptionsDelivery As String = ""
    Public Property OptionsZona As String = ""
    Public Property TotalPendientesWC As Integer = 0
    Public Property MensajeAlerta As String = ""
    Public Property TipoAlerta As String = "success"

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not SesionHelper.VerificarSesion(Context) Then
            Response.Redirect("~/Login.aspx")
            Return
        End If

        ' Leer mensaje de alerta si viene de redirect
        Dim msg As String = Request.QueryString("msg")
        If msg IsNot Nothing AndAlso msg <> "" Then
            MensajeAlerta = HttpUtility.UrlDecode(msg).Replace("'", "\'")
            Dim tipo As String = Request.QueryString("tipo")
            If tipo IsNot Nothing AndAlso tipo <> "" Then
                TipoAlerta = tipo
            End If
        End If

        If Not IsPostBack Then
            Try
                CargarPendientesWC()
                CargarDropdowns()
            Catch ex As Exception
                System.Diagnostics.Debug.WriteLine("ERROR Page_Load: " & ex.Message)
                MensajeAlerta = "Error: " & ex.Message
                TipoAlerta = "error"
            End Try
        End If
    End Sub

    ' ============================================================
    ' BANNER WC PENDIENTES (sigue por server-side porque es chico)
    ' ============================================================
    Private Sub CargarPendientesWC()
        Dim sb As New StringBuilder()
        TotalPendientesWC = 0

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_sp_Pedido_ListarPendientesWC", conn)
                cmd.CommandType = CommandType.StoredProcedure
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        TotalPendientesWC += 1
                        sb.Append(RenderFilaWC(dr))
                    End While
                End Using
            End Using
        End Using

        TablaPendientesWC = sb.ToString()
    End Sub

    Private Function RenderFilaWC(dr As SqlDataReader) As String
        Dim sb As New StringBuilder()
        Dim pedidoId As Integer = CInt(dr("pedido_id"))
        Dim wcNumber As String = LeerStr(dr, "wc_order_number")
        Dim wcStatus As String = LeerStr(dr, "wc_order_status")
        Dim metodoPago As String = LeerStr(dr, "wc_payment_method_title")
        If metodoPago = "" Then metodoPago = "(no especificado)"
        Dim receptor As String = LeerStr(dr, "receptor_nombre")
        Dim celular As String = LeerStr(dr, "receptor_celular")
        Dim totalBs As Decimal = LeerDec(dr, "total_bs")
        Dim contactado As Boolean = LeerBool(dr, "contactado_cliente")
        Dim creadoEn As DateTime = LeerFecha(dr, "creado_en")
        Dim iconoMetodo As String = ObtenerIconoMetodoPago(LeerStr(dr, "wc_payment_method"))
        Dim clienteJs As String = ("WC #" & wcNumber & " - " & receptor).Replace("'", "").Replace(Chr(34), "")

        sb.Append("<div class=""wc-row"">")
        sb.Append("<span class=""code-mono"">#" & HE(wcNumber) & "</span>")
        sb.Append("<div><div style=""font-weight:500"">" & HE(receptor))
        If contactado Then sb.Append("<span class=""contacto-ok""> &middot; contactado</span>")
        sb.Append("</div>")
        sb.Append("<div class=""cell-subtle"">" & HE(celular) & " &middot; " & creadoEn.ToString("dd/MM HH:mm") & "</div></div>")
        sb.Append("<div class=""method-pago""><i class=""ti " & iconoMetodo & """></i> " & HE(metodoPago) & "</div>")
        sb.Append("<span class=""badge badge-warn"">" & HE(wcStatus) & "</span>")
        sb.Append("<span style=""text-align:right;font-weight:500"">Bs " & totalBs.ToString("N2") & "</span>")
        sb.Append("<div class=""actions-cell"">")
        sb.Append("<button type=""button"" class=""btn btn-icon-only"" onclick=""verDetalle(" & pedidoId & ")""><i class=""ti ti-eye""></i></button>")
        sb.Append("<button type=""button"" class=""btn btn-icon-only btn-success-sm"" onclick=""abrirModalAceptar(" & pedidoId & ",'" & clienteJs & "','" & totalBs.ToString("N2") & "')""><i class=""ti ti-check""></i> Aceptar</button>")
        sb.Append("</div></div>")
        Return sb.ToString()
    End Function

    Private Function ObtenerIconoMetodoPago(metodo As String) As String
        If metodo Is Nothing Then Return "ti-credit-card"
        Dim m = metodo.ToLower()
        If m.Contains("qr") OrElse m.Contains("bisa") Then Return "ti-qrcode"
        If m.Contains("transfer") OrElse m.Contains("bnb") OrElse m.Contains("bank") Then Return "ti-building-bank"
        If m.Contains("efectivo") OrElse m.Contains("cash") OrElse m.Contains("cod") OrElse m.Contains("contra") Then Return "ti-cash"
        Return "ti-credit-card"
    End Function

    ' ============================================================
    ' DROPDOWNS (Zona y Delivery)
    ' ============================================================
    Private Sub CargarDropdowns()
        Dim sbZ As New StringBuilder()
        Dim sbD As New StringBuilder()

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()

            ' Zonas
            Using cmd As New SqlCommand("SELECT zona_id, nombre FROM FLORERIA_Zona WHERE ISNULL(activo,1)=1 ORDER BY nombre", conn)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        sbZ.Append("<option value=""" & dr("zona_id") & """>" & HE(dr("nombre").ToString()) & "</option>")
                    End While
                End Using
            End Using

            ' Deliverys
            Using cmd As New SqlCommand("FLORERIA_sp_Asignacion_ListarDeliverysActivos", conn)
                cmd.CommandType = CommandType.StoredProcedure
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        Dim uid As Integer = CInt(dr("usuario_id"))
                        Dim nombre As String = LeerStr(dr, "nombre_completo")
                        Dim activos As Integer = LeerInt(dr, "pedidos_activos_hoy")
                        sbD.Append("<option value=""" & uid & """>" & HE(nombre) & " (" & activos & ")</option>")
                    End While
                End Using
            End Using
        End Using

        OptionsZona = sbZ.ToString()
        OptionsDelivery = sbD.ToString()
    End Sub

    ' ============================================================
    ' POSTBACK PARA ACCIONES
    ' ============================================================
    Protected Sub btnAccion_Click(sender As Object, e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""
        accion = accion.Trim()

        Dim pedidoIdStr As String = Request.Form("hdPedidoId")
        Dim pedidoId As Integer = 0
        Integer.TryParse(pedidoIdStr, pedidoId)
        If pedidoId <= 0 Then Return

        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(Context)
        Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
        If ip Is Nothing Then ip = ""

        Try
            If accion = "ACEPTAR_PAGO" Then
                EjecutarAceptarPago(pedidoId, usuarioId, ip)
            ElseIf accion = "MARCAR_CONTACTADO" Then
                EjecutarMarcarContactado(pedidoId, usuarioId, ip)
            ElseIf accion = "CAMBIAR_ESTADO" Then
                Dim estadoNuevo As String = Request.Form("hdEstadoNuevo")
                If estadoNuevo Is Nothing OrElse estadoNuevo = "" Then Return
                EjecutarCambiarEstado(pedidoId, estadoNuevo, usuarioId, ip)
            ElseIf accion = "CANCELAR_PEDIDO" Then
                ' Verificar permiso
                Dim tipoId As Integer = 3
                If Session("tipo_id") IsNot Nothing Then Integer.TryParse(Session("tipo_id").ToString(), tipoId)
                If tipoId <> 1 AndAlso tipoId <> 2 Then
                    RedirectConMsg("No tienes permiso para cancelar pedidos", "error")
                    Return
                End If
                EjecutarCambiarEstado(pedidoId, "CANCELADO", usuarioId, ip)
            End If
        Catch ex As Exception
            RedirectConMsg("Error: " & ex.Message, "error")
        End Try
    End Sub

    Private Sub EjecutarAceptarPago(pedidoId As Integer, usuarioId As Integer, ip As String)
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_sp_Pedido_AceptarPagoManual", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@pedido_id", pedidoId)
                cmd.Parameters.AddWithValue("@usuario_id", usuarioId)
                cmd.Parameters.AddWithValue("@ip", ip)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        Dim ok As Boolean = LeerBool(dr, "ok")
                        Dim mensaje As String = LeerStr(dr, "mensaje")
                        dr.Close()
                        RedirectConMsg(mensaje, If(ok, "success", "error"))
                        Return
                    End If
                End Using
            End Using
        End Using
    End Sub

    Private Sub EjecutarMarcarContactado(pedidoId As Integer, usuarioId As Integer, ip As String)
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_sp_Pedido_MarcarContactado", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@pedido_id", pedidoId)
                cmd.Parameters.AddWithValue("@contactado", 1)
                cmd.Parameters.AddWithValue("@usuario_id", usuarioId)
                cmd.Parameters.AddWithValue("@ip", ip)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        Dim ok As Boolean = LeerBool(dr, "ok")
                        Dim mensaje As String = LeerStr(dr, "mensaje")
                        dr.Close()
                        RedirectConMsg(mensaje, If(ok, "success", "warning"))
                        Return
                    End If
                End Using
            End Using
        End Using
    End Sub

    Private Sub EjecutarCambiarEstado(pedidoId As Integer, estadoNuevo As String, usuarioId As Integer, ip As String)
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_sp_Pedido_CambiarEstadoOperativo", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@pedido_id", pedidoId)
                cmd.Parameters.AddWithValue("@estado_nuevo", estadoNuevo)
                cmd.Parameters.AddWithValue("@observaciones", DBNull.Value)
                cmd.Parameters.AddWithValue("@usuario_id", usuarioId)
                cmd.Parameters.AddWithValue("@ip", ip)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        Dim ok As Boolean = LeerBool(dr, "ok")
                        Dim mensaje As String = LeerStr(dr, "mensaje")
                        dr.Close()
                        RedirectConMsg(mensaje, If(ok, "success", "warning"))
                        Return
                    End If
                End Using
            End Using
        End Using
    End Sub

    Private Sub RedirectConMsg(mensaje As String, tipo As String)
        Dim url As String = "GestionPedidos.aspx?msg=" & HttpUtility.UrlEncode(mensaje) & "&tipo=" & tipo
        SesionHelper.RedirectSeguro(Context, url)
    End Sub

    ' ============================================================
    ' HELPERS
    ' ============================================================
    Private Function LeerStr(dr As SqlDataReader, campo As String) As String
        Try
            Dim idx = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return ""
            Return dr(idx).ToString()
        Catch
            Return ""
        End Try
    End Function

    Private Function LeerInt(dr As SqlDataReader, campo As String) As Integer
        Try
            Dim idx = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return 0
            Return CInt(dr(idx))
        Catch
            Return 0
        End Try
    End Function

    Private Function LeerDec(dr As SqlDataReader, campo As String) As Decimal
        Try
            Dim idx = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return 0D
            Return CDec(dr(idx))
        Catch
            Return 0D
        End Try
    End Function

    Private Function LeerBool(dr As SqlDataReader, campo As String) As Boolean
        Try
            Dim idx = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return False
            Return CBool(dr(idx))
        Catch
            Return False
        End Try
    End Function

    Private Function LeerFecha(dr As SqlDataReader, campo As String) As DateTime
        Try
            Dim idx = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return DateTime.MinValue
            Return CDate(dr(idx))
        Catch
            Return DateTime.MinValue
        End Try
    End Function

    Private Function HE(texto As String) As String
        If texto Is Nothing Then Return ""
        Return HttpUtility.HtmlEncode(texto)
    End Function

End Class
