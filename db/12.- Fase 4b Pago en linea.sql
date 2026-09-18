/* =========================================================
   12.- Fase 4b: Pago en linea (MercadoPago / PayPal)
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   - Registro/actualizacion de pago sin requerir conductor
     (lo usan las pasarelas de pago).
   Script idempotente.
   ========================================================= */
USE vaia_viajes;
GO

IF OBJECT_ID('dbo.sp_pago_Registrar','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pago_Registrar;
GO
CREATE PROCEDURE sp_pago_Registrar
@idServicio BIGINT, @monto DECIMAL(18,2), @metodo VARCHAR(20)='CASH', @referencia VARCHAR(200)=NULL, @estatus VARCHAR(20)='PAID'
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idServicio)
    BEGIN
        SELECT -1 AS resultado, 'Servicio no encontrado' AS mensaje;
        RETURN;
    END

    DECLARE @idMetodo SMALLINT=(SELECT TOP 1 id FROM tbmetodopago WHERE codigo=@metodo AND activo=1);
    IF @idMetodo IS NULL SET @idMetodo=(SELECT TOP 1 id FROM tbmetodopago WHERE codigo='CASH');
    DECLARE @idEstatus SMALLINT=(SELECT TOP 1 id FROM tbestatuspago WHERE codigo=@estatus);
    IF @idEstatus IS NULL SET @idEstatus=(SELECT TOP 1 id FROM tbestatuspago WHERE codigo='PAID');
    DECLARE @idPasajero BIGINT=(SELECT idpasajero FROM tbservicios WHERE id=@idServicio);

    /* Si ya existe un pago para el servicio, se actualiza (no se duplica) */
    IF EXISTS(SELECT 1 FROM tbpago WHERE idservicio=@idServicio AND activo=1)
    BEGIN
        UPDATE tbpago
           SET monto=@monto, montonetopagar=@monto, idmetodopago=@idMetodo, idestatuspago=@idEstatus,
               referenciapago=ISNULL(@referencia,referenciapago),
               fechapago=CASE WHEN @estatus='PAID' THEN GETDATE() ELSE fechapago END,
               ultimaactualizacion=GETDATE()
         WHERE idservicio=@idServicio AND activo=1;

        SELECT 1 AS resultado, 'Pago actualizado' AS mensaje,
               (SELECT TOP 1 id FROM tbpago WHERE idservicio=@idServicio ORDER BY id DESC) AS idpago;
        RETURN;
    END

    INSERT INTO tbpago(idservicio,idpasajero,monto,montonetopagar,idmetodopago,idestatuspago,referenciapago,fechapago)
    VALUES(@idServicio,@idPasajero,@monto,@monto,@idMetodo,@idEstatus,@referencia,
           CASE WHEN @estatus='PAID' THEN GETDATE() ELSE NULL END);

    DECLARE @idPago BIGINT=SCOPE_IDENTITY();
    UPDATE tbservicios SET idpago=@idPago, idtipopago=@idMetodo, ultimaactualizacion=GETDATE() WHERE id=@idServicio;

    SELECT 1 AS resultado, 'Pago registrado' AS mensaje, @idPago AS idpago;
END
GO

PRINT 'Fase 4b (pago en linea) instalada correctamente.';
GO
