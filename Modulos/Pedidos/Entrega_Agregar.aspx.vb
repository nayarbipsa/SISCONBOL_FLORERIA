Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Web.Script.Serialization

' ============================================================
' SISCONBOL - Agregar/Editar Entrega (BORRADOR)
' Archivo: Modulos/Pedidos/Entrega_Agregar.aspx.vb
' MasterPage: Site.Master
' Tabla principal: FLORERIA_PrePedido_Entrega (NO FLORERIA_Pedido)
'
' Flujo:
'   ?prepedido=X                  -> crea borrador y redirige a ?prepedido=X&entrega=N
'   ?prepedido=X&entrega=N        -> carga el borrador N
' ============================================================
Partial Public Class Modulos_Pedidos_Entrega_Agregar
    Inherits System.Web.UI.Page

    ' --- Propiedades de contexto ---
    Public Property MensajeAlerta As String = ""
    Public Property ModoEdicion As Boolean = False
    Public Property PrePedidoId As Integer = 0
    Public Property PrePedidoEntregaId As Integer = 0
    Public Property PrePedidoCodigo As String = ""
    Public Property ClienteNombre As String = ""
    Public Property ClienteCelular As String = ""
    Public Property ClienteEmail As String = ""
    Public Property TasaCambio As Decimal = 7.0

    ' --- Valores de texto ---
    Public Property ValorReceptor As String = ""
    Public Property ValorCelularReceptor As String = ""
    Public Property ValorFecha As String = ""
    Public Property ValorTipoEntrega As String = "DOMICILIO"
    Public Property ValorDireccion As String = ""
    Public Property ValorReferencia As String = ""
    Public Property ValorGps As String = ""
    Public Property ValorDedicatoria As String = ""
    Public Property ValorFirma As String = ""
    Public Property ValorExpress As Boolean = False
    Public Property ValorOcasion As String = ""
    Public Property ValorDescuento As String = "0"
    Public Property ValorDescuentoMoneda As String = "BOB"
    Public Property MonedaSeleccionada As String = "BOB"
    Public Property FechaMinima As String = ""
    Public Property EstadoLink As Integer = 0

    ' --- IDs seleccionados (para marcar selected en combos) ---
    Public Property ValorCiudadId As Integer = 0
    Public Property ValorZonaId As Integer = 0
    Public Property ValorSucursalRecojoId As Integer = 0
    Public Property ValorSucursalPreparaId As Integer = 0
    Public Property ValorSlotId As Integer = 0

    ' --- HTML generados ---
    Public Property HtmlCiudades As String = ""
    Public Property HtmlSucursales As String = ""
    Public Property HtmlSucursalesRecojo As String = ""
    Public Property HtmlSlots As String = ""
    Public Property HtmlProductos As String = ""
    Public Property HtmlPagos As String = ""

    ' --- HTML categorias buscador ---
    Public Property HtmlCategoriasBtns As String = ""

    ' --- Texto inicial para input de zona (Zona (Bs X.XX)) ---
    Public Property ValorZonaTexto As String = ""

    ' --- JSON para JavaScript ---
    Public Property ZonasJson As String = "[]"
    Public Property SlotsJson As String = "[]"

    ' ============================================================
    ' Page_Load
    ' ============================================================
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If IsPostBack Then Return

        ' --- 1. Resolver PrePedidoId ---
        Dim prepedidoStr As String = Request.QueryString("prepedido")
        If String.IsNullOrEmpty(prepedidoStr) Then
            Response.Redirect("PrePedidos.aspx", False)
            Return
        End If

        Dim ppId As Integer = 0
        If Not Integer.TryParse(prepedidoStr, ppId) OrElse ppId <= 0 Then
            Response.Redirect("PrePedidos.aspx", False)
            Return
        End If
        PrePedidoId = ppId

        ' --- 2. Resolver PrePedidoEntregaId (parametro "entrega") ---
        Dim entregaStr As String = Request.QueryString("entrega")
        Dim entId As Integer = 0
        If Not String.IsNullOrEmpty(entregaStr) Then
            Integer.TryParse(entregaStr, entId)
        End If

        If entId > 0 Then
            ' Verificar que el borrador existe y pertenece al pre-pedido
            If ExisteBorrador(entId, ppId) Then
                PrePedidoEntregaId = entId
                ModoEdicion = True
            Else
                ' borrador invalido -> crear uno nuevo
                PrePedidoEntregaId = CrearBorrador(ppId)
                If PrePedidoEntregaId > 0 Then
                    Response.Redirect("Entrega_Agregar.aspx?prepedido=" & ppId & "&entrega=" & PrePedidoEntregaId, False)
                    Return
                End If
            End If
        Else
            ' No vino "entrega" en URL -> crear borrador nuevo y redirigir
            PrePedidoEntregaId = CrearBorrador(ppId)
            If PrePedidoEntregaId > 0 Then
                Response.Redirect("Entrega_Agregar.aspx?prepedido=" & ppId & "&entrega=" & PrePedidoEntregaId, False)
                Return
            End If
        End If

        ' --- 3. Fechas minimas (mostradas en pantalla) ---
        Dim fechaMin As DateTime = DateTime.Now.AddDays(2)
        FechaMinima = fechaMin.ToString("yyyy-MM-dd")
        ValorFecha = fechaMin.ToString("yyyy-MM-dd")

        ' --- 4. Cargas comunes ---
        CargarDatosPrePedido()
        CargarCategorias()

        ' --- 5. Si hay borrador, cargar sus valores PRIMERO ---
        '     (asi ValorCiudadId, ValorSlotId, etc. estan listos antes
        '      de generar el HTML de ciudades, slots y sucursales)
        If PrePedidoEntregaId > 0 Then
            CargarDatosBorrador()
            CargarProductosBorrador()
            CargarPagosBorrador()
        End If

        ' --- 6. Generar HTMLs de combos (usa los Valor*Id) ---
        CargarCiudades()
        CargarZonas()
        CargarSucursales()
        CargarSlots()
    End Sub

    ' ============================================================
    ' Crear borrador via SP
    ' ============================================================
    Private Function CrearBorrador(ppId As Integer) As Integer
        Try
            Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_PrePedidoEntrega_CrearBorrador", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@prepedido_id", ppId)
                    cmd.Parameters.AddWithValue("@creado_por", usuarioId)
                    Dim pId As New SqlParameter("@prepedido_entrega_id", SqlDbType.Int)
                    pId.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(pId)
                    cmd.ExecuteNonQuery()
                    Return CInt(pId.Value)
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR CrearBorrador: " & ex.Message)
            Return 0
        End Try
    End Function

    ' ============================================================
    ' Verificar que el borrador existe y pertenece al pre-pedido
    ' ============================================================
    Private Function ExisteBorrador(entId As Integer, ppId As Integer) As Boolean
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Dim sql As String = "SELECT COUNT(*) FROM FLORERIA_PrePedido_Entrega " &
                                    "WHERE prepedido_entrega_id = @eid AND prepedido_id = @ppid"
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@eid", entId)
                    cmd.Parameters.AddWithValue("@ppid", ppId)
                    Dim n As Object = cmd.ExecuteScalar()
                    If n Is Nothing OrElse IsDBNull(n) Then Return False
                    Return CInt(n) > 0
                End Using
            End Using
        Catch
            Return False
        End Try
    End Function

    ' ============================================================
    ' CargarDatosPrePedido
    ' ============================================================
    Private Sub CargarDatosPrePedido()
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Dim sql As String = "SELECT codigo, cliente_nombre, cliente_apellidos, cliente_celular, cliente_email, tasa_cambio " &
                                    "FROM FLORERIA_PrePedido WHERE prepedido_id = @id"
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@id", PrePedidoId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            PrePedidoCodigo = dr("codigo").ToString()
                            Dim nombre As String = If(IsDBNull(dr("cliente_nombre")), "", dr("cliente_nombre").ToString())
                            Dim apellidos As String = If(IsDBNull(dr("cliente_apellidos")), "", dr("cliente_apellidos").ToString())
                            ClienteNombre = (nombre.Trim() & " " & apellidos.Trim()).Trim()
                            If ClienteNombre = "" Then ClienteNombre = "Cliente"
                            ClienteCelular = If(IsDBNull(dr("cliente_celular")), "", dr("cliente_celular").ToString())
                            ClienteEmail = If(IsDBNull(dr("cliente_email")), "", dr("cliente_email").ToString())
                            If Not IsDBNull(dr("tasa_cambio")) Then
                                TasaCambio = CDec(dr("tasa_cambio"))
                            End If
                        Else
                            Response.Redirect("PrePedidos.aspx", False)
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Entrega_Agregar.CargarDatosPrePedido: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' CargarDatosBorrador (lee FLORERIA_PrePedido_Entrega)
    ' ============================================================
    Private Sub CargarDatosBorrador()
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Dim sql As String = "SELECT receptor_nombre, receptor_celular, ciudad_id, zona_id, " &
                    "sucursal_id, tipo_entrega, direccion, referencia, gps, " &
                    "fecha_entrega, slot_id, es_express, dedicatoria, firma_tarjeta, " &
                    "tipo_ocacion, sucursal_prepara_id, moneda, " &
                    "descuento_valor, descuento_moneda " &
                    "FROM FLORERIA_PrePedido_Entrega WHERE prepedido_entrega_id = @eid"
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@eid", PrePedidoEntregaId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            ValorReceptor = If(IsDBNull(dr("receptor_nombre")), "", dr("receptor_nombre").ToString())
                            ValorCelularReceptor = If(IsDBNull(dr("receptor_celular")), "", dr("receptor_celular").ToString())
                            ValorCiudadId = If(IsDBNull(dr("ciudad_id")), 0, CInt(dr("ciudad_id")))
                            ValorZonaId = If(IsDBNull(dr("zona_id")), 0, CInt(dr("zona_id")))
                            ValorSucursalRecojoId = If(IsDBNull(dr("sucursal_id")), 0, CInt(dr("sucursal_id")))
                            ValorTipoEntrega = If(IsDBNull(dr("tipo_entrega")), "DOMICILIO", dr("tipo_entrega").ToString())
                            ValorDireccion = If(IsDBNull(dr("direccion")), "", dr("direccion").ToString())
                            ValorReferencia = If(IsDBNull(dr("referencia")), "", dr("referencia").ToString())
                            ValorGps = If(IsDBNull(dr("gps")), "", dr("gps").ToString())
                            If Not IsDBNull(dr("fecha_entrega")) Then
                                ValorFecha = CDate(dr("fecha_entrega")).ToString("yyyy-MM-dd")
                            End If
                            ValorSlotId = If(IsDBNull(dr("slot_id")), 0, CInt(dr("slot_id")))
                            ValorExpress = If(IsDBNull(dr("es_express")), False, CBool(dr("es_express")))
                            ValorDedicatoria = If(IsDBNull(dr("dedicatoria")), "", dr("dedicatoria").ToString())
                            ValorFirma = If(IsDBNull(dr("firma_tarjeta")), "", dr("firma_tarjeta").ToString())
                            ValorOcasion = If(IsDBNull(dr("tipo_ocacion")), "", dr("tipo_ocacion").ToString())
                            ValorSucursalPreparaId = If(IsDBNull(dr("sucursal_prepara_id")), 0, CInt(dr("sucursal_prepara_id")))
                            MonedaSeleccionada = If(IsDBNull(dr("moneda")), "BOB", dr("moneda").ToString())
                            ValorDescuento = If(IsDBNull(dr("descuento_valor")), "0", CDec(dr("descuento_valor")).ToString())
                            ValorDescuentoMoneda = If(IsDBNull(dr("descuento_moneda")), "BOB", dr("descuento_moneda").ToString())
                        End If
                    End Using
                End Using
            End Using

            ' Construir texto inicial para input de zona (Nombre (Bs X.XX))
            If ValorZonaId > 0 Then
                ValorZonaTexto = ObtenerTextoZona(ValorZonaId)
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Entrega_Agregar.CargarDatosBorrador: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' ObtenerTextoZona (Nombre (Bs X.XX))
    ' ============================================================
    Private Function ObtenerTextoZona(zonaId As Integer) As String
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Dim sql As String = "SELECT z.nombre, " &
                    "ISNULL((SELECT TOP 1 t.precio_bs FROM FLORERIA_Zona_Tarifa t WHERE t.zona_id = z.zona_id ORDER BY t.vigente_desde DESC), 0) AS precio_bs " &
                    "FROM FLORERIA_Zona z WHERE z.zona_id = @id"
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@id", zonaId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Return dr("nombre").ToString() & " (Bs " & CDec(dr("precio_bs")).ToString("F2") & ")"
                        End If
                    End Using
                End Using
            End Using
        Catch
        End Try
        Return ""
    End Function

    ' ============================================================
    ' CargarProductosBorrador
    ' ============================================================
    Private Sub CargarProductosBorrador()
        Try
            Dim sb As New System.Text.StringBuilder()
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Dim sql As String = "SELECT detalle_id, producto_id, variacion_id, es_personalizado, " &
                    "nombre_producto, descripcion, cantidad, precio_unitario_bs, precio_unitario_usd, " &
                    "subtotal_bs, personalizacion " &
                    "FROM FLORERIA_PrePedido_Entrega_Detalle WHERE prepedido_entrega_id = @eid"
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@eid", PrePedidoEntregaId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim esPersonalizado As Boolean = CBool(dr("es_personalizado"))
                            Dim nombreProd As String = dr("nombre_producto").ToString()
                            Dim precioBs As Decimal = CDec(dr("precio_unitario_bs"))
                            Dim cantidad As Integer = CInt(dr("cantidad"))
                            Dim personalizacion As String = If(IsDBNull(dr("personalizacion")), "", dr("personalizacion").ToString())
                            Dim detalleId As Integer = CInt(dr("detalle_id"))

                            If esPersonalizado Then
                                sb.AppendLine("<div class='ea-prod-row personalizado' data-detalle-id='" & detalleId & "' data-precio='" & precioBs.ToString("F2") & "' data-cantidad='" & cantidad & "'>")
                                sb.AppendLine("  <div>")
                                sb.AppendLine("    <span class='ea-prod-name'>Producto Personalizado <span style='font-size:9px;color:#F57F17'>WC#7076</span></span>")
                                sb.AppendLine("    <span class='ea-prod-custom'>" & Server.HtmlEncode(personalizacion) & "</span>")
                                sb.AppendLine("    <div style='display:flex;align-items:center;gap:6px;margin-top:3px'><span style='font-size:10px;color:#999'>Cant:</span><input type='number' value='" & cantidad & "' min='1' style='width:45px;text-align:center;padding:2px;font-size:11px;border:1px solid #FFE082;border-radius:4px' onchange='actualizarDetalle(" & detalleId & ", ""cantidad"", this.value)'></div>")
                                sb.AppendLine("  </div>")
                                sb.AppendLine("  <input type='number' value='" & precioBs.ToString("F2") & "' step='0.01' style='width:75px;text-align:center;padding:3px;font-size:12px;border:1px solid #FFE082;border-radius:4px' onchange='actualizarDetalle(" & detalleId & ", ""precio"", this.value)'>")
                            Else
                                sb.AppendLine("<div class='ea-prod-row' data-detalle-id='" & detalleId & "' data-precio='" & precioBs.ToString("F2") & "' data-cantidad='" & cantidad & "'>")
                                sb.AppendLine("  <div>")
                                sb.AppendLine("    <span class='ea-prod-name'>" & Server.HtmlEncode(nombreProd) & "</span>")
                                If personalizacion <> "" Then
                                    sb.AppendLine("    <span class='ea-prod-detail'><span>" & Server.HtmlEncode(personalizacion) & "</span></span>")
                                End If
                                sb.AppendLine("  </div>")
                                sb.AppendLine("  <span style='font-weight:500'>Bs " & precioBs.ToString("N2") & "</span>")
                            End If

                            sb.AppendLine("  <button type='button' style='border:none;background:none;color:#E53935;cursor:pointer;font-size:14px;padding:0' onclick='eliminarDetalle(" & detalleId & ", this)'><i class='ti ti-trash'></i></button>")
                            sb.AppendLine("</div>")
                        End While
                    End Using
                End Using
            End Using
            HtmlProductos = sb.ToString()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Entrega_Agregar.CargarProductosBorrador: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' CargarPagosBorrador
    ' ============================================================
    Private Sub CargarPagosBorrador()
        Try
            Dim sb As New System.Text.StringBuilder()
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Dim sql As String = "SELECT pago_id, metodo_pago, moneda, monto, fecha_pago, verificado " &
                    "FROM FLORERIA_PrePedido_Entrega_Pago WHERE prepedido_entrega_id = @eid ORDER BY fecha_pago"
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@eid", PrePedidoEntregaId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim pagoId As Integer = CInt(dr("pago_id"))
                            Dim metodo As String = dr("metodo_pago").ToString()
                            Dim moneda As String = dr("moneda").ToString()
                            Dim monto As Decimal = CDec(dr("monto"))
                            Dim fecha As DateTime = CDate(dr("fecha_pago"))
                            Dim verificado As Boolean = CBool(dr("verificado"))

                            sb.AppendLine("<div class='ea-pago-row'>")
                            sb.AppendLine("  <span>" & metodo & "</span>")
                            sb.AppendLine("  <span style='font-weight:500'>" & If(moneda = "USD", "$ ", "Bs ") & monto.ToString("N2") & "</span>")
                            sb.AppendLine("  <span style='color:#999'>" & moneda & "</span>")
                            sb.AppendLine("  <span style='font-size:11px;color:#999'>" & fecha.ToString("dd/MM") & "</span>")
                            If verificado Then
                                sb.AppendLine("  <span><i class='ti ti-check' style='font-size:14px;color:#2E7D32'></i></span>")
                            Else
                                sb.AppendLine("  <span><i class='ti ti-clock' style='font-size:14px;color:#F9A825'></i></span>")
                            End If
                            sb.AppendLine("  <button type='button' style='border:none;background:none;color:#E53935;cursor:pointer;font-size:13px;padding:0' onclick='eliminarPago(" & pagoId & ", this)'><i class='ti ti-trash'></i></button>")
                            sb.AppendLine("</div>")
                        End While
                    End Using
                End Using
            End Using
            HtmlPagos = sb.ToString()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Entrega_Agregar.CargarPagosBorrador: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' CargarCiudades (marca selected segun ValorCiudadId)
    ' ============================================================
    Private Sub CargarCiudades()
        Try
            Dim sb As New System.Text.StringBuilder()
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("SELECT ciudad_id, nombre FROM FLORERIA_Ciudad WHERE activo = 1 ORDER BY nombre", conn)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim cid As Integer = CInt(dr("ciudad_id"))
                            Dim selected As String = If(cid = ValorCiudadId, " selected", "")
                            sb.AppendLine("<option value='" & cid & "'" & selected & ">" & dr("nombre").ToString() & "</option>")
                        End While
                    End Using
                End Using
            End Using
            HtmlCiudades = sb.ToString()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Entrega_Agregar.CargarCiudades: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' CargarZonas (JSON para JS - no se marca selected aqui)
    ' ============================================================
    Private Sub CargarZonas()
        Try
            Dim zonasList As New List(Of Object)
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Dim sql As String = "SELECT z.zona_id, z.ciudad_id, z.nombre, " &
                    "ISNULL((SELECT TOP 1 t.precio_bs FROM FLORERIA_Zona_Tarifa t WHERE t.zona_id = z.zona_id ORDER BY t.vigente_desde DESC), 0) AS precio_bs " &
                    "FROM FLORERIA_Zona z WHERE z.activo = 1 ORDER BY z.nombre"
                Using cmd As New SqlCommand(sql, conn)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            zonasList.Add(New With {
                                .zona_id = CInt(dr("zona_id")),
                                .ciudad_id = CInt(dr("ciudad_id")),
                                .nombre = dr("nombre").ToString(),
                                .precio_bs = CDec(dr("precio_bs"))
                            })
                        End While
                    End Using
                End Using
            End Using
            Dim serializer As New JavaScriptSerializer()
            ZonasJson = serializer.Serialize(zonasList)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Entrega_Agregar.CargarZonas: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' CargarSucursales (marca selected en combo Prepara y card de Recojo)
    ' ============================================================
    Private Sub CargarSucursales()
        Try
            Dim sb As New System.Text.StringBuilder()
            Dim sbRecojo As New System.Text.StringBuilder()
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("SELECT sucursal_id, nombre, direccion FROM FLORERIA_Sucursal WHERE activo = 1 ORDER BY nombre", conn)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim sucId As Integer = CInt(dr("sucursal_id"))
                            Dim nombre As String = dr("nombre").ToString()
                            Dim direccion As String = If(IsDBNull(dr("direccion")), "", dr("direccion").ToString())

                            Dim selectedPrepara As String = If(sucId = ValorSucursalPreparaId, " selected", "")
                            sb.AppendLine("<option value='" & sucId & "'" & selectedPrepara & ">" & nombre & "</option>")

                            Dim claseRecojo As String = If(sucId = ValorSucursalRecojoId, "ea-sucursal-card selected", "ea-sucursal-card")
                            sbRecojo.AppendLine("<div class='" & claseRecojo & "' onclick='seleccionarSucursalRecojo(" & sucId & "); var cards=this.parentNode.children; for(var i=0;i<cards.length;i++){cards[i].classList.remove(""selected"")}; this.classList.add(""selected"")'>")
                            sbRecojo.AppendLine("  <i class='ti ti-building-store' style='font-size:20px;color:#3B5BDB'></i>")
                            sbRecojo.AppendLine("  <p style='margin:4px 0 0;font-size:13px;font-weight:500'>" & nombre & "</p>")
                            sbRecojo.AppendLine("  <p style='margin:2px 0 0;font-size:10px;color:#999'>" & direccion & "</p>")
                            sbRecojo.AppendLine("</div>")
                        End While
                    End Using
                End Using
            End Using
            HtmlSucursales = sb.ToString()
            HtmlSucursalesRecojo = sbRecojo.ToString()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Entrega_Agregar.CargarSucursales: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' CargarSlots (marca selected segun ValorSlotId)
    ' ============================================================
    Private Sub CargarSlots()
        Try
            Dim slotsList As New List(Of Object)
            Dim sbNormal As New System.Text.StringBuilder()
            Dim sbExpress As New System.Text.StringBuilder()
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("SELECT slot_id, etiqueta, recargo_bs, es_express FROM FLORERIA_Slot_Horario WHERE activo = 1 ORDER BY es_express, orden_display, hora_inicio", conn)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim slotId As Integer = CInt(dr("slot_id"))
                            Dim etiqueta As String = dr("etiqueta").ToString()
                            Dim recargo As Decimal = If(IsDBNull(dr("recargo_bs")), 0, CDec(dr("recargo_bs")))
                            Dim esExpress As Boolean = CBool(dr("es_express"))
                            Dim textoRecargo As String = If(recargo > 0, " +Bs" & recargo.ToString("N0"), "")
                            Dim selected As String = If(slotId = ValorSlotId, " selected", "")
                            Dim optionHtml As String = "<option value='" & slotId & "'" & selected & ">" & etiqueta & textoRecargo & "</option>"
                            If esExpress Then
                                sbExpress.AppendLine(optionHtml)
                            Else
                                sbNormal.AppendLine(optionHtml)
                            End If
                            slotsList.Add(New With {.slot_id = slotId, .etiqueta = etiqueta, .recargo_bs = recargo, .es_express = esExpress})
                        End While
                    End Using
                End Using
            End Using
            HtmlSlots = "<optgroup label='Horarios normales'>" & sbNormal.ToString() & "</optgroup>" &
                        "<optgroup label='Horarios express'>" & sbExpress.ToString() & "</optgroup>"
            Dim serializer As New JavaScriptSerializer()
            SlotsJson = serializer.Serialize(slotsList)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Entrega_Agregar.CargarSlots: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' CargarCategorias (para filtros del buscador)
    ' ============================================================
    Private Sub CargarCategorias()
        Try
            Dim sb As New System.Text.StringBuilder()
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("SELECT categoria_id, nombre FROM FLORERIA_Categoria WHERE activo = 1 ORDER BY orden, nombre", conn)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim catId As Integer = CInt(dr("categoria_id"))
                            Dim nombre As String = dr("nombre").ToString()
                            sb.AppendLine("<option value='" & catId & "'>" & nombre & "</option>")
                        End While
                    End Using
                End Using
            End Using
            HtmlCategoriasBtns = sb.ToString()
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Entrega_Agregar.CargarCategorias: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' btnAccion_Click
    ' ============================================================
    Protected Sub btnAccion_Click(sender As Object, e As EventArgs)
        ' Postback para acciones que requieren servidor completo
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""
        ' TODO: implementar acciones WooCommerce
    End Sub

End Class
