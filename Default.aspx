<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Default.aspx.vb" Inherits="SISCONBOL_FLORERIA._Default" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Dashboard
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    Dashboard
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div id="divAlerta" class="alerta"></div>

    <div class="bienvenida" id="spBienvenida">Bienvenido</div>
    <div class="bienvenida-sub" id="spFecha"></div>

    <%-- STATS --%>
    <div class="stats">
        <div class="stat">
            <div class="stat-icon"><i class="ti ti-package"></i></div>
            <div class="stat-lbl">Pre-Pedidos</div>
            <div class="stat-val" id="statPrePedidos"><%=TotalPrePedidos%></div>
            <div class="stat-sub" id="statPrePedidosHoy"><%=PrePedidosHoy%></div>
        </div>
        <div class="stat g">
            <div class="stat-icon"><i class="ti ti-coin"></i></div>
            <div class="stat-lbl">Ventas Hoy</div>
            <div class="stat-val" id="statVentasHoy"><%=VentasHoy%> Bs</div>
            <div class="stat-sub" id="statVentasInc"><%=VentasIncremento%></div>
        </div>
        <div class="stat b">
            <div class="stat-icon"><i class="ti ti-truck-delivery"></i></div>
            <div class="stat-lbl">Por Entregar</div>
            <div class="stat-val" id="statPorEntregar"><%=PorEntregar%></div>
            <div class="stat-sub">Para mañana</div>
        </div>
        <div class="stat a">
            <div class="stat-icon"><i class="ti ti-clock"></i></div>
            <div class="stat-lbl">Pendientes Pago</div>
            <div class="stat-val" id="statPendientesPago"><%=PendientesPago%></div>
            <div class="stat-sub" id="statPorVencer"><%=PorVencer%></div>
        </div>
    </div>

    <%-- ACCIONES RÁPIDAS --%>
    <div class="panel" style="margin-top: 20px;">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-bolt"></i>
                Acciones rápidas
            </div>
        </div>
        <div class="panel-body">
            <div class="acciones-rapidas">
                <a href="Modulos/Pedidos/PrePedido_Crear.aspx" class="accion-card accion-primaria">
                    <i class="ti ti-plus"></i>
                    <div class="accion-content">
                        <div class="accion-titulo">Nuevo Pre-Pedido</div>
                        <div class="accion-sub">Crear formulario web</div>
                    </div>
                </a>
                <a href="Modulos/Pedidos/PrePedidos.aspx" class="accion-card">
                    <i class="ti ti-list"></i>
                    <div class="accion-content">
                        <div class="accion-titulo">Gestionar Pre-Pedidos</div>
                        <div class="accion-sub">Ver todos (<%=TotalPrePedidos%>)</div>
                    </div>
                </a>
                <a href="Modulos/Pedidos/GestionPedidos.aspx" class="accion-card">
                    <i class="ti ti-clipboard-list"></i>
                    <div class="accion-content">
                        <div class="accion-titulo">Gestion de Pedidos</div>
                        <div class="accion-sub">Administrar pedidos activos</div>
                    </div>
                </a>
                <a href="Modulos/Pedidos/MisEntregas.aspx" class="accion-card">
                    <i class="ti ti-truck-delivery"></i>
                    <div class="accion-content">
                        <div class="accion-titulo">Mis Entregas</div>
                        <div class="accion-sub">Pedidos asignados a mi</div>
                    </div>
                </a>
            </div>
        </div>
    </div>

    <%-- LISTA PRE-PEDIDOS RECIENTES --%>
    <div class="panel" style="margin-top: 20px;">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-file-description"></i>
                Pre-Pedidos recientes
            </div>
            <div class="panel-actions">
                <a href="Modulos/Pedidos/PrePedidos.aspx" class="btn btn-sm">
                    Ver todos
                    <i class="ti ti-arrow-right"></i>
                </a>
            </div>
        </div>
        <div class="panel-body" style="padding: 0;">
            <div id="divPrePedidosRecientes"></div>
        </div>
    </div>

    <%-- LISTA PEDIDOS RECIENTES --%>
    <div class="panel" style="margin-top: 20px;">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-shopping-bag"></i>
                Pedidos recientes
            </div>
            <div class="panel-actions">
                <a href="Modulos/Pedidos/GestionPedidos.aspx" class="btn btn-sm">
                    Ver todos
                    <i class="ti ti-arrow-right"></i>
                </a>
            </div>
        </div>
        <div class="panel-body" style="padding: 0;">
            <div id="divPedidosRecientes"></div>
        </div>
    </div>

    <%-- JSON oculto para JS --%>
    <div id="jsonPrePedidos" style="display:none;"><%=JsonPrePedidosRecientes%></div>
    <div id="jsonPedidos"    style="display:none;"><%=JsonPedidosRecientes%></div>
</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<style>
.stat-icon { font-size: 20px; margin-bottom: 6px; opacity: 0.8; }
.stat-sub  { font-size: 12px; margin-top: 4px; opacity: 0.7; }

.acciones-rapidas {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 12px;
}
.accion-card {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 14px 16px;
    background: white;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    text-decoration: none;
    color: #424242;
    transition: all 0.15s;
}
.accion-card:hover    { background: #FFF8FB; border-color: #C2185B; transform: translateY(-1px); }
.accion-card i        { font-size: 24px; color: #757575; flex-shrink: 0; }
.accion-primaria      { background: #FFF0F6; border-color: #C2185B; }
.accion-primaria i    { color: #C2185B; }
.accion-primaria:hover{ background: #FFE0ED; }
.accion-content       { flex: 1; }
.accion-titulo        { font-size: 14px; font-weight: 500; color: #424242; margin-bottom: 2px; }
.accion-sub           { font-size: 12px; color: #757575; }

/* ---- Filas de lista (pre-pedidos y pedidos) ---- */
.dash-fila {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 13px 16px;
    border-bottom: 1px solid #f5f5f5;
    cursor: pointer;
    text-decoration: none;
    color: inherit;
    transition: background 0.12s;
}
.dash-fila:last-child { border-bottom: none; }
.dash-fila:hover      { background: #FFF8FB; }

.dash-main  { flex: 1; min-width: 0; }
.dash-top   { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; flex-wrap: wrap; }
.dash-mid   { display: flex; align-items: center; gap: 8px; }
.dash-bot   { display: flex; align-items: center; gap: 8px; margin-top: 4px; flex-wrap: wrap; }

.dash-cod   { font-family: monospace; font-size: 11px; font-weight: 600; color: #7F77DD; }
.dash-cod-p { color: #185FA5; }
.dash-nom   { font-size: 13px; font-weight: 500; color: #212121; }
.dash-sub   { font-size: 11px; color: #9e9e9e; display: flex; align-items: center; gap: 3px; }

.dash-right    { display: flex; flex-direction: column; align-items: flex-end; gap: 3px; flex-shrink: 0; }
.dash-monto    { font-size: 13px; font-weight: 500; color: #212121; white-space: nowrap; }
.dash-fecha    { font-size: 11px; color: #9e9e9e; }
.dash-chevron  { color: #bdbdbd; font-size: 16px; flex-shrink: 0; }

/* ---- Badges ---- */
.db { display: inline-flex; align-items: center; gap: 3px; padding: 2px 8px; border-radius: 99px; font-size: 11px; font-weight: 500; white-space: nowrap; }
.db-borrador   { background: #F1EFE8; color: #5F5E5A; }
.db-form       { background: #E6F1FB; color: #185FA5; }
.db-completado { background: #E1F5EE; color: #0F6E56; }
.db-esp        { background: #FAEEDA; color: #854F0B; }
.db-pagado     { background: #EAF3DE; color: #3B6D11; }
.db-convertido { background: #EEEDFE; color: #534AB7; }
.db-cancelado  { background: #FCEBEB; color: #A32D2D; }
.db-sin-pago   { background: #F1EFE8; color: #5F5E5A; }
.db-anticipo   { background: #FAEEDA; color: #854F0B; }
.db-pago       { background: #EAF3DE; color: #3B6D11; }
.db-sistema    { background: #F1EFE8; color: #5F5E5A; }
.db-wc         { background: #E1F5EE; color: #0F6E56; }
.db-exp        { background: #FCEBEB; color: #A32D2D; }

.db-dot { width: 5px; height: 5px; border-radius: 50%; display: inline-block; flex-shrink: 0; }
.dot-gr { background: #888780; }
.dot-b  { background: #185FA5; }
.dot-g  { background: #3B6D11; }
.dot-y  { background: #854F0B; }
.dot-r  { background: #A32D2D; }
.dot-p  { background: #534AB7; }

/* Token info */
.tk-activo  { font-size: 10px; color: #854F0B; display: inline-flex; align-items: center; gap: 3px; }
.tk-vencido { font-size: 10px; color: #A32D2D; display: inline-flex; align-items: center; gap: 3px; }
.tk-ok      { font-size: 10px; color: #3B6D11; display: inline-flex; align-items: center; gap: 3px; }
.tk-none    { font-size: 10px; color: #9e9e9e; display: inline-flex; align-items: center; gap: 3px; }

.express-pill { background: #FAEEDA; color: #854F0B; font-size: 10px; padding: 1px 5px; border-radius: 3px; }

.empty-state { text-align: center; padding: 40px 20px; color: #9e9e9e; }
</style>

<script type="text/javascript">
// @ts-nocheck
window.addEventListener('DOMContentLoaded', function() {
    cargarDatosUsuario();
    renderPrePedidos();
    renderPedidos();
});

function cargarDatosUsuario() {
    var nombres   = '<%=Session("nombres")%>';
    var apellidos = '<%=Session("apellidos")%>';
    var elBien = document.getElementById('spBienvenida');
    var elFecha = document.getElementById('spFecha');
    if (elBien && nombres) {
        elBien.textContent = 'Bienvenido, ' + nombres + ' ' + apellidos;
    }
    if (elFecha) {
        var dias  = ['Domingo','Lunes','Martes','Miércoles','Jueves','Viernes','Sábado'];
        var meses = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
        var hoy   = new Date();
        elFecha.textContent = dias[hoy.getDay()] + ', ' + hoy.getDate() + ' de ' + meses[hoy.getMonth()] + ' de ' + hoy.getFullYear();
    }
}

/* ============================================================
   PRE-PEDIDOS
   ============================================================ */
function renderPrePedidos() {
    var divJson = document.getElementById('jsonPrePedidos');
    var divLista = document.getElementById('divPrePedidosRecientes');
    if (!divJson || !divLista) return;

    var jsonText = divJson.textContent.trim();
    if (!jsonText) { divLista.innerHTML = htmlVacio('No hay pre-pedidos recientes'); return; }

    var datos;
    try { datos = JSON.parse(jsonText); } catch(e) { return; }
    if (!datos || datos.length === 0) { divLista.innerHTML = htmlVacio('No hay pre-pedidos recientes'); return; }

    var html = '';
    for (var i = 0; i < datos.length; i++) {
        var d = datos[i];
        html += '<a class="dash-fila" href="Modulos/Pedidos/PrePedido_Detalle.aspx?id=' + d.prepedido_id + '">';
        html += '  <div class="dash-main">';

        html += '    <div class="dash-top">';
        html += '      <span class="dash-cod">' + esc(d.codigo) + '</span>';
        html += '      ' + badgePP(d.estado);
        html += '    </div>';

        html += '    <div class="dash-mid">';
        html += '      <span class="dash-nom">' + esc(d.cliente_nombre || 'Sin nombre') + '</span>';
        html += '      <span class="dash-sub"><i class="ti ti-device-mobile"></i> ' + esc(d.cliente_celular) + '</span>';
        html += '    </div>';

        html += '    <div class="dash-bot">';
        html += '      ' + htmlToken(d.token_web, d.token_expira, d.estado);
        html += '      ' + badgePago(d.estado_pago, d.pago_verificado_por);
        html += '    </div>';

        html += '  </div>';
        html += '  <div class="dash-right">';
        html += '    <span class="dash-monto">' + fmt(d.total_general_bs) + ' Bs</span>';
        html += '    <span class="dash-fecha">' + fmtFecha(d.creado_en) + '</span>';
        html += '  </div>';
        html += '  <i class="ti ti-chevron-right dash-chevron"></i>';
        html += '</a>';
    }
    divLista.innerHTML = html;
}

function badgePP(/** @type {string} */ estado) {
    var mapa = {
        'BORRADOR':       '<span class="db db-borrador"><span class="db-dot dot-gr"></span>Borrador</span>',
        'FORM_ENVIADO':   '<span class="db db-form"><span class="db-dot dot-b"></span>Form enviado</span>',
        'COMPLETADO':     '<span class="db db-completado"><span class="db-dot dot-g"></span>Completado</span>',
        'ESPERANDO_PAGO': '<span class="db db-esp"><span class="db-dot dot-y"></span>Esperando pago</span>',
        'PAGADO':         '<span class="db db-pagado"><span class="db-dot dot-g"></span>Pagado</span>',
        'CONVERTIDO':     '<span class="db db-convertido"><span class="db-dot dot-p"></span>Convertido</span>',
        'CANCELADO':      '<span class="db db-cancelado"><span class="db-dot dot-r"></span>Cancelado</span>'
    };
    return mapa[estado] || '<span class="db db-borrador">' + esc(estado) + '</span>';
}

function htmlToken(/** @type {string} */ tokenWeb, /** @type {string} */ tokenExpira, /** @type {string} */ estado) {
    if (estado === 'BORRADOR' || !tokenWeb) {
        return '<span class="tk-none"><i class="ti ti-link-off"></i> Sin enviar</span>';
    }
    if (estado === 'COMPLETADO' || estado === 'ESPERANDO_PAGO' || estado === 'PAGADO' || estado === 'CONVERTIDO') {
        return '<span class="tk-ok"><i class="ti ti-circle-check"></i> Cliente llenó</span>';
    }
    if (tokenExpira) {
        var expira = new Date(tokenExpira);
        var ahora  = new Date();
        if (expira < ahora) {
            return '<span class="tk-vencido"><i class="ti ti-clock-x"></i> Token vencido · ' + fmtFecha(tokenExpira) + '</span>';
        }
        var difH = Math.round((expira - ahora) / 3600000);
        return '<span class="tk-activo"><i class="ti ti-clock"></i> Vence en ' + difH + 'h</span>';
    }
    return '<span class="tk-none"><i class="ti ti-link-off"></i> Sin token</span>';
}

function badgePago(/** @type {string} */ estadoPago, /** @type {string} */ verificadoPor) {
    if (estadoPago === 'VERIFICADO') {
        var por = verificadoPor ? ' · ' + esc(verificadoPor) : '';
        return '<span class="db db-pago"><span class="db-dot dot-g"></span>Verificado' + por + '</span>';
    }
    if (estadoPago === 'PENDIENTE') {
        return '<span class="db db-esp"><span class="db-dot dot-y"></span>Comprobante enviado</span>';
    }
    if (estadoPago === 'RECHAZADO') {
        return '<span class="db db-cancelado"><span class="db-dot dot-r"></span>Pago rechazado</span>';
    }
    return '<span class="db db-sin-pago"><span class="db-dot dot-gr"></span>Sin pago</span>';
}

/* ============================================================
   PEDIDOS
   ============================================================ */
function renderPedidos() {
    var divJson = document.getElementById('jsonPedidos');
    var divLista = document.getElementById('divPedidosRecientes');
    if (!divJson || !divLista) return;

    var jsonText = divJson.textContent.trim();
    if (!jsonText) { divLista.innerHTML = htmlVacio('No hay pedidos recientes'); return; }

    var datos;
    try { datos = JSON.parse(jsonText); } catch(e) { return; }
    if (!datos || datos.length === 0) { divLista.innerHTML = htmlVacio('No hay pedidos recientes'); return; }

    var html = '';
    for (var i = 0; i < datos.length; i++) {
        var d = datos[i];
        html += '<a class="dash-fila" href="Modulos/Pedidos/Pedido_Detalle.aspx?id=' + d.pedido_id + '">';
        html += '  <div class="dash-main">';

        html += '    <div class="dash-top">';
        html += '      <span class="dash-cod dash-cod-p">' + esc(d.codigo) + '</span>';
        html += '      ' + badgeOrigen(d.origen);
        html += '      ' + badgeEstadoPago(d.estado_pago);
        html += '    </div>';

        html += '    <div class="dash-mid">';
        html += '      <span class="dash-nom">' + esc(d.receptor_nombre) + '</span>';
        if (d.zona_nombre) {
            html += '  <span class="dash-sub"><i class="ti ti-map-pin"></i> ' + esc(d.zona_nombre) + '</span>';
        }
        html += '    </div>';

        html += '    <div class="dash-bot">';
        html += '      <span class="dash-sub"><i class="ti ti-calendar"></i> ' + fmtFechaCorta(d.fecha_entrega) + '</span>';
        if (d.es_express) {
            html += '  <span class="express-pill">Express</span>';
        }
        if (d.saldo_bs && parseFloat(d.saldo_bs) > 0) {
            html += '  <span class="db db-anticipo"><span class="db-dot dot-y"></span>Saldo ' + fmt(d.saldo_bs) + ' Bs</span>';
        }
        html += '    </div>';

        html += '  </div>';
        html += '  <div class="dash-right">';
        html += '    <span class="dash-monto">' + fmt(d.total_bs) + ' Bs</span>';
        html += '    <span class="dash-fecha">' + fmtFecha(d.creado_en) + '</span>';
        html += '  </div>';
        html += '  <i class="ti ti-chevron-right dash-chevron"></i>';
        html += '</a>';
    }
    divLista.innerHTML = html;
}

function badgeOrigen(/** @type {string} */ origen) {
    if (origen === 'WOOCOMMERCE') {
        return '<span class="db db-wc">WooCommerce</span>';
    }
    return '<span class="db db-sistema">Sistema</span>';
}

function badgeEstadoPago(/** @type {string} */ ep) {
    var mapa = {
        'PENDIENTE':    '<span class="db db-sin-pago"><span class="db-dot dot-gr"></span>Sin pago</span>',
        'ANTICIPO':     '<span class="db db-anticipo"><span class="db-dot dot-y"></span>Anticipo</span>',
        'PAGADO':       '<span class="db db-pago"><span class="db-dot dot-g"></span>Pagado</span>',
        'REEMBOLSADO':  '<span class="db db-cancelado"><span class="db-dot dot-r"></span>Reembolsado</span>'
    };
    return mapa[ep] || '<span class="db db-sin-pago">' + esc(ep) + '</span>';
}

/* ============================================================
   UTILIDADES
   ============================================================ */
function htmlVacio(/** @type {string} */ msg) {
    return '<div class="empty-state"><i class="ti ti-inbox" style="font-size:36px;display:block;margin-bottom:8px;opacity:0.3;"></i>' + msg + '</div>';
}

function fmt(/** @type {any} */ v) {
    if (!v) return '0.00';
    return parseFloat(v).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function fmtFecha(/** @type {string} */ s) {
    if (!s) return '';
    var d = new Date(s);
    var meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return d.getDate() + ' ' + meses[d.getMonth()];
}

function fmtFechaCorta(/** @type {string} */ s) {
    if (!s) return '';
    var partes = s.split('T')[0].split('-');
    if (partes.length < 3) return s;
    var meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return parseInt(partes[2]) + ' ' + meses[parseInt(partes[1]) - 1] + ' ' + partes[0];
}

function esc(/** @type {any} */ v) {
    if (!v) return '';
    return String(v)
        .replace(/&/g,'&amp;')
        .replace(/</g,'&lt;')
        .replace(/>/g,'&gt;')
        .replace(/"/g,'&quot;');
}


</script>
</asp:Content>
