Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

Partial Public Class Modulos_Config_Usuarios
    Inherits System.Web.UI.Page

    Public Property TablaHtml As String = ""
    Public Property TiposJson As String = "[]"

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not VerificarSesion() Then
            Response.Redirect("~/Login.aspx")
            Return
        End If
        If Not IsPostBack Then
            CargarTiposJson()
            CargarTablaUsuarios()
        End If
    End Sub

    Private Function VerificarSesion() As Boolean
        If Session("token") Is Nothing Then Return False
        Dim token As String = Session("token").ToString()
        Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
        If ip Is Nothing Then ip = ""
        Try
            Dim cadena As String = System.Configuration.ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString
            Using conn As New SqlConnection(cadena)
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_ValidarSesion", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@token", token)
                    cmd.Parameters.AddWithValue("@ip", ip)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then Return CBool(dr("valida"))
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Sesion: " & ex.Message)
        End Try
        Return False
    End Function

    Private Function ObtenerCadena() As String
        Return System.Configuration.ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString
    End Function

    Private Function LimpiarInput(v As String) As String
        If v Is Nothing Then Return ""
        v = v.Trim()
        v = v.Replace("<", "").Replace(">", "").Replace("'", "")
        v = v.Replace("""", "").Replace(";", "").Replace("--", "")
        Return v
    End Function

    Private Sub CargarTiposJson()
        Dim sb As New StringBuilder("[")
        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("SELECT tipo_id, nombre FROM FLORERIA_TipoUsuario WHERE activo=1 ORDER BY nombre", conn)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        Dim primero As Boolean = True
                        While dr.Read()
                            If Not primero Then sb.Append(",")
                            sb.Append("{""id"":").Append(dr("tipo_id"))
                            sb.Append(",""nombre"":""").Append(dr("nombre").ToString().Replace("""", "")).Append("""}")
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

    Private Sub CargarTablaUsuarios()
        Dim sb As New StringBuilder()
        sb.AppendLine("<table class=""tabla"">")
        sb.AppendLine("<thead><tr><th></th><th>Nombre</th><th>Carnet</th><th>Rol</th><th>Vigencia</th><th>Estado</th><th>Acciones</th></tr></thead>")
        sb.AppendLine("<tbody>")
        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Usuario_Listar", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@buscar", DBNull.Value)
                    cmd.Parameters.AddWithValue("@tipo_id", DBNull.Value)
                    cmd.Parameters.AddWithValue("@estado", DBNull.Value)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim uid As Integer = CInt(dr("usuario_id"))
                            Dim tid As Integer = CInt(dr("tipo_id"))
                            Dim nombres As String = HttpUtility.HtmlEncode(dr("nombres").ToString())
                            Dim apes As String = HttpUtility.HtmlEncode(dr("apellidos").ToString())
                            Dim carnet As String = HttpUtility.HtmlEncode(dr("carnet").ToString())
                            Dim email As String = If(IsDBNull(dr("email")), "", HttpUtility.HtmlEncode(dr("email").ToString()))
                            Dim celular As String = If(IsDBNull(dr("celular")), "", HttpUtility.HtmlEncode(dr("celular").ToString()))
                            Dim dir As String = If(IsDBNull(dr("direccion")), "", HttpUtility.HtmlEncode(dr("direccion").ToString()))
                            Dim vigencia As String = If(IsDBNull(dr("vigente_hasta")), "", CDate(dr("vigente_hasta")).ToString("yyyy-MM-dd"))
                            Dim vigShow As String = If(IsDBNull(dr("vigente_hasta")), "Permanente", CDate(dr("vigente_hasta")).ToString("dd/MM/yyyy"))
                            Dim tipo As String = HttpUtility.HtmlEncode(dr("tipo_nombre").ToString())
                            Dim estado As String = dr("estado_calculado").ToString()
                            Dim bloqueado As Boolean = CBool(dr("bloqueado"))
                            Dim iniciales As String = nombres.Substring(0, 1) & apes.Substring(0, 1)
                            Dim texto As String = (nombres & " " & apes & " " & carnet).ToLower()

                            Dim badgeEstado As String = ""
                            Select Case estado
                                Case "ACTIVO" : badgeEstado = "<span class=""badge badge-ok"">Activo</span>"
                                Case "BLOQUEADO" : badgeEstado = "<span class=""badge badge-bloq"">Bloqueado</span>"
                                Case "VENCIDO" : badgeEstado = "<span class=""badge badge-inac"">Vencido</span>"
                                Case "VENCE_HOY" : badgeEstado = "<span class=""badge badge-warn"">Vence hoy</span>"
                                Case Else : badgeEstado = "<span class=""badge badge-inac"">Inactivo</span>"
                            End Select

                            Dim badgeTipo As String = ""
                            Select Case tipo
                                Case "Administrador" : badgeTipo = "<span class=""badge badge-rosa"">" & tipo & "</span>"
                                Case "Cajero" : badgeTipo = "<span class=""badge badge-azul"">" & tipo & "</span>"
                                Case "Delivery" : badgeTipo = "<span class=""badge badge-gris"">" & tipo & "</span>"
                                Case Else : badgeTipo = "<span class=""badge badge-verde"">" & tipo & "</span>"
                            End Select

                            Dim btnBloqueo As String = ""
                            If bloqueado Then
                                btnBloqueo = "<button type=""button"" class=""btn btn-sm btn-success"" onclick=""abrirBloqueo(" & uid & ",false)""><i class=""ti ti-lock-open"" aria-hidden=""true""></i></button>"
                            Else
                                btnBloqueo = "<button type=""button"" class=""btn btn-sm btn-danger"" onclick=""abrirBloqueo(" & uid & ",true)""><i class=""ti ti-lock"" aria-hidden=""true""></i></button>"
                            End If

                            sb.Append("<tr class=""fila-usuario"" ")
                            sb.Append("data-texto=""").Append(texto).Append(""" ")
                            sb.Append("data-rol=""").Append(tid).Append(""" ")
                            sb.Append("data-estado=""").Append(estado).Append(""">")
                            sb.Append("<td><div class=""avatar"">").Append(iniciales).Append("</div></td>")
                            sb.Append("<td><strong>").Append(nombres).Append(" ").Append(apes).Append("</strong>")
                            If email <> "" Then sb.Append("<br><span style=""font-size:11px;color:#9e9e9e"">").Append(email).Append("</span>")
                            sb.Append("</td>")
                            sb.Append("<td>").Append(carnet).Append("</td>")
                            sb.Append("<td>").Append(badgeTipo).Append("</td>")
                            sb.Append("<td>").Append(vigShow).Append("</td>")
                            sb.Append("<td>").Append(badgeEstado).Append("</td>")
                            sb.Append("<td style=""display:flex;gap:4px"">")
                            sb.Append("<button type=""button"" class=""btn btn-sm"" onclick=""abrirModalEditar(")
                            sb.Append(uid).Append(",").Append(tid)
                            sb.Append(",'").Append(nombres).Append("','").Append(apes)
                            sb.Append("','").Append(email).Append("','").Append(celular)
                            sb.Append("','").Append(vigencia).Append("','").Append(dir).Append("')")
                            sb.Append("""><i class=""ti ti-edit"" aria-hidden=""true""></i></button>")
                            sb.Append(btnBloqueo)
                            sb.Append("<button type=""button"" class=""btn btn-sm"" onclick=""abrirReset(").Append(uid).Append(")""><i class=""ti ti-key"" aria-hidden=""true""></i></button>")
                            sb.AppendLine("</td></tr>")
                        End While
                    End Using
                End Using
            End Using
        Catch ex As Exception
            sb.AppendLine("<tr><td colspan=""7"" style=""padding:20px;text-align:center;color:#C62828"">Error al cargar usuarios: " & HttpUtility.HtmlEncode(ex.Message) & "</td></tr>")
            System.Diagnostics.Debug.WriteLine("ERROR CargarTabla: " & ex.Message)
        End Try
        sb.AppendLine("</tbody></table>")
        TablaHtml = sb.ToString()
    End Sub

    Protected Sub btnAccion_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        Dim usuarioId As String = Request.Form("hdUsuarioId")
        Dim motivo As String = Request.Form("hdMotivo")
        Dim creadorId As Integer = CInt(Session("usuario_id"))

        If accion Is Nothing Then accion = ""
        If motivo Is Nothing Then motivo = ""
        If usuarioId Is Nothing Then usuarioId = "0"

        motivo = LimpiarInput(motivo)
        Dim uid As Integer = 0
        If Not Integer.TryParse(usuarioId, uid) Then uid = 0

        Select Case accion
            Case "CREAR"
                ProcesarCrear(creadorId)
            Case "EDITAR"
                ProcesarEditar(uid, creadorId, motivo)
            Case "BLOQUEAR"
                ProcesarBloqueo(uid, True, creadorId, motivo)
            Case "DESBLOQUEAR"
                ProcesarBloqueo(uid, False, creadorId, motivo)
            Case "RESET"
                ProcesarReset(uid, creadorId, motivo)
        End Select

        CargarTiposJson()
        CargarTablaUsuarios()
    End Sub

    Private Sub ProcesarCrear(creadorId As Integer)
        Dim carnet As String = LimpiarInput(Request.Form("hdCarnet"))
        Dim tipoStr As String = Request.Form("hdTipoId")
        Dim nombres As String = LimpiarInput(Request.Form("hdNombres"))
        Dim apellidos As String = LimpiarInput(Request.Form("hdApellidos"))
        Dim email As String = LimpiarInput(Request.Form("hdEmail"))
        Dim celular As String = LimpiarInput(Request.Form("hdCelular"))
        Dim direccion As String = LimpiarInput(Request.Form("hdDireccion"))
        Dim fechaNac As String = Request.Form("hdFechaNac")
        Dim vigencia As String = Request.Form("hdVigencia")

        If carnet Is Nothing Then carnet = ""
        If tipoStr Is Nothing Then tipoStr = "0"
        If nombres Is Nothing Then nombres = ""
        If apellidos Is Nothing Then apellidos = ""
        If email Is Nothing Then email = ""
        If celular Is Nothing Then celular = ""
        If direccion Is Nothing Then direccion = ""
        If fechaNac Is Nothing Then fechaNac = ""
        If vigencia Is Nothing Then vigencia = ""

        ' Validacion en servidor
        If Not System.Text.RegularExpressions.Regex.IsMatch(carnet, "^\d{7,8}$") Then
            MostrarMensaje("Carnet no valido.", False) : Return
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
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Usuario_Crear", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@tipo_id", tipoId)
                    cmd.Parameters.AddWithValue("@carnet", carnet)
                    cmd.Parameters.AddWithValue("@nombres", nombres)
                    cmd.Parameters.AddWithValue("@apellidos", apellidos)
                    cmd.Parameters.AddWithValue("@email", If(email = "", CObj(DBNull.Value), email))
                    cmd.Parameters.AddWithValue("@celular", If(celular = "", CObj(DBNull.Value), celular))
                    cmd.Parameters.AddWithValue("@direccion", If(direccion = "", CObj(DBNull.Value), direccion))
                    cmd.Parameters.AddWithValue("@fecha_nac", fechaNacParam)
                    cmd.Parameters.AddWithValue("@vigente_hasta", vigenciaParam)
                    cmd.Parameters.AddWithValue("@creado_por", creadorId)
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

    Private Sub ProcesarEditar(uid As Integer, modificadorId As Integer, motivo As String)
        Dim tipoStr As String = Request.Form("hdTipoId")
        Dim nombres As String = LimpiarInput(Request.Form("hdNombres"))
        Dim apellidos As String = LimpiarInput(Request.Form("hdApellidos"))
        Dim email As String = LimpiarInput(Request.Form("hdEmail"))
        Dim celular As String = LimpiarInput(Request.Form("hdCelular"))
        Dim direccion As String = LimpiarInput(Request.Form("hdDireccion"))
        Dim fechaNac As String = Request.Form("hdFechaNac")
        Dim vigencia As String = Request.Form("hdVigencia")

        If tipoStr Is Nothing Then tipoStr = "0"
        If nombres Is Nothing Then nombres = ""
        If apellidos Is Nothing Then apellidos = ""
        If email Is Nothing Then email = ""
        If celular Is Nothing Then celular = ""
        If direccion Is Nothing Then direccion = ""
        If fechaNac Is Nothing Then fechaNac = ""
        If vigencia Is Nothing Then vigencia = ""
        If motivo Is Nothing Then motivo = "Actualizacion de datos"

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
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Usuario_Actualizar", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@usuario_id", uid)
                    cmd.Parameters.AddWithValue("@tipo_id", tipoId)
                    cmd.Parameters.AddWithValue("@nombres", nombres)
                    cmd.Parameters.AddWithValue("@apellidos", apellidos)
                    cmd.Parameters.AddWithValue("@email", If(email = "", CObj(DBNull.Value), email))
                    cmd.Parameters.AddWithValue("@celular", If(celular = "", CObj(DBNull.Value), celular))
                    cmd.Parameters.AddWithValue("@direccion", If(direccion = "", CObj(DBNull.Value), direccion))
                    cmd.Parameters.AddWithValue("@fecha_nac", fechaNacParam)
                    cmd.Parameters.AddWithValue("@vigente_hasta", vigenciaParam)
                    cmd.Parameters.AddWithValue("@modificado_por", modificadorId)
                    cmd.Parameters.AddWithValue("@motivo", motivo)
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

    Private Sub ProcesarBloqueo(uid As Integer, bloquear As Boolean, modificadorId As Integer, motivo As String)
        If motivo.Trim().Length < 5 Then
            MostrarMensaje("El motivo es obligatorio (min. 5 caracteres).", False) : Return
        End If
        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Usuario_CambiarBloqueo", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@usuario_id", uid)
                    cmd.Parameters.AddWithValue("@bloquear", If(bloquear, 1, 0))
                    cmd.Parameters.AddWithValue("@modificado_por", modificadorId)
                    cmd.Parameters.AddWithValue("@motivo", motivo)
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

    Private Sub ProcesarReset(uid As Integer, modificadorId As Integer, motivo As String)
        If motivo.Trim().Length < 5 Then
            MostrarMensaje("El motivo es obligatorio (min. 5 caracteres).", False) : Return
        End If
        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Usuario_ResetearPassword", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@usuario_id", uid)
                    cmd.Parameters.AddWithValue("@modificado_por", modificadorId)
                    cmd.Parameters.AddWithValue("@motivo", motivo)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            MostrarMensaje(dr("mensaje").ToString(), CBool(dr("ok")))
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarMensaje("Error al resetear contrasena.", False)
            System.Diagnostics.Debug.WriteLine("ERROR Reset: " & ex.Message)
        End Try
    End Sub

    Private Sub MostrarMensaje(mensaje As String, esOk As Boolean)
        Dim css As String = If(esOk, "alerta alerta-ok show", "alerta alerta-error show")
        Dim js As String = "var d=document.getElementById('divAlertaModal');" &
                            "if(d){d.innerHTML='" & HttpUtility.JavaScriptStringEncode(mensaje) & "';" &
                            "d.className='" & css & "';}" &
                            "var m=document.getElementById('modalUsuario');" &
                            "if(m){m.className='modal-bg show';}"
        ClientScript.RegisterStartupScript(Me.GetType(), "msg", js, True)
    End Sub

End Class
