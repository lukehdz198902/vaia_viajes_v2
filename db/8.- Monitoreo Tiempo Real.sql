/* =========================================================
   8.- Monitoreo en Tiempo Real  (optimizado para escala)
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   Conductores:
     - Ubicacion actual en tbconductorgps (1 fila/conductor)
     - Historial THROTTLED (max 1 registro cada 2 min por conductor)
     - Heartbeat (ultimolatido) para saber quien esta conectado
     - Auto-desconexion de inactivos
   Pasajeros:
     - SIN reporte de ubicacion constante. Solo heartbeat ligero.
     - Se guarda el ORIGEN cuando solicita un servicio (para
       predecir zonas y horarios con mas demanda).
   Analitica:
     - Origenes por zona, solicitudes por hora, pasajeros activos
       por periodo.
   Script idempotente: puede ejecutarse varias veces.
   ========================================================= */
USE vaia_viajes;
GO

/* ---------- 1. Columnas de heartbeat ---------- */
IF COL_LENGTH('tbconductor','ultimolatido') IS NULL
    ALTER TABLE tbconductor ADD ultimolatido DATETIME NULL;
GO
IF COL_LENGTH('tbpasajero','ultimolatido') IS NULL
    ALTER TABLE tbpasajero ADD ultimolatido DATETIME NULL;
GO

/* ---------- 2. Indices para escala ---------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tbconductorgps_idconductor' AND object_id = OBJECT_ID('tbconductorgps'))
    CREATE INDEX IX_tbconductorgps_idconductor ON tbconductorgps(idconductor);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tbconductorgpshistory_conductor_fecha' AND object_id = OBJECT_ID('tbconductorgpshistory'))
    CREATE INDEX IX_tbconductorgpshistory_conductor_fecha ON tbconductorgpshistory(idconductor, fechacreacion);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tbconductor_conectado_latido' AND object_id = OBJECT_ID('tbconductor'))
    CREATE INDEX IX_tbconductor_conectado_latido ON tbconductor(conectado, ultimolatido);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tbhistlatlng_fecha' AND object_id = OBJECT_ID('tbhistoriallatlngconsultadapasajero'))
    CREATE INDEX IX_tbhistlatlng_fecha ON tbhistoriallatlngconsultadapasajero(fechaconsulta);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tbhistlatlng_pasajero' AND object_id = OBJECT_ID('tbhistoriallatlngconsultadapasajero'))
    CREATE INDEX IX_tbhistlatlng_pasajero ON tbhistoriallatlngconsultadapasajero(idpasajero);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tbsesion_tipo_activo' AND object_id = OBJECT_ID('tbsesionusuario'))
    CREATE INDEX IX_tbsesion_tipo_activo ON tbsesionusuario(idtipousuario, activo, fechaconexion);
GO

/* ---------- 3. Ubicacion GPS del conductor (UPSERT + historial throttled) ---------- */
IF OBJECT_ID('dbo.sp_conductor_ActualizarUbicacionGPS','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_ActualizarUbicacionGPS;
GO
CREATE PROCEDURE sp_conductor_ActualizarUbicacionGPS @idConductor INT, @lat VARCHAR(50), @lng VARCHAR(50) AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM tbconductorgps WHERE idconductor = @idConductor)
    BEGIN
        UPDATE tbconductorgps
           SET previouslat = lat,
               previouslng = lng,
               lat = @lat,
               lng = @lng,
               lastposition = GETDATE(),
               ultimaactualizacion = GETDATE()
         WHERE idconductor = @idConductor;
    END
    ELSE
    BEGIN
        INSERT INTO tbconductorgps(idconductor, lat, lng, lastposition, previouslat, previouslng, fechacreacion, ultimaactualizacion)
        VALUES (@idConductor, @lat, @lng, GETDATE(), @lat, @lng, GETDATE(), GETDATE());
    END

    /* Historial acotado: max 1 registro cada 2 minutos por conductor
       (evita que miles de conductores generen millones de filas) */
    INSERT INTO tbconductorgpshistory(idconductor, lat, lng, idconductorestatus)
    SELECT @idConductor, @lat, @lng, idconductorestatus
      FROM tbconductor
     WHERE id = @idConductor
       AND NOT EXISTS (SELECT 1 FROM tbconductorgpshistory h
                        WHERE h.idconductor = @idConductor
                          AND h.fechacreacion > DATEADD(SECOND, -120, GETDATE()));

    UPDATE tbconductor SET ultimolatido = GETDATE() WHERE id = @idConductor;

    SELECT 1 AS resultado, 'Ubicacion actualizada' AS mensaje;
END
GO

/* ---------- 4. Latido del conductor ---------- */
IF OBJECT_ID('dbo.sp_conductor_Latido','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_Latido;
GO
CREATE PROCEDURE sp_conductor_Latido @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    /* Si estaba desconectado, inicia una nueva sesion */
    UPDATE tbconductor
       SET ultimaconexionusr = CASE WHEN ISNULL(conectado,0) = 0 THEN GETDATE() ELSE ultimaconexionusr END,
           conectado = 1,
           ultimolatido = GETDATE()
     WHERE id = @idConductor;
    SELECT 1 AS resultado, 'Latido registrado' AS mensaje;
END
GO

/* ---------- 5. Registrar ORIGEN solicitado por el pasajero ---------- */
/* Se llama UNA vez por solicitud (no por GPS). Sirve para predecir
   zonas y horarios con mas demanda. */
IF OBJECT_ID('dbo.sp_pasajero_RegistrarOrigen','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_RegistrarOrigen;
GO
CREATE PROCEDURE sp_pasajero_RegistrarOrigen @idPasajero BIGINT, @lat VARCHAR(100), @lng VARCHAR(100) AS
BEGIN
    SET NOCOUNT ON;
    IF @idPasajero IS NULL OR @idPasajero <= 0 OR @lat IS NULL OR @lng IS NULL
    BEGIN
        SELECT 0 AS resultado, 'Datos incompletos' AS mensaje;
        RETURN;
    END

    INSERT INTO tbhistoriallatlngconsultadapasajero(idpasajero, lat, lng)
    VALUES (@idPasajero, @lat, @lng);

    SELECT 1 AS resultado, 'Origen registrado' AS mensaje;
END
GO

/* (Obsoleto) Se elimina el reporte constante de ubicacion del pasajero */
IF OBJECT_ID('dbo.sp_pasajero_ActualizarUbicacionGPS','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_ActualizarUbicacionGPS;
GO

/* ---------- 6. Latido del pasajero (presencia ligera) ---------- */
IF OBJECT_ID('dbo.sp_pasajero_Latido','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_Latido;
GO
CREATE PROCEDURE sp_pasajero_Latido @idPasajero BIGINT AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tbpasajero
       SET ultimaconexionusr = CASE WHEN ISNULL(conectado,0) = 0 THEN GETDATE() ELSE ultimaconexionusr END,
           conectado = 1,
           ultimolatido = GETDATE()
     WHERE id = @idPasajero;
    SELECT 1 AS resultado, 'Latido registrado' AS mensaje;
END
GO

/* ---------- 7. Limpieza de conductores inactivos ---------- */
IF OBJECT_ID('dbo.sp_sistema_MarcarConductoresInactivos','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_sistema_MarcarConductoresInactivos;
GO
CREATE PROCEDURE sp_sistema_MarcarConductoresInactivos @segundos INT = 120 AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @desconectado SMALLINT = (SELECT TOP 1 id FROM tbconductorestatus WHERE conductorestatus = 'Desconectado' AND activo = 1);

    DECLARE @inactivos TABLE (idconductor INT);
    INSERT INTO @inactivos(idconductor)
    SELECT id FROM tbconductor
     WHERE conectado = 1
       AND ISNULL(bloqueado,0) = 0
       AND (ultimolatido IS NULL OR DATEDIFF(SECOND, ultimolatido, GETDATE()) > @segundos);

    UPDATE c
       SET c.conectado = 0,
           c.ultimadesconexionusr = GETDATE(),
           c.idconductorestatus = ISNULL(@desconectado, c.idconductorestatus),
           c.ultimaactualizacion = GETDATE()
      FROM tbconductor c
      INNER JOIN @inactivos i ON i.idconductor = c.id;

    INSERT INTO tbhistorialconexionesconductor(idconductor, conectado, fechaconexion)
    SELECT idconductor, 0, GETDATE() FROM @inactivos;

    SELECT (SELECT COUNT(*) FROM @inactivos) AS afectados, 'Limpieza completada' AS mensaje;
END
GO

/* ---------- 7b. Limpieza de pasajeros inactivos ---------- */
IF OBJECT_ID('dbo.sp_sistema_MarcarPasajerosInactivos','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_sistema_MarcarPasajerosInactivos;
GO
CREATE PROCEDURE sp_sistema_MarcarPasajerosInactivos @segundos INT = 180 AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @inactivos TABLE (idpasajero BIGINT);
    INSERT INTO @inactivos(idpasajero)
    SELECT id FROM tbpasajero
     WHERE conectado = 1
       AND ISNULL(bloqueado,0) = 0
       AND (ultimolatido IS NULL OR DATEDIFF(SECOND, ultimolatido, GETDATE()) > @segundos);

    UPDATE p
       SET p.conectado = 0,
           p.ultimadesconexionusr = GETDATE(),
           p.ultimaactualizacion = GETDATE()
      FROM tbpasajero p
      INNER JOIN @inactivos i ON i.idpasajero = p.id;

    INSERT INTO tbhistorialconexionespasajero(idpasajero, conectado, fechaconexion)
    SELECT idpasajero, 0, GETDATE() FROM @inactivos;

    SELECT (SELECT COUNT(*) FROM @inactivos) AS afectados, 'Limpieza completada' AS mensaje;
END
GO

/* ---------- 8. Monitoreo: conductores conectados ---------- */
IF OBJECT_ID('dbo.sp_admin_ConductoresConectados','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_admin_ConductoresConectados;
GO
CREATE PROCEDURE sp_admin_ConductoresConectados @limite INT = 1000 AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@limite)
           c.id,
           c.nombre, c.appaterno, c.apmaterno,
           c.account, c.correo, c.telefono,
           c.conectado, c.ultimaconexionusr, c.ultimolatido,
           DATEDIFF(MINUTE, c.ultimaconexionusr, GETDATE()) AS minutosconectado,
           ce.conductorestatus AS estatus,
           g.lat, g.lng, g.lastposition,
           z.nombrezona
      FROM tbconductor c
      LEFT JOIN tbconductorestatus ce ON ce.id = c.idconductorestatus
      LEFT JOIN tbconductorgps g ON g.idconductor = c.id
      LEFT JOIN tbzonacobertura z ON z.id = c.idzonacobertura
     WHERE c.conectado = 1
       AND ISNULL(c.bloqueado,0) = 0
     ORDER BY c.ultimolatido DESC;
END
GO

/* ---------- 9. Monitoreo: pasajeros usando la app (sin ubicacion) ---------- */
IF OBJECT_ID('dbo.sp_admin_PasajerosConectados','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_admin_PasajerosConectados;
GO
CREATE PROCEDURE sp_admin_PasajerosConectados @limite INT = 1000 AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@limite)
           p.id,
           p.nombre, p.appaterno, p.apmaterno,
           p.account, p.correo, p.telefono,
           p.conectado, p.ultimaconexionusr, p.ultimolatido,
           DATEDIFF(MINUTE, p.ultimaconexionusr, GETDATE()) AS minutosconectado
      FROM tbpasajero p
     WHERE p.conectado = 1
       AND ISNULL(p.bloqueado,0) = 0
     ORDER BY p.ultimolatido DESC;
END
GO

/* ---------- 10. Monitoreo: resumen ---------- */
IF OBJECT_ID('dbo.sp_admin_ResumenMonitoreo','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_admin_ResumenMonitoreo;
GO
CREATE PROCEDURE sp_admin_ResumenMonitoreo AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @disponible SMALLINT = (SELECT TOP 1 id FROM tbconductorestatus WHERE conductorestatus = 'Disponible' AND activo = 1);

    SELECT
        (SELECT COUNT(*) FROM tbconductor WHERE conectado = 1 AND ISNULL(bloqueado,0) = 0) AS conductoresconectados,
        (SELECT COUNT(*) FROM tbconductor WHERE conectado = 1 AND ISNULL(bloqueado,0) = 0 AND idconductorestatus = @disponible) AS conductoresdisponibles,
        (SELECT COUNT(*) FROM tbpasajero WHERE conectado = 1 AND ISNULL(bloqueado,0) = 0) AS pasajerosconectados,
        (SELECT COUNT(*) FROM tbservicios s
          WHERE s.idservicioestatus IN (SELECT id FROM tbservicioestatus
                                         WHERE estatus IN ('Solicitado','En Camino','Llego al Origen','En Viaje'))) AS serviciosactivos;
END
GO

/* ---------- 11. Analitica: origenes (solicitudes) por zona ---------- */
IF OBJECT_ID('dbo.sp_admin_OrigenesPorZona','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_admin_OrigenesPorZona;
GO
CREATE PROCEDURE sp_admin_OrigenesPorZona @dias INT = 7 AS
BEGIN
    SET NOCOUNT ON;
    SELECT z.id AS idzona,
           z.nombrezona,
           COUNT(h.idpasajero) AS solicitudes
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

/* ---------- 12. Analitica: solicitudes por hora del dia ---------- */
IF OBJECT_ID('dbo.sp_admin_SolicitudesPorHora','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_admin_SolicitudesPorHora;
GO
CREATE PROCEDURE sp_admin_SolicitudesPorHora @dias INT = 7 AS
BEGIN
    SET NOCOUNT ON;
    SELECT DATEPART(HOUR, h.fechaconsulta) AS hora,
           COUNT(*) AS solicitudes
      FROM tbhistoriallatlngconsultadapasajero h
     WHERE h.fechaconsulta >= DATEADD(DAY, -@dias, GETDATE())
     GROUP BY DATEPART(HOUR, h.fechaconsulta)
     ORDER BY hora;
END
GO

/* ---------- 13. Analitica: pasajeros activos por dia ---------- */
IF OBJECT_ID('dbo.sp_admin_PasajerosActivosPorPeriodo','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_admin_PasajerosActivosPorPeriodo;
GO
CREATE PROCEDURE sp_admin_PasajerosActivosPorPeriodo @dias INT = 7 AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(s.fechaconexion AS DATE) AS dia,
           COUNT(DISTINCT s.idpasajero) AS pasajerosactivos,
           COUNT(*) AS sesiones
      FROM tbsesionusuario s
     WHERE s.idtipousuario = 1
       AND s.fechaconexion >= DATEADD(DAY, -@dias, GETDATE())
     GROUP BY CAST(s.fechaconexion AS DATE)
     ORDER BY dia;
END
GO

PRINT 'Monitoreo en tiempo real (escala) instalado correctamente.';
GO
