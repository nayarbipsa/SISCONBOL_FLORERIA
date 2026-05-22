<%@ Page Language="VB" AutoEventWireup="true" CodeBehind="Login.aspx.vb" Inherits="SISCONBOL_FLORERIA.Login" %>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SISCONBOL — Ingresar</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/tabler-icons.min.css">
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f5f5f5;min-height:100vh;display:flex;align-items:center;justify-content:center}
.card{background:white;border-radius:12px;padding:40px;width:100%;max-width:380px;border:1px solid #e0e0e0;box-shadow:0 2px 8px rgba(0,0,0,.08)}
.logo{text-align:center;margin-bottom:28px}
.logo-title{font-size:24px;font-weight:600;color:#C2185B;margin-bottom:4px}
.logo-sub{font-size:13px;color:#757575}
.form-group{margin-bottom:18px}
.form-label{display:block;font-size:13px;font-weight:500;color:#424242;margin-bottom:6px}
.form-control{width:100%;padding:10px 12px;border:1px solid #e0e0e0;border-radius:8px;font-size:14px;outline:none;transition:border-color .2s;background:white;color:#424242}
.form-control:focus{border-color:#C2185B}
.form-help{font-size:11px;color:#9e9e9e;margin-top:4px}
.btn-login{width:100%;padding:12px;background:#C2185B;color:white;border:none;border-radius:8px;font-size:15px;font-weight:500;cursor:pointer;margin-top:8px}
.btn-login:hover{background:#880E4F}
.alerta{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:16px;border-left:3px solid #C62828;background:#FFEBEE;color:#C62828;display:none}
.alerta-warn{border-left-color:#E65100!important;background:#FFF3E0!important;color:#E65100!important}
.footer-txt{text-align:center;font-size:11px;color:#9e9e9e;margin-top:20px}
</style>
</head>
<body>
<form id="form1" runat="server">
  <div class="card">
    <div class="logo">
      <div class="logo-title">Floreria</div>
      <div class="logo-sub">Sistema Integral - SISCONBOL</div>
    </div>
    <div class="alerta" id="divAlerta"></div>
    <div class="form-group">
      <label class="form-label">Numero de carnet</label>
      <input type="text"     id="txCarnet"   name="txCarnet"   class="form-control" placeholder="Ej: 12345678" maxlength="8" autocomplete="off"/>
      <div class="form-help">Solo numeros, 7 u 8 digitos</div>
    </div>
    <div class="form-group">
      <label class="form-label">Contrasena</label>
      <input type="password" id="txPassword" name="txPassword" class="form-control" placeholder="........"    maxlength="50"/>
      <div class="form-help">Primera vez: su numero de carnet</div>
    </div>
    <input type="hidden" id="hdCarnet"   name="hdCarnet"/>
    <input type="hidden" id="hdPassword" name="hdPassword"/>
    <button type="button" class="btn-login" onclick="intentarLogin()">Ingresar</button>
    <asp:Button ID="btnPostBack" runat="server" Text="" Style="display:none" OnClick="btnLogin_Click"/>
    <div class="footer-txt">Problemas para ingresar? Contacte al administrador.</div>
  </div>
</form>
<script>
var elTxCarnet   = /** @type {HTMLInputElement}  */ (document.getElementById('txCarnet'));
var elTxPassword = /** @type {HTMLInputElement}  */ (document.getElementById('txPassword'));
var elHdCarnet   = /** @type {HTMLInputElement}  */ (document.getElementById('hdCarnet'));
var elHdPassword = /** @type {HTMLInputElement}  */ (document.getElementById('hdPassword'));

if (elTxCarnet) {
    elTxCarnet.addEventListener('input', function() {
        this.value = this.value.replace(/[^0-9]/g, '').slice(0, 8);
    });
}
document.addEventListener('keydown', function(/** @type {KeyboardEvent} */ e) {
    if (e.key === 'Enter') { intentarLogin(); }
});

function mostrarAlerta(/** @type {string} */ msg, /** @type {boolean} */ esWarn) {
    var d = document.getElementById('divAlerta');
    if (d) {
        d.innerHTML = msg;
        d.className = esWarn ? 'alerta alerta-warn' : 'alerta';
        d.style.display = 'block';
    }
}

function intentarLogin() {
    if (!elTxCarnet || !elTxPassword || !elHdCarnet || !elHdPassword) { return; }
    var carnet = elTxCarnet.value.trim();
    var pwd    = elTxPassword.value;
    if (carnet === '') {
        mostrarAlerta('Por favor ingrese su numero de carnet.', false);
        elTxCarnet.focus();
        return;
    }
    if (!/^\d{7,8}$/.test(carnet)) {
        mostrarAlerta('El carnet debe tener 7 u 8 digitos numericos.', false);
        elTxCarnet.focus();
        return;
    }
    if (pwd === '') {
        mostrarAlerta('Por favor ingrese su contrasena.', false);
        elTxPassword.focus();
        return;
    }
    elHdCarnet.value   = carnet;
    elHdPassword.value = pwd;
    var elBtn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (elBtn) { elBtn.click(); }
}
</script>
</body>
</html>
