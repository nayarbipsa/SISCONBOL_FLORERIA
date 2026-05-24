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
            Dim errorMsg As String = ex.Message
            Try
                Using sr As New StreamReader(ex.Response.GetResponseStream())
                    errorMsg = sr.ReadToEnd()
                End Using
            Catch
            End Try
            ActualizarEstadoSyncPedido(pedidoId, 0, "", "ERROR", errorMsg)
            resultado("mensaje") = "Error: " & errorMsg.Substring(0, Math.Min(100, errorMsg.Length))

        Catch ex As Exception
            ActualizarEstadoSyncPedido(pedidoId, 0, "", "ERROR", ex.Message)
            resultado("mensaje") = "Error: " & ex.Message
        End Try

        Return resultado
    End Function

    Private Shared Function ObtenerPedido(pedidoId As Integer) As Dictionary(Of String, Object)
        Try
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()
                Using cmd As New SqlCommand("SELECT * FROM FLORERIA_Pedido WHERE pedido_id=@id", conn)
                    cmd.Parameters.AddWithValue("@id", pedidoId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Dim p As New Dictionary(Of String, Object)()
                            p("pedido_id") = dr("pedido_id")
                            p("receptor_nombre") = dr("receptor_nombre").ToString()
                            p("receptor_celular") = If(IsDBNull(dr("receptor_celular")), "", dr("receptor_celular").ToString())
                            p("direccion") = If(IsDBNull(dr("direccion")), "", dr("direccion").ToString())
                            p("total_bs") = CDec(dr("total_bs"))
                            p("estado_pago") = dr("estado_pago").ToString()
                            p("wc_order_id") = If(IsDBNull(dr("wc_order_id")), 0, CInt(dr("wc_order_id")))
                            Return p
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ObtenerPedido: " & ex.Message)
        End Try
        Return Nothing
    End Function

    Private Shared Function ConstruirJsonPedido(pedido As Dictionary(Of String, Object)) As String
        Dim sb As New StringBuilder()
        sb.Append("{")

        sb.Append("""status"":""" & MapearEstadoPedido(pedido("estado_pago").ToString()) & """,")

        ' Información de facturación y envío
        sb.Append("""billing"":{")
        sb.Append("""first_name"":""" & EscaparJson(pedido("receptor_nombre").ToString()) & """,")
        sb.Append("""phone"":""" & EscaparJson(pedido("receptor_celular").ToString()) & """},")

        sb.Append("""shipping"":{")
        sb.Append("""first_name"":""" & EscaparJson(pedido("receptor_nombre").ToString()) & """,")
        sb.Append("""address_1"":""" & EscaparJson(pedido("direccion").ToString()) & """},")

        ' Total
        sb.Append("""total"":""" & CDec(pedido("total_bs")).ToString("F2") & """,")

        ' TODO: Agregar line_items (productos del pedido)
        sb.Append("""line_items"":[],")

        If sb.Length > 1 AndAlso sb(sb.Length - 1) = ","c Then sb.Length -= 1
        sb.Append("}")
        Return sb.ToString()
    End Function

    Private Shared Function MapearEstadoPedido(estadoPago As String) As String
        Select Case estadoPago.ToUpper()
            Case "PENDIENTE" : Return "pending"
            Case "PAGADO" : Return "processing"
            Case Else : Return "on-hold"
        End Select
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
    ' ============================================

    ''' <summary>
    ''' Procesa una orden recibida via webhook de WooCommerce
    ''' Crea o actualiza el pedido en FLORERIA_Pedido
    ''' </summary>
    ''' <param name="jsonData">JSON completo del webhook (payload de WooCommerce)</param>
    ''' <returns>Dictionary con ok, mensaje, pedido_id</returns>
    Public Shared Function ProcesarOrdenWebhook(jsonData As String) As Dictionary(Of String, Object)
        Dim resultado As New Dictionary(Of String, Object)
        resultado("ok") = False
        resultado("mensaje") = ""
        resultado("pedido_id") = 0

        Try
            ' ============================================
            ' 1. PARSEAR JSON DE WOOCOMMERCE
            ' ============================================
            Dim serializer As New JavaScriptSerializer()
            serializer.MaxJsonLength = Integer.MaxValue
            Dim orden As Dictionary(Of String, Object) = serializer.Deserialize(Of Dictionary(Of String, Object))(jsonData)

            If Not orden.ContainsKey("id") Then
                resultado("mensaje") = "JSON sin campo 'id'"
                Return resultado
            End If

            ' Campos principales de la orden
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

            ' ============================================
            ' 2. EXTRAER BILLING (FACTURACIÓN)
            ' ============================================
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

            ' Valores por defecto si están vacíos
            If nombreReceptor = "" Then nombreReceptor = "Cliente Web"
            If celular = "" Then celular = "00000000"

            ' ============================================
            ' 3. EXTRAER SHIPPING (ENVÍO)
            ' ============================================
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

            ' ============================================
            ' 4. EXTRAER LINE_ITEMS (PRODUCTOS)
            ' ============================================
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

            ' ============================================
            ' 5. VERIFICAR SI YA EXISTE EL PEDIDO (ANTI-LOOP)
            ' ============================================
            Dim pedidoId As Integer = 0
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()

                ' Buscar pedido existente por wc_order_id
                Using cmd As New SqlCommand("SELECT pedido_id, wc_sync_estado FROM FLORERIA_Pedido WHERE wc_order_id=@wc", conn)
                    cmd.Parameters.AddWithValue("@wc", wcOrderId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            pedidoId = CInt(dr("pedido_id"))
                            Dim estadoSync As String = dr("wc_sync_estado").ToString()
                            
                            ' ============================================
                            ' 🔒 PROTECCIÓN ANTI-LOOP INFINITO
                            ' ============================================
                            ' Si el pedido fue creado/sincronizado DESDE SISCONBOL hacia WC,
                            ' NO procesar este webhook para evitar duplicados
                            ' ============================================
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
                    ' ============================================
                    ' 6A. CREAR NUEVO PEDIDO
                    ' ============================================
                    System.Diagnostics.Debug.WriteLine("[WEBHOOK] Creando NUEVO pedido")

                    ' Buscar o crear PrePedido temporal
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
                        cmd.Parameters.AddWithValue("@ciudad", 1) ' TODO: Mapear ciudad desde shipping.city
                        cmd.Parameters.AddWithValue("@tipoEntrega", "DOMICILIO")
                        cmd.Parameters.AddWithValue("@direccion", direccion.Substring(0, Math.Min(300, direccion.Length)))
                        cmd.Parameters.AddWithValue("@ref", customerNote.Substring(0, Math.Min(300, customerNote.Length)))
                        cmd.Parameters.AddWithValue("@fechaEntrega", DateTime.Now.AddDays(1)) ' Entrega para mañana por defecto
                        cmd.Parameters.AddWithValue("@total", total)
                        cmd.Parameters.AddWithValue("@estadoPago", MapearEstadoPagoWC(status))
                        cmd.Parameters.AddWithValue("@wcId", wcOrderId)
                        cmd.Parameters.AddWithValue("@wcNum", wcOrderNumber)
                        cmd.Parameters.AddWithValue("@wcEstado", "RECIBIDO_WEBHOOK")
                        cmd.Parameters.AddWithValue("@creador", 1) ' Usuario sistema

                        pedidoId = CInt(cmd.ExecuteScalar())
                    End Using

                    resultado("mensaje") = "Pedido creado desde webhook WC #" & wcOrderNumber

                Else
                    ' ============================================
                    ' 6B. ACTUALIZAR PEDIDO EXISTENTE
                    ' ============================================
                    System.Diagnostics.Debug.WriteLine($"[WEBHOOK] ACTUALIZANDO pedido existente ID {pedidoId}")

                    ' Solo actualizar campos que WooCommerce podría haber cambiado
                    ' NO sobrescribir datos locales importantes
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

                ' ============================================
                ' 7. PROCESAR LINE_ITEMS (OPCIONAL)
                ' ============================================
                ' TODO: Implementar inserción en FLORERIA_Pedido_Detalle
                ' Requiere mapear product_id de WC a producto_id local vía wc_product_id
                For Each item In lineItems
                    Dim productId As Integer = If(item.ContainsKey("product_id"), CInt(item("product_id")), 0)
                    Dim quantity As Integer = If(item.ContainsKey("quantity"), CInt(item("quantity")), 1)
                    Dim subtotal As Decimal = 0D
                    If item.ContainsKey("subtotal") Then Decimal.TryParse(item("subtotal").ToString(), subtotal)

                    System.Diagnostics.Debug.WriteLine($"[WEBHOOK] Item: WC Product {productId} x {quantity} = {subtotal}")
                    ' Aquí insertar en FLORERIA_Pedido_Detalle cuando esté lista la tabla
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

    ''' <summary>
    ''' Obtiene o crea un PrePedido temporal para órdenes web
    ''' </summary>
    Private Shared Function ObtenerOCrearPrePedidoWebhook(conn As SqlConnection, wcOrderNumber As String, email As String) As Integer
        Try
            ' Buscar PrePedido existente por email o crear uno genérico
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
            Return 1 ' ID genérico de fallback
        End Try
    End Function

    ''' <summary>
    ''' Mapea el estado de WooCommerce a estado de pago de SISCONBOL
    ''' </summary>
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