

<%@ Page Language="VB" AutoEventWireup="false" CodeFile="PrePedido_Crear.aspx.vb" Inherits="Modulos_Pedidos_PrePedido_Crear" ResponseEncoding="UTF-8" %>

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
.panel-head{padding:12px 18px;border-bottom:1px solid #e0e0e0;display:flex;justify-content:space-between;align-items:center}
.panel-title{font-size:14px;font-weight:500}
.form-body{padding:18px}
.form-group{margin-bottom:16px}
.form-label{display:block;font-size:13px;font-weight:500;margin-bottom:5px;color:#424242}
.form-control{padding:8px 10px;border:1px solid #e0e0e0;border-radius:8px;font-size:13px;background:white;color:#424242;outline:none;transition:border-color .2s;width:100%}
.form-control:focus{border-color:#C2185B}
.req{color:#C2185B}
.btn{padding:7px 14px;border-radius:8px;font-size:13px;border:1px solid #e0e0e0;background:white;color:#424242;cursor:pointer;display:inline-flex;align-items:center;gap:6px;transition:background .15s}
.btn:hover{background:#f5f5f5}
.btn-primary{background:#C2185B;border-color:#C2185B;color:white}
.btn-primary:hover{background:#880E4F}
.alerta{padding:12px 16px;border-radius:8px;margin-bottom:16px;font-size:13px;display:none}
.alerta.show{display:block}
.alerta-exito{background:#E8F5E9;color:#2E7D32;border-left:4px solid #4CAF50}
.alerta-error{background:#FFEBEE;color:#C62828;border-left:4px solid #F44336}
.pais-badge{display:none;padding:3px 10px;border-radius:12px;font-size:12px;font-weight:600;margin-top:5px;width:fit-content}
.pais-bolivia{background:#FFF9C4;color:#F57F17;border:1px solid #F9A825}
.pais-peru{background:#FFEBEE;color:#C62828;border:1px solid #EF9A9A}
.pais-intl{background:#E3F2FD;color:#1565C0;border:1px solid #90CAF9}
.form-help{font-size:11px;color:#9e9e9e;margin-top:4px}
.grid-2{display:grid;grid-template-columns:1fr 1fr;gap:14px}
@media(max-width:600px){.grid-2{grid-template-columns:1fr}}
</style>
</head>
<body>
<form id="form1" runat="server">
<div class="layout">

  <!-- SIDEBAR -->
  <aside class="sidebar" id="sidebar">
    <div class="sb-logo">
      <div class="sb-logo-title">Miss Flores</div>
      <div class="sb-logo-sub">Sistema de Control</div>
    </div>
    <div class="sb-user">
      <div class="sb-avatar" id="spIniciales">--</div>
      <div>
        <div class="sb-user-name" id="spNombre">Cargando...</div>
        <div class="sb-user-role" id="spRol"></div>
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

  <!-- CONTENIDO PRINCIPAL -->
  <div class="main">
    <header class="topbar">
      <div class="topbar-title">
        <i class="ti ti-shopping-cart-plus" style="font-size:17px;vertical-align:-3px;margin-right:8px;color:#C2185B" aria-hidden="true"></i>
        Crear Pre-Pedido
      </div>
      <div style="display:flex;align-items:center;gap:8px">
        <div class="sb-avatar" id="spInicialesTop" style="background:#FCE4EC;color:#880E4F;font-size:12px">--</div>
        <span style="font-size:13px" id="spNombreTop"></span>
      </div>
    </header>

    <div class="content">

      <div class="alerta" id="divAlerta"><%=MensajeAlerta%></div>

      <div class="panel">
        <div class="panel-head">
          <div class="panel-title">Datos del cliente</div>
        </div>
        <div class="form-body">
          <div class="grid-2">

            <div class="form-group">
              <label class="form-label">Celular <span class="req">*</span></label>
              <input type="text" id="txCelular" name="txCelular" class="form-control"
                     placeholder="71234567 o +591 71234567"
                     maxlength="25" onkeyup="detectarPais()" value="<%=ValorCelular%>" />
              <div id="indicadorPais" class="pais-badge"></div>
              <div class="form-help">Bolivia: 71234567 | Peru: +51 987654321 | Internacional: +codigo numero</div>
            </div>

            <div class="form-group">
              <label class="form-label">Tipo de Registro <span class="req">*</span></label>
              <select id="selTipo" name="selTipo" class="form-control">
                <option value="PRE_PEDIDO">Pre-Pedido (Link Web)</option>
                <option value="VENTA_TIENDA">Venta Tienda</option>
                <option value="VENTA_ANTIGUA">Venta Antigua</option>
              </select>
            </div>

            <div class="form-group">
              <label class="form-label">Nombre</label>
              <input type="text" id="txNombre" name="txNombre" class="form-control" placeholder="Juan" />
            </div>

            <div class="form-group">
              <label class="form-label">Apellidos</label>
              <input type="text" id="txApellidos" name="txApellidos" class="form-control" placeholder="Perez Garcia" />
            </div>

            <div class="form-group">
              <label class="form-label">Email</label>
              <input type="email" id="txEmail" name="txEmail" class="form-control" placeholder="juan@email.com" />
            </div>

          </div>

          <input type="hidden" id="hdPaisId" name="hdPaisId" value="" />

          <button type="button" class="btn btn-primary" onclick="enviarFormulario()">
            <i class="ti ti-plus" aria-hidden="true"></i> Crear Pre-Pedido
          </button>
        </div>
      </div>

    </div><!-- /content -->
  </div><!-- /main -->
</div><!-- /layout -->

<!-- Botones ocultos para postback -->
<asp:Button ID="btnPostBack"     runat="server" Style="display:none" OnClick="btnPostBack_Click" />
<asp:Button ID="btnCerrarSesion" runat="server" Style="display:none" OnClick="btnCerrarSesion_Click" />

</form>

<script type="text/javascript">
// @ts-nocheck

// Cargar datos de sesion desde cookie
window.addEventListener('DOMContentLoaded', function() {
    var nombre = '';
    var rol = '';
    var iniciales = '--';
    try {
        var cookies = document.cookie.split(';');
        for (var i = 0; i < cookies.length; i++) {
            var c = cookies[i].trim();
            if (c.indexOf('SISCONBOL_NOMBRE=') === 0) nombre = decodeURIComponent(c.substring(17));
            if (c.indexOf('SISCONBOL_ROL=') === 0) rol = decodeURIComponent(c.substring(14));
        }
        if (nombre) {
            var partes = nombre.split(' ');
            iniciales = partes.length >= 2 ? (partes[0][0] + partes[1][0]).toUpperCase() : nombre.substring(0, 2).toUpperCase();
        }
    } catch(e) {}
    var spN = document.getElementById('spNombre');
    var spR = document.getElementById('spRol');
    var spI = document.getElementById('spIniciales');
    var spNT = document.getElementById('spNombreTop');
    var spIT = document.getElementById('spInicialesTop');
    if (spN) spN.textContent = nombre || 'Usuario';
    if (spR) spR.textContent = rol || '';
    if (spI) spI.textContent = iniciales;
    if (spNT) spNT.textContent = nombre || '';
    if (spIT) spIT.textContent = iniciales;

    // Mostrar alerta si hay mensaje
    var divAlerta = document.getElementById('divAlerta');
    if (divAlerta && divAlerta.textContent.trim() !== '') {
        var esMensajeExito = divAlerta.textContent.indexOf('Pre-Pedido creado') >= 0;
        divAlerta.className = 'alerta ' + (esMensajeExito ? 'alerta-exito' : 'alerta-error') + ' show';
    }
});

function detectarPais() {
    var input = document.getElementById('txCelular');
    var indicador = document.getElementById('indicadorPais');
    var hdPais = document.getElementById('hdPaisId');
    if (!input || !indicador || !hdPais) return;

    var tel = input.value.trim().replace(/[\s\-()]/g, '');
    if (!tel) { indicador.style.display = 'none'; hdPais.value = ''; return; }

    var paisId = '';
    var paisNombre = '';
    var css = 'pais-badge';

    if (tel.match(/^\+?591\d{7,8}$/)) {
        paisId = '1'; paisNombre = 'Bolivia (+591)'; css += ' pais-bolivia';
    } else if (tel.match(/^[67]\d{6,7}$/)) {
        paisId = '1'; paisNombre = 'Bolivia'; css += ' pais-bolivia';
    } else if (tel.match(/^\+?51\d{9}$/)) {
        paisId = '2'; paisNombre = 'Peru (+51)'; css += ' pais-peru';
    } else if (tel.match(/^\+\d{1,4}\d{7,15}$/)) {
        paisId = ''; paisNombre = 'Internacional'; css += ' pais-intl';
    } else {
        indicador.style.display = 'none'; hdPais.value = ''; return;
    }

    indicador.textContent = paisNombre;
    indicador.className = css;
    indicador.style.display = 'inline-block';
    hdPais.value = paisId;
}

function enviarFormulario() {
    var input = document.getElementById('txCelular');
    if (!input || !input.value.trim()) {
        alert('El celular es obligatorio');
        return;
    }
    document.getElementById('<%= btnPostBack.ClientID %>').click();
}

function cerrarSesion() {
    var hd = document.getElementById('hdCerrar');
    if (hd) hd.value = '1';
    document.getElementById('<%= btnCerrarSesion.ClientID %>').click();
}

function toggleHijos(id) {
    var el = document.getElementById(id);
    if (el) el.classList.toggle('open');
}
</script>
</body>
</html>
