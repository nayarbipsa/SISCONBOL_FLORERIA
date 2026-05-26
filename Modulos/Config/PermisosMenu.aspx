<%@ Page Language="VB" MasterPageFile="~/Site.Master"
         AutoEventWireup="false"
         CodeBehind="PermisosMenu.aspx.vb"
         Inherits="SISCONBOL_FLORERIA.Modulos_Config_PermisosMenu" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Permisos de Menú
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    Permisos de Menú por Rol
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

    <div class="alerta" id="divAlerta"></div>

    <!-- Selector de rol -->
    <div class="panel" style="margin-bottom:16px">
        <div class="panel-body" style="padding:14px 18px">
            <div style="display:flex;align-items:center;gap:12px;flex-wrap:wrap">
                <label style="font-size:13px;font-weight:500;color:#616161;white-space:nowrap">
                    <i class="ti ti-shield-check" style="vertical-align:-2px;margin-right:4px;color:#C2185B"></i>
                    Ver permisos del rol:
                </label>
                <select id="selRol" class="form-control" style="width:220px" onchange="cambiarRol()">
                    <option value="">Seleccionar rol...</option>
                </select>
                <span id="spInfoRol" style="font-size:12px;color:#9e9e9e"></span>
            </div>
        </div>
    </div>

    <!-- Matriz de permisos -->
    <div id="divMatriz" style="display:none">
        <div class="panel">
            <div class="panel-head">
                <div class="panel-title">
                    <i class="ti ti-layout-sidebar"></i>
                    Opciones de menú — <span id="spNombreRol" style="color:#C2185B"></span>
                </div>
                <div style="display:flex;gap:8px">
                    <button type="button" class="btn" onclick="marcarTodos(true)">
                        <i class="ti ti-check"></i> Activar todos
                    </button>
                    <button type="button" class="btn" onclick="marcarTodos(false)">
                        <i class="ti ti-x"></i> Quitar todos
                    </button>
                    <button type="button" class="btn btn-primary" onclick="guardarPermisos()">
                        <i class="ti ti-device-floppy"></i> Guardar cambios
                    </button>
                </div>
            </div>

            <!-- Leyenda -->
            <div style="padding:10px 18px;border-bottom:1px solid #f0f0f0;display:flex;gap:20px;flex-wrap:wrap;font-size:12px;color:#757575">
                <span><i class="ti ti-eye" style="color:#1976D2"></i> Ver — el ítem aparece en el menú</span>
                <span><i class="ti ti-plus" style="color:#2E7D32"></i> Crear</span>
                <span><i class="ti ti-edit" style="color:#F57C00"></i> Editar</span>
                <span><i class="ti ti-trash" style="color:#C62828"></i> Eliminar</span>
            </div>

            <div style="overflow-x:auto">
                <table class="tabla" id="tblPermisos">
                    <thead>
                        <tr>
                            <th style="width:36px"></th>
                            <th>Opción de menú</th>
                            <th style="text-align:center;width:70px">
                                <i class="ti ti-eye" style="color:#1976D2" title="Ver"></i> Ver
                            </th>
                            <th style="text-align:center;width:70px">
                                <i class="ti ti-plus" style="color:#2E7D32" title="Crear"></i> Crear
                            </th>
                            <th style="text-align:center;width:70px">
                                <i class="ti ti-edit" style="color:#F57C00" title="Editar"></i> Editar
                            </th>
                            <th style="text-align:center;width:70px">
                                <i class="ti ti-trash" style="color:#C62828" title="Eliminar"></i> Eliminar
                            </th>
                        </tr>
                    </thead>
                    <tbody id="tbodyPermisos">
                        <!-- Poblado por JS -->
                    </tbody>
                </table>
            </div>

            <div style="padding:12px 18px;border-top:1px solid #f0f0f0;display:flex;justify-content:flex-end">
                <button type="button" class="btn btn-primary" onclick="guardarPermisos()">
                    <i class="ti ti-device-floppy"></i> Guardar cambios
                </button>
            </div>
        </div>
    </div>

    <!-- Estado vacío -->
    <div id="divVacio" style="text-align:center;padding:48px;color:#9e9e9e">
        <i class="ti ti-shield" style="font-size:40px;display:block;margin-bottom:10px"></i>
        Selecciona un rol para ver y editar sus permisos de menú.
    </div>

    <!-- Hidden fields -->
    <input type="hidden" id="hdAccion"   name="hdAccion"   value=""/>
    <input type="hidden" id="hdTipoId"   name="hdTipoId"   value=""/>
    <input type="hidden" id="hdPermisos" name="hdPermisos" value=""/>
    <asp:Button ID="btnPostBack" runat="server" Text="" Style="display:none"
                OnClick="btnAccion_Click"/>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

// Datos desde servidor
var tipos  = <%=TiposJson%>;
var menus  = <%=MenusJson%>;

// Estado local
var tipoSeleccionado = 0;
var permisosActuales = {};   // { menu_id: {ver, crear, editar, eliminar} }

// ── Poblar selector de roles ─────────────────────────────────────────
(function () {
    var sel = document.getElementById('selRol');
    if (!sel) return;
    for (var i = 0; i < tipos.length; i++) {
        var o = document.createElement('option');
        o.value = String(tipos[i].id);
        o.textContent = tipos[i].nombre;
        sel.appendChild(o);
    }
})();

// ── Cambiar rol seleccionado → pedir permisos al servidor ────────────
function cambiarRol() {
    var sel = document.getElementById('selRol');
    var tid = sel ? parseInt(sel.value) : 0;
    if (!tid) {
        document.getElementById('divMatriz').style.display = 'none';
        document.getElementById('divVacio').style.display  = '';
        return;
    }
    tipoSeleccionado = tid;

    // Nombre del rol
    var nombre = '';
    for (var i = 0; i < tipos.length; i++) {
        if (tipos[i].id === tid) { nombre = tipos[i].nombre; break; }
    }
    var spNombre = document.getElementById('spNombreRol');
    var spInfo   = document.getElementById('spInfoRol');
    if (spNombre) spNombre.textContent = nombre;
    if (spInfo)   spInfo.textContent   = 'Cargando...';

    // Setear hidden y postback silencioso
    document.getElementById('hdAccion').value = 'CARGAR';
    document.getElementById('hdTipoId').value = String(tid);
    var btn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (btn) btn.click();
}

// ── Construir la tabla de permisos ────────────────────────────────────
function construirTabla(permisos) {
    // permisos: array de {menu_id, puede_ver, puede_crear, puede_editar, puede_eliminar}
    permisosActuales = {};
    for (var i = 0; i < permisos.length; i++) {
        var p = permisos[i];
        permisosActuales[p.menu_id] = {
            ver:     p.puede_ver     === 1,
            crear:   p.puede_crear   === 1,
            editar:  p.puede_editar  === 1,
            eliminar:p.puede_eliminar=== 1
        };
    }

    var tbody = document.getElementById('tbodyPermisos');
    if (!tbody) return;
    tbody.innerHTML = '';

    // Separar padres e hijos
    var padres = [];
    var hijos  = {};
    for (var j = 0; j < menus.length; j++) {
        var m = menus[j];
        if (!m.padre_id) {
            padres.push(m);
        } else {
            if (!hijos[m.padre_id]) hijos[m.padre_id] = [];
            hijos[m.padre_id].push(m);
        }
    }

    // Ordenar padres por orden
    padres.sort(function(a,b){ return a.orden - b.orden; });

    for (var k = 0; k < padres.length; k++) {
        var padre = padres[k];
        var tieneHijos = hijos[padre.menu_id] && hijos[padre.menu_id].length > 0;

        // Fila padre
        var trPadre = document.createElement('tr');
        trPadre.className = 'fila-padre';
        trPadre.style.cssText = 'background:#fafafa;';
        trPadre.setAttribute('data-mid', String(padre.menu_id));

        var perPadre = permisosActuales[padre.menu_id] || {ver:false,crear:false,editar:false,eliminar:false};

        trPadre.innerHTML =
            '<td style="padding:10px 14px">' +
                '<i class="ti ' + (padre.icono||'ti-circle') + '" style="color:#C2185B;font-size:15px"></i>' +
            '</td>' +
            '<td style="font-weight:600;font-size:13px;padding:10px 14px">' + escp(padre.nombre) + '</td>' +
            tdCheck(padre.menu_id, 'ver',     perPadre.ver,      !tieneHijos) +
            tdCheck(padre.menu_id, 'crear',   perPadre.crear,    !tieneHijos) +
            tdCheck(padre.menu_id, 'editar',  perPadre.editar,   !tieneHijos) +
            tdCheck(padre.menu_id, 'eliminar',perPadre.eliminar, !tieneHijos);
        tbody.appendChild(trPadre);

        // Filas hijos
        if (tieneHijos) {
            var hijosOrdenados = hijos[padre.menu_id].sort(function(a,b){ return a.orden - b.orden; });
            for (var h = 0; h < hijosOrdenados.length; h++) {
                var hijo = hijosOrdenados[h];
                var perHijo = permisosActuales[hijo.menu_id] || {ver:false,crear:false,editar:false,eliminar:false};

                var trHijo = document.createElement('tr');
                trHijo.className = 'fila-hijo';
                trHijo.setAttribute('data-mid', String(hijo.menu_id));

                trHijo.innerHTML =
                    '<td style="padding:8px 14px 8px 28px">' +
                        '<i class="ti ti-corner-down-right" style="color:#bdbdbd;font-size:13px"></i>' +
                    '</td>' +
                    '<td style="font-size:13px;padding:8px 14px;color:#424242">' +
                        '<i class="ti ' + (hijo.icono||'ti-circle') + '" style="font-size:13px;color:#9e9e9e;margin-right:5px"></i>' +
                        escp(hijo.nombre) +
                    '</td>' +
                    tdCheck(hijo.menu_id, 'ver',     perHijo.ver,     true) +
                    tdCheck(hijo.menu_id, 'crear',   perHijo.crear,   true) +
                    tdCheck(hijo.menu_id, 'editar',  perHijo.editar,  true) +
                    tdCheck(hijo.menu_id, 'eliminar',perHijo.eliminar,true);
                tbody.appendChild(trHijo);
            }
        }
    }

    document.getElementById('divMatriz').style.display = '';
    document.getElementById('divVacio').style.display  = 'none';
    var spInfo = document.getElementById('spInfoRol');
    if (spInfo) spInfo.textContent = '';
}

// ── Generar <td> con checkbox ─────────────────────────────────────────
function tdCheck(mid, campo, checked, habilitado) {
    var id  = 'chk_' + mid + '_' + campo;
    var dis = habilitado ? '' : ' disabled';
    var sty = habilitado ? '' : ' style="opacity:.3;cursor:not-allowed"';
    return '<td style="text-align:center;padding:8px">' +
        '<input type="checkbox" id="' + id + '" class="chk-permiso"' +
        ' data-mid="' + mid + '" data-campo="' + campo + '"' +
        (checked ? ' checked' : '') + dis + sty +
        ' onchange="onCambioPermiso(this)">' +
        '</td>';
}

// ── Cuando cambia un check: propagar lógica padre → hijo ──────────────
function onCambioPermiso(el) {
    var mid   = parseInt(el.getAttribute('data-mid'));
    var campo = el.getAttribute('data-campo');

    // Si es padre, sincronizar todos sus hijos
    var hijosRows = document.querySelectorAll('.fila-hijo');
    // (los hijos no se auto-sincronizan — es decisión manual del admin)

    // Regla: si desmarcas "ver" del padre, desmarcar hijos también
    if (campo === 'ver' && !el.checked) {
        var trPadre = el.closest('tr');
        var siguiente = trPadre ? trPadre.nextElementSibling : null;
        while (siguiente && siguiente.classList.contains('fila-hijo')) {
            var chkVer = siguiente.querySelector('[data-campo="ver"]');
            if (chkVer && !chkVer.disabled) chkVer.checked = false;
            siguiente = siguiente.nextElementSibling;
        }
    }
    // Regla: si marcas "ver" de un hijo, marcar también el "ver" del padre
    if (campo === 'ver' && el.checked) {
        var trHijo = el.closest('tr');
        if (trHijo) {
            var prev = trHijo.previousElementSibling;
            while (prev && prev.classList.contains('fila-hijo')) {
                prev = prev.previousElementSibling;
            }
            if (prev && prev.classList.contains('fila-padre')) {
                var chkPadreVer = prev.querySelector('[data-campo="ver"]');
                if (chkPadreVer && !chkPadreVer.disabled) chkPadreVer.checked = true;
            }
        }
    }
}

// ── Marcar / desmarcar todos ──────────────────────────────────────────
function marcarTodos(marcar) {
    var chks = document.querySelectorAll('.chk-permiso:not(:disabled)');
    for (var i = 0; i < chks.length; i++) {
        chks[i].checked = marcar;
    }
}

// ── Guardar permisos (serializar y postback) ──────────────────────────
function guardarPermisos() {
    if (!tipoSeleccionado) {
        mostrarAlerta('Selecciona un rol primero.', 'warn');
        return;
    }

    // Recolectar estado de todos los checkboxes
    var filas = document.querySelectorAll('tr[data-mid]');
    var resultado = [];
    for (var i = 0; i < filas.length; i++) {
        var mid      = filas[i].getAttribute('data-mid');
        var chkVer   = filas[i].querySelector('[data-campo="ver"]');
        var chkCr    = filas[i].querySelector('[data-campo="crear"]');
        var chkEd    = filas[i].querySelector('[data-campo="editar"]');
        var chkEl    = filas[i].querySelector('[data-campo="eliminar"]');
        resultado.push(
            mid + ':' +
            (chkVer  && chkVer.checked  ? '1' : '0') +
            (chkCr   && chkCr.checked   ? '1' : '0') +
            (chkEd   && chkEd.checked   ? '1' : '0') +
            (chkEl   && chkEl.checked   ? '1' : '0')
        );
    }

    document.getElementById('hdAccion').value   = 'GUARDAR';
    document.getElementById('hdTipoId').value   = String(tipoSeleccionado);
    document.getElementById('hdPermisos').value = resultado.join('|');
    var btn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (btn) btn.click();
}

// ── Alerta global ─────────────────────────────────────────────────────
function mostrarAlerta(msg, tipo) {
    var d = document.getElementById('divAlerta');
    if (!d) return;
    var cls = 'alerta show ';
    if (tipo === 'ok')   cls += 'alerta-ok';
    else if (tipo === 'warn') cls += 'alerta-warn';
    else                  cls += 'alerta-error';
    d.className   = cls;
    d.innerHTML   = msg;
    setTimeout(function(){ d.className = 'alerta'; }, 4000);
}

function escp(s) {
    return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

// ── Ejecutar tabla si ya hay datos del servidor (tras postback) ────────
var permisosServidor = <%=PermisosJson%>;
var tipoServidor     = <%=TipoSeleccionadoId%>;
if (tipoServidor > 0 && permisosServidor) {
    // Restaurar selector
    var selR = document.getElementById('selRol');
    if (selR) selR.value = String(tipoServidor);
    tipoSeleccionado = tipoServidor;
    var nom = '';
    for (var z = 0; z < tipos.length; z++) {
        if (tipos[z].id === tipoServidor) { nom = tipos[z].nombre; break; }
    }
    var spN = document.getElementById('spNombreRol');
    if (spN) spN.textContent = nom;
    construirTabla(permisosServidor);
}
</script>
</asp:Content>
