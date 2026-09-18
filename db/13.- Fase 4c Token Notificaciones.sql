/* =========================================================
   13.- Fase 4c: Notificaciones (token FCM)
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   - Actualizacion del token de push (googlekey) fuera del login
     (Firebase puede renovar el token en cualquier momento).
   Script idempotente.
   ========================================================= */
USE vaia_viajes;
GO

IF OBJECT_ID('dbo.sp_pasajero_ActualizarToken','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_ActualizarToken;
GO
CREATE PROCEDURE sp_pasajero_ActualizarToken @idPasajero BIGINT, @googlekey VARCHAR(MAX), @so VARCHAR(100)=NULL AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tbpasajero
       SET googlekey=@googlekey, googlekeyso=ISNULL(@so,googlekeyso), ultimaactualizacion=GETDATE()
     WHERE id=@idPasajero;
    SELECT 1 AS resultado, 'Token actualizado' AS mensaje;
END
GO

IF OBJECT_ID('dbo.sp_conductor_ActualizarToken','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_ActualizarToken;
GO
CREATE PROCEDURE sp_conductor_ActualizarToken @idConductor INT, @googlekey VARCHAR(MAX), @so VARCHAR(100)=NULL AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tbconductor
       SET googlekey=@googlekey, googlekeyso=ISNULL(@so,googlekeyso), ultimaactualizacion=GETDATE()
     WHERE id=@idConductor;
    SELECT 1 AS resultado, 'Token actualizado' AS mensaje;
END
GO

PRINT 'Fase 4c (token de notificaciones) instalada correctamente.';
GO
