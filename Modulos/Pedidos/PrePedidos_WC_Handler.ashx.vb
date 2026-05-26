Imports System.Web
Imports System.Web.Script.Serialization

' ============================================================
' HANDLER : PrePedidos_WC_Handler.ashx.vb
' Propósito: Sincronizar un pedido con WooCommerce desde la
'            lista de pre-pedidos (botón WC en cada fila)
' Reutiliza: WooCommerceSync.SincronizarPedido (ya existe)
' Uso: POST ?accion=SINCRONIZAR_WC&pedido_id=123
' ============================================================
Namespace SISCONBOL_FLORERIA
    Public Class PrePedidos_WC_Handler
        Implements IHttpHandler

        Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
            Get
                Return False
            End Get
        End Property

        Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
            context.Response.ContentType = "application/json"
            context.Response.Charset     = "utf-8"

            ' Verificar sesión
            If Not SesionHelper.VerificarSesion(context) Then
                context.Response.Write("{""ok"":false,""mensaje"":""Sesión expirada""}")
                Return
            End If

            Dim accion As String = If(context.Request("accion"), "")

            Select Case accion.ToUpper()
                Case "SINCRONIZAR_WC"
                    SincronizarConWC(context)
                Case Else
                    context.Response.Write("{""ok"":false,""mensaje"":""Acción no reconocida""}")
            End Select
        End Sub

        ' --------------------------------------------------------
        ' Llama a WooCommerceSync.SincronizarPedido y devuelve
        ' el resultado + la URL del pedido en WC si tuvo éxito
        ' --------------------------------------------------------
        Private Sub SincronizarConWC(context As HttpContext)
            Dim pedidoId As Integer = 0
            If Not Integer.TryParse(context.Request("pedido_id"), pedidoId) OrElse pedidoId <= 0 Then
                context.Response.Write("{""ok"":false,""mensaje"":""pedido_id inválido""}")
                Return
            End If

            Try
                Dim resultado As Dictionary(Of String, Object) = WooCommerceSync.SincronizarPedido(pedidoId)

                Dim ok        As Boolean = CBool(resultado("ok"))
                Dim mensaje   As String  = resultado("mensaje").ToString()
                Dim wcOrderId As Integer = CInt(resultado("wc_order_id"))
                Dim wcUrl     As String  = ""

                If ok AndAlso wcOrderId > 0 Then
                    wcUrl = "https://miss-flores.com/wp-admin/post.php?post=" & wcOrderId & "&action=edit"
                End If

                Dim serializer As New JavaScriptSerializer()
                Dim respuesta  = New With {
                    .ok        = ok,
                    .mensaje   = mensaje,
                    .wc_order_id = wcOrderId,
                    .wc_url    = wcUrl
                }
                context.Response.Write(serializer.Serialize(respuesta))

            Catch ex As Exception
                context.Response.Write("{""ok"":false,""mensaje"":""Error interno: " & ex.Message.Replace("""", "'") & """}")
            End Try
        End Sub

    End Class
End Namespace
