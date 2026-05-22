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

End Class