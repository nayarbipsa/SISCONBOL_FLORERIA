Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

Public Class Pedidos_Handler
    Implements IHttpHandler, SessionState.IRequiresSessionState

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "text/html"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)

        ' Verificar sesion
        If Not SesionHelper.VerificarSesion(context) Then
            context.Response.StatusCode = 401
            context.Response.Write("<tr><td colspan='5' class='table-empty'><i class='ti ti-lock'></i>Sesion expirada</td></tr>")
            Return
        End If

        Try
            ' Leer permisos (tipo_id 1=Admin, 2=Gerente, 3=Cajero/Vendedor)
            Dim tipoId As Integer = 3
            If context.Session("tipo_id") IsNot Nothing Then
                Integer.TryParse(context.Session("tipo_id").ToString(), tipoId)
            End If
            Dim esAdminOGerente As Boolean = (tipoId = 1 OrElse tipoId = 2)

            ' Leer filtros del querystring
            Dim buscar As String = LeerQS(context, "b")
            Dim feDesde As String = LeerQS(context, "fed")
            Dim feHasta As String = LeerQS(context, "feh")
            Dim soloHoy As String = LeerQS(context, "hoy")
            Dim crDesde As String = LeerQS(context, "crd")
            Dim crHasta As String = LeerQS(context, "crh")
            Dim estadoPago As String = LeerQS(context, "p")
            Dim estadoOp As String = LeerQS(context, "op")
            Dim zonaIdStr As String = LeerQS(context, "z")
            Dim deliveryIdStr As String = LeerQS(context, "deli")
            Dim soloExpress As String = LeerQS(context, "exp")
            Dim soloSinContactar As String = LeerQS(context, "sc")
            Dim soloSinDelivery As String = LeerQS(context, "sd")
            Dim vistaCompacta As String = LeerQS(context, "cp")

            ' Aplicar default si no hay filtros: solo entregas hoy
            If buscar = "" AndAlso feDesde = "" AndAlso feHasta = "" _
               AndAlso crDesde = "" AndAlso crHasta = "" _
               AndAlso estadoPago = "" AndAlso estadoOp = "" _
               AndAlso zonaIdStr = "" AndAlso deliveryIdStr = "" _
               AndAlso soloExpress = "" AndAlso soloSinContactar = "" _
               AndAlso soloSinDelivery = "" AndAlso soloHoy = "" Then
                soloHoy = "1"
            End If

            Dim sb As New StringBuilder()
            Dim totalFilas As Integer = 0

            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Pedido_Listar", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@buscar", IfBlanco(buscar))
                    cmd.Parameters.AddWithValue("@fecha_desde", IfBlanco(feDesde))
                    cmd.Parameters.AddWithValue("@fecha_hasta", IfBlanco(feHasta))
                    cmd.Parameters.AddWithValue("@solo_hoy", If(soloHoy = "1", 1, 0))
                    cmd.Parameters.AddWithValue("@creado_desde", IfBlanco(crDesde))
                    cmd.Parameters.AddWithValue("@creado_hasta", IfBlanco(crHasta))
                    cmd.Parameters.AddWithValue("@estado_pago", IfBlanco(estadoPago))
                    cmd.Parameters.AddWithValue("@estado_operativo", IfBlanco(estadoOp))
                    cmd.Parameters.AddWithValue("@zona_id", IfInt(zonaIdStr))
                    cmd.Parameters.AddWithValue("@delivery_id", IfInt(deliveryIdStr))
                    cmd.Parameters.AddWithValue("@solo_express", If(soloExpress = "1", 1, 0))
                    cmd.Parameters.AddWithValue("@solo_sin_contactar", If(soloSinContactar = "1", 1, 0))
                    cmd.Parameters.AddWithValue("@solo_sin_delivery", If(soloSinDelivery = "1", 1, 0))
                    cmd.Parameters.AddWithValue("@pagina", 1)
                    cmd.Parameters.AddWithValue("@por_pagina", 200)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            totalFilas += 1
                            sb.Append(RenderFila(dr, esAdminOGerente, vistaCompacta = "1"))
                        End While
                    End Using
                End Using
            End Using

            If totalFilas = 0 Then
                sb.Append("<tr><td colspan=""5"" class=""table-empty"">")
                sb.Append("<i class=""ti ti-clipboard-off""></i>")
                sb.Append("No se encontraron pedidos con esos filtros.")
                sb.Append("</td></tr>")
            End If

            ' Devolver: tbody | total
            context.Response.Write("<!--TOTAL:" & totalFilas & "-->")
            context.Response.Write(sb.ToString())

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Pedidos_Handler: " & ex.Message)
            context.Response.StatusCode = 500
            context.Response.Write("<tr><td colspan=""5"" class=""table-empty"">")
            context.Response.Write("<i class=""ti ti-alert-triangle""></i>Error al cargar: " & HE(ex.Message))
            context.Response.Write("</td></tr>")
        End Try
    End Sub

    ' ============================================================
    ' RENDER DE UNA FILA
    ' ============================================================
    Private Function RenderFila(dr As SqlDataReader, esAdmin As Boolean, compacta As Boolean) As String
        Dim sb As New StringBuilder()
        Dim pedidoId As Integer = CInt(dr("pedido_id"))
        Dim codigo As String = LeerStr(dr, "codigo")
        Dim wcNumber As String = LeerStr(dr, "wc_order_number")
        Dim receptor As String = LeerStr(dr, "receptor_nombre")
        Dim celular As String = LeerStr(dr, "receptor_celular")
        Dim direccion As String = LeerStr(dr, "direccion")
        Dim gps As String = LeerStr(dr, "gps")
        Dim zona As String = LeerStr(dr, "zona_nombre")
        Dim fechaEntrega As DateTime = LeerFecha(dr, "fecha_entrega")
        Dim creadoEn As DateTime = LeerFecha(dr, "creado_en")
        Dim slotInicio As String = LeerHora(dr, "slot_hora_inicio")
        Dim esExpress As Boolean = LeerBool(dr, "es_express")
        Dim estadoPago As String = LeerStr(dr, "estado_pago")
        Dim estadoOp As String = LeerStr(dr, "estado_operativo")
        Dim totalBs As Decimal = LeerDec(dr, "total_bs")
        Dim montoPagado As Decimal = LeerDec(dr, "monto_pagado")
        Dim contactado As Boolean = LeerBool(dr, "contactado_cliente")
        Dim deliveryId As Integer = LeerInt(dr, "delivery_actual_id")
        Dim deliveryNombre As String = LeerStr(dr, "delivery_nombre")

        ' Determinar si es urgente: fecha entrega = hoy AND estado pendiente
        Dim esUrgente As Boolean = (fechaEntrega.Date = DateTime.Today AndAlso estadoOp = "PENDIENTE")
        Dim claseFila As String = ""
        If esExpress Then claseFila &= " row-express"
        If esUrgente Then claseFila &= " row-urgente"

        ' Banner urgente arriba (como fila extra)
        If esUrgente AndAlso Not compacta Then
            sb.Append("<tr><td colspan=""5"" class=""urgente-banner"">")
            sb.Append("<i class=""ti ti-alert-circle""></i> URGENTE: Pedido de hoy aun pendiente de impresion")
            sb.Append("</td></tr>")
        End If

        sb.Append("<tr class=""" & claseFila.Trim() & """>")

        ' ---- COL 1: HORA ----
        sb.Append("<td><div class=""hora-stack"">")
        If esExpress Then
            sb.Append("<span class=""badge badge-express""><i class=""ti ti-bolt""></i> Express</span>")
        End If
        sb.Append("<span style=""font-size:14px;font-weight:600"">" & If(slotInicio <> "", slotInicio, "--:--") & "</span>")
        If Not compacta Then
            sb.Append("<span style=""font-size:10px;color:#999"">" & fechaEntrega.ToString("dd/MM") & " " & DiaSemanaCorto(fechaEntrega) & "</span>")
        End If
        sb.Append("</div></td>")

        ' ---- COL 2: PEDIDO / RECEPTOR ----
        sb.Append("<td><div class=""codigos-stack"">")
        ' Codigos
        sb.Append("<div style=""display:flex;align-items:baseline;gap:8px;margin-bottom:3px"">")
        If wcNumber <> "" Then
            sb.Append("<span class=""wc-big"">#" & HE(wcNumber) & "</span>")
            sb.Append("<span class=""ped-small"">" & HE(codigo) & "</span>")
        Else
            sb.Append("<span class=""wc-empty"">Sin WC</span>")
            sb.Append("<span class=""ped-main"">" & HE(codigo) & "</span>")
        End If
        sb.Append("</div>")
        ' Nombre + contactado
        sb.Append("<div style=""font-weight:500;font-size:13px"">" & HE(receptor))
        If contactado Then
            sb.Append(" <span class=""contacto-icon ok"" title=""Contactado""><i class=""ti ti-check""></i></span>")
        Else
            sb.Append(" <span class=""contacto-icon no"" title=""Sin contactar""><i class=""ti ti-x""></i></span>")
        End If
        sb.Append("</div>")
        ' Direccion + celular
        If Not compacta Then
            sb.Append("<div class=""receptor-info-extra""><i class=""ti ti-map-pin"" style=""font-size:10px""></i> " & HE(direccion) & " &middot; " & HE(celular) & "</div>")
            sb.Append("<div class=""ped-creado""><i class=""ti ti-plus"" style=""font-size:9px""></i> Creado: " & creadoEn.ToString("dd/MM HH:mm") & "</div>")
        End If
        sb.Append("</div></td>")

        ' ---- COL 3: ZONA / DELIVERY ----
        sb.Append("<td><div class=""zona-deli"">")
        sb.Append("<span class=""z""><i class=""ti ti-map-pin-filled""></i> " & HE(zona) & "</span>")
        If deliveryNombre <> "" Then
            sb.Append("<span class=""d""><i class=""ti ti-motorbike""></i> " & HE(AbreviarNombre(deliveryNombre)) & "</span>")
        Else
            sb.Append("<span class=""d empty""><i class=""ti ti-user-off""></i> Sin asignar</span>")
        End If
        sb.Append("</div></td>")

        ' ---- COL 4: ESTADO ----
        sb.Append("<td>")
        sb.Append("<div style=""display:flex;flex-direction:column;gap:3px;align-items:flex-start"">")
        sb.Append(RenderBadgePago(estadoPago, montoPagado, totalBs))
        sb.Append(RenderBadgeOperativo(estadoOp))
        sb.Append("</div>")
        sb.Append("</td>")

        ' ---- COL 5: ACCIONES ----
        sb.Append("<td style=""text-align:right"">")
        sb.Append(RenderDropdownAcciones(pedidoId, estadoOp, contactado, deliveryId, celular, direccion, gps, receptor, codigo, wcNumber, totalBs, esAdmin))
        sb.Append("</td>")

        sb.Append("</tr>")

        Return sb.ToString()
    End Function

    Private Function RenderBadgePago(estado As String, pagado As Decimal, total As Decimal) As String
        Select Case estado
            Case "PAGADO"
                Return "<span class=""badge badge-pagado"">Pagado &middot; Bs " & total.ToString("N0") & "</span>"
            Case "ANTICIPO"
                Dim html As String = "<span class=""badge badge-anticipo"">Anticipo</span>"
                html &= "<span class=""anticipo-monto"">Bs " & pagado.ToString("N0") & " / Bs " & total.ToString("N0") & "</span>"
                Return html
            Case "PENDIENTE"
                Return "<span class=""badge badge-pendiente"">Pendiente &middot; Bs " & total.ToString("N0") & "</span>"
            Case Else
                Return "<span class=""badge"">" & HE(estado) & "</span>"
        End Select
    End Function

    Private Function RenderBadgeOperativo(estado As String) As String
        Select Case estado
            Case "PENDIENTE" : Return "<span class=""badge badge-pendiente"">Pendiente</span>"
            Case "IMPRESO" : Return "<span class=""badge badge-impreso"">Impreso</span>"
            Case "EN_PREPARACION" : Return "<span class=""badge badge-prep"">En prep.</span>"
            Case "LISTO" : Return "<span class=""badge badge-listo"">Listo</span>"
            Case "EN_RUTA" : Return "<span class=""badge badge-ruta"">En ruta</span>"
            Case "ENTREGADO" : Return "<span class=""badge badge-entregado"">Entregado</span>"
            Case "NO_ENTREGADO" : Return "<span class=""badge badge-no-entregado"">No entregado</span>"
            Case "REPROGRAMADO" : Return "<span class=""badge badge-reprogramado"">Reprog.</span>"
            Case Else : Return "<span class=""badge"">" & HE(estado) & "</span>"
        End Select
    End Function

    ' ============================================================
    ' DROPDOWN DE ACCIONES - Estilo B (inteligente)
    ' ============================================================
    Private Function RenderDropdownAcciones(pid As Integer, estadoOp As String, contactado As Boolean, deliveryId As Integer,
                                            celular As String, direccion As String, gps As String,
                                            receptor As String, codigo As String, wcNumber As String,
                                            total As Decimal, esAdmin As Boolean) As String
        Dim sb As New StringBuilder()
        sb.Append("<div class=""dropdown"" id=""dd_" & pid & """>")
        sb.Append("<button type=""button"" class=""btn btn-sm"" onclick=""toggleDropdown(" & pid & ",event)"" style=""font-weight:500"">")
        sb.Append("Acciones <i class=""ti ti-chevron-down""></i>")
        sb.Append("</button>")
        sb.Append("<div class=""dropdown-menu"">")

        ' Header con estado actual
        sb.Append("<div class=""dropdown-header-estado"">Estado: " & FormatearEstado(estadoOp) & "</div>")

        ' Acciones de siguiente paso segun estado
        Dim accionPrincipal As String = ObtenerAccionPrincipal(pid, estadoOp)
        Dim accionVolver As String = ObtenerAccionVolver(pid, estadoOp)
        If accionPrincipal <> "" Then sb.Append(accionPrincipal)
        If accionVolver <> "" Then sb.Append(accionVolver)

        sb.Append("<div class=""dropdown-divider""></div>")
        sb.Append("<div class=""dropdown-section-label"">Gestion</div>")

        sb.Append("<button type=""button"" class=""dropdown-item"" onclick=""verDetalle(" & pid & ")"">")
        sb.Append("<i class=""ti ti-eye""></i> Ver detalle</button>")

        sb.Append("<button type=""button"" class=""dropdown-item"" onclick=""imprimirTicket(" & pid & ")"">")
        sb.Append("<i class=""ti ti-printer""></i> Imprimir ticket</button>")

        sb.Append("<button type=""button"" class=""dropdown-item"" onclick=""asignarDelivery(" & pid & ")"">")
        sb.Append("<i class=""ti ti-motorbike""></i> ")
        sb.Append(If(deliveryId > 0, "Cambiar delivery", "Asignar delivery"))
        sb.Append("</button>")

        If Not contactado Then
            sb.Append("<button type=""button"" class=""dropdown-item"" onclick=""marcarContactado(" & pid & ")"">")
            sb.Append("<i class=""ti ti-phone-check""></i> Marcar contactado</button>")
        End If

        ' Seccion Comunicacion
        sb.Append("<div class=""dropdown-divider""></div>")
        sb.Append("<div class=""dropdown-section-label"">Comunicacion</div>")

        Dim celLimpio As String = LimpiarCelular(celular)
        If celLimpio <> "" Then
            sb.Append("<button type=""button"" class=""dropdown-item"" onclick=""abrirWhatsApp('" & celLimpio & "')"">")
            sb.Append("<i class=""ti ti-brand-whatsapp""></i> WhatsApp receptor</button>")

            sb.Append("<button type=""button"" class=""dropdown-item"" onclick=""llamarCliente('" & celLimpio & "')"">")
            sb.Append("<i class=""ti ti-phone""></i> Llamar al receptor</button>")
        End If

        sb.Append("<button type=""button"" class=""dropdown-item"" onclick=""copiarParaWhatsApp(" & pid & ")"">")
        sb.Append("<i class=""ti ti-copy""></i> Copiar info para WhatsApp</button>")

        Dim mapDest As String = If(gps <> "", gps, direccion)
        sb.Append("<button type=""button"" class=""dropdown-item"" onclick=""abrirMaps('" & HEjs(mapDest) & "')"">")
        sb.Append("<i class=""ti ti-map""></i> Ver en Google Maps</button>")

        ' Seccion Admin (solo admin/gerente)
        If esAdmin Then
            sb.Append("<div class=""dropdown-divider""></div>")
            sb.Append("<div class=""dropdown-section-label"">Administracion</div>")

            sb.Append("<button type=""button"" class=""dropdown-item edit-action"" onclick=""editarPedido(" & pid & ")"">")
            sb.Append("<i class=""ti ti-edit""></i> Editar pedido</button>")

            sb.Append("<button type=""button"" class=""dropdown-item danger-action"" onclick=""cancelarPedido(" & pid & ")"">")
            sb.Append("<i class=""ti ti-trash""></i> Cancelar pedido</button>")
        End If

        sb.Append("</div></div>")
        Return sb.ToString()
    End Function

    Private Function ObtenerAccionPrincipal(pid As Integer, estado As String) As String
        Select Case estado
            Case "PENDIENTE"
                Return "<button type=""button"" class=""dropdown-item next-step"" onclick=""imprimirTicket(" & pid & ")"">" &
                       "<i class=""ti ti-printer""></i> Imprimir ticket</button>"
            Case "IMPRESO"
                Return "<button type=""button"" class=""dropdown-item next-step"" onclick=""cambiarEstado(" & pid & ",'EN_PREPARACION')"">" &
                       "<i class=""ti ti-flower""></i> En preparacion</button>"
            Case "EN_PREPARACION"
                Return "<button type=""button"" class=""dropdown-item next-step"" onclick=""cambiarEstado(" & pid & ",'LISTO')"">" &
                       "<i class=""ti ti-package""></i> Marcar como Listo</button>"
            Case "LISTO"
                Return "<button type=""button"" class=""dropdown-item next-step"" onclick=""cambiarEstado(" & pid & ",'EN_RUTA')"">" &
                       "<i class=""ti ti-truck-delivery""></i> Marcar En ruta</button>"
            Case "EN_RUTA"
                Return "<button type=""button"" class=""dropdown-item next-step"" onclick=""cambiarEstado(" & pid & ",'ENTREGADO')"">" &
                       "<i class=""ti ti-circle-check""></i> Marcar Entregado</button>"
            Case "NO_ENTREGADO"
                Return "<button type=""button"" class=""dropdown-item next-step"" onclick=""cambiarEstado(" & pid & ",'REPROGRAMADO')"">" &
                       "<i class=""ti ti-refresh""></i> Reprogramar</button>"
            Case Else
                Return ""
        End Select
    End Function

    Private Function ObtenerAccionVolver(pid As Integer, estado As String) As String
        Select Case estado
            Case "IMPRESO"
                Return "<button type=""button"" class=""dropdown-item back-step"" onclick=""cambiarEstado(" & pid & ",'PENDIENTE')"">" &
                       "<i class=""ti ti-arrow-back""></i> Volver a Pendiente</button>"
            Case "EN_PREPARACION"
                Return "<button type=""button"" class=""dropdown-item back-step"" onclick=""cambiarEstado(" & pid & ",'IMPRESO')"">" &
                       "<i class=""ti ti-arrow-back""></i> Volver a Impreso</button>"
            Case "LISTO"
                Return "<button type=""button"" class=""dropdown-item back-step"" onclick=""cambiarEstado(" & pid & ",'EN_PREPARACION')"">" &
                       "<i class=""ti ti-arrow-back""></i> Volver a En prep.</button>"
            Case "EN_RUTA"
                Return "<button type=""button"" class=""dropdown-item back-step"" onclick=""cambiarEstado(" & pid & ",'NO_ENTREGADO')"">" &
                       "<i class=""ti ti-circle-x""></i> Marcar No entregado</button>"
            Case Else
                Return ""
        End Select
    End Function

    ' ============================================================
    ' HELPERS
    ' ============================================================
    Private Function LeerQS(context As HttpContext, key As String) As String
        Dim v As String = context.Request.QueryString(key)
        If v Is Nothing Then Return ""
        Return v.Trim()
    End Function

    Private Function IfBlanco(v As String) As Object
        If v Is Nothing OrElse v.Trim() = "" Then Return DBNull.Value
        Return v.Trim()
    End Function

    Private Function IfInt(v As String) As Object
        If v Is Nothing OrElse v.Trim() = "" Then Return DBNull.Value
        Dim n As Integer
        If Integer.TryParse(v, n) Then Return n
        Return DBNull.Value
    End Function

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

    Private Function LeerDec(dr As SqlDataReader, campo As String) As Decimal
        Try
            Dim idx = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return 0D
            Return CDec(dr(idx))
        Catch
            Return 0D
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

    Private Function LeerFecha(dr As SqlDataReader, campo As String) As DateTime
        Try
            Dim idx = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return DateTime.MinValue
            Return CDate(dr(idx))
        Catch
            Return DateTime.MinValue
        End Try
    End Function

    Private Function LeerHora(dr As SqlDataReader, campo As String) As String
        Try
            Dim idx = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return ""
            Dim val = dr(idx)
            If TypeOf val Is TimeSpan Then
                Dim ts = CType(val, TimeSpan)
                Return ts.Hours.ToString("D2") & ":" & ts.Minutes.ToString("D2")
            End If
            Return val.ToString()
        Catch
            Return ""
        End Try
    End Function

    Private Function HE(s As String) As String
        If s Is Nothing Then Return ""
        Return HttpUtility.HtmlEncode(s)
    End Function

    Private Function HEjs(s As String) As String
        If s Is Nothing Then Return ""
        Return s.Replace("\", "\\").Replace("'", "\'").Replace(Chr(34), "")
    End Function

    Private Function AbreviarNombre(nc As String) As String
        If nc Is Nothing OrElse nc.Trim() = "" Then Return ""
        Dim p = nc.Trim().Split(" "c)
        If p.Length >= 2 Then Return p(0) & " " & p(1).Substring(0, 1) & "."
        Return nc
    End Function

    Private Function DiaSemanaCorto(f As DateTime) As String
        Select Case f.DayOfWeek
            Case DayOfWeek.Monday : Return "Lun"
            Case DayOfWeek.Tuesday : Return "Mar"
            Case DayOfWeek.Wednesday : Return "Mie"
            Case DayOfWeek.Thursday : Return "Jue"
            Case DayOfWeek.Friday : Return "Vie"
            Case DayOfWeek.Saturday : Return "Sab"
            Case DayOfWeek.Sunday : Return "Dom"
            Case Else : Return ""
        End Select
    End Function

    Private Function LimpiarCelular(c As String) As String
        If c Is Nothing Then Return ""
        Dim res As String = ""
        For Each ch As Char In c
            If Char.IsDigit(ch) Then res &= ch
        Next
        If res.Length = 8 Then res = "591" & res
        Return res
    End Function

    Private Function FormatearEstado(e As String) As String
        Select Case e
            Case "PENDIENTE" : Return "Pendiente"
            Case "IMPRESO" : Return "Impreso"
            Case "EN_PREPARACION" : Return "En preparacion"
            Case "LISTO" : Return "Listo"
            Case "EN_RUTA" : Return "En ruta"
            Case "ENTREGADO" : Return "Entregado"
            Case "NO_ENTREGADO" : Return "No entregado"
            Case "REPROGRAMADO" : Return "Reprogramado"
            Case Else : Return e
        End Select
    End Function

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
