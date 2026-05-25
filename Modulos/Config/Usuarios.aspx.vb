Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

Partial Public Class Modulos_Config_Usuarios
    Inherits System.Web.UI.Page

    Public Property TablaHtml As String = ""
    Public Property TiposJson As String = "[]"

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' ✅ Site.Master ya verifica sesión — aquí solo lógica de la página
        ' ✅ Verificación adicional: solo ADMINISTRADOR (tipo_id=1) accede a esta página
        Dim tipoId As Integer = 0
        If Session("tipo_id") IsNot Nothing Then
            tipoId = CInt(Session("tipo_id"))
        End If
        If tipoId <> 1 Then
            Response.Redirect("~/Default.aspx")
            Return
        End If

        If Not IsPostBack Then
            CargarTiposJson()
            CargarTablaUsuarios()
        End If
    End Sub

    ' ── Cadena de conexión via SesionHelper ────────────────────────────
    Private Function Cadena() As String
        Return SesionHelper.ObtenerCadena()
    End Function

    ' ── Sanitizar input ────────────────────────────────────────────────
    Private Function Limpiar(v As String) As String
        If v Is Nothing Then Return ""
        v = v.Trim()
        v = v.Replace("<", "").Replace(">", "").Replace("'", "")
        v = v.Replace("""", "").Replace(";", "").Replace("--", "")
        Return v
    End Function

    ' ── Cargar lista de tipos como JSON para poblar selects ────────────
    Private Sub CargarTiposJson()
        Dim sb As New StringBuilder("[")
        Try
            Using conn As New SqlConnection(Cadena())
                conn.Open()
                Using cmd As New SqlCommand(
                    "SELECT tipo_id, nombre FROM FLORERIA_TipoUsuario WHERE activo=1 ORDER BY nombre",
                    conn)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        Dim primero As Boolean = True
                        While dr.Read()
                            If Not primero Then sb.Append(",")
                            sb.Append("{""id"":").Append(dr("tipo_id"))
                            sb.Append(",""nombre"":""").Append(
                                dr("nombre").ToString().Replace("""", "")).Append("""}")
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

    ' ── Construir tabla HTML de usuarios ───────────────────────────────
    Private Sub CargarTablaUsuarios()
        Dim sb As New StringBuilder()
        sb.AppendLine("<table class=""tabla"">")
        sb.AppendLine("<thead><tr>" &
            "<th></th>" &
            "<th>Nombre</th>" &
            "<th>Carnet</th>" &
            "<th>Rol</th>" &
            "<th>Vigencia</th>" &
            "<th>Estado</th>" &
            "<th>Acciones</th>" &
            "</tr></thead>")
        sb.AppendLine("<tbody>")
        Try
            Using conn As New SqlConnection(Cadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Usuario_Listar", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@buscar",  DBNull.Value)
                    cmd.Parameters.AddWithValue("@tipo_id", DBNull.Value)
                    cmd.Parameters.AddWithValue("@estado",  DBNull.Value)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        Dim hayFilas As Boolean = False
                        While dr.Read()
                            hayFilas = True
                            Dim uid      As Integer = CInt(dr("usuario_id"))
                            Dim tid      As Integer = CInt(dr("tipo_id"))
                            Dim nombres  As String  = HttpUtility.HtmlEncode(dr("nombres").ToString())
                            Dim apes     As String  = HttpUtility.HtmlEncode(dr("apellidos").ToString())
                            Dim carnet   As String  = HttpUtility.HtmlEncode(dr("carnet").ToString())
                            Dim email    As String  = If(IsDBNull(dr("email")),    "", HttpUtility.HtmlEncode(dr("email").ToString()))
                            Dim celular  As String  = If(IsDBNull(dr("celular")),  "", HttpUtility.HtmlEncode(dr("celular").ToString()))
                            Dim dir      As String  = If(IsDBNull(dr("direccion")),"", HttpUtility.HtmlEncode(dr("direccion").ToString()))
                            Dim vigencia As String  = If(IsDBNull(dr("vigente_hasta")), "", CDate(dr("vigente_hasta")).ToString("yyyy-MM-dd"))
                            Dim vigShow  As String  = If(IsDBNull(dr("vigente_hasta")), "Permanente", CDate(dr("vigente_hasta")).ToString("dd/MM/yyyy"))
                            Dim tipo     As String  = HttpUtility.HtmlEncode(dr("tipo_nombre").ToString())
                            Dim estado   As String  = dr("estado_calculado").ToString()
                            Dim bloqueado As Boolean = CBool(dr("bloqueado"))
                            Dim iniciales As String = ""
                            If nombres.Length > 0 Then iniciales &= nombres.Substring(0, 1)
                            If apes.Length > 0    Then iniciales &= apes.Substring(0, 1)

                            ' Badge estado
                            Dim badgeEst As String = ""
                            Select Case estado
                                Case "ACTIVO"    : badgeEst = "<span class=""badge badge-ok"">Activo</span>"
                                Case "BLOQUEADO" : badgeEst = "<span class=""badge badge-bloq"">Bloqueado</span>"
                                Case "VENCIDO"   : badgeEst = "<span class=""badge badge-inac"">Vencido</span>"
                                Case "VENCE_HOY" : badgeEst = "<span class=""badge badge-warn"">Vence hoy</span>"
                                Case Else        : badgeEst = "<span class=""badge badge-inac"">Inactivo</span>"
                            End Select

                            ' Badge tipo
                            Dim badgeTipo As String = ""
                            Select Case tipo.ToUpper()
                                Case "ADMINISTRADOR" : badgeTipo = "<span class=""badge badge-rosa"">" & tipo & "</span>"
                                Case "GERENTE"       : badgeTipo = "<span class=""badge badge-azul"">" & tipo & "</span>"
                                Case "CAJERO"        : badgeTipo = "<span class=""badge badge-verde"">" & tipo & "</span>"
                                Case Else            : badgeTipo = "<span class=""badge badge-gris"">" & tipo & "</span>"
                            End Select

                            ' Botón bloqueo
                            Dim btnBloq As String = ""
                            If bloqueado Then
                                btnBloq = "<button type=""button"" class=""btn btn-sm btn-success"" " &
                                          "title=""Desbloquear"" " &
                                          "onclick=""abrirBloqueo(" & uid & ",false)"">" &
                                          "<i class=""ti ti-lock-open""></i></button>"
                            Else
                                btnBloq = "<button type=""button"" class=""btn btn-sm btn-danger"" " &
                                          "title=""Bloquear"" " &
                                          "onclick=""abrirBloqueo(" & uid & ",true)"">" &
                                          "<i class=""ti ti-lock""></i></button>"
                            End If

                            Dim dataTexto As String = (nombres & " " & apes & " " & carnet).ToLower()

                            sb.Append("<tr class=""fila-usuario"" ")
                            sb.Append("data-texto=""").Append(dataTexto).Append(""" ")
                            sb.Append("data-rol=""").Append(tid).Append(""" ")
                            sb.Append("data-estado=""").Append(estado).Append(""">")

                            ' Avatar
                            sb.Append("<td><div class=""avatar"">").Append(iniciales).Append("</div></td>")

                            ' Nombre + email
                            sb.Append("<td><strong>").Append(nombres).Append(" ").Append(apes).Append("</strong>")
                            If email <> "" Then
                                sb.Append("<br><span style=""font-size:11px;color:#9e9e9e"">").Append(email).Append("</span>")
                            End If
                            sb.Append("</td>")

                            sb.Append("<td>").Append(carnet).Append("</td>")
                            sb.Append("<td>").Append(badgeTipo).Append("</td>")
                            sb.Append("<td>").Append(vigShow).Append("</td>")
                            sb.Append("<td>").Append(badgeEst).Append("</td>")

                            ' Acciones
                            sb.Append("<td style=""display:flex;gap:4px"">")
                            sb.Append("<button type=""button"" class=""btn btn-sm"" title=""Editar"" ")
                            sb.Append("onclick=""abrirModalEditar(")
                            sb.Append(uid).Append(",").Append(tid)
                            sb.Append(",'").Append(nombres).Append("','").Append(apes)
                            sb.Append("','").Append(email).Append("','").Append(celular)
                            sb.Append("','").Append(vigencia).Append("','").Append(dir).Append("')")
                            sb.Append("""><i class=""ti ti-edit""></i></button>")
                            sb.Append(btnBloq)
                            sb.Append("<button type=""button"" class=""btn btn-sm"" title=""Resetear contraseña"" ")
                            sb.Append("onclick=""abrirReset(").Append(uid).Append(")"">")
                            sb.Append("<i class=""ti ti-key""></i></button>")
                            sb.Append("</td></tr>")
                        End While

                        If Not hayFilas Then
                            sb.Append("<tr><td colspan=""7"" style=""padding:24px;text-align:center;color:#9e9e9e"">")
                            sb.Append("<i class=""ti ti-users-off"" style=""font-size:20px""></i><br>No hay usuarios registrados.</td></tr>")
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            sb.Append("<tr><td colspan=""7"" style=""padding:20px;text-align:center;color:#C62828"">")
            sb.Append("Error al cargar usuarios: ").Append(HttpUtility.HtmlEncode(ex.Message))
            sb.Append("</td></tr>")
            System.Diagnostics.Debug.WriteLine("ERROR CargarTabla: " & ex.Message)
        End Try
        sb.AppendLine("</tbody></table>")
        TablaHtml = sb.ToString()
    End Sub

    ' ── PostBack principal: despachar según acción ──────────────────────
    Protected Sub btnAccion_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim accion    As String  = Request.Form("hdAccion")
        Dim usuarioId As String  = Request.Form("hdUsuarioId")
        Dim motivo    As String  = Request.Form("hdMotivo")
        Dim creadorId As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)

        If accion    Is Nothing Then accion    = ""
        If motivo    Is Nothing Then motivo    = ""
        If usuarioId Is Nothing Then usuarioId = "0"

        motivo = Limpiar(motivo)
        Dim uid As Integer = 0
        If Not Integer.TryParse(usuarioId, uid) Then uid = 0

        Select Case accion.ToUpper()
            Case "CREAR"       : ProcesarCrear(creadorId)
            Case "EDITAR"      : ProcesarEditar(uid, creadorId, motivo)
            Case "BLOQUEAR"    : ProcesarBloqueo(uid, True,  creadorId, motivo)
            Case "DESBLOQUEAR" : ProcesarBloqueo(uid, False, creadorId, motivo)
            Case "RESET"       : ProcesarReset(uid, creadorId, motivo)
        End Select

        ' Recargar datos para la vista actualizada
        CargarTiposJson()
        CargarTablaUsuarios()
    End Sub

    ' ── Crear usuario ────────────────────────────────────────────────────
    Private Sub ProcesarCrear(creadorId As Integer)
        Dim carnet    As String = Limpiar(Request.Form("hdCarnet"))
        Dim tipoStr   As String = Request.Form("hdTipoId")
        Dim nombres   As String = Limpiar(Request.Form("hdNombres"))
        Dim apellidos As String = Limpiar(Request.Form("hdApellidos"))
        Dim email     As String = Limpiar(Request.Form("hdEmail"))
        Dim celular   As String = Limpiar(Request.Form("hdCelular"))
        Dim direccion As String = Limpiar(Request.Form("hdDireccion"))
        Dim fechaNac  As String = Request.Form("hdFechaNac")
        Dim vigencia  As String = Request.Form("hdVigencia")

        If carnet    Is Nothing Then carnet    = ""
        If tipoStr   Is Nothing Then tipoStr   = "0"
        If nombres   Is Nothing Then nombres   = ""
        If apellidos Is Nothing Then apellidos = ""
        If email     Is Nothing Then email     = ""
        If celular   Is Nothing Then celular   = ""
        If direccion Is Nothing Then direccion = ""
        If fechaNac  Is Nothing Then fechaNac  = ""
        If vigencia  Is Nothing Then vigencia  = ""

        ' Validación servidor
        If Not System.Text.RegularExpressions.Regex.IsMatch(carnet, "^\d{7,8}$") Then
            MostrarMensaje("Carnet no válido (7 u 8 dígitos).", False) : Return
        End If
        If nombres.Trim().Length < 2 Then
            MostrarMensaje("Ingrese los nombres.", False) : Return
        End If
        If apellidos.Trim().Length < 2 Then
            MostrarMensaje("Ingrese los apellidos.", False) : Return
        End If
        Dim tipoId As Integer = 0
        If Not Integer.TryParse(tipoStr, tipoId) OrElse tipoId = 0 Then
            MostrarMensaje("Seleccione un rol.", False) : Return
        End If

        Dim fechaNacParam As Object = DBNull.Value
        If fechaNac <> "" Then
            Dim fn As Date
            If Date.TryParse(fechaNac, fn) Then fechaNacParam = fn
        End If
        Dim vigenciaParam As Object = DBNull.Value
        If vigencia <> "" Then
            Dim vg As Date
            If Date.TryParse(vigencia, vg) Then vigenciaParam = vg
        End If

        Try
            Using conn As New SqlConnection(Cadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Usuario_Crear", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@tipo_id",       tipoId)
                    cmd.Parameters.AddWithValue("@carnet",        carnet)
                    cmd.Parameters.AddWithValue("@nombres",       nombres)
                    cmd.Parameters.AddWithValue("@apellidos",     apellidos)
                    cmd.Parameters.AddWithValue("@email",         If(email = "",     CObj(DBNull.Value), email))
                    cmd.Parameters.AddWithValue("@celular",       If(celular = "",   CObj(DBNull.Value), celular))
                    cmd.Parameters.AddWithValue("@direccion",     If(direccion = "", CObj(DBNull.Value), direccion))
                    cmd.Parameters.AddWithValue("@fecha_nac",     fechaNacParam)
                    cmd.Parameters.AddWithValue("@vigente_hasta", vigenciaParam)
                    cmd.Parameters.AddWithValue("@creado_por",    creadorId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            MostrarMensaje(dr("mensaje").ToString(), CBool(dr("ok")))
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarMensaje("Error al crear usuario.", False)
            System.Diagnostics.Debug.WriteLine("ERROR Crear: " & ex.Message)
        End Try
    End Sub

    ' ── Editar usuario ───────────────────────────────────────────────────
    Private Sub ProcesarEditar(uid As Integer, modificadorId As Integer, motivo As String)
        Dim tipoStr   As String = Request.Form("hdTipoId")
        Dim nombres   As String = Limpiar(Request.Form("hdNombres"))
        Dim apellidos As String = Limpiar(Request.Form("hdApellidos"))
        Dim email     As String = Limpiar(Request.Form("hdEmail"))
        Dim celular   As String = Limpiar(Request.Form("hdCelular"))
        Dim direccion As String = Limpiar(Request.Form("hdDireccion"))
        Dim fechaNac  As String = Request.Form("hdFechaNac")
        Dim vigencia  As String = Request.Form("hdVigencia")

        If tipoStr   Is Nothing Then tipoStr   = "0"
        If nombres   Is Nothing Then nombres   = ""
        If apellidos Is Nothing Then apellidos = ""
        If email     Is Nothing Then email     = ""
        If celular   Is Nothing Then celular   = ""
        If direccion Is Nothing Then direccion = ""
        If fechaNac  Is Nothing Then fechaNac  = ""
        If vigencia  Is Nothing Then vigencia  = ""
        If motivo    Is Nothing OrElse motivo.Trim() = "" Then motivo = "Actualización de datos"

        Dim tipoId As Integer = 0
        Integer.TryParse(tipoStr, tipoId)

        Dim fechaNacParam As Object = DBNull.Value
        If fechaNac <> "" Then
            Dim fn As Date
            If Date.TryParse(fechaNac, fn) Then fechaNacParam = fn
        End If
        Dim vigenciaParam As Object = DBNull.Value
        If vigencia <> "" Then
            Dim vg As Date
            If Date.TryParse(vigencia, vg) Then vigenciaParam = vg
        End If

        Try
            Using conn As New SqlConnection(Cadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Usuario_Actualizar", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@usuario_id",    uid)
                    cmd.Parameters.AddWithValue("@tipo_id",       tipoId)
                    cmd.Parameters.AddWithValue("@nombres",       nombres)
                    cmd.Parameters.AddWithValue("@apellidos",     apellidos)
                    cmd.Parameters.AddWithValue("@email",         If(email = "",     CObj(DBNull.Value), email))
                    cmd.Parameters.AddWithValue("@celular",       If(celular = "",   CObj(DBNull.Value), celular))
                    cmd.Parameters.AddWithValue("@direccion",     If(direccion = "", CObj(DBNull.Value), direccion))
                    cmd.Parameters.AddWithValue("@fecha_nac",     fechaNacParam)
                    cmd.Parameters.AddWithValue("@vigente_hasta", vigenciaParam)
                    cmd.Parameters.AddWithValue("@modificado_por",modificadorId)
                    cmd.Parameters.AddWithValue("@motivo",        motivo)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            MostrarMensaje(dr("mensaje").ToString(), CBool(dr("ok")))
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarMensaje("Error al actualizar usuario.", False)
            System.Diagnostics.Debug.WriteLine("ERROR Editar: " & ex.Message)
        End Try
    End Sub

    ' ── Bloquear / Desbloquear ───────────────────────────────────────────
    Private Sub ProcesarBloqueo(uid As Integer, bloquear As Boolean, modificadorId As Integer, motivo As String)
        If motivo.Trim().Length < 5 Then
            MostrarMensaje("El motivo es obligatorio (mín. 5 caracteres).", False) : Return
        End If
        Try
            Using conn As New SqlConnection(Cadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Usuario_CambiarBloqueo", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@usuario_id",    uid)
                    cmd.Parameters.AddWithValue("@bloquear",      If(bloquear, 1, 0))
                    cmd.Parameters.AddWithValue("@modificado_por",modificadorId)
                    cmd.Parameters.AddWithValue("@motivo",        motivo)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            MostrarMensaje(dr("mensaje").ToString(), CBool(dr("ok")))
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarMensaje("Error al cambiar estado.", False)
            System.Diagnostics.Debug.WriteLine("ERROR Bloqueo: " & ex.Message)
        End Try
    End Sub

    ' ── Reset contraseña ─────────────────────────────────────────────────
    Private Sub ProcesarReset(uid As Integer, modificadorId As Integer, motivo As String)
        If motivo.Trim().Length < 5 Then
            MostrarMensaje("El motivo es obligatorio (mín. 5 caracteres).", False) : Return
        End If
        Try
            Using conn As New SqlConnection(Cadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Usuario_ResetearPassword", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@usuario_id",    uid)
                    cmd.Parameters.AddWithValue("@modificado_por",modificadorId)
                    cmd.Parameters.AddWithValue("@motivo",        motivo)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            MostrarMensaje(dr("mensaje").ToString(), CBool(dr("ok")))
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarMensaje("Error al resetear contraseña.", False)
            System.Diagnostics.Debug.WriteLine("ERROR Reset: " & ex.Message)
        End Try
    End Sub

    ' ── Mostrar mensaje en modal y mantenerlo abierto ────────────────────
    Private Sub MostrarMensaje(mensaje As String, esOk As Boolean)
        Dim css As String = If(esOk, "alerta alerta-ok show", "alerta alerta-error show")
        Dim js As String =
            "var d=document.getElementById('divAlertaModal');" &
            "if(d){d.innerHTML='" & HttpUtility.JavaScriptStringEncode(mensaje) & "';" &
            "d.className='" & css & "';}" &
            "var m=document.getElementById('modalUsuario');" &
            "if(m){m.className='modal-bg show';}"
        ClientScript.RegisterStartupScript(Me.GetType(), "msg", js, True)
    End Sub

End Class
