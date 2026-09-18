using System;
using System.Reflection;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using VaiaViajes.Api.Helpers;

[Route("api/[controller]")]
[ApiController]
public class AdminController : ControllerBase
{
    [HttpGet("version")]
    public IActionResult Version()
    {
        var asm = Assembly.GetExecutingAssembly();
        var location = asm.Location;
        var buildTime = System.IO.File.Exists(location)
            ? System.IO.File.GetLastWriteTime(location)
            : (DateTime?)null;
        return new OkObjectResult(new
        {
            assembly = asm.GetName().Name,
            version = asm.GetName().Version?.ToString(),
            buildTime = buildTime?.ToString("o"),
            path = location,
            hasExtensions = new
            {
                vaiaOk = typeof(ApiResultExtensions).GetMethod("VaiaOk", new[] { typeof(object), typeof(string) }) != null,
                vaiaFromSp = typeof(ApiResultExtensions).GetMethod("VaiaFromSp", new[] { typeof(object), typeof(string) }) != null,
                vaiaSingleFromSp = typeof(ApiResultExtensions).GetMethod("VaiaSingleFromSp", new[] { typeof(object), typeof(string) }) != null,
            }
        });
    }

    /// <summary>
    /// Diagnostico: indica que integraciones estan configuradas en el servidor.
    /// No expone los valores de las llaves, solo si existen.
    /// </summary>
    [HttpGet("diagnostico")]
    public IActionResult Diagnostico()
    {
        var cfg = HttpContext.RequestServices.GetRequiredService<Microsoft.Extensions.Configuration.IConfiguration>();
        var email = HttpContext.RequestServices.GetRequiredService<VaiaViajes.Api.Services.EmailService>();
        var wa = HttpContext.RequestServices.GetRequiredService<VaiaViajes.Api.Services.WhatsAppService>();
        var mp = HttpContext.RequestServices.GetRequiredService<VaiaViajes.Api.Services.MercadoPagoService>();
        var pp = HttpContext.RequestServices.GetRequiredService<VaiaViajes.Api.Services.PayPalService>();

        return new OkObjectResult(new
        {
            success = true,
            data = new
            {
                smtp = email.Configurado,
                smtpHost = cfg["Smtp:Host"],
                smtpFrom = cfg["Smtp:From"],
                whatsapp = wa.Configurado,
                whatsappPhoneId = cfg["WhatsApp:PhoneNumberId"],
                whatsappPlantilla = cfg["WhatsApp:PlantillaAuth"],
                mercadoPago = mp.Configurado,
                mercadoPagoSandbox = cfg["MercadoPago:SandboxMode"],
                paypal = pp.Configurado,
                paypalSandbox = cfg["PayPal:UseSandbox"],
                fcmConductor = !string.IsNullOrEmpty(cfg.GetSection("Fcm:Conductor")["ServerKey"]),
                fcmPasajero = !string.IsNullOrEmpty(cfg.GetSection("Fcm:Pasajero")["ServerKey"]),
                fcmLegacy = !string.IsNullOrEmpty(cfg.GetSection("Fcm")["ServerKey"])
            },
            message = "Diagnostico de configuracion"
        });
    }

    [HttpPost("IniciarSesion")]
    public async Task<IActionResult> IniciarSesion([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        d["pass"] = ParameterHelper.Sha256Hash((string)d["pass"]);
        var result = await DatabaseHelper.QueryAsync<object>("sp_usuario_IniciarSesion", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Inicio de sesion exitoso");
    }

    [HttpPost("CerrarSesion")]
    public async Task<IActionResult> CerrarSesion([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_usuario_CerrarSesion", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Sesion cerrada");
    }

    // ─── MONITOREO EN TIEMPO REAL ────────────────────────────────

    [HttpGet("ResumenMonitoreo")]
    public async Task<IActionResult> ResumenMonitoreo()
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_admin_ResumenMonitoreo");
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Resumen de monitoreo");
    }

    [HttpGet("ConductoresConectados")]
    public async Task<IActionResult> ConductoresConectados()
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_admin_ConductoresConectados");
        return ApiResultExtensions.VaiaFromSp((object)result, "Conductores conectados");
    }

    [HttpGet("PasajerosConectados")]
    public async Task<IActionResult> PasajerosConectados()
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_admin_PasajerosConectados");
        return ApiResultExtensions.VaiaFromSp((object)result, "Pasajeros conectados");
    }

    [HttpGet("OrigenesPorZona")]
    public async Task<IActionResult> OrigenesPorZona(int dias = 7)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_admin_OrigenesPorZona", new { dias });
        return ApiResultExtensions.VaiaFromSp((object)result, "Origenes por zona");
    }

    [HttpGet("SolicitudesPorHora")]
    public async Task<IActionResult> SolicitudesPorHora(int dias = 7)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_admin_SolicitudesPorHora", new { dias });
        return ApiResultExtensions.VaiaFromSp((object)result, "Solicitudes por hora");
    }

    [HttpGet("PasajerosActivosPorPeriodo")]
    public async Task<IActionResult> PasajerosActivosPorPeriodo(int dias = 7)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_admin_PasajerosActivosPorPeriodo", new { dias });
        return ApiResultExtensions.VaiaFromSp((object)result, "Pasajeros activos por periodo");
    }

    // ─── ANALITICA DE ZONAS Y DEMANDA (Fase 5) ──────────────────

    [HttpGet("DemandaPorHoraDia")]
    public async Task<IActionResult> DemandaPorHoraDia(int dias = 30)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_admin_DemandaPorHoraDia", new { dias });
        return ApiResultExtensions.VaiaFromSp((object)result, "Demanda por hora y dia");
    }

    [HttpGet("ZonasRanking")]
    public async Task<IActionResult> ZonasRanking(int dias = 30)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_admin_ZonasRanking", new { dias });
        return ApiResultExtensions.VaiaFromSp((object)result, "Ranking de zonas");
    }

    [HttpGet("OrigenesPuntos")]
    public async Task<IActionResult> OrigenesPuntos(int dias = 30, int limite = 2000)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_admin_OrigenesPuntos", new { dias, limite });
        return ApiResultExtensions.VaiaFromSp((object)result, "Puntos de origen");
    }

    [HttpGet("PrediccionDemanda")]
    public async Task<IActionResult> PrediccionDemanda(int dias = 30)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_admin_PrediccionDemanda", new { dias });
        return ApiResultExtensions.VaiaFromSp((object)result, "Prediccion de demanda");
    }

    [HttpGet("ConductoresPorZona")]
    public async Task<IActionResult> ConductoresPorZona()
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_admin_ConductoresPorZona");
        return ApiResultExtensions.VaiaFromSp((object)result, "Conductores por zona");
    }

    [HttpPost("CrearUsuario")]
    public async Task<IActionResult> CrearUsuario([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        d["pass"] = ParameterHelper.Sha256Hash((string)d["pass"]);
        if (!d.ContainsKey("idCreador") && d.ContainsKey("idActualiza")) d["idCreador"] = d["idActualiza"];
        d.Remove("idActualiza");
        d.Remove("idUsuario");
        var result = await DatabaseHelper.QueryAsync<object>("sp_usuario_Crear", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Usuario creado");
    }

    [HttpPost("EditarUsuario")]
    public async Task<IActionResult> EditarUsuario([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        if (d.ContainsKey("pass")) d["pass"] = ParameterHelper.Sha256Hash((string)d["pass"]);
        var result = await DatabaseHelper.QueryAsync<object>("sp_usuario_Actualizar", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Usuario actualizado");
    }

    [HttpPost("EliminarUsuario")]
    public async Task<IActionResult> EliminarUsuario([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_usuario_Eliminar", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Usuario eliminado");
    }

    [HttpGet("ListarUsuarios")]
    public async Task<IActionResult> ListarUsuarios(int pagina = 1, int tamano = 50, int? idRol = null, bool? activo = null, string busqueda = null)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_usuario_Listar", new { pagina, tamano, idRol, activo, search = busqueda });
        return ApiResultExtensions.VaiaFromSp((object)result, "Usuarios listados");
    }

    [HttpGet("ObtenerUsuario")]
    public async Task<IActionResult> ObtenerUsuario(int idUsuario)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_usuario_Obtener", new { idUsuario });
        if (result == null || !System.Linq.Enumerable.Any(result))
            return "Usuario no encontrado".VaiaNotFound();
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Usuario obtenido");
    }

    [HttpGet("ListarRoles")]
    public async Task<IActionResult> ListarRoles()
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_rol_Listar");
        return ApiResultExtensions.VaiaFromSp((object)result, "Roles listados");
    }

    [HttpGet("ListarPermisosXRol")]
    public async Task<IActionResult> ListarPermisosXRol(int idRol)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_rol_ListarPermisos", new { idRol });
        return ApiResultExtensions.VaiaFromSp((object)result, "Permisos listados");
    }

    [HttpGet("ListarPasajeros")]
    public async Task<IActionResult> ListarPasajeros(int pagina = 1, int tamano = 50, short? idCompania = null, bool? bloqueado = null, string busqueda = null)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_Listar", new { pagina, tamano, idCompania, bloq = bloqueado, search = busqueda });
        return ApiResultExtensions.VaiaFromSp((object)result, "Pasajeros listados");
    }

    [HttpGet("ObtenerPasajero")]
    public async Task<IActionResult> ObtenerPasajero(long idPasajero)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_Obtener", new { idPasajero });
        if (result == null || !System.Linq.Enumerable.Any(result))
            return "Pasajero no encontrado".VaiaNotFound();
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Pasajero obtenido");
    }

    [HttpPost("CrearPasajero")]
    public async Task<IActionResult> CrearPasajero([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        if (d.ContainsKey("notasadicionales")) { d["notas"] = d["notasadicionales"]; d.Remove("notasadicionales"); }
        d.Remove("idPasajero");
        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_Crear", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Pasajero creado");
    }

    [HttpPost("ActualizarPasajero")]
    public async Task<IActionResult> ActualizarPasajero([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        if (d.ContainsKey("notasadicionales")) { d["notas"] = d["notasadicionales"]; d.Remove("notasadicionales"); }
        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_Actualizar", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Pasajero actualizado");
    }

    [HttpPost("SuspenderPasajero")]
    public async Task<IActionResult> SuspenderPasajero([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_Bloquear", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Pasajero suspendido");
    }

    [HttpPost("AsignarSaldoPasajero")]
    public async Task<IActionResult> AsignarSaldoPasajero([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_AsignarSaldo", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Saldo asignado");
    }

    [HttpGet("ListarConductores")]
    public async Task<IActionResult> ListarConductores(int pagina = 1, int tamano = 50, short? idCompania = null, bool? bloqueado = null, short? estatus = null, string busqueda = null)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_Listar", new { pagina, tamano, idCompania, bloq = bloqueado, idEst = estatus, search = busqueda });
        return ApiResultExtensions.VaiaFromSp((object)result, "Conductores listados");
    }

    [HttpGet("ObtenerConductor")]
    public async Task<IActionResult> ObtenerConductor(int idConductor)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_Obtener", new { idConductor });
        if (result == null || !System.Linq.Enumerable.Any(result))
            return "Conductor no encontrado".VaiaNotFound();
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Conductor obtenido");
    }

    [HttpPost("CrearConductor")]
    public async Task<IActionResult> CrearConductor([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        if (d.ContainsKey("licenciaconducir")) { d["licencia"] = d["licenciaconducir"]; d.Remove("licenciaconducir"); }
        if (d.ContainsKey("fechavencimientolicencia")) { d["fvtoLicencia"] = d["fechavencimientolicencia"]; d.Remove("fechavencimientolicencia"); }
        if (d.ContainsKey("tipolicencia")) { d["tipoLicencia"] = d["tipolicencia"]; d.Remove("tipolicencia"); }
        if (d.ContainsKey("nombretitular")) { d["titular"] = d["nombretitular"]; d.Remove("nombretitular"); }
        if (d.ContainsKey("clabeinterbancaria")) { d["clabe"] = d["clabeinterbancaria"]; d.Remove("clabeinterbancaria"); }
        d.Remove("idConductor");
        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_Crear", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Conductor creado");
    }

    [HttpPost("ActualizarConductor")]
    public async Task<IActionResult> ActualizarConductor([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        if (d.ContainsKey("licenciaconducir")) { d["licencia"] = d["licenciaconducir"]; d.Remove("licenciaconducir"); }
        if (d.ContainsKey("fechavencimientolicencia")) { d["fvtoLicencia"] = d["fechavencimientolicencia"]; d.Remove("fechavencimientolicencia"); }
        if (d.ContainsKey("tipolicencia")) { d["tipoLicencia"] = d["tipolicencia"]; d.Remove("tipolicencia"); }
        if (d.ContainsKey("nombretitular")) { d["titular"] = d["nombretitular"]; d.Remove("nombretitular"); }
        if (d.ContainsKey("clabeinterbancaria")) { d["clabe"] = d["clabeinterbancaria"]; d.Remove("clabeinterbancaria"); }
        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_Actualizar", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Conductor actualizado");
    }

    [HttpPost("SuspenderConductor")]
    public async Task<IActionResult> SuspenderConductor([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_Bloquear", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Conductor suspendido");
    }

    [HttpPost("ValidarDocumento")]
    public async Task<IActionResult> ValidarDocumento([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_ValidarDocumento", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Documento validado");
    }

    [HttpGet("ListarDocumentosConductor")]
    public async Task<IActionResult> ListarDocumentosConductor(int idConductor)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_ListarDocumentos", new { idConductor });
        return ApiResultExtensions.VaiaFromSp((object)result, "Documentos listados");
    }

    [HttpPost("AprobarUnidad")]
    public async Task<IActionResult> AprobarUnidad([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_AprobarUnidad", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Unidad aprobada");
    }

    [HttpPost("ValidarDocumentoUnidad")]
    public async Task<IActionResult> ValidarDocumentoUnidad([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_ValidarDocumentoUnidad", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Documento de unidad validado");
    }

    [HttpPost("GestionarServicio")]
    public async Task<IActionResult> GestionarServicio([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_servicio_Gestionar", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Servicio gestionado");
    }

    [HttpGet("ListarServicios")]
    public async Task<IActionResult> ListarServicios(int pagina = 1, int tamano = 50, System.DateTime? fi = null, System.DateTime? ff = null, short? estatus = null, short? idCompania = null, string busqueda = null)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_servicio_Listar", new { pagina, tamano, fi, ff, idEst = estatus, idCompania });
        return ApiResultExtensions.VaiaFromSp((object)result, "Servicios listados");
    }

    [HttpGet("DetalleServicio")]
    public async Task<IActionResult> DetalleServicio(long idServicio)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_servicio_Detalle", new { idServicio });
        if (result == null || !System.Linq.Enumerable.Any(result))
            return "Servicio no encontrado".VaiaNotFound();
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Detalle del servicio");
    }

    [HttpGet("ListarEstatusServicio")]
    public async Task<IActionResult> ListarEstatusServicio()
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_servicio_ListarEstatus");
        return ApiResultExtensions.VaiaFromSp((object)result, "Estatus listados");
    }

    [HttpGet("ReporteServicios")]
    public async Task<IActionResult> ReporteServicios(System.DateTime? fi = null, System.DateTime? ff = null, short? idCompania = null, int? idEstatusViaje = null)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_reporte_Servicios", new { fi, ff, idCompania, idEstatusViaje });
        return ApiResultExtensions.VaiaFromSp((object)result, "Reporte de servicios");
    }

    [HttpGet("ReportePasajeros")]
    public async Task<IActionResult> ReportePasajeros(System.DateTime? fi = null, System.DateTime? ff = null)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_reporte_Pasajeros", new { fi, ff });
        return ApiResultExtensions.VaiaFromSp((object)result, "Reporte de pasajeros");
    }

    [HttpGet("ReporteConductores")]
    public async Task<IActionResult> ReporteConductores(System.DateTime? fi = null, System.DateTime? ff = null)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_reporte_Conductores", new { fi, ff });
        return ApiResultExtensions.VaiaFromSp((object)result, "Reporte de conductores");
    }

    [HttpGet("ReporteIngresos")]
    public async Task<IActionResult> ReporteIngresos(System.DateTime? fi = null, System.DateTime? ff = null, short? idCompania = null)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_reporte_Ingresos", new { fi, ff, idCompania });
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Reporte de ingresos");
    }

    [HttpGet("ReporteComisiones")]
    public async Task<IActionResult> ReporteComisiones(System.DateTime? fi = null, System.DateTime? ff = null)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_reporte_Comisiones", new { fi, ff });
        return ApiResultExtensions.VaiaFromSp((object)result, "Reporte de comisiones");
    }

    [HttpGet("ReporteUtilidadDiaria")]
    public async Task<IActionResult> ReporteUtilidadDiaria(System.DateTime? fecha = null, short? idCompania = null)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_reporte_UtilidadDiaria", new { fecha, idCompania });
        return ApiResultExtensions.VaiaFromSp((object)result, "Reporte de utilidad diaria");
    }

    [HttpGet("ListarIncidentes")]
    public async Task<IActionResult> ListarIncidentes(int pagina = 1, int tamano = 50, System.DateTime? fi = null, System.DateTime? ff = null, int? idTipoIncidente = null, int? idEstatus = null)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_incidente_Listar", new { pagina, tamano, fi, ff, idTipo = idTipoIncidente, idEst = idEstatus });
        return ApiResultExtensions.VaiaFromSp((object)result, "Incidentes listados");
    }

    [HttpGet("DetalleIncidente")]
    public async Task<IActionResult> DetalleIncidente(long idIncidente)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_incidente_DetalleCompleto", new { idIncidente });
        if (result == null || !System.Linq.Enumerable.Any(result))
            return "Incidente no encontrado".VaiaNotFound();
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Detalle del incidente");
    }

    [HttpGet("TiposIncidente")]
    public async Task<IActionResult> TiposIncidente()
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_incidente_ListarTipos");
        return ApiResultExtensions.VaiaFromSp((object)result, "Tipos de incidente");
    }

    [HttpGet("EstatusIncidente")]
    public async Task<IActionResult> EstatusIncidente()
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_incidente_ListarEstatus");
        return ApiResultExtensions.VaiaFromSp((object)result, "Estatus de incidente");
    }

    [HttpGet("ListaIncidentesTablas")]
    public async Task<IActionResult> ListaIncidentesTablas()
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_incidente_ListarTablas");
        return ApiResultExtensions.VaiaFromSp((object)result, "Tablas de incidente");
    }

    [HttpPost("ActualizarEstatusIncidente")]
    public async Task<IActionResult> ActualizarEstatusIncidente([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        var result = await DatabaseHelper.QueryAsync<object>("sp_incidente_CambiarEstatus", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Estatus actualizado");
    }

    [HttpGet("ListarPromociones")]
    public async Task<IActionResult> ListarPromociones(int pagina = 1, int tamano = 50, bool? activo = null)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_promocion_Listar", new { pagina, tamano, activo });
        return ApiResultExtensions.VaiaFromSp((object)result, "Promociones listadas");
    }

    [HttpPost("CrearPromocion")]
    public async Task<IActionResult> CrearPromocion([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        var result = await DatabaseHelper.QueryAsync<object>("sp_promocion_Crear", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Promocion creada");
    }

    [HttpPost("EditarPromocion")]
    public async Task<IActionResult> EditarPromocion([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        var result = await DatabaseHelper.QueryAsync<object>("sp_promocion_Actualizar", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Promocion actualizada");
    }

    [HttpPost("EliminarPromocion")]
    public async Task<IActionResult> EliminarPromocion([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        var result = await DatabaseHelper.QueryAsync<object>("sp_promocion_Eliminar", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Promocion eliminada");
    }

    [HttpPost("GenerarCodigoPromocional")]
    public async Task<IActionResult> GenerarCodigoPromocional([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        var result = await DatabaseHelper.QueryAsync<object>("sp_promocion_GenerarCodigo", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Codigo generado");
    }

    [HttpGet("ListarZonasCobertura")]
    public async Task<IActionResult> ListarZonasCobertura(int pagina = 1, int tamano = 50)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_zona_Listar");
        return ApiResultExtensions.VaiaFromSp((object)result, "Zonas listadas");
    }

    [HttpPost("AgregarZonaCobertura")]
    public async Task<IActionResult> AgregarZonaCobertura([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        if (d.ContainsKey("descripcion")) { d["desc"] = d["descripcion"]; d.Remove("descripcion"); }
        if (d.ContainsKey("latitudcentro")) { d["lat"] = d["latitudcentro"]; d.Remove("latitudcentro"); }
        if (d.ContainsKey("longitudcentro")) { d["lng"] = d["longitudcentro"]; d.Remove("longitudcentro"); }
        if (d.ContainsKey("radio_km")) { d["radio"] = d["radio_km"]; d.Remove("radio_km"); }
        d.Remove("activo");
        d.Remove("id");
        var result = await DatabaseHelper.QueryAsync<object>("sp_zona_Crear", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Zona creada");
    }

    [HttpPost("EditarZonaCobertura")]
    public async Task<IActionResult> EditarZonaCobertura([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        if (d.ContainsKey("descripcion")) { d["desc"] = d["descripcion"]; d.Remove("descripcion"); }
        if (d.ContainsKey("latitudcentro")) { d["lat"] = d["latitudcentro"]; d.Remove("latitudcentro"); }
        if (d.ContainsKey("longitudcentro")) { d["lng"] = d["longitudcentro"]; d.Remove("longitudcentro"); }
        if (d.ContainsKey("radio_km")) { d["radio"] = d["radio_km"]; d.Remove("radio_km"); }
        if (!d.ContainsKey("id") && d.ContainsKey("idZona")) d["id"] = d["idZona"];
        if (d.ContainsKey("idZona")) d.Remove("idZona");
        var result = await DatabaseHelper.QueryAsync<object>("sp_zona_Actualizar", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Zona actualizada");
    }

    [HttpPost("EliminarZonaCobertura")]
    public async Task<IActionResult> EliminarZonaCobertura([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_zona_Eliminar", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Zona eliminada");
    }

    [HttpGet("ObtenerComisionesZona")]
    public async Task<IActionResult> ObtenerComisionesZona(int idZona)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_zona_ObtenerComisiones", new { idZona });
        return ApiResultExtensions.VaiaFromSp((object)result, "Comisiones de zona");
    }

    [HttpPost("ActualizarComisionZona")]
    public async Task<IActionResult> ActualizarComisionZona([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_zona_ActualizarComision", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Comision actualizada");
    }

    [HttpGet("ObtenerConfiguracion")]
    public async Task<IActionResult> ObtenerConfiguracion()
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_configuracion_ObtenerConfig");
        return ApiResultExtensions.VaiaFromSp((object)result, "Configuracion obtenida");
    }

    [HttpPost("GuardarConfiguracion")]
    public async Task<IActionResult> GuardarConfiguracion([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        var result = await DatabaseHelper.QueryAsync<object>("sp_configuracion_ActualizarConfig", d);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Configuracion guardada");
    }

    [HttpPost("ActualizarConfiguracionCosto")]
    public async Task<IActionResult> ActualizarConfiguracionCosto([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_configuracion_ActualizarCosto", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Costo actualizado");
    }

    [HttpGet("ListarCompanias")]
    public async Task<IActionResult> ListarCompanias()
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_compania_Listar");
        return ApiResultExtensions.VaiaFromSp((object)result, "Companias listadas");
    }

    [HttpPost("ActualizarCompania")]
    public async Task<IActionResult> ActualizarCompania([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_compania_Actualizar", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Compania actualizada");
    }

    [HttpGet("ListarSemanasCorte")]
    public async Task<IActionResult> ListarSemanasCorte(int? idConductor = null, short? idCompania = null, int pagina = 1, int tamano = 50)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_corte_ListarSemanas", new { idConductor, idCompania, pagina, tamano });
        return ApiResultExtensions.VaiaFromSp((object)result, "Semanas de corte listadas");
    }

    [HttpPost("ProcesarSemanaCorte")]
    public async Task<IActionResult> ProcesarSemanaCorte([FromBody] dynamic p)
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_corte_Procesar", p);
        return ApiResultExtensions.VaiaSingleFromSp((object)result, "Semana procesada");
    }
}