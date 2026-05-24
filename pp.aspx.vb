Imports System.Data.SqlClient
Imports System.Web

' ============================================================
' SISCONBOL - Redirect Corto Pre-Pedidos (para Somee.com)
' Archivo: pp.aspx.vb
' URL: https://www.floreria.somee.com/pp.aspx?c=PRE-000042
' Redirige a: PrePedido_Detalle.aspx?id=42
' ============================================================
Partial Public Class pp
    Inherits System.Web.UI.Page

    ' ============================================================
    ' Page_Load - Procesar redirect
    ' ============================================================
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' Obtener código del pre-pedido
        Dim codigo As String = Request.QueryString("c")
        
        ' Validar que venga el código
        If String.IsNullOrEmpty(codigo) Then
            ' Sin código, redirigir a lista de pre-pedidos
            Response.Redirect("~/Modulos/Pedidos/PrePedidos.aspx", False)
            Return
        End If
        
        ' Limpiar y validar formato del código
        codigo = codigo.Trim().ToUpper()
        
        ' Validar formato PRE-XXXXXX
        If Not codigo.StartsWith("PRE-") OrElse codigo.Length < 8 Then
            ' Código inválido
            Response.Redirect("~/Modulos/Pedidos/PrePedidos.aspx?error=codigo_invalido", False)
            Return
        End If
        
        ' Buscar el pre-pedido en la base de datos
        Dim prepedidoId As Integer = BuscarPorCodigo(codigo)
        
        If prepedidoId > 0 Then
            ' Pre-pedido encontrado - redirigir al detalle
            Response.Redirect("~/Modulos/Pedidos/PrePedido_Detalle.aspx?id=" & prepedidoId, False)
        Else
            ' No encontrado - redirigir a lista con mensaje
            Response.Redirect("~/Modulos/Pedidos/PrePedidos.aspx?error=no_encontrado&c=" & Server.UrlEncode(codigo), False)
        End If
    End Sub

    ' ============================================================
    ' BuscarPorCodigo - Obtener ID del pre-pedido por código
    ' ============================================================
    Private Function BuscarPorCodigo(codigo As String) As Integer
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                
                ' Query simple para obtener el ID
                Dim sql As String = "SELECT prepedido_id FROM FLORERIA_PrePedido WHERE codigo = @codigo"
                
                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@codigo", codigo)
                    
                    Dim result As Object = cmd.ExecuteScalar()
                    
                    If result IsNot Nothing AndAlso Not IsDBNull(result) Then
                        Return Convert.ToInt32(result)
                    End If
                End Using
            End Using
            
        Catch ex As Exception
            ' Log del error (opcional)
            System.Diagnostics.Debug.WriteLine("ERROR pp.BuscarPorCodigo: " & ex.Message)
        End Try
        
        Return 0 ' No encontrado o error
    End Function

End Class
