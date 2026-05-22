Imports System.Data.SqlClient
Imports System.Web

' ============================================================
' SISCONBOL - Helper de sesion compartido
' Archivo: App_Code/SesionHelper.vb
' Usar en TODAS las paginas internas
' ============================================================
Public Class SesionHelper

    Public Shared Function ObtenerCadena() As String
        Return System.Configuration.ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString
    End Function

    ''' <summary>
    ''' Verifica sesion desde Session ASP.NET o cookie del navegador.
    ''' Si la Session se perdio por recompilacion, la restaura desde la BD.
    ''' Retorna True si la sesion es valida.
    ''' </summary>
    Public Shared Function VerificarSesion(context As HttpContext) As Boolean
        ' 1. Intentar desde Session
        Dim token As String = ""
        If context.Session("token") IsNot Nothing Then
            token = context.Session("token").ToString()
        End If

        ' 2. Si no hay Session, leer desde cookie
        If token = "" Then
            Dim cookie As HttpCookie = context.Request.Cookies("SISCONBOL_TOKEN")
            If cookie Is Nothing Then Return False
            token = cookie.Value
            If token = "" Then Return False
        End If

        ' 3. Validar contra BD
        Dim ip As String = context.Request.ServerVariables("REMOTE_ADDR")
        If ip Is Nothing Then ip = ""

        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_ValidarSesion", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@token", token)
                    cmd.Parameters.AddWithValue("@ip", ip)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Dim valida As Boolean = CBool(dr("valida"))
                            If valida Then
                                ' Restaurar Session si se perdio
                                If context.Session("token") Is Nothing OrElse
                                   context.Session("usuario_id") Is Nothing Then
                                    context.Session("token") = token
                                    Dim uidObj As Object = dr("usuario_id")
                                    If uidObj IsNot Nothing AndAlso Not IsDBNull(uidObj) Then
                                        Dim uid As Integer = CInt(uidObj)
                                        CargarDatosUsuario(context, uid)
                                    End If
                                End If
                            End If
                            Return valida
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR SesionHelper.VerificarSesion: " & ex.Message)
        End Try
        Return False
    End Function

    ''' <summary>
    ''' Carga todos los datos del usuario en Session desde la BD
    ''' </summary>
    Public Shared Sub CargarDatosUsuario(context As HttpContext, uid As Integer)
        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Usuario_ObtenerPorId", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@usuario_id", uid)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            context.Session("usuario_id") = uid
                            context.Session("nombres") = dr("nombres").ToString()
                            context.Session("apellidos") = dr("apellidos").ToString()
                            context.Session("tipo_id") = CInt(dr("tipo_id"))
                            context.Session("tipo_nombre") = dr("tipo_nombre").ToString()
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR SesionHelper.CargarDatos: " & ex.Message)
        End Try
    End Sub

    ''' <summary>
    ''' Obtiene el usuario_id de la Session de forma segura
    ''' </summary>
    Public Shared Function ObtenerUsuarioId(context As HttpContext) As Integer
        If context.Session("usuario_id") IsNot Nothing Then
            Return CInt(context.Session("usuario_id"))
        End If
        Return 0
    End Function

    ''' <summary>
    ''' Genera el HTML del sidebar con menu dinamico
    ''' </summary>
    Public Shared Function GenerarMenuHtml(context As HttpContext, page As System.Web.UI.Page) As String
        Dim usuarioId As Integer = ObtenerUsuarioId(context)
        If usuarioId = 0 Then Return ""

        Dim sbMenu As New System.Text.StringBuilder()
        Dim padres As New List(Of MenuData)()
        Dim hijos As New Dictionary(Of Integer, List(Of MenuData))()

        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_CargarMenu", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@usuario_id", usuarioId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim item As New MenuData()
                            item.MenuId = CInt(dr("menu_id"))
                            item.PadreId = If(IsDBNull(dr("padre_id")), 0, CInt(dr("padre_id")))
                            item.Nombre = dr("nombre").ToString()
                            item.Icono = If(IsDBNull(dr("icono")), "ti-circle", dr("icono").ToString())
                            item.Ruta = If(IsDBNull(dr("ruta")), "#", dr("ruta").ToString())
                            item.Orden = CByte(dr("orden"))
                            If item.PadreId = 0 Then
                                padres.Add(item)
                            Else
                                If Not hijos.ContainsKey(item.PadreId) Then
                                    hijos(item.PadreId) = New List(Of MenuData)()
                                End If
                                hijos(item.PadreId).Add(item)
                            End If
                        End While
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR GenerarMenuHtml: " & ex.Message)
            Return ""
        End Try

        For Each padre In padres.OrderBy(Function(x) x.Orden)
            Dim tieneHijos As Boolean = hijos.ContainsKey(padre.MenuId)
            If tieneHijos Then
                sbMenu.Append("<button type=""button"" class=""nav-item"" ")
                sbMenu.Append("onclick=""toggleHijos('h_" & padre.MenuId & "')"">")
                sbMenu.Append("<i class=""ti " & padre.Icono & " nav-icon""></i>")
                sbMenu.Append("<span>" & padre.Nombre & "</span>")
                sbMenu.Append("<i class=""ti ti-chevron-down nav-arrow""></i>")
                sbMenu.AppendLine("</button>")
                sbMenu.AppendLine("<div class=""nav-children"" id=""h_" & padre.MenuId & """>")
                For Each hijo In hijos(padre.MenuId).OrderBy(Function(x) x.Orden)
                    sbMenu.Append("<a class=""nav-child"" href=""" & page.ResolveUrl(hijo.Ruta) & """>")
                    sbMenu.Append("<i class=""ti " & hijo.Icono & " nav-icon""></i>")
                    sbMenu.Append(hijo.Nombre)
                    sbMenu.AppendLine("</a>")
                Next
                sbMenu.AppendLine("</div>")
            Else
                sbMenu.Append("<a class=""nav-item"" href=""" & page.ResolveUrl(padre.Ruta) & """>")
                sbMenu.Append("<i class=""ti " & padre.Icono & " nav-icon""></i>")
                sbMenu.Append("<span>" & padre.Nombre & "</span>")
                sbMenu.AppendLine("</a>")
            End If
        Next

        Return sbMenu.ToString()
    End Function

    Public Class MenuData
        Public Property MenuId As Integer
        Public Property PadreId As Integer
        Public Property Nombre As String
        Public Property Icono As String
        Public Property Ruta As String
        Public Property Orden As Byte
    End Class


End Class