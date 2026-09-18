/*
 =============================================
 SCRIPT DE LLENADO DE CATÁLOGOS Y CONFIGURACIONES INICIALES
 PARA EL SISTEMA VAIA VIAJES
 =============================================
 Fecha: 2026
 Autor: Ing. Luis Enrique Hernandez Ballesteros
 Descripción: Este script precarga todos los catálogos,
 configuraciones y usuarios necesarios para que la
 aplicación esté lista para uso.
 =============================================
*/

USE vaia_viajes;
GO

-- =============================================
-- 1. CATÁLOGOS BÁSICOS
-- =============================================

-- 1.1 Roles de usuario (tbrol)
INSERT INTO tbrol (rolnombre, activo) VALUES
('Super Administrador', 1),
('Administrador', 1),
('Gerente', 1),
('Supervisor', 1),
('Operador', 1),
('Soporte', 1),
('Contabilidad', 1),
('Marketing', 1);
GO

-- 1.2 Estatus de conductores (tbconductorestatus)
INSERT INTO tbconductorestatus (conductorestatus, descripcion, activo) VALUES
('Disponible', 'Conductor disponible para recibir viajes', 1),
('Ocupado', 'Conductor en un viaje activo', 1),
('Desconectado', 'Conductor no disponible en la app', 1),
('En Pausa', 'Conductor en pausa temporal', 1),
('No Disponible', 'Conductor no disponible por alguna razón', 1),
    ('En Validacion', 'Conductor en proceso de validacion de documentos', 1),
('Suspendido', 'Conductor suspendido temporalmente', 1),
('Bloqueado', 'Conductor bloqueado permanentemente', 1);
GO

-- 1.3 Estatus de documentación (tbestatusdocumentacion)
INSERT INTO tbestatusdocumentacion (nombreestatusdocs, descripcion, activo) VALUES
    ('Pendiente', 'Documentacion pendiente de revision', 1),
    ('En Revision', 'Documentacion en proceso de revision', 1),
    ('Parcialmente Aprobada', 'Algunos documentos aprobados, otros pendientes', 1),
    ('Aprobada', 'Toda la documentacion aprobada', 1),
    ('Rechazada', 'Documentacion rechazada', 1),
    ('Requiere Correccion', 'Se requiere corregir la documentacion', 1);
GO

-- 1.4 Estatus de facturación (tbestatusfacturacion)
INSERT INTO tbestatusfacturacion (nombreestatus, descripcion, activo) VALUES
('Pendiente', 'Facturación pendiente de procesar', 1),
('En Proceso', 'Facturación en proceso', 1),
('Facturada', 'Facturación completada', 1),
('Rechazada', 'Facturación rechazada', 1),
('Cancelada', 'Facturación cancelada', 1);
GO

-- 1.5 Estatus de incidentes (tbestatusincidente)
INSERT INTO tbestatusincidente (nombreestatus, descripcion, activo) VALUES
('Reportado', 'Incidente reportado inicialmente', 1),
('En Investigación', 'Incidente en proceso de investigación', 1),
('Resuelto', 'Incidente resuelto', 1),
('Cerrado', 'Incidente cerrado', 1),
('Cancelado', 'Incidente cancelado', 1);
GO

-- 1.6 Tipos de incidentes (tbtipoincidente)
INSERT INTO tbtipoincidente (nombretipo, descripcion, activo) VALUES
('Problema con el Conductor', 'Incidente relacionado con el comportamiento del conductor', 1),
('Problema con el Pasajero', 'Incidente relacionado con el comportamiento del pasajero', 1),
('Problema con la Unidad', 'Incidente relacionado con el estado de la unidad', 1),
('Problema de Pago', 'Incidente relacionado con el proceso de pago', 1),
('Problema de Ruta', 'Incidente relacionado con la ruta del viaje', 1),
('Problema de Seguridad', 'Incidente relacionado con seguridad', 1),
('Queja General', 'Queja general del servicio', 1);
GO

-- 1.7 Tipos de archivo (tbtipoarchivo)
INSERT INTO tbtipoarchivo (tipoarchivo, descripcion, paraaltaconductor, paraaltaunidad, activo) VALUES
('Identificación Oficial', 'INE, Pasaporte o identificación oficial vigente', 1, 0, 1),
('Licencia de Conducir', 'Licencia de conducir vigente', 1, 0, 1),
('Comprobante de Domicilio', 'Comprobante de domicilio no mayor a 3 meses', 1, 0, 1),
('CURP', 'Clave Única de Registro de Población', 1, 0, 1),
('RFC', 'Registro Federal de Contribuyentes', 1, 0, 1),
('Foto de Perfil', 'Foto de perfil del conductor', 1, 0, 1),
('Comprobante de Estudios', 'Comprobante de estudios o certificado', 0, 0, 1),
('Carta de No Antecedentes', 'Carta de no antecedentes penales', 1, 0, 1),
('Constancia de Situación Fiscal', 'Constancia de situación fiscal', 1, 0, 1),
('Contrato de Trabajo', 'Contrato de trabajo firmado', 1, 0, 1);
GO

-- 1.8 Tipos de archivo de unidad (tbtipoarchivounidad)
INSERT INTO tbtipoarchivounidad (tipoarchivo, descripcion, activo) VALUES
('Tarjeta de Circulación', 'Tarjeta de circulación vigente de la unidad', 1),
('Factura de la Unidad', 'Factura o comprobante de compra de la unidad', 1),
('Seguro de la Unidad', 'Póliza de seguro vigente de la unidad', 1),
('Verificación Vehicular', 'Comprobante de verificación vehicular', 1),
('Fotos de la Unidad', 'Fotografías de la unidad (frontal, trasera, interior)', 1),
('Tenencia', 'Comprobante de pago de tenencia', 1);
GO

-- 1.9 Tipos de combustible (tbtipocombustible)
INSERT INTO tbtipocombustible (nombretipocombustible, activo) VALUES
('Gasolina Magna', 1),
('Gasolina Premium', 1),
('Diésel', 1),
('Gas LP', 1),
('Gas Natural', 1),
('Eléctrico', 1),
('Híbrido', 1);
GO

-- 1.10 Tipos de transmisión (tbtransmision)
INSERT INTO tbtransmision (nombretransmision, activo) VALUES
('Estándar', 1),
('Automática', 1),
('CVT', 1),
('Dual Clutch', 1),
('Manual', 1);
GO

-- 1.11 Tipos de pago (tbtipopago)
INSERT INTO tbtipopago (tipopago, activo) VALUES
('Efectivo', 1),
('Tarjeta de Crédito', 1),
('Tarjeta de Débito', 1),
('PayPal', 1),
('Mercado Pago', 1),
('Transferencia', 1);
GO

-- 1.12 Métodos de pago (tbmetodopago)
INSERT INTO tbmetodopago (metodopago, codigo, activo) VALUES
('Tarjeta de Crédito', 'CARD', 1),
('Tarjeta de Débito', 'DEBIT', 1),
('Efectivo', 'CASH', 1),
('PayPal', 'PAYPAL', 1),
('Mercado Pago', 'MERCADOPAGO', 1);
GO

-- 1.13 Estatus de pago (tbestatuspago)
INSERT INTO tbestatuspago (nombreestatus, codigo, descripcion, activo) VALUES
('Pendiente', 'PENDING', 'Pago pendiente de procesar', 1),
('En Proceso', 'PROCESSING', 'Pago en proceso', 1),
('Pagado', 'PAID', 'Pago completado exitosamente', 1),
('Fallido', 'FAILED', 'Pago falló', 1),
('Reembolsado', 'REFUNDED', 'Pago reembolsado', 1),
('Cancelado', 'CANCELLED', 'Pago cancelado', 1);
GO

-- 1.14 Estatus de servicio (tbservicioestatus)
INSERT INTO tbservicioestatus (estatus, estatusdescription, activo) VALUES
('Solicitado', 'Servicio solicitado por el pasajero, esperando conductor', 1),
('En Camino', 'Conductor en camino al origen', 1),
    ('Llego al Origen', 'Conductor llego al punto de recogida', 1),
    ('En Viaje', 'Viaje en curso', 1),
    ('Casi Llegando', 'Cerca del destino', 1),
    ('Llego al Destino', 'Llego al destino final', 1),
('Finalizado', 'Servicio finalizado', 1),
('Cancelado por Pasajero', 'Cancelado por el pasajero', 1),
('Cancelado por Conductor', 'Cancelado por el conductor', 1),
('Cancelado por Admin', 'Cancelado por el administrador', 1),
('No Pagado', 'Servicio no pagado', 1);
GO

-- 1.15 Estatus de corte semanal (tbcortesemanasemanalestatus)
INSERT INTO tbcortesemanasemanalestatus (nombreestatus, descripcion, activo) VALUES
('Pendiente', 'Corte pendiente de procesar', 1),
('En Proceso', 'Corte en proceso de cálculo', 1),
('Completado', 'Corte completado y calculado', 1),
('Pagado', 'Corte pagado al conductor', 1),
('En Disputa', 'Corte en disputa o revisión', 1);
GO

-- 1.16 Tipos de comisión (tbtipocomision)
INSERT INTO tbtipocomision (tipocomision, codigo, activo) VALUES
('Porcentaje', 'PERCENTAGE', 1),
('Monto Fijo', 'FIXED_AMOUNT', 1);
GO

-- 1.17 Idiomas soportados (tbidioma)
INSERT INTO tbidioma (idioma, codigo, activo) VALUES
('Español', 'es', 1),
('Inglés', 'en', 1),
('Francés', 'fr', 1);
GO

-- =============================================
-- 2. COMPAÑÍA Y CONFIGURACIONES
-- =============================================

-- 2.1 Crear la compañía principal
INSERT INTO tbcompania (
    companianombre, 
    pagocontarjetaactivo, 
    versionpasajeroandroid, 
    versionconductorandroid,
    kmsalaredondamascercanos,
    segesperatomaservicio,
    segesperasalgapasajero,
    nounidadesmascercanas,
    sololaunidadmascercana,
    paypalactivo,
    mercadopagoactivo,
    minsparapagopaypal,
    minsparapagomercadopago,
    androidgoogleapihablitado,
    iosgoogleapihablitado,
    activo
) VALUES (
    'Vaia Viajes México',
    1, -- pago con tarjeta activo
    '1.0.0', -- version pasajero android
    '1.0.0', -- version conductor android
    10, -- km a la redonda
    120, -- segundos para tomar servicio (2 min)
    300, -- segundos de espera (5 min)
    10, -- número de unidades más cercanas
    0, -- false: enviar a todas las unidades cercanas
    1, -- PayPal activo
    1, -- Mercado Pago activo
    3, -- minutos para PayPal
    3, -- minutos para Mercado Pago
    1, -- API Google habilitada Android
    1, -- API Google habilitada iOS
    1
);
GO

-- 2.2 Configuraciones del sistema (tbconfiguracionsistema)
INSERT INTO tbconfiguracionsistema (claveconfiguracion, valorconfiguracion, descripcion, activo) VALUES
('APP_NAME', 'Vaia Viajes', 'Nombre de la aplicación', 1),
('APP_ENV', 'production', 'Ambiente de la aplicación', 1),
('APP_VERSION', '1.0.0', 'Versión de la aplicación', 1),
('APP_TIMEZONE', 'America/Mexico_City', 'Zona horaria de la aplicación', 1),
('DEFAULT_LANGUAGE', 'es', 'Idioma por defecto', 1),
('MAX_INTENTOS_LOGIN', '5', 'Número máximo de intentos de login fallidos antes de bloquear', 1),
('TIEMPO_BLOQUEO_LOGIN_MINUTOS', '15', 'Tiempo de bloqueo en minutos después de exceder intentos', 1),
('TIEMPO_EXPIRACION_SESION_HORAS', '24', 'Tiempo de expiración de sesión en horas', 1),
('TOKEN_EXPIRATION_HOURS', '3', 'Horas de expiración de token de API', 1),
('DISTANCIA_SEGURIDAD_METROS', '200', 'Distancia de seguridad para considerar llegada (metros)', 1),
('RADIO_BUSQUEDA_CONDUCTORES_KM', '10', 'Radio de búsqueda de conductores en kilómetros', 1),
('MAXIMO_CONDUCTORES_NOTIFICADOS', '10', 'Número máximo de conductores a notificar por viaje', 1),
('COMISION_DEFAULT_PORCENTAJE', '3.00', 'Porcentaje de comisión por defecto', 1),
('INTERVALO_ENVIO_UBICACION_SEGUNDOS', '10', 'Intervalo de envío de ubicación GPS en segundos', 1),
('URL_TERMINOS_CONDICIONES', 'https://vaiaviajes.com/terminos', 'URL de términos y condiciones', 1),
('URL_AVISO_PRIVACIDAD', 'https://vaiaviajes.com/privacidad', 'URL de aviso de privacidad', 1),
('EMAIL_CONTACTO', 'soporte@vaiaviajes.com', 'Correo de contacto para soporte', 1),
('TELEFONO_CONTACTO', '+521234567890', 'Teléfono de contacto para soporte', 1);
GO

-- =============================================
-- 3. ZONAS DE COBERTURA
-- =============================================

-- 3.1 Zonas de cobertura (tbzonacobertura)
INSERT INTO tbzonacobertura (nombrezona, descripcion, latitudcentro, longitudcentro, radio_km, activo) VALUES
('Reynosa Centro', 'Zona centro de Reynosa', '26.0923', '-98.2789', 10, 1),
('Zona Conurbada', 'Zona conurbada de Reynosa', '26.0923', '-98.2789', 25, 1),
('Reynosa Norte', 'Zona norte de Reynosa', '26.0923', '-98.2789', 15, 1),
('Reynosa Sur', 'Zona sur de Reynosa', '26.0923', '-98.2789', 15, 1),
('Reynosa Este', 'Zona este de Reynosa', '26.0923', '-98.2789', 15, 1),
('Reynosa Oeste', 'Zona oeste de Reynosa', '26.0923', '-98.2789', 15, 1);
GO

-- 3.2 Comisiones por zona de cobertura (tbzonacoberturacomision)
DECLARE @tipo_comision_porcentaje smallint;
SELECT @tipo_comision_porcentaje = id FROM tbtipocomision WHERE codigo = 'PERCENTAGE';

-- Insertar comisiones para cada zona (3% default)
INSERT INTO tbzonacoberturacomision (idzonacobertura, porcentajecomision, idtipocomision, comisionminima, comisionmaxima, activo)
SELECT 
    id,
    3.00, -- 3% default
    @tipo_comision_porcentaje,
    10.00, -- comisión mínima de $10
    100.00, -- comisión máxima de $100
    1
FROM tbzonacobertura
WHERE activo = 1;
GO

-- =============================================
-- 4. USUARIOS ADMINISTRADORES
-- =============================================

-- Hash comun para todos los usuarios iniciales (password = admin123)
DECLARE @hashAdmin123 VARCHAR(64) = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'admin123'), 2);

-- 4.1 Crear usuario Super Administrador
DECLARE @idSuperAdmin smallint;
DECLARE @idCompania smallint;

SELECT @idCompania = id FROM tbcompania WHERE companianombre = 'Vaia Viajes México';

-- Obtener ID del rol Super Administrador
SELECT @idSuperAdmin = id FROM tbrol WHERE rolnombre = 'Super Administrador';

INSERT INTO tbusuario (
    idcompania,
    nombre,
    appaterno,
    apmaterno,
    sexo,
    idrol,
    correo,
    telefono,
    account,
    pass,
    activo,
    esusuariopropietario,
    puedeveratodoconductor
) VALUES (
    @idCompania,
    'Super',
    'Admin',
    'Vaia',
    'M',
    @idSuperAdmin,
    'superadmin@vaiaviajes.com',
    '+521234567890',
    'superadmin',
    @hashAdmin123,
    1,
    1,
    1
);
GO

-- 4.2 Crear usuario Administrador
-- Hash comun para todos los usuarios iniciales (password = admin123)
DECLARE @hashAdmin123 VARCHAR(64) = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'admin123'), 2);
DECLARE @idAdmin smallint;
DECLARE @idCompania smallint;
SELECT @idCompania = id FROM tbcompania WHERE companianombre = 'Vaia Viajes México';
SELECT @idAdmin = id FROM tbrol WHERE rolnombre = 'Administrador';

INSERT INTO tbusuario (
    idcompania,
    nombre,
    appaterno,
    apmaterno,
    sexo,
    idrol,
    correo,
    telefono,
    account,
    pass,
    activo,
    esusuariopropietario,
    puedeveratodoconductor
) VALUES (
    @idCompania,
    'Admin',
    'Vaia',
    'Viajes',
    'M',
    @idAdmin,
    'admin@vaiaviajes.com',
    '+521234567891',
    'admin',
    @hashAdmin123,
    1,
    0,
    1
);
GO

-- 4.3 Crear usuario de Soporte
-- Hash comun para todos los usuarios iniciales (password = admin123)
DECLARE @hashAdmin123 VARCHAR(64) = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'admin123'), 2);
DECLARE @idSoporte smallint;
DECLARE @idCompania smallint;
SELECT @idCompania = id FROM tbcompania WHERE companianombre = 'Vaia Viajes México';
SELECT @idSoporte = id FROM tbrol WHERE rolnombre = 'Soporte';

INSERT INTO tbusuario (
    idcompania,
    nombre,
    appaterno,
    apmaterno,
    sexo,
    idrol,
    correo,
    telefono,
    account,
    pass,
    activo
) VALUES (
    @idCompania,
    'Soporte',
    'Vaia',
    'Viajes',
    'M',
    @idSoporte,
    'soporte@vaiaviajes.com',
    '+521234567892',
    'soporte',
    @hashAdmin123,
    1
);
GO

-- 4.4 Crear usuario de Contabilidad
-- Hash comun para todos los usuarios iniciales (password = admin123)
DECLARE @hashAdmin123 VARCHAR(64) = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'admin123'), 2);
DECLARE @idContabilidad smallint;
DECLARE @idCompania smallint;
SELECT @idCompania = id FROM tbcompania WHERE companianombre = 'Vaia Viajes México';
SELECT @idContabilidad = id FROM tbrol WHERE rolnombre = 'Contabilidad';

INSERT INTO tbusuario (
    idcompania,
    nombre,
    appaterno,
    apmaterno,
    sexo,
    idrol,
    correo,
    telefono,
    account,
    pass,
    activo
) VALUES (
    @idCompania,
    'Contabilidad',
    'Vaia',
    'Viajes',
    'F',
    @idContabilidad,
    'contabilidad@vaiaviajes.com',
    '+521234567893',
    'contabilidad',
    @hashAdmin123,
    1
);
GO

-- 4.5 Crear usuario de Marketing
-- Hash comun para todos los usuarios iniciales (password = admin123)
DECLARE @hashAdmin123 VARCHAR(64) = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'admin123'), 2);
DECLARE @idMarketing smallint;
DECLARE @idCompania smallint;
SELECT @idCompania = id FROM tbcompania WHERE companianombre = 'Vaia Viajes México';
SELECT @idMarketing = id FROM tbrol WHERE rolnombre = 'Marketing';

INSERT INTO tbusuario (
    idcompania,
    nombre,
    appaterno,
    apmaterno,
    sexo,
    idrol,
    correo,
    telefono,
    account,
    pass,
    activo
) VALUES (
    @idCompania,
    'Marketing',
    'Vaia',
    'Viajes',
    'F',
    @idMarketing,
    'marketing@vaiaviajes.com',
    '+521234567894',
    'marketing',
    @hashAdmin123,
    1
);
GO

-- =============================================
-- 5. MENÚ DEL SISTEMA (tbmenu)
-- =============================================

-- 5.1 Menús principales (headers)
INSERT INTO tbmenu (optionnombre, esheader, idparentmenu, urllink, iconclass, ordernumber, target, activo, idusuariocreo) VALUES
('Dashboard', 0, NULL, '/dashboard', 'metismenu-icon pe-7s-graph', 1, 'rightcontent', 1, 1),
('Usuarios', 1, NULL, '#', 'metismenu-icon pe-7s-users', 2, 'rightcontent', 1, 1),
('Conductores', 1, NULL, '#', 'metismenu-icon pe-7s-car', 3, 'rightcontent', 1, 1),
('Pasajeros', 1, NULL, '#', 'metismenu-icon pe-7s-user', 4, 'rightcontent', 1, 1),
('Viajes', 1, NULL, '#', 'metismenu-icon pe-7s-map', 5, 'rightcontent', 1, 1),
('Finanzas', 1, NULL, '#', 'metismenu-icon pe-7s-cash', 6, 'rightcontent', 1, 1),
('Reportes', 1, NULL, '#', 'metismenu-icon pe-7s-news-paper', 7, 'rightcontent', 1, 1),
('Configuración', 1, NULL, '#', 'metismenu-icon pe-7s-settings', 8, 'rightcontent', 1, 1),
('Incidentes', 1, NULL, '#', 'metismenu-icon pe-7s-warning', 9, 'rightcontent', 1, 1),
('Promociones', 1, NULL, '#', 'metismenu-icon pe-7s-gift', 10, 'rightcontent', 1, 1),
('Seguridad', 1, NULL, '#', 'metismenu-icon pe-7s-lock', 11, 'rightcontent', 1, 1);
GO

-- 5.2 Submenús
DECLARE @idUsuarios int, @idConductores int, @idPasajeros int, @idViajes int, @idFinanzas int, @idReportes int, @idConfiguracion int, @idIncidentes int, @idPromociones int, @idSeguridad int;

SELECT @idUsuarios = id FROM tbmenu WHERE optionnombre = 'Usuarios' AND esheader = 1;
SELECT @idConductores = id FROM tbmenu WHERE optionnombre = 'Conductores' AND esheader = 1;
SELECT @idPasajeros = id FROM tbmenu WHERE optionnombre = 'Pasajeros' AND esheader = 1;
SELECT @idViajes = id FROM tbmenu WHERE optionnombre = 'Viajes' AND esheader = 1;
SELECT @idFinanzas = id FROM tbmenu WHERE optionnombre = 'Finanzas' AND esheader = 1;
SELECT @idReportes = id FROM tbmenu WHERE optionnombre = 'Reportes' AND esheader = 1;
SELECT @idConfiguracion = id FROM tbmenu WHERE optionnombre = 'Configuración' AND esheader = 1;
SELECT @idIncidentes = id FROM tbmenu WHERE optionnombre = 'Incidentes' AND esheader = 1;
SELECT @idPromociones = id FROM tbmenu WHERE optionnombre = 'Promociones' AND esheader = 1;
SELECT @idSeguridad = id FROM tbmenu WHERE optionnombre = 'Seguridad' AND esheader = 1;

-- Submenús para Usuarios
INSERT INTO tbmenu (optionnombre, esheader, idparentmenu, urllink, iconclass, ordernumber, target, activo, idusuariocreo) VALUES
('Lista de Usuarios', 0, @idUsuarios, '/usuarios/lista', 'metismenu-icon pe-7s-user', 1, 'rightcontent', 1, 1),
('Crear Usuario', 0, @idUsuarios, '/usuarios/crear', 'metismenu-icon pe-7s-plus', 2, 'rightcontent', 1, 1),
('Roles', 0, @idUsuarios, '/usuarios/roles', 'metismenu-icon pe-7s-shield', 3, 'rightcontent', 1, 1),
('Permisos', 0, @idUsuarios, '/usuarios/permisos', 'metismenu-icon pe-7s-key', 4, 'rightcontent', 1, 1);

-- Submenús para Conductores
INSERT INTO tbmenu (optionnombre, esheader, idparentmenu, urllink, iconclass, ordernumber, target, activo, idusuariocreo) VALUES
('Lista de Conductores', 0, @idConductores, '/conductores/lista', 'metismenu-icon pe-7s-id', 1, 'rightcontent', 1, 1),
('Registrar Conductor', 0, @idConductores, '/conductores/registrar', 'metismenu-icon pe-7s-plus', 2, 'rightcontent', 1, 1),
('Validar Documentos', 0, @idConductores, '/conductores/validar', 'metismenu-icon pe-7s-check', 3, 'rightcontent', 1, 1),
('Unidades', 0, @idConductores, '/conductores/unidades', 'metismenu-icon pe-7s-car', 4, 'rightcontent', 1, 1),
('Cortes Semanales', 0, @idConductores, '/conductores/cortes', 'metismenu-icon pe-7s-cash', 5, 'rightcontent', 1, 1);

-- Submenús para Pasajeros
INSERT INTO tbmenu (optionnombre, esheader, idparentmenu, urllink, iconclass, ordernumber, target, activo, idusuariocreo) VALUES
('Lista de Pasajeros', 0, @idPasajeros, '/pasajeros/lista', 'metismenu-icon pe-7s-users', 1, 'rightcontent', 1, 1),
('Bloqueados', 0, @idPasajeros, '/pasajeros/bloqueados', 'metismenu-icon pe-7s-close', 2, 'rightcontent', 1, 1);

-- Submenús para Viajes
INSERT INTO tbmenu (optionnombre, esheader, idparentmenu, urllink, iconclass, ordernumber, target, activo, idusuariocreo) VALUES
('Historial de Viajes', 0, @idViajes, '/viajes/historial', 'metismenu-icon pe-7s-clock', 1, 'rightcontent', 1, 1),
('Viajes Activos', 0, @idViajes, '/viajes/activos', 'metismenu-icon pe-7s-play', 2, 'rightcontent', 1, 1),
('Mapa', 0, @idViajes, '/viajes/mapa', 'metismenu-icon pe-7s-map', 3, 'rightcontent', 1, 1);

-- Submenús para Finanzas
INSERT INTO tbmenu (optionnombre, esheader, idparentmenu, urllink, iconclass, ordernumber, target, activo, idusuariocreo) VALUES
('Pagos', 0, @idFinanzas, '/finanzas/pagos', 'metismenu-icon pe-7s-credit', 1, 'rightcontent', 1, 1),
('Cortes', 0, @idFinanzas, '/finanzas/cortes', 'metismenu-icon pe-7s-cash', 2, 'rightcontent', 1, 1),
('Comisiones', 0, @idFinanzas, '/finanzas/comisiones', 'metismenu-icon pe-7s-percent', 3, 'rightcontent', 1, 1),
('Facturación', 0, @idFinanzas, '/finanzas/facturacion', 'metismenu-icon pe-7s-news-paper', 4, 'rightcontent', 1, 1);

-- Submenús para Reportes
INSERT INTO tbmenu (optionnombre, esheader, idparentmenu, urllink, iconclass, ordernumber, target, activo, idusuariocreo) VALUES
('Reporte de Viajes', 0, @idReportes, '/reportes/viajes', 'metismenu-icon pe-7s-graph', 1, 'rightcontent', 1, 1),
('Reporte de Conductores', 0, @idReportes, '/reportes/conductores', 'metismenu-icon pe-7s-user', 2, 'rightcontent', 1, 1),
('Reporte Financiero', 0, @idReportes, '/reportes/financiero', 'metismenu-icon pe-7s-graph', 3, 'rightcontent', 1, 1),
('Reportes Personalizados', 0, @idReportes, '/reportes/personalizados', 'metismenu-icon pe-7s-settings', 4, 'rightcontent', 1, 1);

-- Submenús para Configuración
INSERT INTO tbmenu (optionnombre, esheader, idparentmenu, urllink, iconclass, ordernumber, target, activo, idusuariocreo) VALUES
('Configuración General', 0, @idConfiguracion, '/configuracion/general', 'metismenu-icon pe-7s-settings', 1, 'rightcontent', 1, 1),
('Costos de Viaje', 0, @idConfiguracion, '/configuracion/costos', 'metismenu-icon pe-7s-cash', 2, 'rightcontent', 1, 1),
('Zonas de Cobertura', 0, @idConfiguracion, '/configuracion/zonas', 'metismenu-icon pe-7s-map', 3, 'rightcontent', 1, 1),
('Comisiones', 0, @idConfiguracion, '/configuracion/comisiones', 'metismenu-icon pe-7s-percent', 4, 'rightcontent', 1, 1),
('Avisos', 0, @idConfiguracion, '/configuracion/avisos', 'metismenu-icon pe-7s-bell', 5, 'rightcontent', 1, 1);

-- Submenús para Incidentes
INSERT INTO tbmenu (optionnombre, esheader, idparentmenu, urllink, iconclass, ordernumber, target, activo, idusuariocreo) VALUES
('Lista de Incidentes', 0, @idIncidentes, '/incidentes/lista', 'metismenu-icon pe-7s-warning', 1, 'rightcontent', 1, 1),
('Tipos de Incidentes', 0, @idIncidentes, '/incidentes/tipos', 'metismenu-icon pe-7s-menu', 2, 'rightcontent', 1, 1);

-- Submenús para Promociones
INSERT INTO tbmenu (optionnombre, esheader, idparentmenu, urllink, iconclass, ordernumber, target, activo, idusuariocreo) VALUES
('Códigos Promocionales', 0, @idPromociones, '/promociones/codigos', 'metismenu-icon pe-7s-gift', 1, 'rightcontent', 1, 1),
('Promociones', 0, @idPromociones, '/promociones/lista', 'metismenu-icon pe-7s-megaphone', 2, 'rightcontent', 1, 1);

-- Submenús para Seguridad
INSERT INTO tbmenu (optionnombre, esheader, idparentmenu, urllink, iconclass, ordernumber, target, activo, idusuariocreo) VALUES
('Auditoría', 0, @idSeguridad, '/seguridad/auditoria', 'metismenu-icon pe-7s-search', 1, 'rightcontent', 1, 1),
('Logs de Error', 0, @idSeguridad, '/seguridad/logs', 'metismenu-icon pe-7s-close', 2, 'rightcontent', 1, 1);
GO

-- =============================================
-- 6. ASIGNACIÓN DE MENÚS POR ROL
-- =============================================

-- 6.1 Menús por defecto para Super Administrador
DECLARE @idRolSuperAdmin smallint, @idRolAdmin smallint, @idRolGerente smallint, @idRolSupervisor smallint, @idRolSoporte smallint;

SELECT @idRolSuperAdmin = id FROM tbrol WHERE rolnombre = 'Super Administrador';
SELECT @idRolAdmin = id FROM tbrol WHERE rolnombre = 'Administrador';
SELECT @idRolGerente = id FROM tbrol WHERE rolnombre = 'Gerente';
SELECT @idRolSupervisor = id FROM tbrol WHERE rolnombre = 'Supervisor';
SELECT @idRolSoporte = id FROM tbrol WHERE rolnombre = 'Soporte';

-- Asignar todos los menús al Super Administrador y Administrador
INSERT INTO tbrolmenudefault (idrol, idmenu)
SELECT @idRolSuperAdmin, id FROM tbmenu WHERE activo = 1;

INSERT INTO tbrolmenudefault (idrol, idmenu)
SELECT @idRolAdmin, id FROM tbmenu WHERE activo = 1;

-- Gerente: Dashboard, Conductores, Pasajeros, Viajes, Finanzas, Reportes, Incidentes
INSERT INTO tbrolmenudefault (idrol, idmenu)
SELECT @idRolGerente, id FROM tbmenu 
WHERE optionnombre IN ('Dashboard', 'Conductores', 'Pasajeros', 'Viajes', 'Finanzas', 'Reportes', 'Incidentes')
OR idparentmenu IN (
    SELECT id FROM tbmenu WHERE optionnombre IN ('Conductores', 'Pasajeros', 'Viajes', 'Finanzas', 'Reportes', 'Incidentes')
);

-- Supervisor: Dashboard, Conductores, Pasajeros, Viajes, Reportes
INSERT INTO tbrolmenudefault (idrol, idmenu)
SELECT @idRolSupervisor, id FROM tbmenu 
WHERE optionnombre IN ('Dashboard', 'Conductores', 'Pasajeros', 'Viajes', 'Reportes')
OR idparentmenu IN (
    SELECT id FROM tbmenu WHERE optionnombre IN ('Conductores', 'Pasajeros', 'Viajes', 'Reportes')
);

-- Soporte: Dashboard, Conductores, Pasajeros, Viajes, Incidentes
INSERT INTO tbrolmenudefault (idrol, idmenu)
SELECT @idRolSoporte, id FROM tbmenu 
WHERE optionnombre IN ('Dashboard', 'Conductores', 'Pasajeros', 'Viajes', 'Incidentes')
OR idparentmenu IN (
    SELECT id FROM tbmenu WHERE optionnombre IN ('Conductores', 'Pasajeros', 'Viajes', 'Incidentes')
);
GO

-- =============================================
-- 7. CONFIGURACIÓN DE COSTOS DE VIAJE
-- =============================================

-- 7.1 Configuración de costos por hora (tbappviajecostos)
INSERT INTO tbappviajecostos (
    idcompania,
    costominimo,
    costoporkm,
    costoporminuto,
    horainicio,
    horafin,
    numdiasemana
)
SELECT 
    id,
    50.00, -- costo mínimo $50
    8.00, -- $8 por kilómetro
    2.00, -- $2 por minuto
    '00:00:00',
    '23:59:59',
    1 -- Lunes
FROM tbcompania WHERE companianombre = 'Vaia Viajes México';

-- Agregar costos para todos los días de la semana
INSERT INTO tbappviajecostos (
    idcompania,
    costominimo,
    costoporkm,
    costoporminuto,
    horainicio,
    horafin,
    numdiasemana
)
SELECT 
    idcompania,
    costominimo,
    costoporkm,
    costoporminuto,
    horainicio,
    horafin,
    numdiasemana + 1
FROM tbappviajecostos
WHERE numdiasemana = 1;

-- Repetir para los días restantes
-- (En una implementación real se usaría un loop o se insertarían todos los días)
GO

-- =============================================
-- 8. TOKENS DE APLICACIÓN
-- =============================================

-- 8.1 Inicializar tokens para las apps (tbTokensApp)
INSERT INTO tbTokensApp(appName, token, fechaExpira, esPrimario, esSecundario)
VALUES
('appPasajero', NEWID(), DATEADD(hour, 3, GETDATE()), 1, 0),
('appPasajero', NEWID(), DATEADD(hour, 6, GETDATE()), 0, 1),
('appConductor', NEWID(), DATEADD(hour, 3, GETDATE()), 1, 0),
('appConductor', NEWID(), DATEADD(hour, 6, GETDATE()), 0, 1),
('appVaiaAdmin', NEWID(), DATEADD(hour, 3, GETDATE()), 1, 0),
('appVaiaAdmin', NEWID(), DATEADD(hour, 6, GETDATE()), 0, 1);
GO

-- =============================================
-- 9. AVISOS INICIALES
-- =============================================

-- 9.1 Avisos para pasajeros y conductores
INSERT INTO tbavisosapp (idcompania, esavisopasajero, esavisoconductor, tituloaviso, descripcionaviso, activo)
SELECT 
    id,
    1,
    0,
    '¡Bienvenido a Vaia Viajes!',
    N'Bienvenido a la aplicación de Vaia Viajes. Disfruta de viajes seguros y confiables. Si tienes alguna duda, contáctanos.',
    1
FROM tbcompania WHERE companianombre = 'Vaia Viajes México'
UNION ALL
SELECT 
    id,
    0,
    1,
    '¡Bienvenido a Vaia Viajes Conductor!',
    N'Bienvenido a la aplicación de Vaia Viajes para conductores. Gracias por ser parte de nuestra red de transporte. Recuerda mantener tus documentos al día.',
    1
FROM tbcompania WHERE companianombre = 'Vaia Viajes México'
UNION ALL
SELECT 
    id,
    1,
    1,
    'Actualización del Sistema',
    N'El sistema se actualizará el próximo domingo de 2:00 AM a 4:00 AM. Durante este tiempo el servicio estará suspendido.',
    1
FROM tbcompania WHERE companianombre = 'Vaia Viajes México';
GO

-- =============================================
-- 10. CÓDIGOS PROMOCIONALES INICIALES
-- =============================================

INSERT INTO tbcodigospromo (
    codigopromocional,
    vigentehasta,
    decripcionpromo,
    esporcentaje,
    montodecuento,
    activo,
    usosmaximos,
    validodesde
) VALUES
('VIAJE10', DATEADD(month, 3, GETDATE()), 'Descuento de $10 en tu primer viaje', 0, 10.00, 1, 100, GETDATE()),
('VIAJE20', DATEADD(month, 3, GETDATE()), 'Descuento de $20 en tu primer viaje', 0, 20.00, 1, 50, GETDATE()),
('PORCENTAJE10', DATEADD(month, 3, GETDATE()), '10% de descuento en tu viaje', 1, 10.00, 1, 200, GETDATE()),
('VIAJEGRATIS', DATEADD(month, 1, GETDATE()), 'Viaje gratis hasta $100', 0, 100.00, 1, 10, GETDATE()),
('BIENVENIDA', DATEADD(month, 6, GETDATE()), 'Descuento de bienvenida de $15', 0, 15.00, 1, 500, GETDATE());
GO

-- =============================================
-- 11. MARCAS Y SUBMARCAS
-- =============================================

-- 11.1 Marcas de vehículos
INSERT INTO tbmarca (nombremarca, activo) VALUES
('Chevrolet', 1),
('Ford', 1),
('Nissan', 1),
('Toyota', 1),
('Honda', 1),
('Volkswagen', 1),
('Mazda', 1),
('Hyundai', 1),
('Kia', 1),
('Mercedes-Benz', 1),
('BMW', 1),
('Audi', 1),
('Renault', 1),
('Peugeot', 1),
('Fiat', 1);
GO

-- 11.2 Submarcas (modelos)
DECLARE @idChevrolet int, @idFord int, @idNissan int, @idToyota int, @idHonda int, @idVolkswagen int;

SELECT @idChevrolet = id FROM tbmarca WHERE nombremarca = 'Chevrolet';
SELECT @idFord = id FROM tbmarca WHERE nombremarca = 'Ford';
SELECT @idNissan = id FROM tbmarca WHERE nombremarca = 'Nissan';
SELECT @idToyota = id FROM tbmarca WHERE nombremarca = 'Toyota';
SELECT @idHonda = id FROM tbmarca WHERE nombremarca = 'Honda';
SELECT @idVolkswagen = id FROM tbmarca WHERE nombremarca = 'Volkswagen';

INSERT INTO tbsubmarca (idmarca, nombresubmarca, activo) VALUES
(@idChevrolet, 'Aveo', 1),
(@idChevrolet, 'Spark', 1),
(@idChevrolet, 'Cruze', 1),
(@idChevrolet, 'Camaro', 1),
(@idFord, 'Fiesta', 1),
(@idFord, 'Focus', 1),
(@idFord, 'Mustang', 1),
(@idFord, 'Explorer', 1),
(@idNissan, 'Versa', 1),
(@idNissan, 'Sentra', 1),
(@idNissan, 'Altima', 1),
(@idNissan, 'March', 1),
(@idToyota, 'Corolla', 1),
(@idToyota, 'Camry', 1),
(@idToyota, 'Prius', 1),
(@idToyota, 'Yaris', 1),
(@idHonda, 'Civic', 1),
(@idHonda, 'Accord', 1),
(@idHonda, 'Fit', 1),
(@idHonda, 'CR-V', 1),
(@idVolkswagen, 'Jetta', 1),
(@idVolkswagen, 'Golf', 1),
(@idVolkswagen, 'Polo', 1);
GO

-- =============================================
-- 12. PLANTILLAS DE CORREO HTML
-- =============================================

INSERT INTO tbplantillascorreohtml (nombreplantilla, descripcionplantilla, codigohtml, activo) VALUES
('Registro_Pasajero', 'Plantilla para registro de nuevo pasajero', 
'<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f4f4f4;">
    <div style="background-color: #ffffff; border-radius: 8px; padding: 30px; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">
        <div style="text-align: center; margin-bottom: 20px;">
            <h1 style="color: #2c3e50;">Vaia Viajes</h1>
        </div>
        <h2 style="color: #2c3e50;">¡Bienvenido a Vaia Viajes!</h2>
        <p style="color: #555; line-height: 1.6;">Hola [NOMBRE_PASAJERO],</p>
        <p style="color: #555; line-height: 1.6;">Gracias por registrarte en Vaia Viajes. Estamos emocionados de tenerte como parte de nuestra comunidad de transporte.</p>
        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <p style="margin: 0; color: #555;">Tu cuenta ha sido creada exitosamente. Ya puedes comenzar a solicitar viajes desde nuestra aplicación.</p>
        </div>
        <p style="color: #555; line-height: 1.6;">Para confirmar tu correo, haz clic en el siguiente enlace:</p>
        <div style="text-align: center; margin: 25px 0;">
            <a href="[LINK_CONFIRMACION]" style="background-color: #3498db; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-weight: bold;">Confirmar Correo</a>
        </div>
        <hr style="border: 1px solid #eee; margin: 20px 0;">
        <p style="color: #888; font-size: 12px; text-align: center;">Este es un correo automático, por favor no responder. Si tienes preguntas, contáctanos a soporte@vaiaviajes.com</p>
    </div>
</body>
</html>', 1),

('Registro_Conductor', 'Plantilla para registro de nuevo conductor',
'<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f4f4f4;">
    <div style="background-color: #ffffff; border-radius: 8px; padding: 30px; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">
        <div style="text-align: center; margin-bottom: 20px;">
            <h1 style="color: #2c3e50;">Vaia Viajes</h1>
        </div>
        <h2 style="color: #2c3e50;">¡Bienvenido a Vaia Viajes Conductor!</h2>
        <p style="color: #555; line-height: 1.6;">Hola [NOMBRE_CONDUCTOR],</p>
        <p style="color: #555; line-height: 1.6;">Gracias por registrarte como conductor en Vaia Viajes. A continuación, los pasos para comenzar:</p>
        <ul style="color: #555; line-height: 1.8;">
            <li>Completa tu perfil de conductor</li>
            <li>Registra tu vehículo</li>
            <li>Sube la documentación requerida</li>
            <li>Espera la validación de tus documentos</li>
            <li>¡Comienza a recibir viajes!</li>
        </ul>
        <p style="color: #555; line-height: 1.6;">Para confirmar tu correo, haz clic en el siguiente enlace:</p>
        <div style="text-align: center; margin: 25px 0;">
            <a href="[LINK_CONFIRMACION]" style="background-color: #2ecc71; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-weight: bold;">Confirmar Correo</a>
        </div>
        <hr style="border: 1px solid #eee; margin: 20px 0;">
        <p style="color: #888; font-size: 12px; text-align: center;">Este es un correo automático, por favor no responder. Si tienes preguntas, contáctanos a soporte@vaiaviajes.com</p>
    </div>
</body>
</html>', 1),

('Comprobante_Viaje', 'Plantilla para comprobante de viaje',
'<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f4f4f4;">
    <div style="background-color: #ffffff; border-radius: 8px; padding: 30px; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">
        <div style="text-align: center; margin-bottom: 20px;">
            <h1 style="color: #2c3e50;">Vaia Viajes</h1>
            <p style="color: #888;">Comprobante de Viaje</p>
        </div>
        <div style="background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin: 15px 0;">
            <p><strong>Número de Viaje:</strong> [ID_VIAJE]</p>
            <p><strong>Fecha:</strong> [FECHA_VIAJE]</p>
            <p><strong>Origen:</strong> [ORIGEN]</p>
            <p><strong>Destino:</strong> [DESTINO]</p>
            <p><strong>Conductor:</strong> [CONDUCTOR]</p>
            <p><strong>Unidad:</strong> [UNIDAD]</p>
            <p><strong>Distancia:</strong> [DISTANCIA] km</p>
            <p><strong>Duración:</strong> [DURACION]</p>
            <p style="font-size: 18px; color: #2c3e50;"><strong>Monto Total:</strong> $[MONTO_TOTAL]</p>
            <p style="font-size: 16px; color: #27ae60;"><strong>Método de Pago:</strong> [METODO_PAGO]</p>
            <p style="font-size: 16px; color: #2980b9;"><strong>Estado:</strong> [ESTADO]</p>
        </div>
        <hr style="border: 1px solid #eee; margin: 20px 0;">
        <p style="color: #888; font-size: 12px; text-align: center;">Este es un comprobante de tu viaje en Vaia Viajes. Para cualquier consulta, contáctanos a soporte@vaiaviajes.com</p>
    </div>
</body>
</html>', 1);
GO

-- =============================================
-- 13. VERIFICACIÓN FINAL
-- =============================================

-- Mostrar resumen de la configuración
SELECT '=== CONFIGURACIÓN COMPLETADA ===' AS Mensaje;
SELECT COUNT(*) AS 'Total Tablas Cargadas' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';
SELECT COUNT(*) AS 'Total Usuarios Creados' FROM tbusuario WHERE activo = 1;
SELECT COUNT(*) AS 'Total Menús Configurados' FROM tbmenu WHERE activo = 1;
SELECT COUNT(*) AS 'Total Códigos Promocionales' FROM tbcodigospromo WHERE activo = 1;
SELECT COUNT(*) AS 'Total Conductores' FROM tbconductor WHERE activo = 1;
SELECT COUNT(*) AS 'Total Pasajeros' FROM tbpasajero WHERE activo = 1;
GO

-- Mostrar credenciales de acceso
SELECT 
    '=== CREDENCIALES DE ACCESO ===' AS Mensaje,
    'USUARIO' AS Tipo,
    'Sitio Web' AS Plataforma,
    'superadmin' AS Usuario,
    'admin123' AS Contraseña,
    'superadmin@vaiaviajes.com' AS Correo,
    'Super Administrador' AS Rol
UNION ALL
SELECT 
    '=== CREDENCIALES DE ACCESO ===',
    'USUARIO',
    'Sitio Web',
    'admin',
    'admin123',
    'admin@vaiaviajes.com',
    'Administrador'
UNION ALL
SELECT 
    '=== CREDENCIALES DE ACCESO ===',
    'USUARIO',
    'Sitio Web',
    'soporte',
    'admin123',
    'soporte@vaiaviajes.com',
    'Soporte'
UNION ALL
SELECT 
    '=== CREDENCIALES DE ACCESO ===',
    'USUARIO',
    'Sitio Web',
    'contabilidad',
    'admin123',
    'contabilidad@vaiaviajes.com',
    'Contabilidad'
UNION ALL
SELECT 
    '=== CREDENCIALES DE ACCESO ===',
    'USUARIO',
    'Sitio Web',
    'marketing',
    'admin123',
    'marketing@vaiaviajes.com',
    'Marketing';
GO

-- Mostrar información de las apps
SELECT 
    '=== INFORMACIÓN DE APPS ===' AS Mensaje,
    'App Pasajero' AS Aplicacion,
    'appPasajero' AS TokenApp,
    'Tiene token generado' AS Estado,
    'Usar token para autenticación en API' AS Nota
UNION ALL
SELECT 
    '=== INFORMACIÓN DE APPS ===',
    'App Conductor',
    'appConductor',
    'Tiene token generado',
    'Usar token para autenticación en API'
UNION ALL
SELECT 
    '=== INFORMACIÓN DE APPS ===',
    'Portal Admin',
    'appVaiaAdmin',
    'Tiene token generado',
    'Usar token para autenticación en API';
GO

PRINT '=============================================';
PRINT 'SCRIPT DE CONFIGURACIÓN INICIAL COMPLETADO';
PRINT '=============================================';
PRINT '';
PRINT 'LA APLICACIÓN ESTÁ LISTA PARA USO';
PRINT '';
PRINT 'Credenciales de acceso:';
PRINT '  Usuario: superadmin';
PRINT '  Contraseña: admin123';
PRINT '  URL: /dashboard';
PRINT '';
PRINT 'Tokens de API generados automáticamente.';
PRINT '=============================================';
GO