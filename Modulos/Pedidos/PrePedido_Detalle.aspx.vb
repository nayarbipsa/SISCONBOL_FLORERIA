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
                    
                    ' Generar HTML del pedido
                    sb.AppendLine("<div class='pedido-card'>")
                    sb.AppendLine("  <div class='pedido-header'>")
                    sb.AppendLine("    <div class='pedido-numero'>" & numPedido & "</div>")
                    sb.AppendLine("    <div class='pedido-info'>")
                    sb.AppendLine("      <h4 class='pedido-codigo'>" & pedidoCodigo & "</h4>")
                    sb.AppendLine("      <p class='pedido-desc'>Para " & receptor & If(celReceptor <> "", " • " & celReceptor, "") & "</p>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("    <div style='display:flex;gap:6px;'>")
                    sb.AppendLine("      <a href='Entrega_Agregar.aspx?prepedido=" & PrePedidoId & "&entrega=" & pedidoId & "' class='btn btn-sm'>")
                    sb.AppendLine("        <i class='ti ti-edit'></i> Editar")
                    sb.AppendLine("      </a>")
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
End Class



