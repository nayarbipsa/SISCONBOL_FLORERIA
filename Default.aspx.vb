Imports System.Data.SqlClient

Partial Public Class _Default
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' Site.Master ya verifica la sesión y carga el menú
        ' Aquí solo va la lógica propia de esta página

        If Not IsPostBack Then
            ' Aquí se pueden cargar estadísticas del dashboard
            ' CargarEstadisticas()
        End If
    End Sub

    ' Método de ejemplo para cargar estadísticas
    Private Sub CargarEstadisticas()
        ' TODO: Implementar carga de estadísticas para el dashboard
        ' Ejemplo: total de pedidos hoy, ventas del mes, etc.
    End Sub

End Class
