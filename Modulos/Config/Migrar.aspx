<%@ Page Language="VB" MasterPageFile="~/Site.Master" 
         AutoEventWireup="false" 
         CodeBehind="Migrar.aspx.vb" 
         Inherits="SISCONBOL_FLORERIA.Modulos_Config_Migrar" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Migrar WooCommerce
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    Migración masiva desde WooCommerce
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    
    <!-- Alertas -->
    <div class="alerta" id="divAlerta"></div>

    <!-- MIGRACION CATEGORIAS -->
    <div class="panel">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-tag"></i> Categorías
            </div>
        </div>
        <div class="panel-body">
            <div id="divResCats" style="display:none;margin-bottom:16px">
                <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-bottom:12px">
                    <div style="padding:12px;border-radius:8px;text-align:center;background:#E8F5E9">
                        <div style="font-size:22px;font-weight:500;color:#2E7D32" id="cntCatNuevas">0</div>
                        <div style="font-size:11px;color:#3B6D11">Nuevas</div>
                    </div>
                    <div style="padding:12px;border-radius:8px;text-align:center;background:#E3F2FD">
                        <div style="font-size:22px;font-weight:500;color:#1976D2" id="cntCatActualizadas">0</div>
                        <div style="font-size:11px;color:#0C447C">Actualizadas</div>
                    </div>
                    <div style="padding:12px;border-radius:8px;text-align:center;background:#F5F5F5">
                        <div style="font-size:22px;font-weight:500" id="cntCatSinCambios">0</div>
                        <div style="font-size:11px;color:#757575">Sin cambios</div>
                    </div>
                    <div style="padding:12px;border-radius:8px;text-align:center;background:#FFEBEE">
                        <div style="font-size:22px;font-weight:500;color:#C62828" id="cntCatErrores">0</div>
                        <div style="font-size:11px;color:#791F1F">Errores</div>
                    </div>
                </div>
            </div>
            <button type="button" class="btn btn-primary" onclick="migrarCategorias()">
                <i class="ti ti-cloud-download"></i> Migrar categorías
            </button>
        </div>
    </div>

    <!-- MIGRACION PRODUCTOS -->
    <div class="panel">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-flower"></i> Productos
            </div>
        </div>
        <div class="panel-body">
            <div id="divProgreso" style="display:none;margin-bottom:16px">
                <div style="font-size:12px;color:#757575;margin-bottom:4px" id="spProgTxt">Procesando...</div>
                <div style="height:8px;background:#f0f0f0;border-radius:4px;overflow:hidden">
                    <div id="barProg" style="height:100%;background:#C2185B;width:0;transition:width .3s"></div>
                </div>
            </div>
            <div id="divResProd" style="display:none;margin-bottom:16px">
                <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-bottom:12px">
                    <div style="padding:12px;border-radius:8px;text-align:center;background:#E8F5E9">
                        <div style="font-size:22px;font-weight:500;color:#2E7D32" id="cntProdNuevos">0</div>
                        <div style="font-size:11px;color:#3B6D11">Nuevos</div>
                    </div>
                    <div style="padding:12px;border-radius:8px;text-align:center;background:#E3F2FD">
                        <div style="font-size:22px;font-weight:500;color:#1976D2" id="cntProdActualizados">0</div>
                        <div style="font-size:11px;color:#0C447C">Actualizados</div>
                    </div>
                    <div style="padding:12px;border-radius:8px;text-align:center;background:#F5F5F5">
                        <div style="font-size:22px;font-weight:500" id="cntProdSinCambios">0</div>
                        <div style="font-size:11px;color:#757575">Sin cambios</div>
                    </div>
                    <div style="padding:12px;border-radius:8px;text-align:center;background:#FFEBEE">
                        <div style="font-size:22px;font-weight:500;color:#C62828" id="cntProdErrores">0</div>
                        <div style="font-size:11px;color:#791F1F">Errores</div>
                    </div>
                </div>
            </div>
            <button type="button" class="btn btn-primary" onclick="migrarProductos()">
                <i class="ti ti-cloud-download"></i> Migrar productos
            </button>
        </div>
    </div>

    <!-- MIGRACION PEDIDOS -->
    <div class="panel">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-shopping-cart"></i> Pedidos
            </div>
        </div>
        <div class="panel-body">
            <div class="alerta alerta-info" style="display:block">
                <i class="ti ti-info-circle"></i>
                La migración de pedidos se habilitará cuando las tablas de pedidos estén creadas en la base de datos.
            </div>
            <button type="button" class="btn" onclick="migrarPedidos()" disabled>
                <i class="ti ti-cloud-download"></i> Migrar pedidos (próximamente)
            </button>
        </div>
    </div>

    <!-- Hidden fields -->
    <input type="hidden" id="hdAccion" name="hdAccion" value=""/>
    <input type="hidden" id="hdLote" name="hdLote" value=""/>
    
    <asp:Button ID="btnPostBack" runat="server" Text="" 
                Style="display:none" OnClick="btnAccion_Click"/>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

// Variables globales desde VB.NET (credenciales de FLORERIA_Config)
var WC_URL = '<%=WcUrl%>';
var WC_CONSUMER_KEY = '<%=WcConsumerKey%>';
var WC_CONSUMER_SECRET = '<%=WcConsumerSecret%>';

function mostrarAlerta(/** @type {string} */ msg, /** @type {string} */ tipo) {
    var d = document.getElementById('divAlerta');
    if (!d) return;
    d.className = 'alerta show alerta-' + tipo;
    d.textContent = msg;
    setTimeout(function() {
        if (tipo !== 'error') {
            d.className = 'alerta';
        }
    }, 8000);
}

function setHd(/** @type {string} */ id, /** @type {string} */ val) {
    var el = /** @type {HTMLInputElement} */ (document.getElementById(id));
    if (el) { el.value = val; }
}

function validarCredenciales() {
    if (!WC_URL || !WC_CONSUMER_KEY || !WC_CONSUMER_SECRET) {
        mostrarAlerta('Primero configura las credenciales de WooCommerce en: Configuración > Configuración', 'error');
        return false;
    }
    return true;
}

// -- MIGRACION CATEGORIAS ---------------------------------------
function migrarCategorias() {
    if (!validarCredenciales()) return;
    
    mostrarAlerta('Descargando categorías desde WooCommerce...', 'info');
    
    var auth = 'Basic ' + btoa(WC_CONSUMER_KEY + ':' + WC_CONSUMER_SECRET);
    var xhr = new XMLHttpRequest();
    xhr.open('GET', WC_URL + '/wp-json/wc/v3/products/categories?per_page=100', true);
    xhr.setRequestHeader('Authorization', auth);
    xhr.timeout = 30000;
    
    xhr.onload = function() {
        if (xhr.status !== 200) {
            mostrarAlerta('Error HTTP ' + xhr.status + ': ' + xhr.statusText + '. Verifica las credenciales en Configuración.', 'error');
            return;
        }
        
        try {
            var cats = JSON.parse(xhr.responseText);
            if (!cats || cats.length === 0) {
                mostrarAlerta('No se encontraron categorías en WooCommerce.', 'warn');
                return;
            }
            
            mostrarAlerta('Descargadas ' + cats.length + ' categorías. Guardando en base de datos...', 'info');
            setHd('hdLote', xhr.responseText);
            setHd('hdAccion', 'INSERTAR_CATEGORIAS');
            var btn = document.getElementById('<%= btnPostBack.ClientID %>');
            if (btn) { btn.click(); }
        } catch (e) {
            mostrarAlerta('Error al procesar respuesta JSON: ' + e.message, 'error');
        }
    };
    
    xhr.onerror = function() {
        mostrarAlerta('Error de conexión con WooCommerce. Verifica la URL en Configuración.', 'error');
    };
    
    xhr.ontimeout = function() {
        mostrarAlerta('Tiempo de espera agotado (30 seg). El servidor no respondió.', 'error');
    };
    
    xhr.send();
}

function mostrarResultadoCats(/** @type {number} */ ins, /** @type {number} */ act, 
                              /** @type {number} */ sin, /** @type {number} */ err) {
    var d = document.getElementById('divResCats');
    if (d) { d.style.display = ''; }
    
    var n = document.getElementById('cntCatNuevas');
    var a = document.getElementById('cntCatActualizadas');
    var s = document.getElementById('cntCatSinCambios');
    var e = document.getElementById('cntCatErrores');
    
    if (n) { n.textContent = String(ins); }
    if (a) { a.textContent = String(act); }
    if (s) { s.textContent = String(sin); }
    if (e) { e.textContent = String(err); }
    
    var total = ins + act;
    var mensaje = 'Migración completada: ' + total + ' categorías procesadas';
    if (err > 0) {
        mensaje += ' (' + err + ' con errores). Revisa la consola de Visual Studio para detalles.';
    }
    mostrarAlerta(mensaje, err > 0 ? 'warn' : 'ok');
}

// -- MIGRACION PRODUCTOS ---------------------------------------
var _mTodos = /** @type {Array<any>} */ ([]);
var _mPag = 0;
var _mTotalPags = 0;

function migrarProductos() {
    if (!validarCredenciales()) return;
    
    _mTodos = [];
    _mPag = 0;
    
    var d = document.getElementById('divProgreso');
    if (d) { d.style.display = ''; }
    actualizarBarra(0, 'Obteniendo total de productos...');
    
    var auth = 'Basic ' + btoa(WC_CONSUMER_KEY + ':' + WC_CONSUMER_SECRET);
    var xhr = new XMLHttpRequest();
    xhr.open('GET', WC_URL + '/wp-json/wc/v3/products?per_page=1', true);
    xhr.setRequestHeader('Authorization', auth);
    xhr.timeout = 15000;
    
    xhr.onload = function() {
        if (xhr.status !== 200) {
            mostrarAlerta('Error HTTP ' + xhr.status + ': ' + xhr.statusText, 'error');
            var d2 = document.getElementById('divProgreso');
            if (d2) { d2.style.display = 'none'; }
            return;
        }
        
        try {
            var totalHeader = xhr.getResponseHeader('X-WP-Total');
            var total = totalHeader ? parseInt(totalHeader) : 0;
            
            if (total === 0) {
                mostrarAlerta('No se encontraron productos en WooCommerce.', 'warn');
                var d2 = document.getElementById('divProgreso');
                if (d2) { d2.style.display = 'none'; }
                return;
            }
            
            _mTotalPags = Math.ceil(total / 20);
            actualizarBarra(0, 'Descargando ' + total + ' productos (página 1 de ' + _mTotalPags + ')...');
            _mPag = 1;
            descargarPaginaProd();
        } catch (e) {
            mostrarAlerta('Error: ' + e.message, 'error');
        }
    };
    
    xhr.onerror = function() {
        mostrarAlerta('Error de conexión con WooCommerce.', 'error');
        var d2 = document.getElementById('divProgreso');
        if (d2) { d2.style.display = 'none'; }
    };
    
    xhr.ontimeout = function() {
        mostrarAlerta('Tiempo de espera agotado.', 'error');
        var d2 = document.getElementById('divProgreso');
        if (d2) { d2.style.display = 'none'; }
    };
    
    xhr.send();
}

function descargarPaginaProd() {
    var auth = 'Basic ' + btoa(WC_CONSUMER_KEY + ':' + WC_CONSUMER_SECRET);
    var xhr = new XMLHttpRequest();
    xhr.open('GET', WC_URL + '/wp-json/wc/v3/products?per_page=20&page=' + _mPag, true);
    xhr.setRequestHeader('Authorization', auth);
    xhr.timeout = 30000;
    
    xhr.onload = function() {
        if (xhr.status !== 200) {
            _mPag++;
            if (_mPag > _mTotalPags) {
                enviarAlServidor();
            } else {
                descargarPaginaProd();
            }
            return;
        }
        
        try {
            var lote = JSON.parse(xhr.responseText);
            _mTodos = _mTodos.concat(lote);
            var pct = Math.round((_mPag / _mTotalPags) * 50);
            actualizarBarra(pct, 'Descargados ' + _mTodos.length + ' productos (página ' + _mPag + ' de ' + _mTotalPags + ')...');
            
            if (lote.length < 20 || _mPag >= _mTotalPags) {
                enviarAlServidor();
            } else {
                _mPag++;
                descargarPaginaProd();
            }
        } catch (e) {
            mostrarAlerta('Error al parsear respuesta: ' + e.message, 'error');
        }
    };
    
    xhr.onerror = function() {
        _mPag++;
        if (_mPag > _mTotalPags) {
            enviarAlServidor();
        } else {
            descargarPaginaProd();
        }
    };
    
    xhr.ontimeout = function() {
        mostrarAlerta('Tiempo agotado en página ' + _mPag, 'warn');
        _mPag++;
        if (_mPag > _mTotalPags) {
            enviarAlServidor();
        } else {
            descargarPaginaProd();
        }
    };
    
    xhr.send();
}

function enviarAlServidor() {
    actualizarBarra(55, 'Insertando ' + _mTodos.length + ' productos en base de datos...');
    setHd('hdLote', JSON.stringify(_mTodos));
    setHd('hdAccion', 'INSERTAR_PRODUCTOS');
    var btn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (btn) { btn.click(); }
}

function actualizarBarra(/** @type {number} */ pct, /** @type {string} */ txt) {
    var b = document.getElementById('barProg');
    var t = document.getElementById('spProgTxt');
    if (b) { b.style.width = pct + '%'; }
    if (t) { t.textContent = txt; }
}

function mostrarResultadoProd(/** @type {number} */ ins, /** @type {number} */ act, 
                              /** @type {number} */ sin, /** @type {number} */ err) {
    actualizarBarra(100, 'Completado');
    var d = document.getElementById('divResProd');
    if (d) { d.style.display = ''; }
    
    var n = document.getElementById('cntProdNuevos');
    var a = document.getElementById('cntProdActualizados');
    var s = document.getElementById('cntProdSinCambios');
    var e = document.getElementById('cntProdErrores');
    
    if (n) { n.textContent = String(ins); }
    if (a) { a.textContent = String(act); }
    if (s) { s.textContent = String(sin); }
    if (e) { e.textContent = String(err); }
    
    var total = ins + act;
    var mensaje = 'Migración completada: ' + total + ' productos procesados';
    if (err > 0) {
        mensaje += ' (' + err + ' con errores). Revisa la consola de Visual Studio para detalles.';
    }
    mostrarAlerta(mensaje, err > 0 ? 'warn' : 'ok');
}

// -- MIGRACION PEDIDOS ---------------------------------------
function migrarPedidos() {
    mostrarAlerta('La migración de pedidos aún no está implementada. Se habilitará cuando las tablas de pedidos estén creadas en la base de datos.', 'info');
}
</script>
</asp:Content>
