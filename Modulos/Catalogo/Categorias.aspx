<%@ Page Language="VB" AutoEventWireup="true" CodeBehind="Categorias.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Catalogo_Categorias" MasterPageFile="~/Site.master" %>

<asp:Content ContentPlaceHolderID="CssExtra" runat="server">
<style>
/* === ESTILOS PROPIOS DE CATEGORIAS === */
.content{padding:20px;display:grid;grid-template-columns:1fr 300px;gap:16px;align-items:start}
.panel{background:white;border:1px solid #e0e0e0;border-radius:10px;overflow:hidden}
.panel-head{padding:12px 16px;border-bottom:1px solid #e0e0e0;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px}
.panel-title{font-size:14px;font-weight:500}
.stats-bar{display:flex;gap:16px;padding:8px 16px;border-bottom:1px solid #e0e0e0;background:#fafafa}
.stat-item{font-size:12px;color:#757575}
.stat-item strong{color:#424242;font-weight:500}
.buscar-bar{display:flex;gap:8px;padding:10px 16px;border-bottom:1px solid #e0e0e0}
.form-control{padding:7px 10px;border:1px solid #e0e0e0;border-radius:8px;font-size:13px;background:white;color:#424242;outline:none;transition:border-color .2s;width:100%}
.form-control:focus{border-color:#C2185B}
.campo-error{border-color:#C62828!important}
.campo-ok{border-color:#2E7D32!important}
.form-error{font-size:11px;color:#C62828;margin-top:3px;display:none}
.form-error.show{display:block}
.btn{padding:7px 14px;border-radius:8px;font-size:13px;border:1px solid #e0e0e0;background:white;color:#424242;cursor:pointer;display:inline-flex;align-items:center;gap:6px;transition:background .15s}
.btn:hover{background:#f5f5f5}
.btn-primary{background:#C2185B;border-color:#C2185B;color:white}
.btn-primary:hover{background:#880E4F}
.btn-danger{background:#FFEBEE;border-color:#C62828;color:#C62828}
.btn-warn{background:#FFF3E0;border-color:#F57C00;color:#E65100}
.cargando-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.55);z-index:9999;align-items:center;justify-content:center;flex-direction:column;gap:16px}
.cargando-overlay.show{display:flex}
.cargando-spinner{width:48px;height:48px;border:4px solid rgba(255,255,255,.3);border-top-color:#fff;border-radius:50%;animation:spin .8s linear infinite}
.cargando-texto{color:#fff;font-size:14px;font-weight:500;text-align:center;max-width:280px;line-height:1.4}
@keyframes spin{to{transform:rotate(360deg)}}
.btn-prod{background:#E6F1FB;border-color:#185FA5;color:#0C447C}
.btn-prod:hover{background:#D4E6F8}
.btn-sm{padding:4px 9px;font-size:12px}
.arbol{padding:4px 0;min-height:200px}
.nodo-fila{display:flex;align-items:center;gap:6px;padding:7px 12px;border-bottom:0.5px solid #f5f5f5;cursor:default;transition:background .12s;position:relative}
.nodo-fila:hover{background:#FFF8FB}
.nodo-fila.drag-sobre{border-top:2px solid #C2185B;background:#FCE4EC}
.nodo-fila.arrastrando{opacity:.5;background:#f5f5f5}
.drag-handle{color:#ccc;font-size:15px;cursor:grab;flex-shrink:0;padding:2px}
.drag-handle:hover{color:#9e9e9e}
.toggle-btn{width:20px;height:20px;border:none;background:none;cursor:pointer;color:#9e9e9e;display:flex;align-items:center;justify-content:center;border-radius:4px;flex-shrink:0;font-size:13px}
.toggle-btn:hover{background:#f0f0f0}
.toggle-esp{width:20px;flex-shrink:0}
.nodo-nombre{flex:1;font-size:13px;min-width:0}
.nodo-desc{font-size:11px;color:#9e9e9e;display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.nodo-acciones{display:flex;gap:4px;margin-left:auto;flex-shrink:0}
.nodo-hijos{border-left:2px solid #FCE4EC;margin-left:20px}
.nodo-hijos.cerrado{display:none}
.nivel-1{padding-left:20px}.nivel-2{padding-left:36px}.nivel-3{padding-left:52px}.nivel-4{padding-left:68px}
.badge{padding:2px 7px;border-radius:12px;font-size:10px;font-weight:500;flex-shrink:0}
.badge-sync{background:#E8F5E9;color:#2E7D32}
.badge-pend{background:#FFF3E0;color:#E65100}
.badge-inac{background:#f5f5f5;color:#9e9e9e}
.badge-prod{background:#E6F1FB;color:#0C447C}
.form-panel{background:white;border:1px solid #e0e0e0;border-radius:10px;overflow:hidden;position:sticky;top:68px}
.form-head{padding:12px 16px;border-bottom:1px solid #e0e0e0}
.form-title{font-size:14px;font-weight:500}
.form-body{padding:16px;display:flex;flex-direction:column;gap:12px}
.form-group{display:flex;flex-direction:column;gap:4px}
.form-label{font-size:12px;font-weight:500;color:#616161}
.req{color:#C2185B}
.form-help{font-size:11px;color:#9e9e9e}
.form-foot{padding:12px 16px;border-top:1px solid #e0e0e0;display:flex;gap:8px;justify-content:flex-end;background:#fafafa}
.modal-bg{display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:200;align-items:center;justify-content:center}
.modal-bg.show{display:flex}
.modal{background:white;border-radius:12px;width:100%;max-width:440px}
.modal-head{padding:14px 18px;border-bottom:1px solid #e0e0e0;display:flex;justify-content:space-between;align-items:center}
.modal-title{font-size:15px;font-weight:500}
.modal-close{background:none;border:none;font-size:20px;cursor:pointer;color:#9e9e9e}
.modal-body{padding:18px}
.modal-foot{padding:12px 18px;border-top:1px solid #e0e0e0;display:flex;gap:8px;justify-content:flex-end;background:#fafafa}
@media(max-width:768px){.content{grid-template-columns:1fr}.form-panel{position:static}}
</style>
</asp:Content>

<asp:Content ContentPlaceHolderID="TopbarTitulo" runat="server">
  <i class="ti ti-tag" style="font-size:17px;vertical-align:-3px;margin-right:8px;color:#C2185B" aria-hidden="true"></i>
  Categorias de productos
</asp:Content>

<asp:Content ContentPlaceHolderID="Contenido" runat="server">

  <div class="panel">
    <div class="panel-head">
      <div class="panel-title">Arbol de categorias</div>
      <div style="display:flex;gap:8px;flex-wrap:wrap">
        <button type="button" class="btn btn-sm" onclick="expandirTodo()"><i class="ti ti-arrows-vertical" style="font-size:13px" aria-hidden="true"></i> Expandir todo</button>
        <button type="button" class="btn btn-sm" onclick="contraerTodo()"><i class="ti ti-arrows-minimize" style="font-size:13px" aria-hidden="true"></i> Contraer</button>
        <button type="button" class="btn btn-primary btn-sm" onclick="nuevaCategoria()"><i class="ti ti-plus" style="font-size:13px" aria-hidden="true"></i> Nueva</button>
      </div>
    </div>
    <div class="stats-bar">
      <span class="stat-item">Total: <strong><%=TotalCategorias%></strong></span>
      <span class="stat-item">Sin productos: <strong><%=SinProductos%></strong></span>
      <span class="stat-item">Pendiente sync: <strong><%=PendienteSync%></strong></span>
    </div>
    <div class="buscar-bar">
      <input type="text" id="txBuscar" class="form-control" style="flex:1" placeholder="Buscar categoria..." oninput="filtrarArbol(this.value)"/>
    </div>
    <div class="alerta" id="divAlertaArbol" style="margin:10px 16px 0"></div>
    <div class="arbol" id="divArbol"><%=ArbolHtml%></div>
  </div>

  <div class="form-panel" id="formPanel">
    <div class="form-head"><div class="form-title" id="formTitulo">Nueva categoria</div></div>
    <div class="form-body">
      <div class="alerta" id="divAlertaForm"></div>
      <div class="form-group">
        <label class="form-label">Nombre <span class="req">*</span></label>
        <input type="text" id="txNombre" class="form-control" placeholder="Ej: Ramos de rosas" maxlength="150"/>
        <div class="form-error" id="errNombre">Ingrese el nombre (solo letras, numeros y espacios).</div>
      </div>
      <div class="form-group">
        <label class="form-label">Descripcion</label>
        <textarea id="txDesc" class="form-control" rows="3" placeholder="Descripcion breve..." maxlength="500" style="resize:vertical"></textarea>
      </div>
      <div class="form-group">
        <label class="form-label">Categoria padre</label>
        <select id="selPadre" class="form-control"><option value="0">Sin padre (nivel raiz)</option></select>
        <div class="form-help">Define en que nivel del arbol aparece.</div>
      </div>
      <div class="form-group">
        <label class="form-label">Slug</label>
        <input type="text" id="txSlug" class="form-control" placeholder="se-genera-automatico" maxlength="160"/>
        <div class="form-help">Para WooCommerce. Se genera automatico si lo dejas vacio.</div>
      </div>
    </div>
    <div class="form-foot">
      <button type="button" class="btn btn-sm" onclick="limpiarForm()">Cancelar</button>
      <button type="button" class="btn btn-warn btn-sm" id="btnBajaMasiva" style="display:none" onclick="abrirBajaMasiva()"><i class="ti ti-package-off" style="font-size:13px" aria-hidden="true"></i> Dar de baja</button>
      <button type="button" class="btn btn-sm" id="btnHabilitar" style="display:none;background:#E8F5E9;border-color:#2E7D32;color:#2E7D32" onclick="abrirHabilitar()"><i class="ti ti-package" style="font-size:13px" aria-hidden="true"></i> Habilitar productos</button>
      <button type="button" class="btn btn-primary btn-sm" onclick="guardarCategoria()"><i class="ti ti-device-floppy" style="font-size:13px" aria-hidden="true"></i> Guardar</button>
    </div>
  </div>

  <!-- MODALES -->
  <div class="modal-bg" id="modalBaja">
    <div class="modal">
      <div class="modal-head"><div class="modal-title">Dar de baja productos</div><button type="button" class="modal-close" onclick="cerrarModal()">&times;</button></div>
      <div class="modal-body">
        <div class="alerta alerta-warn show" style="margin-bottom:12px">Todos los productos de esta categoria quedaran inactivos. Esta accion se sincronizara con WooCommerce.</div>
        <div class="form-group">
          <label class="form-label">Motivo <span class="req">*</span></label>
          <input type="text" id="txMotivoBaja" class="form-control" placeholder="Minimo 5 caracteres..." maxlength="300"/>
          <div class="form-error" id="errMotivoBaja">El motivo es obligatorio (min. 5 caracteres).</div>
        </div>
      </div>
      <div class="modal-foot"><button type="button" class="btn btn-sm" onclick="cerrarModal()">Cancelar</button><button type="button" class="btn btn-danger btn-sm" onclick="confirmarBajaMasiva()"><i class="ti ti-package-off" style="font-size:13px" aria-hidden="true"></i> Confirmar baja</button></div>
    </div>
  </div>

  <div class="modal-bg" id="modalHabilitar">
    <div class="modal">
      <div class="modal-head"><div class="modal-title">Habilitar productos</div><button type="button" class="modal-close" onclick="cerrarModalHabilitar()">&times;</button></div>
      <div class="modal-body">
        <div class="alerta alerta-info show" style="margin-bottom:12px">Todos los productos inactivos de esta categoria quedaran activos y se sincronizaran con WooCommerce.</div>
        <div class="form-group">
          <label class="form-label">Motivo <span class="req">*</span></label>
          <input type="text" id="txMotivoHabilitar" class="form-control" placeholder="Minimo 5 caracteres..." maxlength="300"/>
          <div class="form-error" id="errMotivoHabilitar">El motivo es obligatorio (min. 5 caracteres).</div>
        </div>
      </div>
      <div class="modal-foot"><button type="button" class="btn btn-sm" onclick="cerrarModalHabilitar()">Cancelar</button><button type="button" class="btn btn-sm" style="background:#E8F5E9;border-color:#2E7D32;color:#2E7D32" onclick="confirmarHabilitar()"><i class="ti ti-package" style="font-size:13px" aria-hidden="true"></i> Confirmar</button></div>
    </div>
  </div>

  <div class="modal-bg" id="modalEliminar">
    <div class="modal">
      <div class="modal-head"><div class="modal-title">Eliminar categoria</div><button type="button" class="modal-close" onclick="cerrarModalEliminar()">&times;</button></div>
      <div class="modal-body">
        <div class="alerta alerta-error show" style="margin-bottom:12px">Solo se puede eliminar si no tiene subcategorias ni productos asignados.</div>
        <div class="form-group">
          <label class="form-label">Motivo <span class="req">*</span></label>
          <input type="text" id="txMotivoElim" class="form-control" placeholder="Minimo 5 caracteres..." maxlength="300"/>
          <div class="form-error" id="errMotivoElim">El motivo es obligatorio (min. 5 caracteres).</div>
        </div>
      </div>
      <div class="modal-foot"><button type="button" class="btn btn-sm" onclick="cerrarModalEliminar()">Cancelar</button><button type="button" class="btn btn-danger btn-sm" onclick="confirmarEliminar()"><i class="ti ti-trash" style="font-size:13px" aria-hidden="true"></i> Eliminar</button></div>
    </div>
  </div>

  <!-- HIDDEN FIELDS -->
  <input type="hidden" id="hdAccion"    name="hdAccion"    value=""/>
  <input type="hidden" id="hdCatId"     name="hdCatId"     value=""/>
  <input type="hidden" id="hdPadreId"   name="hdPadreId"   value=""/>
  <input type="hidden" id="hdNombre"    name="hdNombre"    value=""/>
  <input type="hidden" id="hdDesc"      name="hdDesc"      value=""/>
  <input type="hidden" id="hdSlug"      name="hdSlug"      value=""/>
  <input type="hidden" id="hdMotivo"    name="hdMotivo"    value=""/>
  <input type="hidden" id="hdOrdenJson" name="hdOrdenJson" value=""/>
  <asp:Button ID="btnPostBack" runat="server" Text="" Style="display:none" OnClick="btnAccion_Click"/>
  <div id="jsonListaCats" style="display:none"><%=ListaCatsJson%></div>
  <div class="cargando-overlay" id="cargandoOverlay">
    <div class="cargando-spinner"></div>
    <div class="cargando-texto" id="cargandoTexto">Procesando...</div>
  </div>

</asp:Content>

<asp:Content ContentPlaceHolderID="ScriptsExtra" runat="server">
<script>
// @ts-nocheck
var catActualId = 0;
var modoEdicion = false;
var dragSrcId = 0;
var dragOverId = 0;

/** @type {Array<{id:number, nombre:string, indent:string}>} */
var listaCats = [];
(function () {
    var dj = document.getElementById('jsonListaCats');
    if (dj) { try { listaCats = JSON.parse(dj.textContent || dj.innerText || '[]'); } catch (ex) { listaCats = []; } }
    poblarSelectPadre(0);
})();

function poblarSelectPadre(excluirId) {
    var sel = /** @type {HTMLSelectElement} */ (document.getElementById('selPadre'));
    if (!sel) { return; }
    sel.innerHTML = '<option value="0">Sin padre (nivel raiz)</option>';
    for (var i = 0; i < listaCats.length; i++) {
        var cat = listaCats[i];
        if (cat.id !== excluirId) {
            var opt = document.createElement('option');
            opt.value = String(cat.id);
            opt.textContent = cat.indent + cat.nombre;
            sel.appendChild(opt);
        }
    }
}

function limpiar(v) { return String(v).replace(/[<>"';\\]/g, '').trim(); }
function soloNombresValidos(v) { return /^[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s\-\/\.]+$/.test(String(v).trim()); }
function setHd(id, val) { var el = /** @type {HTMLInputElement} */ (document.getElementById(String(id))); if (el) { el.value = String(val); } }
function getVal(id) { var el = /** @type {HTMLInputElement} */ (document.getElementById(String(id))); return el ? el.value : ''; }
function mostrarCargando(texto) { var ov = document.getElementById('cargandoOverlay'); var tx = document.getElementById('cargandoTexto'); if (tx) { tx.textContent = String(texto); } if (ov) { ov.className = 'cargando-overlay show'; } }
function marcar(id, estado) { var el = document.getElementById(String(id)); if (el) { el.className = 'form-control' + (estado === 'error' ? ' campo-error' : estado === 'ok' ? ' campo-ok' : ''); } }
function mostrarErr(id, show) { var el = document.getElementById(String(id)); if (el) { el.className = show ? 'form-error show' : 'form-error'; } }

function nuevaCategoria() {
    modoEdicion = false; catActualId = 0; limpiarForm();
    var elTit = document.getElementById('formTitulo');
    var elBaja = /** @type {HTMLElement} */ (document.getElementById('btnBajaMasiva'));
    var elHab = /** @type {HTMLElement} */ (document.getElementById('btnHabilitar'));
    if (elTit) { elTit.textContent = 'Nueva categoria'; }
    if (elBaja) { elBaja.style.display = 'none'; }
    if (elHab) { elHab.style.display = 'none'; }
    poblarSelectPadre(0);
    var elN = /** @type {HTMLInputElement} */ (document.getElementById('txNombre'));
    if (elN) { elN.focus(); }
}

function verProductos(id) { window.location.href = 'Categoria_Productos.aspx?id=' + String(id); }

function editarCategoria(id, padreId, nombre, desc, slug) {
    modoEdicion = true; catActualId = id; limpiarForm();
    var elTit = document.getElementById('formTitulo');
    var elBaja = /** @type {HTMLElement} */ (document.getElementById('btnBajaMasiva'));
    var elHab = /** @type {HTMLElement} */ (document.getElementById('btnHabilitar'));
    var selP = /** @type {HTMLSelectElement} */ (document.getElementById('selPadre'));
    var elN = /** @type {HTMLInputElement} */ (document.getElementById('txNombre'));
    var elDesc = /** @type {HTMLTextAreaElement} */ (document.getElementById('txDesc'));
    var elSlug = /** @type {HTMLInputElement} */ (document.getElementById('txSlug'));
    if (elTit) { elTit.textContent = 'Editar: ' + String(nombre); }
    if (elBaja) { elBaja.style.display = ''; }
    if (elHab) { elHab.style.display = ''; }
    poblarSelectPadre(id);
    if (selP) { selP.value = String(padreId); }
    if (elN) { elN.value = String(nombre); }
    if (elDesc) { elDesc.value = String(desc); }
    if (elSlug) { elSlug.value = String(slug); }
}

function limpiarForm() {
    marcar('txNombre', ''); marcar('txSlug', ''); mostrarErr('errNombre', false);
    var elN = /** @type {HTMLInputElement} */ (document.getElementById('txNombre'));
    var elDesc = /** @type {HTMLTextAreaElement} */ (document.getElementById('txDesc'));
    var elSlug = /** @type {HTMLInputElement} */ (document.getElementById('txSlug'));
    var selP = /** @type {HTMLSelectElement} */ (document.getElementById('selPadre'));
    var elD = document.getElementById('divAlertaForm');
    if (elN) { elN.value = ''; } if (elDesc) { elDesc.value = ''; } if (elSlug) { elSlug.value = ''; }
    if (selP) { selP.value = '0'; } if (elD) { elD.className = 'alerta'; }
}

function guardarCategoria() {
    var nombre = limpiar(getVal('txNombre'));
    var desc = limpiar(getVal('txDesc'));
    var slug = limpiar(getVal('txSlug'));
    var selP = /** @type {HTMLSelectElement} */ (document.getElementById('selPadre'));
    var padreId = selP ? selP.value : '0';
    if (nombre.length < 2 || !soloNombresValidos(nombre)) { marcar('txNombre', 'error'); mostrarErr('errNombre', true); return; }
    marcar('txNombre', 'ok'); mostrarErr('errNombre', false);
    setHd('hdAccion', modoEdicion ? 'EDITAR' : 'CREAR'); setHd('hdCatId', String(catActualId));
    setHd('hdPadreId', padreId); setHd('hdNombre', nombre); setHd('hdDesc', desc); setHd('hdSlug', slug);
    setHd('hdMotivo', 'Guardado desde interfaz');
    mostrarCargando('Guardando categoria y sincronizando con WooCommerce...');
    var btn = document.getElementById('btnPostBack'); if (btn) { btn.click(); }
}

function abrirBajaMasiva() { var elM = document.getElementById('modalBaja'); var elT = /** @type {HTMLInputElement} */ (document.getElementById('txMotivoBaja')); if (elM) { elM.className = 'modal-bg show'; } if (elT) { elT.value = ''; } mostrarErr('errMotivoBaja', false); }
function cerrarModal() { var elM = document.getElementById('modalBaja'); if (elM) { elM.className = 'modal-bg'; } }
function confirmarBajaMasiva() { var motivo = limpiar(getVal('txMotivoBaja')); if (motivo.length < 5) { mostrarErr('errMotivoBaja', true); return; } mostrarErr('errMotivoBaja', false); setHd('hdAccion', 'BAJA_MASIVA'); setHd('hdCatId', String(catActualId)); setHd('hdMotivo', motivo); cerrarModal(); mostrarCargando('Dando de baja productos y sincronizando con WooCommerce...'); var btn = document.getElementById('btnPostBack'); if (btn) { btn.click(); } }

function abrirEliminar(id) { catActualId = id; var elM = document.getElementById('modalEliminar'); var elT = /** @type {HTMLInputElement} */ (document.getElementById('txMotivoElim')); if (elM) { elM.className = 'modal-bg show'; } if (elT) { elT.value = ''; } mostrarErr('errMotivoElim', false); }
function cerrarModalEliminar() { var elM = document.getElementById('modalEliminar'); if (elM) { elM.className = 'modal-bg'; } }
function confirmarEliminar() { var motivo = limpiar(getVal('txMotivoElim')); if (motivo.length < 5) { mostrarErr('errMotivoElim', true); return; } mostrarErr('errMotivoElim', false); setHd('hdAccion', 'ELIMINAR'); setHd('hdCatId', String(catActualId)); setHd('hdMotivo', motivo); cerrarModalEliminar(); mostrarCargando('Eliminando categoria...'); var btn = document.getElementById('btnPostBack'); if (btn) { btn.click(); } }

function toggleNodo(id) { var el = document.getElementById('h_' + String(id)); var ico = document.getElementById('ico_' + String(id)); if (!el) { return; } if (el.className.indexOf('cerrado') >= 0) { el.className = 'nodo-hijos'; if (ico) { ico.className = 'ti ti-chevron-down ico-toggle'; } } else { el.className = 'nodo-hijos cerrado'; if (ico) { ico.className = 'ti ti-chevron-right ico-toggle'; } } }
function expandirTodo() { var h = document.querySelectorAll('.nodo-hijos'); for (var i = 0; i < h.length; i++) { /** @type {HTMLElement} */ (h[i]).className = 'nodo-hijos'; } var ic = document.querySelectorAll('.ico-toggle'); for (var j = 0; j < ic.length; j++) { /** @type {HTMLElement} */ (ic[j]).className = 'ti ti-chevron-down ico-toggle'; } }
function contraerTodo() { var h = document.querySelectorAll('.nodo-hijos'); for (var i = 0; i < h.length; i++) { /** @type {HTMLElement} */ (h[i]).className = 'nodo-hijos cerrado'; } var ic = document.querySelectorAll('.ico-toggle'); for (var j = 0; j < ic.length; j++) { /** @type {HTMLElement} */ (ic[j]).className = 'ti ti-chevron-right ico-toggle'; } }
function filtrarArbol(texto) { var txt = String(texto).toLowerCase().trim(); var filas = document.querySelectorAll('.nodo-fila'); for (var i = 0; i < filas.length; i++) { var fila = /** @type {HTMLElement} */ (filas[i]); fila.style.display = (txt === '' || (fila.getAttribute('data-nombre') || '').indexOf(txt) >= 0) ? '' : 'none'; } }
function onDragStart(e, id) { var ev =/** @type {DragEvent} */(e); dragSrcId = id; var f =/** @type {HTMLElement} */(document.getElementById('fila_' + String(id))); if (f) { f.className = f.className + ' arrastrando'; } if (ev.dataTransfer) { ev.dataTransfer.effectAllowed = 'move'; } }
function onDragEnd(id) { var f =/** @type {HTMLElement} */(document.getElementById('fila_' + String(id))); if (f) { f.className = f.className.replace(' arrastrando', ''); } limpiarDragOver(); }
function onDragOver(e, id) { var ev =/** @type {DragEvent} */(e); ev.preventDefault(); if (dragOverId !== id) { limpiarDragOver(); dragOverId = id; var f =/** @type {HTMLElement} */(document.getElementById('fila_' + String(id))); if (f) { f.className = f.className + ' drag-sobre'; } } }
function onDrop(e, padreDestino, orden) { var ev =/** @type {DragEvent} */(e); ev.preventDefault(); limpiarDragOver(); if (dragSrcId === 0 || dragSrcId === padreDestino) { return; } setHd('hdAccion', 'REORDENAR'); setHd('hdCatId', String(dragSrcId)); setHd('hdPadreId', String(padreDestino)); setHd('hdOrdenJson', String(orden)); setHd('hdMotivo', 'Reordenamiento drag and drop'); var btn = document.getElementById('btnPostBack'); if (btn) { btn.click(); } }
function limpiarDragOver() { if (dragOverId > 0) { var f =/** @type {HTMLElement} */(document.getElementById('fila_' + String(dragOverId))); if (f) { f.className = f.className.replace(' drag-sobre', ''); } dragOverId = 0; } }
function abrirHabilitar() { var elM = document.getElementById('modalHabilitar'); var elT =/** @type {HTMLInputElement} */(document.getElementById('txMotivoHabilitar')); if (elM) { elM.className = 'modal-bg show'; } if (elT) { elT.value = ''; } mostrarErr('errMotivoHabilitar', false); }
function cerrarModalHabilitar() { var elM = document.getElementById('modalHabilitar'); if (elM) { elM.className = 'modal-bg'; } }
function confirmarHabilitar() { var motivo = limpiar(getVal('txMotivoHabilitar')); if (motivo.length < 5) { mostrarErr('errMotivoHabilitar', true); return; } mostrarErr('errMotivoHabilitar', false); setHd('hdAccion', 'HABILITAR'); setHd('hdCatId', String(catActualId)); setHd('hdMotivo', motivo); cerrarModalHabilitar(); mostrarCargando('Habilitando productos y sincronizando con WooCommerce...'); var btn = document.getElementById('btnPostBack'); if (btn) { btn.click(); } }
</script>
</asp:Content>
