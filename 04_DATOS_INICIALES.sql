-- =============================================
-- SISCONBOL_FLORERIA - DATOS INICIALES DEL SISTEMA
-- Archivo: 04_DATOS_INICIALES.sql
-- Descripción: Usuario admin, tipos de usuario, menú, configuraciones
-- Fecha: 2026-05-22
-- =============================================

USE SISCONBOL;
GO

-- =============================================
-- 1. TIPOS DE USUARIO
-- =============================================

SET IDENTITY_INSERT FLORERIA_TipoUsuario ON;

INSERT INTO FLORERIA_TipoUsuario (tipo_id, nombre, descripcion, activo, creado_en)
VALUES
    (1, 'ADMINISTRADOR', 'Acceso total al sistema', 1, GETDATE()),
    (2, 'GERENTE', 'Gestión de operaciones y reportes', 1, GETDATE()),
    (3, 'VENDEDOR', 'Gestión de pedidos y clientes', 1, GETDATE()),
    (4, 'DELIVERY', 'Gestión de entregas', 1, GETDATE()),
    (5, 'CAJERO', 'Gestión de pagos y caja', 1, GETDATE());

SET IDENTITY_INSERT FLORERIA_TipoUsuario OFF;
GO

-- =============================================
-- 2. USUARIO ADMINISTRADOR INICIAL
-- =============================================

-- Password: 12345678 (el carnet por defecto)
-- Hash: SHA256('12345678' + 'FLORERIA2026')
DECLARE @admin_hash VARCHAR(200) = UPPER(CONVERT(VARCHAR(200),
    HASHBYTES('SHA2_256', '12345678' + 'FLORERIA2026'), 2));

SET IDENTITY_INSERT FLORERIA_Usuario ON;

INSERT INTO FLORERIA_Usuario (
    usuario_id, tipo_id, carnet, nombres, apellidos,
    celular, email, password_hash, password_salt,
    debe_cambiar_pwd, activo, bloqueado,
    creado_por, creado_en
)
VALUES (
    1, 1, '12345678', 'Administrador', 'Sistema',
    '70000000', 'admin@sisconbol.com', @admin_hash, 'FLORERIA2026',
    1, 1, 0,
    NULL, GETDATE()
);

SET IDENTITY_INSERT FLORERIA_Usuario OFF;
GO

-- =============================================
-- 3. MENÚ DEL SISTEMA
-- =============================================

SET IDENTITY_INSERT FLORERIA_Menu ON;

-- MENÚ PRINCIPAL (Nivel 1)
INSERT INTO FLORERIA_Menu (menu_id, padre_id, nombre, icono, ruta, orden, activo)
VALUES
    (1,  NULL, 'Dashboard',      'fas fa-home',           '~/Default.aspx',                    1, 1),
    (2,  NULL, 'Pre-Pedidos',    'fas fa-clipboard-list', NULL,                                2, 1),
    (3,  NULL, 'Pedidos',        'fas fa-shopping-cart',  NULL,                                3, 1),
    (4,  NULL, 'Catálogo',       'fas fa-flower',         NULL,                                4, 1),
    (5,  NULL, 'Delivery',       'fas fa-truck',          NULL,                                5, 1),
    (6,  NULL, 'Finanzas',       'fas fa-dollar-sign',    NULL,                                6, 1),
    (7,  NULL, 'Configuración',  'fas fa-cog',            NULL,                                7, 1),
    (8,  NULL, 'Reportes',       'fas fa-chart-bar',      NULL,                                8, 1);

-- SUBMENÚ: PRE-PEDIDOS (Nivel 2)
INSERT INTO FLORERIA_Menu (menu_id, padre_id, nombre, icono, ruta, orden, activo)
VALUES
    (10, 2, 'Nuevo Pre-Pedido',     'fas fa-plus',      '~/Modulos/Pedidos/PrePedidos.aspx',     1, 1),
    (11, 2, 'Lista Pre-Pedidos',    'fas fa-list',      '~/Modulos/Pedidos/ListaPrePedidos.aspx', 2, 1),
    (12, 2, 'Mostrador',            'fas fa-store',     '~/Modulos/Pedidos/Mostrador.aspx',      3, 1);

-- SUBMENÚ: PEDIDOS (Nivel 2)
INSERT INTO FLORERIA_Menu (menu_id, padre_id, nombre, icono, ruta, orden, activo)
VALUES
    (20, 3, 'Lista de Pedidos',     'fas fa-list-ul',   '~/Modulos/Pedidos/Lista.aspx',          1, 1),
    (21, 3, 'Calendario',           'fas fa-calendar',  '~/Modulos/Pedidos/Calendario.aspx',     2, 1),
    (22, 3, 'Seguimiento',          'fas fa-route',     '~/Modulos/Pedidos/Seguimiento.aspx',    3, 1);

-- SUBMENÚ: CATÁLOGO (Nivel 2)
INSERT INTO FLORERIA_Menu (menu_id, padre_id, nombre, icono, ruta, orden, activo)
VALUES
    (30, 4, 'Productos',            'fas fa-box',       '~/Modulos/Catalogo/Productos.aspx',     1, 1),
    (31, 4, 'Categorías',           'fas fa-tags',      '~/Modulos/Catalogo/Categorias.aspx',    2, 1),
    (32, 4, 'Inventario',           'fas fa-warehouse', '~/Modulos/Catalogo/Inventario.aspx',    3, 1);

-- SUBMENÚ: DELIVERY (Nivel 2)
INSERT INTO FLORERIA_Menu (menu_id, padre_id, nombre, icono, ruta, orden, activo)
VALUES
    (40, 5, 'Entregas del Día',     'fas fa-calendar-day', '~/Modulos/Delivery/Lista.aspx',      1, 1),
    (41, 5, 'Rutas',                'fas fa-map-marked',   '~/Modulos/Delivery/Rutas.aspx',      2, 1);

-- SUBMENÚ: FINANZAS (Nivel 2)
INSERT INTO FLORERIA_Menu (menu_id, padre_id, nombre, icono, ruta, orden, activo)
VALUES
    (50, 6, 'Caja',                 'fas fa-cash-register', '~/Modulos/Finanzas/Caja.aspx',      1, 1),
    (51, 6, 'Gastos',               'fas fa-money-bill',    '~/Modulos/Finanzas/Gastos.aspx',    2, 1),
    (52, 6, 'Pagos Pendientes',    'fas fa-clock',         '~/Modulos/Finanzas/Pendientes.aspx', 3, 1);

-- SUBMENÚ: CONFIGURACIÓN (Nivel 2)
INSERT INTO FLORERIA_Menu (menu_id, padre_id, nombre, icono, ruta, orden, activo)
VALUES
    (60, 7, 'Usuarios',             'fas fa-users',         '~/Modulos/Config/Usuarios.aspx',    1, 1),
    (61, 7, 'Zonas',                'fas fa-map',           '~/Modulos/Config/Zonas.aspx',       2, 1),
    (62, 7, 'Slots Horarios',       'fas fa-clock',         '~/Modulos/Config/Slots.aspx',       3, 1),
    (63, 7, 'Sucursales',           'fas fa-building',      '~/Modulos/Config/Sucursales.aspx',  4, 1),
    (64, 7, 'Campañas',             'fas fa-bullhorn',      '~/Modulos/Config/Campanas.aspx',    5, 1),
    (65, 7, 'Sistema',              'fas fa-server',        '~/Modulos/Config/Sistema.aspx',     6, 1);

-- SUBMENÚ: REPORTES (Nivel 2)
INSERT INTO FLORERIA_Menu (menu_id, padre_id, nombre, icono, ruta, orden, activo)
VALUES
    (70, 8, 'Ventas',               'fas fa-chart-line',    '~/Modulos/Reportes/Ventas.aspx',    1, 1),
    (71, 8, 'Productos',            'fas fa-chart-pie',     '~/Modulos/Reportes/Productos.aspx', 2, 1),
    (72, 8, 'Clientes',             'fas fa-users',         '~/Modulos/Reportes/Clientes.aspx',  3, 1),
    (73, 8, 'Auditoría',            'fas fa-history',       '~/Modulos/Reportes/Auditoria.aspx', 4, 1);

SET IDENTITY_INSERT FLORERIA_Menu OFF;
GO

-- =============================================
-- 4. PERMISOS PARA TIPO ADMINISTRADOR
-- =============================================

-- Dar acceso completo a ADMINISTRADOR a todos los menús
INSERT INTO FLORERIA_TipoUsuario_Menu (tipo_id, menu_id, puede_ver, puede_crear, puede_editar, puede_eliminar)
SELECT 1, menu_id, 1, 1, 1, 1
FROM FLORERIA_Menu;
GO

-- =============================================
-- 5. PERMISOS PARA TIPO GERENTE
-- =============================================

-- Gerente: acceso a todo excepto configuración de sistema
INSERT INTO FLORERIA_TipoUsuario_Menu (tipo_id, menu_id, puede_ver, puede_crear, puede_editar, puede_eliminar)
SELECT 2, menu_id, 1, 1, 1, 1
FROM FLORERIA_Menu
WHERE menu_id NOT IN (65); -- Excluir "Sistema"
GO

-- =============================================
-- 6. PERMISOS PARA TIPO VENDEDOR
-- =============================================

-- Vendedor: Pre-Pedidos, Pedidos, Catálogo (solo ver)
INSERT INTO FLORERIA_TipoUsuario_Menu (tipo_id, menu_id, puede_ver, puede_crear, puede_editar, puede_eliminar)
VALUES
    -- Dashboard
    (3, 1, 1, 0, 0, 0),
    -- Pre-Pedidos (acceso completo)
    (3, 2,  1, 1, 1, 0),
    (3, 10, 1, 1, 1, 0),
    (3, 11, 1, 1, 1, 0),
    (3, 12, 1, 1, 1, 0),
    -- Pedidos (ver y editar)
    (3, 3,  1, 0, 1, 0),
    (3, 20, 1, 0, 1, 0),
    (3, 21, 1, 0, 1, 0),
    (3, 22, 1, 0, 0, 0),
    -- Catálogo (solo ver)
    (3, 4,  1, 0, 0, 0),
    (3, 30, 1, 0, 0, 0),
    (3, 31, 1, 0, 0, 0),
    (3, 32, 1, 0, 0, 0);
GO

-- =============================================
-- 7. PERMISOS PARA TIPO DELIVERY
-- =============================================

-- Delivery: Solo módulo de entregas
INSERT INTO FLORERIA_TipoUsuario_Menu (tipo_id, menu_id, puede_ver, puede_crear, puede_editar, puede_eliminar)
VALUES
    -- Dashboard
    (4, 1, 1, 0, 0, 0),
    -- Delivery
    (4, 5,  1, 0, 1, 0),
    (4, 40, 1, 0, 1, 0),
    (4, 41, 1, 0, 0, 0);
GO

-- =============================================
-- 8. PERMISOS PARA TIPO CAJERO
-- =============================================

-- Cajero: Solo finanzas y ver pedidos
INSERT INTO FLORERIA_TipoUsuario_Menu (tipo_id, menu_id, puede_ver, puede_crear, puede_editar, puede_eliminar)
VALUES
    -- Dashboard
    (5, 1, 1, 0, 0, 0),
    -- Pedidos (solo ver)
    (5, 3,  1, 0, 0, 0),
    (5, 20, 1, 0, 0, 0),
    -- Finanzas (acceso completo)
    (5, 6,  1, 1, 1, 0),
    (5, 50, 1, 1, 1, 0),
    (5, 51, 1, 1, 1, 0),
    (5, 52, 1, 1, 1, 0);
GO

-- =============================================
-- 9. CONFIGURACIONES DEL SISTEMA
-- =============================================

INSERT INTO FLORERIA_Config (clave, valor, descripcion, es_secreto, activo, modificado_por, modificado_en)
VALUES
    -- Configuración general
    ('NOMBRE_EMPRESA',        'Miss Flores',                          'Nombre de la empresa',                          0, 1, 1, GETDATE()),
    ('DIRECCION_EMPRESA',     'La Paz, Bolivia',                      'Dirección principal',                           0, 1, 1, GETDATE()),
    ('TELEFONO_EMPRESA',      '70000000',                             'Teléfono de contacto',                          0, 1, 1, GETDATE()),
    ('EMAIL_EMPRESA',         'contacto@missflores.com',              'Email de contacto',                             0, 1, 1, GETDATE()),
    
    -- Configuración de negocio
    ('TASA_CAMBIO_USD',       '7.00',                                 'Tasa de cambio USD a BOB',                      0, 1, 1, GETDATE()),
    ('TIEMPO_EXPIRACION_LINK','48',                                   'Horas de expiración del link de pago',          0, 1, 1, GETDATE()),
    ('STOCK_MINIMO_DEFAULT',  '5',                                    'Stock mínimo por defecto para productos',       0, 1, 1, GETDATE()),
    ('ANTICIPO_MINIMO_PORC',  '50',                                   'Porcentaje mínimo de anticipo (%)',             0, 1, 1, GETDATE()),
    
    -- Configuración de horarios
    ('HORA_APERTURA',         '08:00',                                'Hora de apertura',                              0, 1, 1, GETDATE()),
    ('HORA_CIERRE',           '19:00',                                'Hora de cierre',                                0, 1, 1, GETDATE()),
    ('DIAS_LABORALES',        'L,M,X,J,V,S',                          'Días laborales (L=Lunes, D=Domingo)',           0, 1, 1, GETDATE()),
    
    -- URLs y rutas
    ('URL_FORMULARIO_WEB',    'https://miss-flores.com',              'URL base del formulario web',                   0, 1, 1, GETDATE()),
    ('URL_LOGO_EMPRESA',      '/Imagenes/logo.png',                   'Ruta del logo de la empresa',                   0, 1, 1, GETDATE()),
    
    -- WooCommerce (secretos)
    ('WC_URL',                '',                                     'URL de WooCommerce',                            1, 1, 1, GETDATE()),
    ('WC_CONSUMER_KEY',       '',                                     'Consumer Key de WooCommerce',                   1, 1, 1, GETDATE()),
    ('WC_CONSUMER_SECRET',    '',                                     'Consumer Secret de WooCommerce',                1, 1, 1, GETDATE()),
    
    -- Notificaciones
    ('SMTP_HOST',             '',                                     'Servidor SMTP',                                 1, 1, 1, GETDATE()),
    ('SMTP_PORT',             '587',                                  'Puerto SMTP',                                   0, 1, 1, GETDATE()),
    ('SMTP_USER',             '',                                     'Usuario SMTP',                                  1, 1, 1, GETDATE()),
    ('SMTP_PASSWORD',         '',                                     'Contraseña SMTP',                               1, 1, 1, GETDATE()),
    
    -- Otras configuraciones
    ('MENSAJES_POR_PAGINA',   '20',                                   'Cantidad de registros por página',              0, 1, 1, GETDATE()),
    ('TIEMPO_SESION_HORAS',   '8',                                    'Duración de sesión en horas',                   0, 1, 1, GETDATE());
GO

-- =============================================
-- 10. DATOS GEOGRÁFICOS INICIALES
-- =============================================

-- País: Bolivia
SET IDENTITY_INSERT FLORERIA_Pais ON;
INSERT INTO FLORERIA_Pais (pais_id, codigo_iso, nombre, activo)
VALUES (1, 'BO', 'Bolivia', 1);
SET IDENTITY_INSERT FLORERIA_Pais OFF;
GO

-- Departamentos principales
SET IDENTITY_INSERT FLORERIA_Departamento ON;
INSERT INTO FLORERIA_Departamento (dpto_id, pais_id, nombre, activo)
VALUES
    (1, 1, 'La Paz', 1),
    (2, 1, 'Santa Cruz', 1),
    (3, 1, 'Cochabamba', 1);
SET IDENTITY_INSERT FLORERIA_Departamento OFF;
GO

-- Ciudades principales
SET IDENTITY_INSERT FLORERIA_Ciudad ON;
INSERT INTO FLORERIA_Ciudad (ciudad_id, dpto_id, nombre, activo)
VALUES
    (1, 1, 'La Paz', 1),
    (2, 1, 'El Alto', 1),
    (3, 2, 'Santa Cruz de la Sierra', 1),
    (4, 3, 'Cochabamba', 1);
SET IDENTITY_INSERT FLORERIA_Ciudad OFF;
GO

-- =============================================
-- 11. SLOTS HORARIOS PREDETERMINADOS
-- =============================================

SET IDENTITY_INSERT FLORERIA_Slot_Horario ON;
INSERT INTO FLORERIA_Slot_Horario (slot_id, etiqueta, hora_inicio, hora_fin, recargo_bs, recargo_usd, orden, activo)
VALUES
    (1, 'Mañana (09:00 - 12:00)',     '09:00:00', '12:00:00',  0.00, 0.00, 1, 1),
    (2, 'Tarde (14:00 - 18:00)',      '14:00:00', '18:00:00',  0.00, 0.00, 2, 1),
    (3, 'Noche (18:00 - 20:00)',      '18:00:00', '20:00:00', 10.00, 1.50, 3, 1);
SET IDENTITY_INSERT FLORERIA_Slot_Horario OFF;
GO

-- =============================================
-- 12. AUDITORÍA DE INSTALACIÓN INICIAL
-- =============================================

INSERT INTO FLORERIA_Auditoria (
    usuario_id, usuario_nombre, ip, tabla, registro_id, 
    accion, valor_nuevo, motivo, fecha_hora
)
VALUES (
    1, 'Administrador Sistema', '127.0.0.1', 'SISTEMA',
    'INSTALACION_INICIAL', 'INSERTAR',
    '{"version":"1.0","fecha":"' + CONVERT(VARCHAR, GETDATE(), 120) + '"}',
    'Instalación inicial del sistema SISCONBOL_FLORERIA',
    GETDATE()
);
GO

-- =============================================
-- FIN DE DATOS INICIALES
-- =============================================

PRINT '========================================';
PRINT 'DATOS INICIALES INSTALADOS CORRECTAMENTE';
PRINT '========================================';
PRINT '';
PRINT 'Usuario Administrador:';
PRINT '  Carnet:   12345678';
PRINT '  Password: 12345678';
PRINT '  Debe cambiar contraseña al primer login';
PRINT '';
PRINT 'Total registros creados:';
PRINT '  - 5 Tipos de usuario';
PRINT '  - 1 Usuario administrador';
PRINT '  - 35 Menús';
PRINT '  - 21 Configuraciones';
PRINT '  - 1 País, 3 Departamentos, 4 Ciudades';
PRINT '  - 3 Slots horarios';
PRINT '';
PRINT 'Sistema listo para usar.';
PRINT '========================================';
GO
