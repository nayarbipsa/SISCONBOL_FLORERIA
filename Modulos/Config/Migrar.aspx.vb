Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Text

' ============================================================
' SISCONBOL - Migracion masiva desde WooCommerce
' Archivo: Modulos/Config/Migrar.aspx.vb
' MasterPage: Site.Master (sesion verificada automaticamente)
' Acciones: INSERTAR_CATEGORIAS, INSERTAR_PRODUCTOS, INSERTAR_PEDIDOS
' ============================================================
Partial Public Class Modulos_Config_Migrar
    Inherits System.Web.UI.Page

    ' Propiedades publicas para JavaScript
    Public Property WcUrl As String = ""
    Public Property WcConsumerKey As String = ""
    Public Property WcConsumerSecret As String = ""
    Public Property FechaDesdeDefault As String = ""
    Public Property FechaHastaDefault As String = ""

    ' ============================================================
    ' Page_Load
    ' ============================================================
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            CargarConfiguracion()
            ' Rango de fechas default: ultimos 30 dias
            FechaDesdeDefault = DateTime.Now.AddDays(-30).ToString("yyyy-MM-dd")
            FechaHastaDefault = DateTime.Now.ToString("yyyy-MM-dd")
        End If
    End Sub

    Private Sub CargarConfiguracion()
        WcUrl = ValorConfig("WC_URL")
        WcConsumerKey = ValorConfig("WC_CONSUMER_KEY")
        WcConsumerSecret = ValorConfig("WC_CONSUMER_SECRET")

        If WcUrl = "" OrElse WcConsumerKey = "" OrElse WcConsumerSecret = "" Then
            Dim js As String = "mostrarAlerta('Configura las credenciales de WooCommerce en Configuracion > Configuracion.', 'warn');"
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

    ' ============================================================
    ' btnAccion_Click - Despacha segun hdAccion
    ' ============================================================
    Protected Sub btnAccion_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""
        Select Case accion.Trim()
            Case "INSERTAR_CATEGORIAS" : ProcesarCategorias()
            Case "INSERTAR_PRODUCTOS" : ProcesarProductos()
            Case "INSERTAR_PEDIDOS" : ProcesarPedidos()
        End Select
    End Sub

    ' ============================================================
    ' CATEGORIAS
    ' ============================================================
    Private Sub ProcesarCategorias()
        Dim lote As String = Request.Form("hdLote")
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)

        If lote Is Nothing OrElse lote.Trim() = "" Then
            EscribirJS("rcatsErr", "mostrarAlerta('No se recibieron datos de categorias desde WooCommerce.', 'error');")
            Return
        End If

        Dim ins As Integer = 0, act As Integer = 0, sin As Integer = 0, err As Integer = 0

        Try
            Dim cats As List(Of WcCat) = ParsearCats(lote)
            If cats.Count = 0 Then
                EscribirJS("rcatsVacio", "mostrarAlerta('No se encontraron categorias validas.', 'warn');")
                Return
            End If
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                For Each c In cats
                    Try
                        Dim r As String = InsertarCat(conn, c, uid)
                        If r = "I" Then ins += 1
                        If r = "A" Then act += 1
                        If r = "S" Then sin += 1
                        If r = "E" Then err += 1
                    Catch ex As Exception
                        err += 1
                        System.Diagnostics.Debug.WriteLine("ERROR Cat " & c.Nombre & ": " & ex.Message)
                    End Try
                Next
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ProcCats: " & ex.Message)
            EscribirJS("rcatsExc", "mostrarAlerta('Error al procesar categorias: " & ex.Message.Replace("'", "") & "', 'error');")
            Return
        End Try

        EscribirJS("rcats", "mostrarResultadoCats(" & ins & "," & act & "," & sin & "," & err & ");")
    End Sub

    ' ============================================================
    ' PRODUCTOS
    ' ============================================================
    Private Sub ProcesarProductos()
        Dim lote As String = Request.Form("hdLote")
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)

        If lote Is Nothing OrElse lote.Trim() = "" Then
            EscribirJS("rprodErr", "mostrarAlerta('No se recibieron datos de productos desde WooCommerce.', 'error');")
            Return
        End If

        Dim ins As Integer = 0, act As Integer = 0, sin As Integer = 0, err As Integer = 0

        Try
            Dim prods As List(Of WcProd) = ParsearProds(lote)
            If prods.Count = 0 Then
                EscribirJS("rprodVacio", "mostrarAlerta('No se encontraron productos validos.', 'warn');")
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
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ProcProds: " & ex.Message)
            EscribirJS("rprodExc", "mostrarAlerta('Error al procesar productos: " & ex.Message.Replace("'", "") & "', 'error');")
            Return
        End Try

        EscribirJS("rprod", "mostrarResultadoProd(" & ins & "," & act & "," & sin & "," & err & ");")
    End Sub

    ' ============================================================
    ' PEDIDOS - convierte ordenes WC en PrePedido + Pedido + Detalles
    ' ============================================================
    Private Sub ProcesarPedidos()
        Dim lote As String = Request.Form("hdLote")
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        Dim ip As String = Request.UserHostAddress
        If ip Is Nothing Then ip = ""

        If lote Is Nothing OrElse lote.Trim() = "" Then
            EscribirJS("rpedErr", "mostrarAlerta('No se recibieron datos de pedidos desde WooCommerce.', 'error');")
            Return
        End If

        Dim ins As Integer = 0, act As Integer = 0, sin As Integer = 0, err As Integer = 0

        Try
            Dim pedidos As List(Of WcPedido) = ParsearPedidos(lote)
            If pedidos.Count = 0 Then
                EscribirJS("rpedVacio", "mostrarAlerta('No se encontraron pedidos validos en el rango indicado.', 'info');")
                Return
            End If

            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                For Each p In pedidos
                    Try
                        Dim r As String = InsertarPedido(conn, p, uid, ip)
                        If r = "I" Then ins += 1
                        If r = "A" Then act += 1
                        If r = "S" Then sin += 1
                        If r = "E" Then err += 1
                    Catch ex As Exception
                        err += 1
                        System.Diagnostics.Debug.WriteLine("ERROR Pedido WC#" & p.WcId & ": " & ex.Message)
                    End Try
                Next
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ProcPedidos: " & ex.Message)
            EscribirJS("rpedExc", "mostrarAlerta('Error al procesar pedidos: " & ex.Message.Replace("'", "") & "', 'error');")
            Return
        End Try

        EscribirJS("rped", "mostrarResultadoPed(" & ins & "," & act & "," & sin & "," & err & ");")
    End Sub

    ' ============================================================
    ' InsertarCat
    ' ============================================================
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

            Dim uidP As Object = If(uid > 0, CObj(uid), DBNull.Value)
            Dim descP As Object = If(c.Descripcion <> "", CObj(c.Descripcion), DBNull.Value)
            Dim slugP As Object = If(c.Slug <> "", CObj(c.Slug), DBNull.Value)

            If existe IsNot Nothing Then
                Using cmd As New SqlCommand(
                    "UPDATE FLORERIA_Categoria SET nombre=@n,descripcion=@d,padre_id=@p,slug=@s," &
                    "wc_sync_estado='SINCRONIZADO',modificado_por=@u,modificado_en=GETDATE() " &
                    "WHERE categoria_id=@id AND (nombre<>@n OR ISNULL(descripcion,'')<>ISNULL(@d,''))", conn)
                    cmd.Parameters.AddWithValue("@n", c.Nombre)
                    cmd.Parameters.AddWithValue("@d", descP)
                    cmd.Parameters.AddWithValue("@p", padre)
                    cmd.Parameters.AddWithValue("@s", slugP)
                    cmd.Parameters.AddWithValue("@u", uidP)
                    cmd.Parameters.AddWithValue("@id", CInt(existe))
                    Return If(cmd.ExecuteNonQuery() > 0, "A", "S")
                End Using
            Else
                Using cmd As New SqlCommand(
                    "INSERT INTO FLORERIA_Categoria(padre_id,nombre,descripcion,slug,orden,wc_category_id,wc_sync_estado,creado_por)" &
                    " VALUES(@p,@n,@d,@s,0,@w,'SINCRONIZADO',@u)", conn)
                    cmd.Parameters.AddWithValue("@p", padre)
                    cmd.Parameters.AddWithValue("@n", c.Nombre)
                    cmd.Parameters.AddWithValue("@d", descP)
                    cmd.Parameters.AddWithValue("@s", slugP)
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

    ' ============================================================
    ' InsertarProd
    ' ============================================================
    Private Function InsertarProd(conn As SqlConnection, p As WcProd, uid As Integer) As String
        Try
            Dim existe As Object = Nothing
            Using cmd As New SqlCommand("SELECT producto_id FROM FLORERIA_Producto WHERE wc_product_id=@w", conn)
                cmd.Parameters.AddWithValue("@w", p.WcId)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then existe = dr("producto_id")
                End Using
            End Using

            Dim uidP As Object = If(uid > 0, CObj(uid), DBNull.Value)
            Dim pb As Decimal = 0D : Decimal.TryParse(p.PrecioBS, pb)
            Dim descP As Object = If(p.Descripcion <> "", CObj(p.Descripcion), DBNull.Value)
            Dim iuP As Object = If(p.ImagenUrl <> "", CObj(p.ImagenUrl), DBNull.Value)

            Dim ppP As Object = DBNull.Value
            If p.PromoBS <> "" Then
                Dim ppVal As Decimal = 0D
                If Decimal.TryParse(p.PromoBS, ppVal) Then ppP = ppVal
            End If
            Dim pdP As Object = DBNull.Value
            If p.PromoDesde <> "" Then
                Dim dtVal As DateTime
                If DateTime.TryParse(p.PromoDesde, dtVal) Then pdP = dtVal
            End If
            Dim phP As Object = DBNull.Value
            If p.PromoHasta <> "" Then
                Dim dtVal As DateTime
                If DateTime.TryParse(p.PromoHasta, dtVal) Then phP = dtVal
            End If

            If existe IsNot Nothing Then
                Using cmd As New SqlCommand(
                    "UPDATE FLORERIA_Producto SET nombre=@n,descripcion=@d,precio_base_bs=@pb," &
                    "precio_promo_bs=@pp,promo_desde=@pd,promo_hasta=@ph,destacado=@de,menu_order=@mo," &
                    "imagen_url=@iu,wc_sync_estado='SINCRONIZADO',modificado_por=@u,modificado_en=GETDATE() " &
                    "WHERE producto_id=@id", conn)
                    cmd.Parameters.AddWithValue("@n", p.Nombre)
                    cmd.Parameters.AddWithValue("@d", descP)
                    cmd.Parameters.AddWithValue("@pb", pb)
                    cmd.Parameters.AddWithValue("@pp", ppP)
                    cmd.Parameters.AddWithValue("@pd", pdP)
                    cmd.Parameters.AddWithValue("@ph", phP)
                    cmd.Parameters.AddWithValue("@de", If(p.Destacado, 1, 0))
                    cmd.Parameters.AddWithValue("@mo", p.MenuOrder)
                    cmd.Parameters.AddWithValue("@iu", iuP)
                    cmd.Parameters.AddWithValue("@u", uidP)
                    cmd.Parameters.AddWithValue("@id", CInt(existe))
                    Return If(cmd.ExecuteNonQuery() > 0, "A", "S")
                End Using
            Else
                Dim sk As String = If(p.Sku <> "", p.Sku, "WC" & p.WcId.ToString())
                Using cmd As New SqlCommand(
                    "INSERT INTO FLORERIA_Producto(sku,nombre,descripcion,precio_base_bs,precio_promo_bs," &
                    "promo_desde,promo_hasta,destacado,menu_order,imagen_url,wc_product_id,wc_sync_estado,creado_por)" &
                    " VALUES(@sk,@n,@d,@pb,@pp,@pd,@ph,@de,@mo,@iu,@w,'SINCRONIZADO',@u)", conn)
                    cmd.Parameters.AddWithValue("@sk", sk)
                    cmd.Parameters.AddWithValue("@n", p.Nombre)
                    cmd.Parameters.AddWithValue("@d", descP)
                    cmd.Parameters.AddWithValue("@pb", pb)
                    cmd.Parameters.AddWithValue("@pp", ppP)
                    cmd.Parameters.AddWithValue("@pd", pdP)
                    cmd.Parameters.AddWithValue("@ph", phP)
                    cmd.Parameters.AddWithValue("@de", If(p.Destacado, 1, 0))
                    cmd.Parameters.AddWithValue("@mo", p.MenuOrder)
                    cmd.Parameters.AddWithValue("@iu", iuP)
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

    ' ============================================================
    ' InsertarPedido
    '   Estrategia: 1 orden WC = 1 PrePedido + 1 Pedido
    '   Si ya existe (wc_order_id) lo marca sin cambios (S)
    ' ============================================================
    Private Function InsertarPedido(conn As SqlConnection, p As WcPedido,
                                    uid As Integer, ip As String) As String
        Try
            ' Verificar si ya existe por wc_order_id
            Using chk As New SqlCommand(
                "SELECT pedido_id FROM FLORERIA_Pedido WHERE wc_order_id=@w", conn)
                chk.Parameters.AddWithValue("@w", p.WcId)
                Using dr As SqlDataReader = chk.ExecuteReader()
                    If dr.Read() Then Return "S"   ' ya migrado
                End Using
            End Using

            Dim uidP As Object = If(uid > 0, CObj(uid), DBNull.Value)

            '  1. Crear PrePedido (tipo VENTA_ANTIGUA) 
            Dim preId As Integer = 0
            Dim preCod As String = ""

            Using cmd As New SqlCommand("FLORERIA_sp_PrePedido_Crear", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@tipo_registro", "VENTA_ANTIGUA")
                cmd.Parameters.AddWithValue("@cliente_celular", If(p.ClienteTelefono <> "", p.ClienteTelefono, "00000000"))
                cmd.Parameters.AddWithValue("@agente_id", uid)
                cmd.Parameters.AddWithValue("@ip", ip)

                Dim pId As New SqlParameter("@prepedido_id", SqlDbType.Int)
                pId.Direction = ParameterDirection.Output
                cmd.Parameters.Add(pId)

                Dim pCod As New SqlParameter("@codigo", SqlDbType.VarChar, 20)
                pCod.Direction = ParameterDirection.Output
                cmd.Parameters.Add(pCod)

                cmd.ExecuteNonQuery()

                If pId.Value Is DBNull.Value OrElse pId.Value Is Nothing Then
                    System.Diagnostics.Debug.WriteLine("WARN InsertarPedido: sp_PrePedido_Crear no devolvio id")
                    Return "E"
                End If
                preId = Convert.ToInt32(pId.Value)
                preCod = pCod.Value.ToString()
            End Using

            ' Actualizar datos del cliente en el PrePedido
            If p.ClienteNombre <> "" OrElse p.ClienteEmail <> "" Then
                Using cmd2 As New SqlCommand("FLORERIA_sp_PrePedido_ActualizarCliente", conn)
                    cmd2.CommandType = CommandType.StoredProcedure
                    cmd2.Parameters.AddWithValue("@prepedido_id", preId)
                    cmd2.Parameters.AddWithValue("@cliente_nombre", If(p.ClienteNombre <> "", CObj(p.ClienteNombre), DBNull.Value))
                    cmd2.Parameters.AddWithValue("@cliente_apellidos", DBNull.Value)
                    cmd2.Parameters.AddWithValue("@cliente_email", If(p.ClienteEmail <> "", CObj(p.ClienteEmail), DBNull.Value))
                    cmd2.Parameters.AddWithValue("@cliente_pais_id", DBNull.Value)
                    cmd2.Parameters.AddWithValue("@cliente_ciudad_id", DBNull.Value)
                    cmd2.Parameters.AddWithValue("@modificado_por", uidP)
                    cmd2.Parameters.AddWithValue("@ip", ip)
                    cmd2.ExecuteNonQuery()
                End Using
            End If

            '  2. Crear Pedido 
            Dim pedId As Integer = 0
            Dim pedCod As String = ""

            ' ciudad_id = 1 (Santa Cruz, primera ciudad activa en la BD)
            Dim ciudadId As Integer = 1

            ' Fecha entrega: usar fecha del pedido WC o manana si es null
            Dim fechaEntrega As String = DateTime.Now.AddDays(1).ToString("yyyy-MM-dd")
            If p.FechaEntrega.HasValue Then
                fechaEntrega = p.FechaEntrega.Value.ToString("yyyy-MM-dd")
            End If

            Using cmd As New SqlCommand("FLORERIA_sp_Pedido_Crear", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@prepedido_id", preId)
                cmd.Parameters.AddWithValue("@receptor_nombre", If(p.DestNombre <> "", p.DestNombre, p.ClienteNombre))
                cmd.Parameters.AddWithValue("@receptor_celular", If(p.DestTelefono <> "", p.DestTelefono, If(p.ClienteTelefono <> "", p.ClienteTelefono, "00000000")))
                cmd.Parameters.AddWithValue("@ciudad_id", ciudadId)
                cmd.Parameters.AddWithValue("@zona_id", DBNull.Value)
                cmd.Parameters.AddWithValue("@sucursal_id", DBNull.Value)
                cmd.Parameters.AddWithValue("@tipo_entrega", "DOMICILIO")
                cmd.Parameters.AddWithValue("@direccion", If(p.DireccionEntrega <> "", CObj(p.DireccionEntrega), DBNull.Value))
                cmd.Parameters.AddWithValue("@referencia", DBNull.Value)
                cmd.Parameters.AddWithValue("@fecha_entrega", fechaEntrega)
                cmd.Parameters.AddWithValue("@slot_id", DBNull.Value)
                cmd.Parameters.AddWithValue("@es_express", 0)
                cmd.Parameters.AddWithValue("@dedicatoria", If(p.MensajeTarjeta <> "", CObj(p.MensajeTarjeta), DBNull.Value))
                cmd.Parameters.AddWithValue("@firma_tarjeta", DBNull.Value)
                cmd.Parameters.AddWithValue("@creado_por", uid)
                cmd.Parameters.AddWithValue("@ip", ip)

                Dim pPedId As New SqlParameter("@pedido_id", SqlDbType.Int)
                pPedId.Direction = ParameterDirection.Output
                cmd.Parameters.Add(pPedId)

                Dim pCodP As New SqlParameter("@codigo", SqlDbType.VarChar, 20)
                pCodP.Direction = ParameterDirection.Output
                cmd.Parameters.Add(pCodP)

                cmd.ExecuteNonQuery()

                If pPedId.Value Is DBNull.Value OrElse pPedId.Value Is Nothing Then
                    System.Diagnostics.Debug.WriteLine("WARN InsertarPedido: sp_Pedido_Crear no devolvio id")
                    Return "E"
                End If
                pedId = Convert.ToInt32(pPedId.Value)
                pedCod = pCodP.Value.ToString()
            End Using

            ' Guardar wc_order_id en el pedido recien creado
            Using updWc As New SqlCommand(
                "UPDATE FLORERIA_Pedido SET wc_order_id=@w, wc_sync_estado='SINCRONIZADO', wc_sync_fecha=GETDATE() " &
                "WHERE pedido_id=@id", conn)
                updWc.Parameters.AddWithValue("@w", p.WcId)
                updWc.Parameters.AddWithValue("@id", pedId)
                updWc.ExecuteNonQuery()
            End Using

            '  3. Agregar items del pedido 
            For Each item As WcPedidoItem In p.Items
                Try
                    ' Buscar producto_id por wc_product_id
                    Dim prodId As Object = DBNull.Value
                    Using pCmd As New SqlCommand(
                        "SELECT producto_id FROM FLORERIA_Producto WHERE wc_product_id=@w", conn)
                        pCmd.Parameters.AddWithValue("@w", item.WcProductId)
                        Dim pObj As Object = pCmd.ExecuteScalar()
                        If pObj IsNot Nothing AndAlso Not IsDBNull(pObj) Then
                            prodId = CInt(pObj)
                        End If
                    End Using

                    Using dCmd As New SqlCommand("FLORERIA_sp_Pedido_AgregarProducto", conn)
                        dCmd.CommandType = CommandType.StoredProcedure
                        dCmd.Parameters.AddWithValue("@pedido_id", pedId)
                        dCmd.Parameters.AddWithValue("@producto_id", prodId)
                        dCmd.Parameters.AddWithValue("@variacion_id", DBNull.Value)
                        dCmd.Parameters.AddWithValue("@es_personalizado", 0)
                        dCmd.Parameters.AddWithValue("@nombre_producto", item.NombreProducto)
                        dCmd.Parameters.AddWithValue("@descripcion", DBNull.Value)
                        dCmd.Parameters.AddWithValue("@cantidad", item.Cantidad)
                        dCmd.Parameters.AddWithValue("@precio_unitario_bs", item.PrecioUnitarioBs)
                        dCmd.Parameters.AddWithValue("@precio_unitario_usd", DBNull.Value)
                        dCmd.Parameters.AddWithValue("@personalizacion", DBNull.Value)
                        dCmd.ExecuteNonQuery()
                    End Using
                Catch exItem As Exception
                    System.Diagnostics.Debug.WriteLine("WARN Item " & item.NombreProducto & ": " & exItem.Message)
                End Try
            Next

            Return "I"

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR InsertarPedido WC#" & p.WcId & ": " & ex.Message)
            Return "E"
        End Try
    End Function

    ' ============================================================
    ' ParsearCats - extrae lista de WcCat del JSON de WooCommerce
    ' ============================================================
    Private Function ParsearCats(json As String) As List(Of WcCat)
        Dim lista As New List(Of WcCat)()
        Try
            Dim items As String = ExtraerArray(json, "data")
            If items = "" Then items = json
            Dim idx As Integer = 1
            While idx < items.Length
                Dim obj As String = ExtraerObjeto(items, idx)
                If obj = "" Then Exit While
                Dim cat As New WcCat()
                cat.WcId = ExtraerEntero(obj, "id")
                cat.PadreWcId = ExtraerEntero(obj, "parent")
                cat.Nombre = ExtraerStr(obj, "name")
                cat.Slug = ExtraerStr(obj, "slug")
                cat.Descripcion = LimpiarHtml(ExtraerStr(obj, "description"))
                If cat.WcId > 0 AndAlso cat.Nombre <> "" Then lista.Add(cat)
                idx = items.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ParsearCats: " & ex.Message)
        End Try
        Return lista
    End Function

    ' ============================================================
    ' ParsearProds - extrae lista de WcProd del JSON de WooCommerce
    ' ============================================================
    Private Function ParsearProds(json As String) As List(Of WcProd)
        Dim lista As New List(Of WcProd)()
        Try
            Dim items As String = ExtraerArray(json, "data")
            If items = "" Then items = json
            Dim idx As Integer = 1
            While idx < items.Length
                Dim obj As String = ExtraerObjeto(items, idx)
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
                    Dim primerImg As String = ExtraerObjeto(imgArr, 1)
                    If primerImg <> "" Then prod.ImagenUrl = ExtraerStr(primerImg, "src")
                End If
                If prod.WcId > 0 AndAlso prod.Nombre <> "" Then lista.Add(prod)
                idx = items.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ParsearProds: " & ex.Message)
        End Try
        Return lista
    End Function

    ' ============================================================
    ' ParsearPedidos - extrae lista de WcPedido del JSON de WooCommerce
    ' ============================================================
    Private Function ParsearPedidos(json As String) As List(Of WcPedido)
        Dim lista As New List(Of WcPedido)()
        Try
            Dim items As String = ExtraerArray(json, "data")
            If items = "" Then items = json
            Dim idx As Integer = 1
            While idx < items.Length
                Dim obj As String = ExtraerObjeto(items, idx)
                If obj = "" Then Exit While

                Dim ped As New WcPedido()
                ped.WcId = ExtraerEntero(obj, "id")

                ' Cliente (billing)
                Dim billing As String = ExtraerObjeto(obj, ExtraerPosicion(obj, "billing"))
                If billing = "" Then
                    ' Intentar extraccion simple de campos billing
                    ped.ClienteNombre = ExtraerStr(obj, "first_name")
                    ped.ClienteTelefono = ExtraerStr(obj, "phone")
                    ped.ClienteEmail = ExtraerStr(obj, "email")
                Else
                    ped.ClienteNombre = (ExtraerStr(billing, "first_name") & " " & ExtraerStr(billing, "last_name")).Trim()
                    ped.ClienteTelefono = ExtraerStr(billing, "phone")
                    ped.ClienteEmail = ExtraerStr(billing, "email")
                    ped.DireccionEntrega = ExtraerStr(billing, "address_1") & " " & ExtraerStr(billing, "address_2")
                    ped.DireccionEntrega = ped.DireccionEntrega.Trim()
                End If

                ' Shipping (receptor)
                Dim shipping As String = ExtraerObjeto(obj, ExtraerPosicion(obj, "shipping"))
                If shipping <> "" Then
                    Dim sNom As String = (ExtraerStr(shipping, "first_name") & " " & ExtraerStr(shipping, "last_name")).Trim()
                    If sNom <> "" Then ped.DestNombre = sNom
                    Dim sDir As String = (ExtraerStr(shipping, "address_1") & " " & ExtraerStr(shipping, "address_2")).Trim()
                    If sDir <> "" Then ped.DireccionEntrega = sDir
                End If

                ' Totales
                Dim totalStr As String = ExtraerStr(obj, "total")
                If totalStr <> "" Then Decimal.TryParse(totalStr, ped.TotalBs)

                ' Fecha creacion
                Dim fechaStr As String = ExtraerStr(obj, "date_created")
                If fechaStr <> "" Then
                    Dim dtParsed As DateTime
                    If DateTime.TryParse(fechaStr, dtParsed) Then ped.FechaEntrega = dtParsed.AddDays(2)
                End If

                ' Metadatos personalizados (campo dedicatoria / mensaje tarjeta)
                Dim metaJson As String = ExtraerArray(obj, "meta_data")
                If metaJson <> "" Then
                    ped.MensajeTarjeta = ExtraerMetaValor(metaJson, "dedicatoria")
                    If ped.MensajeTarjeta = "" Then ped.MensajeTarjeta = ExtraerMetaValor(metaJson, "mensaje_tarjeta")
                    ped.DestTelefono = ExtraerMetaValor(metaJson, "celular_receptor")
                End If

                ' Line items (productos)
                Dim lineItemsJson As String = ExtraerArray(obj, "line_items")
                If lineItemsJson <> "" Then
                    ped.Items = ParsearLineItems(lineItemsJson)
                End If

                If ped.WcId > 0 Then lista.Add(ped)

                idx = items.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ParsearPedidos: " & ex.Message)
        End Try
        Return lista
    End Function

    Private Function ParsearLineItems(json As String) As List(Of WcPedidoItem)
        Dim lista As New List(Of WcPedidoItem)()
        Try
            Dim idx As Integer = 1
            While idx < json.Length
                Dim obj As String = ExtraerObjeto(json, idx)
                If obj = "" Then Exit While
                Dim item As New WcPedidoItem()
                item.WcProductId = ExtraerEntero(obj, "product_id")
                item.NombreProducto = ExtraerStr(obj, "name")
                item.Cantidad = ExtraerEntero(obj, "quantity")
                If item.Cantidad <= 0 Then item.Cantidad = 1
                Dim precStr As String = ExtraerStr(obj, "price")
                If precStr <> "" Then Decimal.TryParse(precStr, item.PrecioUnitarioBs)
                If item.PrecioUnitarioBs <= 0 Then item.PrecioUnitarioBs = 1
                If item.NombreProducto <> "" Then lista.Add(item)
                idx = json.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ParsearLineItems: " & ex.Message)
        End Try
        Return lista
    End Function

    ' Extrae el valor de un meta_data con una clave especifica
    Private Function ExtraerMetaValor(metaJson As String, clave As String) As String
        Try
            Dim idx As Integer = 1
            While idx < metaJson.Length
                Dim obj As String = ExtraerObjeto(metaJson, idx)
                If obj = "" Then Exit While
                Dim k As String = ExtraerStr(obj, "key")
                If k.ToLower() = clave.ToLower() Then
                    Return ExtraerStr(obj, "value")
                End If
                idx = metaJson.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch
        End Try
        Return ""
    End Function

    ' Retorna la posicion del primer { despues de una clave de objeto
    Private Function ExtraerPosicion(json As String, clave As String) As Integer
        Try
            Dim patron As String = """" & clave & """"
            Dim idx As Integer = json.IndexOf(patron)
            If idx < 0 Then Return -1
            idx += patron.Length
            While idx < json.Length AndAlso (json(idx) = " "c OrElse json(idx) = ":"c)
                idx += 1
            End While
            If idx < json.Length AndAlso json(idx) = "{"c Then Return idx
        Catch
        End Try
        Return -1
    End Function

    ' ============================================================
    ' Utilidades JSON minimal (sin dependencias externas)
    ' ============================================================
    Private Function ExtraerObjeto(json As String, start As Integer) As String
        Try
            Dim idx As Integer = json.IndexOf("{"c, start)
            If idx < 0 Then Return ""
            Dim depth As Integer = 0
            Dim inicio As Integer = idx
            While idx < json.Length
                If json(idx) = "{"c Then depth += 1
                If json(idx) = "}"c Then
                    depth -= 1
                    If depth = 0 Then Return json.Substring(inicio, idx - inicio + 1)
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
                    If depth = 0 Then Return json.Substring(inicio, idx - inicio + 1)
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
                            Case "n"c, "r"c, "t"c : sb.Append(" ")
                            Case "u"c
                                If idx + 4 < json.Length Then
                                    Dim hex As String = json.Substring(idx + 1, 4)
                                    Dim code As Integer = 0
                                    If Integer.TryParse(hex, System.Globalization.NumberStyles.HexNumber, Nothing, code) Then
                                        sb.Append(ChrW(code))
                                    End If
                                    idx += 4
                                End If
                            Case Else : sb.Append(json(idx))
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
            Text.RegularExpressions.Regex.Replace(html, "<[^>]+>", "")
        ).Trim()
    End Function

    Private Sub EscribirJS(key As String, script As String)
        ClientScript.RegisterStartupScript(Me.GetType(), key, script, True)
    End Sub

    ' ============================================================
    ' Clases internas
    ' ============================================================
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
        Public Property Destacado As Boolean = False
        Public Property MenuOrder As Integer = 0
        Public Property ImagenUrl As String = ""
    End Class

    Private Class WcPedido
        Public Property WcId As Integer
        Public Property ClienteNombre As String = ""
        Public Property ClienteEmail As String = ""
        Public Property ClienteTelefono As String = ""
        Public Property DestNombre As String = ""
        Public Property DestTelefono As String = ""
        Public Property DireccionEntrega As String = ""
        Public Property MensajeTarjeta As String = ""
        Public Property TotalBs As Decimal
        Public Property FechaEntrega As DateTime?
        Public Property Items As New List(Of WcPedidoItem)()
    End Class

    Private Class WcPedidoItem
        Public Property WcProductId As Integer
        Public Property NombreProducto As String = ""
        Public Property Cantidad As Integer = 1
        Public Property PrecioUnitarioBs As Decimal
    End Class

End Class