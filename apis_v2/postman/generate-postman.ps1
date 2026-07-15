param()

$outputPath = "C:\opencode_proyects\vaia_viajes_v2\Proyectos Vaia Viajes\vaia_viajes\apis_v2\postman\VaiaViajes.postman_collection.json"

$collection = [ordered]@{
    info = [ordered]@{
        _postman_id = [guid]::NewGuid().ToString()
        name = "Vaia Viajes API"
        description = "Colección de la API de Vaia Viajes"
        schema = "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    }
    item = @()
}

function New-Request {
    param($name, $method, $url, $headers, $body, $query, $description)

    $item = [ordered]@{
        name = $name
        request = [ordered]@{
            method = $method
            header = $headers
            url = [ordered]@{
                raw = $url
                protocol = "http"
                host = @("localhost:5000")
                path = ($url -replace '^http://localhost:5000/', '').Split('/')
            }
            description = $description
        }
    }

    if ($method -eq "POST" -and $body) {
        $item.request.body = [ordered]@{
            mode = "raw"
            raw = $body
            options = [ordered]@{
                raw = [ordered]@{
                    language = "json"
                }
            }
        }
        $item.request.header += @{
            key = "Content-Type"
            value = "application/json"
            type = "text"
        }
    }

    if ($method -eq "GET" -and $query) {
        $item.request.url.query = $query
    }

    return $item
}

function New-Folder {
    param($name, $description, $baseUrl, $requests)
    return [ordered]@{
        name = $name
        description = $description
        item = $requests
    }
}

# ─── Helper: Query params ───
function QP($key, $value) {
    return [ordered]@{ key = $key; value = $value; type = "text" }
}

# ─────────────────────────────────────────────
# FOLDER 1: Pasajero
# ─────────────────────────────────────────────
$base = "http://localhost:5000/api/pasajero"

$pasajeroItems = @()

$pasajeroItems += New-Request -name "Registrar" -method "POST" -url "$base/Registrar" -description "Registra un nuevo pasajero en la plataforma." -body @"
{
  "idCompania": 1,
  "nombre": "Juan",
  "appaterno": "Pérez",
  "apmaterno": "López",
  "correo": "juan.perez@correo.com",
  "codigopaistel": "+52",
  "telefono": "5512345678",
  "googlekey": "",
  "account": "juanperez",
  "pass": "MiPassword123",
  "idiomapreferido": "es",
  "fechanacimiento": "1990-05-15",
  "genero": "M"
}
"@

$pasajeroItems += New-Request -name "IniciarSesion" -method "POST" -url "$base/IniciarSesion" -description "Inicia sesión de un pasajero con credenciales o Google." -body @"
{
  "account": "juanperez",
  "pass": "MiPassword123",
  "googlekey": "",
  "googlekeyso": "",
  "dispositivoinfo": "iPhone 14",
  "sistemaoperativo": "iOS 17",
  "ipaddress": "192.168.1.10",
  "useragent": "Mozilla/5.0 ...",
  "esLoginGoogle": false,
  "googleuserid": ""
}
"@

$pasajeroItems += New-Request -name "CerrarSesion" -method "POST" -url "$base/CerrarSesion" -description "Cierra la sesión activa del pasajero." -body @"
{
  "idPasajero": 1,
  "uuidsesion": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
"@

$pasajeroItems += New-Request -name "ActualizarPerfil" -method "POST" -url "$base/ActualizarPerfil" -description "Actualiza los datos del perfil del pasajero." -body @"
{
  "idPasajero": 1,
  "nombre": "Juan Carlos",
  "appaterno": "Pérez",
  "apmaterno": "López",
  "fotoperfil": "https://ejemplo.com/foto.jpg",
  "idiomapreferido": "es",
  "fechanacimiento": "1990-05-15",
  "genero": "M",
  "notasadicionales": "Cliente frecuente"
}
"@

$pasajeroItems += New-Request -name "ObtenerPerfil" -method "GET" -url "$base/ObtenerPerfil" -description "Obtiene el perfil completo del pasajero por su ID." -query @(
    (QP "idPasajero" "1")
)

$pasajeroItems += New-Request -name "CambiarPassword" -method "POST" -url "$base/CambiarPassword" -description "Cambia la contraseña del pasajero." -body @"
{
  "idPasajero": 1,
  "passActual": "MiPassword123",
  "passNuevo": "NuevaPass456"
}
"@

$pasajeroItems += New-Request -name "EnviarCodigoVerificacion" -method "POST" -url "$base/EnviarCodigoVerificacion" -description "Envía un código de verificación SMS al teléfono del pasajero." -body @"
{
  "codigopaistel": "+52",
  "telefono": "5512345678"
}
"@

$pasajeroItems += New-Request -name "CambiarTelefono" -method "POST" -url "$base/CambiarTelefono" -description "Cambia el número de teléfono del pasajero usando un código de verificación." -body @"
{
  "idPasajero": 1,
  "codigopaistel": "+52",
  "telefonoNuevo": "5598765432",
  "codigoVerificacion": "123456"
}
"@

$pasajeroItems += New-Request -name "ValidarCodigoPromocional" -method "POST" -url "$base/ValidarCodigoPromocional" -description "Valida un código promocional y verifica si aplica al viaje." -body @"
{
  "codigo": "BIENVENIDO10",
  "idPasajero": 1,
  "montoViaje": 150.00
}
"@

$pasajeroItems += New-Request -name "SolicitarServicio" -method "POST" -url "$base/SolicitarServicio" -description "Solicita un nuevo servicio de viaje." -body @"
{
  "idPasajero": 1,
  "idCompania": 1,
  "dirOrigen": "Av. Reforma 222, CDMX",
  "latOrigen": 19.432608,
  "lngOrigen": -99.133209,
  "dirDestino": "Av. Insurgentes 300, CDMX",
  "latDestino": 19.429173,
  "lngDestino": -99.165674,
  "distanciaMetros": 4500,
  "idTipoPago": 1,
  "codigoPromocional": "",
  "so": "iOS",
  "tipoviaje": "normal"
}
"@

$pasajeroItems += New-Request -name "ConductoresDisponibles" -method "GET" -url "$base/ConductoresDisponibles" -description "Obtiene la lista de conductores disponibles cerca de una ubicación." -query @(
    (QP "lat" "19.432608")
    (QP "lng" "-99.133209")
    (QP "idZona" "1")
)

$pasajeroItems += New-Request -name "ObtenerEstadoServicio" -method "GET" -url "$base/ObtenerEstadoServicio" -description "Obtiene el estado actual de un servicio." -query @(
    (QP "idServicio" "1")
    (QP "idPasajero" "1")
)

$pasajeroItems += New-Request -name "CancelarServicio" -method "POST" -url "$base/CancelarServicio" -description "Cancela un servicio solicitado." -body @"
{
  "idServicio": 1,
  "idPasajero": 1,
  "motivo": "Cambio de planes"
}
"@

$pasajeroItems += New-Request -name "CalificarViaje" -method "POST" -url "$base/CalificarViaje" -description "Califica y comenta un viaje finalizado." -body @"
{
  "idServicio": 1,
  "idPasajero": 1,
  "calificacion": 5,
  "comentarios": "Excelente servicio, muy puntual"
}
"@

$pasajeroItems += New-Request -name "ActivarAlarmaSOS" -method "POST" -url "$base/ActivarAlarmaSOS" -description "Activa la alerta de emergencia SOS durante un viaje." -body @"
{
  "idServicio": 1,
  "idPasajero": 1
}
"@

$pasajeroItems += New-Request -name "AgregarFavorito" -method "POST" -url "$base/AgregarFavorito" -description "Guarda una dirección como favorita." -body @"
{
  "idPasajero": 1,
  "nombre": "Casa",
  "dir": "Av. Siempre Viva 123, CDMX",
  "lat": 19.432608,
  "lng": -99.133209
}
"@

$pasajeroItems += New-Request -name "ListarFavoritos" -method "GET" -url "$base/ListarFavoritos" -description "Obtiene la lista de direcciones favoritas del pasajero." -query @(
    (QP "idPasajero" "1")
)

$pasajeroItems += New-Request -name "EliminarFavorito" -method "POST" -url "$base/EliminarFavorito" -description "Elimina una dirección favorita." -body @"
{
  "idFavorito": 1,
  "idPasajero": 1
}
"@

$pasajeroItems += New-Request -name "HistorialViajes" -method "GET" -url "$base/HistorialViajes" -description "Obtiene el historial de viajes del pasajero con paginación y filtro por fechas." -query @(
    (QP "idPasajero" "1")
    (QP "pagina" "1")
    (QP "tamano" "10")
    (QP "fi" "2025-01-01")
    (QP "ff" "2025-12-31")
)

$pasajeroItems += New-Request -name "DetalleViaje" -method "GET" -url "$base/DetalleViaje" -description "Obtiene el detalle completo de un viaje específico." -query @(
    (QP "idServicio" "1")
    (QP "idPasajero" "1")
)

$pasajeroItems += New-Request -name "ReportarIncidente" -method "POST" -url "$base/ReportarIncidente" -description "Reporta un incidente durante el servicio." -body @"
{
  "idServicio": 1,
  "idPasajero": 1,
  "idTipo": 1,
  "desc": "El conductor tomó una ruta no autorizada",
  "so": "iOS"
}
"@

$pasajeroItems += New-Request -name "ObtenerConfiguracionCostos" -method "GET" -url "$base/ObtenerConfiguracionCostos" -description "Obtiene la configuración de costos de la compañía (tarifas)." -query @(
    (QP "idCompania" "1")
)

$pasajeroItems += New-Request -name "ObtenerAvisos" -method "GET" -url "$base/ObtenerAvisos" -description "Obtiene los avisos/publicaciones activos para la compañía." -query @(
    (QP "idCompania" "1")
)

$pasajeroItems += New-Request -name "ObtenerPromociones" -method "GET" -url "$base/ObtenerPromociones" -description "Obtiene las promociones disponibles."

$pasajeroItems += New-Request -name "ObtenerPropagandas" -method "GET" -url "$base/ObtenerPropagandas" -description "Obtiene las propagandas/publicidad activas."

$pasajeroItems += New-Request -name "EnviarMensajeChat" -method "POST" -url "$base/EnviarMensajeChat" -description "Envía un mensaje en el chat del servicio." -body @"
{
  "idServicio": 1,
  "idPasajero": 1,
  "mensaje": "Hola, voy en camino"
}
"@

$pasajeroItems += New-Request -name "ObtenerMensajesChat" -method "GET" -url "$base/ObtenerMensajesChat" -description "Obtiene los mensajes del chat de un servicio." -query @(
    (QP "idServicio" "1")
    (QP "idPasajero" "1")
)

# ─────────────────────────────────────────────
# FOLDER 2: Conductor
# ─────────────────────────────────────────────
$baseC = "http://localhost:5000/api/conductor"

$conductorItems = @()

$conductorItems += New-Request -name "Registrar" -method "POST" -url "$baseC/Registrar" -description "Registra un nuevo conductor en la plataforma." -body @"
{
  "idCompania": 1,
  "idRazonSocialConductores": 1,
  "idZonaCobertura": 1,
  "nombre": "Carlos",
  "appaterno": "Mendoza",
  "apmaterno": "García",
  "correo": "carlos.mendoza@correo.com",
  "codigopaistel": "+52",
  "telefono": "5511112233",
  "fechanacimiento": "1988-08-20",
  "genero": "M",
  "account": "carlosm",
  "pass": "PassConductor123",
  "noLicencia": "LIC-12345678",
  "fechaVigenciaLicencia": "2027-08-20",
  "paislicencia": "MX",
  "urlfotolicencia": "https://ejemplo.com/licencias/lic123.jpg",
  "tipocontratacion": "independiente"
}
"@

$conductorItems += New-Request -name "IniciarSesion" -method "POST" -url "$baseC/IniciarSesion" -description "Inicia sesión de un conductor." -body @"
{
  "account": "carlosm",
  "pass": "PassConductor123",
  "dispositivoinfo": "Samsung Galaxy S23",
  "sistemaoperativo": "Android 14",
  "ipaddress": "192.168.1.20",
  "useragent": "Mozilla/5.0 ..."
}
"@

$conductorItems += New-Request -name "CerrarSesion" -method "POST" -url "$baseC/CerrarSesion" -description "Cierra la sesión activa del conductor." -body @"
{
  "idConductor": 1,
  "uuidsesion": "b2c3d4e5-f6a7-8901-bcde-f12345678901"
}
"@

$conductorItems += New-Request -name "ObtenerPerfil" -method "GET" -url "$baseC/ObtenerPerfil" -description "Obtiene el perfil completo del conductor." -query @(
    (QP "idConductor" "1")
)

$conductorItems += New-Request -name "ActualizarPerfil" -method "POST" -url "$baseC/ActualizarPerfil" -description "Actualiza los datos del perfil del conductor." -body @"
{
  "idConductor": 1,
  "nombre": "Carlos Andrés",
  "appaterno": "Mendoza",
  "apmaterno": "García",
  "fotoperfil": "https://ejemplo.com/fotos/conductor1.jpg",
  "fechanacimiento": "1988-08-20",
  "genero": "M",
  "notasadicionales": "Conductor preferido"
}
"@

$conductorItems += New-Request -name "CambiarPassword" -method "POST" -url "$baseC/CambiarPassword" -description "Cambia la contraseña del conductor." -body @"
{
  "idConductor": 1,
  "passActual": "PassConductor123",
  "passNuevo": "NuevaPass789"
}
"@

$conductorItems += New-Request -name "ActualizarUbicacion" -method "POST" -url "$baseC/ActualizarUbicacion" -description "Actualiza la ubicación en tiempo real del conductor." -body @"
{
  "idConductor": 1,
  "lat": 19.432608,
  "lng": -99.133209,
  "speed": 35.5,
  "status": "disponible"
}
"@

$conductorItems += New-Request -name "CambiarEstatus" -method "POST" -url "$baseC/CambiarEstatus" -description "Cambia el estatus de disponibilidad del conductor." -body @"
{
  "idConductor": 1,
  "status": "ocupado"
}
"@

$conductorItems += New-Request -name "AceptarServicio" -method "POST" -url "$baseC/AceptarServicio" -description "Acepta un servicio asignado al conductor." -body @"
{
  "idServicio": 1,
  "idConductor": 1,
  "idUnidad": 1,
  "latconductor": 19.432608,
  "lngconductor": -99.133209
}
"@

$conductorItems += New-Request -name "IniciarViaje" -method "POST" -url "$baseC/IniciarViaje" -description "Marca el inicio del viaje (conductor recoge al pasajero)." -body @"
{
  "idServicio": 1,
  "idConductor": 1
}
"@

$conductorItems += New-Request -name "FinalizarViaje" -method "POST" -url "$baseC/FinalizarViaje" -description "Finaliza el viaje registrando la ubicación y kilometraje final." -body @"
{
  "idServicio": 1,
  "idConductor": 1,
  "latFinal": 19.429173,
  "lngFinal": -99.165674,
  "kmRecorridos": 4.5
}
"@

$conductorItems += New-Request -name "ListarUnidades" -method "GET" -url "$baseC/ListarUnidades" -description "Obtiene la lista de unidades (vehículos) asignadas al conductor." -query @(
    (QP "idConductor" "1")
)

$conductorItems += New-Request -name "SeleccionarUnidad" -method "POST" -url "$baseC/SeleccionarUnidad" -description "Selecciona la unidad (vehículo) que usará el conductor." -body @"
{
  "idConductor": 1,
  "idUnidad": 1
}
"@

$conductorItems += New-Request -name "HistorialViajes" -method "GET" -url "$baseC/HistorialViajes" -description "Obtiene el historial de viajes del conductor con paginación y filtro de fechas." -query @(
    (QP "idConductor" "1")
    (QP "pagina" "1")
    (QP "tamano" "10")
    (QP "fi" "2025-01-01")
    (QP "ff" "2025-12-31")
)

$conductorItems += New-Request -name "DetalleViaje" -method "GET" -url "$baseC/DetalleViaje" -description "Obtiene el detalle completo de un viaje específico del conductor." -query @(
    (QP "idServicio" "1")
    (QP "idConductor" "1")
)

$conductorItems += New-Request -name "ObtenerSemanaCorte" -method "GET" -url "$baseC/ObtenerSemanaCorte" -description "Obtiene la semana de corte actual del conductor." -query @(
    (QP "idConductor" "1")
)

$conductorItems += New-Request -name "TransferirSemanaCorte" -method "POST" -url "$baseC/TransferirSemanaCorte" -description "Solicita la transferencia del pago de la semana de corte." -body @"
{
  "idSemanaCorte": 1,
  "idConductor": 1
}
"@

$conductorItems += New-Request -name "EnviarMensajeChat" -method "POST" -url "$baseC/EnviarMensajeChat" -description "Envía un mensaje en el chat del servicio (lado conductor)." -body @"
{
  "idServicio": 1,
  "idConductor": 1,
  "mensaje": "Llegaré en 5 minutos"
}
"@

$conductorItems += New-Request -name "ObtenerMensajesChat" -method "GET" -url "$baseC/ObtenerMensajesChat" -description "Obtiene los mensajes del chat de un servicio (lado conductor)." -query @(
    (QP "idServicio" "1")
    (QP "idConductor" "1")
)

$conductorItems += New-Request -name "ActivarAlarmaSOS" -method "POST" -url "$baseC/ActivarAlarmaSOS" -description "Activa la alerta de emergencia SOS desde el conductor." -body @"
{
  "idServicio": 1,
  "idConductor": 1
}
"@

$conductorItems += New-Request -name "ReportarIncidente" -method "POST" -url "$baseC/ReportarIncidente" -description "Reporta un incidente durante el servicio (lado conductor)." -body @"
{
  "idServicio": 1,
  "idConductor": 1,
  "idTipo": 1,
  "desc": "Pasajero en estado de ebriedad",
  "so": "Android"
}
"@

$conductorItems += New-Request -name "ObtenerNotificaciones" -method "GET" -url "$baseC/ObtenerNotificaciones" -description "Obtiene las notificaciones del conductor." -query @(
    (QP "idConductor" "1")
)

$conductorItems += New-Request -name "ObtenerAvisos" -method "GET" -url "$baseC/ObtenerAvisos" -description "Obtiene los avisos activos para la compañía del conductor." -query @(
    (QP "idCompania" "1")
)

$conductorItems += New-Request -name "ObtenerServicioActivo" -method "GET" -url "$baseC/ObtenerServicioActivo" -description "Obtiene el servicio activo actual del conductor." -query @(
    (QP "idConductor" "1")
)

# ─────────────────────────────────────────────
# FOLDER 3: Admin Web
# ─────────────────────────────────────────────
$baseA = "http://localhost:5000/api/admin"

$adminItems = @()

$adminItems += New-Request -name "IniciarSesion" -method "POST" -url "$baseA/IniciarSesion" -description "Inicia sesión en el panel de administración web." -body @"
{
  "account": "admin@vaiaviajes.com",
  "pass": "AdminPass123"
}
"@

$adminItems += New-Request -name "CerrarSesion" -method "POST" -url "$baseA/CerrarSesion" -description "Cierra la sesión del administrador." -body @"
{
  "idUsuario": 1,
  "uuidsesion": "c3d4e5f6-a7b8-9012-cdef-123456789012"
}
"@

$adminItems += New-Request -name "CrearUsuario" -method "POST" -url "$baseA/CrearUsuario" -description "Crea un nuevo usuario administrador o staff." -body @"
{
  "idCreador": 1,
  "idCompania": 1,
  "nombre": "María",
  "appaterno": "Fernández",
  "apmaterno": "López",
  "sexo": "F",
  "idRol": 2,
  "correo": "maria.fernandez@correo.com",
  "telefono": "5544332211",
  "account": "mariaf",
  "pass": "PassMaria123",
  "esProp": false,
  "puedeVerTodos": true
}
"@

$adminItems += New-Request -name "EditarUsuario" -method "POST" -url "$baseA/EditarUsuario" -description "Edita los datos de un usuario existente." -body @"
{
  "idActualiza": 1,
  "idUsuario": 2,
  "nombre": "María Elena",
  "appaterno": "Fernández",
  "apmaterno": "López",
  "sexo": "F",
  "idRol": 2,
  "correo": "maria.elena@correo.com",
  "telefono": "5544332211",
  "activo": true
}
"@

$adminItems += New-Request -name "EliminarUsuario" -method "POST" -url "$baseA/EliminarUsuario" -description "Elimina (desactiva) un usuario del sistema." -body @"
{
  "idUsuario": 2,
  "idUsuarioElimina": 1
}
"@

$adminItems += New-Request -name "ListarUsuarios" -method "GET" -url "$baseA/ListarUsuarios" -description "Lista los usuarios del sistema con paginación y filtros." -query @(
    (QP "pagina" "1")
    (QP "tamano" "10")
    (QP "idRol" "0")
    (QP "activo" "true")
    (QP "buscar" "")
)

$adminItems += New-Request -name "ObtenerUsuario" -method "GET" -url "$baseA/ObtenerUsuario" -description "Obtiene los detalles de un usuario específico." -query @(
    (QP "idUsuario" "1")
)

$adminItems += New-Request -name "ListarRoles" -method "GET" -url "$baseA/ListarRoles" -description "Lista todos los roles disponibles en el sistema."

$adminItems += New-Request -name "ListarPermisosXRol" -method "GET" -url "$baseA/ListarPermisosXRol" -description "Obtiene los permisos asociados a un rol específico." -query @(
    (QP "idRol" "1")
)

$adminItems += New-Request -name "ListarPasajeros" -method "GET" -url "$baseA/ListarPasajeros" -description "Lista los pasajeros registrados con paginación y filtros." -query @(
    (QP "pagina" "1")
    (QP "tamano" "10")
    (QP "idCompania" "1")
    (QP "activo" "true")
    (QP "buscar" "")
)

$adminItems += New-Request -name "ObtenerPasajero" -method "GET" -url "$baseA/ObtenerPasajero" -description "Obtiene los detalles de un pasajero específico." -query @(
    (QP "idPasajero" "1")
)

$adminItems += New-Request -name "ActualizarPasajero" -method "POST" -url "$baseA/ActualizarPasajero" -description "Actualiza los datos de un pasajero desde administración." -body @"
{
  "idPasajero": 1,
  "idUsuario": 1,
  "nombre": "Juan Carlos",
  "appaterno": "Pérez",
  "apmaterno": "López",
  "correo": "juan.perez@correo.com",
  "telefono": "5512345678",
  "activo": true
}
"@

$adminItems += New-Request -name "SuspenderPasajero" -method "POST" -url "$baseA/SuspenderPasajero" -description "Suspende a un pasajero de la plataforma." -body @"
{
  "idPasajero": 1,
  "idUsuario": 1,
  "motivo": "Incumplimiento de términos y condiciones"
}
"@

$adminItems += New-Request -name "AsignarSaldoPasajero" -method "POST" -url "$baseA/AsignarSaldoPasajero" -description "Asigna o ajusta el saldo de un pasajero." -body @"
{
  "idPasajero": 1,
  "idUsuario": 1,
  "monto": 100.00,
  "concepto": "Bono de bienvenida"
}
"@

$adminItems += New-Request -name "ListarConductores" -method "GET" -url "$baseA/ListarConductores" -description "Lista los conductores registrados con paginación y filtros." -query @(
    (QP "pagina" "1")
    (QP "tamano" "10")
    (QP "idCompania" "1")
    (QP "activo" "true")
    (QP "buscar" "")
)

$adminItems += New-Request -name "ObtenerConductor" -method "GET" -url "$baseA/ObtenerConductor" -description "Obtiene los detalles de un conductor específico." -query @(
    (QP "idConductor" "1")
)

$adminItems += New-Request -name "ActualizarConductor" -method "POST" -url "$baseA/ActualizarConductor" -description "Actualiza los datos de un conductor desde administración." -body @"
{
  "idConductor": 1,
  "idUsuario": 1,
  "nombre": "Carlos Andrés",
  "appaterno": "Mendoza",
  "apmaterno": "García",
  "correo": "carlos.mendoza@correo.com",
  "telefono": "5511112233",
  "noLicencia": "LIC-12345678",
  "fechaVigenciaLicencia": "2027-08-20",
  "activo": true
}
"@

$adminItems += New-Request -name "SuspenderConductor" -method "POST" -url "$baseA/SuspenderConductor" -description "Suspende a un conductor de la plataforma." -body @"
{
  "idConductor": 1,
  "idUsuario": 1,
  "motivo": "Múltiples quejas de pasajeros"
}
"@

$adminItems += New-Request -name "ValidarDocumento" -method "POST" -url "$baseA/ValidarDocumento" -description "Aprueba o rechaza un documento de conductor." -body @"
{
  "idDoc": 1,
  "idUsuario": 1,
  "validado": true,
  "correccion": false,
  "coment": "Documento aprobado"
}
"@

$adminItems += New-Request -name "ListarDocumentosConductor" -method "GET" -url "$baseA/ListarDocumentosConductor" -description "Lista los documentos de un conductor." -query @(
    (QP "idConductor" "1")
)

$adminItems += New-Request -name "GestionarServicio" -method "POST" -url "$baseA/GestionarServicio" -description "Gestiona un servicio (cancelar, reasignar, etc.) desde administración." -body @"
{
  "idServicio": 1,
  "idUsuario": 1,
  "accion": "cancelar",
  "idConductor": 0,
  "motivo": "Servicio duplicado"
}
"@

$adminItems += New-Request -name "ListarServicios" -method "GET" -url "$baseA/ListarServicios" -description "Lista los servicios con paginación y filtros." -query @(
    (QP "pagina" "1")
    (QP "tamano" "10")
    (QP "fi" "2025-01-01")
    (QP "ff" "2025-12-31")
    (QP "idEstatusViaje" "0")
    (QP "idCompania" "1")
)

$adminItems += New-Request -name "DetalleServicio" -method "GET" -url "$baseA/DetalleServicio" -description "Obtiene el detalle completo de un servicio." -query @(
    (QP "idServicio" "1")
)

$adminItems += New-Request -name "ListarEstatusServicio" -method "GET" -url "$baseA/ListarEstatusServicio" -description "Lista los estatus posibles de un servicio (catálogo)."

$adminItems += New-Request -name "ReporteServicios" -method "GET" -url "$baseA/ReporteServicios" -description "Genera reporte de servicios por rango de fechas." -query @(
    (QP "fi" "2025-01-01")
    (QP "ff" "2025-12-31")
    (QP "idCompania" "1")
    (QP "idEstatusViaje" "0")
)

$adminItems += New-Request -name "ReportePasajeros" -method "GET" -url "$baseA/ReportePasajeros" -description "Genera reporte de pasajeros registrados en un rango de fechas." -query @(
    (QP "fi" "2025-01-01")
    (QP "ff" "2025-12-31")
)

$adminItems += New-Request -name "ReporteConductores" -method "GET" -url "$baseA/ReporteConductores" -description "Genera reporte de conductores registrados en un rango de fechas." -query @(
    (QP "fi" "2025-01-01")
    (QP "ff" "2025-12-31")
)

$adminItems += New-Request -name "ReporteIngresos" -method "GET" -url "$baseA/ReporteIngresos" -description "Genera reporte de ingresos por compañía en un rango de fechas." -query @(
    (QP "fi" "2025-01-01")
    (QP "ff" "2025-12-31")
    (QP "idCompania" "1")
)

$adminItems += New-Request -name "ReporteComisiones" -method "GET" -url "$baseA/ReporteComisiones" -description "Genera reporte de comisiones en un rango de fechas." -query @(
    (QP "fi" "2025-01-01")
    (QP "ff" "2025-12-31")
)

$adminItems += New-Request -name "ReporteUtilidadDiaria" -method "GET" -url "$baseA/ReporteUtilidadDiaria" -description "Genera reporte de utilidad diaria por compañía." -query @(
    (QP "fecha" "2025-06-15")
    (QP "idCompania" "1")
)

$adminItems += New-Request -name "ListarIncidentes" -method "GET" -url "$baseA/ListarIncidentes" -description "Lista los incidentes reportados con paginación y filtros." -query @(
    (QP "pagina" "1")
    (QP "tamano" "10")
    (QP "fi" "2025-01-01")
    (QP "ff" "2025-12-31")
    (QP "idTipoIncidente" "0")
    (QP "idServicio" "0")
)

$adminItems += New-Request -name "DetalleIncidente" -method "GET" -url "$baseA/DetalleIncidente" -description "Obtiene el detalle de un incidente específico." -query @(
    (QP "idIncidente" "1")
)

$adminItems += New-Request -name "TiposIncidente" -method "GET" -url "$baseA/TiposIncidente" -description "Lista los tipos de incidente disponibles (catálogo)."

$adminItems += New-Request -name "ListaIncidentesTablas" -method "GET" -url "$baseA/ListaIncidentesTablas" -description "Obtiene datos de tablas relacionadas con incidentes."

$adminItems += New-Request -name "ActualizarEstatusIncidente" -method "POST" -url "$baseA/ActualizarEstatusIncidente" -description "Actualiza el estatus de un incidente." -body @"
{
  "idIncidente": 1,
  "idEstatus": 2,
  "idUsuario": 1,
  "comentario": "Incidente resuelto, se habló con el conductor"
}
"@

$adminItems += New-Request -name "ListarPromociones" -method "GET" -url "$baseA/ListarPromociones" -description "Lista las promociones registradas con paginación y filtro activo." -query @(
    (QP "pagina" "1")
    (QP "tamano" "10")
    (QP "activo" "true")
)

$adminItems += New-Request -name "CrearPromocion" -method "POST" -url "$baseA/CrearPromocion" -description "Crea una nueva promoción en el sistema." -body @"
{
  "idUsuario": 1,
  "nombre": "Bienvenida 10%",
  "codigo": "BIENVENIDO10",
  "tipoDescuento": "porcentaje",
  "valorDescuento": 10.00,
  "montoMinimo": 50.00,
  "usoMaximo": 1000,
  "usoMaximoXUsuario": 1,
  "fechaVigenciaInicio": "2025-06-01",
  "fechaVigenciaFin": "2025-12-31",
  "so": "todos"
}
"@

$adminItems += New-Request -name "EditarPromocion" -method "POST" -url "$baseA/EditarPromocion" -description "Edita una promoción existente." -body @"
{
  "idPromocion": 1,
  "idUsuario": 1,
  "nombre": "Bienvenida 15%",
  "codigo": "BIENVENIDO15",
  "tipoDescuento": "porcentaje",
  "valorDescuento": 15.00,
  "montoMinimo": 50.00,
  "usoMaximo": 1000,
  "usoMaximoXUsuario": 1,
  "fechaVigenciaInicio": "2025-06-01",
  "fechaVigenciaFin": "2025-12-31"
}
"@

$adminItems += New-Request -name "EliminarPromocion" -method "POST" -url "$baseA/EliminarPromocion" -description "Elimina (desactiva) una promoción." -body @"
{
  "idPromocion": 1,
  "idUsuario": 1
}
"@

$adminItems += New-Request -name "GenerarCodigoPromocional" -method "POST" -url "$baseA/GenerarCodigoPromocional" -description "Genera un código promocional adicional para una promoción." -body @"
{
  "idPromocion": 1,
  "codigo": "BIENVENIDO15-EXTRA",
  "idUsuario": 1
}
"@

$adminItems += New-Request -name "ListarZonasCobertura" -method "GET" -url "$baseA/ListarZonasCobertura" -description "Lista las zonas de cobertura con paginación y filtro activo." -query @(
    (QP "pagina" "1")
    (QP "tamano" "10")
    (QP "activo" "true")
)

$adminItems += New-Request -name "AgregarZonaCobertura" -method "POST" -url "$baseA/AgregarZonaCobertura" -description "Agrega una nueva zona de cobertura." -body @"
{
  "nombre": "Zona Centro",
  "desc": "Zona centro de la ciudad",
  "poligono": "[[19.432608,-99.133209],[19.435000,-99.135000],[19.438000,-99.130000]]",
  "idCompania": 1,
  "idUsuario": 1
}
"@

$adminItems += New-Request -name "EditarZonaCobertura" -method "POST" -url "$baseA/EditarZonaCobertura" -description "Edita una zona de cobertura existente." -body @"
{
  "idZonaCobertura": 1,
  "nombre": "Zona Centro Ampliada",
  "desc": "Zona centro y alrededores",
  "poligono": "[[19.432608,-99.133209],[19.440000,-99.138000],[19.445000,-99.125000]]",
  "idCompania": 1,
  "idUsuario": 1
}
"@

$adminItems += New-Request -name "EliminarZonaCobertura" -method "POST" -url "$baseA/EliminarZonaCobertura" -description "Elimina una zona de cobertura." -body @"
{
  "idZonaCobertura": 1,
  "idUsuario": 1
}
"@

$adminItems += New-Request -name "ObtenerComisionesZona" -method "GET" -url "$baseA/ObtenerComisionesZona" -description "Obtiene las comisiones configuradas para una zona." -query @(
    (QP "idZona" "1")
)

$adminItems += New-Request -name "ActualizarComisionZona" -method "POST" -url "$baseA/ActualizarComisionZona" -description "Actualiza la comisión de una zona de cobertura." -body @"
{
  "idZona": 1,
  "porcentaje": 15.00,
  "tipo": "porcentaje",
  "minimo": 5.00,
  "maximo": 50.00
}
"@

$adminItems += New-Request -name "ObtenerConfiguracion" -method "GET" -url "$baseA/ObtenerConfiguracion" -description "Obtiene la configuración general del sistema."

$adminItems += New-Request -name "GuardarConfiguracion" -method "POST" -url "$baseA/GuardarConfiguracion" -description "Guarda la configuración general del sistema." -body @"
{
  "idUsuario": 1,
  "configJSON": "{\"tiempoEsperaConductor\":5,\"radioBusqueda\":3,\"versionApp\":\"2.1.0\"}"
}
"@

$adminItems += New-Request -name "ActualizarConfiguracionCosto" -method "POST" -url "$baseA/ActualizarConfiguracionCosto" -description "Actualiza la configuración de costos/tarifas de una compañía." -body @"
{
  "idCompania": 1,
  "costoMin": 25.00,
  "costoKm": 8.50,
  "costoHora": 150.00,
  "costoNoche": 12.00,
  "idUsuario": 1
}
"@

$adminItems += New-Request -name "ActualizarConfiguracionSistema" -method "POST" -url "$baseA/ActualizarConfiguracionSistema" -description "Actualiza una clave de configuración del sistema." -body @"
{
  "clave": "tiempoEsperaConductor",
  "valor": "10",
  "idUsuario": 1
}
"@

$adminItems += New-Request -name "ListarCompanias" -method "GET" -url "$baseA/ListarCompanias" -description "Lista todas las compañías registradas."

$adminItems += New-Request -name "ActualizarCompania" -method "POST" -url "$baseA/ActualizarCompania" -description "Actualiza los datos de una compañía." -body @"
{
  "idCompania": 1,
  "nombre": "Vaia Viajes CDMX",
  "pagoTarjeta": true,
  "idUsuario": 1
}
"@

$adminItems += New-Request -name "ListarSemanasCorte" -method "GET" -url "$baseA/ListarSemanasCorte" -description "Lista las semanas de corte de un conductor." -query @(
    (QP "idConductor" "1")
    (QP "idCompania" "1")
    (QP "pagina" "1")
    (QP "tamano" "10")
)

$adminItems += New-Request -name "ProcesarSemanaCorte" -method "POST" -url "$baseA/ProcesarSemanaCorte" -description "Procesa y autoriza el pago de una semana de corte." -body @"
{
  "idSemanaCorte": 1,
  "idUsuario": 1
}
"@

$adminItems += New-Request -name "ListarRazonesSocialesConductores" -method "GET" -url "$baseA/ListarRazonesSocialesConductores" -description "Lista las razones sociales disponibles para conductores."

$adminItems += New-Request -name "ListarNotificaciones" -method "GET" -url "$baseA/ListarNotificaciones" -description "Lista las notificaciones enviadas con paginación." -query @(
    (QP "pagina" "1")
    (QP "tamano" "10")
)

$adminItems += New-Request -name "EnviarNotificacion" -method "POST" -url "$baseA/EnviarNotificacion" -description "Envía una notificación push a pasajeros, conductores o un tópico." -body @"
{
  "idUsuario": 1,
  "titulo": "Promoción especial",
  "mensaje": "Disfruta 15% de descuento en tu próximo viaje",
  "idPasajero": 0,
  "idConductor": 0,
  "topico": "todos"
}
"@

$adminItems += New-Request -name "ListarAvisos" -method "GET" -url "$baseA/ListarAvisos" -description "Lista los avisos/publicaciones con paginación y filtro por compañía." -query @(
    (QP "pagina" "1")
    (QP "tamano" "10")
    (QP "idCompania" "1")
)

$adminItems += New-Request -name "AgregarAviso" -method "POST" -url "$baseA/AgregarAviso" -description "Crea un nuevo aviso/publicación." -body @"
{
  "idUsuario": 1,
  "idCompania": 1,
  "titulo": "Mantenimiento programado",
  "mensaje": "El sistema estará en mantenimiento el domingo 2AM-4AM",
  "dirigidoA": "todos",
  "fechaVigenciaInicio": "2025-06-01",
  "fechaVigenciaFin": "2025-06-30"
}
"@

$adminItems += New-Request -name "EditarAviso" -method "POST" -url "$baseA/EditarAviso" -description "Edita un aviso existente." -body @"
{
  "idAviso": 1,
  "idUsuario": 1,
  "titulo": "Mantenimiento programado (actualizado)",
  "mensaje": "El sistema estará en mantenimiento el domingo 3AM-5AM",
  "fechaVigenciaInicio": "2025-06-01",
  "fechaVigenciaFin": "2025-07-15"
}
"@

$adminItems += New-Request -name "EliminarAviso" -method "POST" -url "$baseA/EliminarAviso" -description "Elimina un aviso/publicación." -body @"
{
  "idAviso": 1,
  "idUsuario": 1
}
"@

$adminItems += New-Request -name "ListarAuditoria" -method "GET" -url "$baseA/ListarAuditoria" -description "Lista los registros de auditoría con paginación y filtros." -query @(
    (QP "pagina" "1")
    (QP "tamano" "10")
    (QP "fi" "2025-01-01")
    (QP "ff" "2025-12-31")
    (QP "idUsuario" "0")
    (QP "tabla" "")
    (QP "accion" "")
)

$adminItems += New-Request -name "ObtenerLogs" -method "GET" -url "$baseA/ObtenerLogs" -description "Obtiene los logs del sistema con paginación y filtros." -query @(
    (QP "pagina" "1")
    (QP "tamano" "10")
    (QP "nivel" "error")
    (QP "modulo" "api")
)

$adminItems += New-Request -name "AprobarUnidad" -method "POST" -url "$baseA/AprobarUnidad" -description "Aprueba o rechaza una unidad (vehículo) de un conductor." -body @"
{
  "idConductor": 1,
  "idUnidad": 1,
  "idUsuario": 1
}
"@

$adminItems += New-Request -name "ValidarDocumentoUnidad" -method "POST" -url "$baseA/ValidarDocumentoUnidad" -description "Valida un documento de una unidad (vehículo)." -body @"
{
  "idDoc": 1,
  "idUsuario": 1,
  "validado": true,
  "correccion": false,
  "coment": "Documento de unidad aprobado"
}
"@

# ─── Build collection ───
$collection.item += New-Folder -name "Pasajero" -description "Endpoints para la aplicación móvil del pasajero" -baseUrl $base -requests $pasajeroItems
$collection.item += New-Folder -name "Conductor" -description "Endpoints para la aplicación móvil del conductor" -baseUrl $baseC -requests $conductorItems
$collection.item += New-Folder -name "Admin Web" -description "Endpoints para el panel de administración web" -baseUrl $baseA -requests $adminItems

$json = $collection | ConvertTo-Json -Depth 10

$writer = New-Object System.IO.StreamWriter($outputPath, $false, [System.Text.Encoding]::UTF8)
$writer.Write($json)
$writer.Close()

$file = Get-Item -LiteralPath $outputPath
Write-Host "Archivo generado: $outputPath"
Write-Host ("Tamano: " + $file.Length + " bytes")
