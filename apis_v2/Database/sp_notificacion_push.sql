================================================================================
  STORED PROCEDURES PARA NOTIFICACIONES PUSH (FCM)
  Proyecto: apis_v2 (ASP.NET Core 2.2 - .NET Framework 4.8)
  Base de datos: vaia_viajes
================================================================================

-- ==============================================================================
-- SP 1: Obtiene el token FCM (googlekey) de un pasajero
-- ==============================================================================
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'sp_notificacion_ObtenerTokenPasajero' AND type = 'P')
    DROP PROCEDURE sp_notificacion_ObtenerTokenPasajero;
GO

CREATE PROCEDURE sp_notificacion_ObtenerTokenPasajero
    @idPasajero BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT googlekey
    FROM tbpasajero
    WHERE id = @idPasajero AND activo = 1;
END
GO


-- ==============================================================================
-- SP 2: Obtiene el token FCM (googlekey) de un conductor
-- ==============================================================================
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'sp_notificacion_ObtenerTokenConductor' AND type = 'P')
    DROP PROCEDURE sp_notificacion_ObtenerTokenConductor;
GO

CREATE PROCEDURE sp_notificacion_ObtenerTokenConductor
    @idConductor INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT googlekey
    FROM tbconductor
    WHERE id = @idConductor AND activo = 1;
END
GO


-- ==============================================================================
-- SP 3: Obtiene el nombre completo del conductor (nombre + appaterno)
-- ==============================================================================
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'sp_notificacion_ObtenerNombreConductor' AND type = 'P')
    DROP PROCEDURE sp_notificacion_ObtenerNombreConductor;
GO

CREATE PROCEDURE sp_notificacion_ObtenerNombreConductor
    @idConductor INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ISNULL(nombre, '') + ' ' + ISNULL(appaterno, '') AS nombreCompleto
    FROM tbconductor
    WHERE id = @idConductor;
END
GO


-- ==============================================================================
-- SP 4: Obtiene el nombre completo del pasajero (nombre + appaterno)
-- ==============================================================================
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'sp_notificacion_ObtenerNombrePasajero' AND type = 'P')
    DROP PROCEDURE sp_notificacion_ObtenerNombrePasajero;
GO

CREATE PROCEDURE sp_notificacion_ObtenerNombrePasajero
    @idPasajero BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ISNULL(nombre, '') + ' ' + ISNULL(appaterno, '') AS nombreCompleto
    FROM tbpasajero
    WHERE id = @idPasajero;
END
GO


-- ==============================================================================
-- SP 5: Obtiene todos los tokens FCM de conductores activos de una compania
-- ==============================================================================
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'sp_notificacion_ObtenerTokensConductoresCompania' AND type = 'P')
    DROP PROCEDURE sp_notificacion_ObtenerTokensConductoresCompania;
GO

CREATE PROCEDURE sp_notificacion_ObtenerTokensConductoresCompania
    @idCompania SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT googlekey
    FROM tbconductor
    WHERE idCompania = @idCompania
      AND activo = 1
      AND googlekey IS NOT NULL
      AND googlekey != '';
END
GO
