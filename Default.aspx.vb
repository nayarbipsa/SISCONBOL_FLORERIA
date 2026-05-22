Imports System.Data.SqlClient

Partial Public Class Default_aspx
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' La Master Page ya verifica la sesion y carga el menu
        ' Aqui solo va la logica propia de esta pagina

        If Not IsPostBack Then
            ' Establecer titulo de la pagina en la Master
            Dim master As Site = CType(Me.Master, Site)
            If master IsNot Nothing Then
                master.TituloPagina = "Inicio"
            End If

            ' Aqui se pueden cargar estadisticas del dashboard
            ' CargarEstadisticas()
        End If
    End Sub

End Class
