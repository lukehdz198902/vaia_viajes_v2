/* =========================================================
   17.- Fase 8: Documentos y Unidades del Conductor
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   - Alta/baja de documentos del conductor (base64)
   - Documentos del vehiculo
   - Limite de 10 unidades por conductor
   - No permitir cambiar de unidad con servicio activo
   - Marca/modelo como texto libre en tbunidad
   Script idempotente.
   ========================================================= */
USE vaia_viajes;
GO

/* ---------- 1. Columnas de contenido y texto libre ---------- */
IF COL_LENGTH('tbconductordocumentos','contenidoBase64') IS NULL
    ALTER TABLE tbconductordocumentos ADD contenidoBase64 VARCHAR(MAX) NULL;
GO
IF COL_LENGTH('tbconductorunidadesdocumentos','contenidoBase64') IS NULL
    ALTER TABLE tbconductorunidadesdocumentos ADD contenidoBase64 VARCHAR(MAX) NULL;
GO
IF COL_LENGTH('tbunidad','marcatxt') IS NULL
    ALTER TABLE tbunidad ADD marcatxt VARCHAR(100) NULL;
GO
IF COL_LENGTH('tbunidad','modelotxt') IS NULL
    ALTER TABLE tbunidad ADD modelotxt VARCHAR(100) NULL;
GO

/* ---------- 2. Alta de documento del conductor ---------- */
IF OBJECT_ID('dbo.sp_conductor_AgregarDocumento','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_AgregarDocumento;
GO
CREATE PROCEDURE sp_conductor_AgregarDocumento
@idConductor INT, @idtipoarchivo INT, @nombredocumento VARCHAR(150)=NULL, @contenidoBase64 VARCHAR(MAX)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM tbconductor WHERE id=@idConductor)
    BEGIN SELECT -1 AS resultado,'Conductor no encontrado' AS mensaje; RETURN; END
    IF @idtipoarchivo IS NULL
    BEGIN SELECT -2 AS resultado,'Tipo de documento requerido' AS mensaje; RETURN; END

    /* Si ya existe un documento de ese tipo, se reemplaza */
    IF EXISTS(SELECT 1 FROM tbconductordocumentos WHERE idconductor=@idConductor AND idtipoarchivo=@idtipoarchivo)
        DELETE FROM tbconductordocumentos WHERE idconductor=@idConductor AND idtipoarchivo=@idtipoarchivo;

    INSERT INTO tbconductordocumentos(idconductor,idfile,tokenidfile,idtipoarchivo,nombredocumento,comentarios,contenidoBase64,validado,enrevision,encorreccion,fechacreacion)
    VALUES(@idConductor,0,'',@idtipoarchivo,ISNULL(@nombredocumento,''),'',@contenidoBase64,NULL,1,0,GETDATE());

    DECLARE @idDoc BIGINT=SCOPE_IDENTITY();
    EXEC sp_conductor_ActualizarEstatusDocumentacion @idConductor, NULL;
    SELECT @idDoc AS id,'Documento cargado, pendiente de revision' AS mensaje;
END
GO

/* ---------- 3. Baja de documento ---------- */
IF OBJECT_ID('dbo.sp_conductor_EliminarDocumento','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_EliminarDocumento;
GO
CREATE PROCEDURE sp_conductor_EliminarDocumento @idDocumento BIGINT, @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM tbconductordocumentos WHERE id=@idDocumento AND idconductor=@idConductor;
    EXEC sp_conductor_ActualizarEstatusDocumentacion @idConductor, NULL;
    SELECT 1 AS resultado,'Documento eliminado' AS mensaje;
END
GO

/* ---------- 4. Listar documentos (sin el contenido) ---------- */
IF OBJECT_ID('dbo.sp_conductor_ListarDocumentos','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_ListarDocumentos;
GO
CREATE PROCEDURE sp_conductor_ListarDocumentos @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    SELECT cd.id, cd.idtipoarchivo, ta.tipoarchivo, cd.nombredocumento, cd.comentarios,
           cd.validado, cd.encorreccion, cd.enrevision, cd.comentariocorreccion, cd.fechacreacion,
           CASE WHEN cd.contenidoBase64 IS NULL OR cd.contenidoBase64='' THEN 0 ELSE 1 END AS tienearchivo
      FROM tbconductordocumentos cd
      INNER JOIN tbtipoarchivo ta ON ta.id=cd.idtipoarchivo
     WHERE cd.idconductor=@idConductor
     ORDER BY cd.fechacreacion DESC;
END
GO

/* ---------- 5. Obtener contenido de un documento ---------- */
IF OBJECT_ID('dbo.sp_conductor_ObtenerDocumento','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_ObtenerDocumento;
GO
CREATE PROCEDURE sp_conductor_ObtenerDocumento @idDocumento BIGINT AS
BEGIN
    SET NOCOUNT ON;
    SELECT id, idconductor, idtipoarchivo, nombredocumento, contenidoBase64 FROM tbconductordocumentos WHERE id=@idDocumento;
END
GO

/* ---------- 6. Alta de documento de unidad ---------- */
IF OBJECT_ID('dbo.sp_conductor_AgregarDocumentoUnidad','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_AgregarDocumentoUnidad;
GO
CREATE PROCEDURE sp_conductor_AgregarDocumentoUnidad
@idConductor INT, @idunidad INT, @idtipoarchivounidad INT, @nombredocumento VARCHAR(150)=NULL, @contenidoBase64 VARCHAR(MAX)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM tbconductorunidades WHERE idconductor=@idConductor AND idunidad=@idunidad)
    BEGIN SELECT -1 AS resultado,'La unidad no pertenece al conductor' AS mensaje; RETURN; END

    IF EXISTS(SELECT 1 FROM tbconductorunidadesdocumentos WHERE idunidad=@idunidad AND idtipoarchivounidad=@idtipoarchivounidad)
        DELETE FROM tbconductorunidadesdocumentos WHERE idunidad=@idunidad AND idtipoarchivounidad=@idtipoarchivounidad;

    INSERT INTO tbconductorunidadesdocumentos(idunidad,idconductor,idfile,tokenidfile,idtipoarchivounidad,nombredocumento,comentarios,contenidoBase64,validado,enrevision,encorreccion,fechacreacion)
    VALUES(@idunidad,@idConductor,0,'',@idtipoarchivounidad,ISNULL(@nombredocumento,''),'',@contenidoBase64,NULL,1,0,GETDATE());

    SELECT SCOPE_IDENTITY() AS id,'Documento de unidad cargado' AS mensaje;
END
GO

/* ---------- 7. Listar documentos de una unidad ---------- */
IF OBJECT_ID('dbo.sp_conductor_ListarDocumentosUnidad','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_ListarDocumentosUnidad;
GO
CREATE PROCEDURE sp_conductor_ListarDocumentosUnidad @idConductor INT, @idunidad INT AS
BEGIN
    SET NOCOUNT ON;
    SELECT d.id, d.idtipoarchivounidad, ta.tipoarchivo, d.nombredocumento, d.validado, d.enrevision, d.encorreccion,
           d.comentariocorreccion, d.fechacreacion,
           CASE WHEN d.contenidoBase64 IS NULL OR d.contenidoBase64='' THEN 0 ELSE 1 END AS tienearchivo
      FROM tbconductorunidadesdocumentos d
      LEFT JOIN tbtipoarchivounidad ta ON ta.id=d.idtipoarchivounidad
     WHERE d.idconductor=@idConductor AND d.idunidad=@idunidad
     ORDER BY d.fechacreacion DESC;
END
GO

/* ---------- 8. Agregar unidad (limite 10 + marca/modelo texto) ---------- */
IF OBJECT_ID('dbo.sp_conductor_AgregarUnidad','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_AgregarUnidad;
GO
CREATE PROCEDURE sp_conductor_AgregarUnidad
@idConductor INT, @marca VARCHAR(100)=NULL, @modelo VARCHAR(100)=NULL, @anio INT=NULL,
@color VARCHAR(50)=NULL, @placas VARCHAR(100)=NULL, @asientos TINYINT=4
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @total INT = (SELECT COUNT(*) FROM tbconductorunidades cu INNER JOIN tbunidad u ON u.id=cu.idunidad WHERE cu.idconductor=@idConductor AND u.activo=1);
    IF @total >= 10
    BEGIN SELECT -2 AS resultado,'Maximo 10 unidades por conductor' AS mensaje; RETURN; END

    IF @placas IS NOT NULL AND EXISTS(SELECT 1 FROM tbconductorunidades cu INNER JOIN tbunidad u ON u.id=cu.idunidad WHERE cu.idconductor=@idConductor AND u.placas=@placas AND u.activo=1)
    BEGIN SELECT -1 AS resultado,'Placas ya registradas' AS mensaje; RETURN; END

    INSERT INTO tbunidad(unidad,alias,marcatxt,modelotxt,modelo,aniofabricacion,colorhex,colornombre,numeroasientos,placas,activo)
    VALUES(@placas,@modelo,@marca,@modelo,0,@anio,'',ISNULL(@color,''),ISNULL(@asientos,4),@placas,1);
    DECLARE @idUnidad INT=SCOPE_IDENTITY();
    INSERT INTO tbconductorunidades(idconductor,idunidad,aprobada,enuso) VALUES(@idConductor,@idUnidad,0,0);
    SELECT @idUnidad AS id,'Unidad registrada, pendiente de aprobacion' AS mensaje;
END
GO

/* ---------- 9. Seleccionar unidad (no permitir con servicio activo) ---------- */
IF OBJECT_ID('dbo.sp_conductor_SeleccionarUnidad','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_SeleccionarUnidad;
GO
CREATE PROCEDURE sp_conductor_SeleccionarUnidad @idConductor INT, @idUnidad INT AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS(SELECT 1 FROM tbservicios s INNER JOIN tbservicioestatus e ON e.id=s.idservicioestatus
               WHERE s.idconductor=@idConductor AND e.estatus IN ('En Camino','Llego al Origen','En Viaje'))
    BEGIN SELECT -2 AS resultado,'No puedes cambiar de unidad con un servicio activo' AS mensaje; RETURN; END

    IF NOT EXISTS(SELECT 1 FROM tbconductorunidades WHERE idconductor=@idConductor AND idunidad=@idUnidad AND aprobada=1)
    BEGIN SELECT -1 AS resultado,'Unidad no aprobada' AS mensaje; RETURN; END

    UPDATE tbconductorunidades SET enuso=0 WHERE idconductor=@idConductor;
    UPDATE tbconductorunidades SET enuso=1 WHERE idconductor=@idConductor AND idunidad=@idUnidad;
    SELECT 1 AS resultado,'Unidad seleccionada' AS mensaje;
END
GO

/* ---------- 10. Listar unidades con datos de texto ---------- */
IF OBJECT_ID('dbo.sp_conductor_ListarUnidades','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_ListarUnidades;
GO
CREATE PROCEDURE sp_conductor_ListarUnidades @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    SELECT cu.idconductor, cu.idunidad, cu.aprobada, cu.enuso,
           u.unidad, u.alias, u.marcatxt AS marca, u.modelotxt AS modelo, u.aniofabricacion AS anio,
           u.colornombre AS color, u.colorhex, u.numeroasientos, u.placas, u.noserie,
           (SELECT COUNT(*) FROM tbconductorunidadesdocumentos d WHERE d.idunidad=u.id AND (d.contenidoBase64 IS NOT NULL AND d.contenidoBase64<>'')) AS documentos
      FROM tbconductorunidades cu
      INNER JOIN tbunidad u ON u.id=cu.idunidad
     WHERE cu.idconductor=@idConductor AND u.activo=1;
END
GO

/* ---------- 11. Catalogo de tipos de documento ---------- */
IF OBJECT_ID('dbo.sp_conductor_ListarTiposDocumento','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_ListarTiposDocumento;
GO
CREATE PROCEDURE sp_conductor_ListarTiposDocumento @para VARCHAR(20)='conductor' AS
BEGIN
    SET NOCOUNT ON;
    IF @para='unidad'
        SELECT id, tipoarchivo, descripcion FROM tbtipoarchivounidad WHERE activo=1 ORDER BY id;
    ELSE
        SELECT id, tipoarchivo, descripcion FROM tbtipoarchivo WHERE activo=1 AND paraaltaconductor=1 ORDER BY id;
END
GO

PRINT 'Fase 8 (documentos y unidades) instalada correctamente.';
GO
