/*
 =============================================
 SCRIPT: SERVICIOS AVANZADOS Y SOPORTE
 =============================================
 Fecha: 2026
 Descripcion: Agrega las tablas necesarias para:
   1. Paradas intermedias en un servicio (waypoints)
   2. Servicios programados con anticipacion
   3. Chat de soporte (pasajero/conductor -> admin)
   4. Trazabilidad de asignacion/reasignacion de conductor

 Es idempotente: se puede ejecutar multiples veces.
 =============================================
*/

USE vaia_viajes;
GO

PRINT '=============================================';
PRINT ' CREANDO TABLAS DE SERVICIOS AVANZADOS Y SOPORTE';
PRINT '=============================================';
GO

-- =============================================
-- 1. PARADAS INTERMEDIAS (WAYPOINTS)
-- =============================================
IF OBJECT_ID('tbservicioparadas', 'U') IS NULL
BEGIN
    PRINT '1. Creando tbservicioparadas...';
    CREATE TABLE tbservicioparadas
    (
        id bigint identity primary key,
        idservicio bigint not null foreign key references tbservicios(id),
        orden tinyint not null, /* orden de la parada dentro del recorrido: 1, 2, 3... */
        direccion varchar(300) not null,
        lat varchar(50) not null,
        lng varchar(50) not null,
        referencia varchar(200), /* nombre corto: "Casa de Ana", "Oxxo Reforma", etc. */
        notas varchar(500),
        completada bit default 0, /* 1 cuando el conductor marca que ya paso por ella */
        fecha_completada datetime,
        activo bit default 1,
        fechacreacion datetime default getdate(),
        ultimaactualizacion datetime default getdate()
    );
    CREATE INDEX IX_tbservicioparadas_servicio ON tbservicioparadas(idservicio, orden);
    PRINT '   OK';
END
ELSE PRINT '1. tbservicioparadas ya existe';
GO

-- =============================================
-- 2. SERVICIOS PROGRAMADOS
-- =============================================
IF OBJECT_ID('tbservicioprogramado', 'U') IS NULL
BEGIN
    PRINT '2. Creando tbservicioprogramado...';
    CREATE TABLE tbservicioprogramado
    (
        id bigint identity primary key,
        idpasajero bigint not null foreign key references tbpasajero(id),
        idcompania smallint foreign key references tbcompania(id),
        direccionorigen varchar(300) not null,
        latorigen varchar(50) not null,
        lngorigen varchar(50) not null,
        direcciondestination varchar(300) not null,
        latdestination varchar(50) not null,
        lngdestination varchar(50) not null,
        paradas_json varchar(max), /* JSON con las paradas: [{orden,dir,lat,lng,ref}] */
        fechaprogramada datetime not null, /* fecha y hora en que se requiere el servicio */
        anticipacion_minutos smallint default 15, /* minutos antes para iniciar la asignacion */
        idtipopago smallint foreign key references tbtipopago(id),
        codigo_promocional varchar(100),
        estado varchar(30) default 'Programado', /* Programado, EnCola, Asignado, EnCurso, Completado, Cancelado */
        idserviciogenerado bigint, /* id del servicio real creado cuando se materializa */
        idconductorasignado int,
        notas varchar(500),
        activo bit default 1,
        fechacreacion datetime default getdate(),
        ultimaactualizacion datetime default getdate()
    );
    CREATE INDEX IX_tbservicioprogramado_fecha ON tbservicioprogramado(fechaprogramada, estado, activo);
    CREATE INDEX IX_tbservicioprogramado_pasajero ON tbservicioprogramado(idpasajero, activo);
    PRINT '   OK';
END
ELSE PRINT '2. tbservicioprogramado ya existe';
GO

-- =============================================
-- 3. SOLICITUDES DE SOPORTE
-- =============================================
IF OBJECT_ID('tbsoportesolicitud', 'U') IS NULL
BEGIN
    PRINT '3. Creando tbsoportesolicitud...';
    CREATE TABLE tbsoportesolicitud
    (
        id bigint identity primary key,
        idservicio bigint foreign key references tbservicios(id), /* servicio al que hace referencia */
        idpasajero bigint foreign key references tbpasajero(id),
        idconductor int foreign key references tbconductor(id),
        tipo_solicitante varchar(20) not null, /* 'pasajero' o 'conductor' */
        asunto varchar(200),
        descripcion_inicial varchar(max),
        estatus varchar(30) default 'Abierto', /* Abierto, EnAtencion, Cerrado */
        idusuariosoporte int foreign key references tbusuario(id), /* admin que atiende */
        prioridad varchar(20) default 'Normal', /* Baja, Normal, Alta, Urgente */
        fechacreacion datetime default getdate(),
        fecha_cierre datetime,
        ultimaactualizacion datetime default getdate(),
        activo bit default 1
    );
    CREATE INDEX IX_tbsoportesolicitud_estatus ON tbsoportesolicitud(estatus, activo);
    CREATE INDEX IX_tbsoportesolicitud_servicio ON tbsoportesolicitud(idservicio);
    PRINT '   OK';
END
ELSE PRINT '3. tbsoportesolicitud ya existe';
GO

-- =============================================
-- 4. MENSAJES DE SOPORTE
-- =============================================
IF OBJECT_ID('tbsoportemensaje', 'U') IS NULL
BEGIN
    PRINT '4. Creando tbsoportemensaje...';
    CREATE TABLE tbsoportemensaje
    (
        id bigint identity primary key,
        idsolicitud bigint not null foreign key references tbsoportesolicitud(id),
        emisor varchar(20) not null, /* 'pasajero', 'conductor', 'soporte' */
        idemisor bigint, /* id del emisor (pasajero, conductor o usuario admin) */
        nombre_emisor varchar(150),
        mensaje varchar(max) not null,
        adjunto_base64 varchar(max),
        leido bit default 0,
        fechacreacion datetime default getdate(),
        activo bit default 1
    );
    CREATE INDEX IX_tbsoportemensaje_solicitud ON tbsoportemensaje(idsolicitud, fechacreacion);
    PRINT '   OK';
END
ELSE PRINT '4. tbsoportemensaje ya existe';
GO

-- =============================================
-- 5. COLUMNAS NUEVAS EN tbservicios
-- =============================================
PRINT '5. Agregando columnas a tbservicios...';

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('tbservicios') AND name='esprogramado')
    ALTER TABLE tbservicios ADD esprogramado bit default 0;
GO
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('tbservicios') AND name='fechaprogramada')
    ALTER TABLE tbservicios ADD fechaprogramada datetime;
GO
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('tbservicios') AND name='idprogramado')
    ALTER TABLE tbservicios ADD idprogramado bigint;
GO
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('tbservicios') AND name='totalparadas')
    ALTER TABLE tbservicios ADD totalparadas tinyint default 0;
GO
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('tbservicios') AND name='paradascompletadas')
    ALTER TABLE tbservicios ADD paradascompletadas tinyint default 0;
GO
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('tbservicios') AND name='intentosasignacion')
    ALTER TABLE tbservicios ADD intentosasignacion smallint default 0;
GO
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('tbservicios') AND name='ultimaconductorasignado')
    ALTER TABLE tbservicios ADD ultimaconductorasignado int;
GO
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('tbservicios') AND name='fechaexpiracionsolicitud')
    ALTER TABLE tbservicios ADD fechaexpiracionsolicitud datetime;
GO

PRINT '   OK';
GO

-- =============================================
-- 6. TABLA DE ASIGNACIONES (auditoria de reasignacion)
-- =============================================
IF OBJECT_ID('tbservicioasignacionlog', 'U') IS NULL
BEGIN
    PRINT '6. Creando tbservicioasignacionlog...';
    CREATE TABLE tbservicioasignacionlog
    (
        id bigint identity primary key,
        idservicio bigint not null foreign key references tbservicios(id),
        idconductor int,
        evento varchar(50) not null, /* 'NOTIFICADO', 'ACEPTO', 'RECHAZO', 'TIMEOUT', 'REASIGNADO' */
        detalle varchar(500),
        fechacreacion datetime default getdate()
    );
    CREATE INDEX IX_tbservicioasignacionlog_servicio ON tbservicioasignacionlog(idservicio, fechacreacion);
    PRINT '   OK';
END
ELSE PRINT '6. tbservicioasignacionlog ya existe';
GO

PRINT '';
PRINT '=============================================';
PRINT ' TABLAS CREADAS CORRECTAMENTE';
PRINT '=============================================';
GO