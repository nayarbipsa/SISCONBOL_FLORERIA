<%@ Page Language="VB" AutoEventWireup="false" CodeFile="Usuarios.aspx.vb" Inherits="Modulos_Config_Usuarios" %>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SISCONBOL - Usuarios</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/tabler-icons.min.css">
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f5f5f5;color:#424242}
.topbar{background:white;border-bottom:1px solid #e0e0e0;padding:0 24px;height:52px;display:flex;align-items:center;position:sticky;top:0;z-index:10}
.topbar-title{font-size:15px;font-weight:500}
.content{padding:24px}
.panel{background:white;border:1px solid #e0e0e0;border-radius:10px;overflow:hidden;margin-bottom:20px}
.panel-head{padding:14px 18px;border-bottom:1px solid #e0e0e0;display:flex;justify-content:space-between;align-items:center}
.panel-title{font-size:15px;font-weight:500}
.filtros{display:flex;gap:10px;padding:12px 18px;border-bottom:1px solid #e0e0e0;flex-wrap:wrap;align-items:center}
.form-control{padding:8px 12px;border:1px solid #e0e0e0;border-radius:8px;font-size:13px;outline:none;transition:border-color .2s;background:white;color:#424242}
.form-control:focus{border-color:#C2185B}
.campo-error{border-color:#C62828!important;background:#fff8f8!important}
.campo-ok{border-color:#2E7D32!important}
.form-error{font-size:11px;color:#C62828;margin-top:3px;display:none}
.form-error.show{display:block}
.btn{padding:8px 16px;border-radius:8px;font-size:13px;border:1px solid #e0e0e0;background:white;color:#424242;cursor:pointer;display:inline-flex;align-items:center;gap:6px}
.btn:hover{background:#f5f5f5}
.btn-primary{background:#C2185B;border-color:#C2185B;color:white}
.btn-primary:hover{background:#880E4F}
.btn-sm{padding:5px 10px;font-size:12px}
.btn-danger{background:#FFEBEE;border-color:#C62828;color:#C62828}
.btn-success{background:#E8F5E9;border-color:#2E7D32;color:#2E7D32}
.tabla{width:100%;border-collapse:collapse;font-size:13px}
.tabla th{padding:10px 14px;background:#f5f5f5;font-size:11px;font-weight:500;text-transform:uppercase;letter-spacing:.4px;color:#757575;text-align:left;border-bottom:1px solid #e0e0e0}
.tabla td{padding:10px 14px;border-bottom:1px solid #f0f0f0;vertical-align:middle}
.tabla tr:last-child td{border-bottom:none}
.tabla tr:hover td{background:#FFF8FB}
.avatar{width:32px;height:32px;border-radius:50%;background:#FCE4EC;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:600;color:#880E4F;flex-shrink:0}
.badge{display:inline-block;padding:3px 9px;border-radius:10px;font-size:11px;font-weight:500}
.badge-rosa{background:#FBEAF0;color:#72243E}
.badge-azul{background:#E6F1FB;color:#0C447C}
.badge-verde{background:#EAF3DE;color:#3B6D11}
.badge-gris{background:#F1EFE8;color:#5F5E5A}
.badge-ok{background:#EAF3DE;color:#27500A}
.badge-bloq{background:#FCEBEB;color:#791F1F}
.badge-warn{background:#FAEEDA;color:#633806}
.badge-inac{background:#F1EFE8;color:#5F5E5A}
.modal-bg{display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:200;align-items:center;justify-content:center}
.modal-bg.show{display:flex}
.modal{background:white;border-radius:12px;width:100%;max-width:560px;max-height:90vh;overflow-y:auto}
.modal-head{padding:16px 20px;border-bottom:1px solid #e0e0e0;display:flex;justify-content:space-between;align-items:center;background:white;position:sticky;top:0}
.modal-title{font-size:16px;font-weight:500}
.modal-close{background:none;border:none;font-size:22px;cursor:pointer;color:#9e9e9e;line-height:1}
.modal-body{padding:20px}
.modal-footer{padding:14px 20px;border-top:1px solid #e0e0e0;display:flex;justify-content:flex-end;gap:8px;background:#fafafa}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:14px}
.form-row-full{display:grid;grid-template-columns:1fr;margin-bottom:14px}
.form-group{display:flex;flex-direction:column;gap:5px}
.form-label{font-size:12px;font-weight:500;color:#616161}
.req{color:#C2185B}
.form-help{font-size:11px;color:#9e9e9e}
.alerta{padding:10px 14px;border-radius:8px;font-size:13px;margin-bottom:14px;border-left:3px solid;display:none}
.alerta.show{display:block}
.alerta-error{background:#FFEBEE;border-color:#C62828;color:#C62828}
.alerta-ok{background:#E8F5E9;border-color:#2E7D32;color:#2E7D32}
.alerta-info{background:#E6F1FB;border-color:#185FA5;color:#0C447C}
</style>
</head>
<body>
<form id="form1" runat="server">

<div class="topbar">
  <div class="topbar-title">
    <i class="ti ti-users" style="font-size:18px;vertical-align:-3px;margin-right:6px;color:#C2185B" aria-hidden="true"></i>
    Gestion de Usuarios
  </div>
</div>

<div class="content">
  <div class="alerta alerta-info show" style="margin-bottom:20px">
    <i class="ti ti-info-circle" style="font-size:14px;vertical-align:-2px;margin-right:6px" aria-hidden="true"></i>
    La contrasena inicial de cada usuario es su numero de carnet.
  </div>
  <div class="panel">
    <div class="panel-head">
      <div class="panel-title">Usuarios registrados</div>
      <button type="button" class="btn btn-primary" onclick="abrirModalNuevo()">
        <i class="ti ti-plus" aria-hidden="true"></i> Nuevo usuario
      </button>
    </div>
    <div class="filtros">
      <input type="text" id="txBuscar" class="form-control" style="width:200px" placeholder="Nombre o carnet..."/>
      <select id="selRol" class="form-control" style="width:150px"></select>
      <select id="selEstado" class="form-control" style="width:130px">
        <option value="">Todos</option>
        <option value="ACTIVO">Activos</option>
        <option value="BLOQUEADO">Bloqueados</option>
        <option value="VENCIDO">Vencidos</option>
        <option value="VENCE_HOY">Vencen hoy</option>
      </select>
      <button type="button" class="btn" onclick="filtrarTabla()">
        <i class="ti ti-search" aria-hidden="true"></i> Filtrar
      </button>
    </div>
    <div id="divTabla"><%=TablaHtml%></div>
  </div>
</div>

<input type="hidden" id="hdAccion"    name="hdAccion"    value=""/>
<input type="hidden" id="hdUsuarioId" name="hdUsuarioId" value=""/>
<input type="hidden" id="hdTipoId"    name="hdTipoId"    value=""/>
<input type="hidden" id="hdCarnet"    name="hdCarnet"    value=""/>
<input type="hidden" id="hdNombres"   name="hdNombres"   value=""/>
<input type="hidden" id="hdApellidos" name="hdApellidos" value=""/>
<input type="hidden" id="hdEmail"     name="hdEmail"     value=""/>
<input type="hidden" id="hdCelular"   name="hdCelular"   value=""/>
<input type="hidden" id="hdDireccion" name="hdDireccion" value=""/>
<input type="hidden" id="hdFechaNac"  name="hdFechaNac"  value=""/>
<input type="hidden" id="hdVigencia"  name="hdVigencia"  value=""/>
<input type="hidden" id="hdMotivo"    name="hdMotivo"    value=""/>
<asp:Button ID="btnPostBack" runat="server" Text="" Style="display:none" OnClick="btnAccion_Click"/>

<!-- MODAL NUEVO / EDITAR -->
<div class="modal-bg" id="modalUsuario">
  <div class="modal">
    <div class="modal-head">
      <div class="modal-title" id="modalTitulo">Nuevo usuario</div>
      <button type="button" class="modal-close" onclick="cerrarModal('modalUsuario')">&times;</button>
    </div>
    <div class="modal-body">
      <div class="alerta" id="divAlertaModal"></div>
      <div class="alerta alerta-info show" style="margin-bottom:14px">
        <i class="ti ti-key" style="font-size:13px;vertical-align:-2px;margin-right:6px" aria-hidden="true"></i>
        Contrasena inicial: numero de carnet del usuario.
      </div>
      <div class="form-row">
        <div class="form-group" id="grpCarnet">
          <label class="form-label">Carnet <span class="req">*</span></label>
          <input type="text" id="txCarnet" class="form-control" placeholder="Ej: 7654321" maxlength="8"/>
          <div class="form-error" id="errCarnet">Solo 7 u 8 digitos numericos.</div>
          <div class="form-help">Sera el usuario de acceso.</div>
        </div>
        <div class="form-group">
          <label class="form-label">Rol <span class="req">*</span></label>
          <select id="selTipoModal" class="form-control"><option value="">Seleccionar...</option></select>
          <div class="form-error" id="errTipo">Seleccione un rol.</div>
        </div>
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">Nombres <span class="req">*</span></label>
          <input type="text" id="txNombres"   class="form-control" placeholder="Ej: Maria"    maxlength="100"/>
          <div class="form-error" id="errNombres">Ingrese los nombres (solo letras).</div>
        </div>
        <div class="form-group">
          <label class="form-label">Apellidos <span class="req">*</span></label>
          <input type="text" id="txApellidos" class="form-control" placeholder="Ej: Gonzalez" maxlength="100"/>
          <div class="form-error" id="errApellidos">Ingrese los apellidos (solo letras).</div>
        </div>
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">Celular</label>
          <input type="text" id="txCelular"   class="form-control" placeholder="+591 7X XXX XXX" maxlength="20"/>
        </div>
        <div class="form-group">
          <label class="form-label">Correo electronico</label>
          <input type="text" id="txEmail"     class="form-control" placeholder="correo@ejemplo.com" maxlength="100"/>
          <div class="form-error" id="errEmail">Formato de email invalido.</div>
        </div>
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">Fecha de nacimiento</label>
          <input type="date" id="txFechaNac"  class="form-control"/>
        </div>
        <div class="form-group">
          <label class="form-label">Vigente hasta</label>
          <input type="date" id="txVigencia"  class="form-control"/>
          <div class="form-help">Vacio = permanente.</div>
        </div>
      </div>
      <div class="form-row-full">
        <div class="form-group">
          <label class="form-label">Direccion</label>
          <input type="text" id="txDireccion" class="form-control" placeholder="Calle, numero, zona..." maxlength="200"/>
        </div>
      </div>
    </div>
    <div class="modal-footer">
      <button type="button" class="btn" onclick="cerrarModal('modalUsuario')">Cancelar</button>
      <button type="button" class="btn btn-primary" onclick="guardarUsuario()">
        <i class="ti ti-device-floppy" aria-hidden="true"></i> Guardar
      </button>
    </div>
  </div>
</div>

<!-- MODAL BLOQUEO -->
<div class="modal-bg" id="modalBloqueo">
  <div class="modal" style="max-width:420px">
    <div class="modal-head">
      <div class="modal-title" id="titBloqueo">Bloquear usuario</div>
      <button type="button" class="modal-close" onclick="cerrarModal('modalBloqueo')">&times;</button>
    </div>
    <div class="modal-body">
      <div class="alerta show" id="avisoBloqueo" style="border-color:#C62828;background:#FFEBEE;color:#C62828;margin-bottom:14px">
        Esta accion bloqueara el acceso del usuario al sistema.
      </div>
      <div class="form-group">
        <label class="form-label">Motivo <span class="req">*</span></label>
        <input type="text" id="txMotivoBloqueo" class="form-control" placeholder="Minimo 5 caracteres..." maxlength="300"/>
        <div class="form-error" id="errMotivoBloqueo">El motivo es obligatorio (min. 5 caracteres).</div>
      </div>
    </div>
    <div class="modal-footer">
      <button type="button" class="btn" onclick="cerrarModal('modalBloqueo')">Cancelar</button>
      <button type="button" class="btn btn-danger" id="btnConfBloqueo" onclick="confirmarBloqueo()">
        <i class="ti ti-lock" aria-hidden="true"></i> Confirmar
      </button>
    </div>
  </div>
</div>

<!-- MODAL RESET -->
<div class="modal-bg" id="modalReset">
  <div class="modal" style="max-width:420px">
    <div class="modal-head">
      <div class="modal-title">Resetear contrasena</div>
      <button type="button" class="modal-close" onclick="cerrarModal('modalReset')">&times;</button>
    </div>
    <div class="modal-body">
      <div class="alerta alerta-info show" style="margin-bottom:14px">
        La contrasena volvera a ser el carnet del usuario. Debera cambiarla al ingresar.
      </div>
      <div class="form-group">
        <label class="form-label">Motivo <span class="req">*</span></label>
        <input type="text" id="txMotivoReset" class="form-control" placeholder="Minimo 5 caracteres..." maxlength="300"/>
        <div class="form-error" id="errMotivoReset">El motivo es obligatorio (min. 5 caracteres).</div>
      </div>
    </div>
    <div class="modal-footer">
      <button type="button" class="btn" onclick="cerrarModal('modalReset')">Cancelar</button>
      <button type="button" class="btn btn-primary" onclick="confirmarReset()">
        <i class="ti ti-key" aria-hidden="true"></i> Resetear
      </button>
    </div>
  </div>
</div>

</form>
<script>
var modoEdicion = false;
var tipos = /** @type {Array<{id:number,nombre:string}>} */ (<%=TiposJson%>);

// Poblar selects de roles
(function() {
    var elSelRol   = /** @type {HTMLSelectElement} */ (document.getElementById('selRol'));
    var elSelModal = /** @type {HTMLSelectElement} */ (document.getElementById('selTipoModal'));
    var optTodos   = document.createElement('option');
    optTodos.value       = '';
    optTodos.textContent = 'Todos los roles';
    if (elSelRol) { elSelRol.appendChild(optTodos); }
    for (var i = 0; i < tipos.length; i++) {
        var o1 = document.createElement('option');
        o1.value       = String(tipos[i].id);
        o1.textContent = tipos[i].nombre;
        if (elSelRol)   { elSelRol.appendChild(o1); }
        var o2 = document.createElement('option');
        o2.value       = String(tipos[i].id);
        o2.textContent = tipos[i].nombre;
        if (elSelModal) { elSelModal.appendChild(o2); }
    }
})();

function limpiar(/** @type {string} */ v) {
    return v.replace(/[<>"';\\]/g, '').trim();
}

function soloLetras(/** @type {string} */ v) {
    return /^[a-zA-ZaeiouAEIOUnN\s]+$/.test(v.trim());
}

function esEmailValido(/** @type {string} */ v) {
    return v === '' || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
}

function marcar(/** @type {string} */ id, /** @type {string} */ estado) {
    var el = document.getElementById(id);
    if (!el) { return; }
    el.className = 'form-control' + (estado === 'error' ? ' campo-error' : estado === 'ok' ? ' campo-ok' : '');
}

function mostrarErr(/** @type {string} */ id, /** @type {boolean} */ show) {
    var el = document.getElementById(id);
    if (el) { el.className = show ? 'form-error show' : 'form-error'; }
}

function mostrarAlertaModal(/** @type {string} */ msg, /** @type {boolean} */ esOk) {
    var d = document.getElementById('divAlertaModal');
    if (d) {
        d.innerHTML = msg;
        d.className = esOk ? 'alerta alerta-ok show' : 'alerta alerta-error show';
    }
}

function abrirModal(/** @type {string} */ id) {
    var m = document.getElementById(id);
    if (m) { m.className = 'modal-bg show'; }
}

function cerrarModal(/** @type {string} */ id) {
    var m = document.getElementById(id);
    if (m) { m.className = 'modal-bg'; }
}

function getVal(/** @type {string} */ id) {
    var el = /** @type {HTMLInputElement} */ (document.getElementById(id));
    return el ? el.value : '';
}

function setVal(/** @type {string} */ id, /** @type {string} */ val) {
    var el = /** @type {HTMLInputElement} */ (document.getElementById(id));
    if (el) { el.value = val || ''; }
}

function setHd(/** @type {string} */ id, /** @type {string} */ val) {
    var el = /** @type {HTMLInputElement} */ (document.getElementById(id));
    if (el) { el.value = val; }
}

function abrirModalNuevo() {
    modoEdicion = false;
    limpiarForm();
    var elTit = document.getElementById('modalTitulo');
    var elGrp = document.getElementById('grpCarnet');
    var elD   = document.getElementById('divAlertaModal');
    if (elTit) { elTit.textContent = 'Nuevo usuario'; }
    if (elGrp) { elGrp.style.display = ''; }
    if (elD)   { elD.className = 'alerta'; }
    abrirModal('modalUsuario');
}

function abrirModalEditar(
    /** @type {number} */ uid,
    /** @type {number} */ tid,
    /** @type {string} */ nombres,
    /** @type {string} */ apellidos,
    /** @type {string} */ email,
    /** @type {string} */ celular,
    /** @type {string} */ vigencia,
    /** @type {string} */ direccion
) {
    modoEdicion = true;
    limpiarForm();
    var elTit = document.getElementById('modalTitulo');
    var elGrp = document.getElementById('grpCarnet');
    var elD   = document.getElementById('divAlertaModal');
    var elSel = /** @type {HTMLSelectElement} */ (document.getElementById('selTipoModal'));
    if (elTit) { elTit.textContent = 'Editar usuario'; }
    if (elGrp) { elGrp.style.display = 'none'; }
    if (elD)   { elD.className = 'alerta'; }
    setHd('hdUsuarioId', String(uid));
    if (elSel) { elSel.value = String(tid); }
    setVal('txNombres',   nombres);
    setVal('txApellidos', apellidos);
    setVal('txEmail',     email);
    setVal('txCelular',   celular);
    setVal('txVigencia',  vigencia);
    setVal('txDireccion', direccion);
    abrirModal('modalUsuario');
}

function limpiarForm() {
    var ids = ['txCarnet','txNombres','txApellidos','txEmail','txCelular','txFechaNac','txVigencia','txDireccion'];
    for (var i = 0; i < ids.length; i++) { setVal(ids[i], ''); marcar(ids[i], ''); }
    var elSel = /** @type {HTMLSelectElement} */ (document.getElementById('selTipoModal'));
    if (elSel) { elSel.value = ''; }
    var errIds = ['errCarnet','errTipo','errNombres','errApellidos','errEmail'];
    for (var j = 0; j < errIds.length; j++) { mostrarErr(errIds[j], false); }
}

function guardarUsuario() {
    var carnet    = limpiar(getVal('txCarnet'));
    var nombres   = limpiar(getVal('txNombres'));
    var apellidos = limpiar(getVal('txApellidos'));
    var email     = limpiar(getVal('txEmail'));
    var celular   = limpiar(getVal('txCelular'));
    var fechaNac  = getVal('txFechaNac');
    var vigencia  = getVal('txVigencia');
    var direccion = limpiar(getVal('txDireccion'));
    var elSel     = /** @type {HTMLSelectElement} */ (document.getElementById('selTipoModal'));
    var tipoId    = elSel ? elSel.value : '';
    var valido    = true;

    if (!modoEdicion) {
        if (!/^\d{7,8}$/.test(carnet)) {
            marcar('txCarnet','error'); mostrarErr('errCarnet',true); valido = false;
        } else { marcar('txCarnet','ok'); mostrarErr('errCarnet',false); }
    }
    if (tipoId === '') {
        marcar('selTipoModal','error'); mostrarErr('errTipo',true); valido = false;
    } else { marcar('selTipoModal','ok'); mostrarErr('errTipo',false); }
    if (nombres.length < 2 || !soloLetras(nombres)) {
        marcar('txNombres','error'); mostrarErr('errNombres',true); valido = false;
    } else { marcar('txNombres','ok'); mostrarErr('errNombres',false); }
    if (apellidos.length < 2 || !soloLetras(apellidos)) {
        marcar('txApellidos','error'); mostrarErr('errApellidos',true); valido = false;
    } else { marcar('txApellidos','ok'); mostrarErr('errApellidos',false); }
    if (!esEmailValido(email)) {
        marcar('txEmail','error'); mostrarErr('errEmail',true); valido = false;
    } else { marcar('txEmail','ok'); mostrarErr('errEmail',false); }
    if (!valido) { return; }

    setHd('hdAccion',    modoEdicion ? 'EDITAR' : 'CREAR');
    setHd('hdTipoId',    tipoId);
    setHd('hdCarnet',    carnet);
    setHd('hdNombres',   nombres);
    setHd('hdApellidos', apellidos);
    setHd('hdEmail',     email);
    setHd('hdCelular',   celular);
    setHd('hdFechaNac',  fechaNac);
    setHd('hdVigencia',  vigencia);
    setHd('hdDireccion', direccion);
    var elBtn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (elBtn) { elBtn.click(); }
}

function abrirBloqueo(/** @type {number} */ uid, /** @type {boolean} */ bloquear) {
    setHd('hdUsuarioId', String(uid));
    setHd('hdAccion', bloquear ? 'BLOQUEAR' : 'DESBLOQUEAR');
    var elTit = document.getElementById('titBloqueo');
    var elAvi = document.getElementById('avisoBloqueo');
    var elBtn = document.getElementById('btnConfBloqueo');
    if (elTit) { elTit.textContent = bloquear ? 'Bloquear usuario' : 'Desbloquear usuario'; }
    if (elAvi) {
        elAvi.style.borderColor = bloquear ? '#C62828' : '#185FA5';
        elAvi.style.background  = bloquear ? '#FFEBEE' : '#E6F1FB';
        elAvi.style.color       = bloquear ? '#C62828' : '#0C447C';
        elAvi.textContent = bloquear
            ? 'Esta accion bloqueara el acceso del usuario al sistema.'
            : 'Esta accion restaurara el acceso del usuario al sistema.';
    }
    if (elBtn) {
        elBtn.innerHTML = bloquear
            ? '<i class="ti ti-lock" aria-hidden="true"></i> Bloquear'
            : '<i class="ti ti-lock-open" aria-hidden="true"></i> Desbloquear';
    }
    setVal('txMotivoBloqueo', '');
    mostrarErr('errMotivoBloqueo', false);
    abrirModal('modalBloqueo');
}

function confirmarBloqueo() {
    var motivo = limpiar(getVal('txMotivoBloqueo'));
    if (motivo.length < 5) { mostrarErr('errMotivoBloqueo', true); return; }
    mostrarErr('errMotivoBloqueo', false);
    setHd('hdMotivo', motivo);
    var elBtn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (elBtn) { elBtn.click(); }
}

function abrirReset(/** @type {number} */ uid) {
    setHd('hdUsuarioId', String(uid));
    setHd('hdAccion', 'RESET');
    setVal('txMotivoReset', '');
    mostrarErr('errMotivoReset', false);
    abrirModal('modalReset');
}

function confirmarReset() {
    var motivo = limpiar(getVal('txMotivoReset'));
    if (motivo.length < 5) { mostrarErr('errMotivoReset', true); return; }
    mostrarErr('errMotivoReset', false);
    setHd('hdMotivo', motivo);
    var elBtn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (elBtn) { elBtn.click(); }
}

function filtrarTabla() {
    var elBuscar  = /** @type {HTMLInputElement}  */ (document.getElementById('txBuscar'));
    var elSelRol  = /** @type {HTMLSelectElement} */ (document.getElementById('selRol'));
    var elSelEst  = /** @type {HTMLSelectElement} */ (document.getElementById('selEstado'));
    var texto     = elBuscar  ? elBuscar.value.toLowerCase() : '';
    var rol       = elSelRol  ? elSelRol.value               : '';
    var estado    = elSelEst  ? elSelEst.value               : '';
    var filas     = document.querySelectorAll('.fila-usuario');
    for (var i = 0; i < filas.length; i++) {
        var fila = /** @type {HTMLElement} */ (filas[i]);
        var txtFila    = fila.getAttribute('data-texto')  || '';
        var rolFila    = fila.getAttribute('data-rol')    || '';
        var estadoFila = fila.getAttribute('data-estado') || '';
        var mostrar    = true;
        if (texto  && txtFila.indexOf(texto)   === -1) { mostrar = false; }
        if (rol    && rolFila    !== rol)               { mostrar = false; }
        if (estado && estadoFila !== estado)            { mostrar = false; }
        fila.style.display = mostrar ? '' : 'none';
    }
}
</script>
</body>
</html>
