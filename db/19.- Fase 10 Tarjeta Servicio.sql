/* =========================================================
   19.- Fase 10: Tarjeta de Servicio (datos del pasajero)
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   - Al ofrecer un servicio, incluir la calificacion promedio
     y la cantidad de servicios previos del pasajero.
   Script idempotente.
   ========================================================= */
USE vaia_viajes;
GO

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
ISNULL(c.segesperatomaservicio, 30) AS segundosparatomar,
p.nombre AS pasajeronombre, p.appaterno AS pasajeroappaterno,
CAST(ISNULL((SELECT AVG(CAST(s2.calificacionpasajero AS DECIMAL(4,2)))
               FROM tbservicios s2
              WHERE s2.idpasajero = s.idpasajero AND s2.calificacionpasajero IS NOT NULL), 0) AS DECIMAL(4,2)) AS pasajerocalificacion,
(SELECT COUNT(*)
   FROM tbservicios s3
   INNER JOIN tbservicioestatus e3 ON e3.id = s3.idservicioestatus
  WHERE s3.idpasajero = s.idpasajero AND e3.estatus = 'Finalizado') AS pasajerototalviajes
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

PRINT 'Fase 10 (tarjeta de servicio) instalada correctamente.';
GO
