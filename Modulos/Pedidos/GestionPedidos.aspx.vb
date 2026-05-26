Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

Partial Public Class Modulos_Pedidos_GestionPedidos
    Inherits System.Web.UI.Page

    ' Propiedades publicas para el .aspx
    Public Property TablaPedidos As String = ""
    Public Property TablaPendientesWC As String = ""
    Public Property OptionsDelivery As String = ""
    Public Property TotalHoy As Integer = 0
    Public Property TotalPendientesWC As Integer = 0
    Public Property MensajeAlerta As String = ""
    Public Property TipoAlerta As String = "success"

    ' Valores de filtros (para mantener al refrescar)
    Public Property ValorBuscar As String = ""
    Public Property ValorDesde As String = ""
    Public Property ValorHasta As String = ""
    Public Property ValorSoloHoy As String = "1"
    Public Property ValorEstadoPago As String = ""
    Public Property ValorEstadoOp As String = ""
    Public Property ValorDelivery As String = ""
    Public Property ValorSoloExpress As String = ""

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not SesionHelper.VerificarSesion(Context) Then
            Response.Redirect("~/Login.aspx")
            Return
        End If

        ' Leer filtros del querystring
        LeerFiltros()

        ' Cargar alerta si viene de un redirect post-accion
        Dim msg As String = Request.QueryString("msg")
        If msg IsNot Nothing AndAlso msg <> "" Then
            MensajeAlerta = HttpUtility.UrlDecode(msg)
            Dim tipo As String = Request.QueryString("tipo")
            If tipo IsNot Nothing AndAlso tipo <> "" Then
                TipoAlerta = tipo
            End If
        End If

        If Not IsPostBack Then
            CargarTodo()
        End If
    End Sub

    Private Sub LeerFiltros()
        ValorBuscar = LeerQS("b")
        ValorDesde = LeerQS("d")
        ValorHasta = LeerQS("h")
        ValorSoloHoy = LeerQS("hoy")
        ValorEstadoPago = LeerQS("p")
        ValorEstadoOp = LeerQS("op")
        ValorDelivery = LeerQS("deli")
        ValorSoloExpress = LeerQS("exp")

        ' Por default solo_hoy = 1 si no vino ningun filtro
        If ValorBuscar = "" AndAlso ValorDesde = "" AndAlso ValorHasta = "" _
           AndAlso ValorEstadoPago = "" AndAlso ValorEstadoOp = "" _
           AndAlso ValorDelivery = "" AndAlso ValorSoloExpress = "" _
           AndAlso ValorSoloHoy = "" Then
            ValorSoloHoy = "1"
        End If
    End Sub

    Private Function LeerQS(clave As String) As String
        Dim v As String = Request.QueryString(clave)
        If v Is Nothing Then Return ""
        Return v.Trim()
    End Function

    Private Sub CargarTodo()
        Try
            CargarPendientesWC()
            CargarDeliverysDropdown()
            CargarPedidos()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR GestionPedidos.CargarTodo: " & ex.Message)
            MensajeAlerta = "Error cargando datos: " & ex.Message
            TipoAlerta = "error"
        End Try
    End Sub

    ' ============================================================
    ' CARGAR PEDIDOS WC PENDIENTES (BANNER)
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
        
        ' Icono segun metodo de pago
        Dim iconoMetodo As String = ObtenerIconoMetodoPago(LeerStr(dr, "wc_payment_method"))
        
        sb.Append("<div class=""wc-row"">")
        sb.Append("<span class=""code-mono"">#" & wcNumber & "</span>")
        sb.Append("<div>")
        sb.Append("<div style=""font-weight:500"">" & HE(receptor))
        If contactado Then
            sb.Append("<span class=""contacto-ok""> &middot; contactado</span>")
        End If
        sb.Append("</div>")
        sb.Append("<div class=""cell-subtle"">" & HE(celular) & " &middot; " & creadoEn.ToString("dd/MM HH:mm") & "</div>")
        sb.Append("</div>")
        sb.Append("<div class=""method-pago""><i class=""ti " & iconoMetodo & """></i> " & HE(metodoPago) & "</div>")
        sb.Append("<span class=""badge badge-warn"">" & HE(wcStatus) & "</span>")
        sb.Append("<span style=""text-align:right;font-weight:500"">Bs " & totalBs.ToString("N2") & "</span>")
        sb.Append("<div class=""actions-cell"">")
        sb.Append("<button type=""button"" class=""btn-icon-only"" title=""Ver detalle"" onclick=""verDetalle(" & pedidoId & ")""><i class=""ti ti-eye""></i></button>")
        sb.Append("<button type=""button"" class=""btn-icon-only btn-success-sm"" title=""Aceptar pago manual"" onclick=""abrirModalAceptar(" & pedidoId & ",'WC #" & HE(wcNumber) & " - " & HE(receptor).Replace("'", "\'") & "','" & totalBs.ToString("N2") & "')""><i class=""ti ti-check""></i> Aceptar</button>")
        sb.Append("</div>")
        sb.Append("</div>")
        
        Return sb.ToString()
    End Function

    Private Function ObtenerIconoMetodoPago(metodo As String) As String
        If metodo Is Nothing Then Return "ti-credit-card"
        Dim m As String = metodo.ToLower()
        If m.Contains("qr") OrElse m.Contains("bisa") Then Return "ti-qrcode"
        If m.Contains("transfer") OrElse m.Contains("bnb") OrElse m.Contains("bank") Then Return "ti-building-bank"
        If m.Contains("efectivo") OrElse m.Contains("cash") OrElse m.Contains("cod") OrElse m.Contains("contra") Then Return "ti-cash"
        If m.Contains("tarjeta") OrElse m.Contains("card") OrElse m.Contains("credit") Then Return "ti-credit-card"
        Return "ti-credit-card"
    End Function

    ' ============================================================
    ' CARGAR DROPDOWN DE DELIVERYS
    ' ============================================================
    Private Sub CargarDeliverysDropdown()
        Dim sb As New StringBuilder()

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_sp_Asignacion_ListarDeliverysActivos", conn)
                cmd.CommandType = CommandType.StoredProcedure
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        Dim uid As Integer = CInt(dr("usuario_id"))
                        Dim nombre As String = LeerStr(dr, "nombre_completo")
                        Dim activos As Integer = LeerInt(dr, "pedidos_activos_hoy")
                        Dim selected As String = ""
                        If ValorDelivery = uid.ToString() Then selected = "selected"
                        sb.Append("<option value=""" & uid & """ " & selected & ">" & 
                            HE(nombre) & " (" & activos & ")</option>")
                    End While
                End Using
            End Using
        End Using

        OptionsDelivery = sb.ToString()
    End Sub

    ' ============================================================
    ' CARGAR PEDIDOS (TABLA PRINCIPAL)
    ' ============================================================
    Private Sub CargarPedidos()
        Dim sb As New StringBuilder()
        TotalHoy = 0

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_sp_Pedido_Listar", conn)
                cmd.CommandType = CommandType.StoredProcedure
                
                ' Aplicar filtros
                cmd.Parameters.AddWithValue("@buscar", If(ValorBuscar = "", DirectCast(DBNull.Value, Object), ValorBuscar))
                cmd.Parameters.AddWithValue("@fecha_desde", If(ValorDesde = "", DirectCast(DBNull.Value, Object), ValorDesde))
                cmd.Parameters.AddWithValue("@fecha_hasta", If(ValorHasta = "", DirectCast(DBNull.Value, Object), ValorHasta))
                cmd.Parameters.AddWithValue("@solo_hoy", If(ValorSoloHoy = "1", 1, 0))
                cmd.Parameters.AddWithValue("@estado_pago", If(ValorEstadoPago = "", DirectCast(DBNull.Value, Object), ValorEstadoPago))
                cmd.Parameters.AddWithValue("@estado_operativo", If(ValorEstadoOp = "", DirectCast(DBNull.Value, Object), ValorEstadoOp))
                cmd.Parameters.AddWithValue("@zona_id", DBNull.Value)
                
                Dim deliveryParam As Object = DBNull.Value
                If ValorDelivery <> "" Then
                    Dim deliveryId As Integer = 0
                    If Integer.TryParse(ValorDelivery, deliveryId) AndAlso deliveryId > 0 Then
                        deliveryParam = deliveryId
                    End If
                End If
                cmd.Parameters.AddWithValue("@delivery_id", deliveryParam)
                
                cmd.Parameters.AddWithValue("@solo_express", If(ValorSoloExpress = "1", 1, 0))
                cmd.Parameters.AddWithValue("@pagina", 1)
                cmd.Parameters.AddWithValue("@por_pagina", 100)
                
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        TotalHoy += 1
                        sb.Append(RenderFilaPedido(dr))
                    End While
                End Using
            End Using
        End Using

        If TotalHoy = 0 Then
            sb.Append("<tr><td colspan=""8"" class=""table-empty"">")
            sb.Append("<i class=""ti ti-clipboard-off""></i>")
            sb.Append("No se encontraron pedidos con esos filtros.")
            sb.Append("</td></tr>")
        End If

        TablaPedidos = sb.ToString()
    End Sub

    Private Function RenderFilaPedido(dr As SqlDataReader) As String
        Dim sb As New StringBuilder()
        Dim pedidoId As Integer = CInt(dr("pedido_id"))
        Dim codigo As String = LeerStr(dr, "codigo")
        Dim wcNumber As String = LeerStr(dr, "wc_order_number")
        Dim receptor As String = LeerStr(dr, "receptor_nombre")
        Dim celular As String = LeerStr(dr, "receptor_celular")
        Dim direccion As String = LeerStr(dr, "direccion")
        Dim zona As String = LeerStr(dr, "zona_nombre")
        Dim slotEtiqueta As String = LeerStr(dr, "slot_etiqueta")
        Dim slotInicio As String = LeerHora(dr, "slot_hora_inicio")
        Dim esExpress As Boolean = LeerBool(dr, "es_express")
        Dim estadoPago As String = LeerStr(dr, "estado_pago")
        Dim estadoOp As String = LeerStr(dr, "estado_operativo")
        Dim deliveryNombre As String = LeerStr(dr, "delivery_nombre")
        
        sb.Append("<tr>")
        
        ' Columna 1: Hora con badge express
        sb.Append("<td><div class=""hora-stack"">")
        If esExpress Then
            sb.Append("<span class=""badge badge-express""><i class=""ti ti-bolt""></i> Express</span>")
        End If
        sb.Append("<span style=""font-size:12px;font-weight:500"">" & 
            If(slotInicio <> "", slotInicio, "--:--") & "</span>")
        sb.Append("</div></td>")
        
        ' Columna 2: Codigos
        sb.Append("<td><div class=""codigos-stack"">")
        sb.Append("<span class=""code-mono"">" & HE(codigo) & "</span>")
        If wcNumber <> "" Then
            sb.Append("<span class=""code-wc-small"">WC #" & HE(wcNumber) & "</span>")
        End If
        sb.Append("</div></td>")
        
        ' Columna 3: Receptor + direccion
        sb.Append("<td><div class=""receptor-info"">")
        sb.Append("<div class=""nombre"">" & HE(receptor) & "</div>")
        sb.Append("<div class=""dir"">" & HE(direccion) & " &middot; " & HE(celular) & "</div>")
        sb.Append("</div></td>")
        
        ' Columna 4: Zona
        sb.Append("<td><span style=""font-size:12px"">" & HE(zona) & "</span></td>")
        
        ' Columna 5: Estado pago
        sb.Append("<td>" & RenderBadgePago(estadoPago) & "</td>")
        
        ' Columna 6: Estado operativo
        sb.Append("<td>" & RenderBadgeOperativo(estadoOp) & "</td>")
        
        ' Columna 7: Delivery
        If deliveryNombre <> "" Then
            sb.Append("<td><span style=""font-size:12px"">" & HE(AbreviarNombre(deliveryNombre)) & "</span></td>")
        Else
            sb.Append("<td><span class=""delivery-vacio"">--</span></td>")
        End If
        
        ' Columna 8: Acciones
        sb.Append("<td><div class=""actions-cell"">")
        sb.Append("<button type=""button"" class=""btn-icon-only"" title=""Ver detalle"" onclick=""verDetalle(" & pedidoId & ")""><i class=""ti ti-eye""></i></button>")
        sb.Append("<button type=""button"" class=""btn-icon-only"" title=""Imprimir"" onclick=""imprimirTicket(" & pedidoId & ")""><i class=""ti ti-printer""></i></button>")
        sb.Append("<button type=""button"" class=""btn-icon-only"" title=""Cambiar estado"" onclick=""cambiarEstado(" & pedidoId & ",'" & HE(estadoOp) & "')""><i class=""ti ti-dots-vertical""></i></button>")
        sb.Append("</div></td>")
        
        sb.Append("</tr>")
        
        Return sb.ToString()
    End Function

    Private Function RenderBadgePago(estado As String) As String
        Select Case estado
            Case "PAGADO" : Return "<span class=""badge badge-pagado"">Pagado</span>"
            Case "ANTICIPO" : Return "<span class=""badge badge-anticipo"">Anticipo</span>"
            Case "PENDIENTE" : Return "<span class=""badge badge-pendiente"">Pendiente</span>"
            Case "REEMBOLSADO" : Return "<span class=""badge badge-no-entregado"">Reembolsado</span>"
            Case Else : Return "<span class=""badge"">" & HE(estado) & "</span>"
        End Select
    End Function

    Private Function RenderBadgeOperativo(estado As String) As String
        Select Case estado
            Case "PENDIENTE" : Return "<span class=""badge badge-pendiente"">Pendiente</span>"
            Case "IMPRESO" : Return "<span class=""badge badge-impreso"">Impreso</span>"
            Case "EN_PREPARACION" : Return "<span class=""badge badge-prep"">En prep.</span>"
            Case "LISTO" : Return "<span class=""badge badge-listo"">Listo</span>"
            Case "EN_RUTA" : Return "<span class=""badge badge-ruta"">En ruta</span>"
            Case "ENTREGADO" : Return "<span class=""badge badge-entregado"">Entregado</span>"
            Case "NO_ENTREGADO" : Return "<span class=""badge badge-no-entregado"">No entregado</span>"
            Case "REPROGRAMADO" : Return "<span class=""badge badge-reprogramado"">Reprog.</span>"
            Case Else : Return "<span class=""badge"">" & HE(estado) & "</span>"
        End Select
    End Function

    ' ============================================================
    ' POSTBACK PARA ACCIONES (aceptar pago, cambiar estado)
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
            ElseIf accion.StartsWith("CAMBIAR_ESTADO_") Then
                Dim estadoNuevo As String = accion.Substring("CAMBIAR_ESTADO_".Length)
                EjecutarCambiarEstado(pedidoId, estadoNuevo, usuarioId, ip)
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
        ' Mantener filtros al redirect
        Dim url As String = "GestionPedidos.aspx?msg=" & HttpUtility.UrlEncode(mensaje) & "&tipo=" & tipo
        If ValorBuscar <> "" Then url &= "&b=" & HttpUtility.UrlEncode(ValorBuscar)
        If ValorDesde <> "" Then url &= "&d=" & ValorDesde
        If ValorHasta <> "" Then url &= "&h=" & ValorHasta
        If ValorSoloHoy = "1" Then url &= "&hoy=1"
        If ValorEstadoPago <> "" Then url &= "&p=" & ValorEstadoPago
        If ValorEstadoOp <> "" Then url &= "&op=" & ValorEstadoOp
        If ValorDelivery <> "" Then url &= "&deli=" & ValorDelivery
        If ValorSoloExpress = "1" Then url &= "&exp=1"
        SesionHelper.RedirectSeguro(Context, url)
    End Sub

    ' ============================================================
    ' HELPERS
    ' ============================================================
    Private Function LeerStr(dr As SqlDataReader, campo As String) As String
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return ""
            Return dr(idx).ToString()
        Catch
            Return ""
        End Try
    End Function

    Private Function LeerInt(dr As SqlDataReader, campo As String) As Integer
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return 0
            Return CInt(dr(idx))
        Catch
            Return 0
        End Try
    End Function

    Private Function LeerDec(dr As SqlDataReader, campo As String) As Decimal
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return 0D
            Return CDec(dr(idx))
        Catch
            Return 0D
        End Try
    End Function

    Private Function LeerBool(dr As SqlDataReader, campo As String) As Boolean
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return False
            Return CBool(dr(idx))
        Catch
            Return False
        End Try
    End Function

    Private Function LeerFecha(dr As SqlDataReader, campo As String) As DateTime
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return DateTime.MinValue
            Return CDate(dr(idx))
        Catch
            Return DateTime.MinValue
        End Try
    End Function

    Private Function LeerHora(dr As SqlDataReader, campo As String) As String
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return ""
            Dim val As Object = dr(idx)
            If TypeOf val Is TimeSpan Then
                Dim ts As TimeSpan = CType(val, TimeSpan)
                Return ts.Hours.ToString("D2") & ":" & ts.Minutes.ToString("D2")
            End If
            Return val.ToString()
        Catch
            Return ""
        End Try
    End Function

    Private Function HE(texto As String) As String
        ' HtmlEncode simple
        If texto Is Nothing Then Return ""
        Return HttpUtility.HtmlEncode(texto)
    End Function

    Private Function AbreviarNombre(nombreCompleto As String) As String
        If nombreCompleto Is Nothing OrElse nombreCompleto.Trim() = "" Then Return ""
        Dim partes As String() = nombreCompleto.Trim().Split(" "c)
        If partes.Length >= 2 Then
            Return partes(0) & " " & partes(1).Substring(0, 1) & "."
        End If
        Return nombreCompleto
    End Function

End Class
