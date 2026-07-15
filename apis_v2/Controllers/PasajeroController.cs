using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

[Route("api/[controller]")]
[ApiController]
public class PasajeroController : ControllerBase
{
    [HttpPost("Registrar")] public async Task<IActionResult> Registrar([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_Registrar", p)); }
    [HttpPost("IniciarSesion")] public async Task<IActionResult> IniciarSesion([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_IniciarSesion", p)); }
    [HttpPost("CerrarSesion")] public async Task<IActionResult> CerrarSesion([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_CerrarSesion", p)); }
    [HttpPost("ActualizarPerfil")] public async Task<IActionResult> ActualizarPerfil([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ActualizarPerfil", p)); }
    [HttpGet("ObtenerPerfil")] public async Task<IActionResult> ObtenerPerfil(long idPasajero) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerPerfil", new { idPasajero })); }
    [HttpPost("CambiarPassword")] public async Task<IActionResult> CambiarPassword([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_CambiarPassword", p)); }
    [HttpPost("EnviarCodigoVerificacion")] public async Task<IActionResult> EnviarCodigoVerificacion([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_EnviarCodigoVerificacion", p)); }
    [HttpPost("CambiarTelefono")] public async Task<IActionResult> CambiarTelefono([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_CambiarTelefono", p)); }
    [HttpPost("ValidarCodigoPromocional")] public async Task<IActionResult> ValidarCodigoPromocional([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ValidarCodigoPromocional", p)); }
    [HttpPost("SolicitarServicio")] public async Task<IActionResult> SolicitarServicio([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_SolicitarServicio", p)); }
    [HttpGet("ConductoresDisponibles")] public async Task<IActionResult> ConductoresDisponibles(string lat, string lng, int? idZona) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ConductoresDisponibles", new { lat, lng, idZona })); }
    [HttpGet("ObtenerEstadoServicio")] public async Task<IActionResult> ObtenerEstadoServicio(long idServicio, long idPasajero) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerEstadoServicio", new { idServicio, idPasajero })); }
    [HttpPost("CancelarServicio")] public async Task<IActionResult> CancelarServicio([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_CancelarServicio", p)); }
    [HttpPost("CalificarViaje")] public async Task<IActionResult> CalificarViaje([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_CalificarViaje", p)); }
    [HttpPost("ActivarAlarmaSOS")] public async Task<IActionResult> ActivarAlarmaSOS([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ActivarAlarmaSOS", p)); }
    [HttpPost("AgregarFavorito")] public async Task<IActionResult> AgregarFavorito([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_AgregarFavorito", p)); }
    [HttpGet("ListarFavoritos")] public async Task<IActionResult> ListarFavoritos(long idPasajero) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ListarFavoritos", new { idPasajero })); }
    [HttpPost("EliminarFavorito")] public async Task<IActionResult> EliminarFavorito([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_EliminarFavorito", p)); }
    [HttpGet("HistorialViajes")] public async Task<IActionResult> HistorialViajes(long idPasajero, int pagina = 1, int tamano = 20, System.DateTime? fi = null, System.DateTime? ff = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_HistorialViajes", new { idPasajero, pagina, tamano, fi, ff })); }
    [HttpGet("DetalleViaje")] public async Task<IActionResult> DetalleViaje(long idServicio, long idPasajero) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_DetalleViaje", new { idServicio, idPasajero })); }
    [HttpPost("ReportarIncidente")] public async Task<IActionResult> ReportarIncidente([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ReportarIncidente", p)); }
    [HttpGet("ObtenerConfiguracionCostos")] public async Task<IActionResult> ObtenerConfiguracionCostos(short idCompania) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerConfiguracionCostos", new { idCompania })); }
    [HttpGet("ObtenerAvisos")] public async Task<IActionResult> ObtenerAvisos(short idCompania) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerAvisos", new { idCompania })); }
    [HttpGet("ObtenerPromociones")] public async Task<IActionResult> ObtenerPromociones() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerPromociones")); }
    [HttpGet("ObtenerPropagandas")] public async Task<IActionResult> ObtenerPropagandas() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerPropagandas")); }
    [HttpPost("EnviarMensajeChat")] public async Task<IActionResult> EnviarMensajeChat([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_EnviarMensajeChat", p)); }
    [HttpGet("ObtenerMensajesChat")] public async Task<IActionResult> ObtenerMensajesChat(long idServicio, long idPasajero) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerMensajesChat", new { idServicio, idPasajero })); }
}
