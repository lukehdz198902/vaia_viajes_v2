/*
 =============================================
 SCRIPT DE AJUSTES PARA LA API MOVIL (PASAJERO Y CONDUCTOR)
 =============================================
 Fecha: 2026
 Descripcion: Este script aplica los ajustes necesarios para que las apps
 moviles (pasajero y conductor) funcionen correctamente contra la API.

 Ejecutar UNA VEZ sobre la base de datos vaia_viajes del servidor.
 Es idempotente: se puede ejecutar multiples veces sin problemas.
 =============================================
*/

USE vaia_viajes;
GO

PRINT '=============================================';
PRINT ' APLICANDO AJUSTES API MOVIL';
PRINT '=============================================';
GO

-- =============================================
-- 1. CORREGIR ACENTOS EN ESTATUS DE SERVICIO
-- =============================================
PRINT '1. Corrigiendo acentos en tbservicioestatus...';
GO

UPDATE tbservicioestatus SET estatus = 'Llego al Origen', estatusdescription = 'Conductor llego al punto de recogida'
WHERE estatus = 'Llegó al Origen';

UPDATE tbservicioestatus SET estatus = 'Llego al Destino', estatusdescription = 'Llego al destino final'
WHERE estatus = 'Llegó al Destino';
GO

PRINT '   OK';
GO

-- =============================================
-- 1.1 CORREGIR ACENTOS EN CATALOGOS DE CONDUCTOR Y DOCUMENTACION
-- =============================================
-- Los SPs buscan 'En Validacion', 'En Revision', 'Requiere Correccion'
-- (sin acento) pero la precarga original los inserto con acento.

PRINT '1.1 Corrigiendo acentos en tbconductorestatus y tbestatusdocumentacion...';
GO

-- Se usa LIKE con patron sin acento para evitar problemas de encoding del cliente SQL
UPDATE tbconductorestatus SET conductorestatus = 'En Validacion', descripcion = 'Conductor en proceso de validacion de documentos'
WHERE conductorestatus LIKE 'En Validaci%' AND conductorestatus <> 'En Validacion';

UPDATE tbestatusdocumentacion SET nombreestatusdocs = 'En Revision', descripcion = 'Documentacion en proceso de revision'
WHERE nombreestatusdocs LIKE 'En Revisi%' AND nombreestatusdocs <> 'En Revision';

UPDATE tbestatusdocumentacion SET nombreestatusdocs = 'Requiere Correccion', descripcion = 'Se requiere corregir la documentacion'
WHERE nombreestatusdocs LIKE 'Requiere Correcci%' AND nombreestatusdocs <> 'Requiere Correccion';
GO

PRINT '   OK';
GO

-- =============================================
-- 1.2 REPARAR CONDUCTORES CON idconductorestatus NULL
-- =============================================
-- Conductores que quedaron con idconductorestatus NULL por el bug de acento.

PRINT '1.2 Reparando conductores con idconductorestatus NULL...';
GO

UPDATE tbconductor SET idconductorestatus = (SELECT id FROM tbconductorestatus WHERE conductorestatus='En Validacion')
WHERE idconductorestatus IS NULL OR idconductorestatus NOT IN (SELECT id FROM tbconductorestatus);
GO

PRINT '   OK';
GO

-- =============================================
-- 2. REPARAR SERVICIOS CON ESTATUS NULL
-- =============================================
PRINT '2. Reparando servicios con estatus NULL...';
GO

UPDATE s SET s.idservicioestatus = (SELECT id FROM tbservicioestatus WHERE estatus='Finalizado')
FROM tbservicios s
WHERE s.idservicioestatus IS NULL AND s.llegoasudestino = 1;

UPDATE s SET s.idservicioestatus = (SELECT id FROM tbservicioestatus WHERE estatus='Solicitado')
FROM tbservicios s
WHERE s.idservicioestatus IS NULL AND ISNULL(s.llegoasudestino,0) = 0 AND s.idconductor IS NULL;

UPDATE s SET s.idservicioestatus = (SELECT id FROM tbservicioestatus WHERE estatus='En Viaje')
FROM tbservicios s
WHERE s.idservicioestatus IS NULL AND s.idconductor IS NOT NULL AND ISNULL(s.llegoasudestino,0) = 0;
GO

PRINT '   OK';
GO

-- =============================================
-- 3. SP: OBTENER PERFIL CONDUCTOR
-- =============================================
PRINT '3. Creando sp_conductor_ObtenerPerfil...';
GO

CREATE PROCEDURE sp_conductor_ObtenerPerfil @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.*, ce.conductorestatus, ed.nombreestatusdocs, zc.nombrezona, cmp.companianombre, i.idioma,
           (SELECT COUNT(*) FROM tbconductordocumentos WHERE idconductor=c.id AND validado IS NOT NULL) AS totaldocs,
           (SELECT COUNT(*) FROM tbconductordocumentos WHERE idconductor=c.id AND validado=1) AS docsvalidados,
           (SELECT COUNT(*) FROM tbconductorunidades WHERE idconductor=c.id) AS totalunidades,
           (SELECT COUNT(*) FROM tbcortesemanasemanal WHERE idconductor=c.id AND tbcortesemanasemanal.activo=1) AS totalcortes
    FROM tbconductor c
    INNER JOIN tbconductorestatus ce ON ce.id=c.idconductorestatus
    LEFT JOIN tbestatusdocumentacion ed ON ed.id=c.idestatusdocumentacion
    LEFT JOIN tbzonacobertura zc ON zc.id=c.idzonacobertura
    LEFT JOIN tbcompania cmp ON cmp.id=c.idcompania
    LEFT JOIN tbidioma i ON i.id=c.idiomapreferido
    WHERE c.id=@idConductor;
END
GO

PRINT '   OK';
GO

-- =============================================
-- 4. SP: DETALLE DE VIAJE CONDUCTOR
-- =============================================
PRINT '4. Creando sp_conductor_DetalleViaje...';
GO

CREATE PROCEDURE sp_conductor_DetalleViaje @idServicio BIGINT, @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.*, se.estatus, se.estatusdescription,
           p.nombre AS p_nombre, p.appaterno AS p_appaterno, p.apmaterno AS p_apmaterno,
           p.fotoperfil AS p_foto, p.telefono AS p_tel, p.correo AS p_email,
           u.unidad, u.alias, u.colorhex, u.colornombre, u.numeroasientos, u.placas, u.modelo,
           sm.nombresubmarca, m.nombremarca, tp.tipopago,
           r.polylineruta, r.puntosruta, r.distanciametros AS rd_m, r.duracionsegundos AS rd_s
    FROM tbservicios s
    INNER JOIN tbservicioestatus se ON se.id=s.idservicioestatus
    LEFT JOIN tbpasajero p ON p.id=s.idpasajero
    LEFT JOIN tbunidad u ON u.id=s.idunidad
    LEFT JOIN tbsubmarca sm ON sm.id=u.idsubmarca
    LEFT JOIN tbmarca m ON m.id=sm.idmarca
    LEFT JOIN tbtipopago tp ON tp.id=s.idtipopago
    LEFT JOIN tbrutaasignada r ON r.idservicio=s.id
    WHERE s.id=@idServicio AND (@idConductor=0 OR s.idconductor=@idConductor);
END
GO

PRINT '   OK';
GO

-- =============================================
-- 5. SP: INICIAR SERVICIO PASAJERO
-- =============================================
PRINT '5. Creando sp_pasajero_IniciarServicio...';
GO

ALTER PROCEDURE sp_pasajero_IniciarServicio @idServicio BIGINT, @idPasajero BIGINT, @codigoInicio VARCHAR(10)=NULL AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @enCamino SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='En Camino' AND activo=1);
    IF NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idServicio AND idpasajero=@idPasajero)
        BEGIN SELECT -1 AS resultado, 'Servicio no encontrado' AS mensaje; RETURN; END
    DECLARE @enViaje SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='En Viaje' AND activo=1);
    UPDATE tbservicios SET idservicioestatus=@enViaje, servicioiniciado=1, fechaservicioiniciado=GETDATE(), ultimaactualizacion=GETDATE() WHERE id=@idServicio;
    SELECT 1 AS resultado, 'Servicio iniciado' AS mensaje, @idServicio AS idservicio, @enViaje AS idservicioestatus;
END
GO

PRINT '   OK';
GO

PRINT '';
PRINT '=============================================';
PRINT ' AJUSTES APLICADOS CORRECTAMENTE';
PRINT '=============================================';
GO

SELECT 'Estatus de servicio:' AS Verificacion;
SELECT id, estatus, activo FROM tbservicioestatus WHERE activo = 1 ORDER BY id;
GO