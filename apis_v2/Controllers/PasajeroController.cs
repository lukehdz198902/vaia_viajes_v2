using System.Threading.Tasks;
using System.Web.Http;

public class PasajeroController : ApiController
{
    /// <summary>Registra un nuevo pasajero en la plataforma.</summary>
    [HttpPost] public async Task<IHttpActionResult> Registrar(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_Registrar", p)); }
    /// <summary>Inicia sesion de un pasajero validando credenciales o login con Google.</summary>
    [HttpPost] public async Task<IHttpActionResult> IniciarSesion(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_IniciarSesion", p)); }
    /// <summary>Cierra la sesion activa del pasajero.</summary>
    [HttpPost] public async Task<IHttpActionResult> CerrarSesion(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_CerrarSesion", p)); }
    /// <summary>Actualiza los datos del perfil del pasajero.</summary>
    [HttpPost] public async Task<IHttpActionResult> ActualizarPerfil(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ActualizarPerfil", p)); }
    /// <summary>Obtiene el perfil completo de un pasajero por su ID.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerPerfil(long idPasajero) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerPerfil", new { idPasajero })); }
    /// <summary>Cambia la contrasena del pasajero validando la actual.</summary>
    [HttpPost] public async Task<IHttpActionResult> CambiarPassword(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_CambiarPassword", p)); }
    /// <summary>Envia un codigo de verificacion SMS al telefono del pasajero.</summary>
    [HttpPost] public async Task<IHttpActionResult> EnviarCodigoVerificacion(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_EnviarCodigoVerificacion", p)); }
    /// <summary>Cambia el telefono del pasajero validando codigo de verificacion.</summary>
    [HttpPost] public async Task<IHttpActionResult> CambiarTelefono(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_CambiarTelefono", p)); }
    /// <summary>Valida si un codigo promocional es aplicable al viaje.</summary>
    [HttpPost] public async Task<IHttpActionResult> ValidarCodigoPromocional(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ValidarCodigoPromocional", p)); }
    /// <summary>Solicita un nuevo servicio de viaje desde la app del pasajero.</summary>
    [HttpPost] public async Task<IHttpActionResult> SolicitarServicio(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_SolicitarServicio", p)); }
    /// <summary>Obtiene los conductores disponibles cercanos a una ubicacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ConductoresDisponibles(string lat, string lng, int? idZona) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ConductoresDisponibles", new { lat, lng, idZona })); }
    /// <summary>Consulta el estado actual de un servicio solicitado.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerEstadoServicio(long idServicio, long idPasajero) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerEstadoServicio", new { idServicio, idPasajero })); }
    /// <summary>Cancela un servicio activo indicando el motivo.</summary>
    [HttpPost] public async Task<IHttpActionResult> CancelarServicio(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_CancelarServicio", p)); }
    /// <summary>Califica un viaje finalizado con puntuacion y comentarios.</summary>
    [HttpPost] public async Task<IHttpActionResult> CalificarViaje(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_CalificarViaje", p)); }
    /// <summary>Activa la alarma de emergencia SOS durante un servicio.</summary>
    [HttpPost] public async Task<IHttpActionResult> ActivarAlarmaSOS(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ActivarAlarmaSOS", p)); }
    /// <summary>Agrega una direccion a la lista de favoritos del pasajero.</summary>
    [HttpPost] public async Task<IHttpActionResult> AgregarFavorito(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_AgregarFavorito", p)); }
    /// <summary>Lista las direcciones favoritas del pasajero.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarFavoritos(long idPasajero) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ListarFavoritos", new { idPasajero })); }
    /// <summary>Elimina una direccion de la lista de favoritos.</summary>
    [HttpPost] public async Task<IHttpActionResult> EliminarFavorito(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_EliminarFavorito", p)); }
    /// <summary>Obtiene el historial de viajes del pasajero con paginacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> HistorialViajes(long idPasajero, int pagina = 1, int tamano = 20, System.DateTime? fi = null, System.DateTime? ff = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_HistorialViajes", new { idPasajero, pagina, tamano, fi, ff })); }
    /// <summary>Obtiene el detalle completo de un viaje especifico.</summary>
    [HttpGet]  public async Task<IHttpActionResult> DetalleViaje(long idServicio, long idPasajero) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_DetalleViaje", new { idServicio, idPasajero })); }
    /// <summary>Reporta un incidente ocurrido durante un servicio.</summary>
    [HttpPost] public async Task<IHttpActionResult> ReportarIncidente(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ReportarIncidente", p)); }
    /// <summary>Obtiene la configuracion de costos vigente para una compania.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerConfiguracionCostos(short idCompania) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerConfiguracionCostos", new { idCompania })); }
    /// <summary>Obtiene los avisos activos para una compania.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerAvisos(short idCompania) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerAvisos", new { idCompania })); }
    /// <summary>Obtiene el listado de promociones disponibles.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerPromociones() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerPromociones")); }
    /// <summary>Obtiene las propagandas/publicidad activas.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerPropagandas() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerPropagandas")); }
    /// <summary>Envia un mensaje de chat durante un servicio activo.</summary>
    [HttpPost] public async Task<IHttpActionResult> EnviarMensajeChat(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_EnviarMensajeChat", p)); }
    /// <summary>Obtiene los mensajes de chat de un servicio.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerMensajesChat(long idServicio, long idPasajero) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerMensajesChat", new { idServicio, idPasajero })); }
}
