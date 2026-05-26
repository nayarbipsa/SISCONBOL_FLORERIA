Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

' ============================================================
' SISCONBOL - Recibo Termico (ticket 80mm)
' Archivo: Modulos/Pedidos/Recibo.aspx.vb
' Acceso: ?id={pedido_id}
' Sin MasterPage. Solo para empleados (verifica sesion).
' ============================================================
Partial Public Class Modulos_Pedidos_Recibo
    Inherits System.Web.UI.Page

    ' --- Encabezado ---
    Public Property PedidoId As Integer = 0
    Public Property PedidoCodigo As String = ""
    Public Property WcNumero As String = "---"
    Public Property LineaPreFecha As String = ""
    Public Property LineaAgente As String = ""
    Public Property BloqueSucursalBadge As String = ""

    ' --- Alertas arriba ---
    Public Property BloqueExpress As String = ""
    Public Property BloqueCobrar As String = ""

    ' --- Cliente ---
    Public Property ClienteNombre As String = "---"
    Public Property ClienteCelular As String = "---"

    ' --- Entrega ---
    Public Property FechaEntrega As String = ""
    Public Property Horario As String = "Sin horario"
    Public Property ZonaNombre As String = ""

    ' --- Productos ---
    Public Property HtmlProductos As String = ""
    Public Property BloqueNotaFloreria As String = ""

    ' --- Destinatario ---
    Public Property ReceptorNombre As String = ""
    Public Property ReceptorCelular As String = ""
    Public Property BloqueDireccion As String = ""
    Public Property BloqueOcasion As String = ""

    ' --- Tarjeta ---
    Public Property BloqueTarjeta As String = ""

    ' --- Pago ---
    Public Property MetodoPago As String = "---"
    Public Property EstadoPago As String = "---"

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not SesionHelper.VerificarSesion(HttpContext.Current) Then
            Response.Redirect("~/Login.aspx", False)
            Return
        End If
        Dim qId As String = Request.QueryString("id")
        If String.IsNullOrEmpty(qId) OrElse Not Integer.TryParse(qId, PedidoId) OrElse PedidoId <= 0 Then
            Response.Write("Pedido invalido") : Response.End() : Return
        End If
        Try
            CargarRecibo()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Recibo.CargarRecibo: " & ex.Message)
            Response.Write("Error al cargar el recibo: " & Server.HtmlEncode(ex.Message))
            Response.End()
        End Try
    End Sub

    Private Sub CargarRecibo()
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()

            Dim sql As String =
                "SELECT p.pedido_id, p.codigo, p.prepedido_id, " &
                "       p.receptor_nombre, p.receptor_celular, " &
                "       p.direccion, p.referencia, " &
                "       p.fecha_entrega, p.es_express, " &
                "       p.dedicatoria, p.firma_tarjeta, p.tipo_ocacion, " &
                "       p.nota_floreria, p.tipo_entrega, " &
                "       p.wc_order_id, p.wc_order_number, " &
                "       p.wc_payment_method_title, p.creado_en, " &
                "       z.nombre AS zona_nombre, " &
                "       sl.etiqueta AS slot_etiqueta, sl.hora_inicio, sl.hora_fin, " &
                "       pp.codigo AS prepedido_codigo, " &
                "       pp.cliente_nombre, pp.cliente_apellidos, pp.cliente_celular, " &
                "       u.nombres AS agente_nombres, u.apellidos AS agente_apellidos, " &
                "       sp.nombre AS sucursal_prepara_nombre " &
                "FROM FLORERIA_Pedido p " &
                "LEFT JOIN FLORERIA_Zona         z   ON z.zona_id       = p.zona_id " &
                "LEFT JOIN FLORERIA_Slot_Horario sl  ON sl.slot_id      = p.slot_id " &
                "LEFT JOIN FLORERIA_PrePedido    pp  ON pp.prepedido_id = p.prepedido_id " &
                "LEFT JOIN FLORERIA_Usuario      u   ON u.usuario_id    = p.creado_por " &
                "LEFT JOIN FLORERIA_Sucursal     sp  ON sp.sucursal_id  = p.sucursal_prepara_id " &
                "WHERE p.pedido_id = @id"

            Dim encontrado As Boolean = False
            Dim wcOrderId As Integer = 0
            Dim wcOrderNumber As String = ""
            Dim wcMethodTitle As String = ""
            Dim dedicatoria As String = ""
            Dim firmaTarjeta As String = ""
            Dim ocasion As String = ""
            Dim notaFloreria As String = ""
            Dim esExpress As Boolean = False
            Dim tipoEntrega As String = "DOMICILIO"
            Dim direccion As String = ""
            Dim referencia As String = ""
            Dim sucursalNombre As String = ""

            Using cmd As New SqlCommand(sql, conn)
                cmd.Parameters.AddWithValue("@id", PedidoId)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        encontrado = True

                        PedidoCodigo    = QuitarCeros(dr("codigo").ToString())
                        ReceptorNombre  = dr("receptor_nombre").ToString()
                        ReceptorCelular = dr("receptor_celular").ToString()
                        direccion       = If(IsDBNull(dr("direccion")),    "", dr("direccion").ToString())
                        referencia      = If(IsDBNull(dr("referencia")),   "", dr("referencia").ToString())
                        esExpress       = If(IsDBNull(dr("es_express")),   False, CBool(dr("es_express")))
                        dedicatoria     = If(IsDBNull(dr("dedicatoria")),  "", dr("dedicatoria").ToString())
                        firmaTarjeta    = If(IsDBNull(dr("firma_tarjeta")),"", dr("firma_tarjeta").ToString())
                        ocasion         = If(IsDBNull(dr("tipo_ocacion")), "", dr("tipo_ocacion").ToString())
                        notaFloreria    = If(IsDBNull(dr("nota_floreria")),"", dr("nota_floreria").ToString())
                        tipoEntrega     = If(IsDBNull(dr("tipo_entrega")), "DOMICILIO", dr("tipo_entrega").ToString())
                        ZonaNombre      = If(IsDBNull(dr("zona_nombre")),  "", dr("zona_nombre").ToString())
                        sucursalNombre  = If(IsDBNull(dr("sucursal_prepara_nombre")), "", dr("sucursal_prepara_nombre").ToString())
                        wcOrderId       = If(IsDBNull(dr("wc_order_id")),     0,  CInt(dr("wc_order_id")))
                        wcOrderNumber   = If(IsDBNull(dr("wc_order_number")), "", dr("wc_order_number").ToString())
                        wcMethodTitle   = If(IsDBNull(dr("wc_payment_method_title")), "", dr("wc_payment_method_title").ToString())

                        ' Fecha entrega
                        If Not IsDBNull(dr("fecha_entrega")) Then
                            FechaEntrega = CDate(dr("fecha_entrega")).ToString("ddd dd MMM yyyy", New System.Globalization.CultureInfo("es-ES"))
                        End If

                        ' Horario: la etiqueta ya incluye el intervalo (ej: "Manana (09:00 - 12:00)")
                        ' Si la etiqueta tiene ":" significa que ya trae horas -> usar solo etiqueta
                        ' Si no tiene horas, concatenar etiqueta + intervalo de hora_inicio/hora_fin
                        Dim slotEt As String = If(IsDBNull(dr("slot_etiqueta")), "", dr("slot_etiqueta").ToString())
                        Dim etiquetaTieneHoras As Boolean = slotEt.Contains(":")
                        If etiquetaTieneHoras Then
                            Horario = slotEt
                        ElseIf Not IsDBNull(dr("hora_inicio")) AndAlso Not IsDBNull(dr("hora_fin")) Then
                            Dim hi As TimeSpan = CType(dr("hora_inicio"), TimeSpan)
                            Dim hf As TimeSpan = CType(dr("hora_fin"),    TimeSpan)
                            Dim intv As String = hi.ToString("hh\:mm") & " - " & hf.ToString("hh\:mm")
                            Horario = If(slotEt <> "", slotEt & " " & intv, intv)
                        ElseIf slotEt <> "" Then
                            Horario = slotEt
                        End If

                        ' Linea PRE | fecha
                        Dim preStr As String = ""
                        If Not IsDBNull(dr("prepedido_codigo")) Then
                            preStr = QuitarCeros(dr("prepedido_codigo").ToString()) & " | "
                        End If
                        If Not IsDBNull(dr("creado_en")) Then
                            preStr &= CDate(dr("creado_en")).ToString("dd/MM/yyyy HH:mm")
                        End If
                        LineaPreFecha = preStr

                        ' Agente
                        Dim an As String = If(IsDBNull(dr("agente_nombres")),    "", dr("agente_nombres").ToString().Trim())
                        Dim aa As String = If(IsDBNull(dr("agente_apellidos")), "", dr("agente_apellidos").ToString().Trim())
                        Dim ag As String = (an & " " & aa).Trim()
                        If ag <> "" Then LineaAgente = "Atendido por: " & ag

                        ' Cliente
                        Dim cn As String = If(IsDBNull(dr("cliente_nombre")),    "", dr("cliente_nombre").ToString().Trim())
                        Dim ca As String = If(IsDBNull(dr("cliente_apellidos")), "", dr("cliente_apellidos").ToString().Trim())
                        ClienteNombre  = (cn & " " & ca).Trim()
                        If ClienteNombre = "" Then ClienteNombre = "---"
                        ClienteCelular = If(IsDBNull(dr("cliente_celular")), "---", dr("cliente_celular").ToString())
                    End If
                End Using
            End Using

            If Not encontrado Then
                Response.Write("Pedido no encontrado") : Response.End() : Return
            End If

            ' Numero WC
            WcNumero = If(wcOrderId > 0, "#" & If(wcOrderNumber <> "", wcOrderNumber, wcOrderId.ToString()), "Sin WC")

            ' Badge sucursal (3 letras en mayuscula)
            If sucursalNombre <> "" Then
                Dim letras As String = sucursalNombre.ToUpper()
                If letras.Length > 3 Then letras = letras.Substring(0, 3)
                BloqueSucursalBadge = "<span style='border:2px solid #000;padding:1mm 2mm;font-weight:bold;font-size:12pt;letter-spacing:1px'>" & Server.HtmlEncode(letras) & "</span>"
            End If

            ' EXPRESS
            If esExpress Then
                BloqueExpress = "<div class='alerta-box'>* * * EXPRESS * * *</div>"
            End If

            ' Pago (calcula saldo y bloque COBRAR)
            CargarPago(conn, wcMethodTitle)

            ' Productos
            HtmlProductos = CargarProductos(conn)

            ' Nota floreria
            If notaFloreria <> "" Then
                BloqueNotaFloreria = "<div class='sep'></div><div class='titBloque'>Nota para Floreria</div><div class='nota'>" & Server.HtmlEncode(notaFloreria) & "</div>"
            End If

            ' Direccion con zona y tipo entre parentesis
            Dim sbD As New StringBuilder()
            If direccion <> "" Then
                Dim d As String = direccion.Trim()
                If ZonaNombre <> "" Then d &= ", " & ZonaNombre
                d &= " (" & If(tipoEntrega = "RECOJO_SUCURSAL", "Recojo", "Domicilio") & ")"
                sbD.Append("<div class='fila'><span class='lbl'>Direccion:</span><span class='val'>").Append(Server.HtmlEncode(d)).Append("</span></div>")
            End If
            If referencia <> "" Then
                sbD.Append("<div class='fila'><span class='lbl'>Referencia:</span><span class='val'>").Append(Server.HtmlEncode(referencia)).Append("</span></div>")
            End If
            BloqueDireccion = sbD.ToString()

            ' Ocasion (no mostrar si es OTRO o vacio)
            If ocasion <> "" AndAlso ocasion.ToUpper() <> "OTRO" Then
                BloqueOcasion = "<div class='fila'><span class='lbl'>Ocasion:</span><span class='val'>" & Server.HtmlEncode(MapearOcasion(ocasion)) & "</span></div>"
            End If

            ' Tarjeta
            If dedicatoria <> "" OrElse firmaTarjeta <> "" Then
                Dim sbT As New StringBuilder()
                sbT.Append("<div class='sep'></div><div class='titBloque'>Tarjeta</div><div class='tarjeta'>")
                If dedicatoria <> "" Then sbT.Append("<div class='ded'>&ldquo;").Append(Server.HtmlEncode(dedicatoria)).Append("&rdquo;</div>")
                If firmaTarjeta <> "" Then sbT.Append("<div class='fir'>&mdash; ").Append(Server.HtmlEncode(firmaTarjeta)).Append("</div>")
                sbT.Append("</div>")
                BloqueTarjeta = sbT.ToString()
            End If

        End Using
    End Sub

    Private Sub CargarPago(conn As SqlConnection, wcMethodTitle As String)
        Dim sumaVer As Decimal = 0
        Dim totalBs As Decimal = 0
        Dim metodo As String = ""

        Using cmd As New SqlCommand("SELECT ISNULL(total_bs,0) FROM FLORERIA_Pedido WHERE pedido_id=@id", conn)
            cmd.Parameters.AddWithValue("@id", PedidoId)
            Dim r As Object = cmd.ExecuteScalar()
            If r IsNot Nothing AndAlso Not IsDBNull(r) Then totalBs = CDec(r)
        End Using

        Using cmd As New SqlCommand(
            "SELECT pa.metodo_pago, pa.monto_bs " &
            "FROM FLORERIA_PrePedido_Entrega_Pago pa " &
            "INNER JOIN FLORERIA_PrePedido_Entrega e ON e.prepedido_entrega_id = pa.prepedido_entrega_id " &
            "WHERE e.pedido_id = @pid AND pa.estado = 'VERIFICADO' ORDER BY pa.creado_en", conn)
            cmd.Parameters.AddWithValue("@pid", PedidoId)
            Using dr As SqlDataReader = cmd.ExecuteReader()
                While dr.Read()
                    sumaVer += CDec(dr("monto_bs"))
                    metodo = dr("metodo_pago").ToString()
                End While
            End Using
        End Using

        MetodoPago = If(metodo <> "", MapearMetodo(metodo), If(wcMethodTitle <> "", wcMethodTitle, "---"))

        Dim saldo As Decimal = totalBs - sumaVer
        If totalBs <= 0 OrElse saldo <= 0.01D Then
            EstadoPago = "PAGADO"
        ElseIf sumaVer > 0 Then
            EstadoPago = "ANTICIPO"
            BloqueCobrar = "<div class='alerta-box'>*** COBRAR Bs " & saldo.ToString("N2") & " ***</div>"
        Else
            EstadoPago = "PENDIENTE"
            BloqueCobrar = "<div class='alerta-box'>*** COBRAR Bs " & totalBs.ToString("N2") & " ***</div>"
        End If
    End Sub

    Private Function CargarProductos(conn As SqlConnection) As String
        Dim sb As New StringBuilder()
        Using cmd As New SqlCommand(
            "SELECT nombre_producto, cantidad, personalizacion " &
            "FROM FLORERIA_Pedido_Detalle WHERE pedido_id=@id", conn)
            cmd.Parameters.AddWithValue("@id", PedidoId)
            Using dr As SqlDataReader = cmd.ExecuteReader()
                While dr.Read()
                    Dim nom  As String  = dr("nombre_producto").ToString()
                    Dim cant As Integer = CInt(dr("cantidad"))
                    Dim pers As String  = If(IsDBNull(dr("personalizacion")), "", dr("personalizacion").ToString())
                    sb.Append("<div class='prod'><div class='nom'>").Append(cant).Append(" x ").Append(Server.HtmlEncode(nom)).Append("</div>")
                    If pers <> "" Then sb.Append("<div class='pers'>&gt; ").Append(Server.HtmlEncode(pers)).Append("</div>")
                    sb.Append("</div>")
                End While
            End Using
        End Using
        If sb.Length = 0 Then sb.Append("<div class='prod'><div class='nom'>(Sin productos)</div></div>")
        Return sb.ToString()
    End Function

    ' "PED-000014" -> "PED-14"
    Private Function QuitarCeros(codigo As String) As String
        If String.IsNullOrEmpty(codigo) Then Return codigo
        Dim pos As Integer = codigo.IndexOf("-"c)
        If pos < 0 Then Return codigo
        Dim num As String = codigo.Substring(pos + 1).TrimStart("0"c)
        If num = "" Then num = "0"
        Return codigo.Substring(0, pos + 1) & num
    End Function

    Private Function MapearOcasion(c As String) As String
        Select Case c.ToUpper()
            Case "CUMPLEANOS"     : Return "Cumpleanos"
            Case "ANIVERSARIO"    : Return "Aniversario"
            Case "AMOR"           : Return "Amor"
            Case "AGRADECIMIENTO" : Return "Agradecimiento"
            Case "CONDOLENCIAS"   : Return "Condolencias"
            Case "GRADUACION"     : Return "Graduacion"
            Case "NACIMIENTO"     : Return "Nacimiento"
            Case Else             : Return c
        End Select
    End Function

    Private Function MapearMetodo(c As String) As String
        Select Case c.ToUpper()
            Case "EFECTIVO"      : Return "Efectivo"
            Case "QR"            : Return "QR Bolivia (BNB)"
            Case "TRANSFERENCIA" : Return "Transferencia"
            Case "PAYPAL"        : Return "PayPal"
            Case "CRIPTO"        : Return "Cripto USDT"
            Case "YAPE"          : Return "Yape"
            Case "PIX"           : Return "Pix"
            Case "TARJETA"       : Return "Tarjeta"
            Case "PAGOMOVIL"     : Return "Pago Movil"
            Case Else            : Return c
        End Select
    End Function

End Class
