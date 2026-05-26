Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

Partial Public Class Modulos_Pedidos_PrePedidos
    Inherits System.Web.UI.Page

    Public Property JsonInicial As String = ""
    Public Property JsonAgentes As String = ""
    Public Property MiUsuarioId As String = "0"

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Dim esAjax As Boolean = (Request.Headers("X-Requested-With") = "XMLHttpRequest")
            Dim accion As String  = If(Request.QueryString("accion"), "")

            If esAjax AndAlso accion = "LISTAR" Then
                ResponderAjax()
            Else
                Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
                MiUsuarioId   = usuarioId.ToString()
                JsonAgentes   = ObtenerAgentes()
                ' Primera carga: por defecto agente actual = yo (mis pedidos)
                JsonInicial   = ObtenerJson(
                    buscar         := If(Request.QueryString("buscar"), ""),
                    estado         := If(Request.QueryString("estado"), ""),
                    creadoPorId    := 0,
                    agenteActualId := usuarioId,
                    pagina         := 1
                )
            End If
        End If
    End Sub

    Private Sub ResponderAjax()
        Dim buscar         As String  = If(Request.QueryString("buscar"), "")
        Dim estado         As String  = If(Request.QueryString("estado"), "")
        Dim pagina         As Integer = 1
        Dim creadoPorId    As Integer = 0
        Dim agenteActualId As Integer = 0

        If Not Integer.TryParse(Request.QueryString("p"),       pagina)         Then pagina         = 1
        If Not Integer.TryParse(Request.QueryString("creador"), creadoPorId)    Then creadoPorId    = 0
        If Not Integer.TryParse(Request.QueryString("agente"),  agenteActualId) Then agenteActualId = 0

        Dim json As String = ObtenerJson(buscar, estado, creadoPorId, agenteActualId, pagina)
        Response.Clear()
        Response.ContentType = "application/json"
        Response.Charset     = "utf-8"
        Response.Write(json)
        Response.End()
    End Sub

    Private Function ObtenerJson(buscar As String, estado As String,
                                 creadoPorId As Integer, agenteActualId As Integer,
                                 pagina As Integer) As String
        Dim porPagina      As Integer = 20
        Dim totalRegistros As Integer = 0
        Dim items          As New List(Of PrePedidoItem)()

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_PrePedido_Listar", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@agente_actual_id", If(agenteActualId > 0, CObj(agenteActualId), DBNull.Value))
                    cmd.Parameters.AddWithValue("@creado_por_id",    If(creadoPorId    > 0, CObj(creadoPorId),    DBNull.Value))
                    cmd.Parameters.AddWithValue("@tipo_registro",    "PRE_PEDIDO")
                    cmd.Parameters.AddWithValue("@estado",           If(estado  <> "", CObj(estado),  DBNull.Value))
                    cmd.Parameters.AddWithValue("@buscar",           If(buscar  <> "", CObj(buscar),  DBNull.Value))
                    cmd.Parameters.AddWithValue("@pagina",           pagina)
                    cmd.Parameters.AddWithValue("@por_pagina",       porPagina)

                    Dim paramTotal As New SqlParameter("@total_registros", SqlDbType.Int)
                    paramTotal.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(paramTotal)

                    Using reader As SqlDataReader = cmd.ExecuteReader()
                        While reader.Read()
                            Dim item As New PrePedidoItem()
                            item.prepedido_id     = LeerInt(reader, "prepedido_id")
                            item.codigo           = LeerStr(reader, "codigo")
                            item.cliente_celular  = LeerStr(reader, "cliente_celular")
                            item.estado           = LeerStr(reader, "estado")
                            item.total_general_bs = LeerDecimal(reader, "total_general_bs")
                            item.estado_pago      = LeerStr(reader, "estado_pago")
                            item.creado_en        = CDate(reader("creado_en")).ToString("yyyy-MM-ddTHH:mm:ss")
                            item.agente_nombre    = LeerStr(reader, "agente_nombre")
                            item.creador_nombre   = LeerStr(reader, "creador_nombre")

                            Dim nom As String = LeerStr(reader, "cliente_nombre").Trim()
                            Dim ape As String = LeerStr(reader, "cliente_apellidos").Trim()
                            If ape <> "" Then nom = (nom & " " & ape).Trim()
                            item.cliente_nombre = If(nom = "", Nothing, nom)

                            item.token_web = LeerStr(reader, "token_web")
                            If Not IsDBNull(reader("token_expira")) Then
                                item.token_expira = CDate(reader("token_expira")).ToString("yyyy-MM-ddTHH:mm:ss")
                            End If

                            item.pago_verificado_por = LeerStr(reader, "pago_verificado_por")

                            If Not IsDBNull(reader("fecha_entrega_min")) Then
                                item.fecha_entrega_min = CDate(reader("fecha_entrega_min")).ToString("yyyy-MM-dd")
                            End If

                            ' Datos WooCommerce del primer pedido hijo
                            item.pedido_id_principal      = LeerInt(reader, "pedido_id_principal")
                            item.wc_order_id_principal    = LeerInt(reader, "wc_order_id_principal")
                            item.wc_order_number_principal = LeerStr(reader, "wc_order_number_principal")

                            items.Add(item)
                        End While
                    End Using

                    If Not IsDBNull(paramTotal.Value) Then
                        totalRegistros = CInt(paramTotal.Value)
                    End If
                End Using
            End Using
        Catch ex As SqlException
            Dim err = New With {.total = 0, .items = New List(Of PrePedidoItem)(), .error = ex.Message}
            Return New JavaScriptSerializer().Serialize(err)
        End Try

        Return New JavaScriptSerializer().Serialize(New With {.total = totalRegistros, .items = items})
    End Function

    Private Function ObtenerAgentes() As String
        Dim lista As New List(Of AgenteItem)()
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Dim sql As String =
                    "SELECT DISTINCT u.usuario_id, u.nombres + ' ' + u.apellidos AS nombre_completo " &
                    "FROM FLORERIA_Usuario u " &
                    "WHERE u.activo = 1 " &
                    "  AND (  EXISTS (SELECT 1 FROM FLORERIA_PrePedido pp WHERE pp.creado_por       = u.usuario_id) " &
                    "      OR EXISTS (SELECT 1 FROM FLORERIA_PrePedido pp WHERE pp.agente_actual_id = u.usuario_id)) " &
                    "ORDER BY nombre_completo"
                Using cmd As New SqlCommand(sql, conn)
                    Using reader As SqlDataReader = cmd.ExecuteReader()
                        While reader.Read()
                            lista.Add(New AgenteItem With {
                                .usuario_id      = LeerInt(reader, "usuario_id"),
                                .nombre_completo = LeerStr(reader, "nombre_completo")
                            })
                        End While
                    End Using
                End Using
            End Using
        Catch ex As SqlException
            Return "[]"
        End Try
        Return New JavaScriptSerializer().Serialize(lista)
    End Function

    Private Function LeerInt(r As SqlDataReader, col As String) As Integer
        If IsDBNull(r(col)) Then Return 0
        Return Convert.ToInt32(r(col))
    End Function
    Private Function LeerDecimal(r As SqlDataReader, col As String) As Decimal
        If IsDBNull(r(col)) Then Return 0D
        Return Convert.ToDecimal(r(col))
    End Function
    Private Function LeerStr(r As SqlDataReader, col As String) As String
        If IsDBNull(r(col)) Then Return ""
        Return r(col).ToString()
    End Function

    Public Class PrePedidoItem
        Public Property prepedido_id            As Integer
        Public Property codigo                  As String
        Public Property cliente_celular         As String
        Public Property cliente_nombre          As String
        Public Property estado                  As String
        Public Property token_web               As String
        Public Property token_expira            As String
        Public Property total_general_bs        As Decimal
        Public Property estado_pago             As String
        Public Property pago_verificado_por     As String
        Public Property creado_en               As String
        Public Property creador_nombre          As String
        Public Property agente_nombre           As String
        Public Property fecha_entrega_min       As String
        Public Property pedido_id_principal     As Integer
        Public Property wc_order_id_principal   As Integer
        Public Property wc_order_number_principal As String
    End Class

    Public Class AgenteItem
        Public Property usuario_id      As Integer
        Public Property nombre_completo As String
    End Class

End Class
