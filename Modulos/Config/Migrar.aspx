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
                <button type="button" class="btn btn-sm btn-primary" id="btnMigrarPed" onclick="migrarPedidos()">
                    <i class="ti ti-cloud-download"></i> Migrar pedidos
                </button>
                <button type="button" class="btn btn-sm" id="btnDetenerPed" onclick="detenerMigracion()" style="display:none">
                    <i class="ti ti-player-stop"></i> Detener
                </button>
            </div>
        </div>
        <div class="panel-body">

            <!-- Filtros -->
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

            <div class="form-group" style="margin-bottom:14px">
                <label class="form-label">Estado en WooCommerce</label>
                <select id="selEstadoWC" class="form-control">
                    <option value="any" selected>Todos los estados (recomendado)</option>
                    <option value="processing">processing (pagados)</option>
                    <option value="pending">pending (pendientes de pago)</option>
                    <option value="on-hold">on-hold (en espera)</option>
                    <option value="completed">completed (completados)</option>
                    <option value="entregado">entregado</option>
                    <option value="cancelled">cancelled (cancelados)</option>
                    <option value="failed">failed (fallidos)</option>
                </select>
            </div>

            <!-- Barra de progreso -->
            <div id="divProgresoPed" style="display:none;margin-bottom:14px">
                <div style="font-size:12px;color:#757575;margin-bottom:4px" id="spProgTxtPed">Procesando...</div>
                <div style="height:8px;background:#f0f0f0;border-radius:4px;overflow:hidden">
                    <div id="barProgPed" style="height:100%;background:var(--rosa);width:0;transition:width .3s"></div>
                </div>
            </div>

            <!-- Contadores en tiempo real -->
            <div id="divResPed" style="display:none;margin-bottom:14px">
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

            <!-- Log visible de lo que esta pasando -->
            <div id="divLogPed" style="display:none;margin-top:12px">
                <div style="font-size:11px;font-weight:500;color:#757575;margin-bottom:4px">
                    <i class="ti ti-terminal"></i> Log de migracion:
                </div>
                <div id="logPedContenido"
                     style="font-family:monospace;font-size:11px;background:#f8f8f8;border:1px solid #e0e0e0;
                            border-radius:6px;padding:8px 10px;max-height:220px;overflow-y:auto;
                            line-height:1.6">
                </div>
            </div>

        </div>
    </div>

    <!-- Hidden fields y boton postback — el lote es PEQUENO (20 pedidos max) -->
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

//  PEDIDOS — arquitectura de lotes con persistencia
//  IMPORTANTE: ASP.NET hace postback que recarga la pagina, las variables
//  JS se pierden. Por eso guardamos estado en sessionStorage.
// -------------------------------------------------------
var _pedPag        = 0;
var _pedTotalPags  = 0;
var _pedTotal      = 0;
var _pedDesde      = '';
var _pedHasta      = '';
var _pedEstado     = '';
var _pedDetener    = false;
var _pedIns        = 0;
var _pedAct        = 0;
var _pedSin        = 0;
var _pedErr        = 0;
var _pedProcesados = 0;

// --- Persistencia para sobrevivir al postback ---
function guardarEstadoPed() {
    try {
        sessionStorage.setItem('pedEstado', JSON.stringify({
            pag: _pedPag, tot: _pedTotal, totPags: _pedTotalPags,
            desde: _pedDesde, hasta: _pedHasta, est: _pedEstado,
            ins: _pedIns, act: _pedAct, sin: _pedSin, err: _pedErr,
            procesados: _pedProcesados,
            corriendo: true,
            log: document.getElementById('logPedContenido') ? document.getElementById('logPedContenido').innerHTML : ''
        }));
    } catch(e) { console.error('guardarEstadoPed:', e); }
}

function restaurarEstadoPed() {
    try {
        var raw = sessionStorage.getItem('pedEstado');
        if (!raw) return false;
        var s = JSON.parse(raw);
        if (!s || !s.corriendo) return false;
        _pedPag = s.pag; _pedTotal = s.tot; _pedTotalPags = s.totPags;
        _pedDesde = s.desde; _pedHasta = s.hasta; _pedEstado = s.est;
        _pedIns = s.ins; _pedAct = s.act; _pedSin = s.sin; _pedErr = s.err;
        _pedProcesados = s.procesados;

        document.getElementById('divProgresoPed').style.display = '';
        document.getElementById('divResPed').style.display      = '';
        document.getElementById('divLogPed').style.display      = '';
        document.getElementById('btnMigrarPed').style.display   = 'none';
        document.getElementById('btnDetenerPed').style.display  = '';
        if (s.log) document.getElementById('logPedContenido').innerHTML = s.log;
        actualizarContadores();
        return true;
    } catch(e) { console.error('restaurarEstadoPed:', e); return false; }
}

function limpiarEstadoPed() {
    try { sessionStorage.removeItem('pedEstado'); } catch(e) {}
}

function migrarPedidos() {
    if (!validarCredenciales()) return;

    _pedDesde  = document.getElementById('txPedFechaDesde').value;
    _pedHasta  = document.getElementById('txPedFechaHasta').value;
    _pedEstado = document.getElementById('selEstadoWC').value;

    if (!_pedDesde || !_pedHasta) {
        mostrarAlerta('Selecciona el rango de fechas', 'warn');
        return;
    }

    // Reset
    _pedPag = 0; _pedTotalPags = 0; _pedTotal = 0; _pedDetener = false;
    _pedIns = 0; _pedAct = 0; _pedSin = 0; _pedErr = 0; _pedProcesados = 0;
    limpiarEstadoPed();

    document.getElementById('divProgresoPed').style.display = '';
    document.getElementById('divResPed').style.display      = '';
    document.getElementById('divLogPed').style.display      = '';
    document.getElementById('logPedContenido').innerHTML    = '';
    document.getElementById('btnMigrarPed').style.display   = 'none';
    document.getElementById('btnDetenerPed').style.display  = '';

    actualizarBarra(0, 'Obteniendo total de pedidos...');
    actualizarContadores();

    // Paso 1: obtener total
    var params = '?per_page=1&after=' + _pedDesde + 'T00:00:00&before=' + _pedHasta + 'T23:59:59';
    if (_pedEstado !== 'any') params += '&status=' + _pedEstado;

    var xhr = new XMLHttpRequest();
    xhr.open('GET', WC_URL + '/wp-json/wc/v3/orders' + params, true);
    xhr.setRequestHeader('Authorization', authHeader());
    xhr.timeout = 15000;
    xhr.onload = function() {
        if (xhr.status !== 200) {
            agregarLog('ERROR HTTP ' + xhr.status + ' al obtener total', 'error');
            finalizarMigracion(true);
            return;
        }
        try {
            _pedTotal     = parseInt(xhr.getResponseHeader('X-WP-Total') || '0');
            _pedTotalPags = Math.ceil(_pedTotal / 20);
            if (_pedTotal === 0) {
                agregarLog('No se encontraron pedidos en el rango indicado.', 'warn');
                finalizarMigracion(false);
                return;
            }
            agregarLog('Total: ' + _pedTotal + ' pedidos en ' + _pedTotalPags + ' paginas', 'info');
            _pedPag = 1;
            procesarSiguienteLote();
        } catch(e) {
            agregarLog('ERROR al parsear respuesta: ' + e.message, 'error');
            finalizarMigracion(true);
        }
    };
    xhr.onerror   = function() { agregarLog('ERROR de conexion al obtener total', 'error'); finalizarMigracion(true); };
    xhr.ontimeout = function() { agregarLog('TIMEOUT al obtener total', 'error'); finalizarMigracion(true); };
    xhr.send();
}

function procesarSiguienteLote() {
    if (_pedDetener) {
        agregarLog('Migracion detenida por el usuario en pagina ' + _pedPag, 'warn');
        finalizarMigracion(false);
        return;
    }
    if (_pedPag > _pedTotalPags) {
        finalizarMigracion(false);
        return;
    }

    var pct = Math.round(((_pedPag - 1) / _pedTotalPags) * 100);
    actualizarBarra(pct, 'Pagina ' + _pedPag + ' de ' + _pedTotalPags + ' — descargando...');

    var params = '?per_page=20&page=' + _pedPag +
        '&after=' + _pedDesde + 'T00:00:00&before=' + _pedHasta + 'T23:59:59';
    if (_pedEstado !== 'any') params += '&status=' + _pedEstado;

    var xhr = new XMLHttpRequest();
    xhr.open('GET', WC_URL + '/wp-json/wc/v3/orders' + params, true);
    xhr.setRequestHeader('Authorization', authHeader());
    xhr.timeout = 30000;
    xhr.onload = function() {
        if (xhr.status !== 200) {
            agregarLog('WARN pagina ' + _pedPag + ' HTTP ' + xhr.status + ' — saltando', 'warn');
            _pedPag++;
            procesarSiguienteLote();
            return;
        }
        try {
            var lote = JSON.parse(xhr.responseText);
            if (!lote || lote.length === 0) {
                _pedPag++;
                procesarSiguienteLote();
                return;
            }
            agregarLog('Pagina ' + _pedPag + ': ' + lote.length + ' pedidos descargados — enviando al servidor...', 'info');
            actualizarBarra(pct, 'Pagina ' + _pedPag + ' de ' + _pedTotalPags + ' — guardando en BD...');
            enviarLoteAlServidor(lote);
        } catch(e) {
            agregarLog('ERROR parseando pagina ' + _pedPag + ': ' + e.message, 'error');
            _pedPag++;
            procesarSiguienteLote();
        }
    };
    xhr.onerror   = function() { agregarLog('ERROR de red en pagina ' + _pedPag, 'error'); _pedPag++; procesarSiguienteLote(); };
    xhr.ontimeout = function() { agregarLog('TIMEOUT en pagina ' + _pedPag, 'warn');        _pedPag++; procesarSiguienteLote(); };
    xhr.send();
}

function enviarLoteAlServidor(lote) {
    try {
        // Guardar estado ANTES del postback para que se restaure despues
        guardarEstadoPed();
        setHd('hdLote',   JSON.stringify(lote));
        setHd('hdAccion', 'INSERTAR_PEDIDOS');
        document.getElementById('<%= btnPostBack.ClientID %>').click();
    } catch(e) {
        agregarLog('ERROR CRITICO enviando lote al servidor: ' + e.message, 'error');
        _pedErr += lote.length;
        actualizarContadores();
        _pedPag++;
        procesarSiguienteLote();
    }
}

function detenerMigracion() {
    _pedDetener = true;
    agregarLog('Deteniendo despues del lote actual...', 'warn');
    document.getElementById('btnDetenerPed').disabled = true;
}

function recibirResultadoLote(ins, act, sin, err, detalle) {
    _pedIns += ins;
    _pedAct += act;
    _pedSin += sin;
    _pedErr += err;
    _pedProcesados += (ins + act + sin + err);

    var color = err > 0 ? 'error' : (ins + act > 0 ? 'ok' : 'info');
    var msg = 'Pagina ' + _pedPag + ' lista: ';
    if (ins > 0) msg += ins + ' nuevos ';
    if (act > 0) msg += act + ' actualizados ';
    if (sin > 0) msg += sin + ' sin cambios ';
    if (err > 0) msg += err + ' ERRORES';
    if (detalle) msg += ' [' + detalle + ']';
    agregarLog(msg, color);

    actualizarContadores();
    _pedPag++;

    // Guardar estado actualizado antes de seguir con el siguiente lote
    guardarEstadoPed();
    procesarSiguienteLote();
}

function finalizarMigracion(huboError) {
    actualizarBarra(100, 'Completado — ' + _pedProcesados + ' pedidos procesados de ' + _pedTotal);
    document.getElementById('btnMigrarPed').style.display  = '';
    document.getElementById('btnDetenerPed').style.display = 'none';
    limpiarEstadoPed();

    var tipo = huboError ? 'warn' : (_pedErr > 0 ? 'warn' : 'ok');
    var msg  = 'Migracion finalizada: ' + _pedIns + ' nuevos, ' + _pedAct + ' actualizados, ' + _pedSin + ' sin cambios';
    if (_pedErr > 0) msg += ', ' + _pedErr + ' con errores (ver log)';
    mostrarAlerta(msg, tipo);
    agregarLog('=== FIN: ' + msg + ' ===', tipo === 'ok' ? 'ok' : 'warn');
}

function actualizarContadores() {
    document.getElementById('cntPedNuevos').textContent       = String(_pedIns);
    document.getElementById('cntPedActualizados').textContent = String(_pedAct);
    document.getElementById('cntPedSinCambios').textContent   = String(_pedSin);
    document.getElementById('cntPedErrores').textContent      = String(_pedErr);
}

function agregarLog(msg, tipo) {
    var log = document.getElementById('logPedContenido');
    if (!log) return;
    var colores = { 'ok':'#388e3c', 'error':'#c62828', 'warn':'#e65100', 'info':'#1565c0' };
    var color = colores[tipo] || '#424242';
    var hora  = new Date().toLocaleTimeString('es-BO', {hour:'2-digit', minute:'2-digit', second:'2-digit'});
    var linea = document.createElement('div');
    linea.style.color = color;
    linea.textContent = '[' + hora + '] ' + msg;
    log.appendChild(linea);
    log.scrollTop = log.scrollHeight;
}

function actualizarBarra(pct, txt) {
    var b = document.getElementById('barProgPed');
    var t = document.getElementById('spProgTxtPed');
    if (b) b.style.width = pct + '%';
    if (t) t.textContent = txt;
}

// Auto-restauracion al cargar la pagina (despues de postback)
if (typeof window !== 'undefined') {
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            if (restaurarEstadoPed()) {
                // El estado se restauro — esperamos que el servidor llame recibirResultadoLote()
                // Si por alguna razon no llega (error en server), forzamos siguiente lote
                setTimeout(function() {
                    // Si despues de 2 segundos no se llamo a recibirResultadoLote, asumimos error
                    var ahora = (_pedIns + _pedAct + _pedSin + _pedErr);
                    if (ahora === _pedProcesados) {
                        // No hubo cambios desde el guardado → el servidor probablemente fallo en silencio
                        agregarLog('AVISO: Servidor no respondio en pagina ' + _pedPag + ' — saltando', 'warn');
                        _pedErr += 1;
                        actualizarContadores();
                        _pedPag++;
                        procesarSiguienteLote();
                    }
                }, 3000);
            }
        });
    } else {
        if (restaurarEstadoPed()) {
            setTimeout(function() {
                var ahora = (_pedIns + _pedAct + _pedSin + _pedErr);
                if (ahora === _pedProcesados) {
                    agregarLog('AVISO: Servidor no respondio en pagina ' + _pedPag + ' — saltando', 'warn');
                    _pedErr += 1;
                    actualizarContadores();
                    _pedPag++;
                    procesarSiguienteLote();
                }
            }, 3000);
        }
    }
}

// Llamada legacy
function mostrarResultadoPed(ins, act, sin, err) {
    recibirResultadoLote(ins, act, sin, err, '');
}
</script>
</asp:Content>
