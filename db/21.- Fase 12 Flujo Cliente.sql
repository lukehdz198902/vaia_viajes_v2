/* =========================================================
   21.- Fase 12: Flujo del cliente (pasajero)
   Compatible con SQL Server 2012
   ---------------------------------------------------------
   - Verificacion de telefono ANTES de crear la cuenta.
   - Verificacion de correo electronico (codigo por email).
   - Inicio de sesion / registro con Google.
   Script idempotente.
   ========================================================= */
USE vaia_viajes;
GO

/* ---------------------------------------------------------
   1) Marca de validacion en los codigos de WhatsApp
   --------------------------------------------------------- */
IF COL_LENGTH('dbo.tbpasajerocodigos','fechavalidacion') IS NULL
    ALTER TABLE dbo.tbpasajerocodigos ADD fechavalidacion DATETIME NULL;
GO

/* ---------------------------------------------------------
   2) Tabla de codigos de verificacion por correo
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.tbpasajerocodigoscorreo','U') IS NULL
BEGIN
    CREATE TABLE dbo.tbpasajerocodigoscorreo(
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        idpasajero BIGINT NOT NULL,
        correo VARCHAR(100) NOT NULL,
        codigoverificacion VARCHAR(50) NOT NULL,
        fechalimiteexpira DATETIME NOT NULL,
        activo BIT NOT NULL DEFAULT(1),
        fechavalidacion DATETIME NULL,
        fechacreacion DATETIME NOT NULL DEFAULT(GETDATE())
    );
    CREATE INDEX IX_pasajerocodigoscorreo_pasajero ON dbo.tbpasajerocodigoscorreo(idpasajero, activo);
END
GO

/* ---------------------------------------------------------
   2b) Enviar codigo de WhatsApp (version autoritativa,
       soporta telefono directo o idPasajero)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.sp_pasajero_EnviarCodigoVerificacion','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_EnviarCodigoVerificacion;
GO
CREATE PROCEDURE sp_pasajero_EnviarCodigoVerificacion @codigopaistel VARCHAR(15)=NULL, @telefono VARCHAR(30)=NULL, @idPasajero BIGINT=NULL AS
BEGIN
    SET NOCOUNT ON;

    IF @idPasajero IS NOT NULL AND (@codigopaistel IS NULL OR @telefono IS NULL)
        SELECT @codigopaistel=codigopaistel, @telefono=telefono FROM tbpasajero WHERE id=@idPasajero;

    IF @codigopaistel IS NULL OR @telefono IS NULL
    BEGIN SELECT -1 AS resultado, 'Faltan datos' AS mensaje, NULL AS codigoverificacion; RETURN; END

    DECLARE @codigo VARCHAR(50)=CAST(CAST(100000+RAND()*899999 AS INT) AS VARCHAR(6));
    DECLARE @limite DATETIME=DATEADD(MINUTE,10,GETDATE());

    UPDATE tbpasajerocodigos SET activo=0 WHERE codigopaistel=@codigopaistel AND notelefono=@telefono;
    INSERT INTO tbpasajerocodigos(codigopaistel,notelefono,codigoverificacion,fechalimiteexpira) VALUES(@codigopaistel,@telefono,@codigo,@limite);

    SELECT 1 AS resultado, 'Codigo enviado' AS mensaje, @codigo AS codigoverificacion;
END
GO

/* ---------------------------------------------------------
   3) Validar codigo de WhatsApp -> marca fechavalidacion
   --------------------------------------------------------- */
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

    UPDATE tbpasajerocodigos SET activo = 0, fechavalidacion = GETDATE()
     WHERE notelefono = @telefono AND codigoverificacion = @codigo;

    UPDATE tbpasajero
       SET telefonoconfirmado = 1, ultimaactualizacion = GETDATE()
     WHERE telefono = @telefono
       AND (@codigopaistel IS NULL OR codigopaistel = @codigopaistel);

    SELECT 1 AS resultado, 'Codigo validado' AS mensaje;
END
GO

/* ---------------------------------------------------------
   4) Registrar pasajero: exige telefono verificado por WhatsApp
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.sp_pasajero_Registrar','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_Registrar;
GO
CREATE PROCEDURE sp_pasajero_Registrar
    @idCompania SMALLINT, @nombre VARCHAR(50), @appaterno VARCHAR(50), @apmaterno VARCHAR(50),
    @correo VARCHAR(100), @codigopaistel VARCHAR(15)='+52', @telefono VARCHAR(30),
    @googlekey VARCHAR(MAX), @account VARCHAR(50), @pass VARCHAR(8000),
    @idiomapreferido SMALLINT=NULL, @fechanacimiento DATE=NULL, @genero CHAR(1)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS(SELECT 1 FROM tbpasajerocodigos
                       WHERE notelefono = @telefono
                         AND fechavalidacion IS NOT NULL
                         AND fechavalidacion >= DATEADD(MINUTE,-30,GETDATE()))
        BEGIN
            SELECT -4 AS id, 'Debes verificar tu telefono por WhatsApp antes de registrarte' AS mensaje;
            RETURN;
        END

        IF EXISTS(SELECT 1 FROM tbpasajero WHERE account=@account AND activo=1)
            BEGIN SELECT -1 AS id, 'La cuenta de usuario ya existe' AS mensaje; RETURN; END
        IF EXISTS(SELECT 1 FROM tbpasajero WHERE correo=@correo AND activo=1)
            BEGIN SELECT -2 AS id, 'El correo ya esta registrado' AS mensaje; RETURN; END
        IF EXISTS(SELECT 1 FROM tbpasajero WHERE telefono=@telefono AND activo=1)
            BEGIN SELECT -3 AS id, 'El telefono ya esta registrado' AS mensaje; RETURN; END

        INSERT INTO tbpasajero(idcompania,nombre,appaterno,apmaterno,correo,codigopaistel,telefono,googlekey,account,pass,
                               idiomapreferido,fechanacimiento,genero,telefonoconfirmado,conectado,ultimaconexionusr)
        VALUES(@idCompania,@nombre,@appaterno,@apmaterno,@correo,@codigopaistel,@telefono,@googlekey,@account,@pass,
               @idiomapreferido,@fechanacimiento,@genero,1,1,GETDATE());

        DECLARE @nuevoId BIGINT = SCOPE_IDENTITY();
        SELECT @nuevoId AS id, 'Registro exitoso' AS mensaje;
    END TRY
    BEGIN CATCH
        SELECT -99 AS id, ERROR_MESSAGE() AS mensaje;
    END CATCH
END
GO

/* ---------------------------------------------------------
   5) Enviar codigo de verificacion por correo
      @correoNuevo: si viene, se valida contra el correo nuevo
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.sp_pasajero_EnviarCodigoCorreo','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_EnviarCodigoCorreo;
GO
CREATE PROCEDURE sp_pasajero_EnviarCodigoCorreo @idPasajero BIGINT, @correoNuevo VARCHAR(100)=NULL AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @correo VARCHAR(100) = @correoNuevo;
    IF @correo IS NULL
        SELECT @correo = correo FROM tbpasajero WHERE id=@idPasajero AND activo=1;

    IF @correo IS NULL OR LTRIM(RTRIM(@correo))=''
    BEGIN SELECT -1 AS resultado, 'Pasajero sin correo registrado' AS mensaje, NULL AS correo, NULL AS codigoverificacion; RETURN; END

    IF @correoNuevo IS NOT NULL AND EXISTS(SELECT 1 FROM tbpasajero WHERE correo=@correoNuevo AND id<>@idPasajero AND activo=1)
    BEGIN SELECT -2 AS resultado, 'El correo ya esta en uso' AS mensaje, NULL AS correo, NULL AS codigoverificacion; RETURN; END

    DECLARE @codigo VARCHAR(50)=CAST(CAST(100000+RAND()*899999 AS INT) AS VARCHAR(6));
    DECLARE @limite DATETIME=DATEADD(MINUTE,15,GETDATE());

    UPDATE tbpasajerocodigoscorreo SET activo=0 WHERE idpasajero=@idPasajero AND activo=1;

    INSERT INTO tbpasajerocodigoscorreo(idpasajero,correo,codigoverificacion,fechalimiteexpira)
    VALUES(@idPasajero,@correo,@codigo,@limite);

    SELECT 1 AS resultado, 'Codigo enviado' AS mensaje, @correo AS correo, @codigo AS codigoverificacion;
END
GO

/* ---------------------------------------------------------
   6) Validar codigo de correo -> correoconfirmado = 1
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.sp_pasajero_ValidarCodigoCorreo','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_ValidarCodigoCorreo;
GO
CREATE PROCEDURE sp_pasajero_ValidarCodigoCorreo @idPasajero BIGINT, @codigo VARCHAR(50) AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(SELECT 1 FROM tbpasajerocodigoscorreo
                   WHERE idpasajero=@idPasajero AND codigoverificacion=@codigo
                     AND activo=1 AND fechalimiteexpira>=GETDATE())
    BEGIN SELECT -1 AS resultado, 'Codigo invalido o expirado' AS mensaje; RETURN; END

    UPDATE tbpasajerocodigoscorreo SET activo=0, fechavalidacion=GETDATE()
     WHERE idpasajero=@idPasajero AND codigoverificacion=@codigo;

    UPDATE tbpasajero SET correoconfirmado=1, ultimaactualizacion=GETDATE() WHERE id=@idPasajero;

    SELECT 1 AS resultado, 'Correo verificado' AS mensaje;
END
GO

/* ---------------------------------------------------------
   7) Cambiar correo (valida el codigo enviado al correo nuevo)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.sp_pasajero_CambiarCorreo','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_CambiarCorreo;
GO
CREATE PROCEDURE sp_pasajero_CambiarCorreo @idPasajero BIGINT, @correoNuevo VARCHAR(100), @codigo VARCHAR(50) AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS(SELECT 1 FROM tbpasajero WHERE correo=@correoNuevo AND id<>@idPasajero AND activo=1)
    BEGIN SELECT -1 AS resultado, 'El correo ya esta en uso' AS mensaje; RETURN; END

    IF NOT EXISTS(SELECT 1 FROM tbpasajerocodigoscorreo
                   WHERE idpasajero=@idPasajero AND correo=@correoNuevo
                     AND codigoverificacion=@codigo AND activo=1 AND fechalimiteexpira>=GETDATE())
    BEGIN SELECT -2 AS resultado, 'Codigo invalido o expirado' AS mensaje; RETURN; END

    UPDATE tbpasajerocodigoscorreo SET activo=0, fechavalidacion=GETDATE()
     WHERE idpasajero=@idPasajero AND codigoverificacion=@codigo;

    UPDATE tbpasajero SET correo=@correoNuevo, correoconfirmado=1, ultimaactualizacion=GETDATE() WHERE id=@idPasajero;

    SELECT 1 AS resultado, 'Correo actualizado' AS mensaje;
END
GO

/* ---------------------------------------------------------
   8) Iniciar sesion / registrar con Google
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.sp_pasajero_IniciarSesionGoogle','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_pasajero_IniciarSesionGoogle;
GO
CREATE PROCEDURE sp_pasajero_IniciarSesionGoogle
    @googleuserid VARCHAR(255), @correo VARCHAR(100), @nombre VARCHAR(50)=NULL, @appaterno VARCHAR(50)=NULL,
    @apmaterno VARCHAR(50)=NULL, @fotourl VARCHAR(1000)=NULL,
    @googlekey VARCHAR(MAX)=NULL, @googlekeyso VARCHAR(100)=NULL,
    @dispositivoinfo VARCHAR(500)=NULL, @sistemaoperativo VARCHAR(100)=NULL,
    @ipaddress VARCHAR(50)=NULL, @useragent VARCHAR(500)=NULL, @idCompania SMALLINT=1
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @idPasajero BIGINT;

        SELECT @idPasajero=id FROM tbpasajero WHERE googleuserid=@googleuserid AND activo=1;
        IF @idPasajero IS NULL AND @correo IS NOT NULL
            SELECT @idPasajero=id FROM tbpasajero WHERE correo=@correo AND activo=1;

        IF @idPasajero IS NULL
        BEGIN
            DECLARE @account VARCHAR(50)=LEFT(ISNULL(NULLIF(@correo,''),'google'),45);
            IF EXISTS(SELECT 1 FROM tbpasajero WHERE account=@account)
                SET @account=LEFT(@account,40)+CAST(CAST(RAND()*99999 AS INT) AS VARCHAR(5));

            INSERT INTO tbpasajero(idcompania,nombre,appaterno,apmaterno,correo,codigopaistel,telefono,googlekey,account,pass,
                                   googleuserid,eslogueadocongoogle,fotourlgoogle,correoconfirmado,telefonoconfirmado,conectado,ultimaconexionusr)
            VALUES(@idCompania,ISNULL(NULLIF(@nombre,''),'Usuario'),ISNULL(@appaterno,''),ISNULL(@apmaterno,''),@correo,'+52','',
                   @googlekey,@account,CONVERT(VARCHAR(8000),NEWID()),@googleuserid,1,@fotourl,1,0,1,GETDATE());
            SET @idPasajero=SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE tbpasajero
               SET googleuserid=@googleuserid, eslogueadocongoogle=1,
                   fotourlgoogle=ISNULL(@fotourl,fotourlgoogle),
                   correoconfirmado=CASE WHEN @correo IS NOT NULL THEN 1 ELSE correoconfirmado END,
                   conectado=1, ultimaconexionusr=GETDATE(),
                   googlekey=ISNULL(@googlekey,googlekey), googlekeyso=ISNULL(@googlekeyso,googlekeyso)
             WHERE id=@idPasajero;
        END

        INSERT INTO tbhistorialconexionespasajero(idpasajero,conectado) VALUES(@idPasajero,1);

        DECLARE @uuidsesion VARCHAR(1500)=NEWID();
        INSERT INTO tbsesionusuario(idtipousuario,idpasajero,uuidsesion,fechaconexion,activo,dispositivoinfo,sistemaoperativo,ipaddress,useragent)
        VALUES(1,@idPasajero,@uuidsesion,GETDATE(),1,@dispositivoinfo,@sistemaoperativo,@ipaddress,@useragent);

        SELECT p.id,p.idcompania,p.nombre,p.appaterno,p.apmaterno,p.correo,p.correoconfirmado,p.codigopaistel,p.telefono,p.telefonoconfirmado,
               p.fotoperfil,p.account,p.requierefacturacion,p.bloqueado,p.conectado,p.eslogueadocongoogle,p.googleuserid,p.fotourlgoogle,
               p.metodopagopreferido,p.idiomapreferido,p.fechanacimiento,p.genero,p.googlekey AS googlekeyso,
               mp.metodopago,i.idioma,@uuidsesion AS uuidsesion,'Inicio de sesion exitoso' AS mensaje
          FROM tbpasajero p
          LEFT JOIN tbmetodopago mp ON mp.id=p.metodopagopreferido
          LEFT JOIN tbidioma i ON i.id=p.idiomapreferido
         WHERE p.id=@idPasajero;
    END TRY
    BEGIN CATCH SELECT -99 AS id, ERROR_MESSAGE() AS mensaje; END CATCH
END
GO

PRINT 'Fase 12 (flujo del cliente) instalada correctamente.';
GO
