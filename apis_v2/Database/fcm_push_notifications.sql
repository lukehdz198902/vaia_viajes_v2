================================================================================
  FCM PUSH NOTIFICATIONS - CONFIGURACION Y REFERENCIA
  Proyecto: apis_v2 (ASP.NET Core 2.2 - .NET Framework 4.8)
================================================================================

DESCRIPCION:
  Este script documenta la configuracion necesaria para el envio de
  notificaciones push mediante Firebase Cloud Messaging (FCM).

  TODAS las consultas a base de datos se realizan mediante
  stored procedures (ver sp_notificacion_push.sql).

================================================================================
1. CONFIGURACION EN appsettings.json
================================================================================

Agregar al archivo appsettings.json la clave del servidor FCM:

{
  "ConnectionStrings": {
    "VaiaViajes": "Data Source=.;Initial Catalog=vaia_viajes;Integrated Security=True;"
  },
  "Fcm": {
    "ServerKey": "AAAA_...TU_CLAVE_FCM_AQUI..."
  }
}

La clave se obtiene de:
  Firebase Console > Proyecto > Cloud Messaging > Clave del servidor

================================================================================
2. TOKENS FCM EN LA BASE DE DATOS (via Stored Procedures)
================================================================================

Los tokens FCM se almacenan en el campo 'googlekey' de las tablas:

  tbpasajero.googlekey    -> VARCHAR(MAX) - Token FCM del pasajero
  tbconductor.googlekey   -> VARCHAR(MAX) - Token FCM del conductor

Archivo de SPs: sp_notificacion_push.sql
  sp_notificacion_ObtenerTokenPasajero             @idPasajero     -> googlekey
  sp_notificacion_ObtenerTokenConductor             @idConductor    -> googlekey
  sp_notificacion_ObtenerNombreConductor            @idConductor    -> nombreCompleto
  sp_notificacion_ObtenerNombrePasajero             @idPasajero     -> nombreCompleto
  sp_notificacion_ObtenerTokensConductoresCompania  @idCompania     -> googlekey (lista)

Los tokens se actualizan automaticamente durante el inicio de sesion:

  sp_pasajero_IniciarSesion  -> actualiza googlekey en tbpasajero
  sp_conductor_IniciarSesion -> actualiza googlekey en tbconductor

================================================================================
3. EVENTOS QUE DISPARAN NOTIFICACIONES PUSH
================================================================================

Pasajero -> Conductores cercanos:
  Evento:    SolicitarServicio
  Titulo:    "Nuevo servicio disponible"
  Cuerpo:    "Hay un nuevo viaje solicitado cerca de tu ubicacion"
  Tipo:      new_ride
  SP:        sp_notificacion_ObtenerTokensConductoresCompania
  Destino:   Todos los conductores activos de la compania

Conductor -> Pasajero:
  Evento:    AceptarServicio
  Titulo:    "Conductor en camino"
  Cuerpo:    "[Nombre] ha aceptado tu servicio y va en camino"
  Tipo:      ride_accepted
  SP:        sp_notificacion_ObtenerTokenPasajero
  Destino:   Pasajero del servicio

Conductor -> Pasajero:
  Evento:    IniciarViaje
  Titulo:    "Viaje iniciado"
  Cuerpo:    "Tu viaje ha comenzado. Disfruta el trayecto!"
  Tipo:      ride_started
  SP:        sp_notificacion_ObtenerTokenPasajero
  Destino:   Pasajero del servicio

Conductor -> Pasajero:
  Evento:    FinalizarViaje
  Titulo:    "Viaje finalizado"
  Cuerpo:    "Has llegado a tu destino. Califica tu experiencia"
  Tipo:      ride_finished
  SP:        sp_notificacion_ObtenerTokenPasajero
  Destino:   Pasajero del servicio

Pasajero -> Conductor:
  Evento:    CancelarServicio
  Titulo:    "Servicio cancelado"
  Cuerpo:    "[Nombre] ha cancelado el servicio #[id]"
  Tipo:      ride_cancelled
  SP:        sp_notificacion_ObtenerTokenConductor
  Destino:   Conductor del servicio

Chat:
  Evento:    EnviarMensajeChat (ambos lados)
  Titulo:    "Mensaje de [Nombre]"
  Cuerpo:    "[texto del mensaje]"
  Tipo:      chat_message
  SP:        sp_notificacion_ObtenerTokenPasajero / sp_notificacion_ObtenerTokenConductor
  Destino:   La otra parte del chat

SOS - Alarma de emergencia:
  Evento:    ActivarAlarmaSOS (ambos lados)
  Titulo:    "ALERTA SOS"
  Cuerpo:    "[Quien] ha activado la alarma de emergencia"
  Tipo:      sos_passenger / sos_conductor
  SP:        sp_notificacion_ObtenerTokenPasajero / sp_notificacion_ObtenerTokenConductor
  Destino:   La otra parte del servicio

================================================================================
4. ESTRUCTURA DEL PAYLOAD FCM
================================================================================

Notificacion individual:
  {
    "to": "<TOKEN_FCM>",
    "notification": {
      "title": "Titulo de la notificacion",
      "body": "Cuerpo de la notificacion",
      "sound": "default"
    },
    "data": {
      "type": "ride_accepted|ride_started|ride_finished|ride_cancelled|new_ride|chat_message|sos_passenger|sos_conductor",
      "idservicio": "123"
    },
    "priority": "high"
  }

Multiples dispositivos:
  {
    "registration_ids": ["token1", "token2", ...],
    ...
  }

================================================================================
5. CODIGOS TIPO EN data.type
================================================================================

  new_ride          -> Nuevo servicio solicitado (para conductores)
  ride_accepted     -> Conductor acepto el servicio (para pasajero)
  ride_started      -> Viaje iniciado (para pasajero)
  ride_finished     -> Viaje finalizado (para pasajero)
  ride_cancelled    -> Servicio cancelado (para conductor)
  chat_message      -> Nuevo mensaje de chat (para ambos lados)
  sos_passenger     -> Alarma SOS activada por pasajero (para conductor)
  sos_conductor     -> Alarma SOS activada por conductor (para pasajero)

================================================================================
6. VERIFICACION DE ENTREGA
================================================================================

Prueba manual con curl:

  curl -X POST https://fcm.googleapis.com/fcm/send ^
    -H "Authorization: key=AAAA_SERVER_KEY" ^
    -H "Content-Type: application/json" ^
    -d "{\"to\":\"<TOKEN_FCM>\",\"notification\":{\"title\":\"Prueba\",\"body\":\"Notificacion de prueba\"}}"

La respuesta FCM incluye:
  - success: numero de dispositivos que recibieron el mensaje
  - failure: numero de dispositivos que fallaron
  - results: arreglo con detalles individuales (error si el token es invalido)

================================================================================
FIN DEL DOCUMENTO
================================================================================
