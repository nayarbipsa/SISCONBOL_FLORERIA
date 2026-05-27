Imports System.Data
Imports System.Data.SqlClient
Imports System.Web

' ============================================================
' SISCONBOL_FLORERIA - Mis Entregas
' Muestra los pedidos asignados al agente logueado como delivery
' Archivo: Modulos/Pedidos/MisEntregas.aspx.vb
' ============================================================
Partial Public Class Modulos_Pedidos_MisEntregas
    Inherits System.Web.UI.Page

    ' ============================================================
    ' Propiedades para el ASPX
    ' ============================================================
    Public Property NombreAgente As String = "Agente"
    Public Property AgentId As Integer = 0
    Public Property MensajeAlerta As String = ""
    Public Property TipoAlerta As String = "success"

    ' ============================================================
    ' PAGE LOAD
    ' ============================================================
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Site.Master verifica sesion, pero doble check aqui
        If Not SesionHelper.VerificarSesion(Context) Then
            Response.Redirect("~/Login.aspx")
            Return
        End If

        ' Leer datos del agente desde Session
        AgentId = SesionHelper.ObtenerUsuarioId(Context)
        NombreAgente = SesionHelper.ObtenerUsuarioNombre(Context)

        ' Mensaje de alerta si viene de redirect
        Dim msg As String = Request.QueryString("msg")
        If msg IsNot Nothing AndAlso msg <> "" Then
            MensajeAlerta = HttpUtility.UrlDecode(msg).Replace("'", "\'")
            Dim tipo As String = Request.QueryString("tipo")
            If tipo IsNot Nothing AndAlso tipo <> "" Then
                TipoAlerta = tipo
            End If
        End If
    End Sub

    ' ============================================================
    ' POSTBACK - CAMBIAR ESTADO OPERATIVO
    ' ============================================================
    Protected Sub btnAccion_Click(sender As Object, e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""
        accion = accion.Trim()

        Dim pedidoIdStr As String = Request.Form("hdPedidoId")
        Dim pedidoId As Integer = 0
        Integer.TryParse(pedidoIdStr, pedidoId)
        If pedidoId <= 0 Then Return

        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(Context)
        Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
        If ip Is Nothing Then ip = ""

        Try
            If accion = "CAMBIAR_ESTADO" Then
                Dim estadoNuevo As String = Request.Form("hdEstadoNuevo")
                If estadoNuevo Is Nothing OrElse estadoNuevo = "" Then Return
                EjecutarCambiarEstado(pedidoId, estadoNuevo, usuarioId, ip)
            End If
        Catch ex As Exception
            RedirectConMsg("Error: " & ex.Message, "error")
        End Try
    End Sub

    Private Sub EjecutarCambiarEstado(pedidoId As Integer, estadoNuevo As String, usuarioId As Integer, ip As String)
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_sp_Pedido_CambiarEstadoOperativo", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@pedido_id", pedidoId)
                cmd.Parameters.AddWithValue("@estado_nuevo", estadoNuevo)
                cmd.Parameters.AddWithValue("@observaciones", DBNull.Value)
                cmd.Parameters.AddWithValue("@usuario_id", usuarioId)
                cmd.Parameters.AddWithValue("@ip", ip)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        Dim ok As Boolean = LeerBool(dr, "ok")
                        Dim mensaje As String = LeerStr(dr, "mensaje")
                        dr.Close()
                        RedirectConMsg(mensaje, If(ok, "success", "warning"))
                        Return
                    End If
                End Using
            End Using
        End Using
    End Sub

    Private Sub RedirectConMsg(mensaje As String, tipo As String)
        Dim url As String = "MisEntregas.aspx?msg=" & HttpUtility.UrlEncode(mensaje) & "&tipo=" & tipo
        SesionHelper.RedirectSeguro(Context, url)
    End Sub

    ' ============================================================
    ' HELPERS (mismo patron que GestionPedidos)
    ' ============================================================
    Private Function LeerStr(dr As SqlDataReader, campo As String) As String
        Try
            Dim idx = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return ""
            Return dr(idx).ToString()
        Catch
            Return ""
        End Try
    End Function

    Private Function LeerBool(dr As SqlDataReader, campo As String) As Boolean
        Try
            Dim idx = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return False
            Return CBool(dr(idx))
        Catch
            Return False
        End Try
    End Function

End Class
