<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="ProductosPrecios.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Catalogo_ProductosPrecios" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Modificar Precios
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    Modificación masiva de precios
</asp:Content>

<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
    .precios-toolbar { display:flex; gap:10px; align-items:center; flex-wrap:wrap; margin-bottom:14px; }
    .precios-toolbar .stat { background:#f5f5f5; padding:6px 12px; border-radius:6px; font-size:13px; }
    .precios-toolbar .stat strong { color:#1976d2; }
    .input-precio { width:110px; text-align:right; }
    .input-precio.modificado { background:#fff8e1; border-color:#f9a825; font-weight:600; }
    .input-precio.exito { background:#e8f5e9; border-color:#43a047; }
    .input-precio.error { background:#ffebee; border-color:#e53935; }
    .barra-progreso { height:8px; background:#eeeeee; border-radius:4px; overflow:hidden; margin-top:8px; display:none; }
    .barra-progreso > div { height:100%; background:#1976d2; width:0%; transition:width .25s; }
    .progreso-texto { font-size:13px; color:#616161; margin-top:6px; display:none; }
    #divResumen { display:none; margin-top:14px; }
    .fila-error-msg { font-size:11px; color:#e53935; margin-top:2px; }
    .badge-pequeno { font-size:11px; padding:2px 6px; }
</style>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

<div class="alerta" id="divAlerta"></div>

<div class="panel">
  <div class="panel-head">
    <div class="panel-title">Modificar precios masivamente</div>
  </div>
  <div class="panel-body">

    <!-- FILTROS -->
    <div class="panel-filters">
      <div class="filter-group">
        <input type="text" id="txBuscar" class="form-control" placeholder="Buscar por nombre o SKU..." style="min-width:240px"/>
      </div>
      <div class="filter-group">
        <select id="ddCategoria" class="form-control" style="min-width:240px">
          <%=CategoriasOptionsHtml%>
        </select>
      </div>
      <div class="filter-group">
        <select id="ddEstado" class="form-control" style="min-width:140px">
          <option value="1">Solo activos</option>
          <option value="0">Solo inactivos</option>
          <option value="">Todos</option>
        </select>
      </div>
      <div class="filter-group">
        <button type="button" class="btn btn-secondary" onclick="buscarProductos()">
          <i class="ti ti-search"></i> Buscar
        </button>
      </div>
    </div>

    <!-- TOOLBAR DE EJECUCION -->
    <div class="precios-toolbar">
      <div class="stat">Total filas: <strong id="lblTotal">0</strong></div>
      <div class="stat">Modificados: <strong id="lblModificados">0</strong></div>
      <div style="flex:1"></div>
      <button type="button" class="btn btn-secondary" onclick="resetearCambios()" id="btnResetear" style="display:none">
        <i class="ti ti-restore"></i> Descartar cambios
      </button>
      <button type="button" class="btn btn-primary" onclick="ejecutarCambios()" id="btnEjecutar" disabled>
        <i class="ti ti-cloud-upload"></i> Ejecutar cambios
      </button>
    </div>

    <!-- BARRA DE PROGRESO -->
    <div class="barra-progreso" id="barraProgreso"><div></div></div>
    <div class="progreso-texto" id="progresoTexto">Procesando...</div>

    <!-- RESUMEN -->
    <div id="divResumen" class="alerta"></div>

    <!-- TABLA -->
    <div class="table-container">
      <table class="table">
        <thead>
          <tr>
            <th style="width:50px"></th>
            <th>Producto</th>
            <th style="width:140px">Categoría</th>
            <th style="width:90px;text-align:center">Estado</th>
            <th style="width:130px;text-align:right">Precio actual (Bs)</th>
            <th style="width:140px;text-align:right">Nuevo precio (Bs)</th>
            <th style="width:120px">WC sync</th>
          </tr>
        </thead>
        <tbody id="tbodyProductos">
          <%=TablaHtml%>
        </tbody>
      </table>
    </div>

  </div>
</div>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

// ================================================
// MODIFICACION MASIVA DE PRECIOS
// ================================================

// Recargar tabla con filtros
function buscarProductos() {
    var buscar = document.getElementById('txBuscar');
    var cat    = document.getElementById('ddCategoria');
    var est    = document.getElementById('ddEstado');
    if (!buscar || !cat || !est) return;

    var url = 'ProductosPrecios.aspx?b=' + encodeURIComponent(buscar.value || '') +
              '&cat=' + encodeURIComponent(cat.value || '') +
              '&activo=' + encodeURIComponent(est.value || '');
    window.location.href = url;
}

// Enter en input buscar
(function () {
    var b = document.getElementById('txBuscar');
    if (b) {
        b.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') { e.preventDefault(); buscarProductos(); }
        });
    }
})();

// Inicializar contadores
function refrescarContadores() {
    var inputs = document.querySelectorAll('input.input-precio');
    var modificados = 0;
    for (var i = 0; i < inputs.length; i++) {
        var inp = inputs[i];
        var actual  = parseFloat(inp.getAttribute('data-precio-actual') || '0');
        var ingresado = parseFloat(inp.value || '0');
        if (!isNaN(ingresado) && ingresado > 0 && Math.abs(ingresado - actual) > 0.001) {
            modificados++;
            inp.classList.add('modificado');
        } else {
            inp.classList.remove('modificado');
        }
    }
    var lblT = document.getElementById('lblTotal');
    var lblM = document.getElementById('lblModificados');
    var btn  = document.getElementById('btnEjecutar');
    var btnR = document.getElementById('btnResetear');
    if (lblT) lblT.textContent = inputs.length;
    if (lblM) lblM.textContent = modificados;
    if (btn)  btn.disabled = (modificados === 0);
    if (btnR) btnR.style.display = (modificados === 0) ? 'none' : '';
}

// Listener en cada input
function vincularInputs() {
    var inputs = document.querySelectorAll('input.input-precio');
    for (var i = 0; i < inputs.length; i++) {
        inputs[i].addEventListener('input', refrescarContadores);
    }
    refrescarContadores();
}
vincularInputs();

// Descartar cambios = recargar pagina con mismos filtros
function resetearCambios() {
    if (!confirm('¿Descartar todos los cambios sin guardar?')) return;
    var inputs = document.querySelectorAll('input.input-precio');
    for (var i = 0; i < inputs.length; i++) {
        inputs[i].value = inputs[i].getAttribute('data-precio-actual');
        inputs[i].classList.remove('modificado','exito','error');
        var err = document.getElementById('err_' + inputs[i].getAttribute('data-pid'));
        if (err) err.textContent = '';
    }
    refrescarContadores();
    var res = document.getElementById('divResumen');
    if (res) { res.style.display = 'none'; res.textContent = ''; }
}

// ================================================
// EJECUTAR CAMBIOS - AJAX UNO POR UNO
// ================================================
function ejecutarCambios() {
    var inputs = document.querySelectorAll('input.input-precio');
    var pendientes = [];
    for (var i = 0; i < inputs.length; i++) {
        var inp = inputs[i];
        var actual    = parseFloat(inp.getAttribute('data-precio-actual') || '0');
        var ingresado = parseFloat(inp.value || '0');
        if (isNaN(ingresado) || ingresado <= 0) continue;
        if (Math.abs(ingresado - actual) <= 0.001) continue;

        pendientes.push({
            pid:    inp.getAttribute('data-pid'),
            nombre: inp.getAttribute('data-nombre'),
            precio: ingresado.toFixed(2),
            input:  inp
        });
    }

    if (pendientes.length === 0) {
        mostrarAlertaLocal('No hay cambios para ejecutar.', 'warn');
        return;
    }

    if (!confirm('Se van a actualizar ' + pendientes.length + ' producto(s).\n\n' +
                 'Para cada uno: primero se actualiza en WooCommerce y solo si responde OK,\n' +
                 'se actualiza en la base de datos.\n\n¿Continuar?')) {
        return;
    }

    // Bloquear UI
    var btn = document.getElementById('btnEjecutar');
    var btnR = document.getElementById('btnResetear');
    if (btn) btn.disabled = true;
    if (btnR) btnR.disabled = true;

    var barra = document.getElementById('barraProgreso');
    var barraInt = barra ? barra.querySelector('div') : null;
    var txt = document.getElementById('progresoTexto');
    if (barra) barra.style.display = '';
    if (txt) txt.style.display = '';

    var total = pendientes.length;
    var idx = 0;
    var exitos = 0;
    var errores = 0;
    var errMsgs = [];

    function siguiente() {
        if (idx >= total) {
            finalizar();
            return;
        }
        var item = pendientes[idx];
        if (txt) txt.textContent = 'Procesando ' + (idx + 1) + ' de ' + total + ': ' + item.nombre;
        if (barraInt) barraInt.style.width = Math.round(((idx) / total) * 100) + '%';

        var fd = new FormData();
        fd.append('producto_id', item.pid);
        fd.append('precio_base_bs', item.precio);

        var xhr = new XMLHttpRequest();
        xhr.open('POST', 'ProductosPrecios_Handler.ashx', true);
        xhr.timeout = 60000; // 60s por producto (WC puede tardar)
        xhr.onload = function () {
            var resp = null;
            try { resp = JSON.parse(xhr.responseText); } catch (e) {}

            if (xhr.status === 200 && resp && resp.ok) {
                item.input.classList.remove('modificado','error');
                item.input.classList.add('exito');
                item.input.setAttribute('data-precio-actual', item.precio);
                // Actualizar columna "precio actual" en la misma fila
                var tdActual = document.getElementById('actual_' + item.pid);
                if (tdActual) tdActual.textContent = 'Bs ' + parseFloat(item.precio).toFixed(2);
                // Actualizar badge sync
                var tdSync = document.getElementById('sync_' + item.pid);
                if (tdSync) tdSync.innerHTML = '<span class="badge badge-sync-ok badge-pequeno">Sincronizado</span>';
                exitos++;
            } else {
                item.input.classList.remove('modificado','exito');
                item.input.classList.add('error');
                var msg = (resp && resp.mensaje) ? resp.mensaje : ('HTTP ' + xhr.status);
                var err = document.getElementById('err_' + item.pid);
                if (err) err.textContent = msg;
                errMsgs.push(item.nombre + ': ' + msg);
                errores++;
            }
            idx++;
            siguiente();
        };
        xhr.onerror = function () {
            item.input.classList.remove('modificado','exito');
            item.input.classList.add('error');
            var err = document.getElementById('err_' + item.pid);
            if (err) err.textContent = 'Error de red';
            errMsgs.push(item.nombre + ': Error de red');
            errores++;
            idx++;
            siguiente();
        };
        xhr.ontimeout = function () {
            item.input.classList.remove('modificado','exito');
            item.input.classList.add('error');
            var err = document.getElementById('err_' + item.pid);
            if (err) err.textContent = 'Timeout (WC no respondió en 60s)';
            errMsgs.push(item.nombre + ': Timeout');
            errores++;
            idx++;
            siguiente();
        };
        xhr.send(fd);
    }

    function finalizar() {
        if (barraInt) barraInt.style.width = '100%';
        if (txt) txt.textContent = 'Finalizado: ' + exitos + ' actualizados, ' + errores + ' con error.';
        var res = document.getElementById('divResumen');
        if (res) {
            var clase = (errores === 0) ? 'alerta-ok' : (exitos === 0 ? 'alerta-error' : 'alerta-warn');
            res.className = 'alerta show ' + clase;
            var html = '<strong>' + exitos + ' actualizados</strong>';
            if (errores > 0) {
                html += ' / <strong>' + errores + ' con error</strong><br>';
                html += '<small>' + errMsgs.slice(0, 5).join(' · ');
                if (errMsgs.length > 5) html += ' · ...y ' + (errMsgs.length - 5) + ' más';
                html += '</small>';
            }
            res.innerHTML = html;
            res.style.display = '';
        }
        if (btnR) btnR.disabled = false;
        refrescarContadores(); // re-deshabilita btnEjecutar si ya no hay modificados
    }

    siguiente();
}

function mostrarAlertaLocal(msg, tipo) {
    var d = document.getElementById('divAlerta');
    if (!d) return;
    d.className = 'alerta show alerta-' + tipo;
    d.textContent = msg;
    setTimeout(function () {
        var x = document.getElementById('divAlerta');
        if (x) x.className = 'alerta';
    }, 4000);
}
</script>
</asp:Content>
