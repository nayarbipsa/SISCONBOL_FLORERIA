-- =============================================
-- SISCONBOL_FLORERIA - TODOS LOS STORED PROCEDURES
-- Total SPs: 48
-- =============================================
 USE [SISCONBOL]
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Asignacion_Crear]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_Asignacion_Crear]
    @pedido_id      INT,
    @delivery_id    INT,
    @asignado_por   INT,
    @observaciones  NVARCHAR(500) = NULL,
    @ip             VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar pedido
    IF NOT EXISTS (SELECT 1 FROM FLORERIA_Pedido WHERE pedido_id = @pedido_id)
    BEGIN
        SELECT 0 AS ok, 'Pedido no encontrado.' AS mensaje;
        RETURN;
    END
    
    -- Validar que el delivery es un usuario tipo DELIVERY (tipo_id = 4)
    IF NOT EXISTS (SELECT 1 FROM FLORERIA_Usuario 
                   WHERE usuario_id = @delivery_id 
                     AND tipo_id = 4 
                     AND activo = 1)
    BEGIN
        SELECT 0 AS ok, 'Usuario delivery invalido o inactivo.' AS mensaje;
        RETURN;
    END
    
    BEGIN TRANSACTION;
    
    -- 1. Liberar asignaciones activas anteriores del mismo pedido
    UPDATE FLORERIA_Asignacion
    SET activa = 0,
        liberado_en = GETDATE(),
        liberado_por = @asignado_por,
        motivo_liberacion = 'Reasignacion a otro delivery'
    WHERE pedido_id = @pedido_id AND activa = 1;
    
    -- 2. Crear nueva asignacion
    INSERT INTO FLORERIA_Asignacion
        (pedido_id, delivery_id, asignado_por, asignado_en, activa, observaciones)
    VALUES
        (@pedido_id, @delivery_id, @asignado_por, GETDATE(), 1, @observaciones);
    
    DECLARE @asignacion_id INT = SCOPE_IDENTITY();
    
    -- 3. Actualizar delivery_actual_id en el pedido (denormalizado)
    UPDATE FLORERIA_Pedido
    SET delivery_actual_id = @delivery_id,
        modificado_por = @asignado_por,
        modificado_en = GETDATE()
    WHERE pedido_id = @pedido_id;
    
    -- 4. Log de estado
    DECLARE @delivery_nombre VARCHAR(400);
    SELECT @delivery_nombre = nombres + ' ' + apellidos 
    FROM FLORERIA_Usuario WHERE usuario_id = @delivery_id;
    
    INSERT INTO FLORERIA_Pedido_Estado_Log
        (pedido_id, estado_anterior, estado_nuevo, observaciones, usuario_id, fecha_hora)
    VALUES
        (@pedido_id, NULL, 'DELIVERY_ASIGNADO', 
         'Asignado a ' + @delivery_nombre, @asignado_por, GETDATE());
    
    -- 5. Auditoria
    INSERT INTO FLORERIA_Auditoria
        (usuario_id, ip, tabla, registro_id, accion, valor_nuevo, motivo)
    VALUES
        (@asignado_por, @ip, 'FLORERIA_Asignacion', CAST(@asignacion_id AS VARCHAR),
         'INSERTAR',
         '{"pedido_id":"' + CAST(@pedido_id AS VARCHAR) + 
         '","delivery_id":"' + CAST(@delivery_id AS VARCHAR) + '"}',
         'Asignacion de delivery a pedido');
    
    COMMIT TRANSACTION;
    
    SELECT 1 AS ok, 'Delivery asignado correctamente.' AS mensaje, @asignacion_id AS asignacion_id;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Asignacion_ListarDeliverysActivos]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_Asignacion_ListarDeliverysActivos]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT
        u.usuario_id,
        u.nombres,
        u.apellidos,
        u.nombres + ' ' + u.apellidos AS nombre_completo,
        u.celular,
        -- Cantidad de pedidos asignados activos hoy
        (SELECT COUNT(*) 
         FROM FLORERIA_Asignacion a
         INNER JOIN FLORERIA_Pedido p ON a.pedido_id = p.pedido_id
         WHERE a.delivery_id = u.usuario_id
           AND a.activa = 1
           AND p.fecha_entrega = CAST(GETDATE() AS DATE)
           AND p.estado_operativo NOT IN ('ENTREGADO', 'NO_ENTREGADO')
        ) AS pedidos_activos_hoy
    FROM FLORERIA_Usuario u
    WHERE u.tipo_id = 4
      AND u.activo = 1
      AND u.bloqueado = 0
    ORDER BY u.nombres ASC;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_CambiarPassword]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ────────────────────────────────────────
CREATE   PROCEDURE [dbo].[FLORERIA_sp_CambiarPassword]
    @usuario_id      INT,
    @pwd_actual_hash VARCHAR(200),
    @pwd_nueva_hash  VARCHAR(200),
    @pwd_nueva_salt  VARCHAR(50),
    @ip              VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @hash_bd VARCHAR(200);
    SELECT @hash_bd = password_hash FROM FLORERIA_Usuario WHERE usuario_id = @usuario_id;

    IF @hash_bd != @pwd_actual_hash
    BEGIN
        SELECT 0 AS ok, 'La contraseña actual es incorrecta.' AS mensaje;
        RETURN;
    END;

    UPDATE FLORERIA_Usuario SET
        password_hash    = @pwd_nueva_hash,
        password_salt    = @pwd_nueva_salt,
        debe_cambiar_pwd = 0,
        modificado_en    = GETDATE(),
        modificado_por   = @usuario_id
    WHERE usuario_id = @usuario_id;

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, ip, tabla, registro_id, accion, valor_nuevo)
    VALUES
        (@usuario_id, @ip, 'FLORERIA_Usuario',
         CAST(@usuario_id AS VARCHAR), 'MODIFICAR',
         '{"campo":"password","detalle":"Contrasena cambiada"}');

    SELECT 1 AS ok, 'Contraseña actualizada correctamente.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_CargarMenu]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_CargarMenu]
    @usuario_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        m.menu_id,
        m.padre_id,
        m.nombre,
        m.icono,
        m.ruta,
        m.orden,
        CASE
            WHEN um.tipo_excepcion = 'QUITAR' THEN 0
            WHEN um.tipo_excepcion = 'AGREGAR' THEN 1
            ELSE ISNULL(tm.puede_ver, 0)
        END AS puede_ver,
        CASE
            WHEN um.tipo_excepcion = 'QUITAR' THEN 0
            WHEN um.tipo_excepcion = 'AGREGAR' THEN um.puede_crear
            ELSE ISNULL(tm.puede_crear, 0)
        END AS puede_crear,
        CASE
            WHEN um.tipo_excepcion = 'QUITAR' THEN 0
            WHEN um.tipo_excepcion = 'AGREGAR' THEN um.puede_editar
            ELSE ISNULL(tm.puede_editar, 0)
        END AS puede_editar,
        CASE
            WHEN um.tipo_excepcion = 'QUITAR' THEN 0
            WHEN um.tipo_excepcion = 'AGREGAR' THEN um.puede_eliminar
            ELSE ISNULL(tm.puede_eliminar, 0)
        END AS puede_eliminar,
        CASE
            WHEN EXISTS(SELECT 1 FROM FLORERIA_Menu hijos WHERE hijos.padre_id = m.menu_id AND hijos.activo = 1) THEN 1
            ELSE 0
        END AS tiene_hijos
    FROM FLORERIA_Menu m
    JOIN FLORERIA_Usuario u ON u.usuario_id = @usuario_id
    LEFT JOIN FLORERIA_TipoUsuario_Menu tm
           ON tm.menu_id = m.menu_id AND tm.tipo_id = u.tipo_id
    LEFT JOIN FLORERIA_Usuario_Menu um
           ON um.menu_id = m.menu_id AND um.usuario_id = @usuario_id
    WHERE m.activo = 1
      AND (
            um.tipo_excepcion = 'AGREGAR'
            OR (um.tipo_excepcion IS NULL AND ISNULL(tm.puede_ver, 0) = 1)
          )
    ORDER BY m.padre_id, m.orden;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_Actualizar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP: Actualizar categoría
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_Actualizar]
    @categoria_id   INT,
    @padre_id       INT,
    @nombre         VARCHAR(150),
    @descripcion    VARCHAR(500),
    @slug           VARCHAR(160),
    @modificado_por INT,
    @motivo         VARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    -- No puede ser su propio padre
    IF @padre_id = @categoria_id
    BEGIN
        SELECT 0 AS ok, 'Una categoria no puede ser padre de si misma.' AS mensaje;
        RETURN;
    END;

    -- Validar nombre duplicado en mismo nivel (excepto ella misma)
    IF EXISTS (
        SELECT 1 FROM FLORERIA_Categoria
        WHERE nombre = @nombre
          AND (padre_id = @padre_id OR (padre_id IS NULL AND @padre_id IS NULL))
          AND categoria_id <> @categoria_id
    )
    BEGIN
        SELECT 0 AS ok, 'Ya existe una categoria con ese nombre en este nivel.' AS mensaje;
        RETURN;
    END;

    -- Validar slug único (excepto ella misma)
    IF @slug IS NOT NULL AND @slug <> ''
    BEGIN
        IF EXISTS (SELECT 1 FROM FLORERIA_Categoria WHERE slug = @slug AND categoria_id <> @categoria_id)
        BEGIN
            SELECT 0 AS ok, 'El slug ya esta en uso por otra categoria.' AS mensaje;
            RETURN;
        END;
    END;

    -- Guardar valor anterior para auditoría
    DECLARE @anterior NVARCHAR(MAX);
    SELECT @anterior = '{"nombre":"' + nombre + '","padre_id":"' + ISNULL(CAST(padre_id AS VARCHAR),'null') + '"}'
    FROM FLORERIA_Categoria WHERE categoria_id = @categoria_id;

    UPDATE FLORERIA_Categoria SET
        padre_id       = @padre_id,
        nombre         = @nombre,
        descripcion    = NULLIF(@descripcion, ''),
        slug           = NULLIF(@slug, ''),
        wc_sync_estado = 'PENDIENTE',
        modificado_por = @modificado_por,
        modificado_en  = GETDATE()
    WHERE categoria_id = @categoria_id;

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_anterior, valor_nuevo, motivo)
    VALUES
        (@modificado_por, 'FLORERIA_Categoria', CAST(@categoria_id AS VARCHAR),
         'MODIFICAR', @anterior,
         '{"nombre":"' + @nombre + '","padre_id":"' + ISNULL(CAST(@padre_id AS VARCHAR),'null') + '"}',
         @motivo);

    SELECT 1 AS ok, 'Categoria actualizada correctamente.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_AgregarProductos]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ══════════════════════════════════════════════════════════════════════════════
-- SP: Agregar productos a una categoría
-- ══════════════════════════════════════════════════════════════════════════════
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_AgregarProductos]
    @categoria_id     INT,
    @productos_ids    VARCHAR(MAX),
    @producto_principal_id INT = NULL,
    @usuario_id       INT
AS BEGIN
    SET NOCOUNT ON;
    
    DECLARE @producto_id INT;
    DECLARE @pos INT;
    DECLARE @ids VARCHAR(MAX) = @productos_ids + ',';
    DECLARE @agregados INT = 0;
    DECLARE @duplicados INT = 0;
    
    -- Validar que la categoría existe
    IF NOT EXISTS (SELECT 1 FROM FLORERIA_Categoria WHERE categoria_id = @categoria_id AND activo = 1)
    BEGIN
        SELECT 0 AS ok, 'Categoria no existe o esta inactiva' AS mensaje;
        RETURN;
    END;
    
    -- Procesar cada ID
    WHILE LEN(@ids) > 0
    BEGIN
        SET @pos = CHARINDEX(',', @ids);
        IF @pos > 1
        BEGIN
            SET @producto_id = CAST(LEFT(@ids, @pos - 1) AS INT);
            
            -- Verificar si ya existe
            IF NOT EXISTS (
                SELECT 1 FROM FLORERIA_Producto_Categoria 
                WHERE producto_id = @producto_id 
                  AND categoria_id = @categoria_id
            )
            BEGIN
                -- Determinar si es principal
                DECLARE @es_principal BIT = 0;
                IF @producto_principal_id IS NOT NULL AND @producto_id = @producto_principal_id
                BEGIN
                    SET @es_principal = 1;
                    
                    -- Quitar el principal actual
                    UPDATE FLORERIA_Producto_Categoria
                    SET es_principal = 0
                    WHERE categoria_id = @categoria_id AND es_principal = 1;
                END;
                
                -- Insertar
                INSERT INTO FLORERIA_Producto_Categoria 
                    (producto_id, categoria_id, es_principal, creado_por, creado_en)
                VALUES 
                    (@producto_id, @categoria_id, @es_principal, @usuario_id, GETDATE());
                    
                SET @agregados = @agregados + 1;
            END
            ELSE
            BEGIN
                SET @duplicados = @duplicados + 1;
            END;
        END;
        
        SET @ids = RIGHT(@ids, LEN(@ids) - @pos);
    END;
    
    -- Auditar
    INSERT INTO FLORERIA_Auditoria 
        (usuario_id, tabla, registro_id, accion, valor_nuevo, fecha_hora)
    VALUES 
        (@usuario_id, 'FLORERIA_Producto_Categoria', CAST(@categoria_id AS VARCHAR(50)), 
         'INSERTAR', 'Agregados: ' + CAST(@agregados AS VARCHAR) + ', Duplicados: ' + CAST(@duplicados AS VARCHAR),
         GETDATE());
    
    SELECT 
        1 AS ok, 
        'Se agregaron ' + CAST(@agregados AS VARCHAR) + ' producto(s)' + 
        CASE WHEN @duplicados > 0 THEN ' (' + CAST(@duplicados AS VARCHAR) + ' ya existian)' ELSE '' END AS mensaje,
        @agregados AS agregados,
        @duplicados AS duplicados;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_BajaProductos]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP: Dar de baja masiva de productos de una categoría
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_BajaProductos]
    @categoria_id   INT,
    @modificado_por INT,
    @motivo         VARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    IF @motivo IS NULL OR LEN(LTRIM(RTRIM(@motivo))) < 5
    BEGIN
        SELECT 0 AS ok, 'El motivo es obligatorio (min. 5 caracteres).' AS mensaje, 0 AS total_afectados;
        RETURN;
    END;

    DECLARE @total INT;

    -- Contar productos activos en esta categoría
    SELECT @total = COUNT(*)
    FROM FLORERIA_Producto_Categoria pc
    JOIN FLORERIA_Producto p ON pc.producto_id = p.producto_id
    WHERE pc.categoria_id = @categoria_id AND p.activo = 1;

    -- Dar de baja
    UPDATE FLORERIA_Producto SET
        activo         = 0,
        wc_sync_estado = 'PENDIENTE',
        modificado_por = @modificado_por,
        modificado_en  = GETDATE()
    WHERE producto_id IN (
        SELECT pc.producto_id
        FROM FLORERIA_Producto_Categoria pc
        WHERE pc.categoria_id = @categoria_id
    ) AND activo = 1;

    -- Auditoría por cada producto dado de baja
    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_nuevo, motivo)
    SELECT
        @modificado_por, 'FLORERIA_Producto',
        CAST(pc.producto_id AS VARCHAR),
        'MODIFICAR',
        '{"activo":"0","origen":"baja_masiva_categoria","categoria_id":"' + CAST(@categoria_id AS VARCHAR) + '"}',
        @motivo
    FROM FLORERIA_Producto_Categoria pc
    JOIN FLORERIA_Producto p ON pc.producto_id = p.producto_id
    WHERE pc.categoria_id = @categoria_id;

    SELECT 1 AS ok,
           CAST(@total AS VARCHAR) + ' productos dados de baja correctamente.' AS mensaje,
           @total AS total_afectados;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_CambiarOrden]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP: Cambiar orden (drag & drop)
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_CambiarOrden]
    @categoria_id   INT,
    @nuevo_padre_id INT,
    @nuevo_orden    INT,
    @modificado_por INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Guardar anterior para auditoría
    DECLARE @anterior NVARCHAR(MAX);
    SELECT @anterior = '{"padre_id":"' + ISNULL(CAST(padre_id AS VARCHAR),'null') + '","orden":"' + CAST(orden AS VARCHAR) + '"}'
    FROM FLORERIA_Categoria WHERE categoria_id = @categoria_id;

    -- Reordenar hermanos del nuevo nivel
    UPDATE FLORERIA_Categoria SET
        orden = orden + 1
    WHERE (padre_id = @nuevo_padre_id OR (padre_id IS NULL AND @nuevo_padre_id IS NULL))
      AND orden >= @nuevo_orden
      AND categoria_id <> @categoria_id;

    -- Mover la categoría
    UPDATE FLORERIA_Categoria SET
        padre_id       = @nuevo_padre_id,
        orden          = @nuevo_orden,
        wc_sync_estado = 'PENDIENTE',
        modificado_por = @modificado_por,
        modificado_en  = GETDATE()
    WHERE categoria_id = @categoria_id;

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_anterior, valor_nuevo, motivo)
    VALUES
        (@modificado_por, 'FLORERIA_Categoria', CAST(@categoria_id AS VARCHAR),
         'MODIFICAR', @anterior,
         '{"nuevo_padre_id":"' + ISNULL(CAST(@nuevo_padre_id AS VARCHAR),'null') + '","nuevo_orden":"' + CAST(@nuevo_orden AS VARCHAR) + '"}',
         'Reordenamiento drag and drop');

    SELECT 1 AS ok, 'Orden actualizado.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_Crear]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP: Crear categoría
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_Crear]
    @padre_id       INT,
    @nombre         VARCHAR(150),
    @descripcion    VARCHAR(500),
    @slug           VARCHAR(160),
    @creado_por     INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar nombre duplicado en el mismo nivel
    IF EXISTS (
        SELECT 1 FROM FLORERIA_Categoria
        WHERE nombre = @nombre
          AND (padre_id = @padre_id OR (padre_id IS NULL AND @padre_id IS NULL))
    )
    BEGIN
        SELECT 0 AS ok, 'Ya existe una categoria con ese nombre en este nivel.' AS mensaje, NULL AS categoria_id;
        RETURN;
    END;

    -- Validar slug único
    IF @slug IS NOT NULL AND @slug <> ''
    BEGIN
        IF EXISTS (SELECT 1 FROM FLORERIA_Categoria WHERE slug = @slug)
        BEGIN
            SELECT 0 AS ok, 'El slug ya esta en uso por otra categoria.' AS mensaje, NULL AS categoria_id;
            RETURN;
        END;
    END;

    -- Calcular orden (último del nivel)
    DECLARE @orden INT;
    SELECT @orden = ISNULL(MAX(orden), 0) + 1
    FROM FLORERIA_Categoria
    WHERE (padre_id = @padre_id OR (padre_id IS NULL AND @padre_id IS NULL));

    INSERT INTO FLORERIA_Categoria
        (padre_id, nombre, descripcion, slug, orden, wc_sync_estado, creado_por)
    VALUES
        (@padre_id, @nombre, NULLIF(@descripcion,''), NULLIF(@slug,''),
         @orden, 'PENDIENTE', @creado_por);

    DECLARE @nueva_id INT = SCOPE_IDENTITY();

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_nuevo, motivo)
    VALUES
        (@creado_por, 'FLORERIA_Categoria', CAST(@nueva_id AS VARCHAR),
         'INSERTAR',
         '{"nombre":"' + @nombre + '","padre_id":"' + ISNULL(CAST(@padre_id AS VARCHAR),'null') + '"}',
         'Creacion de categoria');

    SELECT 1 AS ok, 'Categoria creada correctamente.' AS mensaje, @nueva_id AS categoria_id;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_Eliminar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP: Eliminar categoría (solo si no tiene productos ni hijos)
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_Eliminar]
    @categoria_id   INT,
    @modificado_por INT,
    @motivo         VARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    IF @motivo IS NULL OR LEN(LTRIM(RTRIM(@motivo))) < 5
    BEGIN
        SELECT 0 AS ok, 'El motivo es obligatorio (min. 5 caracteres).' AS mensaje;
        RETURN;
    END;

    -- Verificar que no tenga hijos
    IF EXISTS (SELECT 1 FROM FLORERIA_Categoria WHERE padre_id = @categoria_id)
    BEGIN
        SELECT 0 AS ok, 'No se puede eliminar una categoria que tiene subcategorias.' AS mensaje;
        RETURN;
    END;

    -- Verificar que no tenga productos
    IF EXISTS (SELECT 1 FROM FLORERIA_Producto_Categoria WHERE categoria_id = @categoria_id)
    BEGIN
        SELECT 0 AS ok, 'No se puede eliminar una categoria que tiene productos asignados.' AS mensaje;
        RETURN;
    END;

    -- Guardar para auditoría
    DECLARE @anterior NVARCHAR(MAX);
    SELECT @anterior = '{"nombre":"' + nombre + '","activo":"' + CAST(activo AS VARCHAR) + '"}'
    FROM FLORERIA_Categoria WHERE categoria_id = @categoria_id;

    DELETE FROM FLORERIA_Categoria WHERE categoria_id = @categoria_id;

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_anterior, motivo)
    VALUES
        (@modificado_por, 'FLORERIA_Categoria', CAST(@categoria_id AS VARCHAR),
         'ELIMINAR', @anterior, @motivo);

    SELECT 1 AS ok, 'Categoria eliminada correctamente.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_GuardarWcId]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_GuardarWcId]
    @categoria_id   INT,
    @wc_category_id INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE FLORERIA_Categoria SET
        wc_category_id = @wc_category_id,
        wc_sync_estado = 'SINCRONIZADO',
        wc_sync_fecha  = GETDATE()
    WHERE categoria_id = @categoria_id;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_HabilitarProductos]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_HabilitarProductos]
    @categoria_id   INT,
    @modificado_por INT,
    @motivo         VARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    IF @motivo IS NULL OR LEN(LTRIM(RTRIM(@motivo))) < 5
    BEGIN
        SELECT 0 AS ok, 'El motivo es obligatorio (min. 5 caracteres).' AS mensaje, 0 AS total_afectados;
        RETURN;
    END;

    DECLARE @total INT;
    SELECT @total = COUNT(*)
    FROM FLORERIA_Producto_Categoria pc
    JOIN FLORERIA_Producto p ON pc.producto_id = p.producto_id
    WHERE pc.categoria_id = @categoria_id AND p.activo = 0;

    UPDATE FLORERIA_Producto SET
        activo         = 1,
        wc_sync_estado = 'PENDIENTE',
        modificado_por = @modificado_por,
        modificado_en  = GETDATE()
    WHERE producto_id IN (
        SELECT pc.producto_id FROM FLORERIA_Producto_Categoria pc
        WHERE pc.categoria_id = @categoria_id
    ) AND activo = 0;

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_nuevo, motivo)
    SELECT
        @modificado_por, 'FLORERIA_Producto',
        CAST(pc.producto_id AS VARCHAR),
        'MODIFICAR',
        '{"activo":"1","origen":"habilitacion_masiva_categoria","categoria_id":"' + CAST(@categoria_id AS VARCHAR) + '"}',
        @motivo
    FROM FLORERIA_Producto_Categoria pc
    JOIN FLORERIA_Producto p ON pc.producto_id = p.producto_id
    WHERE pc.categoria_id = @categoria_id;

    SELECT 1 AS ok,
           CAST(@total AS VARCHAR) + ' productos habilitados correctamente.' AS mensaje,
           @total AS total_afectados;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_Listar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

-- SP: Listar categorías en árbol
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_Listar]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        c.categoria_id,
        c.padre_id,
        c.nombre,
        c.descripcion,
        c.slug,
        c.orden,
        c.activo,
        c.wc_category_id,
        c.wc_sync_estado,
        c.wc_sync_fecha,
        c.creado_en,
        c.modificado_en,
        u1.nombres + ' ' + u1.apellidos  AS creado_por_nombre,
        u2.nombres + ' ' + u2.apellidos  AS modificado_por_nombre,
        -- Cuántos productos tiene esta categoría
        (SELECT COUNT(*) FROM FLORERIA_Producto_Categoria pc
         WHERE pc.categoria_id = c.categoria_id) AS total_productos
    FROM FLORERIA_Categoria c
    LEFT JOIN FLORERIA_Usuario u1 ON c.creado_por    = u1.usuario_id
    LEFT JOIN FLORERIA_Usuario u2 ON c.modificado_por = u2.usuario_id
    ORDER BY c.padre_id, c.orden, c.nombre;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_ListarProductos]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ══════════════════════════════════════════════════════════════════════════════
-- SP: Listar productos de una categoría específica
-- ══════════════════════════════════════════════════════════════════════════════
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_ListarProductos]
    @categoria_id INT,
    @buscar       VARCHAR(200) = NULL,
    @estado       VARCHAR(20)  = NULL,
    @sync_estado  VARCHAR(20)  = NULL,
    @stock_estado VARCHAR(20)  = NULL
AS BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        p.producto_id,
        p.sku,
        p.nombre,
        p.descripcion,
        p.precio_base_bs,
        p.precio_base_usd,
        p.precio_promo_bs,
        p.precio_promo_usd,
        p.promo_desde,
        p.promo_hasta,
        p.stock_actual,
        p.stock_minimo,
        p.tiene_variaciones,
        p.wc_product_id,
        p.wc_sync_estado,
        p.activo,
        p.imagen_url,
        pc.es_principal,
        
        -- Estado de stock calculado
        CASE 
            WHEN p.stock_actual = 0 THEN 'agotado'
            WHEN p.stock_actual <= p.stock_minimo THEN 'bajo'
            ELSE 'normal'
        END AS stock_estado,
        
        -- Promoción activa HOY
        CASE
            WHEN p.precio_promo_bs IS NOT NULL
             AND p.promo_desde <= CAST(GETDATE() AS DATE)
             AND (p.promo_hasta IS NULL OR p.promo_hasta >= CAST(GETDATE() AS DATE))
            THEN 1 
            ELSE 0
        END AS tiene_promo_activa,
        
        -- Total de categorías del producto
        (SELECT COUNT(*) 
         FROM FLORERIA_Producto_Categoria pc2 
         WHERE pc2.producto_id = p.producto_id) AS total_categorias,
         
        -- Nombres de otras categorías (primeras 3)
        STUFF((
            SELECT TOP 3 ', ' + c2.nombre
            FROM FLORERIA_Producto_Categoria pc3
            INNER JOIN FLORERIA_Categoria c2 ON pc3.categoria_id = c2.categoria_id
            WHERE pc3.producto_id = p.producto_id 
              AND pc3.categoria_id <> @categoria_id
              AND c2.activo = 1
            FOR XML PATH('')
        ), 1, 2, '') AS otras_categorias
        
    FROM FLORERIA_Producto p
    INNER JOIN FLORERIA_Producto_Categoria pc ON p.producto_id = pc.producto_id
    WHERE pc.categoria_id = @categoria_id
      AND (@buscar IS NULL OR 
           p.nombre LIKE '%' + @buscar + '%' OR 
           p.sku LIKE '%' + @buscar + '%')
      AND (@estado IS NULL OR 
           (@estado = 'activo' AND p.activo = 1) OR
           (@estado = 'inactivo' AND p.activo = 0))
      AND (@sync_estado IS NULL OR p.wc_sync_estado = @sync_estado)
      AND (@stock_estado IS NULL OR
           (@stock_estado = 'disponible' AND p.stock_actual > p.stock_minimo) OR
           (@stock_estado = 'bajo' AND p.stock_actual > 0 AND p.stock_actual <= p.stock_minimo) OR
           (@stock_estado = 'agotado' AND p.stock_actual = 0))
    ORDER BY 
        CASE WHEN pc.es_principal = 1 THEN 0 ELSE 1 END,
        p.nombre;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_MarcarPrincipal]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ══════════════════════════════════════════════════════════════════════════════
-- SP: Marcar un producto como principal de una categoría
-- ══════════════════════════════════════════════════════════════════════════════
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_MarcarPrincipal]
    @categoria_id INT,
    @producto_id  INT,
    @usuario_id   INT
AS BEGIN
    SET NOCOUNT ON;
    
    -- Validar que existe la relación
    IF NOT EXISTS (
        SELECT 1 FROM FLORERIA_Producto_Categoria 
        WHERE producto_id = @producto_id AND categoria_id = @categoria_id
    )
    BEGIN
        SELECT 0 AS ok, 'El producto no pertenece a esta categoria' AS mensaje;
        RETURN;
    END;
    
    -- Quitar el principal actual
    UPDATE FLORERIA_Producto_Categoria
    SET es_principal = 0
    WHERE categoria_id = @categoria_id AND es_principal = 1;
    
    -- Marcar el nuevo principal
    UPDATE FLORERIA_Producto_Categoria
    SET es_principal = 1
    WHERE producto_id = @producto_id AND categoria_id = @categoria_id;
    
    -- Auditar
    INSERT INTO FLORERIA_Auditoria 
        (usuario_id, tabla, registro_id, accion, valor_nuevo, fecha_hora)
    VALUES 
        (@usuario_id, 'FLORERIA_Producto_Categoria', 
         CAST(@producto_id AS VARCHAR) + '-' + CAST(@categoria_id AS VARCHAR),
         'MODIFICAR', 'Marcado como principal', GETDATE());
    
    SELECT 1 AS ok, 'Producto marcado como principal' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_MarcarSincronizada]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_MarcarSincronizada]
    @categoria_id INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE FLORERIA_Categoria SET
        wc_sync_estado = 'SINCRONIZADO',
        wc_sync_fecha  = GETDATE()
    WHERE categoria_id = @categoria_id;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_ObtenerStats]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ══════════════════════════════════════════════════════════════════════════════
-- SP: Obtener stats de productos de una categoría
-- ══════════════════════════════════════════════════════════════════════════════
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_ObtenerStats]
    @categoria_id INT
AS BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        COUNT(*) AS total_productos,
        SUM(CASE WHEN p.activo = 1 THEN 1 ELSE 0 END) AS total_activos,
        SUM(CASE WHEN p.stock_actual > 0 THEN 1 ELSE 0 END) AS total_con_stock,
        SUM(CASE WHEN p.wc_sync_estado = 'PENDIENTE' THEN 1 ELSE 0 END) AS total_pendientes_sync
    FROM FLORERIA_Producto p
    INNER JOIN FLORERIA_Producto_Categoria pc ON p.producto_id = pc.producto_id
    WHERE pc.categoria_id = @categoria_id;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_ProductosDisponibles]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ══════════════════════════════════════════════════════════════════════════════
-- SP: Listar productos disponibles para agregar (NO están en la categoría)
-- ══════════════════════════════════════════════════════════════════════════════
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_ProductosDisponibles]
    @categoria_id INT,
    @buscar       VARCHAR(200) = NULL,
    @limite       INT = 100
AS BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP (@limite)
        p.producto_id,
        p.sku,
        p.nombre,
        p.precio_base_bs,
        p.precio_promo_bs,
        p.stock_actual,
        p.wc_sync_estado,
        p.imagen_url,
        
        -- Promoción activa
        CASE
            WHEN p.precio_promo_bs IS NOT NULL
             AND p.promo_desde <= CAST(GETDATE() AS DATE)
             AND (p.promo_hasta IS NULL OR p.promo_hasta >= CAST(GETDATE() AS DATE))
            THEN 1 
            ELSE 0
        END AS tiene_promo_activa,
        
        -- Categorías actuales del producto
        (SELECT COUNT(*) 
         FROM FLORERIA_Producto_Categoria pc2 
         WHERE pc2.producto_id = p.producto_id) AS total_categorias
        
    FROM FLORERIA_Producto p
    WHERE p.activo = 1
      AND p.producto_id NOT IN (
          SELECT producto_id 
          FROM FLORERIA_Producto_Categoria 
          WHERE categoria_id = @categoria_id
      )
      AND (@buscar IS NULL OR 
           p.nombre LIKE '%' + @buscar + '%' OR 
           p.sku LIKE '%' + @buscar + '%')
    ORDER BY p.nombre;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_QuitarProducto]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ══════════════════════════════════════════════════════════════════════════════
-- SP: Quitar un producto de una categoría
-- ══════════════════════════════════════════════════════════════════════════════
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_QuitarProducto]
    @categoria_id INT,
    @producto_id  INT,
    @usuario_id   INT,
    @motivo       VARCHAR(300)
AS BEGIN
    SET NOCOUNT ON;
    
    -- Validar que existe la relación
    IF NOT EXISTS (
        SELECT 1 FROM FLORERIA_Producto_Categoria 
        WHERE producto_id = @producto_id AND categoria_id = @categoria_id
    )
    BEGIN
        SELECT 0 AS ok, 'El producto no pertenece a esta categoria' AS mensaje;
        RETURN;
    END;
    
    -- Guardar valor anterior para auditoría
    DECLARE @valor_anterior NVARCHAR(MAX);
    DECLARE @era_principal BIT;
    
    SELECT @era_principal = es_principal,
           @valor_anterior = 
        '{"producto_id":' + CAST(@producto_id AS VARCHAR) + 
        ',"categoria_id":' + CAST(@categoria_id AS VARCHAR) +
        ',"es_principal":' + CAST(es_principal AS VARCHAR) + '}'
    FROM FLORERIA_Producto_Categoria
    WHERE producto_id = @producto_id AND categoria_id = @categoria_id;
    
    -- Eliminar
    DELETE FROM FLORERIA_Producto_Categoria
    WHERE producto_id = @producto_id 
      AND categoria_id = @categoria_id;
    
    -- Auditar
    INSERT INTO FLORERIA_Auditoria 
        (usuario_id, tabla, registro_id, accion, valor_anterior, motivo, fecha_hora)
    VALUES 
        (@usuario_id, 'FLORERIA_Producto_Categoria', 
         CAST(@producto_id AS VARCHAR) + '-' + CAST(@categoria_id AS VARCHAR),
         'ELIMINAR', @valor_anterior, @motivo, GETDATE());
    
    SELECT 1 AS ok, 'Producto quitado de la categoria' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Categoria_QuitarProductosMasivo]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ══════════════════════════════════════════════════════════════════════════════
-- SP: Quitar múltiples productos de una categoría (masivo)
-- ══════════════════════════════════════════════════════════════════════════════
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Categoria_QuitarProductosMasivo]
    @categoria_id   INT,
    @productos_ids  VARCHAR(MAX),
    @usuario_id     INT,
    @motivo         VARCHAR(300)
AS BEGIN
    SET NOCOUNT ON;
    
    DECLARE @producto_id INT;
    DECLARE @pos INT;
    DECLARE @ids VARCHAR(MAX) = @productos_ids + ',';
    DECLARE @eliminados INT = 0;
    
    WHILE LEN(@ids) > 0
    BEGIN
        SET @pos = CHARINDEX(',', @ids);
        IF @pos > 1
        BEGIN
            SET @producto_id = CAST(LEFT(@ids, @pos - 1) AS INT);
            
            IF EXISTS (
                SELECT 1 FROM FLORERIA_Producto_Categoria 
                WHERE producto_id = @producto_id AND categoria_id = @categoria_id
            )
            BEGIN
                DELETE FROM FLORERIA_Producto_Categoria
                WHERE producto_id = @producto_id AND categoria_id = @categoria_id;
                
                SET @eliminados = @eliminados + 1;
            END;
        END;
        
        SET @ids = RIGHT(@ids, LEN(@ids) - @pos);
    END;
    
    -- Auditar
    INSERT INTO FLORERIA_Auditoria 
        (usuario_id, tabla, registro_id, accion, valor_anterior, motivo, fecha_hora)
    VALUES 
        (@usuario_id, 'FLORERIA_Producto_Categoria', CAST(@categoria_id AS VARCHAR(50)),
         'ELIMINAR', 'Eliminados: ' + CAST(@eliminados AS VARCHAR), @motivo, GETDATE());
    
    SELECT 
        1 AS ok,
        'Se quitaron ' + CAST(@eliminados AS VARCHAR) + ' producto(s)' AS mensaje,
        @eliminados AS eliminados;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_CerrarSesion]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ────────────────────────────────────────
CREATE   PROCEDURE [dbo].[FLORERIA_sp_CerrarSesion]
    @token VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE FLORERIA_Sesion SET
        activa      = 0,
        cerrada_por = 'USUARIO'
    WHERE token = @token AND activa = 1;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Config_Guardar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Corregir SP Guardar para hacer UPSERT (INSERT si no existe, UPDATE si existe)
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Config_Guardar]
    @clave          VARCHAR(100),
    @valor          NVARCHAR(500),
    @modificado_por INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @anterior  NVARCHAR(500);
    DECLARE @es_secreto BIT;
    DECLARE @existe    INT = 0;

    SELECT @anterior   = valor,
           @es_secreto = es_secreto,
           @existe      = 1
    FROM FLORERIA_Config WHERE clave = @clave;

    IF @existe = 1
    BEGIN
        -- Actualizar existente
        UPDATE FLORERIA_Config SET
            valor          = @valor,
            modificado_por = @modificado_por,
            modificado_en  = GETDATE()
        WHERE clave = @clave;
    END
    ELSE
    BEGIN
        -- Insertar nuevo si no existía
        INSERT INTO FLORERIA_Config (clave, valor, es_secreto, modificado_por, modificado_en)
        VALUES (@clave, @valor, 0, @modificado_por, GETDATE());
        SET @es_secreto = 0;
    END;

    -- Auditoría
    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_anterior, valor_nuevo, motivo)
    VALUES
        (@modificado_por, 'FLORERIA_Config', @clave,
         'MODIFICAR',
         CASE WHEN @es_secreto = 1 THEN '{"valor":"***"}' ELSE '{"valor":"' + ISNULL(@anterior,'') + '"}' END,
         CASE WHEN @es_secreto = 1 THEN '{"valor":"***"}' ELSE '{"valor":"' + ISNULL(@valor,'') + '"}' END,
         'Actualizacion de configuracion');

    SELECT 1 AS ok, 'Configuracion guardada.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Config_ListarTodas]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_Config_ListarTodas]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        c.config_id,
        c.clave,
        c.valor,
        c.descripcion,
        c.es_secreto,
        c.modificado_en,
        u.nombres + ' ' + u.apellidos AS modificado_por_nombre
    FROM FLORERIA_Config c
    LEFT JOIN FLORERIA_Usuario u ON c.modificado_por = u.usuario_id
    WHERE c.activo = 1
    ORDER BY c.clave;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Config_Obtener]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Corregir SP Obtener para retornar solo el valor
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Config_Obtener]
    @clave VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT valor
    FROM FLORERIA_Config
    WHERE clave = @clave AND activo = 1;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Dashboard_Estadisticas]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_Dashboard_Estadisticas]
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
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Dashboard_PedidosRecientes]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- SP 2: FLORERIA_sp_Dashboard_PedidosRecientes
-- Propósito: Últimos N pedidos del agente para dashboard
--            Muestra origen (SISTEMA vs WOOCOMMERCE)
--            y estado de pago real
-- =============================================
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Dashboard_PedidosRecientes]
    @usuario_id INT,
    @cantidad   INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@cantidad)
        p.pedido_id,
        p.codigo,
        p.receptor_nombre,
        p.receptor_celular,
        p.fecha_entrega,
        p.es_express,
        p.total_bs,
        p.anticipo_bs,
        p.saldo_bs,
        p.estado_pago,
        CASE
            WHEN p.wc_order_id IS NOT NULL THEN 'WOOCOMMERCE'
            ELSE 'SISTEMA'
        END AS origen,
        p.wc_order_number,
        pp.codigo AS prepedido_codigo,
        z.nombre  AS zona_nombre,
        p.creado_en
    FROM FLORERIA_Pedido p
    LEFT JOIN FLORERIA_PrePedido pp ON p.prepedido_id = pp.prepedido_id
    LEFT JOIN FLORERIA_Zona z       ON p.zona_id      = z.zona_id
    WHERE pp.agente_actual_id = @usuario_id
       OR (p.wc_order_id IS NOT NULL AND p.creado_por = @usuario_id)
    ORDER BY p.pedido_id DESC
END
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Dashboard_PrePedidosRecientes]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- SP 1: FLORERIA_sp_Dashboard_PrePedidosRecientes
-- Propósito: Últimos N pre-pedidos del agente para dashboard
--            Incluye token_web, token_expira y estado de pago
--            desde FLORERIA_Pedido_Pago (confirmación manual)
-- =============================================
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Dashboard_PrePedidosRecientes]
    @usuario_id INT,
    @cantidad   INT = 6
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
        pp.token_web,
        pp.token_expira,
        pp.total_general_bs,
        pp.creado_en,
        ISNULL(
            (SELECT TOP 1 pag.estado
             FROM FLORERIA_Pedido_Pago pag
             WHERE pag.prepedido_id = pp.prepedido_id
             ORDER BY pag.pago_id DESC),
            'SIN_PAGO'
        ) AS estado_pago,
        ISNULL(
            (SELECT TOP 1 u2.nombres + ' ' + u2.apellidos
             FROM FLORERIA_Pedido_Pago pag2
             INNER JOIN FLORERIA_Usuario u2 ON pag2.verificado_por = u2.usuario_id
             WHERE pag2.prepedido_id = pp.prepedido_id
               AND pag2.estado = 'VERIFICADO'
             ORDER BY pag2.pago_id DESC),
            NULL
        ) AS pago_verificado_por
    FROM FLORERIA_PrePedido pp
    WHERE pp.agente_actual_id = @usuario_id
      AND pp.tipo_registro = 'PRE_PEDIDO'
    ORDER BY pp.prepedido_id DESC
END
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Login]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================================
-- CORRECCION: FLORERIA_sp_Login
-- Problema: expira_en usaba GETDATE() que es hora del servidor
--           (UTC o USA), no hora de Bolivia (UTC-4)
-- Solucion: calcular 23:59:59 del dia actual en hora Bolivia
-- Ejecutar en: SSMS conectado a Somee
-- ============================================================

CREATE   PROCEDURE [dbo].[FLORERIA_sp_Login]
    @carnet        VARCHAR(8),
    @password_hash VARCHAR(200),
    @ip            VARCHAR(50),
    @user_agent    VARCHAR(500),
    @es_celular    BIT,
    @dispositivo   VARCHAR(100),
    @sistema_op    VARCHAR(50),
    @navegador     VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- =============================================
    -- 1. CALCULAR HORA ACTUAL EN BOLIVIA (UTC-4)
    -- =============================================
    DECLARE @horaBolivia  DATETIME = DATEADD(HOUR, -4, GETUTCDATE())
    DECLARE @expira_en    DATETIME = CAST(CAST(@horaBolivia AS DATE) AS DATETIME) + '23:59:59'

    -- =============================================
    -- 2. VERIFICAR QUE EL USUARIO EXISTE Y ESTA ACTIVO
    -- =============================================
    DECLARE @usuario_id        INT
    DECLARE @tipo_id           SMALLINT
    DECLARE @nombres           VARCHAR(100)
    DECLARE @apellidos         VARCHAR(100)
    DECLARE @debe_cambiar_pwd  BIT
    DECLARE @activo            BIT
    DECLARE @bloqueado         BIT
    DECLARE @bloqueado_hasta   DATETIME
    DECLARE @intentos          TINYINT
    DECLARE @vigente_hasta     DATE
    DECLARE @pwd_hash_bd       VARCHAR(200)

    SELECT
        @usuario_id       = usuario_id,
        @tipo_id          = tipo_id,
        @nombres          = nombres,
        @apellidos        = apellidos,
        @debe_cambiar_pwd = debe_cambiar_pwd,
        @activo           = activo,
        @bloqueado        = bloqueado,
        @bloqueado_hasta  = bloqueado_hasta,
        @intentos         = intentos_fallidos,
        @vigente_hasta    = vigente_hasta,
        @pwd_hash_bd      = password_hash
    FROM FLORERIA_Usuario
    WHERE carnet = @carnet

    -- Usuario no existe
    IF @usuario_id IS NULL
    BEGIN
        SELECT 'ERROR' AS resultado, 'Carnet o contrasena incorrectos.' AS mensaje,
               NULL AS usuario_id, NULL AS token, NULL AS debe_cambiar_pwd,
               NULL AS nombres, NULL AS apellidos, NULL AS tipo_id
        RETURN
    END

    -- Usuario inactivo
    IF @activo = 0
    BEGIN
        SELECT 'ERROR' AS resultado, 'Usuario inactivo. Contacte al administrador.' AS mensaje,
               NULL AS usuario_id, NULL AS token, NULL AS debe_cambiar_pwd,
               NULL AS nombres, NULL AS apellidos, NULL AS tipo_id
        RETURN
    END

    -- Bloqueado permanente
    IF @bloqueado = 1
    BEGIN
        SELECT 'ERROR' AS resultado, 'Usuario bloqueado. Contacte al administrador.' AS mensaje,
               NULL AS usuario_id, NULL AS token, NULL AS debe_cambiar_pwd,
               NULL AS nombres, NULL AS apellidos, NULL AS tipo_id
        RETURN
    END

    -- Bloqueado temporalmente
    IF @bloqueado_hasta IS NOT NULL AND @horaBolivia < @bloqueado_hasta
    BEGIN
        DECLARE @minutos INT = DATEDIFF(MINUTE, @horaBolivia, @bloqueado_hasta) + 1
        SELECT 'BLOQUEADO_TEMP' AS resultado,
               'Demasiados intentos fallidos. Intente en ' + CAST(@minutos AS VARCHAR) + ' minutos.' AS mensaje,
               NULL AS usuario_id, NULL AS token, NULL AS debe_cambiar_pwd,
               NULL AS nombres, NULL AS apellidos, NULL AS tipo_id
        RETURN
    END

    -- Vigencia vencida
    IF @vigente_hasta IS NOT NULL AND CAST(@horaBolivia AS DATE) > @vigente_hasta
    BEGIN
        SELECT 'VENCIDO' AS resultado, 'Su acceso ha vencido. Contacte al administrador.' AS mensaje,
               NULL AS usuario_id, NULL AS token, NULL AS debe_cambiar_pwd,
               NULL AS nombres, NULL AS apellidos, NULL AS tipo_id
        RETURN
    END

    -- =============================================
    -- 3. VERIFICAR PASSWORD
    -- =============================================
    IF @pwd_hash_bd <> @password_hash
    BEGIN
        -- Incrementar intentos fallidos
        UPDATE FLORERIA_Usuario
        SET intentos_fallidos = intentos_fallidos + 1,
            bloqueado_hasta   = CASE
                                    WHEN intentos_fallidos + 1 >= 6 THEN NULL  -- bloqueo permanente
                                    WHEN intentos_fallidos + 1 >= 3 THEN DATEADD(MINUTE, 5, @horaBolivia)
                                    ELSE bloqueado_hasta
                                END,
            bloqueado         = CASE WHEN intentos_fallidos + 1 >= 6 THEN 1 ELSE bloqueado END
        WHERE usuario_id = @usuario_id

        SELECT 'ERROR' AS resultado, 'Carnet o contrasena incorrectos.' AS mensaje,
               NULL AS usuario_id, NULL AS token, NULL AS debe_cambiar_pwd,
               NULL AS nombres, NULL AS apellidos, NULL AS tipo_id
        RETURN
    END

    -- =============================================
    -- 4. LOGIN EXITOSO — CREAR SESION
    -- =============================================

    -- Resetear intentos fallidos y bloqueo temporal
    UPDATE FLORERIA_Usuario
    SET intentos_fallidos = 0,
        bloqueado_hasta   = NULL
    WHERE usuario_id = @usuario_id

    -- Cerrar sesiones anteriores del mismo usuario
    UPDATE FLORERIA_Sesion
    SET activa      = 0,
        cerrada_por = 'NUEVA_SESION'
    WHERE usuario_id = @usuario_id
      AND activa     = 1

    -- Generar token unico
    DECLARE @token VARCHAR(100) = LOWER(REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''))
                                + LOWER(REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''))

    -- Insertar nueva sesion con expira_en en hora Bolivia
    INSERT INTO FLORERIA_Sesion
        (usuario_id, token, ip, user_agent, es_celular, dispositivo, sistema_op, navegador, inicio, ultimo_acceso, expira_en, activa)
    VALUES
        (@usuario_id, @token, @ip, @user_agent, @es_celular, @dispositivo, @sistema_op, @navegador,
         @horaBolivia, @horaBolivia, @expira_en, 1)

    -- Retornar datos del usuario
    SELECT
        'OK'              AS resultado,
        'Login exitoso'   AS mensaje,
        @usuario_id       AS usuario_id,
        @token            AS token,
        @debe_cambiar_pwd AS debe_cambiar_pwd,
        @nombres          AS nombres,
        @apellidos        AS apellidos,
        @tipo_id          AS tipo_id
END
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_PagoMetodo_Map_Obtener]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_PagoMetodo_Map_Obtener]
    @codigo_sisconbol VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @method VARCHAR(50)
    DECLARE @title  VARCHAR(100)

    SELECT TOP 1
        @method = wc_payment_method,
        @title  = wc_payment_method_title
    FROM FLORERIA_PagoMetodo_Map
    WHERE codigo_sisconbol = @codigo_sisconbol
      AND activo = 1

    -- Fallback si no se encuentra
    IF @method IS NULL
    BEGIN
        SET @method = 'bacs'
        SET @title  = ISNULL(@codigo_sisconbol, 'Otro')
    END

    SELECT
        @method AS wc_payment_method,
        @title  AS wc_payment_method_title
END
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_AceptarPagoManual]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_Pedido_AceptarPagoManual]
    @pedido_id   INT,
    @usuario_id  INT,
    @ip          VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables del pedido
    DECLARE @estado_pago_actual VARCHAR(20);
    DECLARE @wc_order_id INT;
    DECLARE @total_bs DECIMAL(10,2);
    DECLARE @total_usd DECIMAL(10,2);
    DECLARE @wc_payment_method VARCHAR(50);
    
    -- Variables calculadas
    DECLARE @pagado_previo_bs DECIMAL(10,2);
    DECLARE @pagado_previo_usd DECIMAL(10,2);
    DECLARE @monto_a_registrar_bs DECIMAL(10,2);
    DECLARE @monto_a_registrar_usd DECIMAL(10,2);
    
    -- 1. Leer datos del pedido
    SELECT 
        @estado_pago_actual = estado_pago,
        @wc_order_id = wc_order_id,
        @total_bs = total_bs,
        @total_usd = total_usd,
        @wc_payment_method = wc_payment_method
    FROM FLORERIA_Pedido 
    WHERE pedido_id = @pedido_id;
    
    -- Validar que existe
    IF @estado_pago_actual IS NULL
    BEGIN
        SELECT 0 AS ok, 'Pedido no encontrado.' AS mensaje;
        RETURN;
    END
    
    -- Validar que no esta ya pagado
    IF @estado_pago_actual = 'PAGADO'
    BEGIN
        SELECT 0 AS ok, 'Este pedido ya esta marcado como pagado.' AS mensaje;
        RETURN;
    END
    
    -- 2. Calcular cuanto se pago previamente (solo pagos verificados)
    SELECT 
        @pagado_previo_bs = ISNULL(SUM(monto_bs), 0),
        @pagado_previo_usd = ISNULL(SUM(monto_usd), 0)
    FROM FLORERIA_Pedido_Pago
    WHERE pedido_id = @pedido_id
      AND estado = 'VERIFICADO';
    
    -- 3. VALIDACION: bloquear si ya hay sobrepago en pagos previos
    IF @pagado_previo_bs > @total_bs
    BEGIN
        SELECT 0 AS ok, 
            'Sobrepago detectado en pagos previos. Total pedido: Bs ' + 
            CAST(@total_bs AS VARCHAR) + 
            ' / Pagado previo: Bs ' + 
            CAST(@pagado_previo_bs AS VARCHAR) + 
            '. Revisa los pagos registrados antes de continuar.' AS mensaje;
        RETURN;
    END
    
    -- 4. VALIDACION: bloquear si ya esta totalmente pagado pero estado_pago no se actualizo
    IF @pagado_previo_bs >= @total_bs
    BEGIN
        SELECT 0 AS ok, 
            'Este pedido ya tiene el total cubierto en pagos previos (Bs ' + 
            CAST(@pagado_previo_bs AS VARCHAR) + 
            '). Solo falta actualizar el estado del pedido.' AS mensaje;
        RETURN;
    END
    
    -- 5. Calcular el monto que falta pagar (lo que vamos a registrar)
    SET @monto_a_registrar_bs = @total_bs - @pagado_previo_bs;
    SET @monto_a_registrar_usd = @total_usd - @pagado_previo_usd;
    
    -- 6. Ejecutar todo en transaccion
    BEGIN TRANSACTION;
    
    -- 6.1 Actualizar pedido
    UPDATE FLORERIA_Pedido
    SET estado_pago = 'PAGADO',
        anticipo_bs = @total_bs,    -- total pagado ahora = total pedido
        saldo_bs = 0,
        modificado_por = @usuario_id,
        modificado_en = GETDATE()
    WHERE pedido_id = @pedido_id;
    
    -- 6.2 Registrar el pago en FLORERIA_Pedido_Pago
    --     monto = lo que FALTABA, no el total
    INSERT INTO FLORERIA_Pedido_Pago
        (pedido_id, tipo_pago, metodo_pago, monto_bs, monto_usd,
         referencia, estado, verificado_por, verificado_en,
         observaciones, creado_por, creado_en)
    VALUES
        (@pedido_id, 
         CASE WHEN @pagado_previo_bs > 0 THEN 'SALDO' ELSE 'TOTAL' END,
         ISNULL(@wc_payment_method, 'MANUAL'),
         @monto_a_registrar_bs, @monto_a_registrar_usd,
         CASE WHEN @wc_order_id IS NOT NULL 
              THEN 'WC #' + CAST(@wc_order_id AS VARCHAR) 
              ELSE NULL END,
         'VERIFICADO', @usuario_id, GETDATE(),
         CASE WHEN @pagado_previo_bs > 0 
              THEN 'Saldo aceptado manualmente. Pagado previo: Bs ' + 
                   CAST(@pagado_previo_bs AS VARCHAR)
              ELSE 'Aceptado manualmente desde gestion de pedidos'
         END,
         @usuario_id, GETDATE());
    
    -- 6.3 Log de cambio de estado
    INSERT INTO FLORERIA_Pedido_Estado_Log
        (pedido_id, estado_anterior, estado_nuevo, observaciones, usuario_id, fecha_hora)
    VALUES
        (@pedido_id, @estado_pago_actual, 'PAGADO', 
         'Pago aceptado manualmente. Monto: Bs ' + 
         CAST(@monto_a_registrar_bs AS VARCHAR), 
         @usuario_id, GETDATE());
    
    -- 6.4 Auditoria
    INSERT INTO FLORERIA_Auditoria
        (usuario_id, ip, tabla, registro_id, accion, valor_anterior, valor_nuevo, motivo)
    VALUES
        (@usuario_id, @ip, 'FLORERIA_Pedido', CAST(@pedido_id AS VARCHAR),
         'MODIFICAR',
         '{"estado_pago":"' + @estado_pago_actual + 
         '","pagado_previo_bs":"' + CAST(@pagado_previo_bs AS VARCHAR) + '"}',
         '{"estado_pago":"PAGADO","monto_registrado_bs":"' + 
         CAST(@monto_a_registrar_bs AS VARCHAR) + '"}',
         'Aceptacion manual de pago WC');
    
    COMMIT TRANSACTION;
    
    SELECT 1 AS ok, 
        'Pago aceptado correctamente. Registrado: Bs ' + 
        CAST(@monto_a_registrar_bs AS VARCHAR) AS mensaje,
        @monto_a_registrar_bs AS monto_registrado,
        @pagado_previo_bs AS pagado_previo;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_AgregarProducto]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FLORERIA_sp_Pedido_AgregarProducto]
    @pedido_id INT, @producto_id INT = NULL, @variacion_id INT = NULL,
    @es_personalizado BIT, @nombre_producto VARCHAR(200), @descripcion NVARCHAR(500) = NULL,
    @cantidad INT, @precio_unitario_bs DECIMAL(10,2), @precio_unitario_usd DECIMAL(10,2) = 0,
    @personalizacion NVARCHAR(500) = NULL -- Asegura este campo
AS
BEGIN
    INSERT INTO [dbo].[FLORERIA_Pedido_Detalle] (
        pedido_id, producto_id, variacion_id, es_personalizado, nombre_producto, 
        descripcion, cantidad, precio_unitario_bs, precio_unitario_usd, 
        subtotal_bs, subtotal_usd, personalizacion, creado_en
    )
    VALUES (
        @pedido_id, @producto_id, @variacion_id, @es_personalizado, @nombre_producto,
        @descripcion, @cantidad, @precio_unitario_bs, @precio_unitario_usd,
        (@cantidad * @precio_unitario_bs), (@cantidad * @precio_unitario_usd),
        @personalizacion, GETDATE()
    );
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_CalcularEnvio]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- SP 8: FLORERIA_sp_Pedido_CalcularEnvio
-- Descripción: Calcular costo de envío
-- =============================================
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Pedido_CalcularEnvio]
    @pedido_id           INT,
    @tasa_cambio         DECIMAL(10,4)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar pedido existe
    IF NOT EXISTS (SELECT 1 FROM FLORERIA_Pedido WHERE pedido_id = @pedido_id)
    BEGIN
        RAISERROR('El pedido no existe', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @tipo_entrega VARCHAR(20);
        DECLARE @zona_id INT;
        DECLARE @slot_id SMALLINT;
        DECLARE @es_express BIT;
        
        -- Obtener datos del pedido
        SELECT 
            @tipo_entrega = tipo_entrega,
            @zona_id = zona_id,
            @slot_id = slot_id,
            @es_express = es_express
        FROM FLORERIA_Pedido
        WHERE pedido_id = @pedido_id;
        
        DECLARE @tarifa_base_bs DECIMAL(10,2) = 0;
        DECLARE @recargo_horario_bs DECIMAL(10,2) = 0;
        DECLARE @recargo_express_bs DECIMAL(10,2) = 0;
        
        -- 1. Tarifa base de zona (solo si es DOMICILIO)
        IF @tipo_entrega = 'DOMICILIO' AND @zona_id IS NOT NULL
        BEGIN
            SELECT TOP 1 @tarifa_base_bs = precio_bs
            FROM FLORERIA_Zona_Tarifa
            WHERE zona_id = @zona_id
              AND vigente_desde <= CAST(GETDATE() AS DATE)
              AND (vigente_hasta IS NULL OR vigente_hasta >= CAST(GETDATE() AS DATE))
            ORDER BY vigente_desde DESC;
        END
        
        -- 2. Recargo por horario (solo si NO es express)
        IF @es_express = 0 AND @slot_id IS NOT NULL
        BEGIN
            SELECT @recargo_horario_bs = ISNULL(recargo_bs, 0)
            FROM FLORERIA_Slot_Horario
            WHERE slot_id = @slot_id;
        END
        
        -- 3. Recargo express
        IF @es_express = 1 AND @zona_id IS NOT NULL
        BEGIN
            SELECT @recargo_express_bs = ISNULL(recargo_bs, 0)
            FROM FLORERIA_Zona_Express
            WHERE zona_id = @zona_id
              AND activo = 1;
        END
        
        -- Calcular equivalentes en USD
        DECLARE @tarifa_base_usd DECIMAL(10,2) = @tarifa_base_bs / @tasa_cambio;
        DECLARE @recargo_horario_usd DECIMAL(10,2) = @recargo_horario_bs / @tasa_cambio;
        DECLARE @recargo_express_usd DECIMAL(10,2) = @recargo_express_bs / @tasa_cambio;
        
        -- Actualizar pedido
        UPDATE FLORERIA_Pedido
        SET envio_bs = @tarifa_base_bs,
            envio_usd = @tarifa_base_usd,
            recargo_horario_bs = @recargo_horario_bs,
            recargo_horario_usd = @recargo_horario_usd,
            recargo_express_bs = @recargo_express_bs,
            recargo_express_usd = @recargo_express_usd,
            total_bs = subtotal_productos_bs + @tarifa_base_bs + @recargo_horario_bs + @recargo_express_bs,
            total_usd = subtotal_productos_usd + @tarifa_base_usd + @recargo_horario_usd + @recargo_express_usd,
            saldo_bs = total_bs - anticipo_bs,
            modificado_en = GETDATE()
        WHERE pedido_id = @pedido_id;
        
        -- Actualizar total general del pre-pedido
        DECLARE @prepedido_id INT;
        SELECT @prepedido_id = prepedido_id FROM FLORERIA_Pedido WHERE pedido_id = @pedido_id;
        
        UPDATE FLORERIA_PrePedido
        SET total_general_bs = (
                SELECT SUM(total_bs) FROM FLORERIA_Pedido WHERE prepedido_id = @prepedido_id
            ),
            total_general_usd = (
                SELECT SUM(total_usd) FROM FLORERIA_Pedido WHERE prepedido_id = @prepedido_id
            ),
            modificado_en = GETDATE()
        WHERE prepedido_id = @prepedido_id;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_CambiarEstadoOperativo]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_Pedido_CambiarEstadoOperativo]
    @pedido_id        INT,
    @estado_nuevo     VARCHAR(20),
    @observaciones    VARCHAR(500) = NULL,
    @usuario_id       INT,
    @ip               VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar estado
    IF @estado_nuevo NOT IN ('PENDIENTE', 'IMPRESO', 'EN_PREPARACION', 'LISTO', 
                              'EN_RUTA', 'ENTREGADO', 'NO_ENTREGADO', 'REPROGRAMADO')
    BEGIN
        SELECT 0 AS ok, 'Estado operativo invalido.' AS mensaje;
        RETURN;
    END
    
    -- Verificar que el pedido existe
    DECLARE @estado_anterior VARCHAR(20);
    SELECT @estado_anterior = estado_operativo
    FROM FLORERIA_Pedido WHERE pedido_id = @pedido_id;
    
    IF @estado_anterior IS NULL
    BEGIN
        SELECT 0 AS ok, 'Pedido no encontrado.' AS mensaje;
        RETURN;
    END
    
    -- No hacer nada si es el mismo estado
    IF @estado_anterior = @estado_nuevo
    BEGIN
        SELECT 0 AS ok, 'El pedido ya esta en ese estado.' AS mensaje;
        RETURN;
    END
    
    -- Actualizar pedido
    UPDATE FLORERIA_Pedido
    SET estado_operativo = @estado_nuevo,
        modificado_por = @usuario_id,
        modificado_en = GETDATE()
    WHERE pedido_id = @pedido_id;
    
    -- Registrar en log
    INSERT INTO FLORERIA_Pedido_Estado_Log
        (pedido_id, estado_anterior, estado_nuevo, observaciones, usuario_id, fecha_hora)
    VALUES
        (@pedido_id, @estado_anterior, @estado_nuevo, @observaciones, @usuario_id, GETDATE());
    
    -- Auditoria
    INSERT INTO FLORERIA_Auditoria
        (usuario_id, ip, tabla, registro_id, accion, valor_anterior, valor_nuevo)
    VALUES
        (@usuario_id, @ip, 'FLORERIA_Pedido', CAST(@pedido_id AS VARCHAR),
         'MODIFICAR',
         '{"estado_operativo":"' + @estado_anterior + '"}',
         '{"estado_operativo":"' + @estado_nuevo + '"}');
    
    SELECT 1 AS ok, 'Estado actualizado correctamente.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_Crear]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================================
-- ALTER: FLORERIA_sp_Pedido_Crear
-- Agrega llamada a RecalcularEstado al final del SP
-- Para que al crear un pedido hijo el PrePedido pase
-- automáticamente a COMPLETADO
-- =============================================================
CREATE PROCEDURE [dbo].[FLORERIA_sp_Pedido_Crear]
    @prepedido_id   INT,
    @receptor_nombre  VARCHAR(200),
    @receptor_celular VARCHAR(20),
    @ciudad_id        SMALLINT,
    @zona_id          INT          = NULL,
    @sucursal_id      SMALLINT     = NULL,
    @tipo_entrega     VARCHAR(20),
    @direccion        VARCHAR(300) = NULL,
    @referencia       VARCHAR(300) = NULL,
    @fecha_entrega    DATE,
    @slot_id          SMALLINT     = NULL,
    @es_express       BIT          = 0,
    @dedicatoria      NVARCHAR(500)= NULL,
    @firma_tarjeta    VARCHAR(100) = NULL,
    @wc_order_id      INT          = NULL,
    @tipo_ocacion     VARCHAR(30)  = 'OTRO',
    @nota_floreria    NVARCHAR(500)= NULL,
    @creado_por       INT          = NULL,
    @ip               VARCHAR(50)  = NULL,
    @pedido_id        INT          OUTPUT,
    @codigo           VARCHAR(20)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ultimo_numero INT;
    SELECT @ultimo_numero = ISNULL(MAX(CAST(SUBSTRING(codigo, 5, 6) AS INT)), 0)
    FROM FLORERIA_Pedido WHERE codigo LIKE 'PED-%';
    SET @codigo = 'PED-' + RIGHT('000000' + CAST(@ultimo_numero + 1 AS VARCHAR), 6);

    INSERT INTO [dbo].[FLORERIA_Pedido] (
        prepedido_id, codigo, wc_order_id, receptor_nombre, receptor_celular,
        ciudad_id, zona_id, sucursal_id, tipo_entrega, direccion, referencia,
        fecha_entrega, slot_id, es_express, dedicatoria, firma_tarjeta,
        tipo_ocacion, nota_floreria, wc_sync_estado, wc_sync_fecha,
        creado_por, creado_en
    )
    VALUES (
        @prepedido_id, @codigo, @wc_order_id, ISNULL(@receptor_nombre, 'Sin nombre'),
        ISNULL(@receptor_celular, '00000000'), @ciudad_id, ISNULL(@zona_id, 0), @sucursal_id,
        ISNULL(@tipo_entrega, 'DOMICILIO'), @direccion, @referencia, @fecha_entrega,
        @slot_id, ISNULL(@es_express, 0), @dedicatoria, @firma_tarjeta,
        @tipo_ocacion, @nota_floreria, 'SINCRONIZADO', GETDATE(), @creado_por, GETDATE()
    );
    SET @pedido_id = SCOPE_IDENTITY();

    -- *** NUEVO: recalcular estado del PrePedido automáticamente ***
    IF @prepedido_id IS NOT NULL AND @prepedido_id > 0
    BEGIN
        EXEC FLORERIA_sp_PrePedido_RecalcularEstado
            @prepedido_id   = @prepedido_id,
            @modificado_por = @creado_por;
    END

END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_Detalle_SyncWC]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_Pedido_Detalle_SyncWC]
    @pedido_id           INT,
    @wc_line_item_id     INT,
    @producto_id         INT          = NULL,
    @nombre_producto     VARCHAR(200),
    @cantidad            INT          = 1,
    @precio_unitario_bs  DECIMAL(10,2) = 0,
    @precio_unitario_usd DECIMAL(10,2) = 0,
    @personalizacion     NVARCHAR(500) = NULL,
    @accion              VARCHAR(10)  OUTPUT,
    @mensaje_error       NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @accion = 'ERROR';
    SET @mensaje_error = NULL;

    BEGIN TRY
        -- Defaults
        IF @cantidad IS NULL OR @cantidad <= 0 SET @cantidad = 1;
        IF @precio_unitario_bs IS NULL OR @precio_unitario_bs < 0 SET @precio_unitario_bs = 0;
        IF @precio_unitario_usd IS NULL OR @precio_unitario_usd < 0 SET @precio_unitario_usd = 0;
        IF @nombre_producto IS NULL OR LTRIM(RTRIM(@nombre_producto)) = ''
            SET @nombre_producto = 'Producto sin nombre';

        -- Si ya existe detalle con este wc_line_item_id → UPDATE
        IF EXISTS (SELECT 1 FROM FLORERIA_Pedido_Detalle
                   WHERE pedido_id = @pedido_id AND wc_line_item_id = @wc_line_item_id)
        BEGIN
            UPDATE FLORERIA_Pedido_Detalle
            SET producto_id          = @producto_id,
                nombre_producto      = @nombre_producto,
                cantidad             = @cantidad,
                precio_unitario_bs   = @precio_unitario_bs,
                precio_unitario_usd  = @precio_unitario_usd,
                subtotal_bs          = @cantidad * @precio_unitario_bs,
                subtotal_usd         = @cantidad * @precio_unitario_usd,
                personalizacion      = @personalizacion
            WHERE pedido_id = @pedido_id AND wc_line_item_id = @wc_line_item_id;

            SET @accion = 'UPDATE';
        END
        ELSE
        BEGIN
            INSERT INTO FLORERIA_Pedido_Detalle (
                pedido_id, producto_id, wc_line_item_id,
                es_personalizado, nombre_producto, cantidad,
                precio_unitario_bs, precio_unitario_usd,
                subtotal_bs, subtotal_usd,
                personalizacion, creado_en
            )
            VALUES (
                @pedido_id, @producto_id, @wc_line_item_id,
                0, @nombre_producto, @cantidad,
                @precio_unitario_bs, @precio_unitario_usd,
                @cantidad * @precio_unitario_bs,
                @cantidad * @precio_unitario_usd,
                @personalizacion, GETDATE()
            );

            SET @accion = 'INSERT';
        END

        SET @mensaje_error = NULL;
    END TRY
    BEGIN CATCH
        SET @accion = 'ERROR';
        SET @mensaje_error = LEFT(
            'Detalle WC#' + CAST(@wc_line_item_id AS VARCHAR) + ' - ' + ERROR_MESSAGE(),
            500
        );
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_Listar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_Pedido_Listar]
    @buscar NVARCHAR(200) = NULL,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL,
    @solo_hoy BIT = 0,
    @creado_desde DATE = NULL,
    @creado_hasta DATE = NULL,
    @estado_pago NVARCHAR(20) = NULL,
    @estado_operativo NVARCHAR(30) = NULL,
    @zona_id INT = NULL,
    @delivery_id INT = NULL,
    @solo_express BIT = 0,
    @solo_sin_contactar BIT = 0,
    @solo_sin_delivery BIT = 0,
    @pagina INT = 1,
    @por_pagina INT = 100
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @offset INT = (@pagina - 1) * @por_pagina;
    DECLARE @hoy DATE = CAST(GETDATE() AS DATE);
    DECLARE @manana DATE = DATEADD(DAY, 1, @hoy);

    SELECT 
        p.pedido_id,
        p.codigo,
        ISNULL(p.wc_order_id, 0) AS wc_order_id,
        ISNULL(p.wc_order_number, '') AS wc_order_number,
        ISNULL(p.wc_order_status, '') AS wc_order_status,
        ISNULL(p.receptor_nombre, '') AS receptor_nombre,
        ISNULL(p.receptor_celular, '') AS receptor_celular,
        ISNULL(p.direccion, '') AS direccion,
        ISNULL(p.referencia, '') AS referencia,
        ISNULL(p.gps, '') AS gps,
        ISNULL(z.nombre, '') AS zona_nombre,
        ISNULL(p.fecha_entrega, GETDATE()) AS fecha_entrega,
        ISNULL(p.creado_en, GETDATE()) AS creado_en,
        ISNULL(s.etiqueta, '') AS slot_etiqueta,
        s.hora_inicio AS slot_hora_inicio,
        s.hora_fin AS slot_hora_fin,
        ISNULL(p.es_express, 0) AS es_express,
        ISNULL(p.estado_pago, 'PENDIENTE') AS estado_pago,
        ISNULL(p.estado_operativo, 'PENDIENTE') AS estado_operativo,
        ISNULL(p.total_bs, 0) AS total_bs,
        ISNULL((
            SELECT SUM(pp.monto_bs)
            FROM FLORERIA_Pedido_Pago pp
            WHERE pp.pedido_id = p.pedido_id 
              AND pp.estado = 'VERIFICADO'
        ), 0) AS monto_pagado,
        ISNULL(p.contactado_cliente, 0) AS contactado_cliente,
        ISNULL(p.delivery_actual_id, 0) AS delivery_actual_id,
        ISNULL(u_deli.nombres + ' ' + u_deli.apellidos, '') AS delivery_nombre
    FROM FLORERIA_Pedido p
    LEFT JOIN FLORERIA_Zona z ON z.zona_id = p.zona_id
    LEFT JOIN FLORERIA_Slot_Horario s ON s.slot_id = p.slot_id
    LEFT JOIN FLORERIA_Usuario u_deli ON u_deli.usuario_id = p.delivery_actual_id
    WHERE 
        (@buscar IS NULL OR @buscar = '' OR
            p.codigo LIKE '%' + @buscar + '%' OR
            p.wc_order_number LIKE '%' + @buscar + '%' OR
            p.receptor_nombre LIKE '%' + @buscar + '%' OR
            p.receptor_celular LIKE '%' + @buscar + '%' OR
            p.direccion LIKE '%' + @buscar + '%'
        )
        AND (
            @solo_hoy = 0 
            OR CAST(p.fecha_entrega AS DATE) = @hoy
        )
        AND (
            @solo_hoy = 1 
            OR (@fecha_desde IS NULL OR CAST(p.fecha_entrega AS DATE) >= @fecha_desde)
        )
        AND (
            @solo_hoy = 1 
            OR (@fecha_hasta IS NULL OR CAST(p.fecha_entrega AS DATE) <= @fecha_hasta)
        )
        AND (@creado_desde IS NULL OR CAST(p.creado_en AS DATE) >= @creado_desde)
        AND (@creado_hasta IS NULL OR CAST(p.creado_en AS DATE) <= @creado_hasta)
        AND (@estado_pago IS NULL OR @estado_pago = '' OR p.estado_pago = @estado_pago)
        AND (@estado_operativo IS NULL OR @estado_operativo = '' OR p.estado_operativo = @estado_operativo)
        AND (@zona_id IS NULL OR p.zona_id = @zona_id)
        AND (
            @delivery_id IS NULL 
            OR (@delivery_id = -1 AND (p.delivery_actual_id IS NULL OR p.delivery_actual_id = 0))
            OR p.delivery_actual_id = @delivery_id
        )
        AND (@solo_express = 0 OR p.es_express = 1)
        AND (@solo_sin_contactar = 0 OR ISNULL(p.contactado_cliente, 0) = 0)
        AND (@solo_sin_delivery = 0 OR p.delivery_actual_id IS NULL OR p.delivery_actual_id = 0)
        AND ISNULL(p.estado_pago, '') NOT IN ('CANCELADO')
        -- OPCION C: Excluir WC pendientes SOLO si NO son urgentes (entrega > manana)
        AND NOT (
            ISNULL(p.wc_order_number, '') <> '' 
            AND p.estado_pago = 'PENDIENTE'
            AND CAST(p.fecha_entrega AS DATE) > @manana
        )
    ORDER BY 
        p.es_express DESC,
        ISNULL(s.hora_inicio, '23:59:59') ASC,
        p.fecha_entrega ASC,
        p.pedido_id DESC
    OFFSET @offset ROWS
    FETCH NEXT @por_pagina ROWS ONLY;

END
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_ListarPendientesWC]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_Pedido_ListarPendientesWC]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT
        p.pedido_id,
        p.codigo,
        p.wc_order_id,
        p.wc_order_number,
        p.wc_order_status,
        p.wc_payment_method,
        p.wc_payment_method_title,
        p.wc_date_modified,
        p.receptor_nombre,
        p.receptor_celular,
        p.total_bs,
        p.contactado_cliente,
        p.contactado_en,
        p.creado_en
    FROM FLORERIA_Pedido p
    WHERE p.wc_order_id IS NOT NULL
      AND p.estado_pago = 'PENDIENTE'
      AND p.wc_order_status IN ('pending', 'on-hold')
    ORDER BY p.creado_en DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_MarcarContactado]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_Pedido_MarcarContactado]
    @pedido_id   INT,
    @contactado  BIT,
    @usuario_id  INT,
    @ip          VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM FLORERIA_Pedido WHERE pedido_id = @pedido_id)
    BEGIN
        SELECT 0 AS ok, 'Pedido no encontrado.' AS mensaje;
        RETURN;
    END
    
    UPDATE FLORERIA_Pedido
    SET contactado_cliente = @contactado,
        contactado_en = CASE WHEN @contactado = 1 THEN GETDATE() ELSE NULL END,
        contactado_por = CASE WHEN @contactado = 1 THEN @usuario_id ELSE NULL END,
        modificado_por = @usuario_id,
        modificado_en = GETDATE()
    WHERE pedido_id = @pedido_id;
    
    -- Log
    INSERT INTO FLORERIA_Pedido_Estado_Log
        (pedido_id, estado_anterior, estado_nuevo, observaciones, usuario_id, fecha_hora)
    VALUES
        (@pedido_id, NULL, 
         CASE WHEN @contactado = 1 THEN 'CONTACTADO' ELSE 'DES_CONTACTADO' END,
         NULL, @usuario_id, GETDATE());
    
    -- Auditoria
    INSERT INTO FLORERIA_Auditoria
        (usuario_id, ip, tabla, registro_id, accion, valor_nuevo)
    VALUES
        (@usuario_id, @ip, 'FLORERIA_Pedido', CAST(@pedido_id AS VARCHAR),
         'MODIFICAR',
         '{"contactado_cliente":"' + CAST(@contactado AS VARCHAR) + '"}');
    
    SELECT 1 AS ok, 'Estado de contacto actualizado.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_MarcarImpreso]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_Pedido_MarcarImpreso]
    @pedido_id   INT,
    @usuario_id  INT,
    @ip          VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @estado_actual VARCHAR(20);
    SELECT @estado_actual = estado_operativo
    FROM FLORERIA_Pedido WHERE pedido_id = @pedido_id;
    
    IF @estado_actual IS NULL
    BEGIN
        SELECT 0 AS ok, 'Pedido no encontrado.' AS mensaje;
        RETURN;
    END
    
    -- Solo cambiar si estaba en PENDIENTE (no retroceder estados)
    IF @estado_actual = 'PENDIENTE'
    BEGIN
        UPDATE FLORERIA_Pedido
        SET estado_operativo = 'IMPRESO',
            modificado_por = @usuario_id,
            modificado_en = GETDATE()
        WHERE pedido_id = @pedido_id;
        
        INSERT INTO FLORERIA_Pedido_Estado_Log
            (pedido_id, estado_anterior, estado_nuevo, observaciones, usuario_id, fecha_hora)
        VALUES
            (@pedido_id, 'PENDIENTE', 'IMPRESO', 'Ticket impreso', @usuario_id, GETDATE());
    END
    ELSE
    BEGIN
        -- Solo registrar el evento sin cambiar estado
        INSERT INTO FLORERIA_Pedido_Estado_Log
            (pedido_id, estado_anterior, estado_nuevo, observaciones, usuario_id, fecha_hora)
        VALUES
            (@pedido_id, @estado_actual, @estado_actual, 'Re-impresion de ticket', @usuario_id, GETDATE());
    END
    
    SELECT 1 AS ok, 'OK' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_ObtenerDetalle]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_Pedido_ObtenerDetalle]
    @pedido_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 1. Datos del pedido
    SELECT
        p.pedido_id,
        p.prepedido_id,
        p.codigo,
        pp.codigo AS prepedido_codigo,
        -- Receptor
        p.receptor_nombre,
        p.receptor_celular,
        p.direccion,
        p.referencia,
        p.latitud,
        p.longitud,
        p.gps,
        -- Ubicacion
        p.ciudad_id,
        c.nombre AS ciudad_nombre,
        p.zona_id,
        z.nombre AS zona_nombre,
        p.sucursal_id,
        p.sucursal_prepara_id,
        p.tipo_entrega,
        -- Fecha y slot
        p.fecha_entrega,
        p.slot_id,
        sh.etiqueta AS slot_etiqueta,
        sh.hora_inicio AS slot_hora_inicio,
        sh.hora_fin AS slot_hora_fin,
        p.es_express,
        -- Tarjeta
        p.dedicatoria,
        p.firma_tarjeta,
        p.tipo_ocacion,
        p.nota_floreria,
        -- Montos
        p.subtotal_productos_bs,
        p.subtotal_productos_usd,
        p.envio_bs,
        p.envio_usd,
        p.recargo_express_bs,
        p.recargo_horario_bs,
        p.descuento_bs,
        p.total_bs,
        p.total_usd,
        p.anticipo_bs,
        p.saldo_bs,
        -- Estados
        p.estado_pago,
        p.estado_operativo,
        p.contactado_cliente,
        p.contactado_en,
        uct.nombres + ' ' + uct.apellidos AS contactado_por_nombre,
        -- WooCommerce
        p.wc_order_id,
        p.wc_order_number,
        p.wc_order_url,
        p.wc_order_status,
        p.wc_payment_method,
        p.wc_payment_method_title,
        p.wc_date_paid,
        p.wc_date_modified,
        -- Delivery actual
        p.delivery_actual_id,
        ud.nombres + ' ' + ud.apellidos AS delivery_nombre,
        ud.celular AS delivery_celular,
        -- Observaciones
        p.observaciones,
        -- Auditoria
        p.creado_en,
        p.modificado_en,
        uc.nombres + ' ' + uc.apellidos AS creado_por_nombre,
        um.nombres + ' ' + um.apellidos AS modificado_por_nombre
    FROM FLORERIA_Pedido p
    LEFT JOIN FLORERIA_PrePedido pp ON p.prepedido_id = pp.prepedido_id
    LEFT JOIN FLORERIA_Ciudad c ON p.ciudad_id = c.ciudad_id
    LEFT JOIN FLORERIA_Zona z ON p.zona_id = z.zona_id
    LEFT JOIN FLORERIA_Slot_Horario sh ON p.slot_id = sh.slot_id
    LEFT JOIN FLORERIA_Usuario ud ON p.delivery_actual_id = ud.usuario_id
    LEFT JOIN FLORERIA_Usuario uc ON p.creado_por = uc.usuario_id
    LEFT JOIN FLORERIA_Usuario um ON p.modificado_por = um.usuario_id
    LEFT JOIN FLORERIA_Usuario uct ON p.contactado_por = uct.usuario_id
    WHERE p.pedido_id = @pedido_id;
    
    -- 2. Productos
    SELECT
        pd.detalle_id,
        pd.producto_id,
        pd.variacion_id,
        pd.es_personalizado,
        pd.nombre_producto,
        pd.descripcion,
        pd.cantidad,
        pd.precio_unitario_bs,
        pd.precio_unitario_usd,
        pd.subtotal_bs,
        pd.subtotal_usd,
        pd.personalizacion
    FROM FLORERIA_Pedido_Detalle pd
    WHERE pd.pedido_id = @pedido_id
    ORDER BY pd.detalle_id ASC;
    
    -- 3. Historial de estados
    SELECT
        l.log_id,
        l.estado_anterior,
        l.estado_nuevo,
        l.observaciones,
        l.usuario_id,
        u.nombres + ' ' + u.apellidos AS usuario_nombre,
        l.fecha_hora
    FROM FLORERIA_Pedido_Estado_Log l
    LEFT JOIN FLORERIA_Usuario u ON l.usuario_id = u.usuario_id
    WHERE l.pedido_id = @pedido_id
    ORDER BY l.fecha_hora ASC;
    
    -- 4. Pagos registrados
    SELECT
        pg.pago_id,
        pg.tipo_pago,
        pg.metodo_pago,
        pg.monto_bs,
        pg.monto_usd,
        pg.referencia,
        pg.estado,
        pg.observaciones,
        pg.verificado_por,
        uv.nombres + ' ' + uv.apellidos AS verificado_por_nombre,
        pg.verificado_en,
        pg.creado_por,
        ucp.nombres + ' ' + ucp.apellidos AS creado_por_nombre,
        pg.creado_en
    FROM FLORERIA_Pedido_Pago pg
    LEFT JOIN FLORERIA_Usuario uv ON pg.verificado_por = uv.usuario_id
    LEFT JOIN FLORERIA_Usuario ucp ON pg.creado_por = ucp.usuario_id
    WHERE pg.pedido_id = @pedido_id
    ORDER BY pg.creado_en ASC;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_ObtenerParaTicket]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_Pedido_ObtenerParaTicket]
    @pedido_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 1. Cabecera
    SELECT
        p.pedido_id,
        p.codigo AS codigo_pedido,
        pp.codigo AS codigo_prepedido,
        p.wc_order_number,
        p.wc_order_id,
        -- Receptor
        p.receptor_nombre,
        p.receptor_celular,
        p.direccion,
        p.referencia,
        p.gps,
        -- Zona / ciudad
        z.nombre AS zona_nombre,
        c.nombre AS ciudad_nombre,
        -- Fecha
        p.fecha_entrega,
        sh.etiqueta AS slot_etiqueta,
        sh.hora_inicio AS slot_hora_inicio,
        sh.hora_fin AS slot_hora_fin,
        p.es_express,
        -- Tarjeta
        p.dedicatoria,
        p.firma_tarjeta,
        p.tipo_ocacion,
        p.nota_floreria,
        -- Montos
        p.subtotal_productos_bs,
        p.envio_bs,
        p.recargo_express_bs,
        p.recargo_horario_bs,
        p.descuento_bs,
        p.total_bs,
        -- Estados
        p.estado_pago,
        p.estado_operativo,
        -- Delivery
        ud.nombres + ' ' + ud.apellidos AS delivery_nombre,
        -- Observaciones
        p.observaciones
    FROM FLORERIA_Pedido p
    LEFT JOIN FLORERIA_PrePedido pp ON p.prepedido_id = pp.prepedido_id
    LEFT JOIN FLORERIA_Zona z ON p.zona_id = z.zona_id
    LEFT JOIN FLORERIA_Ciudad c ON p.ciudad_id = c.ciudad_id
    LEFT JOIN FLORERIA_Slot_Horario sh ON p.slot_id = sh.slot_id
    LEFT JOIN FLORERIA_Usuario ud ON p.delivery_actual_id = ud.usuario_id
    WHERE p.pedido_id = @pedido_id;
    
    -- 2. Productos
    SELECT
        pd.nombre_producto,
        pd.descripcion,
        pd.cantidad,
        pd.precio_unitario_bs,
        pd.subtotal_bs,
        pd.personalizacion
    FROM FLORERIA_Pedido_Detalle pd
    WHERE pd.pedido_id = @pedido_id
    ORDER BY pd.detalle_id ASC;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_Pago_UpsertWC]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_Pedido_Pago_UpsertWC]
    @pedido_id       INT,
    @metodo_pago     VARCHAR(30),
    @monto_bs        DECIMAL(10,2),
    @monto_usd       DECIMAL(10,2) = 0,
    @referencia      VARCHAR(100) = NULL,
    @estado          VARCHAR(20)  = 'PENDIENTE',
    @observaciones   NVARCHAR(500) = NULL,
    @creado_por      INT          = NULL,
    @accion          VARCHAR(10)  OUTPUT,
    @mensaje_error   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @accion = 'ERROR';
    SET @mensaje_error = NULL;

    BEGIN TRY
        -- Validar metodo_pago contra CHECK constraint
        -- Valores permitidos: PIX, YAPE, CRIPTO, PAYPAL, PAGOMOVIL, TRANSFERENCIA, QR, TARJETA, EFECTIVO
        IF @metodo_pago NOT IN ('PIX','YAPE','CRIPTO','PAYPAL','PAGOMOVIL','TRANSFERENCIA','QR','TARJETA','EFECTIVO')
            SET @metodo_pago = 'TRANSFERENCIA';

        -- Validar estado
        IF @estado NOT IN ('PENDIENTE','VERIFICADO','RECHAZADO')
            SET @estado = 'PENDIENTE';

        IF @monto_bs  IS NULL OR @monto_bs  < 0 SET @monto_bs  = 0;
        IF @monto_usd IS NULL OR @monto_usd < 0 SET @monto_usd = 0;

        -- Validar que el pedido exista
        IF NOT EXISTS (SELECT 1 FROM FLORERIA_Pedido WHERE pedido_id = @pedido_id)
        BEGIN
            SET @accion = 'ERROR';
            SET @mensaje_error = 'pedido_id=' + CAST(@pedido_id AS VARCHAR) + ' no existe';
            RETURN;
        END

        -- ¿Ya hay pago para este pedido?
        IF EXISTS (SELECT 1 FROM FLORERIA_Pedido_Pago WHERE pedido_id = @pedido_id)
        BEGIN
            -- UPDATE solo si el nuevo estado mejora (PENDIENTE → VERIFICADO)
            UPDATE FLORERIA_Pedido_Pago
            SET metodo_pago = @metodo_pago,
                monto_bs    = @monto_bs,
                monto_usd   = @monto_usd,
                referencia  = ISNULL(@referencia, referencia),
                estado      = CASE
                                WHEN @estado = 'VERIFICADO' THEN 'VERIFICADO'
                                ELSE estado  -- mantener estado actual si no mejora
                              END,
                observaciones = ISNULL(@observaciones, observaciones)
            WHERE pedido_id = @pedido_id;

            SET @accion = 'UPDATE';
        END
        ELSE
        BEGIN
            INSERT INTO FLORERIA_Pedido_Pago (
                pedido_id, tipo_pago, metodo_pago,
                monto_bs, monto_usd, referencia,
                estado, observaciones, creado_por, creado_en
            )
            VALUES (
                @pedido_id, 'TOTAL', @metodo_pago,
                @monto_bs, @monto_usd, @referencia,
                @estado, @observaciones, @creado_por, GETDATE()
            );

            SET @accion = 'INSERT';
        END

        SET @mensaje_error = NULL;
    END TRY
    BEGIN CATCH
        SET @accion = 'ERROR';
        SET @mensaje_error = LEFT(
            'Pago pedido_id=' + CAST(@pedido_id AS VARCHAR) + ' - ' + ERROR_MESSAGE(),
            500
        );
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Pedido_UpsertWC]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================
-- ALTER sp_Pedido_UpsertWC v2
-- 
-- CAMBIOS RESPECTO A v1:
-- 1. @fecha_entrega ahora es opcional (NULL permitido)
-- 2. En UPDATE: si @fecha_entrega es NULL, NO pisa la fecha en BD
-- 3. En UPDATE: si @slot_id es NULL, NO pisa el slot en BD
-- 4. En UPDATE: si @direccion viene "Sin direccion" o "Recojo en sucursal", solo se pisa si lo de BD es similar
-- 5. En INSERT: si @fecha_entrega es NULL, usa la fecha de hoy como ultimo recurso
-- 
-- Logica clave: en UPDATE solo se actualizan campos que WC realmente envio.
-- Asi las correcciones manuales en SISCONBOL se preservan.
-- ============================================================

CREATE PROCEDURE [dbo].[FLORERIA_sp_Pedido_UpsertWC]
    @wc_order_id              INT,
    @wc_order_number          VARCHAR(50)  = NULL,
    @wc_order_key             VARCHAR(100) = NULL,
    @wc_order_status          VARCHAR(30)  = NULL,
    @wc_date_paid             DATETIME     = NULL,
    @wc_date_modified         DATETIME     = NULL,
    @wc_payment_method        VARCHAR(50)  = NULL,
    @wc_payment_method_title  VARCHAR(100) = NULL,
    @receptor_nombre          VARCHAR(200),
    @receptor_celular         VARCHAR(20),
    @ciudad_id                SMALLINT     = 1,
    @zona_id                  INT          = NULL,
    @slot_id                  SMALLINT     = NULL,
    @sucursal_id              SMALLINT     = NULL,
    @tipo_entrega             VARCHAR(20)  = 'DOMICILIO',
    @direccion                VARCHAR(300) = NULL,
    @referencia               VARCHAR(300) = NULL,
    @fecha_entrega            DATE         = NULL,   -- ahora NULL permitido
    @es_express               BIT          = 0,
    @dedicatoria              NVARCHAR(500) = NULL,
    @firma_tarjeta            VARCHAR(100) = NULL,
    @tipo_ocacion             VARCHAR(30)  = 'OTRO',
    @nota_floreria            NVARCHAR(500) = NULL,
    @gps                      VARCHAR(200) = NULL,
    @observaciones            NVARCHAR(1000) = NULL,
    @total_bs                 DECIMAL(10,2) = 0,
    @total_usd                DECIMAL(10,2) = 0,
    @envio_bs                 DECIMAL(10,2) = 0,
    @envio_usd                DECIMAL(10,2) = 0,
    @descuento_bs             DECIMAL(10,2) = 0,
    @descuento_usd            DECIMAL(10,2) = 0,
    @estado_pago              VARCHAR(20)  = 'PENDIENTE',
    @estado_operativo         VARCHAR(20)  = 'PENDIENTE',
    @creado_por               INT          = NULL,
    @ip                       VARCHAR(50)  = NULL,
    @pedido_id                INT          OUTPUT,
    @codigo                   VARCHAR(20)  OUTPUT,
    @accion                   VARCHAR(10)  OUTPUT,
    @mensaje_error            NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @accion = 'ERROR';
    SET @mensaje_error = NULL;
    SET @pedido_id = 0;
    SET @codigo = NULL;

    BEGIN TRY
        -- Validaciones de CHECK constraints
        IF @estado_pago NOT IN ('PENDIENTE','PAGADO','ANTICIPO','REEMBOLSADO')
            SET @estado_pago = 'PENDIENTE';
        IF @estado_operativo NOT IN ('PENDIENTE','PREPARANDO','EN_CAMINO','ENTREGADO','FALLIDO')
            SET @estado_operativo = 'PENDIENTE';
        IF @tipo_entrega NOT IN ('DOMICILIO','RECOJO_SUCURSAL')
            SET @tipo_entrega = 'DOMICILIO';
        IF @tipo_ocacion NOT IN ('CUMPLEANOS','ANIVERSARIO','AMOR','AGRADECIMIENTO','CONDOLENCIAS','GRADUACION','NACIMIENTO','OTRO')
            SET @tipo_ocacion = 'OTRO';

        -- Defaults
        IF @receptor_nombre  IS NULL OR LTRIM(RTRIM(@receptor_nombre))  = '' SET @receptor_nombre  = 'Sin nombre';
        IF @receptor_celular IS NULL OR LTRIM(RTRIM(@receptor_celular)) = '' SET @receptor_celular = '00000000';

        -- Validar zona y slot
        IF @zona_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM FLORERIA_Zona WHERE zona_id = @zona_id)
            SET @zona_id = NULL;
        IF @slot_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM FLORERIA_Slot_Horario WHERE slot_id = @slot_id)
            SET @slot_id = NULL;

        -- Buscar pedido existente
        SELECT @pedido_id = pedido_id
        FROM FLORERIA_Pedido
        WHERE wc_order_id = @wc_order_id;

        IF @pedido_id IS NOT NULL AND @pedido_id > 0
        BEGIN
            -- =====================================================
            -- UPDATE: actualizar SOLO campos que WC realmente envio
            -- Si un campo viene NULL = WC no lo mando = NO pisar lo de BD
            -- Esto preserva correcciones manuales hechas en SISCONBOL
            -- =====================================================
            UPDATE FLORERIA_Pedido
            SET wc_order_number         = @wc_order_number,
                wc_order_url            = @wc_order_key,
                wc_order_status         = @wc_order_status,
                wc_date_paid            = @wc_date_paid,
                wc_date_modified        = @wc_date_modified,
                wc_payment_method       = @wc_payment_method,
                wc_payment_method_title = @wc_payment_method_title,
                wc_sync_estado          = 'SINCRONIZADO',
                wc_sync_fecha           = GETDATE(),
                estado_pago             = @estado_pago,
                estado_operativo        = @estado_operativo,
                -- Campos que SOLO se actualizan si WC mando un valor real:
                fecha_entrega           = ISNULL(@fecha_entrega, fecha_entrega),
                slot_id                 = ISNULL(@slot_id,       slot_id),
                zona_id                 = ISNULL(@zona_id,       zona_id),
                tipo_entrega            = ISNULL(@tipo_entrega,  tipo_entrega),
                direccion               = CASE
                                            WHEN @direccion IS NULL OR @direccion = '' THEN direccion
                                            WHEN @direccion IN ('Sin direccion','Recojo en sucursal') THEN direccion
                                            ELSE @direccion
                                          END,
                total_bs                = @total_bs,
                total_usd               = @total_usd,
                envio_bs                = @envio_bs,
                envio_usd               = @envio_usd,
                descuento_bs            = @descuento_bs,
                descuento_usd           = @descuento_usd,
                observaciones           = ISNULL(@observaciones, observaciones),
                gps                     = ISNULL(gps, @gps),
                modificado_por          = @creado_por,
                modificado_en           = GETDATE()
            WHERE pedido_id = @pedido_id;

            SELECT @codigo = codigo FROM FLORERIA_Pedido WHERE pedido_id = @pedido_id;
            SET @accion = 'UPDATE';
        END
        ELSE
        BEGIN
            -- =====================================================
            -- INSERT: pedido nuevo
            -- Si @fecha_entrega es NULL aqui (no llego ninguna fecha), 
            -- usamos GETDATE() como ultimo recurso pero marcamos el sync_estado
            -- para que sea facil de identificar
            -- =====================================================
            DECLARE @fechaInsert DATE = ISNULL(@fecha_entrega, CAST(GETDATE() AS DATE));
            DECLARE @direccionInsert VARCHAR(300) = ISNULL(@direccion, 'Sin direccion');
            DECLARE @receptorNombreInsert VARCHAR(200) = ISNULL(@receptor_nombre, 'Sin nombre');
            DECLARE @receptorCelInsert VARCHAR(20) = ISNULL(@receptor_celular, '00000000');

            INSERT INTO FLORERIA_Pedido (
                codigo, wc_order_id, wc_order_number, wc_order_url,
                wc_order_status, wc_date_paid, wc_date_modified,
                wc_payment_method, wc_payment_method_title,
                receptor_nombre, receptor_celular,
                ciudad_id, zona_id, sucursal_id, tipo_entrega,
                direccion, referencia, fecha_entrega, slot_id, es_express,
                dedicatoria, firma_tarjeta, tipo_ocacion, nota_floreria,
                gps, observaciones,
                total_bs, total_usd, envio_bs, envio_usd, descuento_bs, descuento_usd,
                estado_pago, estado_operativo,
                wc_sync_estado, wc_sync_fecha,
                creado_por, creado_en
            )
            VALUES (
                'TEMP', @wc_order_id, @wc_order_number, @wc_order_key,
                @wc_order_status, @wc_date_paid, @wc_date_modified,
                @wc_payment_method, @wc_payment_method_title,
                @receptorNombreInsert, @receptorCelInsert,
                @ciudad_id, @zona_id, @sucursal_id, @tipo_entrega,
                @direccionInsert, @referencia, @fechaInsert, @slot_id, @es_express,
                @dedicatoria, @firma_tarjeta, @tipo_ocacion, @nota_floreria,
                @gps, @observaciones,
                @total_bs, @total_usd, @envio_bs, @envio_usd, @descuento_bs, @descuento_usd,
                @estado_pago, @estado_operativo,
                'SINCRONIZADO', GETDATE(),
                @creado_por, GETDATE()
            );

            SET @pedido_id = SCOPE_IDENTITY();
            SET @codigo    = 'PED-' + RIGHT('000000' + CAST(@pedido_id AS VARCHAR), 6);

            UPDATE FLORERIA_Pedido SET codigo = @codigo WHERE pedido_id = @pedido_id;

            SET @accion = 'INSERT';
        END

        SET @mensaje_error = NULL;
    END TRY
    BEGIN CATCH
        SET @accion = 'ERROR';
        SET @mensaje_error = LEFT(
            'WC#' + CAST(@wc_order_id AS VARCHAR) + ' - ' +
            ERROR_MESSAGE() + ' (linea ' + CAST(ERROR_LINE() AS VARCHAR) + ')',
            500
        );
        SET @pedido_id = 0;
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_PrePedido_ActualizarCliente]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_PrePedido_ActualizarCliente]
    @prepedido_id         INT,
    @cliente_nombre       VARCHAR(200),
    @cliente_apellidos    VARCHAR(200),
    @cliente_email        VARCHAR(100),
    @cliente_pais_id      TINYINT,
    @cliente_ciudad_id    SMALLINT,
    @modificado_por       INT,
    @ip                   VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- ========================================================
    -- VALIDACIONES
    -- ========================================================
    
    -- Validar nombre (solo si no es NULL)
    IF @cliente_nombre IS NOT NULL
    BEGIN
        -- Solo letras, espacios, acentos
        IF @cliente_nombre LIKE '%[^a-zA-ZáéíóúÁÉÍÓÚñÑ ]%'
        BEGIN
            RAISERROR('El nombre solo puede contener letras y espacios', 16, 1);
            RETURN;
        END;

        IF dbo.FLORERIA_fn_ValidarTexto(@cliente_nombre) = 0
        BEGIN
            RAISERROR('El nombre contiene caracteres no permitidos', 16, 1);
            RETURN;
        END;
    END;

    -- Validar apellidos (solo si no es NULL)
    IF @cliente_apellidos IS NOT NULL
    BEGIN
        IF @cliente_apellidos LIKE '%[^a-zA-ZáéíóúÁÉÍÓÚñÑ ]%'
        BEGIN
            RAISERROR('Los apellidos solo pueden contener letras y espacios', 16, 1);
            RETURN;
        END;

        IF dbo.FLORERIA_fn_ValidarTexto(@cliente_apellidos) = 0
        BEGIN
            RAISERROR('Los apellidos contienen caracteres no permitidos', 16, 1);
            RETURN;
        END;
    END;

    -- Validar email (solo si no es NULL)
    IF @cliente_email IS NOT NULL
    BEGIN
        IF @cliente_email NOT LIKE '%@%.%'
        BEGIN
            RAISERROR('El email tiene un formato inválido', 16, 1);
            RETURN;
        END;

        IF dbo.FLORERIA_fn_ValidarTexto(@cliente_email) = 0
        BEGIN
            RAISERROR('El email contiene caracteres no permitidos', 16, 1);
            RETURN;
        END;
    END;

    -- Actualizar
    UPDATE FLORERIA_PrePedido SET
        cliente_nombre     = @cliente_nombre,
        cliente_apellidos  = @cliente_apellidos,
        cliente_email      = @cliente_email,
        cliente_pais_id    = @cliente_pais_id,
        cliente_ciudad_id  = @cliente_ciudad_id,
        modificado_por     = @modificado_por,
        modificado_en      = GETDATE()
    WHERE prepedido_id = @prepedido_id;

    -- Auditoría
    INSERT INTO FLORERIA_Auditoria (usuario_id, ip, tabla, registro_id, accion, valor_nuevo)
    VALUES (@modificado_por, @ip, 'FLORERIA_PrePedido', CAST(@prepedido_id AS VARCHAR), 
            'MODIFICAR', '{"campo":"cliente_datos","detalle":"Actualización de datos del cliente"}');
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_PrePedido_Crear]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_PrePedido_Crear]
    @tipo_registro   VARCHAR(20),
    @cliente_celular VARCHAR(20),
    @agente_id       INT,
    @ip              VARCHAR(50),
    @prepedido_id    INT OUTPUT,
    @codigo          VARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- ========================================================
        -- 1. VALIDACIONES DE SEGURIDAD
        -- ========================================================
        IF dbo.FLORERIA_fn_ValidarCelular(@cliente_celular) = 0
        BEGIN
            RAISERROR('El celular tiene un formato invalido', 16, 1);
            RETURN;
        END;

        IF dbo.FLORERIA_fn_ValidarTexto(@cliente_celular) = 0
        BEGIN
            RAISERROR('El celular contiene caracteres no permitidos', 16, 1);
            RETURN;
        END;

        -- ========================================================
        -- 2. SI YA EXISTE PRE-PEDIDO ACTIVO -> REUTILIZARLO
        -- ========================================================
        DECLARE @existente_id INT = NULL;
        DECLARE @existente_codigo VARCHAR(20) = NULL;
        DECLARE @existente_estado VARCHAR(30) = NULL;

        SELECT TOP 1
            @existente_id     = prepedido_id,
            @existente_codigo = codigo,
            @existente_estado = estado
        FROM FLORERIA_PrePedido
        WHERE cliente_celular = @cliente_celular
          AND estado IN ('BORRADOR', 'FORM_ENVIADO', 'FORM_COMPLETADO',
                         'COMPROBANTE_ENVIADO', 'PAGADO')
        ORDER BY prepedido_id DESC;

        IF @existente_id IS NOT NULL
        BEGIN
            -- Asignar OUTPUT
            SET @prepedido_id = @existente_id;
            SET @codigo       = @existente_codigo;

            -- Devolver resultset con ya_existia = 1
            SELECT
                @existente_id     AS prepedido_id,
                @existente_codigo AS codigo,
                @existente_estado AS estado,
                CAST(1 AS BIT)    AS ya_existia;
            RETURN;
        END;

        -- ========================================================
        -- 3. NO EXISTE -> CREAR NUEVO PRE-PEDIDO
        -- ========================================================
        BEGIN TRANSACTION;

        -- Generar codigo secuencial PRE-XXXXXX
        DECLARE @siguiente INT;
        SELECT @siguiente = ISNULL(MAX(
            CASE WHEN codigo LIKE 'PRE-%'
                 THEN CAST(SUBSTRING(codigo, 5, LEN(codigo)) AS INT)
                 ELSE 0 END
        ), 0) + 1
        FROM FLORERIA_PrePedido;

        SET @codigo = 'PRE-' + RIGHT('000000' + CAST(@siguiente AS VARCHAR), 6);

        -- Determinar estado segun tipo
        DECLARE @estado VARCHAR(30);
        SET @estado = CASE @tipo_registro
            WHEN 'PRE_PEDIDO'    THEN 'BORRADOR'
            WHEN 'VENTA_TIENDA'  THEN 'PAGADO'
            WHEN 'VENTA_ANTIGUA' THEN 'COMPLETADO'
            ELSE 'BORRADOR'
        END;

        -- Insertar pre-pedido nuevo
        INSERT INTO FLORERIA_PrePedido (
            codigo, tipo_registro, cliente_celular,
            estado, token_web,
            total_general_bs, total_general_usd, tasa_cambio,
            descuento_bs, descuento_usd,
            agente_actual_id, creado_por, creado_en
        )
        VALUES (
            @codigo, @tipo_registro, @cliente_celular,
            @estado, NULL,
            0, 0, 7.0000,
            0, 0,
            @agente_id, @agente_id, GETDATE()
        );

        SET @prepedido_id = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        -- Devolver resultset con ya_existia = 0
        SELECT
            prepedido_id,
            codigo,
            estado,
            CAST(0 AS BIT) AS ya_existia
        FROM FLORERIA_PrePedido
        WHERE prepedido_id = @prepedido_id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @err VARCHAR(4000);
        SET @err = ERROR_MESSAGE();
        RAISERROR(@err, 16, 1);
    END CATCH;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_PrePedido_GenerarLink]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_PrePedido_GenerarLink]
    @prepedido_id        INT,
    @moneda_formulario   CHAR(3) = 'BOB',
    @descuento_bs        DECIMAL(10,2) = 0,
    @descuento_motivo    VARCHAR(300) = NULL,
    @modificado_por      INT,
    @ip                  VARCHAR(50),
    @token               VARCHAR(100) OUTPUT,
    @url_completa        VARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @codigo VARCHAR(20);
    
    -- Verificar que el pre-pedido existe
    IF NOT EXISTS (SELECT 1 FROM FLORERIA_PrePedido WHERE prepedido_id = @prepedido_id)
    BEGIN
        RAISERROR('Pre-pedido no encontrado', 16, 1);
        RETURN;
    END
    
    -- Obtener código
    SELECT @codigo = codigo FROM FLORERIA_PrePedido WHERE prepedido_id = @prepedido_id;
    
    -- Generar token único (GUID + GUID = 100 chars sin guiones)
    SET @token = REPLACE(CAST(NEWID() AS VARCHAR(100)), '-', '') + REPLACE(CAST(NEWID() AS VARCHAR(100)), '-', '');
    SET @token = SUBSTRING(@token, 1, 100);
    
    -- Actualizar pre-pedido
    UPDATE FLORERIA_PrePedido
    SET token_web = @token,
        token_expira = DATEADD(HOUR, 48, GETDATE()),
        moneda_formulario = @moneda_formulario,
        descuento_bs = @descuento_bs,
        descuento_motivo = @descuento_motivo,
        estado = CASE 
                    WHEN estado = 'BORRADOR' THEN 'FORM_ENVIADO'
                    ELSE estado 
                 END,
        modificado_por = @modificado_por,
        modificado_en = GETDATE()
    WHERE prepedido_id = @prepedido_id;
    
    -- Construir URL
    SET @url_completa = 'https://miss-flores.com/pedido?t=' + @token + '&m=' + @moneda_formulario;
    
    -- Auditoría (usando valores PERMITIDOS)
    INSERT INTO FLORERIA_Auditoria (
        usuario_id, 
        ip, 
        tabla, 
        registro_id, 
        accion,              -- ✅ DEBE SER: 'INSERTAR', 'MODIFICAR', o 'ELIMINAR'
        valor_nuevo
    )
    VALUES (
        @modificado_por, 
        @ip, 
        'FLORERIA_PrePedido', 
        CAST(@prepedido_id AS VARCHAR), 
        'MODIFICAR',         -- ✅ CORREGIDO: era 'GENERAR_LINK', ahora 'MODIFICAR'
        '{"codigo":"' + @codigo + '","accion":"generar_link","url":"' + @url_completa + '"}'
    );
    
    SELECT @token AS token, @url_completa AS url;
END
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_PrePedido_Listar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================================
-- ALTER: FLORERIA_sp_PrePedido_Listar  v7
-- Novedades vs v6:
--   + estado_operativo_principal (estado_operativo del primer pedido hijo)
--   + pedidos_entregados         (cuántos pedidos hijos ya están ENTREGADOS)
--   + @fecha_entrega_desde / @fecha_entrega_hasta (filtro de fecha entrega)
--   + @estado_operativo_filtro   (PENDIENTE / ENTREGADO / NO_ENTREGADO / NULL=todos)
--   + receptor_nombre, receptor_celular (del primer pedido hijo)
--   + wc_numeros_lista   ("#4518 · #4519")
--   + total_entregas_bs  (SUM real de total_bs de pedidos hijos)
-- =============================================================
CREATE PROCEDURE [dbo].[FLORERIA_sp_PrePedido_Listar]
    @agente_actual_id          INT          = NULL,
    @creado_por_id             INT          = NULL,
    @estado                    VARCHAR(30)  = NULL,
    @tipo_registro             VARCHAR(20)  = NULL,
    @buscar                    VARCHAR(100) = NULL,
    @fecha_entrega_desde       DATE         = NULL,
    @fecha_entrega_hasta       DATE         = NULL,
    @estado_operativo_filtro   VARCHAR(20)  = NULL,
    @pagina                    INT          = 1,
    @por_pagina                INT          = 20,
    @total_registros           INT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @offset INT = (@pagina - 1) * @por_pagina;

    -- ---- Contar total (aplicando todos los filtros) ----
    SELECT @total_registros = COUNT(*)
    FROM FLORERIA_PrePedido pp
    WHERE (@agente_actual_id IS NULL OR pp.agente_actual_id = @agente_actual_id)
      AND (@creado_por_id    IS NULL OR pp.creado_por       = @creado_por_id)
      AND (@estado           IS NULL OR pp.estado           = @estado)
      AND (@tipo_registro    IS NULL OR pp.tipo_registro    = @tipo_registro)
      AND (
          @buscar IS NULL
          OR pp.codigo            LIKE '%' + @buscar + '%'
          OR pp.cliente_celular   LIKE '%' + @buscar + '%'
          OR pp.cliente_nombre    LIKE '%' + @buscar + '%'
          OR pp.cliente_apellidos LIKE '%' + @buscar + '%'
      )
      -- Filtro fecha entrega: existe al menos 1 pedido hijo con fecha en rango
      AND (
          @fecha_entrega_desde IS NULL AND @fecha_entrega_hasta IS NULL
          OR EXISTS (
              SELECT 1 FROM FLORERIA_Pedido p
              WHERE p.prepedido_id = pp.prepedido_id
                AND (@fecha_entrega_desde IS NULL OR p.fecha_entrega >= @fecha_entrega_desde)
                AND (@fecha_entrega_hasta IS NULL OR p.fecha_entrega <= @fecha_entrega_hasta)
          )
      )
      -- Filtro estado operativo
      AND (
          @estado_operativo_filtro IS NULL
          OR (
              @estado_operativo_filtro = 'PENDIENTE' AND EXISTS (
                  SELECT 1 FROM FLORERIA_Pedido p
                  WHERE p.prepedido_id = pp.prepedido_id
                    AND p.estado_operativo NOT IN ('ENTREGADO','NO_ENTREGADO')
              )
          )
          OR (
              @estado_operativo_filtro = 'ENTREGADO' AND EXISTS (
                  SELECT 1 FROM FLORERIA_Pedido p
                  WHERE p.prepedido_id = pp.prepedido_id
                    AND p.estado_operativo = 'ENTREGADO'
              )
          )
          OR (
              @estado_operativo_filtro = 'NO_ENTREGADO' AND EXISTS (
                  SELECT 1 FROM FLORERIA_Pedido p
                  WHERE p.prepedido_id = pp.prepedido_id
                    AND p.estado_operativo = 'NO_ENTREGADO'
              )
          )
      );

    -- ---- Página ----
    SELECT
        pp.prepedido_id,
        pp.codigo,
        pp.tipo_registro,
        pp.cliente_celular,
        pp.cliente_nombre,
        pp.cliente_apellidos,
        pp.cliente_email,
        pp.estado,
        pp.total_general_bs,
        pp.total_general_usd,
        pp.moneda_formulario,
        pp.token_web,
        pp.token_expira,
        pp.creado_en,
        pp.modificado_en,
        ua.nombres + ' ' + ua.apellidos AS agente_nombre,
        uc.nombres + ' ' + uc.apellidos AS creador_nombre,

        ISNULL(
            (SELECT TOP 1 fpag.estado
             FROM FLORERIA_Pedido_Pago fpag
             WHERE fpag.prepedido_id = pp.prepedido_id
             ORDER BY fpag.pago_id DESC),
            'SIN_PAGO'
        ) AS estado_pago,

        ISNULL(
            (SELECT TOP 1 uv.nombres + ' ' + uv.apellidos
             FROM FLORERIA_Pedido_Pago fpag2
             INNER JOIN FLORERIA_Usuario uv ON fpag2.verificado_por = uv.usuario_id
             WHERE fpag2.prepedido_id = pp.prepedido_id
               AND fpag2.estado = 'VERIFICADO'
             ORDER BY fpag2.pago_id DESC),
            NULL
        ) AS pago_verificado_por,

        (SELECT MIN(p.fecha_entrega)
         FROM FLORERIA_Pedido p
         WHERE p.prepedido_id = pp.prepedido_id) AS fecha_entrega_min,

        (SELECT COUNT(*)
         FROM FLORERIA_Pedido p
         WHERE p.prepedido_id = pp.prepedido_id) AS cantidad_pedidos,

        (SELECT TOP 1 p.pedido_id
         FROM FLORERIA_Pedido p
         WHERE p.prepedido_id = pp.prepedido_id
         ORDER BY p.pedido_id) AS pedido_id_principal,

        (SELECT TOP 1 p.wc_order_id
         FROM FLORERIA_Pedido p
         WHERE p.prepedido_id = pp.prepedido_id
         ORDER BY p.pedido_id) AS wc_order_id_principal,

        (SELECT TOP 1 p.wc_order_number
         FROM FLORERIA_Pedido p
         WHERE p.prepedido_id = pp.prepedido_id
         ORDER BY p.pedido_id) AS wc_order_number_principal,

        (SELECT COUNT(*)
         FROM FLORERIA_Pedido p
         WHERE p.prepedido_id = pp.prepedido_id
           AND p.wc_order_id IS NOT NULL) AS pedidos_wc_sync,

        -- *** v6 ***
        (SELECT TOP 1 p.receptor_nombre
         FROM FLORERIA_Pedido p
         WHERE p.prepedido_id = pp.prepedido_id
         ORDER BY p.pedido_id) AS receptor_nombre,

        (SELECT TOP 1 p.receptor_celular
         FROM FLORERIA_Pedido p
         WHERE p.prepedido_id = pp.prepedido_id
         ORDER BY p.pedido_id) AS receptor_celular,

        (SELECT STRING_AGG('#' + p.wc_order_number, ' · ')
             WITHIN GROUP (ORDER BY p.pedido_id)
         FROM FLORERIA_Pedido p
         WHERE p.prepedido_id = pp.prepedido_id
           AND p.wc_order_number IS NOT NULL) AS wc_numeros_lista,

        ISNULL(
            (SELECT SUM(p.total_bs)
             FROM FLORERIA_Pedido p
             WHERE p.prepedido_id = pp.prepedido_id),
            0
        ) AS total_entregas_bs,

        -- *** v7 ***
        (SELECT TOP 1 p.estado_operativo
         FROM FLORERIA_Pedido p
         WHERE p.prepedido_id = pp.prepedido_id
         ORDER BY p.pedido_id) AS estado_operativo_principal,

        (SELECT COUNT(*)
         FROM FLORERIA_Pedido p
         WHERE p.prepedido_id = pp.prepedido_id
           AND p.estado_operativo = 'ENTREGADO') AS pedidos_entregados

    FROM FLORERIA_PrePedido pp
    INNER JOIN FLORERIA_Usuario ua ON pp.agente_actual_id = ua.usuario_id
    INNER JOIN FLORERIA_Usuario uc ON pp.creado_por       = uc.usuario_id
    WHERE (@agente_actual_id IS NULL OR pp.agente_actual_id = @agente_actual_id)
      AND (@creado_por_id    IS NULL OR pp.creado_por       = @creado_por_id)
      AND (@estado           IS NULL OR pp.estado           = @estado)
      AND (@tipo_registro    IS NULL OR pp.tipo_registro    = @tipo_registro)
      AND (
          @buscar IS NULL
          OR pp.codigo            LIKE '%' + @buscar + '%'
          OR pp.cliente_celular   LIKE '%' + @buscar + '%'
          OR pp.cliente_nombre    LIKE '%' + @buscar + '%'
          OR pp.cliente_apellidos LIKE '%' + @buscar + '%'
      )
      AND (
          @fecha_entrega_desde IS NULL AND @fecha_entrega_hasta IS NULL
          OR EXISTS (
              SELECT 1 FROM FLORERIA_Pedido p
              WHERE p.prepedido_id = pp.prepedido_id
                AND (@fecha_entrega_desde IS NULL OR p.fecha_entrega >= @fecha_entrega_desde)
                AND (@fecha_entrega_hasta IS NULL OR p.fecha_entrega <= @fecha_entrega_hasta)
          )
      )
      AND (
          @estado_operativo_filtro IS NULL
          OR (
              @estado_operativo_filtro = 'PENDIENTE' AND EXISTS (
                  SELECT 1 FROM FLORERIA_Pedido p
                  WHERE p.prepedido_id = pp.prepedido_id
                    AND p.estado_operativo NOT IN ('ENTREGADO','NO_ENTREGADO')
              )
          )
          OR (
              @estado_operativo_filtro = 'ENTREGADO' AND EXISTS (
                  SELECT 1 FROM FLORERIA_Pedido p
                  WHERE p.prepedido_id = pp.prepedido_id
                    AND p.estado_operativo = 'ENTREGADO'
              )
          )
          OR (
              @estado_operativo_filtro = 'NO_ENTREGADO' AND EXISTS (
                  SELECT 1 FROM FLORERIA_Pedido p
                  WHERE p.prepedido_id = pp.prepedido_id
                    AND p.estado_operativo = 'NO_ENTREGADO'
              )
          )
      )
    ORDER BY pp.prepedido_id DESC
    OFFSET @offset ROWS
    FETCH NEXT @por_pagina ROWS ONLY;

END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_PrePedido_ListarRecientes]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_PrePedido_ListarRecientes]
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
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_PrePedido_ObtenerPorToken]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- SP 4: FLORERIA_sp_PrePedido_ObtenerPorToken
-- Descripción: Obtener pre-pedido para formulario web
-- =============================================
CREATE   PROCEDURE [dbo].[FLORERIA_sp_PrePedido_ObtenerPorToken]
    @token VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar token existe
    IF NOT EXISTS (SELECT 1 FROM FLORERIA_PrePedido WHERE token_web = @token)
    BEGIN
        RAISERROR('Token inválido', 16, 1);
        RETURN;
    END
    
    -- Validar no expiró
    IF EXISTS (SELECT 1 FROM FLORERIA_PrePedido WHERE token_web = @token AND token_expira < GETDATE())
    BEGIN
        -- Cambiar estado a EXPIRADO
        UPDATE FLORERIA_PrePedido SET estado = 'EXPIRADO' WHERE token_web = @token;
        RAISERROR('El link ha expirado. Contacte al vendedor.', 16, 1);
        RETURN;
    END
    
    -- Validar estado permite edición
    DECLARE @estado VARCHAR(30);
    SELECT @estado = estado FROM FLORERIA_PrePedido WHERE token_web = @token;
    
    IF @estado NOT IN ('FORM_ENVIADO', 'FORM_COMPLETADO', 'COMPROBANTE_ENVIADO')
    BEGIN
        RAISERROR('Este pre-pedido ya no puede ser editado', 16, 1);
        RETURN;
    END
    
    -- RESULTSET 1: Datos del pre-pedido
    SELECT 
        pp.prepedido_id,
        pp.codigo,
        pp.tipo_registro,
        pp.cliente_celular,
        pp.cliente_nombre,
        pp.cliente_apellidos,
        pp.cliente_email,
        pp.cliente_pais_id,
        pp.cliente_ciudad_id,
        pp.estado,
        pp.total_general_bs,
        pp.total_general_usd,
        pp.tasa_cambio,
        pp.moneda_formulario,
        pp.descuento_bs,
        pp.descuento_usd,
        pp.descuento_motivo,
        pp.token_expira,
        pp.fecha_limite_pago,
        -- Datos del agente
        u.nombres + ' ' + u.apellidos AS agente_nombre,
        u.celular AS agente_celular
    FROM FLORERIA_PrePedido pp
    INNER JOIN FLORERIA_Usuario u ON pp.agente_actual_id = u.usuario_id
    WHERE pp.token_web = @token;
    
    -- RESULTSET 2: Pedidos del pre-pedido
    SELECT 
        p.pedido_id,
        p.codigo,
        p.receptor_nombre,
        p.receptor_celular,
        p.ciudad_id,
        p.zona_id,
        p.sucursal_id,
        p.tipo_entrega,
        p.direccion,
        p.referencia,
        p.fecha_entrega,
        p.slot_id,
        p.es_express,
        p.dedicatoria,
        p.firma_tarjeta,
        p.subtotal_productos_bs,
        p.envio_bs,
        p.total_bs,
        -- Datos de zona
        z.nombre AS zona_nombre,
        z.codigo AS zona_codigo,
        -- Datos de slot
        s.etiqueta AS slot_etiqueta,
        s.hora_inicio,
        s.hora_fin
    FROM FLORERIA_Pedido p
    LEFT JOIN FLORERIA_Zona z ON p.zona_id = z.zona_id
    LEFT JOIN FLORERIA_Slot_Horario s ON p.slot_id = s.slot_id
    WHERE p.prepedido_id = (SELECT prepedido_id FROM FLORERIA_PrePedido WHERE token_web = @token)
    ORDER BY p.pedido_id;
    
    -- RESULTSET 3: Productos por pedido
    SELECT 
        pd.detalle_id,
        pd.pedido_id,
        pd.producto_id,
        pd.variacion_id,
        pd.es_personalizado,
        pd.nombre_producto,
        pd.descripcion,
        pd.cantidad,
        pd.precio_unitario_bs,
        pd.subtotal_bs,
        pd.personalizacion,
        -- Datos del producto
        p.sku,
        p.imagen_url
    FROM FLORERIA_Pedido_Detalle pd
    LEFT JOIN FLORERIA_Producto p ON pd.producto_id = p.producto_id
    WHERE pd.pedido_id IN (
        SELECT pedido_id FROM FLORERIA_Pedido 
        WHERE prepedido_id = (SELECT prepedido_id FROM FLORERIA_PrePedido WHERE token_web = @token)
    )
    ORDER BY pd.pedido_id, pd.detalle_id;
    
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_PrePedido_RecalcularEstado]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================================
-- SP: FLORERIA_sp_PrePedido_RecalcularEstado  v2
-- Calcula y actualiza el estado del PrePedido automáticamente
-- según los datos reales en BD.
--
-- Considera AMBOS flujos del sistema:
--   - Flujo borrador: FLORERIA_PrePedido_Entrega + ..._Entrega_Pago
--   - Flujo final:    FLORERIA_Pedido + FLORERIA_Pedido_Pago
--
-- Lógica (en orden de prioridad):
--   1. Si está CANCELADO o EXPIRADO → no tocar
--   2. CONVERTIDO    → algún pedido hijo tiene wc_order_id
--   3. PAGADO        → pago VERIFICADO (en cualquiera de las 2 tablas de pago)
--   4. ESPERANDO_PAGO→ pago PENDIENTE (en cualquiera de las 2 tablas de pago)
--   5. COMPLETADO    → existe pedido o entrega con receptor + fecha_entrega
--   6. FORM_ENVIADO  → tiene token_web activo
--   7. BORRADOR      → ninguna condición anterior
-- =============================================================
CREATE   PROCEDURE [dbo].[FLORERIA_sp_PrePedido_RecalcularEstado]
    @prepedido_id   INT,
    @modificado_por INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM FLORERIA_PrePedido WHERE prepedido_id = @prepedido_id)
    BEGIN
        RAISERROR('PrePedido no encontrado: %d', 16, 1, @prepedido_id);
        RETURN;
    END

    -- No recalcular si está CANCELADO o EXPIRADO
    IF EXISTS (
        SELECT 1 FROM FLORERIA_PrePedido
        WHERE prepedido_id = @prepedido_id
          AND estado IN ('CANCELADO','EXPIRADO')
    ) RETURN;

    DECLARE @nuevo_estado VARCHAR(30);

    SELECT @nuevo_estado =
        CASE
            -- 1. Algún pedido hijo (final) tiene WC → CONVERTIDO
            WHEN EXISTS (
                SELECT 1 FROM FLORERIA_Pedido p
                WHERE p.prepedido_id = @prepedido_id
                  AND p.wc_order_id IS NOT NULL
            ) THEN 'CONVERTIDO'

            -- 2. Pago verificado en cualquiera de las 2 tablas → PAGADO
            WHEN EXISTS (
                SELECT 1 FROM FLORERIA_Pedido_Pago pp
                WHERE pp.prepedido_id = @prepedido_id
                  AND pp.estado = 'VERIFICADO'
            )
              OR EXISTS (
                SELECT 1
                FROM FLORERIA_PrePedido_Entrega_Pago pep
                INNER JOIN FLORERIA_PrePedido_Entrega pe
                        ON pep.prepedido_entrega_id = pe.prepedido_entrega_id
                WHERE pe.prepedido_id = @prepedido_id
                  AND pep.estado = 'VERIFICADO'
            ) THEN 'PAGADO'

            -- 3. Pago pendiente de verificar → ESPERANDO_PAGO
            WHEN EXISTS (
                SELECT 1 FROM FLORERIA_Pedido_Pago pp
                WHERE pp.prepedido_id = @prepedido_id
                  AND pp.estado = 'PENDIENTE'
            )
              OR EXISTS (
                SELECT 1
                FROM FLORERIA_PrePedido_Entrega_Pago pep
                INNER JOIN FLORERIA_PrePedido_Entrega pe
                        ON pep.prepedido_entrega_id = pe.prepedido_entrega_id
                WHERE pe.prepedido_id = @prepedido_id
                  AND pep.estado = 'PENDIENTE'
            ) THEN 'ESPERANDO_PAGO'

            -- 4. Existe pedido final o entrega borrador con receptor + fecha → COMPLETADO
            WHEN EXISTS (
                SELECT 1 FROM FLORERIA_Pedido p
                WHERE p.prepedido_id = @prepedido_id
                  AND p.receptor_nombre IS NOT NULL
                  AND p.receptor_nombre <> ''
                  AND p.receptor_nombre <> 'Sin nombre'
                  AND p.fecha_entrega IS NOT NULL
            )
              OR EXISTS (
                SELECT 1 FROM FLORERIA_PrePedido_Entrega pe
                WHERE pe.prepedido_id = @prepedido_id
                  AND pe.receptor_nombre IS NOT NULL
                  AND pe.receptor_nombre <> ''
                  AND pe.fecha_entrega IS NOT NULL
            ) THEN 'COMPLETADO'

            -- 5. Token web vigente → FORM_ENVIADO
            WHEN EXISTS (
                SELECT 1 FROM FLORERIA_PrePedido
                WHERE prepedido_id = @prepedido_id
                  AND token_web IS NOT NULL
                  AND token_expira > GETDATE()
            ) THEN 'FORM_ENVIADO'

            -- 6. Nada → BORRADOR
            ELSE 'BORRADOR'
        END;

    UPDATE FLORERIA_PrePedido
    SET estado         = @nuevo_estado,
        modificado_por = ISNULL(@modificado_por, modificado_por),
        modificado_en  = GETDATE()
    WHERE prepedido_id = @prepedido_id
      AND estado <> @nuevo_estado;

    SELECT @nuevo_estado AS estado_nuevo,
           @prepedido_id AS prepedido_id;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_PrePedidoEntrega_Confirmar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================================
-- FIX: FLORERIA_sp_PrePedidoEntrega_Confirmar
-- Cambios respecto a la versión anterior:
--
--   1. Bug CHECK constraint (CRÍTICO - rompía la confirmación):
--      Antes: estado_pago = 'PARCIAL' (no permitido)
--      Ahora: estado_pago = 'ANTICIPO' (permitido por CK_FLORERIA_Pedido_EstadoPago)
--
--   2. Total real (CRÍTICO - guardaba menos que el frontend mostraba):
--      Antes: total = subtotal - descuento
--      Ahora: total = subtotal + envio + recargo_horario - descuento
--      (NOTA: recargo_express ya no se suma porque el recargo express
--       ya viene incluido dentro del recargo_horario del slot)
--
--   3. Recargos reales (antes se guardaban en cero):
--      Lee envío desde FLORERIA_Zona_Tarifa (último vigente)
--      Lee recargo_horario desde FLORERIA_Slot_Horario
--      Los guarda en envio_bs y recargo_horario_bs respectivamente
--      recargo_express_bs se deja en 0 (ya está en el slot)
--
-- EJECUTAR EN SSMS sobre la base de datos SISCONBOL.
-- Es un ALTER PROCEDURE: reemplaza el SP existente sin tocar permisos.
-- ============================================================

CREATE PROCEDURE [dbo].[FLORERIA_sp_PrePedidoEntrega_Confirmar]
    @prepedido_entrega_id   INT,
    @usuario_id             INT,
    @pedido_id              INT OUTPUT,
    @codigo                 VARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar borrador
    IF NOT EXISTS (SELECT 1 FROM FLORERIA_PrePedido_Entrega
                   WHERE prepedido_entrega_id = @prepedido_entrega_id
                     AND estado = 'BORRADOR')
    BEGIN
        RAISERROR('El borrador no existe o ya fue confirmado', 16, 1);
        RETURN;
    END

    -- Leer datos del borrador
    DECLARE
        @prepedido_id        INT,
        @receptor_nombre     VARCHAR(200),
        @receptor_celular    VARCHAR(20),
        @ciudad_id           SMALLINT,
        @zona_id             INT,
        @sucursal_id         SMALLINT,
        @tipo_entrega        VARCHAR(20),
        @direccion           VARCHAR(300),
        @referencia          VARCHAR(300),
        @gps                 VARCHAR(300),
        @fecha_entrega       DATE,
        @slot_id             SMALLINT,
        @es_express          BIT,
        @dedicatoria         NVARCHAR(500),
        @firma_tarjeta       VARCHAR(100),
        @tipo_ocacion        VARCHAR(30),
        @sucursal_prepara_id SMALLINT,
        @descuento_valor     DECIMAL(10,2),
        @descuento_moneda    CHAR(3),
        @nota_floreria       NVARCHAR(500);

    SELECT
        @prepedido_id        = prepedido_id,
        @receptor_nombre     = ISNULL(receptor_nombre, ''),
        @receptor_celular    = ISNULL(receptor_celular, ''),
        @ciudad_id           = ciudad_id,
        @zona_id             = zona_id,
        @sucursal_id         = sucursal_id,
        @tipo_entrega        = tipo_entrega,
        @direccion           = direccion,
        @referencia          = referencia,
        @gps                 = gps,
        @fecha_entrega       = fecha_entrega,
        @slot_id             = slot_id,
        @es_express          = es_express,
        @dedicatoria         = dedicatoria,
        @firma_tarjeta       = firma_tarjeta,
        @tipo_ocacion        = tipo_ocacion,
        @sucursal_prepara_id = sucursal_prepara_id,
        @descuento_valor     = descuento_valor,
        @descuento_moneda    = descuento_moneda,
        @nota_floreria       = nota_floreria
    FROM FLORERIA_PrePedido_Entrega
    WHERE prepedido_entrega_id = @prepedido_entrega_id;

    -- Validaciones minimas
    IF @receptor_nombre = '' OR @receptor_celular = ''
    BEGIN
        RAISERROR('Faltan datos del destinatario (nombre o celular)', 16, 1);
        RETURN;
    END
    IF @ciudad_id IS NULL
    BEGIN
        RAISERROR('Falta seleccionar ciudad', 16, 1);
        RETURN;
    END
    IF @tipo_entrega = 'DOMICILIO' AND @zona_id IS NULL
    BEGIN
        RAISERROR('Para entrega a domicilio debe especificar la zona', 16, 1);
        RETURN;
    END
    IF @tipo_entrega = 'RECOJO_SUCURSAL' AND @sucursal_id IS NULL
    BEGIN
        RAISERROR('Para recojo en sucursal debe especificar la sucursal', 16, 1);
        RETURN;
    END
    IF @fecha_entrega IS NULL OR @fecha_entrega < CAST(GETDATE() AS DATE)
    BEGIN
        RAISERROR('La fecha de entrega es invalida', 16, 1);
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM FLORERIA_PrePedido_Entrega_Detalle
                   WHERE prepedido_entrega_id = @prepedido_entrega_id)
    BEGIN
        RAISERROR('La entrega no tiene productos', 16, 1);
        RETURN;
    END

    -- Descuento -> separar en BS / USD segun moneda
    DECLARE @desc_bs DECIMAL(10,2) = 0;
    DECLARE @desc_usd DECIMAL(10,2) = 0;
    IF @descuento_valor > 0
    BEGIN
        IF @descuento_moneda = 'USD'
            SET @desc_usd = @descuento_valor;
        ELSE
            SET @desc_bs = @descuento_valor;
    END

    -- ============================================================
    -- *** FIX #2 y #3: Calcular envío y recargo horario reales ***
    -- ============================================================

    -- Envío en BS (último precio vigente para la zona)
    DECLARE @envio_bs DECIMAL(10,2) = 0;
    IF @tipo_entrega = 'DOMICILIO' AND @zona_id IS NOT NULL
    BEGIN
        SELECT TOP 1 @envio_bs = ISNULL(precio_bs, 0)
        FROM FLORERIA_Zona_Tarifa
        WHERE zona_id = @zona_id
        ORDER BY vigente_desde DESC;
        SET @envio_bs = ISNULL(@envio_bs, 0);
    END

    -- Recargo horario en BS (recargo_bs del slot, ya incluye express)
    DECLARE @recargo_horario_bs DECIMAL(10,2) = 0;
    IF @slot_id IS NOT NULL AND @slot_id > 0
    BEGIN
        SELECT @recargo_horario_bs = ISNULL(recargo_bs, 0)
        FROM FLORERIA_Slot_Horario
        WHERE slot_id = @slot_id;
        SET @recargo_horario_bs = ISNULL(@recargo_horario_bs, 0);
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Generar codigo PED-XXXXXX
        DECLARE @ultimo_numero INT;
        SELECT @ultimo_numero = ISNULL(MAX(CAST(SUBSTRING(codigo, 5, 6) AS INT)), 0)
        FROM FLORERIA_Pedido
        WHERE codigo LIKE 'PED-%';

        SET @codigo = 'PED-' + RIGHT('000000' + CAST(@ultimo_numero + 1 AS VARCHAR), 6);

        -- Calcular subtotales del detalle
        DECLARE
            @subtotal_bs   DECIMAL(10,2) = 0,
            @subtotal_usd  DECIMAL(10,2) = 0;

        SELECT
            @subtotal_bs  = ISNULL(SUM(subtotal_bs),  0),
            @subtotal_usd = ISNULL(SUM(subtotal_usd), 0)
        FROM FLORERIA_PrePedido_Entrega_Detalle
        WHERE prepedido_entrega_id = @prepedido_entrega_id;

        -- Calcular anticipo (suma de pagos VERIFICADOS en borrador, solo BS)
        DECLARE @anticipo_bs DECIMAL(10,2) = 0;
        SELECT @anticipo_bs = ISNULL(SUM(monto_bs), 0)
        FROM FLORERIA_PrePedido_Entrega_Pago
        WHERE prepedido_entrega_id = @prepedido_entrega_id
          AND estado = 'VERIFICADO';

        -- ============================================================
        -- *** FIX #2: Total REAL incluyendo envío y horario ***
        -- ============================================================
        DECLARE @total_bs DECIMAL(10,2) = @subtotal_bs + @envio_bs + @recargo_horario_bs - @desc_bs;
        IF @total_bs < 0 SET @total_bs = 0;

        DECLARE @total_usd DECIMAL(10,2) = @subtotal_usd - @desc_usd;
        IF @total_usd < 0 SET @total_usd = 0;

        DECLARE @saldo_bs DECIMAL(10,2) = @total_bs - @anticipo_bs;
        IF @saldo_bs < 0 SET @saldo_bs = 0;

        -- INSERT FLORERIA_Pedido
        INSERT INTO FLORERIA_Pedido (
            prepedido_id, codigo, receptor_nombre, receptor_celular,
            ciudad_id, zona_id, sucursal_id, tipo_entrega,
            direccion, referencia, gps,
            fecha_entrega, slot_id, es_express,
            dedicatoria, firma_tarjeta, tipo_ocacion,
            sucursal_prepara_id, nota_floreria,
            subtotal_productos_bs, subtotal_productos_usd,
            envio_bs, envio_usd,
            recargo_express_bs, recargo_express_usd,
            recargo_horario_bs, recargo_horario_usd,
            descuento_bs, descuento_usd, descuento_moneda,
            total_bs, total_usd,
            anticipo_bs, saldo_bs, estado_pago,
            wc_sync_estado, creado_por, creado_en
        )
        VALUES (
            @prepedido_id, @codigo, @receptor_nombre, @receptor_celular,
            @ciudad_id, @zona_id, @sucursal_id, @tipo_entrega,
            @direccion, @referencia, @gps,
            @fecha_entrega, @slot_id, @es_express,
            @dedicatoria, @firma_tarjeta, @tipo_ocacion,
            @sucursal_prepara_id, @nota_floreria,
            @subtotal_bs, @subtotal_usd,
            @envio_bs, 0,                                  -- *** FIX #3: envío real (era 0) ***
            0, 0,                                          -- recargo_express queda 0 (incluido en horario)
            @recargo_horario_bs, 0,                        -- *** FIX #3: recargo horario real (era 0) ***
            @desc_bs, @desc_usd, @descuento_moneda,
            @total_bs, @total_usd,                         -- *** FIX #2: total real ***
            @anticipo_bs, @saldo_bs,
            CASE
                WHEN @anticipo_bs >= @total_bs THEN 'PAGADO'
                WHEN @anticipo_bs > 0 THEN 'ANTICIPO'       -- *** FIX #1: era 'PARCIAL' (rompía CHECK) ***
                ELSE 'PENDIENTE'
            END,
            'PENDIENTE', @usuario_id, GETDATE()
        );

        SET @pedido_id = SCOPE_IDENTITY();

        -- Copiar detalle
        INSERT INTO FLORERIA_Pedido_Detalle (
            pedido_id, producto_id, variacion_id, es_personalizado,
            nombre_producto, descripcion, cantidad,
            precio_unitario_bs, precio_unitario_usd,
            subtotal_bs, subtotal_usd, personalizacion, creado_en
        )
        SELECT
            @pedido_id, producto_id, variacion_id, es_personalizado,
            nombre_producto, descripcion, cantidad,
            precio_unitario_bs, precio_unitario_usd,
            subtotal_bs, subtotal_usd, personalizacion, GETDATE()
        FROM FLORERIA_PrePedido_Entrega_Detalle
        WHERE prepedido_entrega_id = @prepedido_entrega_id;

        -- Copiar pagos (estructura real: monto_bs/monto_usd/estado/tipo_pago)
        INSERT INTO FLORERIA_Pedido_Pago (
            pedido_id, prepedido_id, tipo_pago, metodo_pago,
            monto_bs, monto_usd,
            referencia, comprobante_url,
            estado, verificado_por, verificado_en,
            observaciones, creado_por, creado_en
        )
        SELECT
            @pedido_id, @prepedido_id, tipo_pago, metodo_pago,
            monto_bs, monto_usd,
            referencia, comprobante_url,
            estado, verificado_por, verificado_en,
            observaciones, creado_por, creado_en
        FROM FLORERIA_PrePedido_Entrega_Pago
        WHERE prepedido_entrega_id = @prepedido_entrega_id;

        -- Marcar borrador como CONFIRMADO
        UPDATE FLORERIA_PrePedido_Entrega
        SET estado          = 'CONFIRMADO',
            pedido_id       = @pedido_id,
            confirmado_en   = GETDATE(),
            modificado_por  = @usuario_id,
            modificado_en   = GETDATE()
        WHERE prepedido_entrega_id = @prepedido_entrega_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @err VARCHAR(4000);
        SET @err = ERROR_MESSAGE();
        RAISERROR(@err, 16, 1);
    END CATCH;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_PrePedidoEntrega_CrearBorrador]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================
-- PASO 6: CREAR SP FLORERIA_sp_PrePedidoEntrega_CrearBorrador
-- ============================================================
CREATE PROCEDURE [dbo].[FLORERIA_sp_PrePedidoEntrega_CrearBorrador]
    @prepedido_id           INT,
    @creado_por             INT,
    @prepedido_entrega_id   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM FLORERIA_PrePedido WHERE prepedido_id = @prepedido_id)
    BEGIN
        RAISERROR('El pre-pedido no existe', 16, 1);
        RETURN;
    END

    DECLARE @fecha_default DATE = DATEADD(DAY, 2, CAST(GETDATE() AS DATE));

    INSERT INTO FLORERIA_PrePedido_Entrega (
        prepedido_id, estado, tipo_entrega, fecha_entrega,
        moneda, descuento_valor, descuento_moneda,
        creado_por, creado_en
    )
    VALUES (
        @prepedido_id, 'BORRADOR', 'DOMICILIO', @fecha_default,
        'BOB', 0, 'BOB',
        @creado_por, GETDATE()
    );

    SET @prepedido_entrega_id = SCOPE_IDENTITY();
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Producto_Actualizar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP: Actualizar producto
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Producto_Actualizar]
    @producto_id       INT,
    @sku               VARCHAR(50),
    @nombre            VARCHAR(200),
    @descripcion       NVARCHAR(MAX),
    @categoria_id      INT,
    @precio_base_bs    DECIMAL(10,2),
    @precio_base_usd   DECIMAL(10,2),
    @precio_promo_bs   DECIMAL(10,2),
    @precio_promo_usd  DECIMAL(10,2),
    @promo_desde       DATE,
    @promo_hasta       DATE,
    @tiene_variaciones BIT,
    @destacado         BIT,
    @menu_order        INT,
    @notas_internas    NVARCHAR(500),
    @stock_actual      INT,
    @stock_minimo      INT,
    @modificado_por    INT,
    @motivo            VARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM FLORERIA_Producto
               WHERE sku = @sku AND producto_id <> @producto_id)
    BEGIN
        SELECT 0 AS ok, 'Ya existe otro producto con ese SKU.' AS mensaje;
        RETURN;
    END;

    IF @precio_promo_bs IS NOT NULL AND @precio_promo_bs >= @precio_base_bs
    BEGIN
        SELECT 0 AS ok, 'El precio promocional debe ser menor al precio base.' AS mensaje;
        RETURN;
    END;

    DECLARE @anterior NVARCHAR(MAX);
    SELECT @anterior = '{"sku":"' + sku + '","precio_bs":"' + CAST(precio_base_bs AS VARCHAR) + '"}'
    FROM FLORERIA_Producto WHERE producto_id = @producto_id;

    UPDATE FLORERIA_Producto SET
        sku                = @sku,
        nombre             = @nombre,
        descripcion        = NULLIF(@descripcion,''),
        categoria_id       = @categoria_id,
        precio_base_bs     = @precio_base_bs,
        precio_base_usd    = @precio_base_usd,
        precio_promo_bs    = @precio_promo_bs,
        precio_promo_usd   = @precio_promo_usd,
        promo_desde        = @promo_desde,
        promo_hasta        = @promo_hasta,
        tiene_variaciones  = @tiene_variaciones,
        destacado          = @destacado,
        menu_order         = @menu_order,
        notas_internas     = NULLIF(@notas_internas,''),
        stock_actual       = @stock_actual,
        stock_minimo       = @stock_minimo,
        wc_sync_estado     = 'PENDIENTE',
        modificado_por     = @modificado_por,
        modificado_en      = GETDATE()
    WHERE producto_id = @producto_id;

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_anterior, valor_nuevo, motivo)
    VALUES
        (@modificado_por, 'FLORERIA_Producto', CAST(@producto_id AS VARCHAR),
         'MODIFICAR', @anterior,
         '{"sku":"' + @sku + '","precio_bs":"' + CAST(@precio_base_bs AS VARCHAR) + '"}',
         @motivo);

    SELECT 1 AS ok, 'Producto actualizado correctamente.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Producto_CambiarEstado]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP: Cambiar estado activo/inactivo
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Producto_CambiarEstado]
    @producto_id    INT,
    @activo         BIT,
    @modificado_por INT,
    @motivo         VARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    IF @motivo IS NULL OR LEN(LTRIM(RTRIM(@motivo))) < 5
    BEGIN
        SELECT 0 AS ok, 'El motivo es obligatorio (min. 5 caracteres).' AS mensaje;
        RETURN;
    END;

    UPDATE FLORERIA_Producto SET
        activo         = @activo,
        wc_sync_estado = 'PENDIENTE',
        modificado_por = @modificado_por,
        modificado_en  = GETDATE()
    WHERE producto_id = @producto_id;

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_nuevo, motivo)
    VALUES
        (@modificado_por, 'FLORERIA_Producto', CAST(@producto_id AS VARCHAR),
         'MODIFICAR',
         '{"activo":"' + CAST(@activo AS VARCHAR) + '"}',
         @motivo);

    DECLARE @msg VARCHAR(100);
    SET @msg = CASE WHEN @activo = 1 THEN 'Producto activado.' ELSE 'Producto desactivado.' END;
    SELECT 1 AS ok, @msg AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Producto_Crear]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP: Crear producto completo
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Producto_Crear]
    @sku               VARCHAR(50),
    @nombre            VARCHAR(200),
    @descripcion       NVARCHAR(MAX),
    @categoria_id      INT,
    @precio_base_bs    DECIMAL(10,2),
    @precio_base_usd   DECIMAL(10,2),
    @precio_promo_bs   DECIMAL(10,2),
    @precio_promo_usd  DECIMAL(10,2),
    @promo_desde       DATE,
    @promo_hasta       DATE,
    @tiene_variaciones BIT,
    @destacado         BIT,
    @menu_order        INT,
    @notas_internas    NVARCHAR(500),
    @stock_actual      INT,
    @stock_minimo      INT,
    @creado_por        INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM FLORERIA_Producto WHERE sku = @sku)
    BEGIN
        SELECT 0 AS ok, 'Ya existe un producto con ese SKU.' AS mensaje, NULL AS producto_id;
        RETURN;
    END;

    -- Validar promo: precio promo debe ser menor al base
    IF @precio_promo_bs IS NOT NULL AND @precio_promo_bs >= @precio_base_bs
    BEGIN
        SELECT 0 AS ok, 'El precio promocional debe ser menor al precio base.', NULL AS producto_id;
        RETURN;
    END;

    INSERT INTO FLORERIA_Producto (
        sku, nombre, descripcion, categoria_id,
        precio_base_bs, precio_base_usd,
        precio_promo_bs, precio_promo_usd,
        promo_desde, promo_hasta,
        tiene_variaciones, destacado, menu_order,
        notas_internas, stock_actual, stock_minimo,
        wc_sync_estado, activo, creado_por
    ) VALUES (
        @sku, @nombre, NULLIF(@descripcion,''), @categoria_id,
        @precio_base_bs, @precio_base_usd,
        @precio_promo_bs, @precio_promo_usd,
        @promo_desde, @promo_hasta,
        @tiene_variaciones, @destacado, @menu_order,
        NULLIF(@notas_internas,''), @stock_actual, @stock_minimo,
        'PENDIENTE', 1, @creado_por
    );

    DECLARE @nuevo_id INT = SCOPE_IDENTITY();

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_nuevo, motivo)
    VALUES
        (@creado_por, 'FLORERIA_Producto', CAST(@nuevo_id AS VARCHAR),
         'INSERTAR',
         '{"sku":"' + @sku + '","nombre":"' + @nombre + '"}',
         'Creacion de producto');

    SELECT 1 AS ok, 'Producto creado correctamente.' AS mensaje, @nuevo_id AS producto_id;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Producto_GuardarCategorias]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP: Guardar categorías de un producto (muchos a muchos)
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Producto_GuardarCategorias]
    @producto_id  INT,
    @categoria_ids VARCHAR(500),  -- IDs separados por coma: "1,5,12"
    @principal_id  INT,
    @creado_por    INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Eliminar relaciones existentes
    DELETE FROM FLORERIA_Producto_Categoria WHERE producto_id = @producto_id;

    -- Insertar categoría principal
    IF @principal_id > 0
    BEGIN
        INSERT INTO FLORERIA_Producto_Categoria (producto_id, categoria_id, es_principal, creado_por)
        VALUES (@producto_id, @principal_id, 1, @creado_por);
    END;

    -- Insertar categorías adicionales desde string CSV
    DECLARE @ids  VARCHAR(500) = @categoria_ids + ',';
    DECLARE @pos  INT = 1;
    DECLARE @next INT;
    DECLARE @id   INT;

    WHILE @pos <= LEN(@ids)
    BEGIN
        SET @next = CHARINDEX(',', @ids, @pos);
        IF @next = 0 BREAK;
        DECLARE @parte VARCHAR(20) = LTRIM(RTRIM(SUBSTRING(@ids, @pos, @next - @pos)));
        IF ISNUMERIC(@parte) = 1
        BEGIN
            SET @id = CAST(@parte AS INT);
            IF @id > 0 AND @id <> @principal_id
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM FLORERIA_Producto_Categoria
                               WHERE producto_id = @producto_id AND categoria_id = @id)
                BEGIN
                    INSERT INTO FLORERIA_Producto_Categoria (producto_id, categoria_id, es_principal, creado_por)
                    VALUES (@producto_id, @id, 0, @creado_por);
                END;
            END;
        END;
        SET @pos = @next + 1;
    END;

    SELECT 1 AS ok, 'Categorias guardadas.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Producto_GuardarVariaciones]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP: Guardar variaciones (borra las existentes y reinserta)
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Producto_GuardarVariaciones]
    @producto_id    INT,
    @variaciones_json NVARCHAR(MAX),
    @modificado_por INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Las variaciones se manejan desde VB.NET una por una
    -- Este SP actualiza wc_sync_estado del producto
    UPDATE FLORERIA_Producto SET
        wc_sync_estado = 'PENDIENTE',
        modificado_por = @modificado_por,
        modificado_en  = GETDATE()
    WHERE producto_id = @producto_id;

    SELECT 1 AS ok, 'Variaciones actualizadas.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Producto_Listar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP con paginacion
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Producto_Listar]
    @buscar         VARCHAR(200) = NULL,
    @categoria_id   INT          = NULL,
    @activo         BIT          = NULL,
    @wc_sync_estado VARCHAR(20)  = NULL,
    @pagina         INT          = 1,
    @por_pagina     INT          = 20
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @offset INT = (@pagina - 1) * @por_pagina;

    SELECT
        p.producto_id, p.sku, p.nombre,
        p.precio_base_bs, p.precio_base_usd,
        p.precio_promo_bs, p.precio_promo_usd,
        p.promo_desde, p.promo_hasta,
        p.destacado, p.menu_order,
        p.notas_internas, p.stock_actual, p.stock_minimo,
        p.tiene_variaciones, p.wc_product_id,
        p.wc_sync_estado, p.wc_sync_fecha,
        p.activo, p.creado_en, p.modificado_en,
        p.categoria_id, p.imagen_url,
        c.nombre AS categoria_nombre,
        CASE
            WHEN p.precio_promo_bs IS NOT NULL
             AND p.promo_desde <= CAST(GETDATE() AS DATE)
             AND p.promo_hasta  >= CAST(GETDATE() AS DATE)
            THEN 1 ELSE 0
        END AS promo_activa_hoy,
        (SELECT COUNT(*) FROM FLORERIA_Producto_Variacion v
         WHERE v.producto_id = p.producto_id AND v.activo = 1) AS total_variaciones
    FROM FLORERIA_Producto p
    LEFT JOIN FLORERIA_Categoria c ON p.categoria_id = c.categoria_id
    WHERE
        (@buscar IS NULL OR p.nombre LIKE '%' + @buscar + '%' OR p.sku LIKE '%' + @buscar + '%')
    AND (@activo IS NULL OR p.activo = @activo)
    AND (@wc_sync_estado IS NULL OR p.wc_sync_estado = @wc_sync_estado)
    AND (
        @categoria_id IS NULL
        OR p.categoria_id = @categoria_id
        OR EXISTS (
            SELECT 1 FROM FLORERIA_Producto_Categoria pc
            WHERE pc.producto_id = p.producto_id AND pc.categoria_id = @categoria_id
        )
    )
    ORDER BY p.destacado DESC, p.menu_order, p.nombre
    OFFSET @offset ROWS FETCH NEXT @por_pagina ROWS ONLY;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Producto_ObtenerPorId]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_Producto_ObtenerPorId]
    @producto_id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Resultset 1: datos del producto
    SELECT
        p.producto_id, p.sku, p.nombre, p.descripcion,
        p.categoria_id, p.precio_base_bs, p.precio_base_usd,
        p.precio_promo_bs, p.precio_promo_usd,
        p.promo_desde, p.promo_hasta,
        p.tiene_variaciones, p.destacado, p.menu_order,
        p.notas_internas, p.stock_actual, p.stock_minimo,
        p.wc_product_id, p.wc_sync_estado, p.wc_sync_fecha,
        p.activo, p.imagen_url,
        c.nombre AS categoria_nombre
    FROM FLORERIA_Producto p
    LEFT JOIN FLORERIA_Categoria c ON p.categoria_id = c.categoria_id
    WHERE p.producto_id = @producto_id;

    -- Resultset 2: variaciones
    SELECT
        variacion_id, sku_variacion,
        atrib_1_nombre, atrib_1_valor,
        atrib_2_nombre, atrib_2_valor,
        atrib_3_nombre, atrib_3_valor,
        precio_bs, precio_usd,
        precio_promo_bs, precio_promo_usd,
        promo_desde, promo_hasta,
        activo
    FROM FLORERIA_Producto_Variacion
    WHERE producto_id = @producto_id AND activo = 1
    ORDER BY variacion_id;

    -- Resultset 3: categorias del producto
    SELECT pc.categoria_id, c.nombre
    FROM FLORERIA_Producto_Categoria pc
    INNER JOIN FLORERIA_Categoria c ON pc.categoria_id = c.categoria_id
    WHERE pc.producto_id = @producto_id;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_TipoMenu_Guardar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[FLORERIA_sp_TipoMenu_Guardar]
    @tipo_id        SMALLINT,
    @menu_id        SMALLINT,
    @puede_ver      BIT,
    @puede_crear    BIT,
    @puede_editar   BIT,
    @puede_eliminar BIT,
    @modificado_por INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM FLORERIA_TipoUsuario_Menu
        WHERE tipo_id = @tipo_id AND menu_id = @menu_id
    )
    BEGIN
        UPDATE FLORERIA_TipoUsuario_Menu
        SET puede_ver      = @puede_ver,
            puede_crear    = @puede_crear,
            puede_editar   = @puede_editar,
            puede_eliminar = @puede_eliminar
        WHERE tipo_id = @tipo_id AND menu_id = @menu_id;
    END
    ELSE
    BEGIN
        INSERT INTO FLORERIA_TipoUsuario_Menu
            (tipo_id, menu_id, puede_ver, puede_crear, puede_editar, puede_eliminar)
        VALUES
            (@tipo_id, @menu_id, @puede_ver, @puede_crear, @puede_editar, @puede_eliminar);
    END

    -- Auditoría
    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_nuevo, motivo)
    VALUES (
        @modificado_por,
        'FLORERIA_TipoUsuario_Menu',
        CAST(@tipo_id AS VARCHAR) + '_' + CAST(@menu_id AS VARCHAR),
        'MODIFICAR',
        '{"tipo_id":' + CAST(@tipo_id AS VARCHAR) +
        ',"menu_id":' + CAST(@menu_id AS VARCHAR) +
        ',"ver":'     + CAST(@puede_ver AS VARCHAR) +
        ',"crear":'   + CAST(@puede_crear AS VARCHAR) +
        ',"editar":'  + CAST(@puede_editar AS VARCHAR) +
        ',"eliminar":' + CAST(@puede_eliminar AS VARCHAR) + '}',
        'Cambio de permisos de menu'
    );
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Usuario_Actualizar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_Usuario_Actualizar]
    @usuario_id     INT,
    @tipo_id        SMALLINT,
    @nombres        VARCHAR(100),
    @apellidos      VARCHAR(100),
    @email          VARCHAR(100),
    @celular        VARCHAR(20),
    @direccion      VARCHAR(200),
    @fecha_nac      DATE,
    @vigente_hasta  DATE,
    @modificado_por INT,
    @motivo         VARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM FLORERIA_Usuario WHERE usuario_id = @usuario_id)
    BEGIN
        SELECT 0 AS ok, 'Usuario no encontrado.' AS mensaje;
        RETURN;
    END;

    IF @email IS NOT NULL AND @email <> ''
    BEGIN
        IF EXISTS (SELECT 1 FROM FLORERIA_Usuario
                   WHERE email = @email AND usuario_id <> @usuario_id)
        BEGIN
            SELECT 0 AS ok, 'Ese correo ya lo usa otro usuario.' AS mensaje;
            RETURN;
        END;
    END;

    DECLARE @anterior NVARCHAR(MAX);
    SELECT @anterior = '{"nombres":"' + nombres + '","apellidos":"' + apellidos +
                       '","tipo_id":"' + CAST(tipo_id AS VARCHAR) + '"}'
    FROM FLORERIA_Usuario WHERE usuario_id = @usuario_id;

    UPDATE FLORERIA_Usuario SET
        tipo_id        = @tipo_id,
        nombres        = @nombres,
        apellidos      = @apellidos,
        email          = NULLIF(@email, ''),
        celular        = NULLIF(@celular, ''),
        direccion      = NULLIF(@direccion, ''),
        fecha_nac      = @fecha_nac,
        vigente_hasta  = @vigente_hasta,
        modificado_por = @modificado_por,
        modificado_en  = GETDATE()
    WHERE usuario_id = @usuario_id;

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_anterior, valor_nuevo, motivo)
    VALUES
        (@modificado_por, 'FLORERIA_Usuario', CAST(@usuario_id AS VARCHAR),
         'MODIFICAR', @anterior,
         '{"nombres":"' + @nombres + '","apellidos":"' + @apellidos + '"}',
         @motivo);

    SELECT 1 AS ok, 'Usuario actualizado correctamente.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Usuario_CambiarBloqueo]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_Usuario_CambiarBloqueo]
    @usuario_id     INT,
    @bloquear       BIT,
    @modificado_por INT,
    @motivo         VARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    IF @motivo IS NULL OR LEN(LTRIM(RTRIM(@motivo))) < 5
    BEGIN
        SELECT 0 AS ok, 'Debe ingresar un motivo de al menos 5 caracteres.' AS mensaje;
        RETURN;
    END;

    UPDATE FLORERIA_Usuario SET
        bloqueado         = @bloquear,
        intentos_fallidos = 0,
        bloqueado_hasta   = NULL,
        modificado_por    = @modificado_por,
        modificado_en     = GETDATE()
    WHERE usuario_id = @usuario_id;

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_nuevo, motivo)
    VALUES
        (@modificado_por, 'FLORERIA_Usuario', CAST(@usuario_id AS VARCHAR),
         'MODIFICAR',
         '{"bloqueado":"' + CAST(@bloquear AS VARCHAR) + '"}',
         @motivo);

    DECLARE @msg VARCHAR(100);
    SET @msg = CASE WHEN @bloquear = 1 THEN 'Usuario bloqueado.' ELSE 'Usuario desbloqueado.' END;
    SELECT 1 AS ok, @msg AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Usuario_CambiarPassword]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_Usuario_CambiarPassword]
    @usuario_id      INT,
    @pwd_actual_hash VARCHAR(200),
    @pwd_nueva_hash  VARCHAR(200),
    @ip              VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @hash_bd VARCHAR(200);
    SELECT @hash_bd = password_hash FROM FLORERIA_Usuario WHERE usuario_id = @usuario_id;

    IF @hash_bd IS NULL
    BEGIN
        SELECT 0 AS ok, 'Usuario no encontrado.' AS mensaje;
        RETURN;
    END;

    IF @hash_bd <> @pwd_actual_hash
    BEGIN
        SELECT 0 AS ok, 'La contrasena actual es incorrecta.' AS mensaje;
        RETURN;
    END;

    IF @pwd_actual_hash = @pwd_nueva_hash
    BEGIN
        SELECT 0 AS ok, 'La nueva contrasena no puede ser igual a la actual.' AS mensaje;
        RETURN;
    END;

    UPDATE FLORERIA_Usuario SET
        password_hash    = @pwd_nueva_hash,
        debe_cambiar_pwd = 0,
        modificado_en    = GETDATE(),
        modificado_por   = @usuario_id
    WHERE usuario_id = @usuario_id;

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, ip, tabla, registro_id, accion, valor_nuevo)
    VALUES
        (@usuario_id, @ip, 'FLORERIA_Usuario',
         CAST(@usuario_id AS VARCHAR), 'MODIFICAR',
         '{"campo":"password","detalle":"Cambio por el usuario"}');

    SELECT 1 AS ok, 'Contrasena actualizada correctamente.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Usuario_Crear]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_Usuario_Crear]
    @tipo_id        SMALLINT,
    @carnet         VARCHAR(8),
    @nombres        VARCHAR(100),
    @apellidos      VARCHAR(100),
    @email          VARCHAR(100),
    @celular        VARCHAR(20),
    @direccion      VARCHAR(200),
    @fecha_nac      DATE,
    @vigente_hasta  DATE,
    @creado_por     INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM FLORERIA_Usuario WHERE carnet = @carnet)
    BEGIN
        SELECT 0 AS ok, 'Ya existe un usuario con ese numero de carnet.' AS mensaje, NULL AS usuario_id;
        RETURN;
    END;

    IF @email IS NOT NULL AND @email <> ''
    BEGIN
        IF EXISTS (SELECT 1 FROM FLORERIA_Usuario WHERE email = @email)
        BEGIN
            SELECT 0 AS ok, 'Ya existe un usuario con ese correo electronico.' AS mensaje, NULL AS usuario_id;
            RETURN;
        END;
    END;

    DECLARE @salt VARCHAR(50)  = 'FLORERIA2026';
    DECLARE @hash VARCHAR(200) = UPPER(CONVERT(VARCHAR(200),
        HASHBYTES('SHA2_256', @carnet + 'FLORERIA2026'), 2));

    INSERT INTO FLORERIA_Usuario (
        tipo_id, carnet, nombres, apellidos,
        email, celular, direccion, fecha_nac,
        password_hash, password_salt,
        debe_cambiar_pwd, vigente_hasta,
        activo, creado_por
    ) VALUES (
        @tipo_id, @carnet, @nombres, @apellidos,
        NULLIF(@email, ''), NULLIF(@celular, ''),
        NULLIF(@direccion, ''), @fecha_nac,
        @hash, @salt,
        1, @vigente_hasta,
        1, @creado_por
    );

    DECLARE @nuevo_id INT = SCOPE_IDENTITY();

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_nuevo, motivo)
    VALUES
        (@creado_por, 'FLORERIA_Usuario', CAST(@nuevo_id AS VARCHAR),
         'INSERTAR',
         '{"carnet":"' + @carnet + '","nombres":"' + @nombres + '"}',
         'Creacion de usuario');

    SELECT 1 AS ok, 'Usuario creado correctamente.' AS mensaje, @nuevo_id AS usuario_id;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Usuario_Listar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_Usuario_Listar]
    @buscar     VARCHAR(100) = NULL,
    @tipo_id    SMALLINT     = NULL,
    @estado     VARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        u.usuario_id,
        u.tipo_id,
        u.carnet,
        u.nombres,
        u.apellidos,
        u.email,
        u.celular,
        u.direccion,
        u.fecha_nac,
        u.vigente_hasta,
        u.activo,
        u.bloqueado,
        u.intentos_fallidos,
        u.debe_cambiar_pwd,
        u.creado_en,
        t.nombre AS tipo_nombre,
        CASE
            WHEN u.bloqueado = 1
                THEN 'BLOQUEADO'
            WHEN u.activo = 0
                THEN 'INACTIVO'
            WHEN u.vigente_hasta IS NOT NULL
             AND u.vigente_hasta < CAST(GETDATE() AS DATE)
                THEN 'VENCIDO'
            WHEN u.vigente_hasta IS NOT NULL
             AND u.vigente_hasta = CAST(GETDATE() AS DATE)
                THEN 'VENCE_HOY'
            ELSE 'ACTIVO'
        END AS estado_calculado
    FROM FLORERIA_Usuario u
    JOIN FLORERIA_TipoUsuario t ON u.tipo_id = t.tipo_id
    WHERE
        (@buscar  IS NULL OR u.nombres   LIKE '%' + @buscar + '%'
                          OR u.apellidos LIKE '%' + @buscar + '%'
                          OR u.carnet    LIKE '%' + @buscar + '%')
    AND (@tipo_id IS NULL OR u.tipo_id = @tipo_id)
    AND (
        @estado IS NULL
        OR (@estado = 'ACTIVO'    AND u.activo = 1 AND u.bloqueado = 0
            AND (u.vigente_hasta IS NULL OR u.vigente_hasta >= CAST(GETDATE() AS DATE)))
        OR (@estado = 'BLOQUEADO' AND u.bloqueado = 1)
        OR (@estado = 'VENCIDO'   AND u.vigente_hasta IS NOT NULL
            AND u.vigente_hasta < CAST(GETDATE() AS DATE))
    )
    ORDER BY u.apellidos, u.nombres;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Usuario_ObtenerPorId]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_Usuario_ObtenerPorId]
    @usuario_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        u.usuario_id, u.tipo_id, u.carnet,
        u.nombres, u.apellidos, u.email, u.celular,
        u.direccion, u.fecha_nac,
        u.vigente_desde, u.vigente_hasta,
        u.activo, u.bloqueado, u.intentos_fallidos,
        u.debe_cambiar_pwd, u.creado_en,
        t.nombre AS tipo_nombre
    FROM FLORERIA_Usuario u
    JOIN FLORERIA_TipoUsuario t ON u.tipo_id = t.tipo_id
    WHERE u.usuario_id = @usuario_id;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Usuario_ResetearPassword]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_Usuario_ResetearPassword]
    @usuario_id     INT,
    @modificado_por INT,
    @motivo         VARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    IF @motivo IS NULL OR LEN(LTRIM(RTRIM(@motivo))) < 5
    BEGIN
        SELECT 0 AS ok, 'Debe ingresar un motivo de al menos 5 caracteres.' AS mensaje;
        RETURN;
    END;

    DECLARE @carnet VARCHAR(8);
    SELECT @carnet = carnet FROM FLORERIA_Usuario WHERE usuario_id = @usuario_id;

    IF @carnet IS NULL
    BEGIN
        SELECT 0 AS ok, 'Usuario no encontrado.' AS mensaje;
        RETURN;
    END;

    DECLARE @salt VARCHAR(50)  = 'FLORERIA2026';
    DECLARE @hash VARCHAR(200) = UPPER(CONVERT(VARCHAR(200),
        HASHBYTES('SHA2_256', @carnet + 'FLORERIA2026'), 2));

    UPDATE FLORERIA_Usuario SET
        password_hash    = @hash,
        password_salt    = @salt,
        debe_cambiar_pwd = 1,
        modificado_por   = @modificado_por,
        modificado_en    = GETDATE()
    WHERE usuario_id = @usuario_id;

    INSERT INTO FLORERIA_Auditoria
        (usuario_id, tabla, registro_id, accion, valor_nuevo, motivo)
    VALUES
        (@modificado_por, 'FLORERIA_Usuario', CAST(@usuario_id AS VARCHAR),
         'MODIFICAR',
         '{"campo":"password","detalle":"Reset a carnet"}',
         @motivo);

    SELECT 1 AS ok, 'Contrasena reseteada. El usuario debera cambiarla al ingresar.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_ValidarSesion]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[FLORERIA_sp_ValidarSesion]  
    @token VARCHAR(100),  
    @ip    VARCHAR(50)  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    -- Hora actual en Bolivia (UTC-4)  
    DECLARE @horaBolivia DATETIME = DATEADD(HOUR, -4, GETUTCDATE())  
  
    DECLARE @sesion_id  BIGINT  
    DECLARE @usuario_id INT  
    DECLARE @expira_en  DATETIME  
    DECLARE @activa     BIT  
  
    SELECT  
        @sesion_id  = sesion_id,  
        @usuario_id = usuario_id,  
        @expira_en  = expira_en,  
        @activa     = activa  
    FROM FLORERIA_Sesion  
    WHERE token = @token  
  
    -- Token no existe  
    IF @sesion_id IS NULL  
    BEGIN  
        SELECT 0 AS valida, 'Token no existe' AS mensaje, NULL AS usuario_id, NULL AS nombres, NULL AS apellidos, NULL AS tipo_nombre
        RETURN  
    END  
  
    -- Sesion cerrada  
    IF @activa = 0  
    BEGIN  
        SELECT 0 AS valida, 'Sesion cerrada' AS mensaje, NULL AS usuario_id, NULL AS nombres, NULL AS apellidos, NULL AS tipo_nombre
        RETURN  
    END  
  
    -- Sesion expirada (comparar con hora Bolivia)  
    IF @horaBolivia > @expira_en  
    BEGIN  
        UPDATE FLORERIA_Sesion SET activa = 0, cerrada_por = 'SISTEMA'  
        WHERE sesion_id = @sesion_id  
  
        SELECT 0 AS valida, 'Sesion expirada' AS mensaje, NULL AS usuario_id, NULL AS nombres, NULL AS apellidos, NULL AS tipo_nombre
        RETURN  
    END  
  
    -- Sesion valida — actualizar ultimo acceso con hora Bolivia  
    UPDATE FLORERIA_Sesion  
    SET ultimo_acceso = @horaBolivia  
    WHERE sesion_id = @sesion_id  
  
    -- Retornar datos completos del usuario
    SELECT  
        1 AS valida,
        'OK' AS mensaje,
        u.usuario_id,
        u.nombres,
        u.apellidos,
        t.nombre AS tipo_nombre
    FROM FLORERIA_Usuario u
    INNER JOIN FLORERIA_TipoUsuario t ON u.tipo_id = t.tipo_id
    WHERE u.usuario_id = @usuario_id
END
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Variacion_Eliminar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP: Eliminar variación
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Variacion_Eliminar]
    @variacion_id   INT,
    @modificado_por INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE FLORERIA_Producto_Variacion SET
        activo         = 0,
        wc_sync_estado = 'PENDIENTE',
        modificado_por = @modificado_por,
        modificado_en  = GETDATE()
    WHERE variacion_id = @variacion_id;
    SELECT 1 AS ok, 'Variacion eliminada.' AS mensaje;
END;
GO
/****** Object:  StoredProcedure [dbo].[FLORERIA_sp_Variacion_Guardar]    Script Date: 26/05/2026 21:40:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP: Guardar una variación individual
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Variacion_Guardar]
    @variacion_id    INT,
    @producto_id     INT,
    @sku_variacion   VARCHAR(60),
    @atrib_1_nombre  VARCHAR(40),
    @atrib_1_valor   VARCHAR(80),
    @atrib_2_nombre  VARCHAR(40),
    @atrib_2_valor   VARCHAR(80),
    @atrib_3_nombre  VARCHAR(40),
    @atrib_3_valor   VARCHAR(80),
    @precio_bs       DECIMAL(10,2),
    @precio_usd      DECIMAL(10,2),
    @precio_promo_bs DECIMAL(10,2),
    @precio_promo_usd DECIMAL(10,2),
    @promo_desde     DATE,
    @promo_hasta     DATE,
    @modificado_por  INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar promo
    IF @precio_promo_bs IS NOT NULL AND @precio_promo_bs >= @precio_bs
    BEGIN
        SELECT 0 AS ok, 'El precio promo debe ser menor al precio base.' AS mensaje, 0 AS variacion_id;
        RETURN;
    END;

    IF @variacion_id = 0
    BEGIN
        -- Verificar SKU único
        IF EXISTS (SELECT 1 FROM FLORERIA_Producto_Variacion WHERE sku_variacion = @sku_variacion)
        BEGIN
            SELECT 0 AS ok, 'Ya existe una variacion con ese SKU.' AS mensaje, 0 AS variacion_id;
            RETURN;
        END;

        INSERT INTO FLORERIA_Producto_Variacion (
            producto_id, sku_variacion,
            atrib_1_nombre, atrib_1_valor,
            atrib_2_nombre, atrib_2_valor,
            atrib_3_nombre, atrib_3_valor,
            precio_bs, precio_usd,
            precio_promo_bs, precio_promo_usd,
            promo_desde, promo_hasta,
            wc_sync_estado, activo, creado_por
        ) VALUES (
            @producto_id, @sku_variacion,
            NULLIF(@atrib_1_nombre,''), NULLIF(@atrib_1_valor,''),
            NULLIF(@atrib_2_nombre,''), NULLIF(@atrib_2_valor,''),
            NULLIF(@atrib_3_nombre,''), NULLIF(@atrib_3_valor,''),
            @precio_bs, @precio_usd,
            @precio_promo_bs, @precio_promo_usd,
            @promo_desde, @promo_hasta,
            'PENDIENTE', 1, @modificado_por
        );
        SELECT 1 AS ok, 'Variacion creada.' AS mensaje, SCOPE_IDENTITY() AS variacion_id;
    END
    ELSE
    BEGIN
        UPDATE FLORERIA_Producto_Variacion SET
            sku_variacion    = @sku_variacion,
            atrib_1_nombre   = NULLIF(@atrib_1_nombre,''),
            atrib_1_valor    = NULLIF(@atrib_1_valor,''),
            atrib_2_nombre   = NULLIF(@atrib_2_nombre,''),
            atrib_2_valor    = NULLIF(@atrib_2_valor,''),
            atrib_3_nombre   = NULLIF(@atrib_3_nombre,''),
            atrib_3_valor    = NULLIF(@atrib_3_valor,''),
            precio_bs        = @precio_bs,
            precio_usd       = @precio_usd,
            precio_promo_bs  = @precio_promo_bs,
            precio_promo_usd = @precio_promo_usd,
            promo_desde      = @promo_desde,
            promo_hasta      = @promo_hasta,
            wc_sync_estado   = 'PENDIENTE',
            modificado_por   = @modificado_por,
            modificado_en    = GETDATE()
        WHERE variacion_id = @variacion_id AND producto_id = @producto_id;
        SELECT 1 AS ok, 'Variacion actualizada.' AS mensaje, @variacion_id AS variacion_id;
    END;
END;
GO
