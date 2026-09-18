/* =========================================================
   14.- Fase 5: Analitica de Zonas y Demanda
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   - Demanda por hora y dia de la semana (mapa de calor)
   - Ranking de zonas con promedio diario
   - Puntos de origen (para mapa de calor)
   - Prediccion simple (promedio historico por zona/hora)
   - Conductores disponibles por zona (oferta vs demanda)
   Script idempotente.
   ========================================================= */
USE vaia_viajes;
GO

/* ---------- 1. Demanda por hora y dia de la semana ---------- */
IF OBJECT_ID('dbo.sp_admin_DemandaPorHoraDia','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_admin_DemandaPorHoraDia;
GO
CREATE PROCEDURE sp_admin_DemandaPorHoraDia @dias INT = 30 AS
BEGIN
    SET NOCOUNT ON;
    SELECT DATEPART(WEEKDAY, h.fechaconsulta) AS diassemana,
           DATEPART(HOUR, h.fechaconsulta) AS hora,
           COUNT(*) AS solicitudes
      FROM tbhistoriallatlngconsultadapasajero h
     WHERE h.fechaconsulta >= DATEADD(DAY, -@dias, GETDATE())
     GROUP BY DATEPART(WEEKDAY, h.fechaconsulta), DATEPART(HOUR, h.fechaconsulta)
     ORDER BY diassemana, hora;
END
GO

/* ---------- 2. Ranking de zonas ---------- */
IF OBJECT_ID('dbo.sp_admin_ZonasRanking','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_admin_ZonasRanking;
GO
CREATE PROCEDURE sp_admin_ZonasRanking @dias INT = 30 AS
BEGIN
    SET NOCOUNT ON;
    SELECT z.id AS idzona,
           z.nombrezona,
           COUNT(h.idpasajero) AS solicitudes,
           COUNT(DISTINCT CAST(h.fechaconsulta AS DATE)) AS diasconactividad,
           CASE WHEN COUNT(DISTINCT CAST(h.fechaconsulta AS DATE)) > 0
                THEN CAST(COUNT(h.idpasajero) * 1.0 / COUNT(DISTINCT CAST(h.fechaconsulta AS DATE)) AS DECIMAL(10,2))
                ELSE CAST(0 AS DECIMAL(10,2)) END AS promediodiario
      FROM tbzonacobertura z
      LEFT JOIN tbhistoriallatlngconsultadapasajero h
        ON h.fechaconsulta >= DATEADD(DAY, -@dias, GETDATE())
       AND ISNULL(z.radio_km,0) > 0
       AND dbo.fn_CalcularDistancia(
              TRY_CAST(z.latitudcentro AS DECIMAL(18,10)),
              TRY_CAST(z.longitudcentro AS DECIMAL(18,10)),
              TRY_CAST(h.lat AS DECIMAL(18,10)),
              TRY_CAST(h.lng AS DECIMAL(18,10))
           ) <= z.radio_km
     WHERE ISNULL(z.activo,1) = 1
     GROUP BY z.id, z.nombrezona
     ORDER BY solicitudes DESC;
END
GO

/* ---------- 3. Puntos de origen (mapa de calor) ---------- */
IF OBJECT_ID('dbo.sp_admin_OrigenesPuntos','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_admin_OrigenesPuntos;
GO
CREATE PROCEDURE sp_admin_OrigenesPuntos @dias INT = 30, @limite INT = 2000 AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP(@limite)
           TRY_CAST(h.lat AS DECIMAL(18,10)) AS lat,
           TRY_CAST(h.lng AS DECIMAL(18,10)) AS lng,
           h.fechaconsulta
      FROM tbhistoriallatlngconsultadapasajero h
     WHERE h.fechaconsulta >= DATEADD(DAY, -@dias, GETDATE())
       AND h.lat IS NOT NULL AND h.lng IS NOT NULL
     ORDER BY h.fechaconsulta DESC;
END
GO

/* ---------- 4. Prediccion: promedio por zona y hora ---------- */
IF OBJECT_ID('dbo.sp_admin_PrediccionDemanda','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_admin_PrediccionDemanda;
GO
CREATE PROCEDURE sp_admin_PrediccionDemanda @dias INT = 30 AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @diasEfectivos INT = CASE WHEN @dias <= 0 THEN 1 ELSE @dias END;

    SELECT z.id AS idzona,
           z.nombrezona,
           DATEPART(HOUR, h.fechaconsulta) AS hora,
           CAST(COUNT(*) * 1.0 / @diasEfectivos AS DECIMAL(10,2)) AS promediodiario
      FROM tbhistoriallatlngconsultadapasajero h
      INNER JOIN tbzonacobertura z
        ON ISNULL(z.activo,1) = 1
       AND ISNULL(z.radio_km,0) > 0
       AND dbo.fn_CalcularDistancia(
              TRY_CAST(z.latitudcentro AS DECIMAL(18,10)),
              TRY_CAST(z.longitudcentro AS DECIMAL(18,10)),
              TRY_CAST(h.lat AS DECIMAL(18,10)),
              TRY_CAST(h.lng AS DECIMAL(18,10))
           ) <= z.radio_km
     WHERE h.fechaconsulta >= DATEADD(DAY, -@dias, GETDATE())
     GROUP BY z.id, z.nombrezona, DATEPART(HOUR, h.fechaconsulta)
     ORDER BY promediodiario DESC;
END
GO

/* ---------- 5. Conductores disponibles por zona (oferta vs demanda) ---------- */
IF OBJECT_ID('dbo.sp_admin_ConductoresPorZona','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_admin_ConductoresPorZona;
GO
CREATE PROCEDURE sp_admin_ConductoresPorZona AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @disponible SMALLINT = (SELECT TOP 1 id FROM tbconductorestatus WHERE conductorestatus='Disponible' AND activo=1);
    SELECT z.id AS idzona,
           z.nombrezona,
           COUNT(c.id) AS conductoresdisponibles
      FROM tbzonacobertura z
      LEFT JOIN tbconductor c
        ON c.idzonacobertura = z.id
       AND c.conectado = 1
       AND ISNULL(c.bloqueado,0) = 0
       AND c.idconductorestatus = @disponible
     WHERE ISNULL(z.activo,1) = 1
     GROUP BY z.id, z.nombrezona
     ORDER BY conductoresdisponibles DESC;
END
GO

PRINT 'Fase 5 (analitica de zonas) instalada correctamente.';
GO
