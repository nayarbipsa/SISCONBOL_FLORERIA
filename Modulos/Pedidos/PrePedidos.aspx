<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="PrePedidos.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_PrePedidos" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Pre-Pedidos
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    Pre-Pedidos
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

    <div id="divAlerta" class="alerta"></div>

    <%-- TOOLBAR --%>
    <div class="filtros">
        <div class="filtro">
            <input type="text" id="txBuscar" class="form-control"
                   placeholder="Código, celular, nombre..."
                   oninput="onBuscarInput()" />
        </div>
        <div class="filtro" style="flex:0 0 auto; min-width:0;">
            <select id="selEstado" class="form-control" onchange="aplicarFiltros()">
                <option value="">Todos los estados</option>
                <option value="BORRADOR">Borrador</option>
                <option value="FORM_ENVIADO">Form enviado</option>
                <option value="COMPLETADO">Completado</option>
                <option value="ESPERANDO_PAGO">Esperando pago</option>
                <option value="PAGADO">Pagado</option>
                <option value="CONVERTIDO">Convertido</option>
                <option value="CANCELADO">Cancelado</option>
            </select>
        </div>
        <div style="flex:0 0 auto;">
            <a href="PrePedido_Crear.aspx" class="btn btn-primary">
                <i class="ti ti-plus"></i> Nuevo
            </a>
        </div>
    </div>

    <%-- LISTA --%>
    <div class="panel">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-file-description"></i>
                Pre-Pedidos
            </div>
            <div class="panel-actions">
                <span id="spTotal" style="font-size:12px; color:#9e9e9e;"></span>
            </div>
        </div>
        <div class="panel-body" style="padding:0;" id="divLista">
            <div class="pp-loading">
                <i class="ti ti-loader" style="font-size:24px; opacity:0.4;"></i>
                Cargando...
            </div>
        </div>
        <%-- Paginación --%>
        <div class="panel-footer" id="divPaginacion" style="display:none;">
            <button class="btn btn-sm" id="btnAnterior" onclick="irPagina(-1)" disabled>
                <i class="ti ti-chevron-left"></i> Anterior
            </button>
            <span id="spPagina" style="font-size:13px; color:#616161;"></span>
            <button class="btn btn-sm" id="btnSiguiente" onclick="irPagina(1)">
                Siguiente <i class="ti ti-chevron-right"></i>
            </button>
        </div>
    </div>

    <%-- JSON del servidor (primera carga) --%>
    <div id="jsonInicial" style="display:none;"><%=JsonInicial%></div>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<style>
/* Fila de la lista */
.pp-fila {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 13px 18px;
    border-bottom: 1px solid #f5f5f5;
    text-decoration: none;
    color: inherit;
    transition: background .12s;
}
.pp-fila:last-child  { border-bottom: none; }
.pp-fila:hover       { background: #FFF8FB; }

.pp-main  { flex: 1; min-width: 0; }
.pp-top   { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; flex-wrap: wrap; }
.pp-mid   { display: flex; align-items: center; gap: 8px; }
.pp-bot   { display: flex; align-items: center; gap: 8px; margin-top: 4px; flex-wrap: wrap; }

.pp-cod   { font-family: monospace; font-size: 11px; font-weight: 600; color: #7F77DD; }
.pp-nom   { font-size: 13px; font-weight: 500; color: #212121; }
.pp-sub   { font-size: 11px; color: #9e9e9e; display: inline-flex; align-items: center; gap: 3px; }

.pp-right   { display: flex; flex-direction: column; align-items: flex-end; gap: 3px; flex-shrink: 0; }
.pp-monto   { font-size: 13px; font-weight: 500; color: #212121; }
.pp-fecha   { font-size: 11px; color: #9e9e9e; }
.pp-chevron { color: #bdbdbd; font-size: 16px; flex-shrink: 0; }

/* Badges de estado pre-pedido */
.ppb { display: inline-flex; align-items: center; gap: 3px; padding: 2px 8px; border-radius: 99px; font-size: 11px; font-weight: 500; white-space: nowrap; }
.ppb-dot { width: 5px; height: 5px; border-radius: 50%; display: inline-block; flex-shrink: 0; }
.ppb-borrador   { background: #F1EFE8; color: #5F5E5A; }
.ppb-form       { background: #E6F1FB; color: #185FA5; }
.ppb-completado { background: #E1F5EE; color: #0F6E56; }
.ppb-esp        { background: #FAEEDA; color: #854F0B; }
.ppb-pagado     { background: #EAF3DE; color: #3B6D11; }
.ppb-convertido { background: #EEEDFE; color: #534AB7; }
.ppb-cancelado  { background: #FCEBEB; color: #A32D2D; }

/* Badges de pago */
.ppb-sinpago  { background: #F1EFE8; color: #5F5E5A; }
.ppb-pendpago { background: #FAEEDA; color: #854F0B; }
.ppb-verif    { background: #EAF3DE; color: #3B6D11; }
.ppb-rech     { background: #FCEBEB; color: #A32D2D; }

/* Info del token */
.tk-activo  { font-size: 10px; color: #854F0B; display: inline-flex; align-items: center; gap: 3px; }
.tk-vencido { font-size: 10px; color: #A32D2D; display: inline-flex; align-items: center; gap: 3px; }
.tk-ok      { font-size: 10px; color: #3B6D11; display: inline-flex; align-items: center; gap: 3px; }
.tk-none    { font-size: 10px; color: #9e9e9e; display: inline-flex; align-items: center; gap: 3px; }

/* Loading y empty */
.pp-loading { text-align: center; padding: 40px; color: #9e9e9e; display: flex; flex-direction: column; align-items: center; gap: 8px; }
.pp-empty   { text-align: center; padding: 40px; color: #9e9e9e; }
</style>

<script type="text/javascript">
// @ts-nocheck
var _pagina    = 1;
var _porPagina = 20;
var _total     = 0;
var _buscarTimer = null;

window.addEventListener('DOMContentLoaded', function() {
    // Leer parámetro ?buscar= de la URL si viene del dashboard
    var params = new URLSearchParams(window.location.search);
    var buscarParam = params.get('buscar');
    if (buscarParam) {
        document.getElementById('txBuscar').value = buscarParam;
    }

    // Cargar primera página desde JSON del servidor (evita llamada extra)
    var divJson = document.getElementById('jsonInicial');
    if (divJson && divJson.textContent.trim()) {
        try {
            var inicial = JSON.parse(divJson.textContent.trim());
            _total = inicial.total || 0;
            renderLista(inicial.items || []);
            actualizarPaginacion();
        } catch(e) {
            cargarDesdeServidor();
        }
    } else {
        cargarDesdeServidor();
    }
});

function onBuscarInput() {
    clearTimeout(_buscarTimer);
    _buscarTimer = setTimeout(function() {
        _pagina = 1;
        cargarDesdeServidor();
    }, 350);
}

function aplicarFiltros() {
    _pagina = 1;
    cargarDesdeServidor();
}

function irPagina(delta) {
    _pagina += delta;
    cargarDesdeServidor();
}

function cargarDesdeServidor() {
    var buscar  = document.getElementById('txBuscar').value.trim();
    var estado  = document.getElementById('selEstado').value;

    var url = window.location.pathname
        + '?accion=LISTAR'
        + '&p=' + _pagina
        + '&buscar=' + encodeURIComponent(buscar)
        + '&estado=' + encodeURIComponent(estado);

    document.getElementById('divLista').innerHTML =
        '<div class="pp-loading"><i class="ti ti-loader" style="font-size:24px;opacity:0.4;"></i> Cargando...</div>';

    fetch(url, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
        .then(function(r) { return r.json(); })
        .then(function(data) {
            _total = data.total || 0;
            renderLista(data.items || []);
            actualizarPaginacion();
        })
        .catch(function() {
            document.getElementById('divLista').innerHTML =
                '<div class="pp-empty">Error al cargar. Intente de nuevo.</div>';
        });
}

function renderLista(items) {
    var div = document.getElementById('divLista');
    var spTotal = document.getElementById('spTotal');

    if (spTotal) {
        spTotal.textContent = _total + ' resultado' + (_total === 1 ? '' : 's');
    }

    if (!items || items.length === 0) {
        div.innerHTML = '<div class="pp-empty"><i class="ti ti-inbox" style="font-size:36px;display:block;margin-bottom:8px;opacity:0.3;"></i>Sin resultados</div>';
        return;
    }

    var html = '';
    for (var i = 0; i < items.length; i++) {
        var d = items[i];
        html += '<a class="pp-fila" href="PrePedido_Detalle.aspx?id=' + d.prepedido_id + '">';
        html += '  <div class="pp-main">';

        // Línea 1: código + estado
        html += '    <div class="pp-top">';
        html += '      <span class="pp-cod">' + esc(d.codigo) + '</span>';
        html += '      ' + badgeEstado(d.estado);
        html += '    </div>';

        // Línea 2: nombre + celular
        html += '    <div class="pp-mid">';
        html += '      <span class="pp-nom">' + esc(d.cliente_nombre || 'Sin nombre') + '</span>';
        html += '      <span class="pp-sub"><i class="ti ti-device-mobile"></i> ' + esc(d.cliente_celular) + '</span>';
        html += '    </div>';

        // Línea 3: token + estado pago
        html += '    <div class="pp-bot">';
        html += '      ' + htmlToken(d.token_web, d.token_expira, d.estado);
        html += '      ' + badgePago(d.estado_pago, d.pago_verificado_por);
        html += '    </div>';

        html += '  </div>';

        // Derecha: monto + fecha
        html += '  <div class="pp-right">';
        html += '    <span class="pp-monto">' + fmt(d.total_general_bs) + ' Bs</span>';
        html += '    <span class="pp-fecha">' + fmtFecha(d.creado_en) + '</span>';
        html += '  </div>';

        html += '  <i class="ti ti-chevron-right pp-chevron"></i>';
        html += '</a>';
    }
    div.innerHTML = html;
}

function actualizarPaginacion() {
    var totalPags = Math.ceil(_total / _porPagina);
    var divPag = document.getElementById('divPaginacion');
    var spPag  = document.getElementById('spPagina');
    var btnAnt = document.getElementById('btnAnterior');
    var btnSig = document.getElementById('btnSiguiente');

    if (totalPags <= 1) {
        if (divPag) divPag.style.display = 'none';
        return;
    }

    if (divPag) divPag.style.display = 'flex';
    if (spPag)  spPag.textContent = 'Pág. ' + _pagina + ' / ' + totalPags;
    if (btnAnt) btnAnt.disabled = (_pagina <= 1);
    if (btnSig) btnSig.disabled = (_pagina >= totalPags);
}

/* ---- Helpers de presentación ---- */
function badgeEstado(estado) {
    var m = {
        'BORRADOR':       '<span class="ppb ppb-borrador"><span class="ppb-dot" style="background:#888780"></span>Borrador</span>',
        'FORM_ENVIADO':   '<span class="ppb ppb-form"><span class="ppb-dot" style="background:#185FA5"></span>Form enviado</span>',
        'COMPLETADO':     '<span class="ppb ppb-completado"><span class="ppb-dot" style="background:#3B6D11"></span>Completado</span>',
        'ESPERANDO_PAGO': '<span class="ppb ppb-esp"><span class="ppb-dot" style="background:#854F0B"></span>Esperando pago</span>',
        'PAGADO':         '<span class="ppb ppb-pagado"><span class="ppb-dot" style="background:#3B6D11"></span>Pagado</span>',
        'CONVERTIDO':     '<span class="ppb ppb-convertido"><span class="ppb-dot" style="background:#534AB7"></span>Convertido</span>',
        'CANCELADO':      '<span class="ppb ppb-cancelado"><span class="ppb-dot" style="background:#A32D2D"></span>Cancelado</span>'
    };
    return m[estado] || '<span class="ppb ppb-borrador">' + esc(estado) + '</span>';
}

function htmlToken(tokenWeb, tokenExpira, estado) {
    if (!tokenWeb || estado === 'BORRADOR') {
        return '<span class="tk-none"><i class="ti ti-link-off"></i> Sin enviar</span>';
    }
    if (estado === 'COMPLETADO' || estado === 'ESPERANDO_PAGO' || estado === 'PAGADO' || estado === 'CONVERTIDO') {
        return '<span class="tk-ok"><i class="ti ti-circle-check"></i> Cliente llenó</span>';
    }
    if (tokenExpira) {
        var expira = new Date(tokenExpira);
        var ahora  = new Date();
        if (expira < ahora) {
            return '<span class="tk-vencido"><i class="ti ti-clock-x"></i> Token vencido</span>';
        }
        var difH = Math.round((expira - ahora) / 3600000);
        return '<span class="tk-activo"><i class="ti ti-clock"></i> Vence en ' + difH + 'h</span>';
    }
    return '<span class="tk-none"><i class="ti ti-link-off"></i> Sin token</span>';
}

function badgePago(estadoPago, verificadoPor) {
    if (estadoPago === 'VERIFICADO') {
        return '<span class="ppb ppb-verif"><span class="ppb-dot" style="background:#3B6D11"></span>Pago verificado</span>';
    }
    if (estadoPago === 'PENDIENTE') {
        return '<span class="ppb ppb-pendpago"><span class="ppb-dot" style="background:#854F0B"></span>Comprobante enviado</span>';
    }
    if (estadoPago === 'RECHAZADO') {
        return '<span class="ppb ppb-rech"><span class="ppb-dot" style="background:#A32D2D"></span>Pago rechazado</span>';
    }
    return '<span class="ppb ppb-sinpago"><span class="ppb-dot" style="background:#888780"></span>Sin pago</span>';
}

function fmt(v) {
    if (!v) return '0.00';
    return parseFloat(v).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function fmtFecha(s) {
    if (!s) return '';
    var d = new Date(s);
    var meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return d.getDate() + ' ' + meses[d.getMonth()];
}

function esc(v) {
    if (!v) return '';
    return String(v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
</script>
</asp:Content>
