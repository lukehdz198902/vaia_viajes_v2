/* =========================================================
   10.- Fase 3: Flujo de Asignacion
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   - Codigo de inicio de 4 digitos aleatorio por servicio
   - Tiempo de respuesta por conductor configurable
     (tbcompania.segesperatomaservicio)
   - Reasignacion sin repetir conductor
     (tbserviciosconductoresnotificados)
   Script idempotente.
   ========================================================= */
USE vaia_viajes;
GO

/* ---------- 1. Columnas nuevas en tbservicios ---------- */
IF COL_LENGTH('tbservicios','codigoinicio') IS NULL
    ALTER TABLE tbservicios ADD codigoinicio VARCHAR(10) NULL;
GO
IF COL_LENGTH('tbservicios','fechaexpiracionasignacion') IS NULL
    ALTER TABLE tbservicios ADD fechaexpiracionasignacion DATETIME NULL;
GO

/* ---------- 2. Indice para notificados ---------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_serviciosconductoresnotificados' AND object_id = OBJECT_ID('tbserviciosconductoresnotificados'))
    CREATE INDEX IX_serviciosconductoresnotificados ON tbserviciosconductoresnotificados(idservicio, idconductor);
GO

/* ---------- 3. Solicitar servicio: genera codigo de 4 digitos ---------- */
IF OBJECT_ID('dbo.sp_pasajero_SolicitarServicio','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_SolicitarServicio;
GO
CREATE PROCEDURE sp_pasajero_SolicitarServicio
@idPasajero BIGINT, @idCompania SMALLINT, @dirOrigen VARCHAR(300), @latOrigen VARCHAR(50), @lngOrigen VARCHAR(50),
@dirDestino VARCHAR(300), @latDestino VARCHAR(50), @lngDestino VARCHAR(50), @distanciaMetros INT,
@idTipoPago SMALLINT, @codigoPromocional VARCHAR(100)=NULL, @so VARCHAR(100)=NULL, @tipoviaje VARCHAR(50)='URBANO'
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY
DECLARE @costo DECIMAL(18,2), @idCodPromo INT, @desc DECIMAL(18,2)=0, @dur INT=@distanciaMetros/250*60;
DECLARE @idZona INT, @kms INT, @numUnid INT;
SELECT @kms=kmsalaredondamascercanos,@numUnid=nounidadesmascercanas FROM tbcompania WHERE id=@idCompania;
SELECT @idZona=id FROM tbzonacobertura WHERE activo=1 AND dbo.fn_CalcularDistancia(CAST(@latOrigen AS DECIMAL(18,10)),CAST(@lngOrigen AS DECIMAL(18,10)),CAST(ISNULL(latitudcentro,'0') AS DECIMAL(18,10)),CAST(ISNULL(longitudcentro,'0') AS DECIMAL(18,10))) <= radio_km;
IF @codigoPromocional IS NOT NULL BEGIN
DECLARE @pr TABLE(v BIT,m VARCHAR(500),md DECIMAL(18,2),ep BIT,ic INT);
INSERT INTO @pr EXEC sp_pasajero_ValidarCodigoPromocional @codigoPromocional,@idPasajero,@costo;
SELECT @idCodPromo=ic,@desc=md FROM @pr WHERE v=1;
END
SET @costo = dbo.fn_CalcularCostoViaje(@idCompania,@distanciaMetros,@dur,GETDATE())-@desc;
IF @costo<0 SET @costo=0;

/* Codigo de inicio aleatorio de 4 digitos (con ceros a la izquierda) */
DECLARE @codigo VARCHAR(10)=RIGHT('0000'+CAST(ABS(CHECKSUM(NEWID()))%10000 AS VARCHAR(4)),4);

INSERT INTO tbservicios(idconductor,idpasajero,idservicioestatus,direccionorigen,latorigen,lngorigen,direcciondestination,latdestination,lngdestination,costoestimado,distanciametros,idtipopago,idcodigopromo,montodescuento,so,tipoviaje,durationsegundos,codigoinicio)
VALUES(NULL,@idPasajero,(SELECT id FROM tbservicioestatus WHERE estatus='Solicitado' AND activo=1),@dirOrigen,@latOrigen,@lngOrigen,@dirDestino,@latDestino,@lngDestino,@costo,@distanciaMetros,@idTipoPago,@idCodPromo,@desc,@so,@tipoviaje,@dur,@codigo);
DECLARE @idServ BIGINT=SCOPE_IDENTITY();
INSERT INTO tbhistoriallatlngconsultadapasajero(idpasajero,lat,lng) VALUES(@idPasajero,@latOrigen,@lngOrigen);
IF @idCodPromo IS NOT NULL BEGIN
UPDATE tbcodigospromo SET usosactuales=usosactuales+1 WHERE id=@idCodPromo;
INSERT INTO tbcodigospromousados(idpasajero,idcodigopromo,idservicio) VALUES(@idPasajero,@idCodPromo,@idServ);
END
SELECT @idServ AS idservicio, @costo AS costoestimado, @distanciaMetros AS distanciametros, @dur AS duracionsegundos, @desc AS montodescuento, @codigo AS codigoinicio, 'Servicio solicitado' AS mensaje;
END TRY
BEGIN CATCH SELECT -99 AS idservicio, ERROR_MESSAGE() AS mensaje; END CATCH
END
GO

/* ---------- 4. Estado del servicio: incluye el codigo de inicio ---------- */
IF OBJECT_ID('dbo.sp_pasajero_ObtenerEstadoServicio','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_ObtenerEstadoServicio;
GO
CREATE PROCEDURE sp_pasajero_ObtenerEstadoServicio @idServicio BIGINT, @idPasajero BIGINT AS
BEGIN
SET NOCOUNT ON;
SELECT s.id,s.idservicioestatus,se.estatus,se.estatusdescription,s.direccionorigen,s.latorigen,s.lngorigen,s.direcciondestination,s.latdestination,s.lngdestination,
s.costoestimado,s.distanciametros,s.durationsegundos,s.montodescuento,s.servicioiniciado,s.llegoalorigen,s.llegoasudestino,s.fechacreacion,s.fechaservicioiniciado,
s.fechallegoalorigen,s.fechallegoasudestino,s.alarmasospasajero,s.alarmasosconductor,s.sesalioderuta,s.motivocancelacion,s.canceladopor,s.fechacancelacion,
s.calificacion,s.idconductor,s.codigoinicio,c.nombre AS conductor_nombre,c.appaterno AS conductor_appaterno,c.fotoperfil AS conductor_foto,c.telefono AS conductor_telefono,u.unidad,u.colorhex,u.colornombre,u.numeroasientos,u.placas,sm.nombresubmarca,m.nombremarca,g.lat AS conductor_lat,g.lng AS conductor_lng
FROM tbservicios s INNER JOIN tbservicioestatus se ON se.id=s.idservicioestatus
LEFT JOIN tbconductor c ON c.id=s.idconductor LEFT JOIN tbconductorunidades cu ON cu.idconductor=c.id AND cu.enuso=1
LEFT JOIN tbunidad u ON u.id=cu.idunidad LEFT JOIN tbsubmarca sm ON sm.id=u.idsubmarca
LEFT JOIN tbmarca m ON m.id=sm.idmarca LEFT JOIN tbconductorgps g ON g.idconductor=c.id
WHERE s.id=@idServicio AND s.idpasajero=@idPasajero;
END
GO

/* ---------- 5. Conductor inicia viaje validando el codigo ---------- */
IF OBJECT_ID('dbo.sp_conductor_IniciarViaje','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_IniciarViaje;
GO
CREATE PROCEDURE sp_conductor_IniciarViaje @idServicio BIGINT, @idConductor INT, @codigoInicio VARCHAR(10)=NULL AS
BEGIN
SET NOCOUNT ON;
DECLARE @llego SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='Llego al Origen' AND activo=1);
DECLARE @viaje SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='En Viaje' AND activo=1);

IF NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idServicio AND idconductor=@idConductor)
BEGIN SELECT -1 AS resultado,'Servicio no encontrado' AS mensaje; RETURN; END

DECLARE @codigoGuardado VARCHAR(10)=(SELECT codigoinicio FROM tbservicios WHERE id=@idServicio);
IF @codigoGuardado IS NOT NULL AND LTRIM(RTRIM(ISNULL(@codigoInicio,''))) <> @codigoGuardado
BEGIN SELECT -2 AS resultado,'Codigo de inicio incorrecto' AS mensaje; RETURN; END

IF NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idServicio AND idconductor=@idConductor AND idservicioestatus=@llego)
BEGIN SELECT -3 AS resultado,'El viaje no puede iniciarse en el estatus actual' AS mensaje; RETURN; END

UPDATE tbservicios SET idservicioestatus=@viaje,servicioiniciado=1,fechaservicioiniciado=GETDATE(),ultimaactualizacion=GETDATE() WHERE id=@idServicio AND idconductor=@idConductor;
SELECT 1 AS resultado,'Viaje iniciado' AS mensaje;
END
GO

/* ---------- 6. Servicios listos para asignar (respeta el tiempo de respuesta) ---------- */
IF OBJECT_ID('dbo.sp_sistema_ObtenerServiciosSinAsignar','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_sistema_ObtenerServiciosSinAsignar;
GO
CREATE PROCEDURE sp_sistema_ObtenerServiciosSinAsignar @limite INT=20 AS
BEGIN
SET NOCOUNT ON;
SELECT TOP(@limite) s.id, s.idpasajero, p.idcompania, s.direccionorigen, s.latorigen, s.lngorigen,
s.direcciondestination, s.latdestination, s.lngdestination, s.costoestimado, s.codigoinicio,
s.distanciametros, s.fechacreacion, s.intentosAsignacion, s.ultimaconductorasignado,
s.fechaexpiracionsolicitud, s.fechaexpiracionasignacion,
ISNULL(c.segesperatomaservicio, 30) AS segundosparatomar
FROM tbservicios s
INNER JOIN tbpasajero p ON p.id=s.idpasajero
LEFT JOIN tbcompania c ON c.id=p.idcompania
WHERE s.idconductor IS NULL
AND s.idservicioestatus=(SELECT id FROM tbservicioestatus WHERE estatus='Solicitado' AND activo=1)
AND (s.fechaexpiracionsolicitud IS NULL OR s.fechaexpiracionsolicitud > GETDATE())
AND (s.fechaexpiracionasignacion IS NULL OR s.fechaexpiracionasignacion <= GETDATE())
ORDER BY s.fechacreacion ASC;
END
GO

/* ---------- 7. Registrar conductor notificado (inicia su ventana de respuesta) ---------- */
IF OBJECT_ID('dbo.sp_sistema_RegistrarNotificado','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_sistema_RegistrarNotificado;
GO
CREATE PROCEDURE sp_sistema_RegistrarNotificado @idservicio BIGINT, @idconductor INT, @segundos INT=30 AS
BEGIN
SET NOCOUNT ON;
IF NOT EXISTS(SELECT 1 FROM tbserviciosconductoresnotificados WHERE idservicio=@idservicio AND idconductor=@idconductor)
    INSERT INTO tbserviciosconductoresnotificados(idservicio,idconductor) VALUES(@idservicio,@idconductor);

UPDATE tbservicios
   SET intentosasignacion=ISNULL(intentosasignacion,0)+1,
       ultimaconductorasignado=@idconductor,
       fechaexpiracionasignacion=DATEADD(SECOND,@segundos,GETDATE()),
       ultimaactualizacion=GETDATE()
 WHERE id=@idservicio;

SELECT 1 AS resultado, 'Notificado' AS mensaje;
END
GO

/* ---------- 8. Conductores ya notificados de un servicio ---------- */
IF OBJECT_ID('dbo.sp_sistema_ObtenerNotificados','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_sistema_ObtenerNotificados;
GO
CREATE PROCEDURE sp_sistema_ObtenerNotificados @idservicio BIGINT AS
BEGIN
SET NOCOUNT ON;
SELECT idconductor FROM tbserviciosconductoresnotificados WHERE idservicio=@idservicio;
END
GO

/* ---------- 9. Rechazo: libera de inmediato para reasignar a otro ---------- */
IF OBJECT_ID('dbo.sp_conductor_RechazarServicio','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_RechazarServicio;
GO
CREATE PROCEDURE sp_conductor_RechazarServicio @idservicio BIGINT, @idconductor INT, @motivo VARCHAR(300)=NULL AS
BEGIN
SET NOCOUNT ON;
INSERT INTO tbservicioasignacionlog(idservicio, idconductor, evento, detalle)
VALUES(@idservicio, @idconductor, 'RECHAZO', ISNULL(@motivo,'Conductor rechazo la solicitud'));

UPDATE tbservicios
   SET intentosasignacion=ISNULL(intentosasignacion,0)+1,
       ultimaconductorasignado=@idconductor,
       fechaexpiracionasignacion=NULL,
       ultimaactualizacion=GETDATE()
 WHERE id=@idservicio;

SELECT 1 AS resultado, 'Servicio rechazado' AS mensaje;
END
GO

PRINT 'Fase 3 (flujo de asignacion) instalada correctamente.';
GO
