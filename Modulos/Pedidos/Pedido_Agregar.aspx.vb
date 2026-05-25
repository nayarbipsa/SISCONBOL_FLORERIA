Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Web.Script.Serialization

' ============================================================
' SISCONBOL - Agregar Pedido (Entrega) a Pre-Pedido
' Archivo: Modulos/Pedidos/Pedido_Agregar.aspx.vb
' MasterPage: Site.Master
' ============================================================
Partial Public Class Modulos_Pedidos_Pedido_Agregar
    Inherits System.Web.UI.Page

    ' Propiedades públicas para la vista
    Public Property MensajeAlerta As String = ""
    Public Property PrePedidoId As Integer = 0
    Public Property PedidoId As Integer = 0
    Public Property ModoEdicion As Boolean = False
    Public Property PrePedidoCodigo As String = ""
    Public Property PedidoCodigo As String = ""
    Public Property ClienteNombre As String = ""
    Public Property ValorReceptor As String = ""
    Public Property ValorCelularReceptor As String = ""
    Public Property ValorFecha As String = ""
    Public Property ValorDireccion As String = ""
    Public Property ValorReferencia As String = ""
    Public Property ValorDedicatoria As String = ""
    Public Property ValorFirma As String = ""
    Public Property ValorMensaje As String = ""
    Public Property FechaMinima As String = ""
    Public Property HtmlZonas As String = ""
    Public Property HtmlSucursales As String = ""
    Public Property ProductosJson As String = "[]"
    Public Property ZonasJson As String = "[]"
    Public Property CiudadSeleccionada As Integer = 0
    Public Property ZonaSeleccionada As Integer = 0
    Public Property SucursalSeleccionada As Integer = 0
    Public Property SlotSeleccionado As Integer = 0
    Public Property TipoEntrega As String = "DOMICILIO"
    Public Property EsExpress As Boolean = False

    ' ============================================================
    ' Page_Load
    ' ============================================================
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ' ============================================================
            ' DETECTAR MODO: AGREGAR vs EDITAR
            ' ============================================================
            Dim prepedidoStr As String = Request.QueryString("prepedido")
            Dim pedidoStr As String = Request.QueryString("pedido")
            
            ' Validar pre-pedido (OBLIGATORIO)
            If String.IsNullOrEmpty(prepedidoStr) Then
                SesionHelper.RedirectSeguro(HttpContext.Current, "PrePedidos.aspx")
                Return
            End If

            Dim prepedidoId As Integer = 0
            If Not Integer.TryParse(prepedidoStr, prepedidoId) OrElse prepedidoId <= 0 Then
                SesionHelper.RedirectSeguro(HttpContext.Current, "PrePedidos.aspx")
                Return
            End If

            PrePedidoId = prepedidoId
            
            ' DEBUG
            System.Diagnostics.Debug.WriteLine("=== DEBUG Page_Load ===")
            System.Diagnostics.Debug.WriteLine("prepedidoStr: " & prepedidoStr)
            System.Diagnostics.Debug.WriteLine("PrePedidoId asignado: " & PrePedidoId)
            System.Diagnostics.Debug.WriteLine("pedidoStr: " & If(String.IsNullOrEmpty(pedidoStr), "VACIO", pedidoStr))
            
            ' ============================================================
            ' MODO EDICIÓN: Si viene "pedido=" → cargar datos existentes
            ' ============================================================
            If Not String.IsNullOrEmpty(pedidoStr) Then
                Dim pedidoId As Integer = 0
                If Integer.TryParse(pedidoStr, pedidoId) AndAlso pedidoId > 0 Then
                    PedidoId = pedidoId
                    ModoEdicion = True
                End If
            End If
            
            ' Calcular fecha mínima (HOY + 2 días)
            Dim fechaMin As DateTime = DateTime.Now.AddDays(2)
            FechaMinima = fechaMin.ToString("yyyy-MM-dd")
            
            ' Cargar datos
            CargarDatosPrePedido()
            
            If ModoEdicion Then
                ' MODO EDICIÓN: Cargar datos del pedido existente
                CargarDatosPedido()
            Else
                ' MODO AGREGAR: Valores por defecto
                ValorFecha = fechaMin.ToString("yyyy-MM-dd")
            End If
            
            CargarZonas()
            CargarSucursales()
            CargarProductos()
        End If
    End Sub

    ' ============================================================
    ' CargarDatosPrePedido
    ' ============================================================
    Private Sub CargarDatosPrePedido()
        Try
            System.Diagnostics.Debug.WriteLine("=== DEBUG CargarDatosPrePedido ===")
            System.Diagnostics.Debug.WriteLine("PrePedidoId ANTES de SQL: " & PrePedidoId)
            
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                Dim sql As String = "SELECT codigo, cliente_nombre, cliente_apellidos FROM FLORERIA_PrePedido WHERE prepedido_id = @id"
                System.Diagnostics.Debug.WriteLine("SQL: " & sql)

                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@id", PrePedidoId)
                    System.Diagnostics.Debug.WriteLine("Parámetro @id: " & PrePedidoId)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            System.Diagnostics.Debug.WriteLine("PrePedido ENCONTRADO")
                            PrePedidoCodigo = dr("codigo").ToString()
                            
                            Dim nombre As String = If(IsDBNull(dr("cliente_nombre")), "", dr("cliente_nombre").ToString())
                            Dim apellidos As String = If(IsDBNull(dr("cliente_apellidos")), "", dr("cliente_apellidos").ToString())
                            
                            If nombre.Trim() <> "" Then
                                ClienteNombre = nombre.Trim()
                                If apellidos.Trim() <> "" Then
                                    ClienteNombre &= " " & apellidos.Trim()
                                End If
                            Else
                                ClienteNombre = "Cliente"
                            End If
                        Else
                            System.Diagnostics.Debug.WriteLine("ERROR: PrePedido NO ENCONTRADO con ID: " & PrePedidoId)
                            SesionHelper.RedirectSeguro(HttpContext.Current, "PrePedidos.aspx")
                        End If
                    End Using
                End Using
            End Using

        Catch ex As Exception
            MensajeAlerta = "Error al cargar: " & ex.Message
            System.Diagnostics.Debug.WriteLine("ERROR Pedido_Agregar.CargarDatosPrePedido: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' CargarDatosPedido - Cargar datos del pedido existente (MODO EDICIÓN)
    ' ============================================================
    Private Sub CargarDatosPedido()
        Try
            ' DEBUG: Verificar parámetros
            System.Diagnostics.Debug.WriteLine("=== DEBUG CargarDatosPedido ===")
            System.Diagnostics.Debug.WriteLine("PedidoId: " & PedidoId)
            System.Diagnostics.Debug.WriteLine("PrePedidoId: " & PrePedidoId)
            
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                ' SQL con todos los campos necesarios
                Dim sql As String = "SELECT " &
                    "ped.codigo, ped.receptor_nombre, ped.receptor_celular, " &
                    "ped.ciudad_id, ped.zona_id, ped.sucursal_id, " &
                    "ped.tipo_entrega, ped.direccion, ped.referencia, " &
                    "ped.fecha_entrega, ped.slot_id, ped.es_express, " &
                    "ped.dedicatoria, ped.firma_tarjeta " &
                    "FROM FLORERIA_Pedido ped " &
                    "WHERE ped.pedido_id = @pedidoId AND ped.prepedido_id = @prepedidoId"

                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@pedidoId", PedidoId)
                    cmd.Parameters.AddWithValue("@prepedidoId", PrePedidoId)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        System.Diagnostics.Debug.WriteLine("ExecuteReader ejecutado")
                        
                        If dr.Read() Then
                            System.Diagnostics.Debug.WriteLine("Pedido encontrado - Código: " & dr("codigo").ToString())
                            
                            ' Datos básicos
                            PedidoCodigo = dr("codigo").ToString()
                            ValorReceptor = If(IsDBNull(dr("receptor_nombre")), "", dr("receptor_nombre").ToString())
                            ValorCelularReceptor = If(IsDBNull(dr("receptor_celular")), "", dr("receptor_celular").ToString())
                            
                            ' Ubicación
                            If Not IsDBNull(dr("ciudad_id")) Then
                                CiudadSeleccionada = CInt(dr("ciudad_id"))
                            End If
                            
                            If Not IsDBNull(dr("zona_id")) Then
                                ZonaSeleccionada = CInt(dr("zona_id"))
                            End If
                            
                            If Not IsDBNull(dr("sucursal_id")) Then
                                SucursalSeleccionada = CInt(dr("sucursal_id"))
                            End If
                            
                            ' Tipo entrega
                            TipoEntrega = If(IsDBNull(dr("tipo_entrega")), "DOMICILIO", dr("tipo_entrega").ToString())
                            ValorDireccion = If(IsDBNull(dr("direccion")), "", dr("direccion").ToString())
                            ValorReferencia = If(IsDBNull(dr("referencia")), "", dr("referencia").ToString())
                            
                            ' Fecha y horario
                            If Not IsDBNull(dr("fecha_entrega")) Then
                                Dim fecha As DateTime = CDate(dr("fecha_entrega"))
                                ValorFecha = fecha.ToString("yyyy-MM-dd")
                            End If
                            
                            If Not IsDBNull(dr("slot_id")) Then
                                SlotSeleccionado = CInt(dr("slot_id"))
                            End If
                            
                            If Not IsDBNull(dr("es_express")) Then
                                EsExpress = CBool(dr("es_express"))
                            End If
                            
                            ' Mensaje
                            ValorDedicatoria = If(IsDBNull(dr("dedicatoria")), "", dr("dedicatoria").ToString())
                            ValorFirma = If(IsDBNull(dr("firma_tarjeta")), "", dr("firma_tarjeta").ToString())
                        Else
                            ' No existe o no pertenece a este pre-pedido
                            System.Diagnostics.Debug.WriteLine("ERROR: Pedido NO encontrado")
                            System.Diagnostics.Debug.WriteLine("SQL: " & sql)
                            SesionHelper.RedirectSeguro(HttpContext.Current, "PrePedido_Detalle.aspx?id=" & PrePedidoId)
                            Return
                        End If
                    End Using
                End Using
            End Using

        Catch ex As Exception
            MensajeAlerta = "Error al cargar entrega: " & ex.Message
            System.Diagnostics.Debug.WriteLine("ERROR Pedido_Agregar.CargarDatosPedido: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' CargarZonas - Para dropdown y JSON
    ' ============================================================
    Private Sub CargarZonas()
        Try
            Dim zonasList As New List(Of Object)
            Dim sb As New System.Text.StringBuilder()
            
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                Dim sql As String = "SELECT zona_id, nombre, costo_base FROM FLORERIA_Zona WHERE activo = 1 ORDER BY nombre"

                Using cmd As New SqlCommand(sql, conn)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim zonaId As Integer = CInt(dr("zona_id"))
                            Dim nombre As String = dr("nombre").ToString()
                            Dim costo As Decimal = If(IsDBNull(dr("costo_base")), 0, CDec(dr("costo_base")))
                            
                            ' HTML para dropdown
                            sb.AppendLine("<option value='" & zonaId & "'>" & nombre & " (+" & costo.ToString("N2") & " Bs)</option>")
                            
                            ' JSON para JavaScript
                            zonasList.Add(New With {
                                .id = zonaId,
                                .nombre = nombre,
                                .costo = costo
                            })
                        End While
                    End Using
                End Using
            End Using

            HtmlZonas = sb.ToString()
            
            ' Convertir a JSON
            Dim serializer As New JavaScriptSerializer()
            ZonasJson = serializer.Serialize(zonasList)

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Pedido_Agregar.CargarZonas: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' CargarSucursales - Para dropdown
    ' ============================================================
    Private Sub CargarSucursales()
        Try
            Dim sb As New System.Text.StringBuilder()
            
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                Dim sql As String = "SELECT sucursal_id, nombre FROM FLORERIA_Sucursal WHERE activo = 1 ORDER BY nombre"

                Using cmd As New SqlCommand(sql, conn)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim sucId As Integer = CInt(dr("sucursal_id"))
                            Dim nombre As String = dr("nombre").ToString()
                            
                            sb.AppendLine("<option value='" & sucId & "'>" & nombre & "</option>")
                        End While
                    End Using
                End Using
            End Using

            HtmlSucursales = sb.ToString()

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Pedido_Agregar.CargarSucursales: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' CargarProductos - Para catálogo JSON
    ' ============================================================
    Private Sub CargarProductos()
        Try
            Dim productosList As New List(Of Object)
            
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                Dim sql As String = "SELECT producto_id, nombre, precio_bs FROM FLORERIA_Producto WHERE activo = 1 ORDER BY nombre"

                Using cmd As New SqlCommand(sql, conn)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim prodId As Integer = CInt(dr("producto_id"))
                            Dim nombre As String = dr("nombre").ToString()
                            Dim precio As Decimal = If(IsDBNull(dr("precio_bs")), 0, CDec(dr("precio_bs")))
                            
                            productosList.Add(New With {
                                .id = prodId,
                                .nombre = nombre,
                                .precio = precio
                            })
                        End While
                    End Using
                End Using
            End Using

            ' Convertir a JSON
            Dim serializer As New JavaScriptSerializer()
            ProductosJson = serializer.Serialize(productosList)

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Pedido_Agregar.CargarProductos: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' btnAccion_Click - Procesar formulario
    ' ============================================================
    Protected Sub btnAccion_Click(sender As Object, e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        
        If accion = "GUARDAR" Then
            GuardarPedido()
        End If
    End Sub

    ' ============================================================
    ' GuardarPedido - Crear pedido en BD
    ' ============================================================
    Private Sub GuardarPedido()
        Try
            ' Obtener datos del formulario
            Dim receptor As String = Request.Form("txReceptor")
            Dim celular As String = Request.Form("txCelularReceptor")
            Dim fecha As String = Request.Form("txFecha")
            Dim horario As String = Request.Form("selHorario")
            Dim tipoEntrega As String = Request.Form("selTipoEntrega")
            Dim zonaId As String = Request.Form("selZona")
            Dim sucursalId As String = Request.Form("selSucursal")
            Dim direccion As String = Request.Form("txDireccion")
            Dim mensaje As String = Request.Form("txMensaje")
            Dim productosJson As String = Request.Form("hdProductosJson")
            
            ' Validaciones básicas
            If String.IsNullOrEmpty(receptor) OrElse String.IsNullOrEmpty(celular) OrElse String.IsNullOrEmpty(fecha) Then
                MensajeAlerta = "Faltan datos requeridos"
                Return
            End If
            
            ' TODO: Llamar a SP para crear pedido
            ' FLORERIA_sp_Pedido_Crear(@prepedido_id, @receptor, @celular, @fecha, ...)
            
            ' Por ahora, redirigir al detalle
            SesionHelper.RedirectSeguro(HttpContext.Current, "PrePedido_Detalle.aspx?id=" & PrePedidoId)
            
        Catch ex As Exception
            MensajeAlerta = "Error al guardar: " & ex.Message
            System.Diagnostics.Debug.WriteLine("ERROR Pedido_Agregar.GuardarPedido: " & ex.Message)
        End Try
    End Sub

End Class
