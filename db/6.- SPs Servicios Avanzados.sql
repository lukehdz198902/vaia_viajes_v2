/*
 =============================================
 SCRIPT: SPs SERVICIOS AVANZADOS (PARADAS, PROGRAMADOS, ASIGNACION)
 =============================================
 Fecha: 2026
 Idempotente.
 =============================================
*/

USE vaia_viajes;
GO

PRINT '=============================================';
PRINT ' CREANDO SPs DE SERVICIOS AVANZADOS';
PRINT '=============================================';
GO

-- =============================================
-- PARADAS INTERMEDIAS
-- =============================================

PRINT 'sp_servicio_AgregarParada';
GO
CREATE PROCEDURE sp_servicio_AgregarParada
    @idservicio BIGINT, @orden TINYINT, @direccion VARCHAR(300), @lat VARCHAR(50), @lng VARCHAR(50),
    @referencia VARCHAR(200)=NULL, @notas VARCHAR(500)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idservicio)
        BEGIN SELECT -1 AS id, 'Servicio no encontrado' AS mensaje; RETURN; END
    IF EXISTS(SELECT 1 FROM tbservicioparadas WHERE idservicio=@idservicio AND orden=@orden AND activo=1)
        BEGIN SELECT -2 AS id, 'Ya existe una parada en ese orden' AS mensaje; RETURN; END
    INSERT INTO tbservicioparadas(idservicio, orden, direccion, lat, lng, referencia, notas)
    VALUES(@idservicio, @orden, @direccion, @lat, @lng, @referencia, @notas);
    UPDATE tbservicios SET totalparadas=(SELECT COUNT(*) FROM tbservicioparadas WHERE idservicio=@idservicio AND activo=1), ultimaactualizacion=GETDATE() WHERE id=@idservicio;
    SELECT SCOPE_IDENTITY() AS id, 'Parada agregada' AS mensaje;
END
GO

PRINT 'sp_servicio_ListarParadas';
GO
CREATE PROCEDURE sp_servicio_ListarParadas @idservicio BIGINT AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, idservicio, orden, direccion, lat, lng, referencia, notas, completada, fecha_completada, fechacreacion
    FROM tbservicioparadas WHERE idservicio=@idservicio AND activo=1 ORDER BY orden;
END
GO

PRINT 'sp_servicio_CompletarParada';
GO
CREATE PROCEDURE sp_servicio_CompletarParada @idParada BIGINT, @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @idservicio BIGINT;
    SELECT @idservicio=idservicio FROM tbservicioparadas WHERE id=@idParada;
    IF @idservicio IS NULL BEGIN SELECT -1 AS resultado, 'Parada no encontrada' AS mensaje; RETURN; END
    IF @idConductor > 0 AND NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idservicio AND idconductor=@idConductor)
        BEGIN SELECT -2 AS resultado, 'La parada no pertenece a este conductor' AS mensaje; RETURN; END
    UPDATE tbservicioparadas SET completada=1, fecha_completada=GETDATE(), ultimaactualizacion=GETDATE() WHERE id=@idParada;
    UPDATE tbservicios SET paradascompletadas=(SELECT COUNT(*) FROM tbservicioparadas WHERE idservicio=@idservicio AND activo=1 AND completada=1), ultimaactualizacion=GETDATE() WHERE id=@idservicio;
    SELECT 1 AS resultado, 'Parada completada' AS mensaje, @idservicio AS idservicio;
END
GO

PRINT 'sp_servicio_EliminarParada';
GO
CREATE PROCEDURE sp_servicio_EliminarParada @idParada BIGINT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @idservicio BIGINT;
    SELECT @idservicio=idservicio FROM tbservicioparadas WHERE id=@idParada;
    UPDATE tbservicioparadas SET activo=0, ultimaactualizacion=GETDATE() WHERE id=@idParada;
    IF @idservicio IS NOT NULL
        UPDATE tbservicios SET totalparadas=(SELECT COUNT(*) FROM tbservicioparadas WHERE idservicio=@idservicio AND activo=1), ultimaactualizacion=GETDATE() WHERE id=@idservicio;
    SELECT 1 AS resultado, 'Parada eliminada' AS mensaje;
END
GO

-- =============================================
-- SERVICIOS PROGRAMADOS
-- =============================================

PRINT 'sp_pasajero_ProgramarServicio';
GO
CREATE PROCEDURE sp_pasajero_ProgramarServicio
    @idPasajero BIGINT, @idCompania SMALLINT,
    @dirOrigen VARCHAR(300), @latOrigen VARCHAR(50), @lngOrigen VARCHAR(50),
    @dirDestino VARCHAR(300), @latDestino VARCHAR(50), @lngDestino VARCHAR(50),
    @fechaProgramada DATETIME, @paradasJson VARCHAR(MAX)=NULL,
    @idTipoPago SMALLINT=NULL, @codigoPromocional VARCHAR(100)=NULL,
    @anticipacionMinutos SMALLINT=15, @notas VARCHAR(500)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @fechaProgramada <= GETDATE()
        BEGIN SELECT -1 AS id, 'La fecha programada debe ser en el futuro' AS mensaje; RETURN; END
    INSERT INTO tbservicioprogramado(idpasajero, idcompania, direccionorigen, latorigen, lngorigen,
        direcciondestination, latdestination, lngdestination, paradas_json, fechaprogramada,
        anticipacion_minutos, idtipopago, codigo_promocional, notas)
    VALUES(@idPasajero, @idCompania, @dirOrigen, @latOrigen, @lngOrigen,
        @dirDestino, @latDestino, @lngDestino, @paradasJson, @fechaProgramada,
        @anticipacionMinutos, @idTipoPago, @codigoPromocional, @notas);
    SELECT SCOPE_IDENTITY() AS id, 'Servicio programado' AS mensaje;
END
GO

PRINT 'sp_pasajero_ListarServiciosProgramados';
GO
CREATE PROCEDURE sp_pasajero_ListarServiciosProgramados @idPasajero BIGINT, @estado VARCHAR(30)=NULL AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.*, se.estatus AS estatusServicioReal
    FROM tbservicioprogramado p
    LEFT JOIN tbservicios s ON s.id=p.idserviciogenerado
    LEFT JOIN tbservicioestatus se ON se.id=s.idservicioestatus
    WHERE p.idpasajero=@idPasajero AND p.activo=1 AND (@estado IS NULL OR p.estado=@estado)
    ORDER BY p.fechaprogramada ASC;
END
GO

PRINT 'sp_pasajero_ObtenerServicioProgramado';
GO
CREATE PROCEDURE sp_pasajero_ObtenerServicioProgramado @id BIGINT, @idPasajero BIGINT AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM tbservicioprogramado WHERE id=@id AND idpasajero=@idPasajero AND activo=1;
END
GO

PRINT 'sp_pasajero_CancelarServicioProgramado';
GO
CREATE PROCEDURE sp_pasajero_CancelarServicioProgramado @id BIGINT, @idPasajero BIGINT, @motivo VARCHAR(500)=NULL AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM tbservicioprogramado WHERE id=@id AND idpasajero=@idPasajero AND activo=1)
        BEGIN SELECT -1 AS resultado, 'Servicio programado no encontrado' AS mensaje; RETURN; END
    IF EXISTS(SELECT 1 FROM tbservicioprogramado WHERE id=@id AND estado IN ('EnCurso','Completado'))
        BEGIN SELECT -2 AS resultado, 'El servicio ya no puede cancelarse' AS mensaje; RETURN; END
    UPDATE tbservicioprogramado SET estado='Cancelado', notas=ISNULL(@motivo,notas), ultimaactualizacion=GETDATE() WHERE id=@id;
    SELECT 1 AS resultado, 'Servicio programado cancelado' AS mensaje;
END
GO

PRINT 'sp_sistema_ObtenerProgramadosPendientes';
GO
CREATE PROCEDURE sp_sistema_ObtenerProgramadosPendientes AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.*
    FROM tbservicioprogramado p
    WHERE p.activo=1 AND p.estado='Programado'
      AND p.fechaprogramada <= DATEADD(MINUTE, p.anticipacion_minutos, GETDATE())
    ORDER BY p.fechaprogramada ASC;
END
GO

PRINT 'sp_sistema_MaterializarProgramado';
GO
CREATE PROCEDURE sp_sistema_MaterializarProgramado @id BIGINT, @idServicioGenerado BIGINT AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tbservicioprogramado SET estado='EnCola', idserviciogenerado=@idServicioGenerado, ultimaactualizacion=GETDATE() WHERE id=@id;
    SELECT 1 AS resultado, 'Programado materializado' AS mensaje;
END
GO

-- =============================================
-- ASIGNACION AUTOMATICA
-- =============================================

PRINT 'sp_sistema_ObtenerServiciosSinAsignar';
GO
CREATE PROCEDURE sp_sistema_ObtenerServiciosSinAsignar @limite INT=20 AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP(@limite) s.id, s.idpasajero, p.idcompania, s.direccionorigen, s.latorigen, s.lngorigen,
           s.direcciondestination, s.latdestination, s.lngdestination, s.costoestimado,
           s.distanciametros, s.fechacreacion, s.intentosAsignacion, s.ultimaconductorasignado,
           s.fechaexpiracionsolicitud
    FROM tbservicios s
    INNER JOIN tbpasajero p ON p.id=s.idpasajero
    WHERE s.idconductor IS NULL
      AND s.idservicioestatus=(SELECT id FROM tbservicioestatus WHERE estatus='Solicitado' AND activo=1)
      AND (s.fechaexpiracionsolicitud IS NULL OR s.fechaexpiracionsolicitud > GETDATE())
    ORDER BY s.fechacreacion ASC;
END
GO

PRINT 'sp_sistema_RegistrarAsignacionLog';
GO
CREATE PROCEDURE sp_sistema_RegistrarAsignacionLog
    @idservicio BIGINT, @idconductor INT=NULL, @evento VARCHAR(50), @detalle VARCHAR(500)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO tbservicioasignacionlog(idservicio, idconductor, evento, detalle)
    VALUES(@idservicio, @idconductor, @evento, @detalle);
    SELECT 1 AS resultado, 'Log registrado' AS mensaje;
END
GO

PRINT 'sp_sistema_IncrementarIntentoAsignacion';
GO
CREATE PROCEDURE sp_sistema_IncrementarIntentoAsignacion @idservicio BIGINT, @idconductor INT=NULL AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tbservicios SET intentosasignacion=ISNULL(intentosasignacion,0)+1,
        ultimaconductorasignado=ISNULL(@idconductor, ultimaconductorasignado),
        ultimaactualizacion=GETDATE()
    WHERE id=@idservicio;
    SELECT 1 AS resultado, 'Intento registrado' AS mensaje;
END
GO

PRINT 'sp_sistema_ExpirarSolicitud';
GO
CREATE PROCEDURE sp_sistema_ExpirarSolicitud @idservicio BIGINT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sinAsignar SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='Cancelado por Admin' AND activo=1);
    UPDATE tbservicios SET idservicioestatus=@sinAsignar, motivocancelacion='Sin conductor disponible',
        canceladopor='sistema', fechacancelacion=GETDATE(), ultimaactualizacion=GETDATE()
    WHERE id=@idservicio AND idconductor IS NULL;
    SELECT 1 AS resultado, 'Solicitud expirada' AS mensaje;
END
GO

PRINT 'sp_conductor_RechazarServicio';
GO
CREATE PROCEDURE sp_conductor_RechazarServicio @idservicio BIGINT, @idconductor INT, @motivo VARCHAR(300)=NULL AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO tbservicioasignacionlog(idservicio, idconductor, evento, detalle)
    VALUES(@idservicio, @idconductor, 'RECHAZO', ISNULL(@motivo,'Conductor rechazo la solicitud'));
    UPDATE tbservicios SET intentosasignacion=ISNULL(intentosasignacion,0)+1, ultimaconductorasignado=@idconductor, ultimaactualizacion=GETDATE() WHERE id=@idservicio;
    SELECT 1 AS resultado, 'Servicio rechazado' AS mensaje;
END
GO

PRINT 'sp_servicio_MarcarComoProgramado';
GO
CREATE PROCEDURE sp_servicio_MarcarComoProgramado @idservicio BIGINT, @idprogramado BIGINT, @fechaprogramada DATETIME=NULL AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tbservicios SET esprogramado=1, idprogramado=@idprogramado, fechaprogramada=ISNULL(@fechaprogramada, fechaprogramada), ultimaactualizacion=GETDATE()
    WHERE id=@idservicio;
    SELECT 1 AS resultado, 'Servicio marcado como programado' AS mensaje;
END
GO

PRINT '';
PRINT '=============================================';
PRINT ' SPs DE SERVICIOS AVANZADOS CREADOS';
PRINT '=============================================';
GO