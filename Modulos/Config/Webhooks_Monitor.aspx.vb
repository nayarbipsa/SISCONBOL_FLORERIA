Imports System.Data
Imports System.Data.SqlClient

Namespace Modulos.Config
    Partial Public Class Webhooks_Monitor
        Inherits System.Web.UI.Page

        ' Declarar controles explícitamente
        Protected WithEvents hdnAccion As System.Web.UI.WebControls.HiddenField
        Protected WithEvents hdnLogId As System.Web.UI.WebControls.HiddenField
        Protected WithEvents btnAccion As System.Web.UI.WebControls.Button

        Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
            ' Verificar sesión - SesionHelper.VerificarSesion recibe HttpContext
            If Not SesionHelper.VerificarSesion(Context) Then
                Response.Redirect("~/Login.aspx")
                Return
            End If

            If Not IsPostBack Then
                ' Cargar datos iniciales si es necesario
            End If
        End Sub

        Protected Sub btnAccion_Click(sender As Object, e As EventArgs) Handles btnAccion.Click
            Dim accion As String = hdnAccion.Value
            Dim logId As String = hdnLogId.Value

            Select Case accion
                Case "ver_detalle"
                    ' TODO: Implementar
                Case "limpiar_antiguos"
                    LimpiarLogsAntiguos()
            End Select
        End Sub

        Private Sub LimpiarLogsAntiguos()
            Try
                Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                    conn.Open()
                    Using cmd As New SqlCommand("DELETE FROM FLORERIA_Webhook_Log WHERE fecha < DATEADD(DAY, -30, GETDATE())", conn)
                        Dim eliminados As Integer = cmd.ExecuteNonQuery()
                        ' TODO: Mostrar mensaje
                    End Using
                End Using
            Catch ex As Exception
                System.Diagnostics.Debug.WriteLine("ERROR LimpiarLogs: " & ex.Message)
            End Try
        End Sub

    End Class
End Namespace
