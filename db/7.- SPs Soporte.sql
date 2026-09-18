/*
 =============================================
 SCRIPT: SPs DE SOPORTE (CHAT ADMIN <-> PASAJERO/CONDUCTOR)
 =============================================
 Fecha: 2026
 Idempotente.
 =============================================
*/

USE vaia_viajes;
GO

PRINT '=============================================';
PRINT ' CREANDO SPs DE SOPORTE';
PRINT '=============================================';
GO

PRINT 'sp_soporte_CrearSolicitud';
GO
CREATE PROCEDURE sp_soporte_CrearSolicitud
    @idservicio BIGINT=NULL, @idpasajero BIGINT=NULL, @idconductor INT=NULL,
    @tipoSolicitante VARCHAR(20), @asunto VARCHAR(200)=NULL, @descripcion VARCHAR(MAX)=NULL,
    @prioridad VARCHAR(20)='Normal'
AS
BEGIN
    SET NOCOUNT ON;
    IF @idservicio IS NULL
        BEGIN SELECT -1 AS id, 'Debe especificar un servicio de referencia' AS mensaje; RETURN; END
    IF @tipoSolicitante NOT IN ('pasajero','conductor')
        BEGIN SELECT -2 AS id, 'Tipo de solicitante invalido' AS mensaje; RETURN; END

    -- Validar que el servicio exista y que el solicitante tenga relacion con el
    IF @tipoSolicitante='pasajero' AND NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idservicio AND idpasajero=@idpasajero)
        BEGIN SELECT -3 AS id, 'El servicio no pertenece al pasajero' AS mensaje; RETURN; END
    IF @tipoSolicitante='conductor' AND NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idservicio AND idconductor=@idconductor)
        BEGIN SELECT -4 AS id, 'El servicio no pertenece al conductor' AS mensaje; RETURN; END

    -- Si ya hay una solicitud abierta para ese servicio y tipo, devolverla
    DECLARE @existente BIGINT;
    SELECT TOP 1 @existente=id FROM tbsoportesolicitud
    WHERE idservicio=@idservicio AND tipo_solicitante=@tipoSolicitante AND estatus<>'Cerrado' AND activo=1
    ORDER BY fechacreacion DESC;
    IF @existente IS NOT NULL
        BEGIN SELECT @existente AS id, 'Ya existe una solicitud activa' AS mensaje, 1 AS existente; RETURN; END

    INSERT INTO tbsoportesolicitud(idservicio, idpasajero, idconductor, tipo_solicitante, asunto, descripcion_inicial, prioridad)
    VALUES(@idservicio, @idpasajero, @idconductor, @tipoSolicitante, @asunto, @descripcion, @prioridad);
    DECLARE @nuevo BIGINT=SCOPE_IDENTITY();

    IF @descripcion IS NOT NULL AND LEN(@descripcion) > 0
        INSERT INTO tbsoportemensaje(idsolicitud, emisor, idemisor, nombre_emisor, mensaje)
        VALUES(@nuevo, @tipoSolicitante, CASE WHEN @tipoSolicitante='pasajero' THEN @idpasajero ELSE @idconductor END, NULL, @descripcion);

    SELECT @nuevo AS id, 'Solicitud de soporte creada' AS mensaje, 0 AS existente;
END
GO

PRINT 'sp_soporte_ListarSolicitudes';
GO
CREATE PROCEDURE sp_soporte_ListarSolicitudes
    @estatus VARCHAR(30)=NULL, @tipoSolicitante VARCHAR(20)=NULL, @idservicio BIGINT=NULL,
    @pagina INT=1, @tamano INT=50
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @off INT=(@pagina-1)*@tamano;
    SELECT s.id, s.idservicio, s.idpasajero, s.idconductor, s.tipo_solicitante, s.asunto,
           s.descripcion_inicial, s.estatus, s.idusuariosoporte, s.prioridad, s.fechacreacion,
           s.fecha_cierre, s.ultimaactualizacion,
           p.nombre + ' ' + p.appaterno AS pasajero_nombre, p.telefono AS pasajero_tel,
           c.nombre + ' ' + c.appaterno AS conductor_nombre, c.telefono AS conductor_tel,
           u.nombre + ' ' + u.appaterno AS soporte_nombre,
           sv.idservicioestatus, se.estatus AS servicio_estatus,
           (SELECT COUNT(*) FROM tbsoportemensaje m WHERE m.idsolicitud=s.id AND m.activo=1) AS totalmensajes,
           (SELECT COUNT(*) FROM tbsoportemensaje m WHERE m.idsolicitud=s.id AND m.activo=1 AND m.emisor<>'soporte' AND m.leido=0) AS noleidos,
           COUNT(*) OVER() AS totalregistros
    FROM tbsoportesolicitud s
    LEFT JOIN tbpasajero p ON p.id=s.idpasajero
    LEFT JOIN tbconductor c ON c.id=s.idconductor
    LEFT JOIN tbusuario u ON u.id=s.idusuariosoporte
    LEFT JOIN tbservicios sv ON sv.id=s.idservicio
    LEFT JOIN tbservicioestatus se ON se.id=sv.idservicioestatus
    WHERE s.activo=1
      AND (@estatus IS NULL OR s.estatus=@estatus)
      AND (@tipoSolicitante IS NULL OR s.tipo_solicitante=@tipoSolicitante)
      AND (@idservicio IS NULL OR s.idservicio=@idservicio)
    ORDER BY
      CASE s.estatus WHEN 'Abierto' THEN 0 WHEN 'EnAtencion' THEN 1 ELSE 2 END,
      CASE s.prioridad WHEN 'Urgente' THEN 0 WHEN 'Alta' THEN 1 WHEN 'Normal' THEN 2 ELSE 3 END,
      s.fechacreacion DESC
    OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

PRINT 'sp_soporte_ObtenerSolicitud';
GO
CREATE PROCEDURE sp_soporte_ObtenerSolicitud @id BIGINT AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.*,
           p.nombre + ' ' + p.appaterno AS pasajero_nombre, p.telefono AS pasajero_tel, p.correo AS pasajero_correo,
           c.nombre + ' ' + c.appaterno AS conductor_nombre, c.telefono AS conductor_tel, c.correo AS conductor_correo,
           u.nombre + ' ' + u.appaterno AS soporte_nombre,
           sv.direccionorigen, sv.direcciondestination, sv.costoestimado, sv.fechacreacion AS servicio_fecha,
           se.estatus AS servicio_estatus
    FROM tbsoportesolicitud s
    LEFT JOIN tbpasajero p ON p.id=s.idpasajero
    LEFT JOIN tbconductor c ON c.id=s.idconductor
    LEFT JOIN tbusuario u ON u.id=s.idusuariosoporte
    LEFT JOIN tbservicios sv ON sv.id=s.idservicio
    LEFT JOIN tbservicioestatus se ON se.id=sv.idservicioestatus
    WHERE s.id=@id;
END
GO

PRINT 'sp_soporte_EnviarMensaje';
GO
CREATE PROCEDURE sp_soporte_EnviarMensaje
    @idsolicitud BIGINT, @emisor VARCHAR(20), @idemisor BIGINT=NULL,
    @nombreEmisor VARCHAR(150)=NULL, @mensaje VARCHAR(MAX), @adjunto VARCHAR(MAX)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM tbsoportesolicitud WHERE id=@idsolicitud AND activo=1)
        BEGIN SELECT -1 AS id, 'Solicitud no encontrada' AS mensaje; RETURN; END
    INSERT INTO tbsoportemensaje(idsolicitud, emisor, idemisor, nombre_emisor, mensaje, adjunto_base64)
    VALUES(@idsolicitud, @emisor, @idemisor, @nombreEmisor, @mensaje, @adjunto);
    DECLARE @nuevo BIGINT=SCOPE_IDENTITY();
    UPDATE tbsoportesolicitud SET ultimaactualizacion=GETDATE(),
        estatus = CASE WHEN estatus='Abierto' AND @emisor='soporte' THEN 'EnAtencion' ELSE estatus END
    WHERE id=@idsolicitud;
    SELECT @nuevo AS id, 'Mensaje enviado' AS mensaje;
END
GO

PRINT 'sp_soporte_ListarMensajes';
GO
CREATE PROCEDURE sp_soporte_ListarMensajes @idsolicitud BIGINT, @emisor VARCHAR(20)=NULL AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, idsolicitud, emisor, idemisor, nombre_emisor, mensaje, adjunto_base64, leido, fechacreacion
    FROM tbsoportemensaje
    WHERE idsolicitud=@idsolicitud AND activo=1
    ORDER BY fechacreacion ASC;
END
GO

PRINT 'sp_soporte_AsignarSoporte';
GO
CREATE PROCEDURE sp_soporte_AsignarSoporte @id BIGINT, @idUsuarioSoporte INT AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tbsoportesolicitud SET idusuariosoporte=@idUsuarioSoporte,
        estatus = CASE WHEN estatus='Abierto' THEN 'EnAtencion' ELSE estatus END,
        ultimaactualizacion=GETDATE()
    WHERE id=@id;
    SELECT 1 AS resultado, 'Solicitud asignada' AS mensaje;
END
GO

PRINT 'sp_soporte_CerrarSolicitud';
GO
CREATE PROCEDURE sp_soporte_CerrarSolicitud @id BIGINT, @idUsuarioSoporte INT=NULL, @comentario VARCHAR(500)=NULL AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tbsoportesolicitud SET estatus='Cerrado', fecha_cierre=GETDATE(),
        idusuariosoporte=ISNULL(@idUsuarioSoporte, idusuariosoporte),
        ultimaactualizacion=GETDATE()
    WHERE id=@id;
    IF @comentario IS NOT NULL AND LEN(@comentario) > 0
        INSERT INTO tbsoportemensaje(idsolicitud, emisor, idemisor, mensaje)
        VALUES(@id, 'soporte', @idUsuarioSoporte, @comentario);
    SELECT 1 AS resultado, 'Solicitud cerrada' AS mensaje;
END
GO

PRINT 'sp_soporte_MarcarLeidos';
GO
CREATE PROCEDURE sp_soporte_MarcarLeidos @idsolicitud BIGINT, @paraEmisor VARCHAR(20) AS
BEGIN
    SET NOCOUNT ON;
    IF @paraEmisor='soporte'
        UPDATE tbsoportemensaje SET leido=1 WHERE idsolicitud=@idsolicitud AND emisor<>'soporte' AND leido=0;
    ELSE
        UPDATE tbsoportemensaje SET leido=1 WHERE idsolicitud=@idsolicitud AND emisor='soporte' AND leido=0;
    SELECT 1 AS resultado, 'Marcados como leidos' AS mensaje;
END
GO

PRINT 'sp_soporte_ContarNoLeidos';
GO
CREATE PROCEDURE sp_soporte_ContarNoLeidos @paraEmisor VARCHAR(20)='soporte' AS
BEGIN
    SET NOCOUNT ON;
    IF @paraEmisor='soporte'
        SELECT COUNT(*) AS total FROM tbsoportemensaje m
        INNER JOIN tbsoportesolicitud s ON s.id=m.idsolicitud
        WHERE m.emisor<>'soporte' AND m.leido=0 AND m.activo=1 AND s.activo=1 AND s.estatus<>'Cerrado';
    ELSE
        SELECT COUNT(*) AS total FROM tbsoportemensaje m
        INNER JOIN tbsoportesolicitud s ON s.id=m.idsolicitud
        WHERE m.emisor='soporte' AND m.leido=0 AND m.activo=1 AND s.activo=1;
END
GO

PRINT '';
PRINT '=============================================';
PRINT ' SPs DE SOPORTE CREADOS';
PRINT '=============================================';
GO