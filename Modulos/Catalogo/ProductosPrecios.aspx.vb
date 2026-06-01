Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

Partial Public Class Modulos_Catalogo_ProductosPrecios
    Inherits System.Web.UI.Page

    Public Property TablaHtml As String = ""
    Public Property CategoriasOptionsHtml As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            CargarCategorias()
            CargarTablaProductos()
        End If
    End Sub

    Private Function ObtenerCadena() As String
        Return SesionHelper.ObtenerCadena()
    End Function

    ' ============================================================
    ' DROPDOWN DE CATEGORIAS (jerarquico, con indentacion)
    ' ============================================================
    Private Sub CargarCategorias()
        Dim sb As New StringBuilder()
        sb.Append("<option value="""">Todas las categorias</option>")

        Dim catSeleccionada As String = Request.QueryString("cat")
        If catSeleccionada Is Nothing Then catSeleccionada = ""

        Try
            ' Estructura: categoria_id, padre_id, nombre
            Dim todas As New List(Of Dictionary(Of String, Object))()
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Categoria_Listar", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim fila As New Dictionary(Of String, Object)()
                            fila("categoria_id") = CInt(dr("categoria_id"))
                            fila("padre_id") = If(IsDBNull(dr("padre_id")), 0, CInt(dr("padre_id")))
                            fila("nombre") = dr("nombre").ToString()
                            fila("activo") = If(IsDBNull(dr("activo")), True, CBool(dr("activo")))
                            todas.Add(fila)
                        End While
                    End Using
                End Using
            End Using

            ' Renderizar jerarquia: primero raices, luego hijos (1 nivel de identacion por nivel)
            RenderCatRecursivo(sb, todas, 0, 0, catSeleccionada)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR CargarCategorias: " & ex.Message)
        End Try

        CategoriasOptionsHtml = sb.ToString()
    End Sub

    Private Sub RenderCatRecursivo(sb As StringBuilder,
                                   todas As List(Of Dictionary(Of String, Object)),
                                   padreId As Integer,
                                   nivel As Integer,
                                   seleccionada As String)
        For Each c As Dictionary(Of String, Object) In todas
            If CInt(c("padre_id")) <> padreId Then Continue For
            Dim catId As Integer = CInt(c("categoria_id"))
            Dim activo As Boolean = CBool(c("activo"))
            Dim prefijo As String = New String("-"c, nivel * 2)
            If nivel > 0 Then prefijo &= " "
            Dim sel As String = ""
            If seleccionada = catId.ToString() Then sel = " selected"
            Dim nombre As String = c("nombre").ToString()
            If Not activo Then nombre &= " (inactiva)"
            sb.Append("<option value=""" & catId & """" & sel & ">" & prefijo & nombre & "</option>")
            RenderCatRecursivo(sb, todas, catId, nivel + 1, seleccionada)
        Next
    End Sub

    ' ============================================================
    ' TABLA DE PRODUCTOS
    ' ============================================================
    Private Sub CargarTablaProductos()
        Dim sb As New StringBuilder()
        Dim lista As New List(Of Dictionary(Of String, Object))()

        Try
            ' Leer filtros
            Dim buscar As String = Request.QueryString("b")
            If buscar Is Nothing Then buscar = ""
            buscar = buscar.Trim()

            Dim catStr As String = Request.QueryString("cat")
            If catStr Is Nothing Then catStr = ""
            Dim categoriaId As Object = DBNull.Value
            Dim catNum As Integer = 0
            If catStr <> "" AndAlso Integer.TryParse(catStr, catNum) AndAlso catNum > 0 Then
                categoriaId = catNum
            End If

            Dim activoStr As String = Request.QueryString("activo")
            If activoStr Is Nothing Then activoStr = "1"  ' default = solo activos
            Dim activo As Object = DBNull.Value
            If activoStr = "1" Then
                activo = 1
            ElseIf activoStr = "0" Then
                activo = 0
            End If

            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Producto_Listar", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@buscar", If(buscar = "", CObj(DBNull.Value), CObj(buscar)))
                    cmd.Parameters.AddWithValue("@categoria_id", categoriaId)
                    cmd.Parameters.AddWithValue("@activo", activo)
                    cmd.Parameters.AddWithValue("@wc_sync_estado", DBNull.Value)
                    cmd.Parameters.AddWithValue("@pagina", 1)
                    cmd.Parameters.AddWithValue("@por_pagina", 500) ' edicion masiva = mas filas

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim fila As New Dictionary(Of String, Object)()
                            fila("producto_id") = CInt(dr("producto_id"))
                            fila("nombre") = dr("nombre").ToString()
                            fila("precio_base_bs") = CDec(dr("precio_base_bs"))
                            fila("activo") = CBool(dr("activo"))
                            fila("imagen_url") = If(IsDBNull(dr("imagen_url")), "", dr("imagen_url").ToString())
                            fila("wc_sync_estado") = If(IsDBNull(dr("wc_sync_estado")), "PENDIENTE", dr("wc_sync_estado").ToString())
                            fila("wc_product_id") = If(IsDBNull(dr("wc_product_id")), 0, CInt(dr("wc_product_id")))
                            fila("categoria_nombre") = If(IsDBNull(dr("categoria_nombre")), "", dr("categoria_nombre").ToString())
                            lista.Add(fila)
                        End While
                    End Using
                End Using
            End Using

            If lista.Count = 0 Then
                TablaHtml = "<tr><td colspan=""7"" style=""text-align:center;padding:40px;color:#9e9e9e"">No se encontraron productos con los filtros aplicados.</td></tr>"
                Return
            End If

            For Each fila As Dictionary(Of String, Object) In lista
                Dim pid As Integer = CInt(fila("producto_id"))
                Dim nombre As String = fila("nombre").ToString()
                Dim precio As Decimal = CDec(fila("precio_base_bs"))
                Dim activoVal As Boolean = CBool(fila("activo"))
                Dim imgUrl As String = fila("imagen_url").ToString()
                Dim syncEstado As String = fila("wc_sync_estado").ToString()
                Dim wcProdId As Integer = CInt(fila("wc_product_id"))
                Dim catNombre As String = fila("categoria_nombre").ToString()

                Dim nombreEsc As String = EscaparHtml(nombre)
                Dim catEsc As String = EscaparHtml(catNombre)
                Dim nombreAttr As String = EscaparAttr(nombre)

                sb.Append("<tr>")

                ' Imagen
                sb.Append("<td>")
                If imgUrl <> "" Then
                    sb.Append("<img src=""" & EscaparAttr(imgUrl) & """ alt="""" style=""width:36px;height:36px;object-fit:cover;border-radius:4px""/>")
                Else
                    sb.Append("<i class=""ti ti-photo"" style=""font-size:22px;color:#bdbdbd""></i>")
                End If
                sb.Append("</td>")

                ' Nombre + mensaje de error inline
                sb.Append("<td><strong>" & nombreEsc & "</strong>")
                sb.Append("<div class=""fila-error-msg"" id=""err_" & pid & """></div>")
                sb.Append("</td>")

                ' Categoria
                sb.Append("<td>" & catEsc & "</td>")

                ' Estado
                sb.Append("<td style=""text-align:center"">")
                If activoVal Then
                    sb.Append("<span class=""badge badge-success badge-pequeno"">Activo</span>")
                Else
                    sb.Append("<span class=""badge badge-secondary badge-pequeno"">Inactivo</span>")
                End If
                sb.Append("</td>")

                ' Precio actual
                sb.Append("<td style=""text-align:right"" id=""actual_" & pid & """>Bs " & precio.ToString("N2") & "</td>")

                ' Nuevo precio (input)
                sb.Append("<td style=""text-align:right"">")
                sb.Append("<input type=""number"" step=""0.01"" min=""0.01"" max=""999999"" ")
                sb.Append("class=""form-control input-precio"" ")
                sb.Append("value=""" & precio.ToString("F2", System.Globalization.CultureInfo.InvariantCulture) & """ ")
                sb.Append("data-pid=""" & pid & """ ")
                sb.Append("data-nombre=""" & nombreAttr & """ ")
                sb.Append("data-precio-actual=""" & precio.ToString("F2", System.Globalization.CultureInfo.InvariantCulture) & """ ")
                If wcProdId <= 0 Then
                    sb.Append("disabled title=""Sin wc_product_id - no se puede sincronizar"" ")
                End If
                sb.Append("/>")
                sb.Append("</td>")

                ' WC sync badge
                sb.Append("<td id=""sync_" & pid & """>")
                If wcProdId <= 0 Then
                    sb.Append("<span class=""badge badge-sync-none badge-pequeno"">Sin WC ID</span>")
                Else
                    Dim badgeClass As String = ""
                    Dim badgeTxt As String = ""
                    Select Case syncEstado.ToUpper()
                        Case "SINCRONIZADO"
                            badgeClass = "badge-sync-ok"
                            badgeTxt = "Sincronizado"
                        Case "PENDIENTE"
                            badgeClass = "badge-sync-pend"
                            badgeTxt = "Pendiente"
                        Case "ERROR"
                            badgeClass = "badge-sync-error"
                            badgeTxt = "Error"
                        Case Else
                            badgeClass = "badge-sync-none"
                            badgeTxt = syncEstado
                    End Select
                    sb.Append("<span class=""badge " & badgeClass & " badge-pequeno"">" & badgeTxt & "</span>")
                End If
                sb.Append("</td>")

                sb.Append("</tr>")
            Next

            TablaHtml = sb.ToString()

        Catch ex As Exception
            TablaHtml = "<tr><td colspan=""7"" style=""text-align:center;padding:40px;color:#E53935"">Error: " & EscaparHtml(ex.Message) & "</td></tr>"
            System.Diagnostics.Debug.WriteLine("ERROR CargarTablaProductos: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' HELPERS
    ' ============================================================
    Private Function EscaparHtml(s As String) As String
        If s Is Nothing Then Return ""
        Return s.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")
    End Function

    Private Function EscaparAttr(s As String) As String
        If s Is Nothing Then Return ""
        Return s.Replace("&", "&amp;").Replace("""", "&quot;").Replace("<", "&lt;").Replace(">", "&gt;")
    End Function

End Class
