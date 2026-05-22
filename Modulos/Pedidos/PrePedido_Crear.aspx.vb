Imports System.Data
Imports System.Data.SqlClient
Imports System.Web

Partial Public Class Modulos_Pedidos_PrePedido_Crear
    Inherits System.Web.UI.Page

    Public Property MenuHtml As String = ""
    Public Property MensajeAlerta As String = ""
    Public Property ValorCelular As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not SesionHelper.VerificarSesion(HttpContext.Current) Then
            Response.Redirect("~/Login.aspx")
            Return
        End If
        MenuHtml = SesionHelper.GenerarMenuHtml(HttpContext.Current, Me)
    End Sub

    Protected Sub btnPostBack_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim celular As String = Request.Form("txCelular")
        Dim nombre As String = Request.Form("txNombre")
        Dim apellidos As String = Request.Form("txApellidos")
        Dim email As String = Request.Form("txEmail")
        Dim tipoRegistro As String = Request.Form("selTipo")
        Dim paisIdStr As String = Request.Form("hdPaisId")

        If celular Is Nothing Then celular = ""
        If nombre Is Nothing Then nombre = ""
        If apellidos Is Nothing Then apellidos = ""
        If email Is Nothing Then email = ""
        If tipoRegistro Is Nothing Then tipoRegistro = "PRE_PEDIDO"
        If paisIdStr Is Nothing Then paisIdStr = ""

        celular = celular.Trim()
        nombre = nombre.Trim()
        apellidos = apellidos.Trim()
        email = email.Trim()

        If celular = "" Then
            MensajeAlerta = "El celular es obligatorio"
            MenuHtml = SesionHelper.GenerarMenuHtml(HttpContext.Current, Me)
            Return
        End If

        ValorCelular = celular

        ' Detectar pais
        Dim paisId As Object = DBNull.Value
        If paisIdStr <> "" Then
            Dim tmp As Integer = 0
            If Integer.TryParse(paisIdStr, tmp) Then paisId = tmp
        End If
        If paisId Is DBNull.Value Then
            If celular.StartsWith("+591") OrElse celular.StartsWith("591") Then
                paisId = 1
            ElseIf celular.StartsWith("+51") OrElse celular.StartsWith("51") Then
                paisId = 2
            ElseIf (celular.StartsWith("6") OrElse celular.StartsWith("7")) AndAlso (celular.Length = 7 OrElse celular.Length = 8) Then
                paisId = 1
            End If
        End If

        Dim prepedidoId As Integer = 0
        Dim codigoGenerado As String = ""

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_PrePedido_Crear", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@tipo_registro", tipoRegistro)
                    cmd.Parameters.AddWithValue("@cliente_celular", celular)
                    cmd.Parameters.AddWithValue("@agente_id", SesionHelper.ObtenerUsuarioId(HttpContext.Current))
                    cmd.Parameters.AddWithValue("@ip", Request.UserHostAddress)

                    Dim pId As New SqlParameter("@prepedido_id", SqlDbType.Int)
                    pId.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(pId)

                    Dim pCod As New SqlParameter("@codigo", SqlDbType.VarChar, 20)
                    pCod.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(pCod)

                    cmd.ExecuteNonQuery()

                    ' Verificar que el SP retornó valores validos
                    If pId.Value Is DBNull.Value OrElse pId.Value Is Nothing Then
                        MensajeAlerta = "Error: No se pudo crear el pre-pedido"
                        MenuHtml = SesionHelper.GenerarMenuHtml(HttpContext.Current, Me)
                        Return
                    End If

                    prepedidoId = Convert.ToInt32(pId.Value)
                    codigoGenerado = pCod.Value.ToString()
                End Using

                ' Solo actualizar si el ID es valido
                If prepedidoId > 0 Then
                    Using cmd2 As New SqlCommand("FLORERIA_sp_PrePedido_ActualizarCliente", conn)
                        cmd2.CommandType = Data.CommandType.StoredProcedure
                        cmd2.Parameters.AddWithValue("@prepedido_id", prepedidoId)
                        cmd2.Parameters.AddWithValue("@cliente_nombre", If(nombre = "", CObj(DBNull.Value), CObj(nombre)))
                        cmd2.Parameters.AddWithValue("@cliente_apellidos", If(apellidos = "", CObj(DBNull.Value), CObj(apellidos)))
                        cmd2.Parameters.AddWithValue("@cliente_email", If(email = "", CObj(DBNull.Value), CObj(email)))
                        cmd2.Parameters.AddWithValue("@cliente_pais_id", paisId)
                        cmd2.Parameters.AddWithValue("@cliente_ciudad_id", CObj(DBNull.Value))
                        cmd2.Parameters.AddWithValue("@modificado_por", SesionHelper.ObtenerUsuarioId(HttpContext.Current))
                        cmd2.Parameters.AddWithValue("@ip", Request.UserHostAddress)
                        cmd2.ExecuteNonQuery()
                    End Using
                End If
            End Using

            MensajeAlerta = "Pre-Pedido creado: " & codigoGenerado
            ValorCelular = ""

        Catch ex As Exception
            MensajeAlerta = "Error: " & ex.Message.Replace("'", "")
        End Try

        MenuHtml = SesionHelper.GenerarMenuHtml(HttpContext.Current, Me)
    End Sub

    Protected Sub btnCerrarSesion_Click(ByVal sender As Object, ByVal e As EventArgs)
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
        Dim cookie As New HttpCookie("SISCONBOL_TOKEN", "")
        cookie.Expires = DateTime.Now.AddDays(-1)
        Response.Cookies.Add(cookie)
        Session.Abandon()
        Response.Redirect("~/Login.aspx")
    End Sub

End Class