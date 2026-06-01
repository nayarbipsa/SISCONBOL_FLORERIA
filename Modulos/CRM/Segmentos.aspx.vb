Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Text

' ============================================================
' SISCONBOL_FLORERIA - Segmentos (code-behind)
' Tarjetas de segmentos RFM con conteo, valor y enlace a la
' lista de clientes filtrada por ese segmento.
' ============================================================
Partial Public Class Modulos_CRM_Segmentos
    Inherits System.Web.UI.Page

    Public Property CardsHtml As String = ""

    ' Definicion fija de los segmentos RFM (nombre, color, descripcion)
    Private Shared ReadOnly Defs As New List(Of String())(New String()() {
        New String() {"Campeon", "#2e7d32", "Compraron hace poco, con frecuencia y mucho monto. Tus mejores clientes."},
        New String() {"Leal", "#1565c0", "Compran seguido. Mantenelos con beneficios y novedades."},
        New String() {"Nuevo/Potencial", "#e65100", "Compraron hace poco pero pocas veces. Buen potencial para fidelizar."},
        New String() {"En riesgo", "#f9a825", "Buenos clientes que llevan tiempo sin comprar. Reactivalos."},
        New String() {"Perdido", "#c62828", "Hace mucho que no compran. Campana de recuperacion agresiva."},
        New String() {"Regular", "#757575", "Comportamiento promedio. Oportunidad de hacerlos crecer."}
    })

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        Dim conteos As New Dictionary(Of String, Integer)
        Dim valores As New Dictionary(Of String, Decimal)
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("SELECT rfm_segmento, COUNT(*) AS c, ISNULL(SUM(total_gastado_bs),0) AS v FROM FLORERIA_CRM_Cliente GROUP BY rfm_segmento", conn)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim seg As String = If(IsDBNull(dr("rfm_segmento")), "", dr("rfm_segmento").ToString())
                            conteos(seg) = CInt(dr("c"))
                            valores(seg) = CDec(dr("v"))
                        End While
                    End Using
                End Using
            End Using
        Catch ex As Exception
            CardsHtml = "<p style='color:#c62828'>Error: " & Server.HtmlEncode(ex.Message) & "</p>"
            Return
        End Try

        Dim sb As New StringBuilder()
        For Each d As String() In Defs
            Dim nombre As String = d(0)
            Dim color As String = d(1)
            Dim desc As String = d(2)
            Dim cnt As Integer = If(conteos.ContainsKey(nombre), conteos(nombre), 0)
            Dim val As Decimal = If(valores.ContainsKey(nombre), valores(nombre), 0D)
            sb.AppendFormat("<div class='seg-card' style='border-left-color:{0}'>", color)
            sb.AppendFormat("<h3 style='color:{0}'>{1}</h3>", color, Server.HtmlEncode(nombre))
            sb.AppendFormat("<div class='cnt'>{0}</div>", cnt.ToString("N0", CultureInfo.InvariantCulture))
            sb.AppendFormat("<div class='val'>{0} Bs en compras</div>", val.ToString("N0", CultureInfo.InvariantCulture))
            sb.AppendFormat("<p>{0}</p>", Server.HtmlEncode(desc))
            sb.AppendFormat("<a class='btn btn-sm' href='Clientes.aspx'><i class='ti ti-list'></i> Ver clientes</a>")
            sb.Append("</div>")
        Next
        CardsHtml = sb.ToString()
    End Sub

End Class
