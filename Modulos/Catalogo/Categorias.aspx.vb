Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web
Imports System.Net
Imports System.IO

Partial Public Class Modulos_Catalogo_Categorias
    Inherits System.Web.UI.Page

    ' MenuHtml ya no es necesario — lo maneja Site.master
    Public Property ArbolHtml As String = ""
    Public Property ListaCatsJson As String = "[]"
    Public Property TotalCategorias As Integer = 0
    Public Property SinProductos As Integer = 0
    Public Property PendienteSync As Integer = 0

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' La Master Page (Site.master) ya verifica sesion y carga el menu
        ' Aqui solo va la logica propia de Categorias
        If Not IsPostBack Then
            CargarDatos()
        End If
    End Sub

    Private Sub CargarDatos()
        Dim cats As List(Of CatData) = ObtenerCategorias()
        ArbolHtml = GenerarArbolHtml(cats)
        ListaCatsJson = GenerarListaJson(cats)
        TotalCategorias = cats.Count
        SinProductos = 0
        PendienteSync = 0
        For Each c In cats
            If c.TotalProductos = 0 Then SinProductos += 1
            If c.SyncEstado = "PENDIENTE" Then PendienteSync += 1
        Next
    End Sub

    Private Function ObtenerCategorias() As List(Of CatData)
        Dim lista As New List(Of CatData)()
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_Listar", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim c As New CatData()
                            c.CatId = CInt(dr("categoria_id"))
                            c.PadreId = If(IsDBNull(dr("padre_id")), 0, CInt(dr("padre_id")))
                            c.Nombre = dr("nombre").ToString()
                            c.Descripcion = If(IsDBNull(dr("descripcion")), "", dr("descripcion").ToString())
                            c.Slug = If(IsDBNull(dr("slug")), "", dr("slug").ToString())
                            c.Orden = CInt(dr("orden"))
                            c.Activo = CBool(dr("activo"))
                            c.SyncEstado = dr("wc_sync_estado").ToString()
                            c.TotalProductos = CInt(dr("total_productos"))
                            lista.Add(c)
                        End While
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ObtenerCategorias: " & ex.Message)
        End Try
        Return lista
    End Function

    Private Function GenerarArbolHtml(cats As List(Of CatData)) As String
        Dim sb As New StringBuilder()
        Dim padres As New List(Of CatData)()
        Dim hijos As New Dictionary(Of Integer, List(Of CatData))()
        For Each c In cats
            If c.PadreId = 0 Then
                padres.Add(c)
            Else
                If Not hijos.ContainsKey(c.PadreId) Then hijos(c.PadreId) = New List(Of CatData)()
                hijos(c.PadreId).Add(c)
            End If
        Next
        For Each padre In padres.OrderBy(Function(x) x.Orden)
            RenderNodo(sb, padre, hijos, 0)
        Next
        Return sb.ToString()
    End Function

    Private Sub RenderNodo(sb As StringBuilder, c As CatData,
                            hijos As Dictionary(Of Integer, List(Of CatData)),
                            nivel As Integer)
        Dim tieneHijos As Boolean = hijos.ContainsKey(c.CatId)
        Dim nivel_css As String = "nivel-" & Math.Min(nivel, 4)
        Dim nombreEnc As String = HttpUtility.HtmlEncode(c.Nombre)
        Dim descEnc As String = HttpUtility.HtmlEncode(c.Descripcion)
        Dim nombreJs As String = c.Nombre.Replace("'", "\'").Replace("""", "&quot;")
        Dim descJs As String = c.Descripcion.Replace("'", "\'").Replace("""", "&quot;")
        Dim slugJs As String = c.Slug.Replace("'", "\'")

        Dim badgeSync As String = ""
        If c.SyncEstado = "SINCRONIZADO" Then
            badgeSync = "<span class=""badge badge-sync"">WC</span>"
        ElseIf c.SyncEstado = "PENDIENTE" Then
            badgeSync = "<span class=""badge badge-pend"">Pendiente</span>"
        End If

        Dim badgeProd As String = "<span class=""badge badge-prod"">" & c.TotalProductos & " prod</span>"
        If c.TotalProductos = 0 Then badgeProd = "<span class=""badge badge-inac"">Sin prod</span>"

        sb.Append("<div id=""fila_" & c.CatId & """ class=""nodo-fila " & nivel_css & """ ")
        sb.Append("draggable=""true"" ")
        sb.Append("data-nombre=""" & nombreEnc.ToLower() & """ ")
        sb.Append("ondragstart=""onDragStart(event," & c.CatId & ")"" ")
        sb.Append("ondragend=""onDragEnd(" & c.CatId & ")"" ")
        sb.Append("ondragover=""onDragOver(event," & c.CatId & ")"" ")
        sb.Append("ondrop=""onDrop(event," & c.PadreId & "," & c.Orden & ")"">")
        sb.Append("<i class=""ti ti-grip-vertical drag-handle"" aria-hidden=""true""></i>")
        If tieneHijos Then
            sb.Append("<button type=""button"" class=""toggle-btn"" onclick=""toggleNodo('" & c.CatId & "')"">")
            sb.Append("<i class=""ti ti-chevron-down ico-toggle"" id=""ico_" & c.CatId & """  aria-hidden=""true""></i>")
            sb.Append("</button>")
        Else
            sb.Append("<div class=""toggle-esp""></div>")
        End If
        sb.Append("<span class=""nodo-nombre"">")
        sb.Append(nombreEnc)
        If descEnc <> "" Then
            sb.Append("<span class=""nodo-desc"">" & descEnc.Substring(0, Math.Min(40, descEnc.Length)) & "</span>")
        End If
        sb.Append("</span>")
        sb.Append(badgeProd)
        sb.Append(badgeSync)
        sb.Append("<div class=""nodo-acciones"">")
        sb.Append("<button type=""button"" class=""btn btn-sm btn-prod"" title=""Gestionar productos"" ")
        sb.Append("onclick=""verProductos(" & c.CatId & ")"">")
        sb.Append("<i class=""ti ti-package"" aria-hidden=""true""></i></button>")
        sb.Append("<button type=""button"" class=""btn btn-sm"" ")
        sb.Append("onclick=""editarCategoria(" & c.CatId & "," & c.PadreId & ",'" & nombreJs & "','" & descJs & "','" & slugJs & "')"">")
        sb.Append("<i class=""ti ti-edit"" aria-hidden=""true""></i></button>")
        sb.Append("<button type=""button"" class=""btn btn-sm btn-danger"" onclick=""abrirEliminar(" & c.CatId & ")"">")
        sb.Append("<i class=""ti ti-trash"" aria-hidden=""true""></i></button>")
        sb.Append("</div>")
        sb.AppendLine("</div>")

        If tieneHijos Then
            sb.AppendLine("<div class=""nodo-hijos"" id=""h_" & c.CatId & """>")
            For Each hijo In hijos(c.CatId).OrderBy(Function(x) x.Orden)
                RenderNodo(sb, hijo, hijos, nivel + 1)
            Next
            sb.AppendLine("</div>")
        End If
    End Sub

    Private Function GenerarListaJson(cats As List(Of CatData)) As String
        Dim sb As New StringBuilder("[")
        Dim primero As Boolean = True
        Dim padres As New List(Of CatData)()
        Dim hijos As New Dictionary(Of Integer, List(Of CatData))()
        For Each c In cats
            If c.PadreId = 0 Then
                padres.Add(c)
            Else
                If Not hijos.ContainsKey(c.PadreId) Then hijos(c.PadreId) = New List(Of CatData)()
                hijos(c.PadreId).Add(c)
            End If
        Next
        For Each padre In padres.OrderBy(Function(x) x.Orden)
            AgregarJsonNodo(sb, padre, hijos, 0, primero)
            primero = False
        Next
        sb.Append("]")
        Return sb.ToString()
    End Function

    Private Sub AgregarJsonNodo(sb As StringBuilder, c As CatData,
                                 hijos As Dictionary(Of Integer, List(Of CatData)),
                                 nivel As Integer, ByRef primero As Boolean)
        Dim indent As String = New String(" "c, nivel * 2)
        Dim nombreEsc As String = c.Nombre.Replace("\", "\\").Replace("""", "\""")
        If Not primero Then sb.Append(",")
        sb.Append("{""id"":" & c.CatId & ",""nombre"":""" & nombreEsc & """,""indent"":""" & indent & """}")
        primero = False
        If hijos.ContainsKey(c.CatId) Then
            For Each hijo In hijos(c.CatId).OrderBy(Function(x) x.Orden)
                AgregarJsonNodo(sb, hijo, hijos, nivel + 1, primero)
            Next
        End If
    End Sub

    Protected Sub btnAccion_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""
        Select Case accion
            Case "CREAR" : ProcesarCrear()
            Case "EDITAR" : ProcesarEditar()
            Case "ELIMINAR" : ProcesarEliminar()
            Case "BAJA_MASIVA" : ProcesarBajaMasiva()
            Case "HABILITAR" : ProcesarHabilitar()
            Case "REORDENAR" : ProcesarReordenar()
        End Select
        CargarDatos()
    End Sub

    Private Sub ProcesarCrear()
        Dim nombre As String = LimpiarInput(Request.Form("hdNombre"))
        Dim desc As String = LimpiarInput(Request.Form("hdDesc"))
        Dim slug As String = LimpiarInput(Request.Form("hdSlug"))
        Dim padreId As Integer = 0
        Integer.TryParse(Request.Form("hdPadreId"), padreId)
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        If nombre = "" Then MostrarAlertaArbol("El nombre es obligatorio.", "error") : Return
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_Crear", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@padre_id", If(padreId > 0, CObj(padreId), CObj(DBNull.Value)))
                    cmd.Parameters.AddWithValue("@nombre", nombre)
                    cmd.Parameters.AddWithValue("@descripcion", If(desc = "", CObj(DBNull.Value), desc))
                    cmd.Parameters.AddWithValue("@slug", If(slug = "", CObj(DBNull.Value), slug))
                    cmd.Parameters.AddWithValue("@creado_por", If(uid > 0, CObj(uid), CObj(DBNull.Value)))
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            If CBool(dr("ok")) Then
                                Dim nuevaId As Integer = CInt(dr("categoria_id"))
                                Dim sincOk As Boolean = SincronizarConWC(nuevaId, nombre, desc, slug, 0, 0)
                                If sincOk Then
                                    MostrarAlertaArbol("Categoria creada y sincronizada con WooCommerce.", "ok")
                                Else
                                    MostrarAlertaArbol("Categoria creada. No se pudo sincronizar con WC (se sincronizara despues).", "warn")
                                End If
                            Else
                                MostrarAlertaArbol(dr("mensaje").ToString(), "error")
                            End If
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarAlertaArbol("Error: " & ex.Message, "error")
        End Try
    End Sub

    Private Sub ProcesarEditar()
        Dim catId As Integer = 0
        Integer.TryParse(Request.Form("hdCatId"), catId)
        Dim nombre As String = LimpiarInput(Request.Form("hdNombre"))
        Dim desc As String = LimpiarInput(Request.Form("hdDesc"))
        Dim slug As String = LimpiarInput(Request.Form("hdSlug"))
        Dim padreId As Integer = 0
        Integer.TryParse(Request.Form("hdPadreId"), padreId)
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        If nombre = "" Then MostrarAlertaArbol("El nombre es obligatorio.", "error") : Return
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_Actualizar", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@categoria_id", catId)
                    cmd.Parameters.AddWithValue("@padre_id", If(padreId > 0, CObj(padreId), CObj(DBNull.Value)))
                    cmd.Parameters.AddWithValue("@nombre", nombre)
                    cmd.Parameters.AddWithValue("@descripcion", If(desc = "", CObj(DBNull.Value), desc))
                    cmd.Parameters.AddWithValue("@slug", If(slug = "", CObj(DBNull.Value), slug))
                    cmd.Parameters.AddWithValue("@modificado_por", If(uid > 0, CObj(uid), CObj(DBNull.Value)))
                    cmd.Parameters.AddWithValue("@motivo", "Edicion desde interfaz")
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            If CBool(dr("ok")) Then
                                Dim wcId As Integer = 0
                                Try
                                    Using conn2 As New SqlConnection(SesionHelper.ObtenerCadena())
                                        conn2.Open()
                                        Using cmd2 As New SqlCommand("FLORERIA_sp_Categoria_Listar", conn2)
                                            cmd2.CommandType = Data.CommandType.StoredProcedure
                                            Using dr2 As SqlDataReader = cmd2.ExecuteReader()
                                                While dr2.Read()
                                                    If CInt(dr2("categoria_id")) = catId Then
                                                        If Not IsDBNull(dr2("wc_category_id")) Then wcId = CInt(dr2("wc_category_id"))
                                                        Exit While
                                                    End If
                                                End While
                                            End Using
                                        End Using
                                    End Using
                                Catch : End Try
                                Dim sincOk As Boolean = SincronizarConWC(catId, nombre, desc, slug, wcId, padreId)
                                If sincOk Then
                                    MostrarAlertaArbol("Categoria actualizada y sincronizada con WooCommerce.", "ok")
                                Else
                                    MostrarAlertaArbol("Categoria actualizada. No se pudo sincronizar con WC (se sincronizara despues).", "warn")
                                End If
                            Else
                                MostrarAlertaArbol(dr("mensaje").ToString(), "error")
                            End If
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarAlertaArbol("Error: " & ex.Message, "error")
        End Try
    End Sub

    Private Sub ProcesarEliminar()
        Dim catId As Integer = 0
        Integer.TryParse(Request.Form("hdCatId"), catId)
        Dim motivo As String = LimpiarInput(Request.Form("hdMotivo"))
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_Eliminar", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@categoria_id", catId)
                    cmd.Parameters.AddWithValue("@modificado_por", If(uid > 0, CObj(uid), CObj(DBNull.Value)))
                    cmd.Parameters.AddWithValue("@motivo", motivo)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            If CBool(dr("ok")) Then
                                MostrarAlertaArbol("Categoria eliminada.", "ok")
                            Else
                                MostrarAlertaArbol(dr("mensaje").ToString(), "error")
                            End If
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarAlertaArbol("Error: " & ex.Message, "error")
        End Try
    End Sub

    Private Sub ProcesarBajaMasiva()
        Dim catId As Integer = 0
        Integer.TryParse(Request.Form("hdCatId"), catId)
        Dim motivo As String = LimpiarInput(Request.Form("hdMotivo"))
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_BajaProductos", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@categoria_id", catId)
                    cmd.Parameters.AddWithValue("@modificado_por", If(uid > 0, CObj(uid), CObj(DBNull.Value)))
                    cmd.Parameters.AddWithValue("@motivo", motivo)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            If Not CBool(dr("ok")) Then
                                MostrarAlertaArbol(dr("mensaje").ToString(), "error") : Return
                            End If
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarAlertaArbol("Error: " & ex.Message, "error") : Return
        End Try
        Dim sincOk As Integer = SincronizarProductosDeCat(catId, "draft")
        If sincOk >= 0 Then
            MostrarAlertaArbol("Productos dados de baja y sincronizados con WooCommerce.", "ok")
        Else
            MostrarAlertaArbol("Productos dados de baja. No se pudo sincronizar con WC (se sincronizara despues).", "warn")
        End If
    End Sub

    Private Sub ProcesarHabilitar()
        Dim catId As Integer = 0
        Integer.TryParse(Request.Form("hdCatId"), catId)
        Dim motivo As String = LimpiarInput(Request.Form("hdMotivo"))
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_HabilitarProductos", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@categoria_id", catId)
                    cmd.Parameters.AddWithValue("@modificado_por", If(uid > 0, CObj(uid), CObj(DBNull.Value)))
                    cmd.Parameters.AddWithValue("@motivo", motivo)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            If Not CBool(dr("ok")) Then
                                MostrarAlertaArbol(dr("mensaje").ToString(), "error") : Return
                            End If
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarAlertaArbol("Error: " & ex.Message, "error") : Return
        End Try
        Dim sincOk As Integer = SincronizarProductosDeCat(catId, "publish")
        If sincOk >= 0 Then
            MostrarAlertaArbol("Productos habilitados y sincronizados con WooCommerce.", "ok")
        Else
            MostrarAlertaArbol("Productos habilitados. No se pudo sincronizar con WC (se sincronizara despues).", "warn")
        End If
    End Sub

    Private Sub ProcesarReordenar()
        Dim catId As Integer = 0
        Dim padreId As Integer = 0
        Dim orden As Integer = 0
        Integer.TryParse(Request.Form("hdCatId"), catId)
        Integer.TryParse(Request.Form("hdPadreId"), padreId)
        Integer.TryParse(Request.Form("hdOrdenJson"), orden)
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_CambiarOrden", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@categoria_id", catId)
                    cmd.Parameters.AddWithValue("@nuevo_padre_id", If(padreId > 0, CObj(padreId), CObj(DBNull.Value)))
                    cmd.Parameters.AddWithValue("@nuevo_orden", orden)
                    cmd.Parameters.AddWithValue("@modificado_por", If(uid > 0, CObj(uid), CObj(DBNull.Value)))
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Reordenar: " & ex.Message)
        End Try
    End Sub

    Private Function SincronizarConWC(catId As Integer, nombre As String,
                                       desc As String, slug As String,
                                       wcCatId As Integer, wcPadreId As Integer) As Boolean
        Try
            Dim wcUrl As String = ObtenerConfig("WC_URL")
            If wcUrl = "" Then Return False
            Dim bridgeSecret As String = ObtenerConfig("WC_WEBHOOK_SECRET")
            If bridgeSecret = "" Then bridgeSecret = "MissFlores2026Sec"
            Dim accion As String = If(wcCatId > 0, "actualizar_categoria", "crear_categoria")
            Dim apiUrl As String = wcUrl.TrimEnd("/") & "/wc-bridge.php?secret=" & bridgeSecret & "&accion=" & accion
            Dim nombreSafe As String = nombre.Replace("\", "\\").Replace("""", "\""")
            Dim descSafe As String = desc.Replace("\", "\\").Replace("""", "\""")
            Dim body As String = "{""nombre"":""" & nombreSafe & """," &
                                  """descripcion"":""" & descSafe & """," &
                                  """slug"":""" & slug & """," &
                                  """wc_padre_id"":" & wcPadreId & "," &
                                  """wc_category_id"":" & wcCatId & "}"
            ServicePointManager.ServerCertificateValidationCallback = Function(s, c, ch, e) True
            Dim request As HttpWebRequest = CType(WebRequest.Create(apiUrl), HttpWebRequest)
            request.Method = "POST"
            request.ContentType = "application/json"
            request.Timeout = 3000
            Dim bodyBytes() As Byte = Encoding.UTF8.GetBytes(body)
            request.ContentLength = bodyBytes.Length
            Using stream As Stream = request.GetRequestStream()
                stream.Write(bodyBytes, 0, bodyBytes.Length)
            End Using
            Dim resp As HttpWebResponse = CType(request.GetResponse(), HttpWebResponse)
            Dim reader As New StreamReader(resp.GetResponseStream())
            Dim json As String = reader.ReadToEnd()
            resp.Close()
            If accion = "crear_categoria" AndAlso json.Contains("""ok"":true") Then
                Dim wcIdNuevo As Integer = ExtraerEntero(json, "wc_category_id")
                If wcIdNuevo > 0 Then
                    Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                        conn.Open()
                        Using cmd As New SqlCommand("FLORERIA_sp_Categoria_GuardarWcId", conn)
                            cmd.CommandType = Data.CommandType.StoredProcedure
                            cmd.Parameters.AddWithValue("@categoria_id", catId)
                            cmd.Parameters.AddWithValue("@wc_category_id", wcIdNuevo)
                            cmd.ExecuteNonQuery()
                        End Using
                    End Using
                End If
            ElseIf accion = "actualizar_categoria" AndAlso json.Contains("""ok"":true") Then
                Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                    conn.Open()
                    Using cmd As New SqlCommand("FLORERIA_sp_Categoria_MarcarSincronizada", conn)
                        cmd.CommandType = Data.CommandType.StoredProcedure
                        cmd.Parameters.AddWithValue("@categoria_id", catId)
                        cmd.ExecuteNonQuery()
                    End Using
                End Using
            End If
            Return json.Contains("""ok"":true")
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR SincronizarWC: " & ex.Message)
            Return False
        End Try
    End Function

    Private Function SincronizarProductosDeCat(catId As Integer, wcStatus As String) As Integer
        Dim sincOk As Integer = 0
        Try
            Dim wcUrl As String = ObtenerConfig("WC_URL")
            Dim wcKey As String = ObtenerConfig("WC_CONSUMER_KEY")
            Dim wcSecret As String = ObtenerConfig("WC_CONSUMER_SECRET")
            If wcUrl = "" OrElse wcKey = "" OrElse wcSecret = "" Then Return -1
            Dim wcProdIds As New List(Of Integer)()
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_ListarProductos", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@categoria_id", catId)
                    cmd.Parameters.AddWithValue("@buscar", DBNull.Value)
                    cmd.Parameters.AddWithValue("@estado", DBNull.Value)
                    cmd.Parameters.AddWithValue("@sync_estado", DBNull.Value)
                    cmd.Parameters.AddWithValue("@stock_estado", DBNull.Value)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim wcProdId As Integer = 0
                            If HasColumn(dr, "wc_product_id") AndAlso Not IsDBNull(dr("wc_product_id")) Then
                                wcProdId = CInt(dr("wc_product_id"))
                            End If
                            If wcProdId > 0 Then wcProdIds.Add(wcProdId)
                        End While
                    End Using
                End Using
            End Using
            If wcProdIds.Count = 0 Then Return 0
            ServicePointManager.ServerCertificateValidationCallback = Function(s, c, ch, e) True
            Dim credencial As String = Convert.ToBase64String(Encoding.UTF8.GetBytes(wcKey & ":" & wcSecret))
            Dim body As String = "{""status"":""" & wcStatus & """}"
            Dim bodyBytes() As Byte = Encoding.UTF8.GetBytes(body)
            For Each wcProdId As Integer In wcProdIds
                Try
                    Dim apiUrl As String = wcUrl.TrimEnd("/") & "/wp-json/wc/v3/products/" & wcProdId
                    Dim req As HttpWebRequest = CType(WebRequest.Create(apiUrl), HttpWebRequest)
                    req.Method = "PUT"
                    req.ContentType = "application/json"
                    req.Timeout = 3000
                    req.Headers.Add("Authorization", "Basic " & credencial)
                    req.ContentLength = bodyBytes.Length
                    Using stream As Stream = req.GetRequestStream()
                        stream.Write(bodyBytes, 0, bodyBytes.Length)
                    End Using
                    Dim resp As HttpWebResponse = CType(req.GetResponse(), HttpWebResponse)
                    Dim reader As New StreamReader(resp.GetResponseStream())
                    Dim json As String = reader.ReadToEnd()
                    resp.Close()
                    If json.Contains("""id"":") Then sincOk += 1
                Catch exProd As Exception
                    System.Diagnostics.Debug.WriteLine("Sync prod " & wcProdId & " fallo: " & exProd.Message)
                End Try
            Next
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR SincronizarProductosDeCat: " & ex.Message)
            Return -1
        End Try
        Return sincOk
    End Function

    Private Function ExtraerEntero(json As String, campo As String) As Integer
        Try
            Dim patron As String = """" & campo & """:"
            Dim idx As Integer = json.IndexOf(patron)
            If idx < 0 Then Return 0
            idx += patron.Length
            Dim sb As New StringBuilder()
            While idx < json.Length AndAlso Char.IsDigit(json(idx))
                sb.Append(json(idx)) : idx += 1
            End While
            Dim resultado As Integer = 0
            Integer.TryParse(sb.ToString(), resultado)
            Return resultado
        Catch
            Return 0
        End Try
    End Function

    Private Function ObtenerConfig(clave As String) As String
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Config_Obtener", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@clave", clave)
                    Dim result As Object = cmd.ExecuteScalar()
                    If result IsNot Nothing AndAlso Not IsDBNull(result) Then Return result.ToString()
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ObtenerConfig: " & ex.Message)
        End Try
        Return ""
    End Function

    Private Sub MostrarAlertaArbol(mensaje As String, tipo As String)
        Dim m As String = mensaje.Replace("\", "\\").Replace("'", "").Replace(Chr(13), "").Replace(Chr(10), " ")
        Dim js As String = "var d=document.getElementById('divAlertaArbol');" &
                           "if(d){d.textContent='" & m & "';" &
                           "d.className='alerta alerta-" & tipo & " show';}"
        ClientScript.RegisterStartupScript(Me.GetType(), "alerta", js, True)
    End Sub

    Private Function LimpiarInput(v As String) As String
        If v Is Nothing Then Return ""
        Return v.Trim().Replace("<", "").Replace(">", "").Replace("'", "").Replace("""", "")
    End Function

    Private Function HasColumn(dr As SqlDataReader, nombre As String) As Boolean
        Try
            For i As Integer = 0 To dr.FieldCount - 1
                If String.Equals(dr.GetName(i), nombre, StringComparison.OrdinalIgnoreCase) Then Return True
            Next
        Catch
        End Try
        Return False
    End Function

    Private Class CatData
        Public Property CatId As Integer
        Public Property PadreId As Integer
        Public Property Nombre As String = ""
        Public Property Descripcion As String = ""
        Public Property Slug As String = ""
        Public Property Orden As Integer
        Public Property Activo As Boolean
        Public Property SyncEstado As String = ""
        Public Property TotalProductos As Integer
    End Class

End Class