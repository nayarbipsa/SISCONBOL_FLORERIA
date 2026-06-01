Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.IO
Imports System.Net
Imports System.Text
Imports System.Web.Script.Serialization

' ============================================================
' SISCONBOL_FLORERIA - CrmWcExtractor
' Motor de extraccion del ESPEJO crudo de WooCommerce.
' Descarga orders / products / categories desde la API WC v3
' y los guarda (upsert) en las tablas FLORERIA_WC_*.
'
' NO toca las tablas operativas. Reusa el patron HTTP de
' Migrar.aspx (Basic Auth, paginacion per_page=100).
'
' Convencion del proyecto: App_Code SIN Namespace.
' ============================================================
Public Class CrmWcExtractor

    ' Resultado de una corrida de extraccion
    Public Class Resultado
        Public Property Ok As Boolean = False
        Public Property ExtraccionId As Integer = 0
        Public Property Total As Integer = 0
        Public Property Nuevos As Integer = 0
        Public Property Actualizados As Integer = 0
        Public Property Errores As Integer = 0
        Public Property UltimaPaginaOk As Integer = 0
        Public Property Log As String = ""
    End Class

    ' Claves de meta_data que guardamos en FLORERIA_WC_Order_Meta.
    ' El resto del meta_data igual queda completo en json_raw.
    Private Shared ReadOnly MetaInteresantes As New HashSet(Of String)(StringComparer.OrdinalIgnoreCase) From {
        "delivery_date", "delivery_time", "delivery_type", "pickup_date", "pickup_time",
        "tipo_de_ocacion", "_woocs_order_rate", "nota_floreria", "gps",
        "firma_tarjeta", "mensaje_tarjeta", "dedicatoria", "TelefonoRecibe", "_ppcp_paypal_order_id"
    }

    ' ========================================================
    ' CONFIG (lee credenciales de FLORERIA_Config)
    ' ========================================================
    Private Shared Function ValorConfig(clave As String) As String
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("SELECT valor FROM FLORERIA_Config WHERE clave=@c AND activo=1", conn)
                    cmd.Parameters.AddWithValue("@c", clave)
                    Dim r As Object = cmd.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then Return r.ToString()
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR CrmWcExtractor.ValorConfig: " & ex.Message)
        End Try
        Return ""
    End Function

    Private Shared Function CrearAuth(ckey As String, csec As String) As String
        Return "Basic " & Convert.ToBase64String(Encoding.UTF8.GetBytes(ckey & ":" & csec))
    End Function

    ' Descarga el texto JSON de un endpoint paginado de WC
    Private Shared Function DescargarPagina(urlBase As String, auth As String, endpointConParams As String) As String
        Dim req As HttpWebRequest = DirectCast(WebRequest.Create(urlBase & "/wp-json/wc/v3" & endpointConParams), HttpWebRequest)
        req.Method = "GET"
        req.Headers.Add("Authorization", auth)
        req.Timeout = 90000
        Using resp As HttpWebResponse = DirectCast(req.GetResponse(), HttpWebResponse)
            If resp.StatusCode <> HttpStatusCode.OK Then
                Throw New Exception("HTTP " & CInt(resp.StatusCode))
            End If
            Using sr As New StreamReader(resp.GetResponseStream())
                Return sr.ReadToEnd()
            End Using
        End Using
    End Function

    ' ========================================================
    ' Helpers de parseo (JavaScriptSerializer -> Dictionary)
    ' ========================================================
    Private Shared Function GStr(d As Dictionary(Of String, Object), key As String) As String
        If d Is Nothing OrElse Not d.ContainsKey(key) OrElse d(key) Is Nothing Then Return ""
        Return d(key).ToString().Trim()
    End Function

    Private Shared Function GInt(d As Dictionary(Of String, Object), key As String) As Integer
        Dim s As String = GStr(d, key)
        Dim v As Integer = 0
        Integer.TryParse(s, v)
        Return v
    End Function

    Private Shared Function GDec(d As Dictionary(Of String, Object), key As String) As Decimal
        Dim s As String = GStr(d, key)
        Dim v As Decimal = 0D
        Decimal.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, v)
        Return v
    End Function

    Private Shared Function GDate(d As Dictionary(Of String, Object), key As String) As Object
        Dim s As String = GStr(d, key)
        If s = "" Then Return DBNull.Value
        Dim dt As DateTime
        If DateTime.TryParse(s, dt) Then Return dt
        Return DBNull.Value
    End Function

    Private Shared Function GSub(d As Dictionary(Of String, Object), key As String) As Dictionary(Of String, Object)
        If d IsNot Nothing AndAlso d.ContainsKey(key) Then
            Return TryCast(d(key), Dictionary(Of String, Object))
        End If
        Return Nothing
    End Function

    Private Shared Function GArr(d As Dictionary(Of String, Object), key As String) As Object()
        If d IsNot Nothing AndAlso d.ContainsKey(key) Then
            Dim arr As Object() = TryCast(d(key), Object())
            If arr IsNot Nothing Then Return arr
        End If
        Return New Object() {}
    End Function

    ' Busca un valor en el array meta_data por clave
    Private Shared Function MetaValor(metaArr As Object(), clave As String) As String
        If metaArr Is Nothing Then Return ""
        For Each o As Object In metaArr
            Dim m As Dictionary(Of String, Object) = TryCast(o, Dictionary(Of String, Object))
            If m IsNot Nothing AndAlso GStr(m, "key") = clave Then
                Return GStr(m, "value")
            End If
        Next
        Return ""
    End Function

    Private Shared Function ValorComoTexto(v As Object) As String
        If v Is Nothing Then Return ""
        If TypeOf v Is String Then Return CStr(v)
        Try
            Dim ser As New JavaScriptSerializer()
            ser.MaxJsonLength = Integer.MaxValue
            Return ser.Serialize(v)
        Catch
            Return v.ToString()
        End Try
    End Function

    ' ========================================================
    ' EXTRAER ORDENES (por rango de fechas = un tramo)
    ' ========================================================
    Public Shared Function ExtraerOrdenes(desde As String, hasta As String, statusFiltro As String, usuarioId As Integer) As Resultado
        Dim res As New Resultado()
        Dim log As New StringBuilder()
        Dim url As String = ValorConfig("WC_URL")
        Dim ckey As String = ValorConfig("WC_CONSUMER_KEY")
        Dim csec As String = ValorConfig("WC_CONSUMER_SECRET")
        If url = "" OrElse ckey = "" OrElse csec = "" Then
            res.Log = "ERROR: Faltan credenciales WC en Configuracion."
            Return res
        End If
        If statusFiltro Is Nothing OrElse statusFiltro.Trim() = "" Then statusFiltro = "any"

        res.ExtraccionId = IniciarSync("ORDERS", desde, hasta, statusFiltro, usuarioId)
        Dim auth As String = CrearAuth(ckey, csec)
        Dim ser As New JavaScriptSerializer()
        ser.MaxJsonLength = Integer.MaxValue

        log.AppendLine("Extraccion ORDERS #" & res.ExtraccionId & " (" & desde & " a " & hasta & ", status=" & statusFiltro & ")")

        Try
            Dim pagina As Integer = 1
            Dim continuar As Boolean = True
            While continuar AndAlso pagina <= 200
                Dim params As String = "/orders?per_page=100&page=" & pagina
                If desde <> "" Then params &= "&after=" & desde & "T00:00:00"
                If hasta <> "" Then params &= "&before=" & hasta & "T23:59:59"
                If statusFiltro <> "any" Then params &= "&status=" & statusFiltro
                params &= "&orderby=date&order=asc"

                Dim json As String
                Try
                    json = DescargarPagina(url, auth, params)
                Catch wex As Exception
                    log.AppendLine("ERROR HTTP pagina " & pagina & ": " & wex.Message)
                    Exit While
                End Try

                Dim lista As Object() = TryCast(ser.DeserializeObject(json), Object())
                If lista Is Nothing OrElse lista.Length = 0 Then Exit While

                For Each o As Object In lista
                    Dim ord As Dictionary(Of String, Object) = TryCast(o, Dictionary(Of String, Object))
                    If ord Is Nothing Then Continue For
                    Try
                        ' Conexion FRESCA por orden + reintento: un corte de red
                        ' mata solo esta orden, no el resto del lote.
                        Dim accion As String = ProcesarOrden(ord, ser.Serialize(ord), res.ExtraccionId)
                        If accion = "I" Then res.Nuevos += 1 Else res.Actualizados += 1
                        res.Total += 1
                    Catch exo As Exception
                        res.Errores += 1
                        log.AppendLine("ERROR orden WC#" & GInt(ord, "id") & ": " & exo.Message)
                    End Try
                Next

                log.AppendLine("Pagina " & pagina & ": " & lista.Length & " ordenes (acumulado " & res.Total & ")")
                res.UltimaPaginaOk = pagina
                If lista.Length < 100 Then continuar = False
                pagina += 1
            End While
            res.Ok = True
            log.AppendLine("LISTO: " & res.Total & " ordenes (" & res.Nuevos & " nuevas, " & res.Actualizados & " actualizadas, " & res.Errores & " errores).")
        Catch ex As Exception
            log.AppendLine("ERROR CRITICO: " & ex.Message)
        End Try

        res.Log = log.ToString()
        FinalizarSync(res, If(res.Ok, "OK", "ERROR"))
        Return res
    End Function

    ' Procesa UNA orden con conexion propia y reintento (resiliente a
    ' cortes de red del servidor remoto).
    Private Shared Function ProcesarOrden(ord As Dictionary(Of String, Object), json As String, extraccionId As Integer) As String
        Dim ultimoError As Exception = Nothing
        For intento As Integer = 1 To 2
            Try
                Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                    conn.Open()
                    Return UpsertOrden(conn, ord, json, extraccionId)
                End Using
            Catch ex As Exception
                ultimoError = ex
            End Try
        Next
        Throw ultimoError
    End Function

    Private Shared Function UpsertOrden(conn As SqlConnection, ord As Dictionary(Of String, Object), json As String, extraccionId As Integer) As String
        Dim wcId As Integer = GInt(ord, "id")
        Dim billing As Dictionary(Of String, Object) = GSub(ord, "billing")
        Dim shipping As Dictionary(Of String, Object) = GSub(ord, "shipping")
        Dim metaArr As Object() = GArr(ord, "meta_data")
        Dim items As Object() = GArr(ord, "line_items")

        ' shipping direccion = address_1 + address_2
        Dim dir1 As String = GStr(shipping, "address_1")
        Dim dir2 As String = GStr(shipping, "address_2")
        Dim dirShip As String = If(dir2 <> "", (dir1 & " " & dir2).Trim(), dir1)

        ' subtotal = suma de subtotales de items
        Dim subtotal As Decimal = 0D
        For Each it As Object In items
            Dim itd As Dictionary(Of String, Object) = TryCast(it, Dictionary(Of String, Object))
            If itd IsNot Nothing Then subtotal += GDec(itd, "subtotal")
        Next

        ' meta utiles
        Dim deliveryDate As String = MetaValor(metaArr, "delivery_date")
        If deliveryDate = "" Then deliveryDate = MetaValor(metaArr, "pickup_date")
        Dim deliveryTime As String = MetaValor(metaArr, "delivery_time")
        If deliveryTime = "" Then deliveryTime = MetaValor(metaArr, "pickup_time")
        Dim tipoOcacion As String = MetaValor(metaArr, "tipo_de_ocacion")
        Dim rateStr As String = MetaValor(metaArr, "_woocs_order_rate")
        Dim woocsRate As Decimal = 0D
        If rateStr <> "" Then Decimal.TryParse(rateStr, NumberStyles.Any, CultureInfo.InvariantCulture, woocsRate)
        ' Clamp: descartar tasas absurdas (la real BOB/USD ronda 0.14 - 7)
        If woocsRate < 0D OrElse woocsRate > 100000D Then woocsRate = 0D

        Dim ddObj As Object = DBNull.Value
        If deliveryDate <> "" Then
            Dim dd As DateTime
            If DateTime.TryParse(deliveryDate, dd) Then ddObj = dd.Date
        End If

        Dim accion As String = "I"
        Using cmd As New SqlCommand("FLORERIA_WC_sp_Order_Upsert", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.CommandTimeout = 60
            cmd.Parameters.AddWithValue("@wc_order_id", wcId)
            cmd.Parameters.AddWithValue("@number", Trunc(GStr(ord, "number"), 30))
            cmd.Parameters.AddWithValue("@order_key", Trunc(GStr(ord, "order_key"), 60))
            cmd.Parameters.AddWithValue("@status", Trunc(GStr(ord, "status"), 30))
            cmd.Parameters.AddWithValue("@currency", Trunc(GStr(ord, "currency"), 3))
            cmd.Parameters.AddWithValue("@date_created", GDate(ord, "date_created"))
            cmd.Parameters.AddWithValue("@date_paid", GDate(ord, "date_paid"))
            cmd.Parameters.AddWithValue("@date_modified", GDate(ord, "date_modified"))
            cmd.Parameters.AddWithValue("@customer_id", GInt(ord, "customer_id"))
            cmd.Parameters.AddWithValue("@billing_nombre", Trunc(GStr(billing, "first_name"), 150))
            cmd.Parameters.AddWithValue("@billing_apellidos", Trunc(GStr(billing, "last_name"), 150))
            cmd.Parameters.AddWithValue("@billing_email", Trunc(GStr(billing, "email"), 200))
            cmd.Parameters.AddWithValue("@billing_phone", Trunc(GStr(billing, "phone"), 40))
            cmd.Parameters.AddWithValue("@shipping_nombre", Trunc((GStr(shipping, "first_name") & " " & GStr(shipping, "last_name")).Trim(), 200))
            cmd.Parameters.AddWithValue("@shipping_phone", Trunc(GStr(shipping, "phone"), 40))
            cmd.Parameters.AddWithValue("@shipping_direccion", Trunc(dirShip, 400))
            cmd.Parameters.AddWithValue("@shipping_ciudad", Trunc(GStr(shipping, "city"), 100))
            cmd.Parameters.AddWithValue("@shipping_state", Trunc(GStr(shipping, "state"), 100))
            cmd.Parameters.AddWithValue("@payment_method", Trunc(GStr(ord, "payment_method"), 50))
            cmd.Parameters.AddWithValue("@payment_method_title", Trunc(GStr(ord, "payment_method_title"), 120))
            cmd.Parameters.AddWithValue("@subtotal", subtotal)
            cmd.Parameters.AddWithValue("@shipping_total", GDec(ord, "shipping_total"))
            cmd.Parameters.AddWithValue("@discount_total", GDec(ord, "discount_total"))
            cmd.Parameters.AddWithValue("@total", GDec(ord, "total"))
            cmd.Parameters.AddWithValue("@woocs_rate", woocsRate)
            cmd.Parameters.AddWithValue("@delivery_date", ddObj)
            cmd.Parameters.AddWithValue("@delivery_time", Trunc(deliveryTime, 40))
            cmd.Parameters.AddWithValue("@tipo_ocacion", Trunc(tipoOcacion, 60))
            cmd.Parameters.AddWithValue("@cantidad_items", items.Length)
            cmd.Parameters.AddWithValue("@json_raw", If(json Is Nothing, CObj(DBNull.Value), CObj(json)))
            cmd.Parameters.AddWithValue("@extraccion_id", extraccionId)
            Dim r As Object = cmd.ExecuteScalar()
            If r IsNot Nothing AndAlso Not IsDBNull(r) Then accion = r.ToString()
        End Using

        ' line_items
        For Each it As Object In items
            Dim itd As Dictionary(Of String, Object) = TryCast(it, Dictionary(Of String, Object))
            If itd Is Nothing Then Continue For
            Using cmd As New SqlCommand("FLORERIA_WC_sp_OrderItem_Insert", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@wc_order_id", wcId)
                cmd.Parameters.AddWithValue("@wc_line_item_id", GInt(itd, "id"))
                cmd.Parameters.AddWithValue("@wc_product_id", GInt(itd, "product_id"))
                cmd.Parameters.AddWithValue("@wc_variation_id", GInt(itd, "variation_id"))
                cmd.Parameters.AddWithValue("@nombre", Trunc(GStr(itd, "name"), 300))
                cmd.Parameters.AddWithValue("@sku", Trunc(GStr(itd, "sku"), 100))
                cmd.Parameters.AddWithValue("@cantidad", GInt(itd, "quantity"))
                cmd.Parameters.AddWithValue("@precio_unitario", GDec(itd, "price"))
                cmd.Parameters.AddWithValue("@subtotal", GDec(itd, "subtotal"))
                cmd.Parameters.AddWithValue("@total", GDec(itd, "total"))
                cmd.ExecuteNonQuery()
            End Using
        Next

        ' meta_data: solo las claves utiles para analisis (el resto queda
        ' integro en json_raw). Asi se reducen los round-trips al servidor
        ' remoto, que es lo que provocaba los timeouts.
        If metaArr IsNot Nothing Then
            For Each o As Object In metaArr
                Dim m As Dictionary(Of String, Object) = TryCast(o, Dictionary(Of String, Object))
                If m Is Nothing Then Continue For
                Dim k As String = GStr(m, "key")
                If k = "" OrElse Not MetaInteresantes.Contains(k) Then Continue For
                Dim val As String = ""
                If m.ContainsKey("value") Then val = ValorComoTexto(m("value"))
                Using cmd As New SqlCommand("FLORERIA_WC_sp_OrderMeta_Insert", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@wc_order_id", wcId)
                    cmd.Parameters.AddWithValue("@meta_key", Trunc(k, 200))
                    cmd.Parameters.AddWithValue("@meta_value", If(val = "", CObj(DBNull.Value), CObj(val)))
                    cmd.ExecuteNonQuery()
                End Using
            Next
        End If

        Return accion
    End Function

    ' ========================================================
    ' EXTRAER PRODUCTOS
    ' ========================================================
    Public Shared Function ExtraerProductos(usuarioId As Integer) As Resultado
        Dim res As New Resultado()
        Dim log As New StringBuilder()
        Dim url As String = ValorConfig("WC_URL")
        Dim ckey As String = ValorConfig("WC_CONSUMER_KEY")
        Dim csec As String = ValorConfig("WC_CONSUMER_SECRET")
        If url = "" OrElse ckey = "" OrElse csec = "" Then
            res.Log = "ERROR: Faltan credenciales WC en Configuracion."
            Return res
        End If
        res.ExtraccionId = IniciarSync("PRODUCTS", "", "", "", usuarioId)
        Dim auth As String = CrearAuth(ckey, csec)
        Dim ser As New JavaScriptSerializer()
        ser.MaxJsonLength = Integer.MaxValue
        log.AppendLine("Extraccion PRODUCTS #" & res.ExtraccionId)

        Try
            Dim pagina As Integer = 1
            Dim continuar As Boolean = True
            While continuar AndAlso pagina <= 100
                Dim json As String
                Try
                    json = DescargarPagina(url, auth, "/products?per_page=100&page=" & pagina)
                Catch wex As Exception
                    log.AppendLine("ERROR HTTP pagina " & pagina & ": " & wex.Message)
                    Exit While
                End Try
                Dim lista As Object() = TryCast(ser.DeserializeObject(json), Object())
                If lista Is Nothing OrElse lista.Length = 0 Then Exit While
                For Each o As Object In lista
                    Dim p As Dictionary(Of String, Object) = TryCast(o, Dictionary(Of String, Object))
                    If p Is Nothing Then Continue For
                    Try
                        Dim accion As String = ProcesarProducto(p, ser.Serialize(p), res.ExtraccionId)
                        If accion = "I" Then res.Nuevos += 1 Else res.Actualizados += 1
                        res.Total += 1
                    Catch exo As Exception
                        res.Errores += 1
                        log.AppendLine("ERROR producto WC#" & GInt(p, "id") & ": " & exo.Message)
                    End Try
                Next
                log.AppendLine("Pagina " & pagina & ": " & lista.Length & " productos (acumulado " & res.Total & ")")
                res.UltimaPaginaOk = pagina
                If lista.Length < 100 Then continuar = False
                pagina += 1
            End While
            res.Ok = True
            log.AppendLine("LISTO: " & res.Total & " productos (" & res.Nuevos & " nuevos, " & res.Actualizados & " actualizados).")
        Catch ex As Exception
            log.AppendLine("ERROR CRITICO: " & ex.Message)
        End Try
        res.Log = log.ToString()
        FinalizarSync(res, If(res.Ok, "OK", "ERROR"))
        Return res
    End Function

    Private Shared Function ProcesarProducto(p As Dictionary(Of String, Object), json As String, extraccionId As Integer) As String
        Dim ultimoError As Exception = Nothing
        For intento As Integer = 1 To 2
            Try
                Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                    conn.Open()
                    Return UpsertProducto(conn, p, json, extraccionId)
                End Using
            Catch ex As Exception
                ultimoError = ex
            End Try
        Next
        Throw ultimoError
    End Function

    Private Shared Function UpsertProducto(conn As SqlConnection, p As Dictionary(Of String, Object), json As String, extraccionId As Integer) As String
        Dim cats As New List(Of String)
        For Each c As Object In GArr(p, "categories")
            Dim cd As Dictionary(Of String, Object) = TryCast(c, Dictionary(Of String, Object))
            If cd IsNot Nothing Then cats.Add(GInt(cd, "id").ToString())
        Next
        Dim accion As String = "I"
        Using cmd As New SqlCommand("FLORERIA_WC_sp_Product_Upsert", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.CommandTimeout = 60
            cmd.Parameters.AddWithValue("@wc_product_id", GInt(p, "id"))
            cmd.Parameters.AddWithValue("@name", Trunc(GStr(p, "name"), 300))
            cmd.Parameters.AddWithValue("@slug", Trunc(GStr(p, "slug"), 300))
            cmd.Parameters.AddWithValue("@sku", Trunc(GStr(p, "sku"), 100))
            cmd.Parameters.AddWithValue("@type", Trunc(GStr(p, "type"), 30))
            cmd.Parameters.AddWithValue("@status", Trunc(GStr(p, "status"), 20))
            cmd.Parameters.AddWithValue("@regular_price", GDec(p, "regular_price"))
            cmd.Parameters.AddWithValue("@sale_price", GDec(p, "sale_price"))
            cmd.Parameters.AddWithValue("@stock_status", Trunc(GStr(p, "stock_status"), 20))
            cmd.Parameters.AddWithValue("@total_sales", GInt(p, "total_sales"))
            cmd.Parameters.AddWithValue("@date_created", GDate(p, "date_created"))
            cmd.Parameters.AddWithValue("@date_modified", GDate(p, "date_modified"))
            cmd.Parameters.AddWithValue("@json_raw", If(json Is Nothing, CObj(DBNull.Value), CObj(json)))
            cmd.Parameters.AddWithValue("@extraccion_id", extraccionId)
            cmd.Parameters.AddWithValue("@categorias_csv", String.Join(",", cats))
            Dim r As Object = cmd.ExecuteScalar()
            If r IsNot Nothing AndAlso Not IsDBNull(r) Then accion = r.ToString()
        End Using
        Return accion
    End Function

    ' ========================================================
    ' EXTRAER CATEGORIAS
    ' ========================================================
    Public Shared Function ExtraerCategorias(usuarioId As Integer) As Resultado
        Dim res As New Resultado()
        Dim log As New StringBuilder()
        Dim url As String = ValorConfig("WC_URL")
        Dim ckey As String = ValorConfig("WC_CONSUMER_KEY")
        Dim csec As String = ValorConfig("WC_CONSUMER_SECRET")
        If url = "" OrElse ckey = "" OrElse csec = "" Then
            res.Log = "ERROR: Faltan credenciales WC en Configuracion."
            Return res
        End If
        res.ExtraccionId = IniciarSync("CATEGORIES", "", "", "", usuarioId)
        Dim auth As String = CrearAuth(ckey, csec)
        Dim ser As New JavaScriptSerializer()
        ser.MaxJsonLength = Integer.MaxValue
        log.AppendLine("Extraccion CATEGORIES #" & res.ExtraccionId)

        Try
            Dim pagina As Integer = 1
            Dim continuar As Boolean = True
            While continuar AndAlso pagina <= 50
                Dim json As String
                Try
                    json = DescargarPagina(url, auth, "/products/categories?per_page=100&page=" & pagina)
                Catch wex As Exception
                    log.AppendLine("ERROR HTTP pagina " & pagina & ": " & wex.Message)
                    Exit While
                End Try
                Dim lista As Object() = TryCast(ser.DeserializeObject(json), Object())
                If lista Is Nothing OrElse lista.Length = 0 Then Exit While
                For Each o As Object In lista
                    Dim c As Dictionary(Of String, Object) = TryCast(o, Dictionary(Of String, Object))
                    If c Is Nothing Then Continue For
                    Try
                        Dim accion As String = ProcesarCategoria(c, ser.Serialize(c), res.ExtraccionId)
                        If accion = "I" Then res.Nuevos += 1 Else res.Actualizados += 1
                        res.Total += 1
                    Catch exo As Exception
                        res.Errores += 1
                        log.AppendLine("ERROR categoria WC#" & GInt(c, "id") & ": " & exo.Message)
                    End Try
                Next
                log.AppendLine("Pagina " & pagina & ": " & lista.Length & " categorias (acumulado " & res.Total & ")")
                res.UltimaPaginaOk = pagina
                If lista.Length < 100 Then continuar = False
                pagina += 1
            End While
            res.Ok = True
            log.AppendLine("LISTO: " & res.Total & " categorias (" & res.Nuevos & " nuevas, " & res.Actualizados & " actualizadas).")
        Catch ex As Exception
            log.AppendLine("ERROR CRITICO: " & ex.Message)
        End Try
        res.Log = log.ToString()
        FinalizarSync(res, If(res.Ok, "OK", "ERROR"))
        Return res
    End Function

    Private Shared Function ProcesarCategoria(c As Dictionary(Of String, Object), json As String, extraccionId As Integer) As String
        Dim ultimoError As Exception = Nothing
        For intento As Integer = 1 To 2
            Try
                Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                    conn.Open()
                    Using cmd As New SqlCommand("FLORERIA_WC_sp_Category_Upsert", conn)
                        cmd.CommandType = CommandType.StoredProcedure
                        cmd.Parameters.AddWithValue("@wc_category_id", GInt(c, "id"))
                        cmd.Parameters.AddWithValue("@name", Trunc(GStr(c, "name"), 200))
                        cmd.Parameters.AddWithValue("@slug", Trunc(GStr(c, "slug"), 200))
                        cmd.Parameters.AddWithValue("@parent", GInt(c, "parent"))
                        cmd.Parameters.AddWithValue("@count", GInt(c, "count"))
                        cmd.Parameters.AddWithValue("@json_raw", CObj(json))
                        cmd.Parameters.AddWithValue("@extraccion_id", extraccionId)
                        Dim r As Object = cmd.ExecuteScalar()
                        Return If(r IsNot Nothing AndAlso Not IsDBNull(r), r.ToString(), "I")
                    End Using
                End Using
            Catch ex As Exception
                ultimoError = ex
            End Try
        Next
        Throw ultimoError
    End Function

    ' ========================================================
    ' SYNC LOG
    ' ========================================================
    Private Shared Function IniciarSync(tipo As String, desde As String, hasta As String, statusFiltro As String, usuarioId As Integer) As Integer
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_WC_sp_Sync_Iniciar", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@tipo", tipo)
                    cmd.Parameters.AddWithValue("@fecha_desde", If(desde = "", CObj(DBNull.Value), CObj(desde)))
                    cmd.Parameters.AddWithValue("@fecha_hasta", If(hasta = "", CObj(DBNull.Value), CObj(hasta)))
                    cmd.Parameters.AddWithValue("@status_filtro", If(statusFiltro = "", CObj(DBNull.Value), CObj(statusFiltro)))
                    cmd.Parameters.AddWithValue("@usuario_id", usuarioId)
                    Dim r As Object = cmd.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then Return CInt(r)
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR IniciarSync: " & ex.Message)
        End Try
        Return 0
    End Function

    Private Shared Sub FinalizarSync(res As Resultado, estado As String)
        If res.ExtraccionId <= 0 Then Return
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_WC_sp_Sync_Finalizar", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@extraccion_id", res.ExtraccionId)
                    cmd.Parameters.AddWithValue("@total_descargados", res.Total)
                    cmd.Parameters.AddWithValue("@nuevos", res.Nuevos)
                    cmd.Parameters.AddWithValue("@actualizados", res.Actualizados)
                    cmd.Parameters.AddWithValue("@errores", res.Errores)
                    cmd.Parameters.AddWithValue("@ultima_pagina_ok", res.UltimaPaginaOk)
                    cmd.Parameters.AddWithValue("@estado", estado)
                    cmd.Parameters.AddWithValue("@log_resumen", If(res.Log = "", CObj(DBNull.Value), CObj(res.Log)))
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR FinalizarSync: " & ex.Message)
        End Try
    End Sub

    ' Recalcula la capa B (clientes + RFM) desde el espejo
    Public Shared Function RecalcularClientes() As Integer
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_CRM_sp_RecalcularClientes", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.CommandTimeout = 300
                    Dim r As Object = cmd.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then Return CInt(r)
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR RecalcularClientes: " & ex.Message)
        End Try
        Return 0
    End Function

    Private Shared Function Trunc(s As String, n As Integer) As String
        If s Is Nothing Then Return ""
        If s.Length <= n Then Return s
        Return s.Substring(0, n)
    End Function

End Class
