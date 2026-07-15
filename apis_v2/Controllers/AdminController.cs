using System.Threading.Tasks;
using System.Web.Http;

public class AdminController : ApiController
{
    /// <summary>Inicia sesion de un usuario administrador en la plataforma web.</summary>
    [HttpPost] public async Task<IHttpActionResult> IniciarSesion(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_IniciarSesion", p)); }
    /// <summary>Cierra la sesion activa del usuario administrador.</summary>
    [HttpPost] public async Task<IHttpActionResult> CerrarSesion(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_CerrarSesion", p)); }
    /// <summary>Crea un nuevo usuario del sistema (admin, supervisor, etc.).</summary>
    [HttpPost] public async Task<IHttpActionResult> CrearUsuario(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_Crear", p)); }
    /// <summary>Actualiza los datos de un usuario existente.</summary>
    [HttpPost] public async Task<IHttpActionResult> EditarUsuario(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_Actualizar", p)); }
    /// <summary>Elimina (desactiva) un usuario del sistema.</summary>
    [HttpPost] public async Task<IHttpActionResult> EliminarUsuario(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_Eliminar", p)); }
    /// <summary>Lista los usuarios del sistema con filtros y paginacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarUsuarios(int pagina = 1, int tamano = 50, int? idRol = null, bool? activo = null, string buscar = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_Listar", new { pagina, tamano, idRol, activo, search = buscar })); }
    /// <summary>Obtiene los datos de un usuario por su ID.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerUsuario(int idUsuario) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_usuario_Obtener", new { idUsuario })); }
    /// <summary>Lista todos los roles del sistema.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarRoles() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_rol_Listar")); }
    /// <summary>Lista los permisos asociados a un rol especifico.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarPermisosXRol(int idRol) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_rol_ListarPermisos", new { idRol })); }

    /// <summary>Lista los pasajeros registrados con filtros y paginacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarPasajeros(int pagina = 1, int tamano = 50, short? idCompania = null, bool? activo = null, string buscar = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_Listar", new { pagina, tamano, idCompania, activo, search = buscar })); }
    /// <summary>Obtiene los datos de un pasajero por su ID.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerPasajero(long idPasajero) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_Obtener", new { idPasajero })); }
    /// <summary>Actualiza los datos de un pasajero desde el panel admin.</summary>
    [HttpPost] public async Task<IHttpActionResult> ActualizarPasajero(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_Actualizar", p)); }
    /// <summary>Suspende/bloquea a un pasajero indicando el motivo.</summary>
    [HttpPost] public async Task<IHttpActionResult> SuspenderPasajero(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_Bloquear", p)); }
    /// <summary>Asigna saldo a la cuenta de un pasajero.</summary>
    [HttpPost] public async Task<IHttpActionResult> AsignarSaldoPasajero(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_pasajero_AsignarSaldo", p)); }

    /// <summary>Lista los conductores registrados con filtros y paginacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarConductores(int pagina = 1, int tamano = 50, short? idCompania = null, bool? activo = null, string buscar = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_Listar", new { pagina, tamano, idCompania, activo, search = buscar })); }
    /// <summary>Obtiene los datos de un conductor por su ID.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerConductor(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_Obtener", new { idConductor })); }
    /// <summary>Actualiza los datos de un conductor desde el panel admin.</summary>
    [HttpPost] public async Task<IHttpActionResult> ActualizarConductor(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_Actualizar", p)); }
    /// <summary>Suspende/bloquea a un conductor indicando el motivo.</summary>
    [HttpPost] public async Task<IHttpActionResult> SuspenderConductor(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_Bloquear", p)); }
    /// <summary>Valida o rechaza un documento de un conductor.</summary>
    [HttpPost] public async Task<IHttpActionResult> ValidarDocumento(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ValidarDocumento", p)); }
    /// <summary>Lista los documentos de un conductor.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarDocumentosConductor(int idConductor) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ListarDocumentos", new { idConductor })); }
    /// <summary>Aprueba una unidad de transporte de un conductor.</summary>
    [HttpPost] public async Task<IHttpActionResult> AprobarUnidad(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_AprobarUnidad", p)); }
    /// <summary>Valida o rechaza un documento de una unidad.</summary>
    [HttpPost] public async Task<IHttpActionResult> ValidarDocumentoUnidad(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ValidarDocumentoUnidad", p)); }

    /// <summary>Gestiona un servicio: asignar, cancelar, modificar, etc.</summary>
    [HttpPost] public async Task<IHttpActionResult> GestionarServicio(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_servicio_Gestionar", p)); }
    /// <summary>Lista los servicios con filtros de fecha, estatus y compania.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarServicios(int pagina = 1, int tamano = 50, System.DateTime? fi = null, System.DateTime? ff = null, int? idEstatusViaje = null, short? idCompania = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_servicio_Listar", new { pagina, tamano, fi, ff, idEstatusViaje, idCompania })); }
    /// <summary>Obtiene el detalle completo de un servicio.</summary>
    [HttpGet]  public async Task<IHttpActionResult> DetalleServicio(long idServicio) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_servicio_Detalle", new { idServicio })); }
    /// <summary>Lista los estatus posibles de un servicio/viaje.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarEstatusServicio() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_servicio_ListarEstatus")); }

    /// <summary>Genera reporte de servicios en un rango de fechas.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ReporteServicios(System.DateTime? fi = null, System.DateTime? ff = null, short? idCompania = null, int? idEstatusViaje = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_reporte_Servicios", new { fi, ff, idCompania, idEstatusViaje })); }
    /// <summary>Genera reporte de pasajeros registrados en un rango de fechas.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ReportePasajeros(System.DateTime? fi = null, System.DateTime? ff = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_reporte_Pasajeros", new { fi, ff })); }
    /// <summary>Genera reporte de conductores registrados en un rango de fechas.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ReporteConductores(System.DateTime? fi = null, System.DateTime? ff = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_reporte_Conductores", new { fi, ff })); }
    /// <summary>Genera reporte de ingresos en un rango de fechas.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ReporteIngresos(System.DateTime? fi = null, System.DateTime? ff = null, short? idCompania = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_reporte_Ingresos", new { fi, ff, idCompania })); }
    /// <summary>Genera reporte de comisiones en un rango de fechas.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ReporteComisiones(System.DateTime? fi = null, System.DateTime? ff = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_reporte_Comisiones", new { fi, ff })); }
    /// <summary>Genera reporte de utilidad diaria para una compania.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ReporteUtilidadDiaria(System.DateTime? fecha = null, short? idCompania = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_reporte_UtilidadDiaria", new { fecha, idCompania })); }

    /// <summary>Lista los incidentes reportados con filtros y paginacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarIncidentes(int pagina = 1, int tamano = 50, System.DateTime? fi = null, System.DateTime? ff = null, int? idTipoIncidente = null, long? idServicio = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_incidente_Listar", new { pagina, tamano, fi, ff, idTipoIncidente, idServicio })); }
    /// <summary>Obtiene el detalle de un incidente por su ID.</summary>
    [HttpGet]  public async Task<IHttpActionResult> DetalleIncidente(long idIncidente) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_incidente_Detalle", new { idIncidente })); }
    /// <summary>Lista los tipos de incidente disponibles.</summary>
    [HttpGet]  public async Task<IHttpActionResult> TiposIncidente() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_incidente_ListarTipos")); }
    /// <summary>Lista las tablas referenciadas en incidentes.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListaIncidentesTablas() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_incidente_ListarTablas")); }
    /// <summary>Actualiza el estatus de un incidente.</summary>
    [HttpPost] public async Task<IHttpActionResult> ActualizarEstatusIncidente(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_incidente_ActualizarEstatus", p)); }

    /// <summary>Lista las promociones configuradas con filtros y paginacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarPromociones(int pagina = 1, int tamano = 50, bool? activo = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_promocion_Listar", new { pagina, tamano, activo })); }
    /// <summary>Crea una nueva promocion en el sistema.</summary>
    [HttpPost] public async Task<IHttpActionResult> CrearPromocion(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_promocion_Crear", p)); }
    /// <summary>Edita una promocion existente.</summary>
    [HttpPost] public async Task<IHttpActionResult> EditarPromocion(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_promocion_Actualizar", p)); }
    /// <summary>Elimina (desactiva) una promocion.</summary>
    [HttpPost] public async Task<IHttpActionResult> EliminarPromocion(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_promocion_Eliminar", p)); }
    /// <summary>Genera un codigo promocional para una promocion existente.</summary>
    [HttpPost] public async Task<IHttpActionResult> GenerarCodigoPromocional(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_promocion_GenerarCodigo", p)); }

    /// <summary>Lista las zonas de cobertura con filtros y paginacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarZonasCobertura(int pagina = 1, int tamano = 50, bool? activo = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_zona_Listar", new { pagina, tamano, activo })); }
    /// <summary>Agrega una nueva zona de cobertura.</summary>
    [HttpPost] public async Task<IHttpActionResult> AgregarZonaCobertura(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_zona_Crear", p)); }
    /// <summary>Edita una zona de cobertura existente.</summary>
    [HttpPost] public async Task<IHttpActionResult> EditarZonaCobertura(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_zona_Actualizar", p)); }
    /// <summary>Elimina una zona de cobertura.</summary>
    [HttpPost] public async Task<IHttpActionResult> EliminarZonaCobertura(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_zona_Eliminar", p)); }
    /// <summary>Obtiene la configuracion de comisiones de una zona.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerComisionesZona(int idZona) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_zona_ObtenerComisiones", new { idZona })); }
    /// <summary>Actualiza la comision de una zona de cobertura.</summary>
    [HttpPost] public async Task<IHttpActionResult> ActualizarComisionZona(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_zona_ActualizarComision", p)); }

    /// <summary>Obtiene la configuracion general del sistema.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerConfiguracion() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_configuracion_Obtener")); }
    /// <summary>Guarda la configuracion general del sistema.</summary>
    [HttpPost] public async Task<IHttpActionResult> GuardarConfiguracion(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_configuracion_Guardar", p)); }
    /// <summary>Actualiza la configuracion de costos de una compania.</summary>
    [HttpPost] public async Task<IHttpActionResult> ActualizarConfiguracionCosto(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_configuracion_ActualizarCosto", p)); }
    /// <summary>Actualiza una clave de configuracion del sistema.</summary>
    [HttpPost] public async Task<IHttpActionResult> ActualizarConfiguracionSistema(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_configuracion_ActualizarSistema", p)); }

    /// <summary>Lista las companias registradas.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarCompanias() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_compania_Listar")); }
    /// <summary>Actualiza los datos de una compania.</summary>
    [HttpPost] public async Task<IHttpActionResult> ActualizarCompania(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_compania_Actualizar", p)); }

    /// <summary>Lista las semanas de corte con filtros y paginacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarSemanasCorte(int? idConductor = null, short? idCompania = null, int pagina = 1, int tamano = 50) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_corte_ListarSemanas", new { idConductor, idCompania, pagina, tamano })); }
    /// <summary>Procesa el pago de una semana de corte a un conductor.</summary>
    [HttpPost] public async Task<IHttpActionResult> ProcesarSemanaCorte(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_corte_Procesar", p)); }
    /// <summary>Lista las razones sociales disponibles para conductores.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarRazonesSocialesConductores() { return Ok(await DatabaseHelper.QueryAsync<object>("sp_conductor_ListarRazonesSociales")); }

    /// <summary>Lista las notificaciones enviadas con paginacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarNotificaciones(int pagina = 1, int tamano = 50) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_notificacion_Listar", new { pagina, tamano })); }
    /// <summary>Envia una notificacion a pasajeros, conductores o topicos.</summary>
    [HttpPost] public async Task<IHttpActionResult> EnviarNotificacion(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_notificacion_Enviar", p)); }

    /// <summary>Lista los avisos activos con filtros y paginacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarAvisos(int pagina = 1, int tamano = 50, short? idCompania = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_aviso_Listar", new { pagina, tamano, idCompania })); }
    /// <summary>Crea un nuevo aviso para una compania.</summary>
    [HttpPost] public async Task<IHttpActionResult> AgregarAviso(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_aviso_Crear", p)); }
    /// <summary>Edita un aviso existente.</summary>
    [HttpPost] public async Task<IHttpActionResult> EditarAviso(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_aviso_Actualizar", p)); }
    /// <summary>Elimina un aviso.</summary>
    [HttpPost] public async Task<IHttpActionResult> EliminarAviso(dynamic p) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_aviso_Eliminar", p)); }
    /// <summary>Lista la bitacora de auditoria con filtros y paginacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ListarAuditoria(int pagina = 1, int tamano = 50, System.DateTime? fi = null, System.DateTime? ff = null, int? idUsuario = null, string tabla = null, string accion = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_auditoria_Listar", new { pagina, tamano, fi, ff, idUsuario, tabla, accion })); }
    /// <summary>Obtiene los logs del sistema con filtros y paginacion.</summary>
    [HttpGet]  public async Task<IHttpActionResult> ObtenerLogs(int pagina = 1, int tamano = 50, string nivel = null, string modulo = null) { return Ok(await DatabaseHelper.QueryAsync<object>("sp_log_Listar", new { pagina, tamano, nivel, modulo })); }
}
