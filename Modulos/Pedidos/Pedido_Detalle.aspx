<%@ Page Title="Detalle Pedido" Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false" CodeBehind="Pedido_Detalle.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_Pedido_Detalle" %>

<asp:Content ID="ContentTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Pedido <%=Codigo%> — SISCONBOL
</asp:Content>

<asp:Content ID="ContentPage" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-shopping-bag" style="vertical-align:-2px"></i> Pedido <%=Codigo%>
</asp:Content>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

<style>
.pd-hd{background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);border-radius:12px;padding:18px;color:#fff;margin-bottom:14px}
.pd-hd .breadcrumb{font-size:12px;opacity:.9;margin-bottom:6px}
.pd-hd .breadcrumb a{color:#fff;text-decoration:underline}
.pd-hd h2{margin:0;font-size:22px;font-weight:500}
.pd-hd h2 .sl{font-size:13px;font-weight:400;opacity:.85;margin-left:6px}
.pd-hd .meta{font-size:12px;opacity:.85;margin-top:3px}

.estados{display:flex;flex-wrap:wrap;gap:6px;margin-top:12px}
.e-pill{padding:4px 10px;border-radius:99px;font-size:11px;font-weight:500;background:rgba(255,255,255,.22);display:inline-flex;align-items:center;gap:4px}
.e-pill i{font-size:13px}
.e-pill.op-PENDIENTE  {background:#FFF3E0;color:#E65100}
.e-pill.op-PREPARANDO {background:#E3F2FD;color:#1565C0}
.e-pill.op-EN_CAMINO  {background:#FFF8E1;color:#856404}
.e-pill.op-ENTREGADO  {background:#E8F5E9;color:#1B5E20}
.e-pill.op-FALLIDO    {background:#FFEBEE;color:#C62828}
.e-pill.pago-PAGADO   {background:#E8F5E9;color:#1B5E20}
.e-pill.pago-ANTICIPO {background:#FFF8E1;color:#856404}
.e-pill.pago-PENDIENTE{background:#F1F1F1;color:#5F5E5A}
.e-pill.pago-REEMBOLSADO{background:#FFEBEE;color:#C62828}
.e-pill.wc-ok {background:#F3E5F5;color:#6A1B9A}
.e-pill.wc-no {background:#ECEFF1;color:#37474F}

.hd-actions{display:flex;gap:6px;flex-wrap:wrap;margin-top:12px}
.btn-hd{background:rgba(255,255,255,.18);color:#fff;border:0.5px solid rgba(255,255,255,.4);padding:7px 12px;border-radius:6px;font-size:12px;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;gap:5px;font-weight:500}
.btn-hd:hover{background:rgba(255,255,255,.28)}
.btn-hd.wsp{background:#E8F5E9;color:#1B5E20;border-color:#A5D6A7}

.pd-panel{background:#fff;border:1px solid #e0e0e0;border-radius:8px;margin-bottom:12px;overflow:hidden}
.pd-panel-head{padding:10px 14px;border-bottom:1px solid #f0f0f0;display:flex;align-items:center;gap:8px;font-size:13px;font-weight:500;color:#212121}
.pd-panel-head i{font-size:16px;color:#7F77DD}
.pd-panel-body{padding:14px}

.grid-2{display:grid;grid-template-columns:repeat(2,1fr);gap:12px}
.grid-3{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}
@media(max-width:480px){.grid-3{grid-template-columns:repeat(2,1fr)}}
.f-lbl{font-size:10px;color:#9e9e9e;text-transform:uppercase;letter-spacing:.3px;margin-bottom:2px}
.f-val{font-size:13px;font-weight:500;color:#212121}
.f-val .small{font-size:11px;color:#9e9e9e;font-weight:400;display:block;margin-top:1px}
.f-val.empty{color:#bdbdbd;font-weight:400;font-style:italic}

.prod-row{display:flex;align-items:center;gap:10px;padding:10px 0;border-bottom:1px solid #f0f0f0}
.prod-row:last-child{border-bottom:none}
.prod-thumb{width:42px;height:42px;border-radius:6px;background:#FCE4EC;display:flex;align-items:center;justify-content:center;font-size:18px;color:#C2185B;flex-shrink:0}
.prod-info{flex:1;min-width:0}
.prod-nom{font-size:13px;font-weight:500;color:#212121;margin:0 0 1px}
.prod-desc{font-size:11px;color:#9e9e9e;margin:0}
.prod-pers{font-size:11px;color:#6A1B9A;margin:2px 0 0;font-style:italic}
.prod-precio{text-align:right;flex-shrink:0}
.prod-precio .cant{font-size:11px;color:#9e9e9e}
.prod-precio .sub{font-size:13px;font-weight:600;color:#212121}

.dedi-card{background:#FFF8E1;border-left:3px solid #FBC02D;padding:12px 14px;border-radius:6px;font-size:13px;color:#5F4B00;font-style:italic;line-height:1.5}
.dedi-firma{margin-top:6px;font-size:12px;color:#7A5C00;font-style:normal;font-weight:500}

.tot-tabla{border:1px solid #e0e0e0;border-radius:6px;overflow:hidden}
.tot-row{display:flex;justify-content:space-between;padding:8px 14px;font-size:13px;border-bottom:1px solid #f0f0f0;background:#fff}
.tot-row:last-child{border-bottom:none}
.tot-row.desc   {color:#C62828}
.tot-row.recargo{color:#E65100}
.tot-row.total  {background:#7F77DD;color:#fff;font-weight:600;font-size:14px}

.pago-row{display:flex;align-items:center;justify-content:space-between;padding:10px 0;border-bottom:1px solid #f0f0f0;font-size:13px;gap:10px}
.pago-row:last-child{border-bottom:none}
.pago-info{flex:1;min-width:0}
.pago-info .met{font-weight:500;color:#212121}
.pago-info .det{font-size:11px;color:#9e9e9e;margin-top:2px}
.pago-monto{font-weight:600;text-align:right;flex-shrink:0}
.pago-monto .estado-mini{display:block;font-size:10px;font-weight:400;margin-top:2px}
.pago-monto .estado-mini.v{color:#1B5E20}
.pago-monto .estado-mini.p{color:#E65100}
.pago-monto .estado-mini.r{color:#C62828}

.nota-int{background:#F3E5F5;border-left:3px solid #6A1B9A;padding:10px 12px;border-radius:6px;font-size:12px;color:#4A148C;line-height:1.5}
.obs-int{background:#FAFAFA;border-left:3px solid #9e9e9e;padding:10px 12px;border-radius:6px;font-size:12px;color:#424242;line-height:1.5;margin-top:8px}

.empty-state{text-align:center;padding:24px;color:#9e9e9e;font-size:12px;font-style:italic}

.footer-acc{display:flex;gap:8px;justify-content:flex-end;flex-wrap:wrap;margin-top:14px}
.btn-back{background:#fff;border:1px solid #e0e0e0;padding:8px 14px;border-radius:6px;font-size:12px;cursor:pointer;display:inline-flex;align-items:center;gap:5px;color:#424242;text-decoration:none}
.btn-back:hover{background:#fafafa}

.alerta-error{background:#FFEBEE;border-left:3px solid #C62828;padding:12px 14px;border-radius:6px;color:#B71C1C;font-size:13px;margin-bottom:12px}

.btn-editar-entrega{margin-left:auto;background:#EEEDFE;color:#534AB7;border:0.5px solid #CECBF6;padding:5px 11px;border-radius:6px;font-size:11px;cursor:pointer;display:inline-flex;align-items:center;gap:5px;font-weight:500}
.btn-editar-entrega:hover{background:#CECBF6}

.pe-overlay{position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:9999;display:none;align-items:flex-start;justify-content:center;padding:40px 16px;overflow-y:auto}
.pe-overlay.show{display:flex}
.pe-modal{background:#fff;border-radius:10px;max-width:580px;width:100%;border:1px solid #d0d0d0;overflow:hidden}
.pe-hd{padding:14px 18px;border-bottom:1px solid #ececec;display:flex;align-items:center;gap:8px}
.pe-hd i{font-size:17px;color:#7F77DD}
.pe-hd .ti{font-size:17px;color:#7F77DD}
.pe-hd-title{font-size:14px;font-weight:500;color:#212121;flex:1}
.pe-close{background:transparent;border:none;color:#9e9e9e;font-size:18px;cursor:pointer;padding:0;line-height:1}
.pe-warn{padding:10px 18px;background:#FFF8E1;border-bottom:1px solid #FBC02D;font-size:11px;color:#5F4B00;display:flex;gap:6px;align-items:flex-start}
.pe-warn i{font-size:14px;color:#E65100;flex-shrink:0;margin-top:1px}
.pe-body{padding:14px 18px}
.pe-sect-title{font-size:11px;font-weight:500;color:#534AB7;text-transform:uppercase;letter-spacing:.3px;margin-bottom:8px;display:flex;align-items:center;gap:5px}
.pe-sect-title i{font-size:13px}
.pe-group{margin-bottom:14px}
.pe-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:8px}
.pe-field{display:flex;flex-direction:column}
.pe-label{font-size:11px;color:#666;margin-bottom:3px}
.pe-input,.pe-select{width:100%;padding:7px 9px;font-size:13px;border:1px solid #d0d0d0;border-radius:6px;background:#fff;font-family:inherit;box-sizing:border-box}
.pe-input:focus,.pe-select:focus{outline:none;border-color:#7F77DD;box-shadow:0 0 0 2px rgba(127,119,221,.15)}
.pe-radio-group{display:flex;gap:14px;padding:6px 0}
.pe-radio-group label{font-size:13px;display:inline-flex;align-items:center;gap:5px;cursor:pointer}
.pe-msg{padding:8px 12px;border-radius:6px;font-size:12px;margin-bottom:10px;display:none}
.pe-msg.error{background:#FFEBEE;color:#B71C1C;border-left:3px solid #C62828;display:block}
.pe-msg.ok{background:#E8F5E9;color:#1B5E20;border-left:3px solid #1B5E20;display:block}
.pe-foot{padding:11px 18px;border-top:1px solid #ececec;background:#fafafa;display:flex;gap:8px;justify-content:flex-end}
.pe-btn{padding:7px 14px;border-radius:6px;font-size:12px;cursor:pointer;font-family:inherit;display:inline-flex;align-items:center;gap:5px}
.pe-btn-cancel{background:#fff;color:#424242;border:1px solid #d0d0d0}
.pe-btn-save{background:#7F77DD;color:#fff;border:1px solid #7F77DD;font-weight:500}
.pe-btn-save:hover{background:#6A62D0}
.pe-btn-save:disabled{background:#bdbdbd;border-color:#bdbdbd;cursor:wait}
</style>

<% If TienePedido Then %>

<!-- HEADER -->
<div class="pd-hd">
    <div class="breadcrumb">
        <i class="ti ti-arrow-left" aria-hidden="true"></i>
        <a href="PrePedido_Detalle.aspx?id=<%=PrePedidoId%>">Pre-Pedido <%=PrePedidoCodigo%></a> ›
    </div>
    <h2>Pedido <%=Codigo%></h2>
    <div class="meta">Creado <%=FechaCreacion%><%=If(CreadorNombre <> "", " por " & CreadorNombre, "")%></div>

    <div class="estados">
        <span class="e-pill op-<%=EstadoOperativo%>"><i class="ti ti-package" aria-hidden="true"></i> <%=EstadoOperativoLabel%></span>
        <span class="e-pill pago-<%=EstadoPago%>"><i class="ti ti-cash" aria-hidden="true"></i> <%=EstadoPagoLabel%></span>
        <% If WcOrderId > 0 Then %>
            <span class="e-pill wc-ok"><i class="ti ti-brand-woocommerce" aria-hidden="true"></i> WC <%=WcOrderNumberMostrar%></span>
        <% Else %>
            <span class="e-pill wc-no"><i class="ti ti-brand-woocommerce" aria-hidden="true"></i> Sin WC</span>
        <% End If %>
    </div>

    <div class="hd-actions">
        <a class="btn-hd" href="Recibo.aspx?id=<%=PedidoId%>" target="_blank">
            <i class="ti ti-printer" aria-hidden="true"></i> Imprimir recibo
        </a>
        <% If WcOrderId > 0 Then %>
            <a class="btn-hd" href="https://miss-flores.com/wp-admin/post.php?post=<%=WcOrderId%>&action=edit" target="_blank">
                <i class="ti ti-brand-woocommerce" aria-hidden="true"></i> Ver en WC
            </a>
        <% End If %>
        <% If ReceptorCelular <> "" Then %>
            <a class="btn-hd wsp" href="https://wa.me/591<%=ReceptorCelular%>" target="_blank">
                <i class="ti ti-brand-whatsapp" aria-hidden="true"></i> WhatsApp receptor
            </a>
        <% End If %>
    </div>
</div>

<!-- DATOS DE ENTREGA -->
<div class="pd-panel">
    <div class="pd-panel-head">
        <i class="ti ti-truck-delivery" aria-hidden="true"></i> Datos de entrega
        <% If PuedeEditar Then %>
            <button type="button" class="btn-editar-entrega" onclick="peAbrirModal()">
                <i class="ti ti-edit" style="font-size:12px" aria-hidden="true"></i> Editar entrega
            </button>
        <% End If %>
    </div>
    <div class="pd-panel-body">
        <div class="grid-2" style="margin-bottom:12px">
            <div>
                <div class="f-lbl">Receptor</div>
                <div class="f-val"><%=ReceptorNombre%><% If ReceptorCelular <> "" Then %><span class="small"><%=ReceptorCelular%></span><% End If %></div>
            </div>
            <div>
                <div class="f-lbl">Fecha entrega</div>
                <div class="f-val"><%=FechaEntrega%><% If Horario <> "" Then %><span class="small"><%=Horario%></span><% End If %></div>
            </div>
            <div>
                <div class="f-lbl">Tipo</div>
                <div class="f-val"><%=TipoEntregaLabel%></div>
            </div>
            <div>
                <div class="f-lbl">Express</div>
                <div class="f-val" style="<%=If(EsExpress, "color:#E65100", "")%>"><%=If(EsExpress, "Sí", "No")%></div>
            </div>
            <div>
                <div class="f-lbl">Ciudad</div>
                <div class="f-val"><%=Ciudad%></div>
            </div>
            <div>
                <div class="f-lbl">Zona</div>
                <div class="f-val <%=If(Zona = "", "empty", "")%>"><%=If(Zona = "", "Sin zona", Zona)%></div>
            </div>
        </div>
        <% If Direccion <> "" Then %>
        <div>
            <div class="f-lbl">Dirección</div>
            <div class="f-val" style="font-weight:400"><%=Direccion%><% If Referencia <> "" Then %><span class="small">Ref: <%=Referencia%></span><% End If %></div>
        </div>
        <% End If %>
    </div>
</div>

<!-- PRODUCTOS -->
<div class="pd-panel">
    <div class="pd-panel-head">
        <i class="ti ti-flower" aria-hidden="true"></i> Productos
        <span style="font-weight:400;color:#9e9e9e;font-size:11px;margin-left:auto"><%=CantidadItems%> ítems</span>
    </div>
    <div class="pd-panel-body" style="padding:8px 14px">
        <% If HtmlProductos <> "" Then %>
            <%=HtmlProductos%>
        <% Else %>
            <div class="empty-state">Sin productos registrados</div>
        <% End If %>
    </div>
</div>

<!-- DEDICATORIA -->
<% If Dedicatoria <> "" OrElse FirmaTarjeta <> "" OrElse TipoOcacion <> "" Then %>
<div class="pd-panel">
    <div class="pd-panel-head"><i class="ti ti-mail-heart" aria-hidden="true"></i> Dedicatoria y ocasión</div>
    <div class="pd-panel-body">
        <% If Dedicatoria <> "" Then %>
        <div class="dedi-card">
            "<%=Dedicatoria%>"
            <% If FirmaTarjeta <> "" Then %>
                <div class="dedi-firma">— Firma: <%=FirmaTarjeta%></div>
            <% End If %>
        </div>
        <% End If %>
        <% If TipoOcacion <> "" Then %>
        <div style="margin-top:10px;font-size:12px;color:#9e9e9e">
            <strong style="color:#424242">Ocasión:</strong> <%=TipoOcacionLabel%>
        </div>
        <% End If %>
    </div>
</div>
<% End If %>

<!-- TOTALES -->
<div class="pd-panel">
    <div class="pd-panel-head"><i class="ti ti-calculator" aria-hidden="true"></i> Resumen económico</div>
    <div class="pd-panel-body">
        <div class="tot-tabla">
            <div class="tot-row"><span>Subtotal productos</span><span><%=SubtotalProductosBs%> Bs</span></div>
            <div class="tot-row"><span>Envío</span><span><%=EnvioBs%> Bs</span></div>
            <% If RecargoExpressBsNum > 0 Then %>
            <div class="tot-row recargo"><span>Recargo express</span><span>+<%=RecargoExpressBs%> Bs</span></div>
            <% End If %>
            <% If RecargoHorarioBsNum > 0 Then %>
            <div class="tot-row recargo"><span>Recargo horario</span><span>+<%=RecargoHorarioBs%> Bs</span></div>
            <% End If %>
            <% If DescuentoBsNum > 0 Then %>
            <div class="tot-row desc"><span>Descuento</span><span>−<%=DescuentoBs%> Bs</span></div>
            <% End If %>
            <div class="tot-row total"><span>TOTAL</span><span><%=TotalBs%> Bs</span></div>
        </div>
        <% If TotalUsd <> "0.00" Then %>
        <div style="margin-top:10px;font-size:11px;color:#9e9e9e;text-align:right">
            Equivalente: <%=TotalUsd%> USD
        </div>
        <% End If %>
    </div>
</div>

<!-- PAGOS -->
<div class="pd-panel">
    <div class="pd-panel-head">
        <i class="ti ti-credit-card" aria-hidden="true"></i> Pagos
        <span style="margin-left:auto;font-size:11px;font-weight:400;color:#9e9e9e">Estado: <strong style="color:#424242"><%=EstadoPagoLabel%></strong></span>
    </div>
    <div class="pd-panel-body">
        <div class="grid-3" style="margin-bottom:14px">
            <div><div class="f-lbl">Anticipo</div><div class="f-val"><%=AnticipoBs%> Bs</div></div>
            <div><div class="f-lbl">Saldo</div><div class="f-val" style="<%=If(SaldoBsNum > 0, "color:#E65100", "")%>"><%=SaldoBs%> Bs</div></div>
            <div><div class="f-lbl">Total</div><div class="f-val"><%=TotalBs%> Bs</div></div>
        </div>
        <% If HtmlPagos <> "" Then %>
            <%=HtmlPagos%>
        <% Else %>
            <div class="empty-state">No hay pagos registrados</div>
        <% End If %>
    </div>
</div>

<!-- NOTAS INTERNAS -->
<% If NotaFloreria <> "" OrElse Observaciones <> "" Then %>
<div class="pd-panel">
    <div class="pd-panel-head"><i class="ti ti-note" aria-hidden="true"></i> Notas internas</div>
    <div class="pd-panel-body">
        <% If NotaFloreria <> "" Then %>
        <div class="nota-int">
            <strong>Nota florería:</strong> <%=NotaFloreria%>
        </div>
        <% End If %>
        <% If Observaciones <> "" Then %>
        <div class="obs-int">
            <strong>Observaciones:</strong> <%=Observaciones%>
        </div>
        <% End If %>
    </div>
</div>
<% End If %>

<!-- INFO OPERATIVA -->
<div class="pd-panel">
    <div class="pd-panel-head"><i class="ti ti-building-store" aria-hidden="true"></i> Información operativa</div>
    <div class="pd-panel-body">
        <div class="grid-2">
            <div>
                <div class="f-lbl">Sucursal prepara</div>
                <div class="f-val <%=If(SucursalPrepara = "", "empty", "")%>"><%=If(SucursalPrepara = "", "Sin asignar", SucursalPrepara)%></div>
            </div>
            <div>
                <div class="f-lbl">Estado sync WC</div>
                <div class="f-val"><%=WcSyncEstado%><% If WcSyncFecha <> "" Then %><span class="small"><%=WcSyncFecha%></span><% End If %></div>
            </div>
            <% If WcOrderId > 0 Then %>
            <div>
                <div class="f-lbl">WC Order</div>
                <div class="f-val"><%=WcOrderNumberMostrar%><% If WcOrderStatus <> "" Then %><span class="small"><%=WcOrderStatus%></span><% End If %></div>
            </div>
            <% End If %>
            <% If WcPaymentMethodTitle <> "" Then %>
            <div>
                <div class="f-lbl">Método pago WC</div>
                <div class="f-val"><%=WcPaymentMethodTitle%></div>
            </div>
            <% End If %>
        </div>
    </div>
</div>

<!-- FOOTER -->
<div class="footer-acc">
    <a class="btn-back" href="PrePedido_Detalle.aspx?id=<%=PrePedidoId%>">
        <i class="ti ti-arrow-left" aria-hidden="true"></i> Volver al pre-pedido
    </a>
</div>

<!-- ============================================================ -->
<!-- MODAL: Editar datos de entrega (solo Admin/Gerente)           -->
<!-- ============================================================ -->
<% If PuedeEditar Then %>
<div id="peOverlay" class="pe-overlay" role="dialog" aria-modal="true" aria-labelledby="peTitle">
    <div class="pe-modal">
        <div class="pe-hd">
            <i class="ti ti-edit" aria-hidden="true"></i>
            <div class="pe-hd-title" id="peTitle">Editar datos de entrega — <%=Codigo%></div>
            <button type="button" class="pe-close" onclick="peCerrarModal()" aria-label="Cerrar"><i class="ti ti-x" aria-hidden="true"></i></button>
        </div>

        <div class="pe-warn">
            <i class="ti ti-alert-triangle" aria-hidden="true"></i>
            <span>Estás editando un pedido confirmado. Los cambios quedan registrados en auditoría.</span>
        </div>

        <div class="pe-body">

            <div id="peMsg" class="pe-msg"></div>

            <!-- Fecha y horario -->
            <div class="pe-group">
                <div class="pe-sect-title"><i class="ti ti-calendar" aria-hidden="true"></i> Fecha y horario</div>
                <div class="pe-grid">
                    <div class="pe-field">
                        <label class="pe-label">Fecha entrega *</label>
                        <input type="date" id="peFecha" class="pe-input" value="<%=FechaEntregaInput%>" min="<%=FechaMinima%>">
                    </div>
                    <div class="pe-field">
                        <label class="pe-label">Horario</label>
                        <select id="peSlot" class="pe-select">
                            <option value="">-- Sin horario --</option>
                            <%=HtmlSlotsEdit%>
                        </select>
                    </div>
                </div>
            </div>

            <!-- Tipo de entrega -->
            <div class="pe-group">
                <div class="pe-sect-title"><i class="ti ti-truck-delivery" aria-hidden="true"></i> Tipo de entrega</div>
                <div class="pe-radio-group">
                    <label><input type="radio" name="peTipoEntrega" value="DOMICILIO" <%=If(TipoEntregaRaw <> "RECOJO_SUCURSAL", "checked", "")%> onchange="peToggleTipoEntrega()"> Domicilio</label>
                    <label><input type="radio" name="peTipoEntrega" value="RECOJO_SUCURSAL" <%=If(TipoEntregaRaw = "RECOJO_SUCURSAL", "checked", "")%> onchange="peToggleTipoEntrega()"> Recojo en sucursal</label>
                </div>
            </div>

            <!-- Ciudad (siempre) -->
            <div class="pe-group">
                <div class="pe-field">
                    <label class="pe-label">Ciudad *</label>
                    <select id="peCiudad" class="pe-select" onchange="peFiltrarZonas()">
                        <option value="">-- Seleccionar --</option>
                        <%=HtmlCiudadesEdit%>
                    </select>
                </div>
            </div>

            <!-- DOMICILIO: Zona + Dirección + Referencia -->
            <div id="peCamposDomicilio" class="pe-group">
                <div class="pe-sect-title"><i class="ti ti-map-pin" aria-hidden="true"></i> Dirección de entrega</div>
                <div class="pe-grid">
                    <div class="pe-field">
                        <label class="pe-label">Zona *</label>
                        <input type="text" id="peZonaTexto" class="pe-input" placeholder="Escriba para buscar zona..." list="peDlZonas" autocomplete="off" value="<%=ZonaNombreActual%>" onchange="peSeleccionarZona(this.value)" onkeydown="if(event.key==='Enter'){event.preventDefault();return false;}">
                        <datalist id="peDlZonas"></datalist>
                        <input type="hidden" id="peZonaId" value="<%=If(ZonaIdActual>0, ZonaIdActual.ToString(), "")%>">
                    </div>
                    <div class="pe-field">
                        <label class="pe-label">Dirección *</label>
                        <input type="text" id="peDireccion" class="pe-input" maxlength="300" value="<%=Server.HtmlEncode(Direccion)%>">
                    </div>
                </div>
                <div class="pe-field" style="margin-top:8px">
                    <label class="pe-label">Referencia</label>
                    <input type="text" id="peReferencia" class="pe-input" maxlength="300" value="<%=Server.HtmlEncode(Referencia)%>">
                </div>
            </div>

            <!-- RECOJO: Sucursal -->
            <div id="peCamposRecojo" class="pe-group" style="display:none">
                <div class="pe-sect-title"><i class="ti ti-building-store" aria-hidden="true"></i> Sucursal de recojo</div>
                <div class="pe-field">
                    <label class="pe-label">Sucursal *</label>
                    <select id="peSucursal" class="pe-select">
                        <option value="">-- Seleccionar --</option>
                        <%=HtmlSucursalesEdit%>
                    </select>
                </div>
            </div>

            <!-- Motivo -->
            <div class="pe-group">
                <label class="pe-label"><i class="ti ti-message-circle" style="font-size:12px;vertical-align:-1px" aria-hidden="true"></i> Motivo del cambio (opcional)</label>
                <input type="text" id="peMotivo" class="pe-input" maxlength="500" placeholder="Ej: Cliente cambió dirección a último momento">
            </div>

        </div>

        <div class="pe-foot">
            <button type="button" class="pe-btn pe-btn-cancel" onclick="peCerrarModal()">Cancelar</button>
            <button type="button" id="peBtnGuardar" class="pe-btn pe-btn-save" onclick="peGuardar()">
                <i class="ti ti-device-floppy" style="font-size:13px" aria-hidden="true"></i> Guardar cambios
            </button>
        </div>
    </div>
</div>
<% End If %>

<% Else %>
<div class="alerta-error">
    <i class="ti ti-alert-circle" style="vertical-align:-2px"></i>
    <%=MensajeError%>
</div>
<div class="footer-acc">
    <a class="btn-back" href="PrePedidos.aspx">
        <i class="ti ti-arrow-left" aria-hidden="true"></i> Volver a la lista
    </a>
</div>
<% End If %>

</asp:Content>

<asp:Content ID="ContentScripts" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

<% If TienePedido AndAlso PuedeEditar Then %>
// ====================================================================
// PEDIDO_DETALLE - Modal de edicion de entrega
// ====================================================================

var PEDIDO_ID = <%=PedidoId%>;
var PE_ZONAS = <%=ZonasJson%>;

function peAbrirModal(){
    var ov = document.getElementById('peOverlay');
    if(!ov) return;
    ov.classList.add('show');
    peLimpiarMsg();
    peToggleTipoEntrega();
    peFiltrarZonas();
}

function peCerrarModal(){
    var ov = document.getElementById('peOverlay');
    if(!ov) return;
    ov.classList.remove('show');
}

function peMostrarMsg(tipo, texto){
    var m = document.getElementById('peMsg');
    if(!m) return;
    m.className = 'pe-msg ' + tipo;
    m.textContent = texto;
}

function peLimpiarMsg(){
    var m = document.getElementById('peMsg');
    if(!m) return;
    m.className = 'pe-msg';
    m.textContent = '';
}

function peToggleTipoEntrega(){
    var radios = document.getElementsByName('peTipoEntrega');
    var tipo = 'DOMICILIO';
    for(var i=0;i<radios.length;i++){
        if(radios[i].checked){ tipo = radios[i].value; break; }
    }
    var dom = document.getElementById('peCamposDomicilio');
    var rec = document.getElementById('peCamposRecojo');
    if(tipo === 'RECOJO_SUCURSAL'){
        if(dom) dom.style.display = 'none';
        if(rec) rec.style.display = '';
    } else {
        if(dom) dom.style.display = '';
        if(rec) rec.style.display = 'none';
    }
}

function peFiltrarZonas(){
    var cidSel = document.getElementById('peCiudad');
    var dl = document.getElementById('peDlZonas');
    if(!dl) return;
    var cid = cidSel ? parseInt(cidSel.value) || 0 : 0;
    dl.innerHTML = '';
    if(!PE_ZONAS || !PE_ZONAS.length) return;
    for(var i=0;i<PE_ZONAS.length;i++){
        var z = PE_ZONAS[i];
        if(cid > 0 && z.ciudad_id !== cid) continue;
        var opt = document.createElement('option');
        opt.value = z.nombre;
        opt.setAttribute('data-id', z.zona_id);
        dl.appendChild(opt);
    }
}

function peSeleccionarZona(texto){
    var hd = document.getElementById('peZonaId');
    if(!hd) return;
    if(!texto){ hd.value = ''; return; }
    var t = texto.trim().toLowerCase();
    var encontrada = null;
    for(var i=0;i<PE_ZONAS.length;i++){
        if(PE_ZONAS[i].nombre.toLowerCase() === t){ encontrada = PE_ZONAS[i]; break; }
    }
    if(encontrada){
        hd.value = encontrada.zona_id;
    } else {
        hd.value = '';
    }
}

function peValidar(){
    var fecha = (document.getElementById('peFecha') || {}).value || '';
    if(!fecha){ peMostrarMsg('error', 'Debe indicar la fecha de entrega.'); return false; }

    var radios = document.getElementsByName('peTipoEntrega');
    var tipo = 'DOMICILIO';
    for(var i=0;i<radios.length;i++){
        if(radios[i].checked){ tipo = radios[i].value; break; }
    }

    var cid = parseInt((document.getElementById('peCiudad')||{}).value) || 0;
    if(cid <= 0){ peMostrarMsg('error', 'Debe seleccionar una ciudad.'); return false; }

    if(tipo === 'DOMICILIO'){
        var zid = parseInt((document.getElementById('peZonaId')||{}).value) || 0;
        if(zid <= 0){ peMostrarMsg('error', 'Debe seleccionar una zona valida de la lista.'); return false; }
        var dir = ((document.getElementById('peDireccion')||{}).value || '').trim();
        if(!dir){ peMostrarMsg('error', 'La direccion es obligatoria para entrega a domicilio.'); return false; }
    } else {
        var sid = parseInt((document.getElementById('peSucursal')||{}).value) || 0;
        if(sid <= 0){ peMostrarMsg('error', 'Debe seleccionar una sucursal de recojo.'); return false; }
    }
    return true;
}

function peGuardar(){
    peLimpiarMsg();
    if(!peValidar()) return;

    var radios = document.getElementsByName('peTipoEntrega');
    var tipo = 'DOMICILIO';
    for(var i=0;i<radios.length;i++){
        if(radios[i].checked){ tipo = radios[i].value; break; }
    }

    var fd = new FormData();
    fd.append('accion', 'ACTUALIZAR_ENTREGA');
    fd.append('pedido_id', PEDIDO_ID);
    fd.append('fecha_entrega', (document.getElementById('peFecha')||{}).value || '');
    fd.append('slot_id', (document.getElementById('peSlot')||{}).value || '');
    fd.append('tipo_entrega', tipo);
    fd.append('ciudad_id', (document.getElementById('peCiudad')||{}).value || '');

    if(tipo === 'DOMICILIO'){
        fd.append('zona_id', (document.getElementById('peZonaId')||{}).value || '');
        fd.append('direccion', ((document.getElementById('peDireccion')||{}).value || '').trim());
        fd.append('referencia', ((document.getElementById('peReferencia')||{}).value || '').trim());
        fd.append('sucursal_id', '');
    } else {
        fd.append('zona_id', '');
        fd.append('direccion', '');
        fd.append('referencia', '');
        fd.append('sucursal_id', (document.getElementById('peSucursal')||{}).value || '');
    }
    fd.append('motivo', ((document.getElementById('peMotivo')||{}).value || '').trim());

    var btn = document.getElementById('peBtnGuardar');
    if(btn) btn.disabled = true;

    fetch('PedidoEditar_Handler.ashx', { method: 'POST', body: fd, credentials: 'same-origin' })
        .then(function(r){ return r.text(); })
        .then(function(txt){
            var data = null;
            try { data = JSON.parse(txt); } catch(e){ data = null; }
            if(!data){
                peMostrarMsg('error', 'Respuesta invalida del servidor.');
                if(btn) btn.disabled = false;
                return;
            }
            if(data.ok){
                peMostrarMsg('ok', data.msg || 'Guardado.');
                setTimeout(function(){ window.location.reload(); }, 700);
            } else {
                peMostrarMsg('error', data.msg || 'Error al guardar.');
                if(btn) btn.disabled = false;
            }
        })
        .catch(function(err){
            peMostrarMsg('error', 'Error de red: ' + err);
            if(btn) btn.disabled = false;
        });
}

// Cerrar al hacer click en el overlay (fuera del modal)
document.addEventListener('DOMContentLoaded', function(){
    var ov = document.getElementById('peOverlay');
    if(ov){
        ov.addEventListener('click', function(e){
            if(e.target === ov) peCerrarModal();
        });
    }
});
<% End If %>
</script>
</asp:Content>
