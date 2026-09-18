/* =========================================================
   15.- Fase 6: Verificacion de telefono por WhatsApp
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   - Valida el codigo de 6 digitos enviado por WhatsApp
     (tbpasajerocodigos) durante el registro.
   Script idempotente.
   ========================================================= */
USE vaia_viajes;
GO

IF OBJECT_ID('dbo.sp_pasajero_ValidarCodigoVerificacion','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_ValidarCodigoVerificacion;
GO
CREATE PROCEDURE sp_pasajero_ValidarCodigoVerificacion
@codigopaistel VARCHAR(15), @telefono VARCHAR(30), @codigo VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF @telefono IS NULL OR @codigo IS NULL OR LTRIM(RTRIM(@codigo)) = ''
    BEGIN
        SELECT -1 AS resultado, 'Codigo requerido' AS mensaje;
        RETURN;
    END

    IF NOT EXISTS(SELECT 1 FROM tbpasajerocodigos
                   WHERE notelefono = @telefono
                     AND codigoverificacion = @codigo
                     AND activo = 1
                     AND fechalimiteexpira >= GETDATE())
    BEGIN
        SELECT -2 AS resultado, 'Codigo invalido o expirado' AS mensaje;
        RETURN;
    END

    UPDATE tbpasajerocodigos SET activo = 0
     WHERE notelefono = @telefono AND codigoverificacion = @codigo;

    UPDATE tbpasajero
       SET telefonoconfirmado = 1, ultimaactualizacion = GETDATE()
     WHERE telefono = @telefono
       AND (@codigopaistel IS NULL OR codigopaistel = @codigopaistel);

    SELECT 1 AS resultado, 'Codigo validado' AS mensaje;
END
GO

PRINT 'Fase 6 (verificacion WhatsApp) instalada correctamente.';
GO
