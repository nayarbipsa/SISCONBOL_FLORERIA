Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

' ============================================================
' MODULO : Lista de Pre-Pedidos
' Archivo : Modulos/Pedidos/PrePedidos.aspx.vb
' Arq.    : MasterPage — sesión y menú los maneja Site.Master
' ============================================================
Partial Public Class Modulos_Pedidos_PrePedidos
    Inherits System.Web.UI.Page

    Public Property JsonInicial As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Dim esAjax As Boolean = (Request.Headers("X-Requested-With") = "XMLHttpRequest")
            Dim accion As String = If(Request.QueryString("accion"), "")

            If esAjax AndAlso accion = "LISTAR" Then
                ResponderAjax()
            Else
                ' Primera carga: pre-inyectar datos para evitar fetch extra
                JsonInicial = ObtenerJson(
                    buscar:=If(Request.QueryString("buscar"), ""),
                    estado:=If(Request.QueryString("estado"), ""),
                    pagina:=1
                )
            End If
        End If
    End Sub

    ' ----------------------------------------------------------------
    ' AJAX — responde al fetch() del JS con Content-Type application/json
    ' ----------------------------------------------------------------
    Private Sub ResponderAjax()
        Dim buscar As String = If(Request.QueryString("buscar"), "")
        Dim estado As String = If(Request.QueryString("estado"), "")
        Dim pagina As Integer = 1
        If Not Integer.TryParse(Request.QueryString("p"), pagina) Then pagina = 1

        Dim json As String = ObtenerJson(buscar, estado, pagina)

        Response.Clear()
        Response.ContentType = "application/json"
        Response.Charset = "utf-8"
        Response.Write(json)
        Response.End()
    End Sub

    ' ----------------------------------------------------------------
    ' OBTENER JSON — primera carga y AJAX usan el mismo método
    ' ----------------------------------------------------------------
    Private Function ObtenerJson(buscar As String, estado As String, pagina As Integer) As String
        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        Dim porPagina As Integer = 20
        Dim totalRegistros As Integer = 0
        Dim items As New List(Of PrePedidoItem)()

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_PrePedido_Listar", conn)
                    cmd.CommandType = CommandType.StoredProcedure

                    cmd.Parameters.AddWithValue("@agente_id",     usuarioId)
                    cmd.Parameters.AddWithValue("@tipo_registro",  "PRE_PEDIDO")
                    cmd.Parameters.AddWithValue("@estado",         If(estado <> "", CObj(estado), DBNull.Value))
                    cmd.Parameters.AddWithValue("@buscar",         If(buscar <> "", CObj(buscar), DBNull.Value))
                    cmd.Parameters.AddWithValue("@pagina",         pagina)
                    cmd.Parameters.AddWithValue("@por_pagina",     porPagina)

                    Dim paramTotal As New SqlParameter("@total_registros", SqlDbType.Int)
                    paramTotal.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(paramTotal)

                    Using reader As SqlDataReader = cmd.ExecuteReader()
                        While reader.Read()
                            Dim item As New PrePedidoItem()
                            item.prepedido_id    = LeerInt(reader, "prepedido_id")
                            item.codigo          = reader("codigo").ToString()
                            item.cliente_celular = reader("cliente_celular").ToString()
                            item.estado          = reader("estado").ToString()
                            item.total_general_bs = LeerDecimal(reader, "total_general_bs")
                            item.estado_pago     = reader("estado_pago").ToString()
                            item.creado_en       = CDate(reader("creado_en")).ToString("yyyy-MM-ddTHH:mm:ss")
                            item.creado_por_nombre = LeerStr(reader, "creado_por_nombre")

                            ' Nombre completo del cliente
                            Dim nom As String = LeerStr(reader, "cliente_nombre").Trim()
                            Dim ape As String = LeerStr(reader, "cliente_apellidos").Trim()
                            If ape <> "" Then nom = (nom & " " & ape).Trim()
                            item.cliente_nombre = If(nom = "", Nothing, nom)

                            ' Token
                            item.token_web    = LeerStr(reader, "token_web")
                            Dim te As String  = LeerStr(reader, "token_expira")
                            If te <> "" Then item.token_expira = CDate(reader("token_expira")).ToString("yyyy-MM-ddTHH:mm:ss")

                            ' Verificador de pago
                            item.pago_verificado_por = LeerStr(reader, "pago_verificado_por")

                            ' Fecha de entrega más próxima de los pedidos hijos
                            If Not IsDBNull(reader("fecha_entrega_min")) Then
                                item.fecha_entrega_min = CDate(reader("fecha_entrega_min")).ToString("yyyy-MM-dd")
                            End If

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

        Dim resultado = New With {.total = totalRegistros, .items = items}
        Return New JavaScriptSerializer().Serialize(resultado)
    End Function

    ' ----------------------------------------------------------------
    ' HELPERS
    ' ----------------------------------------------------------------
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

    ' ----------------------------------------------------------------
    ' CLASE DE DATOS
    ' ----------------------------------------------------------------
    Public Class PrePedidoItem
        Public Property prepedido_id       As Integer
        Public Property codigo             As String
        Public Property cliente_celular    As String
        Public Property cliente_nombre     As String
        Public Property estado             As String
        Public Property token_web          As String
        Public Property token_expira       As String
        Public Property total_general_bs   As Decimal
        Public Property estado_pago        As String
        Public Property pago_verificado_por As String
        Public Property creado_en          As String
        Public Property creado_por_nombre  As String
        Public Property fecha_entrega_min  As String
    End Class

End Class
