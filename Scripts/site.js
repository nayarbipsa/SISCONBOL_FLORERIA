/* =====================================================
   SISCONBOL_FLORERIA - JavaScript Global
   Archivo: Scripts/site.js
   Versión: 2.0 CONSOLIDADA
   Uso: Todas las páginas con MasterPage
   ===================================================== */

// ============================================
// SIDEBAR MÓVIL
// ============================================

function abrirSidebar() {
    var sidebar = document.getElementById('sidebar');
    var overlay = document.getElementById('overlay');
    if (sidebar) { sidebar.classList.add('open'); }
    if (overlay) { overlay.classList.add('show'); }
}

function cerrarSidebar() {
    var sidebar = document.getElementById('sidebar');
    var overlay = document.getElementById('overlay');
    if (sidebar) { sidebar.classList.remove('open'); }
    if (overlay) { overlay.classList.remove('show'); }
}

// ============================================
// MENÚ JERÁRQUICO
// ============================================

/**
 * Toggle de items del menú con hijos
 * @param {string} id - ID del contenedor de hijos
 */
function toggleHijos(/** @type {string} */ id) {
    var el = document.getElementById(id);
    if (el) {
        el.classList.toggle('open');
    }
}

// ============================================
// AVATAR MENU (TOPBAR)
// ============================================

function toggleAvatarMenu() {
    var menu = document.getElementById('avatarMenu');
    if (menu) {
        menu.classList.toggle('show');
    }
}

// Cerrar avatar menu al hacer clic fuera
document.addEventListener('DOMContentLoaded', function () {
    document.addEventListener('click', function (e) {
        var avatar = document.getElementById('avatarBtn');
        var menu = document.getElementById('avatarMenu');

        if (!avatar || !menu) return;

        var clickDentro = avatar.contains(/** @type {Node} */(e.target)) ||
            menu.contains(/** @type {Node} */(e.target));

        if (!clickDentro && menu.classList.contains('show')) {
            menu.classList.remove('show');
        }
    });
});

// ============================================
// CERRAR SESIÓN
// ============================================

/**
 * Cierra la sesión del usuario
 * Nota: Esta función es sobrescrita en Site.Master para usar el botón del master
 */
function cerrarSesion() {
    var elHd = /** @type {HTMLInputElement} */ (document.getElementById('hdCerrar'));
    var elBtn = document.getElementById('btnCerrarSesion');
    if (elHd) { elHd.value = '1'; }
    if (elBtn) { elBtn.click(); }
}

// ============================================
// ALERTAS
// ============================================

/**
 * Muestra una alerta temporal con auto-ocultado
 * @param {string} mensaje - Texto del mensaje
 * @param {string} tipo - success, error, warning, info
 */
function mostrarAlerta(/** @type {string} */ mensaje, /** @type {string} */ tipo) {
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
 * Oculta la alerta actual
 */
function ocultarAlerta() {
    var div = document.getElementById('divAlerta');
    if (div) {
        div.className = 'alerta';
    }
}

// ============================================
// VALIDACIÓN DE FORMULARIOS
// ============================================

/**
 * Marca un campo con error visual
 * @param {string} idCampo - ID del campo input
 * @param {string} idError - ID del mensaje de error
 * @param {boolean} esError - true para marcar error, false para quitar
 */
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
        error.style.display = esError ? 'block' : 'none';
    }
}

/**
 * Limpia todos los errores de formulario
 */
function limpiarErrores() {
    var camposError = document.querySelectorAll('.campo-error');
    for (var i = 0; i < camposError.length; i++) {
        camposError[i].classList.remove('campo-error');
        camposError[i].classList.remove('campo-ok');
    }

    var mensajesError = document.querySelectorAll('.error');
    for (var j = 0; j < mensajesError.length; j++) {
        mensajesError[j].style.display = 'none';
    }
}

/**
 * Valida que un campo no esté vacío
 * @param {string} idCampo - ID del campo input
 * @param {string} idError - ID del mensaje de error
 * @returns {boolean} - true si es válido, false si está vacío
 */
function validarRequerido(/** @type {string} */ idCampo, /** @type {string} */ idError) {
    var campo = /** @type {HTMLInputElement} */ (document.getElementById(idCampo));

    if (!campo) return true;

    var valor = campo.value.trim();
    var esValido = valor !== '';

    marcarError(idCampo, idError, !esValido);

    if (!esValido && campo.focus) {
        campo.focus();
    }

    return esValido;
}

/**
 * Valida formato de email
 * @param {string} email - Email a validar
 * @returns {boolean} - true si es válido
 */
function validarEmail(/** @type {string} */ email) {
    var regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return regex.test(email);
}

/**
 * Valida un campo de email
 * @param {string} idCampo - ID del campo input
 * @param {string} idError - ID del mensaje de error
 * @returns {boolean} - true si es válido
 */
function validarCampoEmail(/** @type {string} */ idCampo, /** @type {string} */ idError) {
    var campo = /** @type {HTMLInputElement} */ (document.getElementById(idCampo));

    if (!campo) return true;

    var valor = campo.value.trim();

    if (valor === '') {
        marcarError(idCampo, idError, true);
        return false;
    }

    var esValido = validarEmail(valor);
    marcarError(idCampo, idError, !esValido);

    return esValido;
}

// ============================================
// FORMATEO DE DATOS
// ============================================

/**
 * Formatea fecha a DD/MM/YYYY
 * @param {string} fecha - Fecha en formato ISO o similar
 * @returns {string} - Fecha formateada
 */
function formatearFecha(/** @type {string} */ fecha) {
    if (!fecha) return '';
    var d = new Date(fecha);
    if (isNaN(d.getTime())) return fecha;

    var dia = ('0' + d.getDate()).slice(-2);
    var mes = ('0' + (d.getMonth() + 1)).slice(-2);
    var anio = d.getFullYear();

    return dia + '/' + mes + '/' + anio;
}

/**
 * Formatea número a moneda boliviana
 * @param {number} monto - Monto a formatear
 * @returns {string} - Monto formateado como "Bs 1,234.56"
 */
function formatearBs(/** @type {number} */ monto) {
    if (typeof monto !== 'number') {
        monto = parseFloat(monto) || 0;
    }
    return 'Bs ' + monto.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

/**
 * Formatea número a moneda dólares
 * @param {number} monto - Monto a formatear
 * @returns {string} - Monto formateado como "$us 1,234.56"
 */
function formatearUsd(/** @type {number} */ monto) {
    if (typeof monto !== 'number') {
        monto = parseFloat(monto) || 0;
    }
    return '$us ' + monto.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

/**
 * Formatea número con separadores de miles
 * @param {number} numero - Número a formatear
 * @returns {string} - Número formateado
 */
function formatearNumero(/** @type {number} */ numero) {
    if (typeof numero !== 'number') {
        numero = parseFloat(numero) || 0;
    }
    return numero.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

// ============================================
// UTILIDADES DE CAMPOS
// ============================================

/**
 * Obtiene el valor de un input con fallback
 * @param {string} idCampo - ID del campo
 * @param {string} valorDefault - Valor por defecto si está vacío
 * @returns {string} - Valor del campo o default
 */
function obtenerValor(/** @type {string} */ idCampo, /** @type {string} */ valorDefault) {
    var campo = /** @type {HTMLInputElement} */ (document.getElementById(idCampo));
    if (!campo) return valorDefault;

    var valor = campo.value.trim();
    return valor === '' ? valorDefault : valor;
}

/**
 * Establece el valor de un input
 * @param {string} idCampo - ID del campo
 * @param {string} valor - Valor a establecer
 */
function establecerValor(/** @type {string} */ idCampo, /** @type {string} */ valor) {
    var campo = /** @type {HTMLInputElement} */ (document.getElementById(idCampo));
    if (campo) {
        campo.value = valor;
    }
}

/**
 * Limpia el valor de un campo
 * @param {string} idCampo - ID del campo
 */
function limpiarCampo(/** @type {string} */ idCampo) {
    establecerValor(idCampo, '');
}

/**
 * Habilita un campo
 * @param {string} idCampo - ID del campo
 */
function habilitarCampo(/** @type {string} */ idCampo) {
    var campo = /** @type {HTMLInputElement} */ (document.getElementById(idCampo));
    if (campo) {
        campo.disabled = false;
    }
}

/**
 * Deshabilita un campo
 * @param {string} idCampo - ID del campo
 */
function deshabilitarCampo(/** @type {string} */ idCampo) {
    var campo = /** @type {HTMLInputElement} */ (document.getElementById(idCampo));
    if (campo) {
        campo.disabled = true;
    }
}

// ============================================
// UTILIDADES DE BOTONES
// ============================================

/**
 * Deshabilita un botón con spinner de carga
 * @param {string} idBoton - ID del botón
 * @param {string} textoLoading - Texto a mostrar mientras carga
 */
function deshabilitarBotonConSpinner(/** @type {string} */ idBoton, /** @type {string} */ textoLoading) {
    var btn = /** @type {HTMLButtonElement} */ (document.getElementById(idBoton));
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="ti ti-loader spinner"></i> ' + textoLoading;
    }
}

/**
 * Habilita un botón restaurando su contenido original
 * @param {string} idBoton - ID del botón
 * @param {string} textoOriginal - Texto original del botón
 * @param {string} iconoClase - Clase del icono (opcional)
 */
function habilitarBoton(/** @type {string} */ idBoton, /** @type {string} */ textoOriginal, /** @type {string} */ iconoClase) {
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

// ============================================
// NAVEGACIÓN Y SCROLL
// ============================================

/**
 * Hace scroll al top de la página
 */
function scrollTop() {
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

/**
 * Hace scroll a un elemento específico
 * @param {string} idElemento - ID del elemento
 */
function scrollToElement(/** @type {string} */ idElemento) {
    var el = document.getElementById(idElemento);
    if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}

// ============================================
// DIÁLOGOS Y CONFIRMACIONES
// ============================================

/**
 * Muestra un diálogo de confirmación
 * @param {string} mensaje - Mensaje a mostrar
 * @returns {boolean} - true si confirma, false si cancela
 */
function confirmar(/** @type {string} */ mensaje) {
    return confirm(mensaje);
}

// ============================================
// UTILIDADES DE TABLAS
// ============================================

/**
 * Alterna la visibilidad de una fila expandible en tabla
 * @param {string} idFila - ID de la fila a mostrar/ocultar
 */
function toggleFilaDetalle(/** @type {string} */ idFila) {
    var fila = document.getElementById(idFila);
    if (fila) {
        var display = fila.style.display;
        fila.style.display = (display === 'none' || display === '') ? 'table-row' : 'none';
    }
}

// ============================================
// UTILIDADES DE VISTAS/PESTAÑAS
// ============================================

/**
 * Cambia entre vistas/pestañas
 * @param {string} idVista - ID de la vista a mostrar
 */
function mostrarVista(/** @type {string} */ idVista) {
    // Ocultar todas las vistas
    var vistas = document.querySelectorAll('.vista');
    for (var i = 0; i < vistas.length; i++) {
        vistas[i].classList.remove('activa');
    }

    // Mostrar la vista seleccionada
    var vista = document.getElementById(idVista);
    if (vista) {
        vista.classList.add('activa');
    }
}

/**
 * Activa una pestaña y su contenido
 * @param {string} idPestana - ID de la pestaña
 * @param {string} idContenido - ID del contenido a mostrar
 */
function activarPestana(/** @type {string} */ idPestana, /** @type {string} */ idContenido) {
    // Desactivar todas las pestañas
    var pestanas = document.querySelectorAll('.tab');
    for (var i = 0; i < pestanas.length; i++) {
        pestanas[i].classList.remove('activa');
    }

    // Activar la pestaña seleccionada
    var pestana = document.getElementById(idPestana);
    if (pestana) {
        pestana.classList.add('activa');
    }

    // Mostrar el contenido correspondiente
    mostrarVista(idContenido);
}

// ============================================
// UTILIDADES DE MODALES
// ============================================

/**
 * Abre un modal
 * @param {string} idModal - ID del modal a abrir
 */
function abrirModal(/** @type {string} */ idModal) {
    var modal = document.getElementById(idModal);
    if (modal) {
        modal.classList.add('show');
    }
}

/**
 * Cierra un modal
 * @param {string} idModal - ID del modal a cerrar
 */
function cerrarModal(/** @type {string} */ idModal) {
    var modal = document.getElementById(idModal);
    if (modal) {
        modal.classList.remove('show');
    }
}

// ============================================
// UTILIDADES DE IMÁGENES
// ============================================

/**
 * Previsualiza una imagen antes de subirla
 * @param {string} idInput - ID del input file
 * @param {string} idImagen - ID de la imagen donde mostrar preview
 */
function previsualizarImagen(/** @type {string} */ idInput, /** @type {string} */ idImagen) {
    var input = /** @type {HTMLInputElement} */ (document.getElementById(idInput));
    var img = /** @type {HTMLImageElement} */ (document.getElementById(idImagen));

    if (!input || !img) return;

    if (input.files && input.files[0]) {
        var reader = new FileReader();

        reader.onload = function (e) {
            if (e.target && typeof e.target.result === 'string') {
                img.src = e.target.result;
                img.style.display = 'block';
            }
        };

        reader.readAsDataURL(input.files[0]);
    }
}

// ============================================
// UTILIDADES DE ARRAYS Y OBJETOS
// ============================================

/**
 * Verifica si un array contiene un valor
 * @param {Array} arr - Array a verificar
 * @param {*} valor - Valor a buscar
 * @returns {boolean} - true si contiene el valor
 */
function contiene(/** @type {Array} */ arr, /** @type {*} */ valor) {
    if (!arr || !Array.isArray(arr)) return false;

    for (var i = 0; i < arr.length; i++) {
        if (arr[i] === valor) return true;
    }
    return false;
}

// ============================================
// UTILIDADES DE STRINGS
// ============================================

/**
 * Capitaliza la primera letra de un string
 * @param {string} str - String a capitalizar
 * @returns {string} - String capitalizado
 */
function capitalizar(/** @type {string} */ str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
}

/**
 * Trunca un string a un largo máximo
 * @param {string} str - String a truncar
 * @param {number} maxLength - Largo máximo
 * @returns {string} - String truncado
 */
function truncar(/** @type {string} */ str, /** @type {number} */ maxLength) {
    if (!str) return '';
    if (str.length <= maxLength) return str;
    return str.substring(0, maxLength) + '...';
}

// ============================================
// FIN DE ARCHIVO
// ============================================