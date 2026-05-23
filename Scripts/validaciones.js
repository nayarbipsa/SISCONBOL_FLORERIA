// ============================================================
// SISCONBOL - Validaciones JavaScript
// Archivo: Scripts/validaciones.js
// Uso: Funciones de validación reutilizables
// ============================================================
// @ts-nocheck

var Validaciones = (function() {
    'use strict';

    // ========================================================
    // VALIDACIONES DE TEXTO
    // ========================================================

    /**
     * Valida que un texto solo contenga letras, espacios y acentos
     * @param {string} texto - Texto a validar
     * @returns {boolean}
     */
    function esTextoValido(texto) {
        if (!texto) return false;
        texto = texto.trim();
        if (texto === '') return false;
        // Solo letras, espacios, acentos, ñ
        var regex = /^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$/;
        return regex.test(texto);
    }

    /**
     * Valida que un texto alfanumérico sea válido
     * @param {string} texto - Texto a validar
     * @returns {boolean}
     */
    function esAlfanumericoValido(texto) {
        if (!texto) return false;
        texto = texto.trim();
        if (texto === '') return false;
        // Letras, números, espacios, guiones, puntos
        var regex = /^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s\.\-]+$/;
        return regex.test(texto);
    }

    // ========================================================
    // VALIDACIONES DE CELULAR
    // ========================================================

    /**
     * Valida que un celular tenga formato válido
     * @param {string} celular - Celular a validar
     * @returns {boolean}
     */
    function esCelularValido(celular) {
        if (!celular) return false;
        celular = celular.trim();
        if (celular === '') return false;

        // Solo números, +, espacios, guiones, paréntesis
        var regex = /^[\d\s\+\-\(\)]+$/;
        if (!regex.test(celular)) return false;

        // Contar solo dígitos
        var digitos = celular.replace(/[^\d]/g, '');
        
        // Mínimo 7 dígitos
        if (digitos.length < 7) return false;
        
        // Máximo 15 dígitos
        if (digitos.length > 15) return false;

        return true;
    }

    /**
     * Normaliza un celular removiendo formato
     * @param {string} celular - Celular a normalizar
     * @returns {string}
     */
    function normalizarCelular(celular) {
        if (!celular) return '';
        return celular.replace(/[\s\-\(\)]/g, '');
    }

    // ========================================================
    // VALIDACIONES DE EMAIL
    // ========================================================

    /**
     * Valida que un email tenga formato válido
     * @param {string} email - Email a validar
     * @returns {boolean}
     */
    function esEmailValido(email) {
        if (!email) return false;
        email = email.trim();
        if (email === '') return false;
        // Regex básico de email
        var regex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        return regex.test(email);
    }

    // ========================================================
    // VALIDACIONES DE LONGITUD
    // ========================================================

    /**
     * Valida que un texto esté dentro de un rango de longitud
     * @param {string} texto - Texto a validar
     * @param {number} minimo - Longitud mínima
     * @param {number} maximo - Longitud máxima
     * @returns {boolean}
     */
    function validarLongitud(texto, minimo, maximo) {
        if (!texto) return false;
        var longitud = texto.trim().length;
        return longitud >= minimo && longitud <= maximo;
    }

    // ========================================================
    // DETECCIÓN DE PATRONES PELIGROSOS
    // ========================================================

    /**
     * Detecta posibles intentos de inyección SQL o XSS
     * @param {string} texto - Texto a validar
     * @returns {boolean}
     */
    function tienePatronPeligroso(texto) {
        if (!texto) return false;
        
        texto = texto.toUpperCase();
        
        var patrones = [
            'DROP TABLE', 'DROP DATABASE', 'DELETE FROM',
            'INSERT INTO', 'UPDATE ', 'EXEC ', 'EXECUTE',
            'SCRIPT>', '<SCRIPT', 'UNION SELECT', 'OR 1=1',
            '\'; DROP', '--', '/*', '*/', 'XP_', 'SP_'
        ];
        
        for (var i = 0; i < patrones.length; i++) {
            if (texto.indexOf(patrones[i]) !== -1) {
                return true;
            }
        }
        
        return false;
    }

    // ========================================================
    // VALIDACIÓN Y MARCADO DE ERRORES EN UI
    // ========================================================

    /**
     * Marca un campo como inválido y muestra mensaje
     * @param {string} idCampo - ID del input
     * @param {string} mensaje - Mensaje de error
     */
    function marcarCampoInvalido(idCampo, mensaje) {
        var campo = /** @type {HTMLInputElement} */ (document.getElementById(idCampo));
        if (campo) {
            campo.style.borderColor = '#F44336';
            campo.style.backgroundColor = '#FFEBEE';
            campo.focus();
        }
        
        if (mensaje) {
            alert(mensaje);
        }
    }

    /**
     * Limpia el marcado de error de un campo
     * @param {string} idCampo - ID del input
     */
    function limpiarCampoInvalido(idCampo) {
        var campo = /** @type {HTMLInputElement} */ (document.getElementById(idCampo));
        if (campo) {
            campo.style.borderColor = '';
            campo.style.backgroundColor = '';
        }
    }

    // ========================================================
    // VALIDACIÓN COMPLETA DE FORMULARIO PRE-PEDIDO
    // ========================================================

    /**
     * Valida formulario de creación de pre-pedido
     * @returns {Object} {valido: boolean, mensaje: string, campo: string}
     */
    function validarFormularioPrePedido() {
        // Obtener valores
        var celular = /** @type {HTMLInputElement} */ (document.getElementById('txCelular'));
        var nombre = /** @type {HTMLInputElement} */ (document.getElementById('txNombre'));
        var apellidos = /** @type {HTMLInputElement} */ (document.getElementById('txApellidos'));
        var email = /** @type {HTMLInputElement} */ (document.getElementById('txEmail'));

        if (!celular) {
            return {valido: false, mensaje: 'Campo celular no encontrado', campo: ''};
        }

        var valCelular = celular.value.trim();
        var valNombre = nombre ? nombre.value.trim() : '';
        var valApellidos = apellidos ? apellidos.value.trim() : '';
        var valEmail = email ? email.value.trim() : '';

        // Validar celular (obligatorio)
        if (valCelular === '') {
            return {valido: false, mensaje: 'El celular es obligatorio', campo: 'txCelular'};
        }

        if (!esCelularValido(valCelular)) {
            return {
                valido: false, 
                mensaje: 'El celular tiene un formato inválido. Use solo números, +, espacios, guiones y paréntesis',
                campo: 'txCelular'
            };
        }

        if (tienePatronPeligroso(valCelular)) {
            return {
                valido: false,
                mensaje: 'El celular contiene caracteres no permitidos',
                campo: 'txCelular'
            };
        }

        // Validar nombre (opcional)
        if (valNombre !== '') {
            if (!esTextoValido(valNombre)) {
                return {
                    valido: false,
                    mensaje: 'El nombre solo puede contener letras y espacios',
                    campo: 'txNombre'
                };
            }

            if (tienePatronPeligroso(valNombre)) {
                return {
                    valido: false,
                    mensaje: 'El nombre contiene caracteres no permitidos',
                    campo: 'txNombre'
                };
            }

            if (valNombre.length > 200) {
                return {
                    valido: false,
                    mensaje: 'El nombre no puede exceder 200 caracteres',
                    campo: 'txNombre'
                };
            }
        }

        // Validar apellidos (opcional)
        if (valApellidos !== '') {
            if (!esTextoValido(valApellidos)) {
                return {
                    valido: false,
                    mensaje: 'Los apellidos solo pueden contener letras y espacios',
                    campo: 'txApellidos'
                };
            }

            if (tienePatronPeligroso(valApellidos)) {
                return {
                    valido: false,
                    mensaje: 'Los apellidos contienen caracteres no permitidos',
                    campo: 'txApellidos'
                };
            }

            if (valApellidos.length > 200) {
                return {
                    valido: false,
                    mensaje: 'Los apellidos no pueden exceder 200 caracteres',
                    campo: 'txApellidos'
                };
            }
        }

        // Validar email (opcional)
        if (valEmail !== '') {
            if (!esEmailValido(valEmail)) {
                return {
                    valido: false,
                    mensaje: 'El email tiene un formato inválido',
                    campo: 'txEmail'
                };
            }

            if (tienePatronPeligroso(valEmail)) {
                return {
                    valido: false,
                    mensaje: 'El email contiene caracteres no permitidos',
                    campo: 'txEmail'
                };
            }

            if (valEmail.length > 100) {
                return {
                    valido: false,
                    mensaje: 'El email no puede exceder 100 caracteres',
                    campo: 'txEmail'
                };
            }
        }

        return {valido: true, mensaje: 'Validación exitosa', campo: ''};
    }

    // ========================================================
    // API PÚBLICA
    // ========================================================

    return {
        esTextoValido: esTextoValido,
        esAlfanumericoValido: esAlfanumericoValido,
        esCelularValido: esCelularValido,
        normalizarCelular: normalizarCelular,
        esEmailValido: esEmailValido,
        validarLongitud: validarLongitud,
        tienePatronPeligroso: tienePatronPeligroso,
        marcarCampoInvalido: marcarCampoInvalido,
        limpiarCampoInvalido: limpiarCampoInvalido,
        validarFormularioPrePedido: validarFormularioPrePedido
    };
})();
