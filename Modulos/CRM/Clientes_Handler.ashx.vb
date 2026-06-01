Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

' ============================================================
' SISCONBOL_FLORERIA - Clientes_Handler
' Devuelve el fragmento HTML de la tabla de clientes (capa B).
' ============================================================
Public Class Clientes_Handler
    Implements IHttpHandler, SessionState.IRequiresSessionState

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "text/html"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)

        If Not SesionHelper.VerificarSesion(context) Then
            context.Response.StatusCode = 401
            context.Response.Write("<p style='text-align:center;color:#c62828;padding:20px'>Sesion expirada</p>")
            Return
        End If

        Dim action As String = LeerQS(context, "action")
        If action = "ficha" Then
            RenderFicha(context)
            Return
        End If

        RenderListado(context)
    End Sub

    Private Sub RenderListado(context As HttpContext)
        Dim buscar As String = LeerQS(context, "b")
        Dim seg As String = LeerQS(context, "seg")
        Dim orden As String = LeerQS(context, "o")
        If orden = "" Then orden = "gasto"

        Dim sb As New StringBuilder()
        Dim filas As Integer = 0
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_CRM_sp_Cliente_Listar", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@busqueda", Blanco(buscar))
                    cmd.Parameters.AddWithValue("@segmento", Blanco(seg))
                    cmd.Parameters.AddWithValue("@ciudad", DBNull.Value)
                    cmd.Parameters.AddWithValue("@orden", orden)
                    cmd.Parameters.AddWithValue("@top", 500)

                    sb.Append("<table class='crm-table'><thead><tr>")
                    sb.Append("<th>Cliente</th><th>Contacto</th><th>Ciudad</th><th style='text-align:center'>Pedidos</th>")
                    sb.Append("<th style='text-align:right'>Gastado (Bs)</th><th style='text-align:right'>Ticket</th>")
                    sb.Append("<th>Ultima compra</th><th>Segmento</th><th>RFM</th>")
                    sb.Append("</tr></thead><tbody>")

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            filas += 1
                            Dim nombre As String = (LeerStr(dr, "nombre") & " " & LeerStr(dr, "apellidos")).Trim()
                            If nombre = "" Then nombre = "(sin nombre)"
                            Dim email As String = LeerStr(dr, "email_original")
                            If email = "" Then email = LeerStr(dr, "email_norm")
                            Dim segm As String = LeerStr(dr, "rfm_segmento")
                            Dim ultima As Object = dr("ultima_compra")
                            Dim ultimaTxt As String = If(IsDBNull(ultima), "-", CDate(ultima).ToString("yyyy-MM-dd"))

                            sb.Append("<tr>")
                            sb.AppendFormat("<td><strong>{0}</strong></td>", context.Server.HtmlEncode(nombre))
                            sb.AppendFormat("<td>{0}<br/><span style='color:#999;font-size:11px'>{1}</span></td>",
                                            context.Server.HtmlEncode(email), context.Server.HtmlEncode(LeerStr(dr, "telefono_norm")))
                            sb.AppendFormat("<td>{0}</td>", context.Server.HtmlEncode(LeerStr(dr, "ciudad_top")))
                            sb.AppendFormat("<td style='text-align:center'>{0}</td>", dr("total_pedidos"))
                            sb.AppendFormat("<td style='text-align:right'>{0:N2}</td>", CDec(dr("total_gastado_bs")))
                            sb.AppendFormat("<td style='text-align:right'>{0:N2}</td>", CDec(dr("ticket_promedio_bs")))
                            sb.AppendFormat("<td>{0}</td>", ultimaTxt)
                            sb.AppendFormat("<td><span class='seg seg-{0}'>{1}</span></td>", ClaseSeg(segm), context.Server.HtmlEncode(segm))
                            sb.AppendFormat("<td style='color:#999;font-size:11px'>{0}-{1}-{2}</td>",
                                            LeerStr(dr, "r_score"), LeerStr(dr, "f_score"), LeerStr(dr, "m_score"))
                            sb.Append("</tr>")
                        End While
                    End Using
                    sb.Append("</tbody></table>")
                End Using
            End Using
        Catch ex As Exception
            context.Response.Write("<p style='color:#c62828;text-align:center;padding:20px'>Error: " & context.Server.HtmlEncode(ex.Message) & "</p>")
            Return
        End Try

        If filas = 0 Then
            context.Response.Write("<p style='color:#999;text-align:center;padding:30px'>No hay clientes. Descarga ordenes y recalcula en 'Extraer'.</p>")
            Return
        End If
        context.Response.Write("<p style='color:#999;font-size:12px;margin:0 0 8px 0'>" & filas & " clientes</p>")
        context.Response.Write(sb.ToString())
    End Sub

    Private Sub RenderFicha(context As HttpContext)
        Dim idStr As String = LeerQS(context, "id")
        Dim id As Integer = 0
        Integer.TryParse(idStr, id)
        Dim sb As New StringBuilder()
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_CRM_sp_Cliente_Ficha", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@cliente_crm_id", id)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            sb.AppendFormat("<h3>{0} {1}</h3>", context.Server.HtmlEncode(LeerStr(dr, "nombre")), context.Server.HtmlEncode(LeerStr(dr, "apellidos")))
                            sb.AppendFormat("<p>{0} | {1}</p>", context.Server.HtmlEncode(LeerStr(dr, "email_original")), context.Server.HtmlEncode(LeerStr(dr, "telefono_norm")))
                        End If
                        If dr.NextResult() Then
                            sb.Append("<table class='crm-table'><thead><tr><th>WC#</th><th>Estado</th><th>Fecha</th><th>Entrega</th><th style='text-align:right'>Total</th><th>Pago</th><th>Ocasion</th></tr></thead><tbody>")
                            While dr.Read()
                                Dim fc As Object = dr("date_created")
                                Dim de As Object = dr("delivery_date")
                                sb.Append("<tr>")
                                sb.AppendFormat("<td>{0}</td>", LeerStr(dr, "number"))
                                sb.AppendFormat("<td>{0}</td>", context.Server.HtmlEncode(LeerStr(dr, "status")))
                                sb.AppendFormat("<td>{0}</td>", If(IsDBNull(fc), "-", CDate(fc).ToString("yyyy-MM-dd")))
                                sb.AppendFormat("<td>{0}</td>", If(IsDBNull(de), "-", CDate(de).ToString("yyyy-MM-dd")))
                                sb.AppendFormat("<td style='text-align:right'>{0:N2}</td>", CDec(dr("total")))
                                sb.AppendFormat("<td>{0}</td>", context.Server.HtmlEncode(LeerStr(dr, "payment_method_title")))
                                sb.AppendFormat("<td>{0}</td>", context.Server.HtmlEncode(LeerStr(dr, "tipo_ocacion")))
                                sb.Append("</tr>")
                            End While
                            sb.Append("</tbody></table>")
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            context.Response.Write("Error: " & context.Server.HtmlEncode(ex.Message))
            Return
        End Try
        context.Response.Write(sb.ToString())
    End Sub

    ' ---- helpers ----
    Private Function ClaseSeg(s As String) As String
        If s Is Nothing Then Return "Regular"
        Return s.Replace("/", "").Replace(" ", "")
    End Function

    Private Function LeerStr(dr As SqlDataReader, col As String) As String
        Dim o As Object = dr(col)
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return o.ToString()
    End Function

    Private Function LeerQS(context As HttpContext, k As String) As String
        Dim v As String = context.Request.QueryString(k)
        If v Is Nothing Then Return ""
        Return v.Trim()
    End Function

    Private Function Blanco(s As String) As Object
        If s Is Nothing OrElse s.Trim() = "" Then Return DBNull.Value
        Return s.Trim()
    End Function

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
