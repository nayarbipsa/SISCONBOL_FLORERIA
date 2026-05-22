// =====================================================
// SISCONBOL_FLORERIA - Scripts Globales
// Archivo: Scripts/site.js
// Uso: Funciones compartidas en todas las páginas
// =====================================================

// @ts-nocheck

// === SIDEBAR MÓVIL ===
function abrirSidebar() {
    var elSb = document.getElementById('sidebar');
    var elOv = document.getElementById('overlay');
    if (elSb) { elSb.classList.add('open'); }
    if (elOv) { elOv.classList.add('show'); }
}

function cerrarSidebar() {
    var elSb = document.getElementById('sidebar');
    var elOv = document.getElementById('overlay');
    if (elSb) { elSb.classList.remove('open'); }
    if (elOv) { elOv.classList.remove('show'); }
}

// === MENÚ JERÁRQUICO ===
function toggleHijos(/** @type {string} */ id) {
    var el = document.getElementById(id);
    if (el) { el.classList.toggle('open'); }
}

// === AVATAR MENU ===
function toggleAvatarMenu() {
    var elMenu = document.getElementById('avatarMenu');
    if (elMenu) { 
        elMenu.className = elMenu.className === 'avatar-menu show' ? 'avatar-menu' : 'avatar-menu show'; 
    }
}

// Cerrar avatar menu al hacer clic fuera
document.addEventListener('DOMContentLoaded', function() {
    document.addEventListener('click', function(/** @type {MouseEvent} */ e) {
        var elMenu = document.getElementById('avatarMenu');
        var elAvatarBtn = document.getElementById('btnAvatar');
        if (!elMenu || !elAvatarBtn) { return; }
        var target = /** @type {Node} */ (e.target);
        if (!elAvatarBtn.contains(target) && !elMenu.contains(target)) {
            elMenu.className = 'avatar-menu';
        }
    });
});

// === CERRAR SESIÓN ===
function cerrarSesion() {
    var elHd = /** @type {HTMLInputElement} */ (document.getElementById('hdCerrar'));
    var elBtn = document.getElementById('btnCerrarSesion');
    if (elHd) { elHd.value = '1'; }
    if (elBtn) { elBtn.click(); }
}

// === UTILIDADES ===

// Formatear fecha en español
function formatearFecha(fecha) {
    var dias = ['Domingo', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado'];
    var meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return dias[fecha.getDay()] + ' ' + fecha.getDate() + ' de ' + meses[fecha.getMonth()] + ' de ' + fecha.getFullYear();
}

// Mostrar alerta
function mostrarAlerta(/** @type {string} */ idAlerta, /** @type {boolean} */ mostrar) {
    var el = document.getElementById(idAlerta);
    if (el) {
        if (mostrar) {
            el.classList.add('show');
        } else {
            el.classList.remove('show');
        }
    }
}

// Marcar campo con error
function marcarError(/** @type {string} */ idCampo, /** @type {string} */ idError, /** @type {boolean} */ esError) {
    var campo = document.getElementById(idCampo);
    var error = document.getElementById(idError);
    
    if (campo) {
        if (esError) {
            campo.classList.add('campo-error');
            campo.classList.remove('campo-ok');
        } else {
            campo.classList.remove('campo-error');
            campo.classList.add('campo-ok');
        }
    }
    
    if (error) {
        if (esError) {
            error.classList.add('show');
        } else {
            error.classList.remove('show');
        }
    }
}

// Limpiar errores de formulario
function limpiarErrores() {
    var campos = document.querySelectorAll('.campo-error');
    for (var i = 0; i < campos.length; i++) {
        campos[i].classList.remove('campo-error');
    }
    
    var errores = document.querySelectorAll('.form-error.show');
    for (var j = 0; j < errores.length; j++) {
        errores[j].classList.remove('show');
    }
}

// Validar campo requerido
function validarRequerido(/** @type {string} */ idCampo, /** @type {string} */ idError) {
    var campo = /** @type {HTMLInputElement} */ (document.getElementById(idCampo));
    if (!campo) { return true; }
    
    var valor = campo.value.trim();
    var esValido = valor !== '';
    
    marcarError(idCampo, idError, !esValido);
    return esValido;
}

// Validar email
function validarEmail(/** @type {string} */ email) {
    var regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return regex.test(email);
}

// Formatear moneda bolivianos
function formatearBs(/** @type {number} */ monto) {
    return 'Bs ' + monto.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

// Formatear moneda dólares
function formatearUsd(/** @type {number} */ monto) {
    return '$us ' + monto.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

// Obtener valor de input con fallback
function obtenerValor(/** @type {string} */ idCampo, /** @type {string} */ valorDefault) {
    var campo = /** @type {HTMLInputElement} */ (document.getElementById(idCampo));
    if (!campo) { return valorDefault; }
    var valor = campo.value.trim();
    return valor === '' ? valorDefault : valor;
}

// Establecer valor de input
function establecerValor(/** @type {string} */ idCampo, /** @type {string} */ valor) {
    var campo = /** @type {HTMLInputElement} */ (document.getElementById(idCampo));
    if (campo) { campo.value = valor; }
}

// Confirmar acción
function confirmar(/** @type {string} */ mensaje) {
    return confirm(mensaje);
}

// Scroll al top
function scrollTop() {
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Scroll a elemento
function scrollToElement(/** @type {string} */ idElemento) {
    var el = document.getElementById(idElemento);
    if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}


// ============================================
// AGREGAR AL FINAL DE site.js
// Funciones para alertas y utilidades
// ============================================

/**
 * Muestra una alerta temporal
 * @param {string} mensaje - Texto del mensaje
 * @param {string} tipo - success, error, warning
 */
function mostrarAlerta(mensaje, tipo) {
    var div = document.getElementById('divAlerta');
    if (div) {
        div.textContent = mensaje;
        div.className = 'alerta alerta-' + tipo + ' show';

        // Auto-ocultar después de 5 segundos
        setTimeout(function () {
            div.className = 'alerta';
        }, 5000);
    }
}

/**
 * Formatea número a moneda boliviana
 * @param {number} monto
 * @returns {string}
 */
function formatearBs(monto) {
    if (typeof monto !== 'number') monto = parseFloat(monto) || 0;
    return 'Bs ' + monto.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

/**
 * Valida campo requerido
 * @param {string} idCampo
 * @param {string} idError
 * @returns {boolean}
 */
function validarRequerido(idCampo, idError) {
    var campo = /** @type {HTMLInputElement} */ (document.getElementById(idCampo));
    var error = document.getElementById(idError);

    if (!campo) return true;

    var valor = campo.value.trim();
    var esValido = valor !== '';

    if (error) {
        error.style.display = esValido ? 'none' : 'block';
    }

    if (!esValido && campo.focus) {
        campo.focus();
    }

    return esValido;
}

/**
 * Marca campo con error
 * @param {string} idCampo
 * @param {string} idError
 * @param {boolean} esError
 */
function marcarError(idCampo, idError, esError) {
    var campo = document.getElementById(idCampo);
    var error = document.getElementById(idError);

    if (campo) {
        if (esError) {
            campo.classList.add('form-control-error');
        } else {
            campo.classList.remove('form-control-error');
        }
    }

    if (error) {
        error.style.display = esError ? 'block' : 'none';
    }
}

/**
 * Deshabilita un botón con spinner
 * @param {string} idBoton
 * @param {string} textoLoading
 */
function deshabilitarBotonConSpinner(idBoton, textoLoading) {
    var btn = /** @type {HTMLButtonElement} */ (document.getElementById(idBoton));
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="ti ti-loader spinner"></i> ' + textoLoading;
    }
}

/**
 * Habilita un botón
 * @param {string} idBoton
 * @param {string} textoOriginal
 * @param {string} iconoClase
 */
function habilitarBoton(idBoton, textoOriginal, iconoClase) {
    var btn = /** @type {HTMLButtonElement} */ (document.getElementById(idBoton));
    if (btn) {
        btn.disabled = false;
        if (iconoClase) {
            btn.innerHTML = '<i class="' + iconoClase + '"></i> ' + textoOriginal;
        } else {
            btn.textContent = textoOriginal;
        }
    }
}