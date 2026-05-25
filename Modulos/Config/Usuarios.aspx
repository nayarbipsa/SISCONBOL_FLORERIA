<%@ Page Language="VB" MasterPageFile="~/Site.master" AutoEventWireup="false"
         CodeBehind="Usuarios.aspx.vb"
         Inherits="SISCONBOL_FLORERIA.Modulos_Config_Usuarios" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Gestión de Usuarios
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    Gestión de Usuarios
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

    <!-- Alerta global (éxito/error después de postback) -->
    <div class="alerta" id="divAlertaGlobal"></div>

    <!-- Panel principal -->
    <div class="panel">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-users"></i> Usuarios registrados
            </div>
            <button type="button" class="btn btn-primary" onclick="abrirModalNuevo()">
                <i class="ti ti-plus"></i> Nuevo usuario
            </button>
        </div>

        <!-- Filtros -->
        <div class="filtros">
            <input type="text" id="txBuscar" class="form-control" style="width:200px"
                   placeholder="Nombre o carnet..." onkeyup="filtrarTabla()"/>
            <select id="selRolFiltro" class="form-control" style="width:170px"
                    onchange="filtrarTabla()"></select>
            <select id="selEstadoFiltro" class="form-control" style="width:140px"
                    onchange="filtrarTabla()">
                <option value="">Todos los estados</option>
                <option value="ACTIVO">Activos</option>
                <option value="BLOQUEADO">Bloqueados</option>
                <option value="VENCIDO">Vencidos</option>
                <option value="VENCE_HOY">Vencen hoy</option>
                <option value="INACTIVO">Inactivos</option>
            </select>
        </div>

        <!-- Tabla dinámica -->
        <div id="divTabla"><%=TablaHtml%></div>
    </div>

    <!-- Hidden fields -->
    <input type="hidden" id="hdAccion"     name="hdAccion"     value=""/>
    <input type="hidden" id="hdUsuarioId"  name="hdUsuarioId"  value=""/>
    <input type="hidden" id="hdTipoId"     name="hdTipoId"     value=""/>
    <input type="hidden" id="hdCarnet"     name="hdCarnet"     value=""/>
    <input type="hidden" id="hdNombres"    name="hdNombres"    value=""/>
    <input type="hidden" id="hdApellidos"  name="hdApellidos"  value=""/>
    <input type="hidden" id="hdEmail"      name="hdEmail"      value=""/>
    <input type="hidden" id="hdCelular"    name="hdCelular"    value=""/>
    <input type="hidden" id="hdDireccion"  name="hdDireccion"  value=""/>
    <input type="hidden" id="hdFechaNac"   name="hdFechaNac"   value=""/>
    <input type="hidden" id="hdVigencia"   name="hdVigencia"   value=""/>
    <input type="hidden" id="hdMotivo"     name="hdMotivo"     value=""/>
    <asp:Button ID="btnPostBack" runat="server" Text="" Style="display:none"
                OnClick="btnAccion_Click"/>

    <!-- ===================== MODAL NUEVO / EDITAR ===================== -->
    <div class="modal-bg" id="modalUsuario">
        <div class="modal" style="max-width:580px">
            <div class="modal-head">
                <div class="modal-title" id="modalTitulo">Nuevo usuario</div>
                <button type="button" class="modal-close"
                        onclick="cerrarModal('modalUsuario')">&times;</button>
            </div>
            <div class="modal-body">
                <div class="alerta" id="divAlertaModal"></div>
                <div class="alerta alerta-info show" style="margin-bottom:14px">
                    <i class="ti ti-key" style="font-size:13px;vertical-align:-2px;margin-right:5px"></i>
                    Contraseña inicial: el número de carnet del usuario.
                </div>

                <div class="form-row">
                    <div class="form-group" id="grpCarnet">
                        <label class="form-label">Carnet <span class="req">*</span></label>
                        <input type="text" id="txCarnet" class="form-control"
                               placeholder="Ej: 7654321" maxlength="8"/>
                        <div class="form-error" id="errCarnet">Solo 7 u 8 dígitos numéricos.</div>
                        <div class="form-help">Será el usuario de acceso.</div>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Rol <span class="req">*</span></label>
                        <select id="selTipoModal" class="form-control">
                            <option value="">Seleccionar...</option>
                        </select>
                        <div class="form-error" id="errTipo">Seleccione un rol.</div>
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Nombres <span class="req">*</span></label>
                        <input type="text" id="txNombres" class="form-control"
                               placeholder="Ej: Maria" maxlength="100"/>
                        <div class="form-error" id="errNombres">Ingrese los nombres (solo letras).</div>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Apellidos <span class="req">*</span></label>
                        <input type="text" id="txApellidos" class="form-control"
                               placeholder="Ej: Gonzalez" maxlength="100"/>
                        <div class="form-error" id="errApellidos">Ingrese los apellidos (solo letras).</div>
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Celular</label>
                        <input type="text" id="txCelular" class="form-control"
                               placeholder="+591 7X XXX XXX" maxlength="20"/>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Correo electrónico</label>
                        <input type="text" id="txEmail" class="form-control"
                               placeholder="correo@ejemplo.com" maxlength="100"/>
                        <div class="form-error" id="errEmail">Formato de email inválido.</div>
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">Fecha de nacimiento</label>
                        <input type="date" id="txFechaNac" class="form-control"/>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Vigente hasta</label>
                        <input type="date" id="txVigencia" class="form-control"/>
                        <div class="form-help">Vacío = permanente.</div>
                    </div>
                </div>

                <div class="form-row-full">
                    <div class="form-group">
                        <label class="form-label">Dirección</label>
                        <input type="text" id="txDireccion" class="form-control"
                               placeholder="Calle, número, zona..." maxlength="200"/>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn" onclick="cerrarModal('modalUsuario')">Cancelar</button>
                <button type="button" class="btn btn-primary" onclick="guardarUsuario()">
                    <i class="ti ti-device-floppy"></i> Guardar
                </button>
            </div>
        </div>
    </div>

    <!-- ===================== MODAL BLOQUEO/DESBLOQUEO ===================== -->
    <div class="modal-bg" id="modalBloqueo">
        <div class="modal" style="max-width:430px">
            <div class="modal-head">
                <div class="modal-title" id="titBloqueo">Bloquear usuario</div>
                <button type="button" class="modal-close"
                        onclick="cerrarModal('modalBloqueo')">&times;</button>
            </div>
            <div class="modal-body">
                <div class="alerta show" id="avisoBloqueo"
                     style="border-color:#C62828;background:#FFEBEE;color:#C62828;margin-bottom:14px">
                    Esta acción bloqueará el acceso del usuario al sistema.
                </div>
                <div class="form-group">
                    <label class="form-label">Motivo <span class="req">*</span></label>
                    <input type="text" id="txMotivoBloqueo" class="form-control"
                           placeholder="Mínimo 5 caracteres..." maxlength="300"/>
                    <div class="form-error" id="errMotivoBloqueo">
                        El motivo es obligatorio (mín. 5 caracteres).
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn" onclick="cerrarModal('modalBloqueo')">Cancelar</button>
                <button type="button" class="btn btn-danger" id="btnConfBloqueo"
                        onclick="confirmarBloqueo()">
                    <i class="ti ti-lock"></i> Confirmar
                </button>
            </div>
        </div>
    </div>

    <!-- ===================== MODAL RESET PASSWORD ===================== -->
    <div class="modal-bg" id="modalReset">
        <div class="modal" style="max-width:430px">
            <div class="modal-head">
                <div class="modal-title">Resetear contraseña</div>
                <button type="button" class="modal-close"
                        onclick="cerrarModal('modalReset')">&times;</button>
            </div>
            <div class="modal-body">
                <div class="alerta alerta-info show" style="margin-bottom:14px">
                    La contraseña volverá a ser el carnet del usuario. Deberá cambiarla al ingresar.
                </div>
                <div class="form-group">
                    <label class="form-label">Motivo <span class="req">*</span></label>
                    <input type="text" id="txMotivoReset" class="form-control"
                           placeholder="Mínimo 5 caracteres..." maxlength="300"/>
                    <div class="form-error" id="errMotivoReset">
                        El motivo es obligatorio (mín. 5 caracteres).
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn" onclick="cerrarModal('modalReset')">Cancelar</button>
                <button type="button" class="btn btn-primary" onclick="confirmarReset()">
                    <i class="ti ti-key"></i> Resetear
                </button>
            </div>
        </div>
    </div>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck
var modoEdicion = false;
var tipos = <%=TiposJson%>;

// ── Poblar selects de roles ──────────────────────────────────────────
(function () {
    var selFiltro = document.getElementById('selRolFiltro');
    var selModal  = document.getElementById('selTipoModal');
    if (selFiltro) {
        var optTodos = document.createElement('option');
        optTodos.value = ''; optTodos.textContent = 'Todos los roles';
        selFiltro.appendChild(optTodos);
    }
    for (var i = 0; i < tipos.length; i++) {
        if (selFiltro) {
            var o1 = document.createElement('option');
            o1.value = String(tipos[i].id); o1.textContent = tipos[i].nombre;
            selFiltro.appendChild(o1);
        }
        if (selModal) {
            var o2 = document.createElement('option');
            o2.value = String(tipos[i].id); o2.textContent = tipos[i].nombre;
            selModal.appendChild(o2);
        }
    }
})();

// ── Helpers básicos ─────────────────────────────────────────────────
function limpiar(v) { return (v || '').replace(/[<>"';\\]/g, '').trim(); }
function soloLetras(v) { return /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$/.test(v.trim()); }
function esEmailValido(v) { return v === '' || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v); }

function marcar(id, estado) {
    var el = document.getElementById(id);
    if (!el) return;
    el.className = 'form-control' +
        (estado === 'error' ? ' campo-error' : estado === 'ok' ? ' campo-ok' : '');
}
function mostrarErr(id, show) {
    var el = document.getElementById(id);
    if (el) el.className = show ? 'form-error show' : 'form-error';
}
function getVal(id) { var el = document.getElementById(id); return el ? el.value : ''; }
function setVal(id, val) { var el = document.getElementById(id); if (el) el.value = (val || ''); }

// ── Modales ──────────────────────────────────────────────────────────
function abrirModal(id)  { var m = document.getElementById(id); if (m) m.className = 'modal-bg show'; }
function cerrarModal(id) { var m = document.getElementById(id); if (m) m.className = 'modal-bg'; }

function mostrarAlertaModal(msg, esOk) {
    var d = document.getElementById('divAlertaModal');
    if (d) {
        d.innerHTML = msg;
        d.className = esOk ? 'alerta alerta-ok show' : 'alerta alerta-error show';
    }
}

// ── Modal Nuevo ──────────────────────────────────────────────────────
function abrirModalNuevo() {
    modoEdicion = false;
    limpiarForm();
    var t = document.getElementById('modalTitulo');
    var g = document.getElementById('grpCarnet');
    var d = document.getElementById('divAlertaModal');
    if (t) t.textContent = 'Nuevo usuario';
    if (g) g.style.display = '';
    if (d) d.className = 'alerta';
    abrirModal('modalUsuario');
}

// ── Modal Editar ─────────────────────────────────────────────────────
function abrirModalEditar(uid, tid, nombres, apellidos, email, celular, vigencia, direccion) {
    modoEdicion = true;
    limpiarForm();
    var t   = document.getElementById('modalTitulo');
    var g   = document.getElementById('grpCarnet');
    var d   = document.getElementById('divAlertaModal');
    var sel = document.getElementById('selTipoModal');
    if (t) t.textContent = 'Editar usuario';
    if (g) g.style.display = 'none';
    if (d) d.className = 'alerta';
    setVal('hdUsuarioId', String(uid));
    if (sel) sel.value = String(tid);
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
    var sel = document.getElementById('selTipoModal');
    if (sel) sel.value = '';
    ['errCarnet','errTipo','errNombres','errApellidos','errEmail'].forEach(function(id){
        mostrarErr(id, false);
    });
}

// ── Guardar (CREAR / EDITAR) ─────────────────────────────────────────
function guardarUsuario() {
    var carnet    = limpiar(getVal('txCarnet'));
    var nombres   = limpiar(getVal('txNombres'));
    var apellidos = limpiar(getVal('txApellidos'));
    var email     = limpiar(getVal('txEmail'));
    var celular   = limpiar(getVal('txCelular'));
    var fechaNac  = getVal('txFechaNac');
    var vigencia  = getVal('txVigencia');
    var direccion = limpiar(getVal('txDireccion'));
    var sel       = document.getElementById('selTipoModal');
    var tipoId    = sel ? sel.value : '';
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
    if (!valido) return;

    setVal('hdAccion',    modoEdicion ? 'EDITAR' : 'CREAR');
    setVal('hdTipoId',    tipoId);
    setVal('hdCarnet',    carnet);
    setVal('hdNombres',   nombres);
    setVal('hdApellidos', apellidos);
    setVal('hdEmail',     email);
    setVal('hdCelular',   celular);
    setVal('hdFechaNac',  fechaNac);
    setVal('hdVigencia',  vigencia);
    setVal('hdDireccion', direccion);
    var btn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (btn) btn.click();
}

// ── Bloqueo / Desbloqueo ─────────────────────────────────────────────
function abrirBloqueo(uid, bloquear) {
    setVal('hdUsuarioId', String(uid));
    setVal('hdAccion', bloquear ? 'BLOQUEAR' : 'DESBLOQUEAR');
    var tit  = document.getElementById('titBloqueo');
    var avi  = document.getElementById('avisoBloqueo');
    var btn  = document.getElementById('btnConfBloqueo');
    if (tit) tit.textContent = bloquear ? 'Bloquear usuario' : 'Desbloquear usuario';
    if (avi) {
        avi.style.borderColor = bloquear ? '#C62828' : '#185FA5';
        avi.style.background  = bloquear ? '#FFEBEE' : '#E6F1FB';
        avi.style.color       = bloquear ? '#C62828' : '#0C447C';
        avi.textContent = bloquear
            ? 'Esta acción bloqueará el acceso del usuario al sistema.'
            : 'Esta acción restaurará el acceso del usuario al sistema.';
    }
    if (btn) {
        btn.innerHTML = bloquear
            ? '<i class="ti ti-lock"></i> Bloquear'
            : '<i class="ti ti-lock-open"></i> Desbloquear';
    }
    setVal('txMotivoBloqueo', '');
    mostrarErr('errMotivoBloqueo', false);
    abrirModal('modalBloqueo');
}

function confirmarBloqueo() {
    var motivo = limpiar(getVal('txMotivoBloqueo'));
    if (motivo.length < 5) { mostrarErr('errMotivoBloqueo', true); return; }
    mostrarErr('errMotivoBloqueo', false);
    setVal('hdMotivo', motivo);
    var btn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (btn) btn.click();
}

// ── Reset password ───────────────────────────────────────────────────
function abrirReset(uid) {
    setVal('hdUsuarioId', String(uid));
    setVal('hdAccion', 'RESET');
    setVal('txMotivoReset', '');
    mostrarErr('errMotivoReset', false);
    abrirModal('modalReset');
}

function confirmarReset() {
    var motivo = limpiar(getVal('txMotivoReset'));
    if (motivo.length < 5) { mostrarErr('errMotivoReset', true); return; }
    mostrarErr('errMotivoReset', false);
    setVal('hdMotivo', motivo);
    var btn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (btn) btn.click();
}

// ── Filtro cliente ───────────────────────────────────────────────────
function filtrarTabla() {
    var buscar = getVal('txBuscar').toLowerCase();
    var rol    = getVal('selRolFiltro');
    var estado = getVal('selEstadoFiltro');
    var filas  = document.querySelectorAll('.fila-usuario');
    for (var i = 0; i < filas.length; i++) {
        var f   = filas[i];
        var txt = (f.getAttribute('data-texto')  || '').toLowerCase();
        var r   = f.getAttribute('data-rol')    || '';
        var est = f.getAttribute('data-estado') || '';
        var ok  = true;
        if (buscar && txt.indexOf(buscar) === -1) ok = false;
        if (rol    && r   !== rol)                ok = false;
        if (estado && est !== estado)             ok = false;
        f.style.display = ok ? '' : 'none';
    }
}
</script>
</asp:Content>
