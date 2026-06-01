Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text

' ============================================================
' SISCONBOL_FLORERIA - Analisis (code-behind)
' Dashboard server-side: KPIs, segmentos, top productos, estacionalidad.
' Lee los SPs FLORERIA_CRM_sp_Dashboard_* y _Estacionalidad.
' ============================================================
Partial Public Class Modulos_CRM_Analisis
    Inherits System.Web.UI.Page

    Public Property TotalClientes As String = "0"
    Public Property Recurrentes As String = "0"
    Public Property Unicos As String = "0"
    Public Property IngresoTotal As String = "0"
    Public Property LtvPromedio As String = "0"
    Public Property TicketPromedio As String = "0"
    Public Property SegmentosHtml As String = ""
    Public Property TopProductosHtml As String = ""
    Public Property EstacionalidadHtml As String = ""

    Private Shared ReadOnly MesesNombre() As String = {"", "Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"}

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Try
            CargarKpis()
            CargarTopProductos()
            CargarEstacionalidad()
        Catch ex As Exception
            SegmentosHtml = "<p style='color:#c62828'>Error: " & Server.HtmlEncode(ex.Message) & "</p>"
        End Try
    End Sub

    Private Sub CargarKpis()
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_CRM_sp_Dashboard_KPIs", conn)
                cmd.CommandType = CommandType.StoredProcedure
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        TotalClientes = Format(CInt(dr("total_clientes")))
                        Recurrentes = Format(CInt(dr("clientes_recurrentes")))
                        Unicos = Format(CInt(dr("clientes_unicos")))
                        IngresoTotal = CDec(dr("ingreso_total_bs")).ToString("N0", CultureInfo.InvariantCulture)
                        LtvPromedio = CDec(dr("ltv_promedio_bs")).ToString("N2", CultureInfo.InvariantCulture)
                        TicketPromedio = CDec(dr("ticket_promedio_bs")).ToString("N2", CultureInfo.InvariantCulture)
                    End If

                    ' Segundo result set: distribucion por segmento
                    Dim sb As New StringBuilder()
                    If dr.NextResult() Then
                        ' acumular para barras proporcionales
                        Dim segs As New List(Of String())
                        Dim maxVal As Decimal = 0D
                        While dr.Read()
                            Dim seg As String = If(IsDBNull(dr("rfm_segmento")), "(s/d)", dr("rfm_segmento").ToString())
                            Dim cli As Integer = CInt(dr("clientes"))
                            Dim val As Decimal = CDec(dr("valor_bs"))
                            If val > maxVal Then maxVal = val
                            segs.Add(New String() {seg, cli.ToString(), val.ToString("N0", CultureInfo.InvariantCulture), val.ToString()})
                        End While
                        sb.Append("<table class='crm-table'><thead><tr><th>Segmento</th><th style='text-align:center'>Clientes</th><th style='text-align:right'>Valor (Bs)</th><th style='width:30%'></th></tr></thead><tbody>")
                        For Each s As String() In segs
                            Dim val As Decimal = Decimal.Parse(s(3), CultureInfo.InvariantCulture)
                            Dim pct As Integer = If(maxVal > 0, CInt(Math.Round(val / maxVal * 100)), 0)
                            sb.AppendFormat("<tr><td><strong>{0}</strong></td><td style='text-align:center'>{1}</td><td style='text-align:right'>{2}</td><td><div class='bar' style='width:{3}%'></div></td></tr>",
                                            Server.HtmlEncode(s(0)), s(1), s(2), pct)
                        Next
                        sb.Append("</tbody></table>")
                    End If
                    SegmentosHtml = sb.ToString()
                End Using
            End Using
        End Using
        If SegmentosHtml = "" Then SegmentosHtml = "<p style='color:#999'>Sin datos. Recalcula clientes en 'Extraer'.</p>"
    End Sub

    Private Sub CargarTopProductos()
        Dim sb As New StringBuilder()
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_CRM_sp_Dashboard_TopProductos", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@top", 15)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    sb.Append("<table class='crm-table'><thead><tr><th>Producto</th><th style='text-align:center'>Unidades</th><th style='text-align:right'>Total (Bs)</th></tr></thead><tbody>")
                    Dim hay As Boolean = False
                    While dr.Read()
                        hay = True
                        sb.AppendFormat("<tr><td>{0}</td><td style='text-align:center'>{1}</td><td style='text-align:right'>{2:N2}</td></tr>",
                                        Server.HtmlEncode(dr("nombre").ToString()), dr("unidades"), CDec(dr("total_bs")))
                    End While
                    sb.Append("</tbody></table>")
                    If Not hay Then sb.Clear() : sb.Append("<p style='color:#999'>Sin datos.</p>")
                End Using
            End Using
        End Using
        TopProductosHtml = sb.ToString()
    End Sub

    Private Sub CargarEstacionalidad()
        Dim sb As New StringBuilder()
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_CRM_sp_Dashboard_Estacionalidad", conn)
                cmd.CommandType = CommandType.StoredProcedure
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    sb.Append("<table class='crm-table'><thead><tr><th>Periodo</th><th style='text-align:center'>Pedidos</th><th style='text-align:right'>Total (Bs)</th></tr></thead><tbody>")
                    Dim hay As Boolean = False
                    While dr.Read()
                        hay = True
                        Dim anio As Integer = CInt(dr("anio"))
                        Dim mes As Integer = CInt(dr("mes"))
                        Dim mesTxt As String = If(mes >= 1 AndAlso mes <= 12, MesesNombre(mes), mes.ToString())
                        sb.AppendFormat("<tr><td>{0} {1}</td><td style='text-align:center'>{2}</td><td style='text-align:right'>{3:N2}</td></tr>",
                                        mesTxt, anio, dr("pedidos"), CDec(dr("total_bs")))
                    End While
                    sb.Append("</tbody></table>")
                    If Not hay Then sb.Clear() : sb.Append("<p style='color:#999'>Sin datos. Descarga ordenes en 'Extraer'.</p>")
                End Using
            End Using
        End Using
        EstacionalidadHtml = sb.ToString()
    End Sub

    Private Function Format(n As Integer) As String
        Return n.ToString("N0", CultureInfo.InvariantCulture)
    End Function

End Class
