<%@ Page Language="VB" AutoEventWireup="false" CodeFile="PrePedidos.aspx.vb" Inherits="Modulos_Pedidos_PrePedidos" %>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SISCONBOL - Crear Pre-Pedido</title>
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
.content{padding:20px;max-width:800px;margin:0 auto}
.panel{background:white;border:1px solid #e0e0e0;border-radius:10px;overflow:hidden;margin-bottom:16px}
.panel-head{padding:14px 18px;border-bottom:1px solid #e0e0e0}
.panel-title{font-size:15px;font-weight:500}
.panel-body{padding:20px}
.form-group{margin-bottom:16px}
.form-label{display:block;font-size:13px;font-weight:500;color:#616161;margin-bottom:6px}
.form-label.required:after{content:' *';color:#C62828}
.form-control{padding:9px 12px;border:1px solid #e0e0e0;border-radius:8px;font-size:14px;background:white;color:#424242;outline:none;transition:border-color .2s;width:100%;font-family:inherit}
.form-control:focus{border-color:#C2185B}
.form-control:disabled{background:#f5f5f5;color:#9e9e9e}
.form-help{font-size:12px;color:#757575;margin-top:4px}
.radio-group{display:flex;flex-direction:column;gap:10px}
.radio-item{display:flex;align-items:center;gap:8px;padding:10px 12px;border:1px solid #e0e0e0;border-radius:8px;cursor:pointer;transition:all .2s}
.radio-item:hover{background:#f9f9f9;border-color:#C2185B}
.radio-item input{margin:0}
.radio-item label{cursor:pointer;font-size:14px;flex:1}
.radio-item.checked{background:#FCE4EC;border-color:#C2185B}
.btn-group{display:flex;gap:10px;justify-content:flex-end;margin-top:20px}
.btn{padding:9px 18px;border-radius:8px;font-size:14px;border:1px solid #e0e0e0;background:white;color:#424242;cursor:pointer;display:inline-flex;align-items:center;gap:8px;transition:background .15s;text-decoration:none;font-family:inherit}
.btn:hover{background:#f5f5f5}
.btn-primary{background:#C2185B;border-color:#C2185B;color:white}
.btn-primary:hover{background:#880E4F}
.btn:disabled{opacity:.5;cursor:not-allowed}
.alerta{padding:12px 16px;border-radius:8px;font-size:13px;margin-bottom:16px;border-left:3px solid;display:none}
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
      <a href="Lista.aspx" class="btn" style="padding:6px;width:36px;height:36px;justify-content:center">
        <i class="ti ti-arrow-left"></i>
      </a>
      <div class="topbar-title">Crear Pre-Pedido</div>
    </div>

    <div class="content">
      <div id="divAlerta" class="alerta"></div>

      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">Datos del Cliente</div>
        </div>
        <div class="panel-body">
          
          <div class="form-group">
            <label class="form-label required">Celular</label>
            <input type="text" id="txCelular" name="txCelular" class="form-control" 
                   placeholder="77123456" maxlength="20" required/>
            <div class="form-help">Número de celular del cliente (7-8 dígitos)</div>
          </div>

          <div class="form-group">
            <label class="form-label">Nombre</label>
            <input type="text" id="txNombre" name="txNombre" class="form-control" 
                   placeholder="Juan" maxlength="200"/>
          </div>

          <div class="form-group">
            <label class="form-label">Apellidos</label>
            <input type="text" id="txApellidos" name="txApellidos" class="form-control" 
                   placeholder="Pérez García" maxlength="200"/>
          </div>

          <div class="form-group">
            <label class="form-label">Email</label>
            <input type="email" id="txEmail" name="txEmail" class="form-control" 
                   placeholder="cliente@ejemplo.com" maxlength="100"/>
          </div>

        </div>
      </div>

      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">Tipo de Registro</div>
        </div>
        <div class="panel-body">
          
          <div class="radio-group">
            <div class="radio-item checked" onclick="seleccionarTipo('PRE_PEDIDO', this)">
              <input type="radio" name="tipo" id="rdPrePedido" value="PRE_PEDIDO" checked/>
              <label for="rdPrePedido">
                <strong>Pre-Pedido</strong><br>
                <small style="color:#757575">Cliente completará datos en formulario web</small>
              </label>
            </div>

            <div class="radio-item" onclick="seleccionarTipo('VENTA_TIENDA', this)">
              <input type="radio" name="tipo" id="rdVentaTienda" value="VENTA_TIENDA"/>
              <label for="rdVentaTienda">
                <strong>Venta en Tienda</strong><br>
                <small style="color:#757575">Cliente pagó en tienda, crear pedido directamente</small>
              </label>
            </div>

            <div class="radio-item" onclick="seleccionarTipo('VENTA_ANTIGUA', this)">
              <input type="radio" name="tipo" id="rdVentaAntigua" value="VENTA_ANTIGUA"/>
              <label for="rdVentaAntigua">
                <strong>Venta Antigua</strong><br>
                <small style="color:#757575">Registro histórico de venta anterior</small>
              </label>
            </div>
          </div>

        </div>
      </div>

      <div class="btn-group">
        <a href="Lista.aspx" class="btn">
          <i class="ti ti-x"></i> Cancelar
        </a>
        <button type="button" class="btn btn-primary" onclick="crearPrePedido()" id="btnCrear">
          <i class="ti ti-check"></i> Crear Pre-Pedido
        </button>
      </div>

    </div>
  </div>
</div>

<input type="hidden" id="hdAccion" name="hdAccion"/>
<input type="hidden" id="hdCelular" name="hdCelular"/>
<input type="hidden" id="hdNombre" name="hdNombre"/>
<input type="hidden" id="hdApellidos" name="hdApellidos"/>
<input type="hidden" id="hdEmail" name="hdEmail"/>
<input type="hidden" id="hdTipo" name="hdTipo" value="PRE_PEDIDO"/>
<asp:Button ID="btnPostBack" runat="server" Style="display:none" OnClick="btnPostBack_Click"/>
</form>

<div id="resultData" style="display:none;"><%=ResultData%></div>

<script type="text/javascript">
window.addEventListener('DOMContentLoaded', function() {
  cargarDatosUsuario();
  verificarResultado();
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

function seleccionarTipo(tipo, elemento) {
  var items = document.querySelectorAll('.radio-item');
  for (var i = 0; i < items.length; i++) {
    items[i].classList.remove('checked');
  }
  elemento.classList.add('checked');
  
  var radio = elemento.querySelector('input[type="radio"]');
  if (radio) radio.checked = true;
  
  var hd = document.getElementById('hdTipo');
  if (hd) hd.value = tipo;
}

function crearPrePedido() {
  var celular = document.getElementById('txCelular');
  if (!celular || !celular.value.trim()) {
    mostrarAlerta('El celular es obligatorio', 'error');
    if (celular) celular.focus();
    return;
  }
  
  var cel = celular.value.trim();
  if (cel.length < 7 || cel.length > 8) {
    mostrarAlerta('El celular debe tener 7 u 8 dígitos', 'error');
    celular.focus();
    return;
  }
  
  if (!/^[67]\d+$/.test(cel)) {
    mostrarAlerta('El celular debe comenzar con 6 o 7', 'error');
    celular.focus();
    return;
  }
  
  var btn = document.getElementById('btnCrear');
  if (btn) btn.disabled = true;
  
  var hd = document.getElementById('hdAccion');
  if (hd) hd.value = 'CREAR';
  
  hd = document.getElementById('hdCelular');
  if (hd) hd.value = cel;
  
  var nombre = document.getElementById('txNombre');
  hd = document.getElementById('hdNombre');
  if (hd && nombre) hd.value = nombre.value.trim();
  
  var apellidos = document.getElementById('txApellidos');
  hd = document.getElementById('hdApellidos');
  if (hd && apellidos) hd.value = apellidos.value.trim();
  
  var email = document.getElementById('txEmail');
  hd = document.getElementById('hdEmail');
  if (hd && email) hd.value = email.value.trim();
  
  var postback = document.getElementById('btnPostBack');
  if (postback) postback.click();
}

function verificarResultado() {
  var divResult = document.getElementById('resultData');
  if (!divResult) return;
  
  var resultText = divResult.textContent || divResult.innerText;
  if (!resultText || resultText.trim() === '') return;
  
  try {
    var result = JSON.parse(resultText);
    if (result.exito) {
      mostrarAlerta(result.mensaje, 'ok');
      setTimeout(function() {
        window.location.href = 'Detalle.aspx?id=' + result.prepedido_id;
      }, 1000);
    } else {
      mostrarAlerta(result.mensaje, 'error');
      var btn = document.getElementById('btnCrear');
      if (btn) btn.disabled = false;
    }
  } catch(e) {
    console.error('Error parseando resultado:', e);
  }
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
