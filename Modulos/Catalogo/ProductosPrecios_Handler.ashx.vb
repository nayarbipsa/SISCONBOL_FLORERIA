Imports System.Data
Imports System.Data.SqlClient
Imports System.IO
Imports System.Net
Imports System.Text
Imports System.Web
Imports System.Web.Script.Serialization

' ============================================================
' SISCONBOL_FLORERIA - ProductosPrecios_Handler
'
' Procesa UN producto a la vez (llamado via AJAX desde
' ProductosPrecios.aspx). Cada llamada:
'   1. Abre conexion SQL solo para leer datos del producto
'    2. Cierra conexion
'    3. Hace PUT a WooCommerce (esta es la parte que tarda)
'    4. Si WC respondio OK -> abre conexion SQL para UPDATE
'    5. Si WC fallo -> NO toca la BD, retorna error
'
' Asi se cumple:
'   - "Primero WC, despues BD"
'   - "Una conexion por producto" (no se mantiene conexion abierta
'     mientras WC tarda)
' ============================================================
Public Class ProductosPrecios_Handler
    Implements IHttpHandler, SessionState.IRequiresSessionState

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)

        ' Verificar sesion
        If Not SesionHelper.VerificarSesion(context) Then
            context.Response.StatusCode = 401
            EscribirJson(context, False, "Sesion expirada")
            Return
        End If

        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(context)
        If uid <= 0 Then
            EscribirJson(context, False, "Usuario no identificado")
            Return
        End If

        ' Leer parametros
        Dim pidStr As String = LeerForm(context, "producto_id")
        Dim precioStr As String = LeerForm(context, "precio_base_bs")

        Dim pid As Integer = 0
        If Not Integer.TryParse(pidStr, pid) OrElse pid <= 0 Then
            EscribirJson(context, False, "producto_id invalido")
            Return
        End If

        ' Aceptar tanto "150.50" como "150,50"
        Dim precioNorm As String = precioStr
        If precioNorm IsNot Nothing Then
            precioNorm = precioNorm.Replace(",", ".").Trim()
        End If
        Dim precio As Decimal = 0
        If Not Decimal.TryParse(precioNorm,
                                System.Globalization.NumberStyles.Number,
                                System.Globalization.CultureInfo.InvariantCulture,
                                precio) OrElse precio <= 0 Then
            EscribirJson(context, False, "Precio invalido")
            Return
        End If

        ' Limitar a 2 decimales
        precio = Math.Round(precio, 2)

        ' --------------------------------------------------------
        ' PASO 1: leer datos del producto (conexion corta)
        ' --------------------------------------------------------
        Dim wcProductId As Integer = 0
        Dim nombre As String = ""
        Dim descripcion As String = ""
        Dim activo As Boolean = True
        Dim imagenUrl As String = ""
        Dim precioPromoBs As Decimal = 0
        Dim promoDesde As Object = Nothing
        Dim promoHasta As Object = Nothing
        Dim precioActual As Decimal = 0

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand(
                    "SELECT wc_product_id, nombre, descripcion, activo, imagen_url, " &
                    "       precio_base_bs, precio_promo_bs, promo_desde, promo_hasta " &
                    "FROM FLORERIA_Producto WHERE producto_id = @pid", conn)
                    cmd.Parameters.AddWithValue("@pid", pid)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If Not dr.Read() Then
                            EscribirJson(context, False, "Producto no existe")
                            Return
                        End If
                        wcProductId = If(IsDBNull(dr("wc_product_id")), 0, CInt(dr("wc_product_id")))
                        nombre = dr("nombre").ToString()
                        descripcion = If(IsDBNull(dr("descripcion")), "", dr("descripcion").ToString())
                        activo = CBool(dr("activo"))
                        imagenUrl = If(IsDBNull(dr("imagen_url")), "", dr("imagen_url").ToString())
                        precioActual = CDec(dr("precio_base_bs"))
                        precioPromoBs = If(IsDBNull(dr("precio_promo_bs")), 0D, CDec(dr("precio_promo_bs")))
                        promoDesde = If(IsDBNull(dr("promo_desde")), Nothing, dr("promo_desde"))
                        promoHasta = If(IsDBNull(dr("promo_hasta")), Nothing, dr("promo_hasta"))
                    End Using
                End Using
            End Using
        Catch ex As Exception
            EscribirJson(context, False, "Error BD lectura: " & ex.Message)
            Return
        End Try

        If wcProductId <= 0 Then
            EscribirJson(context, False, "Producto sin wc_product_id - no se puede sincronizar")
            Return
        End If

        ' Validar promo activa
        If precioPromoBs > 0 AndAlso promoDesde IsNot Nothing AndAlso promoHasta IsNot Nothing Then
            Dim hoy As Date = Date.Today
            Dim desde As Date = CDate(promoDesde)
            Dim hasta As Date = CDate(promoHasta)
            If hoy >= desde AndAlso hoy <= hasta AndAlso precioPromoBs >= precio Then
                EscribirJson(context, False,
                             "El nuevo precio (" & precio.ToString("F2") &
                             ") debe ser mayor al precio promo vigente (" &
                             precioPromoBs.ToString("F2") & ").")
                Return
            End If
        End If

        ' Si no hay cambio, salir OK
        If precioActual = precio Then
            EscribirJson(context, True, "Sin cambios")
            Return
        End If

        ' --------------------------------------------------------
        ' PASO 2: leer credenciales WC (conexion corta)
        ' --------------------------------------------------------
        Dim wcUrl As String = ObtenerConfig("WC_URL")
        Dim wcKey As String = ObtenerConfig("WC_CONSUMER_KEY")
        Dim wcSecret As String = ObtenerConfig("WC_CONSUMER_SECRET")
        Dim syncActivo As String = ObtenerConfig("SYNC_ACTIVO")

        If syncActivo <> "1" Then
            EscribirJson(context, False, "Sincronizacion WC desactivada en configuracion")
            Return
        End If
        If wcUrl = "" OrElse wcKey = "" OrElse wcSecret = "" Then
            EscribirJson(context, False, "Credenciales WC no configuradas")
            Return
        End If

        ' --------------------------------------------------------
        ' PASO 3: PUT a WooCommerce (esta es la parte lenta -
        ' aqui NO hay conexion SQL abierta)
        ' --------------------------------------------------------
        Dim wcOk As Boolean = False
        Dim wcMsg As String = ""

        Try
            ' Determinar si la promo esta vigente para el JSON
            Dim promoActiva As Boolean = False
            If precioPromoBs > 0 AndAlso promoDesde IsNot Nothing AndAlso promoHasta IsNot Nothing Then
                Dim hoy As Date = Date.Today
                Dim desde As Date = CDate(promoDesde)
                Dim hasta As Date = CDate(promoHasta)
                If hoy >= desde AndAlso hoy <= hasta Then promoActiva = True
            End If

            ' JSON minimo: solo el campo que cambia
            Dim sb As New StringBuilder()
            sb.Append("{")
            sb.Append("""regular_price"":""" & precio.ToString("F2", System.Globalization.CultureInfo.InvariantCulture) & """")
            If promoActiva Then
                sb.Append(",""sale_price"":""" & precioPromoBs.ToString("F2", System.Globalization.CultureInfo.InvariantCulture) & """")
            End If
            sb.Append("}")
            Dim bodyJson As String = sb.ToString()

            Dim apiUrl As String = wcUrl.TrimEnd("/"c) & "/wp-json/wc/v3/products/" & wcProductId

            ' Permitir SSL self-signed por si el servidor lo tiene mal
            ServicePointManager.ServerCertificateValidationCallback = Function(s, c, ch, e) True

            Dim req As HttpWebRequest = CType(WebRequest.Create(apiUrl), HttpWebRequest)
            req.Method = "PUT"
            req.ContentType = "application/json"
            req.Timeout = 55000  ' 55s (el JS espera 60s)
            req.ReadWriteTimeout = 55000

            Dim cred As String = Convert.ToBase64String(Encoding.UTF8.GetBytes(wcKey & ":" & wcSecret))
            req.Headers.Add("Authorization", "Basic " & cred)

            Dim bodyBytes() As Byte = Encoding.UTF8.GetBytes(bodyJson)
            req.ContentLength = bodyBytes.Length
            Using stream As Stream = req.GetRequestStream()
                stream.Write(bodyBytes, 0, bodyBytes.Length)
            End Using

            Using resp As HttpWebResponse = CType(req.GetResponse(), HttpWebResponse)
                Using sr As New StreamReader(resp.GetResponseStream())
                    Dim respJson As String = sr.ReadToEnd()
                    ' WC retorna el producto entero con su "id". Si trae id -> OK
                    Try
                        Dim ser As New JavaScriptSerializer()
                        Dim d As Dictionary(Of String, Object) = ser.Deserialize(Of Dictionary(Of String, Object))(respJson)
                        If d IsNot Nothing AndAlso d.ContainsKey("id") AndAlso CInt(d("id")) = wcProductId Then
                            wcOk = True
                        Else
                            wcMsg = "Respuesta WC sin id valido"
                        End If
                    Catch
                        ' Aun asi, si HTTP 200 lo consideramos exito basico
                        If respJson.Contains("""id"":") Then
                            wcOk = True
                        Else
                            wcMsg = "Respuesta WC no parseable"
                        End If
                    End Try
                End Using
            End Using

        Catch ex As WebException
            Dim detalle As String = ex.Message
            Try
                If ex.Response IsNot Nothing Then
                    Using sr As New StreamReader(ex.Response.GetResponseStream())
                        detalle = sr.ReadToEnd()
                    End Using
                End If
            Catch
            End Try
            ' Limitar tamaño del mensaje
            If detalle.Length > 200 Then detalle = detalle.Substring(0, 200)
            wcMsg = "Error WC: " & detalle
        Catch ex As Exception
            wcMsg = "Error WC: " & ex.Message
        End Try

        ' Si WC fallo -> NO tocar BD
        If Not wcOk Then
            ' Marcar como ERROR en BD para que se vea en la tabla
            MarcarSyncError(pid)
            EscribirJson(context, False, wcMsg)
            Return
        End If

        ' --------------------------------------------------------
        ' PASO 4: WC respondio OK -> ahora si actualizar BD
        ' (conexion corta)
        ' --------------------------------------------------------
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Producto_ActualizarPrecio", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@producto_id", pid)
                    cmd.Parameters.AddWithValue("@precio_base_bs", precio)
                    cmd.Parameters.AddWithValue("@modificado_por", uid)
                    cmd.Parameters.AddWithValue("@motivo", "Modificacion masiva de precios")

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Dim ok As Boolean = (CInt(dr("ok")) = 1)
                            Dim msg As String = dr("mensaje").ToString()
                            If Not ok Then
                                ' Caso raro: WC ya se actualizo pero el SP rechazo
                                EscribirJson(context, False,
                                             "WC actualizado pero BD rechazo: " & msg)
                                Return
                            End If
                        End If
                    End Using
                End Using

                ' Marcar como SINCRONIZADO porque WC ya confirmo
                Using cmd2 As New SqlCommand("FLORERIA_sp_Producto_MarcarSincronizado", conn)
                    cmd2.CommandType = CommandType.StoredProcedure
                    cmd2.Parameters.AddWithValue("@producto_id", pid)
                    cmd2.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            EscribirJson(context, False,
                         "WC actualizado pero error al guardar en BD: " & ex.Message)
            Return
        End Try

        EscribirJson(context, True, "Actualizado en WC y BD")
    End Sub

    ' ============================================================
    ' HELPERS
    ' ============================================================
    Private Sub MarcarSyncError(pid As Integer)
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand(
                    "UPDATE FLORERIA_Producto SET wc_sync_estado='ERROR', wc_sync_fecha=GETDATE() " &
                    "WHERE producto_id=@pid", conn)
                    cmd.Parameters.AddWithValue("@pid", pid)
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR MarcarSyncError: " & ex.Message)
        End Try
    End Sub

    Private Function ObtenerConfig(clave As String) As String
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand(
                    "SELECT valor FROM FLORERIA_Config WHERE clave=@c AND activo=1", conn)
                    cmd.Parameters.AddWithValue("@c", clave)
                    Dim v As Object = cmd.ExecuteScalar()
                    If v IsNot Nothing AndAlso Not IsDBNull(v) Then Return v.ToString()
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ObtenerConfig: " & ex.Message)
        End Try
        Return ""
    End Function

    Private Function LeerForm(context As HttpContext, clave As String) As String
        Dim v As String = context.Request.Form(clave)
        If v Is Nothing Then v = ""
        Return v.Trim()
    End Function

    Private Sub EscribirJson(context As HttpContext, ok As Boolean, mensaje As String)
        Dim msgEsc As String = mensaje
        If msgEsc Is Nothing Then msgEsc = ""
        msgEsc = msgEsc.Replace("\", "\\").Replace("""", "\""").Replace(Chr(13), " ").Replace(Chr(10), " ")
        Dim okStr As String = "false"
        If ok Then okStr = "true"
        context.Response.Write("{""ok"":" & okStr & ",""mensaje"":""" & msgEsc & """}")
    End Sub

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
