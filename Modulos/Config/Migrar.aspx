<%@ Page Language="VB" MasterPageFile="~/Site.Master"
         AutoEventWireup="false"
         CodeBehind="Migrar.aspx.vb"
         Inherits="SISCONBOL_FLORERIA.Modulos_Config_Migrar" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Migrar WooCommerce
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-cloud-download" style="vertical-align:-2px"></i> Migracion masiva desde WooCommerce
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Alerta global -->
    <div class="alerta" id="divAlerta"></div>

    <!-- ============================================================ -->
    <!-- PANEL: CATEGORIAS                                            -->
    <!-- ============================================================ -->
    <div class="panel" style="margin-bottom:16px">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-tag"></i> Categorias
            </div>
            <div class="panel-actions">
                <button type="button" class="btn btn-sm btn-primary" onclick="migrarCategorias()">
                    <i class="ti ti-cloud-download"></i> Migrar categorias
                </button>
            </div>
        </div>
        <div class="panel-body">
            <div id="divResCats" style="display:none">
                <div class="grid-4">
                    <div class="stat g">
                        <div class="stat-lbl">Nuevas</div>
                        <div class="stat-val" id="cntCatNuevas">0</div>
                    </div>
                    <div class="stat b">
                        <div class="stat-lbl">Actualizadas</div>
                        <div class="stat-val" id="cntCatActualizadas">0</div>
                    </div>
                    <div class="stat">
                        <div class="stat-lbl">Sin cambios</div>
                        <div class="stat-val" id="cntCatSinCambios">0</div>
                    </div>
                    <div class="stat r">
                        <div class="stat-lbl">Errores</div>
                        <div class="stat-val" id="cntCatErrores">0</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- ============================================================ -->
    <!-- PANEL: PRODUCTOS                                             -->
    <!-- ============================================================ -->
    <div class="panel" style="margin-bottom:16px">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-flower"></i> Productos
            </div>
            <div class="panel-actions">
                <button type="button" class="btn btn-sm btn-primary" onclick="migrarProductos()">
                    <i class="ti ti-cloud-download"></i> Migrar productos
                </button>
            </div>
        </div>
        <div class="panel-body">
            <div id="divProgreso" style="display:none;margin-bottom:14px">
                <div style="font-size:12px;color:#757575;margin-bottom:4px" id="spProgTxt">Procesando...</div>
                <div style="height:8px;background:#f0f0f0;border-radius:4px;overflow:hidden">
                    <div id="barProg" style="height:100%;background:var(--rosa);width:0;transition:width .3s"></div>
                </div>
            </div>
            <div id="divResProd" style="display:none">
                <div class="grid-4">
                    <div class="stat g">
                        <div class="stat-lbl">Nuevos</div>
                        <div class="stat-val" id="cntProdNuevos">0</div>
                    </div>
                    <div class="stat b">
                        <div class="stat-lbl">Actualizados</div>
                        <div class="stat-val" id="cntProdActualizados">0</div>
                    </div>
                    <div class="stat">
                        <div class="stat-lbl">Sin cambios</div>
                        <div class="stat-val" id="cntProdSinCambios">0</div>
                    </div>
                    <div class="stat r">
                        <div class="stat-lbl">Errores</div>
                        <div class="stat-val" id="cntProdErrores">0</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- ============================================================ -->
    <!-- PANEL: PEDIDOS                                               -->
    <!-- ============================================================ -->
    <div class="panel" style="margin-bottom:16px">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-shopping-cart"></i> Pedidos
            </div>
            <div class="panel-actions">
                <button type="button" class="btn btn-sm btn-primary" onclick="migrarPedidos()">
                    <i class="ti ti-cloud-download"></i> Migrar pedidos
                </button>
            </div>
        </div>
        <div class="panel-body">

            <!-- Filtros de fecha -->
            <div class="grid-2" style="margin-bottom:14px">
                <div class="form-group">
                    <label class="form-label">Desde fecha</label>
                    <input type="date" id="txPedFechaDesde" class="form-control"
                           value="<%=FechaDesdeDefault%>" />
                </div>
                <div class="form-group">
                    <label class="form-label">Hasta fecha</label>
                    <input type="date" id="txPedFechaHasta" class="form-control"
                           value="<%=FechaHastaDefault%>" />
                </div>
            </div>

            <!-- Estado WC a filtrar -->
            <div class="form-group" style="margin-bottom:14px">
                <label class="form-label">Estado en WooCommerce</label>
                <select id="selEstadoWC" class="form-control">
                    <option value="any">Todos los estados</option>
                    <option value="processing" selected>processing (pagados)</option>
                    <option value="pending">pending (pendientes de pago)</option>
                    <option value="on-hold">on-hold (en espera)</option>
                    <option value="completed">completed (completados)</option>
                </select>
            </div>

            <!-- Barra de progreso pedidos -->
            <div id="divProgresoPed" style="display:none;margin-bottom:14px">
                <div style="font-size:12px;color:#757575;margin-bottom:4px" id="spProgTxtPed">Procesando...</div>
                <div style="height:8px;background:#f0f0f0;border-radius:4px;overflow:hidden">
                    <div id="barProgPed" style="height:100%;background:var(--rosa);width:0;transition:width .3s"></div>
                </div>
            </div>

            <!-- Resultados pedidos -->
            <div id="divResPed" style="display:none">
                <div class="grid-4">
                    <div class="stat g">
                        <div class="stat-lbl">Nuevos</div>
                        <div class="stat-val" id="cntPedNuevos">0</div>
                    </div>
                    <div class="stat b">
                        <div class="stat-lbl">Actualizados</div>
                        <div class="stat-val" id="cntPedActualizados">0</div>
                    </div>
                    <div class="stat">
                        <div class="stat-lbl">Sin cambios</div>
                        <div class="stat-val" id="cntPedSinCambios">0</div>
                    </div>
                    <div class="stat r">
                        <div class="stat-lbl">Errores</div>
                        <div class="stat-val" id="cntPedErrores">0</div>
                    </div>
                </div>
            </div>

        </div>
    </div>

    <!-- Hidden fields y boton postback -->
    <input type="hidden" id="hdAccion" name="hdAccion" value=""/>
    <input type="hidden" id="hdLote"   name="hdLote"   value=""/>

    <asp:Button ID="btnPostBack" runat="server" Text=""
                Style="display:none" OnClick="btnAccion_Click"/>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

// Credenciales inyectadas desde VB.NET
var WC_URL            = '<%=WcUrl%>';
var WC_CONSUMER_KEY   = '<%=WcConsumerKey%>';
var WC_CONSUMER_SECRET= '<%=WcConsumerSecret%>';

//  HELPERS 
function mostrarAlerta(/** @type {string} */ msg, /** @type {string} */ tipo) {
    var d = document.getElementById('divAlerta');
    if (!d) return;
    d.className = 'alerta show alerta-' + tipo;
    d.textContent = msg;
    if (tipo !== 'error') {
        setTimeout(function() { d.className = 'alerta'; }, 8000);
    }
}

function setHd(/** @type {string} */ id, /** @type {string} */ val) {
    var el = /** @type {HTMLInputElement} */ (document.getElementById(id));
    if (el) el.value = val;
}

function validarCredenciales() {
    if (!WC_URL || !WC_CONSUMER_KEY || !WC_CONSUMER_SECRET) {
        mostrarAlerta('Primero configura las credenciales de WooCommerce en Configuracion > Configuracion', 'error');
        return false;
    }
    return true;
}

function authHeader() {
    return 'Basic ' + btoa(WC_CONSUMER_KEY + ':' + WC_CONSUMER_SECRET);
}

//  CATEGORIAS 
function migrarCategorias() {
    if (!validarCredenciales()) return;
    mostrarAlerta('Descargando categorias desde WooCommerce...', 'info');

    var xhr = new XMLHttpRequest();
    xhr.open('GET', WC_URL + '/wp-json/wc/v3/products/categories?per_page=100', true);
    xhr.setRequestHeader('Authorization', authHeader());
    xhr.timeout = 30000;

    xhr.onload = function() {
        if (xhr.status !== 200) {
            mostrarAlerta('Error HTTP ' + xhr.status + '. Verifica las credenciales en Configuracion.', 'error');
            return;
        }
        try {
            var cats = JSON.parse(xhr.responseText);
            if (!cats || cats.length === 0) {
                mostrarAlerta('No se encontraron categorias en WooCommerce.', 'warn');
                return;
            }
            mostrarAlerta('Descargadas ' + cats.length + ' categorias. Guardando...', 'info');
            setHd('hdLote', xhr.responseText);
            setHd('hdAccion', 'INSERTAR_CATEGORIAS');
            document.getElementById('<%= btnPostBack.ClientID %>').click();
        } catch (e) {
            mostrarAlerta('Error al procesar respuesta: ' + e.message, 'error');
        }
    };
    xhr.onerror   = function() { mostrarAlerta('Error de conexion con WooCommerce.', 'error'); };
    xhr.ontimeout = function() { mostrarAlerta('Tiempo de espera agotado (30s).', 'error'); };
    xhr.send();
}

function mostrarResultadoCats(/** @type {number} */ ins, /** @type {number} */ act,
                               /** @type {number} */ sin, /** @type {number} */ err) {
    document.getElementById('divResCats').style.display = '';
    document.getElementById('cntCatNuevas').textContent      = String(ins);
    document.getElementById('cntCatActualizadas').textContent= String(act);
    document.getElementById('cntCatSinCambios').textContent  = String(sin);
    document.getElementById('cntCatErrores').textContent     = String(err);
    var total = ins + act;
    var msg = 'Migracion completada: ' + total + ' categorias procesadas';
    if (err > 0) msg += ' (' + err + ' con errores)';
    mostrarAlerta(msg, err > 0 ? 'warn' : 'ok');
}

//  PRODUCTOS 
var _mTodos = [];
var _mPag   = 0;
var _mTotalPags = 0;

function migrarProductos() {
    if (!validarCredenciales()) return;
    _mTodos = [];
    _mPag   = 0;
    document.getElementById('divProgreso').style.display = '';
    actualizarBarra(0, 'Obteniendo total de productos...');

    var xhr = new XMLHttpRequest();
    xhr.open('GET', WC_URL + '/wp-json/wc/v3/products?per_page=1', true);
    xhr.setRequestHeader('Authorization', authHeader());
    xhr.timeout = 15000;

    xhr.onload = function() {
        if (xhr.status !== 200) {
            mostrarAlerta('Error HTTP ' + xhr.status, 'error');
            document.getElementById('divProgreso').style.display = 'none';
            return;
        }
        try {
            var total = parseInt(xhr.getResponseHeader('X-WP-Total') || '0');
            if (total === 0) {
                mostrarAlerta('No se encontraron productos en WooCommerce.', 'warn');
                document.getElementById('divProgreso').style.display = 'none';
                return;
            }
            _mTotalPags = Math.ceil(total / 20);
            actualizarBarra(0, 'Descargando ' + total + ' productos (pagina 1 de ' + _mTotalPags + ')...');
            _mPag = 1;
            descargarPaginaProd();
        } catch (e) {
            mostrarAlerta('Error: ' + e.message, 'error');
        }
    };
    xhr.onerror   = function() { mostrarAlerta('Error de conexion.', 'error'); };
    xhr.ontimeout = function() { mostrarAlerta('Tiempo agotado.', 'error'); };
    xhr.send();
}

function descargarPaginaProd() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', WC_URL + '/wp-json/wc/v3/products?per_page=20&page=' + _mPag, true);
    xhr.setRequestHeader('Authorization', authHeader());
    xhr.timeout = 30000;

    xhr.onload = function() {
        if (xhr.status === 200) {
            try {
                var lote = JSON.parse(xhr.responseText);
                _mTodos = _mTodos.concat(lote);
                var pct = Math.round((_mPag / _mTotalPags) * 50);
                actualizarBarra(pct, 'Descargados ' + _mTodos.length + ' productos (pagina ' + _mPag + ' de ' + _mTotalPags + ')...');
                if (lote.length < 20 || _mPag >= _mTotalPags) {
                    enviarProductosAlServidor();
                } else {
                    _mPag++;
                    descargarPaginaProd();
                }
            } catch (e) {
                mostrarAlerta('Error al parsear: ' + e.message, 'error');
            }
        } else {
            _mPag++;
            if (_mPag > _mTotalPags) enviarProductosAlServidor();
            else descargarPaginaProd();
        }
    };
    xhr.onerror   = function() { _mPag++; if (_mPag > _mTotalPags) enviarProductosAlServidor(); else descargarPaginaProd(); };
    xhr.ontimeout = function() { _mPag++; if (_mPag > _mTotalPags) enviarProductosAlServidor(); else descargarPaginaProd(); };
    xhr.send();
}

function enviarProductosAlServidor() {
    actualizarBarra(55, 'Insertando ' + _mTodos.length + ' productos en base de datos...');
    setHd('hdLote', JSON.stringify(_mTodos));
    setHd('hdAccion', 'INSERTAR_PRODUCTOS');
    document.getElementById('<%= btnPostBack.ClientID %>').click();
}

function actualizarBarra(/** @type {number} */ pct, /** @type {string} */ txt) {
    var b = document.getElementById('barProg');
    var t = document.getElementById('spProgTxt');
    if (b) b.style.width = pct + '%';
    if (t) t.textContent = txt;
}

function mostrarResultadoProd(/** @type {number} */ ins, /** @type {number} */ act,
                               /** @type {number} */ sin, /** @type {number} */ err) {
    actualizarBarra(100, 'Completado');
    document.getElementById('divResProd').style.display     = '';
    document.getElementById('cntProdNuevos').textContent     = String(ins);
    document.getElementById('cntProdActualizados').textContent= String(act);
    document.getElementById('cntProdSinCambios').textContent  = String(sin);
    document.getElementById('cntProdErrores').textContent     = String(err);
    var total = ins + act;
    var msg = 'Migracion completada: ' + total + ' productos procesados';
    if (err > 0) msg += ' (' + err + ' con errores)';
    mostrarAlerta(msg, err > 0 ? 'warn' : 'ok');
}

//  PEDIDOS 
var _pedTodos = [];
var _pedPag   = 0;
var _pedTotalPags = 0;

function migrarPedidos() {
    if (!validarCredenciales()) return;

    var desde = document.getElementById('txPedFechaDesde').value;
    var hasta = document.getElementById('txPedFechaHasta').value;
    var estado= document.getElementById('selEstadoWC').value;

    if (!desde || !hasta) {
        mostrarAlerta('Selecciona el rango de fechas', 'warn');
        return;
    }

    _pedTodos = [];
    _pedPag   = 0;
    document.getElementById('divProgresoPed').style.display = '';
    actualizarBarraPed(0, 'Obteniendo total de pedidos...');

    var params = '?per_page=1&after=' + desde + 'T00:00:00&before=' + hasta + 'T23:59:59';
    if (estado !== 'any') params += '&status=' + estado;

    var xhr = new XMLHttpRequest();
    xhr.open('GET', WC_URL + '/wp-json/wc/v3/orders' + params, true);
    xhr.setRequestHeader('Authorization', authHeader());
    xhr.timeout = 15000;

    xhr.onload = function() {
        if (xhr.status !== 200) {
            mostrarAlerta('Error HTTP ' + xhr.status, 'error');
            document.getElementById('divProgresoPed').style.display = 'none';
            return;
        }
        try {
            var total = parseInt(xhr.getResponseHeader('X-WP-Total') || '0');
            if (total === 0) {
                mostrarAlerta('No se encontraron pedidos en el rango indicado.', 'info');
                document.getElementById('divProgresoPed').style.display = 'none';
                return;
            }
            _pedTotalPags = Math.ceil(total / 20);
            actualizarBarraPed(0, 'Descargando ' + total + ' pedidos...');
            _pedPag = 1;
            descargarPaginaPed(desde, hasta, estado);
        } catch (e) {
            mostrarAlerta('Error: ' + e.message, 'error');
        }
    };
    xhr.onerror   = function() { mostrarAlerta('Error de conexion.', 'error'); };
    xhr.ontimeout = function() { mostrarAlerta('Tiempo agotado.', 'error'); };
    xhr.send();
}

function descargarPaginaPed(/** @type {string} */ desde, /** @type {string} */ hasta, /** @type {string} */ estado) {
    var params = '?per_page=20&page=' + _pedPag +
        '&after=' + desde + 'T00:00:00&before=' + hasta + 'T23:59:59';
    if (estado !== 'any') params += '&status=' + estado;

    var xhr = new XMLHttpRequest();
    xhr.open('GET', WC_URL + '/wp-json/wc/v3/orders' + params, true);
    xhr.setRequestHeader('Authorization', authHeader());
    xhr.timeout = 30000;

    xhr.onload = function() {
        if (xhr.status === 200) {
            try {
                var lote = JSON.parse(xhr.responseText);
                _pedTodos = _pedTodos.concat(lote);
                var pct = Math.round((_pedPag / _pedTotalPags) * 50);
                actualizarBarraPed(pct, 'Descargados ' + _pedTodos.length + ' pedidos (pag. ' + _pedPag + ')...');
                if (lote.length < 20 || _pedPag >= _pedTotalPags) {
                    enviarPedidosAlServidor();
                } else {
                    _pedPag++;
                    descargarPaginaPed(desde, hasta, estado);
                }
            } catch (e) {
                mostrarAlerta('Error al parsear pedidos: ' + e.message, 'error');
            }
        } else {
            _pedPag++;
            if (_pedPag > _pedTotalPags) enviarPedidosAlServidor();
            else descargarPaginaPed(desde, hasta, estado);
        }
    };
    xhr.onerror   = function() { _pedPag++; if (_pedPag > _pedTotalPags) enviarPedidosAlServidor(); else descargarPaginaPed(desde, hasta, estado); };
    xhr.ontimeout = function() { _pedPag++; if (_pedPag > _pedTotalPags) enviarPedidosAlServidor(); else descargarPaginaPed(desde, hasta, estado); };
    xhr.send();
}

function enviarPedidosAlServidor() {
    actualizarBarraPed(55, 'Insertando ' + _pedTodos.length + ' pedidos en base de datos...');
    setHd('hdLote', JSON.stringify(_pedTodos));
    setHd('hdAccion', 'INSERTAR_PEDIDOS');
    document.getElementById('<%= btnPostBack.ClientID %>').click();
}

function actualizarBarraPed(/** @type {number} */ pct, /** @type {string} */ txt) {
    var b = document.getElementById('barProgPed');
    var t = document.getElementById('spProgTxtPed');
    if (b) b.style.width = pct + '%';
    if (t) t.textContent = txt;
}

function mostrarResultadoPed(/** @type {number} */ ins, /** @type {number} */ act,
                              /** @type {number} */ sin, /** @type {number} */ err) {
    actualizarBarraPed(100, 'Completado');
    document.getElementById('divResPed').style.display      = '';
    document.getElementById('cntPedNuevos').textContent      = String(ins);
    document.getElementById('cntPedActualizados').textContent = String(act);
    document.getElementById('cntPedSinCambios').textContent   = String(sin);
    document.getElementById('cntPedErrores').textContent      = String(err);
    var total = ins + act;
    var msg = 'Migracion completada: ' + total + ' pedidos procesados';
    if (err > 0) msg += ' (' + err + ' con errores)';
    mostrarAlerta(msg, err > 0 ? 'warn' : 'ok');
}
</script>
</asp:Content>
