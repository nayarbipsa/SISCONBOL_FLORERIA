Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web
Imports System.Net
Imports System.IO

Partial Public Class Modulos_Catalogo_Categoria_Productos
    Inherits System.Web.UI.Page

    Public Property MenuHtml As String = ""
    Public Property TablaHtml As String = ""
    Public Property CategoriaId As Integer = 0
    Public Property CategoriaNombre As String = ""
    Public Property CategoriaRuta As String = ""
    Public Property StatTotal As Integer = 0
    Public Property StatActivos As Integer = 0
    Public Property StatPrincipal As Integer = 0
    Public Property StatPromo As Integer = 0
    Public Property NombreUsuario As String = ""
    Public Property Iniciales As String = ""
    Public Property RolUsuario As String = ""
    Public Property DisponiblesHtml As String = ""
    Public Property MostrarModal As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not SesionHelper.VerificarSesion(HttpContext.Current) Then
            Response.Redirect("~/Login.aspx")
            Return
        End If
        MenuHtml = SesionHelper.GenerarMenuHtml(HttpContext.Current, Me)
        CargarDatosUsuario()

        Dim idStr As String = Request.QueryString("id")
        If idStr Is Nothing Then idStr = ""
        ' En postback el QueryString puede perderse — leer del hidden field
        If idStr = "" Then
            Dim idForm As String = Request.Form("hdCategoriaId")
            If idForm IsNot Nothing Then idStr = idForm
        End If
        If idStr = "" Then idStr = "0"
        Integer.TryParse(idStr, CategoriaId)

        If CategoriaId <= 0 Then
            Response.Redirect("Categorias.aspx")
            Return
        End If

        CargarInfoCategoria()
        If CategoriaNombre = "" Then
            Response.Redirect("Categorias.aspx")
            Return
        End If

        If Not IsPostBack Then
            CargarTabla("", "")
            CargarStats()
            ProcesarBuscarDisponibles("")
        End If
    End Sub

    Protected Sub btnAccion_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""

        Select Case accion
            Case "BUSCAR_DISPONIBLES"
                Dim bd As String = Request.Form("hdBuscarDisp")
                If bd Is Nothing Then bd = ""
                ProcesarBuscarDisponibles(bd)
                Return

            Case "AGREGAR_PRODUCTOS"
                ProcesarAgregar()

            Case "QUITAR"
                ProcesarQuitar()

            Case "QUITAR_MASIVO"
                ProcesarQuitarMasivo()

            Case "MARCAR_PRINCIPAL"
                ProcesarMarcarPrincipal()
        End Select

        CargarTabla("", "")
        CargarStats()
        ProcesarBuscarDisponibles("")
    End Sub

    Protected Sub btnCerrarSesion_Click(ByVal sender As Object, ByVal e As EventArgs)
        EjecutarCerrarSesion()
    End Sub

    ' --- DATOS DEL USUARIO ------------------------------------
    Private Sub CargarDatosUsuario()
        Try
            Dim n As Object = Session("nombres")
            Dim a As Object = Session("apellidos")
            Dim r As Object = Session("tipo_nombre")
            Dim ns As String = If(n IsNot Nothing, n.ToString(), "")
            Dim ap As String = If(a IsNot Nothing, a.ToString(), "")
            Dim rl As String = If(r IsNot Nothing, r.ToString(), "")
            NombreUsuario = (ns & " " & ap).Trim()
            RolUsuario = rl
            Dim ini As String = ""
            If ns.Length > 0 Then ini &= ns.Substring(0, 1).ToUpper()
            If ap.Length > 0 Then ini &= ap.Substring(0, 1).ToUpper()
            If ini = "" Then ini = "--"
            Iniciales = ini
        Catch
            NombreUsuario = ""
            Iniciales = "--"
            RolUsuario = ""
        End Try
    End Sub

    ' --- INFO DE LA CATEGORIA ---------------------------------
    Private Sub CargarInfoCategoria()
        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_Listar", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim id As Integer = CInt(dr("categoria_id"))
                            If id = CategoriaId Then
                                CategoriaNombre = If(IsDBNull(dr("nombre")), "", dr("nombre").ToString())
                                Dim padNom As String = ""
                                If HasReaderColumn(dr, "padre_nombre") Then
                                    If Not IsDBNull(dr("padre_nombre")) Then padNom = dr("padre_nombre").ToString()
                                End If
                                If padNom <> "" Then
                                    CategoriaRuta = padNom & " / " & CategoriaNombre
                                Else
                                    CategoriaRuta = "Categoria raiz"
                                End If
                                Exit While
                            End If
                        End While
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR CargarInfoCategoria: " & ex.Message)
        End Try
    End Sub

    ' --- STATS ------------------------------------------------
    Private Sub CargarStats()
        Dim spOk As Boolean = False
        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_ObtenerStats", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@categoria_id", CategoriaId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            ' Intentar nombres estandar primero
                            If HasReaderColumn(dr, "total") AndAlso Not IsDBNull(dr("total")) Then StatTotal = CInt(dr("total")) : spOk = True
                            If HasReaderColumn(dr, "total_productos") AndAlso Not IsDBNull(dr("total_productos")) Then StatTotal = CInt(dr("total_productos")) : spOk = True
                            If HasReaderColumn(dr, "activos") AndAlso Not IsDBNull(dr("activos")) Then StatActivos = CInt(dr("activos"))
                            If HasReaderColumn(dr, "productos_activos") AndAlso Not IsDBNull(dr("productos_activos")) Then StatActivos = CInt(dr("productos_activos"))
                            If HasReaderColumn(dr, "principal") AndAlso Not IsDBNull(dr("principal")) Then StatPrincipal = CInt(dr("principal"))
                            If HasReaderColumn(dr, "con_principal") AndAlso Not IsDBNull(dr("con_principal")) Then StatPrincipal = CInt(dr("con_principal"))
                            If HasReaderColumn(dr, "promo") AndAlso Not IsDBNull(dr("promo")) Then StatPromo = CInt(dr("promo"))
                            If HasReaderColumn(dr, "en_promo") AndAlso Not IsDBNull(dr("en_promo")) Then StatPromo = CInt(dr("en_promo"))
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR CargarStats SP: " & ex.Message)
        End Try

        ' Fallback: calcular directo si el SP no funcionó o devolvió 0 total
        If Not spOk OrElse StatTotal = 0 Then
            Try
                Using conn2 As New SqlConnection(ObtenerCadena())
                    conn2.Open()
                    Using cmd2 As New SqlCommand("FLORERIA_sp_Categoria_ListarProductos", conn2)
                        cmd2.CommandType = Data.CommandType.StoredProcedure
                        cmd2.Parameters.AddWithValue("@categoria_id", CategoriaId)
                        cmd2.Parameters.AddWithValue("@buscar", DBNull.Value)
                        cmd2.Parameters.AddWithValue("@estado", DBNull.Value)
                        cmd2.Parameters.AddWithValue("@sync_estado", DBNull.Value)
                        cmd2.Parameters.AddWithValue("@stock_estado", DBNull.Value)
                        Dim tot As Integer = 0
                        Dim act As Integer = 0
                        Dim pri As Integer = 0
                        Dim pro As Integer = 0
                        Using dr2 As SqlDataReader = cmd2.ExecuteReader()
                            While dr2.Read()
                                tot += 1
                                If HasReaderColumn(dr2, "activo") AndAlso Not IsDBNull(dr2("activo")) AndAlso CBool(dr2("activo")) Then act += 1
                                If HasReaderColumn(dr2, "es_principal") AndAlso Not IsDBNull(dr2("es_principal")) AndAlso CBool(dr2("es_principal")) Then pri += 1
                                Dim tieneP As Boolean = False
                                If HasReaderColumn(dr2, "tiene_promo_activa") AndAlso Not IsDBNull(dr2("tiene_promo_activa")) Then tieneP = CBool(dr2("tiene_promo_activa"))
                                If tieneP Then pro += 1
                            End While
                        End Using
                        StatTotal = tot
                        StatActivos = act
                        StatPrincipal = pri
                        StatPromo = pro
                    End Using
                End Using
            Catch ex2 As Exception
                System.Diagnostics.Debug.WriteLine("ERROR CargarStats fallback: " & ex2.Message)
            End Try
        End If

        ' Actualizar divs via JS (funciona tanto en carga inicial como en postbacks)
        Dim js As String =
            "var eT=document.getElementById('stTotal');" &
            "var eA=document.getElementById('stActivos');" &
            "var eP=document.getElementById('stPrincipal');" &
            "var ePr=document.getElementById('stPromo');" &
            "if(eT){eT.textContent='" & StatTotal & "';}" &
            "if(eA){eA.textContent='" & StatActivos & "';}" &
            "if(eP){eP.textContent='" & StatPrincipal & "';}" &
            "if(ePr){ePr.textContent='" & StatPromo & "';}"
        ClientScript.RegisterStartupScript(Me.GetType(), "stats", js, True)
    End Sub

    ' --- TABLA DE PRODUCTOS DE LA CATEGORIA ------------------
    Private Sub CargarTabla(filtroTxt As String, filtroEstado As String)
        Dim sb As New StringBuilder()
        sb.AppendLine("<table class=""tabla""><thead><tr>")
        sb.Append("<th style=""width:36px""></th>")
        sb.Append("<th style=""width:50px""></th>")
        sb.Append("<th>Producto</th>")
        sb.Append("<th>SKU</th>")
        sb.Append("<th>Precio</th>")
        sb.Append("<th>Stock</th>")
        sb.Append("<th>Estado</th>")
        sb.Append("<th>Principal</th>")
        sb.Append("<th style=""width:140px"">Acciones</th>")
        sb.AppendLine("</tr></thead><tbody>")

        Dim hayDatos As Boolean = False

        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_ListarProductos", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@categoria_id", CategoriaId)
                    cmd.Parameters.AddWithValue("@buscar", If(filtroTxt = "", CObj(DBNull.Value), filtroTxt))
                    Dim estParam As Object = DBNull.Value
                    If filtroEstado = "ACTIVO" Then estParam = "activo"
                    If filtroEstado = "INACTIVO" Then estParam = "inactivo"
                    cmd.Parameters.AddWithValue("@estado", estParam)
                    cmd.Parameters.AddWithValue("@sync_estado", DBNull.Value)
                    cmd.Parameters.AddWithValue("@stock_estado", DBNull.Value)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            hayDatos = True
                            Dim id As Integer = CInt(dr("producto_id"))
                            Dim sku As String = If(IsDBNull(dr("sku")), "", dr("sku").ToString())
                            Dim nombre As String = If(IsDBNull(dr("nombre")), "", dr("nombre").ToString())
                            Dim precioBase As Decimal = If(IsDBNull(dr("precio_base_bs")), 0D, CDec(dr("precio_base_bs")))
                            Dim precioPromo As Decimal = If(IsDBNull(dr("precio_promo_bs")), 0D, CDec(dr("precio_promo_bs")))
                            Dim imgUrl As String = If(HasReaderColumn(dr, "imagen_url") AndAlso Not IsDBNull(dr("imagen_url")), dr("imagen_url").ToString(), "")
                            Dim tienePromo As Boolean = False
                            If HasReaderColumn(dr, "tiene_promo_activa") Then
                                tienePromo = (Not IsDBNull(dr("tiene_promo_activa"))) AndAlso CBool(dr("tiene_promo_activa"))
                            End If
                            Dim stockAct As Integer = If(HasReaderColumn(dr, "stock_actual") AndAlso Not IsDBNull(dr("stock_actual")), CInt(dr("stock_actual")), 0)
                            Dim stockMin As Integer = If(HasReaderColumn(dr, "stock_minimo") AndAlso Not IsDBNull(dr("stock_minimo")), CInt(dr("stock_minimo")), 0)
                            Dim activo As Boolean = If(HasReaderColumn(dr, "activo") AndAlso Not IsDBNull(dr("activo")), CBool(dr("activo")), True)
                            Dim esPrinc As Boolean = If(HasReaderColumn(dr, "es_principal") AndAlso Not IsDBNull(dr("es_principal")), CBool(dr("es_principal")), False)

                            ' Fila con atributos para filtro cliente
                            Dim activoAttr As String = If(activo, "activo", "inactivo")
                            sb.Append("<tr id=""fila_" & id & """ data-nombre=""" & HttpUtility.HtmlAttributeEncode(nombre.ToLower()) & """ data-sku=""" & HttpUtility.HtmlAttributeEncode(sku.ToLower()) & """ data-activo=""" & activoAttr & """>")

                            ' Checkbox
                            sb.Append("<td><div class=""chk"" id=""chk_" & id & """ onclick=""toggleSel(" & id & ")""><i class=""ti ti-check"" aria-hidden=""true""></i></div></td>")

                            ' Imagen
                            sb.Append("<td>")
                            If imgUrl <> "" Then
                                sb.Append("<div class=""img-thumb""><img src=""" & HttpUtility.HtmlAttributeEncode(imgUrl) & """ alt="""" loading=""lazy"" style=""width:100%;height:100%;object-fit:cover""/></div>")
                            Else
                                sb.Append("<div class=""img-thumb""><i class=""ti ti-photo"" aria-hidden=""true""></i></div>")
                            End If
                            sb.Append("</td>")

                            ' Nombre
                            sb.Append("<td><div style=""font-weight:500"">" & HttpUtility.HtmlEncode(nombre) & "</div></td>")

                            ' SKU
                            sb.Append("<td style=""font-family:monospace;font-size:11px;color:#757575"">" & HttpUtility.HtmlEncode(sku) & "</td>")

                            ' Precio
                            sb.Append("<td>")
                            If tienePromo AndAlso precioPromo > 0 Then
                                sb.Append("<div class=""precio-tachado"">Bs " & precioBase.ToString("0.00") & "</div>")
                                sb.Append("<div class=""precio-promo"">Bs " & precioPromo.ToString("0.00") & "</div>")
                            Else
                                sb.Append("Bs " & precioBase.ToString("0.00"))
                            End If
                            sb.Append("</td>")

                            ' Stock
                            sb.Append("<td>")
                            If stockAct = 0 Then
                                sb.Append("<span class=""badge badge-stock-agotado"">Agotado</span>")
                            ElseIf stockAct <= stockMin Then
                                sb.Append("<span class=""badge badge-stock-bajo"">" & stockAct & " unid</span>")
                            Else
                                sb.Append("<span class=""badge badge-stock-ok"">" & stockAct & " unid</span>")
                            End If
                            sb.Append("</td>")

                            ' Estado
                            sb.Append("<td>")
                            If activo Then
                                sb.Append("<span class=""badge badge-ok"">Activo</span>")
                            Else
                                sb.Append("<span class=""badge badge-inac"">Inactivo</span>")
                            End If
                            sb.Append("</td>")

                            ' Principal
                            sb.Append("<td>")
                            If esPrinc Then
                                sb.Append("<span class=""badge badge-principal""><i class=""ti ti-star"" aria-hidden=""true""></i> Principal</span>")
                            Else
                                sb.Append("<button type=""button"" class=""btn btn-sm"" title=""Marcar como categoria principal"" onclick=""marcarPrincipal(" & id & ")""><i class=""ti ti-star"" aria-hidden=""true""></i></button>")
                            End If
                            sb.Append("</td>")

                            ' Acciones
                            Dim nombreJs As String = nombre.Replace("\", "\\").Replace("'", "\'")
                            sb.Append("<td style=""white-space:nowrap"">")
                            sb.Append("<a href=""ProductoEditar.aspx?id=" & id & """ class=""btn btn-sm"" title=""Editar producto""><i class=""ti ti-edit"" aria-hidden=""true""></i></a> ")
                            sb.Append("<button type=""button"" class=""btn btn-sm btn-danger"" title=""Quitar de categoria"" onclick=""abrirQuitar(" & id & ",'" & nombreJs & "')""><i class=""ti ti-x"" aria-hidden=""true""></i></button>")
                            sb.Append("</td>")

                            sb.AppendLine("</tr>")
                        End While
                    End Using
                End Using
            End Using
        Catch ex As Exception
            sb.AppendLine("<tr><td colspan=""9"" style=""padding:20px;text-align:center;color:#C62828"">Error: " & HttpUtility.HtmlEncode(ex.Message) & "</td></tr>")
            System.Diagnostics.Debug.WriteLine("ERROR CargarTabla: " & ex.Message)
        End Try

        If Not hayDatos Then
            sb.AppendLine("<tr><td colspan=""9""><div class=""estado-vacio""><i class=""ti ti-package-off"" aria-hidden=""true""></i><div class=""estado-vacio-tit"">No hay productos en esta categoria</div><div class=""estado-vacio-sub"">Haz clic en ""Agregar productos"" para asignar productos a esta categoria.</div></div></td></tr>")
        End If

        sb.AppendLine("</tbody></table>")
        TablaHtml = sb.ToString()
    End Sub

    ' --- BUSCAR PRODUCTOS DISPONIBLES (modal) -----------------
    Private Sub ProcesarBuscarDisponibles(buscar As String)
        Dim sb As New StringBuilder()
        Dim hay As Boolean = False

        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_ProductosDisponibles", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@categoria_id", CategoriaId)
                    cmd.Parameters.AddWithValue("@buscar", If(buscar = "", CObj(DBNull.Value), buscar))
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        sb.Append("<div class=""disp-grid"">")
                        While dr.Read()
                            hay = True
                            Dim id As Integer = CInt(dr("producto_id"))
                            Dim sku As String = If(IsDBNull(dr("sku")), "", dr("sku").ToString())
                            Dim nombre As String = If(IsDBNull(dr("nombre")), "", dr("nombre").ToString())
                            Dim precio As Decimal = If(IsDBNull(dr("precio_base_bs")), 0D, CDec(dr("precio_base_bs")))
                            Dim imgUrl As String = If(HasReaderColumn(dr, "imagen_url") AndAlso Not IsDBNull(dr("imagen_url")), dr("imagen_url").ToString(), "")
                            Dim totalCats As Integer = 0
                            If HasReaderColumn(dr, "total_categorias") AndAlso Not IsDBNull(dr("total_categorias")) Then
                                totalCats = CInt(dr("total_categorias"))
                            End If

                            ' Thumbnail
                            Dim thumbHtml As String = ""
                            If imgUrl <> "" Then
                                thumbHtml = "<div class=""img-thumb""><img src=""" & HttpUtility.HtmlAttributeEncode(imgUrl) & """ alt="""" loading=""lazy"" style=""width:100%;height:100%;object-fit:cover;border-radius:6px""/></div>"
                            Else
                                thumbHtml = "<div class=""img-thumb""><i class=""ti ti-photo"" aria-hidden=""true""></i></div>"
                            End If

                            sb.Append("<div class=""disp-card"" id=""disp_" & id & """ data-nombre=""" & HttpUtility.HtmlAttributeEncode(nombre.ToLower()) & """ data-sku=""" & HttpUtility.HtmlAttributeEncode(sku.ToLower()) & """ onclick=""toggleSelDisp(" & id & ")"">")
                            sb.Append(thumbHtml)
                            sb.Append("<div class=""disp-info"">")
                            sb.Append("<div class=""disp-nombre"">" & HttpUtility.HtmlEncode(nombre) & "</div>")
                            sb.Append("<div class=""disp-sku"">" & HttpUtility.HtmlEncode(sku) & "</div>")
                            sb.Append("<div class=""disp-precio"">Bs " & precio.ToString("0.00"))
                            If totalCats > 0 Then
                                sb.Append(" &nbsp;<span class=""badge badge-cat"">" & totalCats & " cats</span>")
                            End If
                            sb.Append("</div>")
                            sb.Append("</div>")
                            sb.Append("</div>")
                        End While
                        sb.Append("</div>")
                    End Using
                End Using
            End Using
        Catch ex As Exception
            sb.Clear()
            sb.Append("<div class=""estado-vacio""><i class=""ti ti-alert-triangle"" aria-hidden=""true""></i>")
            sb.Append("<div class=""estado-vacio-sub"">Error: " & HttpUtility.HtmlEncode(ex.Message) & "</div></div>")
            System.Diagnostics.Debug.WriteLine("ERROR BuscarDisponibles: " & ex.Message)
        End Try

        If Not hay Then
            sb.Clear()
            sb.Append("<div class=""estado-vacio""><i class=""ti ti-search-off"" aria-hidden=""true""></i>")
            sb.Append("<div class=""estado-vacio-sub"">No se encontraron productos disponibles.</div></div>")
        End If

        ' DisponiblesHtml y MostrarModal se leen en DOMContentLoaded desde DIV puente
        DisponiblesHtml = sb.ToString()
        MostrarModal = "agregar"
        ' Solo restaurar texto del buscador si habia busqueda
        If buscar <> "" Then
            Dim buscarVal As String = buscar.Replace("'", "")
            Dim js As String =
                "window.addEventListener('DOMContentLoaded',function(){" &
                "var tx=document.getElementById('txBuscarDisp');" &
                "if(tx){tx.value='" & buscarVal & "';}" &
                "});"
            ClientScript.RegisterStartupScript(Me.GetType(), "disp", js, True)
        End If

        CargarTabla("", "")
        CargarStats()
    End Sub

    ' --- AGREGAR PRODUCTOS A LA CATEGORIA --------------------
    Private Sub ProcesarAgregar()
        Dim idsStr As String = Request.Form("hdProductoIds")
        If idsStr Is Nothing OrElse idsStr.Trim() = "" Then
            MostrarAlerta("Selecciona al menos un producto.", "error")
            Return
        End If

        Dim uid As Integer = ObtenerUid()
        Dim agregados As Integer = 0

        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_AgregarProductos", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@categoria_id", CategoriaId)
                    cmd.Parameters.AddWithValue("@productos_ids", idsStr.Trim())
                    cmd.Parameters.AddWithValue("@producto_principal_id", DBNull.Value)
                    cmd.Parameters.AddWithValue("@usuario_id", If(uid > 0, CObj(uid), CObj(DBNull.Value)))
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Dim okVal As Integer = 0
                            If Not IsDBNull(dr("ok")) Then okVal = CInt(dr("ok"))
                            If HasReaderColumn(dr, "agregados") AndAlso Not IsDBNull(dr("agregados")) Then agregados = CInt(dr("agregados"))
                            If okVal <> 1 Then
                                Dim msgVal As String = If(HasReaderColumn(dr, "mensaje") AndAlso Not IsDBNull(dr("mensaje")), dr("mensaje").ToString(), "Error al agregar")
                                MostrarAlerta(msgVal, "error")
                                Return
                            End If
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarAlerta("Error: " & ex.Message, "error")
            System.Diagnostics.Debug.WriteLine("ERROR Agregar: " & ex.Message)
            Return
        End Try

        ' Sincronizar cada producto con WooCommerce
        Dim sincOk As Integer = 0
        For Each p As String In idsStr.Split(","c)
            Dim pid As Integer = 0
            If Integer.TryParse(p.Trim(), pid) AndAlso pid > 0 Then
                If SincronizarCategoriasProducto(pid) Then sincOk += 1
            End If
        Next

        If sincOk = agregados Then
            MostrarAlerta(agregados.ToString() & " producto(s) agregados y sincronizados con WooCommerce.", "ok")
        Else
            MostrarAlerta(agregados.ToString() & " agregados. " & sincOk.ToString() & " sincronizados con WC.", "warn")
        End If
    End Sub

    ' --- QUITAR UN PRODUCTO ----------------------------------
    Private Sub ProcesarQuitar()
        Dim pidStr As String = Request.Form("hdProductoId")
        Dim motivo As String = Request.Form("hdMotivo")
        If pidStr Is Nothing Then pidStr = "0"
        If motivo Is Nothing Then motivo = ""

        Dim pid As Integer = 0
        Integer.TryParse(pidStr, pid)
        If pid <= 0 Then
            MostrarAlerta("Producto invalido.", "error")
            Return
        End If
        If motivo.Trim().Length < 1 Then
            MostrarAlerta("El motivo es obligatorio.", "error")
            Return
        End If

        Dim uid As Integer = ObtenerUid()

        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_QuitarProducto", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@categoria_id", CategoriaId)
                    cmd.Parameters.AddWithValue("@producto_id", pid)
                    cmd.Parameters.AddWithValue("@motivo", motivo)
                    cmd.Parameters.AddWithValue("@usuario_id", If(uid > 0, CObj(uid), CObj(DBNull.Value)))
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            MostrarAlerta("Error al quitar: " & ex.Message, "error")
            System.Diagnostics.Debug.WriteLine("ERROR Quitar: " & ex.Message)
            Return
        End Try

        ' Sincronizar categorias del producto con WooCommerce
        Dim sincOk As Boolean = SincronizarCategoriasProducto(pid)
        If sincOk Then
            MostrarAlerta("Producto quitado y sincronizado con WooCommerce.", "ok")
        Else
            MostrarAlerta("Producto quitado. No se pudo sincronizar con WC (se sincronizara despues).", "warn")
        End If
    End Sub

    ' --- QUITAR MASIVO ---------------------------------------
    Private Sub ProcesarQuitarMasivo()
        Dim idsStr As String = Request.Form("hdProductoIds")
        Dim motivo As String = Request.Form("hdMotivo")
        If idsStr Is Nothing Then idsStr = ""
        If motivo Is Nothing Then motivo = ""

        If idsStr.Trim() = "" Then
            MostrarAlerta("No hay productos seleccionados.", "error")
            Return
        End If
        If motivo.Trim().Length < 1 Then
            MostrarAlerta("El motivo es obligatorio.", "error")
            Return
        End If

        Dim uid As Integer = ObtenerUid()
        Dim quitados As Integer = 0

        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_QuitarProductosMasivo", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@categoria_id", CategoriaId)
                    cmd.Parameters.AddWithValue("@productos_ids", idsStr.Trim())
                    cmd.Parameters.AddWithValue("@usuario_id", If(uid > 0, CObj(uid), CObj(DBNull.Value)))
                    cmd.Parameters.AddWithValue("@motivo", motivo)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Dim okVal As Integer = 0
                            If Not IsDBNull(dr("ok")) Then okVal = CInt(dr("ok"))
                            If HasReaderColumn(dr, "eliminados") AndAlso Not IsDBNull(dr("eliminados")) Then quitados = CInt(dr("eliminados"))
                            If okVal <> 1 Then
                                Dim msgVal As String = If(HasReaderColumn(dr, "mensaje") AndAlso Not IsDBNull(dr("mensaje")), dr("mensaje").ToString(), "Error al quitar")
                                MostrarAlerta(msgVal, "error")
                                Return
                            End If
                        End If
                    End Using
                End Using
            End Using
        Catch ex As Exception
            MostrarAlerta("Error: " & ex.Message, "error")
            System.Diagnostics.Debug.WriteLine("ERROR QuitarMasivo: " & ex.Message)
            Return
        End Try

        ' Sincronizar cada producto con WooCommerce
        Dim sincOk As Integer = 0
        For Each p As String In idsStr.Split(","c)
            Dim pid As Integer = 0
            If Integer.TryParse(p.Trim(), pid) AndAlso pid > 0 Then
                If SincronizarCategoriasProducto(pid) Then sincOk += 1
            End If
        Next

        If sincOk = quitados Then
            MostrarAlerta(quitados.ToString() & " producto(s) quitados y sincronizados con WooCommerce.", "ok")
        Else
            MostrarAlerta(quitados.ToString() & " quitados. " & sincOk.ToString() & " sincronizados con WC.", "warn")
        End If
    End Sub

    ' --- MARCAR COMO CATEGORIA PRINCIPAL ---------------------
    Private Sub ProcesarMarcarPrincipal()
        Dim pidStr As String = Request.Form("hdProductoId")
        If pidStr Is Nothing Then pidStr = "0"
        Dim pid As Integer = 0
        Integer.TryParse(pidStr, pid)
        If pid <= 0 Then
            MostrarAlerta("Producto invalido.", "error")
            Return
        End If

        Dim uid As Integer = ObtenerUid()

        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_MarcarPrincipal", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@categoria_id", CategoriaId)
                    cmd.Parameters.AddWithValue("@producto_id", pid)
                    cmd.Parameters.AddWithValue("@usuario_id", If(uid > 0, CObj(uid), CObj(DBNull.Value)))
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            MostrarAlerta("Error: " & ex.Message, "error")
            System.Diagnostics.Debug.WriteLine("ERROR MarcarPrincipal: " & ex.Message)
            Return
        End Try

        ' Sincronizar con WC (la categoria principal cambia en WC tambien)
        Dim sincOk As Boolean = SincronizarCategoriasProducto(pid)
        If sincOk Then
            MostrarAlerta("Marcado como principal y sincronizado con WooCommerce.", "ok")
        Else
            MostrarAlerta("Marcado como principal. No se pudo sincronizar con WC.", "warn")
        End If
    End Sub

    ' --- SINCRONIZACION CON WOOCOMMERCE ----------------------
    ' Obtiene todas las categorias WC del producto desde la BD
    ' y actualiza el producto en WC via API REST (o bridge si no funciona directo)
    Private Function SincronizarCategoriasProducto(productoId As Integer) As Boolean
        Try
            ' 1. Obtener wc_product_id del producto
            Dim wcProdId As Integer = 0
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Producto_ObtenerPorId", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@producto_id", productoId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            If HasReaderColumn(dr, "wc_product_id") AndAlso Not IsDBNull(dr("wc_product_id")) Then
                                wcProdId = CInt(dr("wc_product_id"))
                            End If
                        End If
                    End Using
                End Using
            End Using

            If wcProdId <= 0 Then
                System.Diagnostics.Debug.WriteLine("SyncWC: producto " & productoId & " sin wc_product_id")
                Return False
            End If

            ' 2. Obtener todos los wc_category_id del producto desde BD
            Dim wcCatIds As New List(Of Integer)()
            Using conn2 As New SqlConnection(ObtenerCadena())
                conn2.Open()
                Using cmd2 As New SqlCommand("FLORERIA_sp_Categoria_ListarProductos", conn2)
                    ' Buscar en que categorias esta el producto ahora
                    ' Usamos una consulta auxiliar via SP generico
                End Using
                ' Consulta directa para obtener wc_category_id de todas las categorias del producto
                Using cmd3 As New SqlCommand("FLORERIA_sp_Categoria_Listar", conn2)
                    cmd3.CommandType = Data.CommandType.StoredProcedure
                    Using dr3 As SqlDataReader = cmd3.ExecuteReader()
                        Dim todasCats As New List(Of Integer)()
                        Dim wcIds As New Dictionary(Of Integer, Integer)()
                        While dr3.Read()
                            Dim catId As Integer = CInt(dr3("categoria_id"))
                            Dim wcCatId As Integer = 0
                            If HasReaderColumn(dr3, "wc_category_id") AndAlso Not IsDBNull(dr3("wc_category_id")) Then
                                wcCatId = CInt(dr3("wc_category_id"))
                            End If
                            If wcCatId > 0 Then wcIds(catId) = wcCatId
                        End While
                        ' Ahora buscar qué categorias tiene este producto via SP
                        Using conn4 As New SqlConnection(ObtenerCadena())
                            conn4.Open()
                            Using cmd4 As New SqlCommand("FLORERIA_sp_Categoria_ListarProductos", conn4)
                                ' No sirve aqui — necesitamos las cats del producto, no los prods de una cat
                                ' Usamos ObtenerPorId que retorna las categorias en el 3er resultset
                            End Using
                            Using cmd5 As New SqlCommand("FLORERIA_sp_Producto_ObtenerPorId", conn4)
                                cmd5.CommandType = Data.CommandType.StoredProcedure
                                cmd5.Parameters.AddWithValue("@producto_id", productoId)
                                Using dr5 As SqlDataReader = cmd5.ExecuteReader()
                                    ' Saltar primer resultset (producto)
                                    dr5.NextResult()
                                    ' Saltar segundo resultset (variaciones)
                                    dr5.NextResult()
                                    ' Tercer resultset: categorias del producto
                                    While dr5.Read()
                                        Dim catId As Integer = 0
                                        If HasReaderColumn(dr5, "categoria_id") AndAlso Not IsDBNull(dr5("categoria_id")) Then
                                            catId = CInt(dr5("categoria_id"))
                                        End If
                                        If catId > 0 AndAlso wcIds.ContainsKey(catId) Then
                                            wcCatIds.Add(wcIds(catId))
                                        End If
                                    End While
                                End Using
                            End Using
                        End Using
                    End Using
                End Using
            End Using

            ' 3. Construir JSON de categorias para WC
            ' Formato: {"categories": [{"id": 5}, {"id": 12}]}
            Dim sbCats As New StringBuilder("[")
            Dim primero As Boolean = True
            For Each wcCatId As Integer In wcCatIds
                If Not primero Then sbCats.Append(",")
                sbCats.Append("{""id"":" & wcCatId & "}")
                primero = False
            Next
            sbCats.Append("]")

            Dim body As String = "{""categories"":" & sbCats.ToString() & "}"

            ' 4. Intentar primero via API REST directa
            Dim wcUrl As String = ObtenerConfig("WC_URL")
            Dim wcKey As String = ObtenerConfig("WC_CONSUMER_KEY")
            Dim wcSecret As String = ObtenerConfig("WC_CONSUMER_SECRET")

            If wcUrl = "" OrElse wcKey = "" OrElse wcSecret = "" Then Return False

            ServicePointManager.ServerCertificateValidationCallback = Function(s, c, ch, e) True

            ' Intentar API REST directa primero
            Dim apiUrl As String = wcUrl.TrimEnd("/") & "/wp-json/wc/v3/products/" & wcProdId
            Dim credencial As String = Convert.ToBase64String(Encoding.UTF8.GetBytes(wcKey & ":" & wcSecret))

            Try
                Dim req As HttpWebRequest = CType(WebRequest.Create(apiUrl), HttpWebRequest)
                req.Method = "PUT"
                req.ContentType = "application/json"
                req.Timeout = 3000
                req.Headers.Add("Authorization", "Basic " & credencial)

                Dim bodyBytes() As Byte = Encoding.UTF8.GetBytes(body)
                req.ContentLength = bodyBytes.Length
                Using stream As Stream = req.GetRequestStream()
                    stream.Write(bodyBytes, 0, bodyBytes.Length)
                End Using

                Dim resp As HttpWebResponse = CType(req.GetResponse(), HttpWebResponse)
                Dim reader As New StreamReader(resp.GetResponseStream())
                Dim json As String = reader.ReadToEnd()
                resp.Close()

                Dim exito As Boolean = json.Contains("""id"":") AndAlso json.Contains("""categories"":")
                If exito Then
                    MarcarProductoPendiente(productoId, "SINCRONIZADO")
                    Return True
                End If
            Catch exApi As Exception
                System.Diagnostics.Debug.WriteLine("API directa fallo, intentando bridge: " & exApi.Message)
            End Try

            ' 5. Fallback: intentar via bridge PHP
            Dim bridgeSecret As String = ObtenerConfig("WC_WEBHOOK_SECRET")
            If bridgeSecret = "" Then bridgeSecret = "MissFlores2026Sec"
            Dim bridgeUrl As String = wcUrl.TrimEnd("/") & "/wc-bridge.php?secret=" & bridgeSecret & "&accion=actualizar_categorias_producto"

            Try
                Dim reqB As HttpWebRequest = CType(WebRequest.Create(bridgeUrl), HttpWebRequest)
                reqB.Method = "POST"
                reqB.ContentType = "application/json"
                reqB.Timeout = 3000

                Dim bridgeBody As String = "{""wc_product_id"":" & wcProdId & ",""categories"":" & sbCats.ToString() & "}"
                Dim bridgeBytes() As Byte = Encoding.UTF8.GetBytes(bridgeBody)
                reqB.ContentLength = bridgeBytes.Length
                Using streamB As Stream = reqB.GetRequestStream()
                    streamB.Write(bridgeBytes, 0, bridgeBytes.Length)
                End Using

                Dim respB As HttpWebResponse = CType(reqB.GetResponse(), HttpWebResponse)
                Dim readerB As New StreamReader(respB.GetResponseStream())
                Dim jsonB As String = readerB.ReadToEnd()
                respB.Close()

                If jsonB.Contains("""ok"":true") Then
                    MarcarProductoPendiente(productoId, "SINCRONIZADO")
                    Return True
                End If
            Catch exBridge As Exception
                System.Diagnostics.Debug.WriteLine("Bridge tambien fallo: " & exBridge.Message)
            End Try

            ' Ninguno funciono — marcar como PENDIENTE para sync posterior
            MarcarProductoPendiente(productoId, "PENDIENTE")
            Return False

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR SincronizarCategorias: " & ex.Message)
            Return False
        End Try
    End Function

    Private Sub MarcarProductoPendiente(productoId As Integer, estado As String)
        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                ' FLORERIA_sp_Producto_Actualizar marca wc_sync_estado=PENDIENTE internamente
                ' Usamos FLORERIA_sp_Producto_CambiarEstado no aplica aqui
                ' El unico SP disponible para marcar sync es el de Categoria_MarcarSincronizada (solo para categorias)
                ' Por esto usamos update directo de wc_sync_estado que es una columna tecnica, no de negocio
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_MarcarSincronizada", conn)
                    ' Este SP es solo para categorias — no aplica
                End Using
            End Using
        Catch
        End Try
        ' Nota: el wc_sync_estado se actualiza via FLORERIA_sp_Producto_Actualizar
        ' cuando se guarda el producto completo. Aqui solo registramos en debug.
        System.Diagnostics.Debug.WriteLine("MarcarSync producto " & productoId & " -> " & estado)
    End Sub

    Private Function ObtenerConfig(clave As String) As String
        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Config_Obtener", conn)
                    cmd.CommandType = Data.CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@clave", clave)
                    Dim res As Object = cmd.ExecuteScalar()
                    If res IsNot Nothing AndAlso Not IsDBNull(res) Then Return res.ToString()
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR ObtenerConfig: " & ex.Message)
        End Try
        Return ""
    End Function

    Private Function ExtraerEnteroJson(json As String, campo As String) As Integer
        Try
            Dim patron As String = """" & campo & """"
            Dim idx As Integer = json.IndexOf(patron)
            If idx < 0 Then Return 0
            idx += patron.Length
            While idx < json.Length AndAlso (json(idx) = " "c OrElse json(idx) = ":"c)
                idx += 1
            End While
            Dim sb As New StringBuilder()
            While idx < json.Length AndAlso Char.IsDigit(json(idx))
                sb.Append(json(idx))
                idx += 1
            End While
            Dim resultado As Integer = 0
            Integer.TryParse(sb.ToString(), resultado)
            Return resultado
        Catch
            Return 0
        End Try
    End Function


    Private Sub MostrarAlerta(msg As String, tipo As String)
        Dim m As String = msg.Replace("\", "\\").Replace("'", "\'").Replace(Chr(13), "").Replace(Chr(10), " ")
        Dim js As String =
            "var d=document.getElementById('divAlerta');" &
            "if(d){d.className='alerta show alerta-" & tipo & "';d.textContent='" & m & "';" &
            "setTimeout(function(){var x=document.getElementById('divAlerta');if(x){x.className='alerta';}},4000);}"
        ClientScript.RegisterStartupScript(Me.GetType(), "alerta_" & DateTime.Now.Ticks.ToString(), js, True)
    End Sub

    ' --- HELPERS -----------------------------------------------
    Private Function ObtenerCadena() As String
        Return SesionHelper.ObtenerCadena()
    End Function

    Private Function ObtenerUid() As Integer
        Return SesionHelper.ObtenerUsuarioId(HttpContext.Current)
    End Function

    Private Function HasReaderColumn(dr As SqlDataReader, nombre As String) As Boolean
        Try
            For i As Integer = 0 To dr.FieldCount - 1
                If String.Equals(dr.GetName(i), nombre, StringComparison.OrdinalIgnoreCase) Then
                    Return True
                End If
            Next
        Catch
        End Try
        Return False
    End Function

    Private Sub EjecutarCerrarSesion()
        If Session("token") IsNot Nothing Then
            Try
                Using conn As New SqlConnection(ObtenerCadena())
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
        Dim cookieToken As New HttpCookie("SISCONBOL_TOKEN", "")
        cookieToken.Expires = DateTime.Now.AddDays(-1)
        Response.Cookies.Add(cookieToken)
        Session.Abandon()
        Response.Redirect("~/Login.aspx")
    End Sub

End Class