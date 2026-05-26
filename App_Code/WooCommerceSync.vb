Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Net
Imports System.Text
Imports System.Web.Script.Serialization

Public Class WooCommerceSync

    ' ============================================
    ' CONFIGURACIÓN
    ' ============================================

    Private Shared Function ObtenerConfig(clave As String) As String
        Try
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()
                Using cmd As New SqlCommand("SELECT valor FROM FLORERIA_Config WHERE clave=@c AND activo=1", conn)
                    cmd.Parameters.AddWithValue("@c", clave)
                    Dim val As Object = cmd.ExecuteScalar()
                    If val IsNot Nothing Then Return val.ToString()
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ObtenerConfig: " & ex.Message)
        End Try
        Return ""
    End Function

    Private Shared Function CrearRequest(metodo As String, endpoint As String) As HttpWebRequest
        Dim wcUrl As String = ObtenerConfig("WC_URL")
        Dim wcKey As String = ObtenerConfig("WC_CONSUMER_KEY")
        Dim wcSecret As String = ObtenerConfig("WC_CONSUMER_SECRET")

        Dim url As String = wcUrl & "/wp-json/wc/v3" & endpoint
        Dim request As HttpWebRequest = CType(WebRequest.Create(url), HttpWebRequest)
        request.Method = metodo
        request.ContentType = "application/json"

        ' Basic Auth
        Dim credentials As String = wcKey & ":" & wcSecret
        Dim credBytes() As Byte = Encoding.UTF8.GetBytes(credentials)
        Dim credBase64 As String = Convert.ToBase64String(credBytes)
        request.Headers.Add("Authorization", "Basic " & credBase64)

        Return request
    End Function

    Private Shared Function EscaparJson(texto As String) As String
        If texto Is Nothing Then Return ""
        Return texto.Replace("\", "\\").Replace("""", "\""").Replace(vbCr, "").Replace(vbLf, "\n").Replace(vbTab, " ")
    End Function

    ' ============================================
    ' SINCRONIZAR PRODUCTO
    ' ============================================

    Public Shared Function SincronizarProducto(productoId As Integer) As Dictionary(Of String, Object)
        Dim resultado As New Dictionary(Of String, Object)
        resultado("ok") = False
        resultado("mensaje") = ""
        resultado("wc_product_id") = 0

        Try
            Dim syncActivo As String = ObtenerConfig("SYNC_ACTIVO")
            If syncActivo <> "1" Then
                resultado("mensaje") = "Sincronización desactivada en configuración"
                Return resultado
            End If

            ' Obtener datos del producto
            Dim producto As Dictionary(Of String, Object) = ObtenerProducto(productoId)
            If producto Is Nothing Then
                resultado("mensaje") = "Producto no encontrado"
                Return resultado
            End If

            ' Construir JSON para WooCommerce
            Dim wcData As String = ConstruirJsonProducto(producto)

            ' Determinar si es CREATE o UPDATE
            Dim wcProductId As Integer = If(producto.ContainsKey("wc_product_id"), CInt(producto("wc_product_id")), 0)
            Dim metodo As String = If(wcProductId > 0, "PUT", "POST")
            Dim endpoint As String = "/products"
            If wcProductId > 0 Then endpoint &= "/" & wcProductId

            ' Crear request
            Dim request As HttpWebRequest = CrearRequest(metodo, endpoint)

            ' Enviar datos
            Using sw As New StreamWriter(request.GetRequestStream())
                sw.Write(wcData)
            End Using

            ' Leer respuesta
            Using response As HttpWebResponse = CType(request.GetResponse(), HttpWebResponse)
                Using sr As New StreamReader(response.GetResponseStream())
                    Dim respuesta As String = sr.ReadToEnd()

                    Dim serializer As New JavaScriptSerializer()
                    Dim wcRespuesta As Dictionary(Of String, Object) = serializer.Deserialize(Of Dictionary(Of String, Object))(respuesta)

                    If wcRespuesta.ContainsKey("id") Then
                        wcProductId = CInt(wcRespuesta("id"))
                        ActualizarEstadoSyncProducto(productoId, wcProductId, "SINCRONIZADO", "")
                        resultado("ok") = True
                        resultado("mensaje") = "Producto sincronizado correctamente"
                        resultado("wc_product_id") = wcProductId
                    Else
                        resultado("mensaje") = "Respuesta WC sin ID"
                    End If
                End Using
            End Using

        Catch ex As WebException
            Dim errorMsg As String = ex.Message
            Try
                Using sr As New StreamReader(ex.Response.GetResponseStream())
                    errorMsg = sr.ReadToEnd()
                End Using
            Catch
            End Try
            ActualizarEstadoSyncProducto(productoId, 0, "ERROR", errorMsg)
            resultado("mensaje") = "Error WC: " & errorMsg.Substring(0, Math.Min(100, errorMsg.Length))

        Catch ex As Exception
            ActualizarEstadoSyncProducto(productoId, 0, "ERROR", ex.Message)
            resultado("mensaje") = "Error: " & ex.Message
        End Try

        Return resultado
    End Function

    Private Shared Function ObtenerProducto(productoId As Integer) As Dictionary(Of String, Object)
        Try
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Producto_ObtenerPorId", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@producto_id", productoId)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Dim p As New Dictionary(Of String, Object)()
                            p("producto_id") = dr("producto_id")
                            p("nombre") = dr("nombre").ToString()
                            p("descripcion") = If(IsDBNull(dr("descripcion")), "", dr("descripcion").ToString())
                            p("precio_base_bs") = CDec(dr("precio_base_bs"))
                            p("precio_promo_bs") = If(IsDBNull(dr("precio_promo_bs")), 0D, CDec(dr("precio_promo_bs")))
                            p("promo_desde") = If(IsDBNull(dr("promo_desde")), Nothing, dr("promo_desde"))
                            p("promo_hasta") = If(IsDBNull(dr("promo_hasta")), Nothing, dr("promo_hasta"))
                            p("activo") = CBool(dr("activo"))
                            p("imagen_url") = If(IsDBNull(dr("imagen_url")), "", dr("imagen_url").ToString())
                            p("wc_product_id") = If(IsDBNull(dr("wc_product_id")), 0, CInt(dr("wc_product_id")))
                            Return p
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ObtenerProducto: " & ex.Message)
        End Try
        Return Nothing
    End Function

    Private Shared Function ConstruirJsonProducto(producto As Dictionary(Of String, Object)) As String
        Dim sb As New StringBuilder()
        sb.Append("{")

        sb.Append("""name"":""" & EscaparJson(producto("nombre").ToString()) & """,")
        sb.Append("""description"":""" & EscaparJson(producto("descripcion").ToString()) & """,")

        Dim precioBase As Decimal = CDec(producto("precio_base_bs"))
        Dim precioPromo As Decimal = CDec(producto("precio_promo_bs"))
        Dim promoDesde As Object = producto("promo_desde")
        Dim promoHasta As Object = producto("promo_hasta")

        Dim promoActiva As Boolean = False
        If precioPromo > 0 AndAlso promoDesde IsNot Nothing AndAlso promoHasta IsNot Nothing Then
            Dim hoy As Date = Date.Today
            Dim desde As Date = CDate(promoDesde)
            Dim hasta As Date = CDate(promoHasta)
            If hoy >= desde AndAlso hoy <= hasta Then promoActiva = True
        End If

        If promoActiva Then
            sb.Append("""regular_price"":""" & precioBase.ToString("F2") & """,")
            sb.Append("""sale_price"":""" & precioPromo.ToString("F2") & """,")
        Else
            sb.Append("""regular_price"":""" & precioBase.ToString("F2") & """,")
        End If

        Dim estado As String = If(CBool(producto("activo")), "publish", "draft")
        sb.Append("""status"":""" & estado & """,")

        Dim imagenUrl As String = producto("imagen_url").ToString()
        If imagenUrl <> "" Then
            If Not imagenUrl.StartsWith("http") Then
                Dim baseUrl As String = ObtenerConfig("WC_URL")
                imagenUrl = baseUrl & imagenUrl
            End If
            sb.Append("""images"":[{""src"":""" & imagenUrl & """}],")
        End If

        If sb.Length > 1 AndAlso sb(sb.Length - 1) = ","c Then sb.Length -= 1
        sb.Append("}")
        Return sb.ToString()
    End Function

    Private Shared Sub ActualizarEstadoSyncProducto(productoId As Integer, wcProductId As Integer, estado As String, errorMsg As String)
        Try
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()
                Dim sql As String = "UPDATE FLORERIA_Producto SET wc_sync_estado=@estado, wc_sync_fecha=GETDATE()"
                If wcProductId > 0 Then sql &= ", wc_product_id=@wcid"
                sql &= " WHERE producto_id=@pid"

                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@estado", estado)
                    cmd.Parameters.AddWithValue("@pid", productoId)
                    If wcProductId > 0 Then cmd.Parameters.AddWithValue("@wcid", wcProductId)
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ActualizarEstadoSyncProducto: " & ex.Message)
        End Try
    End Sub

    ' ============================================
    ' SINCRONIZAR CATEGORÍA
    ' ============================================

    Public Shared Function SincronizarCategoria(categoriaId As Integer) As Dictionary(Of String, Object)
        Dim resultado As New Dictionary(Of String, Object)
        resultado("ok") = False
        resultado("mensaje") = ""
        resultado("wc_category_id") = 0

        Try
            Dim syncActivo As String = ObtenerConfig("SYNC_ACTIVO")
            If syncActivo <> "1" Then
                resultado("mensaje") = "Sincronización desactivada"
                Return resultado
            End If

            Dim categoria As Dictionary(Of String, Object) = ObtenerCategoria(categoriaId)
            If categoria Is Nothing Then
                resultado("mensaje") = "Categoría no encontrada"
                Return resultado
            End If

            Dim wcData As String = ConstruirJsonCategoria(categoria)
            Dim wcCategoryId As Integer = If(categoria.ContainsKey("wc_category_id"), CInt(categoria("wc_category_id")), 0)
            Dim metodo As String = If(wcCategoryId > 0, "PUT", "POST")
            Dim endpoint As String = "/products/categories"
            If wcCategoryId > 0 Then endpoint &= "/" & wcCategoryId

            Dim request As HttpWebRequest = CrearRequest(metodo, endpoint)
            Using sw As New StreamWriter(request.GetRequestStream())
                sw.Write(wcData)
            End Using

            Using response As HttpWebResponse = CType(request.GetResponse(), HttpWebResponse)
                Using sr As New StreamReader(response.GetResponseStream())
                    Dim respuesta As String = sr.ReadToEnd()
                    Dim serializer As New JavaScriptSerializer()
                    Dim wcRespuesta As Dictionary(Of String, Object) = serializer.Deserialize(Of Dictionary(Of String, Object))(respuesta)

                    If wcRespuesta.ContainsKey("id") Then
                        wcCategoryId = CInt(wcRespuesta("id"))
                        ActualizarEstadoSyncCategoria(categoriaId, wcCategoryId, "SINCRONIZADO", "")
                        resultado("ok") = True
                        resultado("mensaje") = "Categoría sincronizada"
                        resultado("wc_category_id") = wcCategoryId
                    End If
                End Using
            End Using

        Catch ex As WebException
            Dim errorMsg As String = ex.Message
            Try
                Using sr As New StreamReader(ex.Response.GetResponseStream())
                    errorMsg = sr.ReadToEnd()
                End Using
            Catch
            End Try
            ActualizarEstadoSyncCategoria(categoriaId, 0, "ERROR", errorMsg)
            resultado("mensaje") = "Error: " & errorMsg.Substring(0, Math.Min(100, errorMsg.Length))

        Catch ex As Exception
            ActualizarEstadoSyncCategoria(categoriaId, 0, "ERROR", ex.Message)
            resultado("mensaje") = "Error: " & ex.Message
        End Try

        Return resultado
    End Function

    Private Shared Function ObtenerCategoria(categoriaId As Integer) As Dictionary(Of String, Object)
        Try
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()
                Using cmd As New SqlCommand("SELECT * FROM FLORERIA_Categoria WHERE categoria_id=@id", conn)
                    cmd.Parameters.AddWithValue("@id", categoriaId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Dim c As New Dictionary(Of String, Object)()
                            c("categoria_id") = dr("categoria_id")
                            c("nombre") = dr("nombre").ToString()
                            c("descripcion") = If(IsDBNull(dr("descripcion")), "", dr("descripcion").ToString())
                            c("slug") = dr("slug").ToString()
                            c("padre_id") = If(IsDBNull(dr("padre_id")), 0, CInt(dr("padre_id")))
                            c("wc_category_id") = If(IsDBNull(dr("wc_category_id")), 0, CInt(dr("wc_category_id")))
                            Return c
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ObtenerCategoria: " & ex.Message)
        End Try
        Return Nothing
    End Function

    Private Shared Function ConstruirJsonCategoria(categoria As Dictionary(Of String, Object)) As String
        Dim sb As New StringBuilder()
        sb.Append("{")
        sb.Append("""name"":""" & EscaparJson(categoria("nombre").ToString()) & """,")
        sb.Append("""description"":""" & EscaparJson(categoria("descripcion").ToString()) & """,")
        sb.Append("""slug"":""" & categoria("slug").ToString() & """,")

        Dim padreId As Integer = CInt(categoria("padre_id"))
        If padreId > 0 Then
            Dim wcPadreId As Integer = ObtenerWcCategoryId(padreId)
            If wcPadreId > 0 Then
                sb.Append("""parent"":" & wcPadreId & ",")
            End If
        End If

        If sb.Length > 1 AndAlso sb(sb.Length - 1) = ","c Then sb.Length -= 1
        sb.Append("}")
        Return sb.ToString()
    End Function

    Private Shared Function ObtenerWcCategoryId(categoriaId As Integer) As Integer
        Try
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()
                Using cmd As New SqlCommand("SELECT wc_category_id FROM FLORERIA_Categoria WHERE categoria_id=@id", conn)
                    cmd.Parameters.AddWithValue("@id", categoriaId)
                    Dim val As Object = cmd.ExecuteScalar()
                    If val IsNot Nothing AndAlso Not IsDBNull(val) Then Return CInt(val)
                End Using
            End Using
        Catch
        End Try
        Return 0
    End Function

    Private Shared Sub ActualizarEstadoSyncCategoria(categoriaId As Integer, wcCategoryId As Integer, estado As String, errorMsg As String)
        Try
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()
                Dim sql As String = "UPDATE FLORERIA_Categoria SET wc_sync_estado=@estado, wc_sync_fecha=GETDATE()"
                If wcCategoryId > 0 Then sql &= ", wc_category_id=@wcid"
                sql &= " WHERE categoria_id=@cid"

                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@estado", estado)
                    cmd.Parameters.AddWithValue("@cid", categoriaId)
                    If wcCategoryId > 0 Then cmd.Parameters.AddWithValue("@wcid", wcCategoryId)
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ActualizarEstadoSyncCategoria: " & ex.Message)
        End Try
    End Sub

    ' ============================================
    ' SINCRONIZAR PEDIDO (ORDEN)
    ' ============================================

    Public Shared Function SincronizarPedido(pedidoId As Integer) As Dictionary(Of String, Object)
        Dim resultado As New Dictionary(Of String, Object)
        resultado("ok") = False
        resultado("mensaje") = ""
        resultado("wc_order_id") = 0

        Try
            Dim syncActivo As String = ObtenerConfig("SYNC_ACTIVO")
            If syncActivo <> "1" Then
                resultado("mensaje") = "Sincronización desactivada"
                Return resultado
            End If

            Dim pedido As Dictionary(Of String, Object) = ObtenerPedido(pedidoId)
            If pedido Is Nothing Then
                resultado("mensaje") = "Pedido no encontrado"
                Return resultado
            End If

            Dim wcData As String = ConstruirJsonPedido(pedido)

            ' === FIX #4: LOG DEL PAYLOAD COMPLETO ===
            ' Antes de mandar, dejamos rastro de qué se está enviando.
            ' Útil cuando Woo devuelve errores: ya no hay que adivinar.
            System.Diagnostics.Debug.WriteLine("===========================================")
            System.Diagnostics.Debug.WriteLine("[WC_SYNC] Enviando pedido_id=" & pedidoId & " a WooCommerce")
            System.Diagnostics.Debug.WriteLine("[WC_SYNC] Payload (longitud=" & wcData.Length & "):")
            System.Diagnostics.Debug.WriteLine(wcData)
            System.Diagnostics.Debug.WriteLine("===========================================")

            Dim wcOrderId As Integer = If(pedido.ContainsKey("wc_order_id"), CInt(pedido("wc_order_id")), 0)
            Dim metodo As String = If(wcOrderId > 0, "PUT", "POST")
            Dim endpoint As String = "/orders"
            If wcOrderId > 0 Then endpoint &= "/" & wcOrderId

            Dim request As HttpWebRequest = CrearRequest(metodo, endpoint)
            Using sw As New StreamWriter(request.GetRequestStream())
                sw.Write(wcData)
            End Using

            Using response As HttpWebResponse = CType(request.GetResponse(), HttpWebResponse)
                Using sr As New StreamReader(response.GetResponseStream())
                    Dim respuesta As String = sr.ReadToEnd()
                    System.Diagnostics.Debug.WriteLine("[WC_SYNC] Respuesta WC: " & respuesta.Substring(0, Math.Min(500, respuesta.Length)))

                    Dim serializer As New JavaScriptSerializer()
                    Dim wcRespuesta As Dictionary(Of String, Object) = serializer.Deserialize(Of Dictionary(Of String, Object))(respuesta)

                    If wcRespuesta.ContainsKey("id") Then
                        wcOrderId = CInt(wcRespuesta("id"))
                        Dim orderNumber As String = If(wcRespuesta.ContainsKey("number"), wcRespuesta("number").ToString(), wcOrderId.ToString())
                        ActualizarEstadoSyncPedido(pedidoId, wcOrderId, orderNumber, "SINCRONIZADO", "")
                        resultado("ok") = True
                        resultado("mensaje") = "Pedido sincronizado"
                        resultado("wc_order_id") = wcOrderId
                    End If
                End Using
            End Using

        Catch ex As WebException
            ' === FIX #4: LOG DETALLADO DEL ERROR ===
            Dim errorMsg As String = ex.Message
            Try
                Using sr As New StreamReader(ex.Response.GetResponseStream())
                    errorMsg = sr.ReadToEnd()
                End Using
            Catch
            End Try
            System.Diagnostics.Debug.WriteLine("[WC_SYNC_ERROR] WebException pedido_id=" & pedidoId)
            System.Diagnostics.Debug.WriteLine("[WC_SYNC_ERROR] Mensaje: " & ex.Message)
            System.Diagnostics.Debug.WriteLine("[WC_SYNC_ERROR] Respuesta WC: " & errorMsg)
            ActualizarEstadoSyncPedido(pedidoId, 0, "", "ERROR", errorMsg)
            resultado("mensaje") = "Error: " & errorMsg.Substring(0, Math.Min(200, errorMsg.Length))

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("[WC_SYNC_ERROR] Exception pedido_id=" & pedidoId & ": " & ex.Message)
            ActualizarEstadoSyncPedido(pedidoId, 0, "", "ERROR", ex.Message)
            resultado("mensaje") = "Error: " & ex.Message
        End Try

        Return resultado
    End Function

    ' ============================================================
    ' ObtenerPedido - lee TODO lo necesario para armar JSON WooCommerce
    ' ============================================================
    Private Shared Function ObtenerPedido(pedidoId As Integer) As Dictionary(Of String, Object)
        Try
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()

                ' --- 1. Datos del pedido + prepedido + ciudad/zona/slot ---
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
                    "       p.tipo_entrega, p.wc_order_id, " &
                    "       c.nombre AS ciudad_nombre, " &
                    "       z.nombre AS zona_nombre, " &
                    "       sl.etiqueta AS slot_etiqueta, sl.wc_slot_value, " &
                    "       pp.cliente_nombre, pp.cliente_apellidos, " &
                    "       pp.cliente_email, pp.cliente_celular " &
                    "FROM FLORERIA_Pedido p " &
                    "LEFT JOIN FLORERIA_Ciudad c     ON c.ciudad_id = p.ciudad_id " &
                    "LEFT JOIN FLORERIA_Zona   z     ON z.zona_id   = p.zona_id " &
                    "LEFT JOIN FLORERIA_Slot_Horario sl ON sl.slot_id = p.slot_id " &
                    "LEFT JOIN FLORERIA_PrePedido    pp ON pp.prepedido_id = p.prepedido_id " &
                    "WHERE p.pedido_id = @id"

                Dim p As Dictionary(Of String, Object) = Nothing
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@id", pedidoId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            p = New Dictionary(Of String, Object)()
                            p("pedido_id") = CInt(dr("pedido_id"))
                            p("codigo") = dr("codigo").ToString()
                            p("prepedido_id") = If(IsDBNull(dr("prepedido_id")), 0, CInt(dr("prepedido_id")))
                            p("receptor_nombre") = dr("receptor_nombre").ToString()
                            p("receptor_celular") = dr("receptor_celular").ToString()
                            p("direccion") = If(IsDBNull(dr("direccion")), "", dr("direccion").ToString())
                            p("referencia") = If(IsDBNull(dr("referencia")), "", dr("referencia").ToString())
                            p("gps") = If(IsDBNull(dr("gps")), "", dr("gps").ToString())
                            p("fecha_entrega") = CDate(dr("fecha_entrega")).ToString("yyyy-MM-dd")
                            p("es_express") = CBool(dr("es_express"))
                            p("dedicatoria") = If(IsDBNull(dr("dedicatoria")), "", dr("dedicatoria").ToString())
                            p("firma_tarjeta") = If(IsDBNull(dr("firma_tarjeta")), "", dr("firma_tarjeta").ToString())
                            p("tipo_ocacion") = If(IsDBNull(dr("tipo_ocacion")), "", dr("tipo_ocacion").ToString())
                            p("nota_floreria") = If(IsDBNull(dr("nota_floreria")), "", dr("nota_floreria").ToString())
                            p("observaciones") = If(IsDBNull(dr("observaciones")), "", dr("observaciones").ToString())
                            p("subtotal_bs") = CDec(dr("subtotal_productos_bs"))
                            p("envio_bs") = CDec(dr("envio_bs"))
                            p("recargo_express_bs") = CDec(dr("recargo_express_bs"))
                            p("recargo_horario_bs") = CDec(dr("recargo_horario_bs"))
                            p("descuento_bs") = CDec(dr("descuento_bs"))
                            p("total_bs") = CDec(dr("total_bs"))
                            p("tipo_entrega") = dr("tipo_entrega").ToString()
                            p("wc_order_id") = If(IsDBNull(dr("wc_order_id")), 0, CInt(dr("wc_order_id")))
                            p("ciudad_nombre") = If(IsDBNull(dr("ciudad_nombre")), "", dr("ciudad_nombre").ToString())
                            p("zona_nombre") = If(IsDBNull(dr("zona_nombre")), "", dr("zona_nombre").ToString())
                            p("slot_etiqueta") = If(IsDBNull(dr("slot_etiqueta")), "", dr("slot_etiqueta").ToString())
                            p("wc_slot_value") = If(IsDBNull(dr("wc_slot_value")), "", dr("wc_slot_value").ToString())

                            Dim cn As String = If(IsDBNull(dr("cliente_nombre")), "", dr("cliente_nombre").ToString())
                            Dim ca As String = If(IsDBNull(dr("cliente_apellidos")), "", dr("cliente_apellidos").ToString())
                            p("cliente_nombre") = cn
                            p("cliente_apellidos") = ca
                            p("cliente_email") = If(IsDBNull(dr("cliente_email")), "", dr("cliente_email").ToString())
                            p("cliente_celular") = If(IsDBNull(dr("cliente_celular")), "", dr("cliente_celular").ToString())
                        End If
                    End Using
                End Using

                If p Is Nothing Then Return Nothing

                ' --- 2. Productos del pedido (lee wc_product_id) ---
                Dim items As New List(Of Dictionary(Of String, Object))
                Dim sqlItems As String =
                    "SELECT d.detalle_id, d.producto_id, d.es_personalizado, " &
                    "       d.nombre_producto, d.cantidad, " &
                    "       d.precio_unitario_bs, d.subtotal_bs, " &
                    "       d.personalizacion, " &
                    "       pr.wc_product_id " &
                    "FROM FLORERIA_Pedido_Detalle d " &
                    "LEFT JOIN FLORERIA_Producto pr ON pr.producto_id = d.producto_id " &
                    "WHERE d.pedido_id = @id"
                Using cmdI As New SqlCommand(sqlItems, conn)
                    cmdI.Parameters.AddWithValue("@id", pedidoId)
                    Using dr As SqlDataReader = cmdI.ExecuteReader()
                        While dr.Read()
                            Dim it As New Dictionary(Of String, Object)
                            it("detalle_id") = CInt(dr("detalle_id"))
                            it("es_personalizado") = CBool(dr("es_personalizado"))
                            it("nombre") = dr("nombre_producto").ToString()
                            it("cantidad") = CInt(dr("cantidad"))
                            it("precio_bs") = CDec(dr("precio_unitario_bs"))
                            it("subtotal_bs") = CDec(dr("subtotal_bs"))
                            it("personalizacion") = If(IsDBNull(dr("personalizacion")), "", dr("personalizacion").ToString())
                            it("wc_product_id") = If(IsDBNull(dr("wc_product_id")), 0, CInt(dr("wc_product_id")))
                            items.Add(it)
                        End While
                    End Using
                End Using
                p("items") = items

                ' --- 3. Metodo de pago: lee el ULTIMO pago verificado del prepedido ---
                Dim metodoPago As String = ""
                Dim ppId As Integer = CInt(p("prepedido_id"))
                If ppId > 0 Then
                    Dim sqlPago As String =
                        "SELECT TOP 1 metodo_pago " &
                        "FROM FLORERIA_PrePedido_Entrega_Pago pa " &
                        "INNER JOIN FLORERIA_PrePedido_Entrega e " &
                        "  ON e.prepedido_entrega_id = pa.prepedido_entrega_id " &
                        "WHERE e.prepedido_id = @pp AND pa.estado = 'VERIFICADO' " &
                        "ORDER BY pa.creado_en DESC"
                    Using cmdP As New SqlCommand(sqlPago, conn)
                        cmdP.Parameters.AddWithValue("@pp", ppId)
                        Dim r As Object = cmdP.ExecuteScalar()
                        If r IsNot Nothing AndAlso Not IsDBNull(r) Then
                            metodoPago = r.ToString()
                        End If
                    End Using
                End If
                If metodoPago = "" Then metodoPago = "EFECTIVO"
                p("metodo_pago_sisconbol") = metodoPago

                ' --- 4. Resolver mapeo a WC via SP ---
                Dim wcMethod As String = "bacs"
                Dim wcTitle As String = metodoPago
                Using cmdM As New SqlCommand("FLORERIA_sp_PagoMetodo_Map_Obtener", conn)
                    cmdM.CommandType = CommandType.StoredProcedure
                    cmdM.Parameters.AddWithValue("@codigo_sisconbol", metodoPago)
                    Using dr As SqlDataReader = cmdM.ExecuteReader()
                        If dr.Read() Then
                            wcMethod = dr("wc_payment_method").ToString()
                            wcTitle = dr("wc_payment_method_title").ToString()
                        End If
                    End Using
                End Using
                p("wc_payment_method") = wcMethod
                p("wc_payment_method_title") = wcTitle

                Return p
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ObtenerPedido: " & ex.Message)
        End Try
        Return Nothing
    End Function

    ' ============================================================
    ' ConstruirJsonPedido - JSON completo para WooCommerce
    '
    ' === CAMBIOS RESPECTO A LA VERSIÓN ANTERIOR ===
    '   FIX #1: billing.address_1 / city / state ahora se mandan
    '           (eran obligatorios y NO iban -> rest_invalid_param: billing)
    '   FIX #2: billing.email tiene fallback genérico si está vacío
    '           (Woo rechaza email vacío con muchas configs)
    '   FIX #3: billing.last_name tiene fallback "." si está vacío
    '           (en Bolivia muchos clientes solo dan un nombre)
    '   FIX #4: ConstruirJson() también es llamado con logging desde
    '           SincronizarPedido (ver arriba), pero acá además
    '           arreglamos el shipping_lines malformado.
    ' ============================================================
    Private Shared Function ConstruirJsonPedido(pedido As Dictionary(Of String, Object)) As String
        ' Constante: producto comodin para items personalizados
        Const WC_PRODUCTO_PERSONALIZADO As Integer = 7076

        Dim sb As New StringBuilder()
        sb.Append("{")

        ' --- Status + pagado ---
        sb.Append("""status"":""processing"",")
        sb.Append("""set_paid"":true,")
        sb.Append("""currency"":""BOB"",")

        ' --- Payment method ---
        Dim wcPm As String = pedido("wc_payment_method").ToString()
        Dim wcPmT As String = pedido("wc_payment_method_title").ToString()
        sb.Append("""payment_method"":""" & EscaparJson(wcPm) & """,")
        sb.Append("""payment_method_title"":""" & EscaparJson(wcPmT) & """,")

        ' --- Customer note ---
        Dim notaFlor As String = pedido("nota_floreria").ToString()
        Dim obs As String = pedido("observaciones").ToString()
        Dim notaFinal As String = ""
        If notaFlor <> "" Then notaFinal = notaFlor
        If obs <> "" Then
            If notaFinal <> "" Then notaFinal &= " | "
            notaFinal &= obs
        End If
        If notaFinal <> "" Then
            sb.Append("""customer_note"":""" & EscaparJson(notaFinal) & """,")
        End If

        ' ============================================================
        ' === BILLING (datos del cliente comprador) ===
        ' FIX #1, #2, #3: incluir address_1/city/state + fallbacks de email/last_name
        ' ============================================================
        Dim cn As String = pedido("cliente_nombre").ToString().Trim()
        Dim ca As String = pedido("cliente_apellidos").ToString().Trim()
        Dim email As String = pedido("cliente_email").ToString().Trim()
        Dim cel As String = pedido("cliente_celular").ToString().Trim()

        ' Fallback de nombre: si no hay cliente, usar el receptor
        If cn = "" Then cn = pedido("receptor_nombre").ToString().Trim()
        If cn = "" Then cn = "Cliente"
        ' Fallback de last_name: Woo requiere algo (mínimo "." es aceptable)
        If ca = "" Then ca = "."
        ' Fallback de email: Woo requiere email válido en muchas configs
        If email = "" Then email = "noreply@miss-flores.com"
        ' Fallback de teléfono: usar el del receptor si falta
        If cel = "" Then cel = pedido("receptor_celular").ToString().Trim()
        If cel = "" Then cel = "00000000"

        ' Para los campos de dirección del billing, copiamos del shipping
        ' (en pedidos físicos, billing address suele ser la misma que shipping)
        Dim dirBill As String = pedido("direccion").ToString().Trim()
        If dirBill = "" Then dirBill = "Sin dirección especificada"
        Dim ciudadBill As String = pedido("ciudad_nombre").ToString().Trim()
        If ciudadBill = "" Then ciudadBill = "La Paz"
        Dim zonaBill As String = pedido("zona_nombre").ToString().Trim()
        If zonaBill = "" Then zonaBill = ciudadBill

        sb.Append("""billing"":{")
        sb.Append("""first_name"":""" & EscaparJson(cn) & """,")
        sb.Append("""last_name"":""" & EscaparJson(ca) & """,")
        sb.Append("""email"":""" & EscaparJson(email) & """,")
        sb.Append("""phone"":""" & EscaparJson(cel) & """,")
        sb.Append("""address_1"":""" & EscaparJson(dirBill) & """,")       ' *** FIX #1 ***
        sb.Append("""city"":""" & EscaparJson(ciudadBill) & """,")         ' *** FIX #1 ***
        sb.Append("""state"":""" & EscaparJson(zonaBill) & """,")          ' *** FIX #1 ***
        sb.Append("""country"":""BO""")
        sb.Append("},")

        ' ============================================================
        ' === SHIPPING (a quién se le entrega) ===
        ' ============================================================
        Dim receptor As String = pedido("receptor_nombre").ToString().Trim()
        Dim rNom As String = receptor
        Dim rApe As String = "."
        Dim pos As Integer = receptor.IndexOf(" "c)
        If pos > 0 Then
            rNom = receptor.Substring(0, pos)
            rApe = receptor.Substring(pos + 1)
        End If
        If rNom = "" Then rNom = "Cliente"
        If rApe = "" Then rApe = "."

        Dim dirShip As String = pedido("direccion").ToString().Trim()
        If dirShip = "" Then dirShip = "Sin dirección especificada"
        Dim ciudadShip As String = pedido("ciudad_nombre").ToString().Trim()
        If ciudadShip = "" Then ciudadShip = "La Paz"
        Dim zonaShip As String = pedido("zona_nombre").ToString().Trim()
        If zonaShip = "" Then zonaShip = ciudadShip
        Dim refShip As String = pedido("referencia").ToString().Trim()

        sb.Append("""shipping"":{")
        sb.Append("""first_name"":""" & EscaparJson(rNom) & """,")
        sb.Append("""last_name"":""" & EscaparJson(rApe) & """,")
        sb.Append("""phone"":""" & EscaparJson(pedido("receptor_celular").ToString()) & """,")
        sb.Append("""address_1"":""" & EscaparJson(dirShip) & """,")
        sb.Append("""address_2"":""" & EscaparJson(refShip) & """,")
        sb.Append("""city"":""" & EscaparJson(ciudadShip) & """,")
        sb.Append("""state"":""" & EscaparJson(zonaShip) & """,")
        sb.Append("""country"":""BO""")
        sb.Append("},")

        ' ============================================================
        ' === LINE ITEMS ===
        ' ============================================================
        sb.Append("""line_items"":[")
        Dim items As List(Of Dictionary(Of String, Object)) = CType(pedido("items"), List(Of Dictionary(Of String, Object)))
        For i As Integer = 0 To items.Count - 1
            Dim it As Dictionary(Of String, Object) = items(i)
            If i > 0 Then sb.Append(",")

            Dim esPers As Boolean = CBool(it("es_personalizado"))
            Dim wcPid As Integer = CInt(it("wc_product_id"))
            If esPers OrElse wcPid <= 0 Then wcPid = WC_PRODUCTO_PERSONALIZADO

            Dim cant As Integer = CInt(it("cantidad"))
            Dim precio As Decimal = CDec(it("precio_bs"))
            Dim subtotal As Decimal = CDec(it("subtotal_bs"))

            sb.Append("{")
            sb.Append("""product_id"":" & wcPid & ",")
            sb.Append("""quantity"":" & cant & ",")
            sb.Append("""subtotal"":""" & subtotal.ToString("F2", System.Globalization.CultureInfo.InvariantCulture) & """,")
            sb.Append("""total"":""" & subtotal.ToString("F2", System.Globalization.CultureInfo.InvariantCulture) & """")

            ' Meta_data del item (personalizacion + nombre real si es comodin)
            Dim metaItem As New List(Of String)
            Dim pers As String = it("personalizacion").ToString()
            If pers <> "" Then
                metaItem.Add("{""key"":""personalizacion"",""value"":""" & EscaparJson(pers) & """}")
            End If
            If esPers Then
                ' Cuando se usa el producto comodin, mandar el nombre real del producto
                metaItem.Add("{""key"":""nombre_personalizado"",""value"":""" & EscaparJson(it("nombre").ToString()) & """}")
                metaItem.Add("{""key"":""precio_unitario_bs"",""value"":""" & precio.ToString("F2", System.Globalization.CultureInfo.InvariantCulture) & """}")
            End If
            If metaItem.Count > 0 Then
                sb.Append(",""meta_data"":[" & String.Join(",", metaItem) & "]")
            End If
            sb.Append("}")
        Next
        sb.Append("],")

        ' ============================================================
        ' === SHIPPING LINES ===
        ' (FIX #5: armado limpio sin manipulación de StringBuilder)
        ' ============================================================
        Dim envioBs As Decimal = CDec(pedido("envio_bs"))
        Dim tipoEnt As String = pedido("tipo_entrega").ToString()
        Dim methodId As String = "flat_rate"
        Dim methodTitle As String = "Envio a domicilio"
        If tipoEnt = "RECOJO_SUCURSAL" Then
            methodId = "local_pickup"
            methodTitle = "Recojo en sucursal"
        Else
            Dim zonaNom As String = pedido("zona_nombre").ToString().Trim()
            If zonaNom <> "" Then
                methodTitle = "Envio a domicilio (" & zonaNom & ")"
            End If
        End If
        sb.Append("""shipping_lines"":[{")
        sb.Append("""method_id"":""" & EscaparJson(methodId) & """,")
        sb.Append("""method_title"":""" & EscaparJson(methodTitle) & """,")
        sb.Append("""total"":""" & envioBs.ToString("F2", System.Globalization.CultureInfo.InvariantCulture) & """")
        sb.Append("}],")

        ' ============================================================
        ' === FEE LINES (recargos y descuento) ===
        ' ============================================================
        Dim fees As New List(Of String)
        Dim recHor As Decimal = CDec(pedido("recargo_horario_bs"))
        Dim recExp As Decimal = CDec(pedido("recargo_express_bs"))
        Dim descBs As Decimal = CDec(pedido("descuento_bs"))
        If recHor > 0 Then
            Dim nomFee As String = "Recargo horario"
            If pedido("slot_etiqueta").ToString() <> "" Then
                nomFee &= " (" & pedido("slot_etiqueta").ToString() & ")"
            End If
            fees.Add("{""name"":""" & EscaparJson(nomFee) & """,""total"":""" & recHor.ToString("F2", System.Globalization.CultureInfo.InvariantCulture) & """}")
        End If
        If recExp > 0 Then
            fees.Add("{""name"":""Recargo express"",""total"":""" & recExp.ToString("F2", System.Globalization.CultureInfo.InvariantCulture) & """}")
        End If
        If descBs > 0 Then
            ' En WC los descuentos van como fee con total negativo
            fees.Add("{""name"":""Descuento"",""total"":""-" & descBs.ToString("F2", System.Globalization.CultureInfo.InvariantCulture) & """}")
        End If
        sb.Append("""fee_lines"":[" & String.Join(",", fees) & "],")

        ' ============================================================
        ' === META_DATA del pedido ===
        ' ============================================================
        Dim meta As New List(Of String)
        meta.Add(MetaPair("delivery_date", pedido("fecha_entrega").ToString()))
        If pedido("wc_slot_value").ToString() <> "" Then
            meta.Add(MetaPair("delivery_time", pedido("wc_slot_value").ToString()))
        ElseIf pedido("slot_etiqueta").ToString() <> "" Then
            meta.Add(MetaPair("delivery_time", pedido("slot_etiqueta").ToString()))
        End If
        If pedido("dedicatoria").ToString() <> "" Then
            meta.Add(MetaPair("mensaje_tarjeta", pedido("dedicatoria").ToString()))
        End If
        If pedido("firma_tarjeta").ToString() <> "" Then
            meta.Add(MetaPair("firma_tarjeta", pedido("firma_tarjeta").ToString()))
        End If
        If pedido("tipo_ocacion").ToString() <> "" Then
            meta.Add(MetaPair("tipo_de_ocacion", pedido("tipo_ocacion").ToString()))
        End If
        If pedido("nota_floreria").ToString() <> "" Then
            meta.Add(MetaPair("nota_floreria", pedido("nota_floreria").ToString()))
        End If
        If pedido("gps").ToString() <> "" Then
            meta.Add(MetaPair("gps", pedido("gps").ToString()))
        End If
        If pedido("receptor_celular").ToString() <> "" Then
            meta.Add(MetaPair("TelefonoRecibe", pedido("receptor_celular").ToString()))
        End If
        ' Codigo interno SISCONBOL para trazabilidad
        meta.Add(MetaPair("sisconbol_codigo", pedido("codigo").ToString()))
        meta.Add(MetaPair("sisconbol_pedido_id", pedido("pedido_id").ToString()))

        sb.Append("""meta_data"":[" & String.Join(",", meta) & "]")

        sb.Append("}")
        Return sb.ToString()
    End Function

    ' Helper para construir cada par {key,value} del meta_data
    Private Shared Function MetaPair(clave As String, valor As String) As String
        Return "{""key"":""" & EscaparJson(clave) & """,""value"":""" & EscaparJson(valor) & """}"
    End Function

    ' (MapearEstadoPedido ya no se usa porque siempre mandamos "processing".
    '  Se conserva por compatibilidad con codigo viejo, pero queda inerte.)
    Private Shared Function MapearEstadoPedido(estadoPago As String) As String
        Return "processing"
    End Function

    Private Shared Sub ActualizarEstadoSyncPedido(pedidoId As Integer, wcOrderId As Integer, wcOrderNumber As String, estado As String, errorMsg As String)
        Try
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()
                Dim sql As String = "UPDATE FLORERIA_Pedido SET wc_sync_estado=@estado, wc_sync_fecha=GETDATE()"
                If wcOrderId > 0 Then sql &= ", wc_order_id=@wcid, wc_order_number=@wcnum"
                sql &= " WHERE pedido_id=@pid"

                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@estado", estado)
                    cmd.Parameters.AddWithValue("@pid", pedidoId)
                    If wcOrderId > 0 Then
                        cmd.Parameters.AddWithValue("@wcid", wcOrderId)
                        cmd.Parameters.AddWithValue("@wcnum", wcOrderNumber)
                    End If
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ActualizarEstadoSyncPedido: " & ex.Message)
        End Try
    End Sub

    ' ============================================
    ' WEBHOOK: RECIBIR ORDEN DESDE WOOCOMMERCE
    ' (Sin cambios - sigue igual que antes)
    ' ============================================

    Public Shared Function ProcesarOrdenWebhook(jsonData As String) As Dictionary(Of String, Object)
        Dim resultado As New Dictionary(Of String, Object)
        resultado("ok") = False
        resultado("mensaje") = ""
        resultado("pedido_id") = 0

        Try
            Dim serializer As New JavaScriptSerializer()
            serializer.MaxJsonLength = Integer.MaxValue
            Dim orden As Dictionary(Of String, Object) = serializer.Deserialize(Of Dictionary(Of String, Object))(jsonData)

            If Not orden.ContainsKey("id") Then
                resultado("mensaje") = "JSON sin campo 'id'"
                Return resultado
            End If

            Dim wcOrderId As Integer = CInt(orden("id"))
            Dim wcOrderNumber As String = If(orden.ContainsKey("number"), orden("number").ToString(), wcOrderId.ToString())
            Dim status As String = If(orden.ContainsKey("status"), orden("status").ToString(), "pending")
            Dim total As Decimal = 0D
            If orden.ContainsKey("total") Then
                Decimal.TryParse(orden("total").ToString(), total)
            End If

            Dim createdDate As String = If(orden.ContainsKey("date_created"), orden("date_created").ToString(), "")
            Dim customerNote As String = If(orden.ContainsKey("customer_note"), orden("customer_note").ToString(), "")

            System.Diagnostics.Debug.WriteLine($"[WEBHOOK] Procesando orden WC #{wcOrderId} (Number: {wcOrderNumber}) - Estado: {status} - Total: {total}")

            Dim billing As Dictionary(Of String, Object) = If(orden.ContainsKey("billing"),
                TryCast(orden("billing"), Dictionary(Of String, Object)),
                New Dictionary(Of String, Object))

            Dim nombreReceptor As String = ""
            Dim celular As String = ""
            Dim email As String = ""

            If billing.ContainsKey("first_name") Then nombreReceptor = billing("first_name").ToString().Trim()
            If billing.ContainsKey("last_name") Then
                Dim apellido As String = billing("last_name").ToString().Trim()
                If apellido <> "" Then nombreReceptor &= " " & apellido
            End If
            If billing.ContainsKey("phone") Then celular = billing("phone").ToString().Trim()
            If billing.ContainsKey("email") Then email = billing("email").ToString().Trim()

            If nombreReceptor = "" Then nombreReceptor = "Cliente Web"
            If celular = "" Then celular = "00000000"

            Dim shipping As Dictionary(Of String, Object) = If(orden.ContainsKey("shipping"),
                TryCast(orden("shipping"), Dictionary(Of String, Object)),
                New Dictionary(Of String, Object))

            Dim direccion As String = ""
            Dim ciudad As String = ""
            Dim estado As String = ""

            If shipping.ContainsKey("address_1") Then direccion = shipping("address_1").ToString().Trim()
            If shipping.ContainsKey("address_2") Then
                Dim dir2 As String = shipping("address_2").ToString().Trim()
                If dir2 <> "" Then direccion &= " " & dir2
            End If
            If shipping.ContainsKey("city") Then ciudad = shipping("city").ToString().Trim()
            If shipping.ContainsKey("state") Then estado = shipping("state").ToString().Trim()

            If direccion = "" Then direccion = "Sin dirección especificada"

            Dim lineItems As New List(Of Dictionary(Of String, Object))
            If orden.ContainsKey("line_items") Then
                Dim itemsArray As Object() = TryCast(orden("line_items"), Object())
                If itemsArray IsNot Nothing Then
                    For Each itemObj As Object In itemsArray
                        Dim item As Dictionary(Of String, Object) = TryCast(itemObj, Dictionary(Of String, Object))
                        If item IsNot Nothing Then lineItems.Add(item)
                    Next
                End If
            End If

            System.Diagnostics.Debug.WriteLine($"[WEBHOOK] Line items encontrados: {lineItems.Count}")

            Dim pedidoId As Integer = 0
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()

                Using cmd As New SqlCommand("SELECT pedido_id, wc_sync_estado FROM FLORERIA_Pedido WHERE wc_order_id=@wc", conn)
                    cmd.Parameters.AddWithValue("@wc", wcOrderId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            pedidoId = CInt(dr("pedido_id"))
                            Dim estadoSync As String = dr("wc_sync_estado").ToString()

                            If estadoSync = "SINCRONIZADO" OrElse estadoSync = "PENDIENTE" Then
                                System.Diagnostics.Debug.WriteLine($"[WEBHOOK_ANTI_LOOP] Orden WC #{wcOrderId} fue CREADA por SISCONBOL - Webhook IGNORADO para evitar duplicado")
                                resultado("ok") = True
                                resultado("pedido_id") = pedidoId
                                resultado("mensaje") = "Webhook ignorado - orden sincronizada desde SISCONBOL (anti-loop)"
                                Return resultado
                            End If

                            System.Diagnostics.Debug.WriteLine($"[WEBHOOK] Pedido ID {pedidoId} existe con estado {estadoSync} - se actualizará")
                        End If
                    End Using
                End Using

                If pedidoId = 0 Then
                    System.Diagnostics.Debug.WriteLine("[WEBHOOK] Creando NUEVO pedido")

                    Dim prepedidoId As Integer = ObtenerOCrearPrePedidoWebhook(conn, wcOrderNumber, email)

                    Using cmd As New SqlCommand("
                        INSERT INTO FLORERIA_Pedido (
                            prepedido_id, codigo, receptor_nombre, receptor_celular,
                            ciudad_id, tipo_entrega, direccion, referencia, fecha_entrega,
                            total_bs, estado_pago, 
                            wc_order_id, wc_order_number, wc_sync_estado, wc_sync_fecha,
                            creado_por, creado_en
                        ) VALUES (
                            @prepedido, @codigo, @nombre, @celular,
                            @ciudad, @tipoEntrega, @direccion, @ref, @fechaEntrega,
                            @total, @estadoPago,
                            @wcId, @wcNum, @wcEstado, GETDATE(),
                            @creador, GETDATE()
                        ); SELECT SCOPE_IDENTITY();", conn)

                        cmd.Parameters.AddWithValue("@prepedido", prepedidoId)
                        cmd.Parameters.AddWithValue("@codigo", "WC-" & wcOrderNumber)
                        cmd.Parameters.AddWithValue("@nombre", nombreReceptor.Substring(0, Math.Min(200, nombreReceptor.Length)))
                        cmd.Parameters.AddWithValue("@celular", celular.Substring(0, Math.Min(20, celular.Length)))
                        cmd.Parameters.AddWithValue("@ciudad", 1)
                        cmd.Parameters.AddWithValue("@tipoEntrega", "DOMICILIO")
                        cmd.Parameters.AddWithValue("@direccion", direccion.Substring(0, Math.Min(300, direccion.Length)))
                        cmd.Parameters.AddWithValue("@ref", customerNote.Substring(0, Math.Min(300, customerNote.Length)))
                        cmd.Parameters.AddWithValue("@fechaEntrega", DateTime.Now.AddDays(1))
                        cmd.Parameters.AddWithValue("@total", total)
                        cmd.Parameters.AddWithValue("@estadoPago", MapearEstadoPagoWC(status))
                        cmd.Parameters.AddWithValue("@wcId", wcOrderId)
                        cmd.Parameters.AddWithValue("@wcNum", wcOrderNumber)
                        cmd.Parameters.AddWithValue("@wcEstado", "RECIBIDO_WEBHOOK")
                        cmd.Parameters.AddWithValue("@creador", 1)

                        pedidoId = CInt(cmd.ExecuteScalar())
                    End Using

                    resultado("mensaje") = "Pedido creado desde webhook WC #" & wcOrderNumber

                Else
                    System.Diagnostics.Debug.WriteLine($"[WEBHOOK] ACTUALIZANDO pedido existente ID {pedidoId}")

                    Using cmd As New SqlCommand("
                        UPDATE FLORERIA_Pedido SET
                            estado_pago = @estadoPago,
                            wc_order_number = @wcNum,
                            wc_sync_estado = @wcEstado,
                            wc_sync_fecha = GETDATE(),
                            modificado_por = @modificador,
                            modificado_en = GETDATE()
                        WHERE pedido_id = @pid", conn)

                        cmd.Parameters.AddWithValue("@estadoPago", MapearEstadoPagoWC(status))
                        cmd.Parameters.AddWithValue("@wcNum", wcOrderNumber)
                        cmd.Parameters.AddWithValue("@wcEstado", "ACTUALIZADO_WEBHOOK")
                        cmd.Parameters.AddWithValue("@modificador", 1)
                        cmd.Parameters.AddWithValue("@pid", pedidoId)

                        cmd.ExecuteNonQuery()
                    End Using

                    resultado("mensaje") = "Pedido actualizado desde webhook WC #" & wcOrderNumber
                End If

                For Each item In lineItems
                    Dim productId As Integer = If(item.ContainsKey("product_id"), CInt(item("product_id")), 0)
                    Dim quantity As Integer = If(item.ContainsKey("quantity"), CInt(item("quantity")), 1)
                    Dim subtotal As Decimal = 0D
                    If item.ContainsKey("subtotal") Then Decimal.TryParse(item("subtotal").ToString(), subtotal)

                    System.Diagnostics.Debug.WriteLine($"[WEBHOOK] Item: WC Product {productId} x {quantity} = {subtotal}")
                Next

            End Using

            resultado("ok") = True
            resultado("pedido_id") = pedidoId

        Catch ex As Exception
            resultado("mensaje") = "Error al procesar webhook: " & ex.Message
            System.Diagnostics.Debug.WriteLine("[WEBHOOK_ERROR] " & ex.Message & vbCrLf & ex.StackTrace)
        End Try

        Return resultado
    End Function

    Private Shared Function ObtenerOCrearPrePedidoWebhook(conn As SqlConnection, wcOrderNumber As String, email As String) As Integer
        Try
            Dim codigo As String = "WEB-" & wcOrderNumber
            Using cmd As New SqlCommand("
                IF EXISTS (SELECT 1 FROM FLORERIA_PrePedido WHERE codigo=@cod)
                    SELECT prepedido_id FROM FLORERIA_PrePedido WHERE codigo=@cod
                ELSE BEGIN
                    INSERT INTO FLORERIA_PrePedido (
                        codigo, tipo_registro, estado, cliente_celular, cliente_email, creado_por
                    ) VALUES (
                        @cod, 'VENTA_TIENDA', 'COMPLETADO', '00000000', @email, 1
                    );
                    SELECT SCOPE_IDENTITY();
                END", conn)

                cmd.Parameters.AddWithValue("@cod", codigo)
                cmd.Parameters.AddWithValue("@email", If(email <> "", email, DBNull.Value))
                Return CInt(cmd.ExecuteScalar())
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("[WEBHOOK] Error crear PrePedido: " & ex.Message)
            Return 1
        End Try
    End Function

    Private Shared Function MapearEstadoPagoWC(wcStatus As String) As String
        Select Case wcStatus.ToLower().Trim()
            Case "pending", "on-hold"
                Return "PENDIENTE"
            Case "processing"
                Return "PAGADO"
            Case "completed"
                Return "PAGADO"
            Case "cancelled", "failed", "refunded"
                Return "CANCELADO"
            Case Else
                Return "PENDIENTE"
        End Select
    End Function

End Class