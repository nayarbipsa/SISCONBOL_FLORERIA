Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

' ============================================================
' SISCONBOL - Recibo Termico (ticket 80mm)
' Archivo: Modulos/Pedidos/Recibo.aspx.vb
'
' Pagina STANDALONE (sin MasterPage) para imprimir.
' Se accede via ?id={pedido_id}  (id de FLORERIA_Pedido)
'
' Si el usuario no esta logueado, redirige a Login.
' Si el pedido no existe, muestra mensaje.
' ============================================================
Partial Public Class Modulos_Pedidos_Recibo
    Inherits System.Web.UI.Page

    ' --- Propiedades expuestas al .aspx ---
    Public Property PedidoId As Integer = 0
    Public Property PedidoCodigo As String = ""
    Public Property PrePedidoCodigo As String = ""
    Public Property WcNumero As String = "—"
    Public Property FechaCreado As String = ""

    Public Property FechaEntrega As String = ""
    Public Property Horario As String = "Sin horario"
    Public Property TipoEntrega As String = "Domicilio"

    Public Property ReceptorNombre As String = ""
    Public Property ReceptorCelular As String = ""

    Public Property ClienteNombre As String = ""
    Public Property ClienteCelular As String = ""

    Public Property SubtotalBs As String = "0.00"
    Public Property TotalBs As String = "0.00"

    Public Property MetodoPago As String = "—"
    Public Property EstadoPago As String = "—"
    Public Property MontoPagadoBs As String = "0.00"

    ' Bloques HTML condicionales
    Public Property BloqueExpress As String = ""
    Public Property BloqueDireccion As String = ""
    Public Property BloqueOcasion As String = ""
    Public Property HtmlProductos As String = ""
    Public Property BloqueTarjeta As String = ""
    Public Property BloqueNotaFloreria As String = ""
    Public Property BloqueEnvio As String = ""
    Public Property BloqueRecargoHor As String = ""
    Public Property BloqueRecargoExp As String = ""
    Public Property BloqueDescuento As String = ""
    Public Property BloqueSaldo As String = ""
    Public Property BloqueAgente As String = ""

    ' ============================================================
    ' Page_Load
    ' ============================================================
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Verificar sesion (este recibo es solo para empleados)
        If Not SesionHelper.VerificarSesion(HttpContext.Current) Then
            Response.Redirect("~/Login.aspx", False)
            Return
        End If

        ' Resolver pedido_id
        Dim qId As String = Request.QueryString("id")
        If String.IsNullOrEmpty(qId) OrElse Not Integer.TryParse(qId, PedidoId) OrElse PedidoId <= 0 Then
            Response.Write("Pedido invalido")
            Response.End()
            Return
        End If

        Try
            CargarRecibo()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Recibo.CargarRecibo: " & ex.Message)
            Response.Write("Error al cargar el recibo: " & Server.HtmlEncode(ex.Message))
            Response.End()
        End Try
    End Sub

    ' ============================================================
    ' CargarRecibo - SELECT del pedido + prepedido + items + pagos
    ' ============================================================
    Private Sub CargarRecibo()
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()

            ' --- 1. Pedido + joins ---
            Dim sql As String =
                "SELECT p.pedido_id, p.codigo, p.prepedido_id, " &
                "       p.receptor_nombre, p.receptor_celular, " &
                "       p.direccion, p.referencia, p.gps, " &
                "       p.fecha_entrega, p.es_express, " &
                "       p.dedicatoria, p.firma_tarjeta, p.tipo_ocacion, " &
                "       p.nota_floreria, p.observaciones, " &
                "       p.subtotal_productos_bs, p.envio_bs, " &
                "       p.recargo_express_bs, p.recargo_horario_bs, " &
                "       p.descuento_bs, p.total_bs, " &
                "       p.tipo_entrega, " &
                "       p.wc_order_id, p.wc_order_number, " &
                "       p.wc_payment_method, p.wc_payment_method_title, " &
                "       p.creado_en, p.creado_por, " &
                "       c.nombre AS ciudad_nombre, " &
                "       z.nombre AS zona_nombre, " &
                "       sl.etiqueta AS slot_etiqueta, " &
                "       sl.hora_inicio, sl.hora_fin, " &
                "       pp.codigo AS prepedido_codigo, " &
                "       pp.cliente_nombre, pp.cliente_apellidos, pp.cliente_celular, " &
                "       u.nombres AS agente_nombre, u.apellidos AS agente_apellidos " &
                "FROM FLORERIA_Pedido p " &
                "LEFT JOIN FLORERIA_Ciudad c     ON c.ciudad_id = p.ciudad_id " &
                "LEFT JOIN FLORERIA_Zona   z     ON z.zona_id   = p.zona_id " &
                "LEFT JOIN FLORERIA_Slot_Horario sl ON sl.slot_id = p.slot_id " &
                "LEFT JOIN FLORERIA_PrePedido pp ON pp.prepedido_id = p.prepedido_id " &
                "LEFT JOIN FLORERIA_Usuario  u  ON u.usuario_id  = p.creado_por " &
                "WHERE p.pedido_id = @id"

            Dim pedidoEncontrado As Boolean = False
            Dim prePedidoId As Integer = 0
            Dim totalBsNum As Decimal = 0
            Dim direccion As String = ""
            Dim referencia As String = ""
            Dim gps As String = ""
            Dim ocasion As String = ""
            Dim dedicatoria As String = ""
            Dim firmaTarjeta As String = ""
            Dim notaFloreria As String = ""
            Dim envioBs As Decimal = 0
            Dim recHor As Decimal = 0
            Dim recExp As Decimal = 0
            Dim descBs As Decimal = 0
            Dim esExpress As Boolean = False
            Dim slotEtiqueta As String = ""
            Dim slotHoraIni As Object = Nothing
            Dim slotHoraFin As Object = Nothing
            Dim wcOrderId As Integer = 0
            Dim wcOrderNumber As String = ""
            Dim wcPaymentMethodTitle As String = ""
            Dim agenteNombre As String = ""
            Dim agenteApellidos As String = ""

            Using cmd As New SqlCommand(sql, conn)
                cmd.Parameters.AddWithValue("@id", PedidoId)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        pedidoEncontrado = True

                        PedidoCodigo    = dr("codigo").ToString()
                        prePedidoId     = If(IsDBNull(dr("prepedido_id")), 0, CInt(dr("prepedido_id")))
                        ReceptorNombre  = dr("receptor_nombre").ToString()
                        ReceptorCelular = dr("receptor_celular").ToString()

                        direccion       = If(IsDBNull(dr("direccion")),     "", dr("direccion").ToString())
                        referencia      = If(IsDBNull(dr("referencia")),    "", dr("referencia").ToString())
                        gps             = If(IsDBNull(dr("gps")),           "", dr("gps").ToString())
                        ocasion         = If(IsDBNull(dr("tipo_ocacion")),  "", dr("tipo_ocacion").ToString())
                        dedicatoria     = If(IsDBNull(dr("dedicatoria")),   "", dr("dedicatoria").ToString())
                        firmaTarjeta    = If(IsDBNull(dr("firma_tarjeta")), "", dr("firma_tarjeta").ToString())
                        notaFloreria    = If(IsDBNull(dr("nota_floreria")), "", dr("nota_floreria").ToString())
                        esExpress       = If(IsDBNull(dr("es_express")),    False, CBool(dr("es_express")))

                        If Not IsDBNull(dr("fecha_entrega")) Then
                            Dim fe As DateTime = CDate(dr("fecha_entrega"))
                            FechaEntrega = fe.ToString("dddd dd MMM yyyy", New System.Globalization.CultureInfo("es-ES"))
                        End If

                        slotEtiqueta = If(IsDBNull(dr("slot_etiqueta")), "", dr("slot_etiqueta").ToString())
                        slotHoraIni  = If(IsDBNull(dr("hora_inicio")), Nothing, dr("hora_inicio"))
                        slotHoraFin  = If(IsDBNull(dr("hora_fin")),    Nothing, dr("hora_fin"))

                        Dim tipoEntDb As String = If(IsDBNull(dr("tipo_entrega")), "DOMICILIO", dr("tipo_entrega").ToString())
                        TipoEntrega = If(tipoEntDb = "RECOJO_SUCURSAL", "RECOJO EN SUCURSAL", "Domicilio")

                        envioBs = If(IsDBNull(dr("envio_bs")),             0D, CDec(dr("envio_bs")))
                        recHor  = If(IsDBNull(dr("recargo_horario_bs")),   0D, CDec(dr("recargo_horario_bs")))
                        recExp  = If(IsDBNull(dr("recargo_express_bs")),   0D, CDec(dr("recargo_express_bs")))
                        descBs  = If(IsDBNull(dr("descuento_bs")),         0D, CDec(dr("descuento_bs")))

                        Dim subtotalNum As Decimal = If(IsDBNull(dr("subtotal_productos_bs")), 0D, CDec(dr("subtotal_productos_bs")))
                        totalBsNum                 = If(IsDBNull(dr("total_bs")),              0D, CDec(dr("total_bs")))
                        SubtotalBs = subtotalNum.ToString("N2")
                        TotalBs    = totalBsNum.ToString("N2")

                        wcOrderId            = If(IsDBNull(dr("wc_order_id")),     0,  CInt(dr("wc_order_id")))
                        wcOrderNumber        = If(IsDBNull(dr("wc_order_number")), "", dr("wc_order_number").ToString())
                        wcPaymentMethodTitle = If(IsDBNull(dr("wc_payment_method_title")), "", dr("wc_payment_method_title").ToString())

                        If Not IsDBNull(dr("creado_en")) Then
                            FechaCreado = CDate(dr("creado_en")).ToString("dd/MM/yyyy HH:mm")
                        End If

                        PrePedidoCodigo = If(IsDBNull(dr("prepedido_codigo")), "—", dr("prepedido_codigo").ToString())

                        Dim cn As String = If(IsDBNull(dr("cliente_nombre")),    "", dr("cliente_nombre").ToString())
                        Dim ca As String = If(IsDBNull(dr("cliente_apellidos")), "", dr("cliente_apellidos").ToString())
                        ClienteNombre   = (cn.Trim() & " " & ca.Trim()).Trim()
                        If ClienteNombre = "" Then ClienteNombre = "—"
                        ClienteCelular  = If(IsDBNull(dr("cliente_celular")), "—", dr("cliente_celular").ToString())

                        agenteNombre    = If(IsDBNull(dr("agente_nombre")),    "", dr("agente_nombre").ToString())
                        agenteApellidos = If(IsDBNull(dr("agente_apellidos")), "", dr("agente_apellidos").ToString())
                    End If
                End Using
            End Using

            If Not pedidoEncontrado Then
                Response.Write("Pedido no encontrado")
                Response.End()
                Return
            End If

            ' --- 2. Numero WooCommerce visible ---
            If wcOrderId > 0 Then
                If wcOrderNumber <> "" AndAlso wcOrderNumber <> wcOrderId.ToString() Then
                    WcNumero = "#" & wcOrderNumber
                Else
                    WcNumero = "#" & wcOrderId.ToString()
                End If
            Else
                WcNumero = "Sin WC"
            End If

            ' --- 3. Horario formateado ---
            If slotEtiqueta <> "" Then
                Horario = slotEtiqueta
                If slotHoraIni IsNot Nothing AndAlso slotHoraFin IsNot Nothing Then
                    Dim hi As TimeSpan = CType(slotHoraIni, TimeSpan)
                    Dim hf As TimeSpan = CType(slotHoraFin, TimeSpan)
                    Horario &= " (" & hi.ToString("hh\:mm") & " - " & hf.ToString("hh\:mm") & ")"
                End If
            ElseIf slotHoraIni IsNot Nothing AndAlso slotHoraFin IsNot Nothing Then
                Dim hi As TimeSpan = CType(slotHoraIni, TimeSpan)
                Dim hf As TimeSpan = CType(slotHoraFin, TimeSpan)
                Horario = hi.ToString("hh\:mm") & " - " & hf.ToString("hh\:mm")
            End If

            ' --- 4. Bloque EXPRESS ---
            If esExpress Then
                BloqueExpress = "<div class='express'>* * *  EXPRESS  * * *</div>"
            End If

            ' --- 5. Bloque DIRECCION ---
            If direccion <> "" OrElse referencia <> "" OrElse gps <> "" Then
                Dim sb As New StringBuilder()
                If direccion <> "" Then
                    sb.Append("<div class='fila'><span class='lbl'>Direccion:</span><span class='val'>").Append(Server.HtmlEncode(direccion)).Append("</span></div>")
                End If
                If referencia <> "" Then
                    sb.Append("<div class='fila'><span class='lbl'>Referencia:</span><span class='val'>").Append(Server.HtmlEncode(referencia)).Append("</span></div>")
                End If
                If gps <> "" Then
                    sb.Append("<div class='fila'><span class='lbl'>GPS:</span><span class='val'>").Append(Server.HtmlEncode(gps)).Append("</span></div>")
                End If
                BloqueDireccion = sb.ToString()
            End If

            ' --- 6. Bloque OCASION ---
            If ocasion <> "" Then
                BloqueOcasion = "<div class='fila'><span class='lbl'>Ocasion:</span><span class='val'>" & Server.HtmlEncode(MapearOcasion(ocasion)) & "</span></div>"
            End If

            ' --- 7. Productos del pedido ---
            HtmlProductos = CargarProductos(conn)

            ' --- 8. Bloque TARJETA (dedicatoria + firma) ---
            If dedicatoria <> "" OrElse firmaTarjeta <> "" Then
                Dim sbT As New StringBuilder()
                sbT.Append("<div class='sep'></div>")
                sbT.Append("<div class='titBloque'>Tarjeta</div>")
                sbT.Append("<div class='tarjeta'>")
                If dedicatoria <> "" Then
                    sbT.Append("<div class='ded'>""").Append(Server.HtmlEncode(dedicatoria)).Append("""</div>")
                End If
                If firmaTarjeta <> "" Then
                    sbT.Append("<div class='fir'>— ").Append(Server.HtmlEncode(firmaTarjeta)).Append("</div>")
                End If
                sbT.Append("</div>")
                BloqueTarjeta = sbT.ToString()
            End If

            ' --- 9. Bloque NOTA FLORERIA ---
            If notaFloreria <> "" Then
                Dim sbN As New StringBuilder()
                sbN.Append("<div class='sep'></div>")
                sbN.Append("<div class='titBloque'>Nota para Floreria</div>")
                sbN.Append("<div class='nota'>").Append(Server.HtmlEncode(notaFloreria)).Append("</div>")
                BloqueNotaFloreria = sbN.ToString()
            End If

            ' --- 10. Bloques de totales condicionales ---
            If envioBs > 0 Then
                BloqueEnvio = "<div class='fila'><span>Envio:</span><span>Bs " & envioBs.ToString("N2") & "</span></div>"
            End If
            If recHor > 0 Then
                BloqueRecargoHor = "<div class='fila'><span>Recargo horario:</span><span>Bs " & recHor.ToString("N2") & "</span></div>"
            End If
            If recExp > 0 Then
                BloqueRecargoExp = "<div class='fila'><span>Recargo express:</span><span>Bs " & recExp.ToString("N2") & "</span></div>"
            End If
            If descBs > 0 Then
                BloqueDescuento = "<div class='fila'><span>Descuento:</span><span>- Bs " & descBs.ToString("N2") & "</span></div>"
            End If

            ' --- 11. Pago: leer del prepedido (suma de verificados) ---
            If prePedidoId > 0 Then
                CargarPagos(conn, prePedidoId, totalBsNum, wcPaymentMethodTitle)
            Else
                MetodoPago    = If(wcPaymentMethodTitle <> "", wcPaymentMethodTitle, "—")
                EstadoPago    = "VERIFICADO"
                MontoPagadoBs = totalBsNum.ToString("N2")
            End If

            ' --- 12. Agente ---
            Dim agenteFull As String = (agenteNombre.Trim() & " " & agenteApellidos.Trim()).Trim()
            If agenteFull <> "" Then
                BloqueAgente = "<div>Atendido por: " & Server.HtmlEncode(agenteFull) & "</div>"
            End If

        End Using
    End Sub

    ' ============================================================
    ' CargarProductos - lista de items del pedido
    ' ============================================================
    Private Function CargarProductos(conn As SqlConnection) As String
        Dim sb As New StringBuilder()
        Dim sql As String =
            "SELECT nombre_producto, cantidad, precio_unitario_bs, subtotal_bs, personalizacion, es_personalizado " &
            "FROM FLORERIA_Pedido_Detalle " &
            "WHERE pedido_id = @id"

        Using cmd As New SqlCommand(sql, conn)
            cmd.Parameters.AddWithValue("@id", PedidoId)
            Using dr As SqlDataReader = cmd.ExecuteReader()
                While dr.Read()
                    Dim nom As String = dr("nombre_producto").ToString()
                    Dim cant As Integer = CInt(dr("cantidad"))
                    Dim precio As Decimal = CDec(dr("precio_unitario_bs"))
                    Dim subtotal As Decimal = CDec(dr("subtotal_bs"))
                    Dim pers As String = If(IsDBNull(dr("personalizacion")), "", dr("personalizacion").ToString())

                    sb.Append("<div class='prod'>")
                    sb.Append("  <div class='nom'>").Append(cant).Append(" x ").Append(Server.HtmlEncode(nom)).Append("</div>")
                    sb.Append("  <div class='pre det'>")
                    sb.Append("    <span>Bs ").Append(precio.ToString("N2")).Append(" c/u</span>")
                    sb.Append("    <span>Bs ").Append(subtotal.ToString("N2")).Append("</span>")
                    sb.Append("  </div>")
                    If pers <> "" Then
                        sb.Append("  <div class='pers'>&gt; ").Append(Server.HtmlEncode(pers)).Append("</div>")
                    End If
                    sb.Append("</div>")
                End While
            End Using
        End Using

        If sb.Length = 0 Then sb.Append("<div class='prod'><div class='det'>(Sin productos)</div></div>")
        Return sb.ToString()
    End Function

    ' ============================================================
    ' CargarPagos - resumen del pago para el prepedido completo
    ' Muestra: metodo principal (ultimo verificado), suma de verificados,
    '          estado del pago, y saldo pendiente si lo hay.
    ' ============================================================
    Private Sub CargarPagos(conn As SqlConnection, prePedidoId As Integer, totalPedido As Decimal, wcMethodTitle As String)
        Dim sumaVerificado As Decimal = 0
        Dim metodoUltimo As String = ""

        ' Sumar pagos verificados de TODAS las entregas del prepedido
        ' (esto es importante si hay varias entregas pero un solo pago global)
        ' Pero para este recibo, el monto pagado se considera SOLO el del pedido (que es 1 entrega)
        ' Lectura: pagos del prepedido_entrega correspondiente a este pedido
        Dim sql As String =
            "SELECT pa.metodo_pago, pa.monto_bs, pa.estado " &
            "FROM FLORERIA_PrePedido_Entrega_Pago pa " &
            "INNER JOIN FLORERIA_PrePedido_Entrega e " &
            "    ON e.prepedido_entrega_id = pa.prepedido_entrega_id " &
            "WHERE e.pedido_id = @pid " &
            "  AND pa.estado <> 'RECHAZADO' " &
            "ORDER BY pa.creado_en"

        Using cmd As New SqlCommand(sql, conn)
            cmd.Parameters.AddWithValue("@pid", PedidoId)
            Using dr As SqlDataReader = cmd.ExecuteReader()
                While dr.Read()
                    Dim met As String = dr("metodo_pago").ToString()
                    Dim mon As Decimal = CDec(dr("monto_bs"))
                    Dim est As String = dr("estado").ToString()
                    If est = "VERIFICADO" Then
                        sumaVerificado += mon
                        metodoUltimo = met
                    End If
                End While
            End Using
        End Using

        If metodoUltimo = "" Then
            MetodoPago = If(wcMethodTitle <> "", wcMethodTitle, "—")
        Else
            MetodoPago = MapearMetodo(metodoUltimo)
        End If

        MontoPagadoBs = sumaVerificado.ToString("N2")

        Dim saldo As Decimal = totalPedido - sumaVerificado
        If saldo <= 0.01D Then
            EstadoPago = "PAGADO"
        ElseIf sumaVerificado > 0 Then
            EstadoPago = "ANTICIPO"
            BloqueSaldo = "<div class='fila'><span class='lbl'>Saldo a cobrar:</span><span class='val'><b>Bs " & saldo.ToString("N2") & "</b></span></div>"
        Else
            EstadoPago = "PENDIENTE"
            BloqueSaldo = "<div class='fila'><span class='lbl'>Saldo a cobrar:</span><span class='val'><b>Bs " & totalPedido.ToString("N2") & "</b></span></div>"
        End If
    End Sub

    ' ============================================================
    ' Helpers de formato
    ' ============================================================
    Private Function MapearOcasion(codigo As String) As String
        Select Case codigo.ToUpper()
            Case "CUMPLEANOS"  : Return "Cumpleaños"
            Case "ANIVERSARIO" : Return "Aniversario"
            Case "AMOR"        : Return "Amor"
            Case "AMISTAD"     : Return "Amistad"
            Case "CONDOLENCIAS" : Return "Condolencias"
            Case "GRADUACION"  : Return "Graduación"
            Case "AGRADECIMIENTO" : Return "Agradecimiento"
            Case "DISCULPAS"   : Return "Disculpas"
            Case Else          : Return codigo
        End Select
    End Function

    Private Function MapearMetodo(codigo As String) As String
        Select Case codigo.ToUpper()
            Case "EFECTIVO"      : Return "Efectivo"
            Case "QR"            : Return "QR Bolivia (BNB)"
            Case "TRANSFERENCIA" : Return "Transferencia"
            Case "PAYPAL"        : Return "PayPal"
            Case "CRIPTO"        : Return "Cripto USDT"
            Case "YAPE"          : Return "Yape"
            Case "PIX"           : Return "Pix"
            Case "TARJETA"       : Return "Tarjeta"
            Case "PAGOMOVIL"     : Return "Pago Movil"
            Case Else            : Return codigo
        End Select
    End Function

End Class
