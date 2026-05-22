Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web
Imports System.IO
Imports System.Net
Imports System.Web.Script.Serialization

Partial Public Class Modulos_Catalogo_ProductoEditar
    Inherits System.Web.UI.Page

    Public Property ScriptOnLoad As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Dim idStr As String = Request.QueryString("id")
            If idStr Is Nothing Then idStr = "0"
            Dim pid As Integer = 0
            Integer.TryParse(idStr, pid)
            
            If pid > 0 Then
                CargarProducto(pid)
            Else
                ScriptOnLoad = "document.getElementById('spTitulo').textContent='Nuevo producto';"
            End If
        End If
    End Sub

    Private Function ObtenerCadena() As String
        Return SesionHelper.ObtenerCadena()
    End Function

    Private Function ObtenerUid() As Integer
        Return SesionHelper.ObtenerUsuarioId(HttpContext.Current)
    End Function

    Private Function Limpiar(v As String) As String
        If v Is Nothing Then Return ""
        Return v.Trim().Replace("<", "").Replace(">", "").Replace("'", "").Replace("""", "")
    End Function

    Private Sub CargarProducto(pid As Integer)
        Dim sb As New StringBuilder()
        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Producto_ObtenerPorId", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@producto_id", pid)
                    
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Dim nom As String = Limpiar(dr("nombre").ToString())
                            Dim desc As String = Limpiar(If(IsDBNull(dr("descripcion")), "", dr("descripcion").ToString()))
                            Dim pBS As String = dr("precio_base_bs").ToString()
                            Dim promoBS As String = If(IsDBNull(dr("precio_promo_bs")), "", dr("precio_promo_bs").ToString())
                            Dim promoDes As String = ""
                            Dim promoHas As String = ""
                            
                            If Not IsDBNull(dr("promo_desde")) Then
                                promoDes = CDate(dr("promo_desde")).ToString("yyyy-MM-dd")
                            End If
                            If Not IsDBNull(dr("promo_hasta")) Then
                                promoHas = CDate(dr("promo_hasta")).ToString("yyyy-MM-dd")
                            End If
                            
                            Dim activo As String = If(CBool(dr("activo")), "true", "false")
                            Dim wcId As String = ""
                            Dim wcSync As String = "PENDIENTE"
                            Dim wcFecha As String = ""
                            Dim imgUrl As String = ""
                            
                            If Not IsDBNull(dr("wc_product_id")) Then wcId = dr("wc_product_id").ToString()
                            If Not IsDBNull(dr("wc_sync_estado")) Then wcSync = dr("wc_sync_estado").ToString()
                            If Not IsDBNull(dr("wc_sync_fecha")) Then wcFecha = CDate(dr("wc_sync_fecha")).ToString("dd/MM/yyyy HH:mm")
                            If Not IsDBNull(dr("imagen_url")) Then imgUrl = dr("imagen_url").ToString()

                            sb.Append("document.getElementById('spTitulo').textContent='" & nom & "';")
                            sb.Append("setVal('txNombre','" & nom & "');")
                            sb.Append("setVal('txDesc','" & desc.Replace(vbCrLf, " ").Replace(vbLf, " ") & "');")
                            sb.Append("setVal('txPrecioBS','" & pBS & "');")
                            sb.Append("setChk('chkActivo'," & activo & ");")
                            sb.Append("setHd('hdProductoId','" & pid & "');")

                            If promoBS <> "" AndAlso promoDes <> "" AndAlso promoHas <> "" Then
                                sb.Append("var chkP=document.getElementById('chkPromo');")
                                sb.Append("if(chkP){chkP.checked=true;togglePromo();}")
                                sb.Append("setVal('txPromoBS','" & promoBS & "');")
                                sb.Append("setVal('txPromoDesde','" & promoDes & "');")
                                sb.Append("setVal('txPromoHasta','" & promoHas & "');")
                                sb.Append("calcPromo();")
                            End If

                            If imgUrl <> "" Then
                                sb.Append("var img=document.getElementById('imgPreview');")
                                sb.Append("var divPrev=document.getElementById('divImgPreview');")
                                sb.Append("var divPlace=document.getElementById('divImgPlaceholder');")
                                sb.Append("if(img){img.src='" & imgUrl & "';}")
                                sb.Append("if(divPrev){divPrev.style.display='block';}")
                                sb.Append("if(divPlace){divPlace.style.display='none';}")
                                sb.Append("var bc=document.getElementById('btnCambiarImg');")
                                sb.Append("var bq=document.getElementById('btnQuitarImg');")
                                sb.Append("if(bc){bc.style.display='inline-flex';}")
                                sb.Append("if(bq){bq.style.display='inline-flex';}")
                            End If

                            Dim wcBadge As String = ""
                            Dim wcTexto As String = ""
                            Select Case wcSync.ToUpper()
                                Case "SINCRONIZADO"
                                    wcBadge = "badge-sync-ok"
                                    wcTexto = "Sincronizado"
                                Case "PENDIENTE"
                                    wcBadge = "badge-sync-pend"
                                    wcTexto = "Pendiente"
                                Case "ERROR"
                                    wcBadge = "badge-sync-error"
                                    wcTexto = "Error"
                                Case Else
                                    wcBadge = "badge-sync-none"
                                    wcTexto = "Sin sincronizar"
                            End Select

                            sb.Append("var divWc=document.getElementById('divWcInfo');")
                            sb.Append("if(divWc){")
                            sb.Append("divWc.innerHTML='<p style=""font-size:12px;margin-bottom:6px"">Estado: <span class=""badge " & wcBadge & """>" & wcTexto & "</span></p>';")
                            If wcId <> "" Then
                                sb.Append("divWc.innerHTML+='<p style=""font-size:11px;color:#757575"">WC ID: " & wcId & "</p>';")
                            End If
                            If wcFecha <> "" Then
                                sb.Append("divWc.innerHTML+='<p style=""font-size:11px;color:#757575"">Última sync: " & wcFecha & "</p>';")
                            End If
                            sb.Append("}")
                            
                            sb.Append("var btnSync=document.getElementById('btnSincWc');")
                            sb.Append("if(btnSync){btnSync.disabled=false;}")
                        End If
                    End Using
                End Using
            End Using
            
            ScriptOnLoad = sb.ToString()
            
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR CargarProducto: " & ex.Message)
        End Try
    End Sub

    Protected Sub btnGuardar_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim uid As Integer = ObtenerUid()
        Dim pidStr As String = Request.Form("hdProductoId")
        If pidStr Is Nothing Then pidStr = "0"
        Dim pid As Integer = 0
        Integer.TryParse(pidStr, pid)

        Dim nombre As String = Limpiar(Request.Form("hdNombre"))
        Dim desc As String = Limpiar(Request.Form("hdDesc"))
        Dim pBSStr As String = Request.Form("hdPrecioBS")
        Dim promoActiva As String = Request.Form("hdPromoActiva")
        Dim promoBSStr As String = Request.Form("hdPromoBS")
        Dim promoDes As String = Request.Form("hdPromoDesde")
        Dim promoHas As String = Request.Form("hdPromoHasta")
        Dim activoStr As String = Request.Form("hdActivo")
        Dim imgBase64 As String = Request.Form("hdImagenBase64")
        Dim imgNombre As String = Request.Form("hdImagenNombre")

        If pBSStr Is Nothing Then pBSStr = "0"
        If promoBSStr Is Nothing Then promoBSStr = ""
        If promoDes Is Nothing Then promoDes = ""
        If promoHas Is Nothing Then promoHas = ""
        If activoStr Is Nothing Then activoStr = "1"
        If promoActiva Is Nothing Then promoActiva = "0"
        If imgBase64 Is Nothing Then imgBase64 = ""
        If imgNombre Is Nothing Then imgNombre = ""

        Dim precD As Decimal = 0
        Decimal.TryParse(pBSStr, precD)
        
        Dim promoD As Object = DBNull.Value
        Dim pdesD As Object = DBNull.Value
        Dim phasD As Object = DBNull.Value
        
        If promoActiva = "1" AndAlso promoBSStr <> "" Then
            Dim tmp As Decimal = 0
            If Decimal.TryParse(promoBSStr, tmp) Then promoD = tmp
        End If
        If promoActiva = "1" AndAlso promoDes <> "" Then
            Dim tmpD As Date
            If Date.TryParse(promoDes, tmpD) Then pdesD = tmpD
        End If
        If promoActiva = "1" AndAlso promoHas <> "" Then
            Dim tmpD As Date
            If Date.TryParse(promoHas, tmpD) Then phasD = tmpD
        End If
        
        Dim activo As Integer = If(activoStr = "1", 1, 0)
        Dim uidP As Object = If(uid > 0, CObj(uid), CObj(DBNull.Value))

        Dim imgUrlFinal As String = ""
        If imgBase64 <> "" AndAlso imgNombre <> "" Then
            imgUrlFinal = GuardarImagenFisica(pid, imgBase64, imgNombre)
        End If

        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()

                If pid > 0 Then
                    Using cmd As New SqlCommand("FLORERIA_sp_Producto_Actualizar", conn)
                        cmd.CommandType = CommandType.StoredProcedure
                        cmd.Parameters.AddWithValue("@producto_id", pid)
                        cmd.Parameters.AddWithValue("@sku", "PROD-" & pid)
                        cmd.Parameters.AddWithValue("@nombre", nombre)
                        cmd.Parameters.AddWithValue("@descripcion", If(desc = "", CObj(DBNull.Value), desc))
                        cmd.Parameters.AddWithValue("@categoria_id", DBNull.Value)
                        cmd.Parameters.AddWithValue("@precio_base_bs", precD)
                        cmd.Parameters.AddWithValue("@precio_base_usd", DBNull.Value)
                        cmd.Parameters.AddWithValue("@precio_promo_bs", promoD)
                        cmd.Parameters.AddWithValue("@precio_promo_usd", DBNull.Value)
                        cmd.Parameters.AddWithValue("@promo_desde", pdesD)
                        cmd.Parameters.AddWithValue("@promo_hasta", phasD)
                        cmd.Parameters.AddWithValue("@tiene_variaciones", 0)
                        cmd.Parameters.AddWithValue("@destacado", 0)
                        cmd.Parameters.AddWithValue("@menu_order", 0)
                        cmd.Parameters.AddWithValue("@notas_internas", DBNull.Value)
                        cmd.Parameters.AddWithValue("@stock_actual", 0)
                        cmd.Parameters.AddWithValue("@stock_minimo", 5)
                        cmd.Parameters.AddWithValue("@imagen_url", If(imgUrlFinal = "", CObj(DBNull.Value), imgUrlFinal))
                        cmd.Parameters.AddWithValue("@activo", activo)
                        cmd.Parameters.AddWithValue("@modificado_por", uidP)
                        cmd.ExecuteNonQuery()
                    End Using
                Else
                    Using cmd As New SqlCommand("FLORERIA_sp_Producto_Crear", conn)
                        cmd.CommandType = CommandType.StoredProcedure
                        cmd.Parameters.AddWithValue("@sku", "PROD-NEW")
                        cmd.Parameters.AddWithValue("@nombre", nombre)
                        cmd.Parameters.AddWithValue("@descripcion", If(desc = "", CObj(DBNull.Value), desc))
                        cmd.Parameters.AddWithValue("@categoria_id", DBNull.Value)
                        cmd.Parameters.AddWithValue("@precio_base_bs", precD)
                        cmd.Parameters.AddWithValue("@precio_base_usd", DBNull.Value)
                        cmd.Parameters.AddWithValue("@precio_promo_bs", promoD)
                        cmd.Parameters.AddWithValue("@precio_promo_usd", DBNull.Value)
                        cmd.Parameters.AddWithValue("@promo_desde", pdesD)
                        cmd.Parameters.AddWithValue("@promo_hasta", phasD)
                        cmd.Parameters.AddWithValue("@tiene_variaciones", 0)
                        cmd.Parameters.AddWithValue("@destacado", 0)
                        cmd.Parameters.AddWithValue("@menu_order", 0)
                        cmd.Parameters.AddWithValue("@notas_internas", DBNull.Value)
                        cmd.Parameters.AddWithValue("@stock_actual", 0)
                        cmd.Parameters.AddWithValue("@stock_minimo", 5)
                        cmd.Parameters.AddWithValue("@imagen_url", If(imgUrlFinal = "", CObj(DBNull.Value), imgUrlFinal))
                        cmd.Parameters.AddWithValue("@activo", activo)
                        cmd.Parameters.AddWithValue("@creado_por", uidP)
                        
                        Dim pidNew As Object = cmd.ExecuteScalar()
                        If pidNew IsNot Nothing Then
                            pid = CInt(pidNew)
                            Using cmdUpd As New SqlCommand("UPDATE FLORERIA_Producto SET sku='PROD-" & pid & "' WHERE producto_id=@p", conn)
                                cmdUpd.Parameters.AddWithValue("@p", pid)
                                cmdUpd.ExecuteNonQuery()
                            End Using
                        End If
                    End Using
                End If
            End Using

            Response.Redirect("/Modulos/Catalogo/Productos.aspx")
            
        Catch ex As Exception
            ScriptOnLoad = "mostrarAlerta('Error al guardar: " & ex.Message.Replace("'", "").Replace("""", "").Substring(0, Math.Min(100, ex.Message.Length)) & "', 'error');"
            System.Diagnostics.Debug.WriteLine("ERROR Guardar: " & ex.Message)
        End Try
    End Sub

    Private Function GuardarImagenFisica(pid As Integer, base64 As String, nombreArchivo As String) As String
        Try
            Dim ext As String = Path.GetExtension(nombreArchivo).ToLower()
            If ext <> ".jpg" AndAlso ext <> ".jpeg" AndAlso ext <> ".png" AndAlso ext <> ".webp" Then
                Return ""
            End If
            
            Dim carpeta As String = Server.MapPath("~/Imagenes/Productos/")
            If Not Directory.Exists(carpeta) Then Directory.CreateDirectory(carpeta)
            
            Dim archivo As String = "prod_" & pid & "_" & DateTime.Now.Ticks & ext
            Dim ruta As String = Path.Combine(carpeta, archivo)
            Dim bytes() As Byte = Convert.FromBase64String(base64)
            File.WriteAllBytes(ruta, bytes)
            
            Return "/Imagenes/Productos/" & archivo
            
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR GuardarImagen: " & ex.Message)
            Return ""
        End Try
    End Function

    Protected Sub btnSincronizar_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim pidStr As String = Request.Form("hdProductoId")
        If pidStr Is Nothing Then pidStr = "0"
        Dim pid As Integer = 0
        Integer.TryParse(pidStr, pid)
        If pid = 0 Then Return
        
        Try
            Dim resultado As Dictionary(Of String, Object) = SincronizarProductoWC(pid)
            
            If CBool(resultado("ok")) Then
                ScriptOnLoad = "mostrarAlerta('Producto sincronizado con WooCommerce', 'success');"
            Else
                Dim msg As String = resultado("mensaje").ToString().Replace("'", "").Replace("""", "")
                ScriptOnLoad = "mostrarAlerta('Error: " & msg & "', 'error');"
            End If
            
            CargarProducto(pid)
            
        Catch ex As Exception
            ScriptOnLoad = "mostrarAlerta('Error al sincronizar: " & ex.Message.Replace("'", "").Replace("""", "") & "', 'error');"
            System.Diagnostics.Debug.WriteLine("ERROR Sincronizar: " & ex.Message)
        End Try
    End Sub

    Private Function SincronizarProductoWC(productoId As Integer) As Dictionary(Of String, Object)
        Dim resultado As New Dictionary(Of String, Object)
        resultado("ok") = False
        resultado("mensaje") = ""

        Try
            Dim syncActivo As String = ObtenerConfigWC("SYNC_ACTIVO")
            If syncActivo <> "1" Then
                resultado("mensaje") = "Sincronización desactivada"
                Return resultado
            End If

            Dim wcUrl As String = ObtenerConfigWC("WC_URL")
            Dim wcKey As String = ObtenerConfigWC("WC_CONSUMER_KEY")
            Dim wcSecret As String = ObtenerConfigWC("WC_CONSUMER_SECRET")

            Dim producto As Dictionary(Of String, Object) = ObtenerProductoParaWC(productoId)
            If producto Is Nothing Then
                resultado("mensaje") = "Producto no encontrado"
                Return resultado
            End If

            Dim wcProductId As Integer = If(producto.ContainsKey("wc_product_id"), CInt(producto("wc_product_id")), 0)
            Dim metodo As String = If(wcProductId > 0, "PUT", "POST")
            Dim endpoint As String = "/products"
            If wcProductId > 0 Then endpoint &= "/" & wcProductId

            Dim url As String = wcUrl & "/wp-json/wc/v3" & endpoint
            Dim request As HttpWebRequest = CType(WebRequest.Create(url), HttpWebRequest)
            request.Method = metodo
            request.ContentType = "application/json"

            Dim credentials As String = wcKey & ":" & wcSecret
            Dim credBytes() As Byte = Encoding.UTF8.GetBytes(credentials)
            Dim credBase64 As String = Convert.ToBase64String(credBytes)
            request.Headers.Add("Authorization", "Basic " & credBase64)

            Dim jsonData As String = ConstruirJsonProductoWC(producto, wcUrl)

            Using sw As New StreamWriter(request.GetRequestStream())
                sw.Write(jsonData)
            End Using

            Using response As HttpWebResponse = CType(request.GetResponse(), HttpWebResponse)
                Using sr As New StreamReader(response.GetResponseStream())
                    Dim respuesta As String = sr.ReadToEnd()
                    Dim serializer As New JavaScriptSerializer()
                    Dim wcResp As Dictionary(Of String, Object) = serializer.Deserialize(Of Dictionary(Of String, Object))(respuesta)

                    If wcResp.ContainsKey("id") Then
                        wcProductId = CInt(wcResp("id"))
                        ActualizarSyncProducto(productoId, wcProductId, "SINCRONIZADO")
                        resultado("ok") = True
                        resultado("mensaje") = "Sincronizado"
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
            ActualizarSyncProducto(productoId, 0, "ERROR")
            resultado("mensaje") = errorMsg.Substring(0, Math.Min(100, errorMsg.Length))

        Catch ex As Exception
            ActualizarSyncProducto(productoId, 0, "ERROR")
            resultado("mensaje") = ex.Message
        End Try

        Return resultado
    End Function

    Private Function ObtenerConfigWC(clave As String) As String
        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("SELECT valor FROM FLORERIA_Config WHERE clave=@c AND activo=1", conn)
                    cmd.Parameters.AddWithValue("@c", clave)
                    Dim val As Object = cmd.ExecuteScalar()
                    If val IsNot Nothing Then Return val.ToString()
                End Using
            End Using
        Catch
        End Try
        Return ""
    End Function

    Private Function ObtenerProductoParaWC(productoId As Integer) As Dictionary(Of String, Object)
        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Producto_ObtenerPorId", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@producto_id", productoId)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Dim p As New Dictionary(Of String, Object)()
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
        Catch
        End Try
        Return Nothing
    End Function

    Private Function ConstruirJsonProductoWC(producto As Dictionary(Of String, Object), wcUrl As String) As String
        Dim sb As New StringBuilder()
        sb.Append("{")
        sb.Append("""name"":""" & EscaparJsonWC(producto("nombre").ToString()) & """,")
        sb.Append("""description"":""" & EscaparJsonWC(producto("descripcion").ToString()) & """,")

        Dim precioBase As Decimal = CDec(producto("precio_base_bs"))
        Dim precioPromo As Decimal = CDec(producto("precio_promo_bs"))

        Dim promoActiva As Boolean = False
        If precioPromo > 0 AndAlso producto("promo_desde") IsNot Nothing AndAlso producto("promo_hasta") IsNot Nothing Then
            Dim hoy As Date = Date.Today
            Dim desde As Date = CDate(producto("promo_desde"))
            Dim hasta As Date = CDate(producto("promo_hasta"))
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
                imagenUrl = wcUrl & imagenUrl
            End If
            sb.Append("""images"":[{""src"":""" & imagenUrl & """}],")
        End If

        If sb.Length > 1 AndAlso sb(sb.Length - 1) = ","c Then sb.Length -= 1
        sb.Append("}")
        Return sb.ToString()
    End Function

    Private Function EscaparJsonWC(texto As String) As String
        If texto Is Nothing Then Return ""
        Return texto.Replace("\", "\\").Replace("""", "\""").Replace(vbCr, "").Replace(vbLf, "\n").Replace(vbTab, " ")
    End Function

    Private Sub ActualizarSyncProducto(productoId As Integer, wcProductId As Integer, estado As String)
        Try
            Using conn As New SqlConnection(ObtenerCadena())
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
        Catch
        End Try
    End Sub

End Class
