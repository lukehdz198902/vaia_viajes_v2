/* =========================================================
   16.- Fase 7: Registro y Verificacion del Conductor
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   - Columnas: correoconfirmado, codigopaistel
   - Verificacion de TELEFONO por WhatsApp (tbconductorcodigos)
   - Verificacion de CORREO por email (tbconductorcorreocodigos)
   - Registro guarda el pais y marca el telefono como confirmado
   Script idempotente.
   ========================================================= */
USE vaia_viajes;
GO

/* ---------- 1. Columnas nuevas en tbconductor ---------- */
IF COL_LENGTH('tbconductor','correoconfirmado') IS NULL
    ALTER TABLE tbconductor ADD correoconfirmado BIT DEFAULT 0;
GO
IF COL_LENGTH('tbconductor','codigopaistel') IS NULL
    ALTER TABLE tbconductor ADD codigopaistel VARCHAR(15) NULL;
GO

/* ---------- 2. Tabla de codigos de correo ---------- */
IF OBJECT_ID('tbconductorcorreocodigos','U') IS NULL
CREATE TABLE tbconductorcorreocodigos
(
    id BIGINT IDENTITY PRIMARY KEY,
    idconductor INT NULL,
    correo VARCHAR(100) NOT NULL,
    codigoverificacion VARCHAR(50) NOT NULL,
    fechalimiteexpira DATETIME NOT NULL,
    activo BIT DEFAULT 1,
    fechacreacion DATETIME DEFAULT GETDATE()
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tbconductorcorreocodigos' AND object_id = OBJECT_ID('tbconductorcorreocodigos'))
    CREATE INDEX IX_tbconductorcorreocodigos ON tbconductorcorreocodigos(correo, codigoverificacion, activo);
GO

/* ---------- 3. Enviar codigo de TELEFONO (WhatsApp) ---------- */
IF OBJECT_ID('dbo.sp_conductor_EnviarCodigoVerificacion','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_EnviarCodigoVerificacion;
GO
CREATE PROCEDURE sp_conductor_EnviarCodigoVerificacion @codigopaistel VARCHAR(15)=NULL, @telefono VARCHAR(30)=NULL AS
BEGIN
    SET NOCOUNT ON;
    IF @codigopaistel IS NULL OR @telefono IS NULL
    BEGIN SELECT -1 AS resultado, 'Faltan datos' AS mensaje; RETURN; END

    DECLARE @codigo VARCHAR(50)=CAST(CAST(100000+RAND()*899999 AS INT) AS VARCHAR(6));
    DECLARE @limite DATETIME=DATEADD(MINUTE,10,GETDATE());

    UPDATE tbconductorcodigos SET activo=0 WHERE codigopaistel=@codigopaistel AND notelefono=@telefono;
    INSERT INTO tbconductorcodigos(codigopaistel,notelefono,codigoverificacion,fechalimiteexpira)
    VALUES(@codigopaistel,@telefono,@codigo,@limite);

    SELECT 1 AS resultado, 'Codigo enviado' AS mensaje, @codigo AS codigoverificacion;
END
GO

/* ---------- 4. Validar codigo de TELEFONO ---------- */
IF OBJECT_ID('dbo.sp_conductor_ValidarCodigoVerificacion','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_ValidarCodigoVerificacion;
GO
CREATE PROCEDURE sp_conductor_ValidarCodigoVerificacion @codigopaistel VARCHAR(15)=NULL, @telefono VARCHAR(30)=NULL, @codigo VARCHAR(50)=NULL AS
BEGIN
    SET NOCOUNT ON;
    IF @telefono IS NULL OR @codigo IS NULL OR LTRIM(RTRIM(@codigo))=''
    BEGIN SELECT -1 AS resultado, 'Codigo requerido' AS mensaje; RETURN; END

    IF NOT EXISTS(SELECT 1 FROM tbconductorcodigos
                   WHERE notelefono=@telefono AND codigoverificacion=@codigo
                     AND activo=1 AND fechalimiteexpira>=GETDATE())
    BEGIN SELECT -2 AS resultado, 'Codigo invalido o expirado' AS mensaje; RETURN; END

    UPDATE tbconductorcodigos SET activo=0 WHERE notelefono=@telefono AND codigoverificacion=@codigo;

    UPDATE tbconductor SET telefonoconfirmado=1, codigopaistel=ISNULL(@codigopaistel,codigopaistel), ultimaactualizacion=GETDATE()
     WHERE telefono=@telefono;

    SELECT 1 AS resultado, 'Telefono verificado' AS mensaje;
END
GO

/* ---------- 5. Enviar codigo de CORREO ---------- */
IF OBJECT_ID('dbo.sp_conductor_EnviarCodigoCorreo','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_EnviarCodigoCorreo;
GO
CREATE PROCEDURE sp_conductor_EnviarCodigoCorreo @idConductor INT=NULL, @correo VARCHAR(100)=NULL AS
BEGIN
    SET NOCOUNT ON;
    IF @idConductor IS NOT NULL AND @correo IS NULL
        SELECT @correo=correo FROM tbconductor WHERE id=@idConductor;
    IF @correo IS NULL OR LTRIM(RTRIM(@correo))=''
    BEGIN SELECT -1 AS resultado, 'Correo requerido' AS mensaje; RETURN; END

    DECLARE @codigo VARCHAR(50)=CAST(CAST(100000+RAND()*899999 AS INT) AS VARCHAR(6));
    DECLARE @limite DATETIME=DATEADD(MINUTE,15,GETDATE());

    UPDATE tbconductorcorreocodigos SET activo=0 WHERE correo=@correo;
    INSERT INTO tbconductorcorreocodigos(idconductor,correo,codigoverificacion,fechalimiteexpira)
    VALUES(@idConductor,@correo,@codigo,@limite);

    SELECT 1 AS resultado, 'Codigo enviado' AS mensaje, @codigo AS codigoverificacion;
END
GO

/* ---------- 6. Validar codigo de CORREO ---------- */
IF OBJECT_ID('dbo.sp_conductor_ValidarCodigoCorreo','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_ValidarCodigoCorreo;
GO
CREATE PROCEDURE sp_conductor_ValidarCodigoCorreo @correo VARCHAR(100)=NULL, @codigo VARCHAR(50)=NULL AS
BEGIN
    SET NOCOUNT ON;
    IF @correo IS NULL OR @codigo IS NULL OR LTRIM(RTRIM(@codigo))=''
    BEGIN SELECT -1 AS resultado, 'Datos requeridos' AS mensaje; RETURN; END

    IF NOT EXISTS(SELECT 1 FROM tbconductorcorreocodigos
                   WHERE correo=@correo AND codigoverificacion=@codigo
                     AND activo=1 AND fechalimiteexpira>=GETDATE())
    BEGIN SELECT -2 AS resultado, 'Codigo invalido o expirado' AS mensaje; RETURN; END

    UPDATE tbconductorcorreocodigos SET activo=0 WHERE correo=@correo AND codigoverificacion=@codigo;
    UPDATE tbconductor SET correoconfirmado=1, ultimaactualizacion=GETDATE() WHERE correo=@correo;

    SELECT 1 AS resultado, 'Correo verificado' AS mensaje;
END
GO

/* ---------- 7. Actualizar correo (para reenviar verificacion) ---------- */
IF OBJECT_ID('dbo.sp_conductor_ActualizarCorreo','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_ActualizarCorreo;
GO
CREATE PROCEDURE sp_conductor_ActualizarCorreo @idConductor INT, @correo VARCHAR(100) AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM tbconductor WHERE correo=@correo AND id<>@idConductor AND activo=1)
    BEGIN SELECT -1 AS resultado, 'Correo ya registrado' AS mensaje; RETURN; END

    UPDATE tbconductor SET correo=@correo, correoconfirmado=0, ultimaactualizacion=GETDATE() WHERE id=@idConductor;
    SELECT 1 AS resultado, 'Correo actualizado' AS mensaje;
END
GO

/* ---------- 8. Registro: guarda pais y marca telefono confirmado ---------- */
IF OBJECT_ID('dbo.sp_conductor_Registrar','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_conductor_Registrar;
GO
CREATE PROCEDURE sp_conductor_Registrar
@idCompania SMALLINT, @idZonaCobertura INT=NULL, @nombre VARCHAR(50), @appaterno VARCHAR(50), @apmaterno VARCHAR(50),
@sexo CHAR(1), @correo VARCHAR(100), @telefono VARCHAR(30), @googlekey VARCHAR(MAX),
@account VARCHAR(50), @pass VARCHAR(8000), @curp VARCHAR(50)=NULL, @rfc VARCHAR(50)=NULL,
@licencia VARCHAR(50)=NULL, @idioma SMALLINT=NULL, @fechaNac DATE=NULL, @codigopaistel VARCHAR(15)=NULL
AS
BEGIN
SET NOCOUNT ON;
IF EXISTS(SELECT 1 FROM tbconductor WHERE account=@account AND activo=1) BEGIN SELECT -1 AS id, 'Cuenta ya existe' AS mensaje; RETURN; END
IF EXISTS(SELECT 1 FROM tbconductor WHERE correo=@correo AND activo=1) BEGIN SELECT -2 AS id, 'Correo ya registrado' AS mensaje; RETURN; END
IF EXISTS(SELECT 1 FROM tbconductor WHERE telefono=@telefono AND activo=1) BEGIN SELECT -3 AS id, 'Telefono ya registrado' AS mensaje; RETURN; END

DECLARE @idEstVal SMALLINT=(SELECT id FROM tbconductorestatus WHERE conductorestatus='En Validacion');
DECLARE @idEstDocs INT=(SELECT id FROM tbestatusdocumentacion WHERE nombreestatusdocs='Pendiente');

INSERT INTO tbconductor(idcompania,idzonacobertura,nombre,appaterno,apmaterno,idconductorestatus,sexo,correo,telefono,googlekey,account,pass,idestatusdocumentacion,documentacionaprobada,curp,rfc,licenciaconducir,idiomapreferido,fechanacimiento,conectado,ultimaconexionusr,telefonoconfirmado,codigopaistel)
VALUES(@idCompania,@idZonaCobertura,@nombre,@appaterno,@apmaterno,@idEstVal,@sexo,@correo,@telefono,@googlekey,@account,@pass,@idEstDocs,0,@curp,@rfc,@licencia,@idioma,@fechaNac,1,GETDATE(),1,@codigopaistel);

DECLARE @nuevoId INT=SCOPE_IDENTITY();
INSERT INTO tbconductorgps(idconductor,lat,lng,lastposition,previouslat,previouslng) VALUES(@nuevoId,'','',GETDATE(),'','');
INSERT INTO tbhistorialconexionesconductor(idconductor,conectado) VALUES(@nuevoId,1);
SELECT @nuevoId AS id, 'Registro exitoso. Complete su documentacion.' AS mensaje;
END
GO

PRINT 'Fase 7 (registro y verificacion del conductor) instalada correctamente.';
GO
