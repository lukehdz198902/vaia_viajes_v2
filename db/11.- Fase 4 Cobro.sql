/* =========================================================
   11.- Fase 4: Cobro (taximetro + pago)
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   - Taximetro: costo en vivo durante el viaje (costoencurso)
   - Finalizacion con costo final + comision del conductor
   - Registro de pago (efectivo / tarjeta / paypal / mercadopago)
   Script idempotente.
   ========================================================= */
USE vaia_viajes;
GO

/* ---------- 1. Columnas nuevas en tbservicios ---------- */
IF COL_LENGTH('tbservicios','costoencurso') IS NULL
    ALTER TABLE tbservicios ADD costoencurso DECIMAL(18,2) NULL;
GO
IF COL_LENGTH('tbservicios','costofinal') IS NULL
    ALTER TABLE tbservicios ADD costofinal DECIMAL(18,2) NULL;
GO

/* ---------- 2. Taximetro: actualiza el costo en vivo del viaje ---------- */
IF OBJECT_ID('dbo.sp_conductor_ActualizarTaximetro','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_ActualizarTaximetro;
GO
CREATE PROCEDURE sp_conductor_ActualizarTaximetro
@idServicio BIGINT, @idConductor INT, @distanciaMetros INT, @duracionSegundos INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @viaje SMALLINT = (SELECT id FROM tbservicioestatus WHERE estatus='En Viaje' AND activo=1);
    IF NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idServicio AND idconductor=@idConductor AND idservicioestatus=@viaje)
    BEGIN
        SELECT -1 AS resultado, 'El servicio no esta en viaje' AS mensaje, CAST(0 AS DECIMAL(18,2)) AS costo;
        RETURN;
    END

    DECLARE @idCompania SMALLINT = (SELECT p.idcompania FROM tbservicios s INNER JOIN tbpasajero p ON p.id=s.idpasajero WHERE s.id=@idServicio);
    DECLARE @costo DECIMAL(18,2) = dbo.fn_CalcularCostoViaje(@idCompania, @distanciaMetros, @duracionSegundos, GETDATE());

    UPDATE tbservicios
       SET costoencurso=@costo,
           distanciametros=@distanciaMetros,
           durationsegundos=@duracionSegundos,
           ultimaactualizacion=GETDATE()
     WHERE id=@idServicio;

    SELECT 1 AS resultado, 'Costo actualizado' AS mensaje, @costo AS costo;
END
GO

/* ---------- 3. Finalizar viaje con costo final + comision ---------- */
IF OBJECT_ID('dbo.sp_conductor_FinalizarViaje','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_FinalizarViaje;
GO
CREATE PROCEDURE sp_conductor_FinalizarViaje
@idServicio BIGINT, @idConductor INT, @distReal INT=NULL, @durReal INT=NULL,
@poly VARCHAR(MAX)=NULL, @puntos VARCHAR(MAX)=NULL, @costoFinal DECIMAL(18,2)=NULL
AS
BEGIN
SET NOCOUNT ON;
DECLARE @viaje SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='En Viaje' AND activo=1);
DECLARE @fin SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='Finalizado' AND activo=1);
DECLARE @disp SMALLINT=(SELECT id FROM tbconductorestatus WHERE conductorestatus='Disponible');

/* Costo final: el enviado por la app o el ultimo costo en curso o el estimado */
DECLARE @costo DECIMAL(18,2) = ISNULL(@costoFinal,
    ISNULL((SELECT costoencurso FROM tbservicios WHERE id=@idServicio),
           (SELECT costoestimado FROM tbservicios WHERE id=@idServicio)));

/* Comision del conductor segun su zona de cobertura */
DECLARE @idZona INT = (SELECT idzonacobertura FROM tbconductor WHERE id=@idConductor);
DECLARE @com DECIMAL(18,2) = dbo.fn_CalcularComision(@idZona, @costo);

UPDATE tbservicios SET idservicioestatus=@fin,llegoasudestino=1,fechallegoasudestino=GETDATE(),
    distanciametros=ISNULL(@distReal,distanciametros),durationsegundos=ISNULL(@durReal,durationsegundos),
    costofinal=@costo,comisionaplicada=@com,gananciaconductor=@costo-@com,
    ultimaactualizacion=GETDATE(),fechafinalizoconductor=GETDATE()
WHERE id=@idServicio AND idconductor=@idConductor AND idservicioestatus=@viaje;

UPDATE tbconductor SET idconductorestatus=@disp WHERE id=@idConductor;

IF @poly IS NOT NULL OR @puntos IS NOT NULL BEGIN
IF EXISTS(SELECT 1 FROM tbrutaasignada WHERE idservicio=@idServicio)
UPDATE tbrutaasignada SET polylineruta=ISNULL(@poly,polylineruta),puntosruta=ISNULL(@puntos,puntosruta),distanciametros=ISNULL(@distReal,distanciametros),duracionsegundos=ISNULL(@durReal,duracionsegundos),ultimaactualizacion=GETDATE() WHERE idservicio=@idServicio;
ELSE
INSERT INTO tbrutaasignada(idservicio,polylineruta,puntosruta,distanciametros,duracionsegundos) VALUES(@idServicio,@poly,@puntos,@distReal,@durReal);
END

SELECT 1 AS resultado,'Viaje finalizado' AS mensaje, @costo AS costofinal, @com AS comisionaplicada, @costo-@com AS gananciaconductor;
END
GO

/* ---------- 4. Registrar pago del servicio ---------- */
IF OBJECT_ID('dbo.sp_conductor_RegistrarPago','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_RegistrarPago;
GO
CREATE PROCEDURE sp_conductor_RegistrarPago
@idServicio BIGINT, @idConductor INT, @monto DECIMAL(18,2), @metodo VARCHAR(20)='CASH', @referencia VARCHAR(200)=NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idServicio AND idconductor=@idConductor)
    BEGIN
        SELECT -1 AS resultado, 'Servicio no encontrado' AS mensaje;
        RETURN;
    END

    /* Evitar doble cobro */
    IF EXISTS(SELECT 1 FROM tbpago WHERE idservicio=@idServicio AND activo=1)
    BEGIN
        SELECT -2 AS resultado, 'El servicio ya tiene un pago registrado' AS mensaje;
        RETURN;
    END

    DECLARE @idMetodo SMALLINT=(SELECT TOP 1 id FROM tbmetodopago WHERE codigo=@metodo AND activo=1);
    IF @idMetodo IS NULL SET @idMetodo=(SELECT TOP 1 id FROM tbmetodopago WHERE codigo='CASH');
    DECLARE @idPagado SMALLINT=(SELECT TOP 1 id FROM tbestatuspago WHERE codigo='PAID');
    DECLARE @idPasajero BIGINT=(SELECT idpasajero FROM tbservicios WHERE id=@idServicio);

    INSERT INTO tbpago(idservicio,idpasajero,monto,montonetopagar,idmetodopago,idestatuspago,referenciapago,fechapago)
    VALUES(@idServicio,@idPasajero,@monto,@monto,@idMetodo,@idPagado,@referencia,GETDATE());

    DECLARE @idPago BIGINT=SCOPE_IDENTITY();
    UPDATE tbservicios SET idpago=@idPago, idtipopago=@idMetodo, ultimaactualizacion=GETDATE() WHERE id=@idServicio;

    SELECT 1 AS resultado, 'Pago registrado' AS mensaje, @idPago AS idpago;
END
GO

/* ---------- 5. Estado del servicio: incluye costos en vivo ---------- */
IF OBJECT_ID('dbo.sp_pasajero_ObtenerEstadoServicio','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_ObtenerEstadoServicio;
GO
CREATE PROCEDURE sp_pasajero_ObtenerEstadoServicio @idServicio BIGINT, @idPasajero BIGINT AS
BEGIN
SET NOCOUNT ON;
SELECT s.id,s.idservicioestatus,se.estatus,se.estatusdescription,s.direccionorigen,s.latorigen,s.lngorigen,s.direcciondestination,s.latdestination,s.lngdestination,
s.costoestimado,s.costoencurso,s.costofinal,s.distanciametros,s.durationsegundos,s.montodescuento,s.servicioiniciado,s.llegoalorigen,s.llegoasudestino,s.fechacreacion,s.fechaservicioiniciado,
s.fechallegoalorigen,s.fechallegoasudestino,s.alarmasospasajero,s.alarmasosconductor,s.sesalioderuta,s.motivocancelacion,s.canceladopor,s.fechacancelacion,
s.calificacion,s.idconductor,s.codigoinicio,s.idpago,c.nombre AS conductor_nombre,c.appaterno AS conductor_appaterno,c.fotoperfil AS conductor_foto,c.telefono AS conductor_telefono,u.unidad,u.colorhex,u.colornombre,u.numeroasientos,u.placas,sm.nombresubmarca,m.nombremarca,g.lat AS conductor_lat,g.lng AS conductor_lng
FROM tbservicios s INNER JOIN tbservicioestatus se ON se.id=s.idservicioestatus
LEFT JOIN tbconductor c ON c.id=s.idconductor LEFT JOIN tbconductorunidades cu ON cu.idconductor=c.id AND cu.enuso=1
LEFT JOIN tbunidad u ON u.id=cu.idunidad LEFT JOIN tbsubmarca sm ON sm.id=u.idsubmarca
LEFT JOIN tbmarca m ON m.id=sm.idmarca LEFT JOIN tbconductorgps g ON g.idconductor=c.id
WHERE s.id=@idServicio AND s.idpasajero=@idPasajero;
END
GO

/* ---------- 6. Comprobante del viaje (datos para el correo) ---------- */
IF OBJECT_ID('dbo.sp_servicio_Comprobante','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_servicio_Comprobante;
GO
CREATE PROCEDURE sp_servicio_Comprobante @idServicio BIGINT AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.id, s.fechacreacion, s.fechafinalizoconductor, s.direccionorigen, s.direcciondestination,
           s.costofinal, s.montodescuento, s.distanciametros, s.durationsegundos,
           p.nombre AS pasajero_nombre, p.appaterno AS pasajero_appaterno, p.correo AS pasajero_correo,
           c.nombre AS conductor_nombre, c.appaterno AS conductor_appaterno,
           u.unidad, u.placas, mp.metodopago, ep.nombreestatus AS estatuspago, pg.fechapago
      FROM tbservicios s
      LEFT JOIN tbpasajero p ON p.id=s.idpasajero
      LEFT JOIN tbconductor c ON c.id=s.idconductor
      LEFT JOIN tbconductorunidades cu ON cu.idconductor=c.id AND cu.enuso=1
      LEFT JOIN tbunidad u ON u.id=cu.idunidad
      LEFT JOIN tbpago pg ON pg.idservicio=s.id AND pg.activo=1
      LEFT JOIN tbmetodopago mp ON mp.id=pg.idmetodopago
      LEFT JOIN tbestatuspago ep ON ep.id=pg.idestatuspago
     WHERE s.id=@idServicio;
END
GO

PRINT 'Fase 4 (cobro) instalada correctamente.';
GO
