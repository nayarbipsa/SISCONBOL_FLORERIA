<%@ WebHandler Language="VB" Class="Entrega_Handler" %>

Imports System
Imports System.Web
Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

' ============================================================
' SISCONBOL - Handler de Entrega (borrador)
' Archivo: Modulos/Pedidos/Entrega_Handler.ashx
' Tablas: FLORERIA_PrePedido_Entrega(_Detalle, _Pago)
' NUNCA escribe en FLORERIA_Pedido (eso lo hace el SP Confirmar)
' ============================================================
Public Class Entrega_Handler
    Implements IHttpHandler
    Implements System.Web.SessionState.IRequiresSessionState

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json"

        ' Validar sesion
        If Not SesionHelper.VerificarSesion(context) Then
            context.Response.Write("{""ok"":false,""msg"":""Sesion expirada""}")
            Return
        End If

        Dim accion As String = context.Request.Form("accion")
        If accion Is Nothing Then accion = ""

        Try
            Select Case accion
                Case "BUSCAR_PRODUCTOS"
                    BuscarProductos(context)
                Case "AGREGAR_PRODUCTO"
                    AgregarProducto(context)
                Case "ELIMINAR_DETALLE"
                    EliminarDetalle(context)
                Case "ACTUALIZAR_DETALLE"
                    ActualizarDetalle(context)
                Case "GUARDAR_CAMPO"
                    GuardarCampo(context)
                Case "AGREGAR_PAGO"
                    AgregarPago(context)
                Case "ELIMINAR_PAGO"
                    EliminarPago(context)
                Case "CONFIRMAR"
                    Confirmar(context)
                Case "CREAR_WC"
                    CrearEnWooCommerce(context)
                Case "SINCRONIZAR_PEDIDO_WC"
                    SincronizarPedidoYaCreado(context)
                Case Else
                    context.Response.Write("{""ok"":false,""msg"":""Accion no valida""}")
            End Select
        Catch ex As Exception
            context.Response.Write("{""ok"":false,""msg"":""" & ex.Message.Replace("""", "'") & """}")
        End Try
    End Sub

    ' ============================================================
    ' BUSCAR PRODUCTOS
    ' NO filtra por p.activo. Devuelve TODOS los productos.
    ' Los inactivos se marcan visualmente en el front (badge "INACTIVO").
    ' Activos van primero gracias al ORDER BY p.activo DESC.
    ' ============================================================
    Private Sub BuscarProductos(context As HttpContext)
        Dim texto As String = context.Request.Form("texto")
        If texto Is Nothing Then texto = ""
        texto = texto.Trim()

        Dim categoriaId As String = context.Request.Form("categoria_id")
        If categoriaId Is Nothing Then categoriaId = "0"

        Dim catId As Integer = 0
        Integer.TryParse(categoriaId, catId)

        Dim resultados As New List(Of Object)
        Dim serializer As New JavaScriptSerializer()

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()

            Dim sql As String = "SELECT p.producto_id, p.sku, p.nombre, p.descripcion, " &
                "p.precio_base_bs, p.precio_base_usd, p.tiene_variaciones, " &
                "p.stock_actual, p.imagen_url, p.wc_product_id, p.activo, " &
                "c.nombre AS categoria_nombre " &
                "FROM FLORERIA_Producto p " &
                "LEFT JOIN FLORERIA_Categoria c ON p.categoria_id = c.categoria_id " &
                "WHERE 1=1"

            If texto <> "" Then sql &= " AND (p.nombre LIKE @texto OR p.sku LIKE @texto)"
            If catId > 0 Then sql &= " AND p.categoria_id = @catId"
            ' Activos primero, luego inactivos. Dentro de cada grupo por menu_order/nombre.
            sql &= " ORDER BY p.activo DESC, p.menu_order, p.nombre"

            Using cmd As New SqlCommand(sql, conn)
                If texto <> "" Then cmd.Parameters.AddWithValue("@texto", "%" & texto & "%")
                If catId > 0 Then cmd.Parameters.AddWithValue("@catId", catId)

                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        resultados.Add(New With {
                            .producto_id = CInt(dr("producto_id")),
                            .sku = dr("sku").ToString(),
                            .nombre = dr("nombre").ToString(),
                            .descripcion = If(IsDBNull(dr("descripcion")), "", dr("descripcion").ToString()),
                            .precio_base_bs = CDec(dr("precio_base_bs")),
                            .precio_base_usd = If(IsDBNull(dr("precio_base_usd")), 0D, CDec(dr("precio_base_usd"))),
                            .tiene_variaciones = CBool(dr("tiene_variaciones")),
                            .stock_actual = CInt(dr("stock_actual")),
                            .imagen_url = If(IsDBNull(dr("imagen_url")), "", dr("imagen_url").ToString()),
                            .wc_product_id = If(IsDBNull(dr("wc_product_id")), 0, CInt(dr("wc_product_id"))),
                            .activo = CBool(dr("activo")),
                            .categoria = If(IsDBNull(dr("categoria_nombre")), "", dr("categoria_nombre").ToString())
                        })
                    End While
                End Using
            End Using
        End Using

        context.Response.Write("{""ok"":true,""productos"":" & serializer.Serialize(resultados) & "}")
    End Sub

    ' ============================================================
    ' AGREGAR PRODUCTO (INSERT en PrePedido_Entrega_Detalle)
    ' ============================================================
    Private Sub AgregarProducto(context As HttpContext)
        Dim entregaId As Integer = 0
        Integer.TryParse(context.Request.Form("prepedido_entrega_id"), entregaId)

        If entregaId <= 0 Then
            context.Response.Write("{""ok"":false,""msg"":""prepedido_entrega_id invalido""}")
            Return
        End If

        ' Validar que el borrador existe y esta en estado BORRADOR
        If Not ValidarBorradorEditable(entregaId) Then
            context.Response.Write("{""ok"":false,""msg"":""El borrador no existe o ya fue confirmado""}")
            Return
        End If

        Dim productoId As Integer = 0
        Integer.TryParse(context.Request.Form("producto_id"), productoId)

        Dim variacionId As String = context.Request.Form("variacion_id")
        If variacionId Is Nothing Then variacionId = ""

        Dim esPersonalizado As Boolean = (context.Request.Form("es_personalizado") = "1")

        Dim nombreProducto As String = context.Request.Form("nombre_producto")
        If nombreProducto Is Nothing Then nombreProducto = ""

        Dim personalizacion As String = context.Request.Form("personalizacion")
        If personalizacion Is Nothing Then personalizacion = ""

        Dim precioBs As Decimal = ParseDecimalSeguro(context.Request.Form("precio_bs"))

        Dim precioUsd As Decimal = ParseDecimalSeguro(context.Request.Form("precio_usd"))

        Dim cantidad As Integer = 1
        Integer.TryParse(context.Request.Form("cantidad"), cantidad)
        If cantidad < 1 Then cantidad = 1

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()

            Dim sql As String = "INSERT INTO FLORERIA_PrePedido_Entrega_Detalle " &
                "(prepedido_entrega_id, producto_id, variacion_id, es_personalizado, nombre_producto, " &
                "cantidad, precio_unitario_bs, precio_unitario_usd, subtotal_bs, subtotal_usd, personalizacion) " &
                "VALUES (@eid, @prodId, @varId, @esPers, @nombre, " &
                "@cant, @precBs, @precUsd, @subBs, @subUsd, @pers); " &
                "SELECT SCOPE_IDENTITY();"

            Using cmd As New SqlCommand(sql, conn)
                cmd.Parameters.AddWithValue("@eid", entregaId)
                cmd.Parameters.AddWithValue("@prodId", If(productoId > 0, CObj(productoId), DBNull.Value))
                cmd.Parameters.AddWithValue("@varId", If(variacionId <> "" AndAlso variacionId <> "0", CObj(CInt(variacionId)), DBNull.Value))
                cmd.Parameters.AddWithValue("@esPers", esPersonalizado)
                cmd.Parameters.AddWithValue("@nombre", nombreProducto)
                cmd.Parameters.AddWithValue("@cant", cantidad)
                cmd.Parameters.AddWithValue("@precBs", precioBs)
                cmd.Parameters.AddWithValue("@precUsd", precioUsd)
                cmd.Parameters.AddWithValue("@subBs", precioBs * cantidad)
                cmd.Parameters.AddWithValue("@subUsd", precioUsd * cantidad)
                cmd.Parameters.AddWithValue("@pers", If(personalizacion = "", DBNull.Value, CObj(personalizacion)))

                Dim newId As Object = cmd.ExecuteScalar()
                Dim detalleId As Integer = Convert.ToInt32(newId)

                context.Response.Write("{""ok"":true,""detalle_id"":" & detalleId & "}")
            End Using
        End Using
    End Sub

    ' ============================================================
    ' ELIMINAR DETALLE
    ' ============================================================
    Private Sub EliminarDetalle(context As HttpContext)
        Dim detalleId As Integer = 0
        Integer.TryParse(context.Request.Form("detalle_id"), detalleId)

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("DELETE FROM FLORERIA_PrePedido_Entrega_Detalle WHERE detalle_id = @id", conn)
                cmd.Parameters.AddWithValue("@id", detalleId)
                cmd.ExecuteNonQuery()
            End Using
        End Using

        context.Response.Write("{""ok"":true}")
    End Sub

    ' ============================================================
    ' ACTUALIZAR DETALLE (cantidad o precio del personalizado)
    ' ============================================================
    Private Sub ActualizarDetalle(context As HttpContext)
        Dim detalleId As Integer = 0
        Integer.TryParse(context.Request.Form("detalle_id"), detalleId)

        Dim campo As String = context.Request.Form("campo")
        If campo Is Nothing Then campo = ""

        Dim valor As String = context.Request.Form("valor")
        If valor Is Nothing Then valor = ""

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()

            Dim sql As String = ""
            Select Case campo
                Case "cantidad"
                    Dim cant As Integer = 1
                    Integer.TryParse(valor, cant)
                    If cant < 1 Then cant = 1
                    sql = "UPDATE FLORERIA_PrePedido_Entrega_Detalle " &
                          "SET cantidad = @val, " &
                          "subtotal_bs = precio_unitario_bs * @val, " &
                          "subtotal_usd = precio_unitario_usd * @val " &
                          "WHERE detalle_id = @id"
                    Using cmd As New SqlCommand(sql, conn)
                        cmd.Parameters.AddWithValue("@val", cant)
                        cmd.Parameters.AddWithValue("@id", detalleId)
                        cmd.ExecuteNonQuery()
                    End Using
                Case "precio"
                    Dim precio As Decimal = ParseDecimalSeguro(valor)
                    sql = "UPDATE FLORERIA_PrePedido_Entrega_Detalle " &
                          "SET precio_unitario_bs = @val, " &
                          "subtotal_bs = @val * cantidad " &
                          "WHERE detalle_id = @id"
                    Using cmd As New SqlCommand(sql, conn)
                        cmd.Parameters.AddWithValue("@val", precio)
                        cmd.Parameters.AddWithValue("@id", detalleId)
                        cmd.ExecuteNonQuery()
                    End Using
            End Select
        End Using

        context.Response.Write("{""ok"":true}")
    End Sub

    ' ============================================================
    ' GUARDAR CAMPO (auto-guardado individual sobre PrePedido_Entrega)
    ' ============================================================
    Private Sub GuardarCampo(context As HttpContext)
        Dim entregaId As Integer = 0
        Integer.TryParse(context.Request.Form("prepedido_entrega_id"), entregaId)

        Dim campo As String = context.Request.Form("campo")
        If campo Is Nothing Then campo = ""

        Dim valor As String = context.Request.Form("valor")
        If valor Is Nothing Then valor = ""

        If entregaId <= 0 Then
            context.Response.Write("{""ok"":false,""msg"":""prepedido_entrega_id invalido""}")
            Return
        End If

        If Not ValidarBorradorEditable(entregaId) Then
            context.Response.Write("{""ok"":false,""msg"":""El borrador no existe o ya fue confirmado""}")
            Return
        End If

        ' Lista blanca de campos permitidos (TODOS existen en FLORERIA_PrePedido_Entrega)
        Dim camposPermitidos As String() = {
            "receptor_nombre", "receptor_celular", "ciudad_id", "zona_id",
            "sucursal_id", "tipo_entrega", "direccion", "referencia", "gps",
            "fecha_entrega", "slot_id", "es_express",
            "dedicatoria", "firma_tarjeta", "tipo_ocacion",
            "sucursal_prepara_id", "moneda",
            "descuento_valor", "descuento_moneda", "nota_floreria"
        }

        If Array.IndexOf(camposPermitidos, campo) < 0 Then
            context.Response.Write("{""ok"":false,""msg"":""Campo no permitido""}")
            Return
        End If

        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()

            Dim sql As String = "UPDATE FLORERIA_PrePedido_Entrega SET [" & campo & "] = @val, " &
                "modificado_por = @uid, modificado_en = GETDATE() " &
                "WHERE prepedido_entrega_id = @eid"

            Using cmd As New SqlCommand(sql, conn)
                ' Determinar tipo de valor
                Select Case campo
                    Case "ciudad_id", "zona_id", "sucursal_id", "slot_id", "sucursal_prepara_id"
                        Dim intVal As Integer = 0
                        If Integer.TryParse(valor, intVal) AndAlso intVal > 0 Then
                            cmd.Parameters.AddWithValue("@val", intVal)
                        Else
                            cmd.Parameters.AddWithValue("@val", DBNull.Value)
                        End If
                    Case "es_express"
                        cmd.Parameters.AddWithValue("@val", If(valor = "1", True, False))
                    Case "fecha_entrega"
                        Dim dtVal As DateTime = DateTime.Now.AddDays(2)
                        If DateTime.TryParse(valor, dtVal) Then
                            cmd.Parameters.AddWithValue("@val", dtVal)
                        Else
                            cmd.Parameters.AddWithValue("@val", DBNull.Value)
                        End If
                    Case "descuento_valor"
                        Dim decVal As Decimal = ParseDecimalSeguro(valor)
                        If decVal < 0 Then decVal = 0
                        cmd.Parameters.AddWithValue("@val", decVal)
                    Case Else
                        If valor = "" Then
                            cmd.Parameters.AddWithValue("@val", DBNull.Value)
                        Else
                            cmd.Parameters.AddWithValue("@val", valor)
                        End If
                End Select

                cmd.Parameters.AddWithValue("@uid", usuarioId)
                cmd.Parameters.AddWithValue("@eid", entregaId)
                cmd.ExecuteNonQuery()
            End Using

            ' [NUEVO] Si se actualizo receptor_nombre/celular o fecha_entrega -> recalcular estado
            ' Esto cubre el caso "agente llena todo manualmente sin enviar form web"
            If campo = "receptor_nombre" OrElse campo = "receptor_celular" OrElse campo = "fecha_entrega" Then
                Try
                    Dim ppId As Integer = ObtenerPrepedidoIdDeEntrega(conn, entregaId)
                    If ppId > 0 Then
                        Using cmdR As New SqlCommand("FLORERIA_sp_PrePedido_RecalcularEstado", conn)
                            cmdR.CommandType = CommandType.StoredProcedure
                            cmdR.Parameters.AddWithValue("@prepedido_id", ppId)
                            cmdR.Parameters.AddWithValue("@modificado_por", usuarioId)
                            cmdR.ExecuteNonQuery()
                        End Using
                    End If
                Catch
                    ' Silencioso: no interrumpir el guardado
                End Try
            End If
        End Using

        context.Response.Write("{""ok"":true}")
    End Sub

    ' ============================================================
    ' AGREGAR PAGO (sobre PrePedido_Entrega_Pago, esquema alineado con FLORERIA_Pedido_Pago)
    ' Recibe: prepedido_entrega_id, tipo_pago, metodo_pago, monto_bs, monto_usd,
    '         referencia, comprobante_url, estado, observaciones
    ' ============================================================
    Private Sub AgregarPago(context As HttpContext)
        Dim entregaId As Integer = 0
        Integer.TryParse(context.Request.Form("prepedido_entrega_id"), entregaId)

        If entregaId <= 0 Then
            context.Response.Write("{""ok"":false,""msg"":""prepedido_entrega_id invalido""}")
            Return
        End If

        If Not ValidarBorradorEditable(entregaId) Then
            context.Response.Write("{""ok"":false,""msg"":""El borrador no existe o ya fue confirmado""}")
            Return
        End If

        Dim tipoPago As String = context.Request.Form("tipo_pago")
        If tipoPago Is Nothing OrElse tipoPago = "" Then tipoPago = "TOTAL"

        Dim metodoPago As String = context.Request.Form("metodo_pago")
        If metodoPago Is Nothing Then metodoPago = ""

        Dim montoBs As Decimal = ParseDecimalSeguro(context.Request.Form("monto_bs"))
        If montoBs < 0 Then montoBs = 0

        Dim montoUsd As Decimal = ParseDecimalSeguro(context.Request.Form("monto_usd"))
        If montoUsd < 0 Then montoUsd = 0

        Dim referencia As String = context.Request.Form("referencia")
        If referencia Is Nothing Then referencia = ""

        Dim comprobanteUrl As String = context.Request.Form("comprobante_url")
        If comprobanteUrl Is Nothing Then comprobanteUrl = ""

        Dim estado As String = context.Request.Form("estado")
        If estado Is Nothing OrElse estado = "" Then estado = "PENDIENTE"

        Dim observaciones As String = context.Request.Form("observaciones")
        If observaciones Is Nothing Then observaciones = ""

        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()

            ' ============================================================
            ' VALIDACION: el pago no puede exceder el saldo pendiente.
            ' Cuentan TODOS los pagos no rechazados (VERIFICADO + PENDIENTE).
            ' Tolerancia de 0.01 Bs para evitar errores de redondeo.
            ' Solo si estado != 'RECHAZADO' (un rechazo no suma).
            ' ============================================================
            If estado <> "RECHAZADO" AndAlso montoBs > 0 Then
                Dim totalPedido As Decimal = CalcularTotalBorrador(conn, entregaId)
                Dim yaPagado As Decimal = CalcularPagosNoRechazados(conn, entregaId)
                Dim saldo As Decimal = totalPedido - yaPagado

                If totalPedido > 0 AndAlso (montoBs - 0.01D) > saldo Then
                    Dim msg As String = "El monto excede el saldo pendiente. " &
                                        "Total: Bs " & totalPedido.ToString("F2") & ", " &
                                        "ya registrado: Bs " & yaPagado.ToString("F2") & ", " &
                                        "saldo: Bs " & saldo.ToString("F2") & ", " &
                                        "intento: Bs " & montoBs.ToString("F2") & "."
                    context.Response.Write("{""ok"":false,""msg"":""" & msg.Replace("""", "'") & """}")
                    Return
                End If
            End If

            Dim sql As String = "INSERT INTO FLORERIA_PrePedido_Entrega_Pago " &
                "(prepedido_entrega_id, tipo_pago, metodo_pago, monto_bs, monto_usd, " &
                "referencia, comprobante_url, estado, verificado_por, verificado_en, " &
                "observaciones, creado_por) " &
                "VALUES (@eid, @tipo, @metodo, @montoBs, @montoUsd, " &
                "@ref, @comp, @estado, @verifPor, @verifEn, @obs, @uid); " &
                "SELECT SCOPE_IDENTITY();"

            Using cmd As New SqlCommand(sql, conn)
                cmd.Parameters.AddWithValue("@eid", entregaId)
                cmd.Parameters.AddWithValue("@tipo", tipoPago)
                cmd.Parameters.AddWithValue("@metodo", metodoPago)
                cmd.Parameters.AddWithValue("@montoBs", montoBs)
                cmd.Parameters.AddWithValue("@montoUsd", montoUsd)
                cmd.Parameters.AddWithValue("@ref", If(referencia = "", DBNull.Value, CObj(referencia)))
                cmd.Parameters.AddWithValue("@comp", If(comprobanteUrl = "", DBNull.Value, CObj(comprobanteUrl)))
                cmd.Parameters.AddWithValue("@estado", estado)
                cmd.Parameters.AddWithValue("@obs", If(observaciones = "", DBNull.Value, CObj(observaciones)))
                cmd.Parameters.AddWithValue("@uid", usuarioId)

                If estado = "VERIFICADO" Then
                    cmd.Parameters.AddWithValue("@verifPor", usuarioId)
                    cmd.Parameters.AddWithValue("@verifEn", DateTime.Now)
                Else
                    cmd.Parameters.AddWithValue("@verifPor", DBNull.Value)
                    cmd.Parameters.AddWithValue("@verifEn", DBNull.Value)
                End If

                Dim newId As Object = cmd.ExecuteScalar()
                Dim pagoId As Integer = Convert.ToInt32(newId)

                ' [NUEVO] Recalcular estado del PrePedido -> pasa a ESPERANDO_PAGO o PAGADO
                Try
                    Dim ppId As Integer = ObtenerPrepedidoIdDeEntrega(conn, entregaId)
                    If ppId > 0 Then
                        Using cmdR As New SqlCommand("FLORERIA_sp_PrePedido_RecalcularEstado", conn)
                            cmdR.CommandType = CommandType.StoredProcedure
                            cmdR.Parameters.AddWithValue("@prepedido_id", ppId)
                            cmdR.Parameters.AddWithValue("@modificado_por", usuarioId)
                            cmdR.ExecuteNonQuery()
                        End Using
                    End If
                Catch
                    ' Silencioso: el pago ya se guardo, no romper la respuesta al usuario
                End Try

                context.Response.Write("{""ok"":true,""pago_id"":" & pagoId & "}")
            End Using
        End Using
    End Sub

    ' ============================================================
    ' ELIMINAR PAGO
    ' ============================================================
    Private Sub EliminarPago(context As HttpContext)
        Dim pagoId As Integer = 0
        Integer.TryParse(context.Request.Form("pago_id"), pagoId)

        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()

            ' [NUEVO] Antes de borrar, obtener el prepedido_id (lo necesitamos despues)
            Dim ppId As Integer = 0
            Try
                Using cmdGet As New SqlCommand(
                    "SELECT pe.prepedido_id FROM FLORERIA_PrePedido_Entrega_Pago pep " &
                    "INNER JOIN FLORERIA_PrePedido_Entrega pe ON pep.prepedido_entrega_id = pe.prepedido_entrega_id " &
                    "WHERE pep.pago_id = @id", conn)
                    cmdGet.Parameters.AddWithValue("@id", pagoId)
                    Dim r As Object = cmdGet.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then ppId = CInt(r)
                End Using
            Catch
            End Try

            Using cmd As New SqlCommand("DELETE FROM FLORERIA_PrePedido_Entrega_Pago WHERE pago_id = @id", conn)
                cmd.Parameters.AddWithValue("@id", pagoId)
                cmd.ExecuteNonQuery()
            End Using

            ' [NUEVO] Recalcular estado (podria bajar de PAGADO -> ESPERANDO_PAGO -> COMPLETADO)
            If ppId > 0 Then
                Try
                    Using cmdR As New SqlCommand("FLORERIA_sp_PrePedido_RecalcularEstado", conn)
                        cmdR.CommandType = CommandType.StoredProcedure
                        cmdR.Parameters.AddWithValue("@prepedido_id", ppId)
                        cmdR.Parameters.AddWithValue("@modificado_por", usuarioId)
                        cmdR.ExecuteNonQuery()
                    End Using
                Catch
                End Try
            End If
        End Using

        context.Response.Write("{""ok"":true}")
    End Sub

    ' ============================================================
    ' CONFIRMAR (copia borrador a FLORERIA_Pedido via SP)
    ' ============================================================
    Private Sub Confirmar(context As HttpContext)
        Dim entregaId As Integer = 0
        Integer.TryParse(context.Request.Form("prepedido_entrega_id"), entregaId)

        If entregaId <= 0 Then
            context.Response.Write("{""ok"":false,""msg"":""prepedido_entrega_id invalido""}")
            Return
        End If

        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_sp_PrePedidoEntrega_Confirmar", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@prepedido_entrega_id", entregaId)
                cmd.Parameters.AddWithValue("@usuario_id", usuarioId)

                Dim pPedidoId As New SqlParameter("@pedido_id", SqlDbType.Int)
                pPedidoId.Direction = ParameterDirection.Output
                cmd.Parameters.Add(pPedidoId)

                Dim pCodigo As New SqlParameter("@codigo", SqlDbType.VarChar, 20)
                pCodigo.Direction = ParameterDirection.Output
                cmd.Parameters.Add(pCodigo)

                cmd.ExecuteNonQuery()

                Dim pedidoId As Integer = CInt(pPedidoId.Value)
                Dim codigo As String = pCodigo.Value.ToString()

                ' [NUEVO] Recalcular estado tras confirmar (asegura COMPLETADO o superior)
                Try
                    Dim ppId As Integer = ObtenerPrepedidoIdDeEntrega(conn, entregaId)
                    If ppId > 0 Then
                        Using cmdR As New SqlCommand("FLORERIA_sp_PrePedido_RecalcularEstado", conn)
                            cmdR.CommandType = CommandType.StoredProcedure
                            cmdR.Parameters.AddWithValue("@prepedido_id", ppId)
                            cmdR.Parameters.AddWithValue("@modificado_por", usuarioId)
                            cmdR.ExecuteNonQuery()
                        End Using
                    End If
                Catch
                End Try

                context.Response.Write("{""ok"":true,""pedido_id"":" & pedidoId & ",""codigo"":""" & codigo & """}")
            End Using
        End Using
    End Sub

    ' ============================================================
    ' CREAR EN WOOCOMMERCE (flujo de un click)
    ' 1) Si el borrador todavia esta en BORRADOR -> ejecuta el SP Confirmar
    '    que copia a FLORERIA_Pedido y devuelve pedido_id.
    ' 2) Si ya fue confirmado antes (entrega tiene pedido_id) -> reutiliza ese.
    ' 3) Llama WooCommerceSync.SincronizarPedido(pedido_id) que hace el POST
    '    a /wp-json/wc/v3/orders y guarda wc_order_id / wc_order_number /
    '    wc_sync_estado en FLORERIA_Pedido.
    ' ============================================================
    Private Sub CrearEnWooCommerce(context As HttpContext)
        Dim entregaId As Integer = 0
        Integer.TryParse(context.Request.Form("prepedido_entrega_id"), entregaId)

        If entregaId <= 0 Then
            context.Response.Write("{""ok"":false,""msg"":""prepedido_entrega_id invalido""}")
            Return
        End If

        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        Dim pedidoId As Integer = 0
        Dim codigoPed As String = ""
        Dim yaEstabaConfirmado As Boolean = False
        Dim prepedidoIdParaRecalc As Integer = 0

        ' --- PASO 1: ver si ya fue confirmado antes ---
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand(
                    "SELECT estado, pedido_id, prepedido_id FROM FLORERIA_PrePedido_Entrega WHERE prepedido_entrega_id = @id", conn)
                    cmd.Parameters.AddWithValue("@id", entregaId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Dim est As String = dr("estado").ToString()
                            If est <> "BORRADOR" AndAlso Not IsDBNull(dr("pedido_id")) Then
                                pedidoId = CInt(dr("pedido_id"))
                                yaEstabaConfirmado = True
                            End If
                            If Not IsDBNull(dr("prepedido_id")) Then
                                prepedidoIdParaRecalc = CInt(dr("prepedido_id"))
                            End If
                        Else
                            context.Response.Write("{""ok"":false,""msg"":""Entrega no encontrada""}")
                            Return
                        End If
                    End Using
                End Using

                ' --- PASO 2: si era borrador, ejecutar SP Confirmar ---
                If Not yaEstabaConfirmado Then
                    ' Sanear tipo_ocacion: el CHECK constraint en FLORERIA_Pedido solo
                    ' acepta: CUMPLEANOS, ANIVERSARIO, AMOR, AGRADECIMIENTO,
                    '         CONDOLENCIAS, GRADUACION, NACIMIENTO, OTRO
                    ' Si el borrador trae NULL o un valor invalido (incluso ""),
                    ' lo dejamos en 'OTRO' para que el SP_Confirmar no falle.
                    Using cmdFix As New SqlCommand(
                        "UPDATE FLORERIA_PrePedido_Entrega " &
                        "SET tipo_ocacion = 'OTRO' " &
                        "WHERE prepedido_entrega_id = @id " &
                        "  AND (tipo_ocacion IS NULL " &
                        "    OR LTRIM(RTRIM(tipo_ocacion)) = '' " &
                        "    OR tipo_ocacion NOT IN " &
                        "       ('CUMPLEANOS','ANIVERSARIO','AMOR','AGRADECIMIENTO'," &
                        "        'CONDOLENCIAS','GRADUACION','NACIMIENTO','OTRO'))", conn)
                        cmdFix.Parameters.AddWithValue("@id", entregaId)
                        cmdFix.ExecuteNonQuery()
                    End Using

                    Using cmd As New SqlCommand("FLORERIA_sp_PrePedidoEntrega_Confirmar", conn)
                        cmd.CommandType = CommandType.StoredProcedure
                        cmd.Parameters.AddWithValue("@prepedido_entrega_id", entregaId)
                        cmd.Parameters.AddWithValue("@usuario_id", usuarioId)

                        Dim pId As New SqlParameter("@pedido_id", SqlDbType.Int)
                        pId.Direction = ParameterDirection.Output
                        cmd.Parameters.Add(pId)

                        Dim pCod As New SqlParameter("@codigo", SqlDbType.VarChar, 20)
                        pCod.Direction = ParameterDirection.Output
                        cmd.Parameters.Add(pCod)

                        cmd.ExecuteNonQuery()

                        pedidoId = CInt(pId.Value)
                        codigoPed = pCod.Value.ToString()
                    End Using
                Else
                    ' Recuperar codigo del pedido ya confirmado
                    Using cmd As New SqlCommand("SELECT codigo FROM FLORERIA_Pedido WHERE pedido_id = @id", conn)
                        cmd.Parameters.AddWithValue("@id", pedidoId)
                        Dim r As Object = cmd.ExecuteScalar()
                        If r IsNot Nothing AndAlso Not IsDBNull(r) Then codigoPed = r.ToString()
                    End Using
                End If
            End Using
        Catch ex As Exception
            context.Response.Write("{""ok"":false,""msg"":""Error al confirmar pedido: " & ex.Message.Replace("""", "'") & """}")
            Return
        End Try

        If pedidoId <= 0 Then
            context.Response.Write("{""ok"":false,""msg"":""No se pudo obtener pedido_id""}")
            Return
        End If

        ' --- PASO 3: sincronizar con WooCommerce ---
        Dim sync As Dictionary(Of String, Object) = Nothing
        Try
            sync = WooCommerceSync.SincronizarPedido(pedidoId)
        Catch ex As Exception
            context.Response.Write("{""ok"":false,""pedido_id"":" & pedidoId &
                ",""codigo"":""" & codigoPed & """" &
                ",""msg"":""Pedido confirmado pero fallo el envio a WC: " & ex.Message.Replace("""", "'") & """}")
            Return
        End Try

        Dim okSync As Boolean = sync IsNot Nothing AndAlso sync.ContainsKey("ok") AndAlso CBool(sync("ok"))
        Dim msgSync As String = If(sync IsNot Nothing AndAlso sync.ContainsKey("mensaje"), sync("mensaje").ToString(), "")
        Dim wcOrdId As Integer = If(sync IsNot Nothing AndAlso sync.ContainsKey("wc_order_id"), CInt(sync("wc_order_id")), 0)

        ' [NUEVO] Recalcular estado tras sincronizar con WC -> pasa a CONVERTIDO
        If prepedidoIdParaRecalc > 0 Then
            Try
                Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                    conn.Open()
                    Using cmdR As New SqlCommand("FLORERIA_sp_PrePedido_RecalcularEstado", conn)
                        cmdR.CommandType = CommandType.StoredProcedure
                        cmdR.Parameters.AddWithValue("@prepedido_id", prepedidoIdParaRecalc)
                        cmdR.Parameters.AddWithValue("@modificado_por", usuarioId)
                        cmdR.ExecuteNonQuery()
                    End Using
                End Using
            Catch
            End Try
        End If

        Dim sb As New System.Text.StringBuilder()
        sb.Append("{")
        sb.Append("""ok"":" & If(okSync, "true", "false") & ",")
        sb.Append("""pedido_id"":" & pedidoId & ",")
        sb.Append("""codigo"":""" & codigoPed & """,")
        sb.Append("""wc_order_id"":" & wcOrdId & ",")
        sb.Append("""msg"":""" & msgSync.Replace("""", "'") & """")
        sb.Append("}")
        context.Response.Write(sb.ToString())
    End Sub

    ' ============================================================
    ' Helper: validar que el borrador esta editable
    ' ============================================================
    Private Function ValidarBorradorEditable(entregaId As Integer) As Boolean
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("SELECT estado FROM FLORERIA_PrePedido_Entrega WHERE prepedido_entrega_id = @id", conn)
                    cmd.Parameters.AddWithValue("@id", entregaId)
                    Dim resultado As Object = cmd.ExecuteScalar()
                    If resultado Is Nothing OrElse IsDBNull(resultado) Then Return False
                    Return (resultado.ToString() = "BORRADOR")
                End Using
            End Using
        Catch
            Return False
        End Try
    End Function

    ' ============================================================
    ' Helper: calcular el TOTAL del borrador en Bs.
    '   subtotal de productos + envio zona + recargo slot + 50 si express
    '   - descuento (convertido a Bs segun descuento_moneda)
    ' Replica la misma formula que el JS en calcularSubtotal().
    ' Si algo falla, devuelve 0 (la validacion no bloquea, queda permisiva).
    ' ============================================================
    Private Function CalcularTotalBorrador(conn As SqlConnection, entregaId As Integer) As Decimal
        Try
            ' 1. Subtotal de productos
            Dim subtotal As Decimal = 0
            Using cmd As New SqlCommand(
                "SELECT ISNULL(SUM(subtotal_bs), 0) FROM FLORERIA_PrePedido_Entrega_Detalle " &
                "WHERE prepedido_entrega_id = @id", conn)
                cmd.Parameters.AddWithValue("@id", entregaId)
                Dim r As Object = cmd.ExecuteScalar()
                If r IsNot Nothing AndAlso Not IsDBNull(r) Then subtotal = CDec(r)
            End Using

            ' 2. Leer campos del borrador: zona, slot, express, descuento, prepedido_id
            Dim zonaId As Integer = 0
            Dim slotId As Integer = 0
            Dim esExpress As Boolean = False
            Dim descuentoValor As Decimal = 0
            Dim descuentoMoneda As String = "BOB"
            Dim ppId As Integer = 0

            Using cmd As New SqlCommand(
                "SELECT zona_id, slot_id, es_express, descuento_valor, descuento_moneda, prepedido_id " &
                "FROM FLORERIA_PrePedido_Entrega WHERE prepedido_entrega_id = @id", conn)
                cmd.Parameters.AddWithValue("@id", entregaId)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        zonaId = If(IsDBNull(dr("zona_id")), 0, CInt(dr("zona_id")))
                        slotId = If(IsDBNull(dr("slot_id")), 0, CInt(dr("slot_id")))
                        esExpress = If(IsDBNull(dr("es_express")), False, CBool(dr("es_express")))
                        descuentoValor = If(IsDBNull(dr("descuento_valor")), 0D, CDec(dr("descuento_valor")))
                        descuentoMoneda = If(IsDBNull(dr("descuento_moneda")), "BOB", dr("descuento_moneda").ToString())
                        ppId = If(IsDBNull(dr("prepedido_id")), 0, CInt(dr("prepedido_id")))
                    End If
                End Using
            End Using

            ' 3. Costo de envio (zona)
            Dim envio As Decimal = 0
            If zonaId > 0 Then
                Using cmd As New SqlCommand(
                    "SELECT TOP 1 precio_bs FROM FLORERIA_Zona_Tarifa " &
                    "WHERE zona_id = @z ORDER BY vigente_desde DESC", conn)
                    cmd.Parameters.AddWithValue("@z", zonaId)
                    Dim r As Object = cmd.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then envio = CDec(r)
                End Using
            End If

            ' 4. Recargo horario (slot)
            Dim recargoHorario As Decimal = 0
            If slotId > 0 Then
                Using cmd As New SqlCommand(
                    "SELECT ISNULL(recargo_bs, 0) FROM FLORERIA_Slot_Horario WHERE slot_id = @s", conn)
                    cmd.Parameters.AddWithValue("@s", slotId)
                    Dim r As Object = cmd.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then recargoHorario = CDec(r)
                End Using
            End If

            ' 5. Recargo express (50 Bs hardcoded igual que el JS)
            Dim recargoExpress As Decimal = If(esExpress, 50D, 0D)

            ' 6. Descuento (si esta en USD, convertir a Bs con tasa del prepedido)
            Dim descuentoBs As Decimal = descuentoValor
            If descuentoMoneda = "USD" AndAlso ppId > 0 Then
                Dim tasa As Decimal = 0
                Using cmd As New SqlCommand("SELECT tasa_cambio FROM FLORERIA_PrePedido WHERE prepedido_id = @p", conn)
                    cmd.Parameters.AddWithValue("@p", ppId)
                    Dim r As Object = cmd.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then tasa = CDec(r)
                End Using
                If tasa > 0 Then descuentoBs = descuentoValor * tasa
            End If

            Dim total As Decimal = subtotal + envio + recargoHorario + recargoExpress - descuentoBs
            If total < 0 Then total = 0
            Return total
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR CalcularTotalBorrador: " & ex.Message)
            Return 0
        End Try
    End Function

    ' ============================================================
    ' Helper: suma de pagos NO RECHAZADOS (VERIFICADO + PENDIENTE)
    ' Un PENDIENTE puede convertirse en VERIFICADO despues, asi que cuenta.
    ' ============================================================
    Private Function CalcularPagosNoRechazados(conn As SqlConnection, entregaId As Integer) As Decimal
        Try
            Using cmd As New SqlCommand(
                "SELECT ISNULL(SUM(monto_bs), 0) FROM FLORERIA_PrePedido_Entrega_Pago " &
                "WHERE prepedido_entrega_id = @id AND estado <> 'RECHAZADO'", conn)
                cmd.Parameters.AddWithValue("@id", entregaId)
                Dim r As Object = cmd.ExecuteScalar()
                If r IsNot Nothing AndAlso Not IsDBNull(r) Then Return CDec(r)
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR CalcularPagosNoRechazados: " & ex.Message)
        End Try
        Return 0
    End Function

    ' ============================================================
    ' [NUEVO] Helper: obtener prepedido_id desde prepedido_entrega_id
    ' Usado por los recalculos de estado tras cambios en pagos/campos.
    ' ============================================================
    Private Function ObtenerPrepedidoIdDeEntrega(conn As SqlConnection, entregaId As Integer) As Integer
        Try
            Using cmd As New SqlCommand(
                "SELECT prepedido_id FROM FLORERIA_PrePedido_Entrega " &
                "WHERE prepedido_entrega_id = @id", conn)
                cmd.Parameters.AddWithValue("@id", entregaId)
                Dim r As Object = cmd.ExecuteScalar()
                If r IsNot Nothing AndAlso Not IsDBNull(r) Then
                    Return CInt(r)
                End If
            End Using
        Catch
        End Try
        Return 0
    End Function

    ' ============================================================
    ' Helper: Parsea un texto a Decimal IGNORANDO la cultura del servidor.
    ' El JS siempre manda numeros en formato ingles ("320.00") via toFixed(),
    ' pero si el servidor esta en es-BO/es-ES el "." se toma como miles
    ' y "320.00" se vuelve 32000. Esto fuerza InvariantCulture (.) primero.
    ' Si falla, intenta con coma como fallback (por si algun input manual).
    ' ============================================================
    Private Function ParseDecimalSeguro(texto As String) As Decimal
        Dim r As Decimal = 0
        If texto Is Nothing Then Return 0
        texto = texto.Trim()
        If texto = "" Then Return 0

        ' 1) Probar formato invariant (punto decimal)
        If Decimal.TryParse(texto,
                            System.Globalization.NumberStyles.Float Or System.Globalization.NumberStyles.AllowThousands,
                            System.Globalization.CultureInfo.InvariantCulture,
                            r) Then
            Return r
        End If

        ' 2) Fallback: cambiar coma por punto y reintentar
        Dim alt As String = texto.Replace(",", ".")
        If Decimal.TryParse(alt,
                            System.Globalization.NumberStyles.Float,
                            System.Globalization.CultureInfo.InvariantCulture,
                            r) Then
            Return r
        End If

        Return 0
    End Function

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    ' ============================================================
    ' SINCRONIZAR PEDIDO YA CREADO con WooCommerce
    ' Recibe pedido_id (de FLORERIA_Pedido ya existente).
    ' Llama WooCommerceSync.SincronizarPedido que hace POST (si wc_order_id IS NULL)
    ' o PUT (si ya existe). Devuelve el wc_order_id resultante para construir el link.
    ' ============================================================
    Private Sub SincronizarPedidoYaCreado(context As HttpContext)
        Dim pedidoId As Integer = 0
        Integer.TryParse(context.Request.Form("pedido_id"), pedidoId)

        If pedidoId <= 0 Then
            context.Response.Write("{""ok"":false,""msg"":""pedido_id invalido""}")
            Return
        End If

        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)

        Dim sync As Dictionary(Of String, Object) = Nothing
        Try
            sync = WooCommerceSync.SincronizarPedido(pedidoId)
        Catch ex As Exception
            context.Response.Write("{""ok"":false,""pedido_id"":" & pedidoId &
                ",""msg"":""Error al sincronizar con WC: " & ex.Message.Replace("""", "'") & """}")
            Return
        End Try

        Dim okSync As Boolean = sync IsNot Nothing AndAlso sync.ContainsKey("ok") AndAlso CBool(sync("ok"))
        Dim msgSync As String = If(sync IsNot Nothing AndAlso sync.ContainsKey("mensaje"), sync("mensaje").ToString(), "")
        Dim wcOrdId As Integer = If(sync IsNot Nothing AndAlso sync.ContainsKey("wc_order_id"), CInt(sync("wc_order_id")), 0)

        ' [NUEVO] Recalcular estado del PrePedido tras sincronizar -> CONVERTIDO
        If okSync AndAlso wcOrdId > 0 Then
            Try
                Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                    conn.Open()
                    Dim ppId As Integer = 0
                    Using cmdGet As New SqlCommand(
                        "SELECT prepedido_id FROM FLORERIA_Pedido WHERE pedido_id = @id", conn)
                        cmdGet.Parameters.AddWithValue("@id", pedidoId)
                        Dim r As Object = cmdGet.ExecuteScalar()
                        If r IsNot Nothing AndAlso Not IsDBNull(r) Then ppId = CInt(r)
                    End Using
                    If ppId > 0 Then
                        Using cmdR As New SqlCommand("FLORERIA_sp_PrePedido_RecalcularEstado", conn)
                            cmdR.CommandType = CommandType.StoredProcedure
                            cmdR.Parameters.AddWithValue("@prepedido_id", ppId)
                            cmdR.Parameters.AddWithValue("@modificado_por", usuarioId)
                            cmdR.ExecuteNonQuery()
                        End Using
                    End If
                End Using
            Catch
            End Try
        End If

        Dim sb As New System.Text.StringBuilder()
        sb.Append("{")
        sb.Append("""ok"":" & If(okSync, "true", "false") & ",")
        sb.Append("""pedido_id"":" & pedidoId & ",")
        sb.Append("""wc_order_id"":" & wcOrdId & ",")
        sb.Append("""msg"":""" & msgSync.Replace("""", "'") & """")
        sb.Append("}")
        context.Response.Write(sb.ToString())
    End Sub

End Class
