-- =============================================
-- STORED PROCEDURES PARA DASHBOARD
-- Fecha: 23 Mayo 2026
-- =============================================

USE SISCONBOL
GO

-- =============================================
-- SP 1: FLORERIA_sp_Dashboard_Estadisticas
-- Propósito: Obtener todas las estadísticas del dashboard
-- =============================================

IF OBJECT_ID('FLORERIA_sp_Dashboard_Estadisticas', 'P') IS NOT NULL
    DROP PROCEDURE FLORERIA_sp_Dashboard_Estadisticas
GO

CREATE PROCEDURE FLORERIA_sp_Dashboard_Estadisticas
    @usuario_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @hoy DATE = CAST(GETDATE() AS DATE)
    DECLARE @ayer DATE = DATEADD(DAY, -1, @hoy)
    DECLARE @manana DATE = DATEADD(DAY, 1, @hoy)
    DECLARE @en_48h DATETIME = DATEADD(HOUR, 48, GETDATE())
    
    SELECT
        -- Pre-Pedidos
        (SELECT COUNT(*) 
         FROM FLORERIA_PrePedido 
         WHERE estado NOT IN ('COMPLETADO', 'CANCELADO', 'EXPIRADO')
           AND agente_actual_id = @usuario_id) AS total_prepedidos,
        
        (SELECT COUNT(*) 
         FROM FLORERIA_PrePedido 
         WHERE CAST(creado_en AS DATE) = @hoy
           AND agente_actual_id = @usuario_id) AS prepedidos_hoy,
        
        -- Ventas Hoy
        (SELECT ISNULL(SUM(total_general_bs), 0)
         FROM FLORERIA_PrePedido
         WHERE estado = 'PAGADO'
           AND CAST(creado_en AS DATE) = @hoy
           AND agente_actual_id = @usuario_id) AS ventas_hoy_bs,
        
        -- Ventas Ayer (para comparación)
        (SELECT ISNULL(SUM(total_general_bs), 0)
         FROM FLORERIA_PrePedido
         WHERE estado = 'PAGADO'
           AND CAST(creado_en AS DATE) = @ayer
           AND agente_actual_id = @usuario_id) AS ventas_ayer_bs,
        
        -- Por Entregar Mañana
        (SELECT COUNT(DISTINCT p.pedido_id)
         FROM FLORERIA_Pedido p
         INNER JOIN FLORERIA_PrePedido pp ON p.prepedido_id = pp.prepedido_id
         WHERE p.fecha_entrega = @manana
           AND pp.estado IN ('PAGADO', 'WC_CREADO')
           AND pp.agente_actual_id = @usuario_id) AS por_entregar_manana,
        
        -- Pendientes de Pago
        (SELECT COUNT(*)
         FROM FLORERIA_PrePedido
         WHERE estado IN ('COMPROBANTE_ENVIADO')
           AND agente_actual_id = @usuario_id) AS pendientes_pago,
        
        -- Por Vencer en 48 horas
        (SELECT COUNT(*)
         FROM FLORERIA_PrePedido
         WHERE estado IN ('FORM_ENVIADO', 'FORM_COMPLETADO')
           AND token_expira <= @en_48h
           AND token_expira > GETDATE()
           AND agente_actual_id = @usuario_id) AS por_vencer_48h
        
END
GO

-- =============================================
-- SP 2: FLORERIA_sp_PrePedido_ListarRecientes
-- Propósito: Obtener los últimos N pre-pedidos del usuario
-- =============================================

IF OBJECT_ID('FLORERIA_sp_PrePedido_ListarRecientes', 'P') IS NOT NULL
    DROP PROCEDURE FLORERIA_sp_PrePedido_ListarRecientes
GO

CREATE PROCEDURE FLORERIA_sp_PrePedido_ListarRecientes
    @usuario_id  INT,
    @cantidad    INT = 5
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP (@cantidad)
        pp.prepedido_id,
        pp.codigo,
        pp.tipo_registro,
        pp.cliente_celular,
        pp.cliente_nombre,
        pp.cliente_apellidos,
        pp.estado,
        pp.total_general_bs,
        pp.total_general_usd,
        pp.creado_en,
        u.nombres + ' ' + u.apellidos AS agente_nombre
    FROM FLORERIA_PrePedido pp
    LEFT JOIN FLORERIA_Usuario u ON pp.agente_actual_id = u.usuario_id
    WHERE pp.agente_actual_id = @usuario_id
    ORDER BY pp.prepedido_id DESC
    
END
GO

-- =============================================
-- VERIFICACIÓN
-- =============================================

PRINT '✓ FLORERIA_sp_Dashboard_Estadisticas creado correctamente'
PRINT '✓ FLORERIA_sp_PrePedido_ListarRecientes creado correctamente'
PRINT ''
PRINT 'Ejecutar estos SPs para probar:'
PRINT 'EXEC FLORERIA_sp_Dashboard_Estadisticas @usuario_id = 1'
PRINT 'EXEC FLORERIA_sp_PrePedido_ListarRecientes @usuario_id = 1, @cantidad = 5'
GO
