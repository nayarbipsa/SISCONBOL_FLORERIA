<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="GestionPedidos.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_GestionPedidos" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Gestion de Pedidos
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-clipboard-list" style="vertical-align:-2px"></i> Gestion de Pedidos
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

<div class="alerta" id="divAlerta"></div>

<!-- FILTRO DE SUCURSAL -->
<div class="panel suc-filter-panel">
    <div class="suc-filter-label"><i class="ti ti-building-store"></i> Sucursal que prepara</div>
    <div class="suc-filter-pills" id="sucPills">
        <label class="suc-pill active" data-sp="">
            <input type="radio" name="sucPrepara" value="" checked/>
            Todas <span class="suc-count">(<%= TotalGeneralSucursal %>)</span>
        </label>
        <%= SucursalRadios %>
        <label class="suc-pill" data-sp="-1">
            <input type="radio" name="sucPrepara" value="-1"/>
            Sin establecer <span class="suc-count">(<%= TotalSinSucursal %>)</span>
        </label>
    </div>
</div>

<!-- TABS -->
<div class="tabs-container">
    <div class="tab-item active" data-tab="todos" onclick="cambiarTab('todos')">
        <i class="ti ti-list"></i>
        <span>Todos los pedidos</span>
        <span class="tab-badge" id="badgeTodos">0</span>
    </div>
    <div class="tab-item" data-tab="wc_pendiente" onclick="cambiarTab('wc_pendiente')">
        <i class="ti ti-cash-banknote"></i>
        <span>Verificar pago WC</span>
        <span class="tab-badge tab-badge-warn" id="badgeWC">0</span>
    </div>
</div>

<!-- PANEL TAB TODOS -->
<div class="tab-panel" id="panelTodos">

    <div class="panel">
        <div class="panel-head">
            <div class="panel-title">Pedidos del periodo</div>
            <div class="panel-actions">
                <button type="button" class="btn-toggle-vista" id="btnVista" onclick="toggleVistaCompacta()">
                    <i class="ti ti-layout-rows"></i> Detallado
                </button>
                <button type="button" class="btn btn-sm" onclick="cargarPedidos()">
                    <i class="ti ti-refresh"></i> Refrescar
                </button>
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
                    <input type="text" id="txBuscar" class="form-control" placeholder="Codigo PED/WC, cliente, receptor, celular, direccion..."/>
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

            <div class="filter-fecha-bloque">
                <div class="filter-fecha-titulo estado"><i class="ti ti-flag"></i> Estado de entrega</div>
                <div style="display:flex;flex-wrap:wrap;gap:5px" id="pillsEstado">
                    <span class="pill-filter active" data-val="">Todos</span>
                    <span class="pill-filter" data-val="en_curso">En curso</span>
                    <span class="pill-filter" data-val="en_ruta">En ruta</span>
                    <span class="pill-filter" data-val="entregados">Entregados</span>
                    <span class="pill-filter" data-val="problemas">Problemas</span>
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
            <span class="auto-msg"><i class="ti ti-info-circle"></i> Click en una fila para ver el detalle completo</span>
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
                        <th style="width:220px;text-align:right">Acciones</th>
                    </tr>
                </thead>
                <tbody id="tbodyPedidos">
                    <tr><td colspan="5" class="tabla-loading"><i class="ti ti-loader"></i><br>Cargando...</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- PANEL TAB VERIFICAR WC -->
<div class="tab-panel" id="panelWC" style="display:none">

    <div class="aviso-wc">
        <i class="ti ti-info-circle"></i>
        <div>
            <div class="aviso-wc-t1">Estos pedidos llegaron de WooCommerce con pago manual (QR, transferencia, COD).</div>
            <div class="aviso-wc-t2">Verifica el ingreso en tu banco antes de aceptar. WooCommerce nunca los confirmara automaticamente.</div>
        </div>
    </div>

    <div class="panel">
        <div class="panel-head">
            <div class="panel-title">Pedidos pendientes de verificacion</div>
            <div class="panel-actions">
                <button type="button" class="btn btn-sm" onclick="cargarPedidos()">
                    <i class="ti ti-refresh"></i> Refrescar
                </button>
            </div>
        </div>

        <div style="padding:14px 16px;background:#fafafa;border-bottom:1px solid #e0e0e0">
            <div class="filter-group" style="margin-bottom:10px">
                <label>Buscar</label>
                <div class="search-wrap">
                    <i class="ti ti-search"></i>
                    <input type="text" id="txBuscarWC" class="form-control" placeholder="WC #, cliente, receptor, celular..."/>
                </div>
            </div>

            <div class="filter-fecha-bloque" style="margin-bottom:0">
                <div class="filter-fecha-titulo entrega"><i class="ti ti-truck-delivery"></i> Fecha de entrega</div>
                <div style="display:flex;flex-wrap:wrap;gap:5px" id="pillsEntregaWC">
                    <span class="pill-filter active" data-tipo="entrega" data-val="todas">Todas</span>
                    <span class="pill-filter" data-tipo="entrega" data-val="hoy">Hoy</span>
                    <span class="pill-filter" data-tipo="entrega" data-val="manana">Manana</span>
                    <span class="pill-filter" data-tipo="entrega" data-val="semana">Esta semana</span>
                </div>
            </div>
        </div>

        <div class="filtros-footer">
            <span class="auto-msg"><i class="ti ti-info-circle"></i> Boton verde acepta el pago manual</span>
            <span>Mostrando <span id="lblMostrandoWC">0</span> pedidos</span>
        </div>

        <div class="table-container">
            <table class="table tabla-wc" id="tablaPedidosWC">
                <thead>
                    <tr>
                        <th style="width:70px">WC #</th>
                        <th>Cliente / Receptor</th>
                        <th style="width:160px">Metodo pago</th>
                        <th style="width:90px">Entrega</th>
                        <th style="width:90px;text-align:right">Monto</th>
                        <th style="width:170px;text-align:right">Acciones</th>
                    </tr>
                </thead>
                <tbody id="tbodyPedidosWC">
                    <tr><td colspan="6" class="tabla-loading"><i class="ti ti-loader"></i><br>Cargando...</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Hidden fields -->
<input type="hidden" id="hdAccion" name="hdAccion" value=""/>
<input type="hidden" id="hdPedidoId" name="hdPedidoId" value=""/>
<input type="hidden" id="hdEstadoNuevo" name="hdEstadoNuevo" value=""/>
<input type="hidden" id="hdTabActivo" name="hdTabActivo" value="todos"/>
<asp:Button ID="btnPostBack" runat="server" Text="" Style="display:none" OnClick="btnAccion_Click"/>

<!-- MODAL ACEPTAR PAGO -->
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

<!-- MODAL ASIGNAR DELIVERY -->
<div class="modal-overlay hidden" id="modalAsignar">
    <div class="modal-asignar">
        <div class="modal-asignar-header">
            <div>
                <div class="modal-asignar-titulo">Asignar delivery</div>
                <div class="modal-asignar-subtitulo" id="mAsignContexto">-</div>
            </div>
            <button type="button" class="btn-icon-only" onclick="cerrarModalAsignar()" title="Cerrar"><i class="ti ti-x"></i></button>
        </div>

        <div class="modal-asignar-buscar">
            <i class="ti ti-search"></i>
            <input type="text" id="mAsignBuscar" placeholder="Buscar por nombre..."/>
        </div>

        <div class="modal-asignar-lista" id="mAsignLista">
            <div class="md-loading"><i class="ti ti-loader"></i><br>Cargando deliverys...</div>
        </div>

        <div class="modal-asignar-aviso hidden" id="mAsignAviso">
            <i class="ti ti-alert-triangle"></i>
            <span id="mAsignAvisoMsg"></span>
        </div>

        <div class="modal-asignar-footer">
            <button type="button" class="btn" onclick="cerrarModalAsignar()">Cancelar</button>
            <button type="button" class="btn btn-primary" id="mAsignBtnConfirmar" onclick="confirmarAsignacion()" disabled>
                <i class="ti ti-motorbike"></i> Asignar
            </button>
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
var _timerBuscarWC = null;
var _btnPostbackId = '<%= btnPostBack.ClientID %>';
var _tabActiva = 'todos';
var _sucPreparaSel = '';

// ============================================================
// TABS
// ============================================================
function cambiarTab(tab) {
    if (tab === _tabActiva) return;
    _tabActiva = tab;
    document.getElementById('hdTabActivo').value = tab;

    var tabs = document.querySelectorAll('.tab-item');
    for (var i = 0; i < tabs.length; i++) {
        if (tabs[i].dataset.tab === tab) {
            tabs[i].classList.add('active');
        } else {
            tabs[i].classList.remove('active');
        }
    }

    document.getElementById('panelTodos').style.display = (tab === 'todos') ? '' : 'none';
    document.getElementById('panelWC').style.display = (tab === 'wc_pendiente') ? '' : 'none';

    cargarPedidos();
}

// ============================================================
// FILTRO SUCURSAL
// ============================================================
function setupSucursales() {
    var inputs = document.querySelectorAll('input[name="sucPrepara"]');
    for (var i = 0; i < inputs.length; i++) {
        inputs[i].addEventListener('change', function() {
            _sucPreparaSel = this.value;
            var labels = document.querySelectorAll('.suc-pill');
            for (var j = 0; j < labels.length; j++) {
                labels[j].classList.remove('active');
            }
            this.closest('.suc-pill').classList.add('active');
            cargarPedidos();
        });
    }
}

// ============================================================
// QUERYSTRING
// ============================================================
function construirQuery() {
    var qs = 'tab=' + _tabActiva + '&';

    if (_sucPreparaSel !== '') {
        qs += 'sp=' + encodeURIComponent(_sucPreparaSel) + '&';
    }

    if (_tabActiva === 'todos') {
        var b = document.getElementById('txBuscar').value;
        if (b) qs += 'b=' + encodeURIComponent(b) + '&';

        var pillEntrega = document.querySelector('#pillsEntrega .pill-filter.active');
        if (pillEntrega) {
            qs += construirFiltroFecha(pillEntrega.dataset.val, 'fed', 'feh', 'txFeDesde', 'txFeHasta');
        }

        var pillCreacion = document.querySelector('#pillsCreacion .pill-filter.active');
        if (pillCreacion) {
            qs += construirFiltroFechaCreacion(pillCreacion.dataset.val);
        }

        // Grupo de estados operativos
        var pillEstado = document.querySelector('#pillsEstado .pill-filter.active');
        if (pillEstado && pillEstado.dataset.val) {
            qs += 'es=' + encodeURIComponent(pillEstado.dataset.val) + '&';
        }

        var p = document.getElementById('ddPago').value; if (p) qs += 'p=' + p + '&';
        var op = document.getElementById('ddOperativo').value; if (op) qs += 'op=' + op + '&';
        var z = document.getElementById('ddZona').value; if (z) qs += 'z=' + z + '&';
        var deli = document.getElementById('ddDelivery').value; if (deli) qs += 'deli=' + deli + '&';

        var flags = document.querySelectorAll('#panelTodos .pill-filter[data-flag]');
        for (var i = 0; i < flags.length; i++) {
            if (flags[i].classList.contains('active')) {
                qs += flags[i].dataset.flag + '=1&';
            }
        }

        if (_vistaCompacta) qs += 'cp=1&';
    } else {
        var bWC = document.getElementById('txBuscarWC').value;
        if (bWC) qs += 'b=' + encodeURIComponent(bWC) + '&';

        var pillEntregaWC = document.querySelector('#pillsEntregaWC .pill-filter.active');
        if (pillEntregaWC && pillEntregaWC.dataset.val !== 'todas') {
            qs += construirFiltroFecha(pillEntregaWC.dataset.val, 'fed', 'feh', '', '');
        }
    }

    return qs;
}

function construirFiltroFecha(val, paramD, paramH, idDesde, idHasta) {
    var qs = '';
    var hoy = new Date();
    var fmt = function(d) {
        return d.getFullYear() + '-' + ('0'+(d.getMonth()+1)).slice(-2) + '-' + ('0'+d.getDate()).slice(-2);
    };
    if (val === 'hoy') {
        qs += 'hoy=1&';
    } else if (val === 'manana') {
        var m = new Date(hoy); m.setDate(m.getDate() + 1);
        qs += paramD + '=' + fmt(m) + '&' + paramH + '=' + fmt(m) + '&';
    } else if (val === 'semana') {
        var lunes = new Date(hoy); lunes.setDate(hoy.getDate() - ((hoy.getDay() + 6) % 7));
        var dom = new Date(lunes); dom.setDate(lunes.getDate() + 6);
        qs += paramD + '=' + fmt(lunes) + '&' + paramH + '=' + fmt(dom) + '&';
    } else if (val === 'prox7') {
        var fin = new Date(hoy); fin.setDate(hoy.getDate() + 7);
        qs += paramD + '=' + fmt(hoy) + '&' + paramH + '=' + fmt(fin) + '&';
    } else if (val === 'rango' && idDesde && idHasta) {
        var fd = document.getElementById(idDesde).value;
        var fh = document.getElementById(idHasta).value;
        if (fd) qs += paramD + '=' + fd + '&';
        if (fh) qs += paramH + '=' + fh + '&';
    }
    return qs;
}

function construirFiltroFechaCreacion(val) {
    var qs = '';
    var hoy = new Date();
    var fmt = function(d) {
        return d.getFullYear() + '-' + ('0'+(d.getMonth()+1)).slice(-2) + '-' + ('0'+d.getDate()).slice(-2);
    };
    if (val === 'hoy') {
        qs += 'crd=' + fmt(hoy) + '&crh=' + fmt(hoy) + '&';
    } else if (val === '24h') {
        var ayer = new Date(hoy); ayer.setDate(ayer.getDate() - 1);
        qs += 'crd=' + fmt(ayer) + '&crh=' + fmt(hoy) + '&';
    } else if (val === 'semana') {
        var lunes = new Date(hoy); lunes.setDate(hoy.getDate() - ((hoy.getDay() + 6) % 7));
        qs += 'crd=' + fmt(lunes) + '&crh=' + fmt(hoy) + '&';
    } else if (val === 'rango') {
        var fd = document.getElementById('txCrDesde').value;
        var fh = document.getElementById('txCrHasta').value;
        if (fd) qs += 'crd=' + fd + '&';
        if (fh) qs += 'crh=' + fh + '&';
    }
    return qs;
}

// ============================================================
// CARGAR PEDIDOS
// ============================================================
function cargarPedidos() {
    var esWC = (_tabActiva === 'wc_pendiente');
    var tbody = document.getElementById(esWC ? 'tbodyPedidosWC' : 'tbodyPedidos');
    var lblM = document.getElementById(esWC ? 'lblMostrandoWC' : 'lblMostrando');
    var badge = document.getElementById(esWC ? 'badgeWC' : 'badgeTodos');
    var colspan = esWC ? 6 : 5;

    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="' + colspan + '" class="tabla-loading"><i class="ti ti-loader"></i><br>Cargando...</td></tr>';

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
            var totalMatch = html.match(/^<!--TOTAL:(\d+)-->/);
            var total = 0;
            if (totalMatch) {
                total = parseInt(totalMatch[1], 10);
                html = html.replace(/^<!--TOTAL:\d+-->/, '');
            }
            tbody.innerHTML = html;
            if (lblM) lblM.textContent = total;
            if (badge) badge.textContent = total;

            if (!esWC) {
                actualizarContadorWC();
            }
        })
        .catch(function(err) {
            tbody.innerHTML = '<tr><td colspan="' + colspan + '" class="table-empty"><i class="ti ti-alert-triangle"></i><br>Error: ' + err.message + '</td></tr>';
        });
}

function actualizarContadorWC() {
    var qs = 'tab=wc_pendiente';
    if (_sucPreparaSel !== '') qs += '&sp=' + encodeURIComponent(_sucPreparaSel);
    qs += '&_=' + Date.now();

    fetch('Pedidos_Handler.ashx?' + qs, { credentials: 'same-origin' })
        .then(function(r) { return r.text(); })
        .then(function(html) {
            var m = html.match(/^<!--TOTAL:(\d+)-->/);
            if (m) {
                var n = parseInt(m[1], 10);
                document.getElementById('badgeWC').textContent = n;
            }
        })
        .catch(function() {});
}

function limpiarFiltros() {
    document.getElementById('txBuscar').value = '';
    var pills = document.querySelectorAll('#pillsEntrega .pill-filter');
    for (var i = 0; i < pills.length; i++) pills[i].classList.remove('active');
    document.querySelector('#pillsEntrega .pill-filter[data-val="hoy"]').classList.add('active');
    var pillsC = document.querySelectorAll('#pillsCreacion .pill-filter');
    for (var i = 0; i < pillsC.length; i++) pillsC[i].classList.remove('active');
    document.querySelector('#pillsCreacion .pill-filter[data-val="cualquiera"]').classList.add('active');
    // Reset pills estado
    var pillsE = document.querySelectorAll('#pillsEstado .pill-filter');
    for (var i = 0; i < pillsE.length; i++) pillsE[i].classList.remove('active');
    document.querySelector('#pillsEstado .pill-filter[data-val=""]').classList.add('active');
    document.getElementById('ddPago').value = '';
    document.getElementById('ddOperativo').value = '';
    document.getElementById('ddZona').value = '';
    document.getElementById('ddDelivery').value = '';
    var flags = document.querySelectorAll('#panelTodos .pill-filter[data-flag]');
    for (var i = 0; i < flags.length; i++) flags[i].classList.remove('active');
    document.getElementById('rangoEntrega').classList.remove('show');
    document.getElementById('rangoCreacion').classList.remove('show');
    cargarPedidos();
}

// ============================================================
// EVENTOS DE FILTROS
// ============================================================
function setupEventos() {
    var pe = document.querySelectorAll('#pillsEntrega .pill-filter');
    for (var i = 0; i < pe.length; i++) {
        pe[i].addEventListener('click', function() {
            var all = document.querySelectorAll('#pillsEntrega .pill-filter');
            for (var j = 0; j < all.length; j++) all[j].classList.remove('active');
            this.classList.add('active');
            var rango = document.getElementById('rangoEntrega');
            if (this.dataset.val === 'rango') {
                rango.classList.add('show');
            } else {
                rango.classList.remove('show');
                cargarPedidos();
            }
        });
    }

    var pc = document.querySelectorAll('#pillsCreacion .pill-filter');
    for (var i = 0; i < pc.length; i++) {
        pc[i].addEventListener('click', function() {
            var all = document.querySelectorAll('#pillsCreacion .pill-filter');
            for (var j = 0; j < all.length; j++) all[j].classList.remove('active');
            this.classList.add('active');
            var rango = document.getElementById('rangoCreacion');
            if (this.dataset.val === 'rango') {
                rango.classList.add('show');
            } else {
                rango.classList.remove('show');
                cargarPedidos();
            }
        });
    }

    // Pills grupo de estados
    var pes = document.querySelectorAll('#pillsEstado .pill-filter');
    for (var i = 0; i < pes.length; i++) {
        pes[i].addEventListener('click', function() {
            var all = document.querySelectorAll('#pillsEstado .pill-filter');
            for (var j = 0; j < all.length; j++) all[j].classList.remove('active');
            this.classList.add('active');
            cargarPedidos();
        });
    }

    var flags = document.querySelectorAll('#panelTodos .pill-filter[data-flag]');
    for (var i = 0; i < flags.length; i++) {
        flags[i].addEventListener('click', function() {
            this.classList.toggle('active');
            cargarPedidos();
        });
    }

    var peWC = document.querySelectorAll('#pillsEntregaWC .pill-filter');
    for (var i = 0; i < peWC.length; i++) {
        peWC[i].addEventListener('click', function() {
            var all = document.querySelectorAll('#pillsEntregaWC .pill-filter');
            for (var j = 0; j < all.length; j++) all[j].classList.remove('active');
            this.classList.add('active');
            cargarPedidos();
        });
    }

    var selects = ['ddPago', 'ddOperativo', 'ddZona', 'ddDelivery'];
    for (var i = 0; i < selects.length; i++) {
        var el = document.getElementById(selects[i]);
        if (el) el.addEventListener('change', cargarPedidos);
    }

    var rangos = ['txFeDesde', 'txFeHasta', 'txCrDesde', 'txCrHasta'];
    for (var i = 0; i < rangos.length; i++) {
        var el = document.getElementById(rangos[i]);
        if (el) el.addEventListener('change', cargarPedidos);
    }

    var tx = document.getElementById('txBuscar');
    if (tx) {
        tx.addEventListener('input', function() {
            if (_timerBuscar) clearTimeout(_timerBuscar);
            _timerBuscar = setTimeout(cargarPedidos, 400);
        });
    }

    var txWC = document.getElementById('txBuscarWC');
    if (txWC) {
        txWC.addEventListener('input', function() {
            if (_timerBuscarWC) clearTimeout(_timerBuscarWC);
            _timerBuscarWC = setTimeout(cargarPedidos, 400);
        });
    }
}

// ============================================================
// VISTA COMPACTA / DETALLADA
// ============================================================
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

// ============================================================
// VER DETALLE (sin modal, va directo a Pedido_Detalle.aspx)
// ============================================================
function abrirDetalleModal(pid) {
    if (!pid) return;
    window.location.href = 'Pedido_Detalle.aspx?id=' + pid;
}

// Cerrar dropdowns/modal con ESC
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        cerrarModalAceptar();
        cerrarModalAsignar();
        cerrarTodosDropdowns();
    }
});

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
    var dds = document.querySelectorAll('.dropdown');
    for (var i = 0; i < dds.length; i++) dds[i].classList.remove('open');
}

document.addEventListener('click', function(e) {
    var t = e.target;
    if (!t.closest || !t.closest('.dropdown')) cerrarTodosDropdowns();
});

// ============================================================
// ACCIONES PEDIDO
// ============================================================
function imprimirTicket(pid) {
    cerrarTodosDropdowns();
    var v = window.open('Recibo.aspx?id=' + pid, 'recibo', 'width=400,height=600');
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

// ============================================================
// MODAL ASIGNAR DELIVERY
// ============================================================
var _asignPedidoId = 0;
var _asignDeliverySel = 0;
var _asignDeliveryNombre = '';
var _asignDeliverys = [];

function asignarDelivery(pid) {
    cerrarTodosDropdowns();
    if (!pid) return;
    _asignPedidoId = pid;
    _asignDeliverySel = 0;
    _asignDeliveryNombre = '';

    // Mostrar contexto: codigo + receptor + zona desde la fila
    var fila = document.querySelector('tr[data-pid="' + pid + '"]');
    var contexto = 'Pedido #' + pid;
    var deliveryActualNombre = '';
    if (fila) {
        var pedEl = fila.querySelector('.ped-main, .ped-small');
        var recEl = fila.querySelectorAll('td')[1];
        var zEl = fila.querySelector('.zona-deli .z');
        var partes = [];
        if (pedEl) partes.push(pedEl.textContent.trim());
        if (recEl) {
            var divs = recEl.querySelectorAll('div');
            for (var i = 0; i < divs.length; i++) {
                var t = divs[i].textContent.trim();
                if (t && t.length < 60 && !t.startsWith('Compr')) {
                    partes.push(t);
                    break;
                }
            }
        }
        if (zEl) partes.push(zEl.textContent.trim());
        contexto = partes.join(' · ');

        // Detectar si ya tiene delivery asignado
        var deliEl = fila.querySelector('.deli-asignado');
        if (deliEl) {
            deliveryActualNombre = deliEl.textContent.trim();
        }
    }

    document.getElementById('mAsignContexto').textContent = contexto;
    document.getElementById('mAsignBtnConfirmar').disabled = true;
    document.getElementById('mAsignBtnConfirmar').innerHTML = '<i class="ti ti-motorbike"></i> Asignar';
    document.getElementById('mAsignBuscar').value = '';

    // Aviso si ya tiene delivery
    var aviso = document.getElementById('mAsignAviso');
    var avisoMsg = document.getElementById('mAsignAvisoMsg');
    if (deliveryActualNombre) {
        aviso.classList.remove('hidden');
        avisoMsg.textContent = 'Este pedido ya tiene delivery (' + deliveryActualNombre + '). Asignar a otro lo reasignara.';
    } else {
        aviso.classList.add('hidden');
    }

    document.getElementById('modalAsignar').classList.remove('hidden');

    // Cargar deliverys
    document.getElementById('mAsignLista').innerHTML = '<div class="md-loading"><i class="ti ti-loader"></i><br>Cargando deliverys...</div>';
    fetch('Pedidos_Handler.ashx?action=deliverys&_=' + Date.now(), { credentials: 'same-origin' })
        .then(function(r) {
            if (r.status === 401) {
                window.location.href = '../../Login.aspx';
                return null;
            }
            return r.json();
        })
        .then(function(data) {
            if (data === null) return;
            _asignDeliverys = data;
            pintarListaDeliverys('');
        })
        .catch(function(err) {
            document.getElementById('mAsignLista').innerHTML = '<div class="md-loading"><i class="ti ti-alert-triangle"></i><br>Error: ' + err.message + '</div>';
        });
}

function pintarListaDeliverys(filtro) {
    var lista = document.getElementById('mAsignLista');
    if (!_asignDeliverys || _asignDeliverys.length === 0) {
        lista.innerHTML = '<div class="md-loading"><i class="ti ti-user-off"></i><br>No hay usuarios disponibles.</div>';
        return;
    }

    filtro = (filtro || '').toLowerCase().trim();
    var html = '';
    var ultimoOrden = -1;
    var seccionTitulos = { 1: 'Deliverys', 2: 'Vendedores', 3: 'Gerentes', 4: 'Administradores' };
    var encontrados = 0;

    for (var i = 0; i < _asignDeliverys.length; i++) {
        var d = _asignDeliverys[i];

        // Aplicar filtro
        if (filtro && d.nombre.toLowerCase().indexOf(filtro) === -1) {
            continue;
        }
        encontrados++;

        // Header de seccion
        if (d.orden !== ultimoOrden) {
            var titulo = seccionTitulos[d.orden] || 'Otros';
            html += '<div class="asign-seccion">' + titulo + '</div>';
            ultimoOrden = d.orden;
        }

        // Iniciales
        var iniciales = obtenerInicialesJs(d.nombre);
        var colorAvatar = colorPorTipo(d.tipo_id);

        // Badge carga
        var badgeCarga = '';
        if (d.pedidos_hoy === 0) {
            badgeCarga = '<span class="asign-carga asign-libre">libre</span>';
        } else if (d.pedidos_hoy >= 7) {
            badgeCarga = '<span class="asign-carga asign-cargado">' + d.pedidos_hoy + ' hoy</span>';
        } else {
            badgeCarga = '<span class="asign-carga">' + d.pedidos_hoy + ' hoy</span>';
        }

        // Badge tipo
        var badgeTipo = '<span class="asign-tipo asign-tipo-' + d.tipo_id + '">' + d.tipo_corto + '</span>';

        var seleccionado = (d.id === _asignDeliverySel) ? ' selected' : '';
        html += '<div class="asign-item' + seleccionado + '" data-uid="' + d.id + '" data-nombre="' + escapeHtmlJs(d.nombre) + '" onclick="seleccionarDelivery(' + d.id + ')">';
        html += '<div class="asign-avatar" style="background:' + colorAvatar + '">' + iniciales + '</div>';
        html += '<div class="asign-info">';
        html += '<div class="asign-nombre">' + escapeHtmlJs(d.nombre) + ' ' + badgeTipo + '</div>';
        if (d.celular) html += '<div class="asign-cel">' + escapeHtmlJs(d.celular) + '</div>';
        html += '</div>';
        html += badgeCarga;
        html += '</div>';
    }

    if (encontrados === 0) {
        html = '<div class="md-loading"><i class="ti ti-search-off"></i><br>No hay resultados.</div>';
    }

    lista.innerHTML = html;
}

function seleccionarDelivery(uid) {
    _asignDeliverySel = uid;
    // Encontrar nombre
    for (var i = 0; i < _asignDeliverys.length; i++) {
        if (_asignDeliverys[i].id === uid) {
            _asignDeliveryNombre = _asignDeliverys[i].nombre;
            break;
        }
    }
    // Repintar para marcar el seleccionado
    pintarListaDeliverys(document.getElementById('mAsignBuscar').value);
    // Habilitar boton y actualizar texto
    var btn = document.getElementById('mAsignBtnConfirmar');
    btn.disabled = false;
    btn.innerHTML = '<i class="ti ti-motorbike"></i> Asignar a ' + escapeHtmlJs(_asignDeliveryNombre);
}

function cerrarModalAsignar() {
    document.getElementById('modalAsignar').classList.add('hidden');
    _asignPedidoId = 0;
    _asignDeliverySel = 0;
    _asignDeliveryNombre = '';
    _asignDeliverys = [];
}

function confirmarAsignacion() {
    if (_asignPedidoId <= 0 || _asignDeliverySel <= 0) return;
    document.getElementById('hdAccion').value = 'ASIGNAR_DELIVERY';
    document.getElementById('hdPedidoId').value = _asignPedidoId;
    document.getElementById('hdEstadoNuevo').value = _asignDeliverySel; // reusamos este campo
    cerrarModalAsignar();
    document.getElementById(_btnPostbackId).click();
}

// Helpers JS
function obtenerInicialesJs(nombre) {
    if (!nombre) return '??';
    var partes = nombre.trim().split(/\s+/);
    if (partes.length === 1) return (partes[0].substring(0, 2)).toUpperCase();
    return (partes[0].charAt(0) + partes[1].charAt(0)).toUpperCase();
}

function colorPorTipo(tipoId) {
    switch (tipoId) {
        case 1: return '#757575';  // Admin gris
        case 2: return '#9C27B0';  // Gerente morado
        case 3: return '#03A9F4';  // Vendedor celeste
        case 4: return '#FF9800';  // Delivery naranja
        default: return '#666';
    }
}

function escapeHtmlJs(s) {
    if (!s) return '';
    var div = document.createElement('div');
    div.textContent = s;
    return div.innerHTML;
}

// Setup buscador del modal
document.addEventListener('DOMContentLoaded', function() {
    var inp = document.getElementById('mAsignBuscar');
    if (inp) {
        inp.addEventListener('input', function() {
            pintarListaDeliverys(this.value);
        });
    }
});

function editarPedido(pid) {
    cerrarTodosDropdowns();
    window.location.href = 'Pedido_Detalle.aspx?id=' + pid;
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

function verEnWooCommerce(pid) {
    cerrarTodosDropdowns();
    var fila = document.querySelector('tr[data-pid="' + pid + '"]');
    if (fila) {
        var wcEl = fila.querySelector('.wc-big');
        if (wcEl) {
            var wcNum = wcEl.textContent.replace('#', '').trim();
            window.open('https://miss-flores.com/wp-admin/post.php?post=' + wcNum + '&action=edit', '_blank');
        }
    }
}

function copiarParaWhatsApp(pid) {
    cerrarTodosDropdowns();
    fetch('Pedidos_Handler.ashx?action=copy&id=' + pid).catch(function(){});
    var texto = 'Hola, soy Miss Flores. Tu pedido esta en camino. Te contactamos pronto.';
    if (navigator.clipboard) {
        navigator.clipboard.writeText(texto).then(function() {
            alert('Texto copiado al portapapeles');
        }).catch(function() {
            prompt('Copia este texto:', texto);
        });
    } else {
        prompt('Copia este texto:', texto);
    }
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
    setupSucursales();
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
