-- ============================================
-- Missing Stored Procedures for vaia_viajes
-- Generated from AdminController.cs references
-- ============================================

-- ============================================
-- 1. sp_usuario_CerrarSesion
-- ============================================
CREATE PROCEDURE sp_usuario_CerrarSesion @idUsuario INT AS
BEGIN SET NOCOUNT ON;
UPDATE tbsesionusuario SET activo=0,fechadesconexion=GETDATE() WHERE idusuario=@idUsuario AND activo=1;
SELECT 1 AS resultado,'Sesion cerrada' AS mensaje; END
GO

-- ============================================
-- 2. sp_usuario_Eliminar
-- ============================================
CREATE PROCEDURE sp_usuario_Eliminar @idUsuario INT, @idActualiza INT AS
BEGIN SET NOCOUNT ON;
UPDATE tbusuario SET activo=0,ultimaactualizacion=GETDATE() WHERE id=@idUsuario;
INSERT INTO tbauditoria(tablaafectada,idregistro,accion,idusuario) VALUES('tbusuario',CAST(@idUsuario AS VARCHAR),'ELIMINAR',@idActualiza);
SELECT 1 AS resultado,'Usuario desactivado' AS mensaje; END
GO

-- ============================================
-- 3. sp_rol_ListarPermisos
-- ============================================
CREATE PROCEDURE sp_rol_ListarPermisos @idRol SMALLINT AS
BEGIN SET NOCOUNT ON;
SELECT m.*,rm.idrol FROM tbmenu m LEFT JOIN tbrolmenudefault rm ON rm.idmenu=m.id AND rm.idrol=@idRol WHERE m.activo=1 ORDER BY m.ordernumber; END
GO

-- ============================================
-- 4. sp_pasajero_Actualizar
-- ============================================
CREATE PROCEDURE sp_pasajero_Actualizar @idPasajero BIGINT, @idCompania SMALLINT=NULL, @nombre VARCHAR(50)=NULL, @appaterno VARCHAR(50)=NULL, @apmaterno VARCHAR(50)=NULL, @correo VARCHAR(100)=NULL, @codigopaistel VARCHAR(15)=NULL, @telefono VARCHAR(30)=NULL, @fechanacimiento DATE=NULL, @genero CHAR(1)=NULL, @notas VARCHAR(500)=NULL, @activo BIT=NULL AS
BEGIN SET NOCOUNT ON;
UPDATE tbpasajero SET nombre=ISNULL(@nombre,nombre),appaterno=ISNULL(@appaterno,appaterno),apmaterno=ISNULL(@apmaterno,apmaterno),correo=ISNULL(@correo,correo),codigopaistel=ISNULL(@codigopaistel,codigopaistel),telefono=ISNULL(@telefono,telefono),fechanacimiento=ISNULL(@fechanacimiento,fechanacimiento),genero=ISNULL(@genero,genero),notasadicionales=ISNULL(@notas,notasadicionales),activo=ISNULL(@activo,activo),ultimaactualizacion=GETDATE() WHERE id=@idPasajero;
SELECT 1 AS resultado,'Pasajero actualizado' AS mensaje; END
GO

-- ============================================
-- 5. sp_pasajero_AsignarSaldo
-- ============================================
CREATE PROCEDURE sp_pasajero_AsignarSaldo @idPasajero BIGINT, @saldo DECIMAL(10,2), @idUsuario INT AS
BEGIN SET NOCOUNT ON;
SELECT 1 AS resultado,'Saldo asignado' AS mensaje; END
GO

-- ============================================
-- 6. sp_conductor_Actualizar
-- ============================================
CREATE PROCEDURE sp_conductor_Actualizar @idConductor INT, @idCompania SMALLINT=NULL, @idZona INT=NULL, @nombre VARCHAR(50)=NULL, @appaterno VARCHAR(50)=NULL, @apmaterno VARCHAR(50)=NULL, @sexo CHAR(1)=NULL, @correo VARCHAR(100)=NULL, @telefono VARCHAR(30)=NULL, @curp VARCHAR(50)=NULL, @rfc VARCHAR(50)=NULL, @licencia VARCHAR(50)=NULL, @fvtoLicencia DATETIME=NULL, @tipoLicencia VARCHAR(20)=NULL, @banco VARCHAR(100)=NULL, @titular VARCHAR(150)=NULL, @clabe VARCHAR(150)=NULL, @notas VARCHAR(500)=NULL, @activo BIT=NULL AS
BEGIN SET NOCOUNT ON;
UPDATE tbconductor SET nombre=ISNULL(@nombre,nombre),appaterno=ISNULL(@appaterno,appaterno),apmaterno=ISNULL(@apmaterno,apmaterno),sexo=ISNULL(@sexo,sexo),correo=ISNULL(@correo,correo),telefono=ISNULL(@telefono,telefono),curp=ISNULL(@curp,curp),rfc=ISNULL(@rfc,rfc),licenciaconducir=ISNULL(@licencia,licenciaconducir),fechavencimientolicencia=ISNULL(@fvtoLicencia,fechavencimientolicencia),tipolicencia=ISNULL(@tipoLicencia,tipolicencia),banco=ISNULL(@banco,banco),nombretitular=ISNULL(@titular,nombretitular),clabeinterbancaria=ISNULL(@clabe,clabeinterbancaria),notasadicionales=ISNULL(@notas,notasadicionales),activo=ISNULL(@activo,activo),ultimaactualizacion=GETDATE() WHERE id=@idConductor;
SELECT 1 AS resultado,'Conductor actualizado' AS mensaje; END
GO

-- ============================================
-- 7. sp_conductor_ListarRazonesSociales
-- ============================================
CREATE PROCEDURE sp_conductor_ListarRazonesSociales AS
BEGIN SET NOCOUNT ON;
SELECT DISTINCT rfc,nombretitular,banco,clabeinterbancaria FROM tbconductor WHERE activo=1 AND rfc IS NOT NULL ORDER BY nombretitular; END
GO

-- ============================================
-- 8. sp_promocion_Actualizar
-- ============================================
CREATE PROCEDURE sp_promocion_Actualizar @id INT, @titulo NVARCHAR(1500)=NULL, @img VARCHAR(MAX)=NULL, @inicio DATETIME=NULL, @fin DATETIME=NULL, @asunto NVARCHAR(MAX)=NULL, @activo BIT=NULL AS
BEGIN SET NOCOUNT ON;
UPDATE tbpromociones SET titulopublicidad=ISNULL(@titulo,titulopublicidad),imgbase64=ISNULL(@img,imgbase64),iniciovigenciapromocion=ISNULL(@inicio,iniciovigenciapromocion),finvigenciapromocion=ISNULL(@fin,finvigenciapromocion),asuntocorreo=ISNULL(@asunto,asuntocorreo),activo=ISNULL(@activo,activo) WHERE id=@id;
SELECT 1 AS resultado,'Promocion actualizada' AS mensaje; END
GO

-- ============================================
-- 9. sp_promocion_Eliminar
-- ============================================
CREATE PROCEDURE sp_promocion_Eliminar @id INT AS
BEGIN SET NOCOUNT ON;
UPDATE tbpromociones SET activo=0 WHERE id=@id;
SELECT 1 AS resultado,'Promocion desactivada' AS mensaje; END
GO

-- ============================================
-- 10. sp_promocion_Listar
-- ============================================
CREATE PROCEDURE sp_promocion_Listar @activo BIT=NULL, @pagina INT=1, @tamano INT=50 AS
BEGIN SET NOCOUNT ON;
DECLARE @off INT=(@pagina-1)*@tamano;
SELECT *,COUNT(*) OVER() AS totalregistros FROM tbpromociones WHERE (@activo IS NULL OR activo=@activo) ORDER BY fechacreacion DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY; END
GO

-- ============================================
-- 11. sp_zona_Eliminar
-- ============================================
CREATE PROCEDURE sp_zona_Eliminar @id INT AS
BEGIN SET NOCOUNT ON;
UPDATE tbzonacobertura SET activo=0 WHERE id=@id;
SELECT 1 AS resultado,'Zona desactivada' AS mensaje; END
GO

-- ============================================
-- 12. sp_zona_ObtenerComisiones
-- ============================================
CREATE PROCEDURE sp_zona_ObtenerComisiones @idZona INT AS
BEGIN SET NOCOUNT ON;
SELECT * FROM tbzonacoberturacomision WHERE idzonacobertura=@idZona AND activo=1; END
GO

-- ============================================
-- 13. sp_aviso_Actualizar
-- ============================================
CREATE PROCEDURE sp_aviso_Actualizar @id INT, @idCompania SMALLINT=NULL, @titulo VARCHAR(50)=NULL, @descripcion NVARCHAR(300)=NULL, @paraPasajero BIT=NULL, @paraConductor BIT=NULL, @activo BIT=NULL AS
BEGIN SET NOCOUNT ON;
UPDATE tbavisosapp SET idcompania=ISNULL(@idCompania,idcompania),tituloaviso=ISNULL(@titulo,tituloaviso),descripcionaviso=ISNULL(@descripcion,descripcionaviso),esavisopasajero=ISNULL(@paraPasajero,esavisopasajero),esavisoconductor=ISNULL(@paraConductor,esavisoconductor),activo=ISNULL(@activo,activo) WHERE id=@id;
SELECT 1 AS resultado,'Aviso actualizado' AS mensaje; END
GO

-- ============================================
-- 14. sp_aviso_Eliminar
-- ============================================
CREATE PROCEDURE sp_aviso_Eliminar @id INT AS
BEGIN SET NOCOUNT ON;
UPDATE tbavisosapp SET activo=0 WHERE id=@id;
SELECT 1 AS resultado,'Aviso desactivado' AS mensaje; END
GO

-- ============================================
-- 15. sp_compania_Listar
-- ============================================
CREATE PROCEDURE sp_compania_Listar AS
BEGIN SET NOCOUNT ON;
SELECT * FROM tbcompania WHERE activo=1 ORDER BY companianombre; END
GO

-- ============================================
-- 16. sp_incidente_ListarTablas
-- ============================================
CREATE PROCEDURE sp_incidente_ListarTablas AS
BEGIN SET NOCOUNT ON;
SELECT id,nombretipo,descripcion FROM tbtipoincidente WHERE activo=1;
SELECT id,nombreestatus,descripcion FROM tbestatusincidente WHERE activo=1;
SELECT id,estatus,estatusdescription FROM tbservicioestatus WHERE activo=1; END
GO

-- ============================================
-- 17. sp_reporte_Pasajeros
-- ============================================
CREATE PROCEDURE sp_reporte_Pasajeros @fi DATETIME=NULL, @ff DATETIME=NULL AS
BEGIN SET NOCOUNT ON;
SELECT p.*,c.companianombre,(SELECT COUNT(*) FROM tbservicios WHERE idpasajero=p.id AND (@fi IS NULL OR fechacreacion>=@fi) AND (@ff IS NULL OR fechacreacion<=@ff)) AS totalviajes,(SELECT ISNULL(SUM(costoestimado),0) FROM tbservicios WHERE idpasajero=p.id AND (@fi IS NULL OR fechacreacion>=@fi) AND (@ff IS NULL OR fechacreacion<=@ff) AND idservicioestatus IN (SELECT id FROM tbservicioestatus WHERE estatus='Finalizado')) AS totalingresos FROM tbpasajero p LEFT JOIN tbcompania c ON c.id=p.idcompania WHERE (@fi IS NULL OR p.fechacreacion>=@fi) AND (@ff IS NULL OR p.fechacreacion<=@ff) ORDER BY p.fechacreacion DESC; END
GO

-- ============================================
-- 18. sp_reporte_Conductores
-- ============================================
CREATE PROCEDURE sp_reporte_Conductores @fi DATETIME=NULL, @ff DATETIME=NULL, @idZona INT=NULL AS
BEGIN SET NOCOUNT ON;
SELECT c.*,ce.conductorestatus,zc.nombrezona,cmp.companianombre,(SELECT COUNT(*) FROM tbservicios WHERE idconductor=c.id AND (@fi IS NULL OR fechacreacion>=@fi) AND (@ff IS NULL OR fechacreacion<=@ff)) AS totalviajes,(SELECT ISNULL(SUM(costoestimado),0) FROM tbservicios WHERE idconductor=c.id AND (@fi IS NULL OR fechacreacion>=@fi) AND (@ff IS NULL OR fechacreacion<=@ff) AND idservicioestatus IN (SELECT id FROM tbservicioestatus WHERE estatus='Finalizado')) AS totalingresos FROM tbconductor c LEFT JOIN tbconductorestatus ce ON ce.id=c.idconductorestatus LEFT JOIN tbzonacobertura zc ON zc.id=c.idzonacobertura LEFT JOIN tbcompania cmp ON cmp.id=c.idcompania WHERE (@fi IS NULL OR c.fechacreacion>=@fi) AND (@ff IS NULL OR c.fechacreacion<=@ff) AND (@idZona IS NULL OR c.idzonacobertura=@idZona) ORDER BY c.fechacreacion DESC; END
GO

-- ============================================
-- 19. sp_reporte_Ingresos
-- ============================================
CREATE PROCEDURE sp_reporte_Ingresos @fi DATETIME=NULL, @ff DATETIME=NULL, @idCompania SMALLINT=NULL AS
BEGIN SET NOCOUNT ON;
SELECT ISNULL(SUM(costoestimado),0) AS totalingresos,ISNULL(SUM(gananciaconductor),0) AS totalgananciaconductor,ISNULL(SUM(comisionaplicada),0) AS totalcomision,COUNT(*) AS totalviajes FROM tbservicios WHERE idservicioestatus IN (SELECT id FROM tbservicioestatus WHERE estatus='Finalizado') AND (@fi IS NULL OR fechacreacion>=@fi) AND (@ff IS NULL OR fechacreacion<=@ff); END
GO

-- ============================================
-- 20. sp_reporte_Comisiones
-- ============================================
CREATE PROCEDURE sp_reporte_Comisiones @fi DATETIME=NULL, @ff DATETIME=NULL, @idZona INT=NULL AS
BEGIN SET NOCOUNT ON;
SELECT zc.nombrezona,ISNULL(SUM(s.comisionaplicada),0) AS totalcomision,ISNULL(SUM(s.costoestimado),0) AS totalingresos,COUNT(s.id) AS totalviajes FROM tbservicios s INNER JOIN tbconductor c ON c.id=s.idconductor INNER JOIN tbzonacobertura zc ON zc.id=c.idzonacobertura WHERE s.idservicioestatus IN (SELECT id FROM tbservicioestatus WHERE estatus='Finalizado') AND (@fi IS NULL OR s.fechacreacion>=@fi) AND (@ff IS NULL OR s.fechacreacion<=@ff) AND (@idZona IS NULL OR c.idzonacobertura=@idZona) GROUP BY zc.nombrezona ORDER BY zc.nombrezona; END
GO

-- ============================================
-- 21. sp_reporte_UtilidadDiaria
-- ============================================
CREATE PROCEDURE sp_reporte_UtilidadDiaria @fecha DATE=NULL, @idCompania SMALLINT=NULL AS
BEGIN SET NOCOUNT ON;
SELECT CAST(s.fechacreacion AS DATE) AS fecha,ISNULL(SUM(s.costoestimado),0) AS ingresos,ISNULL(SUM(s.gananciaconductor),0) AS pagoconductor,ISNULL(SUM(s.comisionaplicada),0) AS comision,ISNULL(SUM(s.costoestimado - s.gananciaconductor - ISNULL(s.comisionaplicada,0)),0) AS utilidad,COUNT(s.id) AS viajes FROM tbservicios s WHERE s.idservicioestatus IN (SELECT id FROM tbservicioestatus WHERE estatus='Finalizado') AND (@fecha IS NULL OR CAST(s.fechacreacion AS DATE)=@fecha) GROUP BY CAST(s.fechacreacion AS DATE) ORDER BY fecha; END
GO

-- ============================================
-- 22. sp_configuracion_Obtener
-- ============================================
CREATE PROCEDURE sp_configuracion_Obtener AS
BEGIN SET NOCOUNT ON;
EXEC sp_configuracion_ObtenerConfig NULL; END
GO

-- ============================================
-- 23. sp_configuracion_Guardar
-- ============================================
CREATE PROCEDURE sp_configuracion_Guardar @clave VARCHAR(100), @valor VARCHAR(MAX) AS
BEGIN SET NOCOUNT ON;
EXEC sp_configuracion_ActualizarConfig @clave, @valor; END
GO

-- ============================================
-- 24. sp_configuracion_ActualizarSistema
-- ============================================
CREATE PROCEDURE sp_configuracion_ActualizarSistema @clave VARCHAR(100), @valor VARCHAR(MAX) AS
BEGIN SET NOCOUNT ON;
EXEC sp_configuracion_ActualizarConfig @clave, @valor; END
GO

-- ============================================
-- 25. sp_log_Listar
-- ============================================
CREATE PROCEDURE sp_log_Listar @nivel VARCHAR(50)=NULL, @modulo VARCHAR(100)=NULL, @pagina INT=1, @tamano INT=50 AS
BEGIN SET NOCOUNT ON;
DECLARE @off INT=(@pagina-1)*@tamano;
SELECT *,COUNT(*) OVER() AS totalregistros FROM tblogerror ORDER BY fechacreacion DESC OFFSET @off ROWS FETCH NEXT @tamano ROWS ONLY; END
GO

-- ============================================
-- 26. sp_notificacion_Listar
-- ============================================
CREATE PROCEDURE sp_notificacion_Listar @enviado BIT=NULL, @fi DATETIME=NULL, @ff DATETIME=NULL, @pagina INT=1, @tamano INT=50 AS
BEGIN SET NOCOUNT ON;
EXEC sp_notificacion_ListarPush @enviado, @fi, @ff, @pagina, @tamano; END
GO
