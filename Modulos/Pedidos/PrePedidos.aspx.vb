Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

' ============================================================
' MODULO: Lista de Pre-Pedidos
' Archivo: Modulos/Pedidos/PrePedidos.aspx.vb
' Arquitectura: MasterPage — NO tocar sesión ni menú aquí
' ============================================================
Partial Public Class Modulos_Pedidos_PrePedidos
    Inherits System.Web.UI.Page

    ' JSON para la primera carga (evita segundo request)
    Public Property JsonInicial As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            ' Detectar si viene como petición AJAX (fetch del JS)
            Dim esAjax As Boolean = (Request.Headers("X-Requested-With") = "XMLHttpRequest")
            Dim accion As String = If(Request.QueryString("accion"), "")

            If esAjax AndAlso accion = "LISTAR" Then
                ResponderAjax()
            Else
                ' Primera carga normal: pre-cargar datos en JSON para el JS
                JsonInicial = ObtenerJson(
                    buscar:=If(Request.QueryString("buscar"), ""),
                    estado:=If(Request.QueryString("estado"), ""),
                    pagina:=1
                )
            End If
        End If
    End Sub

    ' ============================================================
    ' RESPUESTA AJAX — fetch() desde el JS
    ' ============================================================
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

    ' ============================================================
    ' OBTENER JSON — usado tanto en primera carga como en AJAX
    ' ============================================================
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

                    ' Siempre filtrar por agente actual
                    cmd.Parameters.AddWithValue("@agente_id", usuarioId)

                    ' Tipo: por defecto solo PRE_PEDIDO en esta pantalla
                    cmd.Parameters.AddWithValue("@tipo_registro", "PRE_PEDIDO")

                    ' Estado (NULL = todos)
                    If estado <> "" Then
                        cmd.Parameters.AddWithValue("@estado", estado)
                    Else
                        cmd.Parameters.AddWithValue("@estado", DBNull.Value)
                    End If

                    ' Búsqueda (NULL = sin filtro)
                    If buscar <> "" Then
                        cmd.Parameters.AddWithValue("@buscar", buscar)
                    Else
                        cmd.Parameters.AddWithValue("@buscar", DBNull.Value)
                    End If

                    cmd.Parameters.AddWithValue("@pagina", pagina)
                    cmd.Parameters.AddWithValue("@por_pagina", porPagina)

                    Dim paramTotal As New SqlParameter("@total_registros", SqlDbType.Int)
                    paramTotal.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(paramTotal)

                    Using reader As SqlDataReader = cmd.ExecuteReader()
                        While reader.Read()
                            Dim item As New PrePedidoItem()
                            item.prepedido_id = CInt(reader("prepedido_id"))
                            item.codigo = reader("codigo").ToString()
                            item.cliente_celular = reader("cliente_celular").ToString()
                            item.estado = reader("estado").ToString()
                            item.total_general_bs = CDec(reader("total_general_bs"))
                            item.estado_pago = reader("estado_pago").ToString()
                            item.creado_en = CDate(reader("creado_en")).ToString("yyyy-MM-ddTHH:mm:ss")

                            ' Nombre completo
                            Dim nom As String = ""
                            If Not IsDBNull(reader("cliente_nombre")) Then nom = reader("cliente_nombre").ToString().Trim()
                            If Not IsDBNull(reader("cliente_apellidos")) AndAlso reader("cliente_apellidos").ToString().Trim() <> "" Then
                                nom = (nom & " " & reader("cliente_apellidos").ToString().Trim()).Trim()
                            End If
                            item.cliente_nombre = If(nom = "", Nothing, nom)

                            ' Token
                            If Not IsDBNull(reader("token_web")) Then
                                item.token_web = reader("token_web").ToString()
                            End If
                            If Not IsDBNull(reader("token_expira")) Then
                                item.token_expira = CDate(reader("token_expira")).ToString("yyyy-MM-ddTHH:mm:ss")
                            End If

                            ' Quien verificó
                            If Not IsDBNull(reader("pago_verificado_por")) Then
                                item.pago_verificado_por = reader("pago_verificado_por").ToString()
                            End If

                            items.Add(item)
                        End While
                    End Using

                    ' Leer OUTPUT después de cerrar el reader
                    If Not IsDBNull(paramTotal.Value) Then
                        totalRegistros = CInt(paramTotal.Value)
                    End If
                End Using
            End Using

        Catch ex As SqlException
            ' Devolver estructura vacía con error
            Dim errObj = New With {.total = 0, .items = New List(Of PrePedidoItem)(), .error = ex.Message}
            Return New JavaScriptSerializer().Serialize(errObj)
        End Try

        Dim resultado = New With {.total = totalRegistros, .items = items}
        Return New JavaScriptSerializer().Serialize(resultado)
    End Function

    ' ============================================================
    ' CLASE DE DATOS
    ' ============================================================
    Public Class PrePedidoItem
        Public Property prepedido_id As Integer
        Public Property codigo As String
        Public Property cliente_celular As String
        Public Property cliente_nombre As String
        Public Property estado As String
        Public Property token_web As String
        Public Property token_expira As String
        Public Property total_general_bs As Decimal
        Public Property estado_pago As String
        Public Property pago_verificado_por As String
        Public Property creado_en As String
    End Class

End Class
