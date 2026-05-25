Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Text

' ============================================================
' SISCONBOL - Migracion masiva desde WooCommerce
' Archivo: Modulos/Config/Migrar.aspx.vb
' Mapeo basado en JSON real de miss-flores.com (Mayo 2026)
' ============================================================
Partial Public Class Modulos_Config_Migrar
    Inherits System.Web.UI.Page

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
            FechaDesdeDefault = DateTime.Now.AddDays(-30).ToString("yyyy-MM-dd")
            FechaHastaDefault = DateTime.Now.ToString("yyyy-MM-dd")
        End If
    End Sub

    Private Sub CargarConfiguracion()
        WcUrl    = ValorConfig("WC_URL")
        WcConsumerKey    = ValorConfig("WC_CONSUMER_KEY")
        WcConsumerSecret = ValorConfig("WC_CONSUMER_SECRET")
        If WcUrl = "" OrElse WcConsumerKey = "" OrElse WcConsumerSecret = "" Then
            EscribirJS("cfgWarn", "mostrarAlerta('Configura las credenciales de WooCommerce en Configuracion.', 'warn');")
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
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then Return r.ToString()
                End Using
            End Using
        Catch ex As Exception
            Log("ValorConfig", "ERROR leyendo clave '" & clave & "': " & ex.Message)
        End Try
        Return ""
    End Function

    ' ============================================================
    ' btnAccion_Click
    ' ============================================================
    Protected Sub btnAccion_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""
        Select Case accion.Trim()
            Case "INSERTAR_CATEGORIAS" : ProcesarCategorias()
            Case "INSERTAR_PRODUCTOS"  : ProcesarProductos()
            Case "INSERTAR_PEDIDOS"    : ProcesarPedidos()
        End Select
    End Sub

    ' ============================================================
    ' CATEGORIAS
    ' ============================================================
    Private Sub ProcesarCategorias()
        Dim lote As String = Request.Form("hdLote")
        Dim uid  As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        If lote Is Nothing OrElse lote.Trim() = "" Then
            EscribirJS("rcatsErr", "mostrarAlerta('ERROR: No se recibieron datos de categorias desde WooCommerce.', 'error');")
            Return
        End If
        Dim ins As Integer = 0, act As Integer = 0, sin As Integer = 0, err As Integer = 0
        Try
            Dim cats As List(Of WcCat) = ParsearCats(lote)
            If cats.Count = 0 Then
                EscribirJS("rcatsVacio", "mostrarAlerta('No se encontraron categorias validas en la respuesta de WooCommerce.', 'warn');")
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
                        Log("InsertarCat", "ERROR en categoria WcId=" & c.WcId & " Nombre='" & c.Nombre & "': " & ex.Message)
                    End Try
                Next
            End Using
        Catch ex As Exception
            Log("ProcesarCategorias", "ERROR CRITICO: " & ex.Message)
            EscribirJS("rcatsExc", "mostrarAlerta('ERROR al procesar categorias: " & EscJs(ex.Message) & "', 'error');")
            Return
        End Try
        EscribirJS("rcats", "mostrarResultadoCats(" & ins & "," & act & "," & sin & "," & err & ");")
    End Sub

    ' ============================================================
    ' PRODUCTOS
    ' ============================================================
    Private Sub ProcesarProductos()
        Dim lote As String = Request.Form("hdLote")
        Dim uid  As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        If lote Is Nothing OrElse lote.Trim() = "" Then
            EscribirJS("rprodErr", "mostrarAlerta('ERROR: No se recibieron datos de productos desde WooCommerce.', 'error');")
            Return
        End If
        Dim ins As Integer = 0, act As Integer = 0, sin As Integer = 0, err As Integer = 0
        Try
            Dim prods As List(Of WcProd) = ParsearProds(lote)
            If prods.Count = 0 Then
                EscribirJS("rprodVacio", "mostrarAlerta('No se encontraron productos validos en la respuesta de WooCommerce.', 'warn');")
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
                        Log("InsertarProd", "ERROR en producto WcId=" & p.WcId & " Nombre='" & p.Nombre & "': " & ex.Message)
                    End Try
                Next
            End Using
        Catch ex As Exception
            Log("ProcesarProductos", "ERROR CRITICO: " & ex.Message)
            EscribirJS("rprodExc", "mostrarAlerta('ERROR al procesar productos: " & EscJs(ex.Message) & "', 'error');")
            Return
        End Try
        EscribirJS("rprod", "mostrarResultadoProd(" & ins & "," & act & "," & sin & "," & err & ");")
    End Sub

    ' ============================================================
    ' PEDIDOS
    ' ============================================================
    Private Sub ProcesarPedidos()
        Dim lote As String = Request.Form("hdLote")
        Dim uid  As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        Dim ip   As String  = If(Request.UserHostAddress Is Nothing, "", Request.UserHostAddress)
        If lote Is Nothing OrElse lote.Trim() = "" Then
            EscribirJS("rpedErr", "agregarLog('ERROR: No se recibieron datos de pedidos desde WooCommerce.', 'error'); finalizarMigracion(true);")
            Return
        End If
        Dim ins As Integer = 0, act As Integer = 0, sin As Integer = 0, err As Integer = 0
        Dim errDetalle As New StringBuilder()
        Try
            Dim pedidos As List(Of WcPedido) = ParsearPedidos(lote)
            If pedidos.Count = 0 Then
                EscribirJS("rpedVacio", "agregarLog('No se encontraron pedidos validos en el rango indicado.', 'warn'); finalizarMigracion(false);")
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
                        If r = "E" Then
                            err += 1
                            errDetalle.Append("WC#" & p.WcId & " ")
                        End If
                    Catch ex As Exception
                        err += 1
                        errDetalle.Append("WC#" & p.WcId & "(" & ex.Message.Substring(0, Math.Min(60, ex.Message.Length)) & ") ")
                        Log("InsertarPedido", "ERROR en pedido WcId=" & p.WcId & ": " & ex.Message)
                    End Try
                Next
            End Using
        Catch ex As Exception
            Log("ProcesarPedidos", "ERROR CRITICO: " & ex.Message)
            EscribirJS("rpedExc", "agregarLog('ERROR CRITICO: " & EscJs(ex.Message) & "', 'error'); finalizarMigracion(true);")
            Return
        End Try
        Dim jsExtra As String = ""
        If err > 0 AndAlso errDetalle.Length > 0 Then
            jsExtra = "console.error('Pedidos con error: " & EscJs(errDetalle.ToString()) & "');"
        End If
        EscribirJS("rped", jsExtra & "recibirResultadoLote(" & ins & "," & act & "," & sin & "," & err & ",'" & EscJs(errDetalle.ToString()) & "');")
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
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then padre = CInt(r)
                End Using
            End If

            Dim uidP  As Object = If(uid > 0, CObj(uid), DBNull.Value)
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
            Log("InsertarCat", "WcId=" & c.WcId & " - " & ex.Message)
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

            Dim uidP  As Object  = If(uid > 0, CObj(uid), DBNull.Value)
            Dim pb    As Decimal = 0D : Decimal.TryParse(p.PrecioBS, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, pb)
            Dim descP As Object  = If(p.Descripcion <> "", CObj(p.Descripcion), DBNull.Value)
            Dim iuP   As Object  = If(p.ImagenUrl <> "", CObj(p.ImagenUrl), DBNull.Value)

            Dim ppP As Object = DBNull.Value
            If p.PromoBS <> "" Then
                Dim ppVal As Decimal = 0D
                If Decimal.TryParse(p.PromoBS, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, ppVal) Then ppP = ppVal
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
                    cmd.Parameters.AddWithValue("@n",  p.Nombre)
                    cmd.Parameters.AddWithValue("@d",  descP)
                    cmd.Parameters.AddWithValue("@pb", pb)
                    cmd.Parameters.AddWithValue("@pp", ppP)
                    cmd.Parameters.AddWithValue("@pd", pdP)
                    cmd.Parameters.AddWithValue("@ph", phP)
                    cmd.Parameters.AddWithValue("@de", If(p.Destacado, 1, 0))
                    cmd.Parameters.AddWithValue("@mo", p.MenuOrder)
                    cmd.Parameters.AddWithValue("@iu", iuP)
                    cmd.Parameters.AddWithValue("@u",  uidP)
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
                    cmd.Parameters.AddWithValue("@n",  p.Nombre)
                    cmd.Parameters.AddWithValue("@d",  descP)
                    cmd.Parameters.AddWithValue("@pb", pb)
                    cmd.Parameters.AddWithValue("@pp", ppP)
                    cmd.Parameters.AddWithValue("@pd", pdP)
                    cmd.Parameters.AddWithValue("@ph", phP)
                    cmd.Parameters.AddWithValue("@de", If(p.Destacado, 1, 0))
                    cmd.Parameters.AddWithValue("@mo", p.MenuOrder)
                    cmd.Parameters.AddWithValue("@iu", iuP)
                    cmd.Parameters.AddWithValue("@w",  p.WcId)
                    cmd.Parameters.AddWithValue("@u",  uidP)
                    cmd.ExecuteNonQuery()
                    Return "I"
                End Using
            End If
        Catch ex As Exception
            Log("InsertarProd", "WcId=" & p.WcId & " - " & ex.Message)
            Return "E"
        End Try
    End Function

    ' ============================================================
    ' InsertarPedido — UPSERT
    '   INSERT si es nuevo, UPDATE si ya existe
    '   prepedido_id = NULL (SP alterado para aceptarlo)
    '   Retorna: I=insertado, A=actualizado, E=error
    ' ============================================================
    Private Function InsertarPedido(conn As SqlConnection, p As WcPedido, uid As Integer, ip As String) As String
        Try
            ' --- 1. Buscar si ya existe por wc_order_id ---
            Dim pedidoExistenteId As Integer = 0
            Dim wcDateModBD       As DateTime = DateTime.MinValue
            Using chk As New SqlCommand(
                "SELECT pedido_id, ISNULL(wc_date_modified, '1900-01-01') AS wc_date_modified " &
                "FROM FLORERIA_Pedido WHERE wc_order_id=@w", conn)
                chk.Parameters.AddWithValue("@w", p.WcId)
                Using dr As SqlDataReader = chk.ExecuteReader()
                    If dr.Read() Then
                        pedidoExistenteId = CInt(dr("pedido_id"))
                        wcDateModBD       = CDate(dr("wc_date_modified"))
                    End If
                End Using
            End Using

            ' --- 2. Calcular totales (necesario tanto para INSERT como UPDATE) ---
            Dim totalBs  As Decimal = p.TotalBs
            Dim envioBs  As Decimal = p.EnvioBs
            Dim descBs   As Decimal = p.DescuentoBs
            Dim tasa     As Decimal = If(p.WoocsRate > 0, p.WoocsRate, 0D)
            Dim totalUsd As Decimal = If(tasa > 0, Math.Round(totalBs * tasa, 2), 0D)
            Dim envioUsd As Decimal = If(tasa > 0, Math.Round(envioBs * tasa, 2), 0D)
            Dim descUsd  As Decimal = If(tasa > 0, Math.Round(descBs  * tasa, 2), 0D)

            ' --- 3. Calcular estado_pago y estado_operativo ---
            ' PayPal/Tarjeta con date_paid confirmado = PAGADO automatico
            ' QR/Libelula con status processing/completed/entregado = PAGADO
            ' Todo lo demas = PENDIENTE (verificacion manual)
            Dim estadoPago As String = "PENDIENTE"
            Dim statusLower As String = p.WcOrderStatus.ToLower().Trim()
            If p.WcDatePaid.HasValue Then
                estadoPago = "PAGADO"
            ElseIf statusLower = "processing" OrElse statusLower = "completed" OrElse statusLower = "entregado" Then
                estadoPago = "PAGADO"
            End If

            ' estado_operativo basado en status WC
            '   entregado/completed → ENTREGADO
            '   processing          → PREPARANDO (pago confirmado, en proceso)
            '   on-hold/pending     → PENDIENTE
            '   failed/cancelled    → FALLIDO
            Dim estadoOperativo As String = "PENDIENTE"
            Select Case statusLower
                Case "entregado", "completed"     : estadoOperativo = "ENTREGADO"
                Case "processing"                  : estadoOperativo = "PREPARANDO"
                Case "failed", "cancelled"         : estadoOperativo = "FALLIDO"
                Case Else                          : estadoOperativo = "PENDIENTE"
            End Select

            ' ============================================================
            ' CASO A: PEDIDO YA EXISTE → ACTUALIZAR solo campos de WC
            ' NO se pisan: receptor_nombre, direccion, fecha_entrega,
            '              slot_id, zona_id, nota_floreria, dedicatoria
            '              (pueden haber sido editados en SISCONBOL)
            ' ============================================================
            If pedidoExistenteId > 0 Then
                ' Solo actualizar si WC tiene una version mas nueva
                Dim wcDateMod As DateTime = If(p.WcDateModified.HasValue, p.WcDateModified.Value, DateTime.MinValue)
                If wcDateMod <= wcDateModBD Then
                    Log("InsertarPedido", "WC#" & p.WcId & " sin cambios desde ultima sync - omitido")
                    Return "S"
                End If

                Try
                    Using upd As New SqlCommand(
                        "UPDATE FLORERIA_Pedido SET " &
                        "  wc_order_status=@wst, " &
                        "  wc_date_paid=@wdp, " &
                        "  wc_payment_method=@wpm, " &
                        "  wc_payment_method_title=@wpmt, " &
                        "  wc_date_modified=@wdm, " &
                        "  wc_order_number=@wnum, " &
                        "  wc_order_url=@wurl, " &
                        "  wc_sync_estado='SINCRONIZADO', " &
                        "  wc_sync_fecha=GETDATE(), " &
                        "  estado_pago=@ep, " &
                        "  estado_operativo=@eo, " &
                        "  total_bs=@tbs, total_usd=@tusd, " &
                        "  envio_bs=@ebs, envio_usd=@eusd, " &
                        "  descuento_bs=@dbs, descuento_usd=@dusd, " &
                        "  observaciones=@obs, " &
                        "  gps=ISNULL(gps, @gps), " &
                        "  modificado_por=@u, modificado_en=GETDATE() " &
                        "WHERE pedido_id=@pid", conn)
                        upd.Parameters.AddWithValue("@wst",  If(p.WcOrderStatus <> "",         CObj(p.WcOrderStatus),          DBNull.Value))
                        upd.Parameters.AddWithValue("@wdp",  If(p.WcDatePaid.HasValue,          CObj(p.WcDatePaid.Value),        DBNull.Value))
                        upd.Parameters.AddWithValue("@wpm",  If(p.PaymentMethod <> "",          CObj(p.PaymentMethod),           DBNull.Value))
                        upd.Parameters.AddWithValue("@wpmt", If(p.PaymentMethodTitle <> "",     CObj(p.PaymentMethodTitle),      DBNull.Value))
                        upd.Parameters.AddWithValue("@wdm",  If(p.WcDateModified.HasValue,      CObj(p.WcDateModified.Value),    DBNull.Value))
                        upd.Parameters.AddWithValue("@wnum", If(p.WcOrderNumber <> "",          CObj(p.WcOrderNumber),           DBNull.Value))
                        upd.Parameters.AddWithValue("@wurl", If(p.WcOrderKey <> "",             CObj(p.WcOrderKey),              DBNull.Value))
                        upd.Parameters.AddWithValue("@ep",   estadoPago)
                        upd.Parameters.AddWithValue("@eo",   estadoOperativo)
                        upd.Parameters.AddWithValue("@tbs",  totalBs)
                        upd.Parameters.AddWithValue("@tusd", totalUsd)
                        upd.Parameters.AddWithValue("@ebs",  envioBs)
                        upd.Parameters.AddWithValue("@eusd", envioUsd)
                        upd.Parameters.AddWithValue("@dbs",  descBs)
                        upd.Parameters.AddWithValue("@dusd", descUsd)
                        upd.Parameters.AddWithValue("@obs",  If(p.Observaciones <> "",          CObj(p.Observaciones),           DBNull.Value))
                        upd.Parameters.AddWithValue("@gps",  If(p.Gps <> "",                   CObj(p.Gps),                     DBNull.Value))
                        upd.Parameters.AddWithValue("@u",    uid)
                        upd.Parameters.AddWithValue("@pid",  pedidoExistenteId)
                        upd.ExecuteNonQuery()
                    End Using
                    Log("InsertarPedido", "WC#" & p.WcId & " ACTUALIZADO → pedido_id=" & pedidoExistenteId & " estado=" & estadoPago)
                Catch ex As Exception
                    Log("InsertarPedido", "WC#" & p.WcId & " - ERROR en UPDATE: " & ex.Message)
                    Return "E"
                End Try

                ' Actualizar pago si cambio a PAGADO
                ActualizarOInsertarPago(conn, pedidoExistenteId, p, totalBs, totalUsd, estadoPago, uid)

                Return "A"
            End If

            ' ============================================================
            ' CASO B: PEDIDO NUEVO → INSERTAR
            ' ============================================================

            ' --- 4. Resolver slot_id ---
            Dim slotId As Object = DBNull.Value
            If p.DeliveryTime <> "" Then
                slotId = ObtenerOCrearSlot(conn, p.DeliveryTime)
                If slotId Is DBNull.Value Then
                    Log("InsertarPedido", "WC#" & p.WcId & " - No se pudo resolver slot '" & p.DeliveryTime & "'")
                End If
            End If

            ' --- 5. Resolver zona_id ---
            Dim zonaId As Object = DBNull.Value
            If p.ShippingState <> "" Then
                zonaId = ObtenerOCrearZona(conn, p.ShippingState)
                If zonaId Is DBNull.Value Then
                    Log("InsertarPedido", "WC#" & p.WcId & " - No se pudo resolver zona '" & p.ShippingState & "'")
                End If
            End If

            ' --- 6. Crear Pedido via SP ---
            Dim receptorNombre As String = If(p.ShippingNombre <> "", p.ShippingNombre, If(p.BillingNombre <> "", (p.BillingNombre & " " & p.BillingApellidos).Trim(), "Sin nombre"))
            Dim receptorCel    As String = If(p.ShippingPhone <> "", p.ShippingPhone, If(p.TelefonoRecibe <> "", p.TelefonoRecibe, If(p.BillingPhone <> "", p.BillingPhone, "00000000")))
            Dim direccion      As String = If(p.Direccion <> "", p.Direccion, "Sin direccion")
            Dim fechaEntrega   As DateTime = If(p.DeliveryDate.HasValue, p.DeliveryDate.Value, DateTime.Now.AddDays(1))

            Dim pedId As Integer = 0
            Try
                Using cmd As New SqlCommand("FLORERIA_sp_Pedido_Crear", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@receptor_nombre",  receptorNombre.Substring(0, Math.Min(200, receptorNombre.Length)))
                    cmd.Parameters.AddWithValue("@receptor_celular", receptorCel.Substring(0, Math.Min(20, receptorCel.Length)))
                    cmd.Parameters.AddWithValue("@ciudad_id",        1)
                    cmd.Parameters.AddWithValue("@zona_id",          zonaId)
                    cmd.Parameters.AddWithValue("@tipo_entrega",     "DOMICILIO")
                    cmd.Parameters.AddWithValue("@direccion",        direccion.Substring(0, Math.Min(300, direccion.Length)))
                    cmd.Parameters.AddWithValue("@fecha_entrega",    fechaEntrega)
                    cmd.Parameters.AddWithValue("@slot_id",          slotId)
                    cmd.Parameters.AddWithValue("@dedicatoria",      If(p.MensajeTarjeta <> "", CObj(p.MensajeTarjeta), DBNull.Value))
                    cmd.Parameters.AddWithValue("@firma_tarjeta",    If(p.FirmaTarjeta <> "",   CObj(p.FirmaTarjeta),   DBNull.Value))
                    cmd.Parameters.AddWithValue("@wc_order_id",      p.WcId)
                    cmd.Parameters.AddWithValue("@tipo_ocacion",     MapearTipoOcacion(p.TipoOcacion))
                    cmd.Parameters.AddWithValue("@nota_floreria",    If(p.NotaFloreria <> "",   CObj(p.NotaFloreria),   DBNull.Value))
                    cmd.Parameters.AddWithValue("@creado_por",       uid)
                    cmd.Parameters.AddWithValue("@ip",               ip)
                    Dim pPedId As New SqlParameter("@pedido_id", SqlDbType.Int)         With {.Direction = ParameterDirection.Output}
                    Dim pCodP  As New SqlParameter("@codigo",    SqlDbType.VarChar, 20) With {.Direction = ParameterDirection.Output}
                    cmd.Parameters.Add(pPedId) : cmd.Parameters.Add(pCodP)
                    cmd.ExecuteNonQuery()
                    pedId = Convert.ToInt32(pPedId.Value)
                End Using
            Catch ex As Exception
                Log("InsertarPedido", "WC#" & p.WcId & " - ERROR en SP Pedido_Crear: " & ex.Message)
                Return "E"
            End Try

            ' --- 7. UPDATE campos extra que SP no recibe (incluye nuevas columnas WC) ---
            Try
                Using upd As New SqlCommand(
                    "UPDATE FLORERIA_Pedido SET " &
                    "  wc_order_number=@wnum, wc_order_url=@wurl, " &
                    "  wc_order_status=@wst, " &
                    "  wc_date_paid=@wdp, " &
                    "  wc_payment_method=@wpm, " &
                    "  wc_payment_method_title=@wpmt, " &
                    "  wc_date_modified=@wdm, " &
                    "  estado_pago=@ep, " &
                    "  estado_operativo=@eo, " &
                    "  gps=@gps, observaciones=@obs, " &
                    "  total_bs=@tbs, total_usd=@tusd, " &
                    "  envio_bs=@ebs, envio_usd=@eusd, " &
                    "  descuento_bs=@dbs, descuento_usd=@dusd, " &
                    "  wc_sync_estado='SINCRONIZADO', wc_sync_fecha=GETDATE() " &
                    "WHERE pedido_id=@pid", conn)
                    upd.Parameters.AddWithValue("@wnum", If(p.WcOrderNumber <> "",      CObj(p.WcOrderNumber),       DBNull.Value))
                    upd.Parameters.AddWithValue("@wurl", If(p.WcOrderKey <> "",         CObj(p.WcOrderKey),          DBNull.Value))
                    upd.Parameters.AddWithValue("@wst",  If(p.WcOrderStatus <> "",      CObj(p.WcOrderStatus),       DBNull.Value))
                    upd.Parameters.AddWithValue("@wdp",  If(p.WcDatePaid.HasValue,      CObj(p.WcDatePaid.Value),    DBNull.Value))
                    upd.Parameters.AddWithValue("@wpm",  If(p.PaymentMethod <> "",      CObj(p.PaymentMethod),       DBNull.Value))
                    upd.Parameters.AddWithValue("@wpmt", If(p.PaymentMethodTitle <> "", CObj(p.PaymentMethodTitle),  DBNull.Value))
                    upd.Parameters.AddWithValue("@wdm",  If(p.WcDateModified.HasValue,  CObj(p.WcDateModified.Value),DBNull.Value))
                    upd.Parameters.AddWithValue("@ep",   estadoPago)
                    upd.Parameters.AddWithValue("@eo",   estadoOperativo)
                    upd.Parameters.AddWithValue("@gps",  If(p.Gps <> "",               CObj(p.Gps),                 DBNull.Value))
                    upd.Parameters.AddWithValue("@obs",  If(p.Observaciones <> "",      CObj(p.Observaciones),       DBNull.Value))
                    upd.Parameters.AddWithValue("@tbs",  totalBs)
                    upd.Parameters.AddWithValue("@tusd", totalUsd)
                    upd.Parameters.AddWithValue("@ebs",  envioBs)
                    upd.Parameters.AddWithValue("@eusd", envioUsd)
                    upd.Parameters.AddWithValue("@dbs",  descBs)
                    upd.Parameters.AddWithValue("@dusd", descUsd)
                    upd.Parameters.AddWithValue("@pid",  pedId)
                    upd.ExecuteNonQuery()
                End Using
            Catch ex As Exception
                Log("InsertarPedido", "WC#" & p.WcId & " - AVISO UPDATE campos extra: " & ex.Message)
            End Try

            ' --- 8. Insertar line_items ---
            For Each item As WcPedidoItem In p.Items
                Try
                    Dim prodId As Object = DBNull.Value
                    If item.WcProductId > 0 Then
                        Using pCmd As New SqlCommand("SELECT producto_id FROM FLORERIA_Producto WHERE wc_product_id=@w", conn)
                            pCmd.Parameters.AddWithValue("@w", item.WcProductId)
                            Dim pObj As Object = pCmd.ExecuteScalar()
                            If pObj IsNot Nothing AndAlso Not IsDBNull(pObj) Then prodId = pObj
                        End Using
                    End If

                    Dim precioBs  As Decimal = item.PrecioUnitarioBs
                    Dim precioUsd As Decimal = If(tasa > 0, Math.Round(precioBs * tasa, 2), 0D)
                    Dim subtotBs  As Decimal = item.SubtotalBs
                    Dim subtotUsd As Decimal = If(tasa > 0, Math.Round(subtotBs * tasa, 2), 0D)

                    Using dCmd As New SqlCommand("FLORERIA_sp_Pedido_AgregarProducto", conn)
                        dCmd.CommandType = CommandType.StoredProcedure
                        dCmd.Parameters.AddWithValue("@pedido_id",           pedId)
                        dCmd.Parameters.AddWithValue("@producto_id",         prodId)
                        dCmd.Parameters.AddWithValue("@es_personalizado",    0)
                        dCmd.Parameters.AddWithValue("@nombre_producto",     item.NombreProducto.Substring(0, Math.Min(200, item.NombreProducto.Length)))
                        dCmd.Parameters.AddWithValue("@cantidad",            item.Cantidad)
                        dCmd.Parameters.AddWithValue("@precio_unitario_bs",  precioBs)
                        dCmd.Parameters.AddWithValue("@precio_unitario_usd", precioUsd)
                        dCmd.Parameters.AddWithValue("@personalizacion",     If(item.Personalizacion <> "", CObj(item.Personalizacion), DBNull.Value))
                        dCmd.ExecuteNonQuery()
                    End Using

                    If item.WcLineItemId > 0 Then
                        Try
                            Using updItem As New SqlCommand(
                                "UPDATE TOP(1) FLORERIA_Pedido_Detalle SET wc_line_item_id=@wli " &
                                "WHERE pedido_id=@pid AND nombre_producto=@nom AND wc_line_item_id IS NULL", conn)
                                updItem.Parameters.AddWithValue("@wli", item.WcLineItemId)
                                updItem.Parameters.AddWithValue("@pid", pedId)
                                updItem.Parameters.AddWithValue("@nom", item.NombreProducto.Substring(0, Math.Min(200, item.NombreProducto.Length)))
                                updItem.ExecuteNonQuery()
                            End Using
                        Catch ex As Exception
                            Log("InsertarPedido", "WC#" & p.WcId & " - AVISO wc_line_item_id=" & item.WcLineItemId & ": " & ex.Message)
                        End Try
                    End If
                Catch ex As Exception
                    Log("InsertarPedido", "WC#" & p.WcId & " - ERROR line_item WcProductId=" & item.WcProductId & " '" & item.NombreProducto & "': " & ex.Message)
                End Try
            Next

            ' --- 9. Registrar pago en FLORERIA_Pedido_Pago ---
            ActualizarOInsertarPago(conn, pedId, p, totalBs, totalUsd, estadoPago, uid)

            Log("InsertarPedido", "WC#" & p.WcId & " INSERTADO OK → pedido_id=" & pedId & " estado_pago=" & estadoPago)
            Return "I"

        Catch ex As Exception
            Log("InsertarPedido", "WC#" & p.WcId & " - ERROR CRITICO: " & ex.Message & " | " & ex.StackTrace.Substring(0, Math.Min(200, ex.StackTrace.Length)))
            Return "E"
        End Try
    End Function

    ' ============================================================
    ' MapearMetodoPago
    '   Convierte el valor de WC al CHECK constraint
    '   BD acepta: PAYPAL, QR, TRANSFERENCIA, TARJETA, EFECTIVO,
    '              PIX, YAPE, CRIPTO, PAGOMOVIL
    ' ============================================================
    Private Function MapearMetodoPago(method As String, title As String) As String
        Dim m As String = If(method, "").ToLower().Trim()
        Dim t As String = If(title,  "").ToLower().Trim()

        ' PayPal y tarjetas via PayPal
        If m.Contains("paypal") OrElse t.Contains("paypal") Then Return "PAYPAL"
        If m.Contains("ppcp")   OrElse m.Contains("ppec")   Then Return "PAYPAL"
        If m.Contains("card")   OrElse t.Contains("tarjeta") OrElse t.Contains("card") Then Return "TARJETA"

        ' QR Bolivia (Banco Nacional, etc.)
        If m.Contains("bnb") OrElse m.Contains("banconacional") OrElse m.Contains("qr") OrElse t.Contains("qr") Then Return "QR"

        ' Libelula
        If m.Contains("libelula") OrElse t.Contains("libelula") Then Return "TRANSFERENCIA"

        ' Transferencia
        If m.Contains("bacs") OrElse m.Contains("transfer") OrElse t.Contains("transfer") Then Return "TRANSFERENCIA"

        ' Efectivo / contra entrega
        If m.Contains("cod") OrElse m.Contains("cash") OrElse t.Contains("efectivo") OrElse t.Contains("contra entrega") Then Return "EFECTIVO"

        ' Default: si no sabemos, usar TRANSFERENCIA (es lo mas seguro y editable luego)
        Return "TRANSFERENCIA"
    End Function

    ' ============================================================
    ' MapearTipoOcacion
    '   Convierte el valor libre de WC al valor del CHECK constraint
    '   BD acepta: CUMPLEANOS, ANIVERSARIO, AMOR, AGRADECIMIENTO,
    '              CONDOLENCIAS, GRADUACION, NACIMIENTO, OTRO
    ' ============================================================
    Private Function MapearTipoOcacion(valorWC As String) As String
        If valorWC Is Nothing OrElse valorWC.Trim() = "" Then Return "OTRO"
        Select Case valorWC.Trim().ToLower()
            Case "cumpleaños", "cumpleanos", "cumpleano", "birthday"
                Return "CUMPLEANOS"
            Case "aniversario", "anniversary", "anniversario"
                Return "ANIVERSARIO"
            Case "amor", "te amo", "love", "san valentin", "san valentín", "valentín", "valentin"
                Return "AMOR"
            Case "agradecimiento", "gracias", "thank you", "thanks"
                Return "AGRADECIMIENTO"
            Case "condolencias", "pesames", "pésames", "funeral", "sepelio"
                Return "CONDOLENCIAS"
            Case "graduacion", "graduación", "graduation", "grado", "titulacion", "titulación"
                Return "GRADUACION"
            Case "nacimiento", "bebe", "bebé", "baby shower", "bienvenida"
                Return "NACIMIENTO"
            Case Else
                Return "OTRO"
        End Select
    End Function
    '   Registra o actualiza el pago en FLORERIA_Pedido_Pago
    '   Solo inserta si no existe ya un pago para ese pedido_id
    ' ============================================================
    Private Sub ActualizarOInsertarPago(conn As SqlConnection, pedId As Integer, p As WcPedido,
                                         totalBs As Decimal, totalUsd As Decimal,
                                         estadoPago As String, uid As Integer)
        Try
            ' Ver si ya existe un pago para este pedido
            Dim pagoExiste As Boolean = False
            Using chk As New SqlCommand("SELECT COUNT(1) FROM FLORERIA_Pedido_Pago WHERE pedido_id=@pid", conn)
                chk.Parameters.AddWithValue("@pid", pedId)
                pagoExiste = (CInt(chk.ExecuteScalar()) > 0)
            End Using

            ' Estado del pago: PayPal con date_paid = VERIFICADO, resto = PENDIENTE
            Dim estadoRegistro As String = "PENDIENTE"
            If p.WcDatePaid.HasValue AndAlso p.PaymentMethod.ToLower().Contains("paypal") Then
                estadoRegistro = "VERIFICADO"
            End If

            ' Referencia: transaction_id de PayPal o wc_order_number
            Dim referencia As String = If(p.PaypalOrderId <> "", p.PaypalOrderId, If(p.WcOrderNumber <> "", "WC#" & p.WcOrderNumber, ""))

            ' Metodo de pago legible
            ' Mapear metodo_pago al CHECK constraint (PAYPAL/QR/TRANSFERENCIA/TARJETA/EFECTIVO/...)
            Dim metodoPago As String = MapearMetodoPago(p.PaymentMethod, p.PaymentMethodTitle)

            If Not pagoExiste Then
                ' INSERT nuevo registro de pago
                Using ins As New SqlCommand(
                    "INSERT INTO FLORERIA_Pedido_Pago(pedido_id,tipo_pago,metodo_pago,monto_bs,monto_usd," &
                    "referencia,estado,observaciones,creado_por,creado_en) " &
                    "VALUES(@pid,'TOTAL',@mp,@mbs,@musd,@ref,@est,@obs,@u,GETDATE())", conn)
                    ins.Parameters.AddWithValue("@pid",  pedId)
                    ins.Parameters.AddWithValue("@mp",   metodoPago)
                    ins.Parameters.AddWithValue("@mbs",  totalBs)
                    ins.Parameters.AddWithValue("@musd", totalUsd)
                    ins.Parameters.AddWithValue("@ref",  If(referencia <> "", CObj(referencia), DBNull.Value))
                    ins.Parameters.AddWithValue("@est",  estadoRegistro)
                    ins.Parameters.AddWithValue("@obs",  If(p.WcOrderStatus <> "", CObj("WC status: " & p.WcOrderStatus), DBNull.Value))
                    ins.Parameters.AddWithValue("@u",    uid)
                    ins.ExecuteNonQuery()
                    Log("ActualizarOInsertarPago", "Pago registrado pedido_id=" & pedId & " metodo=" & metodoPago & " estado=" & estadoRegistro)
                End Using
            Else
                ' UPDATE solo si el estado mejoro (PENDIENTE → VERIFICADO)
                If estadoRegistro = "VERIFICADO" Then
                    Using upd As New SqlCommand(
                        "UPDATE FLORERIA_Pedido_Pago SET estado=@est, referencia=@ref, " &
                        "metodo_pago=@mp, monto_bs=@mbs, monto_usd=@musd " &
                        "WHERE pedido_id=@pid AND estado='PENDIENTE'", conn)
                        upd.Parameters.AddWithValue("@est",  estadoRegistro)
                        upd.Parameters.AddWithValue("@ref",  If(referencia <> "", CObj(referencia), DBNull.Value))
                        upd.Parameters.AddWithValue("@mp",   metodoPago)
                        upd.Parameters.AddWithValue("@mbs",  totalBs)
                        upd.Parameters.AddWithValue("@musd", totalUsd)
                        upd.Parameters.AddWithValue("@pid",  pedId)
                        upd.ExecuteNonQuery()
                        Log("ActualizarOInsertarPago", "Pago actualizado a VERIFICADO pedido_id=" & pedId)
                    End Using
                End If
            End If
        Catch ex As Exception
            Log("ActualizarOInsertarPago", "pedido_id=" & pedId & " - ERROR: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' ObtenerOCrearSlot
    '   Busca slot por wc_slot_value. Si no existe lo crea activo=0
    ' ============================================================
    Private Function ObtenerOCrearSlot(conn As SqlConnection, deliveryTime As String) As Object
        Try
            ' Buscar existente
            Using cmd As New SqlCommand("SELECT slot_id FROM FLORERIA_Slot_Horario WHERE wc_slot_value=@v", conn)
                cmd.Parameters.AddWithValue("@v", deliveryTime)
                Dim r As Object = cmd.ExecuteScalar()
                If r IsNot Nothing AndAlso Not IsDBNull(r) Then
                    Return CInt(r)
                End If
            End Using

            ' Parsear horas del string "HH:mm - HH:mm"
            Dim partes() As String = deliveryTime.Split(New String() {" - "}, StringSplitOptions.RemoveEmptyEntries)
            Dim horaInicio As String = If(partes.Length > 0, partes(0).Trim() & ":00", "00:00:00")
            Dim horaFin    As String = If(partes.Length > 1, partes(1).Trim() & ":00", "00:00:00")

            ' Calcular duracion en minutos
            Dim duracion As Integer = 180
            Try
                Dim dtIn  As DateTime = DateTime.Parse(partes(0).Trim())
                Dim dtFin As DateTime = DateTime.Parse(partes(1).Trim())
                duracion = CInt((dtFin - dtIn).TotalMinutes)
                If duracion <= 0 Then duracion = 180
            Catch
            End Try

            ' Crear slot deshabilitado
            Using cmd As New SqlCommand(
                "INSERT INTO FLORERIA_Slot_Horario(ciudad_id,etiqueta,hora_inicio,hora_fin,duracion_minutos," &
                "recargo_bs,es_express,activo,orden_display,wc_slot_value,creado_en) " &
                "VALUES(1,@etq,@hi,@hf,@dur,0,0,0,0,@wv,GETDATE()); SELECT SCOPE_IDENTITY();", conn)
                cmd.Parameters.AddWithValue("@etq", deliveryTime)
                cmd.Parameters.AddWithValue("@hi",  horaInicio)
                cmd.Parameters.AddWithValue("@hf",  horaFin)
                cmd.Parameters.AddWithValue("@dur", duracion)
                cmd.Parameters.AddWithValue("@wv",  deliveryTime)
                Dim newId As Object = cmd.ExecuteScalar()
                Log("ObtenerOCrearSlot", "Slot creado activo=0 para '" & deliveryTime & "' → slot_id=" & newId.ToString())
                Return CInt(newId)
            End Using
        Catch ex As Exception
            Log("ObtenerOCrearSlot", "ERROR con '" & deliveryTime & "': " & ex.Message)
            Return DBNull.Value
        End Try
    End Function

    ' ============================================================
    ' ============================================================
    ' ObtenerOCrearZona
    '   Busca zona por wc_zone_code. Si no existe la crea activo=0
    '   IMPORTANTE: usa conexion separada para el INSERT asi el
    '   commit es inmediato y la FK del SP Pedido_Crear lo encuentra
    ' ============================================================
    Private Function ObtenerOCrearZona(conn As SqlConnection, wcZoneCode As String) As Object
        Try
            ' Buscar existente en la conexion actual
            Using cmd As New SqlCommand("SELECT zona_id FROM FLORERIA_Zona WHERE wc_zone_code=@c", conn)
                cmd.Parameters.AddWithValue("@c", wcZoneCode)
                Dim r As Object = cmd.ExecuteScalar()
                If r IsNot Nothing AndAlso Not IsDBNull(r) Then Return CInt(r)
            End Using

            ' No existe — crear en conexion SEPARADA para garantizar commit antes del SP
            Dim codigoFinal As String = wcZoneCode.Substring(0, Math.Min(20, wcZoneCode.Length))
            Dim newZonaId   As Integer = 0

            Using conn2 As New SqlConnection(SesionHelper.ObtenerCadena())
                conn2.Open()

                ' Verificar que el codigo no exista ya
                Using chk As New SqlCommand("SELECT COUNT(1) FROM FLORERIA_Zona WHERE codigo=@c AND ciudad_id=1", conn2)
                    chk.Parameters.AddWithValue("@c", codigoFinal)
                    If CInt(chk.ExecuteScalar()) > 0 Then codigoFinal = wcZoneCode & "_WC"
                End Using

                ' Doble check — puede que otro hilo la haya creado
                Using chk2 As New SqlCommand("SELECT zona_id FROM FLORERIA_Zona WHERE wc_zone_code=@c", conn2)
                    chk2.Parameters.AddWithValue("@c", wcZoneCode)
                    Dim r2 As Object = chk2.ExecuteScalar()
                    If r2 IsNot Nothing AndAlso Not IsDBNull(r2) Then Return CInt(r2)
                End Using

                Using ins As New SqlCommand(
                    "INSERT INTO FLORERIA_Zona(ciudad_id,nombre,codigo,tipo,activo,orden_display,wc_zone_code,creado_en) " &
                    "VALUES(1,@nom,@cod,'DELIVERY',0,0,@wc,GETDATE()); SELECT SCOPE_IDENTITY();", conn2)
                    ins.Parameters.AddWithValue("@nom", wcZoneCode.Substring(0, Math.Min(150, wcZoneCode.Length)))
                    ins.Parameters.AddWithValue("@cod", codigoFinal)
                    ins.Parameters.AddWithValue("@wc",  wcZoneCode)
                    Dim newId As Object = ins.ExecuteScalar()
                    newZonaId = CInt(newId)
                End Using
            End Using

            Log("ObtenerOCrearZona", "Zona creada activo=0 para '" & wcZoneCode & "' → zona_id=" & newZonaId)
            Return newZonaId

        Catch ex As Exception
            Log("ObtenerOCrearZona", "ERROR con '" & wcZoneCode & "': " & ex.Message)
            Return DBNull.Value
        End Try
    End Function

    ' ============================================================
    ' ParsearCats
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
                cat.WcId       = ExtraerEntero(obj, "id")
                cat.PadreWcId  = ExtraerEntero(obj, "parent")
                cat.Nombre     = ExtraerStr(obj, "name")
                cat.Slug       = ExtraerStr(obj, "slug")
                cat.Descripcion = LimpiarHtml(ExtraerStr(obj, "description"))
                If cat.WcId > 0 AndAlso cat.Nombre <> "" Then lista.Add(cat)
                idx = items.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch ex As Exception
            Log("ParsearCats", "ERROR: " & ex.Message)
        End Try
        Return lista
    End Function

    ' ============================================================
    ' ParsearProds
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
                prod.WcId       = ExtraerEntero(obj, "id")
                prod.Nombre     = ExtraerStr(obj, "name")
                prod.Sku        = ExtraerStr(obj, "sku")
                prod.Descripcion = LimpiarHtml(ExtraerStr(obj, "description"))
                prod.PrecioBS   = ExtraerStr(obj, "price")
                prod.PromoBS    = ExtraerStr(obj, "sale_price")
                prod.PromoDesde = ExtraerStr(obj, "date_on_sale_from")
                prod.PromoHasta = ExtraerStr(obj, "date_on_sale_to")
                prod.Tipo       = ExtraerStr(obj, "type")
                prod.Destacado  = (ExtraerStr(obj, "featured") = "true")
                prod.MenuOrder  = ExtraerEntero(obj, "menu_order")
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
            Log("ParsearProds", "ERROR: " & ex.Message)
        End Try
        Return lista
    End Function

    ' ============================================================
    ' ParsearPedidos - mapeo basado en JSON real de miss-flores.com
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

                ' --- Campos raiz ---
                ped.WcId               = ExtraerEntero(obj, "id")
                ped.WcOrderNumber      = ExtraerStr(obj, "number")
                ped.WcOrderKey         = ExtraerStr(obj, "order_key")
                ped.WcOrderStatus      = ExtraerStr(obj, "status")
                ped.PaymentMethod      = ExtraerStr(obj, "payment_method")
                ped.PaymentMethodTitle = ExtraerStr(obj, "payment_method_title")
                ped.Observaciones      = ExtraerStr(obj, "customer_note")

                ' date_paid (null si no pago)
                Dim datePaidStr As String = ExtraerStr(obj, "date_paid")
                If datePaidStr <> "" AndAlso datePaidStr <> "null" Then
                    Dim dtPaid As DateTime
                    If DateTime.TryParse(datePaidStr, dtPaid) Then ped.WcDatePaid = dtPaid
                End If

                ' date_modified (para detectar cambios en reruns)
                Dim dateModStr As String = ExtraerStr(obj, "date_modified")
                If dateModStr <> "" Then
                    Dim dtMod As DateTime
                    If DateTime.TryParse(dateModStr, dtMod) Then ped.WcDateModified = dtMod
                End If

                Dim totalStr As String = ExtraerStr(obj, "total")
                Decimal.TryParse(totalStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, ped.TotalBs)

                Dim envioStr As String = ExtraerStr(obj, "shipping_total")
                Decimal.TryParse(envioStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, ped.EnvioBs)

                Dim descStr As String = ExtraerStr(obj, "discount_total")
                Decimal.TryParse(descStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, ped.DescuentoBs)

                ' --- Billing (quien compra) ---
                Dim posBilling As Integer = obj.IndexOf("""billing""")
                If posBilling >= 0 Then
                    Dim billingObj As String = ExtraerObjeto(obj, posBilling)
                    If billingObj <> "" Then
                        ped.BillingNombre    = ExtraerStr(billingObj, "first_name").Trim()
                        ped.BillingApellidos = ExtraerStr(billingObj, "last_name").Trim()
                        ped.BillingEmail     = ExtraerStr(billingObj, "email").Trim()
                        ped.BillingPhone     = ExtraerStr(billingObj, "phone").Trim()
                    End If
                End If

                ' --- Shipping (quien recibe) ---
                Dim posShipping As Integer = obj.IndexOf("""shipping""")
                If posShipping >= 0 Then
                    Dim shippingObj As String = ExtraerObjeto(obj, posShipping)
                    If shippingObj <> "" Then
                        Dim sNom  As String = ExtraerStr(shippingObj, "first_name").Trim()
                        Dim sApe  As String = ExtraerStr(shippingObj, "last_name").Trim()
                        ped.ShippingNombre = If(sApe <> "", sNom & " " & sApe, sNom).Trim()
                        ped.ShippingPhone  = ExtraerStr(shippingObj, "phone").Trim()
                        Dim dir1 As String = ExtraerStr(shippingObj, "address_1").Trim()
                        Dim dir2 As String = ExtraerStr(shippingObj, "address_2").Trim()
                        ped.Direccion      = If(dir2 <> "", dir1 & " " & dir2, dir1).Trim()
                        ped.ShippingState  = ExtraerStr(shippingObj, "state").Trim()
                    End If
                End If

                ' --- Meta_data ---
                Dim metaArr As String = ExtraerArray(obj, "meta_data")
                If metaArr <> "" Then
                    ped.TelefonoRecibe = ExtraerMetaValor(metaArr, "TelefonoRecibe")
                    ped.DeliveryTime   = ExtraerMetaValor(metaArr, "delivery_time")
                    ped.MensajeTarjeta = ExtraerMetaValor(metaArr, "mensaje_tarjeta")
                    ped.FirmaTarjeta   = ExtraerMetaValor(metaArr, "firma_tarjeta")
                    ped.TipoOcacion    = ExtraerMetaValor(metaArr, "tipo_de_ocacion")
                    ped.NotaFloreria   = ExtraerMetaValor(metaArr, "nota_floreria")
                    ped.Gps            = ExtraerMetaValor(metaArr, "gps")
                    ped.PaypalOrderId  = ExtraerMetaValor(metaArr, "_ppcp_paypal_order_id")

                    ' Tasa de cambio BOB→USD
                    Dim rateStr As String = ExtraerMetaValor(metaArr, "_woocs_order_rate")
                    If rateStr <> "" Then
                        Decimal.TryParse(rateStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, ped.WoocsRate)
                    End If

                    ' Fecha de entrega real (delivery_date, NO date_created)
                    Dim fechaStr As String = ExtraerMetaValor(metaArr, "delivery_date")
                    If fechaStr <> "" Then
                        Dim dtParsed As DateTime
                        If DateTime.TryParse(fechaStr, dtParsed) Then ped.DeliveryDate = dtParsed
                    End If
                End If

                ' Fallback telefono receptor: shipping.phone > TelefonoRecibe > billing.phone
                If ped.ShippingPhone = "" AndAlso ped.TelefonoRecibe <> "" Then
                    ped.ShippingPhone = ped.TelefonoRecibe
                End If

                ' --- Line items ---
                Dim lineItemsJson As String = ExtraerArray(obj, "line_items")
                If lineItemsJson <> "" Then
                    ped.Items = ParsearLineItems(lineItemsJson)
                End If

                If ped.WcId > 0 Then lista.Add(ped)

                idx = items.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch ex As Exception
            Log("ParsearPedidos", "ERROR: " & ex.Message)
        End Try
        Return lista
    End Function

    ' ============================================================
    ' ParsearLineItems
    ' ============================================================
    Private Function ParsearLineItems(json As String) As List(Of WcPedidoItem)
        Dim lista As New List(Of WcPedidoItem)()
        Try
            Dim idx As Integer = 1
            While idx < json.Length
                Dim obj As String = ExtraerObjeto(json, idx)
                If obj = "" Then Exit While
                Dim item As New WcPedidoItem()
                item.WcLineItemId   = ExtraerEntero(obj, "id")
                item.WcProductId    = ExtraerEntero(obj, "product_id")
                item.NombreProducto = ExtraerStr(obj, "name")
                item.Cantidad       = ExtraerEntero(obj, "quantity")
                If item.Cantidad <= 0 Then item.Cantidad = 1

                Dim precStr As String = ExtraerStr(obj, "price")
                If precStr <> "" Then Decimal.TryParse(precStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, item.PrecioUnitarioBs)
                If item.PrecioUnitarioBs <= 0 Then item.PrecioUnitarioBs = 1

                Dim subStr As String = ExtraerStr(obj, "subtotal")
                If subStr <> "" Then Decimal.TryParse(subStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, item.SubtotalBs)
                If item.SubtotalBs <= 0 Then item.SubtotalBs = item.PrecioUnitarioBs * item.Cantidad

                ' Meta del item (personalizacion)
                Dim metaJson As String = ExtraerArray(obj, "meta_data")
                If metaJson <> "" Then
                    item.Personalizacion = ExtraerMetaValor(metaJson, "personalizacion")
                End If

                If item.NombreProducto <> "" Then lista.Add(item)
                idx = json.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch ex As Exception
            Log("ParsearLineItems", "ERROR: " & ex.Message)
        End Try
        Return lista
    End Function

    ' ============================================================
    ' ExtraerMetaValor - busca key en array meta_data
    ' ============================================================
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

    ' ============================================================
    ' Utilidades JSON minimal
    ' ============================================================
    Private Function ExtraerObjeto(json As String, start As Integer) As String
        Try
            Dim idx   As Integer = json.IndexOf("{"c, start)
            If idx < 0 Then Return ""
            Dim depth As Integer = 0
            Dim ini   As Integer = idx
            While idx < json.Length
                If json(idx) = "{"c Then depth += 1
                If json(idx) = "}"c Then
                    depth -= 1
                    If depth = 0 Then Return json.Substring(ini, idx - ini + 1)
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
            Dim idx    As Integer = json.IndexOf(patron)
            If idx < 0 Then Return ""
            idx += patron.Length
            While idx < json.Length AndAlso (json(idx) = " "c OrElse json(idx) = ":"c)
                idx += 1
            End While
            If idx >= json.Length OrElse json(idx) <> "["c Then Return ""
            Dim depth As Integer = 0
            Dim ini   As Integer = idx
            While idx < json.Length
                If json(idx) = "["c Then depth += 1
                If json(idx) = "]"c Then
                    depth -= 1
                    If depth = 0 Then Return json.Substring(ini, idx - ini + 1)
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
            Dim idx    As Integer = json.IndexOf(patron)
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
                                    Dim hex  As String  = json.Substring(idx + 1, 4)
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
        Dim v As String  = ExtraerStr(json, campo)
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

    ' ============================================================
    ' Helpers
    ' ============================================================
    Private Sub EscribirJS(key As String, script As String)
        ClientScript.RegisterStartupScript(Me.GetType(), key, script, True)
    End Sub

    Private Function EscJs(texto As String) As String
        If texto Is Nothing Then Return ""
        Return texto.Replace("\", "\\").Replace("'", "\'").Replace("""", "\""").
                     Replace(vbCr, "").Replace(vbLf, " ").Replace(vbTab, " ").
                     Substring(0, Math.Min(200, texto.Length))
    End Function

    Private Sub Log(origen As String, mensaje As String)
        System.Diagnostics.Debug.WriteLine("[MIGRAR][" & origen & "] " & mensaje)
    End Sub

    ' ============================================================
    ' Clases internas
    ' ============================================================
    Private Class WcCat
        Public Property WcId        As Integer
        Public Property PadreWcId   As Integer
        Public Property Nombre      As String = ""
        Public Property Slug        As String = ""
        Public Property Descripcion As String = ""
    End Class

    Private Class WcProd
        Public Property WcId        As Integer
        Public Property Nombre      As String = ""
        Public Property Sku         As String = ""
        Public Property Descripcion As String = ""
        Public Property PrecioBS    As String = ""
        Public Property PromoBS     As String = ""
        Public Property PromoDesde  As String = ""
        Public Property PromoHasta  As String = ""
        Public Property Tipo        As String = "simple"
        Public Property Destacado   As Boolean = False
        Public Property MenuOrder   As Integer = 0
        Public Property ImagenUrl   As String = ""
    End Class

    Private Class WcPedido
        ' Raiz
        Public Property WcId               As Integer
        Public Property WcOrderNumber      As String = ""
        Public Property WcOrderKey         As String = ""
        Public Property WcOrderStatus      As String = ""   ' on-hold, processing, entregado, failed...
        Public Property WcDatePaid         As DateTime?     ' date_paid de WC
        Public Property WcDateModified     As DateTime?     ' date_modified de WC
        Public Property PaymentMethod      As String = ""   ' banconacionalboliviapay, paypal...
        Public Property PaymentMethodTitle As String = ""   ' Paga con QR, PayPal...
        Public Property PaypalOrderId      As String = ""   ' _ppcp_paypal_order_id
        Public Property Observaciones      As String = ""
        Public Property TotalBs            As Decimal
        Public Property EnvioBs            As Decimal
        Public Property DescuentoBs        As Decimal
        Public Property WoocsRate          As Decimal       ' tasa BOB→USD
        ' Billing (quien compra)
        Public Property BillingNombre      As String = ""
        Public Property BillingApellidos   As String = ""
        Public Property BillingEmail       As String = ""
        Public Property BillingPhone       As String = ""
        ' Shipping (quien recibe)
        Public Property ShippingNombre     As String = ""
        Public Property ShippingPhone      As String = ""
        Public Property Direccion          As String = ""
        Public Property ShippingState      As String = ""   ' BO164 → zona
        ' Meta_data
        Public Property TelefonoRecibe     As String = ""
        Public Property DeliveryTime       As String = ""   ' 15:00 - 18:00 → slot
        Public Property DeliveryDate       As DateTime?     ' fecha REAL de entrega
        Public Property MensajeTarjeta     As String = ""   ' → dedicatoria
        Public Property FirmaTarjeta       As String = ""   ' → firma_tarjeta
        Public Property TipoOcacion        As String = ""   ' → tipo_ocacion
        Public Property NotaFloreria       As String = ""   ' → nota_floreria
        Public Property Gps                As String = ""   ' → gps
        ' Items
        Public Property Items As New List(Of WcPedidoItem)()
    End Class

    Private Class WcPedidoItem
        Public Property WcLineItemId    As Integer
        Public Property WcProductId     As Integer
        Public Property NombreProducto  As String  = ""
        Public Property Cantidad        As Integer = 1
        Public Property PrecioUnitarioBs As Decimal
        Public Property SubtotalBs       As Decimal
        Public Property Personalizacion  As String = ""
    End Class

End Class
