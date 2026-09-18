create database vaia_viajes;
go
use vaia_viajes;

GO
create table tbtokensapp
(
	appname varchar(50) not null, /* Nombre del aplicativo identificador de token: appPasajero (para la app de pasajero), appConductor (para la app de conductor) o appVaiaAdmin  (para el portal web de admins vaia) */
	token varchar(max), /* token primario que generara job */
	tokensecundario varchar(max), /* token secundario que generara job */
	fechaexpira datetime, /* fecha en que expira el token primario */
	fechaexpirasecundario datetime, /* fecha en que expira el token secundario */
	esprimario bit, /* flag para indicar si el token es primario */
	essecundario bit, /* flag para indicar si el token es secundario */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

go
create table tbrol /* tabla que almacena los roles de usuario */
(
	id smallint identity primary key, /* identificador unico */
	rolnombre varchar(50) not null, /* nombre del rol de usuario */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbconductorestatus /* tabla que almacena el estatus de los conductores */
(
	id smallint identity primary key, /* identificador unico */
	conductorestatus varchar(50) not null, /* nombre del estatus del conductor */
	descripcion varchar(500) not null, /* descripcion del estatus del conductor */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbtipoarchivo /* contine los tipos de archivo del conductor en catálogo */
(
	id smallint identity primary key, /* identificador unico */
	tipoarchivo varchar(100) not null, /* nombre del tipo de archivo */
	descripcion varchar(500) not null, /* descripcion del tipo de archivo */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	paraaltaconductor bit default 0, /* flag para identificar si es alta de conductor */
	paraaltaunidad bit default 0 /* flag para identificar si es alta de cliente */
)

create table tbtipoarchivounidad /* contine los tipos de archivo de la unidad en catálogo */
(
	id smallint identity primary key, /* identificador unico */
	tipoarchivo varchar(100), /* nombre del tipo de archivo */
	descripcion varchar(500), /* descripcion del tipo de archivo */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbmarca /* catálogo de las marcas */
(
	id int identity primary key, /* identificador unico */
	nombremarca varchar(300), /* nombre de la marca */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbsubmarca /* catálogo de la submarca o linea de la marca */
(
	id int identity primary key, /* identificador unico */
	idmarca int foreign key references tbmarca(id), /* identificador de la marca */
	nombresubmarca varchar(300), /* nombre de la submarca o linea de la marca */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbtipocombustible /* catálogo de tipos de combustible */
(
	id int identity primary key, /* identificador unico */
	nombretipocombustible varchar(300), /* nombre del tipo de combustible */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbtipoincidente /* catálogo de tipos de incidentes */
(
	id int identity primary key, /* identificador unico */
	nombretipo varchar(300), /* nombre del tipo de incidente */
	descripcion varchar(500), /* descriçión del tipo de incidente */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbtransmision /* catálogo de transmisiones */
(
	id int identity primary key, /* identificador unico */
	nombretransmision varchar(300), /* nombre de la transmisión */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbtipopago /* catálogo de tipos de pago */
(
	id smallint identity primary key, /* identificador unico */
	tipopago varchar(50) not null, /* nombre del tipo de pago */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime /* ultima fecha en que se actualizó el registro */
)

/* NUEVA TABLA: Catálogo de métodos de pago */
create table tbmetodopago
(
	id smallint identity primary key, /* identificador unico */
	metodopago varchar(50) not null, /* nombre del método de pago: Tarjeta, Efectivo, PayPal, MercadoPago */
	codigo varchar(20) not null, /* código identificador: CARD, CASH, PAYPAL, MERCADOPAGO */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

/* NUEVA TABLA: Catálogo de idiomas soportados */
create table tbidioma
(
	id smallint identity primary key, /* identificador unico */
	idioma varchar(50) not null, /* nombre del idioma: Español, Inglés, etc */
	codigo varchar(5) not null, /* código del idioma: es, en, fr, etc */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

/* NUEVA TABLA: Configuración del sistema */
create table tbconfiguracionsistema
(
	id int identity primary key, /* identificador unico */
	claveconfiguracion varchar(100) not null, /* clave única de configuración */
	valorconfiguracion varchar(max), /* valor de la configuración */
	descripcion nvarchar(500), /* descripción de la configuración */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

/* NUEVA TABLA: Catálogo de tipos de comisión */
create table tbtipocomision
(
	id smallint identity primary key, /* identificador unico */
	tipocomision varchar(50) not null, /* nombre del tipo: Porcentaje, MontoFijo */
	codigo varchar(20) not null, /* código: PERCENTAGE, FIXED_AMOUNT */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbzonacobertura /* contiene el catalogo de zonas de cobertura (Ejemplo: Reynosa, Zona Conurbada, etc) */
(
	id int identity primary key, /* identificador unico */
	nombrezona varchar(100), /* nombre de la zona de cobertura */
	descripcion varchar(1500), /* descripcion de la zona de cobertura */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	/* CAMPOS AGREGADOS PARA MEJORAS */
	latitudcentro varchar(50), /* latitud del centro de la zona de cobertura */
	longitudcentro varchar(50), /* longitud del centro de la zona de cobertura */
	radio_km decimal(10, 2), /* radio en kilómetros de la zona de cobertura */
	coordenadapoligono varchar(max) /* coordenadas del polígono que define la zona de cobertura (formato JSON) */
)

/* NUEVA TABLA: Comisión por zona de cobertura */
create table tbzonacoberturacomision
(
	id int identity primary key, /* identificador unico */
	idzonacobertura int foreign key references tbzonacobertura(id), /* identificador de la zona de cobertura */
	porcentajecomision decimal(5, 2) not null default 3.00, /* porcentaje de comisión para la zona (3% default) */
	idtipocomision smallint foreign key references tbtipocomision(id), /* identificador del tipo de comisión */
	comisionminima decimal(10, 2), /* monto mínimo de comisión */
	comisionmaxima decimal(10, 2), /* monto máximo de comisión */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbcompania /* catálogo de compañias */
(
	id smallint identity primary key, /* identificador unico */
	companianombre varchar(50) not null, /* nombre de la compañia */
	pagocontarjetaactivo bit default 0, /* flag que indica si el pago con tarjeta esta activo (true) o no (false) */
	versionpasajeroandroid varchar(100), /* contiene el dato de la version de la app vaia pasajero publicada en google play de android Ej. 1.0.1 */
	versionconductorandroid varchar(100), /* contiene el dato de la version de la app vaia conductor publicada en google play de android Ej. 1.0.1 */
	kmsalaredondamascercanos int, /* kilometros a la redonda que tomara la app para dar un servicio a un pasajero de acuerdo a su origen de inicio, es decir desde donde solicita calcula los kilometros a la redonda y busca unidades disponibles */
	segesperatomaservicio int, /* limite de segundos para que un servicio pueda ser tomado por un conductor */
	segesperasalgapasajero int, /* limite de segundos de espera a que un pasajero aborde a la unidad una vez llego a recogerlo */
	nounidadesmascercanas int, /* número de unidades mas cercanas que va a enviar el servicio */
	sololaunidadmascercana bit default 0, /* flag que indica en caso que sea true que solo se enviara de uno por uno a la unidad mas cercana y en caso que sea false se envia a todas las unidades mas cercanas al mismo tiempo */
	paypalactivo bit default 0, /* flag que indica si esta activo el pago con paypal (true) o si no (false) */
	mercadopagoactivo bit default 0, /* flag que indica si esta activo el pago con mercado pago (true) o si no (false) */
	minsparapagopaypal int default 3, /* limite de minutos para pago con paypal */
	minsparapagomercadopago int default 3, /* limite de minutos para pago con mercado pago */
	androidgoogleapihablitado bit default 0, /* uso de api de google habilitado para android (se usa en ocasiones para reduccion de costos) */
	iosgoogleapihablitado bit default 0, /* uso de api de google habilitado para IOs (se usa en ocasiones para reduccion de costos) */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbusuario /* usuarios que accesaran a la plataforma web */
(
	id int identity primary key, /* identificador unico */
	idcompania smallint foreign key references tbcompania(id), /* identificador de la compañia */
	fotoperfil varchar(max) default '', /* imagen en base 64 de la foto de perfil del usuario */
	nombre varchar(50) not null, /* nombre(s) del usuario */
	appaterno varchar(50) not null, /* apellido paterno del usuario */
	apmaterno varchar(50) not null, /* apellido materno del usuario */
	sexo char(1) not null, /* sexo (M = masculino o F = Femenino) */
	idrol smallint foreign key references tbrol(id), /* identificador del rol de usuario */
	correo varchar(100) not null, /* correo del usuario */
	telefono varchar(30) not null, /* teléfono del usuario */
	account varchar(50) not null, /* cuenta de usuario */
	pass varchar(8000) not null, /* contraseña de la cuenta de usuario */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate(), /* ultima fecha en que se actualizó el registro */
	esusuariopropietario bit default 0, /* flag para identificar si es propietario */
	puedeveratodoconductor bit default 0 /* flag para ver a todos los conductores */
)

/* NUEVA TABLA: Gestión centralizada de sesiones de usuario */
create table tbsesionusuario
(
	id bigint identity primary key, /* identificador unico */
	idtipousuario tinyint not null, /* 1=Pasajero, 2=Conductor, 3=UsuarioWeb */
	idpasajero bigint, /* identificador del pasajero (si aplica) */
	idconductor int, /* identificador del conductor (si aplica) */
	idusuario int, /* identificador del usuario web (si aplica) */
	uuidsesion varchar(1500) not null, /* identificador único de sesión */
	fechaconexion datetime not null default getdate(), /* fecha de inicio de sesión */
	fechadesconexion datetime, /* fecha de cierre de sesión */
	activo bit default 1, /* flag que indica si la sesión sigue activa */
	dispositivoinfo varchar(500), /* información del dispositivo */
	sistemaoperativo varchar(100), /* sistema operativo del dispositivo */
	ipaddress varchar(50), /* dirección IP desde donde se conectó */
	useragent varchar(500), /* user agent del dispositivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

/* NUEVA TABLA: Historial de inicio de sesión con Google */
create table tbsocialloginhistory
(
	id bigint identity primary key, /* identificador unico */
	idtipousuario tinyint not null, /* 1=Pasajero, 2=Conductor */
	idpasajero bigint, /* identificador del pasajero (si aplica) */
	idconductor int, /* identificador del conductor (si aplica) */
	googleuserid varchar(255) not null, /* ID de usuario de Google */
	correo varchar(100) not null, /* correo del usuario */
	nombrecompleto varchar(200), /* nombre completo del usuario */
	foto_perfil_url varchar(1000), /* URL de la foto de perfil de Google */
	provider varchar(50) default 'google', /* proveedor de autenticación */
	fechalogin datetime default getdate(), /* fecha del inicio de sesión */
	ipaddress varchar(50), /* dirección IP desde donde se conectó */
	useragent varchar(500) /* user agent del dispositivo */
)

create table tbunidad /* unidades registradas por los conductores */
(
	id int identity primary key, /* identificador unico */
	unidad varchar(50) not null, /* nombre de la unidad */
	alias varchar(50), /* alias de la unidad */
	modelo int not null, /* modelo de la unidad (Ej.: 2026, 2027...) */
	aniofabricacion int, /* año de fabricación de la unidad */
	colorhex varchar(30) not null, /* color en hexadecimal */
	colornombre varchar(50) not null, /* nombre del color */
	numeroasientos tinyint not null, /* numero de asientos que puede cubrir la unidad */
	capacidadmaxima tinyint, /* capacidad máxima de pasajeros */
	segurovigente bit default 0, /* flag que indica si el seguro está vigente */
	fechavigenciaseguro datetime, /* fecha de vencimiento del seguro */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate(), /* ultima fecha en que se actualizó el registro */
	idtipocombustible int foreign key references tbtipocombustible(id), /* identificador del tipo de combustible */
	idtransmision int foreign key references tbtransmision(id), /* identificador de la transmisión */
	idsubmarca int foreign key references tbsubmarca(id), /* identificador de la submarca / linea de la unidad */
	placas varchar(100), /* placas de la unidad */
	noserie varchar(100) /* número de serie de la unidad */
)

/* NUEVA TABLA: Mantenimiento de unidades */
create table tbmantenimientounidad
(
	id int identity primary key, /* identificador unico */
	idunidad int foreign key references tbunidad(id), /* identificador de la unidad */
	fechamantenimiento datetime not null, /* fecha del mantenimiento */
	proximomantenimiento datetime, /* fecha del próximo mantenimiento programado */
	kilometraje int, /* kilometraje al momento del mantenimiento */
	tipomantenimiento varchar(100), /* tipo de mantenimiento realizado */
	descripcion varchar(500), /* descripción del mantenimiento */
	costo decimal(10, 2), /* costo del mantenimiento */
	proveedor varchar(200), /* proveedor que realizó el mantenimiento */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbappviajecostos /* configuracion de costos de la unidad para los viajes las 24 hrs del dia */
(
	id int identity primary key, /* identificador unico */
	idcompania smallint foreign key references tbcompania(id), /* identificador de la compañia */
	costominimo decimal(10, 2) not null, /* Costo minimo de un viaje a realizar */
	costoporkm decimal(10, 2) not null, /* costo por kilometro que se adicionara al costo minimo */
	costoporminuto decimal(10, 2) default 1, /* costo por minuto que se adicionara al costo minimo */
	horainicio time(7) not null, /* hora de inicio (Ej. 05:00) */
	horafin time(7) not null, /* hora de inicio (Ej. 23:00) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	numdiasemana tinyint default 1 /*  */
)

create table tbavisosapp /*  */
(
	id int identity primary key, /* identificador unico */
	idcompania smallint foreign key references tbcompania(id), /* identificador de la compañia */
	esavisopasajero bit default 0, /* flag que indica si es un aviso a enviar a pasajero (true) o si no (false) */
	esavisoconductor bit default 0, /* flag que indica si es un aviso a enviar a conductor (true) o si no (false) */
	tituloaviso varchar(50) not null, /* nombre del titulo del aviso */
	descripcionaviso nvarchar(300) not null, /* texto descriptivo de el aviso a enviar a usuarios */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

/* NUEVA TABLA: Gestión de notificaciones push */
create table tbnotificacionpush
(
	id int identity primary key, /* identificador unico */
	titulo nvarchar(200) not null, /* título de la notificación */
	mensaje nvarchar(500) not null, /* mensaje de la notificación */
	tipoaudiencia varchar(50) not null, /* tipo: TODOS_PASAJEROS, TODOS_CONDUCTORES, PASAJERO_ESPECIFICO, CONDUCTOR_ESPECIFICO */
	idpasajero bigint, /* pasajero específico (si aplica) */
	idconductor int, /* conductor específico (si aplica) */
	fechaprogramada datetime, /* fecha programada para envío */
	fechaenvio datetime, /* fecha real de envío */
	enviado bit default 0, /* flag que indica si ya fue enviada */
	error_envio varchar(max), /* error en caso de fallo */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

/* NUEVA TABLA: Historial de notificaciones push enviadas */
create table tbnotificacionpushenviada
(
	id bigint identity primary key, /* identificador unico */
	idnotificacionpush int foreign key references tbnotificacionpush(id), /* identificador de la notificación */
	idtipousuario tinyint not null, /* 1=Pasajero, 2=Conductor */
	idpasajero bigint, /* pasajero que recibió la notificación */
	idconductor int, /* conductor que recibió la notificación */
	fechaenvio datetime default getdate(), /* fecha de envío */
	googlekey varchar(max), /* google key utilizada para el envío */
	respuestaenvio varchar(max) /* respuesta del servicio de notificaciones */
)

create table tbpasajero /*  */
(
	id bigint identity primary key, /* identificador unico */
	idcompania smallint foreign key references tbcompania(id), /* identificador de la compañia */
	fotoperfil varchar(max) default '', /* imagen en base 64 de la foto de perfil del usuario */
	nombre varchar(50) not null, /* nombre(s) del pasajero */
	appaterno varchar(50) not null, /* apellido paterno del pasajero */
	apmaterno varchar(50) not null, /* apellido materno del pasajero */
	correo varchar(100) not null, /* correo electronico del pasajero */
	correoconfirmado bit default 0, /* flag que indica si el correo ya se confirmo (true) o si no (false), esto al abrir un correo electronico que se le envia al registrarse */
	codigopaistel varchar(15) default '+52',  /* es el prefijo del telefono a 10 digitos del pasajero, ejemplo +52 para Mexico o +1 para Estados Unidos */
	telefono varchar(30) not null, /* telefono a 10 digitos del pasajero */
	telefonoconfirmado bit default 0, /* flag que indica si el numero de telefono ya se confirmo (true) o si no (false), se confirma al ingresar codigo enviado a Whatsapp del usuario pasajero */
	googlekey varchar(max) not null, /* llave de google que usamos para el envio de notificaciones a usuarios pasajero */
	account varchar(50) not null, /* cuenta de usuario pasajero */
	pass varchar(8000) not null, /* contraseña que usara el usuario pasajero para ingresar a la aplicacion */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	ultimaactualizacion datetime default getdate(), /* ultima fecha en que se actualizó el registro */
	bloqueado bit default 0, /* flag que indica si la cuenta se usuario de bloqueo (true) o si no (false), este bloqueo lo realizaran los administradores en el portal de Vaia Viajes Admin */
	requierefacturacion bit default 0, /* Flag que indica si el usuario requiere facturación de su servicio (true) o si no (false) */
	ultimalatconsultada varchar(100), /* es la ultima latitud de la ubicación que consulto el pasajero para un servicio */
	ultimalngconsultada varchar(100), /* es la ultima longitud de la ubicación que consulto el pasajero para un servicio */
	conectado bit, /* flag que indica si el usuario esta conectado (true) o si no (false) */
	ultimaconexionusr datetime, /* es la fecha de la ultima conexion que realizo el usuario, es decir la ultima vez que abrio su aplicacionde pasajero para solicitar un servicio */
	ultimadesconexionusr datetime, /* es la fecha de la ultima desconexion que realizo el usuario, es decir la ultima vez que cerro su sesion en la aplicacion de pasajero */
	googlekeyso varchar(100), /* sistema operativo en el cual esta conectado el usuario, el ultimo desde donde inicio sesion. con este indicamos si es una google key para notificaciones push para android o IOs */
	correosuscrito bit default 1, /* flag que indica si el usuario registrado desea continuar recibiendo promociones en su correo (true) o si no (false) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	
	/* CAMPOS AGREGADOS PARA AUTENTICACIÓN CON GOOGLE */
	googleuserid varchar(255), /* ID único de usuario de Google (para login social) */
	fotourlgoogle varchar(1000), /* URL de la foto de perfil de Google (si se usa login social) */
	eslogueadocongoogle bit default 0, /* flag que indica si la cuenta fue creada/logueada con Google */
	
	/* CAMPOS AGREGADOS PARA MEJORAS */
	metodopagopreferido smallint foreign key references tbmetodopago(id), /* método de pago preferido del pasajero */
	idiomapreferido smallint foreign key references tbidioma(id), /* idioma preferido del usuario */
	fechanacimiento date, /* fecha de nacimiento del pasajero */
	genero char(1), /* género del pasajero (M/F/O) */
	notasadicionales varchar(500) /* notas adicionales sobre el pasajero */
)

create table tbpasajerosbloqueados /* registro historico de pasajeros bloqueados con su motivo de bloqueo */
(
	codigopaistel varchar(15) default '+52',  /* es el prefijo del telefono a 10 digitos del pasajero, ejemplo +52 para Mexico o +1 para Estados Unidos */
	notelefono varchar(100), /* telefono a 10 digitos del usuario */
	motivobloqueo varchar(1500), /* descripcion del motivo o razon por el que se bloqueo la cuenta de pasajero */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

/* NUEVA TABLA: Auditoría de acciones importantes en el sistema */
create table tbauditoria
(
	id bigint identity primary key, /* identificador unico */
	tablaafectada varchar(100) not null, /* nombre de la tabla afectada */
	idregistro varchar(50) not null, /* ID del registro afectado */
	accion varchar(20) not null, /* acción realizada: INSERT, UPDATE, DELETE, LOGIN, LOGOUT */
	idusuario int, /* usuario que realizó la acción (si es desde web) */
	idpasajero bigint, /* pasajero que realizó la acción (si aplica) */
	idconductor int, /* conductor que realizó la acción (si aplica) */
	campoafectado varchar(100), /* campo específico afectado */
	valorantes varchar(max), /* valor antes del cambio */
	valordespués varchar(max), /* valor después del cambio */
	ipaddress varchar(50), /* dirección IP desde donde se realizó la acción */
	useragent varchar(500), /* user agent del dispositivo */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbcodigospromo /* contiene los codigos de promocion que los administradores registran para descuentos a pasajeros */
(
	id int identity primary key, /* identificador unico */
	codigopromocional varchar(100), /* codigo promocional que debera ingresar el usuario en el aplicativo para  */
	vigentehasta datetime, /* fecha limite de la vigencia en que el codigo puede utilizarse, posterior a esta fecha y hora el codigo ya no es valido */
	decripcionpromo varchar(1500), /* descripcion de la promoción que se le brinda al pasajero */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	esporcentaje bit default 0, /* indica si el monto de la promocion, es decir el descuento si es porcentual (true) o si es por cantidad (false) */
	montodecuento decimal(18, 2), /* monto que se usara para calcular el descuento a brindar ya sea porcentual o en monto dependiendo el flag de esporcentaje */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	/* CAMPOS AGREGADOS PARA MEJORAS */
	usosmaximos int default 0, /* número máximo de usos permitidos (0 = ilimitado) */
	usosactuales int default 0, /* número de usos actuales del código */
	montominimoviaje decimal(10, 2), /* monto mínimo del viaje para aplicar el código */
	usuariounicopasajero bigint, /* permite que solo un pasajero específico use el código */
	descripcionpublica nvarchar(500), /* descripción pública para mostrar en la app */
	validodesde datetime default getdate() /* fecha desde la cual es válido el código */
)

create table tbestatusdocumentacion /* contiene el catalogo de estatus de documentacion */
(
	id int identity primary key, /* identificador unico */
	nombreestatusdocs varchar(100), /* nombre del estatus de documentacion */
	descripcion varchar(1500), /* descripcion del estatus de la documentacion */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbconductor /* contiene los conductores registrados para el uso de la aplicación */
(
	id int identity primary key, /* identificador unico */
	idcompania smallint foreign key references tbcompania(id), /* identificador de la compañia */
	idzonacobertura int foreign key references tbzonacobertura(id), /* identificador de la zona de cobertura */
	fotoperfil varchar(max) default '', /* imagen en base 64 de la foto de perfil del usuario */
	nombre varchar(50) not null, /* nombre(s) del conductor */
	appaterno varchar(50) not null, /* apellido paterno del conductor */
	apmaterno varchar(50) not null, /* apellido materno del conductor */
	idconductorestatus smallint foreign key references tbconductorestatus(id), /* identificador del estatus del conductor */
	sexo char(1) not null, /* sexo (M = masculino o F = Femenino) */
	correo varchar(100) not null, /* correo del conductor */
	telefono varchar(30) not null, /* teléfono del conductor */
	telefonoconfirmado bit default 0, /* flag que indica si el numero de telefono ya se confirmo (true) o si no (false), se confirma al ingresar codigo enviado a Whatsapp del usuario conductor */
	googlekey varchar(max) not null, /* llave de google que usamos para el envio de notificaciones a usuarios conductor */
	account varchar(50) not null, /* cuenta de usuario conductor */
	pass varchar(8000) not null, /* contraseña que usara el usuario conductor para ingresar a la aplicacion */
	ultimaactualizacion datetime default getdate(), /* ultima fecha en que se actualizó el registro */
	idestatusdocumentacion int foreign key references tbestatusdocumentacion(id), /* identificador del estatus de la documentación */
	documentacionaprobada bit default 0, /* flag que indica que toda la documentacion fue aprobada (true / 1), rechazada (false / 0) o pendiente (null) */
	fechadocumentacionvalidada datetime, /* fecha y hora en que se realizo la validacion de la documentacion */
	idusuariovalido int foreign key references tbusuario(id), /* identificaro unico del usuario que valido la documentación del usuario, esto lo realiza desde la web un administrador */ 
	bloqueado bit default 0, /* flag que indica si la cuenta se usuario de bloqueo (true) o si no (false), este bloqueo lo realizaran los administradores en el portal de Vaia Viajes Admin */
	curp varchar(50), /* CURP capturada del conductor, debe ser unica e irrepetible */
	rfc varchar(50), /* RFC capturada del conductor */
	claveelector varchar(50), /* Clave de elector capturada del conductor */
	banco varchar(100), /* Nombre del banco al que pertenece la cuenta del conductor a donde se transferiran sus ganancias por tarjeta */
	nombretitular varchar(150), /* Nombre del titular al que pertenece la cuenta bancaria del conductor a donde se transferiran sus ganancias por tarjeta */
	clabeinterbancaria varchar(150), /* Clabe interbancaria al que pertenece la cuenta del conductor a donde se transferiran sus ganancias por tarjeta */
	conectado bit, /* flag que indica si el usuario esta conectado (true) o si no (false) */
	ultimaconexionusr datetime, /* es la fecha de la ultima conexion que realizo el usuario, es decir la ultima vez que abrio su aplicacionde conductor para solicitar un servicio */
	ultimadesconexionusr datetime, /* es la fecha de la ultima desconexion que realizo el usuario, es decir la ultima vez que cerro su sesion en la aplicacion de conductor */
	googlekeyso varchar(100), /* sistema operativo en el cual esta conectado el usuario, el ultimo desde donde inicio sesion. con este indicamos si es una google key para notificaciones push para android o IOs */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	
	/* CAMPOS AGREGADOS PARA AUTENTICACIÓN CON GOOGLE */
	googleuserid varchar(255), /* ID único de usuario de Google (para login social) */
	fotourlgoogle varchar(1000), /* URL de la foto de perfil de Google (si se usa login social) */
	eslogueadocongoogle bit default 0, /* flag que indica si la cuenta fue creada/logueada con Google */
	
	/* CAMPOS AGREGADOS PARA MEJORAS */
	idiomapreferido smallint foreign key references tbidioma(id), /* idioma preferido del conductor */
	fechanacimiento date, /* fecha de nacimiento del conductor */
	licenciaconducir varchar(50), /* número de licencia de conducir */
	fechavencimientolicencia datetime, /* fecha de vencimiento de la licencia */
	tipolicencia varchar(20), /* tipo de licencia (A, B, C, etc) */
	notasadicionales varchar(500) /* notas adicionales sobre el conductor */
)

/* NUEVA TABLA: Bonificaciones para conductores */
create table tbbonoconductor
(
	id int identity primary key, /* identificador unico */
	idconductor int foreign key references tbconductor(id), /* identificador del conductor */
	descripcion nvarchar(500) not null, /* descripción de la bonificación */
	monto decimal(10, 2) not null, /* monto de la bonificación */
	fechaotorgada datetime default getdate(), /* fecha en que se otorgó la bonificación */
	idservicio bigint, /* servicio que generó la bonificación (si aplica) */
	motivo varchar(100), /* motivo de la bonificación */
	fechapago datetime, /* fecha en que se pagó la bonificación */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbusuariozonascobertura /* contiene la relacion entre el usuario y las zonas de cobertura que tiene asignado y permiso de visualizar */
(
	idusuario int foreign key references tbusuario(id), /* identificador del usuario */
	idzonacobertura int foreign key references tbzonacobertura(id), /* identificador de la zona de cobertura */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbpasajerocodigos /* Contiene los codigos enviardos por whatsapp para la confirmacion de su telefono para la app de pasajero */
(
	codigopaistel varchar(15) default '+52',  /* es el prefijo del telefono a 10 digitos del pasajero, ejemplo +52 para Mexico o +1 para Estados Unidos */
	notelefono varchar(50), /* telefono a 10 digitos del usuario pasajero */
	codigoverificacion varchar(50), /* codigo enviado por whatsapp a pasajero para confirmacion de su correo (Ejemplo 345637) */
	fechalimiteexpira datetime, /* fecha y hora limite en que expira el codigo y puede ser utilizado para confirmar el numero de telefono */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado), si esta inactivo equivale a haber expirado */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbconductorcodigos /* Contiene los codigos enviardos por whatsapp para la confirmacion de su telefono para la app de conductor */
(
	codigopaistel varchar(15) default '+52',  /* es el prefijo del telefono a 10 digitos del conductor, ejemplo +52 para Mexico o +1 para Estados Unidos */
	notelefono varchar(50), /* telefono a 10 digitos del usuario conductor */
	codigoverificacion varchar(50), /* codigo enviado por whatsapp a conductor para confirmacion de su correo (Ejemplo 345637) */
	fechalimiteexpira datetime, /* fecha y hora limite en que expira el codigo y puede ser utilizado para confirmar el numero de telefono */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado), si esta inactivo equivale a haber expirado */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbpasajerodocumentos /* archivo o documentos que el pasajero ha registrado en sistema */
(
	id int identity primary key, /* identificador unico */
	idpasajero bigint foreign key references tbpasajero(id), /* identificador unico del pasajero */
	idfile bigint not null, /* identificador unico del archivo */
	tokenidfile varchar(max) not null, /* identificador unico tipo token el cual e suna llave unica que relaciona el archivo, es el equivalente a idfile pero encriptado */
	idtipoarchivo smallint foreign key references tbtipoarchivo(id), /* identificador del tipo de archivo que se da de alta */
	nombredocumento varchar(500) not null, /* nombre del archivo o documento que se registra */
	comentarios varchar(1500) not null, /* comentarios adicionales sobre el documento registrado */
	idusuariocreo int foreign key references tbusuario(id), /* identificaro unico del usuario que registro el documento, en caso fuera desde la web de vaia admin */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbconductordocumentos /* archivo o documentos que el conductor ha registrado en sistema */
(
	id int identity primary key, /* identificador unico */
	idconductor int foreign key references tbconductor(id), /* identificador del conductor */
	idfile bigint not null, /* identificador unico del archivo */
	tokenidfile varchar(max) not null, /* identificador unico tipo token el cual e suna llave unica que relaciona el archivo, es el equivalente a idfile pero encriptado */
	idtipoarchivo smallint foreign key references tbtipoarchivo(id), /* identificador del tipo de archivo que se da de alta */
	nombredocumento varchar(500) not null, /* nombre del archivo o documento que se registra */
	comentarios varchar(1500) not null, /* comentarios adicionales sobre el documento registrado */
	idusuariocreo int foreign key references tbusuario(id), /* identificaro unico del usuario que registro el documento, en caso fuera desde la web de vaia admin */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	validado bit default 0, /* flag que indica si los administradores validaron el documento que se registro (true = validado o false = sin validar) */
	encorreccion bit default 0, /* flag que indica si los administradores solicitaron una corrección (true = requiere correccion o false = no la requiere) */
	comentariocorreccion varchar(max) default '', /* comentarios anexados a la corrección solicitada */
	enrevision bit default 1 /* flag que indica si el documento se encuentra en revisión (true = esta en revisión o false = no esta en revision) */
)

create table tbconductorgps /* contiene las ubicaciones que a registrado el conductor */
(
	idconductor int foreign key references tbconductor(id), /* identificador del conductor */
	lat varchar(50) not null, /* latitud de la ubicación del conductor */
	lng varchar(50) not null, /* longitud de la ubicación del conductor */
	lastposition datetime not null, /* ultima fecha de la ubicacion del conductor */
	previouslat varchar(50) not null, /* latitud previa a la ultima reportada de la ubicación del conductor */
	previouslng varchar(50) not null, /* longitud previa a la ultima reportada de la ubicación del conductor */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbconductorgpshistory /* historial de ubicaciones gps registradas del conductor */
(
	idconductor int foreign key references tbconductor(id), /* identificador del conductor */
	lat varchar(50) not null, /* latitud de la ubicación del conductor */
	lng varchar(50) not null, /* longitud de la ubicación del conductor */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	idconductorestatus smallint foreign key references tbconductorestatus(id) /* identificador del estatus del conductor */
)

create table tbpasajerohistorialcambiotelefono /* registro historico de el cambio de telefono de una cuenta de pasajero */
(
	idpasajero bigint foreign key references tbpasajero(id), /* identificador unico del pasajero */
	codigopaistel varchar(15) default '+52',  /* es el prefijo del telefono a 10 digitos del pasajero, ejemplo +52 para Mexico o +1 para Estados Unidos */
	telefonodadodebaja varchar(100), /* telefono a 10 digitos del usuario */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbconductorhistorialcambiotelefono /* registro historico de el cambio de telefono de una cuenta de conductor */
(
	idconductor int foreign key references tbconductor(id), /* identificador del conductor */
	codigopaistel varchar(15) default '+52',  /* es el prefijo del telefono a 10 digitos del conductor, ejemplo +52 para Mexico o +1 para Estados Unidos */
	telefonodadodebaja varchar(100), /* telefono a 10 digitos del usuario */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbconductorunidades /* contiena la relacion de unidades ligadas a un conductor */
(
	idconductor int foreign key references tbconductor(id), /* identificador del conductor */
	idunidad int foreign key references tbunidad(id), /* identificador de la unidad */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate(), /* ultima fecha en que se actualizó el registro */
	aprobada bit default 0, /* flag para indicar si la unidad ya fue aprobada y puede usarse o si no */
	proximavalidacion datetime, /* fecha de proxima validacion necesaria a realizar, a partir de la validacion se dan seis meses mas a partir de la fecha actual */
	enuso bit default 1 /* flag que indica si la cuenta de conductor ya esta usando una unidad, ya que solo puede utilizar una a la vez cuando el conductor esta conectado */
)

create table tbconductorunidadesdocumentos /* documentos de las unidades del conductor que pasan por validacion */
(
	id int identity primary key, /* identificador unico */
	idconductor int foreign key references tbconductor(id), /* identificador del conductor */
	idunidad int foreign key references tbunidad(id), /* identificador de la unidad */
	idfile bigint not null, /* identificador unico del archivo */
	tokenidfile varchar(max) not null, /* identificador unico tipo token el cual e suna llave unica que relaciona el archivo, es el equivalente a idfile pero encriptado */
	idtipoarchivounidad smallint foreign key references tbtipoarchivounidad(id), /* identificador del tipo de archivo de unidad que se da de alta */
	nombredocumento varchar(500) not null, /* nombre del archivo o documento que se registra */
	comentarios varchar(1500) not null, /* comentarios adicionales sobre el documento registrado */
	idusuariocreo int foreign key references tbusuario(id), /* identificaro unico del usuario que registro el documento, en caso fuera desde la web de vaia admin */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	validado bit default 0, /* flag que indica si los administradores validaron el documento que se registro (true = validado o false = sin validar) */
	encorreccion bit default 0, /* flag que indica si los administradores solicitaron una corrección (true = requiere correccion o false = no la requiere) */
	comentariocorreccion varchar(max) default '', /* comentarios anexados a la corrección solicitada */
	enrevision bit default 1 /* flag que indica si el documento se encuentra en revisión (true = esta en revisión o false = no esta en revision) */
)

create table tbestatusfacturacion /* catalogo de estatus de facturacion */
(
	id int identity primary key, /* identificador unico */
	nombreestatus varchar(300), /* nombre del estatus de la facturacion */
	descripcion varchar(500), /* descripcion del estatus de la facturacion */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbestatusincidente /* catalogo de estatus de incidente */
(
	id int identity primary key, /* identificador unico */
	nombreestatus varchar(300), /* nombre del estatus del incidente */
	descripcion varchar(500), /* descripcion del estatus del incidente */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

/* NUEVA TABLA: Catálogo de estatus de pago */
create table tbestatuspago
(
	id smallint identity primary key, /* identificador unico */
	nombreestatus varchar(50) not null, /* nombre del estatus: Pendiente, Pagado, Fallido, Reembolsado */
	codigo varchar(20) not null, /* código: PENDING, PAID, FAILED, REFUNDED */
	descripcion varchar(200), /* descripción del estatus */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

/* NUEVA TABLA: Pagos realizados */
create table tbpago
(
	id bigint identity primary key, /* identificador unico */
	idservicio bigint not null, /* identificador del servicio */
	idusuario int, /* usuario que realizó el pago (desde web) */
	idpasajero bigint, /* pasajero que realizó el pago */
	monto decimal(18, 2) not null, /* monto total del pago */
	montoimpuestos decimal(18, 2) default 0, /* monto de impuestos */
	montodescuento decimal(18, 2) default 0, /* monto de descuento aplicado */
	montonetopagar decimal(18, 2), /* monto neto a pagar (total - descuento + impuestos) */
	idmetodopago smallint foreign key references tbmetodopago(id), /* identificador del método de pago */
	idestatuspago smallint foreign key references tbestatuspago(id), /* identificador del estatus del pago */
	referenciapago varchar(200), /* referencia de la transacción */
	fechapago datetime, /* fecha en que se realizó el pago */
	fechacancelacion datetime, /* fecha de cancelación del pago */
	comprobante varchar(max), /* comprobante de pago (ej. PDF en base64 o URL) */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbfacturaconfiguracion /* contiene las configuraciones de la facturacion de un pasajero */
(
	id int identity primary key, /* identificador unico */
	idpasajero bigint foreign key references tbpasajero(id), /* identificador unico del pasajero */
	rfcfacturacion varchar(100), /* RFC para facturar a pasajero */
	correofacturacion varchar(100), /* correo electronico para la facturacion */
	cifbase64 varchar(max), /* archivo en base 64 de la constancia de situacion fiscal CIF */
	idestatusfacturacion int foreign key references tbestatusfacturacion(id), /* identificador del estatus de la facturacion */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbfavoritos /* contiene los sitios favoritos de un pasajero */
(
	id int identity primary key, /* identificador unico */
	idpasajero bigint foreign key references tbpasajero(id), /* identificador unico del pasajero */
	favoritonombre varchar(50) not null, /* nombre del sitio favorito almacenado */
	direccionfavorito varchar(350), /* dirección del sitio favorito almacenado */
	lat varchar(50) not null, /* latitud de la ubicación del sitio favorito */
	lng varchar(50) not null, /* longitud de la ubicación del sitio favorito */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbhistorialnotificaconductor /* historial de notificaciondes de un conductor */
(
	idconductor int foreign key references tbconductor(id), /* identificador del conductor */
	mensajeenviado nvarchar(max), /* mensaje enviado por notificacion a un conductor */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	idusuarioenvio int /* identificador del usuario */
)

create table tbhistorialconexionespasajero /* contiene el historial de conexiones del pasajero */
(
	idpasajero bigint foreign key references tbpasajero(id), /* identificador unico del pasajero */
	conectado bit default 0, /* flag de estatus de conectado (1) o desconectado (0) */
	fechaconexion datetime default getdate() /* fecha de conexion o desconexion registrada */
)

create table tbhistorialconexionesconductor /* contiene el historial de conexiones del conductor */
(
	idconductor int foreign key references tbconductor(id), /* identificador del conductor */
	conectado bit default 0, /* flag de estatus de conectado (1) o desconectado (0) */
	fechaconexion datetime default getdate() /* fecha de conexion o desconexion registrada */
)

create table tbhistoriallatlngconsultadapasajero /* contiene el historial de ubicaciones consultadas por el pasajero para metricas y deteccion de zonas con mas servicios */
(
	idpasajero bigint foreign key references tbpasajero(id), /* identificador unico del pasajero */
	lat varchar(100), /* latitud en ubicación */
	lng varchar(100), /* longitud en ubicación */
	fechaconsulta datetime default getdate() /* fecha de consulta del pasajero */
)

create table tbmenu /* opciones de menu de portal web */
(
	id smallint identity primary key, /* identificador unico */
	optionnombre varchar(100) not null, /* nombre de la opcion de menu */
	esheader bit default 1, /* flag para indicar si es una opcion de encabezado, es decir que contiene mas opciones dentro o si no (false) */
	idparentmenu int, /* identificador de la tabla tbmenu columna id del parent de la opcion */
	urllink varchar(500) not null, /* url que abrira al dar click en la opcion del menu */
	iconclass varchar(100) default 'metismenu-icon pe-7s-browser', /* clase del atributo html class que se le colocara para que cargue el icono */
	ordernumber smallint not null, /* orden numerico para ordenar las opciones */
	target varchar(100) default 'rightcontent', /* atributo a manejar de la opcion (_blank, right) Ej. target="_blank" */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	idusuariocreo int foreign key references tbusuario(id), /* identificaro unico del usuario que registro el documento, en caso fuera desde la web de vaia admin */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbplantillascorreohtml /* contiene las plantillas html de los correos a enviar */
(
	id int identity primary key, /* identificador unico */
	nombreplantilla nvarchar(50) not null, /* nombre unico de la plantilla a utilizar */
	descripcionplantilla nvarchar(500) not null, /* descipcion de la plantilla a utilizar */
	codigohtml nvarchar(max), /* contiene el html de la plantilla a utilizar */
	activo bit default 1 /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
)

create table tbpromociones /* contiene las promociones que registran los administradores para la app de pasajero vaia viajes */
(
	id int identity primary key, /* identificador unico */
	titulopublicidad nvarchar(1500), /* nombre de titulo a utilizar en la promocion */
	imgbase64 varchar(max), /* archivo en base 64 de la promocion */
	iniciovigenciapromocion datetime, /* inicio de vigencia de la promocion */
	finvigenciapromocion datetime, /* fin o fecha limite de vigencia de la promocion */
	asuntocorreo nvarchar(max), /* cuerpo del correo a enviar de la promoción */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbpropagandas /* contiene las propagandas que registran los administradores para la app de pasajero vaia viajes */
(
	id int identity primary key, /* identificador unico */
	titulopropaganda nvarchar(1500), /* nombre de titulo a utilizar en la propaganda */
	imgbase64 varchar(max), /* archivo en base 64 de la propaganda */
	asuntocorreo nvarchar(1500), /* cuerpo del correo a enviar de la propaganda */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbrolmenudefault /* menu predeterminado relacionado al rol, la configuracion se usa para cuando se edite o cree un usuario se le asignen estos permisos predeterminados */
(
	idrol smallint foreign key references tbrol(id), /* identificador del rol del usuario */
	idmenu smallint foreign key references tbmenu(id), /* identificador de la opcion del menu */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

/* NUEVA TABLA: Catálogo de estatus de corte semanal */
create table tbcortesemanasemanalestatus
(
	id smallint identity primary key, /* identificador unico */
	nombreestatus varchar(50) not null, /* nombre del estatus: Pendiente, EnProceso, Completado, Pagado */
	descripcion varchar(200), /* descripción del estatus */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

/* NUEVA TABLA: Cortes semanales */
create table tbcortesemanasemanal
(
	id bigint identity primary key, /* identificador unico */
	idconductor int foreign key references tbconductor(id), /* identificador del conductor */
	idzonacobertura int foreign key references tbzonacobertura(id), /* identificador de la zona de cobertura */
	semanainicio date not null, /* fecha de inicio de la semana del corte */
	semanafin date not null, /* fecha de fin de la semana del corte */
	totalviajes int default 0, /* número total de viajes en la semana */
	totalingresos decimal(18, 2) default 0, /* total de ingresos generados */
	totalcomision decimal(18, 2) default 0, /* total de comisión aplicada */
	totalcomisionporcentaje decimal(5, 2) default 3.00, /* porcentaje de comisión aplicado */
	totalnetoconductor decimal(18, 2) default 0, /* total neto para el conductor (ingresos - comisión) */
	idestatuscorte smallint foreign key references tbcortesemanasemanalestatus(id), /* identificador del estatus del corte */
	fechapagopendiente datetime, /* fecha estimada de pago */
	fechapagorealizado datetime, /* fecha real de pago */
	comprobantepago varchar(max), /* comprobante de pago en base64 o URL */
	comentarios nvarchar(500), /* comentarios adicionales sobre el corte */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

/* NUEVA TABLA: Detalle de cortes semanales (viajes individuales en el corte) */
create table tbcortesemanasemanaldetalle
(
	id bigint identity primary key, /* identificador unico */
	idcortesemanal bigint foreign key references tbcortesemanasemanal(id), /* identificador del corte */
	idservicio bigint not null, /* identificador del servicio incluido en el corte */
	monto decimal(18, 2) not null, /* monto del servicio */
	comisionaplicada decimal(18, 2) default 0, /* comisión aplicada a este servicio */
	porcentajecomision decimal(5, 2) default 3.00, /* porcentaje de comisión aplicado */
	netoconductor decimal(18, 2) not null, /* monto neto para el conductor */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbservicioestatus /* catalogo de estatus de un servicio */
(
	id smallint identity primary key, /* identificador unico */
	estatus varchar(30) not null, /* nombre del estatus del servicios */
	estatusdescription varchar(300) not null, /* descripcion del estatus del servicio */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

/* NUEVA TABLA: Rutas asignadas (para almacenar la ruta completa del viaje) */
create table tbrutaasignada
(
	id bigint identity primary key, /* identificador unico */
	idservicio bigint not null, /* identificador del servicio */
	polylineruta varchar(max), /* polyline de la ruta completa */
	puntosruta varchar(max), /* puntos de la ruta en formato JSON */
	distanciametros int, /* distancia total en metros */
	duracionsegundos int, /* duración estimada en segundos */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbusuariomenu /* contiene la relacion del menu de opciones que tiene relacionado el usuario */
(
	idusuario int foreign key references tbusuario(id), /* identificador del usuario */
	idmenu smallint foreign key references tbmenu(id), /* identificador de la opcion del menu */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbservicios /* contiene los servicios realizados por los pasajeros */
(
	id bigint identity primary key, /* identificador unico */
	idconductor int foreign key references tbconductor(id), /* identificador del conductor */
	idpasajero bigint not null, /* identificador del pasajero */
	idservicioestatus smallint, /* identificador del estatus de servicio */
	direccionorigen varchar(300) not null, /* dirección del origen de inicio del viaje */
	latorigen varchar(50) not null, /* latitud de la ubicación del origen de inicio de viaje */
	lngorigen varchar(50) not null, /* longitud de la ubicación del origen de inicio de viaje */
	direcciondestination varchar(300) not null, /* dirección del destino del viaje */
	latdestination varchar(50) not null, /* latitud de la ubicación del destino del viaje */
	lngdestination varchar(50) not null, /* longitud de la ubicación del destino del viaje */
	costoestimado decimal(18, 2) not null, /* costo estimado a pasajero del servicio */
	distanciametros int not null, /* distancia aproximada de recorrido en metros */
	idpago bigint, /* identificador del pago (ahora referencia a tbpago) */
	calificacion tinyint, /* calificacion del servicio que brindo el conductor */
	calificacionpasajero tinyint default 0, /* calificacion para el pasajero */
	comentarios varchar(500), /* comentarios del servicio que brindo el conductor */
	comentariocalificacionpasajero varchar(150) default '', /* comentarios de la calificacion que se le dio al pasajero */
	servicioiniciado bit default 0, /* flag para indicar si el servicio se inicio (true) o no (false), cambia a 1 o true cuando la unidad llega a sitio y da en iniciar viaje */
	llegoasudestino bit default 0, /* flag para indicar si el servicio llego a su destino (true) o no (false), cambia al detectar con el gps del dispositivo que se acerco a menos de 200 metros a la redonda del destino  */
	idtipopago smallint foreign key references tbtipopago(id), /* identificador del tipo de pago */
	llegoalorigen bit default 0, /* flag para indicar si el servicio llego a su origen (true) o no (false), cambia al detectar con el gps del dispositivo que se acerco a menos de 200 metros a la redonda del origen de inicio de viaje */
	alarmasospasajero bit default 0, /* flag que indica si se activo la alarma SOS desde la app del pasajero (1) o si no (0) */
	sesalioderuta bit default 0, /* flag que indica si se salio de la ruta inicial establecida del viaje el conductor (1) o si no (0) */
	seenviocomprobante bit default 0, /* flag que indica si se le envio el comprobante por correo del servicio al pasajero (1) o si no (0) */
	alarmasosconductor bit default 0, /* flag que indica si se activo la alarma SOS desde la app del conductor (1) o si no (0) */
	so varchar(100), /* sistema operativo de donde se solicito */
	durationsegundos int, /* duracion del servicio en segundos estimados */
	montodescuento decimal(18, 2), /* monto en cantidad del descuento en caso de haber un descuento */
	idcodigopromo int foreign key references tbcodigospromo(id), /* identificador de codigo promocional utilizado para el viaje en caso de haberlo usado */
	idunidad int foreign key references tbunidad(id), /* identificador de la unidad */
	fechasalioderuta datetime, /* fecha en que se detecto que salio de ruta el conductor */
	fechaservicioiniciado datetime, /* fecha en que se registro el inicio del servicio de viaje */
	fechallegoasudestino datetime, /* fecha en que se registro la llegada al destino del viaje */
	fechallegoalorigen datetime, /* fecha en que se registro la llegada al origen de inicio de viaje */
	fechaalarmasosconductor datetime, /* fecha en que se registro la alarma sos por parte del conductor */
	fechaalarmasospasajero datetime, /* fecha en que se registro la alarma sos por parte del pasajero */
	fechafinalizoconductor datetime, /* fecha en que finalizo el conductor el viaje */
	fechafinalizopasajero datetime, /* fecha en que finalizo el pasajero el viaje */
	orderidpaypal varchar(4000), /* identificador de la orden de paypal */
	motivocancelacion varchar(max), /* es el motivo por el cual se realizo la cancelacion */
	canceladopor varchar(15), /* almacena un texto que indica quien los cancelo: pasajero, conductor o administracion */
	fechacancelacion datetime, /* es la fecha y hora en que se cancelo el servicio en caso de que se cancele */
	reembolso bit, /* flag que indica si se realizo un reembolso del servicio */
	reembolsodate datetime, /* fecha en que se realiza el reembolso */
	reembolsomotivo varchar(1500), /* motivo o razon por la que se realiza un reembolso */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate(), /* ultima fecha en que se actualizó el registro */
	
	/* CAMPOS AGREGADOS PARA MEJORAS */
	gananciaconductor decimal(18, 2), /* ganancia del conductor por este viaje (ingreso - comisión) */
	comisionaplicada decimal(18, 2), /* comisión aplicada a este viaje */
	porcentajecomision decimal(5, 2) default 3.00, /* porcentaje de comisión aplicado */
	comisionexcepcion bit default 0, /* flag que indica si se aplicó una comisión excepcional */
	polylineruta varchar(max), /* polyline de la ruta completa (se mantiene por compatibilidad) */
	tipoviaje varchar(50) default 'URBANO', /* tipo de viaje: URBANO, INTERURBANO, AEROPUERTO, etc */
	tiempoesperaorigen int default 0, /* tiempo de espera en origen en segundos */
	tiempoesperadestino int default 0 /* tiempo de espera en destino en segundos */
)

create table tbserviciosconductoresnotificados /* contiene el listado de conductores que se les notifico sobre el servicio */
(
	idservicio bigint foreign key references tbservicios(id), /* identificador unico del servicio solicitado por el pasajero */
	idconductor int foreign key references tbconductor(id), /* identificador del conductor */
	fechanotificado datetime default getdate() /* fecha en que se creo el registro */
)

create table tbincidentes /* contiene el registro de los incidentes enviados por el pasajero desde la app de pasajero */
(
	id int identity primary key, /* identificador unico del incidente */
	idservicio bigint foreign key references tbservicios(id), /* identificador sel servicio del que se reporta el incidente */
	idtipoincidente int foreign key references tbtipoincidente(id), /* identificar del tipo de incidente */
	idestatusincidente int foreign key references tbestatusincidente(id), /* identificador del estatus del incidente para dar seguimiento */
	descripcionincidente varchar(max) not null, /* descripcion del incidente sucedido */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechaincidente datetime default getdate(), /* fecha y hora en que sucedio el incidente */
	so varchar(100) null /* sistema operativo ya sea android o IOs desde donde le sucedio el incidente */
)

create table tbincidenteshistorialestatus /* contiene el historial de cambio de estatus de los incidentes, en si es el seguimiento del avance del incidente */
(
	idservicioincidente int foreign key references tbincidentes(id), /* identificador unico del incidente */
	idestatusincidente int foreign key references tbestatusincidente(id), /* identificador del estatus del incidente al que cambio */
	comentarios varchar(max) not null, /* comentarios sobre el cambio de estatus de seguimiento */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

create table tbserviciosmensaje /* contiene el historial de mensjaes enviados entr el usuario pasajero y el conductor mediante el chat de las apps */
(
	id bigint identity primary key, /* identificador unico */
	idservicio bigint foreign key references tbservicios(id), /* identificador sel servicio del que se reporta el incidente */
	idconductor int foreign key references tbconductor(id), /* identificador del conductor */
	idpasajero bigint not null, /* identificador unico del pasajero */
	desdeapppasajero bit default 0, /* flag que en caso true indica si se envio desde la app pasajero */
	desdeappconductor bit default 0, /* flag que en caso true indica si se envio desde la app conductor */
	mensaje varchar(150) not null, /* texto del mensaje enviado */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tbsolicitudesdefactura /* contiene el listado de solicitudes de facturación que el cliente requiere de su servicio */
(
	idservicio bigint foreign key references tbservicios(id), /* identificador sel servicio del que se reporta el incidente */
	rfcfacturacion varchar(100), /* RFC de la persona a quien se facturara */
	correoenviado varchar(100), /* correo del RFC al que se envio o enviara la factura */
	factenviada bit default 0, /* flag que indica en caso true si la factura si se envio a cliente al correo */
	fechaenviada datetime, /* fecha en que fue enviada la factura */
	comentariosfactura varchar(500), /* comentarios relacionados a la factura */
	activo bit default 1, /* estatus de activo o inactivo (equivalente a eliminado o desactivado) */
	fechasolicitud datetime default getdate() /* fecha en que se creo el registro de solicitud */
)

create table tbcodigospromousados /* contiene los codigos promocionales que uso el pasajero en alguno de sus servicios */
(
	id int identity primary key, /* identificador unico */
	idpasajero bigint foreign key references tbpasajero(id), /* identificador unico del pasajero */
	idcodigopromo int foreign key references tbcodigospromo(id), /* identificador de codigo promocional utilizado para el viaje en caso de haberlo usado */
	idservicio bigint foreign key references tbservicios(id), /* identificador sel servicio del que se reporta el incidente */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro y aplico el codigo promocional */
)

/* NUEVA TABLA: Reportes generados por administradores */
create table tbreporte
(
	id int identity primary key, /* identificador unico */
	nombrereporte nvarchar(200) not null, /* nombre del reporte */
	descripcion nvarchar(500), /* descripción del reporte */
	tiporeporte varchar(50) not null, /* tipo: VIAJES, CONDUCTORES, PASAJEROS, FINANZAS, INCIDENTES */
	fechainicio datetime, /* fecha de inicio del filtro del reporte */
	fechafin datetime, /* fecha de fin del filtro del reporte */
	filtrosaplicados nvarchar(max), /* filtros aplicados en formato JSON */
	archivogenerado varchar(max), /* archivo generado en base64 o URL */
	idusuario_genero int foreign key references tbusuario(id), /* usuario que generó el reporte */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

/* NUEVA TABLA: Filtros de reportes (para guardar configuraciones de filtros reutilizables) */
create table tbreportefiltros
(
	id int identity primary key, /* identificador unico */
	nombrefiltro nvarchar(200) not null, /* nombre del filtro */
	descripcion nvarchar(500), /* descripción del filtro */
	tiporeporte varchar(50) not null, /* tipo de reporte al que aplica */
	filtrosconfiguracion nvarchar(max), /* configuración de filtros en formato JSON */
	idusuario_creo int foreign key references tbusuario(id), /* usuario que creó el filtro */
	publico bit default 0, /* flag que indica si es público (visible para todos) */
	activo bit default 1, /* estatus de activo o inactivo */
	fechacreacion datetime default getdate(), /* fecha en que se creo el registro */
	ultimaactualizacion datetime default getdate() /* ultima fecha en que se actualizó el registro */
)

create table tblogerror /* contiene el listado de errores que suceden y se pueden detectar */
(
	id int identity primary key, /* identificador unico */
	logdescription varchar(max) not null, /* descripcion del error sucedido */
	fechacreacion datetime default getdate() /* fecha en que se creo el registro */
)

/**************** Procedimiento almacenado para generar el token ***************/ 

GO
-- =============================================
-- Author:		Ing. Luis Enrique Hernandez Ballesteros
-- create date: 2026
-- Description:	Genera los tokens para las apps mediante una tarea que se ejecuta cada 10 minutos
-- =============================================
create procedure sp_job_generaTokenApps
AS
BEGIN TRY
	
		-- DEBE EXISTIR UN TOKEN PRIMARIO Y UNO SECUNDARIO YA EN LA TABLA PARA QUE FUNCIONE
		set nocount on;
		
		declare @newToken varchar(max) = ''
		declare @tokenPrimario varchar(max) = ''

		declare @horasExpiraToken int = 3 -- Cada 3 horas

		if exists (select appName from tbTokensApp with(nolock) where appName = 'appPasajero' and esPrimario = 1 and fechaExpira <= getdate())
		begin
			
			set @newToken = NEWID()
			select @tokenPrimario = token from tbTokensApp with(nolock) where appName = 'appPasajero' and esPrimario = 1 and fechaExpira <= getdate()

			update tbTokensApp 
				set token = @tokenPrimario, fechaExpira = dateadd(hour, @horasExpiraToken, getdate())
					where appName = 'appPasajero' and esSecundario = 1

			update tbTokensApp 
				set token = @newToken, fechaExpira = dateadd(hour, @horasExpiraToken, getdate())
					where appName = 'appPasajero' and esPrimario = 1 and fechaExpira <= getdate()

		end
		
		if exists (select appName from tbTokensApp with(nolock) where appName = 'appConductor' and esPrimario = 1 and fechaExpira <= getdate())
		begin
			
			set @newToken = NEWID()
			select @tokenPrimario = token from tbTokensApp with(nolock) where appName = 'appConductor' and esPrimario = 1 and fechaExpira <= getdate()

			update tbTokensApp 
				set token = @tokenPrimario, fechaExpira = dateadd(hour, @horasExpiraToken, getdate())
					where appName = 'appConductor' and esSecundario = 1

			update tbTokensApp 
				set token = @newToken, fechaExpira = dateadd(hour, @horasExpiraToken, getdate())
					where appName = 'appConductor' and esPrimario = 1 and fechaExpira <= getdate()

		end
		
		if exists (select appName from tbTokensApp with(nolock) where appName = 'appVaiaAdmin' and esPrimario = 1 and fechaExpira <= getdate())
		begin
			
			set @newToken = NEWID()
			select @tokenPrimario = token from tbTokensApp with(nolock) where appName = 'appVaiaAdmin' and esPrimario = 1 and fechaExpira <= getdate()

			update tbTokensApp 
				set token = @tokenPrimario, fechaExpira = dateadd(hour, @horasExpiraToken, getdate())
					where appName = 'appVaiaAdmin' and esSecundario = 1

			update tbTokensApp 
				set token = @newToken, fechaExpira = dateadd(hour, @horasExpiraToken, getdate())
					where appName = 'appVaiaAdmin' and esPrimario = 1 and fechaExpira <= getdate()

		end
			
END TRY
BEGIN CATCH

	DECLARE  @ErrorMessage NVARCHAR(4000), @Errorprocedure NVARCHAR(4000), @ErrorLine INT, @ErrorSeverity INT,
			 @ErrorNumber int, @ErrorState int, @ErrorDetails varchar(max)

    SELECT @ErrorMessage = ERROR_MESSAGE(), @Errorprocedure = ERROR_procedure(), @ErrorLine = ERROR_LINE(), 
		@ErrorSeverity = ERROR_SEVERITY(), @ErrorNumber = ERROR_NUMBER(), @ErrorState = ERROR_STATE();
	
	set @ErrorDetails = (select 
							'Procedimiento: ' + @Errorprocedure +
							' - Detalles Técnicos: ' + @ErrorMessage + 
							' - Linea: ' + cast(@ErrorLine as varchar(20)) + 
							' - Severidad: ' + cast(@ErrorSeverity as varchar(20)) + 
							' - Número de Error: ' + cast(@ErrorNumber as varchar(20)) + 
							' - Estado: ' + cast(@ErrorState as varchar(20)))
	
    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );

END CATCH

go
/*
- Estos registro se insertaran al crear la base de datos para que con el job se esten actualizando los token validos

insert into tbTokensApp(appName, token, fechaExpira, esPrimario, esSecundario)
	values('appPasajero', '-', getdate(), 1, 0),
		('appPasajero', '-', getdate(), 0, 1),
		('appConductor', '-', getdate(), 1, 0),
		('appConductor', '-', getdate(), 0, 1),
		('appVaiaAdmin', '-', getdate(), 1, 0),
		('appVaiaAdmin', '-', getdate(), 0, 1)
*/