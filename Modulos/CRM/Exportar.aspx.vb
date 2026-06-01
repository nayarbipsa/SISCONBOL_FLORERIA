Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text

' ============================================================
' SISCONBOL_FLORERIA - Exportar (code-behind)
' Genera CSV de clientes (Google Ads Customer Match o generico)
' y lo entrega como descarga. Audita en FLORERIA_CRM_Export_Log.
' ============================================================
Partial Public Class Modulos_CRM_Exportar
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
    End Sub

    Protected Sub btnExportar_Click(sender As Object, e As EventArgs)
        Dim segmento As String = LeerForm("selSegmento")
        Dim formato As String = LeerForm("selFormato")
        If formato = "" Then formato = "GOOGLEADS"
        Dim esGoogle As Boolean = (formato = "GOOGLEADS")

        Dim sb As New StringBuilder()
        Dim filas As Integer = 0

        If esGoogle Then
            sb.AppendLine("Email,Phone,First Name,Last Name,Country")
        Else
            sb.AppendLine("email,telefono,nombre,apellidos,ciudad,zona,pedidos,total_gastado_bs,ticket_bs,primera_compra,ultima_compra,dias_sin_comprar,segmento")
        End If

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_CRM_sp_Export_Clientes", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@segmento", If(segmento = "", CObj(DBNull.Value), CObj(segmento)))
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            filas += 1
                            If esGoogle Then
                                sb.Append(C(L(dr, "email_sha256"))) : sb.Append(",")
                                sb.Append(C(L(dr, "telefono_sha256"))) : sb.Append(",")
                                sb.Append(C(L(dr, "nombre"))) : sb.Append(",")
                                sb.Append(C(L(dr, "apellidos"))) : sb.Append(",")
                                sb.AppendLine("BO")
                            Else
                                sb.Append(C(L(dr, "email_original"))) : sb.Append(",")
                                sb.Append(C(L(dr, "telefono_norm"))) : sb.Append(",")
                                sb.Append(C(L(dr, "nombre"))) : sb.Append(",")
                                sb.Append(C(L(dr, "apellidos"))) : sb.Append(",")
                                sb.Append(C(L(dr, "ciudad_top"))) : sb.Append(",")
                                sb.Append(C(L(dr, "zona_top"))) : sb.Append(",")
                                sb.Append(L(dr, "total_pedidos")) : sb.Append(",")
                                sb.Append(Num(dr, "total_gastado_bs")) : sb.Append(",")
                                sb.Append(Num(dr, "ticket_promedio_bs")) : sb.Append(",")
                                sb.Append(Fecha(dr, "primera_compra")) : sb.Append(",")
                                sb.Append(Fecha(dr, "ultima_compra")) : sb.Append(",")
                                sb.Append(L(dr, "dias_desde_ultima")) : sb.Append(",")
                                sb.AppendLine(C(L(dr, "rfm_segmento")))
                            End If
                        End While
                    End Using
                End Using

                ' Auditar
                Using cmd As New SqlCommand("INSERT INTO FLORERIA_CRM_Export_Log(segmento_id, formato, total_filas, incluye_hashes, usuario_id, exportado_en) VALUES(NULL, @f, @t, @h, @u, GETDATE())", conn)
                    cmd.Parameters.AddWithValue("@f", If(esGoogle, "CSV_GOOGLEADS", "CSV_GENERICO"))
                    cmd.Parameters.AddWithValue("@t", filas)
                    cmd.Parameters.AddWithValue("@h", esGoogle)
                    cmd.Parameters.AddWithValue("@u", SesionHelper.ObtenerUsuarioId(HttpContext.Current))
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            Response.Clear()
            Response.Write("Error al exportar: " & Server.HtmlEncode(ex.Message))
            Response.End()
            Return
        End Try

        Dim nombreArch As String = If(esGoogle, "clientes_googleads_", "clientes_") & DateTime.Now.ToString("yyyyMMdd_HHmm") & ".csv"
        Response.Clear()
        Response.ContentType = "text/csv"
        Response.AddHeader("Content-Disposition", "attachment; filename=" & nombreArch)
        Response.Write(sb.ToString())
        Response.End()
    End Sub

    ' ---- helpers CSV ----
    Private Function L(dr As SqlDataReader, col As String) As String
        Dim o As Object = dr(col)
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return o.ToString()
    End Function

    Private Function Num(dr As SqlDataReader, col As String) As String
        Dim o As Object = dr(col)
        If o Is Nothing OrElse IsDBNull(o) Then Return "0"
        Return CDec(o).ToString("F2", CultureInfo.InvariantCulture)
    End Function

    Private Function Fecha(dr As SqlDataReader, col As String) As String
        Dim o As Object = dr(col)
        If o Is Nothing OrElse IsDBNull(o) Then Return ""
        Return CDate(o).ToString("yyyy-MM-dd")
    End Function

    ' Escapa un campo CSV
    Private Function C(s As String) As String
        If s Is Nothing Then Return ""
        If s.Contains(",") OrElse s.Contains("""") OrElse s.Contains(vbLf) OrElse s.Contains(vbCr) Then
            Return """" & s.Replace("""", """""") & """"
        End If
        Return s
    End Function

    Private Function LeerForm(campo As String) As String
        Dim v As String = Request.Form(campo)
        If v Is Nothing Then Return ""
        Return v.Trim()
    End Function

End Class
