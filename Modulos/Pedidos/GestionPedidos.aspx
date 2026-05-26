<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="GestionPedidos.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_GestionPedidos" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Gestion de Pedidos
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-clipboard-list" style="vertical-align:-2px"></i> Gestion de Pedidos
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

<!-- Alerta -->
<div class="alerta" id="divAlerta"></div>

<!-- Header con resumen -->
<div class="panel" style="margin-bottom:14px">
    <div class="panel-head">
        <div class="gp-header-info">
            <div class="gp-header-icon"><i class="ti ti-clipboard-list"></i></div>
            <div>
                <div class="gp-header-title"><%= TotalHoy %> pedidos hoy</div>
                <div class="gp-header-subtitle"><%= TotalPendientesWC %> esperando aceptacion manual</div>
            </div>
        </div>
        <div class="panel-actions">
            <button type="button" class="btn btn-primary" onclick="window.location.href='PrePedido_Crear.aspx'">
                <i class="ti ti-plus"></i> Nuevo pedido
            </button>
        </div>
    </div>
</div>

<!-- Banner WC pendientes (solo si hay) -->
<% If TotalPendientesWC > 0 Then %>
<div class="banner-warn" id="bannerWC">
    <div class="banner-warn-head" onclick="toggleBannerWC()">
        <div class="banner-warn-title">
            <i class="ti ti-alert-triangle"></i>
            <div>
                <div class="t1"><%= TotalPendientesWC %> pedidos de WooCommerce esperando aceptacion manual</div>
                <div class="t2">Verifica el pago en tu banco antes de aceptar. WooCommerce nunca los confirmara automaticamente.</div>
            </div>
        </div>
        <button type="button" class="btn btn-sm" onclick="event.stopPropagation(); toggleBannerWC()">
            <i class="ti ti-chevron-up" id="iconBannerWC"></i> <span id="textBannerWC">Ocultar</span>
        </button>
    </div>
    <div class="banner-warn-body" id="bannerWCBody">
        <div class="wc-row wc-row-head">
            <span>WC #</span>
            <span>Cliente / contacto</span>
            <span>Metodo de pago</span>
            <span>Estado WC</span>
            <span style="text-align:right">Monto</span>
            <span style="text-align:right">Acciones</span>
        </div>
        <%= TablaPendientesWC %>
    </div>
</div>
<% End If %>

<!-- Panel principal -->
<div class="panel">
    <div class="panel-head">
        <div class="panel-title">Pedidos del periodo</div>
        <div class="panel-actions">
            <button type="button" class="btn btn-sm" onclick="refrescar()">
                <i class="ti ti-refresh"></i> Refrescar
            </button>
        </div>
    </div>

    <!-- Filtros -->
    <div class="panel-filters">
        <div class="filter-group">
            <label>Buscar</label>
            <div class="search-wrap">
                <i class="ti ti-search"></i>
                <input type="text" id="txBuscar" class="form-control" 
                       placeholder="Codigo, cliente, celular..." 
                       value="<%= ValorBuscar %>" style="min-width:240px"/>
            </div>
        </div>
        <div class="filter-group">
            <label>Desde</label>
            <input type="date" id="txDesde" class="form-control" value="<%= ValorDesde %>"/>
        </div>
        <div class="filter-group">
            <label>Hasta</label>
            <input type="date" id="txHasta" class="form-control" value="<%= ValorHasta %>"/>
        </div>
        <div class="filter-group">
            <label>&nbsp;</label>
            <label class="filter-check <%= If(ValorSoloHoy = "1", "active", "") %>">
                <input type="checkbox" id="chkHoy" <%= If(ValorSoloHoy = "1", "checked", "") %>/>
                <i class="ti ti-calendar-event"></i> Entregas hoy
            </label>
        </div>
        <div class="filter-group">
            <label>Estado pago</label>
            <select id="ddPago" class="form-control">
                <option value="">Todos</option>
                <option value="PAGADO" <%= If(ValorEstadoPago = "PAGADO", "selected", "") %>>Pagado</option>
                <option value="ANTICIPO" <%= If(ValorEstadoPago = "ANTICIPO", "selected", "") %>>Anticipo</option>
                <option value="PENDIENTE" <%= If(ValorEstadoPago = "PENDIENTE", "selected", "") %>>Pendiente</option>
            </select>
        </div>
        <div class="filter-group">
            <label>Estado operativo</label>
            <select id="ddOperativo" class="form-control">
                <option value="">Todos</option>
                <option value="PENDIENTE" <%= If(ValorEstadoOp = "PENDIENTE", "selected", "") %>>Pendiente</option>
                <option value="IMPRESO" <%= If(ValorEstadoOp = "IMPRESO", "selected", "") %>>Impreso</option>
                <option value="EN_PREPARACION" <%= If(ValorEstadoOp = "EN_PREPARACION", "selected", "") %>>En preparacion</option>
                <option value="LISTO" <%= If(ValorEstadoOp = "LISTO", "selected", "") %>>Listo</option>
                <option value="EN_RUTA" <%= If(ValorEstadoOp = "EN_RUTA", "selected", "") %>>En ruta</option>
                <option value="ENTREGADO" <%= If(ValorEstadoOp = "ENTREGADO", "selected", "") %>>Entregado</option>
                <option value="NO_ENTREGADO" <%= If(ValorEstadoOp = "NO_ENTREGADO", "selected", "") %>>No entregado</option>
            </select>
        </div>
        <div class="filter-group">
            <label>Delivery</label>
            <select id="ddDelivery" class="form-control">
                <option value="">Todos</option>
                <%= OptionsDelivery %>
            </select>
        </div>
        <div class="filter-group">
            <label>&nbsp;</label>
            <label class="filter-check <%= If(ValorSoloExpress = "1", "active", "") %>">
                <input type="checkbox" id="chkExpress" <%= If(ValorSoloExpress = "1", "checked", "") %>/>
                <i class="ti ti-bolt"></i> Express
            </label>
        </div>
        <div class="filter-group">
            <label>&nbsp;</label>
            <button type="button" class="btn btn-primary" onclick="aplicarFiltros()">
                <i class="ti ti-filter"></i> Filtrar
            </button>
        </div>
    </div>

    <!-- Tabla -->
    <div class="table-container">
        <table class="table">
            <thead>
                <tr>
                    <th style="width:80px">Hora</th>
                    <th style="width:110px">Codigos</th>
                    <th>Receptor / direccion</th>
                    <th style="width:110px">Zona</th>
                    <th style="width:95px">Pago</th>
                    <th style="width:110px">Estado op.</th>
                    <th style="width:100px">Delivery</th>
                    <th style="width:130px;text-align:right">Acciones</th>
                </tr>
            </thead>
            <tbody>
                <%= TablaPedidos %>
            </tbody>
        </table>
    </div>
</div>

<!-- Hidden fields y boton oculto para postback -->
<input type="hidden" id="hdAccion" name="hdAccion" value=""/>
<input type="hidden" id="hdPedidoId" name="hdPedidoId" value=""/>
<asp:Button ID="btnPostBack" runat="server" Text="" Style="display:none" OnClick="btnAccion_Click"/>

<!-- Modal confirmación aceptar pago -->
<div class="modal-overlay hidden" id="modalAceptar">
    <div class="modal-confirm">
        <div class="modal-confirm-body">
            <div class="modal-icon-big"><i class="ti ti-check"></i></div>
            <div class="modal-title-big">Aceptar pago manual?</div>
            <div class="modal-msg" id="modalAceptarMsg">
                Vas a aceptar el pago de este pedido. Asegurate de haber verificado el pago en tu banco. Esta accion no se puede deshacer.
            </div>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn" onclick="cerrarModalAceptar()">Cancelar</button>
            <button type="button" class="btn btn-success" onclick="confirmarAceptarPago()">
                <i class="ti ti-check"></i> Si, aceptar pago
            </button>
        </div>
    </div>
</div>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

var _pedidoAceptarId = 0;

function toggleBannerWC() {
    var body = document.getElementById('bannerWCBody');
    var icon = document.getElementById('iconBannerWC');
    var txt = document.getElementById('textBannerWC');
    if (!body) return;
    
    if (body.classList.contains('hidden')) {
        body.classList.remove('hidden');
        if (icon) icon.className = 'ti ti-chevron-up';
        if (txt) txt.textContent = 'Ocultar';
    } else {
        body.classList.add('hidden');
        if (icon) icon.className = 'ti ti-chevron-down';
        if (txt) txt.textContent = 'Mostrar';
    }
}

function aplicarFiltros() {
    var buscar = document.getElementById('txBuscar');
    var desde = document.getElementById('txDesde');
    var hasta = document.getElementById('txHasta');
    var hoy = document.getElementById('chkHoy');
    var pago = document.getElementById('ddPago');
    var op = document.getElementById('ddOperativo');
    var deli = document.getElementById('ddDelivery');
    var exp = document.getElementById('chkExpress');
    
    var url = 'GestionPedidos.aspx?';
    if (buscar && buscar.value) url += 'b=' + encodeURIComponent(buscar.value) + '&';
    if (desde && desde.value) url += 'd=' + desde.value + '&';
    if (hasta && hasta.value) url += 'h=' + hasta.value + '&';
    if (hoy && hoy.checked) url += 'hoy=1&';
    if (pago && pago.value) url += 'p=' + pago.value + '&';
    if (op && op.value) url += 'op=' + op.value + '&';
    if (deli && deli.value) url += 'deli=' + deli.value + '&';
    if (exp && exp.checked) url += 'exp=1&';
    
    window.location.href = url;
}

function refrescar() {
    window.location.reload();
}

function verDetalle(pedidoId) {
    window.location.href = 'PedidoDetalle.aspx?id=' + pedidoId;
}

function imprimirTicket(pedidoId) {
    var ventana = window.open('TicketImprimir.aspx?id=' + pedidoId, 
        'ticket', 'width=400,height=600,toolbar=no,menubar=no');
    if (ventana) ventana.focus();
}

// Aceptar pago manual
function abrirModalAceptar(pedidoId, cliente, monto) {
    _pedidoAceptarId = pedidoId;
    var msg = document.getElementById('modalAceptarMsg');
    if (msg) {
        msg.innerHTML = 'Vas a aceptar el pago del pedido <strong>' + cliente + 
            '</strong> por <strong>Bs ' + monto + '</strong>.<br><br>' +
            'Asegurate de haber verificado el pago en tu banco. Esta accion no se puede deshacer.';
    }
    var modal = document.getElementById('modalAceptar');
    if (modal) modal.classList.remove('hidden');
}

function cerrarModalAceptar() {
    var modal = document.getElementById('modalAceptar');
    if (modal) modal.classList.add('hidden');
    _pedidoAceptarId = 0;
}

function confirmarAceptarPago() {
    if (_pedidoAceptarId <= 0) return;
    
    var hdAccion = document.getElementById('hdAccion');
    var hdPedidoId = document.getElementById('hdPedidoId');
    
    if (hdAccion) hdAccion.value = 'ACEPTAR_PAGO';
    if (hdPedidoId) hdPedidoId.value = _pedidoAceptarId;
    
    cerrarModalAceptar();
    
    var btn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (btn) btn.click();
}

// Cambiar estado operativo via prompt
function cambiarEstado(pedidoId, estadoActual) {
    var estados = [
        'PENDIENTE', 'IMPRESO', 'EN_PREPARACION', 'LISTO', 
        'EN_RUTA', 'ENTREGADO', 'NO_ENTREGADO', 'REPROGRAMADO'
    ];
    var msg = 'Estado actual: ' + estadoActual + '\n\nNuevo estado (escribe el numero):\n';
    for (var i = 0; i < estados.length; i++) {
        msg += (i+1) + '. ' + estados[i] + '\n';
    }
    var resp = prompt(msg);
    if (!resp) return;
    var idx = parseInt(resp, 10) - 1;
    if (isNaN(idx) || idx < 0 || idx >= estados.length) {
        alert('Numero invalido');
        return;
    }
    
    var hdAccion = document.getElementById('hdAccion');
    var hdPedidoId = document.getElementById('hdPedidoId');
    if (hdAccion) hdAccion.value = 'CAMBIAR_ESTADO_' + estados[idx];
    if (hdPedidoId) hdPedidoId.value = pedidoId;
    
    var btn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (btn) btn.click();
}

// Inicializacion
(function() {
    // Auto-submit con Enter en buscar
    var buscar = document.getElementById('txBuscar');
    if (buscar) {
        buscar.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') aplicarFiltros();
        });
    }
    
    // Mostrar alerta si viene de redirect con mensaje
    var alertMsg = '<%= MensajeAlerta %>';
    var alertTipo = '<%= TipoAlerta %>';
    if (alertMsg && alertMsg.length > 0) {
        var div = document.getElementById('divAlerta');
        if (div) {
            div.className = 'alerta show alerta-' + (alertTipo || 'success');
            div.textContent = alertMsg;
            setTimeout(function() { div.className = 'alerta'; }, 5000);
        }
    }
})();
</script>
</asp:Content>
