using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

[Route("api/[controller]")]
[ApiController]
public class ConductorController : ControllerBase
{
    [HttpPost("Registrar")] public async Task<IActionResult> Registrar([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_Registrar", p)); }
    [HttpPost("IniciarSesion")] public async Task<IActionResult> IniciarSesion([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_IniciarSesion", p)); }
    [HttpPost("CerrarSesion")] public async Task<IActionResult> CerrarSesion([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_CerrarSesion", p)); }
    [HttpGet("ObtenerPerfil")] public async Task<IActionResult> ObtenerPerfil(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerPerfil", new { idConductor })); }
    [HttpPost("ActualizarPerfil")] public async Task<IActionResult> ActualizarPerfil([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ActualizarPerfil", p)); }
    [HttpPost("CambiarPassword")] public async Task<IActionResult> CambiarPassword([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_CambiarPassword", p)); }
    [HttpPost("ActualizarUbicacion")] public async Task<IActionResult> ActualizarUbicacion([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ActualizarUbicacion", p)); }
    [HttpPost("CambiarEstatus")] public async Task<IActionResult> CambiarEstatus([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_CambiarEstatus", p)); }
    [HttpPost("AceptarServicio")] public async Task<IActionResult> AceptarServicio([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_AceptarServicio", p)); }
    [HttpPost("IniciarViaje")] public async Task<IActionResult> IniciarViaje([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_IniciarViaje", p)); }
    [HttpPost("FinalizarViaje")] public async Task<IActionResult> FinalizarViaje([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_FinalizarViaje", p)); }
    [HttpGet("ListarUnidades")] public async Task<IActionResult> ListarUnidades(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ListarUnidades", new { idConductor })); }
    [HttpPost("SeleccionarUnidad")] public async Task<IActionResult> SeleccionarUnidad([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_SeleccionarUnidad", p)); }
    [HttpGet("HistorialViajes")] public async Task<IActionResult> HistorialViajes(int idConductor, int pagina = 1, int tamano = 20, System.DateTime? fi = null, System.DateTime? ff = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_HistorialViajes", new { idConductor, pagina, tamano, fi, ff })); }
    [HttpGet("DetalleViaje")] public async Task<IActionResult> DetalleViaje(long idServicio, int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_DetalleViaje", new { idServicio, idConductor })); }
    [HttpGet("ObtenerSemanaCorte")] public async Task<IActionResult> ObtenerSemanaCorte(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerSemanaCorte", new { idConductor })); }
    [HttpPost("TransferirSemanaCorte")] public async Task<IActionResult> TransferirSemanaCorte([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_TransferirSemanaCorte", p)); }
    [HttpPost("EnviarMensajeChat")] public async Task<IActionResult> EnviarMensajeChat([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_EnviarMensajeChat", p)); }
    [HttpGet("ObtenerMensajesChat")] public async Task<IActionResult> ObtenerMensajesChat(long idServicio, int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerMensajesChat", new { idServicio, idConductor })); }
    [HttpPost("ActivarAlarmaSOS")] public async Task<IActionResult> ActivarAlarmaSOS([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ActivarAlarmaSOS", p)); }
    [HttpPost("ReportarIncidente")] public async Task<IActionResult> ReportarIncidente([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ReportarIncidente", p)); }
    [HttpGet("ObtenerNotificaciones")] public async Task<IActionResult> ObtenerNotificaciones(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerNotificaciones", new { idConductor })); }
    [HttpGet("ObtenerAvisos")] public async Task<IActionResult> ObtenerAvisos(short idCompania) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerAvisos", new { idCompania })); }
    [HttpGet("ObtenerServicioActivo")] public async Task<IActionResult> ObtenerServicioActivo(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerServicioActivo", new { idConductor })); }
}
