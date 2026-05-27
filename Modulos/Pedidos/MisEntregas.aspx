<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="MisEntregas.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_MisEntregas" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Mis Entregas
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-truck-delivery" style="vertical-align:-2px"></i> Mis Entregas
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

<div class="alerta" id="divAlerta"></div>

<%-- CABECERA DEL AGENTE --%>
<div class="panel" style="margin-bottom:14px">
    <div class="me-header">
        <div class="me-info">
            <div class="me-avatar"><i class="ti ti-user-circle"></i></div>
            <div class="me-datos">
                <div class="me-nombre"><%= NombreAgente %></div>
                <div class="me-rol">Mis pedidos asignados</div>
            </div>
        </div>
        <div class="me-stats">
            <div class="me-stat">
                <div class="me-stat-val" id="statTotal">–</div>
                <div class="me-stat-lbl">Total</div>
            </div>
            <div class="me-stat me-stat-warn">
                <div class="me-stat-val" id="statHoy">–</div>
                <div class="me-stat-lbl">Hoy</div>
            </div>
            <div class="me-stat me-stat-ok">
                <div class="me-stat-val" id="statEntregados">–</div>
                <div class="me-stat-lbl">Entregados</div>
            </div>
            <div class="me-stat me-stat-err">
                <div class="me-stat-val" id="statNoEntregados">–</div>
                <div class="me-stat-lbl">No entregados</div>
            </div>
        </div>
    </div>
</div>

<%-- FILTROS --%>
<div class="panel" style="margin-bottom:14px">
    <div class="panel-head">
        <div class="panel-title">
            <i class="ti ti-filter"></i> Filtros
        </div>
        <div class="panel-actions">
            <button type="button" class="btn btn-sm" onclick="cargarEntregas()">
                <i class="ti ti-refresh"></i> Refrescar
            </button>
            <button type="button" class="btn btn-sm" onclick="limpiarFiltros()">
                <i class="ti ti-x"></i> Limpiar
            </button>
        </div>
    </div>
    <div style="padding:12px 16px">
        <div class="filter-fecha-bloque">
            <div class="filter-fecha-titulo entrega">
                <i class="ti ti-calendar"></i> Fecha de entrega
            </div>
            <div style="display:flex;flex-wrap:wrap;gap:5px" id="pillsFecha">
                <span class="pill-filter active" data-val="hoy">Hoy</span>
                <span class="pill-filter" data-val="manana">Manana</span>
                <span class="pill-filter" data-val="semana">Esta semana</span>
                <span class="pill-filter" data-val="todas">Todas</span>
            </div>
        </div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:10px">
            <div class="search-wrap">
                <i class="ti ti-search"></i>
                <input type="text" id="txBuscar" class="form-control"
                       placeholder="Codigo, receptor, celular, direccion..."/>
            </div>
            <select id="ddEstado" class="form-control" style="font-size:11px;height:32px;padding:5px 8px">
                <option value="">Estado: Todos</option>
                <option value="PENDIENTE">Pendiente</option>
                <option value="EN_RUTA">En ruta</option>
                <option value="ENTREGADO">Entregado</option>
                <option value="NO_ENTREGADO">No entregado</option>
            </select>
        </div>
    </div>
    <div class="filtros-footer">
        <span class="auto-msg"><i class="ti ti-info-circle"></i> Click en fila para ver detalle completo</span>
        <span>Mostrando <span id="lblMostrando">0</span> entregas</span>
    </div>
</div>

<%-- TABLA --%>
<div class="panel">
    <div class="table-container">
        <table class="table" id="tablaEntregas">
            <thead>
                <tr>
                    <th style="width:88px"><i class="ti ti-clock"></i> Slot</th>
                    <th>Receptor · Quien envía · Productos</th>
                    <th style="width:130px">Zona</th>
                    <th style="width:110px">Estado</th>
                    <th style="width:130px;text-align:right">Acción</th>
                </tr>
            </thead>
            <tbody id="tbodyEntregas">
                <tr><td colspan="5" class="tabla-loading">
                    <i class="ti ti-loader"></i><br>Cargando...
                </td></tr>
            </tbody>
        </table>
    </div>
</div>

<%-- Hidden fields + postback --%>
<input type="hidden" id="hdAccion"     name="hdAccion"     value=""/>
<input type="hidden" id="hdPedidoId"   name="hdPedidoId"   value=""/>
<input type="hidden" id="hdEstadoNuevo" name="hdEstadoNuevo" value=""/>
<asp:Button ID="btnPostBack" runat="server" Text="" Style="display:none" OnClick="btnAccion_Click"/>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<style>
/* ---- CABECERA AGENTE ---- */
.me-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 12px;
    padding: 14px 18px;
}
.me-info { display: flex; align-items: center; gap: 11px; }
.me-avatar { font-size: 34px; color: #C2185B; line-height: 1; }
.me-nombre { font-size: 15px; font-weight: 600; color: #212121; }
.me-rol    { font-size: 11px; color: #9e9e9e; margin-top: 2px; }
.me-stats  { display: flex; gap: 20px; flex-wrap: wrap; }
.me-stat   { text-align: center; min-width: 52px; }
.me-stat-val { font-size: 22px; font-weight: 700; color: #424242; line-height: 1; }
.me-stat-lbl { font-size: 10px; color: #9e9e9e; margin-top: 3px; text-transform: uppercase; letter-spacing: .4px; }
.me-stat-warn .me-stat-val { color: #F57C00; }
.me-stat-ok   .me-stat-val { color: #388E3C; }
.me-stat-err  .me-stat-val { color: #D32F2F; }

/* ---- FILAS ---- */
.me-fila-dim td { opacity: .62; }
.me-fila-express { border-left: 3px solid #F57C00 !important; }

/* ---- SLOT ---- */
.me-slot-h    { font-size: 14px; font-weight: 600; color: #212121; }
.me-slot-fin  { font-size: 10px; color: #9e9e9e; }
.me-slot-fecha{ font-size: 10px; color: #9e9e9e; margin-top: 2px; }
.me-exp-pill  {
    display: inline-flex; align-items: center; gap: 3px;
    padding: 2px 6px; border-radius: 10px;
    background: #FFF3E0; color: #E65100;
    font-size: 10px; font-weight: 600; border: 1px solid #FFCC80;
}
.me-exp-pill i { font-size: 10px; }

/* ---- RECEPTOR / ENVIA / PRODUCTOS ---- */
.me-cod      { font-family: monospace; font-size: 11px; font-weight: 700; color: #185FA5; }
.me-receptor { font-size: 13px; font-weight: 600; color: #212121; margin-top: 2px; display: flex; align-items: center; gap: 4px; }
.me-receptor i { font-size: 12px; color: #9e9e9e; }
.me-sub      { font-size: 10px; color: #9e9e9e; display: flex; align-items: center; gap: 3px; margin-top: 2px; }
.me-sub i    { font-size: 11px; }

.me-envia-blk {
    display: flex; align-items: flex-start; gap: 6px;
    margin-top: 6px; padding: 5px 8px;
    background: #FFF8FB; border-radius: 6px;
    border: 1px solid #FCE4EC;
}
.me-envia-lbl {
    font-size: 9px; font-weight: 700; text-transform: uppercase;
    letter-spacing: .5px; color: #C2185B;
    white-space: nowrap; padding-top: 1px;
    display: flex; align-items: center; gap: 3px;
}
.me-envia-lbl i { font-size: 10px; }
.me-envia-nom { font-size: 11px; font-weight: 500; color: #424242; }
.me-envia-cel { font-size: 10px; color: #9e9e9e; font-weight: 400; }

.me-prods     { margin-top: 6px; display: flex; flex-direction: column; gap: 3px; }
.me-prod-row  { display: flex; align-items: flex-start; gap: 5px; font-size: 11px; }
.me-prod-qty  {
    background: #FCE4EC; color: #880E4F;
    border-radius: 4px; padding: 1px 5px;
    font-size: 10px; font-weight: 700; flex-shrink: 0; line-height: 17px;
}
.me-prod-nom  { flex: 1; color: #424242; line-height: 1.4; }
.me-prod-pers { display: block; font-size: 10px; color: #7B1FA2; font-style: italic; margin-top: 1px; }

/* ---- ZONA ---- */
.me-zona { font-size: 11px; color: #424242; display: flex; align-items: center; gap: 4px; }
.me-zona i { font-size: 11px; color: #C2185B; }

/* ---- BADGES ESTADO ---- */
.me-badge { display: inline-flex; align-items: center; gap: 4px; padding: 3px 8px; border-radius: 12px; font-size: 10px; font-weight: 600; white-space: nowrap; }
.me-dot   { width: 5px; height: 5px; border-radius: 50%; flex-shrink: 0; }
.me-b-pend  { background: #FFF8E1; color: #E65100; } .me-b-pend  .me-dot { background: #FFC107; }
.me-b-imp   { background: #F3E5F5; color: #6A1B9A; } .me-b-imp   .me-dot { background: #AB47BC; }
.me-b-prep  { background: #E8EAF6; color: #283593; } .me-b-prep  .me-dot { background: #5C6BC0; }
.me-b-listo { background: #FFF3E0; color: #E65100; } .me-b-listo .me-dot { background: #FF9800; }
.me-b-ruta  { background: #E3F2FD; color: #1565C0; } .me-b-ruta  .me-dot { background: #1976D2; }
.me-b-ok    { background: #E8F5E9; color: #2E7D32; } .me-b-ok    .me-dot { background: #43A047; }
.me-b-fail  { background: #FFEBEE; color: #C62828; } .me-b-fail  .me-dot { background: #E53935; }

/* ---- ACCIONES ---- */
.me-acciones { display: flex; align-items: center; justify-content: flex-end; gap: 4px; flex-wrap: nowrap; }

.me-btn-estado {
    display: inline-flex; align-items: center; gap: 3px;
    padding: 4px 8px; border-radius: 6px;
    font-size: 10px; font-weight: 600; cursor: pointer; border: 1px solid;
    white-space: nowrap;
}
.me-btn-ruta { background: #E3F2FD; color: #1565C0; border-color: #90CAF9; }
.me-btn-ok   { background: #E8F5E9; color: #2E7D32; border-color: #A5D6A7; }
.me-btn-rein { background: #EDE7F6; color: #4527A0; border-color: #B39DDB; }
.me-btn-estado i { font-size: 11px; }

.me-btn-mas {
    width: 28px; height: 28px; border-radius: 6px;
    border: 1px solid #e0e0e0; background: white;
    color: #757575; display: flex; align-items: center;
    justify-content: center; cursor: pointer; font-size: 14px; flex-shrink: 0;
}
.me-btn-mas:hover, .me-btn-mas.open {
    background: #f5f5f5; border-color: #bdbdbd; color: #424242;
}

/* ---- DROPDOWN MENU ---- */
.me-dropdown { position: relative; display: inline-block; }
.me-dd-menu {
    position: absolute; right: 0; top: 32px;
    width: 210px; background: white;
    border: 1px solid #e0e0e0; border-radius: 8px;
    box-shadow: 0 6px 20px rgba(0,0,0,.13);
    z-index: 300; display: none; overflow: hidden;
}
.me-dd-menu.open { display: block; }
.me-dd-sec  { border-bottom: 1px solid #f5f5f5; }
.me-dd-sec:last-child { border-bottom: none; }
.me-dd-lbl  { padding: 5px 11px 2px; font-size: 9px; font-weight: 700; text-transform: uppercase; letter-spacing: .6px; color: #9e9e9e; }
.me-dd-item {
    display: flex; align-items: center; gap: 8px;
    padding: 8px 11px; font-size: 12px; color: #424242;
    cursor: pointer; width: 100%; border: none; background: none;
    text-align: left; transition: background .1s;
}
.me-dd-item:hover { background: #FFF8FB; }
.me-dd-item i { font-size: 15px; width: 17px; flex-shrink: 0; color: #757575; }
.me-dd-item span { display: flex; flex-direction: column; }
.me-dd-item small { font-size: 10px; color: #9e9e9e; margin-top: 1px; }
.me-dd-item.me-dd-danger { color: #C62828; } .me-dd-item.me-dd-danger i { color: #C62828; }
.me-dd-item.me-dd-success { color: #2E7D32; } .me-dd-item.me-dd-success i { color: #2E7D32; }
.me-dd-item.me-dd-disabled { color: #bdbdbd; cursor: default; }
.me-dd-item.me-dd-disabled i { color: #bdbdbd; }
.me-dd-item.me-dd-disabled:hover { background: none; }

.tabla-loading { text-align: center; padding: 32px 16px; color: #9e9e9e; font-size: 13px; }
</style>
<script type="text/javascript">
// @ts-nocheck

var _timer  = null;
var _btnId  = '<%= btnPostBack.ClientID %>';

/* ============================================================
   CARGAR ENTREGAS
   ============================================================ */
function cargarEntregas() {
    var tbody = document.getElementById('tbodyEntregas');
    var lblM  = document.getElementById('lblMostrando');
    if (!tbody) return;

    tbody.innerHTML = '<tr><td colspan="5" class="tabla-loading"><i class="ti ti-loader"></i><br>Cargando...</td></tr>';

    var qs  = construirQuery();
    var url = 'MisEntregas_Handler.ashx?' + qs + '&_=' + Date.now();

    fetch(url, { credentials: 'same-origin' })
        .then(function(r) {
            if (r.status === 401) { window.location.href = '../../Login.aspx'; return null; }
            return r.text();
        })
        .then(function(html) {
            if (html === null) return;
            var m = html.match(/^<!--TOTAL:(\d+)-->/);
            var total = 0;
            if (m) { total = parseInt(m[1], 10); html = html.replace(/^<!--TOTAL:\d+-->/, ''); }
            tbody.innerHTML = html;
            if (lblM) lblM.textContent = total;
            actualizarStats();
        })
        .catch(function(err) {
            tbody.innerHTML = '<tr><td colspan="5" class="table-empty"><i class="ti ti-alert-triangle"></i><br>Error: ' + err.message + '</td></tr>';
        });
}

/* ============================================================
   CONTADORES CABECERA
   ============================================================ */
function actualizarStats() {
    var filas = document.querySelectorAll('#tbodyEntregas tr[data-estado]');
    var total = filas.length;
    var hoy = 0, entregados = 0, noEntregados = 0;
    var hoyStr = new Date().toISOString().split('T')[0];
    for (var i = 0; i < filas.length; i++) {
        var est  = filas[i].dataset.estado || '';
        var fech = filas[i].dataset.fecha  || '';
        if (fech === hoyStr) hoy++;
        if (est === 'ENTREGADO')    entregados++;
        if (est === 'NO_ENTREGADO') noEntregados++;
    }
    document.getElementById('statTotal').textContent        = total;
    document.getElementById('statHoy').textContent          = hoy;
    document.getElementById('statEntregados').textContent   = entregados;
    document.getElementById('statNoEntregados').textContent = noEntregados;
}

/* ============================================================
   QUERY STRING
   ============================================================ */
function construirQuery() {
    var qs = '';
    var b = document.getElementById('txBuscar').value;
    if (b) qs += 'b=' + encodeURIComponent(b) + '&';

    var pill = document.querySelector('#pillsFecha .pill-filter.active');
    if (pill) {
        var val = pill.dataset.val;
        if (val === 'hoy') {
            qs += 'hoy=1&';
        } else if (val === 'manana') {
            var m = new Date(); m.setDate(m.getDate() + 1);
            var fs = fmtD(m); qs += 'fed=' + fs + '&feh=' + fs + '&';
        } else if (val === 'semana') {
            var hoy2 = new Date();
            var lun  = new Date(hoy2); lun.setDate(hoy2.getDate() - ((hoy2.getDay() + 6) % 7));
            var dom  = new Date(lun);  dom.setDate(lun.getDate() + 6);
            qs += 'fed=' + fmtD(lun) + '&feh=' + fmtD(dom) + '&';
        }
        // 'todas' -> sin filtro fecha
    }
    var est = document.getElementById('ddEstado').value;
    if (est) qs += 'op=' + est + '&';
    return qs;
}

function fmtD(d) {
    return d.getFullYear() + '-' + ('0'+(d.getMonth()+1)).slice(-2) + '-' + ('0'+d.getDate()).slice(-2);
}

/* ============================================================
   ACCIONES DE FILA
   ============================================================ */
function cambiarEstado(pid, estadoNuevo) {
    cerrarTodosMenus();
    document.getElementById('hdAccion').value     = 'CAMBIAR_ESTADO';
    document.getElementById('hdPedidoId').value   = pid;
    document.getElementById('hdEstadoNuevo').value = estadoNuevo;
    document.getElementById(_btnId).click();
}

function abrirDetalle(pid) {
    cerrarTodosMenus();
    window.location.href = 'Pedido_Detalle.aspx?id=' + pid;
}

function verRecibo(pid) {
    cerrarTodosMenus();
    window.open('Recibo.aspx?id=' + pid, 'recibo', 'width=420,height=650');
}

function abrirWA(cel) {
    cerrarTodosMenus();
    window.open('https://wa.me/' + cel, '_blank');
}

function llamar(cel) {
    cerrarTodosMenus();
    window.location.href = 'tel:+' + cel;
}

function abrirMaps(dir) {
    cerrarTodosMenus();
    window.open('https://maps.google.com/?q=' + encodeURIComponent(dir), '_blank');
}

/* ============================================================
   MENÚ DESPLEGABLE
   ============================================================ */
function toggleMenuEntrega(pid, evt) {
    if (evt) evt.stopPropagation();
    var menu = document.getElementById('memenu_' + pid);
    var btn  = document.querySelector('#medd_' + pid + ' .me-btn-mas');
    if (!menu) return;
    var isOpen = menu.classList.contains('open');
    cerrarTodosMenus();
    if (!isOpen) {
        menu.classList.add('open');
        if (btn) btn.classList.add('open');
    }
}

function cerrarTodosMenus() {
    document.querySelectorAll('.me-dd-menu').forEach(function(m){ m.classList.remove('open'); });
    document.querySelectorAll('.me-btn-mas').forEach(function(b){ b.classList.remove('open'); });
}

document.addEventListener('click', function(e) {
    if (!e.target.closest('.me-dropdown')) cerrarTodosMenus();
});

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') cerrarTodosMenus();
});

/* ============================================================
   FILTROS + EVENTOS
   ============================================================ */
function limpiarFiltros() {
    document.getElementById('txBuscar').value = '';
    document.getElementById('ddEstado').value = '';
    document.querySelectorAll('#pillsFecha .pill-filter').forEach(function(p){ p.classList.remove('active'); });
    document.querySelector('#pillsFecha .pill-filter[data-val="hoy"]').classList.add('active');
    cargarEntregas();
}

function setupEventos() {
    document.querySelectorAll('#pillsFecha .pill-filter').forEach(function(p) {
        p.addEventListener('click', function() {
            document.querySelectorAll('#pillsFecha .pill-filter').forEach(function(x){ x.classList.remove('active'); });
            this.classList.add('active');
            cargarEntregas();
        });
    });
    var tx = document.getElementById('txBuscar');
    if (tx) tx.addEventListener('input', function() {
        if (_timer) clearTimeout(_timer);
        _timer = setTimeout(cargarEntregas, 400);
    });
    var dd = document.getElementById('ddEstado');
    if (dd) dd.addEventListener('change', cargarEntregas);
}

/* ============================================================
   INIT
   ============================================================ */
(function() {
    setupEventos();
    cargarEntregas();

    var alertMsg  = '<%= MensajeAlerta %>';
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
