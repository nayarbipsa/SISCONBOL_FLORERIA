Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web.Script.Serialization

' ============================================================
' SISCONBOL - Pedido_Detalle
' Archivo: Modulos/Pedidos/Pedido_Detalle.aspx.vb
' Acceso: ?id={pedido_id}
' MasterPage. Verifica sesion. Vista detalle + edicion modal de entrega.
' ============================================================
Partial Public Class Modulos_Pedidos_Pedido_Detalle
    Inherits System.Web.UI.Page

    Public Property TienePedido As Boolean = False
    Public Property MensajeError As String = ""

    ' Identificacion
    Public Property PedidoId          As Integer = 0
    Public Property Codigo            As String = ""
    Public Property PrePedidoId       As Integer = 0
    Public Property PrePedidoCodigo   As String = ""

    ' Cabecera
    Public Property FechaCreacion     As String = ""
    Public Property CreadorNombre     As String = ""
    Public Property EstadoOperativo   As String = "PENDIENTE"
    Public Property EstadoOperativoLabel As String = "Pendiente"
    Public Property EstadoPago        As String = "PENDIENTE"
    Public Property EstadoPagoLabel   As String = "Pendiente"

    ' WooCommerce
    Public Property WcOrderId            As Integer = 0
    Public Property WcOrderNumberMostrar As String = ""
    Public Property WcSyncEstado         As String = "—"
    Public Property WcSyncFecha          As String = ""
    Public Property WcOrderStatus        As String = ""
    Public Property WcPaymentMethodTitle As String = ""

    ' Datos de entrega
    Public Property ReceptorNombre  As String = ""
    Public Property ReceptorCelular As String = ""
    Public Property FechaEntrega    As String = ""
    Public Property Horario         As String = ""
    Public Property TipoEntregaLabel As String = ""
    Public Property EsExpress       As Boolean = False
    Public Property Ciudad          As String = ""
    Public Property Zona            As String = ""
    Public Property Direccion       As String = ""
    Public Property Referencia      As String = ""

    ' Productos
    Public Property HtmlProductos As String = ""
    Public Property CantidadItems As Integer = 0

    ' Dedicatoria
    Public Property Dedicatoria      As String = ""
    Public Property FirmaTarjeta     As String = ""
    Public Property TipoOcacion      As String = ""
    Public Property TipoOcacionLabel As String = ""

    ' Totales
    Public Property SubtotalProductosBs As String = "0.00"
    Public Property EnvioBs             As String = "0.00"
    Public Property RecargoExpressBs    As String = "0.00"
    Public Property RecargoHorarioBs    As String = "0.00"
    Public Property DescuentoBs         As String = "0.00"
    Public Property TotalBs             As String = "0.00"
    Public Property TotalUsd            As String = "0.00"

    Public Property RecargoExpressBsNum As Decimal = 0D
    Public Property RecargoHorarioBsNum As Decimal = 0D
    Public Property DescuentoBsNum      As Decimal = 0D

    ' Pagos
    Public Property AnticipoBs     As String = "0.00"
    Public Property SaldoBs        As String = "0.00"
    Public Property SaldoBsNum     As Decimal = 0D
    Public Property HtmlPagos      As String = ""

    ' Notas
    Public Property NotaFloreria   As String = ""
    Public Property Observaciones  As String = ""

    ' Operativo
    Public Property SucursalPrepara As String = ""

    ' ============================================================
    ' [NUEVO] Datos para el modal de edicion de entrega
    ' ============================================================
    Public Property TipoEntregaRaw       As String  = "DOMICILIO"
    Public Property FechaEntregaInput    As String  = ""
    Public Property FechaMinima          As String  = ""
    Public Property CiudadIdActual       As Integer = 0
    Public Property ZonaIdActual         As Integer = 0
    Public Property ZonaNombreActual     As String  = ""
    Public Property SlotIdActual         As Integer = 0
    Public Property SucursalRecojoIdActual As Integer = 0
    Public Property PuedeEditar          As Boolean = False
    Public Property HtmlCiudadesEdit     As String  = ""
    Public Property HtmlSlotsEdit        As String  = ""
    Public Property HtmlSucursalesEdit   As String  = ""
    Public Property ZonasJson            As String  = "[]"

    ' ============================================================
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If IsPostBack Then Return

        Dim idStr As String = Request.QueryString("id")
        If String.IsNullOrEmpty(idStr) OrElse Not Integer.TryParse(idStr, PedidoId) OrElse PedidoId <= 0 Then
            TienePedido = False
            MensajeError = "ID de pedido invalido"
            Return
        End If

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                If Not CargarCabecera(conn) Then
                    TienePedido = False
                    Return
                End If
                CargarProductos(conn)
                CargarPagos(conn)

                ' [NUEVO] Cargar listas para el modal de edicion
                CargarCiudadesEdit(conn)
                CargarSlotsEdit(conn)
                CargarSucursalesEdit(conn)
                CargarZonasEdit(conn)
                FechaMinima = DateTime.Now.ToString("yyyy-MM-dd")
                DeterminarPuedeEditar()

                TienePedido = True
            End Using
        Catch ex As Exception
            TienePedido = False
            MensajeError = "Error al cargar el pedido: " & ex.Message
        End Try
    End Sub

    ' ============================================================
    ' CARGAR CABECERA
    ' ============================================================
    Private Function CargarCabecera(conn As SqlConnection) As Boolean
        Dim sql As String =
            "SELECT p.pedido_id, p.codigo, p.prepedido_id, " &
            "       p.receptor_nombre, p.receptor_celular, " &
            "       p.fecha_entrega, p.tipo_entrega, p.direccion, p.referencia, " &
            "       p.es_express, p.dedicatoria, p.firma_tarjeta, p.tipo_ocacion, " &
            "       p.ciudad_id, p.zona_id, p.slot_id, p.sucursal_id, " &
            "       p.subtotal_productos_bs, p.envio_bs, " &
            "       p.recargo_express_bs, p.recargo_horario_bs, p.descuento_bs, " &
            "       p.total_bs, p.total_usd, p.anticipo_bs, p.saldo_bs, " &
            "       p.estado_pago, p.estado_operativo, " &
            "       p.wc_order_id, p.wc_order_number, p.wc_sync_estado, p.wc_sync_fecha, " &
            "       p.wc_order_status, p.wc_payment_method_title, " &
            "       p.observaciones, p.nota_floreria, p.creado_en, " &
            "       uc.nombres + ' ' + uc.apellidos AS creador_nombre, " &
            "       c.nombre  AS ciudad_nombre, " &
            "       z.nombre  AS zona_nombre, " &
            "       sh.hora_inicio, sh.hora_fin, " &
            "       sp.nombre AS sucursal_prepara_nombre, " &
            "       pp.codigo AS prepedido_codigo " &
            "FROM   FLORERIA_Pedido p " &
            "LEFT JOIN FLORERIA_PrePedido    pp ON p.prepedido_id        = pp.prepedido_id " &
            "LEFT JOIN FLORERIA_Usuario      uc ON p.creado_por           = uc.usuario_id " &
            "LEFT JOIN FLORERIA_Ciudad       c  ON p.ciudad_id            = c.ciudad_id " &
            "LEFT JOIN FLORERIA_Zona         z  ON p.zona_id              = z.zona_id " &
            "LEFT JOIN FLORERIA_Slot_Horario sh ON p.slot_id              = sh.slot_id " &
            "LEFT JOIN FLORERIA_Sucursal     sp ON p.sucursal_prepara_id  = sp.sucursal_id " &
            "WHERE  p.pedido_id = @id"

        Using cmd As New SqlCommand(sql, conn)
            cmd.Parameters.AddWithValue("@id", PedidoId)
            Using dr As SqlDataReader = cmd.ExecuteReader()
                If Not dr.Read() Then
                    MensajeError = "No se encontro el pedido #" & PedidoId
                    Return False
                End If

                Codigo            = LeerStr(dr, "codigo")
                PrePedidoId       = LeerInt(dr, "prepedido_id")
                PrePedidoCodigo   = LeerStr(dr, "prepedido_codigo")
                CreadorNombre     = LeerStr(dr, "creador_nombre")
                If Not IsDBNull(dr("creado_en")) Then
                    FechaCreacion = CDate(dr("creado_en")).ToString("dd 'de' MMMM HH:mm")
                End If

                ReceptorNombre  = LeerStr(dr, "receptor_nombre")
                ReceptorCelular = LeerStr(dr, "receptor_celular")

                If Not IsDBNull(dr("fecha_entrega")) Then
                    FechaEntrega = CDate(dr("fecha_entrega")).ToString("dd 'de' MMMM yyyy")
                    FechaEntregaInput = CDate(dr("fecha_entrega")).ToString("yyyy-MM-dd")
                End If

                Dim hI As String = LeerStr(dr, "hora_inicio")
                Dim hF As String = LeerStr(dr, "hora_fin")
                If hI <> "" AndAlso hF <> "" Then
                    Horario = FormatearHora(hI) & " — " & FormatearHora(hF)
                End If

                TipoEntregaLabel = LabelTipoEntrega(LeerStr(dr, "tipo_entrega"))
                TipoEntregaRaw   = LeerStr(dr, "tipo_entrega")
                If TipoEntregaRaw = "" Then TipoEntregaRaw = "DOMICILIO"

                EsExpress        = (Not IsDBNull(dr("es_express")) AndAlso CBool(dr("es_express")))
                Ciudad           = LeerStr(dr, "ciudad_nombre")
                Zona             = LeerStr(dr, "zona_nombre")
                Direccion        = LeerStr(dr, "direccion")
                Referencia       = LeerStr(dr, "referencia")

                CiudadIdActual         = LeerInt(dr, "ciudad_id")
                ZonaIdActual           = LeerInt(dr, "zona_id")
                ZonaNombreActual       = LeerStr(dr, "zona_nombre")
                SlotIdActual           = LeerInt(dr, "slot_id")
                SucursalRecojoIdActual = LeerInt(dr, "sucursal_id")

                Dedicatoria   = LeerStr(dr, "dedicatoria")
                FirmaTarjeta  = LeerStr(dr, "firma_tarjeta")
                TipoOcacion   = LeerStr(dr, "tipo_ocacion")
                TipoOcacionLabel = LabelOcasion(TipoOcacion)

                SubtotalProductosBs = LeerDecimalFmt(dr, "subtotal_productos_bs")
                EnvioBs             = LeerDecimalFmt(dr, "envio_bs")
                RecargoExpressBs    = LeerDecimalFmt(dr, "recargo_express_bs")
                RecargoHorarioBs    = LeerDecimalFmt(dr, "recargo_horario_bs")
                DescuentoBs         = LeerDecimalFmt(dr, "descuento_bs")
                TotalBs             = LeerDecimalFmt(dr, "total_bs")
                TotalUsd            = LeerDecimalFmt(dr, "total_usd")

                RecargoExpressBsNum = LeerDecimal(dr, "recargo_express_bs")
                RecargoHorarioBsNum = LeerDecimal(dr, "recargo_horario_bs")
                DescuentoBsNum      = LeerDecimal(dr, "descuento_bs")

                AnticipoBs = LeerDecimalFmt(dr, "anticipo_bs")
                SaldoBs    = LeerDecimalFmt(dr, "saldo_bs")
                SaldoBsNum = LeerDecimal(dr, "saldo_bs")

                EstadoPago      = LeerStr(dr, "estado_pago")
                EstadoPagoLabel = LabelEstadoPago(EstadoPago)
                EstadoOperativo = LeerStr(dr, "estado_operativo")
                EstadoOperativoLabel = LabelEstadoOperativo(EstadoOperativo)

                WcOrderId = LeerInt(dr, "wc_order_id")
                Dim wcNum As String = LeerStr(dr, "wc_order_number")
                If WcOrderId > 0 Then
                    WcOrderNumberMostrar = "#" & If(wcNum <> "", wcNum, WcOrderId.ToString())
                End If
                WcSyncEstado         = If(LeerStr(dr, "wc_sync_estado") = "", "—", LeerStr(dr, "wc_sync_estado"))
                If Not IsDBNull(dr("wc_sync_fecha")) Then
                    WcSyncFecha = CDate(dr("wc_sync_fecha")).ToString("dd MMM HH:mm")
                End If
                WcOrderStatus        = LeerStr(dr, "wc_order_status")
                WcPaymentMethodTitle = LeerStr(dr, "wc_payment_method_title")

                Observaciones   = LeerStr(dr, "observaciones")
                NotaFloreria    = LeerStr(dr, "nota_floreria")
                SucursalPrepara = LeerStr(dr, "sucursal_prepara_nombre")
            End Using
        End Using

        Return True
    End Function

    ' ============================================================
    ' CARGAR PRODUCTOS
    ' ============================================================
    Private Sub CargarProductos(conn As SqlConnection)
        Dim sql As String =
            "SELECT detalle_id, nombre_producto, descripcion, cantidad, " &
            "       precio_unitario_bs, subtotal_bs, personalizacion " &
            "FROM   FLORERIA_Pedido_Detalle " &
            "WHERE  pedido_id = @id " &
            "ORDER BY detalle_id"

        Dim sb As New StringBuilder()
        Dim items As Integer = 0

        Using cmd As New SqlCommand(sql, conn)
            cmd.Parameters.AddWithValue("@id", PedidoId)
            Using dr As SqlDataReader = cmd.ExecuteReader()
                While dr.Read()
                    items += 1
                    Dim nom    As String  = LeerStr(dr, "nombre_producto")
                    Dim desc   As String  = LeerStr(dr, "descripcion")
                    Dim cant   As Integer = LeerInt(dr, "cantidad")
                    Dim precio As String  = LeerDecimalFmt(dr, "precio_unitario_bs")
                    Dim sub_   As String  = LeerDecimalFmt(dr, "subtotal_bs")
                    Dim pers   As String  = LeerStr(dr, "personalizacion")

                    sb.AppendLine("<div class='prod-row'>")
                    sb.AppendLine("  <div class='prod-thumb'><i class='ti ti-flower'></i></div>")
                    sb.AppendLine("  <div class='prod-info'>")
                    sb.AppendLine("    <p class='prod-nom'>" & Esc(nom) & "</p>")
                    If desc <> "" Then
                        sb.AppendLine("    <p class='prod-desc'>" & Esc(desc) & "</p>")
                    End If
                    If pers <> "" Then
                        sb.AppendLine("    <p class='prod-pers'><i class='ti ti-pencil' style='font-size:11px;vertical-align:-1px'></i> " & Esc(pers) & "</p>")
                    End If
                    sb.AppendLine("  </div>")
                    sb.AppendLine("  <div class='prod-precio'>")
                    sb.AppendLine("    <div class='cant'>" & cant & " × " & precio & "</div>")
                    sb.AppendLine("    <div class='sub'>" & sub_ & " Bs</div>")
                    sb.AppendLine("  </div>")
                    sb.AppendLine("</div>")
                End While
            End Using
        End Using

        HtmlProductos = sb.ToString()
        CantidadItems = items
    End Sub

    ' ============================================================
    ' CARGAR PAGOS
    ' ============================================================
    Private Sub CargarPagos(conn As SqlConnection)
        Dim sql As String =
            "SELECT pag.pago_id, pag.tipo_pago, pag.metodo_pago, pag.monto_bs, " &
            "       pag.referencia, pag.estado, pag.creado_en, " &
            "       uv.nombres + ' ' + uv.apellidos AS verificador " &
            "FROM   FLORERIA_Pedido_Pago pag " &
            "LEFT JOIN FLORERIA_Usuario uv ON pag.verificado_por = uv.usuario_id " &
            "WHERE  pag.pedido_id = @id " &
            "ORDER BY pag.pago_id DESC"

        Dim sb As New StringBuilder()

        Using cmd As New SqlCommand(sql, conn)
            cmd.Parameters.AddWithValue("@id", PedidoId)
            Using dr As SqlDataReader = cmd.ExecuteReader()
                While dr.Read()
                    Dim metodo As String  = LeerStr(dr, "metodo_pago")
                    Dim tipo   As String  = LeerStr(dr, "tipo_pago")
                    Dim monto  As String  = LeerDecimalFmt(dr, "monto_bs")
                    Dim refer  As String  = LeerStr(dr, "referencia")
                    Dim est    As String  = LeerStr(dr, "estado")
                    Dim verifi As String  = LeerStr(dr, "verificador")
                    Dim fech   As String  = ""
                    If Not IsDBNull(dr("creado_en")) Then
                        fech = CDate(dr("creado_en")).ToString("dd MMM HH:mm")
                    End If

                    Dim claseEstado As String = If(est = "VERIFICADO", "v", If(est = "RECHAZADO", "r", "p"))
                    Dim labelEstado As String = If(est = "VERIFICADO", "Verificado" & If(verifi <> "", " · " & verifi, ""),
                                                If(est = "RECHAZADO", "Rechazado", "Pendiente"))

                    sb.AppendLine("<div class='pago-row'>")
                    sb.AppendLine("  <div class='pago-info'>")
                    sb.AppendLine("    <div class='met'><i class='ti ti-credit-card' style='font-size:13px;vertical-align:-2px;color:#7F77DD'></i> " & Esc(LabelMetodoPago(metodo)) & " <span style='font-size:10px;color:#9e9e9e;font-weight:400'>(" & Esc(tipo) & ")</span></div>")
                    Dim detalle As String = fech
                    If refer <> "" Then detalle &= " · ref. " & refer
                    sb.AppendLine("    <div class='det'>" & Esc(detalle) & "</div>")
                    sb.AppendLine("  </div>")
                    sb.AppendLine("  <div class='pago-monto'>")
                    sb.AppendLine("    " & monto & " Bs")
                    sb.AppendLine("    <span class='estado-mini " & claseEstado & "'>" & Esc(labelEstado) & "</span>")
                    sb.AppendLine("  </div>")
                    sb.AppendLine("</div>")
                End While
            End Using
        End Using

        HtmlPagos = sb.ToString()
    End Sub

    ' ============================================================
    ' [NUEVO] Determinar si el usuario puede editar este pedido
    ' Requiere: tipo_id = 1 (Admin) o 2 (Gerente)
    '           Estado operativo distinto de ENTREGADO / NO_ENTREGADO
    ' ============================================================
    Private Sub DeterminarPuedeEditar()
        Try
            Dim tipoId As Integer = 3
            If Session("tipo_id") IsNot Nothing Then
                Integer.TryParse(Session("tipo_id").ToString(), tipoId)
            End If

            Dim esAdminOGerente As Boolean = (tipoId = 1 OrElse tipoId = 2)
            Dim estadoBloquea As Boolean = (EstadoOperativo = "ENTREGADO" OrElse EstadoOperativo = "NO_ENTREGADO")

            PuedeEditar = esAdminOGerente AndAlso Not estadoBloquea
        Catch
            PuedeEditar = False
        End Try
    End Sub

    ' ============================================================
    ' [NUEVO] CargarCiudadesEdit - options para el select del modal
    ' ============================================================
    Private Sub CargarCiudadesEdit(conn As SqlConnection)
        Try
            Dim sb As New StringBuilder()
            Using cmd As New SqlCommand("SELECT ciudad_id, nombre FROM FLORERIA_Ciudad WHERE activo = 1 ORDER BY nombre", conn)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        Dim cid As Integer = CInt(dr("ciudad_id"))
                        Dim selAttr As String = If(cid = CiudadIdActual, " selected", "")
                        sb.AppendLine("<option value='" & cid & "'" & selAttr & ">" & Esc(dr("nombre").ToString()) & "</option>")
                    End While
                End Using
            End Using
            HtmlCiudadesEdit = sb.ToString()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR CargarCiudadesEdit: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' [NUEVO] CargarSlotsEdit - optgroups normales/express
    ' ============================================================
    Private Sub CargarSlotsEdit(conn As SqlConnection)
        Try
            Dim sbNormal As New StringBuilder()
            Dim sbExpress As New StringBuilder()
            Dim sql As String = "SELECT slot_id, etiqueta, recargo_bs, es_express " &
                                "FROM   FLORERIA_Slot_Horario " &
                                "WHERE  activo = 1 " &
                                "ORDER BY es_express, orden_display, hora_inicio"
            Using cmd As New SqlCommand(sql, conn)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        Dim sid As Integer = CInt(dr("slot_id"))
                        Dim etiqueta As String = dr("etiqueta").ToString()
                        Dim recargo As Decimal = If(IsDBNull(dr("recargo_bs")), 0D, CDec(dr("recargo_bs")))
                        Dim esExp As Boolean = CBool(dr("es_express"))
                        Dim textoRec As String = If(recargo > 0, " +Bs" & recargo.ToString("N0"), "")
                        Dim selAttr As String = If(sid = SlotIdActual, " selected", "")
                        Dim opt As String = "<option value='" & sid & "'" & selAttr & ">" & Esc(etiqueta) & textoRec & "</option>"
                        If esExp Then
                            sbExpress.AppendLine(opt)
                        Else
                            sbNormal.AppendLine(opt)
                        End If
                    End While
                End Using
            End Using

            Dim sb As New StringBuilder()
            If sbNormal.Length > 0 Then
                sb.AppendLine("<optgroup label='Horarios normales'>")
                sb.Append(sbNormal.ToString())
                sb.AppendLine("</optgroup>")
            End If
            If sbExpress.Length > 0 Then
                sb.AppendLine("<optgroup label='Horarios express'>")
                sb.Append(sbExpress.ToString())
                sb.AppendLine("</optgroup>")
            End If
            HtmlSlotsEdit = sb.ToString()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR CargarSlotsEdit: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' [NUEVO] CargarSucursalesEdit
    ' ============================================================
    Private Sub CargarSucursalesEdit(conn As SqlConnection)
        Try
            Dim sb As New StringBuilder()
            Using cmd As New SqlCommand("SELECT sucursal_id, nombre FROM FLORERIA_Sucursal WHERE activo = 1 ORDER BY nombre", conn)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        Dim sid As Integer = CInt(dr("sucursal_id"))
                        Dim selAttr As String = If(sid = SucursalRecojoIdActual, " selected", "")
                        sb.AppendLine("<option value='" & sid & "'" & selAttr & ">" & Esc(dr("nombre").ToString()) & "</option>")
                    End While
                End Using
            End Using
            HtmlSucursalesEdit = sb.ToString()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR CargarSucursalesEdit: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' [NUEVO] CargarZonasEdit - JSON con zonas activas para datalist
    ' ============================================================
    Private Sub CargarZonasEdit(conn As SqlConnection)
        Try
            Dim zonas As New List(Of Object)
            Dim sql As String = "SELECT zona_id, ciudad_id, nombre " &
                                "FROM   FLORERIA_Zona " &
                                "WHERE  activo = 1 " &
                                "ORDER BY nombre"
            Using cmd As New SqlCommand(sql, conn)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        zonas.Add(New With {
                            .zona_id   = CInt(dr("zona_id")),
                            .ciudad_id = CInt(dr("ciudad_id")),
                            .nombre    = dr("nombre").ToString()
                        })
                    End While
                End Using
            End Using
            Dim serializer As New JavaScriptSerializer()
            ZonasJson = serializer.Serialize(zonas)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR CargarZonasEdit: " & ex.Message)
            ZonasJson = "[]"
        End Try
    End Sub

    ' ============================================================
    ' HELPERS DE LECTURA
    ' ============================================================
    Private Function LeerStr(dr As SqlDataReader, col As String) As String
        Try
            If IsDBNull(dr(col)) Then Return ""
            Return dr(col).ToString().Trim()
        Catch
            Return ""
        End Try
    End Function

    Private Function LeerInt(dr As SqlDataReader, col As String) As Integer
        Try
            If IsDBNull(dr(col)) Then Return 0
            Return Convert.ToInt32(dr(col))
        Catch
            Return 0
        End Try
    End Function

    Private Function LeerDecimal(dr As SqlDataReader, col As String) As Decimal
        Try
            If IsDBNull(dr(col)) Then Return 0D
            Return Convert.ToDecimal(dr(col))
        Catch
            Return 0D
        End Try
    End Function

    Private Function LeerDecimalFmt(dr As SqlDataReader, col As String) As String
        Return LeerDecimal(dr, col).ToString("N2")
    End Function

    ' ============================================================
    ' LABELS
    ' ============================================================
    Private Function LabelEstadoOperativo(v As String) As String
        Select Case v
            Case "PENDIENTE"       : Return "Pendiente"
            Case "IMPRESO"         : Return "Impreso"
            Case "EN_PREPARACION"  : Return "En preparación"
            Case "LISTO"           : Return "Listo"
            Case "EN_RUTA"         : Return "En ruta"
            Case "ENTREGADO"       : Return "Entregado"
            Case "NO_ENTREGADO"    : Return "No entregado"
            Case "REPROGRAMADO"    : Return "Reprogramado"
            Case "PREPARANDO"      : Return "Preparando"
            Case "EN_CAMINO"       : Return "En camino"
            Case "FALLIDO"         : Return "Fallido"
            Case Else              : Return If(v = "", "—", v)
        End Select
    End Function

    Private Function LabelEstadoPago(v As String) As String
        Select Case v
            Case "PENDIENTE"   : Return "Pendiente"
            Case "ANTICIPO"    : Return "Anticipo"
            Case "PAGADO"      : Return "Pagado"
            Case "REEMBOLSADO" : Return "Reembolsado"
            Case Else          : Return If(v = "", "—", v)
        End Select
    End Function

    Private Function LabelTipoEntrega(v As String) As String
        Select Case v
            Case "DOMICILIO"        : Return "Domicilio"
            Case "RECOJO"           : Return "Recojo en tienda"
            Case "RECOJO_SUCURSAL"  : Return "Recojo en tienda"
            Case Else               : Return If(v = "", "—", v)
        End Select
    End Function

    Private Function LabelOcasion(v As String) As String
        Select Case v
            Case "CUMPLEANOS"     : Return "Cumpleaños"
            Case "ANIVERSARIO"    : Return "Aniversario"
            Case "AMOR"           : Return "Amor"
            Case "AGRADECIMIENTO" : Return "Agradecimiento"
            Case "CONDOLENCIAS"   : Return "Condolencias"
            Case "GRADUACION"     : Return "Graduación"
            Case "NACIMIENTO"     : Return "Nacimiento"
            Case "OTRO"           : Return "Otro"
            Case Else             : Return If(v = "", "", v)
        End Select
    End Function

    Private Function LabelMetodoPago(v As String) As String
        Select Case v.ToUpper()
            Case "EFECTIVO"      : Return "Efectivo"
            Case "QR"            : Return "QR / Transferencia"
            Case "TARJETA"       : Return "Tarjeta"
            Case "DEPOSITO"      : Return "Depósito bancario"
            Case "TRANSFERENCIA" : Return "Transferencia"
            Case Else            : Return If(v = "", "—", v)
        End Select
    End Function

    Private Function FormatearHora(h As String) As String
        If h Is Nothing OrElse h.Length < 5 Then Return h
        Return h.Substring(0, 5)
    End Function

    ' ============================================================
    ' Escape basico
    ' ============================================================
    Private Function Esc(v As String) As String
        If String.IsNullOrEmpty(v) Then Return ""
        Return v.Replace("&", "&amp;").
                 Replace("<", "&lt;").
                 Replace(">", "&gt;").
                 Replace("""", "&quot;")
    End Function

End Class
