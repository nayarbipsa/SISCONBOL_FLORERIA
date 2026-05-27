Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Text

' ============================================================
' SISCONBOL - Detalle Pre-Pedido Completo
' Archivo: Modulos/Pedidos/PrePedido_Detalle.aspx.vb
' MasterPage: Site.Master
' SQL CORREGIDO PARA TABLA REAL
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

    ' --- Borradores (FLORERIA_PrePedido_Entrega estado='BORRADOR') ---
    Public Property CantidadBorradores As Integer = 0
    Public Property HtmlBorradores As String = ""

    ' --- Estado del link al cliente ---
    Public Property EstadoLink As Integer = 0    ' 0=no enviado, 1=esperando, 2=cliente confirmo
    Public Property TokenWeb As String = ""
    Public Property TokenExpira As DateTime = DateTime.MinValue
    Public Property TokenAbiertoEn As DateTime = DateTime.MinValue
    Public Property TokenConfirmadoEn As DateTime = DateTime.MinValue
    Public Property LinkExpirado As Boolean = False
    Public Property HorasParaExpirar As Integer = 0

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
                    "p.token_web, p.token_expira, p.token_abierto_en, p.token_confirmado_por_cliente_en, " &
                    "p.creado_en, " &
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
                            
                            ' Link web (token)
                            If Not IsDBNull(dr("token_web")) Then
                                Dim token As String = dr("token_web").ToString()
                                If token <> "" Then
                                    TokenWeb = token
                                    LinkWebGenerado = True
                                    ' La URL real se construye en PrePedido_Handler.ashx (respeta el dominio)
                                    LinkCompleto = ""

                                    If Not IsDBNull(dr("token_expira")) Then
                                        TokenExpira = CDate(dr("token_expira"))
                                        FechaExpiracion = TokenExpira.ToString("dd/MM/yyyy HH:mm")
                                    End If
                                End If
                            End If
                            If Not IsDBNull(dr("token_abierto_en")) Then
                                TokenAbiertoEn = CDate(dr("token_abierto_en"))
                            End If
                            If Not IsDBNull(dr("token_confirmado_por_cliente_en")) Then
                                TokenConfirmadoEn = CDate(dr("token_confirmado_por_cliente_en"))
                            End If
                        Else
                            Response.Redirect("PrePedidos.aspx")
                            Return
                        End If
                    End Using
                End Using

                ' ----- Calcular EstadoLink y horas para expirar -----
                CalcularEstadoLink()

                ' ============================================================
                ' 2. CARGAR PEDIDOS (ENTREGAS)
                ' ============================================================
                CargarPedidos(conn)
                CargarBorradores(conn)

            End Using
        Catch ex As Exception
            MensajeAlerta = "Error al cargar datos: " & ex.Message
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

        ' ============================================================
        ' SQL CORRECTO CON COLUMNAS REALES + JOINs
        ' ============================================================
        Dim sql As String = "SELECT " &
            "ped.pedido_id, ped.codigo, ped.receptor_nombre, ped.receptor_celular, " &
            "ped.fecha_entrega, ped.direccion, ped.tipo_entrega, " &
            "ped.subtotal_productos_bs, ped.envio_bs, ped.total_bs, " &
            "ped.wc_order_id, ped.wc_order_number, " &
            "c.nombre AS ciudad_nombre, " &
            "z.nombre AS zona_nombre, " &
            "s.hora_inicio, s.hora_fin " &
            "FROM FLORERIA_Pedido ped " &
            "LEFT JOIN FLORERIA_Ciudad c ON ped.ciudad_id = c.ciudad_id " &
            "LEFT JOIN FLORERIA_Zona z ON ped.zona_id = z.zona_id " &
            "LEFT JOIN FLORERIA_Slot_Horario s ON ped.slot_id = s.slot_id " &
            "WHERE ped.prepedido_id = @id " &
            "ORDER BY ped.pedido_id"

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
                    
                    Dim horario As String = "Sin horario"
                    If Not IsDBNull(dr("hora_inicio")) AndAlso Not IsDBNull(dr("hora_fin")) Then
                        horario = dr("hora_inicio").ToString() & " - " & dr("hora_fin").ToString()
                    End If
                    
                    ' Zona y dirección
                    Dim zona As String = If(IsDBNull(dr("zona_nombre")), "Sin zona", dr("zona_nombre").ToString())
                    Dim direccion As String = If(IsDBNull(dr("direccion")), "", dr("direccion").ToString())
                    
                    ' Tipo entrega
                    Dim tipoEnt As String = If(IsDBNull(dr("tipo_entrega")), "DOMICILIO", dr("tipo_entrega").ToString())
                    
                    ' Costos
                    Dim costoEnvio As Decimal = If(IsDBNull(dr("envio_bs")), 0, CDec(dr("envio_bs")))
                    Dim total As Decimal = If(IsDBNull(dr("total_bs")), 0, CDec(dr("total_bs")))
                    Dim subtotalProds As Decimal = If(IsDBNull(dr("subtotal_productos_bs")), 0, CDec(dr("subtotal_productos_bs")))
                    
                    ' Acumular totales
                    totalProd += subtotalProds
                    totalEnv += costoEnvio
                    
                    ' WooCommerce
                    Dim wcOrderId As Integer = If(IsDBNull(dr("wc_order_id")), 0, CInt(dr("wc_order_id")))
                    
                    ' Generar HTML del pedido
                    sb.AppendLine("<div class='pedido-card'>")
                    sb.AppendLine("  <div class='pedido-header'>")
                    sb.AppendLine("    <div class='pedido-numero'>" & numPedido & "</div>")
                    sb.AppendLine("    <div class='pedido-info'>")
                    sb.AppendLine("      <h4 class='pedido-codigo'>" & pedidoCodigo & "</h4>")
                    sb.AppendLine("      <p class='pedido-desc'>Para " & receptor & If(celReceptor <> "", " • " & celReceptor, "") & "</p>")
                    sb.AppendLine("    </div>")
                    
                    ' --- Tag CONFIRMADO + Menú "Acciones" desplegable ---
                    sb.AppendLine("    <div style='display:flex;gap:6px;align-items:center;flex-shrink:0'>")
                    sb.AppendLine("      <span style='background:#E8F5E9;color:#2E7D32;padding:4px 10px;border-radius:6px;font-size:11px;font-weight:500;white-space:nowrap'>")
                    sb.AppendLine("        <i class='ti ti-check' style='font-size:13px;vertical-align:-2px'></i> CONFIRMADO")
                    sb.AppendLine("      </span>")
                    sb.AppendLine("      <div class='menu-wrap' style='position:relative'>")
                    sb.AppendLine("        <button type='button' class='btn-acciones-menu' onclick='toggleMenuPedido(this, event)' style='background:#f5f5f5;border:1px solid #e0e0e0;padding:5px 10px;border-radius:6px;font-size:11px;cursor:pointer;display:inline-flex;align-items:center;gap:4px;color:#424242;font-weight:500;white-space:nowrap'>")
                    sb.AppendLine("          Acciones <i class='ti ti-chevron-down' style='font-size:13px'></i>")
                    sb.AppendLine("        </button>")
                    sb.AppendLine("        <div class='menu-dropdown-pedido' data-pedido-id='" & pedidoId & "' style='display:none;position:absolute;top:calc(100% + 4px);right:0;background:#fff;border:1px solid #e0e0e0;border-radius:8px;box-shadow:0 4px 12px rgba(0,0,0,.08);min-width:210px;overflow:hidden;z-index:10'>")
                    
                    ' Opción: Ir al pedido
                    sb.AppendLine("          <a href='Pedido_Detalle.aspx?id=" & pedidoId & "' style='display:flex;align-items:center;gap:8px;padding:10px 14px;font-size:12px;text-decoration:none;color:#212121;border-bottom:1px solid #f5f5f5'>")
                    sb.AppendLine("            <i class='ti ti-eye' style='font-size:15px;width:18px;color:#7F77DD'></i>")
                    sb.AppendLine("            <div>Ir al pedido<span style='display:block;font-size:10px;color:#9e9e9e;margin-top:1px'>Ver detalle completo</span></div>")
                    sb.AppendLine("          </a>")
                    
                    ' Opción: Imprimir recibo
                    sb.AppendLine("          <a href='Recibo.aspx?id=" & pedidoId & "' target='_blank' style='display:flex;align-items:center;gap:8px;padding:10px 14px;font-size:12px;text-decoration:none;color:#212121;border-bottom:1px solid #f5f5f5'>")
                    sb.AppendLine("            <i class='ti ti-printer' style='font-size:15px;width:18px;color:#3B5BDB'></i>")
                    sb.AppendLine("            <div>Imprimir recibo<span style='display:block;font-size:10px;color:#9e9e9e;margin-top:1px'>Ticket térmico 80mm</span></div>")
                    sb.AppendLine("          </a>")
                    
                    ' Opción: Ver / Crear en WooCommerce
                    If wcOrderId > 0 Then
                        Dim wcUrl As String = "https://miss-flores.com/wp-admin/post.php?post=" & wcOrderId & "&action=edit"
                        sb.AppendLine("          <a href='" & wcUrl & "' target='_blank' style='display:flex;align-items:center;gap:8px;padding:10px 14px;font-size:12px;text-decoration:none;color:#212121'>")
                        sb.AppendLine("            <i class='ti ti-brand-woocommerce' style='font-size:15px;width:18px;color:#6A1B9A'></i>")
                        sb.AppendLine("            <div>Ver en WooCommerce<span style='display:block;font-size:10px;color:#9e9e9e;margin-top:1px'>#" & wcOrderId & "</span></div>")
                        sb.AppendLine("          </a>")
                    Else
                        sb.AppendLine("          <button type='button' onclick='sincronizarConWC(" & pedidoId & ", this); cerrarMenusPedido();' style='display:flex;align-items:center;gap:8px;padding:10px 14px;font-size:12px;background:none;border:none;cursor:pointer;width:100%;text-align:left;color:#212121'>")
                        sb.AppendLine("            <i class='ti ti-brand-woocommerce' style='font-size:15px;width:18px;color:#E65100'></i>")
                        sb.AppendLine("            <div>Crear en WooCommerce<span style='display:block;font-size:10px;color:#9e9e9e;margin-top:1px'>Sincronizar este pedido</span></div>")
                        sb.AppendLine("          </button>")
                    End If
                    
                    sb.AppendLine("        </div>") ' fin menu-dropdown-pedido
                    sb.AppendLine("      </div>") ' fin menu-wrap
                    sb.AppendLine("    </div>") ' fin acciones (tag + menú)
                    sb.AppendLine("  </div>") ' fin pedido-header
                    
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
    ' CargarBorradores - Lista de entregas en estado BORRADOR
    ' (FLORERIA_PrePedido_Entrega + agregados de detalle)
    ' ============================================================
    Private Sub CargarBorradores(conn As SqlConnection)
        Dim sb As New StringBuilder()
        Dim cant As Integer = 0

        Dim sql As String = "SELECT " &
            "e.prepedido_entrega_id, e.receptor_nombre, e.receptor_celular, " &
            "e.tipo_entrega, e.direccion, e.fecha_entrega, " &
            "c.nombre AS ciudad_nombre, z.nombre AS zona_nombre, " &
            "su.nombre AS sucursal_nombre, " &
            "s.hora_inicio, s.hora_fin, " &
            "ISNULL((SELECT COUNT(*) FROM FLORERIA_PrePedido_Entrega_Detalle d " &
            "        WHERE d.prepedido_entrega_id = e.prepedido_entrega_id), 0) AS cant_items, " &
            "ISNULL((SELECT SUM(subtotal_bs) FROM FLORERIA_PrePedido_Entrega_Detalle d " &
            "        WHERE d.prepedido_entrega_id = e.prepedido_entrega_id), 0) AS subtotal_bs, " &
            "e.modificado_en, e.creado_en " &
            "FROM FLORERIA_PrePedido_Entrega e " &
            "LEFT JOIN FLORERIA_Ciudad c ON e.ciudad_id = c.ciudad_id " &
            "LEFT JOIN FLORERIA_Zona z ON e.zona_id = z.zona_id " &
            "LEFT JOIN FLORERIA_Sucursal su ON e.sucursal_id = su.sucursal_id " &
            "LEFT JOIN FLORERIA_Slot_Horario s ON e.slot_id = s.slot_id " &
            "WHERE e.prepedido_id = @id AND e.estado = 'BORRADOR' " &
            "ORDER BY e.prepedido_entrega_id"

        Using cmd As New SqlCommand(sql, conn)
            cmd.Parameters.AddWithValue("@id", PrePedidoId)

            Using dr As SqlDataReader = cmd.ExecuteReader()
                While dr.Read()
                    cant += 1
                    Dim entId As Integer = CInt(dr("prepedido_entrega_id"))
                    Dim receptor As String = If(IsDBNull(dr("receptor_nombre")), "", dr("receptor_nombre").ToString())
                    Dim celReceptor As String = If(IsDBNull(dr("receptor_celular")), "", dr("receptor_celular").ToString())

                    Dim fechaEnt As String = "Sin fecha"
                    If Not IsDBNull(dr("fecha_entrega")) Then
                        fechaEnt = CDate(dr("fecha_entrega")).ToString("dd MMM yyyy")
                    End If

                    Dim horario As String = "Sin horario"
                    If Not IsDBNull(dr("hora_inicio")) AndAlso Not IsDBNull(dr("hora_fin")) Then
                        horario = dr("hora_inicio").ToString() & " - " & dr("hora_fin").ToString()
                    End If

                    Dim ciudad As String = If(IsDBNull(dr("ciudad_nombre")), "Sin ciudad", dr("ciudad_nombre").ToString())
                    Dim zona As String = If(IsDBNull(dr("zona_nombre")), "Sin zona", dr("zona_nombre").ToString())
                    Dim sucursal As String = If(IsDBNull(dr("sucursal_nombre")), "", dr("sucursal_nombre").ToString())
                    Dim direccion As String = If(IsDBNull(dr("direccion")), "", dr("direccion").ToString())
                    Dim tipoEnt As String = If(IsDBNull(dr("tipo_entrega")), "DOMICILIO", dr("tipo_entrega").ToString())
                    Dim cantItems As Integer = CInt(dr("cant_items"))
                    Dim subtotalBs As Decimal = CDec(dr("subtotal_bs"))

                    ' Etiqueta destino
                    Dim destinoLabel As String
                    If tipoEnt = "RECOJO_SUCURSAL" Then
                        destinoLabel = If(sucursal = "", "Recojo (sin sucursal)", "Recojo en " & sucursal)
                    Else
                        destinoLabel = zona & ", " & ciudad
                    End If

                    ' Receptor: "Sin destinatario" si esta vacio
                    Dim receptorLabel As String
                    If receptor = "" Then
                        receptorLabel = "<span style='color:#999;font-style:italic'>Sin destinatario</span>"
                    Else
                        receptorLabel = receptor & If(celReceptor <> "", " &bull; " & celReceptor, "")
                    End If

                    sb.AppendLine("<div class='pedido-card' style='border-style:dashed;border-color:#F9A825;background:#FFFDE7'>")
                    sb.AppendLine("  <div class='pedido-header'>")
                    sb.AppendLine("    <div class='pedido-numero' style='background:#F9A825'>" & cant & "</div>")
                    sb.AppendLine("    <div class='pedido-info'>")
                    sb.AppendLine("      <h4 class='pedido-codigo'>Borrador #" & entId & " " &
                                  "<span style='font-size:10px;background:#FFF3CD;color:#856404;padding:2px 8px;border-radius:10px;margin-left:6px;font-weight:500;text-transform:uppercase'>" &
                                  "<i class='ti ti-pencil' style='font-size:11px;vertical-align:-1px'></i> Borrador</span></h4>")
                    sb.AppendLine("      <p class='pedido-desc'>Para " & receptorLabel & "</p>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("    <div style='display:flex;gap:6px;'>")
                    sb.AppendLine("      <a href='Entrega_Agregar.aspx?prepedido=" & PrePedidoId & "&entrega=" & entId & "' class='btn btn-primary btn-sm'>")
                    sb.AppendLine("        <i class='ti ti-edit'></i> Continuar editando")
                    sb.AppendLine("      </a>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("  </div>")

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
                    sb.AppendLine("      <div class='pedido-field-label'>Destino</div>")
                    sb.AppendLine("      <div class='pedido-field-value'>" & destinoLabel & "</div>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("    <div class='pedido-field'>")
                    sb.AppendLine("      <div class='pedido-field-label'>Productos</div>")
                    sb.AppendLine("      <div class='pedido-field-value'>" & cantItems & " items &mdash; Bs " & subtotalBs.ToString("N2") & "</div>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("  </div>")

                    If direccion <> "" Then
                        sb.AppendLine("  <div style='margin-bottom:0.5rem;'>")
                        sb.AppendLine("    <div class='pedido-field-label'>Direccion</div>")
                        sb.AppendLine("    <div style='font-size:13px;color:#424242;margin-top:4px;'>" & direccion & "</div>")
                        sb.AppendLine("  </div>")
                    End If

                    sb.AppendLine("</div>")
                End While
            End Using
        End Using

        CantidadBorradores = cant
        HtmlBorradores = sb.ToString()
    End Sub

    ' ============================================================
    ' Funciones auxiliares
    ' ============================================================
    Private Function GenerarBadgeEstado(estado As String) As String
        Select Case estado
            Case "BORRADOR"
                Return "<span class='badge badge-secondary'>Borrador</span>"
            Case "FORM_ENVIADO"
                Return "<span class='badge badge-info'>Formulario Enviado</span>"
            Case "FORM_COMPLETADO"
                Return "<span class='badge badge-primary'>Formulario Completado</span>"
            Case "COMPROBANTE_ENVIADO"
                Return "<span class='badge badge-warning'>Comprobante Enviado</span>"
            Case "PAGADO"
                Return "<span class='badge badge-success'>Pagado</span>"
            Case "COMPLETADO"
                Return "<span class='badge badge-success'>Completado</span>"
            Case "CANCELADO"
                Return "<span class='badge badge-danger'>Cancelado</span>"
            Case Else
                Return "<span class='badge badge-secondary'>" & estado & "</span>"
        End Select
    End Function

    Private Function FormatearFechaRelativa(fecha As DateTime) As String
        Dim ahora As DateTime = DateTime.Now
        Dim diff As TimeSpan = ahora - fecha
        
        If diff.TotalMinutes < 1 Then
            Return "Hace un momento"
        ElseIf diff.TotalMinutes < 60 Then
            Return "Hace " & CInt(diff.TotalMinutes) & " minutos"
        ElseIf diff.TotalHours < 24 Then
            Return "Hace " & CInt(diff.TotalHours) & " horas"
        ElseIf diff.TotalDays < 7 Then
            Return "Hace " & CInt(diff.TotalDays) & " días"
        Else
            Return fecha.ToString("dd MMM yyyy")
        End If
    End Function

    ' ============================================================
    ' CalcularEstadoLink:
    '   0 = sin token (no enviado)
    '   1 = token vigente, esperando que cliente confirme
    '   2 = cliente confirmo
    '   Tambien marca LinkExpirado y HorasParaExpirar
    ' ============================================================
    Private Sub CalcularEstadoLink()
        If TokenWeb = "" Then
            EstadoLink = 0
            Return
        End If

        If TokenExpira > DateTime.MinValue Then
            If TokenExpira <= DateTime.Now Then
                LinkExpirado = True
                HorasParaExpirar = 0
            Else
                LinkExpirado = False
                HorasParaExpirar = CInt(Math.Max(0, Math.Ceiling(TokenExpira.Subtract(DateTime.Now).TotalHours)))
            End If
        End If

        If TokenConfirmadoEn > DateTime.MinValue Then
            EstadoLink = 2
        Else
            EstadoLink = 1
        End If
    End Sub
End Class



