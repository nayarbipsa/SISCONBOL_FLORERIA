-- =============================================
-- SISCONBOL_FLORERIA - CREACIÓN DE TODOS LOS ÍNDICES
-- Archivo: 02_CREAR_TODOS_LOS_INDICES.sql
-- Total: 51 Índices
-- Fecha: 2026-05-22
-- =============================================

USE SISCONBOL;
GO

-- =============================================
-- ÍNDICES: MÓDULO USUARIOS Y ACCESOS (12 índices)
-- =============================================

-- Tabla FLORERIA_Usuario
CREATE NONCLUSTERED INDEX IX_Usuario_TipoId ON FLORERIA_Usuario(tipo_id);
CREATE NONCLUSTERED INDEX IX_Usuario_Activo ON FLORERIA_Usuario(activo);
CREATE NONCLUSTERED INDEX IX_Usuario_Email ON FLORERIA_Usuario(email);
CREATE NONCLUSTERED INDEX IX_Usuario_Celular ON FLORERIA_Usuario(celular);

-- Tabla FLORERIA_Sesion
CREATE NONCLUSTERED INDEX IX_Sesion_UsuarioId ON FLORERIA_Sesion(usuario_id);
CREATE NONCLUSTERED INDEX IX_Sesion_Activa ON FLORERIA_Sesion(activa);
CREATE NONCLUSTERED INDEX IX_Sesion_ExpiraEn ON FLORERIA_Sesion(expira_en);

-- Tabla FLORERIA_Menu
CREATE NONCLUSTERED INDEX IX_Menu_PadreId ON FLORERIA_Menu(padre_id);
CREATE NONCLUSTERED INDEX IX_Menu_Activo ON FLORERIA_Menu(activo);

-- Tabla FLORERIA_Auditoria
CREATE NONCLUSTERED INDEX IX_Auditoria_UsuarioId ON FLORERIA_Auditoria(usuario_id);
CREATE NONCLUSTERED INDEX IX_Auditoria_Tabla ON FLORERIA_Auditoria(tabla);
CREATE NONCLUSTERED INDEX IX_Auditoria_FechaHora ON FLORERIA_Auditoria(fecha_hora);

-- =============================================
-- ÍNDICES: MÓDULO GEOGRAFÍA (11 índices)
-- =============================================

-- Tabla FLORERIA_Departamento
CREATE NONCLUSTERED INDEX IX_Departamento_PaisId ON FLORERIA_Departamento(pais_id);

-- Tabla FLORERIA_Ciudad
CREATE NONCLUSTERED INDEX IX_Ciudad_DeptoId ON FLORERIA_Ciudad(dpto_id);
CREATE NONCLUSTERED INDEX IX_Ciudad_Activo ON FLORERIA_Ciudad(activo);

-- Tabla FLORERIA_Sucursal
CREATE NONCLUSTERED INDEX IX_Sucursal_CiudadId ON FLORERIA_Sucursal(ciudad_id);
CREATE NONCLUSTERED INDEX IX_Sucursal_Activo ON FLORERIA_Sucursal(activo);

-- Tabla FLORERIA_Zona
CREATE NONCLUSTERED INDEX IX_Zona_CiudadId ON FLORERIA_Zona(ciudad_id);
CREATE NONCLUSTERED INDEX IX_Zona_Activo ON FLORERIA_Zona(activo);

-- Tabla FLORERIA_Zona_Tarifa
CREATE NONCLUSTERED INDEX IX_Zona_Tarifa_ZonaId ON FLORERIA_Zona_Tarifa(zona_id);
CREATE NONCLUSTERED INDEX IX_Zona_Tarifa_Vigencia ON FLORERIA_Zona_Tarifa(vigente_desde, vigente_hasta);

-- Tabla FLORERIA_Slot_Horario
CREATE NONCLUSTERED INDEX IX_Slot_Activo ON FLORERIA_Slot_Horario(activo);

-- =============================================
-- ÍNDICES: MÓDULO CATÁLOGO (15 índices)
-- =============================================

-- Tabla FLORERIA_Categoria
CREATE NONCLUSTERED INDEX IX_Categoria_PadreId ON FLORERIA_Categoria(padre_id);
CREATE NONCLUSTERED INDEX IX_Categoria_Activo ON FLORERIA_Categoria(activo);
CREATE NONCLUSTERED INDEX IX_Categoria_WcSyncEstado ON FLORERIA_Categoria(wc_sync_estado);

-- Tabla FLORERIA_Producto
CREATE NONCLUSTERED INDEX IX_Producto_CategoriaId ON FLORERIA_Producto(categoria_id);
CREATE NONCLUSTERED INDEX IX_Producto_Activo ON FLORERIA_Producto(activo);
CREATE NONCLUSTERED INDEX IX_Producto_WcSyncEstado ON FLORERIA_Producto(wc_sync_estado);
CREATE NONCLUSTERED INDEX IX_Producto_PromoVigente ON FLORERIA_Producto(promo_desde, promo_hasta);

-- Tabla FLORERIA_Producto_Categoria
CREATE NONCLUSTERED INDEX IX_Producto_Categoria_CategoriaId ON FLORERIA_Producto_Categoria(categoria_id);

-- Tabla FLORERIA_Producto_Variacion
CREATE NONCLUSTERED INDEX IX_Producto_Variacion_ProductoId ON FLORERIA_Producto_Variacion(producto_id);
CREATE NONCLUSTERED INDEX IX_Producto_Variacion_Activo ON FLORERIA_Producto_Variacion(activo);

-- Tabla FLORERIA_Producto_Imagen
CREATE NONCLUSTERED INDEX IX_Producto_Imagen_ProductoId ON FLORERIA_Producto_Imagen(producto_id);

-- Tabla FLORERIA_Stock_Movimiento
CREATE NONCLUSTERED INDEX IX_Stock_ProductoId ON FLORERIA_Stock_Movimiento(producto_id);
CREATE NONCLUSTERED INDEX IX_Stock_FechaHora ON FLORERIA_Stock_Movimiento(fecha_hora);

-- =============================================
-- ÍNDICES: MÓDULO PRE-PEDIDOS Y PEDIDOS (10 índices)
-- =============================================

-- Tabla FLORERIA_PrePedido
CREATE NONCLUSTERED INDEX IX_PrePedido_AgenteId ON FLORERIA_PrePedido(agente_actual_id);
CREATE NONCLUSTERED INDEX IX_PrePedido_Estado ON FLORERIA_PrePedido(estado);
CREATE NONCLUSTERED INDEX IX_PrePedido_ClienteCelular ON FLORERIA_PrePedido(cliente_celular);
CREATE NONCLUSTERED INDEX IX_PrePedido_TokenWeb ON FLORERIA_PrePedido(token_web);

-- Tabla FLORERIA_Pedido
CREATE NONCLUSTERED INDEX IX_Pedido_PrePedidoId ON FLORERIA_Pedido(prepedido_id);
CREATE NONCLUSTERED INDEX IX_Pedido_FechaEntrega ON FLORERIA_Pedido(fecha_entrega);
CREATE NONCLUSTERED INDEX IX_Pedido_ZonaId ON FLORERIA_Pedido(zona_id);
CREATE NONCLUSTERED INDEX IX_Pedido_EstadoPago ON FLORERIA_Pedido(estado_pago);

-- Tabla FLORERIA_Pedido_Detalle
CREATE NONCLUSTERED INDEX IX_Pedido_Detalle_ProductoId ON FLORERIA_Pedido_Detalle(producto_id);

-- Tabla FLORERIA_Pedido_Pago
CREATE NONCLUSTERED INDEX IX_Pedido_Pago_PrePedidoId ON FLORERIA_Pedido_Pago(prepedido_id);

GO

-- =============================================
-- FIN DE CREACIÓN DE ÍNDICES
-- =============================================