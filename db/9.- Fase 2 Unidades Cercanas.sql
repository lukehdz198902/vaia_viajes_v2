/* =========================================================
   9.- Fase 2: Unidades Cercanas (optimizado para escala)
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   - Columnas calculadas latnum/lngnum + indice para evitar
     calcular distancia trigonometrica sobre TODOS los conductores.
   - fn_ConductoresCercanos con filtro de "bounding box" previo.
   - sp_pasajero_ConductoresDisponibles respeta:
       kmsalaredondamascercanos   (radio en km)
       nounidadesmascercanas      (maximo de unidades, tope 5)
       sololaunidadmascercana     (solo la mas cercana)
   Script idempotente.
   ========================================================= */
USE vaia_viajes;
GO
/* Requerido para columnas calculadas PERSISTED e indices sobre ellas */
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

/* ---------- 1. Columnas calculadas + indice (bounding box) ---------- */
IF COL_LENGTH('tbconductorgps','latnum') IS NULL
    ALTER TABLE tbconductorgps ADD latnum AS (TRY_CAST(lat AS DECIMAL(18,10))) PERSISTED;
GO
IF COL_LENGTH('tbconductorgps','lngnum') IS NULL
    ALTER TABLE tbconductorgps ADD lngnum AS (TRY_CAST(lng AS DECIMAL(18,10))) PERSISTED;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tbconductorgps_latnum_lngnum' AND object_id = OBJECT_ID('tbconductorgps'))
    CREATE INDEX IX_tbconductorgps_latnum_lngnum ON tbconductorgps(latnum, lngnum);
GO

/* ---------- 2. Conductores cercanos con bounding box ---------- */
IF OBJECT_ID('dbo.fn_ConductoresCercanos','IF') IS NOT NULL
    DROP FUNCTION dbo.fn_ConductoresCercanos;
GO
CREATE FUNCTION fn_ConductoresCercanos (@lat VARCHAR(50), @lng VARCHAR(50), @radioKm INT, @limite INT, @idZona INT=NULL)
RETURNS TABLE AS RETURN (
SELECT TOP(@limite)
    c.id, c.nombre, c.appaterno, c.apmaterno, c.fotoperfil, c.correo, c.telefono, ISNULL(c.googlekey,'') AS googlekey,
    g.lat, g.lng,
    dbo.fn_CalcularDistancia(CAST(@lat AS DECIMAL(18,10)), CAST(@lng AS DECIMAL(18,10)), g.latnum, g.lngnum) AS distancia_km,
    u.id AS idunidad, u.unidad, u.alias, u.colorhex, u.colornombre, u.numeroasientos, u.placas,
    sm.nombresubmarca, m.nombremarca, ce.conductorestatus
FROM tbconductor c
INNER JOIN tbconductorgps g ON g.idconductor = c.id
INNER JOIN tbconductorestatus ce ON ce.id = c.idconductorestatus
LEFT JOIN tbconductorunidades cu ON cu.idconductor = c.id AND cu.enuso = 1 AND cu.aprobada = 1
LEFT JOIN tbunidad u ON u.id = cu.idunidad
LEFT JOIN tbsubmarca sm ON sm.id = u.idsubmarca
LEFT JOIN tbmarca m ON m.id = sm.idmarca
WHERE c.activo = 1 AND c.bloqueado = 0 AND c.documentacionaprobada = 1
  AND ce.conductorestatus = 'Disponible'
  AND g.latnum IS NOT NULL AND g.lngnum IS NOT NULL
  AND (@idZona IS NULL OR c.idzonacobertura = @idZona)
  /* Bounding box: usa el indice IX_tbconductorgps_latnum_lngnum antes de la trigonometria */
  AND g.latnum BETWEEN CAST(@lat AS DECIMAL(18,10)) - (@radioKm / 111.0)
                   AND CAST(@lat AS DECIMAL(18,10)) + (@radioKm / 111.0)
  AND g.lngnum BETWEEN CAST(@lng AS DECIMAL(18,10)) - (@radioKm / (111.0 * COS(RADIANS(CAST(@lat AS DECIMAL(18,10))))))
                   AND CAST(@lng AS DECIMAL(18,10)) + (@radioKm / (111.0 * COS(RADIANS(CAST(@lat AS DECIMAL(18,10))))))
  AND dbo.fn_CalcularDistancia(CAST(@lat AS DECIMAL(18,10)), CAST(@lng AS DECIMAL(18,10)), g.latnum, g.lngnum) <= @radioKm
)
GO

/* ---------- 3. SP de conductores disponibles (radio + maximo configurables) ---------- */
IF OBJECT_ID('dbo.sp_pasajero_ConductoresDisponibles','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_ConductoresDisponibles;
GO
CREATE PROCEDURE sp_pasajero_ConductoresDisponibles @lat VARCHAR(50), @lng VARCHAR(50), @idZona INT=NULL AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @radio INT, @max INT, @solo BIT;
    SELECT @radio = ISNULL(kmsalaredondamascercanos, 5),
           @max   = ISNULL(nounidadesmascercanas, 5),
           @solo  = ISNULL(sololaunidadmascercana, 0)
      FROM tbcompania WHERE activo = 1;

    IF @radio IS NULL OR @radio <= 0 SET @radio = 5;
    IF @max IS NULL OR @max <= 0 SET @max = 5;
    IF @max > 5 SET @max = 5;          /* maximo 5 unidades (requerimiento) */
    IF @solo = 1 SET @max = 1;         /* solo la mas cercana */

    SELECT * FROM dbo.fn_ConductoresCercanos(@lat, @lng, @radio, @max, @idZona) ORDER BY distancia_km;
END
GO

PRINT 'Fase 2 (unidades cercanas) instalada correctamente.';
GO
