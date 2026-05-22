<%@ Page Language="VB" AutoEventWireup="false" CodeFile="Lista.aspx.vb" Inherits="Modulos_Pedidos_Lista" %>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SISCONBOL - Pre-Pedidos</title>
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
.topbar-title{font-size:15px;font-weight:500;flex:1}
.content{padding:20px}
.panel{background:white;border:1px solid #e0e0e0;border-radius:10px;overflow:hidden;margin-bottom:16px}
.panel-head{padding:12px 18px;border-bottom:1px solid #e0e0e0;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px}
.panel-title{font-size:14px;font-weight:500}
.btn{padding:7px 14px;border-radius:8px;font-size:13px;border:1px solid #e0e0e0;background:white;color:#424242;cursor:pointer;display:inline-flex;align-items:center;gap:6px;transition:background .15s;text-decoration:none}
.btn:hover{background:#f5f5f5}
.btn-primary{background:#C2185B;border-color:#C2185B;color:white}
.btn-primary:hover{background:#880E4F}
.btn-sm{padding:4px 9px;font-size:12px}
.form-control{padding:8px 10px;border:1px solid #e0e0e0;border-radius:8px;font-size:13px;background:white;color:#424242;outline:none;transition:border-color .2s;width:100%}
.form-control:focus{border-color:#C2185B}
.filtros{display:flex;gap:10px;padding:12px 18px;border-bottom:1px solid #e0e0e0;flex-wrap:wrap;align-items:center}
.filtros>*{flex:0 0 auto}
.filtros .form-control{width:auto;min-width:150px}
.tabla{width:100%;border-collapse:collapse;font-size:13px}
.tabla th{padding:9px 12px;background:#f5f5f5;font-size:11px;font-weight:500;text-transform:uppercase;letter-spacing:.4px;color:#757575;text-align:left;border-bottom:1px solid #e0e0e0}
.tabla td{padding:9px 12px;border-bottom:1px solid #f0f0f0;vertical-align:middle}
.tabla tr:last-child td{border-bottom:none}
.tabla tr:hover td{background:#FFF8FB;cursor:pointer}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 8px;border-radius:10px;font-size:11px;font-weight:500}
.badge-borrador{background:#F1EFE8;color:#5F5E5A}
.badge-enviado{background:#E6F1FB;color:#0C447C}
.badge-pagado{background:#EAF3DE;color:#27500A}
.paginacion{display:flex;gap:8px;padding:12px 18px;justify-content:center;align-items:center}
.pag-info{font-size:12px;color:#757575}
.codigo{font-family:monospace;font-size:12px;background:#f5f5f5;padding:2px 6px;border-radius:4px}
.empty{text-align:center;padding:40px 20px;color:#9e9e9e}
.alerta{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:12px;border-left:3px solid;display:none}
.alerta.show{display:block}
.alerta-error{background:#FFEBEE;border-color:#C62828;color:#C62828}
.alerta-ok{background:#E8F5E9;border-color:#2E7D32;color:#2E7D32}
</style>
</head>
<body>
<form id="form1" runat="server">
<div class="layout">
  <aside class="sidebar">
    <div class="sb-logo">
      <div class="sb-logo-title">Floreria</div>
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
      <div class="topbar-title">Pre-Pedidos</div>
      <a href="#" class="btn btn-primary"><i class="ti ti-plus"></i> Nuevo Pre-Pedido</a>
    </div>
    <div class="content">
      <div id="divAlerta" class="alerta"></div>
      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">Lista de Pre-Pedidos</div>
        </div>
        <div class="filtros">
          <select id="ddEstado" class="form-control">
            <option value="">-- Todos los estados --</option>
            <option value="BORRADOR">Borrador</option>
            <option value="PAGADO">Pagado</option>
          </select>
          <input type="text" id="txBuscar" class="form-control" placeholder="Buscar..."/>
          <button type="button" class="btn">Buscar</button>
        </div>
        <div id="divTabla"></div>
        <div class="paginacion" id="divPaginacion"></div>
      </div>
    </div>
  </div>
</div>
<input type="hidden" id="hdAccion" name="hdAccion"/>
<asp:Button ID="btnPostBack" runat="server" Style="display:none"/>
</form>
<div id="jsonData" style="display:none;"><%=JsonData%></div>
<script type="text/javascript">
var datosGlobales = null;
window.addEventListener('DOMContentLoaded', function() {
  console.log('DOM cargado');
  cargarDatosUsuario();
  cargarDatosDesdeDiv();
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
function cargarDatosDesdeDiv() {
  var divJson = document.getElementById('jsonData');
  if (!divJson) {
    console.error('div jsonData no encontrado');
    return;
  }
  var jsonText = divJson.textContent || divJson.innerText;
  console.log('JSON text length:', jsonText.length);
  if (!jsonText || jsonText.trim() === '') {
    console.log('No hay datos JSON');
    renderizarTabla([]);
    return;
  }
  try {
    datosGlobales = JSON.parse(jsonText);
    console.log('Datos parseados:', datosGlobales.length);
    renderizarTabla(datosGlobales);
  } catch(e) {
    console.error('Error parseando JSON:', e);
    mostrarAlerta('Error cargando datos', 'error');
  }
}
function renderizarTabla(datos) {
  var div = document.getElementById('divTabla');
  if (!div) return;
  if (!datos || datos.length === 0) {
    div.innerHTML = '<div class="empty">No se encontraron pre-pedidos</div>';
    return;
  }
  var html = '<table class="tabla"><thead><tr><th>Codigo</th><th>Cliente</th><th>Estado</th><th>Total</th></tr></thead><tbody>';
  for (var i = 0; i < datos.length; i++) {
    var d = datos[i];
    html += '<tr onclick="verDetalle(' + d.prepedido_id + ')">' +
      '<td><span class="codigo">' + d.codigo + '</span></td>' +
      '<td>' + (d.cliente_nombre || 'Sin nombre') + '<br><small>' + d.cliente_celular + '</small></td>' +
      '<td><span class="badge badge-' + d.estado.toLowerCase() + '">' + d.estado + '</span></td>' +
      '<td>Bs ' + d.total_general_bs.toFixed(2) + '</td>' +
      '</tr>';
  }
  html += '</tbody></table>';
  div.innerHTML = html;
}
function verDetalle(id) {
  window.location.href = 'Detalle.aspx?id=' + id;
}
function mostrarAlerta(msg, tipo) {
  var div = document.getElementById('divAlerta');
  if (div) {
    div.className = 'alerta show alerta-' + tipo;
    div.textContent = msg;
  }
}
</script>
</body>
</html>
