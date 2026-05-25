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

        Dim precioBs As Decimal = 0
        Decimal.TryParse(context.Request.Form("precio_bs"), precioBs)

        Dim precioUsd As Decimal = 0
        Decimal.TryParse(context.Request.Form("precio_usd"), precioUsd)

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
                    Dim precio As Decimal = 0
                    Decimal.TryParse(valor, precio)
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
                        Dim decVal As Decimal = 0
                        Decimal.TryParse(valor, decVal)
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

        Dim montoBs As Decimal = 0
        Decimal.TryParse(context.Request.Form("monto_bs"), montoBs)
        If montoBs < 0 Then montoBs = 0

        Dim montoUsd As Decimal = 0
        Decimal.TryParse(context.Request.Form("monto_usd"), montoUsd)
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

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("DELETE FROM FLORERIA_PrePedido_Entrega_Pago WHERE pago_id = @id", conn)
                cmd.Parameters.AddWithValue("@id", pagoId)
                cmd.ExecuteNonQuery()
            End Using
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

                context.Response.Write("{""ok"":true,""pedido_id"":" & pedidoId & ",""codigo"":""" & codigo & """}")
            End Using
        End Using
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

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
