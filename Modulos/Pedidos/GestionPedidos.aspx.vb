Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

Partial Public Class Modulos_Pedidos_GestionPedidos
    Inherits System.Web.UI.Page

    ' ============================================================
    ' Propiedades para el ASPX
    ' ============================================================
    Public Property OptionsDelivery As String = ""
    Public Property OptionsZona As String = ""
    Public Property SucursalRadios As String = ""
    Public Property TotalGeneralSucursal As Integer = 0
    Public Property TotalSinSucursal As Integer = 0
    Public Property MensajeAlerta As String = ""
    Public Property TipoAlerta As String = "success"

    ' ============================================================
    ' PAGE LOAD
    ' ============================================================
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not SesionHelper.VerificarSesion(Context) Then
            Response.Redirect("~/Login.aspx")
            Return
        End If

        ' Leer mensaje de alerta si viene de redirect
        Dim msg As String = Request.QueryString("msg")
        If msg IsNot Nothing AndAlso msg <> "" Then
            MensajeAlerta = HttpUtility.UrlDecode(msg).Replace("'", "\'")
            Dim tipo As String = Request.QueryString("tipo")
            If tipo IsNot Nothing AndAlso tipo <> "" Then
                TipoAlerta = tipo
            End If
        End If

        If Not IsPostBack Then
            Try
                CargarDropdowns()
                CargarSucursales()
            Catch ex As Exception
                System.Diagnostics.Debug.WriteLine("ERROR Page_Load: " & ex.Message)
                MensajeAlerta = "Error: " & ex.Message
                TipoAlerta = "error"
            End Try
        End If
    End Sub

    ' ============================================================
    ' CARGAR SUCURSALES (radio buttons dinámicos con conteo)
    ' ============================================================
    Private Sub CargarSucursales()
        Dim sb As New StringBuilder()

        ' Diccionario para guardar conteos por sucursal_id
        Dim conteos As New Dictionary(Of Integer, Integer)
        Dim totalGeneral As Integer = 0
        Dim sinAsignar As Integer = 0

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()

            ' 1. Contar pedidos no cancelados por sucursal_prepara_id
            Using cmd As New SqlCommand("SELECT ISNULL(sucursal_prepara_id, -1) AS sid, COUNT(*) AS cnt FROM FLORERIA_Pedido WHERE ISNULL(estado_pago,'') NOT IN ('CANCELADO') GROUP BY ISNULL(sucursal_prepara_id, -1)", conn)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        Dim sid As Integer = CInt(dr("sid"))
                        Dim cnt As Integer = CInt(dr("cnt"))
                        totalGeneral += cnt
                        If sid = -1 Then
                            sinAsignar = cnt
                        Else
                            conteos(sid) = cnt
                        End If
                    End While
                End Using
            End Using

            ' 2. Listar sucursales activas
            Using cmd As New SqlCommand("SELECT sucursal_id, nombre FROM FLORERIA_Sucursal WHERE ISNULL(activo,1)=1 ORDER BY nombre", conn)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        Dim sucId As Integer = CInt(dr("sucursal_id"))
                        Dim nombre As String = dr("nombre").ToString()
                        Dim cnt As Integer = 0
                        If conteos.ContainsKey(sucId) Then cnt = conteos(sucId)

                        sb.Append("<label class=""suc-pill"" data-sp=""" & sucId & """>")
                        sb.Append("<input type=""radio"" name=""sucPrepara"" value=""" & sucId & """/>")
                        sb.Append(HE(nombre))
                        sb.Append(" <span class=""suc-count"">(" & cnt & ")</span>")
                        sb.Append("</label>")
                    End While
                End Using
            End Using
        End Using

        SucursalRadios = sb.ToString()
        TotalGeneralSucursal = totalGeneral
        TotalSinSucursal = sinAsignar
    End Sub

    ' ============================================================
    ' DROPDOWNS (Zona y Delivery)
    ' ============================================================
    Private Sub CargarDropdowns()
        Dim sbZ As New StringBuilder()
        Dim sbD As New StringBuilder()

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()

            ' Zonas
            Using cmd As New SqlCommand("SELECT zona_id, nombre FROM FLORERIA_Zona WHERE ISNULL(activo,1)=1 ORDER BY nombre", conn)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        sbZ.Append("<option value=""" & dr("zona_id") & """>" & HE(dr("nombre").ToString()) & "</option>")
                    End While
                End Using
            End Using

            ' Deliverys
            Using cmd As New SqlCommand("FLORERIA_sp_Asignacion_ListarDeliverysActivos", conn)
                cmd.CommandType = CommandType.StoredProcedure
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        Dim uid As Integer = CInt(dr("usuario_id"))
                        Dim nombre As String = LeerStr(dr, "nombre_completo")
                        Dim activos As Integer = LeerInt(dr, "pedidos_activos_hoy")
                        sbD.Append("<option value=""" & uid & """>" & HE(nombre) & " (" & activos & ")</option>")
                    End While
                End Using
            End Using
        End Using

        OptionsZona = sbZ.ToString()
        OptionsDelivery = sbD.ToString()
    End Sub

    ' ============================================================
    ' POSTBACK PARA ACCIONES
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
            If accion = "ACEPTAR_PAGO" Then
                EjecutarAceptarPago(pedidoId, usuarioId, ip)
            ElseIf accion = "MARCAR_CONTACTADO" Then
                EjecutarMarcarContactado(pedidoId, usuarioId, ip)
            ElseIf accion = "CAMBIAR_ESTADO" Then
                Dim estadoNuevo As String = Request.Form("hdEstadoNuevo")
                If estadoNuevo Is Nothing OrElse estadoNuevo = "" Then Return
                EjecutarCambiarEstado(pedidoId, estadoNuevo, usuarioId, ip)
            ElseIf accion = "CANCELAR_PEDIDO" Then
                ' Verificar permiso (solo Admin o Gerente)
                Dim tipoId As Integer = 3
                If Session("tipo_id") IsNot Nothing Then Integer.TryParse(Session("tipo_id").ToString(), tipoId)
                If tipoId <> 1 AndAlso tipoId <> 2 Then
                    RedirectConMsg("No tienes permiso para cancelar pedidos", "error")
                    Return
                End If
                EjecutarCambiarEstado(pedidoId, "CANCELADO", usuarioId, ip)
            End If
        Catch ex As Exception
            RedirectConMsg("Error: " & ex.Message, "error")
        End Try
    End Sub

    Private Sub EjecutarAceptarPago(pedidoId As Integer, usuarioId As Integer, ip As String)
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_sp_Pedido_AceptarPagoManual", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@pedido_id", pedidoId)
                cmd.Parameters.AddWithValue("@usuario_id", usuarioId)
                cmd.Parameters.AddWithValue("@ip", ip)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        Dim ok As Boolean = LeerBool(dr, "ok")
                        Dim mensaje As String = LeerStr(dr, "mensaje")
                        dr.Close()
                        RedirectConMsg(mensaje, If(ok, "success", "error"))
                        Return
                    End If
                End Using
            End Using
        End Using
    End Sub

    Private Sub EjecutarMarcarContactado(pedidoId As Integer, usuarioId As Integer, ip As String)
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_sp_Pedido_MarcarContactado", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@pedido_id", pedidoId)
                cmd.Parameters.AddWithValue("@contactado", 1)
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
        Dim url As String = "GestionPedidos.aspx?msg=" & HttpUtility.UrlEncode(mensaje) & "&tipo=" & tipo
        SesionHelper.RedirectSeguro(Context, url)
    End Sub

    ' ============================================================
    ' HELPERS
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

    Private Function LeerInt(dr As SqlDataReader, campo As String) As Integer
        Try
            Dim idx = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return 0
            Return CInt(dr(idx))
        Catch
            Return 0
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

    Private Function HE(texto As String) As String
        If texto Is Nothing Then Return ""
        Return HttpUtility.HtmlEncode(texto)
    End Function

End Class
