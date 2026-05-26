Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

Partial Public Class Modulos_Config_PermisosMenu
    Inherits System.Web.UI.Page

    Public Property TiposJson         As String = "[]"
    Public Property MenusJson         As String = "[]"
    Public Property PermisosJson      As String = "null"
    Public Property TipoSeleccionadoId As Integer = 0

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' Site.Master verifica sesión — aquí solo validar que sea ADMINISTRADOR
        Dim tipoId As Integer = 0
        If Session("tipo_id") IsNot Nothing Then tipoId = CInt(Session("tipo_id"))
        If tipoId <> 1 Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        If Not IsPostBack Then
            CargarTiposJson()
            CargarMenusJson()
        End If
    End Sub

    ' ── Helpers ────────────────────────────────────────────────────────
    Private Function Cadena() As String
        Return SesionHelper.ObtenerCadena()
    End Function

    Private Function JsonStr(v As String) As String
        If v Is Nothing Then Return ""
        Return v.Replace("\", "\\").Replace("""", "\""").Replace(Chr(13), "").Replace(Chr(10), "")
    End Function

    ' ── Todos los tipos de usuario activos ─────────────────────────────
    Private Sub CargarTiposJson()
        Dim sb As New StringBuilder("[")
        Try
            Using conn As New SqlConnection(Cadena())
                conn.Open()
                Using cmd As New SqlCommand(
                    "SELECT tipo_id, nombre FROM FLORERIA_TipoUsuario WHERE activo=1 ORDER BY nombre", conn)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        Dim primero As Boolean = True
                        While dr.Read()
                            If Not primero Then sb.Append(",")
                            sb.Append("{""id"":").Append(dr("tipo_id"))
                            sb.Append(",""nombre"":""").Append(JsonStr(dr("nombre").ToString())).Append("""}")
                            primero = False
                        End While
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR TiposJson: " & ex.Message)
        End Try
        sb.Append("]")
        TiposJson = sb.ToString()
    End Sub

    ' ── Todos los ítems de menú activos ────────────────────────────────
    Private Sub CargarMenusJson()
        Dim sb As New StringBuilder("[")
        Try
            Using conn As New SqlConnection(Cadena())
                conn.Open()
                Using cmd As New SqlCommand(
                    "SELECT menu_id, padre_id, nombre, icono, ruta, orden " &
                    "FROM FLORERIA_Menu WHERE activo=1 ORDER BY orden", conn)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        Dim primero As Boolean = True
                        While dr.Read()
                            If Not primero Then sb.Append(",")
                            Dim padreId As String = If(IsDBNull(dr("padre_id")), "null", dr("padre_id").ToString())
                            Dim icono   As String = If(IsDBNull(dr("icono")),   "ti-circle", dr("icono").ToString())
                            sb.Append("{")
                            sb.Append("""menu_id"":").Append(dr("menu_id"))
                            sb.Append(",""padre_id"":").Append(padreId)
                            sb.Append(",""nombre"":""").Append(JsonStr(dr("nombre").ToString())).Append("""")
                            sb.Append(",""icono"":""").Append(JsonStr(icono)).Append("""")
                            sb.Append(",""orden"":").Append(dr("orden"))
                            sb.Append("}")
                            primero = False
                        End While
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR MenusJson: " & ex.Message)
        End Try
        sb.Append("]")
        MenusJson = sb.ToString()
    End Sub

    ' ── Cargar permisos actuales de un tipo ────────────────────────────
    Private Sub CargarPermisosJson(tipoId As Integer)
        Dim sb As New StringBuilder("[")
        Try
            Using conn As New SqlConnection(Cadena())
                conn.Open()
                ' LEFT JOIN para incluir ítems sin permiso (con valores 0)
                Using cmd As New SqlCommand(
                    "SELECT m.menu_id, " &
                    "ISNULL(tm.puede_ver,0)      AS puede_ver, " &
                    "ISNULL(tm.puede_crear,0)    AS puede_crear, " &
                    "ISNULL(tm.puede_editar,0)   AS puede_editar, " &
                    "ISNULL(tm.puede_eliminar,0) AS puede_eliminar " &
                    "FROM FLORERIA_Menu m " &
                    "LEFT JOIN FLORERIA_TipoUsuario_Menu tm " &
                    "  ON tm.menu_id=m.menu_id AND tm.tipo_id=@tid " &
                    "WHERE m.activo=1 ORDER BY m.orden", conn)
                    cmd.Parameters.AddWithValue("@tid", tipoId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        Dim primero As Boolean = True
                        While dr.Read()
                            If Not primero Then sb.Append(",")
                            sb.Append("{")
                            sb.Append("""menu_id"":").Append(dr("menu_id"))
                            sb.Append(",""puede_ver"":").Append(CInt(dr("puede_ver")))
                            sb.Append(",""puede_crear"":").Append(CInt(dr("puede_crear")))
                            sb.Append(",""puede_editar"":").Append(CInt(dr("puede_editar")))
                            sb.Append(",""puede_eliminar"":").Append(CInt(dr("puede_eliminar")))
                            sb.Append("}")
                            primero = False
                        End While
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR PermisosJson: " & ex.Message)
        End Try
        sb.Append("]")
        PermisosJson      = sb.ToString()
        TipoSeleccionadoId = tipoId
    End Sub

    ' ── PostBack: CARGAR o GUARDAR ──────────────────────────────────────
    Protected Sub btnAccion_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim accion  As String  = Request.Form("hdAccion")
        Dim tipoStr As String  = Request.Form("hdTipoId")
        Dim adminId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)

        If accion  Is Nothing Then accion  = ""
        If tipoStr Is Nothing Then tipoStr = "0"

        Dim tipoId As Integer = 0
        If Not Integer.TryParse(tipoStr, tipoId) Then tipoId = 0

        ' Siempre recargar catálogos para la vista
        CargarTiposJson()
        CargarMenusJson()

        Select Case accion.ToUpper()
            Case "CARGAR"
                If tipoId > 0 Then CargarPermisosJson(tipoId)

            Case "GUARDAR"
                If tipoId > 0 Then
                    ProcesarGuardar(tipoId, adminId)
                    ' Recargar permisos actualizados para reflejar en la tabla
                    CargarPermisosJson(tipoId)
                End If
        End Select
    End Sub

    ' ── Guardar permisos: UPSERT masivo ────────────────────────────────
    Private Sub ProcesarGuardar(tipoId As Integer, adminId As Integer)
        Dim raw As String = Request.Form("hdPermisos")
        If raw Is Nothing OrElse raw.Trim() = "" Then
            MostrarMensaje("No se recibieron datos de permisos.", False)
            Return
        End If

        ' Formato: "menu_id:VCED|menu_id:VCED|..."  (V/C/E/D = 0 o 1)
        Dim items() As String = raw.Split("|"c)

        Try
            Using conn As New SqlConnection(Cadena())
                conn.Open()
                Using tran As SqlTransaction = conn.BeginTransaction()
                    Try
                        Dim cmdUpsert As New SqlCommand(
                            "FLORERIA_sp_TipoMenu_Guardar", conn, tran)
                        cmdUpsert.CommandType = Data.CommandType.StoredProcedure

                        For Each item As String In items
                            If item.Trim() = "" Then Continue For
                            Dim partes() As String = item.Split(":"c)
                            If partes.Length <> 2 OrElse partes(1).Length <> 4 Then Continue For

                            Dim mid As Integer = 0
                            If Not Integer.TryParse(partes(0), mid) Then Continue For

                            Dim bits As String = partes(1)
                            Dim ver      As Integer = If(bits(0) = "1"c, 1, 0)
                            Dim crear    As Integer = If(bits(1) = "1"c, 1, 0)
                            Dim editar   As Integer = If(bits(2) = "1"c, 1, 0)
                            Dim eliminar As Integer = If(bits(3) = "1"c, 1, 0)

                            cmdUpsert.Parameters.Clear()
                            cmdUpsert.Parameters.AddWithValue("@tipo_id",       tipoId)
                            cmdUpsert.Parameters.AddWithValue("@menu_id",       mid)
                            cmdUpsert.Parameters.AddWithValue("@puede_ver",     ver)
                            cmdUpsert.Parameters.AddWithValue("@puede_crear",   crear)
                            cmdUpsert.Parameters.AddWithValue("@puede_editar",  editar)
                            cmdUpsert.Parameters.AddWithValue("@puede_eliminar",eliminar)
                            cmdUpsert.Parameters.AddWithValue("@modificado_por",adminId)
                            cmdUpsert.ExecuteNonQuery()
                        Next

                        tran.Commit()
                        MostrarMensaje("Permisos guardados correctamente.", True)

                    Catch ex As Exception
                        tran.Rollback()
                        MostrarMensaje("Error al guardar permisos: " & ex.Message, False)
                        System.Diagnostics.Debug.WriteLine("ERROR Guardar permisos: " & ex.Message)
                    End Try
                End Using
            End Using
        Catch ex As Exception
            MostrarMensaje("Error de conexión: " & ex.Message, False)
            System.Diagnostics.Debug.WriteLine("ERROR conexión permisos: " & ex.Message)
        End Try
    End Sub

    ' ── Mostrar alerta en la página (no en modal) ───────────────────────
    Private Sub MostrarMensaje(mensaje As String, esOk As Boolean)
        Dim tipo As String = If(esOk, "ok", "error")
        Dim js As String =
            "mostrarAlerta('" & HttpUtility.JavaScriptStringEncode(mensaje) & "','" & tipo & "');"
        ClientScript.RegisterStartupScript(Me.GetType(), "msg", js, True)
    End Sub

End Class
