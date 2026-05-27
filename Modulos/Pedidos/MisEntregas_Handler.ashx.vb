Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

' ============================================================
' SISCONBOL_FLORERIA - MisEntregas_Handler
' Renderiza filas de pedidos asignados al delivery logueado.
' SIN montos visibles. Muestra: slot, receptor, quien envia,
' productos, zona, estado, boton principal + menu opciones.
' ============================================================
Public Class MisEntregas_Handler
    Implements IHttpHandler, SessionState.IRequiresSessionState

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "text/html"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)

        If Not SesionHelper.VerificarSesion(context) Then
            context.Response.StatusCode = 401
            context.Response.Write("<tr><td colspan='5' class='table-empty'><i class='ti ti-lock'></i> Sesion expirada</td></tr>")
            Return
        End If

        ' ID del agente logueado — solo ve SUS pedidos
        Dim agentId As Integer = SesionHelper.ObtenerUsuarioId(context)
        If agentId = 0 Then
            context.Response.StatusCode = 401
            Return
        End If

        Try
            Dim buscar As String      = LeerQS(context, "b")
            Dim soloHoy As String     = LeerQS(context, "hoy")
            Dim feDesde As String     = LeerQS(context, "fed")
            Dim feHasta As String     = LeerQS(context, "feh")
            Dim estadoOp As String    = LeerQS(context, "op")

            Dim sb As New StringBuilder()
            Dim totalFilas As Integer = 0

            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Pedido_Listar", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@buscar",             IfBlanco(buscar))
                    cmd.Parameters.AddWithValue("@fecha_desde",        IfBlanco(feDesde))
                    cmd.Parameters.AddWithValue("@fecha_hasta",        IfBlanco(feHasta))
                    cmd.Parameters.AddWithValue("@solo_hoy",           If(soloHoy = "1", 1, 0))
                    cmd.Parameters.AddWithValue("@creado_desde",       DBNull.Value)
                    cmd.Parameters.AddWithValue("@creado_hasta",       DBNull.Value)
                    cmd.Parameters.AddWithValue("@estado_pago",        DBNull.Value)
                    cmd.Parameters.AddWithValue("@estado_operativo",   IfBlanco(estadoOp))
                    cmd.Parameters.AddWithValue("@zona_id",            DBNull.Value)
                    cmd.Parameters.AddWithValue("@delivery_id",        agentId)
                    cmd.Parameters.AddWithValue("@solo_express",       0)
                    cmd.Parameters.AddWithValue("@solo_sin_contactar", 0)
                    cmd.Parameters.AddWithValue("@solo_sin_delivery",  0)
                    cmd.Parameters.AddWithValue("@sucursal_prepara_id",DBNull.Value)
                    cmd.Parameters.AddWithValue("@solo_wc_pendiente",  0)
                    cmd.Parameters.AddWithValue("@pagina",             1)
                    cmd.Parameters.AddWithValue("@por_pagina",         200)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            totalFilas += 1
                            sb.Append(RenderFila(dr, context))
                        End While
                    End Using
                End Using
            End Using

            If totalFilas = 0 Then
                sb.Append("<tr><td colspan='5' class='table-empty'>")
                sb.Append("<i class='ti ti-clipboard-off'></i><br>")
                sb.Append("No tienes entregas con esos filtros.")
                sb.Append("</td></tr>")
            End If

            context.Response.Write("<!--TOTAL:" & totalFilas & "-->" & sb.ToString())

        Catch ex As Exception
            context.Response.Write("<tr><td colspan='5' class='table-empty'><i class='ti ti-alert-triangle'></i> Error: " & HE(ex.Message) & "</td></tr>")
        End Try
    End Sub

    ' ============================================================
    ' RENDER FILA
    ' ============================================================
    Private Function RenderFila(dr As SqlDataReader, context As HttpContext) As String
        Dim sb As New StringBuilder()

        ' Leer campos
        Dim pid         As Integer  = CInt(dr("pedido_id"))
        Dim codigo      As String   = LeerStr(dr, "codigo")
        Dim receptor    As String   = LeerStr(dr, "receptor_nombre")
        Dim celReceptor As String   = LimpiarCelular(LeerStr(dr, "receptor_celular"))
        Dim direccion   As String   = LeerStr(dr, "direccion")
        Dim gps         As String   = LeerStr(dr, "gps")
        Dim zona        As String   = LeerStr(dr, "zona_nombre")
        Dim fechaEnt    As DateTime = LeerFecha(dr, "fecha_entrega")
        Dim slotInicio  As String   = LeerHora(dr, "slot_hora_inicio")
        Dim slotFin     As String   = LeerHora(dr, "slot_hora_fin")
        Dim esExpress   As Boolean  = LeerBool(dr, "es_express")
        Dim estadoOp    As String   = LeerStr(dr, "estado_operativo")
        Dim estadoPago  As String   = LeerStr(dr, "estado_pago")

        ' Quien envia (comprador del pre-pedido)
        Dim clienteNombre    As String = LeerStr(dr, "cliente_nombre")
        Dim clienteApellidos As String = LeerStr(dr, "cliente_apellidos")
        Dim clienteCelular   As String = LimpiarCelular(LeerStr(dr, "cliente_celular"))
        Dim tienePrepedido   As Boolean = (LeerInt(dr, "tiene_prepedido") = 1)
        Dim clienteCompleto  As String = (clienteNombre & " " & clienteApellidos).Trim()

        ' Clase de fila
        Dim claseFila As String = "me-fila"
        If estadoOp = "ENTREGADO" OrElse estadoOp = "NO_ENTREGADO" Then
            claseFila &= " me-fila-dim"
        End If
        If esExpress Then claseFila &= " me-fila-express"

        ' Data attributes para contadores JS
        Dim fechaAttr As String = fechaEnt.ToString("yyyy-MM-dd")

        sb.Append("<tr class=""" & claseFila & """ ")
        sb.Append("data-estado=""" & HE(estadoOp) & """ ")
        sb.Append("data-fecha=""" & fechaAttr & """ ")
        sb.Append("onclick=""abrirDetalle(" & pid & ")"" style=""cursor:pointer"">")

        ' ---- COL 1: SLOT ----
        sb.Append("<td onclick=""event.stopPropagation()"">")
        If slotInicio <> "" Then
            sb.Append("<div class=""me-slot-h"">")
            sb.Append(slotInicio)
            If slotFin <> "" Then sb.Append("<span class=""me-slot-fin""> – " & slotFin & "</span>")
            sb.Append("</div>")
        Else
            sb.Append("<div class=""me-slot-h"">Sin slot</div>")
        End If
        sb.Append("<div class=""me-slot-fecha"">")
        sb.Append(fechaEnt.ToString("dd") & " " & MesCorto(fechaEnt) & " " & DiaSemana(fechaEnt))
        sb.Append("</div>")
        If esExpress Then
            sb.Append("<div style=""margin-top:4px""><span class=""me-exp-pill""><i class=""ti ti-bolt""></i> Express</span></div>")
        End If
        sb.Append("</td>")

        ' ---- COL 2: RECEPTOR + QUIEN ENVIA + PRODUCTOS ----
        sb.Append("<td>")

        ' Codigo
        sb.Append("<div style=""display:flex;align-items:center;gap:5px;flex-wrap:wrap"">")
        sb.Append("<span class=""me-cod"">" & HE(codigo) & "</span>")
        sb.Append("</div>")

        ' Receptor
        sb.Append("<div class=""me-receptor"">")
        sb.Append("<i class=""ti ti-user""></i> ")
        sb.Append(HE(receptor))
        sb.Append("</div>")
        If celReceptor <> "" Then
            sb.Append("<div class=""me-sub""><i class=""ti ti-device-mobile""></i> " & HE(LeerStr(dr, "receptor_celular")) & "</div>")
        End If
        If direccion <> "" Then
            sb.Append("<div class=""me-sub""><i class=""ti ti-map-pin""></i> " & HE(direccion) & "</div>")
        End If

        ' Quien envia
        If tienePrepedido AndAlso clienteCompleto <> "" Then
            sb.Append("<div class=""me-envia-blk"">")
            sb.Append("<span class=""me-envia-lbl""><i class=""ti ti-shopping-cart""></i> Envía</span>")
            sb.Append("<span class=""me-envia-nom"">")
            sb.Append(HE(clienteCompleto))
            If LeerStr(dr, "cliente_celular") <> "" Then
                sb.Append("<span class=""me-envia-cel""> · " & HE(LeerStr(dr, "cliente_celular")) & "</span>")
            End If
            sb.Append("</span>")
            sb.Append("</div>")
        End If

        ' Productos (subquery inline)
        Dim productos As String = ObtenerProductos(pid)
        If productos <> "" Then
            sb.Append("<div class=""me-prods"">")
            sb.Append(productos)
            sb.Append("</div>")
        End If

        sb.Append("</td>")

        ' ---- COL 3: ZONA ----
        sb.Append("<td>")
        sb.Append("<div class=""me-zona""><i class=""ti ti-map-pin""></i> " & HE(zona) & "</div>")
        sb.Append("</td>")

        ' ---- COL 4: ESTADO ----
        sb.Append("<td>")
        sb.Append(RenderBadgeEstado(estadoOp))
        sb.Append("</td>")

        ' ---- COL 5: BOTON PRINCIPAL + MENU ----
        sb.Append("<td style=""text-align:right"" onclick=""event.stopPropagation()"">")
        sb.Append("<div class=""me-acciones"">")

        ' Botón principal contextual según estado
        Select Case estadoOp
            Case "PENDIENTE", "IMPRESO", "EN_PREPARACION", "LISTO"
                sb.Append("<button type=""button"" class=""me-btn-estado me-btn-ruta"" ")
                sb.Append("onclick=""cambiarEstado(" & pid & ",'EN_RUTA')"">")
                sb.Append("<i class=""ti ti-truck-delivery""></i> En ruta")
                sb.Append("</button>")
            Case "EN_RUTA"
                sb.Append("<button type=""button"" class=""me-btn-estado me-btn-ok"" ")
                sb.Append("onclick=""cambiarEstado(" & pid & ",'ENTREGADO')"">")
                sb.Append("<i class=""ti ti-check""></i> Entregado")
                sb.Append("</button>")
            Case "NO_ENTREGADO"
                sb.Append("<button type=""button"" class=""me-btn-estado me-btn-rein"" ")
                sb.Append("onclick=""cambiarEstado(" & pid & ",'EN_RUTA')"">")
                sb.Append("<i class=""ti ti-refresh""></i> Reintentar")
                sb.Append("</button>")
        End Select

        ' Botón "..." menú opciones
        sb.Append("<div class=""me-dropdown"" id=""medd_" & pid & """>")
        sb.Append("<button type=""button"" class=""me-btn-mas"" ")
        sb.Append("onclick=""toggleMenuEntrega(" & pid & ",event)"" aria-label=""Más opciones"">")
        sb.Append("<i class=""ti ti-dots-vertical""></i>")
        sb.Append("</button>")

        ' Menú desplegable
        sb.Append("<div class=""me-dd-menu"" id=""memenu_" & pid & """>")

        ' --- Sección: Contactar receptor ---
        sb.Append("<div class=""me-dd-sec"">")
        sb.Append("<div class=""me-dd-lbl"">Contactar receptor</div>")
        If celReceptor <> "" Then
            sb.Append("<button type=""button"" class=""me-dd-item"" onclick=""abrirWA('" & celReceptor & "')"">")
            sb.Append("<i class=""ti ti-brand-whatsapp"" style=""color:#25D366""></i>")
            sb.Append("<span>WhatsApp<small>" & HE(LeerStr(dr, "receptor_celular")) & "</small></span>")
            sb.Append("</button>")
            sb.Append("<button type=""button"" class=""me-dd-item"" onclick=""llamar('" & celReceptor & "')"">")
            sb.Append("<i class=""ti ti-phone""></i>")
            sb.Append("<span>Llamar<small>" & HE(LeerStr(dr, "receptor_celular")) & "</small></span>")
            sb.Append("</button>")
        Else
            sb.Append("<div class=""me-dd-item me-dd-disabled""><i class=""ti ti-phone-off""></i><span>Sin celular</span></div>")
        End If
        sb.Append("</div>")

        ' --- Sección: Contactar quien envía ---
        sb.Append("<div class=""me-dd-sec"">")
        sb.Append("<div class=""me-dd-lbl"">Contactar quien envía</div>")
        If tienePrepedido AndAlso clienteCelular <> "" Then
            sb.Append("<button type=""button"" class=""me-dd-item"" onclick=""abrirWA('" & clienteCelular & "')"">")
            sb.Append("<i class=""ti ti-brand-whatsapp"" style=""color:#25D366""></i>")
            sb.Append("<span>WhatsApp " & HE(clienteNombre) & "<small>" & HE(LeerStr(dr, "cliente_celular")) & "</small></span>")
            sb.Append("</button>")
            sb.Append("<button type=""button"" class=""me-dd-item"" onclick=""llamar('" & clienteCelular & "')"">")
            sb.Append("<i class=""ti ti-phone""></i>")
            sb.Append("<span>Llamar " & HE(clienteNombre) & "<small>" & HE(LeerStr(dr, "cliente_celular")) & "</small></span>")
            sb.Append("</button>")
        Else
            sb.Append("<div class=""me-dd-item me-dd-disabled""><i class=""ti ti-phone-off""></i><span>Sin datos de quien envía</span></div>")
        End If
        sb.Append("</div>")

        ' --- Sección: Pedido ---
        sb.Append("<div class=""me-dd-sec"">")
        sb.Append("<div class=""me-dd-lbl"">Pedido</div>")
        sb.Append("<button type=""button"" class=""me-dd-item"" onclick=""verRecibo(" & pid & ")"">")
        sb.Append("<i class=""ti ti-receipt""></i><span>Ver recibo</span>")
        sb.Append("</button>")
        sb.Append("<button type=""button"" class=""me-dd-item"" onclick=""abrirDetalle(" & pid & ")"">")
        sb.Append("<i class=""ti ti-eye""></i><span>Ver detalle completo</span>")
        sb.Append("</button>")
        Dim mapDest As String = If(gps <> "", gps, direccion)
        If mapDest <> "" Then
            sb.Append("<button type=""button"" class=""me-dd-item"" onclick=""abrirMaps('" & HEjs(mapDest) & "')"">")
            sb.Append("<i class=""ti ti-map""></i><span>Abrir en Maps</span>")
            sb.Append("</button>")
        End If
        sb.Append("</div>")

        ' --- Sección: Cambiar estado (opciones NO visibles en botón principal) ---
        Dim tieneOpcionesEstado As Boolean = False
        Dim sbEst As New StringBuilder()
        Select Case estadoOp
            Case "EN_RUTA"
                tieneOpcionesEstado = True
                sbEst.Append("<button type=""button"" class=""me-dd-item me-dd-danger"" onclick=""cambiarEstado(" & pid & ",'NO_ENTREGADO')"">")
                sbEst.Append("<i class=""ti ti-x""></i><span>No entregado</span>")
                sbEst.Append("</button>")
            Case "NO_ENTREGADO"
                tieneOpcionesEstado = True
                sbEst.Append("<button type=""button"" class=""me-dd-item me-dd-success"" onclick=""cambiarEstado(" & pid & ",'ENTREGADO')"">")
                sbEst.Append("<i class=""ti ti-check""></i><span>Entregado</span>")
                sbEst.Append("</button>")
            Case "ENTREGADO"
                ' Solo ver, no cambiar
        End Select

        If tieneOpcionesEstado Then
            sb.Append("<div class=""me-dd-sec"">")
            sb.Append("<div class=""me-dd-lbl"">Cambiar estado</div>")
            sb.Append(sbEst.ToString())
            sb.Append("</div>")
        End If

        sb.Append("</div>") ' /me-dd-menu
        sb.Append("</div>") ' /me-dropdown
        sb.Append("</div>") ' /me-acciones
        sb.Append("</td>")

        sb.Append("</tr>")
        Return sb.ToString()
    End Function

    ' ============================================================
    ' OBTENER PRODUCTOS del pedido (consulta separada)
    ' ============================================================
    Private Function ObtenerProductos(pedidoId As Integer) As String
        Dim sb As New StringBuilder()
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand(
                    "SELECT nombre_producto, cantidad, personalizacion " &
                    "FROM FLORERIA_Pedido_Detalle " &
                    "WHERE pedido_id = @id ORDER BY detalle_id", conn)
                    cmd.Parameters.AddWithValue("@id", pedidoId)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            Dim nombre As String = ""
                            Dim qty    As Integer = 1
                            Dim pers   As String = ""
                            If Not dr.IsDBNull(0) Then nombre = dr(0).ToString()
                            If Not dr.IsDBNull(1) Then qty = CInt(dr(1))
                            If Not dr.IsDBNull(2) Then pers = dr(2).ToString().Trim()

                            sb.Append("<div class=""me-prod-row"">")
                            sb.Append("<span class=""me-prod-qty"">")
                            sb.Append(qty)
                            sb.Append("×</span>")
                            sb.Append("<span class=""me-prod-nom"">")
                            sb.Append(HE(nombre))
                            If pers <> "" Then
                                sb.Append("<span class=""me-prod-pers"">""" & HE(pers) & """</span>")
                            End If
                            sb.Append("</span>")
                            sb.Append("</div>")
                        End While
                    End Using
                End Using
            End Using
        Catch
            ' Si falla, no mostrar productos
        End Try
        Return sb.ToString()
    End Function

    ' ============================================================
    ' BADGE ESTADO OPERATIVO
    ' ============================================================
    Private Function RenderBadgeEstado(estado As String) As String
        Select Case estado
            Case "PENDIENTE"      : Return "<span class=""me-badge me-b-pend""><span class=""me-dot""></span>Pendiente</span>"
            Case "IMPRESO"        : Return "<span class=""me-badge me-b-imp""><span class=""me-dot""></span>Impreso</span>"
            Case "EN_PREPARACION" : Return "<span class=""me-badge me-b-prep""><span class=""me-dot""></span>En preparación</span>"
            Case "LISTO"          : Return "<span class=""me-badge me-b-listo""><span class=""me-dot""></span>Listo</span>"
            Case "EN_RUTA"        : Return "<span class=""me-badge me-b-ruta""><span class=""me-dot""></span>En ruta</span>"
            Case "ENTREGADO"      : Return "<span class=""me-badge me-b-ok""><span class=""me-dot""></span>Entregado</span>"
            Case "NO_ENTREGADO"   : Return "<span class=""me-badge me-b-fail""><span class=""me-dot""></span>No entregado</span>"
            Case Else             : Return "<span class=""me-badge me-b-pend""><span class=""me-dot""></span>" & HE(estado) & "</span>"
        End Select
    End Function

    ' ============================================================
    ' HELPERS
    ' ============================================================
    Private Function LeerStr(dr As SqlDataReader, campo As String) As String
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return ""
            Return dr(idx).ToString()
        Catch
            Return ""
        End Try
    End Function

    Private Function LeerInt(dr As SqlDataReader, campo As String) As Integer
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return 0
            Return CInt(dr(idx))
        Catch
            Return 0
        End Try
    End Function

    Private Function LeerBool(dr As SqlDataReader, campo As String) As Boolean
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return False
            Return CBool(dr(idx))
        Catch
            Return False
        End Try
    End Function

    Private Function LeerFecha(dr As SqlDataReader, campo As String) As DateTime
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return DateTime.Today
            Return CDate(dr(idx))
        Catch
            Return DateTime.Today
        End Try
    End Function

    Private Function LeerHora(dr As SqlDataReader, campo As String) As String
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return ""
            Dim t As TimeSpan = CType(dr(idx), TimeSpan)
            Return t.Hours.ToString("00") & ":" & t.Minutes.ToString("00")
        Catch
            Try
                Dim raw As String = dr(campo).ToString()
                If raw.Length >= 5 Then Return raw.Substring(0, 5)
                Return raw
            Catch
                Return ""
            End Try
        End Try
    End Function

    Private Function LimpiarCelular(cel As String) As String
        If cel Is Nothing Then Return ""
        Dim r As String = ""
        For Each c As Char In cel
            If Char.IsDigit(c) Then r &= c
        Next
        Return r
    End Function

    Private Function IfBlanco(v As String) As Object
        If v Is Nothing OrElse v.Trim() = "" Then Return DBNull.Value
        Return v.Trim()
    End Function

    Private Function HE(s As String) As String
        If s Is Nothing Then Return ""
        Return System.Web.HttpUtility.HtmlEncode(s)
    End Function

    Private Function HEjs(s As String) As String
        If s Is Nothing Then Return ""
        Return s.Replace("\", "\\").Replace("'", "\'").Replace(Chr(34), "&quot;")
    End Function

    Private Function LeerQS(context As HttpContext, key As String) As String
        Dim v As String = context.Request.QueryString(key)
        If v Is Nothing Then Return ""
        Return v.Trim()
    End Function

    Private Function MesCorto(d As DateTime) As String
        Dim meses() As String = {"ene","feb","mar","abr","may","jun","jul","ago","sep","oct","nov","dic"}
        Return meses(d.Month - 1)
    End Function

    Private Function DiaSemana(d As DateTime) As String
        Dim dias() As String = {"dom","lun","mar","mié","jue","vie","sáb"}
        Return dias(CInt(d.DayOfWeek))
    End Function

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
