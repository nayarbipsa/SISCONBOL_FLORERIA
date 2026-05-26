<%@ Page Language="VB" AutoEventWireup="false" CodeFile="Categoria_Productos.aspx.vb" Inherits="Modulos_Catalogo_Categoria_Productos" %>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SISCONBOL - Productos de Categoria</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/tabler-icons.min.css">
<style>
*{box-sizing:border-box;margin:0;padding:0}
:root{--rosa:#C2185B;--rosa-osc:#880E4F;--rosa-cl:#FCE4EC}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f5f5f5;color:#424242}
.layout{display:flex;min-height:100vh}
.sidebar{width:230px;background:var(--rosa-osc);position:fixed;height:100vh;overflow-y:auto;display:flex;flex-direction:column;z-index:100}
.main{margin-left:230px;flex:1;display:flex;flex-direction:column}
.sb-logo{padding:18px 16px 14px;border-bottom:1px solid rgba(255,255,255,.15)}
.sb-logo-title{font-size:16px;font-weight:600;color:#fff}
.sb-logo-sub{font-size:11px;color:rgba(255,255,255,.6);margin-top:2px}
.sb-user{padding:12px 16px;border-bottom:1px solid rgba(255,255,255,.15);display:flex;align-items:center;gap:8px}
.sb-avatar{width:34px;height:34px;border-radius:50%;background:rgba(255,255,255,.2);display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:600;color:#fff;flex-shrink:0}
.sb-user-name{font-size:13px;font-weight:500;color:#fff}
.sb-user-role{font-size:11px;color:rgba(255,255,255,.6)}
.nav{flex:1;padding:8px 0}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 16px;color:rgba(255,255,255,.8);font-size:13px;cursor:pointer;border-left:3px solid transparent;transition:all .15s;text-decoration:none;background:none;border-top:none;border-right:none;border-bottom:none;width:100%;text-align:left}
.nav-item:hover{background:rgba(255,255,255,.08);color:#fff}
.nav-icon{font-size:17px;flex-shrink:0}
.nav-arrow{margin-left:auto;font-size:13px}
.nav-children{display:none;background:rgba(0,0,0,.15)}
.nav-children.open{display:block}
.nav-child{display:flex;align-items:center;gap:8px;padding:8px 16px 8px 42px;color:rgba(255,255,255,.65);font-size:12px;text-decoration:none;transition:color .15s}
.nav-child:hover{color:#fff}
.sb-footer{padding:12px 16px;border-top:1px solid rgba(255,255,255,.15)}
.btn-logout{display:flex;align-items:center;gap:8px;color:rgba(255,255,255,.6);font-size:12px;cursor:pointer;background:none;border:none;width:100%;text-align:left;padding:0}
.btn-logout:hover{color:#fff}
.topbar{background:white;border-bottom:1px solid #e0e0e0;padding:0 24px;height:52px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:10}
.topbar-title{font-size:15px;font-weight:500;flex:1}
.content{padding:20px}
.panel{background:white;border:1px solid #e0e0e0;border-radius:10px;overflow:hidden;margin-bottom:16px}
.panel-head{padding:12px 18px;border-bottom:1px solid #e0e0e0;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px}
.panel-title{font-size:14px;font-weight:500}
.panel-sub{font-size:11px;color:#9e9e9e;margin-top:2px}
.btn{padding:7px 14px;border-radius:8px;font-size:13px;border:1px solid #e0e0e0;background:white;color:#424242;cursor:pointer;display:inline-flex;align-items:center;gap:6px;transition:background .15s}
.btn:hover{background:#f5f5f5}
.btn-primary{background:#C2185B;border-color:#C2185B;color:white}
.btn-primary:hover{background:#880E4F}
.btn-success{background:#E8F5E9;border-color:#2E7D32;color:#2E7D32}
.btn-danger{background:#FFEBEE;border-color:#C62828;color:#C62828}
.btn-warn{background:#FFF3E0;border-color:#F57C00;color:#E65100}
.btn-info{background:#E6F1FB;border-color:#185FA5;color:#0C447C}
.btn-sm{padding:4px 9px;font-size:12px}
.form-control{padding:8px 10px;border:1px solid #e0e0e0;border-radius:8px;font-size:13px;background:white;color:#424242;outline:none;transition:border-color .2s;width:100%}
.form-control:focus{border-color:#C2185B}
.tabla{width:100%;border-collapse:collapse;font-size:13px}
.tabla th{padding:9px 12px;background:#f5f5f5;font-size:11px;font-weight:500;text-transform:uppercase;letter-spacing:.4px;color:#757575;text-align:left;border-bottom:1px solid #e0e0e0}
.tabla td{padding:9px 12px;border-bottom:1px solid #f0f0f0;vertical-align:middle}
.tabla tr:last-child td{border-bottom:none}
.tabla tr:hover td{background:#FFF8FB}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 8px;border-radius:10px;font-size:11px;font-weight:500}
.badge-cat{background:#E6F1FB;color:#0C447C}
.badge-ok{background:#EAF3DE;color:#27500A}
.badge-inac{background:#F1EFE8;color:#5F5E5A}
.badge-pend{background:#FAEEDA;color:#633806}
.badge-promo{background:#FBEAF0;color:#72243E}
.badge-principal{background:#FFF3E0;color:#E65100;border:1px solid #FFB74D}
.badge-stock-ok{background:#EAF3DE;color:#27500A}
.badge-stock-bajo{background:#FAEEDA;color:#633806}
.badge-stock-agotado{background:#FFEBEE;color:#C62828}
.filtros{display:flex;gap:10px;padding:12px 18px;border-bottom:1px solid #e0e0e0;flex-wrap:wrap;align-items:center}
.alerta{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:12px;border-left:3px solid;display:none}
.alerta.show{display:block}
.alerta-error{background:#FFEBEE;border-color:#C62828;color:#C62828}
.alerta-ok{background:#E8F5E9;border-color:#2E7D32;color:#2E7D32}
.alerta-info{background:#E6F1FB;border-color:#185FA5;color:#0C447C}
.precio-tachado{text-decoration:line-through;color:#9e9e9e;font-size:11px}
.precio-promo{color:#C2185B;font-weight:500}
.img-thumb{width:40px;height:40px;border-radius:6px;background:#f5f5f5;border:1px solid #e0e0e0;display:flex;align-items:center;justify-content:center;color:#bdbdbd;font-size:18px;flex-shrink:0;overflow:hidden}
.cabecera-cat{display:flex;align-items:center;gap:14px;padding:14px 18px;background:linear-gradient(135deg,#FFF8FB 0%,#FCE4EC 100%);border-bottom:1px solid #e0e0e0}
.cab-ico{width:48px;height:48px;border-radius:10px;background:white;display:flex;align-items:center;justify-content:center;color:#C2185B;font-size:24px;border:1px solid #FCE4EC;flex-shrink:0}
.cab-info{flex:1;min-width:0}
.cab-titulo{font-size:18px;font-weight:600;color:#880E4F;margin-bottom:2px}
.cab-ruta{font-size:12px;color:#9e9e9e}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;padding:14px 18px;background:#fafafa;border-bottom:1px solid #e0e0e0}
.stat-card{background:white;border:1px solid #e0e0e0;border-radius:8px;padding:10px 14px;display:flex;align-items:center;gap:10px}
.stat-ico{width:34px;height:34px;border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:17px;flex-shrink:0}
.stat-ico-azul{background:#E6F1FB;color:#0C447C}
.stat-ico-verde{background:#EAF3DE;color:#27500A}
.stat-ico-rosa{background:#FBEAF0;color:#72243E}
.stat-ico-naranja{background:#FFF3E0;color:#E65100}
.stat-num{font-size:18px;font-weight:600;color:#424242;line-height:1}
.stat-label{font-size:11px;color:#9e9e9e;margin-top:2px}
.estado-vacio{padding:50px 20px;text-align:center;color:#9e9e9e}
.estado-vacio i{font-size:48px;color:#e0e0e0;margin-bottom:10px;display:block}
.estado-vacio-tit{font-size:15px;color:#616161;margin-bottom:6px}
.estado-vacio-sub{font-size:13px;margin-bottom:14px}
.chk{width:18px;height:18px;border:2px solid #e0e0e0;border-radius:4px;cursor:pointer;display:inline-flex;align-items:center;justify-content:center;background:white;transition:all .15s}
.chk.on{background:#2E7D32;border-color:#2E7D32;color:white}
.chk i{font-size:13px}
.acc-masivas{display:none;padding:12px 18px;background:#FFF3E0;border-bottom:1px solid #FFE0B2;align-items:center;gap:10px}
.acc-masivas.show{display:flex}
.acc-info{flex:1;font-size:13px;color:#E65100;font-weight:500}
.overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:99}
.modal-bg{display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:200;align-items:center;justify-content:center;padding:20px}
.modal-bg.show{display:flex}
.cargando-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.55);z-index:9999;align-items:center;justify-content:center;flex-direction:column;gap:16px}
.cargando-overlay.show{display:flex}
.cargando-spinner{width:48px;height:48px;border:4px solid rgba(255,255,255,.3);border-top-color:#fff;border-radius:50%;animation:spin .8s linear infinite}
.cargando-texto{color:#fff;font-size:14px;font-weight:500;text-align:center;max-width:280px;line-height:1.4}
@keyframes spin{to{transform:rotate(360deg)}}
.modal{background:white;border-radius:12px;width:100%;max-width:760px;max-height:90vh;display:flex;flex-direction:column}
.modal-head{padding:14px 18px;border-bottom:1px solid #e0e0e0;display:flex;justify-content:space-between;align-items:center;flex-shrink:0}
.modal-title{font-size:15px;font-weight:500}
.modal-close{background:none;border:none;font-size:20px;cursor:pointer;color:#9e9e9e}
.modal-body{padding:18px;overflow-y:auto;flex:1}
.modal-foot{padding:12px 18px;border-top:1px solid #e0e0e0;display:flex;gap:8px;justify-content:flex-end;background:#fafafa;flex-shrink:0;flex-wrap:wrap}
.disp-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:10px;max-height:50vh;overflow-y:auto;padding:4px}
.disp-card{border:2px solid #e0e0e0;border-radius:10px;padding:10px;cursor:pointer;transition:all .15s;display:flex;align-items:center;gap:10px;background:white}
.disp-card:hover{border-color:#C2185B;background:#FFF8FB}
.disp-card.sel{border-color:#2E7D32;background:#E8F5E9}
.disp-info{flex:1;min-width:0}
.disp-nombre{font-size:13px;font-weight:500;color:#424242;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.disp-sku{font-size:11px;color:#9e9e9e;font-family:monospace}
.disp-precio{font-size:12px;color:#C2185B;font-weight:500;margin-top:2px}
</style>
</head>
<body>
<form id="form1" runat="server">
<div class="overlay" id="overlay" onclick="cerrarSidebar()"></div>
<div class="layout">

  <aside class="sidebar" id="sidebar">
    <div class="sb-logo">
      <div class="sb-logo-title">Floreria</div>
      <div class="sb-logo-sub">Sistema Integral</div>
    </div>
    <div class="sb-user">
      <div class="sb-avatar" id="spIniciales">--</div>
      <div>
        <div class="sb-user-name" id="spNombre">Cargando...</div>
        <div class="sb-user-role"  id="spRol"></div>
      </div>
    </div>
    <nav class="nav"><%=MenuHtml%></nav>
    <div class="sb-footer">
      <input type="hidden" id="hdCerrar" name="hdCerrar" value="0"/>
      <button type="button" class="btn-logout" onclick="cerrarSesion()">
        <i class="ti ti-logout" style="font-size:16px" aria-hidden="true"></i> Cerrar sesion
      </button>
    </div>
  </aside>

  <div class="main">
    <header class="topbar">
      <button type="button" style="background:none;border:none;cursor:pointer;padding:4px;display:none" id="btnHamburger" onclick="abrirSidebar()">
        <i class="ti ti-menu-2" style="font-size:22px" aria-hidden="true"></i>
      </button>
      <div class="topbar-title">
        <i class="ti ti-package" style="font-size:17px;vertical-align:-3px;margin-right:8px;color:#C2185B" aria-hidden="true"></i>
        Productos de la categoria
      </div>
      <div style="display:flex;align-items:center;gap:8px">
        <div class="sb-avatar" id="spInicialesTop" style="background:#FCE4EC;color:#880E4F;font-size:12px">--</div>
        <span style="font-size:13px" id="spNombreTop"></span>
      </div>
    </header>

    <div class="contenido">

      <div style="display:flex;align-items:center;gap:10px;margin-bottom:16px">
        <button type="button" class="btn" onclick="volverCategorias()">
          <i class="ti ti-arrow-left" aria-hidden="true"></i> Volver a categorias
        </button>
      </div>

      <div class="alerta" id="divAlerta"></div>

      <!-- CABECERA DE CATEGORIA -->
      <div class="panel">
        <div class="cabecera-cat">
          <div class="cab-ico">
            <i class="ti ti-folder" aria-hidden="true"></i>
          </div>
          <div class="cab-info">
            <div class="cab-titulo"><%=CategoriaNombre%></div>
            <div class="cab-ruta"><%=CategoriaRuta%></div>
          </div>
        </div>

        <!-- STATS -->
        <div class="stats">
          <div class="stat-card">
            <div class="stat-ico stat-ico-azul"><i class="ti ti-package" aria-hidden="true"></i></div>
            <div>
              <div class="stat-num" id="stTotal"><%=StatTotal%></div>
              <div class="stat-label">Productos</div>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-ico stat-ico-verde"><i class="ti ti-eye" aria-hidden="true"></i></div>
            <div>
              <div class="stat-num" id="stActivos"><%=StatActivos%></div>
              <div class="stat-label">Activos</div>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-ico stat-ico-naranja"><i class="ti ti-star" aria-hidden="true"></i></div>
            <div>
              <div class="stat-num" id="stPrincipal"><%=StatPrincipal%></div>
              <div class="stat-label">Principal aqui</div>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-ico stat-ico-rosa"><i class="ti ti-discount-2" aria-hidden="true"></i></div>
            <div>
              <div class="stat-num" id="stPromo"><%=StatPromo%></div>
              <div class="stat-label">En promo</div>
            </div>
          </div>
        </div>

        <!-- ACCIONES MASIVAS -->
        <div class="acc-masivas" id="accMasivas">
          <div class="chk on" onclick="desmarcarTodos()"><i class="ti ti-check" aria-hidden="true"></i></div>
          <div class="acc-info"><span id="cntSel">0</span> productos seleccionados</div>
          <button type="button" class="btn btn-sm" onclick="desmarcarTodos()">Desmarcar</button>
          <button type="button" class="btn btn-sm btn-danger" onclick="abrirQuitarMasivo()">
            <i class="ti ti-trash" aria-hidden="true"></i> Quitar seleccionados
          </button>
        </div>

        <!-- FILTROS -->
        <div class="panel-head">
          <div class="panel-title">Productos en esta categoria</div>
          <button type="button" class="btn btn-primary" onclick="abrirAgregar()">
            <i class="ti ti-plus" aria-hidden="true"></i> Agregar productos
          </button>
        </div>
        <div class="filtros">
          <input type="text" id="txBuscar" class="form-control" style="width:220px" placeholder="Nombre o SKU..."
                 oninput="filtrarTablaLocal()"
                 onkeydown="if(event.key==='Escape'){limpiarFiltro();}"/>
          <select id="selEstado" class="form-control" style="width:140px" onchange="filtrarTablaLocal()">
            <option value="">Todos</option>
            <option value="activo">Activos</option>
            <option value="inactivo">Inactivos</option>
          </select>
          <button type="button" class="btn" onclick="limpiarFiltro()" title="Limpiar filtro">
            <i class="ti ti-x" aria-hidden="true"></i>
          </button>
        </div>

        <div id="divTabla"><%=TablaHtml%></div>
      </div>

    </div>
  </div>
</div>

<!-- MODAL: AGREGAR PRODUCTOS -->
<div class="modal-bg" id="modalAgregar">
  <div class="modal">
    <div class="modal-head">
      <div class="modal-title">Agregar productos a la categoria</div>
      <button type="button" class="modal-close" onclick="cerrarModal('modalAgregar')">&times;</button>
    </div>
    <div class="modal-body">
      <div style="margin-bottom:12px">
        <input type="text" id="txBuscarDisp" class="form-control" placeholder="Buscar producto disponible..." oninput="filtrarDisponiblesLocal()"/>
      </div>
      <div id="divDisponibles">
        <div class="estado-vacio">
          <i class="ti ti-search" aria-hidden="true"></i>
          <div class="estado-vacio-sub">Escribe para buscar productos...</div>
        </div>
      </div>
    </div>
    <div class="modal-foot">
      <div style="flex:1;font-size:12px;color:#757575" id="lblSelDisp">0 seleccionados</div>
      <button type="button" class="btn" onclick="cerrarModal('modalAgregar')">Cancelar</button>
      <button type="button" class="btn btn-primary" onclick="confirmarAgregar()">
        <i class="ti ti-plus" aria-hidden="true"></i> Agregar seleccionados
      </button>
    </div>
  </div>
</div>

<!-- MODAL: QUITAR INDIVIDUAL -->
<div class="modal-bg" id="modalQuitar">
  <div class="modal" style="max-width:440px">
    <div class="modal-head">
      <div class="modal-title">Quitar producto de la categoria</div>
      <button type="button" class="modal-close" onclick="cerrarModal('modalQuitar')">&times;</button>
    </div>
    <div class="modal-body">
      <p style="font-size:13px;margin-bottom:10px">Se quitara <strong id="lblProdQuitar"></strong> de esta categoria. El producto no se elimina, solo deja de pertenecer aqui.</p>
      <label class="form-label">Motivo</label>
      <input type="text" id="txMotivoQuitar" class="form-control" placeholder="Ej: Reorganizacion de categorias"/>
    </div>
    <div class="modal-foot">
      <button type="button" class="btn" onclick="cerrarModal('modalQuitar')">Cancelar</button>
      <button type="button" class="btn btn-danger" onclick="confirmarQuitar()">
        <i class="ti ti-trash" aria-hidden="true"></i> Quitar
      </button>
    </div>
  </div>
</div>

<!-- MODAL: QUITAR MASIVO -->
<div class="modal-bg" id="modalQuitarMasivo">
  <div class="modal" style="max-width:440px">
    <div class="modal-head">
      <div class="modal-title">Quitar productos seleccionados</div>
      <button type="button" class="modal-close" onclick="cerrarModal('modalQuitarMasivo')">&times;</button>
    </div>
    <div class="modal-body">
      <p style="font-size:13px;margin-bottom:10px">Se quitaran <strong id="lblCntMasivo"></strong> productos de esta categoria.</p>
      <label class="form-label">Motivo</label>
      <input type="text" id="txMotivoMasivo" class="form-control" placeholder="Ej: Reorganizacion de categorias"/>
    </div>
    <div class="modal-foot">
      <button type="button" class="btn" onclick="cerrarModal('modalQuitarMasivo')">Cancelar</button>
      <button type="button" class="btn btn-danger" onclick="confirmarQuitarMasivo()">
        <i class="ti ti-trash" aria-hidden="true"></i> Quitar todos
      </button>
    </div>
  </div>
</div>

<!-- HIDDEN FIELDS -->
<input type="hidden" id="hdAccion"        name="hdAccion"        value=""/>
<input type="hidden" id="hdCategoriaId"   name="hdCategoriaId"   value="<%=CategoriaId%>"/>
<input type="hidden" id="hdProductoId"    name="hdProductoId"    value=""/>
<input type="hidden" id="hdProductoIds"   name="hdProductoIds"   value=""/>
<input type="hidden" id="hdMotivo"        name="hdMotivo"        value=""/>
<input type="hidden" id="hdBuscarDisp"    name="hdBuscarDisp"    value=""/>
<div id="divDisponiblesData" style="display:none"><%=DisponiblesHtml%></div>
<div id="divMostrarModal"    style="display:none"><%=MostrarModal%></div>

<div class="cargando-overlay" id="cargandoOverlay">
  <div class="cargando-spinner"></div>
  <div class="cargando-texto" id="cargandoTexto">Procesando...</div>
</div>

<asp:Button ID="btnAccion"        runat="server" Text="" Style="display:none" OnClick="btnAccion_Click"/>
<asp:Button ID="btnCerrarSesion"  runat="server" Text="" Style="display:none" OnClick="btnCerrarSesion_Click"/>

<script>
var selMasivos    = [];
var selDisponibles = [];

function mostrarCargando(/** @type {string} */ texto) {
    var ov = $id('cargandoOverlay');
    var tx = $id('cargandoTexto');
    if (tx) { tx.textContent = texto || 'Procesando...'; }
    if (ov) { ov.className = 'cargando-overlay show'; }
}

function $id(/** @type {string} */ id) { return document.getElementById(id); }

function setHd(/** @type {string} */ id, /** @type {string} */ val) {
    var el = /** @type {HTMLInputElement} */ ($id(id));
    if (el) { el.value = val; }
}

function getVal(/** @type {string} */ id) {
    var el = /** @type {HTMLInputElement} */ ($id(id));
    return el ? el.value : '';
}

function postBack(/** @type {string} */ accion) {
    setHd('hdAccion', accion);
    var btn = /** @type {HTMLElement} */ ($id('<%= btnAccion.ClientID %>'));
    if (btn) { btn.click(); }
}

function mostrarAlerta(/** @type {string} */ msg, /** @type {string} */ tipo) {
    var el = $id('divAlerta');
    if (!el) { return; }
    el.className = 'alerta show alerta-' + tipo;
    el.textContent = msg;
    setTimeout(function(){ var d=$id('divAlerta'); if(d){ d.className='alerta'; } }, 4000);
}

function volverCategorias() {
    window.location.href = 'Categorias.aspx';
}

function filtrarTablaLocal() {
    var tx  = /** @type {HTMLInputElement}  */ ($id('txBuscar'));
    var se  = /** @type {HTMLSelectElement} */ ($id('selEstado'));
    var txt = tx ? tx.value.toLowerCase().trim() : '';
    var est = se ? se.value : '';
    var filas = document.querySelectorAll('#divTabla tbody tr');
    var vis = 0;
    for (var i = 0; i < filas.length; i++) {
        var fila = /** @type {HTMLElement} */ (filas[i]);
        var nom  = (fila.getAttribute('data-nombre') || '');
        var sku  = (fila.getAttribute('data-sku')    || '');
        var act  = (fila.getAttribute('data-activo') || '');
        var okTxt = (txt === '' || nom.indexOf(txt) >= 0 || sku.indexOf(txt) >= 0);
        var okEst = (est === '' || act === est);
        if (okTxt && okEst) {
            fila.style.display = '';
            vis++;
        } else {
            fila.style.display = 'none';
        }
    }
    var dvVacio = $id('trVacioFiltro');
    var tbody = document.querySelector('#divTabla tbody');
    if (vis === 0 && filas.length > 0) {
        if (!dvVacio && tbody) {
            var tr = document.createElement('tr');
            tr.id = 'trVacioFiltro';
            tr.innerHTML = '<td colspan="9" style="padding:30px;text-align:center;color:#9e9e9e">Sin resultados para el filtro aplicado</td>';
            tbody.appendChild(tr);
        }
    } else {
        if (dvVacio) { dvVacio.parentNode.removeChild(dvVacio); }
    }
}

function limpiarFiltro() {
    var tx = /** @type {HTMLInputElement}  */ ($id('txBuscar'));
    var se = /** @type {HTMLSelectElement} */ ($id('selEstado'));
    if (tx) { tx.value = ''; }
    if (se) { se.value = ''; }
    filtrarTablaLocal();
    if (tx) { tx.focus(); }
}

function toggleSel(/** @type {number} */ id) {
    var idx = selMasivos.indexOf(id);
    if (idx >= 0) { selMasivos.splice(idx, 1); }
    else          { selMasivos.push(id); }
    var fila = $id('fila_' + id);
    var chk  = $id('chk_'  + id);
    if (fila) { fila.style.background = (idx < 0) ? '#FFF8FB' : ''; }
    if (chk)  { chk.className = (idx < 0) ? 'chk on' : 'chk'; }
    actualizarBarraMasiva();
}

function actualizarBarraMasiva() {
    var bar = $id('accMasivas');
    var cnt = $id('cntSel');
    if (cnt) { cnt.textContent = selMasivos.length.toString(); }
    if (bar) { bar.className = (selMasivos.length > 0) ? 'acc-masivas show' : 'acc-masivas'; }
}

function desmarcarTodos() {
    for (var i = 0; i < selMasivos.length; i++) {
        var fila = $id('fila_' + selMasivos[i]);
        var chk  = $id('chk_'  + selMasivos[i]);
        if (fila) { fila.style.background = ''; }
        if (chk)  { chk.className = 'chk'; }
    }
    selMasivos = [];
    actualizarBarraMasiva();
}

function marcarPrincipal(/** @type {number} */ id) {
    setHd('hdProductoId', id.toString());
    postBack('MARCAR_PRINCIPAL');
}

function abrirQuitar(/** @type {number} */ id, /** @type {string} */ nombre) {
    setHd('hdProductoId', id.toString());
    var lbl = $id('lblProdQuitar');
    var mot = /** @type {HTMLInputElement} */ ($id('txMotivoQuitar'));
    if (lbl) { lbl.textContent = nombre; }
    if (mot) { mot.value = ''; }
    abrirModal('modalQuitar');
}

function confirmarQuitar() {
    var motivo = getVal('txMotivoQuitar');
    if (motivo.trim().length < 1) { mostrarAlerta('Indica un motivo.', 'error'); return; }
    setHd('hdMotivo', motivo);
    cerrarModal('modalQuitar');
    mostrarCargando('Quitando producto y sincronizando con WooCommerce...');
    postBack('QUITAR');
}

function abrirQuitarMasivo() {
    if (selMasivos.length === 0) { return; }
    var lbl = $id('lblCntMasivo');
    var mot = /** @type {HTMLInputElement} */ ($id('txMotivoMasivo'));
    if (lbl) { lbl.textContent = selMasivos.length.toString(); }
    if (mot) { mot.value = ''; }
    abrirModal('modalQuitarMasivo');
}

function confirmarQuitarMasivo() {
    var motivo = getVal('txMotivoMasivo');
    if (motivo.trim().length < 1) { mostrarAlerta('Indica un motivo.', 'error'); return; }
    setHd('hdMotivo',      motivo);
    setHd('hdProductoIds', selMasivos.join(','));
    cerrarModal('modalQuitarMasivo');
    mostrarCargando('Quitando productos y sincronizando con WooCommerce...');
    postBack('QUITAR_MASIVO');
}

function abrirAgregar() {
    selDisponibles = [];
    var tx = /** @type {HTMLInputElement} */ ($id('txBuscarDisp'));
    if (tx) { tx.value = ''; }
    actualizarLblSel();

    // Copiar HTML desde el DIV puente al contenedor visible del modal
    var divData = $id('divDisponiblesData');
    var dv      = $id('divDisponibles');
    if (divData && dv) {
        dv.innerHTML = divData.innerHTML;
    }
    // Limpiar filtro visual
    var cards = document.querySelectorAll('#divDisponibles .disp-card');
    for (var i = 0; i < cards.length; i++) {
        var card = /** @type {HTMLElement} */ (cards[i]);
        card.style.display = '';
    }
    abrirModal('modalAgregar');
}

var timerBusqueda = null;
function filtrarDisponiblesLocal() {
    var tx  = /** @type {HTMLInputElement} */ ($id('txBuscarDisp'));
    var txt = tx ? tx.value.toLowerCase().trim() : '';
    var cards = document.querySelectorAll('#divDisponibles .disp-card');
    var visibles = 0;
    for (var i = 0; i < cards.length; i++) {
        var card = /** @type {HTMLElement} */ (cards[i]);
        var nom  = (card.getAttribute('data-nombre') || '').toLowerCase();
        var sku  = (card.getAttribute('data-sku')    || '').toLowerCase();
        if (txt === '' || nom.indexOf(txt) >= 0 || sku.indexOf(txt) >= 0) {
            card.style.display = '';
            visibles++;
        } else {
            card.style.display = 'none';
        }
    }
    var dv = $id('divDisponibles');
    var dvVacio = $id('divDispVacio');
    if (dv) {
        if (visibles === 0 && cards.length > 0) {
            if (!dvVacio) {
                var v = document.createElement('div');
                v.id = 'divDispVacio';
                v.className = 'estado-vacio';
                v.innerHTML = '<i class="ti ti-search-off" aria-hidden="true"></i><div class="estado-vacio-sub">Sin resultados para "' + txt + '"</div>';
                dv.appendChild(v);
            }
        } else {
            if (dvVacio) { dvVacio.parentNode.removeChild(dvVacio); }
        }
    }
}

function buscarDisponibles() {
    filtrarDisponiblesLocal();
}

function toggleSelDisp(/** @type {number} */ id) {
    var idx = selDisponibles.indexOf(id);
    if (idx >= 0) { selDisponibles.splice(idx, 1); }
    else          { selDisponibles.push(id); }
    var card = $id('disp_' + id);
    if (card) { card.className = (idx < 0) ? 'disp-card sel' : 'disp-card'; }
    actualizarLblSel();
}

function actualizarLblSel() {
    var lbl = $id('lblSelDisp');
    if (lbl) { lbl.textContent = selDisponibles.length + ' seleccionados'; }
}

function confirmarAgregar() {
    if (selDisponibles.length === 0) { mostrarAlerta('Selecciona al menos un producto.', 'error'); return; }
    setHd('hdProductoIds', selDisponibles.join(','));
    cerrarModal('modalAgregar');
    mostrarCargando('Agregando productos y sincronizando con WooCommerce...');
    postBack('AGREGAR_PRODUCTOS');
}

function abrirModal(/** @type {string} */ id) {
    var el = $id(id);
    if (el) { el.className = 'modal-bg show'; }
}

function cerrarModal(/** @type {string} */ id) {
    var el = $id(id);
    if (el) { el.className = 'modal-bg'; }
}

function abrirSidebar() {
    var sb = $id('sidebar');
    var ov = $id('overlay');
    if (sb) { sb.style.transform = 'translateX(0)'; }
    if (ov) { ov.style.display = 'block'; }
}

function cerrarSidebar() {
    var sb = $id('sidebar');
    var ov = $id('overlay');
    if (sb && window.innerWidth < 900) { sb.style.transform = 'translateX(-100%)'; }
    if (ov) { ov.style.display = 'none'; }
}

function cerrarSesion() {
    setHd('hdCerrar', '1');
    var btn = /** @type {HTMLElement} */ ($id('<%= btnCerrarSesion.ClientID %>'));
    if (btn) { btn.click(); }
}

window.addEventListener('DOMContentLoaded', function() {
    var nombre    = '<%=NombreUsuario%>';
    var iniciales = '<%=Iniciales%>';
    var rol = '<%=RolUsuario%>';
    var elN = $id('spNombre');
    var elI = $id('spIniciales');
    var elR = $id('spRol');
    var elNT = $id('spNombreTop');
    var elIT = $id('spInicialesTop');
    if (elN) { elN.textContent = nombre; }
    if (elI) { elI.textContent = iniciales; }
    if (elR) { elR.textContent = rol; }
    if (elNT) { elNT.textContent = nombre; }
    if (elIT) { elIT.textContent = iniciales; }
});

document.addEventListener('keydown', function (/** @type {KeyboardEvent} */ e) {
    if (e.key === 'Escape') {
        cerrarModal('modalAgregar');
        cerrarModal('modalQuitar');
        cerrarModal('modalQuitarMasivo');
    }
});
</script>

</form>
</body>
</html>
