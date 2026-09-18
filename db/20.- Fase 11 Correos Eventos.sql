/* =========================================================
   20.- Fase 11: Correos de eventos del conductor
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   - Validar documento devuelve los datos del conductor y su
     nuevo estatus de documentacion (para enviar correo).
   Script idempotente.
   ========================================================= */
USE vaia_viajes;
GO

IF OBJECT_ID('dbo.sp_conductor_ValidarDocumento','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_ValidarDocumento;
GO
CREATE PROCEDURE sp_conductor_ValidarDocumento @idDoc INT, @idUsuario INT, @validado BIT, @correccion BIT=0, @coment VARCHAR(MAX)=NULL AS
BEGIN
    SET NOCOUNT ON;

    UPDATE tbconductordocumentos
       SET validado=@validado, encorreccion=@correccion,
           enrevision=CASE WHEN @validado=1 OR @correccion=1 THEN 0 ELSE 1 END,
           comentariocorreccion=ISNULL(@coment,''), idusuariocreo=@idUsuario
     WHERE id=@idDoc;

    DECLARE @idCond INT;
    SELECT @idCond=idconductor FROM tbconductordocumentos WHERE id=@idDoc;

    EXEC sp_conductor_ActualizarEstatusDocumentacion @idCond, @idUsuario;

    SELECT 1 AS resultado, 'Documento validado' AS mensaje,
           @idCond AS idconductor,
           c.correo, c.nombre, c.documentacionaprobada, ed.nombreestatusdocs
      FROM tbconductor c
      LEFT JOIN tbestatusdocumentacion ed ON ed.id=c.idestatusdocumentacion
     WHERE c.id=@idCond;
END
GO

PRINT 'Fase 11 (correos de eventos) instalada correctamente.';
GO
