Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

Partial Public Class Modulos_Pedidos_Lista
    Inherits System.Web.UI.Page

    Public Property MenuHtml As String = ""
    Public Property JsonData As String = ""

    Public Class PrePedidoItem
        Public Property prepedido_id As Integer
        Public Property codigo As String
        Public Property tipo_registro As String
        Public Property cliente_celular As String
        Public Property cliente_nombre As String
        Public Property cliente_apellidos As String
        Public Property estado As String
        Public Property total_general_bs As Decimal
        Public Property total_general_usd As Decimal
        Public Property agente_nombre As String
        Public Property cantidad_pedidos As Integer
        Public Property creado_en As String
    End Class

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not SesionHelper.VerificarSesion(Context) Then
            Response.Redirect("~/Login.aspx")
            Return
        End If

        MenuHtml = SesionHelper.GenerarMenuHtml(Context, Me)

        If Not IsPostBack Then
            CargarDatos()
        End If
    End Sub

    Private Sub CargarDatos()
        Dim lista As New List(Of PrePedidoItem)()
        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(Context)
        Dim tipoId As Integer = 0

        If Session("tipo_id") IsNot Nothing Then
            tipoId = CInt(Session("tipo_id"))
        End If

        Dim agenteIdFiltro As Object = DBNull.Value
        If tipoId > 2 Then
            agenteIdFiltro = usuarioId
        End If

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_PrePedido_Listar", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@agente_id", agenteIdFiltro)
                    cmd.Parameters.AddWithValue("@estado", DBNull.Value)
                    cmd.Parameters.AddWithValue("@buscar", DBNull.Value)
                    cmd.Parameters.AddWithValue("@pagina", 1)
                    cmd.Parameters.AddWithValue("@por_pagina", 20)

                    Dim paramTotal As New SqlParameter("@total_registros", SqlDbType.Int)
                    paramTotal.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(paramTotal)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim item As New PrePedidoItem()
                            item.prepedido_id = CInt(dr("prepedido_id"))
                            item.codigo = dr("codigo").ToString()
                            item.tipo_registro = dr("tipo_registro").ToString()
                            item.cliente_celular = dr("cliente_celular").ToString()
                            item.cliente_nombre = If(IsDBNull(dr("cliente_nombre")), "", dr("cliente_nombre").ToString())
                            item.cliente_apellidos = If(IsDBNull(dr("cliente_apellidos")), "", dr("cliente_apellidos").ToString())
                            item.estado = dr("estado").ToString()
                            item.total_general_bs = CDec(dr("total_general_bs"))
                            item.total_general_usd = CDec(dr("total_general_usd"))
                            item.agente_nombre = dr("agente_nombre").ToString()
                            item.cantidad_pedidos = CInt(dr("cantidad_pedidos"))
                            item.creado_en = CDate(dr("creado_en")).ToString("yyyy-MM-dd HH:mm:ss")
                            lista.Add(item)
                        End While
                    End Using
                End Using
            End Using

            Dim serializer As New JavaScriptSerializer()
            JsonData = serializer.Serialize(lista)

        Catch ex As Exception
            JsonData = "[]"
        End Try
    End Sub

End Class
