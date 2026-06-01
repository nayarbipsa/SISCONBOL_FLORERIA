Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Web.Script.Serialization

' ============================================================
' SISCONBOL - Pagina publica del cliente (link unificado)
' Archivo: cliente/index.aspx.vb
'
' Validacion:
'   - SIN sesion de usuario (publico)
'   - Se valida por token_web (vigente, no expirado)
'   - Marca token_abierto_en la primera vez
'
' QueryString: ?t=GUID32
' ============================================================
Partial Public Class Cliente_Index
    Inherits System.Web.UI.Page

    ' --- Pagina states ---
    Public Property Estado As String = "OK"   ' OK | INVALIDO | EXPIRADO | CONFIRMADO

    ' --- Datos del PrePedido ---
    Public Property PrePedidoId As Integer = 0
    Public Property Token As String = ""
    Public Property Codigo As String = ""
    Public Property ClienteNombre As String = ""
    Public Property ClienteApellidos As String = ""
    Public Property ClienteEmail As String = ""
    Public Property ClienteCelular As String = ""
    Public Property TasaCambio As Decimal = 7.0
    Public Property MetodoPagoCliente As String = ""

    ' --- Tiempo restante ---
    Public Property TokenExpira As DateTime = DateTime.MinValue
    Public Property HorasRestantes As Integer = 24
    Public Property MinutosRestantes As Integer = 0

    ' --- Agente (para boton WhatsApp comprobante) ---
    Public Property CelularAgenteLimpio As String = ""
    Public Property NombreAgente As String = ""

    ' --- Entregas (HTML) ---
    Public Property CantidadEntregas As Integer = 0
    Public Property HtmlEntregas As String = ""

    ' --- Totales agregados (suma de TODAS las entregas en borrador) ---
    Public Property TotalGeneralBs As Decimal = 0
    Public Property TotalGeneralUsd As Decimal = 0

    ' --- DEBUG: capturar mensaje real de excepción para diagnóstico ---
    Public Property ErrorDebug As String = ""

    ' ============================================================
    ' Page_Load (publico, sin VerificarSesion)
    ' ============================================================
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If IsPostBack Then Return

        ' --- 1. Validar token (acepta ?t=token o, como fallback, ?c=CODIGO) ---
        Dim t As String = Request.QueryString("t")
        If t Is Nothing Then t = ""
        t = t.Trim()

        ' Entrada por link corto ?c=PRE-000123: resuelve a token_web (lo asegura
        ' si falta o expiro). Asi la misma pagina sirve si se entra con el codigo.
        If t = "" Then
            Dim c As String = Request.QueryString("c")
            If c IsNot Nothing AndAlso c.Trim() <> "" Then
                Dim info As PrePedidoLink.Info = PrePedidoLink.AsegurarTokenPorCodigo(c, 0)
                If info.Encontrado AndAlso info.Token <> "" Then t = info.Token
            End If
        End If

        If t = "" OrElse t.Length < 16 Then
            Estado = "INVALIDO"
            Return
        End If
        Token = t

        ' --- 2. Buscar pre-pedido por token ---
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                Dim sql As String = "SELECT p.prepedido_id, p.codigo, " &
                    "p.cliente_nombre, p.cliente_apellidos, p.cliente_celular, p.cliente_email, " &
                    "p.tasa_cambio, p.metodo_pago_cliente, " &
                    "p.token_expira, p.token_abierto_en, p.token_confirmado_por_cliente_en, " &
                    "p.agente_actual_id, " &
                    "u.nombres + ' ' + u.apellidos AS agente_nombre, u.celular AS agente_celular " &
                    "FROM FLORERIA_PrePedido p " &
                    "LEFT JOIN FLORERIA_Usuario u ON p.agente_actual_id = u.usuario_id " &
                    "WHERE p.token_web = @t"

                Dim confirmadoEn As DateTime = DateTime.MinValue
                Dim primerAbierto As Boolean = False

                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@t", t)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If Not dr.Read() Then
                            Estado = "INVALIDO"
                            Return
                        End If

                        PrePedidoId = CInt(dr("prepedido_id"))
                        Codigo = dr("codigo").ToString()
                        ClienteNombre = If(IsDBNull(dr("cliente_nombre")), "", dr("cliente_nombre").ToString())
                        ClienteApellidos = If(IsDBNull(dr("cliente_apellidos")), "", dr("cliente_apellidos").ToString())
                        ClienteEmail = If(IsDBNull(dr("cliente_email")), "", dr("cliente_email").ToString())
                        ClienteCelular = If(IsDBNull(dr("cliente_celular")), "", dr("cliente_celular").ToString())
                        If Not IsDBNull(dr("tasa_cambio")) Then TasaCambio = CDec(dr("tasa_cambio"))
                        MetodoPagoCliente = If(IsDBNull(dr("metodo_pago_cliente")), "", dr("metodo_pago_cliente").ToString())

                        If Not IsDBNull(dr("token_expira")) Then TokenExpira = CDate(dr("token_expira"))
                        If Not IsDBNull(dr("token_confirmado_por_cliente_en")) Then confirmadoEn = CDate(dr("token_confirmado_por_cliente_en"))
                        primerAbierto = IsDBNull(dr("token_abierto_en"))

                        NombreAgente = If(IsDBNull(dr("agente_nombre")), "Agente Miss Flores", dr("agente_nombre").ToString())

                        ' Limpiar celular del agente para wa.me
                        Dim agCel As String = If(IsDBNull(dr("agente_celular")), "", dr("agente_celular").ToString())
                        For Each c As Char In agCel
                            If Char.IsDigit(c) Then CelularAgenteLimpio &= c
                        Next
                        If CelularAgenteLimpio.Length = 8 AndAlso (CelularAgenteLimpio.StartsWith("6") OrElse CelularAgenteLimpio.StartsWith("7")) Then
                            CelularAgenteLimpio = "591" & CelularAgenteLimpio
                        End If
                    End Using
                End Using

                ' --- 3. Verificar estado del token ---
                If confirmadoEn > DateTime.MinValue Then
                    Estado = "CONFIRMADO"
                    Return
                End If

                If TokenExpira <= DateTime.Now Then
                    Estado = "EXPIRADO"
                    Return
                End If

                ' Calcular tiempo restante
                Dim diff As TimeSpan = TokenExpira.Subtract(DateTime.Now)
                HorasRestantes = CInt(Math.Floor(diff.TotalHours))
                MinutosRestantes = diff.Minutes

                ' --- 4. Si es primer abierto, marcarlo ---
                If primerAbierto Then
                    Using cmdUpd As New SqlCommand(
                        "UPDATE FLORERIA_PrePedido SET token_abierto_en = GETDATE() " &
                        "WHERE prepedido_id = @id AND token_abierto_en IS NULL", conn)
                        cmdUpd.Parameters.AddWithValue("@id", PrePedidoId)
                        cmdUpd.ExecuteNonQuery()
                    End Using
                End If

                ' --- 5. Cargar entregas borrador y totales ---
                CargarEntregas(conn)
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR cliente/index Page_Load: " & ex.Message)
            Estado = "INVALIDO"
            ' DEBUG TEMPORAL: capturar mensaje + stack para diagnóstico
            ErrorDebug = ex.GetType().Name & ": " & ex.Message
            If ex.InnerException IsNot Nothing Then
                ErrorDebug &= " | INNER: " & ex.InnerException.Message
            End If
            ErrorDebug &= " | STACK: " & ex.StackTrace
        End Try
    End Sub

    ' ============================================================
    ' CargarEntregas - lista las entregas BORRADOR del pre-pedido
    '
    ' FIX MARS: ANTES se llamaba a ObtenerHtmlProductos(conn, eId) DENTRO del
    ' While dr.Read() principal. Eso abre un segundo DataReader sobre la misma
    ' conexion y SQL Server tira:
    '   "There is already an open DataReader associated with this Command"
    '
    ' Solucion: precargamos TODOS los productos en un Dictionary antes de
    ' empezar el reader principal, y dentro del bucle solo consultamos el dict.
    ' ============================================================
    Private Sub CargarEntregas(conn As SqlConnection)
        ' --- 0. Precargar productos de TODAS las entregas BORRADOR de este prepedido ---
        Dim productosPorEntrega As New System.Collections.Generic.Dictionary(Of Integer, String)
        Dim sqlProds As String = "SELECT d.prepedido_entrega_id, d.nombre_producto, d.cantidad, d.subtotal_bs " & _
            "FROM FLORERIA_PrePedido_Entrega_Detalle d " & _
            "INNER JOIN FLORERIA_PrePedido_Entrega e ON d.prepedido_entrega_id = e.prepedido_entrega_id " & _
            "WHERE e.prepedido_id = @id AND e.estado = 'BORRADOR' " & _
            "ORDER BY d.prepedido_entrega_id, d.detalle_id"

        Using cmdP As New SqlCommand(sqlProds, conn)
            cmdP.Parameters.AddWithValue("@id", PrePedidoId)
            Using drP As SqlDataReader = cmdP.ExecuteReader()
                While drP.Read()
                    Dim eid As Integer = CInt(drP("prepedido_entrega_id"))
                    Dim nombre As String = drP("nombre_producto").ToString()
                    Dim cant As Integer = CInt(drP("cantidad"))
                    Dim sub_ As Decimal = CDec(drP("subtotal_bs"))
                    Dim cantTxt As String = If(cant > 1, " x" & cant, "")
                    Dim linea As String = "      <div class='res-line'><span>" & HE(nombre) & cantTxt & "</span><span>Bs " & sub_.ToString("N2") & "</span></div>" & vbCrLf

                    If productosPorEntrega.ContainsKey(eid) Then
                        productosPorEntrega(eid) = productosPorEntrega(eid) & linea
                    Else
                        productosPorEntrega(eid) = linea
                    End If
                End While
            End Using
        End Using

        ' --- 1. Ahora si: consulta principal de entregas ---
        Dim sb As New System.Text.StringBuilder()
        Dim sql As String = "SELECT e.prepedido_entrega_id, e.receptor_nombre, e.receptor_celular, " &
            "e.tipo_entrega, e.direccion, e.referencia, e.gps, e.fecha_entrega, " &
            "e.dedicatoria, e.firma_tarjeta, e.tipo_ocacion, e.es_express, " &
            "e.descuento_valor, e.descuento_moneda, " &
            "c.nombre AS ciudad_nombre, z.nombre AS zona_nombre, " &
            "s.etiqueta AS slot_etiqueta, s.recargo_bs AS slot_recargo_bs, " &
            "ISNULL((SELECT SUM(subtotal_bs) FROM FLORERIA_PrePedido_Entrega_Detalle d " &
            "        WHERE d.prepedido_entrega_id = e.prepedido_entrega_id), 0) AS prod_bs, " &
            "ISNULL((SELECT TOP 1 zt.precio_bs FROM FLORERIA_Zona_Tarifa zt " &
            "        WHERE zt.zona_id = e.zona_id ORDER BY zt.vigente_desde DESC), 0) AS envio_bs " &
            "FROM FLORERIA_PrePedido_Entrega e " &
            "LEFT JOIN FLORERIA_Ciudad c ON e.ciudad_id = c.ciudad_id " &
            "LEFT JOIN FLORERIA_Zona z ON e.zona_id = z.zona_id " &
            "LEFT JOIN FLORERIA_Slot_Horario s ON e.slot_id = s.slot_id " &
            "WHERE e.prepedido_id = @id AND e.estado = 'BORRADOR' " &
            "ORDER BY e.prepedido_entrega_id"

        Using cmd As New SqlCommand(sql, conn)
            cmd.Parameters.AddWithValue("@id", PrePedidoId)
            Using dr As SqlDataReader = cmd.ExecuteReader()
                Dim n As Integer = 0
                While dr.Read()
                    n += 1
                    Dim eId As Integer = CInt(dr("prepedido_entrega_id"))
                    Dim receptor As String = If(IsDBNull(dr("receptor_nombre")), "", dr("receptor_nombre").ToString())
                    Dim celReceptor As String = If(IsDBNull(dr("receptor_celular")), "", dr("receptor_celular").ToString())
                    Dim direccion As String = If(IsDBNull(dr("direccion")), "", dr("direccion").ToString())
                    Dim referencia As String = If(IsDBNull(dr("referencia")), "", dr("referencia").ToString())
                    Dim gps As String = If(IsDBNull(dr("gps")), "", dr("gps").ToString())
                    Dim dedicatoria As String = If(IsDBNull(dr("dedicatoria")), "", dr("dedicatoria").ToString())
                    Dim firma As String = If(IsDBNull(dr("firma_tarjeta")), "", dr("firma_tarjeta").ToString())
                    Dim ocasion As String = If(IsDBNull(dr("tipo_ocacion")), "", dr("tipo_ocacion").ToString())
                    Dim ciudad As String = If(IsDBNull(dr("ciudad_nombre")), "", dr("ciudad_nombre").ToString())
                    Dim zona As String = If(IsDBNull(dr("zona_nombre")), "", dr("zona_nombre").ToString())
                    Dim slot As String = If(IsDBNull(dr("slot_etiqueta")), "", dr("slot_etiqueta").ToString())
                    Dim recargoSlot As Decimal = If(IsDBNull(dr("slot_recargo_bs")), 0, CDec(dr("slot_recargo_bs")))
                    Dim esExpress As Boolean = If(IsDBNull(dr("es_express")), False, CBool(dr("es_express")))
                    Dim recargoExpress As Decimal = If(esExpress, 50D, 0D)
                    Dim descuento As Decimal = If(IsDBNull(dr("descuento_valor")), 0, CDec(dr("descuento_valor")))
                    Dim prodBs As Decimal = CDec(dr("prod_bs"))
                    Dim envioBs As Decimal = CDec(dr("envio_bs"))

                    Dim fechaTxt As String = "Sin fecha"
                    If Not IsDBNull(dr("fecha_entrega")) Then
                        fechaTxt = CDate(dr("fecha_entrega")).ToString("dd MMM yyyy")
                    End If

                    Dim totalEntrega As Decimal = prodBs + envioBs + recargoSlot + recargoExpress - descuento
                    TotalGeneralBs += totalEntrega

                    ' Productos detalle - se obtienen del Dictionary precargado (NO se abre nuevo reader)
                    Dim htmlProds As String = ""
                    If productosPorEntrega.ContainsKey(eId) Then
                        htmlProds = productosPorEntrega(eId)
                    End If

                    ' Construir tarjeta
                    sb.AppendLine("<div class='entrega-card' data-entrega-id='" & eId & "'>")
                    sb.AppendLine("  <div class='entrega-header' onclick='toggleEntrega(" & eId & ")'>")
                    sb.AppendLine("    <div class='entrega-resumen'>")
                    sb.AppendLine("      <p class='entrega-titulo'>Entrega " & n & " &middot; " & HE(If(receptor = "", "Sin destinatario", receptor)) & "</p>")
                    sb.AppendLine("      <p class='entrega-sub'>" & HE(fechaTxt) & " &middot; " & HE(If(slot = "", "Sin horario", slot)) & " &middot; Bs " & totalEntrega.ToString("N2") & "</p>")
                    sb.AppendLine("    </div>")
                    sb.AppendLine("    <span class='entrega-badge' id='badge-" & eId & "'>PENDIENTE</span>")
                    sb.AppendLine("    <i class='ti ti-chevron-down chev' id='chev-" & eId & "'></i>")
                    sb.AppendLine("  </div>")

                    sb.AppendLine("  <div class='entrega-body' id='body-" & eId & "' style='display:none'>")

                    ' Resumen de productos
                    sb.AppendLine("    <div class='resumen-box'>")
                    sb.AppendLine(htmlProds)
                    sb.AppendLine("      <div class='res-line muted'><span>Subtotal</span><span>Bs " & prodBs.ToString("N2") & "</span></div>")
                    If envioBs > 0 Then sb.AppendLine("      <div class='res-line muted'><span>Envio (" & HE(zona) & ")</span><span>Bs " & envioBs.ToString("N2") & "</span></div>")
                    If recargoSlot > 0 Then sb.AppendLine("      <div class='res-line warn'><span><i class='ti ti-clock-bolt'></i> Recargo horario</span><span>+Bs " & recargoSlot.ToString("N2") & "</span></div>")
                    If recargoExpress > 0 Then sb.AppendLine("      <div class='res-line warn'><span><i class='ti ti-bolt'></i> Entrega express</span><span>+Bs " & recargoExpress.ToString("N2") & "</span></div>")
                    If descuento > 0 Then sb.AppendLine("      <div class='res-line ok'><span><i class='ti ti-tag'></i> Descuento</span><span>-Bs " & descuento.ToString("N2") & "</span></div>")
                    sb.AppendLine("      <div class='res-line total'><span>Total</span><span>Bs " & totalEntrega.ToString("N2") & "</span></div>")
                    sb.AppendLine("    </div>")

                    ' DESTINATARIO
                    sb.AppendLine("    <p class='section-lbl'>DESTINATARIO</p>")
                    sb.AppendLine("    <label class='inp-lbl'>Nombre de quien recibe *</label>")
                    sb.AppendLine("    <input type='text' class='inp' value='" & HE(receptor) & "' data-eid='" & eId & "' data-campo='receptor_nombre' onblur='guardarCampoEntrega(this)' required>")
                    sb.AppendLine("    <label class='inp-lbl'>Celular de quien recibe *</label>")
                    sb.AppendLine("    <input type='text' class='inp' value='" & HE(celReceptor) & "' data-eid='" & eId & "' data-campo='receptor_celular' onblur='guardarCampoEntrega(this)' required>")

                    ' DIRECCION
                    sb.AppendLine("    <p class='section-lbl'>DIRECCION</p>")
                    sb.AppendLine("    <label class='inp-lbl'>Zona</label>")
                    sb.AppendLine("    <input type='text' class='inp readonly' value='" & HE(zona) & "' readonly>")
                    sb.AppendLine("    <label class='inp-lbl'>Calle, numero, dpto *</label>")
                    sb.AppendLine("    <input type='text' class='inp' value='" & HE(direccion) & "' data-eid='" & eId & "' data-campo='direccion' onblur='guardarCampoEntrega(this)' required>")
                    sb.AppendLine("    <label class='inp-lbl'>Referencia</label>")
                    sb.AppendLine("    <input type='text' class='inp' value='" & HE(referencia) & "' placeholder='Frente al parque...' data-eid='" & eId & "' data-campo='referencia' onblur='guardarCampoEntrega(this)'>")
                    sb.AppendLine("    <label class='inp-lbl'>Ubicacion GPS (link de Google Maps)</label>")
                    sb.AppendLine("    <input type='text' class='inp' value='" & HE(gps) & "' placeholder='https://maps.google.com/...' data-eid='" & eId & "' data-campo='gps' onblur='guardarCampoEntrega(this)'>")

                    ' FECHA Y HORA (bloqueado)
                    sb.AppendLine("    <p class='section-lbl'>FECHA Y HORA</p>")
                    sb.AppendLine("    <div class='inp-grid'>")
                    sb.AppendLine("      <input type='text' class='inp readonly' value='" & HE(fechaTxt) & "' readonly>")
                    sb.AppendLine("      <input type='text' class='inp readonly' value='" & HE(If(slot = "", "Sin horario", slot)) & "' readonly>")
                    sb.AppendLine("    </div>")

                    ' DEDICATORIA
                    sb.AppendLine("    <p class='section-lbl'>DEDICATORIA</p>")
                    sb.AppendLine("    <label class='inp-lbl'>Ocasion</label>")
                    sb.AppendLine("    <select class='inp' data-eid='" & eId & "' data-campo='tipo_ocacion' onchange='guardarCampoEntrega(this)'>")
                    sb.AppendLine("      <option value=''>-- Seleccionar --</option>")
                    For Each opt As String In New String() {"CUMPLEANOS", "ANIVERSARIO", "SAN_VALENTIN", "DIA_MADRE", "DIA_PADRE", "GRADUACION", "CONDOLENCIAS", "OTRO"}
                        Dim selectedAttr As String = If(ocasion = opt, " selected", "")
                        sb.AppendLine("      <option value='" & opt & "'" & selectedAttr & ">" & TraducirOcasion(opt) & "</option>")
                    Next
                    sb.AppendLine("    </select>")
                    sb.AppendLine("    <label class='inp-lbl'>Mensaje</label>")
                    sb.AppendLine("    <textarea class='inp' rows='2' placeholder='Feliz cumpleanos...' data-eid='" & eId & "' data-campo='dedicatoria' onblur='guardarCampoEntrega(this)'>" & HE(dedicatoria) & "</textarea>")
                    sb.AppendLine("    <label class='inp-lbl'>Firma (de quien es)</label>")
                    sb.AppendLine("    <input type='text' class='inp' value='" & HE(firma) & "' data-eid='" & eId & "' data-campo='firma_tarjeta' onblur='guardarCampoEntrega(this)'>")

                    sb.AppendLine("  </div>")
                    sb.AppendLine("</div>")
                End While
                CantidadEntregas = n
            End Using
        End Using

        HtmlEntregas = sb.ToString()
    End Sub

    ' ============================================================
    ' Productos de una entrega (helper)
    ' ============================================================
    Private Function ObtenerHtmlProductos(conn As SqlConnection, entregaId As Integer) As String
        Dim sb As New System.Text.StringBuilder()
        Using cmd As New SqlCommand(
            "SELECT nombre_producto, cantidad, subtotal_bs FROM FLORERIA_PrePedido_Entrega_Detalle " &
            "WHERE prepedido_entrega_id = @id", conn)
            cmd.Parameters.AddWithValue("@id", entregaId)
            Using dr As SqlDataReader = cmd.ExecuteReader()
                While dr.Read()
                    Dim nombre As String = dr("nombre_producto").ToString()
                    Dim cant As Integer = CInt(dr("cantidad"))
                    Dim sub_ As Decimal = CDec(dr("subtotal_bs"))
                    Dim cantTxt As String = If(cant > 1, " x" & cant, "")
                    sb.AppendLine("      <div class='res-line'><span>" & HE(nombre) & cantTxt & "</span><span>Bs " & sub_.ToString("N2") & "</span></div>")
                End While
            End Using
        End Using
        Return sb.ToString()
    End Function

    ' Helpers
    Private Function HE(s As String) As String
        If s Is Nothing Then Return ""
        Return Server.HtmlEncode(s)
    End Function

    Private Function TraducirOcasion(codigo As String) As String
        Select Case codigo
            Case "CUMPLEANOS" : Return "Cumpleanos"
            Case "ANIVERSARIO" : Return "Aniversario"
            Case "SAN_VALENTIN" : Return "San Valentin"
            Case "DIA_MADRE" : Return "Dia de la Madre"
            Case "DIA_PADRE" : Return "Dia del Padre"
            Case "GRADUACION" : Return "Graduacion"
            Case "CONDOLENCIAS" : Return "Condolencias"
            Case "OTRO" : Return "Otro"
            Case Else : Return codigo
        End Select
    End Function

End Class
