-- =============================================
-- SISCONBOL_FLORERIA - TODOS LOS STORED PROCEDURES
-- Total SPs: 48
-- =============================================
 
USE SISCONBOL;
GO
 
-- ============================================================
-- SP: FLORERIA_sp_CambiarPassword
-- ============================================================

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_CargarMenu
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- ────────────────────────────────────────
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
        END AS puede_eliminar
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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_Actualizar
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_AgregarProductos
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_BajaProductos
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_CambiarOrden
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_Crear
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_Eliminar
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_GuardarWcId
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_HabilitarProductos
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_Listar
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_ListarProductos
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_MarcarPrincipal
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_MarcarSincronizada
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_ObtenerStats
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_ProductosDisponibles
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_QuitarProducto
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Categoria_QuitarProductosMasivo
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_CerrarSesion
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Config_Guardar
-- ============================================================
-----t
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Config_ListarTodas
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Config_Obtener
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Login
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ============================================================
-- CORRECCION: FLORERIA_sp_Login
-- Problema: expira_en usaba GETDATE() que es hora del servidor
--           (UTC o USA), no hora de Bolivia (UTC-4)
-- Solucion: calcular 23:59:59 del dia actual en hora Bolivia
-- Ejecutar en: SSMS conectado a Somee
-- ============================================================

CREATE   PROCEDURE FLORERIA_sp_Login
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
 
-- ============================================================
-- SP: FLORERIA_sp_Pedido_AgregarProducto
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- SP 7: FLORERIA_sp_Pedido_AgregarProducto
-- Descripción: Agregar producto al pedido
-- =============================================
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Pedido_AgregarProducto]
    @pedido_id           INT,
    @producto_id         INT,
    @variacion_id        INT,
    @es_personalizado    BIT,
    @nombre_producto     VARCHAR(200),
    @descripcion         NVARCHAR(500),
    @cantidad            INT,
    @precio_unitario_bs  DECIMAL(10,2),
    @precio_unitario_usd DECIMAL(10,2),
    @personalizacion     NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar pedido existe
    IF NOT EXISTS (SELECT 1 FROM FLORERIA_Pedido WHERE pedido_id = @pedido_id)
    BEGIN
        RAISERROR('El pedido no existe', 16, 1);
        RETURN;
    END
    
    -- Validar cantidad
    IF @cantidad <= 0
    BEGIN
        RAISERROR('La cantidad debe ser mayor a 0', 16, 1);
        RETURN;
    END
    
    -- Validar precio
    IF @precio_unitario_bs <= 0
    BEGIN
        RAISERROR('El precio debe ser mayor a 0', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Calcular subtotales
        DECLARE @subtotal_bs DECIMAL(10,2) = @cantidad * @precio_unitario_bs;
        DECLARE @subtotal_usd DECIMAL(10,2) = @cantidad * @precio_unitario_usd;
        
        -- Insertar detalle
        INSERT INTO FLORERIA_Pedido_Detalle (
            pedido_id, producto_id, variacion_id, es_personalizado,
            nombre_producto, descripcion, cantidad,
            precio_unitario_bs, precio_unitario_usd,
            subtotal_bs, subtotal_usd,
            personalizacion, creado_en
        )
        VALUES (
            @pedido_id, @producto_id, @variacion_id, @es_personalizado,
            @nombre_producto, @descripcion, @cantidad,
            @precio_unitario_bs, @precio_unitario_usd,
            @subtotal_bs, @subtotal_usd,
            @personalizacion, GETDATE()
        );
        
        -- Actualizar totales del pedido
        UPDATE FLORERIA_Pedido
        SET subtotal_productos_bs = subtotal_productos_bs + @subtotal_bs,
            subtotal_productos_usd = subtotal_productos_usd + @subtotal_usd,
            total_bs = subtotal_productos_bs + @subtotal_bs + envio_bs + recargo_express_bs + recargo_horario_bs,
            total_usd = subtotal_productos_usd + @subtotal_usd + envio_usd + recargo_express_usd + recargo_horario_usd,
            saldo_bs = total_bs - anticipo_bs
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
 
-- ============================================================
-- SP: FLORERIA_sp_Pedido_CalcularEnvio
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Pedido_Crear
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- SP 6: FLORERIA_sp_Pedido_Crear
-- Descripción: Crear pedido dentro de pre-pedido
-- =============================================
CREATE   PROCEDURE [dbo].[FLORERIA_sp_Pedido_Crear]
    @prepedido_id        INT,
    @receptor_nombre     VARCHAR(200),
    @receptor_celular    VARCHAR(20),
    @ciudad_id           SMALLINT,
    @zona_id             INT,
    @sucursal_id         SMALLINT,
    @tipo_entrega        VARCHAR(20),
    @direccion           VARCHAR(300),
    @referencia          VARCHAR(300),
    @fecha_entrega       DATE,
    @slot_id             SMALLINT,
    @es_express          BIT,
    @dedicatoria         NVARCHAR(500),
    @firma_tarjeta       VARCHAR(100),
    @creado_por          INT,
    @ip                  VARCHAR(50),
    @pedido_id           INT OUTPUT,
    @codigo              VARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar pre-pedido existe
    IF NOT EXISTS (SELECT 1 FROM FLORERIA_PrePedido WHERE prepedido_id = @prepedido_id)
    BEGIN
        RAISERROR('El pre-pedido no existe', 16, 1);
        RETURN;
    END
    
    -- Validar tipo_entrega
    IF @tipo_entrega NOT IN ('DOMICILIO', 'RECOJO_SUCURSAL')
    BEGIN
        RAISERROR('Tipo de entrega inválido', 16, 1);
        RETURN;
    END
    
    -- Validar: si es RECOJO debe tener sucursal_id
    IF @tipo_entrega = 'RECOJO_SUCURSAL' AND @sucursal_id IS NULL
    BEGIN
        RAISERROR('Para recojo en sucursal debe especificar la sucursal', 16, 1);
        RETURN;
    END
    
    -- Validar: si es DOMICILIO debe tener zona_id
    IF @tipo_entrega = 'DOMICILIO' AND @zona_id IS NULL
    BEGIN
        RAISERROR('Para entrega a domicilio debe especificar la zona', 16, 1);
        RETURN;
    END
    
    -- Validar fecha entrega (mínimo 2 horas después)
    IF @fecha_entrega < CAST(GETDATE() AS DATE)
    BEGIN
        RAISERROR('La fecha de entrega no puede ser anterior a hoy', 16, 1);
        RETURN;
    END
    
    -- Validar dedicatoria sin emojis (básico)
    IF @dedicatoria IS NOT NULL AND @dedicatoria LIKE '%[😀-🙏]%'
    BEGIN
        RAISERROR('La dedicatoria no puede contener emojis', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Generar código PED-XXXXXX
        DECLARE @ultimo_numero INT;
        SELECT @ultimo_numero = ISNULL(MAX(CAST(SUBSTRING(codigo, 5, 6) AS INT)), 0)
        FROM FLORERIA_Pedido
        WHERE codigo LIKE 'PED-%';
        
        SET @codigo = 'PED-' + RIGHT('000000' + CAST(@ultimo_numero + 1 AS VARCHAR), 6);
        
        -- Obtener tasa de cambio del pre-pedido
        DECLARE @tasa_cambio DECIMAL(10,4);
        SELECT @tasa_cambio = tasa_cambio FROM FLORERIA_PrePedido WHERE prepedido_id = @prepedido_id;
        
        -- Insertar pedido
        INSERT INTO FLORERIA_Pedido (
            prepedido_id, codigo, receptor_nombre, receptor_celular,
            ciudad_id, zona_id, sucursal_id, tipo_entrega,
            direccion, referencia, fecha_entrega, slot_id, es_express,
            dedicatoria, firma_tarjeta,
            subtotal_productos_bs, subtotal_productos_usd,
            envio_bs, envio_usd,
            recargo_express_bs, recargo_express_usd,
            recargo_horario_bs, recargo_horario_usd,
            total_bs, total_usd,
            anticipo_bs, saldo_bs, estado_pago,
            wc_sync_estado,
            creado_por, creado_en
        )
        VALUES (
            @prepedido_id, @codigo, @receptor_nombre, @receptor_celular,
            @ciudad_id, @zona_id, @sucursal_id, @tipo_entrega,
            @direccion, @referencia, @fecha_entrega, @slot_id, @es_express,
            @dedicatoria, @firma_tarjeta,
            0, 0,  -- subtotales iniciales
            0, 0,  -- envío se calcula después
            0, 0,  -- recargo express
            0, 0,  -- recargo horario
          0, 0,  -- totales
            0, 0, 'PENDIENTE',
            'PENDIENTE',
            @creado_por, GETDATE()
        );
        
        SET @pedido_id = SCOPE_IDENTITY();
        
        -- Auditoría
        INSERT INTO FLORERIA_Auditoria (
            usuario_id, ip, tabla, registro_id, accion,
            valor_nuevo, motivo, fecha_hora
        )
        VALUES (
            @creado_por, @ip, 'FLORERIA_Pedido',
            CAST(@pedido_id AS VARCHAR), 'INSERTAR',
            '{"codigo":"' + @codigo + '","receptor":"' + @receptor_nombre + '"}',
            'Creación de pedido', GETDATE()
        );
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;

GO
 
-- ============================================================
-- SP: FLORERIA_sp_PrePedido_ActualizarCliente
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- PASO 3: SP ActualizarCliente — NUNCA toca token_web
CREATE   PROCEDURE FLORERIA_sp_PrePedido_ActualizarCliente
    @prepedido_id      INT,
    @cliente_nombre    VARCHAR(200),
    @cliente_apellidos VARCHAR(200),
    @cliente_email     VARCHAR(100),
    @cliente_pais_id   TINYINT,
    @cliente_ciudad_id SMALLINT,
    @modificado_por    INT,
    @ip                VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM FLORERIA_PrePedido WHERE prepedido_id = @prepedido_id)
        BEGIN
            RAISERROR('Pre-pedido no encontrado.', 16, 1);
            RETURN;
        END;

        UPDATE FLORERIA_PrePedido
        SET
            cliente_nombre    = COALESCE(@cliente_nombre,    cliente_nombre),
            cliente_apellidos = COALESCE(@cliente_apellidos, cliente_apellidos),
            cliente_email     = COALESCE(@cliente_email,     cliente_email),
            cliente_pais_id   = COALESCE(@cliente_pais_id,   cliente_pais_id),
            cliente_ciudad_id = COALESCE(@cliente_ciudad_id, cliente_ciudad_id),
            modificado_por    = @modificado_por,
            modificado_en     = GETDATE()
        WHERE prepedido_id = @prepedido_id;

        COMMIT TRANSACTION;

        SELECT prepedido_id, codigo, cliente_nombre, cliente_pais_id
        FROM FLORERIA_PrePedido
        WHERE prepedido_id = @prepedido_id;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @err2 VARCHAR(4000);
        SET @err2 = ERROR_MESSAGE();
        RAISERROR(@err2, 16, 1);
    END CATCH;
END;

GO
 
-- ============================================================
-- SP: FLORERIA_sp_PrePedido_Crear
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- PASO 2: SP Crear
CREATE   PROCEDURE FLORERIA_sp_PrePedido_Crear
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
        BEGIN TRANSACTION;

        IF EXISTS (
            SELECT 1 FROM FLORERIA_PrePedido 
            WHERE cliente_celular = @cliente_celular
              AND estado IN ('BORRADOR','FORM_ENVIADO','FORM_COMPLETADO',
                             'COMPROBANTE_ENVIADO','PAGADO')
        )
        BEGIN
            RAISERROR('El cliente ya tiene un pre-pedido activo.', 16, 1);
            RETURN;
        END;

        DECLARE @siguiente INT;
        SELECT @siguiente = ISNULL(MAX(
            CASE WHEN codigo LIKE 'PRE-%' 
                 THEN CAST(SUBSTRING(codigo, 5, LEN(codigo)) AS INT)
                 ELSE 0 END
        ), 0) + 1
        FROM FLORERIA_PrePedido;

        SET @codigo = 'PRE-' + RIGHT('000000' + CAST(@siguiente AS VARCHAR), 6);

        DECLARE @estado VARCHAR(30);
        SET @estado = CASE @tipo_registro
            WHEN 'PRE_PEDIDO'    THEN 'BORRADOR'
            WHEN 'VENTA_TIENDA'  THEN 'PAGADO'
            WHEN 'VENTA_ANTIGUA' THEN 'COMPLETADO'
            ELSE 'BORRADOR'
        END;

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

        SELECT prepedido_id, codigo, estado FROM FLORERIA_PrePedido WHERE prepedido_id = @prepedido_id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        DECLARE @err1 VARCHAR(4000);
        SET @err1 = ERROR_MESSAGE();
        RAISERROR(@err1, 16, 1);
    END CATCH;
END;

GO
 
-- ============================================================
-- SP: FLORERIA_sp_PrePedido_GenerarLink
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- SP 3: FLORERIA_sp_PrePedido_GenerarLink
-- Descripción: Generar token y configurar link web
-- =============================================
CREATE   PROCEDURE [dbo].[FLORERIA_sp_PrePedido_GenerarLink]
    @prepedido_id        INT,
    @moneda_formulario   CHAR(3),
    @descuento_bs        DECIMAL(10,2),
    @descuento_motivo    VARCHAR(300),
    @modificado_por      INT,
    @ip                  VARCHAR(50),
    @token               VARCHAR(100) OUTPUT,
    @url_completa        VARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validar pre-pedido existe
    IF NOT EXISTS (SELECT 1 FROM FLORERIA_PrePedido WHERE prepedido_id = @prepedido_id)
    BEGIN
        RAISERROR('El pre-pedido no existe', 16, 1);
        RETURN;
    END
    
    -- Validar moneda
    IF @moneda_formulario NOT IN ('BOB', 'USD')
    BEGIN
        RAISERROR('Moneda inválida. Solo BOB o USD', 16, 1);
        RETURN;
    END
    
    -- Validar descuento
    IF @descuento_bs < 0 OR @descuento_bs > 100
    BEGIN
        RAISERROR('El descuento debe estar entre 0 y 100 Bs', 16, 1);
        RETURN;
    END
    
    IF @descuento_bs > 0 AND (@descuento_motivo IS NULL OR LEN(LTRIM(RTRIM(@descuento_motivo))) < 10)
    BEGIN
        RAISERROR('Si aplica descuento, el motivo es obligatorio (mínimo 10 caracteres)', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Generar token único (GUID + GUID sin guiones)
        DECLARE @guid1 VARCHAR(50) = REPLACE(CAST(NEWID() AS VARCHAR(50)), '-', '');
        DECLARE @guid2 VARCHAR(50) = REPLACE(CAST(NEWID() AS VARCHAR(50)), '-', '');
        SET @token = @guid1 + @guid2;
        
        -- Calcular expiración (48 horas)
        DECLARE @expiracion DATETIME = DATEADD(HOUR, 48, GETDATE());
        
        -- Calcular descuento en USD
        DECLARE @tasa_cambio DECIMAL(10,4);
        SELECT @tasa_cambio = tasa_cambio FROM FLORERIA_PrePedido WHERE prepedido_id = @prepedido_id;
        
        DECLARE @descuento_usd DECIMAL(10,2) = @descuento_bs / @tasa_cambio;
        
        -- Actualizar pre-pedido
        UPDATE FLORERIA_PrePedido
        SET token_web = @token,
            token_expira = @expiracion,
            moneda_formulario = @moneda_formulario,
            descuento_bs = @descuento_bs,
            descuento_usd = @descuento_usd,
            descuento_motivo = @descuento_motivo,
            estado = 'FORM_ENVIADO',
            fecha_limite_pago = DATEADD(HOUR, 48, GETDATE()),
            modificado_por = @modificado_por,
            modificado_en = GETDATE()
        WHERE prepedido_id = @prepedido_id;
        
        -- Construir URL completa
        -- Obtener configuración de URL base
        DECLARE @url_base VARCHAR(200);
        SELECT @url_base = ISNULL(valor, 'https://miss-flores.com')
        FROM FLORERIA_Config
        WHERE clave = 'URL_FORMULARIO_WEB' AND activo = 1;
        
        SET @url_completa = @url_base + '/pedido?t=' + @token + '&m=' + @moneda_formulario;
        
        -- Auditoría
        INSERT INTO FLORERIA_Auditoria (
            usuario_id, ip, tabla, registro_id, accion,
            valor_nuevo, motivo, fecha_hora
        )
        VALUES (
            @modificado_por, @ip, 'FLORERIA_PrePedido',
            CAST(@prepedido_id AS VARCHAR), 'MODIFICAR',
            '{"accion":"generar_link","token":"' + @token + '","expira":"' + 
            CONVERT(VARCHAR, @expiracion, 120) + '"}',
            'Generación de link web', GETDATE()
        );
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;

GO
 
-- ============================================================
-- SP: FLORERIA_sp_PrePedido_Listar
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- SP 5: FLORERIA_sp_PrePedido_Listar
-- Descripción: Listar pre-pedidos con filtros
-- =============================================
CREATE   PROCEDURE [dbo].[FLORERIA_sp_PrePedido_Listar]
    @agente_id           INT = NULL,
    @estado              VARCHAR(30) = NULL,
    @buscar              VARCHAR(100) = NULL,
    @pagina              INT = 1,
    @por_pagina          INT = 20,
    @total_registros     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Calcular offset
    DECLARE @offset INT = (@pagina - 1) * @por_pagina;
    
    -- Contar total
    SELECT @total_registros = COUNT(*)
    FROM FLORERIA_PrePedido pp
    WHERE (@agente_id IS NULL OR pp.agente_actual_id = @agente_id)
      AND (@estado IS NULL OR pp.estado = @estado)
      AND (
          @buscar IS NULL 
          OR pp.codigo LIKE '%' + @buscar + '%'
          OR pp.cliente_celular LIKE '%' + @buscar + '%'
          OR pp.cliente_nombre LIKE '%' + @buscar + '%'
          OR pp.cliente_apellidos LIKE '%' + @buscar + '%'
      );
    
    -- Retornar página
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
        pp.creado_en,
        pp.modificado_en,
        -- Agente actual
        ua.nombres + ' ' + ua.apellidos AS agente_nombre,
        -- Agente creador
        uc.nombres + ' ' + uc.apellidos AS creador_nombre,
        -- Primer pedido (preview)
        (SELECT TOP 1 p.receptor_nombre + ' - ' + CONVERT(VARCHAR, p.fecha_entrega, 103)
         FROM FLORERIA_Pedido p 
         WHERE p.prepedido_id = pp.prepedido_id 
         ORDER BY p.pedido_id) AS primer_pedido_preview,
        -- Cantidad de pedidos
        (SELECT COUNT(*) FROM FLORERIA_Pedido p WHERE p.prepedido_id = pp.prepedido_id) AS cantidad_pedidos,
        -- WC sincronizado
        (SELECT COUNT(*) FROM FLORERIA_Pedido p 
         WHERE p.prepedido_id = pp.prepedido_id AND p.wc_order_id IS NOT NULL) AS pedidos_wc_sync
    FROM FLORERIA_PrePedido pp
    INNER JOIN FLORERIA_Usuario ua ON pp.agente_actual_id = ua.usuario_id
    INNER JOIN FLORERIA_Usuario uc ON pp.creado_por = uc.usuario_id
    WHERE (@agente_id IS NULL OR pp.agente_actual_id = @agente_id)
      AND (@estado IS NULL OR pp.estado = @estado)
      AND (
          @buscar IS NULL 
          OR pp.codigo LIKE '%' + @buscar + '%'
          OR pp.cliente_celular LIKE '%' + @buscar + '%'
          OR pp.cliente_nombre LIKE '%' + @buscar + '%'
          OR pp.cliente_apellidos LIKE '%' + @buscar + '%'
      )
    ORDER BY pp.prepedido_id DESC
    OFFSET @offset ROWS
    FETCH NEXT @por_pagina ROWS ONLY;
    
END;

GO
 
-- ============================================================
-- SP: FLORERIA_sp_PrePedido_ObtenerPorToken
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Producto_Actualizar
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Producto_CambiarEstado
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Producto_Crear
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Producto_GuardarCategorias
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Producto_GuardarVariaciones
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Producto_Listar
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Producto_ObtenerPorId
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Usuario_Actualizar
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Usuario_CambiarBloqueo
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Usuario_CambiarPassword
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Usuario_Crear
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Usuario_Listar
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Usuario_ObtenerPorId
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Usuario_ResetearPassword
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_ValidarSesion
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- ============================================================
-- CORRECCION: FLORERIA_sp_ValidarSesion
-- Problema: comparaba expira_en con GETDATE() (hora servidor)
--           en vez de hora Bolivia
-- ============================================================

CREATE   PROCEDURE FLORERIA_sp_ValidarSesion
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
        SELECT 0 AS valida, 'Token no existe' AS mensaje, NULL AS usuario_id
        RETURN
    END

    -- Sesion cerrada
    IF @activa = 0
    BEGIN
        SELECT 0 AS valida, 'Sesion cerrada' AS mensaje, NULL AS usuario_id
        RETURN
    END

    -- Sesion expirada (comparar con hora Bolivia)
    IF @horaBolivia > @expira_en
    BEGIN
        UPDATE FLORERIA_Sesion SET activa = 0, cerrada_por = 'SISTEMA'
        WHERE sesion_id = @sesion_id

        SELECT 0 AS valida, 'Sesion expirada' AS mensaje, NULL AS usuario_id
        RETURN
    END

    -- Sesion valida — actualizar ultimo acceso con hora Bolivia
    UPDATE FLORERIA_Sesion
    SET ultimo_acceso = @horaBolivia
    WHERE sesion_id = @sesion_id

    SELECT 1 AS valida, 'OK' AS mensaje, @usuario_id AS usuario_id
END

GO
 
-- ============================================================
-- SP: FLORERIA_sp_Variacion_Eliminar
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- ============================================================
-- SP: FLORERIA_sp_Variacion_Guardar
-- ============================================================
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
 
-- =============================================
-- FIN - TOTAL 48 SPs
-- =============================================
 














