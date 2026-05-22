<%@ Page Language="VB" AutoEventWireup="true" CodeBehind="CambiarPassword.aspx.vb" Inherits="SISCONBOL_FLORERIA.CambiarPassword" %>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SISCONBOL — Cambiar contrasena</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/tabler-icons.min.css">
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f5f5f5;min-height:100vh;display:flex;align-items:center;justify-content:center}
.card{background:white;border-radius:12px;padding:36px;width:100%;max-width:400px;border:1px solid #e0e0e0;box-shadow:0 2px 8px rgba(0,0,0,.08)}
.logo{text-align:center;margin-bottom:24px}
.logo-title{font-size:20px;font-weight:600;color:#C2185B}
.logo-sub{font-size:13px;color:#757575;margin-top:4px}
.aviso{padding:10px 14px;background:#E6F1FB;border-left:3px solid #185FA5;border-radius:0 8px 8px 0;font-size:13px;color:#0C447C;margin-bottom:20px}
.form-group{margin-bottom:16px;position:relative}
.form-label{display:block;font-size:13px;font-weight:500;color:#424242;margin-bottom:6px}
.req{color:#C2185B}
.form-control{width:100%;padding:10px 40px 10px 12px;border:1px solid #e0e0e0;border-radius:8px;font-size:14px;outline:none;transition:border-color .2s;background:white;color:#424242}
.form-control:focus{border-color:#C2185B}
.campo-error{border-color:#C62828!important}
.campo-ok{border-color:#2E7D32!important}
.form-error{font-size:11px;color:#C62828;margin-top:4px;display:none}
.form-error.show{display:block}
.eye-btn{position:absolute;right:10px;top:36px;background:none;border:none;cursor:pointer;color:#9e9e9e;padding:2px}
.pwd-bar{height:4px;border-radius:2px;background:#e0e0e0;margin-top:6px;overflow:hidden}
.pwd-fill{height:100%;border-radius:2px;width:0;transition:width .3s,background .3s}
.pwd-hint{font-size:11px;color:#9e9e9e;margin-top:4px}
.btn-guardar{width:100%;padding:12px;background:#C2185B;color:white;border:none;border-radius:8px;font-size:15px;font-weight:500;cursor:pointer;margin-top:8px}
.btn-guardar:hover{background:#880E4F}
.alerta{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:16px;display:none;border-left:3px solid}
.alerta-error{background:#FFEBEE;border-color:#C62828;color:#C62828}
.alerta-ok{background:#E8F5E9;border-color:#2E7D32;color:#2E7D32}
.alerta.show{display:block}
</style>
</head>
<body>
<form id="form1" runat="server">
  <div class="card">
    <div class="logo">
      <div class="logo-title">Cambiar contrasena</div>
      <div class="logo-sub">SISCONBOL — Floreria</div>
    </div>
    <div class="aviso">
      <i class="ti ti-info-circle" style="font-size:15px;vertical-align:-2px;margin-right:6px" aria-hidden="true"></i>
      Por seguridad debe establecer una nueva contrasena antes de continuar.
    </div>
    <div class="alerta" id="divAlerta"></div>
    <div class="form-group">
      <label class="form-label">Contrasena actual <span class="req">*</span></label>
      <input type="password" id="txActual"    name="txActual"    class="form-control" placeholder="Su contrasena actual" maxlength="50"/>
      <button type="button" class="eye-btn" onclick="toggleVer('txActual','icoActual')" aria-label="Mostrar">
        <i class="ti ti-eye" id="icoActual" style="font-size:16px" aria-hidden="true"></i>
      </button>
      <div class="form-error" id="errActual">Ingrese su contrasena actual.</div>
    </div>
    <div class="form-group">
      <label class="form-label">Nueva contrasena <span class="req">*</span></label>
      <input type="password" id="txNueva"     name="txNueva"     class="form-control" placeholder="Minimo 6 caracteres" maxlength="50"/>
      <button type="button" class="eye-btn" onclick="toggleVer('txNueva','icoNueva')" aria-label="Mostrar">
        <i class="ti ti-eye" id="icoNueva" style="font-size:16px" aria-hidden="true"></i>
      </button>
      <div class="pwd-bar"><div class="pwd-fill" id="pwdFill"></div></div>
      <div class="pwd-hint" id="pwdHint">Minimo 6 caracteres</div>
      <div class="form-error" id="errNueva">La contrasena debe tener al menos 6 caracteres.</div>
    </div>
    <div class="form-group">
      <label class="form-label">Confirmar nueva contrasena <span class="req">*</span></label>
      <input type="password" id="txConfirmar" name="txConfirmar" class="form-control" placeholder="Repita la nueva contrasena" maxlength="50"/>
      <button type="button" class="eye-btn" onclick="toggleVer('txConfirmar','icoConf')" aria-label="Mostrar">
        <i class="ti ti-eye" id="icoConf" style="font-size:16px" aria-hidden="true"></i>
      </button>
      <div class="form-error" id="errConfirmar">Las contrasenas no coinciden.</div>
    </div>
    <input type="hidden" id="hdActual" name="hdActual"/>
    <input type="hidden" id="hdNueva"  name="hdNueva"/>
    <button type="button" class="btn-guardar" onclick="intentarCambiar()">
      <i class="ti ti-lock" style="font-size:16px;vertical-align:-2px;margin-right:6px" aria-hidden="true"></i>
      Guardar nueva contrasena
    </button>
    <asp:Button ID="btnPostBack" runat="server" Text="" Style="display:none" OnClick="btnGuardar_Click"/>
  </div>
</form>
<script>
var elTxActual    = /** @type {HTMLInputElement} */ (document.getElementById('txActual'));
var elTxNueva     = /** @type {HTMLInputElement} */ (document.getElementById('txNueva'));
var elTxConfirmar = /** @type {HTMLInputElement} */ (document.getElementById('txConfirmar'));
var elHdActual    = /** @type {HTMLInputElement} */ (document.getElementById('hdActual'));
var elHdNueva     = /** @type {HTMLInputElement} */ (document.getElementById('hdNueva'));
var elPwdFill     = document.getElementById('pwdFill');
var elPwdHint     = document.getElementById('pwdHint');

if (elTxNueva) {
    elTxNueva.addEventListener('input', function() {
        evaluarFortaleza(this.value);
    });
}

function toggleVer(/** @type {string} */ inputId, /** @type {string} */ iconId) {
    var inp  = /** @type {HTMLInputElement} */ (document.getElementById(inputId));
    var icon = document.getElementById(iconId);
    if (!inp) { return; }
    if (inp.type === 'password') {
        inp.type = 'text';
        if (icon) { icon.className = 'ti ti-eye-off'; }
    } else {
        inp.type = 'password';
        if (icon) { icon.className = 'ti ti-eye'; }
    }
}

function evaluarFortaleza(/** @type {string} */ v) {
    if (!elPwdFill || !elPwdHint) { return; }
    var pct = 0; var color = '#C62828'; var msg = 'Muy corta';
    if (v.length >= 6)  { pct = 33;  color = '#E65100'; msg = 'Debil';   }
    if (v.length >= 8)  { pct = 66;  color = '#F57C00'; msg = 'Regular'; }
    if (v.length >= 10) { pct = 100; color = '#2E7D32'; msg = 'Fuerte';  }
    elPwdFill.style.width      = pct + '%';
    elPwdFill.style.background = color;
    elPwdHint.textContent      = msg;
    elPwdHint.style.color      = color;
}

function marcarCampo(/** @type {string} */ id, /** @type {string} */ estado) {
    var el = document.getElementById(id);
    if (!el) { return; }
    el.className = 'form-control' + (estado === 'error' ? ' campo-error' : estado === 'ok' ? ' campo-ok' : '');
}

function mostrarErr(/** @type {string} */ id, /** @type {boolean} */ show) {
    var el = document.getElementById(id);
    if (el) { el.className = show ? 'form-error show' : 'form-error'; }
}

function mostrarAlerta(/** @type {string} */ msg, /** @type {boolean} */ esOk) {
    var d = document.getElementById('divAlerta');
    if (d) {
        d.innerHTML = msg;
        d.className = esOk ? 'alerta alerta-ok show' : 'alerta alerta-error show';
    }
}

function intentarCambiar() {
    if (!elTxActual || !elTxNueva || !elTxConfirmar || !elHdActual || !elHdNueva) { return; }
    var actual = elTxActual.value.replace(/[<>"';\\\/]/g, '');
    var nueva  = elTxNueva.value.replace(/[<>"';\\\/]/g, '');
    var conf   = elTxConfirmar.value.replace(/[<>"';\\\/]/g, '');
    var valido = true;
    if (actual === '') {
        marcarCampo('txActual', 'error'); mostrarErr('errActual', true); valido = false;
    } else { marcarCampo('txActual', 'ok'); mostrarErr('errActual', false); }
    if (nueva.length < 6) {
        marcarCampo('txNueva', 'error'); mostrarErr('errNueva', true); valido = false;
    } else { marcarCampo('txNueva', 'ok'); mostrarErr('errNueva', false); }
    if (conf !== nueva || conf === '') {
        marcarCampo('txConfirmar', 'error'); mostrarErr('errConfirmar', true); valido = false;
    } else { marcarCampo('txConfirmar', 'ok'); mostrarErr('errConfirmar', false); }
    if (!valido) { return; }
    elHdActual.value = actual;
    elHdNueva.value  = nueva;
    var elBtn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (elBtn) { elBtn.click(); }
}
</script>
</body>
</html>
