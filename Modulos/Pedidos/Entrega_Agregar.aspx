<%@ Page Title="Gestionar Entrega" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Entrega_Agregar.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_Entrega_Agregar" %>

<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
.ea-section { background:white; border:1px solid #e0e0e0; border-radius:12px; margin-bottom:8px; overflow:hidden; }
.ea-section-header { padding:10px 20px; cursor:pointer; display:flex; align-items:center; justify-content:space-between; }
.ea-section-header:hover { background:#fafafa; }
.ea-section-title { display:flex; align-items:center; gap:8px; font-size:14px; font-weight:500; }
.ea-section-summary { font-size:11px; color:#999; }
.ea-section-body { padding:0 20px 16px; border-top:1px solid #f0f0f0; }
.ea-bar { background:white; border:1px solid #e0e0e0; border-radius:12px; padding:8px 16px; margin-bottom:10px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px; }
.ea-bar-left { display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
.ea-bar-sep { width:1px; height:20px; background:#e0e0e0; }
.ea-productos { background:white; border:1px solid #e0e0e0; border-radius:12px; padding:16px 20px; margin-bottom:8px; }
.ea-prod-header { display:flex; align-items:center; justify-content:space-between; margin-bottom:10px; padding-bottom:8px; border-bottom:1px solid #f0f0f0; }
.ea-prod-row { display:flex; flex-direction:column; gap:6px; padding:10px 12px; background:#fafafa; border-radius:8px; margin-bottom:4px; font-size:14px; }
.ea-prod-row.personalizado { background:#FFF8E1; border:1px solid #FFE082; }
.ea-prod-name { font-weight:500; font-size:14px; display:block; word-break:break-word; line-height:1.35; }
/* === ESTRUCTURA CARD VERTICAL (nombre arriba, precio abajo) === */
.ea-prod-card-row1 { display:flex; justify-content:space-between; align-items:flex-start; gap:8px; }
.ea-prod-card-row1 > div:first-child { flex:1; min-width:0; }
.ea-prod-card-detail { font-size:11px; color:#999; display:flex; align-items:center; gap:4px; padding-left:0; }
.ea-prod-card-detail span { color:#F57F17; font-style:italic; word-break:break-word; }
.ea-prod-card-row2 { display:flex; justify-content:space-between; align-items:center; padding-top:5px; border-top:0.5px solid #eee; }
.ea-prod-card-precio-label { font-size:10px; color:#999; text-transform:uppercase; letter-spacing:0.3px; }
.ea-prod-card-precio { font-size:14px; font-weight:600; color:#3B5BDB; }
.ea-prod-card-precio-input { width:80px; text-align:right; padding:3px 6px; font-size:13px; font-weight:600; color:#F57F17; border:1px solid #FFE082; border-radius:6px; background:#fff; }
.ea-prod-card-cant { display:flex; align-items:center; gap:5px; font-size:11px; color:#999; }
.ea-prod-card-cant input { width:48px; text-align:center; padding:3px; font-size:12px; border:1px solid #FFE082; border-radius:4px; }
.ea-prod-card-del { width:30px; height:30px; min-width:30px; border-radius:6px; background:#fff; border:1px solid #FFCDD2; color:#E53935; font-size:15px; display:flex; align-items:center; justify-content:center; cursor:pointer; flex-shrink:0; padding:0; }
.ea-prod-card-del:hover { background:#FFEBEE; }
/* === PRECIO EDITABLE EN BUSCADOR === */
.ea-price-edit { display:inline-flex; align-items:center; gap:3px; background:#F0F4FF; border:1px solid #BBDEFB; border-radius:8px; padding:4px 6px 4px 9px; flex-shrink:0; }
.ea-price-edit.modificado { background:#FFF8E1; border-color:#F57F17; }
.ea-price-edit .ea-price-curr { font-size:12px; color:#3B5BDB; font-weight:500; }
.ea-price-edit.modificado .ea-price-curr { color:#F57F17; }
.ea-price-edit input { width:70px; border:none; background:transparent; font-size:14px; font-weight:600; color:#3B5BDB; text-align:right; outline:none; padding:0; -moz-appearance:textfield; }
.ea-price-edit.modificado input { color:#F57F17; }
.ea-price-edit input::-webkit-outer-spin-button, .ea-price-edit input::-webkit-inner-spin-button { -webkit-appearance:none; margin:0; }
.ea-price-edit .ea-price-edit-ico { font-size:11px; color:#F57F17; margin-left:2px; opacity:0; transition:opacity 0.2s; }
.ea-price-edit.modificado .ea-price-edit-ico { opacity:1; }
.ea-prod-detail { font-size:12px; color:#999; display:block; margin-top:2px; }
.ea-prod-detail span { color:#667eea; }
.ea-prod-custom { font-size:12px; color:#F57F17; display:block; margin-top:2px; word-break:break-word; }
.ea-btn-buscar { font-size:12px; background:#EBF0FF; color:#3B5BDB; border:none; padding:5px 12px; border-radius:8px; cursor:pointer; }
.ea-btn-buscar:hover { background:#D6E0FF; }
.ea-btn-wsp { font-size:11px; padding:5px 10px; background:#E8F5E9; color:#2E7D32; border:1px solid #A5D6A7; border-radius:8px; }
.ea-btn-link { font-size:11px; padding:5px 10px; background:#EBF0FF; color:#3B5BDB; border:1px solid #90CAF9; border-radius:8px; }
.ea-btn-pago { font-size:11px; padding:4px 10px; background:#EBF0FF; color:#3B5BDB; border:1px solid #90CAF9; border-radius:8px; }
.ea-grid-2 { display:grid; grid-template-columns:1fr 1fr; gap:10px; }
.ea-grid-3 { display:grid; grid-template-columns:1fr 1fr 1fr; gap:10px; }
.ea-label { font-size:12px; font-weight:500; display:block; margin-bottom:3px; }
.ea-input { width:100%; padding:7px 10px; border:1px solid #d0d0d0; border-radius:6px; font-size:13px; }
.ea-input:focus { outline:none; border-color:#667eea; box-shadow:0 0 0 3px rgba(102,126,234,0.1); }
.ea-select { width:100%; padding:7px 10px; border:1px solid #d0d0d0; border-radius:6px; font-size:13px; background:white; }
.ea-textarea { width:100%; padding:7px 10px; border:1px solid #d0d0d0; border-radius:6px; font-size:13px; resize:vertical; min-height:60px; }
.ea-radio-group { display:flex; gap:1.5rem; align-items:center; height:36px; }
.ea-radio-label { display:flex; align-items:center; gap:4px; font-size:12px; cursor:pointer; }
.ea-dom-fields { background:#fafafa; border-radius:8px; padding:10px; margin-top:10px; }
.ea-recojo-fields { background:#fafafa; border-radius:8px; padding:12px; margin-top:10px; }
.ea-sucursal-card { flex:1; padding:12px; border-radius:8px; border:1px solid #e0e0e0; cursor:pointer; text-align:center; }
.ea-sucursal-card.selected { border:2px solid #3B5BDB; background:#EBF0FF; }
.ea-resumen { background:white; border:1px solid #e0e0e0; border-radius:12px; padding:16px 20px; margin-bottom:8px; }
.ea-total-row { display:flex; justify-content:space-between; font-size:13px; padding:2px 0; }
.ea-total-row.final { padding-top:6px; margin-top:4px; border-top:2px solid #333; font-size:15px; font-weight:500; }
.ea-pago-row { display:grid; grid-template-columns:1fr 80px 70px 80px 50px 30px; gap:6px; align-items:center; padding:7px 4px; background:#fafafa; border-radius:8px; margin-bottom:3px; font-size:12px; }
.ea-pago-header { display:grid; grid-template-columns:1fr 80px 70px 80px 50px 30px; gap:6px; font-size:10px; color:#aaa; text-transform:uppercase; padding:0 4px; margin-bottom:4px; }
.ea-link-states { display:grid; grid-template-columns:1fr 1fr 1fr; gap:8px; margin-bottom:10px; }
.ea-link-state { text-align:center; padding:8px; border-radius:8px; border:1px solid #e0e0e0; }
.ea-link-state.active { border:2px solid #F9A825; background:#FFF8E1; }
.ea-link-state.inactive { opacity:0.4; }
.ea-check-grid { display:grid; grid-template-columns:1fr 1fr; gap:3px 16px; font-size:12px; margin-bottom:12px; }
.ea-check-item { display:flex; align-items:center; gap:5px; padding:2px 0; }
.ea-btn-wc { width:100%; font-size:13px; padding:11px; display:flex; align-items:center; justify-content:center; gap:7px; background:#EBF0FF; color:#3B5BDB; border:1px solid #90CAF9; border-radius:8px; cursor:pointer; font-weight:500; }
.ea-btn-wc:disabled { background:#f5f5f5; color:#ccc; border-color:#e0e0e0; cursor:not-allowed; }
.ea-badge { font-size:11px; padding:2px 8px; border-radius:10px; }
.ea-badge-warning { background:#FFF8E1; color:#F57F17; }
.ea-badge-success { background:#E8F5E9; color:#2E7D32; }
.ea-badge-count { font-size:11px; color:#999; background:#f5f5f5; padding:2px 8px; border-radius:10px; }
.ea-saved { font-size:11px; color:#2E7D32; display:flex; align-items:center; gap:3px; }
.ea-descuento-row { display:flex; justify-content:space-between; align-items:center; margin-top:4px; padding-top:4px; border-top:1px solid #f0f0f0; }
.ea-descuento-input { display:flex; align-items:center; gap:4px; }
.ea-pago-resumen { margin-top:10px; padding-top:8px; border-top:1px solid #f0f0f0; font-size:13px; }
.ea-modal-overlay { display:none; position:fixed; top:0; left:0; right:0; bottom:0; background:rgba(0,0,0,0.45); z-index:9999; overflow-y:auto; padding:20px; }
.ea-modal { background:white; border-radius:12px; max-width:820px; margin:0 auto; border:1px solid #e0e0e0; }
.ea-modal-sm { max-width:450px; margin:40px auto; }
.ea-modal-header { padding:12px 20px; border-bottom:1px solid #f0f0f0; display:flex; justify-content:space-between; align-items:center; background:#fafafa; border-radius:12px 12px 0 0; }
.ea-modal-close { border:none; background:none; cursor:pointer; font-size:18px; color:#999; }
.ea-badge-count { font-size:11px; color:#999; background:#f5f5f5; padding:2px 8px; border-radius:10px; }
.ea-saved { font-size:11px; color:#2E7D32; display:flex; align-items:center; gap:3px; }
.ea-descuento-row { display:flex; justify-content:space-between; align-items:center; margin-top:4px; padding-top:4px; border-top:1px solid #f0f0f0; }
.ea-descuento-input { display:flex; align-items:center; gap:4px; }
.ea-pago-resumen { margin-top:10px; padding-top:8px; border-top:1px solid #f0f0f0; font-size:13px; }

/* === TOAST DE NOTIFICACIÓN === */
.ea-toast-container { position:fixed; top:20px; right:20px; z-index:10000; display:flex; flex-direction:column; gap:8px; pointer-events:none; }
.ea-toast { background:white; border-radius:10px; padding:12px 18px; min-width:260px; max-width:380px; box-shadow:0 4px 20px rgba(0,0,0,0.15); display:flex; align-items:center; gap:10px; font-size:14px; font-weight:500; pointer-events:auto; animation:eaToastIn 0.25s ease-out; border-left:4px solid #ccc; }
.ea-toast.ok { border-left-color:#2E7D32; color:#1B5E20; }
.ea-toast.ok i { color:#2E7D32; font-size:22px; }
.ea-toast.warn { border-left-color:#F57F17; color:#E65100; }
.ea-toast.warn i { color:#F57F17; font-size:22px; }
.ea-toast.err { border-left-color:#C62828; color:#B71C1C; }
.ea-toast.err i { color:#C62828; font-size:22px; }
.ea-toast.fade-out { animation:eaToastOut 0.3s ease-in forwards; }
@keyframes eaToastIn { from { transform:translateX(420px); opacity:0; } to { transform:translateX(0); opacity:1; } }
@keyframes eaToastOut { from { transform:translateX(0); opacity:1; } to { transform:translateX(420px); opacity:0; } }

/* === RESPONSIVE: CELULAR/TABLET PEQUEÑO (≤768px) === */
@media (max-width: 768px) {
    .ea-bar { flex-direction:column; align-items:stretch; gap:8px; padding:10px 12px; }
    .ea-bar-left { flex-wrap:wrap; justify-content:space-between; }
    .ea-bar-sep { display:none; }
    .ea-grid-2 { grid-template-columns:1fr; gap:8px; }
    .ea-grid-3 { grid-template-columns:1fr; gap:8px; }
    .ea-check-grid { grid-template-columns:1fr; }
    .ea-link-states { grid-template-columns:1fr 1fr 1fr; gap:4px; }

    /* Modales ocupan casi toda la pantalla */
    .ea-modal-overlay { padding:8px; }
    .ea-modal, .ea-modal-sm { max-width:100%; margin:0 auto; }
    .ea-modal-header { padding:10px 14px; }

    /* Filas de productos: en móvil se reducen padding y separadores */
    .ea-prod-row { padding:9px 10px; }

    /* Fila de pagos: cambia a 2 filas (la primera nombre + monto, segunda fecha + estado + acción) */
    .ea-pago-row { grid-template-columns:1fr 90px 30px; grid-auto-rows:auto; padding:8px 6px; gap:4px; }
    .ea-pago-row > span:nth-child(3), .ea-pago-row > span:nth-child(4), .ea-pago-row > span:nth-child(5) { font-size:10px; color:#aaa; }
    .ea-pago-header { display:none; }

    /* Toast ocupa más espacio en mobile */
    .ea-toast-container { top:10px; left:10px; right:10px; }
    .ea-toast { min-width:0; max-width:100%; }

    /* Resumen / panels más compactos */
    .ea-resumen, .ea-productos { padding:12px 14px; }
    .ea-section-header { padding:10px 14px; }
    .ea-section-body { padding:0 14px 12px; }

    /* Monto de pago: grande en mobile para mejor legibilidad */
    #txPagoMonto { font-size:18px !important; padding:10px 12px !important; text-align:right; font-weight:500; }
}

/* === TOGGLE PRODUCTO PERSONALIZADO === */
.ea-toggle-pers { display:flex; align-items:center; gap:5px; padding:5px 11px; border:1px solid #e0e0e0; border-radius:8px; background:#fff; font-size:11px; color:#666; cursor:pointer; white-space:nowrap; flex-shrink:0; user-select:none; font-weight:500; transition:all 0.15s ease; }
.ea-toggle-pers:hover { border-color:#FFE082; background:#FFFEF7; color:#F57F17; }
.ea-toggle-pers.active { border-color:#FFE082; background:#FFF8E1; color:#F57F17; }
.ea-toggle-pers input[type=checkbox] { accent-color:#F57F17; width:13px; height:13px; margin:0; }

/* === PANEL PERSONALIZADO === */
.ea-pers-label { font-size:11px; color:#7A5A0F; font-weight:500; margin-bottom:5px; display:flex; align-items:center; gap:4px; }
.ea-pers-textarea { width:100%; border:1px dashed #d0d0d0; border-radius:7px; padding:9px 11px; font-size:13px; color:#333; outline:none; background:#FFFEF7; resize:vertical; min-height:90px; font-family:inherit; line-height:1.45; box-sizing:border-box; }
.ea-pers-textarea::placeholder { color:#bbb; font-style:italic; }
.ea-pers-textarea:focus { border-color:#F57F17; border-style:solid; background:#fff; }

/* Monto: ancho completo, gigante */
.ea-pers-monto-input { width:100%; border:2px solid #F57F17; border-radius:10px; padding:18px 18px; font-size:32px; font-weight:700; color:#F57F17; text-align:right; outline:none; background:#fff; letter-spacing:0.5px; box-sizing:border-box; -moz-appearance:textfield; }
.ea-pers-monto-input::-webkit-outer-spin-button, .ea-pers-monto-input::-webkit-inner-spin-button { -webkit-appearance:none; margin:0; }
.ea-pers-monto-input::placeholder { color:#FFD699; font-weight:400; }
.ea-pers-monto-input:focus { box-shadow:0 0 0 3px rgba(245,127,23,0.15); background:#FFFEF7; }

/* Moneda pills */
.ea-pers-moneda-btn { border:1.5px solid #e0e0e0; background:#fff; color:#999; border-radius:8px; padding:11px 14px; font-size:14px; font-weight:600; cursor:pointer; display:flex; align-items:center; justify-content:center; gap:5px; transition:all 0.15s ease; }
.ea-pers-moneda-btn:hover { border-color:#FFE082; color:#F57F17; }
.ea-pers-moneda-btn.active { border-color:#F57F17; background:#FFF8E1; color:#F57F17; }
.ea-pers-moneda-btn .check-ico { font-size:14px; opacity:0; transition:opacity 0.15s ease; }
.ea-pers-moneda-btn.active .check-ico { opacity:1; }
</style>
</asp:Content>

<asp:Content ID="ContentTitle" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-package" style="vertical-align:-2px"></i> <%=If(ModoEdicion, "Editar", "Agregar")%> Entrega
</asp:Content>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

<div class="alerta" id="divAlerta"><%=MensajeAlerta%></div>

<!-- HEADER INFO -->
<div class="panel" style="margin-bottom:10px">
    <div class="panel-head">
        <div class="panel-title"><i class="ti ti-shopping-cart"></i> Pre-Pedido: <%=PrePedidoCodigo%></div>
        <div class="panel-actions">
            <a href="PrePedido_Detalle.aspx?id=<%=PrePedidoId%>" class="btn btn-sm"><i class="ti ti-arrow-left"></i> Volver</a>
        </div>
    </div>
    <div class="panel-body">
        <div style="display:grid;grid-template-columns:1fr 1fr 1fr 1fr;gap:8px;align-items:end">
            <div>
                <label class="ea-label" style="font-size:10px;color:#999;margin-bottom:2px">Cliente - Nombre</label>
                <input type="text" id="txClienteNombre" class="ea-input" style="padding:6px 8px;font-size:13px" value="<%=ClienteNombreSolo%>" onblur="guardarCliente('cliente_nombre', this.value)" onkeydown="if(event.key==='Enter'){event.preventDefault();this.blur();return false;}" />
            </div>
            <div>
                <label class="ea-label" style="font-size:10px;color:#999;margin-bottom:2px">Apellidos</label>
                <input type="text" id="txClienteApellidos" class="ea-input" style="padding:6px 8px;font-size:13px" value="<%=ClienteApellidosSolo%>" onblur="guardarCliente('cliente_apellidos', this.value)" onkeydown="if(event.key==='Enter'){event.preventDefault();this.blur();return false;}" />
            </div>
            <div>
                <label class="ea-label" style="font-size:10px;color:#999;margin-bottom:2px">Celular</label>
                <input type="text" id="txClienteCelular" class="ea-input" style="padding:6px 8px;font-size:13px" value="<%=ClienteCelular%>" onblur="guardarCliente('cliente_celular', this.value)" onkeydown="if(event.key==='Enter'){event.preventDefault();this.blur();return false;}" />
            </div>
            <div>
                <label class="ea-label" style="font-size:10px;color:#999;margin-bottom:2px">Email</label>
                <input type="email" id="txClienteEmail" class="ea-input" style="padding:6px 8px;font-size:13px" value="<%=ClienteEmail%>" onblur="guardarCliente('cliente_email', this.value)" onkeydown="if(event.key==='Enter'){event.preventDefault();this.blur();return false;}" />
            </div>
        </div>
    </div>
</div>

<!-- BARRA ACCIONES -->
<div class="ea-bar">
    <div class="ea-bar-left">
        <select id="ddMoneda" name="ddMoneda" class="ea-select" style="width:auto;padding:3px 8px;font-size:12px" onchange="guardarCampo('moneda', this.value); calcularSubtotal();">
            <option value="BOB" <%=If(MonedaSeleccionada = "BOB", "selected", "")%>>Bs</option>
            <option value="USD" <%=If(MonedaSeleccionada = "USD", "selected", "")%>>USD</option>
        </select>
        <div class="ea-bar-sep"></div>
        <div style="display:flex;align-items:center;gap:4px">
            <i class="ti ti-building-store" style="font-size:14px;color:#999" aria-hidden="true"></i>
            <span style="font-size:11px;color:#999">Prepara:</span>
            <select id="ddSucursalPrepara" name="ddSucursalPrepara" class="ea-select" style="width:auto;padding:3px 8px;font-size:12px" onchange="guardarCampo('sucursal_prepara_id', this.value)">
                <option value="0">No definido</option>
                <%=HtmlSucursales%>
            </select>
        </div>
        <div class="ea-bar-sep"></div>
        <span class="ea-saved" id="spanGuardado"><i class="ti ti-check" style="font-size:13px" aria-hidden="true"></i> Guardado</span>
    </div>
    <div style="display:flex;gap:6px">
        <button type="button" class="ea-btn-wsp" onclick="enviarCotizacionWsp()"><i class="ti ti-brand-whatsapp" style="font-size:14px;vertical-align:-2px" aria-hidden="true"></i> Cotizacion</button>
        <button type="button" class="ea-btn-link" onclick="enviarLinkCliente()"><i class="ti ti-link" style="font-size:14px;vertical-align:-2px" aria-hidden="true"></i> Enviar link</button>
    </div>
</div>

<!-- ============================================ -->
<!-- 1. PRODUCTOS -->
<!-- ============================================ -->
<div class="ea-productos">
    <div class="ea-prod-header">
        <div style="display:flex;align-items:center;gap:8px">
            <i class="ti ti-shopping-bag" style="font-size:17px;color:#3B5BDB" aria-hidden="true"></i>
            <span style="font-size:14px;font-weight:500">Productos</span>
            <span class="ea-badge-count" id="spanCantItems">0 items</span>
        </div>
        <button type="button" class="ea-btn-buscar" onclick="abrirBuscadorProductos()"><i class="ti ti-search" style="font-size:14px;vertical-align:-2px" aria-hidden="true"></i> Buscar producto</button>
    </div>
    <div style="display:grid;grid-template-columns:1fr 110px 36px;gap:10px;font-size:11px;color:#aaa;text-transform:uppercase;padding:0 12px;margin-bottom:4px">
        <span>Producto</span><span>Precio</span><span></span>
    </div>
    <div id="divProductos"><%=HtmlProductos%></div>
    <div style="display:flex;justify-content:flex-end;gap:1rem;margin-top:8px;padding-top:8px;border-top:1px solid #f0f0f0;font-size:13px">
        <span style="color:#999">Subtotal:</span>
        <span style="font-weight:500" id="spanSubtotal">Bs 0.00</span>
    </div>
</div>

<!-- ============================================ -->
<!-- 2. DATOS DE ENTREGA (colapsable) -->
<!-- ============================================ -->
<div class="ea-section">
    <div class="ea-section-header" onclick="toggleSeccion('secEntrega')">
        <div class="ea-section-title">
            <i class="ti ti-chevron-down" id="secEntregaArrow" aria-hidden="true"></i>
            <i class="ti ti-truck-delivery" style="color:#3B5BDB" aria-hidden="true"></i>
            Datos de entrega
        </div>
        <span class="ea-section-summary" id="secEntregaResumen"></span>
    </div>
    <div class="ea-section-body" id="secEntregaBody">
        <div class="ea-grid-2" style="padding-top:10px;margin-bottom:10px">
            <div>
                <label class="ea-label">Ciudad *</label>
                <select id="ddCiudad" name="ddCiudad" class="ea-select" onchange="filtrarZonas(); guardarCampo('ciudad_id', this.value)">
                    <option value="">-- Seleccionar --</option>
                    <%=HtmlCiudades%>
                </select>
            </div>
            <div>
                <label class="ea-label">Tipo de entrega *</label>
                <div class="ea-radio-group">
                    <label class="ea-radio-label"><input type="radio" name="tipoEntrega" value="DOMICILIO" <%=If(ValorTipoEntrega <> "RECOJO_SUCURSAL", "checked", "")%> onchange="toggleTipoEntrega(); guardarCampo('tipo_entrega', 'DOMICILIO')"> Domicilio</label>
                    <label class="ea-radio-label"><input type="radio" name="tipoEntrega" value="RECOJO_SUCURSAL" <%=If(ValorTipoEntrega = "RECOJO_SUCURSAL", "checked", "")%> onchange="toggleTipoEntrega(); guardarCampo('tipo_entrega', 'RECOJO_SUCURSAL')"> Recojo</label>
                </div>
            </div>
        </div>
        <!-- DOMICILIO -->
        <div id="fieldsDomicilio" class="ea-dom-fields">
            <div class="ea-grid-2" style="margin-bottom:8px">
                <div>
                    <label class="ea-label">Zona *</label>
                    <input type="text" id="txZonaBuscar" class="ea-input" placeholder="Escriba para buscar zona..." list="dlZonas" autocomplete="off" value="<%=ValorZonaTexto%>" onchange="seleccionarZona(this.value)" onkeydown="if(event.key==='Enter'){event.preventDefault();return false;}">
                    <datalist id="dlZonas"></datalist>
                    <input type="hidden" id="hdZonaId" name="ddZona" value="<%=If(ValorZonaId>0, ValorZonaId.ToString(), "")%>">
                </div>
                <div>
                    <label class="ea-label">Direccion *</label>
                    <input type="text" id="txDireccion" name="txDireccion" class="ea-input" value="<%=ValorDireccion%>" onblur="guardarCampo('direccion', this.value)" onkeydown="if(event.key==='Enter'){event.preventDefault();this.blur();return false;}">
                </div>
            </div>
            <div class="ea-grid-2">
                <div>
                    <label class="ea-label">Referencia</label>
                    <input type="text" id="txReferencia" name="txReferencia" class="ea-input" value="<%=ValorReferencia%>" onblur="guardarCampo('referencia', this.value)" onkeydown="if(event.key==='Enter'){event.preventDefault();this.blur();return false;}">
                </div>
                <div>
                    <label class="ea-label">GPS / Nota</label>
                    <input type="text" id="txGps" name="txGps" class="ea-input" value="<%=ValorGps%>" placeholder="Coordenadas o nota interna..." onblur="guardarCampo('gps', this.value)" onkeydown="if(event.key==='Enter'){event.preventDefault();this.blur();return false;}">
                </div>
            </div>
        </div>
        <!-- RECOJO -->
        <div id="fieldsRecojo" class="ea-recojo-fields" style="display:none">
            <label class="ea-label" style="margin-bottom:8px">Sucursal de recojo:</label>
            <div style="display:flex;gap:12px">
                <%=HtmlSucursalesRecojo%>
            </div>
        </div>
    </div>
</div>

<!-- ============================================ -->
<!-- 3. FECHA Y HORARIO (colapsable) -->
<!-- ============================================ -->
<div class="ea-section">
    <div class="ea-section-header" onclick="toggleSeccion('secFecha')">
        <div class="ea-section-title">
            <i class="ti ti-chevron-down" id="secFechaArrow" aria-hidden="true"></i>
            <i class="ti ti-calendar" style="color:#3B5BDB" aria-hidden="true"></i>
            Fecha y horario
        </div>
        <span class="ea-section-summary" id="secFechaResumen"></span>
    </div>
    <div class="ea-section-body" id="secFechaBody">
        <div class="ea-grid-3" style="padding-top:10px">
            <div>
                <label class="ea-label">Fecha de entrega *</label>
                <input type="date" id="txFecha" name="txFecha" class="ea-input" value="<%=ValorFecha%>" min="<%=FechaMinima%>" onchange="guardarCampo('fecha_entrega', this.value)" onkeydown="if(event.key==='Enter'){event.preventDefault();return false;}">
            </div>
            <div>
                <label class="ea-label">Horario</label>
                <select id="ddSlot" name="ddSlot" class="ea-select" onchange="guardarCampo('slot_id', this.value); sincronizarExpressConSlot(); calcularSubtotal()">
                    <option value="">-- Seleccionar --</option>
                    <%=HtmlSlots%>
                </select>
            </div>
            <div>
                <label class="ea-label">&nbsp;</label>
                <!-- chkExpress: solo informativo, se auto-marca según el slot. NO suma al total. -->
                <label class="ea-radio-label" style="height:36px;cursor:default;opacity:0.85" title="Se marca automáticamente si el horario elegido es Express (no afecta el total, el recargo ya está en el slot)">
                    <input type="checkbox" id="chkExpress" name="chkExpress" disabled <%=If(ValorExpress, "checked", "")%>>
                    <span style="font-size:12px">Express <i class="ti ti-info-circle" style="font-size:11px;color:#999;vertical-align:-1px" aria-hidden="true"></i></span>
                </label>
            </div>
        </div>
    </div>
</div>

<!-- ============================================ -->
<!-- 4. DESTINATARIO Y DEDICATORIA (colapsable) -->
<!-- ============================================ -->
<div class="ea-section">
    <div class="ea-section-header" onclick="toggleSeccion('secDestinatario')">
        <div class="ea-section-title">
            <i class="ti ti-chevron-down" id="secDestinatarioArrow" aria-hidden="true"></i>
            <i class="ti ti-user-heart" style="color:#3B5BDB" aria-hidden="true"></i>
            Destinatario y dedicatoria
        </div>
        <span class="ea-section-summary" id="secDestinatarioResumen"></span>
    </div>
    <div class="ea-section-body" id="secDestinatarioBody">
        <div class="ea-grid-3" style="padding-top:10px;margin-bottom:10px">
            <div>
                <label class="ea-label">Persona que recibe *</label>
                <input type="text" id="txReceptor" name="txReceptor" class="ea-input" value="<%=ValorReceptor%>" onblur="guardarCampo('receptor_nombre', this.value)" onkeydown="if(event.key==='Enter'){event.preventDefault();this.blur();return false;}">
            </div>
            <div>
                <label class="ea-label">Celular *</label>
                <input type="text" id="txCelularReceptor" name="txCelularReceptor" class="ea-input" value="<%=ValorCelularReceptor%>" onblur="guardarCampo('receptor_celular', this.value)" onkeydown="if(event.key==='Enter'){event.preventDefault();this.blur();return false;}">
            </div>
            <div>
                <label class="ea-label">Ocasion</label>
                <select id="ddOcasion" name="ddOcasion" class="ea-select" onchange="guardarCampo('tipo_ocacion', this.value)">
                    <option value="">-- Seleccionar --</option>
                    <option value="CUMPLEANOS" <%=If(ValorOcasion = "CUMPLEANOS", "selected", "")%>>Cumpleaños</option>
                    <option value="ANIVERSARIO" <%=If(ValorOcasion = "ANIVERSARIO", "selected", "")%>>Aniversario</option>
                    <option value="CONDOLENCIAS" <%=If(ValorOcasion = "CONDOLENCIAS", "selected", "")%>>Condolencias</option>
                    <option value="AGRADECIMIENTO" <%=If(ValorOcasion = "AGRADECIMIENTO", "selected", "")%>>Agradecimiento</option>
                    <option value="AMOR" <%=If(ValorOcasion = "AMOR", "selected", "")%>>Amor</option>
                    <option value="NACIMIENTO" <%=If(ValorOcasion = "NACIMIENTO", "selected", "")%>>Nacimiento</option>
                    <option value="GRADUACION" <%=If(ValorOcasion = "GRADUACION", "selected", "")%>>Graduacion</option>
                    <option value="OTRO" <%=If(ValorOcasion = "OTRO", "selected", "")%>>Otro</option>
                </select>
            </div>
        </div>
        <div style="margin-bottom:8px">
            <label class="ea-label">Dedicatoria <span style="color:#999;font-weight:400">(500)</span></label>
            <textarea id="txDedicatoria" name="txDedicatoria" class="ea-textarea" maxlength="500" onblur="guardarCampo('dedicatoria', this.value)"><%=ValorDedicatoria%></textarea>
        </div>
        <div>
            <label class="ea-label">Firma <span style="color:#999;font-weight:400">(100)</span></label>
            <input type="text" id="txFirma" name="txFirma" class="ea-input" value="<%=ValorFirma%>" maxlength="100" onblur="guardarCampo('firma_tarjeta', this.value)" onkeydown="if(event.key==='Enter'){event.preventDefault();this.blur();return false;}">
        </div>
    </div>
</div>

<!-- ============================================ -->
<!-- 5. RESUMEN -->
<!-- ============================================ -->
<div class="ea-resumen">
    <div style="display:flex;align-items:center;gap:8px;margin-bottom:8px;padding-bottom:8px;border-bottom:1px solid #f0f0f0">
        <i class="ti ti-receipt" style="font-size:17px;color:#3B5BDB" aria-hidden="true"></i>
        <span style="font-size:14px;font-weight:500">Resumen</span>
    </div>
    <div id="divResumen">
        <div class="ea-total-row"><span style="color:#999">Subtotal productos</span><span id="resSubtotal">Bs 0.00</span></div>
        <div class="ea-total-row"><span style="color:#999">Envío</span><span id="resEnvio">Bs 0.00</span></div>
        <div class="ea-total-row"><span style="color:#999">Recargo horario</span><span id="resRecargoHorario">Bs 0.00</span></div>
        <!-- Recargo express eliminado: el recargo ya viene incluido en "Recargo horario" según el slot elegido. Se mantiene el span oculto por compatibilidad. -->
        <span id="resRecargoExpress" style="display:none">Bs 0.00</span>
        <div class="ea-descuento-row">
            <span style="color:#2E7D32"><i class="ti ti-discount-2" style="font-size:14px;vertical-align:-2px" aria-hidden="true"></i> Descuento</span>
            <div class="ea-descuento-input">
                <span style="font-size:12px;color:#2E7D32">-</span>
                <input type="number" id="txDescuento" name="txDescuento" value="<%=ValorDescuento%>" min="0" max="100" step="5" style="width:55px;text-align:center;padding:3px;font-size:12px;border:1px solid #d0d0d0;border-radius:4px" onblur="guardarCampo('descuento_valor', this.value); calcularSubtotal()" onchange="calcularSubtotal()" onkeydown="if(event.key==='Enter'){event.preventDefault();this.blur();return false;}">
                <select id="ddDescuentoMoneda" name="ddDescuentoMoneda" style="width:auto;padding:3px 4px;font-size:11px;border:1px solid #d0d0d0;border-radius:4px" onchange="guardarCampo('descuento_moneda', this.value)">
                    <option value="BOB" <%=If(ValorDescuentoMoneda = "BOB" Or ValorDescuentoMoneda = "", "selected", "")%>>Bs</option>
                    <option value="USD" <%=If(ValorDescuentoMoneda = "USD", "selected", "")%>>USD</option>
                </select>
            </div>
        </div>
        <p style="margin:0;font-size:10px;color:#999">Máx 100 Bs / 15 USD</p>
        <div class="ea-total-row final"><span>Total</span><span id="resTotal">Bs 0.00</span></div>
    </div>
</div>

<!-- ============================================ -->
<!-- 6. PAGOS -->
<!-- ============================================ -->
<div class="ea-resumen">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:10px;padding-bottom:8px;border-bottom:1px solid #f0f0f0">
        <div style="display:flex;align-items:center;gap:8px">
            <i class="ti ti-cash" style="font-size:17px;color:#3B5BDB" aria-hidden="true"></i>
            <span style="font-size:14px;font-weight:500">Pagos</span>
            <span class="ea-badge ea-badge-warning" id="spanEstadoPago">Pendiente</span>
        </div>
        <button type="button" class="ea-btn-pago" onclick="abrirModalPago()"><i class="ti ti-plus" style="font-size:13px;vertical-align:-1px" aria-hidden="true"></i> Registrar pago</button>
    </div>
    <div class="ea-pago-header"><span>Método</span><span>Monto</span><span>Moneda</span><span>Fecha</span><span>Verif.</span><span></span></div>
    <div id="divPagos"><%=HtmlPagos%></div>
    <div class="ea-pago-resumen">
        <div style="display:flex;justify-content:space-between;margin-bottom:3px"><span style="color:#999">Total pedido:</span><span id="pagoTotal">Bs 0.00</span></div>
        <div style="display:flex;justify-content:space-between;margin-bottom:3px"><span style="color:#999">Total pagado:</span><span style="color:#2E7D32" id="pagoPagado">Bs 0.00</span></div>
        <div style="display:flex;justify-content:space-between;font-weight:500"><span style="color:#E53935">Saldo pendiente:</span><span style="color:#E53935" id="pagoSaldo">Bs 0.00</span></div>
    </div>
</div>

<!-- ============================================ -->
<!-- 7. ESTADO DEL LINK -->
<!-- ============================================ -->
<div class="ea-resumen">
    <div style="display:flex;align-items:center;gap:8px;margin-bottom:10px;padding-bottom:8px;border-bottom:1px solid #f0f0f0">
        <i class="ti ti-link" style="font-size:17px;color:#3B5BDB" aria-hidden="true"></i>
        <span style="font-size:14px;font-weight:500">Estado del link</span>
    </div>
    <div class="ea-link-states">
        <div class="ea-link-state <%=If(EstadoLink = 0, "active", "inactive")%>">
            <div style="width:26px;height:26px;border-radius:50%;background:#f5f5f5;display:flex;align-items:center;justify-content:center;margin:0 auto 4px"><i class="ti ti-link-off" style="font-size:14px;color:#999" aria-hidden="true"></i></div>
            <p style="margin:0;font-size:10px;font-weight:500">No enviado</p>
        </div>
        <div class="ea-link-state <%=If(EstadoLink = 1, "active", "inactive")%>">
            <div style="width:26px;height:26px;border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center;margin:0 auto 4px"><i class="ti ti-clock" style="font-size:14px;color:#F9A825" aria-hidden="true"></i></div>
            <p style="margin:0;font-size:10px;font-weight:500">Esperando</p>
        </div>
        <div class="ea-link-state <%=If(EstadoLink = 2, "active", "inactive")%>">
            <div style="width:26px;height:26px;border-radius:50%;background:#f5f5f5;display:flex;align-items:center;justify-content:center;margin:0 auto 4px"><i class="ti ti-check" style="font-size:14px;color:#2E7D32" aria-hidden="true"></i></div>
            <p style="margin:0;font-size:10px;font-weight:500">Completó</p>
        </div>
    </div>
    <button type="button" class="btn" style="width:100%;font-size:12px;padding:7px;display:flex;align-items:center;justify-content:center;gap:5px" onclick="verificarLink()"><i class="ti ti-refresh" style="font-size:14px" aria-hidden="true"></i> Verificar si el cliente ya llenó</button>
</div>

<!-- ============================================ -->
<!-- 8. CAMPOS OBLIGATORIOS + WOOCOMMERCE -->
<!-- ============================================ -->
<div class="ea-resumen">
    <div style="display:flex;align-items:center;gap:8px;margin-bottom:10px;padding-bottom:8px;border-bottom:1px solid #f0f0f0">
        <i class="ti ti-list-check" style="font-size:17px;color:#3B5BDB" aria-hidden="true"></i>
        <span style="font-size:14px;font-weight:500">Campos obligatorios</span>
        <span class="ea-badge" id="spanCamposConteo">0 de 7</span>
    </div>
    <div class="ea-check-grid" id="divChecklist"></div>
    <button type="button" class="ea-btn-wc" id="btnCrearWC" disabled onclick="crearPedidoWC()">
        <i class="ti ti-shopping-cart-plus" style="font-size:17px" aria-hidden="true"></i> Crear pedido en WooCommerce
    </button>
    <p style="margin:5px 0 0;font-size:10px;color:#999;text-align:center" id="txtEstadoWC">Faltan campos obligatorios</p>
</div>

<!-- HIDDEN FIELDS -->
<input type="hidden" id="hdPrePedidoEntregaId" name="hdPrePedidoEntregaId" value="<%=PrePedidoEntregaId%>">
<input type="hidden" id="hdPrePedidoId" name="hdPrePedidoId" value="<%=PrePedidoId%>">
<input type="hidden" id="hdAccion" name="hdAccion" value="">
<asp:Button ID="btnAccion" runat="server" Text="" Style="display:none" OnClick="btnAccion_Click"/>


<!-- CONTENEDOR DE TOASTS (notificaciones flotantes) -->
<div id="eaToastContainer" class="ea-toast-container" aria-live="polite"></div>


<!-- MODAL BUSCADOR DE PRODUCTOS (modo dual: buscar / personalizado) -->
<div id="modalBuscador" class="ea-modal-overlay">
    <div class="ea-modal">
        <!-- HEADER: cambia título según modo -->
        <div class="ea-modal-header">
            <span id="spanTituloModal" style="font-size:17px;font-weight:500"><i class="ti ti-search" style="font-size:19px;vertical-align:-2px;margin-right:7px" aria-hidden="true"></i>Buscar producto</span>
            <button type="button" onclick="cerrarBuscador()" class="ea-modal-close"><i class="ti ti-x" aria-hidden="true"></i></button>
        </div>

        <!-- TOGGLE BAR: siempre visible -->
        <div id="toggleBarBuscador" style="padding:9px 18px;border-bottom:0.5px solid #f0f0f0;display:flex;justify-content:space-between;align-items:center;gap:8px;background:#fafafa;transition:background 0.2s, border-color 0.2s">
            <span id="spanToggleModo" style="font-size:11px;color:#666;font-weight:500;display:flex;align-items:center;gap:5px">
                <i class="ti ti-list-search" style="font-size:13px" aria-hidden="true"></i>
                Buscar del catálogo
            </span>
            <label class="ea-toggle-pers" id="lblTogglePers" title="Cambiar a producto personalizado" style="cursor:pointer">
                <input type="checkbox" id="chkMostrarPersonalizado" onchange="togglePersonalizado(this.checked)">
                <i class="ti ti-pencil-plus" style="font-size:13px" aria-hidden="true"></i>
                Personalizado
            </label>
        </div>

        <!-- ========================================================== -->
        <!-- MODO BUSCADOR (default): buscador + categorías + lista     -->
        <!-- ========================================================== -->
        <div id="modoBuscador">
            <div style="padding:14px 22px;border-bottom:1px solid #f0f0f0">
                <div style="display:flex;gap:8px;margin-bottom:10px">
                    <input type="text" id="txBuscarProd" placeholder="Buscar por nombre, SKU..." class="ea-input" style="flex:1;font-size:14px;padding:9px 12px" onkeydown="if(event.key==='Enter'){event.preventDefault();buscarProductos();return false;}">
                    <button type="button" onclick="buscarProductos()" class="ea-btn-buscar" style="font-size:14px;padding:8px 16px"><i class="ti ti-search" style="font-size:16px" aria-hidden="true"></i></button>
                </div>
                <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap">
                    <label style="font-size:13px;color:#666;white-space:nowrap;font-weight:500">Categoría:</label>
                    <select id="ddCategoriaFiltro" class="ea-select" style="font-size:14px;padding:8px 10px;flex:1;min-width:140px" onchange="buscarProductos()">
                        <option value="0" selected>Todas las categorías</option>
                        <%=HtmlCategoriasBtns%>
                    </select>
                </div>
            </div>
            <div id="divListaProductos" style="max-height:480px;overflow-y:auto">
                <p style="padding:20px;text-align:center;color:#999;font-size:13px">Escriba para buscar productos...</p>
            </div>
        </div>

        <!-- ========================================================== -->
        <!-- MODO PERSONALIZADO: panel grande con descripción y monto   -->
        <!-- ========================================================== -->
        <div id="panelPersonalizado" style="display:none;background:#FFF8E1;padding:16px 14px">
            <div style="background:#fff;border-radius:10px;border:1px solid #FFE082;padding:14px">

                <!-- Header del card personalizado -->
                <div style="display:flex;align-items:center;gap:10px;margin-bottom:12px;padding-bottom:10px;border-bottom:0.5px solid #FFE082">
                    <div style="width:42px;height:42px;min-width:42px;border-radius:50%;background:#FFF8E1;display:flex;align-items:center;justify-content:center;color:#F57F17;font-size:20px">
                        <i class="ti ti-pencil-plus" aria-hidden="true"></i>
                    </div>
                    <div>
                        <div style="font-size:14px;font-weight:500;color:#F57F17;display:flex;align-items:center;gap:5px">
                            <i class="ti ti-sparkles" style="font-size:13px" aria-hidden="true"></i>
                            Crear producto único
                        </div>
                        <div style="font-size:11px;color:#999;margin-top:1px">Describí qué quiere el cliente</div>
                    </div>
                </div>

                <!-- Descripción: textarea grande -->
                <label class="ea-pers-label">
                    <i class="ti ti-file-description" style="font-size:11px" aria-hidden="true"></i>
                    Descripción / personalización *
                </label>
                <textarea id="txPersDetalle" class="ea-pers-textarea" placeholder="Ej: Arreglo de 6 rosas rojas + 3 girasoles en florero de cristal, con tarjeta de cumpleaños y globo metálico..." rows="4"></textarea>

                <!-- Monto: ancho completo, grande -->
                <div style="margin-top:14px">
                    <label class="ea-pers-label">
                        <i class="ti ti-cash" style="font-size:11px" aria-hidden="true"></i>
                        Precio acordado *
                    </label>
                    <input type="number" id="txPersPrecio" class="ea-pers-monto-input" placeholder="0.00" step="0.01" inputmode="decimal" onkeydown="if(event.key==='Enter'){event.preventDefault();return false;}">
                    <!-- Moneda: dos pills abajo -->
                    <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:10px">
                        <button type="button" id="btnMonedaBOB" class="ea-pers-moneda-btn active" onclick="seleccionarMonedaPers('BOB')">
                            <i class="ti ti-check check-ico" aria-hidden="true"></i>
                            Bolivianos (Bs)
                        </button>
                        <button type="button" id="btnMonedaUSD" class="ea-pers-moneda-btn" onclick="seleccionarMonedaPers('USD')">
                            <i class="ti ti-check check-ico" aria-hidden="true"></i>
                            Dólares (USD)
                        </button>
                    </div>
                    <!-- Campo oculto que guarda la moneda elegida (compatible con el JS de agregarPersonalizado) -->
                    <input type="hidden" id="ddPersMoneda" value="BOB">
                </div>

                <!-- Acciones -->
                <div style="margin-top:16px;display:flex;gap:6px">
                    <button type="button" onclick="togglePersonalizado(false); document.getElementById('chkMostrarPersonalizado').checked=false;" style="flex:1;background:#fff;color:#999;border:1px solid #e0e0e0;border-radius:8px;padding:11px 14px;font-size:13px;cursor:pointer;font-weight:500">Cancelar</button>
                    <button type="button" onclick="agregarPersonalizado()" style="flex:2;background:#F57F17;color:#fff;border:none;border-radius:8px;padding:11px 14px;font-size:14px;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:5px;font-weight:600">
                        <i class="ti ti-plus" style="font-size:14px" aria-hidden="true"></i>
                        Agregar al pedido
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- MODAL REGISTRAR PAGO (simplificado: Tipo, Moneda, Tasa se autodeducen en JS) -->
<div id="modalPago" class="ea-modal-overlay">
    <div class="ea-modal ea-modal-sm">
        <div class="ea-modal-header">
            <span style="font-size:15px;font-weight:500"><i class="ti ti-cash" style="font-size:17px;vertical-align:-2px;margin-right:6px" aria-hidden="true"></i>Registrar pago</span>
            <button type="button" onclick="cerrarModalPago()" class="ea-modal-close"><i class="ti ti-x" aria-hidden="true"></i></button>
        </div>
        <div style="padding:20px">
            <!-- Info: saldo pendiente del pedido -->
            <div id="divSaldoInfo" style="background:#EBF0FF;border:1px solid #BBDEFB;border-radius:8px;padding:8px 12px;margin-bottom:12px;font-size:12px;color:#3B5BDB;display:none">
                <i class="ti ti-info-circle" style="font-size:13px;vertical-align:-2px" aria-hidden="true"></i>
                Saldo pendiente: <strong id="spanSaldoModal">Bs 0.00</strong>
            </div>

            <div style="margin-bottom:10px">
                <label class="ea-label">Método *</label>
                <select id="ddPagoMetodo" class="ea-select">
                    <option value="">-- Seleccionar --</option>
                    <option value="EFECTIVO">Efectivo</option>
                    <option value="QR">QR Bolivia (BNB)</option>
                    <option value="TRANSFERENCIA">Transferencia</option>
                    <option value="PAYPAL">PayPal</option>
                    <option value="CRIPTO">Cripto USDT</option>
                    <option value="YAPE">Yape</option>
                    <option value="PIX">Pix</option>
                    <option value="TARJETA">Tarjeta</option>
                    <option value="PAGOMOVIL">Pago Movil</option>
                </select>
            </div>

            <div style="margin-bottom:10px">
                <label class="ea-label">Monto en Bs *</label>
                <div style="display:flex;gap:6px;align-items:stretch">
                    <input type="number" id="txPagoMonto" placeholder="0.00" step="0.01" inputmode="decimal" class="ea-input" style="flex:1" oninput="actualizarTipoPagoLabel()" onkeydown="if(event.key==='Enter'){event.preventDefault();return false;}">
                    <button type="button" onclick="llenarMontoTotal()" title="Llenar con el saldo pendiente del pedido" style="font-size:12px;padding:0 12px;background:#E8F5E9;color:#2E7D32;border:1px solid #A5D6A7;border-radius:6px;cursor:pointer;font-weight:500;white-space:nowrap"><i class="ti ti-cash" style="font-size:13px;vertical-align:-1px" aria-hidden="true"></i> Pagó todo</button>
                </div>
                <!-- Tipo de pago autodeducido (solo lectura, informativo) -->
                <div id="divTipoAuto" style="font-size:11px;color:#999;margin-top:4px;display:none">
                    <i class="ti ti-tag" style="font-size:11px;vertical-align:-1px" aria-hidden="true"></i>
                    Se registrará como <span id="spanTipoAuto" style="color:#3B5BDB;font-weight:500">Total</span>
                </div>
            </div>

            <div style="margin-bottom:10px">
                <label class="ea-label">Referencia / Nro transacción</label>
                <input type="text" id="txPagoRef" placeholder="Ej: TXN-123456" class="ea-input" onkeydown="if(event.key==='Enter'){event.preventDefault();return false;}">
            </div>

            <div style="margin-bottom:10px">
                <label class="ea-label">Observaciones</label>
                <input type="text" id="txPagoObs" placeholder="Opcional..." class="ea-input" onkeydown="if(event.key==='Enter'){event.preventDefault();return false;}">
            </div>

            <div style="margin-bottom:16px">
                <label class="ea-label">Estado del pago</label>
                <div style="display:flex;gap:1rem;align-items:center">
                    <label class="ea-radio-label"><input type="radio" name="pagoEstado" value="PENDIENTE"> Pendiente</label>
                    <label class="ea-radio-label"><input type="radio" name="pagoEstado" value="VERIFICADO" checked> Verificado</label>
                    <label class="ea-radio-label"><input type="radio" name="pagoEstado" value="RECHAZADO"> Rechazado</label>
                </div>
            </div>

            <div style="display:flex;justify-content:flex-end;gap:6px;padding-top:10px;border-top:1px solid #f0f0f0">
                <button type="button" onclick="cerrarModalPago()" class="btn" style="font-size:12px;padding:6px 14px">Cancelar</button>
                <button type="button" onclick="guardarPago()" style="font-size:12px;padding:6px 14px;background:#EBF0FF;color:#3B5BDB;border:1px solid #90CAF9;border-radius:8px;cursor:pointer;font-weight:500"><i class="ti ti-check" style="font-size:13px;vertical-align:-1px" aria-hidden="true"></i> Guardar pago</button>
            </div>
        </div>
    </div>
</div>

</asp:Content>

<asp:Content ID="ContentScripts" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

var prepedidoEntregaId = parseInt(document.getElementById('hdPrePedidoEntregaId').value) || 0;
var prepedidoId = parseInt(document.getElementById('hdPrePedidoId').value) || 0;
var zonasData = <%=ZonasJson%>;
var slotsData = <%=SlotsJson%>;
var tasaCambio = <%=TasaCambio.ToString("F4", System.Globalization.CultureInfo.InvariantCulture)%>;

// Devuelve siempre "Bs X.XX" (todo el sistema trabaja en Bs internamente)
function fmtBs(montoBs) {
    return 'Bs ' + (montoBs || 0).toFixed(2);
}

// Devuelve la conversion entre parentesis si la moneda elegida es USD
// Ej: si monto=100 Bs y tasa=7 -> " (USD 14.29)"
// Si la moneda es BOB, devuelve cadena vacia
function convAside(montoBs) {
    var dd = document.getElementById('ddMoneda');
    var moneda = dd ? dd.value : 'BOB';
    if (moneda !== 'USD' || tasaCambio <= 0 || !montoBs) return '';
    return ' <span style="color:#999;font-size:0.9em">(USD ' + (montoBs / tasaCambio).toFixed(2) + ')</span>';
}

// Para uso en mensajes de texto plano (cotizacion WhatsApp)
// Devuelve "Bs X.XX" o "USD X.XX" segun la moneda recibida
function fmtTextoMoneda(montoBs, moneda) {
    if (moneda === 'USD' && tasaCambio > 0) {
        return 'USD ' + (montoBs / tasaCambio).toFixed(2);
    }
    return 'Bs ' + montoBs.toFixed(2);
}

// ============================================================
// BLINDAJE GLOBAL CONTRA ENTER
// Evita que Enter en CUALQUIER input dispare el postback del form
// runat="server" de la MasterPage (que provoca redirect al login).
// ============================================================
document.addEventListener('keydown', function(e) {
    if (e.key !== 'Enter') return;
    var t = e.target;
    if (!t || !t.tagName) return;
    var tag = t.tagName.toLowerCase();
    var type = (t.type || '').toLowerCase();
    // Permitir Enter en textarea y en botones (botones tienen su propio handler)
    if (tag === 'textarea') return;
    if (tag === 'button') return;
    if (tag === 'input' && (type === 'button' || type === 'submit')) return;
    // Cualquier otro input: bloquear Enter
    e.preventDefault();
    return false;
}, true);

// ============================================================
// SECCIONES COLAPSABLES
// ============================================================
function toggleSeccion(nombre) {
    var body = document.getElementById(nombre + 'Body');
    var arrow = document.getElementById(nombre + 'Arrow');
    if (body.style.display === 'none') {
        body.style.display = 'block';
        arrow.className = 'ti ti-chevron-down';
    } else {
        body.style.display = 'none';
        arrow.className = 'ti ti-chevron-right';
    }
}

// ============================================================
// TOGGLE DOMICILIO / RECOJO
// Al volver a Domicilio, limpia los campos que se auto-llenaron por Recojo
// (los detectamos por prefijo "Recoge en tienda" / "Por recoge en tienda").
// El receptor/dedicatoria/firma que el agente escribio manualmente NO se toca.
// ============================================================
function toggleTipoEntrega() {
    var radioDom = document.querySelector('input[name="tipoEntrega"][value="DOMICILIO"]');
    var isDomicilio = !!(radioDom && radioDom.checked);
    document.getElementById('fieldsDomicilio').style.display = isDomicilio ? 'block' : 'none';
    document.getElementById('fieldsRecojo').style.display = isDomicilio ? 'none' : 'block';

    if (isDomicilio) {
        limpiarAutoLlenadosRecojo();
    }

    actualizarChecklist();
}

// ============================================================
// LIMPIAR AUTO-LLENADOS DE RECOJO
// Limpia receptor, celular receptor, ocasion, dedicatoria y firma
// solo si tienen los valores autollenados ("Recoge en tienda...", "Por recoge en tienda", "OTRO").
// Lo escrito manualmente por el agente se respeta.
// ============================================================
function limpiarAutoLlenadosRecojo() {
    var rx = /^Recoge en tienda\b/i;

    var txReceptor = document.getElementById('txReceptor');
    if (txReceptor && rx.test(txReceptor.value)) {
        txReceptor.value = '';
        guardarCampo('receptor_nombre', '');
    }

    // El celular auto-llenado es una copia del cliente -> lo comparamos
    var txCelRec = document.getElementById('txCelularReceptor');
    var txCelCli = document.getElementById('txClienteCelular');
    if (txCelRec && txCelCli && txCelRec.value && txCelRec.value === txCelCli.value) {
        txCelRec.value = '';
        guardarCampo('receptor_celular', '');
    }

    var txDed = document.getElementById('txDedicatoria');
    if (txDed && /^Por recoge en tienda\b/i.test(txDed.value)) {
        txDed.value = '';
        guardarCampo('dedicatoria', '');
    }

    var txFir = document.getElementById('txFirma');
    if (txFir && rx.test(txFir.value)) {
        txFir.value = '';
        guardarCampo('firma_tarjeta', '');
    }

    // Ocasion: si esta en OTRO, la dejamos a vacio para que el agente la reelija si quiere
    var ddOca = document.getElementById('ddOcasion');
    if (ddOca && ddOca.value === 'OTRO') {
        ddOca.value = '';
        guardarCampo('tipo_ocacion', '');
    }
}

// ============================================================
// FILTRAR ZONAS POR CIUDAD
// ============================================================
function filtrarZonas(preservarSeleccion) {
    var ciudadId = parseInt(document.getElementById('ddCiudad').value) || 0;
    var dl = document.getElementById('dlZonas');
    dl.innerHTML = '';
    if (!preservarSeleccion) {
        document.getElementById('txZonaBuscar').value = '';
        document.getElementById('hdZonaId').value = '';
    }
    zonasData.forEach(function(z) {
        if (z.ciudad_id === ciudadId) {
            var opt = document.createElement('option');
            opt.value = z.nombre + ' (Bs ' + z.precio_bs.toFixed(2) + ')';
            opt.setAttribute('data-id', z.zona_id);
            dl.appendChild(opt);
        }
    });
}
function seleccionarZona(texto) {
    var ciudadId = parseInt(document.getElementById('ddCiudad').value) || 0;
    var encontrada = null;
    zonasData.forEach(function(z) {
        if (z.ciudad_id === ciudadId) {
            var label = z.nombre + ' (Bs ' + z.precio_bs.toFixed(2) + ')';
            if (label === texto) encontrada = z;
        }
    });
    if (encontrada) {
        document.getElementById('hdZonaId').value = encontrada.zona_id;
        guardarCampo('zona_id', encontrada.zona_id);
        calcularSubtotal();
    }
}

// ============================================================
// AUTO-GUARDADO VIA AJAX
// ============================================================
function guardarCampo(campo, valor) {
    if (prepedidoEntregaId === 0) {
        mostrarError();
        return;
    }
    mostrarGuardando();
    var formData = new FormData();
    formData.append('accion', 'GUARDAR_CAMPO');
    formData.append('prepedido_entrega_id', prepedidoEntregaId);
    formData.append('campo', campo);
    formData.append('valor', valor);
    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.ok) { mostrarGuardado(); } else { mostrarError(); }
        actualizarChecklist();
    })
    .catch(function() { mostrarError(); });
}

// ============================================================
// GUARDAR CAMPO DEL CLIENTE (cliente_nombre, cliente_apellidos, cliente_email, cliente_celular)
// Usa el endpoint GUARDAR_CLIENTE del handler que actualiza FLORERIA_PrePedido.
// ============================================================
function guardarCliente(campo, valor) {
    if (prepedidoId === 0) {
        mostrarError();
        return;
    }
    mostrarGuardando();
    var formData = new FormData();
    formData.append('accion', 'GUARDAR_CLIENTE');
    formData.append('prepedido_id', prepedidoId);
    formData.append('campo', campo);
    formData.append('valor', valor);
    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.ok) {
            mostrarGuardado();
        } else {
            mostrarError();
            if (data.msg) { mostrarToast(data.msg, 'err'); }
        }
    })
    .catch(function() { mostrarError(); });
}

// ============================================================
// BUSCADOR DE PRODUCTOS
// ============================================================
function abrirBuscadorProductos() {
    document.getElementById('modalBuscador').style.display = 'block';
    document.getElementById('txBuscarProd').value = '';
    document.getElementById('txBuscarProd').focus();
    buscarProductos();
}
function cerrarBuscador() {
    document.getElementById('modalBuscador').style.display = 'none';
    // Resetear el toggle de producto personalizado al cerrar
    var chk = document.getElementById('chkMostrarPersonalizado');
    if (chk) { chk.checked = false; togglePersonalizado(false); }
}
// Alterna entre MODO BUSCADOR (catálogo) y MODO PERSONALIZADO
// - mostrar=true: oculta buscador/categorías/lista, muestra panel grande personalizado
// - mostrar=false: vuelve al buscador del catálogo
function togglePersonalizado(mostrar) {
    var modoBusc = document.getElementById('modoBuscador');
    var panelPers = document.getElementById('panelPersonalizado');
    var titulo = document.getElementById('spanTituloModal');
    var spanModo = document.getElementById('spanToggleModo');
    var toggleBar = document.getElementById('toggleBarBuscador');
    var lblToggle = document.getElementById('lblTogglePers');
    if (!modoBusc || !panelPers) return;

    if (mostrar) {
        // Cambiar a modo personalizado
        modoBusc.style.display = 'none';
        panelPers.style.display = 'block';
        if (titulo) titulo.innerHTML = '<i class="ti ti-pencil-plus" style="font-size:19px;vertical-align:-2px;margin-right:7px;color:#F57F17" aria-hidden="true"></i><span style="color:#F57F17">Producto personalizado</span>';
        if (spanModo) {
            spanModo.innerHTML = '<i class="ti ti-sparkles" style="font-size:13px" aria-hidden="true"></i> Modo personalizado activo';
            spanModo.style.color = '#F57F17';
        }
        if (toggleBar) {
            toggleBar.style.background = '#FFF8E1';
            toggleBar.style.borderBottomColor = '#FFE082';
        }
        if (lblToggle) lblToggle.classList.add('active');
        // Foco en la descripción al abrir
        var tx = document.getElementById('txPersDetalle');
        if (tx) setTimeout(function(){ tx.focus(); }, 200);
    } else {
        // Volver a modo buscador
        modoBusc.style.display = 'block';
        panelPers.style.display = 'none';
        if (titulo) titulo.innerHTML = '<i class="ti ti-search" style="font-size:19px;vertical-align:-2px;margin-right:7px" aria-hidden="true"></i>Buscar producto';
        if (spanModo) {
            spanModo.innerHTML = '<i class="ti ti-list-search" style="font-size:13px" aria-hidden="true"></i> Buscar del catálogo';
            spanModo.style.color = '#666';
        }
        if (toggleBar) {
            toggleBar.style.background = '#fafafa';
            toggleBar.style.borderBottomColor = '#f0f0f0';
        }
        if (lblToggle) lblToggle.classList.remove('active');
    }
}

// Seleccionar moneda del producto personalizado (Bs o USD)
function seleccionarMonedaPers(moneda) {
    var hdMoneda = document.getElementById('ddPersMoneda');
    var btnBOB = document.getElementById('btnMonedaBOB');
    var btnUSD = document.getElementById('btnMonedaUSD');
    if (hdMoneda) hdMoneda.value = moneda;
    if (btnBOB) btnBOB.classList.toggle('active', moneda === 'BOB');
    if (btnUSD) btnUSD.classList.toggle('active', moneda === 'USD');
}
function buscarProductos() {
    var texto = document.getElementById('txBuscarProd').value.trim();
    var ddCat = document.getElementById('ddCategoriaFiltro');
    var catId = ddCat ? ddCat.value : '0';
    var formData = new FormData();
    formData.append('accion', 'BUSCAR_PRODUCTOS');
    formData.append('texto', texto);
    formData.append('categoria_id', catId);
    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.ok) { renderizarProductos(data.productos); }
    });
}
function renderizarProductos(productos) {
    var container = document.getElementById('divListaProductos');
    if (productos.length === 0) {
        container.innerHTML = '<p style="padding:24px;text-align:center;color:#999;font-size:14px">No se encontraron productos</p>';
        return;
    }
    var html = '';
    productos.forEach(function(p) {
        // El handler ya devuelve p.activo (true/false). Inactivos llevan barra de aviso "NO DISPONIBLE".
        var inactivo = (p.activo === false);
        var inactivoFlag = inactivo ? 'true' : 'false';
        var bgRow = inactivo ? '#FFF5F5' : 'transparent';
        var bgHover = inactivo ? '#FFEBEB' : '#fafafa';

        // Contenedor del producto
        var rowStyle = 'border-bottom:1px solid #f0f0f0;background:' + bgRow;
        if (inactivo) rowStyle += ';border-left:4px solid #E53935';

        html += '<div style="' + rowStyle + '" onmouseover="this.style.background=\'' + bgHover + '\'" onmouseout="this.style.background=\'' + bgRow + '\'">';

        // === BARRA DE AVISO "NO DISPONIBLE" (solo para inactivos) ===
        if (inactivo) {
            html += '<div style="background:#E53935;color:white;padding:7px 22px;display:flex;align-items:center;gap:8px;font-size:13px;font-weight:600;letter-spacing:0.3px">';
            html += '<i class="ti ti-ban" style="font-size:16px" aria-hidden="true"></i>';
            html += '<span>NO DISPONIBLE</span>';
            html += '<span style="font-weight:400;opacity:0.92;margin-left:4px;font-size:12px">&mdash; Producto deshabilitado en el catálogo</span>';
            html += '</div>';
        }

        // === CONTENIDO DEL PRODUCTO ===
        html += '<div style="padding:14px 22px">';
        html += '<div style="display:flex;gap:14px;align-items:flex-start' + (inactivo ? ';opacity:0.75' : '') + '">';

        // Imagen 64x64 (más grande)
        if (p.imagen_url && p.imagen_url !== '') {
            var imgFilter = inactivo ? 'filter:grayscale(1);' : '';
            html += '<div style="width:64px;height:64px;min-width:64px;border-radius:8px;overflow:hidden;' + imgFilter + '"><img src="' + p.imagen_url + '" style="width:100%;height:100%;object-fit:cover" onerror="this.parentNode.innerHTML=\'<i class=ti ti-flower style=font-size:28px;color:#E53935></i>\'"></div>';
        } else {
            var iconColor = inactivo ? '#BDBDBD' : '#E53935';
            html += '<div style="width:64px;height:64px;min-width:64px;border-radius:8px;background:#fafafa;display:flex;align-items:center;justify-content:center"><i class="ti ti-flower" style="font-size:28px;color:' + iconColor + '"></i></div>';
        }

        // Bloque texto + acciones (flex:1, min-width:0 para que el wrap funcione bien)
        html += '<div style="flex:1;min-width:0">';

        // Línea: nombre (izq) + precio (der)
        html += '<div style="display:flex;justify-content:space-between;align-items:flex-start;gap:12px">';
        var nombreStyle = 'margin:0;font-size:15px;font-weight:500;line-height:1.35;word-break:break-word';
        if (inactivo) nombreStyle += ';text-decoration:line-through;color:#999';
        html += '<div style="flex:1;min-width:0"><p style="' + nombreStyle + '">' + escapeHtml(p.nombre) + '</p>';
        html += '<p style="margin:3px 0 0;font-size:12px;color:#999">' + escapeHtml(p.sku) + ' &mdash; ' + escapeHtml(p.categoria) + ' &mdash; Stock: ' + p.stock_actual + '</p></div>';

        var precioColor = inactivo ? '#9E9E9E' : '#3B5BDB';
        var precioStyle = inactivo ? 'text-decoration:line-through;' : '';
        // Solo se muestra el precio "viejo" tachado para inactivos - el editable va abajo
        if (inactivo) {
            html += '<p style="margin:0;font-size:13px;font-weight:500;color:' + precioColor + ';' + precioStyle + ';white-space:nowrap">Bs ' + p.precio_base_bs.toFixed(2) + '</p>';
        }
        html += '</div>';

        // Input personalizacion (más grande y legible)
        html += '<input type="text" placeholder="Personalización..." style="width:100%;font-size:13px;padding:6px 10px;margin-top:8px;border:1px dashed #d0d0d0;border-radius:6px;box-sizing:border-box" id="pers_' + p.producto_id + '" onkeydown="if(event.key===\'Enter\'){event.preventDefault();return false;}">';

        // Fila de acción: precio editable (izq) + botón agregar (der)
        html += '<div style="display:flex;justify-content:space-between;align-items:center;margin-top:8px;gap:8px">';

        // Precio editable - solo para productos activos. Inactivos no se editan (usan precio_base_bs).
        if (!inactivo) {
            html += '<div class="ea-price-edit" id="priceWrap_' + p.producto_id + '" data-precio-original="' + p.precio_base_bs.toFixed(2) + '">';
            html += '<span class="ea-price-curr">Bs</span>';
            html += '<input type="number" step="0.01" min="0" value="' + p.precio_base_bs.toFixed(2) + '" ';
            html += 'id="precio_' + p.producto_id + '" ';
            html += 'oninput="marcarPrecioModificado(' + p.producto_id + ')" ';
            html += 'onkeydown="if(event.key===\'Enter\'){event.preventDefault();return false;}">';
            html += '<i class="ti ti-pencil ea-price-edit-ico" aria-hidden="true"></i>';
            html += '</div>';
        } else {
            html += '<span></span>';  // spacer
        }

        var btnBg = inactivo ? '#fff' : '#EBF0FF';
        var btnColor = inactivo ? '#E53935' : '#3B5BDB';
        var btnBorder = inactivo ? '#FFCDD2' : '#90CAF9';
        var btnIcon = inactivo ? 'ti-alert-triangle' : 'ti-plus';
        var btnLabel = inactivo ? 'Agregar de todos modos' : 'Agregar';
        // OJO: usamos escapeAttr (solo escapa " y &) en lugar de escapeHtml (que escapa tildes/ñ).
        // Así getAttribute('data-nombre') devuelve el texto tal cual, sin entidades HTML.
        html += '<button type="button" class="btn-agregar-prod" ';
        html += 'data-pid="' + p.producto_id + '" ';
        html += 'data-nombre="' + escapeAttr(p.nombre) + '" ';
        html += 'data-precio-bs="' + p.precio_base_bs + '" ';
        html += 'data-precio-usd="' + (p.precio_base_usd || 0) + '" ';
        html += 'data-inactivo="' + inactivoFlag + '" ';
        html += 'style="font-size:13px;padding:6px 14px;background:' + btnBg + ';color:' + btnColor + ';border:1px solid ' + btnBorder + ';border-radius:8px;cursor:pointer;font-weight:500">';
        html += '<i class="ti ' + btnIcon + '" style="font-size:14px;vertical-align:-2px"></i> ' + btnLabel + '</button>';
        html += '</div>';

        html += '</div></div></div></div>'; // cierra contenedor texto, flex-gap, padding, root
    });
    container.innerHTML = html;

    // Adjuntar handlers con event delegation (un solo listener para todos los botones).
    // Hacemos esto cada vez que se re-renderiza la lista, reemplazando handler anterior.
    container.onclick = function(ev) {
        var btn = ev.target.closest ? ev.target.closest('.btn-agregar-prod') : null;
        if (!btn) return;
        var pid = parseInt(btn.getAttribute('data-pid')) || 0;
        var nombre = btn.getAttribute('data-nombre') || '';
        var precioBs = parseFloat(btn.getAttribute('data-precio-bs')) || 0;
        var precioUsd = parseFloat(btn.getAttribute('data-precio-usd')) || 0;
        var inactivo = (btn.getAttribute('data-inactivo') === 'true');
        agregarProductoAlPedido(pid, nombre, precioBs, precioUsd, inactivo);
    };
}

// ============================================================
// AGREGAR PRODUCTO AL PEDIDO
// ============================================================
function agregarProductoAlPedido(productoId, nombre, precioBs, precioUsd, esInactivo) {
    // Comparación permisiva (acepta true, 'true', 1, '1')
    var inactivo = (esInactivo === true || esInactivo === 'true' || esInactivo === 1 || esInactivo === '1');

    // Si el producto está inactivo, pedir confirmación explícita ANTES de hacer cualquier cosa
    if (inactivo) {
        var msg = '🚫 PRODUCTO NO DISPONIBLE\n\n';
        msg += '"' + nombre + '" está deshabilitado en el catálogo.\n\n';
        msg += 'Esto significa que:\n';
        msg += '  • No se vende actualmente al público\n';
        msg += '  • Puede no tener stock real\n';
        msg += '  • El precio podría estar desactualizado\n\n';
        msg += '¿Aún así deseas agregarlo al pedido?';
        if (!confirm(msg)) {
            return;  // Usuario canceló, no se hace nada
        }
    }

    // Leer precio EDITADO si existe el input. Si no, usar el original.
    var precioInput = document.getElementById('precio_' + productoId);
    var precioFinal = precioBs;
    if (precioInput) {
        var v = parseFloat(precioInput.value);
        if (!isNaN(v) && v > 0) {
            precioFinal = v;
        }
    }

    var persEl = document.getElementById('pers_' + productoId);
    var persTexto = persEl ? persEl.value.trim() : '';
    // Pasamos el precio editado (puede coincidir con el original o ser distinto)
    insertarProducto(productoId, nombre, precioFinal, precioUsd, persTexto, false, inactivo);
}

// Marca visualmente el precio como modificado cuando el usuario lo cambia
function marcarPrecioModificado(productoId) {
    var wrap = document.getElementById('priceWrap_' + productoId);
    var input = document.getElementById('precio_' + productoId);
    if (!wrap || !input) return;
    var original = parseFloat(wrap.getAttribute('data-precio-original')) || 0;
    var actual = parseFloat(input.value) || 0;
    // Comparación con tolerancia de 1 centavo
    if (Math.abs(actual - original) >= 0.01) {
        wrap.classList.add('modificado');
    } else {
        wrap.classList.remove('modificado');
    }
}
function agregarPersonalizado() {
    // El nombre ahora es FIJO: "Producto Personalizado" (no se pide al usuario)
    var nombre = 'Producto Personalizado';
    var descripcion = document.getElementById('txPersDetalle').value.trim();
    var precioInput = parseFloat(document.getElementById('txPersPrecio').value) || 0;
    var monedaPers = document.getElementById('ddPersMoneda').value || 'BOB';

    if (descripcion === '') {
        mostrarToast('Ingrese la descripción del producto personalizado', 'warn');
        document.getElementById('txPersDetalle').focus();
        return;
    }
    if (precioInput <= 0) {
        mostrarToast('Ingrese un precio válido', 'warn');
        document.getElementById('txPersPrecio').focus();
        return;
    }

    // Convertir precio a Bs (siempre se guarda en Bs internamente)
    var precioBs = precioInput;
    var precioUsd = 0;
    if (monedaPers === 'USD') {
        precioUsd = precioInput;
        precioBs = (tasaCambio > 0) ? (precioInput * tasaCambio) : precioInput;
    } else {
        precioBs = precioInput;
        precioUsd = (tasaCambio > 0) ? (precioInput / tasaCambio) : 0;
    }

    insertarProducto(0, nombre, precioBs, precioUsd, descripcion, true);

    // Limpiar campos del panel personalizado y volver al modo buscador
    document.getElementById('txPersDetalle').value = '';
    document.getElementById('txPersPrecio').value = '';
    seleccionarMonedaPers('BOB');  // reset moneda a BOB
    var chk = document.getElementById('chkMostrarPersonalizado');
    if (chk) { chk.checked = false; togglePersonalizado(false); }
}
function insertarProducto(productoId, nombre, precioBs, precioUsd, personalizacion, esPersonalizado, esInactivo) {
    if (prepedidoEntregaId === 0) {
        mostrarToast('Borrador no inicializado', 'err');
        return;
    }
    var formData = new FormData();
    formData.append('accion', 'AGREGAR_PRODUCTO');
    formData.append('prepedido_entrega_id', prepedidoEntregaId);
    formData.append('producto_id', productoId);
    formData.append('es_personalizado', esPersonalizado ? '1' : '0');
    formData.append('nombre_producto', nombre);
    formData.append('precio_bs', precioBs);
    formData.append('precio_usd', precioUsd);
    formData.append('cantidad', '1');
    formData.append('personalizacion', personalizacion);
    mostrarGuardando();
    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.ok) {
            agregarFilaProducto(data.detalle_id, nombre, precioBs, personalizacion, esPersonalizado);
            mostrarGuardado();
            // Toast informativo
            if (esInactivo) {
                mostrarToast('⚠️ Producto INACTIVO agregado: ' + nombre, 'warn', 5000);
            } else if (esPersonalizado) {
                mostrarToast('Producto personalizado agregado: ' + nombre, 'ok');
            } else {
                mostrarToast('Agregado: ' + nombre, 'ok');
            }
            if (esPersonalizado) {
                // La limpieza de campos y cambio de modo se hace en agregarPersonalizado()
                // (ya no se limpia txPersNombre porque ese campo fue eliminado)
                var txPrecio = document.getElementById('txPersPrecio');
                var txDetalle = document.getElementById('txPersDetalle');
                if (txPrecio) txPrecio.value = '';
                if (txDetalle) txDetalle.value = '';
            }
        } else {
            mostrarToast('Error: ' + (data.msg || 'no se pudo agregar'), 'err', 5000);
        }
    })
    .catch(function() {
        mostrarToast('Error de red al agregar el producto', 'err', 5000);
    });
}
function agregarFilaProducto(detalleId, nombre, precio, personalizacion, esPersonalizado) {
    var container = document.getElementById('divProductos');
    var div = document.createElement('div');
    div.setAttribute('data-detalle-id', detalleId);
    div.setAttribute('data-precio', precio);
    div.setAttribute('data-cantidad', 1);

    var html = '';
    if (esPersonalizado) {
        div.className = 'ea-prod-row personalizado';
        // Row 1: nombre + botón eliminar
        html += '<div class="ea-prod-card-row1">';
        html += '<div><span class="ea-prod-name"><i class="ti ti-pencil-plus" style="font-size:13px;color:#F57F17;vertical-align:-1px" aria-hidden="true"></i> Producto Personalizado <span style="font-size:9px;color:#F57F17">WC#7076</span></span></div>';
        html += '<button type="button" class="ea-prod-card-del" onclick="eliminarDetalle(' + detalleId + ',this)" aria-label="Eliminar"><i class="ti ti-trash" aria-hidden="true"></i></button>';
        html += '</div>';
        // Detalle de personalización
        if (personalizacion) {
            html += '<div class="ea-prod-card-detail"><i class="ti ti-pencil" style="font-size:11px;color:#F57F17" aria-hidden="true"></i><span>' + escapeHtml(personalizacion) + '</span></div>';
        }
        // Row 2: precio editable + cantidad
        html += '<div class="ea-prod-card-row2">';
        html += '<div class="ea-prod-card-cant"><span>Cant:</span><input type="number" value="1" min="1" onchange="actualizarDetalle(' + detalleId + ',\'cantidad\',this.value)"></div>';
        html += '<input type="number" class="ea-prod-card-precio-input" value="' + precio.toFixed(2) + '" step="0.01" onchange="actualizarDetalle(' + detalleId + ',\'precio\',this.value)">';
        html += '</div>';
    } else {
        div.className = 'ea-prod-row';
        // Row 1: nombre + botón eliminar
        html += '<div class="ea-prod-card-row1">';
        html += '<div><span class="ea-prod-name">' + escapeHtml(nombre) + '</span></div>';
        html += '<button type="button" class="ea-prod-card-del" onclick="eliminarDetalle(' + detalleId + ',this)" aria-label="Eliminar"><i class="ti ti-trash" aria-hidden="true"></i></button>';
        html += '</div>';
        // Detalle de personalización (si existe)
        if (personalizacion) {
            html += '<div class="ea-prod-card-detail"><i class="ti ti-pencil" style="font-size:11px;color:#F57F17" aria-hidden="true"></i><span>' + escapeHtml(personalizacion) + '</span></div>';
        }
        // Row 2: etiqueta + precio
        html += '<div class="ea-prod-card-row2">';
        html += '<span class="ea-prod-card-precio-label">Precio</span>';
        html += '<span class="ea-prod-card-precio" data-precio-bs="' + precio.toFixed(2) + '">Bs ' + precio.toFixed(2) + '</span>';
        html += '</div>';
    }
    div.innerHTML = html;
    container.appendChild(div);
    actualizarConteoItems();
    calcularSubtotal();
}

// ============================================================
// ELIMINAR / ACTUALIZAR DETALLE
// ============================================================
function eliminarDetalle(detalleId, btn) {
    if (!confirm('¿Eliminar este producto?')) return;
    var formData = new FormData();
    formData.append('accion', 'ELIMINAR_DETALLE');
    formData.append('detalle_id', detalleId);
    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) { if (data.ok) { btn.closest('.ea-prod-row').remove(); actualizarConteoItems(); calcularSubtotal(); mostrarGuardado(); } });
}
function actualizarDetalle(detalleId, campo, valor) {
    var row = document.querySelector('.ea-prod-row[data-detalle-id="' + detalleId + '"]');
    if (!row) { var btns = document.querySelectorAll('.ea-prod-row'); btns.forEach(function(r) { if (r.querySelector('[onchange*="' + detalleId + '"]')) row = r; }); }
    if (row) {
        if (campo === 'precio') { row.setAttribute('data-precio', valor); }
        if (campo === 'cantidad') { row.setAttribute('data-cantidad', valor); }
        calcularSubtotal();
    }
    var formData = new FormData();
    formData.append('accion', 'ACTUALIZAR_DETALLE');
    formData.append('detalle_id', detalleId);
    formData.append('campo', campo);
    formData.append('valor', valor);
    mostrarGuardando();
    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function() { mostrarGuardado(); });
}

// ============================================================
// PAGOS
// El modal solo pide: Método, Monto en Bs, Referencia, Observaciones, Estado
// El JS calcula automáticamente:
//   - tipo_pago: TOTAL / ANTICIPO / SALDO (según monto y pagos existentes)
//   - monto_usd: convertido con tasaCambio global de la página
// ============================================================
function abrirModalPago() {
    // Mostrar saldo pendiente como referencia
    var totalPedido = leerTotalPedidoBs();
    var yaPagado = sumarPagosNoRechazados();
    var saldo = totalPedido - yaPagado;
    if (saldo < 0) saldo = 0;

    var divInfo = document.getElementById('divSaldoInfo');
    var spanSaldo = document.getElementById('spanSaldoModal');
    if (divInfo && spanSaldo && totalPedido > 0) {
        spanSaldo.textContent = 'Bs ' + saldo.toFixed(2);
        divInfo.style.display = 'block';
    } else if (divInfo) {
        divInfo.style.display = 'none';
    }

    document.getElementById('modalPago').style.display = 'block';
    actualizarTipoPagoLabel();
}
function cerrarModalPago() { document.getElementById('modalPago').style.display = 'none'; }

// Llena el monto con el saldo pendiente (en Bs). Si no hay saldo, usa el total.
function llenarMontoTotal() {
    var totalBs = leerTotalPedidoBs();
    if (totalBs <= 0) {
        mostrarToast('No hay un total calculado todavia', 'warn');
        return;
    }
    var yaPagado = sumarPagosNoRechazados();
    var saldo = totalBs - yaPagado;
    if (saldo <= 0) saldo = totalBs;  // si ya se pagó todo, ofrecer el total completo

    var txMonto = document.getElementById('txPagoMonto');
    if (txMonto) {
        txMonto.value = saldo.toFixed(2);
    }
    actualizarTipoPagoLabel();
}

// Suma todos los pagos NO RECHAZADOS (Verificados + Pendientes) - para calcular saldo
function sumarPagosNoRechazados() {
    var suma = 0;
    document.querySelectorAll('.ea-pago-row').forEach(function(row) {
        var monto = parseFloat(row.getAttribute('data-monto-bs')) || 0;
        var estado = row.getAttribute('data-estado') || '';
        if (estado !== 'RECHAZADO') suma += monto;
    });
    return suma;
}

// Deduce el tipo de pago automáticamente según monto y pagos existentes
// - TOTAL: el pago cubre el total completo del pedido (sin pagos previos)
// - ANTICIPO: primer pago parcial (no hay otros pagos no-rechazados)
// - SALDO: ya hay pagos previos, este completa o aporta más
function deducirTipoPago(montoBs) {
    var totalPedido = leerTotalPedidoBs();
    var yaPagado = sumarPagosNoRechazados();
    if (totalPedido <= 0) return 'TOTAL';
    // Tolerancia 1 centavo
    if (yaPagado < 0.01) {
        // Primer pago del pedido
        if (Math.abs(montoBs - totalPedido) < 0.01) return 'TOTAL';
        return 'ANTICIPO';
    }
    // Ya hay pagos previos -> esto es saldo (parcial o final)
    return 'SALDO';
}

// Refresca la etiqueta "Se registrará como X" debajo del monto
function actualizarTipoPagoLabel() {
    var monto = parseFloat(document.getElementById('txPagoMonto').value) || 0;
    var div = document.getElementById('divTipoAuto');
    var span = document.getElementById('spanTipoAuto');
    if (!div || !span) return;
    if (monto <= 0) {
        div.style.display = 'none';
        return;
    }
    var tipo = deducirTipoPago(monto);
    var etiqueta = tipo === 'TOTAL' ? 'Total' : (tipo === 'ANTICIPO' ? 'Anticipo' : 'Saldo');
    span.textContent = etiqueta;
    div.style.display = 'block';
}

function guardarPago() {
    var metodo = document.getElementById('ddPagoMetodo').value;
    var monto = parseFloat(document.getElementById('txPagoMonto').value) || 0;
    var ref = document.getElementById('txPagoRef').value;
    var obs = document.getElementById('txPagoObs').value;
    var estadoEl = document.querySelector('input[name="pagoEstado"]:checked');
    var estado = estadoEl ? estadoEl.value : 'PENDIENTE';

    if (metodo === '') { alert('Seleccione metodo de pago'); return; }
    if (monto <= 0) { alert('Ingrese monto valido'); return; }
    if (prepedidoEntregaId === 0) { alert('Borrador no inicializado'); return; }

    // El monto se ingresa SIEMPRE en Bs (más simple para el usuario boliviano)
    var montoBs = monto;
    // Calcular USD automáticamente con la tasa global de la página
    var montoUsd = 0;
    if (tasaCambio > 0) {
        montoUsd = monto / tasaCambio;
    }

    // Deducir tipo de pago automáticamente
    var tipoPago = deducirTipoPago(montoBs);

    var formData = new FormData();
    formData.append('accion', 'AGREGAR_PAGO');
    formData.append('prepedido_entrega_id', prepedidoEntregaId);
    formData.append('tipo_pago', tipoPago);
    formData.append('metodo_pago', metodo);
    formData.append('monto_bs', montoBs.toFixed(2));
    formData.append('monto_usd', montoUsd.toFixed(2));
    formData.append('referencia', ref);
    formData.append('observaciones', obs);
    formData.append('estado', estado);

    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.ok) {
            var hoy = new Date();
            var fecha = (hoy.getDate()<10?'0':'') + hoy.getDate() + '/' + ((hoy.getMonth()+1)<10?'0':'') + (hoy.getMonth()+1);

            // Texto del monto: siempre Bs, con USD entre paréntesis si existe
            var textoMonto = 'Bs ' + montoBs.toFixed(2);
            if (montoUsd > 0) textoMonto += ' / $ ' + montoUsd.toFixed(2);

            // Icono según estado
            var iconoHtml;
            if (estado === 'VERIFICADO') {
                iconoHtml = '<i class="ti ti-check" style="font-size:14px;color:#2E7D32"></i>';
            } else if (estado === 'RECHAZADO') {
                iconoHtml = '<i class="ti ti-x" style="font-size:14px;color:#E53935"></i>';
            } else {
                iconoHtml = '<i class="ti ti-clock" style="font-size:14px;color:#F9A825"></i>';
            }

            var container = document.getElementById('divPagos');
            var div = document.createElement('div');
            div.className = 'ea-pago-row';
            div.setAttribute('data-estado', estado);
            div.setAttribute('data-monto-bs', (montoBs || 0).toFixed(2));
            div.innerHTML =
                '<span>' + metodo + ' <span style="font-size:10px;color:#999">(' + tipoPago + ')</span></span>' +
                '<span style="font-weight:500">' + textoMonto + '</span>' +
                '<span style="color:#999;font-size:11px">' + estado + '</span>' +
                '<span style="font-size:11px;color:#999">' + fecha + '</span>' +
                '<span>' + iconoHtml + '</span>' +
                '<button type="button" style="border:none;background:none;color:#E53935;cursor:pointer;font-size:13px;padding:0" onclick="eliminarPago(' + data.pago_id + ',this)"><i class="ti ti-trash"></i></button>';
            container.appendChild(div);

            cerrarModalPago();
            // Limpiar campos
            document.getElementById('ddPagoMetodo').value = '';
            document.getElementById('txPagoMonto').value = '';
            document.getElementById('txPagoRef').value = '';
            document.getElementById('txPagoObs').value = '';
            var radioDefault = document.querySelector('input[name="pagoEstado"][value="VERIFICADO"]');
            if (radioDefault) radioDefault.checked = true;
            var divTipo = document.getElementById('divTipoAuto');
            if (divTipo) divTipo.style.display = 'none';
            recalcularTotalesPagos();  // ← refrescar Total pagado / Saldo / badge
            actualizarChecklist();
            mostrarToast('Pago registrado: Bs ' + montoBs.toFixed(2), 'ok');
        } else {
            alert('Error al guardar pago: ' + (data.msg || 'desconocido'));
        }
    })
    .catch(function() { alert('Error de red al guardar pago'); });
}

// ============================================================
// RECALCULAR TOTALES DE PAGOS
// Suma los pagos VERIFICADOS (los pendientes/rechazados no cuentan),
// actualiza "Total pagado", "Saldo pendiente" y el badge de estado.
// ============================================================
function recalcularTotalesPagos() {
    var sumaVerificado = 0;
    var sumaPendiente = 0;
    document.querySelectorAll('.ea-pago-row').forEach(function(row) {
        var monto = parseFloat(row.getAttribute('data-monto-bs')) || 0;
        var estado = row.getAttribute('data-estado') || '';
        if (estado === 'VERIFICADO') {
            sumaVerificado += monto;
        } else if (estado === 'PENDIENTE') {
            sumaPendiente += monto;
        }
        // RECHAZADO no se suma
    });

    var totalPedido = leerTotalPedidoBs();
    var saldo = totalPedido - sumaVerificado;
    if (saldo < 0) saldo = 0;  // No mostrar saldo negativo (sobrepago)

    // Total pagado
    var pPagado = document.getElementById('pagoPagado');
    if (pPagado) pPagado.innerHTML = fmtBs(sumaVerificado) + convAside(sumaVerificado);

    // Saldo pendiente
    var pSaldo = document.getElementById('pagoSaldo');
    if (pSaldo) pSaldo.innerHTML = fmtBs(saldo) + convAside(saldo);

    // Badge de estado del pago
    var badge = document.getElementById('spanEstadoPago');
    if (badge) {
        if (totalPedido <= 0) {
            badge.textContent = 'Sin total';
            badge.className = 'ea-badge ea-badge-warning';
        } else if (sumaVerificado + 0.01 >= totalPedido) {
            // Pagado completo (con tolerancia de 1 centavo)
            if (sumaVerificado > totalPedido + 0.01) {
                badge.textContent = 'Sobrepago Bs ' + (sumaVerificado - totalPedido).toFixed(2);
                badge.className = 'ea-badge ea-badge-warning';
            } else {
                badge.textContent = 'Pagado';
                badge.className = 'ea-badge ea-badge-success';
            }
        } else if (sumaVerificado > 0) {
            badge.textContent = 'Parcial Bs ' + sumaVerificado.toFixed(2) + ' / ' + totalPedido.toFixed(2);
            badge.className = 'ea-badge ea-badge-warning';
        } else {
            badge.textContent = 'Pendiente';
            badge.className = 'ea-badge ea-badge-warning';
        }
    }
}

function eliminarPago(pagoId, btn) {
    if (!confirm('¿Eliminar este pago?')) return;
    var formData = new FormData();
    formData.append('accion', 'ELIMINAR_PAGO');
    formData.append('pago_id', pagoId);
    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.ok) {
            btn.closest('.ea-pago-row').remove();
            recalcularTotalesPagos();  // ← refrescar después de eliminar
            actualizarChecklist();
        }
    });
}

// ============================================================
// SINCRONIZAR CHECKBOX EXPRESS CON SLOT
// El checkbox es informativo: se marca/desmarca automáticamente
// según el slot elegido (es_express). NO afecta cálculos de total.
// Se llama: al cargar la página y cada vez que cambia el slot.
// ============================================================
function sincronizarExpressConSlot() {
    var ddSlot = document.getElementById('ddSlot');
    var chk = document.getElementById('chkExpress');
    if (!ddSlot || !chk) return;
    var sid = parseInt(ddSlot.value) || 0;
    var esExpressSlot = false;
    slotsData.forEach(function(s) {
        if (s.slot_id === sid && s.es_express) esExpressSlot = true;
    });
    // Solo actualizar y guardar si cambia (evita writes innecesarios)
    if (chk.checked !== esExpressSlot) {
        chk.checked = esExpressSlot;
        guardarCampo('es_express', esExpressSlot ? '1' : '0');
    }
}

// ============================================================
// CALCULAR SUBTOTAL
// ============================================================
function calcularSubtotal() {
    var filas = document.querySelectorAll('.ea-prod-row');
    var subtotal = 0;
    filas.forEach(function(fila) {
        var precio = parseFloat(fila.getAttribute('data-precio')) || 0;
        var cantidad = parseFloat(fila.getAttribute('data-cantidad')) || 1;
        subtotal += precio * cantidad;
    });

    // Refrescar precio de cada fila de producto (no personalizado)
    // El precio se mantiene siempre en Bs pero agregamos la conversion al lado si la moneda es USD
    document.querySelectorAll('.ea-prod-card-precio').forEach(function(sp) {
        var precioBs = parseFloat(sp.getAttribute('data-precio-bs')) || 0;
        sp.innerHTML = 'Bs ' + precioBs.toFixed(2) + convAside(precioBs);
    });

    // Subtotal en cabecera de productos
    var spSub = document.getElementById('spanSubtotal');
    if (spSub) spSub.innerHTML = fmtBs(subtotal) + convAside(subtotal);

    // Resumen
    var resSubtotal = document.getElementById('resSubtotal');
    if (resSubtotal) resSubtotal.innerHTML = fmtBs(subtotal) + convAside(subtotal);

    // Envio de zona
    var costoEnvio = 0;
    var hdZonaId = document.getElementById('hdZonaId');
    if (hdZonaId && hdZonaId.value) {
        var zid = parseInt(hdZonaId.value);
        zonasData.forEach(function(z) { if (z.zona_id === zid) costoEnvio = z.precio_bs; });
    }
    var resEnvio = document.getElementById('resEnvio');
    if (resEnvio) resEnvio.innerHTML = fmtBs(costoEnvio) + convAside(costoEnvio);

    // Recargo horario
    var recargoHorario = 0;
    var ddSlot = document.getElementById('ddSlot');
    if (ddSlot && ddSlot.value) {
        var sid = parseInt(ddSlot.value);
        slotsData.forEach(function(s) { if (s.slot_id === sid) recargoHorario = s.recargo_bs; });
    }
    var resRH = document.getElementById('resRecargoHorario');
    if (resRH) resRH.innerHTML = fmtBs(recargoHorario) + convAside(recargoHorario);

    // Express: el checkbox es solo informativo (se auto-marca según el slot).
    // El recargo ya está incluido en `recargoHorario` arriba. NO sumar nada extra.
    var recargoExpress = 0;
    var resRE = document.getElementById('resRecargoExpress');
    if (resRE) resRE.innerHTML = fmtBs(recargoExpress) + convAside(recargoExpress);

    // Descuento: el usuario lo ingresa en la moneda que elija (BOB o USD).
    // Lo convertimos a Bs para sumarlo a los calculos internos.
    var descuentoInput = parseFloat(document.getElementById('txDescuento').value) || 0;
    var ddDescMon = document.getElementById('ddDescuentoMoneda');
    var descuentoBs = descuentoInput;
    if (ddDescMon && ddDescMon.value === 'USD' && tasaCambio > 0) {
        descuentoBs = descuentoInput * tasaCambio;
    }

    // Total
    var total = subtotal + costoEnvio + recargoHorario + recargoExpress - descuentoBs;
    var resTotal = document.getElementById('resTotal');
    if (resTotal) resTotal.innerHTML = fmtBs(total) + convAside(total);

    // Pago total (siempre en Bs - es el monto del pedido)
    var pagoTotal = document.getElementById('pagoTotal');
    if (pagoTotal) pagoTotal.innerHTML = fmtBs(total) + convAside(total);

    // Cuando cambia el total del pedido, el saldo pendiente cambia también
    recalcularTotalesPagos();

    actualizarChecklist();
}

// ============================================================
// WHATSAPP COTIZACION
// Envia el mensaje en la moneda seleccionada en el toggle (BOB o USD)
// ============================================================
function enviarCotizacionWsp() {
    var filas = document.querySelectorAll('.ea-prod-row');
    if (filas.length === 0) { mostrarToast('Agregue al menos un producto', 'warn'); return; }

    var celular = '<%=ClienteCelular%>';
    var ddMon = document.getElementById('ddMoneda');
    var monedaEnvio = ddMon ? ddMon.value : 'BOB';

    var subtotal = 0;
    var lineas = '';

    filas.forEach(function(fila) {
        var nombreEl = fila.querySelector('.ea-prod-name');
        var detalleEl = fila.querySelector('.ea-prod-card-detail span');
        var precio = parseFloat(fila.getAttribute('data-precio')) || 0;
        var cantidad = parseFloat(fila.getAttribute('data-cantidad')) || 1;
        var sub = precio * cantidad;
        subtotal += sub;
        if (nombreEl) {
            // Línea principal: nombre + cantidad + subtotal
            lineas += '- ' + nombreEl.textContent.trim() + (cantidad > 1 ? ' x' + cantidad : '') + ' - ' + fmtTextoMoneda(sub, monedaEnvio) + '\n';
            // Línea secundaria: personalización (si tiene)
            var pers = detalleEl ? detalleEl.textContent.trim() : '';
            if (pers !== '') {
                lineas += '  ✏️ ' + pers + '\n';
            }
        }
    });

    // Descuento -> siempre se convierte a Bs internamente
    var descuentoInput = parseFloat(document.getElementById('txDescuento').value) || 0;
    var ddDescMon = document.getElementById('ddDescuentoMoneda');
    var descuentoBs = descuentoInput;
    if (ddDescMon && ddDescMon.value === 'USD' && tasaCambio > 0) {
        descuentoBs = descuentoInput * tasaCambio;
    }

    // Envio
    var costoEnvio = 0;
    var zonaTexto = '';
    var hdZonaId = document.getElementById('hdZonaId');
    if (hdZonaId && hdZonaId.value) {
        var zid = parseInt(hdZonaId.value);
        zonasData.forEach(function(z) {
            if (z.zona_id === zid) { costoEnvio = z.precio_bs; zonaTexto = z.nombre; }
        });
    }

    // Recargo horario
    var recargoHorario = 0;
    var horarioTexto = '';
    var ddSlot = document.getElementById('ddSlot');
    if (ddSlot && ddSlot.value) {
        var sid = parseInt(ddSlot.value);
        slotsData.forEach(function(s) {
            if (s.slot_id === sid) {
                recargoHorario = s.recargo_bs;
                horarioTexto = s.etiqueta;
            }
        });
    }

    // Express: el checkbox es solo informativo (recargo ya viene en el slot)
    var recargoExpress = 0;

    var total = subtotal + costoEnvio + recargoHorario + recargoExpress - descuentoBs;

    var mensaje = '*Miss Flores - Cotizacion*\n\n';
    mensaje += lineas + '\n';
    mensaje += 'Subtotal: ' + fmtTextoMoneda(subtotal, monedaEnvio) + '\n';
    if (costoEnvio > 0) {
        mensaje += 'Envio (' + zonaTexto + '): ' + fmtTextoMoneda(costoEnvio, monedaEnvio) + '\n';
    }
    // Horario: siempre que el cliente eligio uno, con o sin recargo
    if (horarioTexto !== '') {
        if (recargoHorario > 0) {
            mensaje += 'Horario (' + horarioTexto + '): ' + fmtTextoMoneda(recargoHorario, monedaEnvio) + '\n';
        } else {
            mensaje += 'Horario (' + horarioTexto + '): sin recargo\n';
        }
    }
    // Línea de "Recargo express" eliminada: ya viene incluido en el slot horario
    if (descuentoBs > 0) {
        mensaje += 'Descuento: -' + fmtTextoMoneda(descuentoBs, monedaEnvio) + '\n';
    }
    mensaje += '*Total: ' + fmtTextoMoneda(total, monedaEnvio) + '*';
    if (monedaEnvio === 'USD') {
        mensaje += '\n_Tasa: ' + tasaCambio.toFixed(2) + ' Bs/USD_';
    }

    // Limpiar numero de celular
    var numLimpio = celular.replace(/[^0-9]/g, '');
    if (numLimpio.length === 8 && (numLimpio.startsWith('6') || numLimpio.startsWith('7'))) {
        numLimpio = '591' + numLimpio;
    }
    if (!numLimpio.startsWith('591') && numLimpio.length < 10) {
        numLimpio = '591' + numLimpio;
    }

    abrirWhatsApp(numLimpio, mensaje);
}

// ============================================================
// ENVIAR LINK AL CLIENTE
// Usa PrePedido_Handler.ashx (accion GENERAR_TOKEN) que ya existe
// Mismo comportamiento que en PrePedido_Detalle.aspx
// ============================================================
function enviarLinkCliente() {
    if (prepedidoId === 0) { mostrarToast('Pre-pedido invalido', 'err'); return; }

    var formData = new FormData();
    formData.append('accion', 'GENERAR_TOKEN');
    formData.append('prepedido_id', prepedidoId);

    fetch('PrePedido_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (!data.ok) {
            if (data.entregas_incompletas && data.entregas_incompletas.length > 0) {
                mostrarModalEntregasIncompletas(data.entregas_incompletas);
                return;
            }
            mostrarToast('Error: ' + (data.msg || 'no se pudo generar el link'), 'err');
            return;
        }

        var mensaje = 'Por favor ingrese al siguiente link para confirmar, llenar los datos de su pedido y completar el pago:\n' + data.url;
        abrirWhatsApp(data.celular_cliente, mensaje);
        mostrarToast('Link generado y enviado', 'ok');

        setTimeout(function() { location.reload(); }, 1200);
    })
    .catch(function() { mostrarToast('Error de red al generar el link', 'err'); });
}

// Modal de entregas incompletas (replicado de PrePedido_Detalle.aspx)
function mostrarModalEntregasIncompletas(lista) {
    var overlay = document.getElementById('modalValidacionLink');
    if (overlay) overlay.parentNode.removeChild(overlay);

    overlay = document.createElement('div');
    overlay.id = 'modalValidacionLink';
    overlay.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:10000;overflow-y:auto;padding:20px;display:flex;align-items:flex-start;justify-content:center';

    var html = '<div style="background:white;border-radius:12px;max-width:560px;width:100%;margin-top:40px;overflow:hidden;box-shadow:0 10px 40px rgba(0,0,0,0.2)">';
    html += '<div style="background:#FFEBEE;color:#B71C1C;padding:16px 22px;display:flex;align-items:center;gap:12px;border-bottom:2px solid #FFCDD2">';
    html += '<i class="ti ti-alert-triangle" style="font-size:28px;color:#C62828"></i>';
    html += '<div style="flex:1">';
    html += '<p style="margin:0;font-size:16px;font-weight:600">No se puede enviar el link</p>';
    html += '<p style="margin:2px 0 0;font-size:13px;color:#7F1D1D">Faltan datos en ' + lista.length + ' entrega' + (lista.length === 1 ? '' : 's') + '.</p>';
    html += '</div>';
    html += '<button type="button" onclick="cerrarModalValidacion()" style="border:none;background:none;cursor:pointer;font-size:22px;color:#999"><i class="ti ti-x"></i></button>';
    html += '</div>';

    html += '<div style="padding:18px 22px;max-height:55vh;overflow-y:auto">';
    lista.forEach(function(item) {
        html += '<div style="border:1px solid #FFCDD2;background:#FFF5F5;border-radius:10px;padding:12px 14px;margin-bottom:10px">';
        html += '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">';
        if (item.entrega_id > 0) {
            html += '<p style="margin:0;font-size:14px;font-weight:600;color:#B71C1C">Entrega ' + item.numero + ' &mdash; ' + escapeHtml(item.receptor) + '</p>';
            if (item.entrega_id === prepedidoEntregaId) {
                html += '<span style="font-size:11px;color:#B71C1C;font-style:italic">(esta entrega)</span>';
            } else {
                html += '<button type="button" onclick="window.location.href=\'Entrega_Agregar.aspx?id=' + item.entrega_id + '\'" style="font-size:12px;padding:5px 12px;background:#3B5BDB;color:white;border:none;border-radius:6px;cursor:pointer;font-weight:500"><i class="ti ti-edit" style="font-size:13px;vertical-align:-2px"></i> Completar</button>';
            }
        } else {
            html += '<p style="margin:0;font-size:14px;font-weight:600;color:#B71C1C">Pre-pedido sin entregas</p>';
        }
        html += '</div>';
        html += '<ul style="margin:0;padding-left:20px;font-size:13px;color:#7F1D1D;line-height:1.7">';
        item.faltantes.forEach(function(campo) {
            html += '<li>' + escapeHtml(campo) + '</li>';
        });
        html += '</ul>';
        html += '</div>';
    });
    html += '</div>';

    html += '<div style="padding:12px 22px;background:#FAFAFA;border-top:1px solid #f0f0f0;display:flex;justify-content:flex-end;gap:8px">';
    html += '<button type="button" onclick="cerrarModalValidacion()" style="padding:8px 18px;font-size:13px;background:white;color:#555;border:1px solid #d0d0d0;border-radius:6px;cursor:pointer;font-weight:500">Cerrar</button>';
    html += '</div>';

    html += '</div>';
    overlay.innerHTML = html;
    document.body.appendChild(overlay);

    overlay.addEventListener('click', function(ev) {
        if (ev.target === overlay) cerrarModalValidacion();
    });
}

function cerrarModalValidacion() {
    var overlay = document.getElementById('modalValidacionLink');
    if (overlay) overlay.parentNode.removeChild(overlay);
}
function verificarLink() { location.reload(); }
function crearPedidoWC() {
    var resultado = validarChecklistCompleto();
    if (!resultado.ok) {
        mostrarToast('Faltan datos: ' + resultado.faltantes.join(', '), 'warn');
        return;
    }

    if (!confirm('Esto va a:\n1) Confirmar el pedido en SISCONBOL (genera codigo PED-...)\n2) Crear el pedido en WooCommerce.\n\n¿Continuar?')) {
        return;
    }

    var btn = document.getElementById('btnCrearWC');
    var txt = document.getElementById('txtEstadoWC');
    if (btn) btn.disabled = true;
    if (txt) {
        txt.innerHTML = '<i class="ti ti-loader" style="font-size:13px;vertical-align:-1px"></i> Procesando... no cierre esta pagina';
        txt.style.color = '#3B5BDB';
    }

    var formData = new FormData();
    formData.append('accion', 'CREAR_WC');
    formData.append('prepedido_entrega_id', prepedidoEntregaId);

    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.ok) {
            var msg = 'Pedido creado: ' + (data.codigo || '?');
            if (data.wc_order_id && data.wc_order_id > 0) {
                msg += '  |  WooCommerce #' + data.wc_order_id;
            }
            mostrarToast(msg, 'ok', 6000);
            if (txt) {
                txt.innerHTML = '<i class="ti ti-circle-check" style="font-size:13px;vertical-align:-1px"></i> ' + msg;
                txt.style.color = '#2E7D32';
            }

            // Abrir el recibo en nueva pestaña para imprimir
            if (data.pedido_id && data.pedido_id > 0) {
                window.open('Recibo.aspx?id=' + data.pedido_id, '_blank');
            }

            // Volver al detalle del prepedido tras 2s
            setTimeout(function() {
                window.location.href = 'PrePedido_Detalle.aspx?id=' + prepedidoId;
            }, 2000);
        } else {
            // Si confirmar funciono pero WC fallo, igual nos quedamos en la pagina
            // para que el agente vea el error y pueda reintentar luego.
            var msg = data.msg || 'Error al crear el pedido';
            mostrarToast('Error: ' + msg, 'err', 8000);
            if (txt) {
                txt.innerHTML = '<i class="ti ti-alert-triangle" style="font-size:13px;vertical-align:-1px"></i> ' + escapeHtml(msg);
                txt.style.color = '#C62828';
            }
            // Si el pedido SI se confirmo (existe pedido_id), reactivar el boton
            // tendria poco sentido. Mejor recargar para ver el estado real.
            if (data.pedido_id && data.pedido_id > 0) {
                setTimeout(function() { location.reload(); }, 4000);
            } else {
                // Si fallo antes de confirmar, podemos reactivar el boton
                if (btn) btn.disabled = false;
            }
        }
    })
    .catch(function(err) {
        mostrarToast('Error de red: ' + err, 'err', 8000);
        if (btn) btn.disabled = false;
        if (txt) {
            txt.textContent = 'Error de red. Intente de nuevo.';
            txt.style.color = '#C62828';
        }
    });
}
// ============================================================
// SELECCIONAR SUCURSAL DE RECOJO
// Al elegir sucursal en modo Recojo: ademas de guardar sucursal_id,
// auto-llena los siguientes campos (SOBRESCRIBIENDO lo que hubiera):
//   - Persona que recibe = "Recoge en tienda <Sucursal>"
//   - Celular receptor   = copia del celular del cliente
//   - Ocasion            = "OTRO"
//   - Dedicatoria        = "Por recoge en tienda"
//   - Firma              = "Recoge en tienda"
// Cada cambio se guarda al servidor via guardarCampo().
// ============================================================
function seleccionarSucursalRecojo(id) {
    guardarCampo('sucursal_id', id);

    // Obtener nombre legible de la sucursal desde la tarjeta clicada
    var sucNombre = '';
    var card = document.querySelector('#fieldsRecojo .ea-sucursal-card.selected p');
    if (card) {
        sucNombre = (card.textContent || card.innerText || '').trim();
    }

    // 1) Persona que recibe
    var textoReceptor = 'Recoge en tienda' + (sucNombre ? ' ' + sucNombre : '');
    var txReceptor = document.getElementById('txReceptor');
    if (txReceptor) {
        txReceptor.value = textoReceptor;
        guardarCampo('receptor_nombre', textoReceptor);
    }

    // 2) Celular receptor = celular del cliente
    var txCelCli = document.getElementById('txClienteCelular');
    var txCelRec = document.getElementById('txCelularReceptor');
    if (txCelRec && txCelCli) {
        var celCli = (txCelCli.value || '').trim();
        if (celCli) {
            txCelRec.value = celCli;
            guardarCampo('receptor_celular', celCli);
        }
    }

    // 3) Ocasion = OTRO
    var ddOca = document.getElementById('ddOcasion');
    if (ddOca) {
        ddOca.value = 'OTRO';
        guardarCampo('tipo_ocacion', 'OTRO');
    }

    // 4) Dedicatoria
    var textoDed = 'Por recoge en tienda';
    var txDed = document.getElementById('txDedicatoria');
    if (txDed) {
        txDed.value = textoDed;
        guardarCampo('dedicatoria', textoDed);
    }

    // 5) Firma
    var textoFir = 'Recoge en tienda';
    var txFir = document.getElementById('txFirma');
    if (txFir) {
        txFir.value = textoFir;
        guardarCampo('firma_tarjeta', textoFir);
    }

    actualizarChecklist();
}

// ============================================================
// CHECKLIST DE CAMPOS OBLIGATORIOS
// Valida los 7 grupos requeridos para enviar el pedido a WooCommerce.
// Habilita / deshabilita el boton "Crear pedido en WC" y actualiza
// el contador "X de 7" y la lista visual #divChecklist.
// ============================================================
function validarChecklistCompleto() {
    var items = [];

    // 1. Productos: al menos uno
    var cantProductos = document.querySelectorAll('.ea-prod-row').length;
    items.push({ etiqueta: 'Producto(s)', ok: cantProductos > 0 });

    // 2. Ciudad
    var ddCiudad = document.getElementById('ddCiudad');
    var ciudadId = ddCiudad ? (parseInt(ddCiudad.value) || 0) : 0;
    items.push({ etiqueta: 'Ciudad', ok: ciudadId > 0 });

    // 3. Datos de entrega (varia segun tipo)
    var radioDom = document.querySelector('input[name="tipoEntrega"][value="DOMICILIO"]');
    var esDomicilio = !!(radioDom && radioDom.checked);
    var entregaOk = false;
    var etiquetaEntrega = '';
    if (esDomicilio) {
        var hdZ = document.getElementById('hdZonaId');
        var zonaId = hdZ ? (parseInt(hdZ.value) || 0) : 0;
        var txDir = document.getElementById('txDireccion');
        var direccion = txDir ? (txDir.value || '').trim() : '';
        entregaOk = (zonaId > 0 && direccion !== '');
        etiquetaEntrega = 'Zona y direccion';
    } else {
        var sucSel = document.querySelector('#fieldsRecojo .ea-sucursal-card.selected');
        entregaOk = !!sucSel;
        etiquetaEntrega = 'Sucursal de recojo';
    }
    items.push({ etiqueta: etiquetaEntrega, ok: entregaOk });

    // 4. Fecha
    var txF = document.getElementById('txFecha');
    var fecha = txF ? (txF.value || '').trim() : '';
    items.push({ etiqueta: 'Fecha de entrega', ok: fecha !== '' });

    // 5. Horario
    var ddS = document.getElementById('ddSlot');
    var slotId = ddS ? (parseInt(ddS.value) || 0) : 0;
    items.push({ etiqueta: 'Horario', ok: slotId > 0 });

    // 6. Receptor (nombre + celular)
    var txR = document.getElementById('txReceptor');
    var txC = document.getElementById('txCelularReceptor');
    var receptor = txR ? (txR.value || '').trim() : '';
    var celular = txC ? (txC.value || '').trim() : '';
    items.push({ etiqueta: 'Receptor (nombre y celular)', ok: receptor !== '' && celular !== '' });

    // 7. Pago: ahora INFORMATIVO. Permite crear pedido WC con saldo pendiente.
    //    Solo BLOQUEA si hay sobrepago (eso si es un error logico).
    //    Suma TODOS los pagos no-RECHAZADOS (VERIFICADO + PENDIENTE) porque
    //    al confirmar el pedido los PENDIENTE pasan a VERIFICADO (FIX SP).
    var sumaCuenta = 0;
    var sumaVerificado = 0;
    var sumaPendiente = 0;
    document.querySelectorAll('.ea-pago-row').forEach(function(row) {
        var est = (row.getAttribute('data-estado') || '').toUpperCase();
        var m = parseFloat(row.getAttribute('data-monto-bs')) || 0;
        if (est === 'VERIFICADO') { sumaVerificado += m; sumaCuenta += m; }
        else if (est === 'PENDIENTE') { sumaPendiente += m; sumaCuenta += m; }
        // RECHAZADO no se suma
    });
    var totalPedido = leerTotalPedidoBs();
    var pagoOk = true;
    var etiquetaPago = '';
    if (totalPedido <= 0) {
        etiquetaPago = 'Pago (sin total calculado)';
    } else if (sumaCuenta > totalPedido + 0.01) {
        // Sobrepago: bloquear
        var exceso = sumaCuenta - totalPedido;
        etiquetaPago = 'Pago excede el total en Bs ' + exceso.toFixed(2);
        pagoOk = false;
    } else if (sumaCuenta + 0.01 >= totalPedido) {
        // Pagado completo
        etiquetaPago = 'Pago completo (Bs ' + sumaCuenta.toFixed(2) + ')';
    } else if (sumaCuenta > 0) {
        // Pago parcial: informativo, NO bloquea
        var saldoFalta = totalPedido - sumaCuenta;
        etiquetaPago = 'Pago parcial: Bs ' + sumaCuenta.toFixed(2) + ' de ' + totalPedido.toFixed(2) +
                       ' (saldo Bs ' + saldoFalta.toFixed(2) + ')';
    } else {
        // Sin pago: informativo, NO bloquea
        etiquetaPago = 'Sin pago registrado (saldo Bs ' + totalPedido.toFixed(2) + ')';
    }
    items.push({ etiqueta: etiquetaPago, ok: pagoOk });

    var faltantes = [];
    items.forEach(function(it) { if (!it.ok) faltantes.push(it.etiqueta); });

    return { ok: faltantes.length === 0, items: items, faltantes: faltantes };
}

// Lee el total en Bs desde #resTotal (texto "Bs 123.45" o "Bs 123.45 (USD ...)")
function leerTotalPedidoBs() {
    var sp = document.getElementById('resTotal');
    if (!sp) return 0;
    var txt = sp.textContent || sp.innerText || '';
    var m = txt.match(/Bs\s+([\d,]+\.?\d*)/);
    if (!m) return 0;
    return parseFloat(m[1].replace(/,/g, '')) || 0;
}

// Pinta el checklist visual, actualiza contador y habilita / deshabilita el boton
function actualizarChecklist() {
    var resultado = validarChecklistCompleto();
    var total = resultado.items.length;
    var okCount = total - resultado.faltantes.length;

    // Contador "X de N"
    var spanCont = document.getElementById('spanCamposConteo');
    if (spanCont) {
        spanCont.textContent = okCount + ' de ' + total;
        spanCont.className = 'ea-badge ' + (okCount === total ? 'ea-badge-success' : 'ea-badge-warning');
    }

    // Lista de items
    var divCheck = document.getElementById('divChecklist');
    if (divCheck) {
        var html = '';
        resultado.items.forEach(function(it) {
            var icono = it.ok
                ? '<i class="ti ti-circle-check" style="font-size:14px;color:#2E7D32" aria-hidden="true"></i>'
                : '<i class="ti ti-circle" style="font-size:14px;color:#bbb" aria-hidden="true"></i>';
            var color = it.ok ? '#333' : '#999';
            html += '<div class="ea-check-item" style="color:' + color + '">' + icono + ' ' + escapeHtml(it.etiqueta) + '</div>';
        });
        divCheck.innerHTML = html;
    }

    // Boton + texto explicativo
    var btn = document.getElementById('btnCrearWC');
    var txt = document.getElementById('txtEstadoWC');
    if (btn) btn.disabled = !resultado.ok;
    if (txt) {
        if (resultado.ok) {
            txt.textContent = 'Todo listo para crear el pedido en WooCommerce';
            txt.style.color = '#2E7D32';
        } else {
            txt.textContent = 'Faltan ' + resultado.faltantes.length + ' campo(s) obligatorio(s)';
            txt.style.color = '#999';
        }
    }
}

// ============================================================
// UTILIDADES
// ============================================================
function mostrarGuardando() {
    var s = document.getElementById('spanGuardado');
    s.innerHTML = '<i class="ti ti-loader" style="font-size:13px"></i> Guardando...'; s.style.color = '#999';
}
function mostrarGuardado() {
    var s = document.getElementById('spanGuardado');
    s.innerHTML = '<i class="ti ti-check" style="font-size:13px"></i> Guardado'; s.style.color = '#2E7D32';
}
function mostrarError() {
    var s = document.getElementById('spanGuardado');
    s.innerHTML = '<i class="ti ti-x" style="font-size:13px"></i> Error'; s.style.color = '#E53935';
}
function actualizarConteoItems() {
    var items = document.querySelectorAll('.ea-prod-row');
    document.getElementById('spanCantItems').textContent = items.length + ' items';
}
function escapeHtml(text) {
    if (!text) return '';
    var div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
// escapeAttr: solo escapa los 3 caracteres peligrosos dentro de un atributo HTML
// con comillas dobles. NO toca tildes, ñ, paréntesis ni emojis -> getAttribute()
// devuelve el texto tal cual lo escribió el usuario.
function escapeAttr(text) {
    if (text === null || text === undefined) return '';
    return String(text)
        .replace(/&/g, '&amp;')
        .replace(/"/g, '&quot;')
        .replace(/</g, '&lt;');
}

// ============================================================
// ABRIR WHATSAPP usando el esquema directo whatsapp://
// Evita la pestaña en blanco que deja https://wa.me/ con window.open.
// Si el usuario no tiene WhatsApp instalado, hace fallback a wa.me.
// ============================================================
function abrirWhatsApp(celular, mensaje) {
    var numero = (celular || '').toString().replace(/[^0-9]/g, '');
    var texto = encodeURIComponent(mensaje || '');
    var urlApp = numero
        ? ('whatsapp://send?phone=' + numero + '&text=' + texto)
        : ('whatsapp://send?text=' + texto);
    var urlWeb = numero
        ? ('https://wa.me/' + numero + '?text=' + texto)
        : ('https://wa.me/?text=' + texto);

    // Crear un <a> efimero, dispararlo, y removerlo. No deja pestaña en blanco.
    var a = document.createElement('a');
    a.href = urlApp;
    a.style.display = 'none';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);

    // Fallback: si en 1.5s no salio del foco (no se lanzo WhatsApp),
    // abrir wa.me en nueva pestaña como ultimo recurso.
    var perdioFoco = false;
    var marcador = function() { perdioFoco = true; };
    window.addEventListener('blur', marcador, { once: true });
    setTimeout(function() {
        window.removeEventListener('blur', marcador);
        if (!perdioFoco) {
            window.open(urlWeb, '_blank');
        }
    }, 1500);
}

// ============================================================
// TOAST DE NOTIFICACIÓN
// tipo: 'ok' (verde), 'warn' (naranja), 'err' (rojo)
// ============================================================
function mostrarToast(mensaje, tipo, duracion) {
    var tipoClase = tipo || 'ok';
    var ms = duracion || (tipoClase === 'warn' ? 5000 : 3000);
    var contenedor = document.getElementById('eaToastContainer');
    if (!contenedor) return;
    var iconos = { ok: 'ti-circle-check', warn: 'ti-alert-triangle', err: 'ti-alert-circle' };
    var icono = iconos[tipoClase] || 'ti-info-circle';
    var toast = document.createElement('div');
    toast.className = 'ea-toast ' + tipoClase;
    toast.innerHTML = '<i class="ti ' + icono + '" aria-hidden="true"></i><span>' + escapeHtml(mensaje) + '</span>';
    contenedor.appendChild(toast);
    setTimeout(function() {
        toast.classList.add('fade-out');
        setTimeout(function() { if (toast.parentNode) toast.parentNode.removeChild(toast); }, 320);
    }, ms);
}

// ============================================================
// INICIALIZAR
// ============================================================
document.addEventListener('DOMContentLoaded', function() {
    toggleTipoEntrega();
    filtrarZonas(true);  // preservar zona pre-cargada del servidor
    sincronizarExpressConSlot();  // sincronizar checkbox según slot inicial
    actualizarConteoItems();
    calcularSubtotal();
    actualizarChecklist();
});
</script>
</asp:Content>
