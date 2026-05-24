Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Text

' ============================================================
' SISCONBOL - Detalle Pre-Pedido Completo
' Archivo: Modulos/Pedidos/PrePedido_Detalle.aspx.vb
' MasterPage: Site.Master
' ============================================================
Partial Public Class Modulos_Pedidos_PrePedido_Detalle
    Inherits System.Web.UI.Page

    ' Propiedades públicas para la vista
    Public Property MensajeAlerta As String = ""
    Public Property PrePedidoId As Integer = 0
    Public Property Codigo As String = ""
    Public Property Estado As String = ""
    Public Property BadgeEstado As String = ""
    Public Property FechaCreacion As String = ""
    Public Property NombreAgente As String = ""
    Public Property ClienteNombre As String = ""
    Public Property ClienteCelular As String = ""
    Public Property ClienteEmail As String = ""
    Public Property TipoRegistro As String = ""
    Public Property LinkWebGenerado As Boolean = False
    Public Property LinkCompleto As String = ""
    Public Property FechaExpiracion As String = ""
    Public Property CantidadPedidos As Integer = 0
    Public Property CantidadProductos As Integer = 0
    Public Property TotalProductos As String = "0.00"
    Public Property TotalEnvios As String = "0.00"
    Public Property TotalGeneral As String = "0.00"
    Public Property HtmlPedidos As String = ""

    ' ============================================================
    ' Page_Load
    ' ============================================================
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Dim idStr As String = Request.QueryString("id")
            
            If String.IsNullOrEmpty(idStr) Then
                Response.Redirect("PrePedidos.aspx")
                Return
            End If

            Dim id As Integer = 0
            If Not Integer.TryParse(idStr, id) OrElse id <= 0 Then
                Response.Redirect("PrePedidos.aspx")
                Return
            End If

            PrePedidoId = id
            CargarDatos()
        End If
    End Sub

    ' ============================================================
    ' CargarDatos - Cargar toda la información del pre-pedido
    ' ============================================================
    Private Sub CargarDatos()
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                ' ============================================================
                ' 1. DATOS PRINCIPALES DEL PRE-PEDIDO
                ' ============================================================
                Dim sql As String = "SELECT p.codigo, p.estado, p.tipo_registro, " &
                    "p.cliente_nombre, p.cliente_apellidos, p.cliente_celular, p.cliente_email, " &
                    "p.token_web, p.token_expira, p.creado_en, " &
                    "u.nombres + ' ' + u.apellidos AS agente_nombre " &
                    "FROM FLORERIA_PrePedido p " &
                    "LEFT JOIN FLORERIA_Usuario u ON p.creado_por = u.usuario_id " &
                    "WHERE p.prepedido_id = @id"

                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@id", PrePedidoId)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            ' Código y estado
                            Codigo = dr("codigo").ToString()
                            Estado = dr("estado").ToString()
                            
                            ' Badge de estado
                            BadgeEstado = GenerarBadgeEstado(Estado)
                            
                            ' Tipo de registro
                            Dim tipo As String = dr("tipo_registro").ToString()
                            Select Case tipo
                                Case "PRE_PEDIDO"
                                    TipoRegistro = "Pre-Pedido"
                                Case "VENTA_TIENDA"
                                    TipoRegistro = "Venta Tienda"
                                Case "VENTA_ANTIGUA"
                                    TipoRegistro = "Venta Antigua"
                                Case Else
                                    TipoRegistro = tipo
                            End Select
                            
                            ' Cliente
                            Dim nombre As String = If(IsDBNull(dr("cliente_nombre")), "", dr("cliente_nombre").ToString())
                            Dim apellidos As String = If(IsDBNull(dr("cliente_apellidos")), "", dr("cliente_apellidos").ToString())
                            
                            If nombre.Trim() <> "" Then
                                ClienteNombre = nombre.Trim()
                                If apellidos.Trim() <> "" Then
                                    ClienteNombre &= " " & apellidos.Trim()
                                End If
                            Else
                                ClienteNombre = "Cliente sin nombre"
                            End If
                            
                            ClienteCelular = dr("cliente_celular").ToString()
                            ClienteEmail = If(IsDBNull(dr("cliente_email")), "Sin email", dr("cliente_email").ToString())
                            
                            ' Fechas
                            Dim creado As DateTime = CDate(dr("creado_en"))
                            FechaCreacion = FormatearFechaRelativa(creado)
                            
                            ' Agente
                            NombreAgente = If(IsDBNull(dr("agente_nombre")), "Desconocido", dr("agente_nombre").ToString())
                            
                            ' Link web
                            If Not IsDBNull(dr("token_web")) Then
                                Dim token As String = dr("token_web").ToString()
                                If token <> "" Then
                                    LinkWebGenerado = True
                                    LinkCompleto = "https://miss-flores.com/pedido?t=" & token
                                    
                                    If Not IsDBNull(dr("token_expira")) Then
                                        Dim expira As DateTime = CDate(dr("token_expira"))
                                        FechaExpiracion = expira.ToString("dd/MM/yyyy HH:mm")
                                    End If
                                End If
                            End If
                        Else
                            Response.Redirect("PrePedidos.aspx")
                            Return
                        End If
                    End Using
                End Using

                ' ============================================================
                ' 2. CARGAR PEDIDOS (ENTREGAS)
                ' ============================================================
                CargarPedidos(conn)

            End Using

        Catch ex As Exception
            MensajeAlerta = "Error al cargar: " & ex.Message
            System.Diagnostics.Debug.WriteLine("ERROR PrePedido_Detalle.CargarDatos: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' CargarPedidos - Cargar lista de pedidos del pre-pedido
    ' ============================================================
    Private Sub CargarPedidos(conn As SqlConnection)
        Dim sb As New StringBuilder()
        Dim totalProd As Decimal = 0
        Dim totalEnv As Decimal = 0
        Dim cantProds As Integer = 0
        Dim numPedido As Integer = 0

        ' Query para obtener pedidos
        Dim sql As String = "SELECT pedido_id, codigo, receptor_nombre, receptor_celular, " &
            "fecha_entrega, horario_inicio, horario_fin, zona_nombre, direccion, " &
            "tipo_entrega, mensaje_tarjeta, costo_envio, total " &
            "FROM FLORERIA_Pedido " &
            "WHERE prepedido_id = @id " &
            "ORDER BY pedido_id"

        Using cmd As New SqlCommand(sql, conn)
            cmd.Parameters.AddWithValue("@id", PrePedidoId)

            Using dr As SqlDataReader = cmd.ExecuteReader()
                While dr.Read()
                    numPedido += 1
                    Dim pedidoId As Integer = CInt(dr("pedido_id"))
                    Dim pedidoCodigo As String = dr("codigo").ToString()
                    Dim receptor As String = dr("receptor_nombre").ToString()
                    Dim celReceptor As String = If(IsDBNull(dr("receptor_celular")), "", dr("receptor_celular").ToString())
                    
                    ' Fecha y horario
                    Dim fechaEnt As String = ""
                    If Not IsDBNull(dr("fecha_entrega")) Then
                        Dim fecha As DateTime = CDate(dr("fecha_entrega"))
                        fechaEnt = fecha.ToString("dd MMM yyyy")
                    End If
                    
                    Dim horario As String = ""
                    If Not IsDBNull(dr("horario_inicio")) AndAlso Not IsDBNull(dr("horario_fin")) Then
                        horario = dr("horario_inicio").ToString() & " - " & dr("horario_fin").ToString()
                    End If
                    
                    ' Zona y dirección
                    Dim zona As String = If(IsDBNull(dr("zona_nombre")), "Sin zona", dr("zona_nombre").ToString())
                    Dim direccion As String = If(IsDBNull(dr("direccion")), "", dr("direccion").ToString())
                    
                    ' Tipo entrega
                    Dim tipoEnt As String = If(IsDBNull(dr("tipo_entrega")), "DOMICILIO", dr("tipo_entrega").ToString())
                    
                    ' Costos
                    Dim costoEnvio As Decimal = If(IsDBNull(dr("costo_envio")), 0, CDec(dr("costo_envio")))
                    Dim total As Decimal = If(IsDBNull(dr("total")), 0, CDec(dr("total")))
                    Dim subtotalProds As Decimal = total - costoEnvio
                    
                    ' Acumular totales
                    totalProd += subtotalProds
                    totalEnv += costoEnvio
                    
                    ' Generar HTML del pedido
                    sb.AppendLine("<div class='pedido-card'>")
                    sb.AppendLine("  <div class='pedido-header'>")
                    sb.AppendLine("    <div class='pedido-numero'>" & numPedido & "</div>")
                    sb.AppendLine("    <div class='pedido-info'>")
                    sb.AppendLine("      <h4 class='pedido-codigo'>" & pedidoCodigo & "</h4>")
                    sb.AppendLine("      <p class='pedido-desc'>Para " & receptor & If(celReceptor <> "", " • " & celReceptor, "") & "</p>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("    <div style='display:flex;gap:6px;'>")
                    sb.AppendLine("      <button type='button' class='btn btn-sm' onclick='editarPedido(" & pedidoId & ")'>")
                    sb.AppendLine("        <i class='ti ti-edit'></i> Editar")
                    sb.AppendLine("      </button>")
                    sb.AppendLine("      <button type='button' class='btn btn-sm' onclick='eliminarPedido(" & pedidoId & ")'>")
                    sb.AppendLine("        <i class='ti ti-trash'></i>")
                    sb.AppendLine("      </button>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("  </div>")
                    
                    ' Información del pedido
                    sb.AppendLine("  <div class='pedido-grid'>")
                    sb.AppendLine("    <div class='pedido-field'>")
                    sb.AppendLine("      <div class='pedido-field-label'>Fecha entrega</div>")
                    sb.AppendLine("      <div class='pedido-field-value'>" & fechaEnt & "</div>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("    <div class='pedido-field'>")
                    sb.AppendLine("      <div class='pedido-field-label'>Horario</div>")
                    sb.AppendLine("      <div class='pedido-field-value'>" & horario & "</div>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("    <div class='pedido-field'>")
                    sb.AppendLine("      <div class='pedido-field-label'>Zona</div>")
                    sb.AppendLine("      <div class='pedido-field-value'>" & zona & "</div>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("    <div class='pedido-field'>")
                    sb.AppendLine("      <div class='pedido-field-label'>Tipo</div>")
                    sb.AppendLine("      <div class='pedido-field-value'>" & If(tipoEnt = "DOMICILIO", "Domicilio", "Recojo") & "</div>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("  </div>")
                    
                    If direccion <> "" Then
                        sb.AppendLine("  <div style='margin-bottom:1rem;'>")
                        sb.AppendLine("    <div class='pedido-field-label'>Direccion</div>")
                        sb.AppendLine("    <div style='font-size:13px;color:#424242;margin-top:4px;'>" & direccion & "</div>")
                        sb.AppendLine("  </div>")
                    End If
                    
                    ' TODO: Cargar productos de este pedido
                    Dim htmlProds As String = CargarProductosPedido(conn, pedidoId, cantProds)
                    If htmlProds <> "" Then
                        sb.AppendLine("  <div class='productos-lista'>")
                        sb.AppendLine("    <div style='font-size:12px;color:#757575;margin-bottom:8px;font-weight:500;'>PRODUCTOS:</div>")
                        sb.AppendLine(htmlProds)
                        sb.AppendLine("  </div>")
                    End If
                    
                    ' Totales del pedido
                    sb.AppendLine("  <div class='totales-box'>")
                    sb.AppendLine("    <div class='total-line'>")
                    sb.AppendLine("      <span class='total-label'>Productos:</span>")
                    sb.AppendLine("      <span class='total-value'>" & subtotalProds.ToString("N2") & " Bs</span>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("    <div class='total-line'>")
                    sb.AppendLine("      <span class='total-label'>Envio:</span>")
                    sb.AppendLine("      <span class='total-value'>" & costoEnvio.ToString("N2") & " Bs</span>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("    <div class='total-line main'>")
                    sb.AppendLine("      <span class='total-label'>TOTAL PEDIDO:</span>")
                    sb.AppendLine("      <span class='total-value'>" & total.ToString("N2") & " Bs</span>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("  </div>")
                    
                    sb.AppendLine("</div>")
                End While
            End Using
        End Using

        CantidadPedidos = numPedido
        CantidadProductos = cantProds
        TotalProductos = totalProd.ToString("N2")
        TotalEnvios = totalEnv.ToString("N2")
        TotalGeneral = (totalProd + totalEnv).ToString("N2")
        HtmlPedidos = sb.ToString()
    End Sub

    ' ============================================================
    ' CargarProductosPedido - Cargar productos de un pedido
    ' ============================================================
    Private Function CargarProductosPedido(conn As SqlConnection, pedidoId As Integer, ByRef contador As Integer) As String
        Dim sb As New StringBuilder()
        
        Dim sql As String = "SELECT pr.nombre, pr.sku, pp.cantidad, pp.precio_unitario, " &
            "(pp.cantidad * pp.precio_unitario) AS subtotal " &
            "FROM FLORERIA_PedidoProducto pp " &
            "INNER JOIN FLORERIA_Producto pr ON pp.producto_id = pr.producto_id " &
            "WHERE pp.pedido_id = @pedido_id " &
            "ORDER BY pp.pedidoproducto_id"

        Using cmd As New SqlCommand(sql, conn)
            cmd.Parameters.AddWithValue("@pedido_id", pedidoId)

            Using dr As SqlDataReader = cmd.ExecuteReader()
                While dr.Read()
                    contador += 1
                    
                    Dim nombre As String = dr("nombre").ToString()
                    Dim sku As String = If(IsDBNull(dr("sku")), "", dr("sku").ToString())
                    Dim cantidad As Integer = CInt(dr("cantidad"))
                    Dim precioUnit As Decimal = CDec(dr("precio_unitario"))
                    Dim subtotal As Decimal = CDec(dr("subtotal"))
                    
                    sb.AppendLine("<div class='producto-item'>")
                    sb.AppendLine("  <div class='producto-icon'>")
                    sb.AppendLine("    <i class='ti ti-flower' style='font-size:24px;color:#999;'></i>")
                    sb.AppendLine("  </div>")
                    sb.AppendLine("  <div class='producto-info'>")
                    sb.AppendLine("    <h5 class='producto-nombre'>" & nombre & "</h5>")
                    If sku <> "" Then
                        sb.AppendLine("    <p class='producto-sku'>SKU: " & sku & "</p>")
                    End If
                    sb.AppendLine("  </div>")
                    sb.AppendLine("  <div class='producto-precio'>")
                    sb.AppendLine("    <div class='producto-cantidad'>Cantidad: " & cantidad & " x " & precioUnit.ToString("N2") & " Bs</div>")
                    sb.AppendLine("    <div class='producto-subtotal'>" & subtotal.ToString("N2") & " Bs</div>")
                    sb.AppendLine("  </div>")
                    sb.AppendLine("</div>")
                End While
            End Using
        End Using

        Return sb.ToString()
    End Function

    ' ============================================================
    ' GenerarBadgeEstado - HTML del badge según estado
    ' ============================================================
    Private Function GenerarBadgeEstado(estado As String) As String
        Dim clase As String = "badge "
        Dim icono As String = ""
        Dim texto As String = ""

        Select Case estado
            Case "BORRADOR"
                clase &= "badge-borrador"
                icono = "ti-pencil"
                texto = "Borrador"
            Case "FORM_ENVIADO"
                clase &= "badge-enviado"
                icono = "ti-send"
                texto = "Link Enviado"
            Case "FORM_COMPLETADO"
                clase &= "badge-completado"
                icono = "ti-check"
                texto = "Completado"
            Case "COMPROBANTE_ENVIADO"
                clase &= "badge-completado"
                icono = "ti-file-upload"
                texto = "Comprobante"
            Case "PAGADO"
                clase &= "badge-pagado"
                icono = "ti-coin"
                texto = "Pagado"
            Case "WC_CREADO"
                clase &= "badge-wc"
                icono = "ti-brand-shopee"
                texto = "En WooCommerce"
            Case "COMPLETADO"
                clase &= "badge-pagado"
                icono = "ti-circle-check"
                texto = "Completado"
            Case "CANCELADO"
                clase &= "badge-cancelado"
                icono = "ti-x"
                texto = "Cancelado"
            Case "EXPIRADO"
                clase &= "badge-expirado"
                icono = "ti-clock-x"
                texto = "Expirado"
            Case Else
                clase &= "badge-borrador"
                texto = estado
        End Select

        Return "<span class='" & clase & "'>" &
               If(icono <> "", "<i class='ti " & icono & "'></i>", "") &
               texto & "</span>"
    End Function

    ' ============================================================
    ' FormatearFechaRelativa - "hace 2 horas", "ayer", etc
    ' ============================================================
    Private Function FormatearFechaRelativa(fecha As DateTime) As String
        Dim ahora As DateTime = DateTime.Now
        Dim diff As TimeSpan = ahora.Subtract(fecha)

        If diff.TotalMinutes < 60 Then
            Return "hace " & CInt(diff.TotalMinutes) & " min"
        ElseIf diff.TotalHours < 24 Then
            Return "hace " & CInt(diff.TotalHours) & " horas"
        ElseIf diff.TotalDays < 7 Then
            Return "hace " & CInt(diff.TotalDays) & " dias"
        Else
            Return fecha.ToString("dd/MM/yyyy HH:mm")
        End If
    End Function

End Class
