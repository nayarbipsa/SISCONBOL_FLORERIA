Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

' ============================================================
' SISCONBOL_FLORERIA - WC_Explorar_Handler
' Explora el espejo crudo (ordenes / productos / categorias)
' y devuelve el json_raw de un registro. Solo lectura.
' ============================================================
Public Class WC_Explorar_Handler
    Implements IHttpHandler, SessionState.IRequiresSessionState

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "text/html"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)

        If Not SesionHelper.VerificarSesion(context) Then
            context.Response.StatusCode = 401
            context.Response.Write("Sesion expirada")
            Return
        End If

        Dim action As String = LeerQS(context, "action")
        Dim tipo As String = LeerQS(context, "tipo")

        If action = "json" Then
            RenderJson(context, tipo)
            Return
        End If

        RenderListado(context, tipo)
    End Sub

    Private Sub RenderListado(context As HttpContext, tipo As String)
        Dim buscar As String = LeerQS(context, "b")
        Dim sb As New StringBuilder()
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Dim sql As String = ""
                Select Case tipo
                    Case "productos"
                        sql = "SELECT TOP 300 wc_product_id, name, sku, status, regular_price, total_sales, date_created " &
                              "FROM FLORERIA_WC_Product " &
                              "WHERE (@b='' OR name LIKE '%'+@b+'%' OR sku LIKE '%'+@b+'%') ORDER BY total_sales DESC"
                    Case "categorias"
                        sql = "SELECT TOP 300 wc_category_id, name, slug, parent, count " &
                              "FROM FLORERIA_WC_Product_Category " &
                              "WHERE (@b='' OR name LIKE '%'+@b+'%') ORDER BY count DESC"
                    Case Else ' ordenes
                        tipo = "ordenes"
                        sql = "SELECT TOP 300 wc_order_id, number, status, date_created, billing_email, total, payment_method_title, cantidad_items " &
                              "FROM FLORERIA_WC_Order " &
                              "WHERE (@b='' OR billing_email LIKE '%'+@b+'%' OR number LIKE '%'+@b+'%') ORDER BY date_created DESC"
                End Select

                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@b", If(buscar Is Nothing, "", buscar))
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        sb.Append("<table class='crm-table'><thead><tr>")
                        For i As Integer = 0 To dr.FieldCount - 1
                            sb.AppendFormat("<th>{0}</th>", context.Server.HtmlEncode(dr.GetName(i)))
                        Next
                        sb.Append("<th>JSON</th></tr></thead><tbody>")
                        Dim hay As Boolean = False
                        Dim idCol As String = If(tipo = "productos", "wc_product_id", If(tipo = "categorias", "wc_category_id", "wc_order_id"))
                        While dr.Read()
                            hay = True
                            sb.Append("<tr>")
                            Dim idVal As String = ""
                            For i As Integer = 0 To dr.FieldCount - 1
                                Dim v As Object = dr.GetValue(i)
                                Dim txt As String = If(v Is Nothing OrElse IsDBNull(v), "", v.ToString())
                                If dr.GetName(i) = idCol Then idVal = txt
                                sb.AppendFormat("<td>{0}</td>", context.Server.HtmlEncode(txt))
                            Next
                            If tipo = "categorias" Then
                                sb.Append("<td>-</td>")
                            Else
                                sb.AppendFormat("<td><button type='button' class='btn btn-sm' style='padding:2px 8px;font-size:11px' onclick=""verJson('{0}',{1})"">ver</button></td>", tipo, idVal)
                            End If
                            sb.Append("</tr>")
                        End While
                        sb.Append("</tbody></table>")
                        If Not hay Then
                            context.Response.Write("<p style='color:#999;text-align:center;padding:30px'>Sin datos. Descarga en 'Extraer'.</p>")
                            Return
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            context.Response.Write("<p style='color:#c62828;text-align:center;padding:20px'>Error: " & context.Server.HtmlEncode(ex.Message) & "</p>")
            Return
        End Try
        context.Response.Write(sb.ToString())
    End Sub

    Private Sub RenderJson(context As HttpContext, tipo As String)
        Dim id As Integer = 0
        Integer.TryParse(LeerQS(context, "id"), id)
        Dim tabla As String = "FLORERIA_WC_Order"
        Dim col As String = "wc_order_id"
        If tipo = "productos" Then
            tabla = "FLORERIA_WC_Product"
            col = "wc_product_id"
        ElseIf tipo = "categorias" Then
            tabla = "FLORERIA_WC_Product_Category"
            col = "wc_category_id"
        End If
        context.Response.ContentType = "text/plain"
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("SELECT json_raw FROM " & tabla & " WHERE " & col & "=@id", conn)
                    cmd.Parameters.AddWithValue("@id", id)
                    Dim r As Object = cmd.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then
                        context.Response.Write(r.ToString())
                    Else
                        context.Response.Write("(sin json_raw)")
                    End If
                End Using
            End Using
        Catch ex As Exception
            context.Response.Write("Error: " & ex.Message)
        End Try
    End Sub

    Private Function LeerQS(context As HttpContext, k As String) As String
        Dim v As String = context.Request.QueryString(k)
        If v Is Nothing Then Return ""
        Return v.Trim()
    End Function

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
