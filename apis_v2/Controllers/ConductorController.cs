using System.Threading.Tasks;
using System.Web.Http;

public class ConductorController : ApiController
{
    /// <summary>Registra un nuevo conductor en la plataforma.</summary>
    [HttpPost] public async Task<IHttpActionResult> Registrar(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_Registrar", p)); }
    /// <summary>Inicia sesion de un conductor validando credenciales.</summary>
    [HttpPost] public async Task<IHttpActionResult> IniciarSesion(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_IniciarSesion", p)); }
    /// <summary>Cierra la sesion activa del conductor.</summary>
    [HttpPost] public async Task<IHttpActionResult> CerrarSesion(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_CerrarSesion", p)); }
    /// <summary>Obtiene el perfil completo de un conductor por su ID.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerPerfil(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerPerfil", new { idConductor })); }
    /// <summary>Actualiza los datos del perfil del conductor.</summary>
    [HttpPost] public async Task<IHttpActionResult> ActualizarPerfil(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ActualizarPerfil", p)); }
    /// <summary>Cambia la contrasena del conductor validando la actual.</summary>
    [HttpPost] public async Task<IHttpActionResult> CambiarPassword(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_CambiarPassword", p)); }
    /// <summary>Actualiza la ubicacion en tiempo real del conductor.</summary>
    [HttpPost] public async Task<IHttpActionResult> ActualizarUbicacion(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ActualizarUbicacion", p)); }
    /// <summary>Cambia el estatus de disponibilidad del conductor.</summary>
    [HttpPost] public async Task<IHttpActionResult> CambiarEstatus(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_CambiarEstatus", p)); }
    /// <summary>Acepta un servicio asignado al conductor.</summary>
    [HttpPost] public async Task<IHttpActionResult> AceptarServicio(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_AceptarServicio", p)); }
    /// <summary>Registra el inicio del viaje (conductor en camino o viaje iniciado).</summary>
    [HttpPost] public async Task<IHttpActionResult> IniciarViaje(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_IniciarViaje", p)); }
    /// <summary>Finaliza el viaje registrando ubicacion final y kilometraje.</summary>
    [HttpPost] public async Task<IHttpActionResult> FinalizarViaje(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_FinalizarViaje", p)); }
    /// <summary>Lista las unidades registradas del conductor.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarUnidades(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ListarUnidades", new { idConductor })); }
    /// <summary>Selecciona la unidad que usara el conductor para viajes.</summary>
    [HttpPost] public async Task<IHttpActionResult> SeleccionarUnidad(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_SeleccionarUnidad", p)); }
    /// <summary>Obtiene el historial de viajes del conductor con paginacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> HistorialViajes(int idConductor, int pagina = 1, int tamano = 20, System.DateTime? fi = null, System.DateTime? ff = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_HistorialViajes", new { idConductor, pagina, tamano, fi, ff })); }
    /// <summary>Obtiene el detalle completo de un viaje para el conductor.</summary>
    [HttpGet]  public async Task<IHttpActionResult> DetalleViaje(long idServicio, int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_DetalleViaje", new { idServicio, idConductor })); }
    /// <summary>Obtiene la semana de corte actual del conductor.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerSemanaCorte(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerSemanaCorte", new { idConductor })); }
    /// <summary>Solicita la transferencia de la semana de corte a su cuenta.</summary>
    [HttpPost] public async Task<IHttpActionResult> TransferirSemanaCorte(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_TransferirSemanaCorte", p)); }
    /// <summary>Envia un mensaje de chat durante un servicio activo.</summary>
    [HttpPost] public async Task<IHttpActionResult> EnviarMensajeChat(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_EnviarMensajeChat", p)); }
    /// <summary>Obtiene los mensajes de chat de un servicio.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerMensajesChat(long idServicio, int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerMensajesChat", new { idServicio, idConductor })); }
    /// <summary>Activa la alarma de emergencia SOS durante un servicio.</summary>
    [HttpPost] public async Task<IHttpActionResult> ActivarAlarmaSOS(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ActivarAlarmaSOS", p)); }
    /// <summary>Reporta un incidente ocurrido durante un servicio.</summary>
    [HttpPost] public async Task<IHttpActionResult> ReportarIncidente(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ReportarIncidente", p)); }
    /// <summary>Obtiene las notificaciones pendientes del conductor.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerNotificaciones(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerNotificaciones", new { idConductor })); }
    /// <summary>Obtiene los avisos activos para una compania.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerAvisos(short idCompania) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerAvisos", new { idCompania })); }
    /// <summary>Obtiene el servicio activo actual del conductor.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerServicioActivo(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerServicioActivo", new { idConductor })); }
}
