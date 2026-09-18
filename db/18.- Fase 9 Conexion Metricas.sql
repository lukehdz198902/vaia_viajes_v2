/* =========================================================
   18.- Fase 9: Conexion (gating) y Metricas del Dia
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   - No permitir conectarse (Disponible) si:
       * la documentacion no esta aprobada
       * esta bloqueado o inactivo
       * no tiene una unidad aprobada seleccionada
   - Resumen del dia: ganancias, servicios realizados y
     minutos conectado.
   Script idempotente.
   ========================================================= */
USE vaia_viajes;
GO

/* ---------- 1. Cambiar estatus con validaciones ---------- */
IF OBJECT_ID('dbo.sp_conductor_CambiarEstatus','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_CambiarEstatus;
GO
CREATE PROCEDURE sp_conductor_CambiarEstatus @idConductor INT, @estatus VARCHAR(50) AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idEst SMALLINT=(SELECT id FROM tbconductorestatus WHERE conductorestatus=@estatus AND activo=1);
    IF @idEst IS NULL BEGIN SELECT -1 AS resultado, 'Estatus no valido' AS mensaje; RETURN; END

    /* Validaciones solo al intentar ponerse Disponible */
    IF @estatus='Disponible'
    BEGIN
        DECLARE @bloqueado BIT, @activo BIT, @docsAprob BIT;
        SELECT @bloqueado=ISNULL(bloqueado,0), @activo=ISNULL(activo,0), @docsAprob=ISNULL(documentacionaprobada,0)
          FROM tbconductor WHERE id=@idConductor;

        IF @activo=0 BEGIN SELECT -2 AS resultado,'Tu cuenta esta desactivada' AS mensaje; RETURN; END
        IF @bloqueado=1 BEGIN SELECT -3 AS resultado,'Tu cuenta esta bloqueada por un administrador' AS mensaje; RETURN; END
        IF @docsAprob=0 BEGIN SELECT -4 AS resultado,'Tu documentacion aun no ha sido aprobada' AS mensaje; RETURN; END

        IF NOT EXISTS(SELECT 1 FROM tbconductorunidades WHERE idconductor=@idConductor AND aprobada=1 AND enuso=1)
        BEGIN SELECT -5 AS resultado,'Selecciona una unidad aprobada antes de conectarte' AS mensaje; RETURN; END
    END

    UPDATE tbconductor SET idconductorestatus=@idEst, ultimaactualizacion=GETDATE() WHERE id=@idConductor;
    SELECT 1 AS resultado, CONCAT('Estatus: ',@estatus) AS mensaje;
END
GO

/* ---------- 2. Resumen del dia ---------- */
IF OBJECT_ID('dbo.sp_conductor_ResumenDia','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_ResumenDia;
GO
CREATE PROCEDURE sp_conductor_ResumenDia @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @hoy DATE = CAST(GETDATE() AS DATE);

    DECLARE @ganancias DECIMAL(18,2)=0, @servicios INT=0;
    SELECT @ganancias = ISNULL(SUM(s.gananciaconductor),0), @servicios = COUNT(*)
      FROM tbservicios s
      INNER JOIN tbservicioestatus e ON e.id=s.idservicioestatus
     WHERE s.idconductor=@idConductor
       AND e.estatus='Finalizado'
       AND CAST(ISNULL(s.fechafinalizoconductor, s.ultimaactualizacion) AS DATE)=@hoy;

    DECLARE @minutos INT=0;
    SELECT @minutos = ISNULL(SUM(DATEDIFF(MINUTE, s.fechaconexion, ISNULL(s.fechadesconexion, GETDATE()))),0)
      FROM tbsesionusuario s
     WHERE s.idtipousuario=2 AND s.idconductor=@idConductor
       AND CAST(s.fechaconexion AS DATE)=@hoy;

    DECLARE @estatus VARCHAR(50)=(SELECT ce.conductorestatus FROM tbconductor c LEFT JOIN tbconductorestatus ce ON ce.id=c.idconductorestatus WHERE c.id=@idConductor);

    SELECT @ganancias AS gananciasdia,
           @servicios AS serviciosdia,
           @minutos AS minutosconectado,
           @estatus AS estatus;
END
GO

PRINT 'Fase 9 (conexion y metricas del dia) instalada correctamente.';
GO
