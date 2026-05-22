Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

Partial Public Class Modulos_Catalogo_Productos
    Inherits System.Web.UI.Page

    Public Property TablaHtml As String = ""
    Public Property ScriptOnLoad As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            CargarTablaProductos()
        End If
    End Sub

    Private Function ObtenerCadena() As String
        Return SesionHelper.ObtenerCadena()
    End Function

    Private Function Limpiar(v As String) As String
        If v Is Nothing Then Return ""
        Return v.Trim().Replace("<", "").Replace(">", "").Replace("'", "").Replace("""", "")
    End Function

    Private Sub CargarTablaProductos()
        Dim sb As New StringBuilder()
        Dim lista As New List(Of Dictionary(Of String, Object))()

        Try
            Using conn As New SqlConnection(ObtenerCadena())
                conn.Open()

                Dim buscar As String = Request.QueryString("b")
                If buscar Is Nothing Then buscar = ""
                buscar = buscar.Trim()

                Dim activo As Object = DBNull.Value
                Dim activoStr As String = Request.QueryString("activo")
                If activoStr = "1" Then
                    activo = 1
                ElseIf activoStr = "0" Then
                    activo = 0
                End If

                Dim syncEstadoFiltro As String = Request.QueryString("sync")
                If syncEstadoFiltro Is Nothing Then syncEstadoFiltro = ""

                Using cmd As New SqlCommand("FLORERIA_sp_Producto_Listar", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@buscar", If(buscar = "", CObj(DBNull.Value), buscar))
                    cmd.Parameters.AddWithValue("@categoria_id", DBNull.Value)
                    cmd.Parameters.AddWithValue("@activo", activo)
                    cmd.Parameters.AddWithValue("@wc_sync_estado", If(syncEstadoFiltro = "", CObj(DBNull.Value), syncEstadoFiltro))
                    cmd.Parameters.AddWithValue("@pagina", 1)
                    cmd.Parameters.AddWithValue("@por_pagina", 100)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim fila As New Dictionary(Of String, Object)()
                            fila("producto_id") = dr("producto_id")
                            fila("nombre") = dr("nombre").ToString()
                            fila("precio_base_bs") = dr("precio_base_bs")
                            fila("activo") = dr("activo")
                            fila("imagen_url") = If(IsDBNull(dr("imagen_url")), "", dr("imagen_url").ToString())
                            fila("wc_sync_estado") = If(IsDBNull(dr("wc_sync_estado")), "PENDIENTE", dr("wc_sync_estado").ToString())
                            lista.Add(fila)
                        End While
                    End Using
                End Using
            End Using

            If lista.Count = 0 Then
                TablaHtml = "<tr><td colspan=""6"" style=""text-align:center;padding:40px;color:#9e9e9e"">No se encontraron productos</td></tr>"
                Return
            End If

            For Each fila As Dictionary(Of String, Object) In lista
                Dim productoId As Integer = CInt(fila("producto_id"))
                Dim nombre As String = fila("nombre").ToString()
                Dim precio As Decimal = CDec(fila("precio_base_bs"))
                Dim activoVal As Boolean = CBool(fila("activo"))
                Dim imgUrl As String = fila("imagen_url").ToString()
                Dim syncEstado As String = fila("wc_sync_estado").ToString()

                sb.Append("<tr onclick=""abrirFormEditar(" & productoId & ")"">")

                sb.Append("<td>")
                If imgUrl <> "" Then
                    sb.Append("<img src=""" & imgUrl & """ alt=""Imagen"" style=""width:40px;height:40px;object-fit:cover;border-radius:4px""/>")
                Else
                    sb.Append("<i class=""ti ti-photo"" style=""font-size:24px;color:#bdbdbd""></i>")
                End If
                sb.Append("</td>")

                sb.Append("<td><strong>" & nombre & "</strong></td>")

                sb.Append("<td>Bs " & precio.ToString("N2") & "</td>")

                sb.Append("<td>")
                If activoVal Then
                    sb.Append("<span class=""badge badge-success"">Activo</span>")
                Else
                    sb.Append("<span class=""badge badge-secondary"">Inactivo</span>")
                End If
                sb.Append("</td>")

                Dim badgeSync As String = ""
                Dim textoSync As String = syncEstado

                Select Case syncEstado.ToUpper()
                    Case "SINCRONIZADO"
                        badgeSync = "badge-sync-ok"
                        textoSync = "Sincronizado"
                    Case "PENDIENTE"
                        badgeSync = "badge-sync-pend"
                        textoSync = "Pendiente"
                    Case "ERROR"
                        badgeSync = "badge-sync-error"
                        textoSync = "Error"
                    Case Else
                        badgeSync = "badge-sync-none"
                        textoSync = "Sin sync"
                End Select

                sb.Append("<td><span class=""badge " & badgeSync & """>" & textoSync & "</span></td>")

                sb.Append("<td class=""td-actions"">")
                sb.Append("<button class=""btn btn-sm"" onclick=""abrirFormEditar(" & productoId & ");event.stopPropagation()"">")
                sb.Append("<i class=""ti ti-edit""></i>")
                sb.Append("</button>")
                sb.Append("</td>")

                sb.Append("</tr>")
            Next

            TablaHtml = sb.ToString()

        Catch ex As Exception
            TablaHtml = "<tr><td colspan=""6"" style=""text-align:center;padding:40px;color:#E53935"">Error: " & ex.Message & "</td></tr>"
            System.Diagnostics.Debug.WriteLine("ERROR CargarTablaProductos: " & ex.Message)
        End Try
    End Sub

End Class
