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
    Public Property PrePedidoCodigo As String = ""
    Public Property ClienteNombre As String = ""
    Public Property ValorReceptor As String = ""
    Public Property ValorCelularReceptor As String = ""
    Public Property ValorFecha As String = ""
    Public Property ValorDireccion As String = ""
    Public Property ValorMensaje As String = ""
    Public Property FechaMinima As String = ""
    Public Property HtmlZonas As String = ""
    Public Property HtmlSucursales As String = ""
    Public Property ProductosJson As String = "[]"
    Public Property ZonasJson As String = "[]"

    ' ============================================================
    ' Page_Load
    ' ============================================================
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ' Obtener ID del pre-pedido
            Dim idStr As String = Request.QueryString("prepedido")
            
            If String.IsNullOrEmpty(idStr) Then
                Response.Redirect("PrePedidos.aspx")
                Return
            End If

            Dim id As Integer = 0
            If Not Integer.TryParse(idStr, id) OrElse id <= 0 Then
                Response.Redirect("PrePedidos.aspx")
                Return
            End If

            PrePedidoId = id
            
            ' Calcular fecha mínima (HOY + 2 días)
            Dim fechaMin As DateTime = DateTime.Now.AddDays(2)
            FechaMinima = fechaMin.ToString("yyyy-MM-dd")
            ValorFecha = fechaMin.ToString("yyyy-MM-dd")
            
            ' Cargar datos
            CargarDatosPrePedido()
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
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                Dim sql As String = "SELECT codigo, cliente_nombre, cliente_apellidos FROM FLORERIA_PrePedido WHERE prepedido_id = @id"

                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@id", PrePedidoId)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
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
                            Response.Redirect("PrePedidos.aspx")
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
            Response.Redirect("PrePedido_Detalle.aspx?id=" & PrePedidoId)
            
        Catch ex As Exception
            MensajeAlerta = "Error al guardar: " & ex.Message
            System.Diagnostics.Debug.WriteLine("ERROR Pedido_Agregar.GuardarPedido: " & ex.Message)
        End Try
    End Sub

End Class
