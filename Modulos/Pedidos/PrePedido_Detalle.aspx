<%@ Page Language="VB" AutoEventWireup="false" CodeFile="Detalle.aspx.vb" Inherits="Modulos_Pedidos_Detalle" %>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SISCONBOL - Detalle Pre-Pedido</title>
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
.topbar{background:white;border-bottom:1px solid #e0e0e0;padding:0 24px;height:52px;display:flex;align-items:center;gap:12px;position:sticky;top:0;z-index:10}
.topbar-title{font-size:15px;font-weight:500;flex:1;display:flex;align-items:center;gap:10px}
.content{padding:20px;max-width:1400px}
.panel{background:white;border:1px solid #e0e0e0;border-radius:10px;overflow:hidden;margin-bottom:16px}
.panel-head{padding:14px 18px;border-bottom:1px solid #e0e0e0;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px}
.panel-title{font-size:15px;font-weight:500}
.panel-body{padding:18px}
.btn{padding:7px 14px;border-radius:8px;font-size:13px;border:1px solid #e0e0e0;background:white;color:#424242;cursor:pointer;display:inline-flex;align-items:center;gap:6px;transition:background .15s;text-decoration:none}
.btn:hover{background:#f5f5f5}
.btn-primary{background:#C2185B;border-color:#C2185B;color:white}
.btn-primary:hover{background:#880E4F}
.btn-success{background:#2E7D32;border-color:#2E7D32;color:white}
.btn-success:hover{background:#1B5E20}
.btn-sm{padding:5px 10px;font-size:12px}
.btn-icon{padding:6px;width:32px;height:32px;justify-content:center}
.btn:disabled{opacity:.5;cursor:not-allowed}
.info-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:16px}
.info-item{display:flex;flex-direction:column;gap:4px}
.info-label{font-size:12px;color:#757575;font-weight:500}
.info-value{font-size:14px;color:#424242}
.badge{display:inline-flex;align-items:center;gap:4px;padding:4px 10px;border-radius:10px;font-size:12px;font-weight:500}
.badge-borrador{background:#F1EFE8;color:#5F5E5A}
.badge-enviado{background:#E6F1FB;color:#0C447C}
.badge-completado{background:#FBEAF0;color:#72243E}
.badge-pagado{background:#EAF3DE;color:#27500A}
.badge-wc{background:#DCEEFB;color:#1976D2}
.badge-cancelado{background:#FFEBEE;color:#C62828}
.badge-expirado{background:#FFF3E0;color:#E65100}
.tabla{width:100%;border-collapse:collapse;font-size:13px}
.tabla th{padding:9px 12px;background:#f5f5f5;font-size:11px;font-weight:500;text-transform:uppercase;letter-spacing:.4px;color:#757575;text-align:left;border-bottom:1px solid #e0e0e0}
.tabla td{padding:9px 12px;border-bottom:1px solid #f0f0f0;vertical-align:middle}
.tabla tr:last-child td{border-bottom:none}
.tabla tr:hover td{background:#FFF8FB}
.empty{text-align:center;padding:30px 20px;color:#9e9e9e;font-size:13px}
.empty-icon{font-size:42px;margin-bottom:10px;opacity:.3}
.codigo{font-family:monospace;font-size:12px;background:#f5f5f5;padding:2px 6px;border-radius:4px}
.alerta{padding:12px 16px;border-radius:8px;font-size:13px;margin-bottom:16px;border-left:3px solid;display:none}
.alerta.show{display:block}
.alerta-error{background:#FFEBEE;border-color:#C62828;color:#C62828}
.alerta-ok{background:#E8F5E9;border-color:#2E7D32;color:#2E7D32}
.alerta-warn{background:#FFF3E0;border-color:#F57C00;color:#F57C00}
.modal{position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,.5);display:none;align-items:center;justify-content:center;z-index:1000}
.modal.show{display:flex}
.modal-content{background:white;border-radius:12px;max-width:600px;width:90%;max-height:90vh;overflow:hidden;display:flex;flex-direction:column}
.modal-header{padding:16px 20px;border-bottom:1px solid #e0e0e0;display:flex;justify-content:space-between;align-items:center}
.modal-title{font-size:16px;font-weight:500}
.modal-body{padding:20px;overflow-y:auto;flex:1}
.modal-footer{padding:16px 20px;border-top:1px solid #e0e0e0;display:flex;gap:10px;justify-content:flex-end}
.form-group{margin-bottom:16px}
.form-label{display:block;font-size:13px;font-weight:500;color:#616161;margin-bottom:6px}
.form-label.required:after{content:' *';color:#C62828}
.form-control{padding:9px 12px;border:1px solid #e0e0e0;border-radius:8px;font-size:14px;background:white;color:#424242;outline:none;transition:border-color .2s;width:100%;font-family:inherit}
.form-control:focus{border-color:#C2185B}
.form-control:disabled{background:#f5f5f5;color:#9e9e9e}
.form-help{font-size:12px;color:#757575;margin-top:4px}
.mini-preview{font-size:11px;color:#757575;margin-top:2px}
.pedido-card{border:1px solid #e0e0e0;border-radius:8px;padding:14px;margin-bottom:12px;background:white}
.pedido-card:hover{background:#FFFBFC;border-color:#C2185B}
.pedido-header{display:flex;justify-content:space-between;align-items:start;margin-bottom:10px}
.pedido-info{flex:1}
.pedido-actions{display:flex;gap:6px}
.link-box{background:#f9f9f9;padding:12px;border-radius:8px;border:1px solid #e0e0e0;margin-top:10px}
.link-url{word-break:break-all;color:#1976D2;font-size:13px;margin-bottom:8px}
</style>
</head>
<body>
<form id="form1" runat="server">
<div class="layout">
  <aside class="sidebar">
    <div class="sb-logo">
      <div class="sb-logo-title">Florería</div>
      <div class="sb-logo-sub">Sistema Integral</div>
    </div>
    <div class="sb-user">
      <div class="sb-avatar" id="spIniciales">--</div>
      <div>
        <div class="sb-user-name" id="spNombre">Cargando...</div>
        <div class="sb-user-role" id="spRol"></div>
      </div>
    </div>
    <nav class="nav"><%=MenuHtml%></nav>
  </aside>

  <div class="main">
    <div class="topbar">
      <a href="Lista.aspx" class="btn btn-icon" title="Volver">
        <i class="ti ti-arrow-left"></i>
      </a>
      <div class="topbar-title">
        <span id="spCodigoTop">Pre-Pedido</span>
        <span id="spEstadoTop"></span>
      </div>
      <button type="button" class="btn btn-success" onclick="generarLink()" id="btnGenerarLink">
        <i class="ti ti-link"></i> Generar Link Web
      </button>
    </div>

    <div class="content">
      <div id="divAlerta" class="alerta"></div>

      <!-- INFO GENERAL -->
      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">Información General</div>
          <button type="button" class="btn btn-sm" onclick="editarCliente()">
            <i class="ti ti-edit"></i> Editar
          </button>
        </div>
        <div class="panel-body">
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">Código</span>
              <span class="info-value" id="spCodigo">-</span>
            </div>
            <div class="info-item">
              <span class="info-label">Tipo</span>
              <span class="info-value" id="spTipo">-</span>
            </div>
            <div class="info-item">
              <span class="info-label">Cliente</span>
              <span class="info-value" id="spCliente">-</span>
            </div>
            <div class="info-item">
              <span class="info-label">Celular</span>
              <span class="info-value" id="spCelular">-</span>
            </div>
            <div class="info-item">
              <span class="info-label">Email</span>
              <span class="info-value" id="spEmail">-</span>
            </div>
            <div class="info-item">
              <span class="info-label">Agente</span>
              <span class="info-value" id="spAgente">-</span>
            </div>
            <div class="info-item">
              <span class="info-label">Total Bs</span>
              <span class="info-value" id="spTotalBs" style="font-weight:600;color:#C2185B">Bs 0.00</span>
            </div>
            <div class="info-item">
              <span class="info-label">Total USD</span>
              <span class="info-value" id="spTotalUsd">$0.00</span>
            </div>
          </div>
        </div>
      </div>

      <!-- PEDIDOS -->
      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">Pedidos (<span id="spCantPedidos">0</span>)</div>
          <button type="button" class="btn btn-sm btn-primary" onclick="agregarPedido()">
            <i class="ti ti-plus"></i> Agregar Pedido
          </button>
        </div>
        <div class="panel-body" id="divPedidos">
          <!-- Se carga dinámicamente -->
        </div>
      </div>

      <!-- LINK WEB -->
      <div class="panel" id="panelLink" style="display:none">
        <div class="panel-head">
          <div class="panel-title">Link Web Cliente</div>
        </div>
        <div class="panel-body">
          <div id="divLinkInfo"></div>
        </div>
      </div>

    </div>
  </div>
</div>

<!-- MODAL AGREGAR PEDIDO -->
<div class="modal" id="modalPedido">
  <div class="modal-content">
    <div class="modal-header">
      <div class="modal-title">Agregar Pedido</div>
      <button type="button" class="btn btn-icon" onclick="cerrarModalPedido()">
        <i class="ti ti-x"></i>
      </button>
    </div>
    <div class="modal-body">
      <div class="form-group">
        <label class="form-label required">Receptor</label>
        <input type="text" id="txReceptor" class="form-control" placeholder="Nombre del receptor"/>
      </div>
      <div class="form-group">
        <label class="form-label required">Celular Receptor</label>
        <input type="text" id="txReceptorCel" class="form-control" placeholder="77123456"/>
      </div>
      <div class="form-group">
        <label class="form-label required">Fecha Entrega</label>
        <input type="date" id="txFecha" class="form-control"/>
      </div>
      <div class="form-group">
        <label class="form-label required">Tipo Entrega</label>
        <select id="ddTipoEntrega" class="form-control" onchange="cambiarTipoEntrega()">
          <option value="">Seleccione...</option>
          <option value="DOMICILIO">Entrega a Domicilio</option>
          <option value="RECOJO_SUCURSAL">Recojo en Sucursal</option>
        </select>
      </div>
      <div class="form-group" id="grpDireccion" style="display:none">
        <label class="form-label required">Dirección</label>
        <input type="text" id="txDireccion" class="form-control" placeholder="Calle, número, zona"/>
      </div>
    </div>
    <div class="modal-footer">
      <button type="button" class="btn" onclick="cerrarModalPedido()">Cancelar</button>
      <button type="button" class="btn btn-primary" onclick="guardarPedido()">Guardar Pedido</button>
    </div>
  </div>
</div>

<input type="hidden" id="hdAccion" name="hdAccion"/>
<input type="hidden" id="hdData" name="hdData"/>
<asp:Button ID="btnPostBack" runat="server" Style="display:none" OnClick="btnPostBack_Click"/>
</form>

<div id="jsonData" style="display:none;"><%=JsonData%></div>

<script type="text/javascript">
var datosPrePedido = null;
var prepedidoId = parseInt('<%=Request.QueryString("id")%>') || 0;

window.addEventListener('DOMContentLoaded', function() {
  cargarDatosUsuario();
  cargarDatos();
});

function cargarDatosUsuario() {
  var nombre = '<%=Session("nombres")%>' + ' ' + '<%=Session("apellidos")%>';
  var rol = '<%=Session("tipo_nombre")%>';
  var el = document.getElementById('spNombre');
  if (el) el.textContent = nombre;
  el = document.getElementById('spRol');
  if (el) el.textContent = rol;
  var iniciales = nombre.split(' ').map(function(p){return p.charAt(0);}).join('');
  el = document.getElementById('spIniciales');
  if (el) el.textContent = iniciales.substring(0,2).toUpperCase();
}

function cargarDatos() {
  var divJson = document.getElementById('jsonData');
  if (!divJson) return;
  var jsonText = divJson.textContent || divJson.innerText;
  if (!jsonText || jsonText.trim() === '') {
    mostrarAlerta('No se pudieron cargar los datos', 'error');
    return;
  }
  try {
    datosPrePedido = JSON.parse(jsonText);
    renderizarDatos();
  } catch(e) {
    console.error('Error parseando JSON:', e);
    mostrarAlerta('Error al cargar datos', 'error');
  }
}

function renderizarDatos() {
  if (!datosPrePedido) return;
  var d = datosPrePedido;
  
  var el = document.getElementById('spCodigoTop');
  if (el) el.innerHTML = '<span class="codigo">' + d.codigo + '</span>';
  
  el = document.getElementById('spEstadoTop');
  if (el) el.innerHTML = obtenerBadgeEstado(d.estado);
  
  el = document.getElementById('spCodigo');
  if (el) el.innerHTML = '<span class="codigo">' + d.codigo + '</span>';
  
  el = document.getElementById('spTipo');
  if (el) el.textContent = obtenerEtiquetaTipo(d.tipo_registro);
  
  el = document.getElementById('spCliente');
  if (el) el.textContent = (d.cliente_nombre || 'Sin nombre') + ' ' + (d.cliente_apellidos || '');
  
  el = document.getElementById('spCelular');
  if (el) el.textContent = d.cliente_celular || '-';
  
  el = document.getElementById('spEmail');
  if (el) el.textContent = d.cliente_email || '-';
  
  el = document.getElementById('spAgente');
  if (el) el.textContent = d.agente_nombre || '-';
  
  el = document.getElementById('spTotalBs');
  if (el) el.textContent = 'Bs ' + (d.total_general_bs || 0).toFixed(2);
  
  el = document.getElementById('spTotalUsd');
  if (el) el.textContent = '$' + (d.total_general_usd || 0).toFixed(2);
  
  el = document.getElementById('spCantPedidos');
  if (el) el.textContent = (d.pedidos || []).length;
  
  renderizarPedidos(d.pedidos || []);
  
  if (d.token_web && d.token_web !== '') {
    renderizarLink(d);
  }
}

function renderizarPedidos(pedidos) {
  var div = document.getElementById('divPedidos');
  if (!div) return;
  
  if (pedidos.length === 0) {
    div.innerHTML = '<div class="empty">' +
      '<div class="empty-icon"><i class="ti ti-clipboard-off"></i></div>' +
      '<div>No hay pedidos agregados</div>' +
      '<div class="mini-preview">Click en "Agregar Pedido" para comenzar</div>' +
      '</div>';
    return;
  }
  
  var html = '';
  for (var i = 0; i < pedidos.length; i++) {
    var p = pedidos[i];
    html += '<div class="pedido-card">' +
      '<div class="pedido-header">' +
      '<div class="pedido-info">' +
      '<div style="font-weight:500;margin-bottom:4px">' + p.codigo + ' - ' + p.receptor_nombre + '</div>' +
      '<div class="mini-preview">Entrega: ' + formatearFecha(p.fecha_entrega) + '</div>' +
      '<div class="mini-preview">Total: Bs ' + (p.total_bs || 0).toFixed(2) + '</div>' +
      '</div>' +
      '<div class="pedido-actions">' +
      '<button type="button" class="btn btn-sm" onclick="verPedido(' + p.pedido_id + ')" title="Ver detalle">' +
      '<i class="ti ti-eye"></i></button>' +
      '</div></div></div>';
  }
  div.innerHTML = html;
}

function renderizarLink(d) {
  var panel = document.getElementById('panelLink');
  if (panel) panel.style.display = 'block';
  
  var div = document.getElementById('divLinkInfo');
  if (!div) return;
  
  var url = 'https://miss-flores.com/pedido?t=' + d.token_web + '&m=' + (d.moneda_formulario || 'BOB');
  var expira = d.token_expira ? formatearFechaHora(d.token_expira) : '-';
  
  div.innerHTML = '<div class="link-box">' +
    '<div style="font-weight:500;margin-bottom:6px">URL del formulario:</div>' +
    '<div class="link-url">' + url + '</div>' +
    '<button type="button" class="btn btn-sm" onclick="copiarLink(\'' + url + '\')">' +
    '<i class="ti ti-copy"></i> Copiar Link</button>' +
    '<div class="mini-preview" style="margin-top:8px">Expira: ' + expira + '</div>' +
    '</div>';
}

function agregarPedido() {
  var modal = document.getElementById('modalPedido');
  if (modal) modal.classList.add('show');
  
  var hoy = new Date();
  hoy.setDate(hoy.getDate() + 1);
  var minFecha = hoy.toISOString().split('T')[0];
  var inp = document.getElementById('txFecha');
  if (inp) {
    inp.min = minFecha;
    inp.value = minFecha;
  }
}

function cerrarModalPedido() {
  var modal = document.getElementById('modalPedido');
  if (modal) modal.classList.remove('show');
}

function cambiarTipoEntrega() {
  var dd = document.getElementById('ddTipoEntrega');
  var grp = document.getElementById('grpDireccion');
  if (dd && grp) {
    grp.style.display = dd.value === 'DOMICILIO' ? 'block' : 'none';
  }
}

function guardarPedido() {
  mostrarAlerta('Funcionalidad en desarrollo', 'warn');
}

function editarCliente() {
  mostrarAlerta('Funcionalidad en desarrollo', 'warn');
}

function generarLink() {
  if (!prepedidoId) return;
  if (!confirm('¿Generar link web para el cliente?')) return;
  
  var hd = document.getElementById('hdAccion');
  if (hd) hd.value = 'GENERAR_LINK';
  
  hd = document.getElementById('hdData');
  if (hd) hd.value = prepedidoId;
  
  var btn = document.getElementById('btnPostBack');
  if (btn) btn.click();
}

function verPedido(pedidoId) {
  mostrarAlerta('Ver detalle pedido #' + pedidoId + ' - En desarrollo', 'warn');
}

function copiarLink(url) {
  if (navigator.clipboard) {
    navigator.clipboard.writeText(url).then(function() {
      mostrarAlerta('Link copiado al portapapeles', 'ok');
    });
  } else {
    mostrarAlerta('Link: ' + url, 'ok');
  }
}

function obtenerBadgeEstado(estado) {
  var clases = {
    'BORRADOR': 'badge-borrador',
    'FORM_ENVIADO': 'badge-enviado',
    'FORM_COMPLETADO': 'badge-enviado',
    'COMPROBANTE_ENVIADO': 'badge-completado',
    'PAGADO': 'badge-pagado',
    'WC_CREADO': 'badge-wc',
    'COMPLETADO': 'badge-pagado',
    'EXPIRADO': 'badge-expirado',
    'CANCELADO': 'badge-cancelado'
  };
  
  var etiquetas = {
    'BORRADOR': 'Borrador',
    'FORM_ENVIADO': 'Form Enviado',
    'FORM_COMPLETADO': 'Form Completado',
    'COMPROBANTE_ENVIADO': 'Comprobante Enviado',
    'PAGADO': 'Pagado',
    'WC_CREADO': 'WC Creado',
    'COMPLETADO': 'Completado',
    'EXPIRADO': 'Expirado',
    'CANCELADO': 'Cancelado'
  };
  
  var clase = clases[estado] || 'badge-borrador';
  var etiqueta = etiquetas[estado] || estado;
  
  return '<span class="badge ' + clase + '">' + etiqueta + '</span>';
}

function obtenerEtiquetaTipo(tipo) {
  var etiquetas = {
    'PRE_PEDIDO': 'Pre-Pedido',
    'VENTA_TIENDA': 'Venta Tienda',
    'VENTA_ANTIGUA': 'Venta Antigua'
  };
  return etiquetas[tipo] || tipo;
}

function formatearFecha(fecha) {
  if (!fecha) return '';
  var d = new Date(fecha);
  var dia = ('0' + d.getDate()).slice(-2);
  var mes = ('0' + (d.getMonth() + 1)).slice(-2);
  var año = d.getFullYear();
  return dia + '/' + mes + '/' + año;
}

function formatearFechaHora(fecha) {
  if (!fecha) return '';
  var d = new Date(fecha);
  return formatearFecha(fecha) + ' ' + 
    ('0' + d.getHours()).slice(-2) + ':' + 
    ('0' + d.getMinutes()).slice(-2);
}

function mostrarAlerta(msg, tipo) {
  var div = document.getElementById('divAlerta');
  if (div) {
    div.className = 'alerta show alerta-' + tipo;
    div.textContent = msg;
    setTimeout(function() {
      div.className = 'alerta';
    }, 5000);
  }
}
</script>
</body>
</html>
