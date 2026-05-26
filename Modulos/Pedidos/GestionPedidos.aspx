<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="GestionPedidos.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_GestionPedidos" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Gestion de Pedidos
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-clipboard-list" style="vertical-align:-2px"></i> Gestion de Pedidos
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

<div class="alerta" id="divAlerta"></div>

<div class="panel">
    <div class="panel-head">
        <div class="gp-header-info">
            <div class="gp-header-icon"><i class="ti ti-clipboard-list"></i></div>
            <div>
                <div class="gp-header-title"><span id="lblTotal">0</span> pedidos hoy</div>
                <div class="gp-header-subtitle"><span id="lblPendientesWC"><%= TotalPendientesWC %></span> esperando aceptacion manual</div>
            </div>
        </div>
        <div class="panel-actions">
            <button type="button" class="btn-toggle-vista" id="btnVista" onclick="toggleVistaCompacta()">
                <i class="ti ti-layout-rows"></i> Detallado
            </button>
            <button type="button" class="btn btn-sm" onclick="cargarPedidos()">
                <i class="ti ti-refresh"></i> Refrescar
            </button>
        </div>
    </div>
</div>

<% If TotalPendientesWC > 0 Then %>
<div class="banner-warn" id="bannerWC">
    <div class="banner-warn-head" onclick="toggleBannerWC()">
        <div class="banner-warn-title">
            <i class="ti ti-alert-triangle"></i>
            <div>
                <div class="t1"><%= TotalPendientesWC %> pedidos WC esperando aceptacion manual</div>
                <div class="t2">Verifica el pago en tu banco antes de aceptar. WooCommerce nunca los confirmara automaticamente.</div>
            </div>
        </div>
        <button type="button" class="btn btn-sm" style="background:transparent;border-color:transparent" onclick="event.stopPropagation();toggleBannerWC()">
            <i class="ti ti-chevron-up" id="iconBannerWC"></i> <span id="textBannerWC">Ocultar</span>
        </button>
    </div>
    <div class="banner-warn-body" id="bannerWCBody">
        <div class="wc-row wc-row-head">
            <span>WC #</span>
            <span>Cliente</span>
            <span>Metodo pago</span>
            <span>Estado WC</span>
            <span style="text-align:right">Monto</span>
            <span style="text-align:right">Acciones</span>
        </div>
        <%= TablaPendientesWC %>
    </div>
</div>
<% End If %>

<div class="panel">
    <div class="panel-head">
        <div class="panel-title">Pedidos del periodo</div>
        <div class="panel-actions">
            <button type="button" class="btn btn-sm" onclick="limpiarFiltros()">
                <i class="ti ti-x"></i> Limpiar
            </button>
        </div>
    </div>

    <div style="padding:14px 16px;background:#fafafa;border-bottom:1px solid #e0e0e0">

        <div class="filter-group" style="margin-bottom:12px">
            <label>Buscar</label>
            <div class="search-wrap">
                <i class="ti ti-search"></i>
                <input type="text" id="txBuscar" class="form-control" placeholder="Codigo PED/WC, cliente, celular, direccion..."/>
            </div>
        </div>

        <div class="filter-fecha-bloque">
            <div class="filter-fecha-titulo entrega"><i class="ti ti-truck-delivery"></i> Fecha de entrega</div>
            <div style="display:flex;flex-wrap:wrap;gap:5px" id="pillsEntrega">
                <span class="pill-filter active" data-tipo="entrega" data-val="hoy">Hoy</span>
                <span class="pill-filter" data-tipo="entrega" data-val="manana">Manana</span>
                <span class="pill-filter" data-tipo="entrega" data-val="semana">Esta semana</span>
                <span class="pill-filter" data-tipo="entrega" data-val="prox7">Proximos 7d</span>
                <span class="pill-filter" data-tipo="entrega" data-val="rango">Rango...</span>
            </div>
            <div class="filter-fecha-rango" id="rangoEntrega">
                <input type="date" id="txFeDesde"/>
                <input type="date" id="txFeHasta"/>
            </div>
        </div>

        <div class="filter-fecha-bloque">
            <div class="filter-fecha-titulo creacion"><i class="ti ti-plus"></i> Fecha de creacion</div>
            <div style="display:flex;flex-wrap:wrap;gap:5px" id="pillsCreacion">
                <span class="pill-filter active" data-tipo="creacion" data-val="cualquiera">Cualquiera</span>
                <span class="pill-filter" data-tipo="creacion" data-val="hoy">Hoy</span>
                <span class="pill-filter" data-tipo="creacion" data-val="24h">Ultimas 24h</span>
                <span class="pill-filter" data-tipo="creacion" data-val="semana">Esta semana</span>
                <span class="pill-filter" data-tipo="creacion" data-val="rango">Rango...</span>
            </div>
            <div class="filter-fecha-rango" id="rangoCreacion">
                <input type="date" id="txCrDesde"/>
                <input type="date" id="txCrHasta"/>
            </div>
        </div>

        <div style="display:grid;grid-template-columns:1fr 1fr 1fr 1fr;gap:8px;margin-bottom:8px">
            <select id="ddPago" class="form-control" style="font-size:11px;height:32px;padding:5px 8px">
                <option value="">Pago: Todos</option>
                <option value="PAGADO">Pagado</option>
                <option value="ANTICIPO">Anticipo</option>
                <option value="PENDIENTE">Pendiente</option>
            </select>
            <select id="ddOperativo" class="form-control" style="font-size:11px;height:32px;padding:5px 8px">
                <option value="">Estado: Todos</option>
                <option value="PENDIENTE">Pendiente</option>
                <option value="IMPRESO">Impreso</option>
                <option value="EN_PREPARACION">En preparacion</option>
                <option value="LISTO">Listo</option>
                <option value="EN_RUTA">En ruta</option>
                <option value="ENTREGADO">Entregado</option>
                <option value="NO_ENTREGADO">No entregado</option>
            </select>
            <select id="ddZona" class="form-control" style="font-size:11px;height:32px;padding:5px 8px">
                <option value="">Zona: Todas</option>
                <%= OptionsZona %>
            </select>
            <select id="ddDelivery" class="form-control" style="font-size:11px;height:32px;padding:5px 8px">
                <option value="">Delivery: Todos</option>
                <option value="-1">Sin asignar</option>
                <%= OptionsDelivery %>
            </select>
        </div>

        <div style="display:flex;gap:5px;flex-wrap:wrap">
            <span class="pill-filter" data-flag="exp"><i class="ti ti-bolt" style="font-size:11px;color:#F57C00"></i> Solo express</span>
            <span class="pill-filter" data-flag="sc"><i class="ti ti-phone-off" style="font-size:11px"></i> Sin contactar</span>
            <span class="pill-filter" data-flag="sd"><i class="ti ti-user-off" style="font-size:11px"></i> Sin delivery</span>
        </div>
    </div>

    <div class="filtros-footer">
        <span class="auto-msg"><i class="ti ti-check"></i> Filtros se aplican al instante</span>
        <span>Mostrando <span id="lblMostrando">0</span> pedidos</span>
    </div>

    <div class="table-container">
        <table class="table" id="tablaPedidos">
            <thead>
                <tr>
                    <th style="width:90px"><i class="ti ti-clock"></i> Hora</th>
                    <th>Pedido / Receptor</th>
                    <th style="width:140px">Zona / Delivery</th>
                    <th style="width:120px">Estado</th>
                    <th style="width:110px;text-align:right">Acciones</th>
                </tr>
            </thead>
            <tbody id="tbodyPedidos">
                <tr><td colspan="5" class="tabla-loading"><i class="ti ti-loader"></i><br>Cargando...</td></tr>
            </tbody>
        </table>
    </div>
</div>

<input type="hidden" id="hdAccion" name="hdAccion" value=""/>
<input type="hidden" id="hdPedidoId" name="hdPedidoId" value=""/>
<input type="hidden" id="hdEstadoNuevo" name="hdEstadoNuevo" value=""/>
<asp:Button ID="btnPostBack" runat="server" Text="" Style="display:none" OnClick="btnAccion_Click"/>

<div class="modal-overlay hidden" id="modalAceptar">
    <div class="modal-confirm">
        <div class="modal-confirm-body">
            <div class="modal-icon-big"><i class="ti ti-check"></i></div>
            <div class="modal-title-big">Aceptar pago manual?</div>
            <div class="modal-msg" id="modalAceptarMsg">Vas a aceptar el pago de este pedido. Asegurate de haber verificado el pago en tu banco. Esta accion no se puede deshacer.</div>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn" onclick="cerrarModalAceptar()">Cancelar</button>
            <button type="button" class="btn btn-success" onclick="confirmarAceptarPago()"><i class="ti ti-check"></i> Si, aceptar pago</button>
        </div>
    </div>
</div>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

var _pedidoAceptarId = 0;
var _vistaCompacta = false;
var _timerBuscar = null;
var _btnPostbackId = '<%= btnPostBack.ClientID %>';

function toggleVistaCompacta() {
    _vistaCompacta = !_vistaCompacta;
    var btn = document.getElementById('btnVista');
    var tabla = document.getElementById('tablaPedidos').parentElement;
    if (_vistaCompacta) {
        btn.classList.add('active');
        btn.innerHTML = '<i class="ti ti-layout-grid"></i> Compacto';
        if (tabla) tabla.classList.add('tabla-compacta');
    } else {
        btn.classList.remove('active');
        btn.innerHTML = '<i class="ti ti-layout-rows"></i> Detallado';
        if (tabla) tabla.classList.remove('tabla-compacta');
    }
    cargarPedidos();
}

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

// ============================================================
// CONSTRUCCION DE QUERYSTRING
// ============================================================
function construirQuery() {
    var qs = '';
    var b = document.getElementById('txBuscar').value;
    if (b) qs += 'b=' + encodeURIComponent(b) + '&';

    // Fecha entrega
    var pillEntrega = document.querySelector('#pillsEntrega .pill-filter.active');
    if (pillEntrega) {
        var v = pillEntrega.dataset.val;
        var hoy = new Date();
        var fmt = function(d) {
            var y = d.getFullYear(), m = ('0'+(d.getMonth()+1)).slice(-2), dd = ('0'+d.getDate()).slice(-2);
            return y + '-' + m + '-' + dd;
        };
        if (v === 'hoy') {
            qs += 'hoy=1&';
        } else if (v === 'manana') {
            var m = new Date(hoy); m.setDate(m.getDate() + 1);
            qs += 'fed=' + fmt(m) + '&feh=' + fmt(m) + '&';
        } else if (v === 'semana') {
            var lunes = new Date(hoy); lunes.setDate(hoy.getDate() - ((hoy.getDay() + 6) % 7));
            var dom = new Date(lunes); dom.setDate(lunes.getDate() + 6);
            qs += 'fed=' + fmt(lunes) + '&feh=' + fmt(dom) + '&';
        } else if (v === 'prox7') {
            var fin = new Date(hoy); fin.setDate(hoy.getDate() + 7);
            qs += 'fed=' + fmt(hoy) + '&feh=' + fmt(fin) + '&';
        } else if (v === 'rango') {
            var fd = document.getElementById('txFeDesde').value;
            var fh = document.getElementById('txFeHasta').value;
            if (fd) qs += 'fed=' + fd + '&';
            if (fh) qs += 'feh=' + fh + '&';
        }
    }

    // Fecha creacion
    var pillCreacion = document.querySelector('#pillsCreacion .pill-filter.active');
    if (pillCreacion) {
        var v = pillCreacion.dataset.val;
        var hoy = new Date();
        var fmt = function(d) {
            var y = d.getFullYear(), m = ('0'+(d.getMonth()+1)).slice(-2), dd = ('0'+d.getDate()).slice(-2);
            return y + '-' + m + '-' + dd;
        };
        if (v === 'hoy') {
            qs += 'crd=' + fmt(hoy) + '&crh=' + fmt(hoy) + '&';
        } else if (v === '24h') {
            var ayer = new Date(hoy); ayer.setDate(ayer.getDate() - 1);
            qs += 'crd=' + fmt(ayer) + '&crh=' + fmt(hoy) + '&';
        } else if (v === 'semana') {
            var lunes = new Date(hoy); lunes.setDate(hoy.getDate() - ((hoy.getDay() + 6) % 7));
            qs += 'crd=' + fmt(lunes) + '&crh=' + fmt(hoy) + '&';
        } else if (v === 'rango') {
            var fd = document.getElementById('txCrDesde').value;
            var fh = document.getElementById('txCrHasta').value;
            if (fd) qs += 'crd=' + fd + '&';
            if (fh) qs += 'crh=' + fh + '&';
        }
    }

    var p = document.getElementById('ddPago').value; if (p) qs += 'p=' + p + '&';
    var op = document.getElementById('ddOperativo').value; if (op) qs += 'op=' + op + '&';
    var z = document.getElementById('ddZona').value; if (z) qs += 'z=' + z + '&';
    var deli = document.getElementById('ddDelivery').value; if (deli) qs += 'deli=' + deli + '&';

    document.querySelectorAll('.pill-filter[data-flag]').forEach(function(p) {
        if (p.classList.contains('active')) {
            qs += p.dataset.flag + '=1&';
        }
    });

    if (_vistaCompacta) qs += 'cp=1&';

    return qs;
}

// ============================================================
// CARGAR PEDIDOS VIA AJAX
// ============================================================
function cargarPedidos() {
    var tbody = document.getElementById('tbodyPedidos');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="5" class="tabla-loading"><i class="ti ti-loader"></i><br>Cargando...</td></tr>';

    var qs = construirQuery();
    var url = 'Pedidos_Handler.ashx?' + qs + '_=' + Date.now();

    fetch(url, { credentials: 'same-origin' })
        .then(function(r) {
            if (r.status === 401) {
                window.location.href = '../../Login.aspx';
                return null;
            }
            return r.text();
        })
        .then(function(html) {
            if (html === null) return;
            // Extraer total del comentario
            var totalMatch = html.match(/^<!--TOTAL:(\d+)-->/);
            var total = 0;
            if (totalMatch) {
                total = parseInt(totalMatch[1], 10);
                html = html.replace(/^<!--TOTAL:\d+-->/, '');
            }
            tbody.innerHTML = html;
            var lblM = document.getElementById('lblMostrando');
            if (lblM) lblM.textContent = total;
            var lblT = document.getElementById('lblTotal');
            if (lblT) lblT.textContent = total;
        })
        .catch(function(err) {
            tbody.innerHTML = '<tr><td colspan="5" class="table-empty"><i class="ti ti-alert-triangle"></i><br>Error: ' + err.message + '</td></tr>';
        });
}

function limpiarFiltros() {
    document.getElementById('txBuscar').value = '';
    document.querySelectorAll('#pillsEntrega .pill-filter').forEach(function(p) { p.classList.remove('active'); });
    document.querySelector('#pillsEntrega .pill-filter[data-val="hoy"]').classList.add('active');
    document.querySelectorAll('#pillsCreacion .pill-filter').forEach(function(p) { p.classList.remove('active'); });
    document.querySelector('#pillsCreacion .pill-filter[data-val="cualquiera"]').classList.add('active');
    document.getElementById('ddPago').value = '';
    document.getElementById('ddOperativo').value = '';
    document.getElementById('ddZona').value = '';
    document.getElementById('ddDelivery').value = '';
    document.querySelectorAll('.pill-filter[data-flag]').forEach(function(p) { p.classList.remove('active'); });
    document.getElementById('rangoEntrega').classList.remove('show');
    document.getElementById('rangoCreacion').classList.remove('show');
    cargarPedidos();
}

// ============================================================
// EVENTOS DE PILLS Y FILTROS
// ============================================================
function setupEventos() {
    // Pills de fecha entrega
    document.querySelectorAll('#pillsEntrega .pill-filter').forEach(function(p) {
        p.addEventListener('click', function() {
            document.querySelectorAll('#pillsEntrega .pill-filter').forEach(function(x) { x.classList.remove('active'); });
            p.classList.add('active');
            var rango = document.getElementById('rangoEntrega');
            if (p.dataset.val === 'rango') {
                rango.classList.add('show');
            } else {
                rango.classList.remove('show');
                cargarPedidos();
            }
        });
    });

    // Pills de fecha creacion
    document.querySelectorAll('#pillsCreacion .pill-filter').forEach(function(p) {
        p.addEventListener('click', function() {
            document.querySelectorAll('#pillsCreacion .pill-filter').forEach(function(x) { x.classList.remove('active'); });
            p.classList.add('active');
            var rango = document.getElementById('rangoCreacion');
            if (p.dataset.val === 'rango') {
                rango.classList.add('show');
            } else {
                rango.classList.remove('show');
                cargarPedidos();
            }
        });
    });

    // Pills de flags
    document.querySelectorAll('.pill-filter[data-flag]').forEach(function(p) {
        p.addEventListener('click', function() {
            p.classList.toggle('active');
            cargarPedidos();
        });
    });

    // Selects
    ['ddPago','ddOperativo','ddZona','ddDelivery'].forEach(function(id) {
        var el = document.getElementById(id);
        if (el) el.addEventListener('change', cargarPedidos);
    });

    // Inputs de rango
    ['txFeDesde','txFeHasta','txCrDesde','txCrHasta'].forEach(function(id) {
        var el = document.getElementById(id);
        if (el) el.addEventListener('change', cargarPedidos);
    });

    // Buscar con debounce
    var txBuscar = document.getElementById('txBuscar');
    if (txBuscar) {
        txBuscar.addEventListener('input', function() {
            if (_timerBuscar) clearTimeout(_timerBuscar);
            _timerBuscar = setTimeout(cargarPedidos, 400);
        });
    }
}

// ============================================================
// DROPDOWN ACCIONES
// ============================================================
function toggleDropdown(pid, evt) {
    if (evt) evt.stopPropagation();
    var dd = document.getElementById('dd_' + pid);
    if (!dd) return;
    var abierto = dd.classList.contains('open');
    cerrarTodosDropdowns();
    if (!abierto) dd.classList.add('open');
}

function cerrarTodosDropdowns() {
    document.querySelectorAll('.dropdown').forEach(function(d) { d.classList.remove('open'); });
}

document.addEventListener('click', function(e) {
    var t = e.target;
    if (!t.closest || !t.closest('.dropdown')) cerrarTodosDropdowns();
});

// ============================================================
// ACCIONES DEL MENU
// ============================================================
function verDetalle(pid) {
    cerrarTodosDropdowns();
    window.location.href = 'PedidoDetalle.aspx?id=' + pid;
}

function imprimirTicket(pid) {
    cerrarTodosDropdowns();
    var v = window.open('TicketImprimir.aspx?id=' + pid, 'ticket', 'width=400,height=600');
    if (v) v.focus();
}

function cambiarEstado(pid, estadoNuevo) {
    cerrarTodosDropdowns();
    document.getElementById('hdAccion').value = 'CAMBIAR_ESTADO';
    document.getElementById('hdPedidoId').value = pid;
    document.getElementById('hdEstadoNuevo').value = estadoNuevo;
    document.getElementById(_btnPostbackId).click();
}

function marcarContactado(pid) {
    cerrarTodosDropdowns();
    if (!confirm('Marcar como contactado?')) return;
    document.getElementById('hdAccion').value = 'MARCAR_CONTACTADO';
    document.getElementById('hdPedidoId').value = pid;
    document.getElementById(_btnPostbackId).click();
}

function asignarDelivery(pid) {
    cerrarTodosDropdowns();
    alert('Asignar delivery - en proxima entrega');
}

function editarPedido(pid) {
    cerrarTodosDropdowns();
    alert('Editar pedido - en proxima entrega');
}

function cancelarPedido(pid) {
    cerrarTodosDropdowns();
    if (!confirm('CANCELAR este pedido? Esta accion no se puede deshacer.')) return;
    document.getElementById('hdAccion').value = 'CANCELAR_PEDIDO';
    document.getElementById('hdPedidoId').value = pid;
    document.getElementById(_btnPostbackId).click();
}

function abrirWhatsApp(cel) {
    cerrarTodosDropdowns();
    window.open('https://wa.me/' + cel, '_blank');
}

function llamarCliente(cel) {
    cerrarTodosDropdowns();
    window.location.href = 'tel:+' + cel;
}

function abrirMaps(dir) {
    cerrarTodosDropdowns();
    window.open('https://maps.google.com/?q=' + encodeURIComponent(dir), '_blank');
}

function copiarParaWhatsApp(pid) {
    cerrarTodosDropdowns();
    fetch('Pedidos_Handler.ashx?action=copy&id=' + pid)
        .catch(function(){});
    var btn = event.target.closest('.dropdown-item');
    var fila = btn.closest('tr');
    var receptor = fila.querySelector('td:nth-child(2) div:nth-child(2)').textContent.trim();
    var texto = 'Hola, soy Miss Flores. Tu pedido esta en camino. Te contactamos pronto.';
    navigator.clipboard.writeText(texto).then(function() {
        alert('Texto copiado al portapapeles');
    }).catch(function() {
        prompt('Copia este texto:', texto);
    });
}

// ============================================================
// MODAL ACEPTAR PAGO WC
// ============================================================
function abrirModalAceptar(pid, cliente, monto) {
    _pedidoAceptarId = pid;
    var msg = document.getElementById('modalAceptarMsg');
    if (msg) msg.innerHTML = 'Vas a aceptar el pago del pedido <strong>' + cliente + '</strong> por <strong>Bs ' + monto + '</strong>.<br><br>Asegurate de haber verificado el pago en tu banco.';
    document.getElementById('modalAceptar').classList.remove('hidden');
}

function cerrarModalAceptar() {
    document.getElementById('modalAceptar').classList.add('hidden');
    _pedidoAceptarId = 0;
}

function confirmarAceptarPago() {
    if (_pedidoAceptarId <= 0) return;
    document.getElementById('hdAccion').value = 'ACEPTAR_PAGO';
    document.getElementById('hdPedidoId').value = _pedidoAceptarId;
    cerrarModalAceptar();
    document.getElementById(_btnPostbackId).click();
}

// ============================================================
// INIT
// ============================================================
(function() {
    setupEventos();
    cargarPedidos();

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
