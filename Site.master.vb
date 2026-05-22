Imports System.Data.SqlClient

Partial Public Class Site
    Inherits System.Web.UI.MasterPage

    Public Property MenuHtml As String = ""
    Public Property TituloPagina As String = "SISCONBOL"

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' 1. Verificar sesion — siempre primero
        If Not SesionHelper.VerificarSesion(HttpContext.Current) Then
            Response.Redirect("~/Login.aspx")
            Return
        End If

        ' 2. Cargar menu siempre (en cada request para que este actualizado)
        MenuHtml = SesionHelper.GenerarMenuHtml(HttpContext.Current, Me.Page)
    End Sub

    Protected Sub btnCerrarSesion_Click(ByVal sender As Object, ByVal e As EventArgs)
        ' Invalidar token en BD
        If Session("token") IsNot Nothing Then
            Try
                Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                    conn.Open()
                    Using cmd As New SqlCommand("FLORERIA_sp_CerrarSesion", conn)
                        cmd.CommandType = Data.CommandType.StoredProcedure
                        cmd.Parameters.AddWithValue("@token", Session("token").ToString())
                        cmd.ExecuteNonQuery()
                    End Using
                End Using
            Catch ex As Exception
                System.Diagnostics.Debug.WriteLine("ERROR CerrarSesion: " & ex.Message)
            End Try
        End If

        ' Eliminar cookies
        Dim cookieToken As New HttpCookie("SISCONBOL_TOKEN", "")
        cookieToken.Expires = DateTime.Now.AddDays(-1)
        Response.Cookies.Add(cookieToken)

        Dim cookieNombre As New HttpCookie("SISCONBOL_NOMBRE", "")
        cookieNombre.Expires = DateTime.Now.AddDays(-1)
        Response.Cookies.Add(cookieNombre)

        Session.Abandon()
        Response.Redirect("~/Login.aspx")
    End Sub

End Class
