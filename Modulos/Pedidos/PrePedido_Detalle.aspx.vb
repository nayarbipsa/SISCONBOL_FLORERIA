Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

Partial Public Class Modulos_Pedidos_Detalle
    Inherits System.Web.UI.Page

    Public Property MenuHtml As String = ""
    Public Property JsonData As String = ""

    Public Class PrePedidoDetalle
        Public Property prepedido_id As Integer
        Public Property codigo As String
        Public Property tipo_registro As String
        Public Property cliente_celular As String
        Public Property cliente_nombre As String
        Public Property cliente_apellidos As String
        Public Property cliente_email As String
        Public Property estado As String
        Public Property total_general_bs As Decimal
        Public Property total_general_usd As Decimal
        Public Property descuento_bs As Decimal
        Public Property descuento_usd As Decimal
        Public Property moneda_formulario As String
        Public Property token_web As String
        Public Property token_expira As String
        Public Property agente_nombre As String
        Public Property creado_en As String
        Public Property cantidad_pedidos As Integer
        Public Property pedidos As List(Of PedidoItem)
    End Class

    Public Class PedidoItem
        Public Property pedido_id As Integer
        Public Property codigo As String
        Public Property receptor_nombre As String
        Public Property receptor_celular As String
        Public Property zona_nombre As String
        Public Property fecha_entrega As String
        Public Property total_bs As Decimal
        Public Property total_usd As Decimal
    End Class

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not SesionHelper.VerificarSesion(Context) Then
            Response.Redirect("~/Login.aspx")
            Return
        End If

        MenuHtml = SesionHelper.GenerarMenuHtml(Context, Me)

        If IsPostBack Then
            ProcesarAccion()
        Else
            CargarDetalle()
        End If
    End Sub

    Private Sub ProcesarAccion()
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""

        If accion = "GENERAR_LINK" Then
            GenerarLink()
        End If

        CargarDetalle()
    End Sub

    Private Sub CargarDetalle()
        Dim idStr As String = Request.QueryString("id")
        If idStr Is Nothing OrElse idStr = "" Then
            JsonData = "{}"
            Return
        End If

        Dim prepedidoId As Integer = 0
        If Not Integer.TryParse(idStr, prepedidoId) Then
            JsonData = "{}"
            Return
        End If

        Dim detalle As PrePedidoDetalle = Nothing

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                Using cmd As New SqlCommand("SELECT * FROM FLORERIA_PrePedido WHERE prepedido_id = @id", conn)
                    cmd.Parameters.AddWithValue("@id", prepedidoId)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            detalle = New PrePedidoDetalle()
                            detalle.prepedido_id = CInt(dr("prepedido_id"))
                            detalle.codigo = dr("codigo").ToString()
                            detalle.tipo_registro = dr("tipo_registro").ToString()
                            detalle.cliente_celular = If(IsDBNull(dr("cliente_celular")), "", dr("cliente_celular").ToString())
                            detalle.cliente_nombre = If(IsDBNull(dr("cliente_nombre")), "", dr("cliente_nombre").ToString())
                            detalle.cliente_apellidos = If(IsDBNull(dr("cliente_apellidos")), "", dr("cliente_apellidos").ToString())
                            detalle.cliente_email = If(IsDBNull(dr("cliente_email")), "", dr("cliente_email").ToString())
                            detalle.estado = dr("estado").ToString()
                            detalle.total_general_bs = CDec(dr("total_general_bs"))
                            detalle.total_general_usd = CDec(dr("total_general_usd"))
                            detalle.descuento_bs = CDec(dr("descuento_bs"))
                            detalle.descuento_usd = CDec(dr("descuento_usd"))
                            detalle.moneda_formulario = If(IsDBNull(dr("moneda_formulario")), "BOB", dr("moneda_formulario").ToString())
                            detalle.token_web = If(IsDBNull(dr("token_web")), "", dr("token_web").ToString())
                            detalle.token_expira = If(IsDBNull(dr("token_expira")), "", CDate(dr("token_expira")).ToString("yyyy-MM-dd HH:mm:ss"))
                            detalle.creado_en = CDate(dr("creado_en")).ToString("yyyy-MM-dd HH:mm:ss")

                            Dim agenteId As Integer = CInt(dr("agente_actual_id"))
                            detalle.agente_nombre = ObtenerNombreAgente(conn, agenteId)
                        End If
                    End Using
                End Using

                If detalle IsNot Nothing Then
                    detalle.pedidos = CargarPedidos(conn, prepedidoId)
                    detalle.cantidad_pedidos = detalle.pedidos.Count

                    Dim serializer As New JavaScriptSerializer()
                    JsonData = serializer.Serialize(detalle)
                Else
                    JsonData = "{}"
                End If
            End Using

        Catch ex As Exception
            JsonData = "{}"
        End Try
    End Sub

    Private Function CargarPedidos(conn As SqlConnection, prepedidoId As Integer) As List(Of PedidoItem)
        Dim lista As New List(Of PedidoItem)()

        Using cmd As New SqlCommand("SELECT p.*, z.nombre AS zona_nombre FROM FLORERIA_Pedido p LEFT JOIN FLORERIA_Zona z ON p.zona_id = z.zona_id WHERE p.prepedido_id = @id ORDER BY p.pedido_id", conn)
            cmd.Parameters.AddWithValue("@id", prepedidoId)

            Using dr As SqlDataReader = cmd.ExecuteReader()
                While dr.Read()
                    Dim item As New PedidoItem()
                    item.pedido_id = CInt(dr("pedido_id"))
                    item.codigo = dr("codigo").ToString()
                    item.receptor_nombre = dr("receptor_nombre").ToString()
                    item.receptor_celular = dr("receptor_celular").ToString()
                    item.zona_nombre = If(IsDBNull(dr("zona_nombre")), "", dr("zona_nombre").ToString())
                    item.fecha_entrega = CDate(dr("fecha_entrega")).ToString("yyyy-MM-dd")
                    item.total_bs = CDec(dr("total_bs"))
                    item.total_usd = CDec(dr("total_usd"))

                    lista.Add(item)
                End While
            End Using
        End Using

        Return lista
    End Function

    Private Function ObtenerNombreAgente(conn As SqlConnection, agenteId As Integer) As String
        Dim nombre As String = ""

        Using cmd As New SqlCommand("SELECT nombres, apellidos FROM FLORERIA_Usuario WHERE usuario_id = @id", conn)
            cmd.Parameters.AddWithValue("@id", agenteId)

            Using dr As SqlDataReader = cmd.ExecuteReader()
                If dr.Read() Then
                    nombre = dr("nombres").ToString() & " " & dr("apellidos").ToString()
                End If
            End Using
        End Using

        Return nombre
    End Function

    Private Sub GenerarLink()
        Dim idStr As String = Request.Form("hdData")
        If idStr Is Nothing OrElse idStr = "" Then Return

        Dim prepedidoId As Integer = 0
        If Not Integer.TryParse(idStr, prepedidoId) Then Return

        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(Context)
        Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
        If ip Is Nothing Then ip = "127.0.0.1"

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                Using cmd As New SqlCommand("FLORERIA_sp_PrePedido_GenerarLink", conn)
                    cmd.CommandType = CommandType.StoredProcedure

                    cmd.Parameters.AddWithValue("@prepedido_id", prepedidoId)
                    cmd.Parameters.AddWithValue("@moneda_formulario", "BOB")
                    cmd.Parameters.AddWithValue("@descuento_bs", 0)
                    cmd.Parameters.AddWithValue("@descuento_motivo", DBNull.Value)
                    cmd.Parameters.AddWithValue("@modificado_por", usuarioId)
                    cmd.Parameters.AddWithValue("@ip", ip)

                    Dim paramToken As New SqlParameter("@token", SqlDbType.VarChar, 100)
                    paramToken.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(paramToken)

                    Dim paramUrl As New SqlParameter("@url_completa", SqlDbType.VarChar, 500)
                    paramUrl.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(paramUrl)

                    cmd.ExecuteNonQuery()
                End Using
            End Using

        Catch ex As Exception
            ' Error silencioso, se recarga la página de todos modos
        End Try
    End Sub

    Protected Sub btnPostBack_Click(sender As Object, e As EventArgs)
        ' Lógica en ProcesarAccion
    End Sub

End Class
