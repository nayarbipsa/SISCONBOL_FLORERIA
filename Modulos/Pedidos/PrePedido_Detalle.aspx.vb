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
    Public Property ClienteNombreSolo As String = ""
    Public Property ClienteApellidos As String = ""
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
            ' --- Ramas AJAX ---
            Dim esAjax As Boolean = (Request.Headers("X-Requested-With") = "XMLHttpRequest")
            Dim accion As String = If(Request.Form("accion"), "")
            If esAjax AndAlso accion = "ACTUALIZAR_NOMBRE_CLIENTE" Then
                ActualizarNombreCliente() : Return
            End If
            If esAjax AndAlso accion = "GENERAR_COTIZACION" Then
                GenerarCotizacion() : Return
            End If

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
    ' AJAX — Actualizar nombre y apellidos del cliente
    ' ============================================================
    Private Sub ActualizarNombreCliente()
        Response.ContentType = "application/json"
        Response.Charset = "utf-8"
        Dim ppId As Integer = 0
        Integer.TryParse(Request.Form("prepedido_id"), ppId)
        Dim nuevoNombre As String = If(Request.Form("nombre"), "").Trim()
        Dim nuevoApellidos As String = If(Request.Form("apellidos"), "").Trim()
        If ppId <= 0 OrElse nuevoNombre = "" Then
            Response.Write("{""ok"":false,""msg"":""Falta el ID o el nombre""}") : Return
        End If
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Dim emailActual As Object = DBNull.Value
                Dim paisIdActual As Object = DBNull.Value
                Dim ciudadIdActual As Object = DBNull.Value
                Using cmdGet As New SqlCommand("SELECT cliente_email, cliente_pais_id, cliente_ciudad_id FROM FLORERIA_PrePedido WHERE prepedido_id = @id", conn)
                    cmdGet.Parameters.AddWithValue("@id", ppId)
                    Using dr As SqlDataReader = cmdGet.ExecuteReader()
                        If dr.Read() Then
                            If Not IsDBNull(dr("cliente_email"))     Then emailActual    = dr("cliente_email")
                            If Not IsDBNull(dr("cliente_pais_id"))   Then paisIdActual   = dr("cliente_pais_id")
                            If Not IsDBNull(dr("cliente_ciudad_id")) Then ciudadIdActual = dr("cliente_ciudad_id")
                        Else
                            Response.Write("{""ok"":false,""msg"":""Pre-pedido no encontrado""}") : Return
                        End If
                    End Using
                End Using
                Using cmd As New SqlCommand("FLORERIA_sp_PrePedido_ActualizarCliente", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@prepedido_id",      ppId)
                    cmd.Parameters.AddWithValue("@cliente_nombre",    nuevoNombre)
                    cmd.Parameters.AddWithValue("@cliente_apellidos", If(nuevoApellidos = "", DBNull.Value, CObj(nuevoApellidos)))
                    cmd.Parameters.AddWithValue("@cliente_email",     emailActual)
                    cmd.Parameters.AddWithValue("@cliente_pais_id",   paisIdActual)
                    cmd.Parameters.AddWithValue("@cliente_ciudad_id", ciudadIdActual)
                    cmd.Parameters.AddWithValue("@modificado_por",    SesionHelper.ObtenerUsuarioId(HttpContext.Current))
                    cmd.Parameters.AddWithValue("@ip",                If(Request.UserHostAddress, ""))
                    cmd.ExecuteNonQuery()
                End Using
                Dim nomCompleto As String = nuevoNombre & If(nuevoApellidos <> "", " " & nuevoApellidos, "")
                Response.Write("{""ok"":true,""nombre_completo"":""" & nomCompleto.Replace("""", "\""") & """}")
            End Using
        Catch ex As SqlException
            Response.Write("{""ok"":false,""msg"":""" & ex.Message.Replace("""", "'").Replace(vbCrLf, " ") & """}")
        Catch ex As Exception
            Response.Write("{""ok"":false,""msg"":""Error inesperado""}")
        End Try
    End Sub

    ' ============================================================
    ' AJAX — Generar cotización WhatsApp (borradores + confirmados)
    ' ============================================================
    Private Sub GenerarCotizacion()
        Response.ContentType = "application/json"
        Response.Charset = "utf-8"
        Dim ppId As Integer = 0
        Integer.TryParse(Request.Form("prepedido_id"), ppId)
        If ppId <= 0 Then
            Response.Write("{""ok"":false,""msg"":""Pre-pedido invalido""}") : Return
        End If
        Try
            Dim sb As New System.Text.StringBuilder()
            Dim sumProds As Decimal = 0D
            Dim sumEnvios As Decimal = 0D
            Dim sumRecargos As Decimal = 0D
            Dim sumDesc As Decimal = 0D
            Dim sumTotal As Decimal = 0D
            Dim contEntregas As Integer = 0

            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                ' Nombre del cliente (solo primer nombre)
                Dim nombreCliente As String = ""
                Using cmdC As New SqlCommand("SELECT cliente_nombre FROM FLORERIA_PrePedido WHERE prepedido_id = @id", conn)
                    cmdC.Parameters.AddWithValue("@id", ppId)
                    Dim r = cmdC.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then
                        Dim nom As String = r.ToString().Trim()
                        Dim idx As Integer = nom.IndexOf(" ")
                        nombreCliente = If(idx > 0, nom.Substring(0, idx), nom)
                    End If
                End Using

                sb.AppendLine(If(nombreCliente <> "", "Hola " & nombreCliente & "! 🌸", "Hola! 🌸"))
                sb.AppendLine("Te paso la cotización de Miss Flores:")
                sb.AppendLine("")

                ' ---- Pedidos confirmados ----
                Dim sqlConf As String =
                    "SELECT p.receptor_nombre, p.receptor_celular, p.fecha_entrega, " &
                    "       p.subtotal_productos_bs, p.envio_bs, " &
                    "       p.recargo_express_bs, p.recargo_horario_bs, " &
                    "       p.descuento_bs, p.total_bs, " &
                    "       z.nombre AS zona_nombre, sh.hora_inicio, sh.hora_fin " &
                    "FROM   FLORERIA_Pedido p " &
                    "LEFT JOIN FLORERIA_Zona         z  ON p.zona_id = z.zona_id " &
                    "LEFT JOIN FLORERIA_Slot_Horario sh ON p.slot_id = sh.slot_id " &
                    "WHERE  p.prepedido_id = @id ORDER BY p.pedido_id"

                Using cmd As New SqlCommand(sqlConf, conn)
                    cmd.Parameters.AddWithValue("@id", ppId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            contEntregas += 1
                            Dim rec As String = If(IsDBNull(dr("receptor_nombre")), "", dr("receptor_nombre").ToString())
                            Dim cel As String = If(IsDBNull(dr("receptor_celular")), "", dr("receptor_celular").ToString())
                            Dim fStr As String = ""
                            If Not IsDBNull(dr("fecha_entrega")) Then fStr = CDate(dr("fecha_entrega")).ToString("dd MMM")
                            Dim hi As String = If(IsDBNull(dr("hora_inicio")), "", dr("hora_inicio").ToString())
                            Dim hf As String = If(IsDBNull(dr("hora_fin")), "", dr("hora_fin").ToString())
                            If hi.Length >= 5 Then hi = hi.Substring(0, 5)
                            If hf.Length >= 5 Then hf = hf.Substring(0, 5)
                            Dim zona As String = If(IsDBNull(dr("zona_nombre")), "", dr("zona_nombre").ToString())
                            Dim subP As Decimal = If(IsDBNull(dr("subtotal_productos_bs")), 0D, CDec(dr("subtotal_productos_bs")))
                            Dim env As Decimal = If(IsDBNull(dr("envio_bs")), 0D, CDec(dr("envio_bs")))
                            Dim rExp As Decimal = If(IsDBNull(dr("recargo_express_bs")), 0D, CDec(dr("recargo_express_bs")))
                            Dim rHor As Decimal = If(IsDBNull(dr("recargo_horario_bs")), 0D, CDec(dr("recargo_horario_bs")))
                            Dim desc As Decimal = If(IsDBNull(dr("descuento_bs")), 0D, CDec(dr("descuento_bs")))
                            Dim tot As Decimal = If(IsDBNull(dr("total_bs")), 0D, CDec(dr("total_bs")))

                            sb.AppendLine("📦 *Entrega " & contEntregas & "*")
                            If rec <> "" Then sb.AppendLine("• Para: " & rec & If(cel <> "", " (" & cel & ")", ""))
                            If fStr <> "" Then sb.AppendLine("• Fecha: " & fStr & If(hi <> "" AndAlso hf <> "", " · " & hi & " a " & hf, ""))
                            If zona <> "" Then sb.AppendLine("• Zona: " & zona)
                            If subP > 0 Then sb.AppendLine("• Productos: " & subP.ToString("N2") & " Bs")
                            If env > 0 Then sb.AppendLine("• Envío: " & env.ToString("N2") & " Bs")
                            If rExp > 0 Then sb.AppendLine("• Recargo express: +" & rExp.ToString("N2") & " Bs")
                            If rHor > 0 Then sb.AppendLine("• Recargo horario: +" & rHor.ToString("N2") & " Bs")
                            If desc > 0 Then sb.AppendLine("• Descuento: -" & desc.ToString("N2") & " Bs")
                            sb.AppendLine("• *Subtotal: " & tot.ToString("N2") & " Bs*")
                            sb.AppendLine("")
                            sumProds += subP : sumEnvios += env
                            sumRecargos += rExp + rHor : sumDesc += desc : sumTotal += tot
                        End While
                    End Using
                End Using

                ' ---- Borradores (sin pedido_id aún) ----
                Dim sqlBor As String =
                    "SELECT e.receptor_nombre, e.receptor_celular, e.fecha_entrega, " &
                    "       e.descuento_valor, " &
                    "       ISNULL((SELECT SUM(d.subtotal_bs) FROM FLORERIA_PrePedido_Entrega_Detalle d WHERE d.prepedido_entrega_id = e.prepedido_entrega_id),0) AS subtotal_bs, " &
                    "       ISNULL((SELECT COUNT(*) FROM FLORERIA_PrePedido_Entrega_Detalle d WHERE d.prepedido_entrega_id = e.prepedido_entrega_id),0) AS cant_items, " &
                    "       z.nombre AS zona_nombre, sh.hora_inicio, sh.hora_fin " &
                    "FROM   FLORERIA_PrePedido_Entrega e " &
                    "LEFT JOIN FLORERIA_Zona         z  ON e.zona_id = z.zona_id " &
                    "LEFT JOIN FLORERIA_Slot_Horario sh ON e.slot_id = sh.slot_id " &
                    "WHERE  e.prepedido_id = @id AND e.estado = 'BORRADOR' AND e.pedido_id IS NULL " &
                    "ORDER BY e.prepedido_entrega_id"

                Using cmd As New SqlCommand(sqlBor, conn)
                    cmd.Parameters.AddWithValue("@id", ppId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim cantIt As Integer = CInt(dr("cant_items"))
                            If cantIt = 0 Then Continue While  ' sin productos, skip
                            contEntregas += 1
                            Dim rec As String = If(IsDBNull(dr("receptor_nombre")), "", dr("receptor_nombre").ToString())
                            Dim cel As String = If(IsDBNull(dr("receptor_celular")), "", dr("receptor_celular").ToString())
                            Dim fStr As String = ""
                            If Not IsDBNull(dr("fecha_entrega")) Then fStr = CDate(dr("fecha_entrega")).ToString("dd MMM")
                            Dim hi As String = If(IsDBNull(dr("hora_inicio")), "", dr("hora_inicio").ToString())
                            Dim hf As String = If(IsDBNull(dr("hora_fin")), "", dr("hora_fin").ToString())
                            If hi.Length >= 5 Then hi = hi.Substring(0, 5)
                            If hf.Length >= 5 Then hf = hf.Substring(0, 5)
                            Dim zona As String = If(IsDBNull(dr("zona_nombre")), "", dr("zona_nombre").ToString())
                            Dim subP As Decimal = CDec(dr("subtotal_bs"))
                            Dim desc As Decimal = If(IsDBNull(dr("descuento_valor")), 0D, CDec(dr("descuento_valor")))
                            Dim tot As Decimal = subP - desc

                            sb.AppendLine("📦 *Entrega " & contEntregas & "* _(referencial)_")
                            If rec <> "" Then sb.AppendLine("• Para: " & rec & If(cel <> "", " (" & cel & ")", ""))
                            If fStr <> "" Then sb.AppendLine("• Fecha: " & fStr & If(hi <> "" AndAlso hf <> "", " · " & hi & " a " & hf, ""))
                            If zona <> "" Then sb.AppendLine("• Zona: " & zona)
                            If subP > 0 Then sb.AppendLine("• Productos: " & subP.ToString("N2") & " Bs")
                            If desc > 0 Then sb.AppendLine("• Descuento: -" & desc.ToString("N2") & " Bs")
                            sb.AppendLine("• *Subtotal: " & tot.ToString("N2") & " Bs*")
                            sb.AppendLine("  _(sin envío ni recargos aún)_")
                            sb.AppendLine("")
                            sumProds += subP : sumDesc += desc : sumTotal += tot
                        End While
                    End Using
                End Using
            End Using

            If contEntregas = 0 Then
                Response.Write("{""ok"":false,""msg"":""No hay entregas con productos para cotizar""}") : Return
            End If

            sb.AppendLine("━━━━━━━━━━━━━━━━━")
            If contEntregas > 1 Then
                sb.AppendLine("Productos: " & sumProds.ToString("N2") & " Bs")
                If sumEnvios > 0 Then sb.AppendLine("Envíos: " & sumEnvios.ToString("N2") & " Bs")
                If sumRecargos > 0 Then sb.AppendLine("Recargos: +" & sumRecargos.ToString("N2") & " Bs")
                If sumDesc > 0 Then sb.AppendLine("Descuentos: -" & sumDesc.ToString("N2") & " Bs")
            End If
            sb.AppendLine("*TOTAL GENERAL: " & sumTotal.ToString("N2") & " Bs*")
            sb.AppendLine("")
            sb.AppendLine("Cualquier consulta avísanos 💐")

            Dim msg As String = sb.ToString()
            Dim msgJson As String = msg.Replace("\", "\\").Replace("""", "\""").
                                        Replace(vbCrLf, "\n").Replace(vbLf, "\n").
                                        Replace(vbCr, "\n").Replace(vbTab, "\t")
            Response.Write("{""ok"":true,""mensaje"":""" & msgJson & """}")

        Catch ex As Exception
            Response.Write("{""ok"":false,""msg"":""" & ex.Message.Replace("""", "'").Replace(vbCrLf, " ") & """}")
        End Try
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
                            
                            ' Guardar separados para edición inline
                            ClienteNombreSolo = nombre.Trim()
                            ClienteApellidos  = apellidos.Trim()
                            
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
            "ped.fecha_entrega, ped.direccion, ped.tipo_entrega, ped.es_express, " &
            "ped.subtotal_productos_bs, ped.envio_bs, ped.total_bs, " &
            "ped.wc_order_id, ped.wc_order_number, " &
            "c.nombre AS ciudad_nombre, " &
            "z.nombre AS zona_nombre, " &
            "s.hora_inicio, s.hora_fin, " &
            "(SELECT COUNT(*) FROM FLORERIA_Pedido_Detalle pd WHERE pd.pedido_id = ped.pedido_id) AS cant_productos " &
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
                    
                    ' Express y cantidad de productos
                    Dim esExpress As Boolean = Not IsDBNull(dr("es_express")) AndAlso CBool(dr("es_express"))
                    Dim cantProductos As Integer = If(IsDBNull(dr("cant_productos")), 0, CInt(dr("cant_productos")))
                    
                    ' ============================================================
                    ' CARD COMPACTA DE PEDIDO CONFIRMADO
                    ' Toda la card es clickeable hacia Pedido_Detalle.aspx
                    ' El menú "Acciones" maneja su propio click (stopPropagation)
                    ' ============================================================
                    
                    ' Horario compacto (sin segundos)
                    Dim horarioCompacto As String = horario
                    If horarioCompacto.Length >= 13 Then
                        Dim partes() As String = horarioCompacto.Split("-"c)
                        If partes.Length = 2 Then
                            horarioCompacto = partes(0).Trim().Substring(0, Math.Min(5, partes(0).Trim().Length)) & "-" & partes(1).Trim().Substring(0, Math.Min(5, partes(1).Trim().Length))
                        End If
                    End If
                    
                    ' Fecha corta (dd MMM)
                    Dim fechaCorta As String = ""
                    If Not IsDBNull(dr("fecha_entrega")) Then
                        fechaCorta = CDate(dr("fecha_entrega")).ToString("dd MMM")
                    End If
                    
                    sb.AppendLine("<div class='card-compact card-ped' onclick=""window.location='Pedido_Detalle.aspx?id=" & pedidoId & "'"">")
                    
                    ' --- LÍNEA 1: número + código + tag + botón Acciones ---
                    sb.AppendLine("  <div class='cc-row1'>")
                    sb.AppendLine("    <div class='cc-num cc-num-conf'>" & numPedido & "</div>")
                    sb.AppendLine("    <span class='cc-cod'>" & pedidoCodigo & "</span>")
                    sb.AppendLine("    <span class='cc-tag cc-tag-conf'><i class='ti ti-check'></i> CONFIRMADO</span>")
                    
                    ' Botón Acciones con menú desplegable
                    sb.AppendLine("    <div class='menu-wrap' style='position:relative;margin-left:auto' onclick='event.stopPropagation()'>")
                    sb.AppendLine("      <button type='button' class='btn-acciones-menu cc-menu-btn' onclick='toggleMenuPedido(this, event)'>")
                    sb.AppendLine("        Acciones <i class='ti ti-chevron-down'></i>")
                    sb.AppendLine("      </button>")
                    sb.AppendLine("      <div class='menu-dropdown-pedido' data-pedido-id='" & pedidoId & "' style='display:none;position:absolute;top:calc(100% + 4px);right:0;background:#fff;border:1px solid #e0e0e0;border-radius:8px;box-shadow:0 4px 12px rgba(0,0,0,.12);min-width:210px;overflow:hidden;z-index:10'>")
                    sb.AppendLine("        <a href='Pedido_Detalle.aspx?id=" & pedidoId & "' style='display:flex;align-items:center;gap:8px;padding:10px 14px;font-size:12px;text-decoration:none;color:#212121;border-bottom:1px solid #f5f5f5'>")
                    sb.AppendLine("          <i class='ti ti-eye' style='font-size:15px;width:18px;color:#7F77DD'></i>")
                    sb.AppendLine("          <div>Ir al pedido<span style='display:block;font-size:10px;color:#9e9e9e;margin-top:1px'>Ver detalle completo</span></div>")
                    sb.AppendLine("        </a>")
                    sb.AppendLine("        <a href='Recibo.aspx?id=" & pedidoId & "' target='_blank' style='display:flex;align-items:center;gap:8px;padding:10px 14px;font-size:12px;text-decoration:none;color:#212121;border-bottom:1px solid #f5f5f5'>")
                    sb.AppendLine("          <i class='ti ti-printer' style='font-size:15px;width:18px;color:#3B5BDB'></i>")
                    sb.AppendLine("          <div>Imprimir recibo<span style='display:block;font-size:10px;color:#9e9e9e;margin-top:1px'>Ticket térmico 80mm</span></div>")
                    sb.AppendLine("        </a>")
                    If wcOrderId > 0 Then
                        Dim wcUrl As String = "https://miss-flores.com/wp-admin/post.php?post=" & wcOrderId & "&action=edit"
                        sb.AppendLine("        <a href='" & wcUrl & "' target='_blank' style='display:flex;align-items:center;gap:8px;padding:10px 14px;font-size:12px;text-decoration:none;color:#212121'>")
                        sb.AppendLine("          <i class='ti ti-brand-woocommerce' style='font-size:15px;width:18px;color:#6A1B9A'></i>")
                        sb.AppendLine("          <div>Ver en WooCommerce<span style='display:block;font-size:10px;color:#9e9e9e;margin-top:1px'>#" & wcOrderId & "</span></div>")
                        sb.AppendLine("        </a>")
                    Else
                        sb.AppendLine("        <button type='button' onclick='sincronizarConWC(" & pedidoId & ", this); cerrarMenusPedido();' style='display:flex;align-items:center;gap:8px;padding:10px 14px;font-size:12px;background:none;border:none;cursor:pointer;width:100%;text-align:left;color:#212121'>")
                        sb.AppendLine("          <i class='ti ti-brand-woocommerce' style='font-size:15px;width:18px;color:#E65100'></i>")
                        sb.AppendLine("          <div>Crear en WooCommerce<span style='display:block;font-size:10px;color:#9e9e9e;margin-top:1px'>Sincronizar este pedido</span></div>")
                        sb.AppendLine("        </button>")
                    End If
                    sb.AppendLine("      </div>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("  </div>") ' fin cc-row1
                    
                    ' --- LÍNEA 2: receptor + celular ---
                    sb.AppendLine("  <div class='cc-row2'>")
                    sb.AppendLine("    <span class='cc-nom'>" & receptor & "</span>")
                    If celReceptor <> "" Then
                        sb.AppendLine("    <span class='cc-meta'><i class='ti ti-device-mobile'></i> " & celReceptor & "</span>")
                    End If
                    sb.AppendLine("  </div>")
                    
                    ' --- LÍNEA 3: info izquierda + total derecha ---
                    sb.AppendLine("  <div class='cc-row3'>")
                    sb.AppendLine("    <div class='cc-info'>")
                    If fechaCorta <> "" Then
                        sb.AppendLine("      <span class='cc-info-item'><i class='ti ti-calendar'></i> " & fechaCorta & " · " & horarioCompacto & "</span>")
                    End If
                    sb.AppendLine("      <span class='cc-info-item'><i class='ti ti-map-pin'></i> " & zona & "</span>")
                    If esExpress Then
                        sb.AppendLine("      <span class='cc-pill-exp'>Express</span>")
                    End If
                    If wcOrderId > 0 Then
                        sb.AppendLine("      <span class='cc-info-item' style='color:#6A1B9A'><i class='ti ti-brand-woocommerce'></i> #" & wcOrderId & "</span>")
                    Else
                        sb.AppendLine("      <span class='cc-info-item' style='color:#E65100'><i class='ti ti-brand-woocommerce'></i> Sin WC</span>")
                    End If
                    sb.AppendLine("    </div>")
                    sb.AppendLine("    <div class='cc-total-wrap'>")
                    sb.AppendLine("      <div class='cc-total'>" & total.ToString("N2") & " Bs</div>")
                    sb.AppendLine("      <span class='cc-total-sub'>" & cantProductos & " prod · env " & costoEnvio.ToString("N0") & "</span>")
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

                    ' ============================================================
                    ' CARD COMPACTA DE BORRADOR (entrega en proceso)
                    ' Toda la card es clickeable → Entrega_Agregar para seguir editando
                    ' ============================================================
                    
                    ' Fecha corta
                    Dim fechaCortaB As String = ""
                    If Not IsDBNull(dr("fecha_entrega")) Then
                        fechaCortaB = CDate(dr("fecha_entrega")).ToString("dd MMM")
                    End If
                    
                    ' Horario compacto
                    Dim horarioCompactoB As String = ""
                    If Not IsDBNull(dr("hora_inicio")) AndAlso Not IsDBNull(dr("hora_fin")) Then
                        Dim hi As String = dr("hora_inicio").ToString()
                        Dim hf As String = dr("hora_fin").ToString()
                        If hi.Length >= 5 Then hi = hi.Substring(0, 5)
                        If hf.Length >= 5 Then hf = hf.Substring(0, 5)
                        horarioCompactoB = hi & "-" & hf
                    End If
                    
                    Dim urlEditar As String = "Entrega_Agregar.aspx?prepedido=" & PrePedidoId & "&entrega=" & entId
                    
                    sb.AppendLine("<div class='card-compact card-bor' onclick=""window.location='" & urlEditar & "'"">")
                    
                    ' --- LÍNEA 1: número + código + tag ---
                    sb.AppendLine("  <div class='cc-row1'>")
                    sb.AppendLine("    <div class='cc-num cc-num-draft'>" & cant & "</div>")
                    sb.AppendLine("    <span class='cc-cod' style='color:#FB923C'>Borrador #" & entId & "</span>")
                    sb.AppendLine("    <span class='cc-tag cc-tag-draft'><i class='ti ti-pencil'></i> EN PROCESO</span>")
                    sb.AppendLine("  </div>")
                    
                    ' --- LÍNEA 2: receptor + celular ---
                    sb.AppendLine("  <div class='cc-row2'>")
                    If receptor = "" Then
                        sb.AppendLine("    <span class='cc-nom' style='color:#bdbdbd;font-style:italic'>Sin destinatario</span>")
                    Else
                        sb.AppendLine("    <span class='cc-nom'>" & receptor & "</span>")
                        If celReceptor <> "" Then
                            sb.AppendLine("    <span class='cc-meta'><i class='ti ti-device-mobile'></i> " & celReceptor & "</span>")
                        End If
                    End If
                    sb.AppendLine("  </div>")
                    
                    ' --- LÍNEA 3: info izquierda + total derecha ---
                    sb.AppendLine("  <div class='cc-row3'>")
                    sb.AppendLine("    <div class='cc-info'>")
                    If fechaCortaB <> "" OrElse horarioCompactoB <> "" Then
                        Dim fechaHor As String = fechaCortaB
                        If horarioCompactoB <> "" Then
                            If fechaHor <> "" Then fechaHor &= " · "
                            fechaHor &= horarioCompactoB
                        End If
                        sb.AppendLine("      <span class='cc-info-item'><i class='ti ti-calendar'></i> " & fechaHor & "</span>")
                    Else
                        sb.AppendLine("      <span class='cc-info-item' style='color:#bdbdbd;font-style:italic'>Sin fecha</span>")
                    End If
                    If Not IsDBNull(dr("zona_nombre")) Then
                        sb.AppendLine("      <span class='cc-info-item'><i class='ti ti-map-pin'></i> " & zona & "</span>")
                    End If
                    sb.AppendLine("    </div>")
                    sb.AppendLine("    <div class='cc-total-wrap'>")
                    Dim claseTotal As String = If(subtotalBs > 0, "cc-total", "cc-total cc-total-empty")
                    sb.AppendLine("      <div class='" & claseTotal & "'>" & subtotalBs.ToString("N0") & " Bs</div>")
                    sb.AppendLine("      <span class='cc-total-sub'>" & cantItems & " producto" & If(cantItems = 1, "", "s") & "</span>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("  </div>")
                    
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



