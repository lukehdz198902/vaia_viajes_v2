/*
 =============================================
 SCRIPT DE FUNCIONES Y PROCEDIMIENTOS ALMACENADOS
 PARA EL SISTEMA VAIA VIAJES
 =============================================
 Fecha: 2026
 Descripcion: Contiene todas las funciones y procedimientos
 almacenados para las aplicaciones de pasajero, conductor
 y plataforma web de administradores.
 =============================================
*/

USE vaia_viajes;
GO

/* ============================================
   FUNCIONES DE UTILERIA
   ============================================ */

CREATE FUNCTION fn_ObtenerNombreCompletoPasajero (@idPasajero BIGINT)
RETURNS VARCHAR(200) AS BEGIN
    DECLARE @n VARCHAR(200);
    SELECT @n = ISNULL(nombre,'')+' '+ISNULL(appaterno,'')+' '+ISNULL(apmaterno,'') FROM tbpasajero WHERE id=@idPasajero;
    RETURN LTRIM(RTRIM(@n));
END
GO

CREATE FUNCTION fn_ObtenerNombreCompletoConductor (@idConductor INT)
RETURNS VARCHAR(200) AS BEGIN
    DECLARE @n VARCHAR(200);
    SELECT @n = ISNULL(nombre,'')+' '+ISNULL(appaterno,'')+' '+ISNULL(apmaterno,'') FROM tbconductor WHERE id=@idConductor;
    RETURN LTRIM(RTRIM(@n));
END
GO

CREATE FUNCTION fn_ObtenerNombreCompletoUsuario (@idUsuario INT)
RETURNS VARCHAR(200) AS BEGIN
    DECLARE @n VARCHAR(200);
    SELECT @n = ISNULL(nombre,'')+' '+ISNULL(appaterno,'')+' '+ISNULL(apmaterno,'') FROM tbusuario WHERE id=@idUsuario;
    RETURN LTRIM(RTRIM(@n));
END
GO

CREATE FUNCTION fn_CalcularDistancia (@lat1 DECIMAL(18,10), @lng1 DECIMAL(18,10), @lat2 DECIMAL(18,10), @lng2 DECIMAL(18,10))
RETURNS DECIMAL(18,2) AS BEGIN
    DECLARE @d DECIMAL(18,2);
    DECLARE @R DECIMAL(10,2) = 6371;
    DECLARE @dlat DECIMAL(18,10) = RADIANS(@lat2-@lat1);
    DECLARE @dlng DECIMAL(18,10) = RADIANS(@lng2-@lng1);
    DECLARE @a DECIMAL(18,10) = SIN(@dlat/2)*SIN(@dlat/2)+COS(RADIANS(@lat1))*COS(RADIANS(@lat2))*SIN(@dlng/2)*SIN(@dlng/2);
    DECLARE @c DECIMAL(18,10) = 2*ATN2(SQRT(@a),SQRT(1-@a));
    SET @d = @R*@c;
    RETURN ROUND(@d,2);
END
GO

CREATE FUNCTION fn_ValidarTokenApp (@appName VARCHAR(50), @token VARCHAR(MAX))
RETURNS BIT AS BEGIN
    DECLARE @v BIT = 0;
    IF EXISTS (SELECT 1 FROM tbTokensApp WHERE appName=@appName AND (token=@token OR tokensecundario=@token) AND (fechaexpira>=GETDATE() OR fechaexpirasecundario>=GETDATE()))
        SET @v = 1;
    RETURN @v;
END
GO

CREATE FUNCTION fn_CalcularCostoViaje (@idCompania SMALLINT, @distanciaMetros INT, @duracionSegundos INT, @fechaViaje DATETIME)
RETURNS DECIMAL(18,2) AS BEGIN
    DECLARE @c DECIMAL(18,2)=0, @dia TINYINT=DATEPART(WEEKDAY,@fechaViaje), @hora TIME=CAST(@fechaViaje AS TIME);
    DECLARE @km DECIMAL(18,2)=@distanciaMetros/1000.0, @min DECIMAL(18,2)=@duracionSegundos/60.0;
    SELECT TOP 1 @c=costominimo+(@km*costoporkm)+(@min*costoporminuto)
    FROM tbappviajecostos WHERE idcompania=@idCompania AND numdiasemana=@dia AND @hora BETWEEN horainicio AND horafin
    ORDER BY costominimo;
    IF @c IS NULL OR @c=0
        SELECT TOP 1 @c=costominimo+(@km*costoporkm)+(@min*costoporminuto)
        FROM tbappviajecostos WHERE idcompania=@idCompania ORDER BY costominimo;
    RETURN ISNULL(@c,0);
END
GO

CREATE FUNCTION fn_CalcularComision (@idZonaCobertura INT, @montoViaje DECIMAL(18,2))
RETURNS DECIMAL(18,2) AS BEGIN
    DECLARE @c DECIMAL(18,2)=0, @p DECIMAL(5,2), @min DECIMAL(10,2), @max DECIMAL(10,2);
    SELECT TOP 1 @p=porcentajecomision,@min=comisionminima,@max=comisionmaxima FROM tbzonacoberturacomision WHERE idzonacobertura=@idZonaCobertura AND activo=1;
    SET @p=ISNULL(@p,3.00); SET @c=@montoViaje*(@p/100);
    IF @c<ISNULL(@min,0) SET @c=ISNULL(@min,0);
    RETURN ROUND(@c,2);
END
GO

CREATE FUNCTION fn_ValidarCodigoPromocional (@codigo VARCHAR(100), @idPasajero BIGINT, @montoViaje DECIMAL(18,2))
RETURNS @r TABLE (valido BIT, mensaje VARCHAR(500), montodescuento DECIMAL(18,2), esporcentaje BIT, idcodigopromo INT) AS BEGIN
    DECLARE @id INT, @vh DATETIME, @ep BIT, @md DECIMAL(18,2), @um INT, @ua INT, @mm DECIMAL(10,2), @uu BIGINT, @vd DATETIME;
    SELECT @id=id,@vh=vigentehasta,@ep=esporcentaje,@md=montodecuento,@um=usosmaximos,@ua=usosactuales,@mm=montominimoviaje,@uu=usuariounicopasajero,@vd=validodesde
    FROM tbcodigospromo WHERE codigopromocional=@codigo AND activo=1;
    IF @id IS NULL BEGIN INSERT INTO @r VALUES(0,'Codigo no existe o inactivo',0,0,NULL); RETURN; END
    IF @vh<GETDATE() BEGIN INSERT INTO @r VALUES(0,'Codigo expirado',0,0,NULL); RETURN; END
    IF @vd>GETDATE() BEGIN INSERT INTO @r VALUES(0,'Codigo no vigente',0,0,NULL); RETURN; END
    IF @um>0 AND @ua>=@um BEGIN INSERT INTO @r VALUES(0,'Limite de usos alcanzado',0,0,NULL); RETURN; END
    IF @uu IS NOT NULL AND @uu<>@idPasajero BEGIN INSERT INTO @r VALUES(0,'No disponible para tu cuenta',0,0,NULL); RETURN; END
    IF @mm IS NOT NULL AND @montoViaje<@mm BEGIN INSERT INTO @r VALUES(0,'Monto minimo no alcanzado',0,0,NULL); RETURN; END
    DECLARE @df DECIMAL(18,2); IF @ep=1 SET @df=@montoViaje*(@md/100); ELSE SET @df=@md;
    IF @df>@montoViaje SET @df=@montoViaje;
    INSERT INTO @r VALUES(1,'Codigo valido',@df,@ep,@id); RETURN;
END
GO

CREATE FUNCTION fn_ConductoresCercanos (@lat VARCHAR(50), @lng VARCHAR(50), @radioKm INT, @limite INT, @idZona INT=NULL)
RETURNS TABLE AS RETURN (
    SELECT TOP(@limite)
        c.id, c.nombre, c.appaterno, c.apmaterno, c.fotoperfil, c.correo, c.telefono, ISNULL(c.googlekey,'') AS googlekey,
        g.lat, g.lng,
        dbo.fn_CalcularDistancia(CAST(ISNULL(NULLIF(@lat,''),'0') AS DECIMAL(18,10)),CAST(ISNULL(NULLIF(@lng,''),'0') AS DECIMAL(18,10)),CAST(ISNULL(NULLIF(g.lat,''),'0') AS DECIMAL(18,10)),CAST(ISNULL(NULLIF(g.lng,''),'0') AS DECIMAL(18,10))) AS distancia_km,
        u.id AS idunidad, u.unidad, u.alias, u.colorhex, u.colornombre, u.numeroasientos, u.placas,
        sm.nombresubmarca, m.nombremarca, ce.conductorestatus
    FROM tbconductor c
    INNER JOIN tbconductorgps g ON g.idconductor=c.id
    INNER JOIN tbconductorestatus ce ON ce.id=c.idconductorestatus
    LEFT JOIN tbconductorunidades cu ON cu.idconductor=c.id AND cu.enuso=1 AND cu.aprobada=1
    LEFT JOIN tbunidad u ON u.id=cu.idunidad
    LEFT JOIN tbsubmarca sm ON sm.id=u.idsubmarca
    LEFT JOIN tbmarca m ON m.id=sm.idmarca
    WHERE c.activo=1 AND c.bloqueado=0 AND c.documentacionaprobada=1
      AND ce.conductorestatus='Disponible'
      AND g.lat IS NOT NULL AND g.lng IS NOT NULL
      AND (@idZona IS NULL OR c.idzonacobertura=@idZona)
      AND dbo.fn_CalcularDistancia(CAST(ISNULL(NULLIF(@lat,''),'0') AS DECIMAL(18,10)),CAST(ISNULL(NULLIF(@lng,''),'0') AS DECIMAL(18,10)),CAST(ISNULL(NULLIF(g.lat,''),'0') AS DECIMAL(18,10)),CAST(ISNULL(NULLIF(g.lng,''),'0') AS DECIMAL(18,10)))<=@radioKm
)
GO

/* ============================================
   SECCION: PROCEDIMIENTOS APP PASAJERO
   ============================================ */

CREATE PROCEDURE sp_pasajero_Registrar
    @idCompania SMALLINT, @nombre VARCHAR(50), @appaterno VARCHAR(50), @apmaterno VARCHAR(50),
    @correo VARCHAR(100), @codigopaistel VARCHAR(15)='+52', @telefono VARCHAR(30),
    @googlekey VARCHAR(MAX), @account VARCHAR(50), @pass VARCHAR(8000),
    @idiomapreferido SMALLINT=NULL, @fechanacimiento DATE=NULL, @genero CHAR(1)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS(SELECT 1 FROM tbpasajero WHERE account=@account AND activo=1)
            BEGIN SELECT -1 AS id, 'La cuenta de usuario ya existe' AS mensaje; RETURN; END
        IF EXISTS(SELECT 1 FROM tbpasajero WHERE correo=@correo AND activo=1)
            BEGIN SELECT -2 AS id, 'El correo ya esta registrado' AS mensaje; RETURN; END
        IF EXISTS(SELECT 1 FROM tbpasajero WHERE telefono=@telefono AND activo=1)
            BEGIN SELECT -3 AS id, 'El telefono ya esta registrado' AS mensaje; RETURN; END
        INSERT INTO tbpasajero(idcompania,nombre,appaterno,apmaterno,correo,codigopaistel,telefono,googlekey,account,pass,idiomapreferido,fechanacimiento,genero,conectado,ultimaconexionusr)
        VALUES(@idCompania,@nombre,@appaterno,@apmaterno,@correo,@codigopaistel,@telefono,@googlekey,@account,@pass,@idiomapreferido,@fechanacimiento,@genero,1,GETDATE());
        DECLARE @nuevoId BIGINT = SCOPE_IDENTITY();
        SELECT @nuevoId AS id, 'Registro exitoso' AS mensaje;
    END TRY
    BEGIN CATCH
        SELECT -99 AS id, ERROR_MESSAGE() AS mensaje;
    END CATCH
END
GO

CREATE PROCEDURE sp_pasajero_IniciarSesion
    @account VARCHAR(50), @pass VARCHAR(8000), @googlekey VARCHAR(MAX)=NULL, @googlekeyso VARCHAR(100)=NULL,
    @dispositivoinfo VARCHAR(500)=NULL, @sistemaoperativo VARCHAR(100)=NULL, @ipaddress VARCHAR(50)=NULL,
    @useragent VARCHAR(500)=NULL, @esLoginGoogle BIT=0, @googleuserid VARCHAR(255)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @idPasajero BIGINT;
        IF @esLoginGoogle=1 AND @googleuserid IS NOT NULL
            SELECT @idPasajero=id FROM tbpasajero WHERE googleuserid=@googleuserid AND activo=1 AND bloqueado=0;
        ELSE
            SELECT @idPasajero=id FROM tbpasajero WHERE (account=@account OR correo=@account) AND pass=@pass AND activo=1 AND bloqueado=0;
        IF @idPasajero IS NULL BEGIN SELECT -1 AS id, 'Credenciales invalidas o cuenta bloqueada' AS mensaje; RETURN; END
        UPDATE tbpasajero SET conectado=1, ultimaconexionusr=GETDATE(), googlekey=ISNULL(@googlekey,googlekey), googlekeyso=ISNULL(@googlekeyso,googlekeyso) WHERE id=@idPasajero;
        INSERT INTO tbhistorialconexionespasajero(idpasajero,conectado) VALUES(@idPasajero,1);
        DECLARE @uuidsesion VARCHAR(1500)=NEWID();
        INSERT INTO tbsesionusuario(idtipousuario,idpasajero,uuidsesion,fechaconexion,activo,dispositivoinfo,sistemaoperativo,ipaddress,useragent)
        VALUES(1,@idPasajero,@uuidsesion,GETDATE(),1,@dispositivoinfo,@sistemaoperativo,@ipaddress,@useragent);
SELECT p.id,p.idcompania,p.nombre,p.appaterno,p.apmaterno,p.correo,p.correoconfirmado,p.codigopaistel,p.telefono,p.telefonoconfirmado,p.fotoperfil,p.account,
               p.requierefacturacion,p.bloqueado,p.conectado,p.eslogueadocongoogle,p.googleuserid,p.fotourlgoogle,p.metodopagopreferido,p.idiomapreferido,p.fechanacimiento,p.genero,
               p.googlekey AS googlekeyso,
               mp.metodopago,i.idioma,@uuidsesion AS uuidsesion,'Inicio de sesion exitoso' AS mensaje
        FROM tbpasajero p LEFT JOIN tbmetodopago mp ON mp.id=p.metodopagopreferido LEFT JOIN tbidioma i ON i.id=p.idiomapreferido WHERE p.id=@idPasajero;
    END TRY
    BEGIN CATCH SELECT -99 AS id, ERROR_MESSAGE() AS mensaje; END CATCH
END
GO

CREATE PROCEDURE sp_pasajero_CerrarSesion @idPasajero BIGINT, @uuidsesion VARCHAR(1500)=NULL AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE tbpasajero SET conectado=0, ultimadesconexionusr=GETDATE() WHERE id=@idPasajero;
        INSERT INTO tbhistorialconexionespasajero(idpasajero,conectado) VALUES(@idPasajero,0);
        IF @uuidsesion IS NOT NULL
            UPDATE tbsesionusuario SET activo=0, fechadesconexion=GETDATE() WHERE uuidsesion=@uuidsesion AND idpasajero=@idPasajero;
        ELSE
            UPDATE tbsesionusuario SET activo=0, fechadesconexion=GETDATE() WHERE idpasajero=@idPasajero AND activo=1;
        SELECT 1 AS resultado, 'Sesion cerrada' AS mensaje;
    END TRY
    BEGIN CATCH SELECT -99 AS resultado, ERROR_MESSAGE() AS mensaje; END CATCH
END
GO

CREATE PROCEDURE sp_pasajero_ActualizarPerfil
    @idPasajero BIGINT, @nombre VARCHAR(50)=NULL, @appaterno VARCHAR(50)=NULL, @apmaterno VARCHAR(50)=NULL,
    @fotoperfil VARCHAR(MAX)=NULL, @idiomapreferido SMALLINT=NULL, @fechanacimiento DATE=NULL,
    @genero CHAR(1)=NULL, @notasadicionales VARCHAR(500)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM tbpasajero WHERE id=@idPasajero AND activo=1)
        BEGIN SELECT -1 AS resultado, 'Pasajero no encontrado' AS mensaje; RETURN; END
    UPDATE tbpasajero SET nombre=ISNULL(@nombre,nombre),appaterno=ISNULL(@appaterno,appaterno),apmaterno=ISNULL(@apmaterno,apmaterno),
        fotoperfil=ISNULL(@fotoperfil,fotoperfil),idiomapreferido=ISNULL(@idiomapreferido,idiomapreferido),fechanacimiento=ISNULL(@fechanacimiento,fechanacimiento),
        genero=ISNULL(@genero,genero),notasadicionales=ISNULL(@notasadicionales,notasadicionales),ultimaactualizacion=GETDATE() WHERE id=@idPasajero;
    SELECT 1 AS resultado, 'Perfil actualizado' AS mensaje;
END
GO

CREATE PROCEDURE sp_pasajero_ObtenerPerfil @idPasajero BIGINT AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.*, mp.metodopago, i.idioma, c.companianombre,
           (SELECT COUNT(*) FROM tbfavoritos WHERE idpasajero=p.id AND activo=1) AS totalfavoritos
    FROM tbpasajero p LEFT JOIN tbmetodopago mp ON mp.id=p.metodopagopreferido
    LEFT JOIN tbidioma i ON i.id=p.idiomapreferido LEFT JOIN tbcompania c ON c.id=p.idcompania WHERE p.id=@idPasajero;
END
GO

CREATE PROCEDURE sp_pasajero_CambiarPassword @idPasajero BIGINT, @passActual VARCHAR(8000), @passNuevo VARCHAR(8000) AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM tbpasajero WHERE id=@idPasajero AND pass=@passActual AND activo=1)
        BEGIN SELECT -1 AS resultado, 'Contrasena actual incorrecta' AS mensaje; RETURN; END
    UPDATE tbpasajero SET pass=@passNuevo, ultimaactualizacion=GETDATE() WHERE id=@idPasajero;
    SELECT 1 AS resultado, 'Contrasena actualizada' AS mensaje;
END
GO

CREATE PROCEDURE sp_pasajero_EnviarCodigoVerificacion @codigopaistel VARCHAR(15)=NULL, @telefono VARCHAR(30)=NULL, @idPasajero BIGINT=NULL AS
BEGIN
    SET NOCOUNT ON;
    IF @idPasajero IS NOT NULL AND (@codigopaistel IS NULL OR @telefono IS NULL)
    BEGIN
        SELECT @codigopaistel=codigopaistel, @telefono=telefono FROM tbpasajero WHERE id=@idPasajero;
    END
    IF @codigopaistel IS NULL OR @telefono IS NULL
    BEGIN SELECT -1 AS resultado, 'Faltan datos' AS mensaje; RETURN; END
    DECLARE @codigo VARCHAR(50)=CAST(CAST(100000+RAND()*899999 AS INT) AS VARCHAR(6));
    DECLARE @limite DATETIME=DATEADD(MINUTE,10,GETDATE());
    UPDATE tbpasajerocodigos SET activo=0 WHERE codigopaistel=@codigopaistel AND notelefono=@telefono;
    INSERT INTO tbpasajerocodigos(codigopaistel,notelefono,codigoverificacion,fechalimiteexpira) VALUES(@codigopaistel,@telefono,@codigo,@limite);
    SELECT 1 AS resultado, 'Codigo enviado' AS mensaje, @codigo AS codigoverificacion;
END
GO

CREATE PROCEDURE sp_pasajero_CambiarTelefono @idPasajero BIGINT, @codigopaistel VARCHAR(15), @telefonoNuevo VARCHAR(30), @codigoVerificacion VARCHAR(50) AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM tbpasajero WHERE telefono=@telefonoNuevo AND id<>@idPasajero AND activo=1)
        BEGIN SELECT -1 AS resultado, 'Telefono ya en uso' AS mensaje; RETURN; END
    IF NOT EXISTS(SELECT 1 FROM tbpasajerocodigos WHERE notelefono=@telefonoNuevo AND codigoverificacion=@codigoVerificacion AND activo=1 AND fechalimiteexpira>=GETDATE())
        BEGIN SELECT -2 AS resultado, 'Codigo invalido o expirado' AS mensaje; RETURN; END
    DECLARE @telAnt VARCHAR(30); SELECT @telAnt=telefono FROM tbpasajero WHERE id=@idPasajero;
    INSERT INTO tbpasajerohistorialcambiotelefono(idpasajero,codigopaistel,telefonodadodebaja) VALUES(@idPasajero,@codigopaistel,@telAnt);
    UPDATE tbpasajero SET telefono=@telefonoNuevo, telefonoconfirmado=1, ultimaactualizacion=GETDATE() WHERE id=@idPasajero;
    UPDATE tbpasajerocodigos SET activo=0 WHERE notelefono=@telefonoNuevo;
    SELECT 1 AS resultado, 'Telefono actualizado' AS mensaje;
END
GO

CREATE PROCEDURE sp_pasajero_ValidarCodigoPromocional @codigo VARCHAR(100), @idPasajero BIGINT, @montoViaje DECIMAL(18,2)=0 AS
BEGIN SET NOCOUNT ON; SELECT * FROM dbo.fn_ValidarCodigoPromocional(@codigo,@idPasajero,@montoViaje); END
GO

CREATE PROCEDURE sp_pasajero_SolicitarServicio
    @idPasajero BIGINT, @idCompania SMALLINT, @dirOrigen VARCHAR(300), @latOrigen VARCHAR(50), @lngOrigen VARCHAR(50),
    @dirDestino VARCHAR(300), @latDestino VARCHAR(50), @lngDestino VARCHAR(50), @distanciaMetros INT,
    @idTipoPago SMALLINT, @codigoPromocional VARCHAR(100)=NULL, @so VARCHAR(100)=NULL, @tipoviaje VARCHAR(50)='URBANO'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @costo DECIMAL(18,2), @idCodPromo INT, @desc DECIMAL(18,2)=0, @dur INT=@distanciaMetros/250*60;
        DECLARE @idZona INT, @kms INT, @numUnid INT;
        SELECT @kms=kmsalaredondamascercanos,@numUnid=nounidadesmascercanas FROM tbcompania WHERE id=@idCompania;
        SELECT @idZona=id FROM tbzonacobertura WHERE activo=1 AND dbo.fn_CalcularDistancia(CAST(@latOrigen AS DECIMAL(18,10)),CAST(@lngOrigen AS DECIMAL(18,10)),CAST(ISNULL(latitudcentro,'0') AS DECIMAL(18,10)),CAST(ISNULL(longitudcentro,'0') AS DECIMAL(18,10))) <= radio_km;
        IF @codigoPromocional IS NOT NULL BEGIN
            DECLARE @pr TABLE(v BIT,m VARCHAR(500),md DECIMAL(18,2),ep BIT,ic INT);
            INSERT INTO @pr EXEC sp_pasajero_ValidarCodigoPromocional @codigoPromocional,@idPasajero,@costo;
            SELECT @idCodPromo=ic,@desc=md FROM @pr WHERE v=1;
        END
        SET @costo = dbo.fn_CalcularCostoViaje(@idCompania,@distanciaMetros,@dur,GETDATE())-@desc;
        IF @costo<0 SET @costo=0;
        INSERT INTO tbservicios(idconductor,idpasajero,idservicioestatus,direccionorigen,latorigen,lngorigen,direcciondestination,latdestination,lngdestination,costoestimado,distanciametros,idtipopago,idcodigopromo,montodescuento,so,tipoviaje,durationsegundos)
        VALUES(NULL,@idPasajero,(SELECT id FROM tbservicioestatus WHERE estatus='Solicitado' AND activo=1),@dirOrigen,@latOrigen,@lngOrigen,@dirDestino,@latDestino,@lngDestino,@costo,@distanciaMetros,@idTipoPago,@idCodPromo,@desc,@so,@tipoviaje,@dur);
        DECLARE @idServ BIGINT=SCOPE_IDENTITY();
        INSERT INTO tbhistoriallatlngconsultadapasajero(idpasajero,lat,lng) VALUES(@idPasajero,@latOrigen,@lngOrigen);
        IF @idCodPromo IS NOT NULL BEGIN
            UPDATE tbcodigospromo SET usosactuales=usosactuales+1 WHERE id=@idCodPromo;
            INSERT INTO tbcodigospromousados(idpasajero,idcodigopromo,idservicio) VALUES(@idPasajero,@idCodPromo,@idServ);
        END
        SELECT @idServ AS idservicio, @costo AS costoestimado, @distanciaMetros AS distanciametros, @dur AS duracionsegundos, @desc AS montodescuento, 'Servicio solicitado' AS mensaje;
    END TRY
    BEGIN CATCH SELECT -99 AS idservicio, ERROR_MESSAGE() AS mensaje; END CATCH
END
GO

CREATE PROCEDURE sp_pasajero_ConductoresDisponibles @lat VARCHAR(50), @lng VARCHAR(50), @idZona INT=NULL AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @radio INT; SELECT @radio=kmsalaredondamascercanos FROM tbcompania WHERE activo=1;
    SELECT * FROM dbo.fn_ConductoresCercanos(@lat,@lng,@radio,20,@idZona) ORDER BY distancia_km;
END
GO

CREATE PROCEDURE sp_pasajero_ObtenerEstadoServicio @idServicio BIGINT, @idPasajero BIGINT AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.id,s.idservicioestatus,se.estatus,se.estatusdescription,s.direccionorigen,s.latorigen,s.lngorigen,s.direcciondestination,s.latdestination,s.lngdestination,
           s.costoestimado,s.distanciametros,s.durationsegundos,s.montodescuento,s.servicioiniciado,s.llegoalorigen,s.llegoasudestino,s.fechacreacion,s.fechaservicioiniciado,
           s.fechallegoalorigen,s.fechallegoasudestino,s.alarmasospasajero,s.alarmasosconductor,s.sesalioderuta,s.motivocancelacion,s.canceladopor,s.fechacancelacion,
           s.calificacion,s.idconductor,c.nombre AS conductor_nombre,c.appaterno AS conductor_appaterno,c.fotoperfil AS conductor_foto,c.telefono AS conductor_telefono,u.unidad,u.colorhex,u.colornombre,u.numeroasientos,u.placas,sm.nombresubmarca,m.nombremarca,g.lat AS conductor_lat,g.lng AS conductor_lng
    FROM tbservicios s INNER JOIN tbservicioestatus se ON se.id=s.idservicioestatus
    LEFT JOIN tbconductor c ON c.id=s.idconductor LEFT JOIN tbconductorunidades cu ON cu.idconductor=c.id AND cu.enuso=1
    LEFT JOIN tbunidad u ON u.id=cu.idunidad LEFT JOIN tbsubmarca sm ON sm.id=u.idsubmarca
    LEFT JOIN tbmarca m ON m.id=sm.idmarca LEFT JOIN tbconductorgps g ON g.idconductor=c.id
    WHERE s.id=@idServicio AND s.idpasajero=@idPasajero;
END
GO

CREATE PROCEDURE sp_pasajero_CancelarServicio @idServicio BIGINT, @idPasajero BIGINT, @motivo VARCHAR(MAX)=NULL AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sol SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='Solicitado' AND activo=1);
    IF NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idServicio AND idpasajero=@idPasajero AND idservicioestatus=@sol)
        BEGIN SELECT -1 AS resultado, 'El servicio no puede cancelarse' AS mensaje; RETURN; END
    DECLARE @can SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='Cancelado por Pasajero' AND activo=1);
    UPDATE tbservicios SET idservicioestatus=@can, motivocancelacion=@motivo, canceladopor='pasajero', fechacancelacion=GETDATE(), ultimaactualizacion=GETDATE() WHERE id=@idServicio;
    SELECT 1 AS resultado, 'Servicio cancelado' AS mensaje;
END
GO

CREATE PROCEDURE sp_pasajero_CalificarViaje @idServicio BIGINT, @idPasajero BIGINT, @calificacion TINYINT, @comentarios VARCHAR(500)=NULL AS
BEGIN
    SET NOCOUNT ON;
    IF @calificacion<1 OR @calificacion>5 BEGIN SELECT -1 AS resultado, 'Rango 1-5' AS mensaje; RETURN; END
    DECLARE @fin SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='Finalizado' AND activo=1);
    IF NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idServicio AND idpasajero=@idPasajero AND idservicioestatus=@fin)
        BEGIN SELECT -2 AS resultado, 'Servicio no finalizado' AS mensaje; RETURN; END
    UPDATE tbservicios SET calificacion=@calificacion, comentarios=@comentarios, ultimaactualizacion=GETDATE() WHERE id=@idServicio;
    DECLARE @idCond INT; SELECT @idCond=idconductor FROM tbservicios WHERE id=@idServicio;
    
    SELECT 1 AS resultado, 'Calificacion registrada' AS mensaje;
END
GO

CREATE PROCEDURE sp_pasajero_ActivarAlarmaSOS @idServicio BIGINT, @idPasajero BIGINT AS
BEGIN
    UPDATE tbservicios SET alarmasospasajero=1, fechaalarmasospasajero=GETDATE(), ultimaactualizacion=GETDATE() WHERE id=@idServicio AND idpasajero=@idPasajero;
    SELECT 1 AS resultado, 'Alarma SOS activada' AS mensaje;
END
GO

CREATE PROCEDURE sp_pasajero_IniciarServicio @idServicio BIGINT, @idPasajero BIGINT, @codigoInicio VARCHAR(10)=NULL AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @enCamino SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='En Camino' AND activo=1);
    IF NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idServicio AND idpasajero=@idPasajero)
        BEGIN SELECT -1 AS resultado, 'Servicio no encontrado' AS mensaje; RETURN; END
    IF EXISTS(SELECT 1 FROM tbservicios WHERE id=@idServicio AND idservicioestatus<>@enCamino)
        BEGIN SELECT -2 AS resultado, 'El servicio aun no esta en camino' AS mensaje; RETURN; END
    DECLARE @enViaje SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='En Viaje' AND activo=1);
    UPDATE tbservicios SET idservicioestatus=@enViaje, servicioiniciado=1, fechaservicioiniciado=GETDATE(), ultimaactualizacion=GETDATE() WHERE id=@idServicio;
    SELECT 1 AS resultado, 'Servicio iniciado' AS mensaje, @idServicio AS idservicio, @enViaje AS idservicioestatus;
END
GO

CREATE PROCEDURE sp_pasajero_AgregarFavorito @idPasajero BIGINT, @nombre VARCHAR(50), @dir VARCHAR(350)=NULL, @lat VARCHAR(50), @lng VARCHAR(50) AS
BEGIN
    INSERT INTO tbfavoritos(idpasajero,favoritonombre,direccionfavorito,lat,lng) VALUES(@idPasajero,@nombre,@dir,@lat,@lng);
    SELECT SCOPE_IDENTITY() AS id, 'Favorito agregado' AS mensaje;
END
GO

CREATE PROCEDURE sp_pasajero_ListarFavoritos @idPasajero BIGINT AS
BEGIN
    SET NOCOUNT ON;
    SELECT id,favoritonombre,direccionfavorito,lat,lng,fechacreacion FROM tbfavoritos WHERE idpasajero=@idPasajero AND activo=1 ORDER BY fechacreacion DESC;
END
GO

CREATE PROCEDURE sp_pasajero_EliminarFavorito @idFavorito INT, @idPasajero BIGINT AS
BEGIN
    UPDATE tbfavoritos SET activo=0 WHERE id=@idFavorito AND idpasajero=@idPasajero;
    SELECT 1 AS resultado, 'Favorito eliminado' AS mensaje;
END
GO

CREATE PROCEDURE sp_pasajero_HistorialViajes
    @idPasajero BIGINT, @pagina INT=1, @tamano INT=20, @fi DATETIME=NULL, @ff DATETIME=NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @off INT=(@pagina-1)*@tamano;
    SELECT s.id,s.direccionorigen,s.direcciondestination,s.costoestimado,s.distanciametros,s.durationsegundos,s.fechacreacion,s.fechaservicioiniciado,
           s.fechallegoasudestino,s.calificacion,s.calificacionpasajero,se.estatus,c.nombre AS cond_nombre,c.appaterno AS cond_appaterno,c.fotoperfil AS cond_foto,
           u.unidad,sm.nombresubmarca,m.nombremarca,u.colorhex,tp.tipopago,COUNT(*) OVER() AS totalregistros
    FROM tbservicios s INNER JOIN tbservicioestatus se ON se.id=s.idservicioestatus
    LEFT JOIN tbconductor c ON c.id=s.idconductor LEFT JOIN tbunidad u ON u.id=s.idunidad
    LEFT JOIN tbsubmarca sm ON sm.id=u.idsubmarca LEFT JOIN tbmarca m ON m.id=sm.idmarca
    LEFT JOIN tbtipopago tp ON tp.id=s.idtipopago
    WHERE s.idpasajero=@idPasajero AND (@fi IS NULL OR s.fechacreacion>=@fi) AND (@ff IS NULL OR s.fechacreacion<=@ff)
    ORDER BY s.fechacreacion DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

CREATE PROCEDURE sp_pasajero_DetalleViaje @idServicio BIGINT, @idPasajero BIGINT AS
BEGIN
    SET NOCOUNT ON;
    SELECT s.*,se.estatus,se.estatusdescription,c.nombre AS c_nombre,c.appaterno AS c_appaterno,c.apmaterno AS c_apmaterno,c.fotoperfil AS c_foto,
           c.telefono AS c_tel,c.correo AS c_email,
           u.unidad,u.alias,u.colorhex,u.colornombre,u.numeroasientos,u.placas,u.modelo,sm.nombresubmarca,m.nombremarca,tp.tipopago,
           mp.metodopago,cp.codigopromocional,r.polylineruta,r.puntosruta,r.distanciametros AS rd_m,r.duracionsegundos AS rd_s
    FROM tbservicios s INNER JOIN tbservicioestatus se ON se.id=s.idservicioestatus
    LEFT JOIN tbconductor c ON c.id=s.idconductor LEFT JOIN tbunidad u ON u.id=s.idunidad
    LEFT JOIN tbsubmarca sm ON sm.id=u.idsubmarca LEFT JOIN tbmarca m ON m.id=sm.idmarca
    LEFT JOIN tbtipopago tp ON tp.id=s.idtipopago
    LEFT JOIN tbmetodopago mp ON mp.id=(SELECT idmetodopago FROM tbpago WHERE idservicio=s.id)
    LEFT JOIN tbcodigospromo cp ON cp.id=s.idcodigopromo LEFT JOIN tbrutaasignada r ON r.idservicio=s.id
    WHERE s.id=@idServicio AND s.idpasajero=@idPasajero;
END
GO

CREATE PROCEDURE sp_pasajero_ReportarIncidente @idServicio BIGINT, @idPasajero BIGINT, @idTipo INT, @desc VARCHAR(MAX), @so VARCHAR(100)=NULL AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idServicio AND idpasajero=@idPasajero)
        BEGIN SELECT -1 AS resultado, 'Servicio no pertenece al pasajero' AS mensaje; RETURN; END
    DECLARE @idStat INT=(SELECT id FROM tbestatusincidente WHERE nombreestatus='Reportado' AND activo=1);
    INSERT INTO tbincidentes(idservicio,idtipoincidente,idestatusincidente,descripcionincidente,so) VALUES(@idServicio,@idTipo,@idStat,@desc,@so);
    INSERT INTO tbincidenteshistorialestatus(idservicioincidente,idestatusincidente,comentarios) VALUES(SCOPE_IDENTITY(),@idStat,'Reportado por pasajero');
    SELECT SCOPE_IDENTITY() AS id, 'Incidente reportado' AS mensaje;
END
GO

CREATE PROCEDURE sp_pasajero_ObtenerConfiguracionCostos @idCompania SMALLINT AS
BEGIN
    SET NOCOUNT ON;
    SELECT costominimo,costoporkm,costoporminuto,numdiasemana,horainicio,horafin
    FROM tbappviajecostos WHERE idcompania=@idCompania AND numdiasemana=DATEPART(WEEKDAY,GETDATE()) ORDER BY horainicio;
END
GO

CREATE PROCEDURE sp_pasajero_ObtenerAvisos @idCompania SMALLINT AS
BEGIN
    SET NOCOUNT ON;
    SELECT id,tituloaviso,descripcionaviso,fechacreacion FROM tbavisosapp WHERE idcompania=@idCompania AND esavisopasajero=1 AND activo=1 ORDER BY fechacreacion DESC;
END
GO

CREATE PROCEDURE sp_pasajero_ObtenerPromociones AS
BEGIN
    SET NOCOUNT ON;
    SELECT id,titulopublicidad,imgbase64,iniciovigenciapromocion,finvigenciapromocion FROM tbpromociones WHERE activo=1 AND GETDATE() BETWEEN iniciovigenciapromocion AND finvigenciapromocion ORDER BY fechacreacion DESC;
END
GO

CREATE PROCEDURE sp_pasajero_ObtenerPropagandas AS
BEGIN
    SET NOCOUNT ON;
    SELECT id,titulopropaganda,imgbase64 FROM tbpropagandas WHERE activo=1 ORDER BY fechacreacion DESC;
END
GO

CREATE PROCEDURE sp_pasajero_EnviarMensajeChat @idServicio BIGINT, @idPasajero BIGINT, @mensaje VARCHAR(150) AS
BEGIN
    INSERT INTO tbserviciosmensaje(idservicio,idconductor,idpasajero,desdeapppasajero,mensaje)
    SELECT @idServicio,s.idconductor,@idPasajero,1,@mensaje FROM tbservicios s WHERE s.id=@idServicio AND s.idpasajero=@idPasajero;
    SELECT SCOPE_IDENTITY() AS id, 'Mensaje enviado' AS mensaje;
END
GO

CREATE PROCEDURE sp_pasajero_ObtenerMensajesChat @idServicio BIGINT, @idPasajero BIGINT AS
BEGIN
    SET NOCOUNT ON;
    SELECT m.id,m.mensaje,m.desdeapppasajero,m.desdeappconductor,m.fechacreacion
    FROM tbserviciosmensaje m INNER JOIN tbservicios s ON s.id=m.idservicio
    WHERE m.idservicio=@idServicio AND s.idpasajero=@idPasajero ORDER BY m.fechacreacion ASC;
END
GO

/* ============================================
   SECCION: PROCEDIMIENTOS APP CONDUCTOR
   ============================================ */

CREATE PROCEDURE sp_conductor_Registrar
    @idCompania SMALLINT, @idZonaCobertura INT=NULL, @nombre VARCHAR(50), @appaterno VARCHAR(50), @apmaterno VARCHAR(50),
    @sexo CHAR(1), @correo VARCHAR(100), @telefono VARCHAR(30), @googlekey VARCHAR(MAX),
    @account VARCHAR(50), @pass VARCHAR(8000), @curp VARCHAR(50)=NULL, @rfc VARCHAR(50)=NULL,
    @licencia VARCHAR(50)=NULL, @idioma SMALLINT=NULL, @fechaNac DATE=NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM tbconductor WHERE account=@account AND activo=1) BEGIN SELECT -1 AS id, 'Cuenta ya existe' AS mensaje; RETURN; END
    IF EXISTS(SELECT 1 FROM tbconductor WHERE correo=@correo AND activo=1) BEGIN SELECT -2 AS id, 'Correo ya registrado' AS mensaje; RETURN; END
    IF EXISTS(SELECT 1 FROM tbconductor WHERE telefono=@telefono AND activo=1) BEGIN SELECT -3 AS id, 'Telefono ya registrado' AS mensaje; RETURN; END
    DECLARE @idEstVal SMALLINT=(SELECT id FROM tbconductorestatus WHERE conductorestatus='En Validacion');
    DECLARE @idEstDocs INT=(SELECT id FROM tbestatusdocumentacion WHERE nombreestatusdocs='Pendiente');
    INSERT INTO tbconductor(idcompania,idzonacobertura,nombre,appaterno,apmaterno,idconductorestatus,sexo,correo,telefono,googlekey,account,pass,idestatusdocumentacion,documentacionaprobada,curp,rfc,licenciaconducir,idiomapreferido,fechanacimiento,conectado,ultimaconexionusr)
    VALUES(@idCompania,@idZonaCobertura,@nombre,@appaterno,@apmaterno,@idEstVal,@sexo,@correo,@telefono,@googlekey,@account,@pass,@idEstDocs,0,@curp,@rfc,@licencia,@idioma,@fechaNac,1,GETDATE());
    DECLARE @nuevoId INT=SCOPE_IDENTITY();
    INSERT INTO tbconductorgps(idconductor,lat,lng,lastposition,previouslat,previouslng) VALUES(@nuevoId,'','',GETDATE(),'','');
    INSERT INTO tbhistorialconexionesconductor(idconductor,conectado) VALUES(@nuevoId,1);
    SELECT @nuevoId AS id, 'Registro exitoso. Complete su documentacion.' AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_IniciarSesion
    @account VARCHAR(50), @pass VARCHAR(8000), @googlekey VARCHAR(MAX)=NULL, @googlekeyso VARCHAR(100)=NULL,
    @dispositivoinfo VARCHAR(500)=NULL, @sistemaoperativo VARCHAR(100)=NULL, @ipaddress VARCHAR(50)=NULL,
    @useragent VARCHAR(500)=NULL, @esLoginGoogle BIT=0, @googleuserid VARCHAR(255)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @idConductor INT;
    IF @esLoginGoogle=1 AND @googleuserid IS NOT NULL
        SELECT @idConductor=id FROM tbconductor WHERE googleuserid=@googleuserid AND activo=1 AND bloqueado=0;
    ELSE
        SELECT @idConductor=id FROM tbconductor WHERE (account=@account OR correo=@account) AND pass=@pass AND activo=1 AND bloqueado=0;
    IF @idConductor IS NULL BEGIN SELECT -1 AS id, 'Credenciales invalidas' AS mensaje; RETURN; END
    UPDATE tbconductor SET conectado=1,ultimaconexionusr=GETDATE(),googlekey=ISNULL(@googlekey,googlekey),googlekeyso=ISNULL(@googlekeyso,googlekeyso) WHERE id=@idConductor;
    INSERT INTO tbhistorialconexionesconductor(idconductor,conectado) VALUES(@idConductor,1);
    DECLARE @uuidsesion VARCHAR(1500)=NEWID();
    INSERT INTO tbsesionusuario(idtipousuario,idconductor,uuidsesion,fechaconexion,activo,dispositivoinfo,sistemaoperativo,ipaddress,useragent)
    VALUES(2,@idConductor,@uuidsesion,GETDATE(),1,@dispositivoinfo,@sistemaoperativo,@ipaddress,@useragent);
    SELECT c.id,c.idcompania,c.idzonacobertura,c.nombre,c.appaterno,c.apmaterno,c.sexo,c.correo,c.telefono,c.telefonoconfirmado,c.fotoperfil,c.account,
           c.idconductorestatus,ce.conductorestatus,c.documentacionaprobada,c.idestatusdocumentacion,ed.nombreestatusdocs,c.bloqueado,c.curp,c.rfc,c.licenciaconducir,
           c.fechavencimientolicencia,c.eslogueadocongoogle,c.googleuserid,c.fotourlgoogle,c.idiomapreferido,c.banco,c.nombretitular,c.clabeinterbancaria,
           zc.nombrezona,i.idioma,@uuidsesion AS uuidsesion,'Inicio exitoso' AS mensaje
    FROM tbconductor c INNER JOIN tbconductorestatus ce ON ce.id=c.idconductorestatus
    LEFT JOIN tbestatusdocumentacion ed ON ed.id=c.idestatusdocumentacion
    LEFT JOIN tbzonacobertura zc ON zc.id=c.idzonacobertura LEFT JOIN tbidioma i ON i.id=c.idiomapreferido WHERE c.id=@idConductor;
END
GO

CREATE PROCEDURE sp_conductor_CerrarSesion @idConductor INT, @uuidsesion VARCHAR(1500)=NULL AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tbconductor SET conectado=0,ultimadesconexionusr=GETDATE() WHERE id=@idConductor;
    DECLARE @desc SMALLINT=(SELECT id FROM tbconductorestatus WHERE conductorestatus='Desconectado');
    UPDATE tbconductor SET idconductorestatus=@desc WHERE id=@idConductor;
    INSERT INTO tbhistorialconexionesconductor(idconductor,conectado) VALUES(@idConductor,0);
    IF @uuidsesion IS NOT NULL UPDATE tbsesionusuario SET activo=0,fechadesconexion=GETDATE() WHERE uuidsesion=@uuidsesion AND idconductor=@idConductor;
    ELSE UPDATE tbsesionusuario SET activo=0,fechadesconexion=GETDATE() WHERE idconductor=@idConductor AND activo=1;
    SELECT 1 AS resultado, 'Sesion cerrada' AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_ActualizarPerfil
    @idConductor INT, @nombre VARCHAR(50)=NULL, @appaterno VARCHAR(50)=NULL, @apmaterno VARCHAR(50)=NULL,
    @fotoperfil VARCHAR(MAX)=NULL, @sexo CHAR(1)=NULL, @correo VARCHAR(100)=NULL, @idioma SMALLINT=NULL,
    @fechaNac DATE=NULL, @licencia VARCHAR(50)=NULL, @fecVenLic DATETIME=NULL, @tipoLic VARCHAR(20)=NULL,
    @notas VARCHAR(500)=NULL, @banco VARCHAR(100)=NULL, @titular VARCHAR(150)=NULL, @clabe VARCHAR(150)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tbconductor SET nombre=ISNULL(@nombre,nombre),appaterno=ISNULL(@appaterno,appaterno),apmaterno=ISNULL(@apmaterno,apmaterno),
        fotoperfil=ISNULL(@fotoperfil,fotoperfil),sexo=ISNULL(@sexo,sexo),correo=ISNULL(@correo,correo),idiomapreferido=ISNULL(@idioma,idiomapreferido),
        fechanacimiento=ISNULL(@fechaNac,fechanacimiento),licenciaconducir=ISNULL(@licencia,licenciaconducir),fechavencimientolicencia=ISNULL(@fecVenLic,fechavencimientolicencia),
        tipolicencia=ISNULL(@tipoLic,tipolicencia),notasadicionales=ISNULL(@notas,notasadicionales),banco=ISNULL(@banco,banco),nombretitular=ISNULL(@titular,nombretitular),
        clabeinterbancaria=ISNULL(@clabe,clabeinterbancaria),ultimaactualizacion=GETDATE() WHERE id=@idConductor;
    SELECT 1 AS resultado, 'Perfil actualizado' AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_ActualizarUbicacionGPS @idConductor INT, @lat VARCHAR(50), @lng VARCHAR(50) AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @pl VARCHAR(50),@pn VARCHAR(50); SELECT @pl=lat,@pn=lng FROM tbconductorgps WHERE idconductor=@idConductor;
    UPDATE tbconductorgps SET previouslat=ISNULL(@pl,@lat),previouslng=ISNULL(@pn,@lng),lat=@lat,lng=@lng,lastposition=GETDATE(),ultimaactualizacion=GETDATE() WHERE idconductor=@idConductor;
    INSERT INTO tbconductorgpshistory(idconductor,lat,lng,idconductorestatus) SELECT @idConductor,@lat,@lng,idconductorestatus FROM tbconductor WHERE id=@idConductor;
    SELECT 1 AS resultado, 'Ubicacion actualizada' AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_CambiarEstatus @idConductor INT, @estatus VARCHAR(50) AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @idEst SMALLINT=(SELECT id FROM tbconductorestatus WHERE conductorestatus=@estatus AND activo=1);
    IF @idEst IS NULL BEGIN SELECT -1 AS resultado, 'Estatus no valido' AS mensaje; RETURN; END
    UPDATE tbconductor SET idconductorestatus=@idEst,ultimaactualizacion=GETDATE() WHERE id=@idConductor;
    SELECT 1 AS resultado, CONCAT('Estatus: ',@estatus) AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_AceptarServicio @idServicio BIGINT, @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sol SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='Solicitado' AND activo=1);
    IF NOT EXISTS(SELECT 1 FROM tbservicios WHERE id=@idServicio AND idservicioestatus=@sol)
        BEGIN SELECT -1 AS resultado, 'Servicio no disponible' AS mensaje; RETURN; END
    DECLARE @cam SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='En Camino' AND activo=1);
    DECLARE @ocup SMALLINT=(SELECT id FROM tbconductorestatus WHERE conductorestatus='Ocupado');
    UPDATE tbservicios SET idconductor=@idConductor,idservicioestatus=@cam,idunidad=(SELECT idunidad FROM tbconductorunidades WHERE idconductor=@idConductor AND enuso=1),ultimaactualizacion=GETDATE() WHERE id=@idServicio;
    UPDATE tbconductor SET idconductorestatus=@ocup WHERE id=@idConductor;
    DELETE FROM tbserviciosconductoresnotificados WHERE idservicio=@idServicio;
    SELECT 1 AS resultado,'Servicio aceptado, dirigete al origen' AS mensaje,s.direccionorigen,s.latorigen,s.lngorigen,s.direcciondestination,s.latdestination,s.lngdestination,s.distanciametros,s.costoestimado,s.tipoviaje,p.nombre AS pas_nombre,p.fotoperfil AS pas_foto,p.telefono AS pas_tel
    FROM tbservicios s INNER JOIN tbpasajero p ON p.id=s.idpasajero WHERE s.id=@idServicio;
END
GO

CREATE PROCEDURE sp_conductor_LlegarAlOrigen @idServicio BIGINT, @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @cam SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='En Camino' AND activo=1);
    DECLARE @llego SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='Llego al Origen' AND activo=1);
    UPDATE tbservicios SET idservicioestatus=@llego,llegoalorigen=1,fechallegoalorigen=GETDATE(),ultimaactualizacion=GETDATE() WHERE id=@idServicio AND idconductor=@idConductor AND idservicioestatus=@cam;
    SELECT 1 AS resultado,'Llegaste al punto de recogida' AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_IniciarViaje @idServicio BIGINT, @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @llego SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='Llego al Origen' AND activo=1);
    DECLARE @viaje SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='En Viaje' AND activo=1);
    UPDATE tbservicios SET idservicioestatus=@viaje,servicioiniciado=1,fechaservicioiniciado=GETDATE(),ultimaactualizacion=GETDATE() WHERE id=@idServicio AND idconductor=@idConductor AND idservicioestatus=@llego;
    SELECT 1 AS resultado,'Viaje iniciado' AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_FinalizarViaje
    @idServicio BIGINT, @idConductor INT, @distReal INT=NULL, @durReal INT=NULL, @poly VARCHAR(MAX)=NULL, @puntos VARCHAR(MAX)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @viaje SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='En Viaje' AND activo=1);
    DECLARE @fin SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='Finalizado' AND activo=1);
    DECLARE @disp SMALLINT=(SELECT id FROM tbconductorestatus WHERE conductorestatus='Disponible');
    UPDATE tbservicios SET idservicioestatus=@fin,llegoasudestino=1,fechallegoasudestino=GETDATE(),distanciametros=ISNULL(@distReal,distanciametros),durationsegundos=ISNULL(@durReal,durationsegundos),ultimaactualizacion=GETDATE(),fechafinalizoconductor=GETDATE() WHERE id=@idServicio AND idconductor=@idConductor AND idservicioestatus=@viaje;
    UPDATE tbconductor SET idconductorestatus=@disp WHERE id=@idConductor;
    IF @poly IS NOT NULL OR @puntos IS NOT NULL BEGIN
        IF EXISTS(SELECT 1 FROM tbrutaasignada WHERE idservicio=@idServicio)
            UPDATE tbrutaasignada SET polylineruta=ISNULL(@poly,polylineruta),puntosruta=ISNULL(@puntos,puntosruta),distanciametros=ISNULL(@distReal,distanciametros),duracionsegundos=ISNULL(@durReal,duracionsegundos),ultimaactualizacion=GETDATE() WHERE idservicio=@idServicio;
        ELSE
            INSERT INTO tbrutaasignada(idservicio,polylineruta,puntosruta,distanciametros,duracionsegundos) VALUES(@idServicio,@poly,@puntos,@distReal,@durReal);
    END
    SELECT 1 AS resultado,'Viaje finalizado' AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_CalificarPasajero @idServicio BIGINT, @idConductor INT, @calif TINYINT, @coment VARCHAR(150)=NULL AS
BEGIN
    IF @calif<1 OR @calif>5 BEGIN SELECT -1 AS resultado,'Rango 1-5' AS mensaje; RETURN; END
    UPDATE tbservicios SET calificacionpasajero=@calif,comentariocalificacionpasajero=@coment,ultimaactualizacion=GETDATE() WHERE id=@idServicio AND idconductor=@idConductor;
    SELECT 1 AS resultado,'Calificacion registrada' AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_ActivarAlarmaSOS @idServicio BIGINT, @idConductor INT AS
BEGIN
    UPDATE tbservicios SET alarmasosconductor=1,fechaalarmasosconductor=GETDATE(),ultimaactualizacion=GETDATE() WHERE id=@idServicio AND idconductor=@idConductor;
    SELECT 1 AS resultado,'Alarma SOS activada' AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_ListarUnidades @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    SELECT cu.*,u.unidad,u.alias,u.modelo,u.aniofabricacion,u.colorhex,u.colornombre,u.numeroasientos,u.capacidadmaxima,u.placas,u.noserie,u.segurovigente,u.fechavigenciaseguro,sm.nombresubmarca,m.nombremarca,tc.nombretipocombustible,t.nombretransmision
    FROM tbconductorunidades cu INNER JOIN tbunidad u ON u.id=cu.idunidad
    LEFT JOIN tbsubmarca sm ON sm.id=u.idsubmarca LEFT JOIN tbmarca m ON m.id=sm.idmarca
    LEFT JOIN tbtipocombustible tc ON tc.id=u.idtipocombustible LEFT JOIN tbtransmision t ON t.id=u.idtransmision
    WHERE cu.idconductor=@idConductor AND u.activo=1;
END
GO

CREATE PROCEDURE sp_conductor_AgregarUnidad
    @idConductor INT, @unidad VARCHAR(50), @alias VARCHAR(50)=NULL, @modelo INT, @anio INT=NULL,
    @colorhex VARCHAR(30), @colornombre VARCHAR(50), @asientos TINYINT, @capMax TINYINT=NULL,
    @idCombustible INT=NULL, @idTransmision INT=NULL, @idSubmarca INT=NULL, @placas VARCHAR(100)=NULL, @serie VARCHAR(100)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM tbconductorunidades cu INNER JOIN tbunidad u ON u.id=cu.idunidad WHERE cu.idconductor=@idConductor AND u.placas=@placas AND u.activo=1)
        BEGIN SELECT -1 AS resultado,'Placas ya registradas' AS mensaje; RETURN; END
    INSERT INTO tbunidad(unidad,alias,modelo,aniofabricacion,colorhex,colornombre,numeroasientos,capacidadmaxima,idtipocombustible,idtransmision,idsubmarca,placas,noserie)
    VALUES(@unidad,@alias,@modelo,@anio,@colorhex,@colornombre,@asientos,@capMax,@idCombustible,@idTransmision,@idSubmarca,@placas,@serie);
    DECLARE @idUnidad INT=SCOPE_IDENTITY();
    INSERT INTO tbconductorunidades(idconductor,idunidad,aprobada,enuso) VALUES(@idConductor,@idUnidad,0,0);
    SELECT @idUnidad AS id,'Unidad registrada, pendiente de aprobacion' AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_SeleccionarUnidad @idConductor INT, @idUnidad INT AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS(SELECT 1 FROM tbconductorunidades WHERE idconductor=@idConductor AND idunidad=@idUnidad AND aprobada=1)
        BEGIN SELECT -1 AS resultado,'Unidad no aprobada' AS mensaje; RETURN; END
    UPDATE tbconductorunidades SET enuso=0 WHERE idconductor=@idConductor;
    UPDATE tbconductorunidades SET enuso=1 WHERE idconductor=@idConductor AND idunidad=@idUnidad;
    SELECT 1 AS resultado,'Unidad seleccionada' AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_HistorialViajes @idConductor INT, @pagina INT=1, @tamano INT=20, @fi DATETIME=NULL, @ff DATETIME=NULL AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @off INT=(@pagina-1)*@tamano;
    SELECT s.id,s.direccionorigen,s.direcciondestination,s.costoestimado,s.gananciaconductor,s.comisionaplicada,s.distanciametros,s.durationsegundos,s.fechacreacion,s.fechaservicioiniciado,s.fechallegoasudestino,s.calificacion,s.calificacionpasajero,se.estatus,p.nombre AS p_nombre,p.appaterno AS p_appaterno,p.fotoperfil AS p_foto,u.unidad,u.placas,COUNT(*) OVER() AS totalregistros
    FROM tbservicios s INNER JOIN tbservicioestatus se ON se.id=s.idservicioestatus
    LEFT JOIN tbpasajero p ON p.id=s.idpasajero LEFT JOIN tbunidad u ON u.id=s.idunidad
    WHERE s.idconductor=@idConductor AND (@fi IS NULL OR s.fechacreacion>=@fi) AND (@ff IS NULL OR s.fechacreacion<=@ff)
    ORDER BY s.fechacreacion DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

CREATE PROCEDURE sp_conductor_ObtenerCorteSemanal @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ini DATE=DATEADD(DAY,-DATEPART(WEEKDAY,GETDATE())+1,CAST(GETDATE() AS DATE));
    DECLARE @fin DATE=DATEADD(DAY,7-DATEPART(WEEKDAY,GETDATE()),CAST(GETDATE() AS DATE));
    SELECT ISNULL(SUM(s.costoestimado),0) AS ingresos,ISNULL(SUM(s.comisionaplicada),0) AS comision,ISNULL(SUM(s.gananciaconductor),0) AS neto,
           COUNT(CASE WHEN se.estatus='Finalizado' THEN 1 END) AS completados,COUNT(*) AS total
    FROM tbservicios s INNER JOIN tbservicioestatus se ON se.id=s.idservicioestatus
    WHERE s.idconductor=@idConductor AND CAST(s.fechacreacion AS DATE)>=@ini AND CAST(s.fechacreacion AS DATE)<=@fin;
END
GO

CREATE PROCEDURE sp_conductor_EnviarMensajeChat @idServicio BIGINT, @idConductor INT, @mensaje VARCHAR(150) AS
BEGIN
    INSERT INTO tbserviciosmensaje(idservicio,idconductor,idpasajero,desdeappconductor,mensaje)
    SELECT @idServicio,@idConductor,s.idpasajero,1,@mensaje FROM tbservicios s WHERE s.id=@idServicio AND s.idconductor=@idConductor;
    SELECT SCOPE_IDENTITY() AS id,'Mensaje enviado' AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_ObtenerMensajesChat @idServicio BIGINT, @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    SELECT m.id,m.mensaje,m.desdeapppasajero,m.desdeappconductor,m.fechacreacion
    FROM tbserviciosmensaje m INNER JOIN tbservicios s ON s.id=m.idservicio
    WHERE m.idservicio=@idServicio AND s.idconductor=@idConductor ORDER BY m.fechacreacion ASC;
END
GO

CREATE PROCEDURE sp_conductor_ObtenerNotificaciones @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    SELECT idconductor,mensajeenviado,fechacreacion FROM tbhistorialnotificaconductor WHERE idconductor=@idConductor ORDER BY fechacreacion DESC;
END
GO

CREATE PROCEDURE sp_conductor_ReportarIncidente @idServicio BIGINT, @idConductor INT, @idTipo INT, @desc VARCHAR(MAX), @so VARCHAR(100)=NULL AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @idStat INT=(SELECT id FROM tbestatusincidente WHERE nombreestatus='Reportado' AND activo=1);
    INSERT INTO tbincidentes(idservicio,idtipoincidente,idestatusincidente,descripcionincidente,so) VALUES(@idServicio,@idTipo,@idStat,@desc,@so);
    INSERT INTO tbincidenteshistorialestatus(idservicioincidente,idestatusincidente,comentarios) VALUES(SCOPE_IDENTITY(),@idStat,'Reportado por conductor');
    SELECT SCOPE_IDENTITY() AS id,'Incidente reportado' AS mensaje;
END
GO

CREATE PROCEDURE sp_conductor_ObtenerAvisos @idCompania SMALLINT AS
BEGIN
    SET NOCOUNT ON;
    SELECT id,tituloaviso,descripcionaviso,fechacreacion FROM tbavisosapp WHERE idcompania=@idCompania AND esavisoconductor=1 AND activo=1 ORDER BY fechacreacion DESC;
END
GO

CREATE PROCEDURE sp_conductor_ObtenerServicioActivo @idConductor INT AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 s.*,se.estatus,se.estatusdescription,p.nombre AS p_nombre,p.appaterno AS p_appaterno,p.fotoperfil AS p_foto,p.telefono AS p_tel
    FROM tbservicios s INNER JOIN tbservicioestatus se ON se.id=s.idservicioestatus
    INNER JOIN tbpasajero p ON p.id=s.idpasajero
    WHERE s.idconductor=@idConductor AND s.idservicioestatus NOT IN (SELECT id FROM tbservicioestatus WHERE estatus IN ('Finalizado','Cancelado por Pasajero','Cancelado por Conductor','Cancelado por Admin'))
    ORDER BY s.fechacreacion DESC;
END
GO

/* ============================================
   SECCION: PROCEDIMIENTOS WEB ADMIN
   ============================================ */

-- Duplicate removed


/* ============================================
   SECCION: PROCEDIMIENTOS WEB ADMIN
   ============================================ */


CREATE PROCEDURE sp_usuario_IniciarSesion @account VARCHAR(50), @pass VARCHAR(8000), @dispositivoinfo VARCHAR(500)=NULL, @sistemaoperativo VARCHAR(100)=NULL, @ipaddress VARCHAR(50)=NULL, @useragent VARCHAR(500)=NULL AS
BEGIN SET NOCOUNT ON;
DECLARE @idUsuario INT; SELECT @idUsuario=id FROM tbusuario WHERE (account=@account OR correo=@account) AND pass=@pass AND activo=1;
IF @idUsuario IS NULL BEGIN SELECT -1 AS id,'Credenciales invalidas' AS mensaje; RETURN; END
DECLARE @uuidsesion VARCHAR(1500)=NEWID();
INSERT INTO tbsesionusuario(idtipousuario,idusuario,uuidsesion,fechaconexion,activo,dispositivoinfo,sistemaoperativo,ipaddress,useragent) VALUES(3,@idUsuario,@uuidsesion,GETDATE(),1,@dispositivoinfo,@sistemaoperativo,@ipaddress,@useragent);
INSERT INTO tbauditoria(tablaafectada,idregistro,accion,idusuario,ipaddress,useragent) VALUES('tbusuario',CAST(@idUsuario AS VARCHAR),'LOGIN',@idUsuario,@ipaddress,@useragent);
SELECT u.id,u.idcompania,u.nombre,u.appaterno,u.apmaterno,u.sexo,u.correo,u.telefono,u.account,u.fotoperfil,u.esusuariopropietario,u.puedeveratodoconductor,u.idrol,r.rolnombre,c.companianombre,@uuidsesion AS uuidsesion,'Inicio exitoso' AS mensaje FROM tbusuario u INNER JOIN tbrol r ON r.id=u.idrol INNER JOIN tbcompania c ON c.id=u.idcompania WHERE u.id=@idUsuario;
END
GO

CREATE PROCEDURE sp_usuario_Crear @idCreador INT, @idCompania SMALLINT, @nombre VARCHAR(50), @appaterno VARCHAR(50), @apmaterno VARCHAR(50), @sexo CHAR(1), @idRol SMALLINT, @correo VARCHAR(100), @telefono VARCHAR(30), @account VARCHAR(50), @pass VARCHAR(8000), @esProp BIT=0, @puedeVerTodos BIT=0, @zonas VARCHAR(MAX)=NULL AS
BEGIN SET NOCOUNT ON;
IF EXISTS(SELECT 1 FROM tbusuario WHERE account=@account AND activo=1) BEGIN SELECT -1 AS id,'Cuenta ya existe' AS mensaje; RETURN; END
INSERT INTO tbusuario(idcompania,nombre,appaterno,apmaterno,sexo,idrol,correo,telefono,account,pass,esusuariopropietario,puedeveratodoconductor) VALUES(@idCompania,@nombre,@appaterno,@apmaterno,@sexo,@idRol,@correo,@telefono,@account,@pass,@esProp,@puedeVerTodos);
DECLARE @nuevoId INT=SCOPE_IDENTITY();
IF @zonas IS NOT NULL AND @puedeVerTodos=0 INSERT INTO tbusuariozonascobertura(idusuario,idzonacobertura) SELECT @nuevoId,CAST(value AS INT) FROM STRING_SPLIT(@zonas,',') WHERE TRY_CAST(value AS INT) IS NOT NULL;
INSERT INTO tbauditoria(tablaafectada,idregistro,accion,idusuario,campoafectado,valorantes,valordespués) VALUES('tbusuario',CAST(@nuevoId AS VARCHAR),'INSERT',@idCreador,'CREACION','',CONCAT('Usuario: ',@account,' Rol: ',@idRol));
SELECT @nuevoId AS id,'Usuario creado' AS mensaje; END
GO

CREATE PROCEDURE sp_usuario_Actualizar @idActualiza INT, @idUsuario INT, @nombre VARCHAR(50)=NULL, @appaterno VARCHAR(50)=NULL, @apmaterno VARCHAR(50)=NULL, @sexo CHAR(1)=NULL, @idRol SMALLINT=NULL, @correo VARCHAR(100)=NULL, @telefono VARCHAR(30)=NULL, @pass VARCHAR(8000)=NULL, @foto VARCHAR(MAX)=NULL, @esProp BIT=NULL, @puedeVerTodos BIT=NULL, @activo BIT=NULL AS
BEGIN SET NOCOUNT ON;
UPDATE tbusuario SET nombre=ISNULL(@nombre,nombre),appaterno=ISNULL(@appaterno,appaterno),apmaterno=ISNULL(@apmaterno,apmaterno),sexo=ISNULL(@sexo,sexo),idrol=ISNULL(@idRol,idrol),correo=ISNULL(@correo,correo),telefono=ISNULL(@telefono,telefono),pass=ISNULL(@pass,pass),fotoperfil=ISNULL(@foto,fotoperfil),esusuariopropietario=ISNULL(@esProp,esusuariopropietario),puedeveratodoconductor=ISNULL(@puedeVerTodos,puedeveratodoconductor),activo=ISNULL(@activo,activo),ultimaactualizacion=GETDATE() WHERE id=@idUsuario;
SELECT 1 AS resultado,'Usuario actualizado' AS mensaje; END
GO

CREATE PROCEDURE sp_usuario_Listar @idCompania SMALLINT=NULL, @activo BIT=NULL, @idRol SMALLINT=NULL, @search VARCHAR(100)=NULL, @pagina INT=1, @tamano INT=50 AS
BEGIN SET NOCOUNT ON;
DECLARE @off INT=(@pagina-1)*@tamano;
SELECT u.id,u.nombre,u.appaterno,u.apmaterno,u.sexo,u.correo,u.telefono,u.account,u.fotoperfil,u.idrol,r.rolnombre,u.esusuariopropietario,u.puedeveratodoconductor,u.activo,u.fechacreacion,u.ultimaactualizacion,COUNT(*) OVER() AS totalregistros FROM tbusuario u INNER JOIN tbrol r ON r.id=u.idrol WHERE (@idCompania IS NULL OR u.idcompania=@idCompania) AND (@activo IS NULL OR u.activo=@activo) AND (@idRol IS NULL OR u.idrol=@idRol) AND (@search IS NULL OR u.nombre LIKE '%'+@search+'%' OR u.correo LIKE '%'+@search+'%' OR u.account LIKE '%'+@search+'%') ORDER BY u.fechacreacion DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

CREATE PROCEDURE sp_usuario_Obtener 
    @idUsuario INT 
AS 
BEGIN
    SET NOCOUNT ON;
    
    -- Obtener los datos del usuario con sus relaciones
    SELECT 
        u.*,
        r.rolnombre,
        c.companianombre,
        -- Reemplazar FOR JSON PATH con una alternativa para SQL 2012
        STUFF(
            (
                SELECT ',' + CAST(idzonacobertura AS VARCHAR(10))
                FROM tbusuariozonascobertura 
                WHERE idusuario = u.id AND activo = 1
                FOR XML PATH('')
            ), 
            1, 1, ''
        ) AS zonas
    FROM 
        tbusuario u 
        INNER JOIN tbrol r ON r.id = u.idrol 
        INNER JOIN tbcompania c ON c.id = u.idcompania 
    WHERE 
        u.id = @idUsuario;
END
GO

CREATE PROCEDURE sp_rol_Listar AS BEGIN SET NOCOUNT ON; SELECT id,rolnombre,activo FROM tbrol WHERE activo=1 ORDER BY id; END
GO

CREATE PROCEDURE sp_conductor_Listar @idCompania SMALLINT=NULL, @idZona INT=NULL, @idEst SMALLINT=NULL, @docAprob BIT=NULL, @bloq BIT=NULL, @search VARCHAR(100)=NULL, @pagina INT=1, @tamano INT=50 AS
BEGIN SET NOCOUNT ON;
DECLARE @off INT=(@pagina-1)*@tamano;
SELECT c.id,c.nombre,c.appaterno,c.apmaterno,c.sexo,c.correo,c.telefono,c.account,c.fotoperfil,c.curp,c.rfc,c.licenciaconducir,c.idconductorestatus,ce.conductorestatus,c.idestatusdocumentacion,ed.nombreestatusdocs,c.documentacionaprobada,c.bloqueado,c.conectado,c.idzonacobertura,zc.nombrezona,c.fechacreacion,c.ultimaconexionusr,c.ultimaactualizacion,c.banco,c.clabeinterbancaria,COUNT(*) OVER() AS totalregistros FROM tbconductor c INNER JOIN tbconductorestatus ce ON ce.id=c.idconductorestatus LEFT JOIN tbestatusdocumentacion ed ON ed.id=c.idestatusdocumentacion LEFT JOIN tbzonacobertura zc ON zc.id=c.idzonacobertura WHERE (@idCompania IS NULL OR c.idcompania=@idCompania) AND (@idZona IS NULL OR c.idzonacobertura=@idZona) AND (@idEst IS NULL OR c.idconductorestatus=@idEst) AND (@docAprob IS NULL OR c.documentacionaprobada=@docAprob) AND (@bloq IS NULL OR c.bloqueado=@bloq) AND (@search IS NULL OR c.nombre LIKE '%'+@search+'%' OR c.correo LIKE '%'+@search+'%' OR c.account LIKE '%'+@search+'%' OR c.telefono LIKE '%'+@search+'%') ORDER BY c.fechacreacion DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

CREATE PROCEDURE sp_conductor_Obtener @idConductor INT AS
BEGIN SET NOCOUNT ON;
SELECT c.*,ce.conductorestatus,ed.nombreestatusdocs,zc.nombrezona,cmp.companianombre,i.idioma,(SELECT COUNT(*) FROM tbconductordocumentos WHERE idconductor=c.id AND validado IS NOT NULL) AS totaldocs,(SELECT COUNT(*) FROM tbconductordocumentos WHERE idconductor=c.id AND validado=1) AS docsvalidados,(SELECT COUNT(*) FROM tbconductorunidades WHERE idconductor=c.id) AS totalunidades,(SELECT COUNT(*) FROM tbcortesemanasemanal WHERE idconductor=c.id AND tbcortesemanasemanal.activo=1) AS totalcortes FROM tbconductor c INNER JOIN tbconductorestatus ce ON ce.id=c.idconductorestatus LEFT JOIN tbestatusdocumentacion ed ON ed.id=c.idestatusdocumentacion LEFT JOIN tbzonacobertura zc ON zc.id=c.idzonacobertura LEFT JOIN tbcompania cmp ON cmp.id=c.idcompania LEFT JOIN tbidioma i ON i.id=c.idiomapreferido WHERE c.id=@idConductor;
END
GO

CREATE PROCEDURE sp_conductor_ValidarDocumento @idDoc INT, @idUsuario INT, @validado BIT, @correccion BIT=0, @coment VARCHAR(MAX)=NULL AS
BEGIN SET NOCOUNT ON;
UPDATE tbconductordocumentos SET validado=@validado,encorreccion=@correccion,enrevision=CASE WHEN @validado=1 OR @correccion=1 THEN 0 ELSE 1 END,comentariocorreccion=ISNULL(@coment,''),idusuariocreo=@idUsuario WHERE id=@idDoc;
DECLARE @idCond INT; SELECT @idCond=idconductor FROM tbconductordocumentos WHERE id=@idDoc;
EXEC sp_conductor_ActualizarEstatusDocumentacion @idCond,@idUsuario;
SELECT 1 AS resultado,'Documento validado' AS mensaje; END
GO

CREATE PROCEDURE sp_conductor_ActualizarEstatusDocumentacion @idConductor INT, @idUsuario INT AS
BEGIN SET NOCOUNT ON;
DECLARE @total INT,@valid INT,@corr INT;
DECLARE @pend INT=(SELECT id FROM tbestatusdocumentacion WHERE nombreestatusdocs='Pendiente');
DECLARE @aprob INT=(SELECT id FROM tbestatusdocumentacion WHERE nombreestatusdocs='Aprobada');
DECLARE @parc INT=(SELECT id FROM tbestatusdocumentacion WHERE nombreestatusdocs='Parcialmente Aprobada');
DECLARE @corrEst INT=(SELECT id FROM tbestatusdocumentacion WHERE nombreestatusdocs='Requiere Correccion');
SELECT @total=COUNT(*),@valid=SUM(CASE WHEN validado=1 THEN 1 ELSE 0 END),@corr=SUM(CASE WHEN encorreccion=1 THEN 1 ELSE 0 END) FROM tbconductordocumentos WHERE idconductor=@idConductor;
DECLARE @nuevo INT=@pend; DECLARE @aprobada BIT=0;
IF @total=0 SET @nuevo=@pend; ELSE IF @corr>0 SET @nuevo=@corrEst; ELSE IF @valid=@total BEGIN SET @nuevo=@aprob; SET @aprobada=1; END ELSE IF @valid>0 SET @nuevo=@parc;
UPDATE tbconductor SET idestatusdocumentacion=@nuevo,documentacionaprobada=@aprobada,fechadocumentacionvalidada=CASE WHEN @aprobada=1 THEN GETDATE() ELSE fechadocumentacionvalidada END,idusuariovalido=@idUsuario,ultimaactualizacion=GETDATE() WHERE id=@idConductor;
IF @aprobada=1 BEGIN DECLARE @disp SMALLINT=(SELECT id FROM tbconductorestatus WHERE conductorestatus='Disponible'); UPDATE tbconductor SET idconductorestatus=@disp WHERE id=@idConductor AND idconductorestatus IN (SELECT id FROM tbconductorestatus WHERE conductorestatus IN ('En Validacion','No Disponible')); END
END
GO

CREATE PROCEDURE sp_conductor_ListarDocumentos @idConductor INT AS
BEGIN SET NOCOUNT ON;
SELECT cd.id,cd.idfile,cd.tokenidfile,cd.idtipoarchivo,ta.tipoarchivo,cd.nombredocumento,cd.comentarios,cd.validado,cd.encorreccion,cd.enrevision,cd.comentariocorreccion,cd.fechacreacion FROM tbconductordocumentos cd INNER JOIN tbtipoarchivo ta ON ta.id=cd.idtipoarchivo WHERE cd.idconductor=@idConductor ORDER BY cd.fechacreacion DESC;
END
GO

CREATE PROCEDURE sp_conductor_Bloquear @idConductor INT, @idUsuario INT, @bloqueado BIT, @motivo VARCHAR(MAX)=NULL AS
BEGIN SET NOCOUNT ON;
UPDATE tbconductor SET bloqueado=@bloqueado,ultimaactualizacion=GETDATE() WHERE id=@idConductor;
IF @bloqueado=1 BEGIN DECLARE @bloq SMALLINT=(SELECT id FROM tbconductorestatus WHERE conductorestatus='Bloqueado'); UPDATE tbconductor SET idconductorestatus=@bloq WHERE id=@idConductor; END
INSERT INTO tbauditoria(tablaafectada,idregistro,accion,idusuario,campoafectado,valorantes,valordespués) VALUES('tbconductor',CAST(@idConductor AS VARCHAR),CASE WHEN @bloqueado=1 THEN 'BLOQUEO' ELSE 'DESBLOQUEO' END,@idUsuario,'bloqueado',CAST(CASE WHEN @bloqueado=1 THEN '0' ELSE '1' END AS VARCHAR),CAST(@bloqueado AS VARCHAR));
SELECT 1 AS resultado, CASE WHEN @bloqueado=1 THEN 'Conductor bloqueado' ELSE 'Conductor desbloqueado' END AS mensaje; END
GO

CREATE PROCEDURE sp_conductor_AprobarUnidad @idConductor INT, @idUnidad INT, @idUsuario INT AS
BEGIN UPDATE tbconductorunidades SET aprobada=1,proximavalidacion=DATEADD(MONTH,6,GETDATE()),ultimaactualizacion=GETDATE() WHERE idconductor=@idConductor AND idunidad=@idUnidad; SELECT 1 AS resultado,'Unidad aprobada' AS mensaje; END
GO

CREATE PROCEDURE sp_conductor_ValidarDocumentoUnidad @idDoc INT, @idUsuario INT, @validado BIT, @correccion BIT=0, @coment VARCHAR(MAX)=NULL AS
BEGIN UPDATE tbconductorunidadesdocumentos SET validado=@validado,encorreccion=@correccion,enrevision=CASE WHEN @validado=1 OR @correccion=1 THEN 0 ELSE 1 END,comentariocorreccion=ISNULL(@coment,''),idusuariocreo=@idUsuario WHERE id=@idDoc; SELECT 1 AS resultado,'Documento de unidad validado' AS mensaje; END
GO

CREATE PROCEDURE sp_conductor_UnidadesPendientes AS
BEGIN SET NOCOUNT ON;
SELECT cu.idconductor,cu.idunidad,cu.fechacreacion,c.nombre AS c_nombre,c.appaterno AS c_appaterno,c.correo AS c_email,c.telefono AS c_tel,u.unidad,u.modelo,u.colorhex,u.colornombre,u.placas,u.noserie,sm.nombresubmarca,m.nombremarca FROM tbconductorunidades cu INNER JOIN tbconductor c ON c.id=cu.idconductor INNER JOIN tbunidad u ON u.id=cu.idunidad LEFT JOIN tbsubmarca sm ON sm.id=u.idsubmarca LEFT JOIN tbmarca m ON m.id=sm.idmarca WHERE cu.aprobada=0 AND u.activo=1 ORDER BY cu.fechacreacion;
END
GO

CREATE PROCEDURE sp_conductor_ListarEstatus AS BEGIN SET NOCOUNT ON; SELECT id,conductorestatus,descripcion FROM tbconductorestatus WHERE activo=1; END
GO

CREATE PROCEDURE sp_pasajero_Listar @idCompania SMALLINT=NULL, @bloq BIT=NULL, @search VARCHAR(100)=NULL, @pagina INT=1, @tamano INT=50 AS
BEGIN SET NOCOUNT ON;
DECLARE @off INT=(@pagina-1)*@tamano;
SELECT p.id,p.nombre,p.appaterno,p.apmaterno,p.correo,p.correoconfirmado,p.codigopaistel,p.telefono,p.telefonoconfirmado,p.account,p.bloqueado,p.conectado,p.ultimaconexionusr,p.fechacreacion,p.eslogueadocongoogle,p.metodopagopreferido,mp.metodopago,c.companianombre,COUNT(*) OVER() AS totalregistros FROM tbpasajero p LEFT JOIN tbmetodopago mp ON mp.id=p.metodopagopreferido LEFT JOIN tbcompania c ON c.id=p.idcompania WHERE (@idCompania IS NULL OR p.idcompania=@idCompania) AND (@bloq IS NULL OR p.bloqueado=@bloq) AND (@search IS NULL OR p.nombre LIKE '%'+@search+'%' OR p.correo LIKE '%'+@search+'%' OR p.account LIKE '%'+@search+'%' OR p.telefono LIKE '%'+@search+'%') ORDER BY p.fechacreacion DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

CREATE PROCEDURE sp_pasajero_Obtener @idPasajero BIGINT AS
BEGIN SET NOCOUNT ON;
SELECT p.*,mp.metodopago,i.idioma,c.companianombre,(SELECT COUNT(*) FROM tbservicios WHERE idpasajero=p.id AND idservicioestatus IN (SELECT id FROM tbservicioestatus WHERE estatus='Finalizado')) AS completados,(SELECT ISNULL(ROUND(AVG(CAST(calificacionpasajero AS DECIMAL(3,1))),1),0) FROM tbservicios WHERE idpasajero=p.id AND calificacionpasajero>0) AS califpromedio FROM tbpasajero p LEFT JOIN tbmetodopago mp ON mp.id=p.metodopagopreferido LEFT JOIN tbidioma i ON i.id=p.idiomapreferido LEFT JOIN tbcompania c ON c.id=p.idcompania WHERE p.id=@idPasajero;
END
GO

CREATE PROCEDURE sp_pasajero_Bloquear @idPasajero BIGINT, @bloqueado BIT, @motivo VARCHAR(1500)=NULL AS
BEGIN SET NOCOUNT ON;
UPDATE tbpasajero SET bloqueado=@bloqueado, ultimaactualizacion=GETDATE() WHERE id=@idPasajero;
IF @bloqueado=1 AND @motivo IS NOT NULL INSERT INTO tbpasajerosbloqueados(codigopaistel,notelefono,motivobloqueo) SELECT codigopaistel,telefono,@motivo FROM tbpasajero WHERE id=@idPasajero;
SELECT 1 AS resultado, CASE WHEN @bloqueado=1 THEN 'Pasajero bloqueado' ELSE 'Pasajero desbloqueado' END AS mensaje; END
GO

CREATE PROCEDURE sp_servicio_Listar @idServicio BIGINT=NULL, @idConductor INT=NULL, @idPasajero BIGINT=NULL, @idEst SMALLINT=NULL, @fi DATETIME=NULL, @ff DATETIME=NULL, @idZona INT=NULL, @pagina INT=1, @tamano INT=50 AS
BEGIN SET NOCOUNT ON;
DECLARE @off INT=(@pagina-1)*@tamano;
SELECT s.id,s.idconductor,s.idpasajero,s.idservicioestatus,se.estatus,s.direccionorigen,s.direcciondestination,s.costoestimado,s.gananciaconductor,s.comisionaplicada,s.distanciametros,s.durationsegundos,s.calificacion,s.calificacionpasajero,s.servicioiniciado,s.llegoasudestino,s.fechacreacion,s.fechaservicioiniciado,s.fechallegoasudestino,s.montodescuento,s.motivocancelacion,s.canceladopor,s.fechacancelacion,s.alarmasospasajero,s.alarmasosconductor,s.tipoviaje,s.idtipopago,tp.tipopago,c.nombre AS c_nombre,c.appaterno AS c_appaterno,c.telefono AS c_tel,p.nombre AS p_nombre,p.appaterno AS p_appaterno,p.telefono AS p_tel,u.unidad,u.placas,COUNT(*) OVER() AS totalregistros FROM tbservicios s INNER JOIN tbservicioestatus se ON se.id=s.idservicioestatus LEFT JOIN tbconductor c ON c.id=s.idconductor LEFT JOIN tbpasajero p ON p.id=s.idpasajero LEFT JOIN tbunidad u ON u.id=s.idunidad LEFT JOIN tbtipopago tp ON tp.id=s.idtipopago WHERE (@idServicio IS NULL OR s.id=@idServicio) AND (@idConductor IS NULL OR s.idconductor=@idConductor) AND (@idPasajero IS NULL OR s.idpasajero=@idPasajero) AND (@idEst IS NULL OR s.idservicioestatus=@idEst) AND (@fi IS NULL OR s.fechacreacion>=@fi) AND (@ff IS NULL OR s.fechacreacion<=@ff) ORDER BY s.fechacreacion DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

CREATE PROCEDURE sp_servicio_Obtener @idServicio BIGINT AS
BEGIN SET NOCOUNT ON;
SELECT s.*,se.estatus,se.estatusdescription,c.nombre AS c_nombre,c.appaterno AS c_appaterno,c.apmaterno AS c_apmaterno,c.fotoperfil AS c_foto,c.telefono AS c_tel,c.correo AS c_email,c.idzonacobertura,zc.nombrezona,p.nombre AS p_nombre,p.appaterno AS p_appaterno,p.apmaterno AS p_apmaterno,p.fotoperfil AS p_foto,p.telefono AS p_tel,p.correo AS p_email,u.unidad,u.alias,u.colorhex,u.colornombre,u.numeroasientos,u.placas,u.modelo,sm.nombresubmarca,m.nombremarca,tp.tipopago,cp.codigopromocional,r.polylineruta,r.puntosruta,r.distanciametros AS rd_m,r.duracionsegundos AS rd_s FROM tbservicios s INNER JOIN tbservicioestatus se ON se.id=s.idservicioestatus LEFT JOIN tbconductor c ON c.id=s.idconductor LEFT JOIN tbpasajero p ON p.id=s.idpasajero LEFT JOIN tbunidad u ON u.id=s.idunidad LEFT JOIN tbsubmarca sm ON sm.id=u.idsubmarca LEFT JOIN tbmarca m ON m.id=sm.idmarca LEFT JOIN tbtipopago tp ON tp.id=s.idtipopago LEFT JOIN tbcodigospromo cp ON cp.id=s.idcodigopromo LEFT JOIN tbrutaasignada r ON r.idservicio=s.id LEFT JOIN tbzonacobertura zc ON zc.id=c.idzonacobertura WHERE s.id=@idServicio;
END
GO

CREATE PROCEDURE sp_servicio_CancelarAdmin @idServicio BIGINT, @idUsuario INT, @motivo VARCHAR(MAX)=NULL AS
BEGIN SET NOCOUNT ON;
DECLARE @can SMALLINT=(SELECT id FROM tbservicioestatus WHERE estatus='Cancelado por Admin' AND activo=1);
UPDATE tbservicios SET idservicioestatus=@can,motivocancelacion=@motivo,canceladopor='administracion',fechacancelacion=GETDATE(),ultimaactualizacion=GETDATE() WHERE id=@idServicio;
DECLARE @idCond INT; SELECT @idCond=idconductor FROM tbservicios WHERE id=@idServicio;
IF @idCond IS NOT NULL BEGIN DECLARE @disp SMALLINT=(SELECT id FROM tbconductorestatus WHERE conductorestatus='Disponible'); UPDATE tbconductor SET idconductorestatus=@disp WHERE id=@idCond; END
SELECT 1 AS resultado,'Servicio cancelado por administrador' AS mensaje; END
GO

CREATE PROCEDURE sp_servicio_ReporteViajes @fi DATETIME, @ff DATETIME, @idZona INT=NULL, @idConductor INT=NULL AS
BEGIN SET NOCOUNT ON;
SELECT s.id,s.fechacreacion,s.direccionorigen,s.direcciondestination,s.costoestimado,s.gananciaconductor,s.comisionaplicada,s.distanciametros,s.durationsegundos,s.calificacion,se.estatus,c.id AS conductor_id,c.nombre AS c_nombre,c.appaterno AS c_appaterno,c.correo AS c_email,c.telefono AS c_tel,zc.nombrezona,cu.unidad,cu.placas,tp.tipopago,p.id AS pasajero_id,p.nombre AS p_nombre,p.appaterno AS p_appaterno,p.correo AS p_email FROM tbservicios s INNER JOIN tbservicioestatus se ON se.id=s.idservicioestatus LEFT JOIN tbconductor c ON c.id=s.idconductor LEFT JOIN tbzonacobertura zc ON zc.id=c.idzonacobertura LEFT JOIN tbunidad cu ON cu.id=s.idunidad LEFT JOIN tbtipopago tp ON tp.id=s.idtipopago LEFT JOIN tbpasajero p ON p.id=s.idpasajero WHERE s.fechacreacion BETWEEN @fi AND @ff AND (@idZona IS NULL OR c.idzonacobertura=@idZona) AND (@idConductor IS NULL OR s.idconductor=@idConductor) ORDER BY s.fechacreacion;
END
GO

CREATE PROCEDURE sp_servicio_ListarEstatus AS BEGIN SET NOCOUNT ON; SELECT id,estatus,estatusdescription FROM tbservicioestatus WHERE activo=1; END
GO

CREATE PROCEDURE sp_incidente_Listar @idEst INT=NULL, @idTipo INT=NULL, @fi DATETIME=NULL, @ff DATETIME=NULL, @pagina INT=1, @tamano INT=50 AS
BEGIN SET NOCOUNT ON;
DECLARE @off INT=(@pagina-1)*@tamano;
SELECT i.id,i.idservicio,i.idtipoincidente,ti.nombretipo,i.idestatusincidente,ei.nombreestatus,i.descripcionincidente,i.so,i.fechaincidente,i.activo,COUNT(*) OVER() AS totalregistros FROM tbincidentes i INNER JOIN tbtipoincidente ti ON ti.id=i.idtipoincidente INNER JOIN tbestatusincidente ei ON ei.id=i.idestatusincidente WHERE (@idEst IS NULL OR i.idestatusincidente=@idEst) AND (@idTipo IS NULL OR i.idtipoincidente=@idTipo) AND (@fi IS NULL OR i.fechaincidente>=@fi) AND (@ff IS NULL OR i.fechaincidente<=@ff) ORDER BY i.fechaincidente DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

CREATE PROCEDURE sp_incidente_Obtener @idIncidente INT AS
BEGIN SET NOCOUNT ON;
SELECT i.*,ti.nombretipo,ti.descripcion AS tipo_desc,ei.nombreestatus,ei.descripcion AS estatus_desc,s.idconductor,s.idpasajero,s.direccionorigen,s.direcciondestination FROM tbincidentes i INNER JOIN tbtipoincidente ti ON ti.id=i.idtipoincidente INNER JOIN tbestatusincidente ei ON ei.id=i.idestatusincidente LEFT JOIN tbservicios s ON s.id=i.idservicio WHERE i.id=@idIncidente;
END
GO

CREATE PROCEDURE sp_incidente_CambiarEstatus @idIncidente INT, @idUsuario INT, @idEstatus INT, @comentarios VARCHAR(MAX) AS
BEGIN SET NOCOUNT ON;
UPDATE tbincidentes SET idestatusincidente=@idEstatus WHERE id=@idIncidente;
INSERT INTO tbincidenteshistorialestatus(idservicioincidente,idestatusincidente,comentarios) VALUES(@idIncidente,@idEstatus,@comentarios);
SELECT 1 AS resultado,'Estatus actualizado' AS mensaje; END
GO

CREATE PROCEDURE sp_incidente_HistorialEstatus @idIncidente INT AS
BEGIN SET NOCOUNT ON;
SELECT ihe.*,ei.nombreestatus FROM tbincidenteshistorialestatus ihe INNER JOIN tbestatusincidente ei ON ei.id=ihe.idestatusincidente WHERE ihe.idservicioincidente=@idIncidente ORDER BY ihe.fechacreacion;
END
GO

CREATE PROCEDURE sp_incidente_ListarTipos AS BEGIN SET NOCOUNT ON; SELECT id,nombretipo,descripcion FROM tbtipoincidente WHERE activo=1; END
GO

CREATE PROCEDURE sp_incidente_ListarEstatus AS BEGIN SET NOCOUNT ON; SELECT id,nombreestatus,descripcion FROM tbestatusincidente WHERE activo=1; END
GO

CREATE PROCEDURE sp_incidente_ListarTablas AS BEGIN SET NOCOUNT ON;
SELECT id,nombretipo AS nombre,'tipo' AS tabla FROM tbtipoincidente WHERE activo=1
UNION ALL
SELECT id,nombreestatus AS nombre,'estatus' AS tabla FROM tbestatusincidente WHERE activo=1
ORDER BY tabla, id;
END
GO

CREATE PROCEDURE sp_incidente_DetalleCompleto @idIncidente INT AS BEGIN SET NOCOUNT ON;
SELECT i.id AS idIncidente, i.idservicio, i.idtipoincidente, ti.nombretipo AS tipo, ti.descripcion AS tipoDesc,
       i.idestatusincidente, ei.nombreestatus AS estatus, ei.descripcion AS estatusDesc,
       i.descripcionincidente AS descripcion, i.so, i.fechaincidente AS fecha, i.activo,
       s.idconductor, s.idpasajero, s.direccionorigen, s.direcciondestination,
       c.nombre + ' ' + c.appaterno AS conductor,
       p.nombre + ' ' + p.appaterno AS pasajero
FROM tbincidentes i
INNER JOIN tbtipoincidente ti ON ti.id = i.idtipoincidente
INNER JOIN tbestatusincidente ei ON ei.id = i.idestatusincidente
LEFT JOIN tbservicios s ON s.id = i.idservicio
LEFT JOIN tbconductor c ON c.id = s.idconductor
LEFT JOIN tbpasajero p ON p.id = s.idpasajero
WHERE i.id = @idIncidente;
SELECT h.idservicioincidente, h.idestatusincidente, e.nombreestatus AS estatus, h.comentarios, h.fechacreacion AS fecha
FROM tbincidenteshistorialestatus h
INNER JOIN tbestatusincidente e ON e.id = h.idestatusincidente
WHERE h.idservicioincidente = @idIncidente
ORDER BY h.fechacreacion DESC;
END
GO

CREATE PROCEDURE sp_promocion_Listar @activo BIT=NULL, @pagina INT=1, @tamano INT=50 AS BEGIN SET NOCOUNT ON;
DECLARE @off INT=(@pagina-1)*@tamano;
SELECT p.id, p.titulopublicidad AS titulo, p.asuntocorreo AS asunto, p.imgbase64 AS img, p.iniciovigenciapromocion AS inicio, p.finvigenciapromocion AS fin, p.activo, p.fechacreacion,
       (CASE WHEN p.activo = 1 AND GETDATE() BETWEEN p.iniciovigenciapromocion AND p.finvigenciapromocion THEN 'VIGENTE'
            WHEN p.activo = 1 AND GETDATE() < p.iniciovigenciapromocion THEN 'PROGRAMADA'
            WHEN p.activo = 1 AND GETDATE() > p.finvigenciapromocion THEN 'VENCIDA'
            ELSE 'INACTIVA' END) AS estadovigencia,
       COUNT(*) OVER() AS totalregistros
FROM tbpromociones p
WHERE (@activo IS NULL OR p.activo = @activo)
ORDER BY p.fechacreacion DESC
OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

CREATE PROCEDURE sp_promocion_Crear @titulo NVARCHAR(1500), @img VARCHAR(MAX)=NULL, @inicio DATETIME, @fin DATETIME, @asunto NVARCHAR(MAX)=NULL, @activo BIT=1 AS BEGIN SET NOCOUNT ON;
INSERT INTO tbpromociones(titulopublicidad, imgbase64, iniciovigenciapromocion, finvigenciapromocion, asuntocorreo, activo)
VALUES(@titulo, @img, @inicio, @fin, @asunto, @activo);
SELECT SCOPE_IDENTITY() AS id, 'Promocion creada' AS mensaje;
END
GO

CREATE PROCEDURE sp_promocion_Actualizar @id INT, @titulo NVARCHAR(1500)=NULL, @img VARCHAR(MAX)=NULL, @inicio DATETIME=NULL, @fin DATETIME=NULL, @asunto NVARCHAR(MAX)=NULL, @activo BIT=NULL AS BEGIN SET NOCOUNT ON;
UPDATE tbpromociones SET
  titulopublicidad = ISNULL(@titulo, titulopublicidad),
  imgbase64 = ISNULL(@img, imgbase64),
  iniciovigenciapromocion = ISNULL(@inicio, iniciovigenciapromocion),
  finvigenciapromocion = ISNULL(@fin, finvigenciapromocion),
  asuntocorreo = ISNULL(@asunto, asuntocorreo),
  activo = ISNULL(@activo, activo)
WHERE id = @id;
SELECT 1 AS id, 'Promocion actualizada' AS mensaje;
END
GO

CREATE PROCEDURE sp_promocion_Eliminar @id INT AS BEGIN SET NOCOUNT ON;
UPDATE tbpromociones SET activo = 0, ultimaactualizacion = GETDATE() WHERE id = @id;
SELECT 1 AS id, 'Promocion eliminada' AS mensaje;
END
GO

CREATE PROCEDURE sp_promocion_GenerarCodigo @idUsuario INT, @idPromocion INT, @codigo VARCHAR(100), @vigenteHasta DATETIME, @descripcion VARCHAR(1500), @esPorcentaje BIT=0, @monto DECIMAL(18,2), @usosMax INT=0 AS BEGIN SET NOCOUNT ON;
IF EXISTS(SELECT 1 FROM tbcodigospromo WHERE codigopromocional=@codigo AND activo=1) BEGIN SELECT -1 AS id,'Codigo ya existe' AS mensaje; RETURN; END
DECLARE @tipo SMALLINT=(SELECT id FROM tbtipocomision WHERE codigo='PERCENTAGE');
INSERT INTO tbcodigospromo(codigopromocional,vigentehasta,decripcionpromo,esporcentaje,montodecuento,usosmaximos)
VALUES(@codigo, @vigenteHasta, @descripcion, @esPorcentaje, @monto, @usosMax);
DECLARE @newId INT=SCOPE_IDENTITY();
SELECT @newId AS id, 'Codigo generado' AS mensaje;
END
GO

CREATE PROCEDURE sp_promocion_ObtenerCodigosPorPromocion @idPromocion INT AS BEGIN SET NOCOUNT ON;
SELECT cp.id, cp.codigopromocional, cp.vigentehasta, cp.decripcionpromo, cp.esporcentaje, cp.montodecuento, cp.usosmaximos, cp.activo
FROM tbcodigospromo cp
WHERE cp.activo = 1
ORDER BY cp.fechacreacion DESC;
END
GO

CREATE PROCEDURE sp_promocion_CrearCodigo @idUsuario INT, @codigo VARCHAR(100), @vigenteHasta DATETIME, @descripcion VARCHAR(1500), @esPorcentaje BIT=0, @monto DECIMAL(18,2), @usosMax INT=0, @montoMin DECIMAL(10,2)=NULL, @usuarioUnico BIGINT=NULL, @descPublica NVARCHAR(500)=NULL AS
BEGIN
IF EXISTS(SELECT 1 FROM tbcodigospromo WHERE codigopromocional=@codigo AND activo=1) BEGIN SELECT -1 AS resultado,'Codigo ya existe' AS mensaje; RETURN; END
INSERT INTO tbcodigospromo(codigopromocional,vigentehasta,decripcionpromo,esporcentaje,montodecuento,usosmaximos,montominimoviaje,usuariounicopasajero,descripcionpublica) VALUES(@codigo,@vigenteHasta,@descripcion,@esPorcentaje,@monto,@usosMax,@montoMin,@usuarioUnico,@descPublica);
SELECT SCOPE_IDENTITY() AS id,'Codigo creado' AS mensaje; END
GO

CREATE PROCEDURE sp_promocion_ListarCodigos @activo BIT=NULL, @pagina INT=1, @tamano INT=50 AS
BEGIN SET NOCOUNT ON;
DECLARE @off INT=(@pagina-1)*@tamano;
SELECT cp.*,COUNT(*) OVER() AS totalregistros FROM tbcodigospromo cp WHERE (@activo IS NULL OR cp.activo=@activo) ORDER BY cp.fechacreacion DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

CREATE PROCEDURE sp_promocion_ObtenerCodigo @idCodigo INT AS
BEGIN SET NOCOUNT ON;
SELECT cp.*,(SELECT COUNT(*) FROM tbcodigospromousados WHERE idcodigopromo=cp.id) AS usosreales FROM tbcodigospromo cp WHERE cp.id=@idCodigo;
END
GO

CREATE PROCEDURE sp_promocion_ActualizarCodigo @idCodigo INT, @vigenteHasta DATETIME=NULL, @monto DECIMAL(18,2)=NULL, @esPorcentaje BIT=NULL, @usosMax INT=NULL, @activo BIT=NULL AS
BEGIN UPDATE tbcodigospromo SET vigentehasta=ISNULL(@vigenteHasta,vigentehasta),montodecuento=ISNULL(@monto,montodecuento),esporcentaje=ISNULL(@esPorcentaje,esporcentaje),usosmaximos=ISNULL(@usosMax,usosmaximos),activo=ISNULL(@activo,activo) WHERE id=@idCodigo; SELECT 1 AS resultado,'Codigo actualizado' AS mensaje; END
GO

CREATE PROCEDURE sp_promocion_CrearPromocion @titulo NVARCHAR(1500), @img VARCHAR(MAX)=NULL, @inicio DATETIME, @fin DATETIME, @asunto NVARCHAR(MAX)=NULL AS
BEGIN INSERT INTO tbpromociones(titulopublicidad,imgbase64,iniciovigenciapromocion,finvigenciapromocion,asuntocorreo) VALUES(@titulo,@img,@inicio,@fin,@asunto); SELECT SCOPE_IDENTITY() AS id,'Promocion creada' AS mensaje; END
GO

CREATE PROCEDURE sp_configuracion_ListarCostos @idCompania SMALLINT AS
BEGIN SET NOCOUNT ON;
SELECT ac.*,dias.dia FROM tbappviajecostos ac CROSS APPLY (SELECT CASE ac.numdiasemana WHEN 1 THEN 'Lunes' WHEN 2 THEN 'Martes' WHEN 3 THEN 'Miercoles' WHEN 4 THEN 'Jueves' WHEN 5 THEN 'Viernes' WHEN 6 THEN 'Sabado' WHEN 7 THEN 'Domingo' END AS dia) dias WHERE ac.idcompania=@idCompania ORDER BY ac.numdiasemana,ac.horainicio;
END
GO

CREATE PROCEDURE sp_configuracion_ActualizarCosto @idCosto INT, @costoMin DECIMAL(10,2)=NULL, @costoKm DECIMAL(10,2)=NULL, @costoMinuto DECIMAL(10,2)=NULL, @horaInicio TIME=NULL, @horaFin TIME=NULL AS
BEGIN UPDATE tbappviajecostos SET costominimo=ISNULL(@costoMin,costominimo),costoporkm=ISNULL(@costoKm,costoporkm),costoporminuto=ISNULL(@costoMinuto,costoporminuto),horainicio=ISNULL(@horaInicio,horainicio),horafin=ISNULL(@horaFin,horafin) WHERE id=@idCosto; SELECT 1 AS resultado,'Costo actualizado' AS mensaje; END
GO

CREATE PROCEDURE sp_configuracion_ObtenerConfig @clave VARCHAR(100)=NULL AS
BEGIN SET NOCOUNT ON;
SELECT id,claveconfiguracion,valorconfiguracion,descripcion FROM tbconfiguracionsistema WHERE activo=1 AND (@clave IS NULL OR claveconfiguracion=@clave);
END
GO

CREATE PROCEDURE sp_configuracion_ActualizarConfig @clave VARCHAR(100), @valor VARCHAR(MAX) AS
BEGIN UPDATE tbconfiguracionsistema SET valorconfiguracion=@valor,ultimaactualizacion=GETDATE() WHERE claveconfiguracion=@clave; SELECT 1 AS resultado,'Config actualizada' AS mensaje; END
GO

CREATE PROCEDURE sp_zona_Listar AS
BEGIN SET NOCOUNT ON;
SELECT z.*,ISNULL(zc.porcentajecomision,3.00) AS comision,zc.comisionminima,zc.comisionmaxima FROM tbzonacobertura z LEFT JOIN tbzonacoberturacomision zc ON zc.idzonacobertura=z.id AND zc.activo=1 WHERE z.activo=1;
END
GO

CREATE PROCEDURE sp_zona_Crear @nombre VARCHAR(100), @desc VARCHAR(1500)=NULL, @lat VARCHAR(50)=NULL, @lng VARCHAR(50)=NULL, @radio DECIMAL(10,2)=NULL, @poligono VARCHAR(MAX)=NULL AS
BEGIN
INSERT INTO tbzonacobertura(nombrezona,descripcion,latitudcentro,longitudcentro,radio_km,coordenadapoligono) VALUES(@nombre,@desc,@lat,@lng,@radio,@poligono);
DECLARE @id INT=SCOPE_IDENTITY();
DECLARE @tipo SMALLINT=(SELECT id FROM tbtipocomision WHERE codigo='PERCENTAGE');
INSERT INTO tbzonacoberturacomision(idzonacobertura,porcentajecomision,idtipocomision,comisionminima,comisionmaxima) VALUES(@id,3.00,@tipo,10.00,100.00);
SELECT @id AS id,'Zona creada' AS mensaje; END
GO

CREATE PROCEDURE sp_zona_Actualizar @id INT, @nombre VARCHAR(100)=NULL, @desc VARCHAR(1500)=NULL, @lat VARCHAR(50)=NULL, @lng VARCHAR(50)=NULL, @radio DECIMAL(10,2)=NULL, @poligono VARCHAR(MAX)=NULL, @activo BIT=NULL AS
BEGIN UPDATE tbzonacobertura SET nombrezona=ISNULL(@nombre,nombrezona),descripcion=ISNULL(@desc,descripcion),latitudcentro=ISNULL(@lat,latitudcentro),longitudcentro=ISNULL(@lng,longitudcentro),radio_km=ISNULL(@radio,radio_km),coordenadapoligono=ISNULL(@poligono,coordenadapoligono),activo=ISNULL(@activo,activo) WHERE id=@id; SELECT 1 AS resultado,'Zona actualizada' AS mensaje; END
GO

CREATE PROCEDURE sp_zona_ActualizarComision @idZona INT, @porcentaje DECIMAL(5,2), @min DECIMAL(10,2)=NULL, @max DECIMAL(10,2)=NULL AS
BEGIN
IF EXISTS(SELECT 1 FROM tbzonacoberturacomision WHERE idzonacobertura=@idZona AND activo=1) UPDATE tbzonacoberturacomision SET porcentajecomision=@porcentaje,comisionminima=ISNULL(@min,comisionminima),comisionmaxima=ISNULL(@max,comisionmaxima),ultimaactualizacion=GETDATE() WHERE idzonacobertura=@idZona AND activo=1;
ELSE BEGIN DECLARE @tipo SMALLINT=(SELECT id FROM tbtipocomision WHERE codigo='PERCENTAGE'); INSERT INTO tbzonacoberturacomision(idzonacobertura,porcentajecomision,idtipocomision,comisionminima,comisionmaxima) VALUES(@idZona,@porcentaje,@tipo,@min,@max); END
SELECT 1 AS resultado,'Comision actualizada' AS mensaje; END
GO

CREATE PROCEDURE sp_corte_GenerarCorteSemanal @idConductor INT=NULL AS
BEGIN SET NOCOUNT ON;
DECLARE @iniSem DATE=DATEADD(DAY,-DATEPART(WEEKDAY,GETDATE())+1,CAST(GETDATE() AS DATE));
DECLARE @finSem DATE=DATEADD(DAY,7-DATEPART(WEEKDAY,GETDATE()),CAST(GETDATE() AS DATE));
DECLARE @pend SMALLINT=(SELECT id FROM tbcortesemanasemanalestatus WHERE nombreestatus='Pendiente');
INSERT INTO tbcortesemanasemanal(idconductor,idzonacobertura,semanainicio,semanafin,totalingresos,totalcomision,totalcomisionporcentaje,totalnetoconductor,idestatuscorte)
SELECT c.id,c.idzonacobertura,@iniSem,@finSem,ISNULL(SUM(s.costoestimado),0),ISNULL(SUM(s.comisionaplicada),0),ISNULL(AVG(s.porcentajecomision),3.00),ISNULL(SUM(s.gananciaconductor),0),@pend
FROM tbconductor c INNER JOIN tbservicios s ON s.idconductor=c.id INNER JOIN tbservicioestatus se ON se.id=s.idservicioestatus
WHERE (@idConductor IS NULL OR c.id=@idConductor) AND CAST(s.fechacreacion AS DATE) BETWEEN @iniSem AND @finSem AND se.estatus='Finalizado'
AND NOT EXISTS(SELECT 1 FROM tbcortesemanasemanal WHERE idconductor=c.id AND semanainicio=@iniSem AND semanafin=@finSem)
GROUP BY c.id,c.idzonacobertura;
SELECT 1 AS resultado,'Corte generado' AS mensaje; END
GO

CREATE PROCEDURE sp_corte_ListarCortes @idConductor INT=NULL, @idEst SMALLINT=NULL, @pagina INT=1, @tamano INT=50 AS
BEGIN SET NOCOUNT ON;
DECLARE @off INT=(@pagina-1)*@tamano;
SELECT cs.*,ce.conductorestatus AS cond_estatus,c.nombre AS c_nombre,c.appaterno AS c_appaterno,zc.nombrezona,es.nombreestatus,COUNT(*) OVER() AS totalregistros FROM tbcortesemanasemanal cs INNER JOIN tbconductor c ON c.id=cs.idconductor LEFT JOIN tbconductorestatus ce ON ce.id=c.idconductorestatus LEFT JOIN tbzonacobertura zc ON zc.id=cs.idzonacobertura LEFT JOIN tbcortesemanasemanalestatus es ON es.id=cs.idestatuscorte WHERE (@idConductor IS NULL OR cs.idconductor=@idConductor) AND (@idEst IS NULL OR cs.idestatuscorte=@idEst) ORDER BY cs.semanainicio DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

CREATE PROCEDURE sp_corte_ObtenerDetalle @idCorte BIGINT AS
BEGIN SET NOCOUNT ON;
SELECT csd.*,s.direccionorigen,s.direcciondestination,s.fechacreacion,s.calificacion,p.nombre AS p_nombre FROM tbcortesemanasemanaldetalle csd INNER JOIN tbservicios s ON s.id=csd.idservicio LEFT JOIN tbpasajero p ON p.id=s.idpasajero WHERE csd.idcortesemanal=@idCorte;
END
GO

CREATE PROCEDURE sp_corte_CambiarEstatus @idCorte BIGINT, @idEstatus SMALLINT, @idUsuario INT, @comprobante VARCHAR(MAX)=NULL AS
BEGIN SET NOCOUNT ON;
UPDATE tbcortesemanasemanal SET idestatuscorte=@idEstatus,comprobantepago=ISNULL(@comprobante,comprobantepago),fechapagorealizado=CASE WHEN (SELECT nombreestatus FROM tbcortesemanasemanalestatus WHERE id=@idEstatus)='Pagado' THEN GETDATE() ELSE fechapagorealizado END,ultimaactualizacion=GETDATE() WHERE id=@idCorte;
SELECT 1 AS resultado,'Estatus de corte actualizado' AS mensaje; END
GO

CREATE PROCEDURE sp_notificacion_EnviarPush @idUsuario INT, @titulo NVARCHAR(200), @mensaje NVARCHAR(500), @tipoAudiencia VARCHAR(50), @idPasajero BIGINT=NULL, @idConductor INT=NULL, @fechaProgramada DATETIME=NULL AS
BEGIN INSERT INTO tbnotificacionpush(titulo,mensaje,tipoaudiencia,idpasajero,idconductor,fechaprogramada) VALUES(@titulo,@mensaje,@tipoAudiencia,@idPasajero,@idConductor,@fechaProgramada); SELECT SCOPE_IDENTITY() AS id,'Notificacion creada' AS mensaje; END
GO

CREATE PROCEDURE sp_notificacion_ListarPush @enviado BIT=NULL, @fi DATETIME=NULL, @ff DATETIME=NULL, @pagina INT=1, @tamano INT=50 AS
BEGIN SET NOCOUNT ON;
DECLARE @off INT=(@pagina-1)*@tamano;
SELECT np.*,COUNT(*) OVER() AS totalregistros FROM tbnotificacionpush np WHERE (@enviado IS NULL OR np.enviado=@enviado) AND (@fi IS NULL OR np.fechacreacion>=@fi) AND (@ff IS NULL OR np.fechacreacion<=@ff) ORDER BY np.fechacreacion DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

CREATE PROCEDURE sp_notificacion_HistorialEnvio @idNotificacion INT AS
BEGIN SET NOCOUNT ON; SELECT * FROM tbnotificacionpushenviada WHERE idnotificacionpush=@idNotificacion ORDER BY fechaenvio DESC; END
GO

CREATE PROCEDURE sp_aviso_Crear @idCompania SMALLINT, @titulo VARCHAR(50), @descripcion NVARCHAR(300), @paraPasajero BIT=0, @paraConductor BIT=0 AS
BEGIN INSERT INTO tbavisosapp(idcompania,esavisopasajero,esavisoconductor,tituloaviso,descripcionaviso) VALUES(@idCompania,@paraPasajero,@paraConductor,@titulo,@descripcion); SELECT SCOPE_IDENTITY() AS id,'Aviso creado' AS mensaje; END
GO

CREATE PROCEDURE sp_aviso_Listar @idCompania SMALLINT=NULL AS
BEGIN SET NOCOUNT ON; SELECT * FROM tbavisosapp WHERE (@idCompania IS NULL OR idcompania=@idCompania) AND activo=1 ORDER BY fechacreacion DESC; END
GO

CREATE PROCEDURE sp_menu_ListarXUsuario @idUsuario INT AS
BEGIN SET NOCOUNT ON;
SELECT DISTINCT m.* FROM tbmenu m INNER JOIN tbusuariomenu um ON um.idmenu=m.id AND um.idusuario=@idUsuario
UNION
SELECT DISTINCT m.* FROM tbmenu m INNER JOIN tbrolmenudefault rmd ON rmd.idmenu=m.id INNER JOIN tbusuario u ON u.idrol=rmd.idrol AND u.id=@idUsuario WHERE m.activo=1 ORDER BY m.ordernumber;
END
GO

CREATE PROCEDURE sp_log_ListarErrores @fi DATETIME=NULL, @ff DATETIME=NULL, @pagina INT=1, @tamano INT=50 AS
BEGIN SET NOCOUNT ON;
DECLARE @off INT=(@pagina-1)*@tamano;
SELECT *,COUNT(*) OVER() AS totalregistros FROM tblogerror WHERE (@fi IS NULL OR fechacreacion>=@fi) AND (@ff IS NULL OR fechacreacion<=@ff) ORDER BY fechacreacion DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

CREATE PROCEDURE sp_auditoria_Listar @tabla VARCHAR(100)=NULL, @accion VARCHAR(20)=NULL, @fi DATETIME=NULL, @ff DATETIME=NULL, @pagina INT=1, @tamano INT=50 AS
BEGIN SET NOCOUNT ON;
DECLARE @off INT=(@pagina-1)*@tamano;
SELECT a.*,u.nombre AS usuario_nombre,u.account AS usuario_account,COUNT(*) OVER() AS totalregistros FROM tbauditoria a LEFT JOIN tbusuario u ON u.id=a.idusuario WHERE (@tabla IS NULL OR a.tablaafectada=@tabla) AND (@accion IS NULL OR a.accion=@accion) AND (@fi IS NULL OR a.fechacreacion>=@fi) AND (@ff IS NULL OR a.fechacreacion<=@ff) ORDER BY a.fechacreacion DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY;
END
GO

CREATE PROCEDURE sp_compania_Obtener AS BEGIN SET NOCOUNT ON; SELECT TOP 1 * FROM tbcompania WHERE activo=1; END
GO

CREATE PROCEDURE sp_compania_Actualizar @id SMALLINT, @nombre VARCHAR(50)=NULL, @kms INT=NULL, @segTomar INT=NULL, @segEspera INT=NULL, @numUnidades INT=NULL, @soloCercana BIT=NULL, @tarjetaAct BIT=NULL, @paypalAct BIT=NULL, @mpAct BIT=NULL, @minPP INT=NULL, @minMP INT=NULL, @verPasajero VARCHAR(100)=NULL, @verConductor VARCHAR(100)=NULL, @andGAPI BIT=NULL, @iosGAPI BIT=NULL AS
BEGIN
UPDATE tbcompania SET companianombre=ISNULL(@nombre,companianombre),kmsalaredondamascercanos=ISNULL(@kms,kmsalaredondamascercanos),segesperatomaservicio=ISNULL(@segTomar,segesperatomaservicio),segesperasalgapasajero=ISNULL(@segEspera,segesperasalgapasajero),nounidadesmascercanas=ISNULL(@numUnidades,nounidadesmascercanas),sololaunidadmascercana=ISNULL(@soloCercana,sololaunidadmascercana),pagocontarjetaactivo=ISNULL(@tarjetaAct,pagocontarjetaactivo),paypalactivo=ISNULL(@paypalAct,paypalactivo),mercadopagoactivo=ISNULL(@mpAct,mercadopagoactivo),minsparapagopaypal=ISNULL(@minPP,minsparapagopaypal),minsparapagomercadopago=ISNULL(@minMP,minsparapagomercadopago),versionpasajeroandroid=ISNULL(@verPasajero,versionpasajeroandroid),versionconductorandroid=ISNULL(@verConductor,versionconductorandroid),androidgoogleapihablitado=ISNULL(@andGAPI,androidgoogleapihablitado),iosgoogleapihablitado=ISNULL(@iosGAPI,iosgoogleapihablitado),ultimaactualizacion=GETDATE() WHERE id=@id;
SELECT 1 AS resultado,'Compania actualizada' AS mensaje; END
GO

PRINT '=============================================';
PRINT 'SCRIPT DE FUNCIONES Y PROCEDIMIENTOS COMPLETADO';
PRINT '=============================================';
GO
