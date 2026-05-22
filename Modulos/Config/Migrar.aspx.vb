Imports System.Data
Imports System.Data.SqlClient
Imports System.Net
Imports System.IO
Imports System.Web
Imports System.Text

Partial Public Class Modulos_Config_Migrar
    Inherits System.Web.UI.Page

    ' Propiedades públicas para exponer a JavaScript
    Public Property WcUrl As String = ""
    Public Property WcConsumerKey As String = ""
    Public Property WcConsumerSecret As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' La verificación de sesión la hace Site.Master
        
        If Not IsPostBack Then
            CargarConfiguracion()
        End If
    End Sub

    Private Sub CargarConfiguracion()
        WcUrl = ValorConfig("WC_URL")
        WcConsumerKey = ValorConfig("WC_CONSUMER_KEY")
        WcConsumerSecret = ValorConfig("WC_CONSUMER_SECRET")
        
        ' Validar que las credenciales estén configuradas
        If WcUrl = "" OrElse WcConsumerKey = "" OrElse WcConsumerSecret = "" Then
            Dim js As String = "mostrarAlerta(" &
                "'Configura las credenciales de WooCommerce primero en Configuración > Configuración.', " &
                "'warn');"
            ClientScript.RegisterStartupScript(Me.GetType(), "alertaConfig", js, True)
        End If
    End Sub

    Private Function ValorConfig(ByVal clave As String) As String
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Config_Obtener", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@clave", clave)
                    Dim r As Object = cmd.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then
                        Return r.ToString()
                    End If
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ValorConfig: " & ex.Message)
        End Try
        Return ""
    End Function

    Protected Sub btnAccion_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""
        
        Select Case accion
            Case "INSERTAR_CATEGORIAS" : ProcesarCategorias()
            Case "INSERTAR_PRODUCTOS" : ProcesarProductos()
            Case "INSERTAR_PEDIDOS" : ProcesarPedidos()
        End Select
    End Sub

    Private Sub ProcesarCategorias()
        Dim lote As String = Request.Form("hdLote")
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        
        If lote Is Nothing OrElse lote.Trim() = "" Then
            Dim js As String = "mostrarAlerta('No se recibieron datos de categorías desde WooCommerce.', 'error');"
            ClientScript.RegisterStartupScript(Me.GetType(), "rcatsErr", js, True)
            Return
        End If

        Dim ins As Integer = 0, act As Integer = 0, sin As Integer = 0, err As Integer = 0
        Dim logMensajes As New System.Text.StringBuilder()
        
        Try
            Dim cats As List(Of WcCat) = ParsearCats(lote)
            
            If cats.Count = 0 Then
                Dim js As String = "mostrarAlerta('No se encontraron categorías válidas en la respuesta de WooCommerce.', 'warn');"
                ClientScript.RegisterStartupScript(Me.GetType(), "rcatsVacio", js, True)
                Return
            End If
            
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                For Each c In cats
                    Try
                        Dim r As String = InsertarCat(conn, c, uid)
                        If r = "I" Then
                            ins += 1
                            logMensajes.AppendLine("✓ Insertada: " & c.Nombre)
                        ElseIf r = "A" Then
                            act += 1
                            logMensajes.AppendLine("↻ Actualizada: " & c.Nombre)
                        ElseIf r = "S" Then
                            sin += 1
                        ElseIf r = "E" Then
                            err += 1
                            logMensajes.AppendLine("✗ Error: " & c.Nombre)
                        End If
                    Catch ex As Exception
                        err += 1
                        logMensajes.AppendLine("✗ Error en " & c.Nombre & ": " & ex.Message)
                        System.Diagnostics.Debug.WriteLine("ERROR Cat " & c.Nombre & ": " & ex.Message)
                    End Try
                Next
            End Using
            
            System.Diagnostics.Debug.WriteLine("MIGRACIÓN CATEGORÍAS - Nuevas: " & ins & ", Actualizadas: " & act & ", Sin cambios: " & sin & ", Errores: " & err)
            
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ProcCats: " & ex.Message)
            Dim js As String = "mostrarAlerta('Error al procesar categorías: " & ex.Message.Replace("'", "") & "', 'error');"
            ClientScript.RegisterStartupScript(Me.GetType(), "rcatsExc", js, True)
            Return
        End Try

        Dim jsResult As String = "mostrarResultadoCats(" & ins & "," & act & "," & sin & "," & err & ");"
        ClientScript.RegisterStartupScript(Me.GetType(), "rcats", jsResult, True)
    End Sub

    Private Sub ProcesarProductos()
        Dim lote As String = Request.Form("hdLote")
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        
        If lote Is Nothing OrElse lote.Trim() = "" Then
            Dim js As String = "mostrarAlerta('No se recibieron datos de productos desde WooCommerce.', 'error');"
            ClientScript.RegisterStartupScript(Me.GetType(), "rprodErr", js, True)
            Return
        End If

        Dim ins As Integer = 0, act As Integer = 0, sin As Integer = 0, err As Integer = 0
        
        Try
            Dim prods As List(Of WcProd) = ParsearProds(lote)
            
            If prods.Count = 0 Then
                Dim js As String = "mostrarAlerta('No se encontraron productos válidos en la respuesta de WooCommerce.', 'warn');"
                ClientScript.RegisterStartupScript(Me.GetType(), "rprodVacio", js, True)
                Return
            End If
            
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                For Each p In prods
                    Try
                        Dim r As String = InsertarProd(conn, p, uid)
                        If r = "I" Then ins += 1
                        If r = "A" Then act += 1
                        If r = "S" Then sin += 1
                        If r = "E" Then err += 1
                    Catch ex As Exception
                        err += 1
                        System.Diagnostics.Debug.WriteLine("ERROR Prod " & p.Nombre & ": " & ex.Message)
                    End Try
                Next
            End Using
            
            System.Diagnostics.Debug.WriteLine("MIGRACIÓN PRODUCTOS - Nuevos: " & ins & ", Actualizados: " & act & ", Sin cambios: " & sin & ", Errores: " & err)
            
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ProcProds: " & ex.Message)
            Dim js As String = "mostrarAlerta('Error al procesar productos: " & ex.Message.Replace("'", "") & "', 'error');"
            ClientScript.RegisterStartupScript(Me.GetType(), "rprodExc", js, True)
            Return
        End Try

        Dim jsResult As String = "mostrarResultadoProd(" & ins & "," & act & "," & sin & "," & err & ");"
        ClientScript.RegisterStartupScript(Me.GetType(), "rprod", jsResult, True)
    End Sub

    Private Sub ProcesarPedidos()
        Dim lote As String = Request.Form("hdLote")
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        
        If lote Is Nothing OrElse lote.Trim() = "" Then
            Dim js As String = "mostrarAlerta('No se recibieron datos de pedidos desde WooCommerce.', 'error');"
            ClientScript.RegisterStartupScript(Me.GetType(), "rpedErr", js, True)
            Return
        End If

        Dim ins As Integer = 0, act As Integer = 0, sin As Integer = 0, err As Integer = 0
        
        Try
            Dim pedidos As List(Of WcPedido) = ParsearPedidos(lote)
            
            If pedidos.Count = 0 Then
                Dim js As String = "mostrarAlerta('No se encontraron pedidos válidos en la respuesta de WooCommerce. Puede que no haya pedidos en el rango solicitado.', 'info');"
                ClientScript.RegisterStartupScript(Me.GetType(), "rpedVacio", js, True)
                Return
            End If
            
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                For Each p In pedidos
                    Try
                        Dim r As String = InsertarPedido(conn, p, uid)
                        If r = "I" Then ins += 1
                        If r = "A" Then act += 1
                        If r = "S" Then sin += 1
                        If r = "E" Then err += 1
                    Catch ex As Exception
                        err += 1
                        System.Diagnostics.Debug.WriteLine("ERROR InsertarPedido: " & ex.Message)
                    End Try
                Next
            End Using
            
            System.Diagnostics.Debug.WriteLine("MIGRACIÓN PEDIDOS - Nuevos: " & ins & ", Actualizados: " & act & ", Sin cambios: " & sin & ", Errores: " & err)
            
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ProcPedidos: " & ex.Message)
            Dim js As String = "mostrarAlerta('Error al procesar pedidos: " & ex.Message.Replace("'", "") & "', 'error');"
            ClientScript.RegisterStartupScript(Me.GetType(), "rpedExc", js, True)
            Return
        End Try

        Dim jsResult As String = "mostrarResultadoPed(" & ins & "," & act & "," & sin & "," & err & ");"
        ClientScript.RegisterStartupScript(Me.GetType(), "rped", jsResult, True)
    End Sub

    Private Function InsertarCat(conn As SqlConnection, c As WcCat, uid As Integer) As String
        Try
            Dim existe As Object = Nothing
            Using cmd As New SqlCommand("SELECT categoria_id FROM FLORERIA_Categoria WHERE wc_category_id=@w", conn)
                cmd.Parameters.AddWithValue("@w", c.WcId)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then existe = dr("categoria_id")
                End Using
            End Using

            Dim padre As Object = DBNull.Value
            If c.PadreWcId > 0 Then
                Using cmd As New SqlCommand("SELECT categoria_id FROM FLORERIA_Categoria WHERE wc_category_id=@w", conn)
                    cmd.Parameters.AddWithValue("@w", c.PadreWcId)
                    Dim r As Object = cmd.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then
                        padre = CInt(r)
                    End If
                End Using
            End If

            Dim uidP As Object = DBNull.Value
            If uid > 0 Then
                uidP = CObj(uid)
            End If

            If existe IsNot Nothing Then
                Using cmd As New SqlCommand(
                    "UPDATE FLORERIA_Categoria SET nombre=@n,descripcion=@d,padre_id=@p,slug=@s," &
                    "wc_sync_estado='SINCRONIZADO',modificado_por=@u,modificado_en=GETDATE() " &
                    "WHERE categoria_id=@id AND (nombre<>@n OR ISNULL(descripcion,'')<>ISNULL(@d,''))", conn)
                    cmd.Parameters.AddWithValue("@n", c.Nombre)
                    
                    Dim desc As Object = DBNull.Value
                    If c.Descripcion <> "" Then desc = c.Descripcion
                    cmd.Parameters.AddWithValue("@d", desc)
                    
                    cmd.Parameters.AddWithValue("@p", padre)
                    
                    Dim slg As Object = DBNull.Value
                    If c.Slug <> "" Then slg = c.Slug
                    cmd.Parameters.AddWithValue("@s", slg)
                    
                    cmd.Parameters.AddWithValue("@u", uidP)
                    cmd.Parameters.AddWithValue("@id", CInt(existe))
                    
                    If cmd.ExecuteNonQuery() > 0 Then
                        Return "A"
                    Else
                        Return "S"
                    End If
                End Using
            Else
                Using cmd As New SqlCommand(
                    "INSERT INTO FLORERIA_Categoria(padre_id,nombre,descripcion,slug,orden,wc_category_id,wc_sync_estado,creado_por)" &
                    " VALUES(@p,@n,@d,@s,0,@w,'SINCRONIZADO',@u)", conn)
                    cmd.Parameters.AddWithValue("@p", padre)
                    cmd.Parameters.AddWithValue("@n", c.Nombre)
                    
                    Dim desc As Object = DBNull.Value
                    If c.Descripcion <> "" Then desc = c.Descripcion
                    cmd.Parameters.AddWithValue("@d", desc)
                    
                    Dim slg As Object = DBNull.Value
                    If c.Slug <> "" Then slg = c.Slug
                    cmd.Parameters.AddWithValue("@s", slg)
                    
                    cmd.Parameters.AddWithValue("@w", c.WcId)
                    cmd.Parameters.AddWithValue("@u", uidP)
                    cmd.ExecuteNonQuery()
                    Return "I"
                End Using
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR InsertarCat: " & ex.Message)
            Return "E"
        End Try
    End Function

    Private Function InsertarProd(conn As SqlConnection, p As WcProd, uid As Integer) As String
        Try
            Dim existe As Object = Nothing
            Using cmd As New SqlCommand("SELECT producto_id FROM FLORERIA_Producto WHERE wc_product_id=@w", conn)
                cmd.Parameters.AddWithValue("@w", p.WcId)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then existe = dr("producto_id")
                End Using
            End Using

            Dim uidP As Object = DBNull.Value
            If uid > 0 Then uidP = CObj(uid)

            If existe IsNot Nothing Then
                Using cmd As New SqlCommand(
                    "UPDATE FLORERIA_Producto SET nombre=@n,descripcion=@d,precio_base_bs=@pb," &
                    "precio_promo_bs=@pp,promo_desde=@pd,promo_hasta=@ph,destacado=@de,menu_order=@mo," &
                    "imagen_url=@iu,wc_sync_estado='SINCRONIZADO',modificado_por=@u,modificado_en=GETDATE() " &
                    "WHERE producto_id=@id", conn)
                    cmd.Parameters.AddWithValue("@n", p.Nombre)
                    
                    Dim desc As Object = DBNull.Value
                    If p.Descripcion <> "" Then desc = p.Descripcion
                    cmd.Parameters.AddWithValue("@d", desc)
                    
                    Dim pb As Decimal = 0D
                    Decimal.TryParse(p.PrecioBS, pb)
                    cmd.Parameters.AddWithValue("@pb", pb)
                    
                    Dim pp As Object = DBNull.Value
                    If p.PromoBS <> "" Then
                        Dim ppVal As Decimal = 0D
                        If Decimal.TryParse(p.PromoBS, ppVal) Then pp = ppVal
                    End If
                    cmd.Parameters.AddWithValue("@pp", pp)
                    
                    Dim pd As Object = DBNull.Value
                    If p.PromoDesde <> "" Then
                        Dim dtVal As DateTime
                        If DateTime.TryParse(p.PromoDesde, dtVal) Then pd = dtVal
                    End If
                    cmd.Parameters.AddWithValue("@pd", pd)
                    
                    Dim ph As Object = DBNull.Value
                    If p.PromoHasta <> "" Then
                        Dim dtVal As DateTime
                        If DateTime.TryParse(p.PromoHasta, dtVal) Then ph = dtVal
                    End If
                    cmd.Parameters.AddWithValue("@ph", ph)
                    
                    cmd.Parameters.AddWithValue("@de", If(p.Destacado, 1, 0))
                    cmd.Parameters.AddWithValue("@mo", p.MenuOrder)
                    
                    Dim iu As Object = DBNull.Value
                    If p.ImagenUrl <> "" Then iu = p.ImagenUrl
                    cmd.Parameters.AddWithValue("@iu", iu)
                    
                    cmd.Parameters.AddWithValue("@u", uidP)
                    cmd.Parameters.AddWithValue("@id", CInt(existe))
                    
                    If cmd.ExecuteNonQuery() > 0 Then
                        Return "A"
                    Else
                        Return "S"
                    End If
                End Using
            Else
                Using cmd As New SqlCommand(
                    "INSERT INTO FLORERIA_Producto(sku,nombre,descripcion,precio_base_bs,precio_promo_bs," &
                    "promo_desde,promo_hasta,destacado,menu_order,imagen_url,wc_product_id,wc_sync_estado,creado_por)" &
                    " VALUES(@sk,@n,@d,@pb,@pp,@pd,@ph,@de,@mo,@iu,@w,'SINCRONIZADO',@u)", conn)
                    
                    Dim sk As String = p.Sku
                    If sk = "" Then sk = "WC" & p.WcId.ToString()
                    cmd.Parameters.AddWithValue("@sk", sk)
                    
                    cmd.Parameters.AddWithValue("@n", p.Nombre)
                    
                    Dim desc As Object = DBNull.Value
                    If p.Descripcion <> "" Then desc = p.Descripcion
                    cmd.Parameters.AddWithValue("@d", desc)
                    
                    Dim pb As Decimal = 0D
                    Decimal.TryParse(p.PrecioBS, pb)
                    cmd.Parameters.AddWithValue("@pb", pb)
                    
                    Dim pp As Object = DBNull.Value
                    If p.PromoBS <> "" Then
                        Dim ppVal As Decimal = 0D
                        If Decimal.TryParse(p.PromoBS, ppVal) Then pp = ppVal
                    End If
                    cmd.Parameters.AddWithValue("@pp", pp)
                    
                    Dim pd As Object = DBNull.Value
                    If p.PromoDesde <> "" Then
                        Dim dtVal As DateTime
                        If DateTime.TryParse(p.PromoDesde, dtVal) Then pd = dtVal
                    End If
                    cmd.Parameters.AddWithValue("@pd", pd)
                    
                    Dim ph As Object = DBNull.Value
                    If p.PromoHasta <> "" Then
                        Dim dtVal As DateTime
                        If DateTime.TryParse(p.PromoHasta, dtVal) Then ph = dtVal
                    End If
                    cmd.Parameters.AddWithValue("@ph", ph)
                    
                    cmd.Parameters.AddWithValue("@de", If(p.Destacado, 1, 0))
                    cmd.Parameters.AddWithValue("@mo", p.MenuOrder)
                    
                    Dim iu As Object = DBNull.Value
                    If p.ImagenUrl <> "" Then iu = p.ImagenUrl
                    cmd.Parameters.AddWithValue("@iu", iu)
                    
                    cmd.Parameters.AddWithValue("@w", p.WcId)
                    cmd.Parameters.AddWithValue("@u", uidP)
                    
                    cmd.ExecuteNonQuery()
                    Return "I"
                End Using
            End If
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR InsertarProd: " & ex.Message)
            Return "E"
        End Try
    End Function

    Private Function InsertarPedido(conn As SqlConnection, p As WcPedido, uid As Integer) As String
        ' TODO: Implementar cuando existan las tablas de pedidos
        Return "S"
    End Function

    Private Function ParsearCats(json As String) As List(Of WcCat)
        Dim lista As New List(Of WcCat)()
        Try
            Dim items As String = ExtraerArray(json, "data")
            If items = "" Then items = json
            
            Dim idx As Integer = 1
            While idx < items.Length
                Dim obj As String = ExtraerObjetoEnPosicion(items, idx)
                If obj = "" Then Exit While
                
                Dim cat As New WcCat()
                cat.WcId = ExtraerEntero(obj, "id")
                cat.PadreWcId = ExtraerEntero(obj, "parent")
                cat.Nombre = ExtraerStr(obj, "name")
                cat.Slug = ExtraerStr(obj, "slug")
                cat.Descripcion = LimpiarHtml(ExtraerStr(obj, "description"))
                
                If cat.WcId > 0 AndAlso cat.Nombre <> "" Then
                    lista.Add(cat)
                End If
                
                idx = items.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ParsearCats: " & ex.Message)
        End Try
        Return lista
    End Function

    Private Function ParsearProds(json As String) As List(Of WcProd)
        Dim lista As New List(Of WcProd)()
        Try
            Dim items As String = ExtraerArray(json, "data")
            If items = "" Then items = json
            
            Dim idx As Integer = 1
            While idx < items.Length
                Dim obj As String = ExtraerObjetoEnPosicion(items, idx)
                If obj = "" Then Exit While
                
                Dim prod As New WcProd()
                prod.WcId = ExtraerEntero(obj, "id")
                prod.Nombre = ExtraerStr(obj, "name")
                prod.Sku = ExtraerStr(obj, "sku")
                prod.Descripcion = LimpiarHtml(ExtraerStr(obj, "description"))
                prod.PrecioBS = ExtraerStr(obj, "price")
                prod.PromoBS = ExtraerStr(obj, "sale_price")
                prod.PromoDesde = ExtraerStr(obj, "date_on_sale_from")
                prod.PromoHasta = ExtraerStr(obj, "date_on_sale_to")
                prod.Tipo = ExtraerStr(obj, "type")
                prod.Destacado = (ExtraerStr(obj, "featured") = "true")
                prod.MenuOrder = ExtraerEntero(obj, "menu_order")
                
                Dim imgArr As String = ExtraerArray(obj, "images")
                If imgArr <> "" Then
                    Dim primerImg As String = ExtraerObjetoEnPosicion(imgArr, 1)
                    If primerImg <> "" Then
                        prod.ImagenUrl = ExtraerStr(primerImg, "src")
                    End If
                End If
                
                If prod.WcId > 0 AndAlso prod.Nombre <> "" Then
                    lista.Add(prod)
                End If
                
                idx = items.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ParsearProds: " & ex.Message)
        End Try
        Return lista
    End Function

    Private Function ParsearPedidos(json As String) As List(Of WcPedido)
        Dim lista As New List(Of WcPedido)()
        ' TODO: Implementar cuando se necesite
        Return lista
    End Function

    Private Function ExtraerObjetoEnPosicion(json As String, start As Integer) As String
        Try
            Dim idx As Integer = json.IndexOf("{"c, start)
            If idx < 0 Then Return ""
            
            Dim depth As Integer = 0
            Dim inicio As Integer = idx
            While idx < json.Length
                If json(idx) = "{"c Then depth += 1
                If json(idx) = "}"c Then
                    depth -= 1
                    If depth = 0 Then
                        Return json.Substring(inicio, idx - inicio + 1)
                    End If
                End If
                idx += 1
            End While
        Catch
        End Try
        Return ""
    End Function

    Private Function ExtraerArray(json As String, campo As String) As String
        Try
            Dim patron As String = """" & campo & """"
            Dim idx As Integer = json.IndexOf(patron)
            If idx < 0 Then Return ""
            
            idx += patron.Length
            While idx < json.Length AndAlso (json(idx) = " "c OrElse json(idx) = ":"c)
                idx += 1
            End While
            
            If idx >= json.Length OrElse json(idx) <> "["c Then Return ""
            
            Dim depth As Integer = 0
            Dim inicio As Integer = idx
            While idx < json.Length
                If json(idx) = "["c Then depth += 1
                If json(idx) = "]"c Then
                    depth -= 1
                    If depth = 0 Then
                        Return json.Substring(inicio, idx - inicio + 1)
                    End If
                End If
                idx += 1
            End While
        Catch
        End Try
        Return ""
    End Function

    Private Function ExtraerStr(json As String, campo As String) As String
        Try
            Dim patron As String = """" & campo & """"
            Dim idx As Integer = json.IndexOf(patron)
            If idx < 0 Then Return ""
            
            idx += patron.Length
            While idx < json.Length AndAlso (json(idx) = " "c OrElse json(idx) = ":"c)
                idx += 1
            End While
            
            If idx >= json.Length Then Return ""
            
            If json(idx) = """"c Then
                idx += 1
                Dim sb As New StringBuilder()
                While idx < json.Length AndAlso json(idx) <> """"c
                    If json(idx) = "\"c AndAlso idx + 1 < json.Length Then
                        idx += 1
                        Select Case json(idx)
                            Case "n"c, "r"c, "t"c
                                sb.Append(" ")
                            Case "u"c
                                If idx + 4 < json.Length Then
                                    Dim hex As String = json.Substring(idx + 1, 4)
                                    Dim code As Integer = 0
                                    If Integer.TryParse(hex, System.Globalization.NumberStyles.HexNumber, Nothing, code) Then
                                        sb.Append(ChrW(code))
                                    End If
                                    idx += 4
                                End If
                            Case Else
                                sb.Append(json(idx))
                        End Select
                    Else
                        sb.Append(json(idx))
                    End If
                    idx += 1
                End While
                Return sb.ToString()
            End If
            
            Dim sb2 As New StringBuilder()
            While idx < json.Length AndAlso json(idx) <> ","c AndAlso json(idx) <> "}"c
                sb2.Append(json(idx))
                idx += 1
            End While
            Return sb2.ToString().Trim()
        Catch
            Return ""
        End Try
    End Function

    Private Function ExtraerEntero(json As String, campo As String) As Integer
        Dim v As String = ExtraerStr(json, campo)
        Dim r As Integer = 0
        Integer.TryParse(v, r)
        Return r
    End Function

    Private Function LimpiarHtml(html As String) As String
        If html = "" Then Return ""
        Return HttpUtility.HtmlDecode(
            System.Text.RegularExpressions.Regex.Replace(html, "<[^>]+>", "")
        ).Trim()
    End Function

    ' Clases internas
    Private Class WcCat
        Public Property WcId As Integer
        Public Property PadreWcId As Integer
        Public Property Nombre As String = ""
        Public Property Slug As String = ""
        Public Property Descripcion As String = ""
    End Class

    Private Class WcProd
        Public Property WcId As Integer
        Public Property Nombre As String = ""
        Public Property Sku As String = ""
        Public Property Descripcion As String = ""
        Public Property PrecioBS As String = ""
        Public Property PromoBS As String = ""
        Public Property PromoDesde As String = ""
        Public Property PromoHasta As String = ""
        Public Property Tipo As String = "simple"
        Public Property Activo As Boolean = True
        Public Property Destacado As Boolean = False
        Public Property MenuOrder As Integer = 0
        Public Property ImagenUrl As String = ""
        Public Property CategoriaWcIds As New List(Of Integer)()
    End Class

    Private Class WcPedido
        Public Property WcId As Integer
        Public Property WcOrderKey As String = ""
        Public Property CodigoUnico As String = ""
        Public Property ClienteNombre As String = ""
        Public Property ClienteEmail As String = ""
        Public Property ClienteTelefono As String = ""
        Public Property DestNombre As String = ""
        Public Property DestTelefono As String = ""
        Public Property DireccionEntrega As String = ""
        Public Property ZonaNombre As String = ""
        Public Property FechaEntrega As DateTime?
        Public Property HoraEntrega As String = ""
        Public Property MensajeTarjeta As String = ""
        Public Property TotalBs As Decimal
        Public Property SubtotalBs As Decimal
        Public Property CostoDeliveryBs As Decimal
        Public Property EstadoPago As String = "PENDIENTE"
        Public Property EstadoPreparacion As String = "PENDIENTE"
        Public Property EstadoEntrega As String = "PENDIENTE"
        Public Property FechaCreacion As DateTime?
        Public Property Items As New List(Of WcPedidoItem)()
    End Class

    Private Class WcPedidoItem
        Public Property WcProductId As Integer
        Public Property NombreProducto As String = ""
        Public Property Cantidad As Integer
        Public Property PrecioUnitarioBs As Decimal
        Public Property SubtotalBs As Decimal
    End Class

End Class
