using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

[Route("api/[controller]")]
[ApiController]
public class AdminController : ControllerBase
{
    [HttpPost("IniciarSesion")] public async Task<IActionResult> IniciarSesion([FromBody] dynamic p) { var d = ParameterHelper.ToDictionary(p); d["pass"] = ParameterHelper.Sha256Hash((string)d["pass"]); return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_IniciarSesion", d)); }
    [HttpPost("CerrarSesion")] public async Task<IActionResult> CerrarSesion([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_CerrarSesion", p)); }
    [HttpPost("CrearUsuario")] public async Task<IActionResult> CrearUsuario([FromBody] dynamic p) { var d = ParameterHelper.ToDictionary(p); d["pass"] = ParameterHelper.Sha256Hash((string)d["pass"]); return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_Crear", d)); }
    [HttpPost("EditarUsuario")] public async Task<IActionResult> EditarUsuario([FromBody] dynamic p) { var d = ParameterHelper.ToDictionary(p); if (d.ContainsKey("pass")) d["pass"] = ParameterHelper.Sha256Hash((string)d["pass"]); return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_Actualizar", d)); }
    [HttpPost("EliminarUsuario")] public async Task<IActionResult> EliminarUsuario([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_Eliminar", p)); }
    [HttpGet("ListarUsuarios")] public async Task<IActionResult> ListarUsuarios(int pagina = 1, int tamano = 50, int? idRol = null, bool? activo = null, string buscar = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_Listar", new { pagina, tamano, idRol, activo, search = buscar })); }
    [HttpGet("ObtenerUsuario")] public async Task<IActionResult> ObtenerUsuario(int idUsuario) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_Obtener", new { idUsuario })); }
    [HttpGet("ListarRoles")] public async Task<IActionResult> ListarRoles() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_rol_Listar")); }
    [HttpGet("ListarPermisosXRol")] public async Task<IActionResult> ListarPermisosXRol(int idRol) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_rol_ListarPermisos", new { idRol })); }

    [HttpGet("ListarPasajeros")] public async Task<IActionResult> ListarPasajeros(int pagina = 1, int tamano = 50, short? idCompania = null, bool? activo = null, string buscar = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_Listar", new { pagina, tamano, idCompania, activo, search = buscar })); }
    [HttpGet("ObtenerPasajero")] public async Task<IActionResult> ObtenerPasajero(long idPasajero) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_Obtener", new { idPasajero })); }
    [HttpPost("ActualizarPasajero")] public async Task<IActionResult> ActualizarPasajero([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_Actualizar", p)); }
    [HttpPost("SuspenderPasajero")] public async Task<IActionResult> SuspenderPasajero([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_Bloquear", p)); }
    [HttpPost("AsignarSaldoPasajero")] public async Task<IActionResult> AsignarSaldoPasajero([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_AsignarSaldo", p)); }

    [HttpGet("ListarConductores")] public async Task<IActionResult> ListarConductores(int pagina = 1, int tamano = 50, short? idCompania = null, bool? activo = null, string buscar = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_Listar", new { pagina, tamano, idCompania, activo, search = buscar })); }
    [HttpGet("ObtenerConductor")] public async Task<IActionResult> ObtenerConductor(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_Obtener", new { idConductor })); }
    [HttpPost("ActualizarConductor")] public async Task<IActionResult> ActualizarConductor([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_Actualizar", p)); }
    [HttpPost("SuspenderConductor")] public async Task<IActionResult> SuspenderConductor([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_Bloquear", p)); }
    [HttpPost("ValidarDocumento")] public async Task<IActionResult> ValidarDocumento([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ValidarDocumento", p)); }
    [HttpGet("ListarDocumentosConductor")] public async Task<IActionResult> ListarDocumentosConductor(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ListarDocumentos", new { idConductor })); }
    [HttpPost("AprobarUnidad")] public async Task<IActionResult> AprobarUnidad([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_AprobarUnidad", p)); }
    [HttpPost("ValidarDocumentoUnidad")] public async Task<IActionResult> ValidarDocumentoUnidad([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ValidarDocumentoUnidad", p)); }

    [HttpPost("GestionarServicio")] public async Task<IActionResult> GestionarServicio([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_servicio_Gestionar", p)); }
    [HttpGet("ListarServicios")] public async Task<IActionResult> ListarServicios(int pagina = 1, int tamano = 50, System.DateTime? fi = null, System.DateTime? ff = null, int? idEstatusViaje = null, short? idCompania = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_servicio_Listar", new { pagina, tamano, fi, ff, idEstatusViaje, idCompania })); }
    [HttpGet("DetalleServicio")] public async Task<IActionResult> DetalleServicio(long idServicio) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_servicio_Detalle", new { idServicio })); }
    [HttpGet("ListarEstatusServicio")] public async Task<IActionResult> ListarEstatusServicio() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_servicio_ListarEstatus")); }

    [HttpGet("ReporteServicios")] public async Task<IActionResult> ReporteServicios(System.DateTime? fi = null, System.DateTime? ff = null, short? idCompania = null, int? idEstatusViaje = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_reporte_Servicios", new { fi, ff, idCompania, idEstatusViaje })); }
    [HttpGet("ReportePasajeros")] public async Task<IActionResult> ReportePasajeros(System.DateTime? fi = null, System.DateTime? ff = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_reporte_Pasajeros", new { fi, ff })); }
    [HttpGet("ReporteConductores")] public async Task<IActionResult> ReporteConductores(System.DateTime? fi = null, System.DateTime? ff = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_reporte_Conductores", new { fi, ff })); }
    [HttpGet("ReporteIngresos")] public async Task<IActionResult> ReporteIngresos(System.DateTime? fi = null, System.DateTime? ff = null, short? idCompania = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_reporte_Ingresos", new { fi, ff, idCompania })); }
    [HttpGet("ReporteComisiones")] public async Task<IActionResult> ReporteComisiones(System.DateTime? fi = null, System.DateTime? ff = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_reporte_Comisiones", new { fi, ff })); }
    [HttpGet("ReporteUtilidadDiaria")] public async Task<IActionResult> ReporteUtilidadDiaria(System.DateTime? fecha = null, short? idCompania = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_reporte_UtilidadDiaria", new { fecha, idCompania })); }

    [HttpGet("ListarIncidentes")] public async Task<IActionResult> ListarIncidentes(int pagina = 1, int tamano = 50, System.DateTime? fi = null, System.DateTime? ff = null, int? idTipoIncidente = null, long? idServicio = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_incidente_Listar", new { pagina, tamano, fi, ff, idTipoIncidente, idServicio })); }
    [HttpGet("DetalleIncidente")] public async Task<IActionResult> DetalleIncidente(long idIncidente) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_incidente_Detalle", new { idIncidente })); }
    [HttpGet("TiposIncidente")] public async Task<IActionResult> TiposIncidente() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_incidente_ListarTipos")); }
    [HttpGet("ListaIncidentesTablas")] public async Task<IActionResult> ListaIncidentesTablas() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_incidente_ListarTablas")); }
    [HttpPost("ActualizarEstatusIncidente")] public async Task<IActionResult> ActualizarEstatusIncidente([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_incidente_ActualizarEstatus", p)); }

    [HttpGet("ListarPromociones")] public async Task<IActionResult> ListarPromociones(int pagina = 1, int tamano = 50, bool? activo = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_promocion_Listar", new { pagina, tamano, activo })); }
    [HttpPost("CrearPromocion")] public async Task<IActionResult> CrearPromocion([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_promocion_Crear", p)); }
    [HttpPost("EditarPromocion")] public async Task<IActionResult> EditarPromocion([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_promocion_Actualizar", p)); }
    [HttpPost("EliminarPromocion")] public async Task<IActionResult> EliminarPromocion([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_promocion_Eliminar", p)); }
    [HttpPost("GenerarCodigoPromocional")] public async Task<IActionResult> GenerarCodigoPromocional([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_promocion_GenerarCodigo", p)); }

    [HttpGet("ListarZonasCobertura")] public async Task<IActionResult> ListarZonasCobertura(int pagina = 1, int tamano = 50, bool? activo = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_zona_Listar", new { pagina, tamano, activo })); }
    [HttpPost("AgregarZonaCobertura")] public async Task<IActionResult> AgregarZonaCobertura([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_zona_Crear", p)); }
    [HttpPost("EditarZonaCobertura")] public async Task<IActionResult> EditarZonaCobertura([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_zona_Actualizar", p)); }
    [HttpPost("EliminarZonaCobertura")] public async Task<IActionResult> EliminarZonaCobertura([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_zona_Eliminar", p)); }
    [HttpGet("ObtenerComisionesZona")] public async Task<IActionResult> ObtenerComisionesZona(int idZona) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_zona_ObtenerComisiones", new { idZona })); }
    [HttpPost("ActualizarComisionZona")] public async Task<IActionResult> ActualizarComisionZona([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_zona_ActualizarComision", p)); }

    [HttpGet("ObtenerConfiguracion")] public async Task<IActionResult> ObtenerConfiguracion() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_configuracion_Obtener")); }
    [HttpPost("GuardarConfiguracion")] public async Task<IActionResult> GuardarConfiguracion([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_configuracion_Guardar", p)); }
    [HttpPost("ActualizarConfiguracionCosto")] public async Task<IActionResult> ActualizarConfiguracionCosto([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_configuracion_ActualizarCosto", p)); }
    [HttpPost("ActualizarConfiguracionSistema")] public async Task<IActionResult> ActualizarConfiguracionSistema([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_configuracion_ActualizarSistema", p)); }

    [HttpGet("ListarCompanias")] public async Task<IActionResult> ListarCompanias() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_compania_Listar")); }
    [HttpPost("ActualizarCompania")] public async Task<IActionResult> ActualizarCompania([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_compania_Actualizar", p)); }

    [HttpGet("ListarSemanasCorte")] public async Task<IActionResult> ListarSemanasCorte(int? idConductor = null, short? idCompania = null, int pagina = 1, int tamano = 50) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_corte_ListarSemanas", new { idConductor, idCompania, pagina, tamano })); }
    [HttpPost("ProcesarSemanaCorte")] public async Task<IActionResult> ProcesarSemanaCorte([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_corte_Procesar", p)); }
    [HttpGet("ListarRazonesSocialesConductores")] public async Task<IActionResult> ListarRazonesSocialesConductores() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ListarRazonesSociales")); }

    [HttpGet("ListarNotificaciones")] public async Task<IActionResult> ListarNotificaciones(int pagina = 1, int tamano = 50) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_notificacion_Listar", new { pagina, tamano })); }
    [HttpPost("EnviarNotificacion")] public async Task<IActionResult> EnviarNotificacion([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_notificacion_Enviar", p)); }

    [HttpGet("ListarAvisos")] public async Task<IActionResult> ListarAvisos(int pagina = 1, int tamano = 50, short? idCompania = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_aviso_Listar", new { pagina, tamano, idCompania })); }
    [HttpPost("AgregarAviso")] public async Task<IActionResult> AgregarAviso([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_aviso_Crear", p)); }
    [HttpPost("EditarAviso")] public async Task<IActionResult> EditarAviso([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_aviso_Actualizar", p)); }
    [HttpPost("EliminarAviso")] public async Task<IActionResult> EliminarAviso([FromBody] dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_aviso_Eliminar", p)); }
    [HttpGet("ListarAuditoria")] public async Task<IActionResult> ListarAuditoria(int pagina = 1, int tamano = 50, System.DateTime? fi = null, System.DateTime? ff = null, int? idUsuario = null, string tabla = null, string accion = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_auditoria_Listar", new { pagina, tamano, fi, ff, idUsuario, tabla, accion })); }
    [HttpGet("ObtenerLogs")] public async Task<IActionResult> ObtenerLogs(int pagina = 1, int tamano = 50, string nivel = null, string modulo = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_log_Listar", new { pagina, tamano, nivel, modulo })); }
}
