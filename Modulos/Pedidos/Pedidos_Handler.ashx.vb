Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

' ============================================================
' SISCONBOL_FLORERIA - Pedidos_Handler
' Version 2 - Soporte para tabs (Todos / WC pendiente), sucursal,
'             cliente comprador y acciones a mano.
' ============================================================
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
            ' Leer permisos (1=Admin, 2=Gerente, 3=Cajero/Vendedor)
            Dim tipoId As Integer = 3
            If context.Session("tipo_id") IsNot Nothing Then
                Integer.TryParse(context.Session("tipo_id").ToString(), tipoId)
            End If
            Dim esAdminOGerente As Boolean = (tipoId = 1 OrElse tipoId = 2)

            ' Leer tab activa (todos | wc_pendiente)
            Dim tab As String = LeerQS(context, "tab")
            If tab = "" Then tab = "todos"

            ' Leer filtros comunes
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
            Dim sucPreparaStr As String = LeerQS(context, "sp")

            ' Flag tab WC
            Dim esTabWC As Boolean = (tab = "wc_pendiente")

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
                    cmd.Parameters.AddWithValue("@sucursal_prepara_id", IfInt(sucPreparaStr))
                    cmd.Parameters.AddWithValue("@solo_wc_pendiente", If(esTabWC, 1, 0))
                    cmd.Parameters.AddWithValue("@pagina", 1)
                    cmd.Parameters.AddWithValue("@por_pagina", 200)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        While dr.Read()
                            totalFilas += 1
                            If esTabWC Then
                                sb.Append(RenderFilaWC(dr))
                            Else
                                sb.Append(RenderFilaTodos(dr, esAdminOGerente, vistaCompacta = "1"))
                            End If
                        End While
                    End Using
                End Using
            End Using

            ' Mensaje cuando no hay resultados
            If totalFilas = 0 Then
                Dim colspan As Integer = If(esTabWC, 6, 5)
                sb.Append("<tr><td colspan=""" & colspan & """ class=""table-empty"">")
                sb.Append("<i class=""ti ti-clipboard-off""></i>")
                sb.Append("No se encontraron pedidos con esos filtros.")
                sb.Append("</td></tr>")
            End If

            ' Devolver: comentario con total + html de tbody
            context.Response.Write("<!--TOTAL:" & totalFilas & "-->")
            context.Response.Write(sb.ToString())

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR Pedidos_Handler: " & ex.Message)
            context.Response.StatusCode = 500
            context.Response.Write("<tr><td colspan=""6"" class=""table-empty"">")
            context.Response.Write("<i class=""ti ti-alert-triangle""></i>Error al cargar: " & HE(ex.Message))
            context.Response.Write("</td></tr>")
        End Try
    End Sub

    ' ============================================================
    ' RENDER FILA TAB "TODOS" - tabla 5 columnas
    ' ============================================================
    Private Function RenderFilaTodos(dr As SqlDataReader, esAdmin As Boolean, compacta As Boolean) As String
        Dim sb As New StringBuilder()

        ' Lectura de campos
        Dim pedidoId As Integer = CInt(dr("pedido_id"))
        Dim codigo As String = LeerStr(dr, "codigo")
        Dim wcNumber As String = LeerStr(dr, "wc_order_number")
        Dim wcOrderId As Integer = LeerInt(dr, "wc_order_id")
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

        ' Cliente comprador
        Dim clienteNombre As String = LeerStr(dr, "cliente_nombre")
        Dim clienteApellidos As String = LeerStr(dr, "cliente_apellidos")
        Dim tienePrepedido As Boolean = (LeerInt(dr, "tiene_prepedido") = 1)
        Dim clienteCompleto As String = (clienteNombre & " " & clienteApellidos).Trim()

        ' Determinar urgencia
        Dim esUrgente As Boolean = (fechaEntrega.Date = DateTime.Today AndAlso estadoOp = "PENDIENTE")
        Dim claseFila As String = "row-pedido"
        If esExpress Then claseFila &= " row-express"
        If esUrgente Then claseFila &= " row-urgente"

        ' Fila completa con click para abrir detalle (excepto en td de acciones)
        sb.Append("<tr class=""" & claseFila & """ data-pid=""" & pedidoId & """ onclick=""abrirDetalleModal(" & pedidoId & ")"" style=""cursor:pointer"">")

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

        ' ---- COL 2: PEDIDO / RECEPTOR + CLIENTE ----
        sb.Append("<td><div class=""codigos-stack"">")

        ' Códigos
        sb.Append("<div style=""display:flex;align-items:baseline;gap:8px;margin-bottom:3px"">")
        If wcNumber <> "" Then
            sb.Append("<span class=""wc-big"">#" & HE(wcNumber) & "</span>")
            sb.Append("<span class=""ped-small"">" & HE(codigo) & "</span>")
        Else
            ' Pedido mostrador (sin WC)
            sb.Append("<span class=""badge-mostrador"">MOSTRADOR</span>")
            sb.Append("<span class=""ped-main"">" & HE(codigo) & "</span>")
        End If
        sb.Append("</div>")

        ' Receptor + ícono contactado
        sb.Append("<div style=""font-weight:500;font-size:13px"">" & HE(receptor))
        If contactado Then
            sb.Append(" <span class=""contacto-icon ok"" title=""Contactado""><i class=""ti ti-check""></i></span>")
        Else
            sb.Append(" <span class=""contacto-icon no"" title=""Sin contactar""><i class=""ti ti-x""></i></span>")
        End If
        sb.Append("</div>")

        ' Cliente comprador (NUEVO)
        If tienePrepedido AndAlso clienteCompleto <> "" Then
            sb.Append("<div class=""cliente-comprador""><i class=""ti ti-shopping-cart""></i> Compró: " & HE(clienteCompleto) & "</div>")
        ElseIf Not tienePrepedido Then
            sb.Append("<div class=""cliente-comprador mostrador""><i class=""ti ti-building-store""></i> Venta directa mostrador</div>")
        End If

        ' Dirección y celular en modo detallado
        If Not compacta Then
            sb.Append("<div class=""receptor-info-extra""><i class=""ti ti-map-pin"" style=""font-size:10px""></i> " & HE(direccion) & " &middot; " & HE(celular) & "</div>")
            sb.Append("<div class=""ped-creado""><i class=""ti ti-plus"" style=""font-size:9px""></i> Creado: " & creadoEn.ToString("dd/MM HH:mm") & "</div>")
        End If
        sb.Append("</div></td>")

        ' ---- COL 3: ZONA / DELIVERY ----
        sb.Append("<td><div class=""zona-deli"">")
        sb.Append("<span class=""z""><i class=""ti ti-map-pin-filled""></i> " & HE(zona) & "</span>")
        If deliveryNombre <> "" AndAlso deliveryId > 0 Then
            ' Delivery asignado: avatar de iniciales + nombre
            Dim iniciales As String = ObtenerIniciales(deliveryNombre)
            sb.Append("<span class=""deli-asignado"">")
            sb.Append("<span class=""deli-avatar"">" & HE(iniciales) & "</span>")
            sb.Append(HE(AbreviarNombre(deliveryNombre)))
            sb.Append("</span>")
        Else
            sb.Append("<span class=""deli-vacio""><i class=""ti ti-user-off""></i> Sin asignar</span>")
        End If
        sb.Append("</div></td>")

        ' ---- COL 4: ESTADO ----
        sb.Append("<td>")
        sb.Append("<div style=""display:flex;flex-direction:column;gap:3px;align-items:flex-start"">")
        sb.Append(RenderBadgePago(estadoPago, montoPagado, totalBs, wcNumber))
        sb.Append(RenderBadgeOperativo(estadoOp))
        sb.Append("</div>")
        sb.Append("</td>")

        ' ---- COL 5: ACCIONES (5 iconos + urgente + menú "más") ----
        ' stopPropagation para que clicks en botones NO abran el modal
        sb.Append("<td style=""text-align:right"" onclick=""event.stopPropagation()"">")
        sb.Append(RenderAccionesTodos(pedidoId, estadoOp, estadoPago, contactado, deliveryId, celular, direccion, gps, receptor, codigo, wcNumber, wcOrderId, totalBs, esAdmin))
        sb.Append("</td>")

        sb.Append("</tr>")

        Return sb.ToString()
    End Function

    ' ============================================================
    ' RENDER FILA TAB "WC PENDIENTE" - tabla 6 columnas
    ' ============================================================
    Private Function RenderFilaWC(dr As SqlDataReader) As String
        Dim sb As New StringBuilder()

        Dim pedidoId As Integer = CInt(dr("pedido_id"))
        Dim wcNumber As String = LeerStr(dr, "wc_order_number")
        Dim wcStatus As String = LeerStr(dr, "wc_order_status")
        Dim receptor As String = LeerStr(dr, "receptor_nombre")
        Dim celular As String = LeerStr(dr, "receptor_celular")
        Dim totalBs As Decimal = LeerDec(dr, "total_bs")
        Dim fechaEntrega As DateTime = LeerFecha(dr, "fecha_entrega")
        Dim creadoEn As DateTime = LeerFecha(dr, "creado_en")
        Dim slotInicio As String = LeerHora(dr, "slot_hora_inicio")
        Dim metodoPagoCodigo As String = LeerStr(dr, "wc_payment_method")
        Dim metodoPagoTitulo As String = LeerStr(dr, "wc_payment_method_title")
        If metodoPagoTitulo = "" Then metodoPagoTitulo = "(no especificado)"

        ' Cliente comprador
        Dim clienteNombre As String = LeerStr(dr, "cliente_nombre")
        Dim clienteApellidos As String = LeerStr(dr, "cliente_apellidos")
        Dim clienteCelular As String = LeerStr(dr, "cliente_celular")
        Dim clienteCompleto As String = (clienteNombre & " " & clienteApellidos).Trim()

        Dim iconoMetodo As String = ObtenerIconoMetodoPago(metodoPagoCodigo)
        Dim clienteJs As String = receptor.Replace("'", "").Replace(Chr(34), "")
        Dim hoy As Date = DateTime.Today
        Dim esUrgente As Boolean = (fechaEntrega.Date <= hoy)

        sb.Append("<tr class=""row-pedido"" data-pid=""" & pedidoId & """ onclick=""abrirDetalleModal(" & pedidoId & ")"" style=""cursor:pointer"">")

        ' ---- COL 1: WC# ----
        sb.Append("<td><span class=""wc-big"">#" & HE(wcNumber) & "</span></td>")

        ' ---- COL 2: CLIENTE / RECEPTOR ----
        sb.Append("<td>")
        ' Cliente arriba pequeño
        If clienteCompleto <> "" Then
            sb.Append("<div class=""cliente-arriba""><i class=""ti ti-shopping-cart""></i> " & HE(clienteCompleto))
            If clienteCelular <> "" Then
                sb.Append(" &middot; " & HE(clienteCelular))
            End If
            sb.Append("</div>")
        End If
        ' Receptor grande
        sb.Append("<div style=""font-weight:500;font-size:13px"">" & HE(receptor) & "</div>")
        sb.Append("<div class=""cell-subtle"">" & HE(celular) & " &middot; " & creadoEn.ToString("dd/MM HH:mm") & "</div>")
        sb.Append("</td>")

        ' ---- COL 3: METODO PAGO ----
        sb.Append("<td><div class=""metodo-pago-cell"">")
        sb.Append("<i class=""ti " & iconoMetodo & """></i> " & HE(metodoPagoTitulo))
        sb.Append("</div></td>")

        ' ---- COL 4: ENTREGA ----
        sb.Append("<td>")
        If esUrgente Then
            sb.Append("<div class=""entrega-urgente"">" & FormatearFechaCorta(fechaEntrega) & "</div>")
        Else
            sb.Append("<div style=""font-size:12px;font-weight:500"">" & FormatearFechaCorta(fechaEntrega) & "</div>")
        End If
        If slotInicio <> "" Then
            sb.Append("<div style=""font-size:10px;color:#999"">" & slotInicio & "</div>")
        End If
        sb.Append("</td>")

        ' ---- COL 5: MONTO ----
        sb.Append("<td style=""text-align:right;font-weight:500"">Bs " & totalBs.ToString("N2") & "</td>")

        ' ---- COL 6: ACCIONES ----
        sb.Append("<td style=""text-align:right"" onclick=""event.stopPropagation()"">")
        sb.Append("<div class=""acciones-wc-cell"">")
        sb.Append("<button type=""button"" class=""btn-icon-only"" title=""Ver detalle"" onclick=""abrirDetalleModal(" & pedidoId & ")""><i class=""ti ti-eye""></i></button>")
        If wcNumber <> "" Then
            sb.Append("<button type=""button"" class=""btn-icon-only"" title=""Ver en WooCommerce"" onclick=""verEnWooCommerce(" & pedidoId & ")""><i class=""ti ti-brand-woocommerce""></i></button>")
        End If
        sb.Append("<button type=""button"" class=""btn-aceptar-wc"" title=""Aceptar pago manual"" onclick=""abrirModalAceptar(" & pedidoId & ",'" & HEjs(clienteJs) & "','" & totalBs.ToString("N2") & "')"">")
        sb.Append("<i class=""ti ti-check""></i> Aceptar")
        sb.Append("</button>")
        sb.Append("</div></td>")

        sb.Append("</tr>")
        Return sb.ToString()
    End Function

    ' ============================================================
    ' RENDER ACCIONES TAB TODOS - 5 iconos + urgente + menu
    ' ============================================================
    Private Function RenderAccionesTodos(pid As Integer, estadoOp As String, estadoPago As String, contactado As Boolean,
                                         deliveryId As Integer, celular As String, direccion As String, gps As String,
                                         receptor As String, codigo As String, wcNumber As String, wcOrderId As Integer,
                                         total As Decimal, esAdmin As Boolean) As String
        Dim sb As New StringBuilder()
        sb.Append("<div class=""acciones-cell"">")

        ' Icono 1: Ver detalle
        sb.Append("<button type=""button"" class=""btn-icon-only"" title=""Ver detalle"" onclick=""abrirDetalleModal(" & pid & ")""><i class=""ti ti-eye""></i></button>")

        ' Icono 2: Imprimir
        sb.Append("<button type=""button"" class=""btn-icon-only"" title=""Imprimir ticket"" onclick=""imprimirTicket(" & pid & ")""><i class=""ti ti-printer""></i></button>")

        ' Icono 3: Ver en WC (solo si tiene wc_order_id)
        If wcOrderId > 0 Then
            sb.Append("<button type=""button"" class=""btn-icon-only"" title=""Ver en WooCommerce"" onclick=""verEnWooCommerce(" & pid & ")""><i class=""ti ti-brand-woocommerce""></i></button>")
        End If

        ' Icono 4: WhatsApp
        Dim celLimpio As String = LimpiarCelular(celular)
        If celLimpio <> "" Then
            sb.Append("<button type=""button"" class=""btn-icon-only"" title=""WhatsApp receptor"" onclick=""abrirWhatsApp('" & celLimpio & "')""><i class=""ti ti-brand-whatsapp"" style=""color:#25D366""></i></button>")
        End If

        ' Icono 5: Maps
        Dim mapDest As String = If(gps <> "", gps, direccion)
        If mapDest <> "" Then
            sb.Append("<button type=""button"" class=""btn-icon-only"" title=""Google Maps"" onclick=""abrirMaps('" & HEjs(mapDest) & "')""><i class=""ti ti-map""></i></button>")
        End If

        ' Acción urgente contextual
        Dim accionUrgente As String = ObtenerAccionUrgente(pid, estadoOp, estadoPago, deliveryId, receptor, total, wcNumber)
        If accionUrgente <> "" Then
            sb.Append(accionUrgente)
        End If

        ' Menú "más"
        sb.Append("<div class=""dropdown"" id=""dd_" & pid & """>")
        sb.Append("<button type=""button"" class=""btn-icon-only"" title=""Más acciones"" onclick=""toggleDropdown(" & pid & ",event)""><i class=""ti ti-dots-vertical""></i></button>")
        sb.Append("<div class=""dropdown-menu"">")
        sb.Append("<div class=""dropdown-header-estado"">Estado: " & FormatearEstado(estadoOp) & "</div>")

        ' Acciones de flujo según estado
        Dim accionSiguiente As String = ObtenerAccionPrincipal(pid, estadoOp)
        Dim accionVolver As String = ObtenerAccionVolver(pid, estadoOp)
        If accionSiguiente <> "" Then sb.Append(accionSiguiente)
        If accionVolver <> "" Then sb.Append(accionVolver)

        sb.Append("<div class=""dropdown-divider""></div>")
        sb.Append("<div class=""dropdown-section-label"">Gestión</div>")

        ' Verificar / Aceptar pago si está pendiente
        If estadoPago = "PENDIENTE" Then
            Dim clienteJsPago As String = HEjs(receptor)
            Dim labelPago As String
            If wcNumber <> "" Then
                labelPago = "Aceptar pago manual"
            Else
                labelPago = "Marcar como pagado"
            End If
            sb.Append("<button type=""button"" class=""dropdown-item urgente-action"" onclick=""abrirModalAceptar(" & pid & ",'" & clienteJsPago & "','" & total.ToString("N2") & "')""><i class=""ti ti-cash""></i> " & labelPago & "</button>")
        End If

        If deliveryId > 0 Then
            sb.Append("<button type=""button"" class=""dropdown-item"" onclick=""asignarDelivery(" & pid & ")""><i class=""ti ti-motorbike""></i> Cambiar delivery</button>")
        Else
            sb.Append("<button type=""button"" class=""dropdown-item"" onclick=""asignarDelivery(" & pid & ")""><i class=""ti ti-motorbike""></i> Asignar delivery</button>")
        End If

        If Not contactado Then
            sb.Append("<button type=""button"" class=""dropdown-item"" onclick=""marcarContactado(" & pid & ")""><i class=""ti ti-phone-check""></i> Marcar contactado</button>")
        End If

        sb.Append("<button type=""button"" class=""dropdown-item"" onclick=""copiarParaWhatsApp(" & pid & ")""><i class=""ti ti-copy""></i> Copiar info WhatsApp</button>")

        If celLimpio <> "" Then
            sb.Append("<button type=""button"" class=""dropdown-item"" onclick=""llamarCliente('" & celLimpio & "')""><i class=""ti ti-phone""></i> Llamar al receptor</button>")
        End If

        ' Admin
        If esAdmin Then
            sb.Append("<div class=""dropdown-divider""></div>")
            sb.Append("<div class=""dropdown-section-label"">Administración</div>")
            sb.Append("<button type=""button"" class=""dropdown-item edit-action"" onclick=""editarPedido(" & pid & ")""><i class=""ti ti-edit""></i> Editar pedido</button>")
            sb.Append("<button type=""button"" class=""dropdown-item danger-action"" onclick=""cancelarPedido(" & pid & ")""><i class=""ti ti-trash""></i> Cancelar pedido</button>")
        End If

        sb.Append("</div></div>")
        sb.Append("</div>")
        Return sb.ToString()
    End Function

    ' ============================================================
    ' ACCION URGENTE CONTEXTUAL (botón coloreado)
    ' ============================================================
    Private Function ObtenerAccionUrgente(pid As Integer, estadoOp As String, estadoPago As String, deliveryId As Integer, receptor As String, total As Decimal, wcNumber As String) As String
        Dim clienteJs As String = HEjs(receptor)

        ' Prioridad 1: WC pendiente de pago -> Aceptar pago
        If wcNumber <> "" AndAlso estadoPago = "PENDIENTE" Then
            Return "<button type=""button"" class=""btn-urgente-pago"" title=""Aceptar pago manual"" onclick=""abrirModalAceptar(" & pid & ",'" & clienteJs & "','" & total.ToString("N2") & "')""><i class=""ti ti-cash""></i></button>"
        End If

        ' Prioridad 2: Sin delivery y estado >= IMPRESO -> Asignar delivery
        If deliveryId <= 0 AndAlso (estadoOp = "IMPRESO" OrElse estadoOp = "EN_PREPARACION" OrElse estadoOp = "LISTO") Then
            Return "<button type=""button"" class=""btn-urgente-deli"" title=""Asignar delivery"" onclick=""asignarDelivery(" & pid & ")""><i class=""ti ti-motorbike""></i></button>"
        End If

        Return ""
    End Function

    ' ============================================================
    ' BADGES DE ESTADO
    ' ============================================================
    Private Function RenderBadgePago(estado As String, pagado As Decimal, total As Decimal, wcNumber As String) As String
        If estado = "PENDIENTE" AndAlso wcNumber <> "" Then
            Return "<span class=""badge badge-pago-verificar"" title=""Pago WC pendiente""><i class=""ti ti-alert-circle""></i> Pago x verif. &middot; Bs " & total.ToString("N0") & "</span>"
        End If

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
    ' FLUJO DE ESTADOS (botones del dropdown "más")
    ' ============================================================
    Private Function ObtenerAccionPrincipal(pid As Integer, estado As String) As String
        Select Case estado
            Case "PENDIENTE"
                Return "<button type=""button"" class=""dropdown-item next-step"" onclick=""imprimirTicket(" & pid & ")""><i class=""ti ti-printer""></i> Imprimir ticket</button>"
            Case "IMPRESO"
                Return "<button type=""button"" class=""dropdown-item next-step"" onclick=""cambiarEstado(" & pid & ",'EN_PREPARACION')""><i class=""ti ti-flower""></i> En preparación</button>"
            Case "EN_PREPARACION"
                Return "<button type=""button"" class=""dropdown-item next-step"" onclick=""cambiarEstado(" & pid & ",'LISTO')""><i class=""ti ti-package""></i> Marcar como Listo</button>"
            Case "LISTO"
                Return "<button type=""button"" class=""dropdown-item next-step"" onclick=""cambiarEstado(" & pid & ",'EN_RUTA')""><i class=""ti ti-truck-delivery""></i> Marcar En ruta</button>"
            Case "EN_RUTA"
                Return "<button type=""button"" class=""dropdown-item next-step"" onclick=""cambiarEstado(" & pid & ",'ENTREGADO')""><i class=""ti ti-circle-check""></i> Marcar Entregado</button>"
            Case "NO_ENTREGADO"
                Return "<button type=""button"" class=""dropdown-item next-step"" onclick=""cambiarEstado(" & pid & ",'REPROGRAMADO')""><i class=""ti ti-refresh""></i> Reprogramar</button>"
            Case Else
                Return ""
        End Select
    End Function

    Private Function ObtenerAccionVolver(pid As Integer, estado As String) As String
        Select Case estado
            Case "IMPRESO"
                Return "<button type=""button"" class=""dropdown-item back-step"" onclick=""cambiarEstado(" & pid & ",'PENDIENTE')""><i class=""ti ti-arrow-back""></i> Volver a Pendiente</button>"
            Case "EN_PREPARACION"
                Return "<button type=""button"" class=""dropdown-item back-step"" onclick=""cambiarEstado(" & pid & ",'IMPRESO')""><i class=""ti ti-arrow-back""></i> Volver a Impreso</button>"
            Case "LISTO"
                Return "<button type=""button"" class=""dropdown-item back-step"" onclick=""cambiarEstado(" & pid & ",'EN_PREPARACION')""><i class=""ti ti-arrow-back""></i> Volver a En prep.</button>"
            Case "EN_RUTA"
                Return "<button type=""button"" class=""dropdown-item back-step"" onclick=""cambiarEstado(" & pid & ",'NO_ENTREGADO')""><i class=""ti ti-circle-x""></i> Marcar No entregado</button>"
            Case Else
                Return ""
        End Select
    End Function

    ' ============================================================
    ' HELPERS
    ' ============================================================
    Private Function ObtenerIconoMetodoPago(metodo As String) As String
        If metodo Is Nothing Then Return "ti-credit-card"
        Dim m = metodo.ToLower()
        If m.Contains("qr") OrElse m.Contains("bisa") OrElse m.Contains("bacs") OrElse m.Contains("banconacional") Then Return "ti-qrcode"
        If m.Contains("transfer") OrElse m.Contains("bnb") OrElse m.Contains("bank") Then Return "ti-building-bank"
        If m.Contains("efectivo") OrElse m.Contains("cash") OrElse m.Contains("cod") OrElse m.Contains("contra") Then Return "ti-cash"
        If m.Contains("paypal") OrElse m.Contains("ppcp") Then Return "ti-brand-paypal"
        Return "ti-credit-card"
    End Function

    Private Function ObtenerIniciales(nombre As String) As String
        If nombre Is Nothing OrElse nombre.Trim() = "" Then Return "?"
        Dim partes = nombre.Trim().Split(" "c)
        If partes.Length >= 2 Then
            Return (partes(0).Substring(0, 1) & partes(1).Substring(0, 1)).ToUpper()
        End If
        Return partes(0).Substring(0, Math.Min(2, partes(0).Length)).ToUpper()
    End Function

    Private Function FormatearFechaCorta(f As DateTime) As String
        Dim hoy = DateTime.Today
        If f.Date = hoy Then Return "Hoy"
        If f.Date = hoy.AddDays(1) Then Return "Mañana"
        If f.Date < hoy Then Return "Pasada"
        Return f.ToString("dd/MM") & " " & DiaSemanaCorto(f)
    End Function

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
            Case DayOfWeek.Wednesday : Return "Mié"
            Case DayOfWeek.Thursday : Return "Jue"
            Case DayOfWeek.Friday : Return "Vie"
            Case DayOfWeek.Saturday : Return "Sáb"
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
            Case "EN_PREPARACION" : Return "En preparación"
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
