using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using VaiaViajes.Api.Helpers;
using VaiaViajes.Api.Services;

[Route("api/[controller]")]
[ApiController]
public class ConductorController : ControllerBase
{
    private FcmService Fcm => HttpContext.RequestServices.GetRequiredService<FcmService>();
    private VaiaViajes.Api.Services.RealtimeNotifier Notifier => HttpContext.RequestServices.GetRequiredService<VaiaViajes.Api.Services.RealtimeNotifier>();
    private EmailService Email => HttpContext.RequestServices.GetRequiredService<EmailService>();
    private WhatsAppService WhatsApp => HttpContext.RequestServices.GetRequiredService<WhatsAppService>();

    [HttpPost("Registrar")]
    public async Task<IActionResult> Registrar([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        d["pass"] = ParameterHelper.Sha256Hash((string)d["pass"]);
        ParameterHelper.ApplyAliases(d,
            "genero", "sexo",
            "idZona", "idZonaCobertura",
            "licenciaconducir", "licencia",
            "idiomapreferido", "idioma",
            "fechanacimiento", "fechaNac",
            "fechavencimientolicencia", "fecVenLic",
            "tipolicencia", "tipoLic",
            "nombretitular", "titular",
            "clabeinterbancaria", "clabe");

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_Registrar", d);
        object boxed = result;

        // Correo de bienvenida
        try
        {
            string correo = d.ContainsKey("correo") ? d["correo"]?.ToString() : null;
            string nombre = d.ContainsKey("nombre") ? d["nombre"]?.ToString() : "Conductor";
            if (!string.IsNullOrEmpty(correo))
                _ = Email.EnviarAsync(correo, "Bienvenido a Vaia Conductor", EmailTemplates.Bienvenida(nombre));
        }
        catch { }

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Registro exitoso");
    }

    [HttpPost("IniciarSesion")]
    public async Task<IActionResult> IniciarSesion([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        d["pass"] = ParameterHelper.Sha256Hash((string)d["pass"]);
        return await SpExecutor.SingleAsync("sp_conductor_IniciarSesion", d, "Inicio de sesion exitoso");
    }

    [HttpPost("CerrarSesion")]
    public async Task<IActionResult> CerrarSesion([FromBody] dynamic p)
    {
        return await SpExecutor.SingleAsync("sp_conductor_CerrarSesion", p, "Sesion cerrada");
    }

    [HttpGet("ObtenerPerfil")]
    public async Task<IActionResult> ObtenerPerfil(int idConductor)
    {
        return await SpExecutor.SingleRequiredAsync("sp_conductor_ObtenerPerfil", new { idConductor }, "Conductor no encontrado", "Perfil obtenido");
    }

    [HttpPost("ActualizarPerfil")]
    public async Task<IActionResult> ActualizarPerfil([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        ParameterHelper.ApplyAliases(d,
            "genero", "sexo",
            "idiomapreferido", "idioma",
            "fechanacimiento", "fechaNac",
            "licenciaconducir", "licencia",
            "fechavencimientolicencia", "fecVenLic",
            "tipolicencia", "tipoLic",
            "nombretitular", "titular",
            "clabeinterbancaria", "clabe",
            "notasadicionales", "notas");
        return await SpExecutor.SingleAsync("sp_conductor_ActualizarPerfil", d, "Perfil actualizado");
    }

    [HttpPost("CambiarPassword")]
    public async Task<IActionResult> CambiarPassword([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        d["pass"] = ParameterHelper.Sha256Hash((string)d["pass"]);

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_CambiarPassword", d);
        object boxed = result;

        // Correo de aviso de cambio de contrasena
        try
        {
            int idConductor = d.ContainsKey("idConductor") ? Convert.ToInt32(d["idConductor"]) : 0;
            if (idConductor > 0)
            {
                var perfil = await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerPerfil", new { idConductor });
                var pf = System.Linq.Enumerable.FirstOrDefault(perfil as System.Collections.Generic.IEnumerable<object>) as System.Collections.Generic.IDictionary<string, object>;
                if (pf != null)
                {
                    string correo = pf.ContainsKey("correo") ? pf["correo"]?.ToString() : null;
                    string nombre = pf.ContainsKey("nombre") ? pf["nombre"]?.ToString() : "Conductor";
                    if (!string.IsNullOrEmpty(correo))
                        _ = Email.EnviarAsync(correo, "Contrasena actualizada - Vaia Conductor", EmailTemplates.CambioPassword(nombre));
                }
            }
        }
        catch { }

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Contrasena actualizada");
    }

    // ─── VERIFICACION DE TELEFONO (WhatsApp) Y CORREO ────────────

    /// <summary>Envia el codigo de verificacion del telefono por WhatsApp.</summary>
    [HttpPost("EnviarCodigoVerificacion")]
    public async Task<IActionResult> EnviarCodigoVerificacion([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_EnviarCodigoVerificacion", d);
        object boxed = result;

        try
        {
            string telefono = d.ContainsKey("telefono") ? d["telefono"]?.ToString() : null;
            string codigo = null;
            var first = System.Linq.Enumerable.FirstOrDefault(result as System.Collections.Generic.IEnumerable<object>);
            var dict = first as System.Collections.Generic.IDictionary<string, object>;
            if (dict != null && dict.ContainsKey("codigoverificacion") && dict["codigoverificacion"] != null)
                codigo = dict["codigoverificacion"].ToString();

            if (!string.IsNullOrEmpty(telefono) && !string.IsNullOrEmpty(codigo))
                _ = WhatsApp.EnviarCodigoAsync(telefono, codigo);
        }
        catch { }

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Codigo enviado");
    }

    [HttpPost("ValidarCodigoVerificacion")]
    public async Task<IActionResult> ValidarCodigoVerificacion([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        return await SpExecutor.SingleAsync("sp_conductor_ValidarCodigoVerificacion", d, "Telefono verificado");
    }

    /// <summary>Envia el codigo de verificacion del correo electronico.</summary>
    [HttpPost("EnviarCodigoCorreo")]
    public async Task<IActionResult> EnviarCodigoCorreo([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_EnviarCodigoCorreo", d);
        object boxed = result;

        try
        {
            string correo = d.ContainsKey("correo") ? d["correo"]?.ToString() : null;
            string nombre = "Conductor";
            if (d.ContainsKey("idConductor") && d["idConductor"] != null)
            {
                var perfil = await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerPerfil", new { idConductor = System.Convert.ToInt32(d["idConductor"]) });
                var pf = System.Linq.Enumerable.FirstOrDefault(perfil as System.Collections.Generic.IEnumerable<object>) as System.Collections.Generic.IDictionary<string, object>;
                if (pf != null && pf.ContainsKey("nombre") && pf["nombre"] != null) nombre = pf["nombre"].ToString();
            }

            string codigo = null;
            var first = System.Linq.Enumerable.FirstOrDefault(result as System.Collections.Generic.IEnumerable<object>);
            var dict = first as System.Collections.Generic.IDictionary<string, object>;
            if (dict != null && dict.ContainsKey("codigoverificacion") && dict["codigoverificacion"] != null)
                codigo = dict["codigoverificacion"].ToString();

            if (!string.IsNullOrEmpty(correo) && !string.IsNullOrEmpty(codigo))
                _ = Email.EnviarAsync(correo, "Verifica tu correo - Vaia Conductor", EmailTemplates.CodigoVerificacion(nombre, codigo));
        }
        catch { }

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Codigo enviado");
    }

    [HttpPost("ValidarCodigoCorreo")]
    public async Task<IActionResult> ValidarCodigoCorreo([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        return await SpExecutor.SingleAsync("sp_conductor_ValidarCodigoCorreo", d, "Correo verificado");
    }

    [HttpPost("ActualizarCorreo")]
    public async Task<IActionResult> ActualizarCorreo([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        return await SpExecutor.SingleAsync("sp_conductor_ActualizarCorreo", d, "Correo actualizado");
    }

    /// <summary>Actualiza el token de push (FCM) del conductor.</summary>
    [HttpPost("ActualizarToken")]
    public async Task<IActionResult> ActualizarToken([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        return await SpExecutor.SingleAsync("sp_conductor_ActualizarToken", d, "Token actualizado");
    }

    [HttpPost("ActualizarUbicacion")]
    public async Task<IActionResult> ActualizarUbicacion([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_ActualizarUbicacionGPS", d);
        object boxed = result;

        int idConductor = d.ContainsKey("idConductor") ? System.Convert.ToInt32(d["idConductor"]) : 0;
        string lat = d.ContainsKey("lat") ? d["lat"]?.ToString() : null;
        string lng = d.ContainsKey("lng") ? d["lng"]?.ToString() : null;
        if (idConductor > 0 && !string.IsNullOrEmpty(lat) && !string.IsNullOrEmpty(lng))
        {
            await Notifier.NotificarConductor(idConductor, "UbicacionActualizada", new { idConductor, lat, lng });
        }

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Ubicacion actualizada");
    }

    [HttpPost("CambiarEstatus")]
    public async Task<IActionResult> CambiarEstatus([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_CambiarEstatus", d);
        object boxed = result;

        int idConductor = d.ContainsKey("idConductor") ? System.Convert.ToInt32(d["idConductor"]) : 0;
        string estatus = d.ContainsKey("estatus") ? d["estatus"]?.ToString() : "";
        if (idConductor > 0)
        {
            await Notifier.NotificarConductor(idConductor, "EstatusCambiado", new { idConductor, estatus });
            // Notificar a admins el cambio de disponibilidad
            await Notifier.NotificarConductor(idConductor, "DisponibilidadActualizada", new
            {
                idConductor,
                estatus,
                disponible = estatus == "Disponible",
                lat = d.ContainsKey("lat") ? d["lat"]?.ToString() : null,
                lng = d.ContainsKey("lng") ? d["lng"]?.ToString() : null
            });
        }

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Estatus actualizado");
    }

    [HttpPost("AceptarServicio")]
    public async Task<IActionResult> AceptarServicio([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_AceptarServicio", d);
        object boxed = result;

        var idServicio = d.ContainsKey("idServicio") ? System.Convert.ToInt64(d["idServicio"]) : 0L;
        var idConductor = d.ContainsKey("idConductor") ? System.Convert.ToInt32(d["idConductor"]) : 0;
        if (idServicio > 0 && idConductor > 0)
        {
            var pasajeroId = await GetPasajeroIdFromService(idServicio);
            if (pasajeroId > 0)
            {
                var token = await Fcm.GetPasajeroTokenAsync(pasajeroId);
                var nombre = await Fcm.GetConductorNameAsync(idConductor);
                if (!string.IsNullOrEmpty(token))
                {
                    _ = Fcm.SendToTokenAsync(token, "Conductor en camino",
                        $"{nombre} ha aceptado tu servicio y va en camino",
                        new System.Collections.Generic.Dictionary<string, string>
                        {
                            ["type"] = "ride_accepted",
                            ["idservicio"] = idServicio.ToString(),
                        });
                }
            }
            // Notificar por WebSocket
            await Notifier.NotificarServicioAceptado(idServicio, pasajeroId, new
            {
                idServicio,
                idConductor,
                estatus = "En Camino",
                conductorNombre = await Fcm.GetConductorNameAsync(idConductor),
                fecha = System.DateTime.UtcNow.ToString("o")
            });
        }
        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Servicio aceptado");
    }

    [HttpPost("RechazarServicio")]
    public async Task<IActionResult> RechazarServicio([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_RechazarServicio", d);
        object boxed = result;

        // Notificar a admins para trazabilidad
        long idServicio = d.ContainsKey("idservicio") ? System.Convert.ToInt64(d["idservicio"]) : 0;
        int idConductor = d.ContainsKey("idconductor") ? System.Convert.ToInt32(d["idconductor"]) : 0;
        if (idServicio > 0)
        {
            var notifier = HttpContext.RequestServices.GetRequiredService<VaiaViajes.Api.Services.RealtimeNotifier>();
            await notifier.NotificarConductor(idConductor, "ServicioRechazado", new { idServicio });
        }
        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Servicio rechazado");
    }

    [HttpPost("LlegarAlOrigen")]
    public async Task<IActionResult> LlegarAlOrigen([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_LlegarAlOrigen", d);
        object boxed = result;

        var idServicio = d.ContainsKey("idServicio") ? System.Convert.ToInt64(d["idServicio"]) : 0L;
        if (idServicio > 0)
        {
            var pasajeroId = await GetPasajeroIdFromService(idServicio);
            if (pasajeroId > 0)
            {
                var token = await Fcm.GetPasajeroTokenAsync(pasajeroId);
                if (!string.IsNullOrEmpty(token))
                {
                    _ = Fcm.SendToTokenAsync(token, "Tu conductor ha llegado",
                        "El conductor esta en el punto de recogida",
                        new System.Collections.Generic.Dictionary<string, string>
                        {
                            ["type"] = "ride_arrived",
                            ["idservicio"] = idServicio.ToString(),
                        });
                }
            }
            await Notifier.NotificarEstatusCambiado(idServicio, "Llego al Origen");
        }
        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Llegada registrada");
    }

    [HttpPost("IniciarViaje")]
    public async Task<IActionResult> IniciarViaje([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_IniciarViaje", d);
        object boxed = result;

        var idServicio = d.ContainsKey("idServicio") ? System.Convert.ToInt64(d["idServicio"]) : 0L;
        if (idServicio > 0)
        {
            var pasajeroId = await GetPasajeroIdFromService(idServicio);
            if (pasajeroId > 0)
            {
                var token = await Fcm.GetPasajeroTokenAsync(pasajeroId);
                if (!string.IsNullOrEmpty(token))
                {
                    _ = Fcm.SendToTokenAsync(token, "Viaje iniciado",
                        "Tu viaje ha comenzado. Disfruta el trayecto!",
                        new System.Collections.Generic.Dictionary<string, string>
                        {
                            ["type"] = "ride_started",
                            ["idservicio"] = idServicio.ToString(),
                        });
                }
            }
            await Notifier.NotificarEstatusCambiado(idServicio, "En Viaje");
        }
        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Viaje iniciado");
    }

    [HttpPost("FinalizarViaje")]
    public async Task<IActionResult> FinalizarViaje([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        ParameterHelper.ApplyAliases(d,
            "rd_m", "distReal",
            "rd_s", "durReal",
            "distanciaMetros", "distReal",
            "duracionsegundos", "durReal");
        d.Remove("lat");
        d.Remove("lng");

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_FinalizarViaje", d);
        object boxed = result;

        var idServicio = d.ContainsKey("idServicio") ? System.Convert.ToInt64(d["idServicio"]) : 0L;
        if (idServicio > 0)
        {
            var pasajeroId = await GetPasajeroIdFromService(idServicio);
            if (pasajeroId > 0)
            {
                var token = await Fcm.GetPasajeroTokenAsync(pasajeroId);
                if (!string.IsNullOrEmpty(token))
                {
                    _ = Fcm.SendToTokenAsync(token, "Viaje finalizado",
                        "Has llegado a tu destino. Califica tu experiencia",
                        new System.Collections.Generic.Dictionary<string, string>
                        {
                            ["type"] = "ride_finished",
                            ["idservicio"] = idServicio.ToString(),
                        });
                }
            }
            await Notifier.NotificarEstatusCambiado(idServicio, "Finalizado");
            await Notifier.NotificarEstatusAdmin(idServicio, "Finalizado");

            // Correo al conductor con el resumen del servicio
            try
            {
                int idConductor = d.ContainsKey("idConductor") ? Convert.ToInt32(d["idConductor"]) : 0;
                decimal costo = 0;
                var first = System.Linq.Enumerable.FirstOrDefault(result as System.Collections.Generic.IEnumerable<object>);
                var dict = first as System.Collections.Generic.IDictionary<string, object>;
                if (dict != null && dict.ContainsKey("costofinal") && dict["costofinal"] != null)
                    costo = Convert.ToDecimal(dict["costofinal"]);

                if (idConductor > 0)
                {
                    var perfil = await DatabaseHelper.QueryAsync<object>("sp_conductor_ObtenerPerfil", new { idConductor });
                    var pf = System.Linq.Enumerable.FirstOrDefault(perfil as System.Collections.Generic.IEnumerable<object>) as System.Collections.Generic.IDictionary<string, object>;
                    if (pf != null)
                    {
                        string correo = pf.ContainsKey("correo") ? pf["correo"]?.ToString() : null;
                        string nombre = pf.ContainsKey("nombre") ? pf["nombre"]?.ToString() : "Conductor";
                        if (!string.IsNullOrEmpty(correo))
                            _ = Email.EnviarAsync(correo, "Servicio finalizado #" + idServicio + " - Vaia Conductor",
                                EmailTemplates.ServicioFinalizado(nombre, idServicio.ToString(), costo.ToString("N2")));
                    }
                }
            }
            catch { }
        }
        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Viaje finalizado");
    }

    /// <summary>
    /// Taximetro: el conductor reporta distancia/tiempo acumulados durante el viaje
    /// y el servidor calcula el costo en vivo, que se difunde a ambas apps.
    /// </summary>
    [HttpPost("ActualizarTaximetro")]
    public async Task<IActionResult> ActualizarTaximetro([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_ActualizarTaximetro", d);
        object boxed = result;

        var idServicio = d.ContainsKey("idServicio") ? System.Convert.ToInt64(d["idServicio"]) : 0L;
        int dist = d.ContainsKey("distanciaMetros") ? System.Convert.ToInt32(d["distanciaMetros"]) : 0;
        int dur = d.ContainsKey("duracionSegundos") ? System.Convert.ToInt32(d["duracionSegundos"]) : 0;

        decimal costo = 0;
        var first = System.Linq.Enumerable.FirstOrDefault(result as System.Collections.Generic.IEnumerable<object>);
        var dict = first as System.Collections.Generic.IDictionary<string, object>;
        if (dict != null && dict.ContainsKey("costo") && dict["costo"] != null)
            costo = System.Convert.ToDecimal(dict["costo"]);

        if (idServicio > 0 && costo > 0)
            await Notifier.NotificarCostoActualizado(idServicio, costo, dist, dur);

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Costo actualizado");
    }

    /// <summary>
    /// Registra el pago del servicio (efectivo por defecto) y envia el comprobante
    /// al correo del pasajero.
    /// </summary>
    [HttpPost("RegistrarPago")]
    public async Task<IActionResult> RegistrarPago([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_RegistrarPago", d);
        object boxed = result;

        long idServicio = d.ContainsKey("idServicio") ? System.Convert.ToInt64(d["idServicio"]) : 0L;
        bool ok = false;
        var first = System.Linq.Enumerable.FirstOrDefault(result as System.Collections.Generic.IEnumerable<object>);
        var dict = first as System.Collections.Generic.IDictionary<string, object>;
        if (dict != null && dict.ContainsKey("resultado") && dict["resultado"] != null)
            ok = System.Convert.ToInt32(dict["resultado"]) > 0;

        if (ok && idServicio > 0)
        {
            await Notifier.NotificarEstatusCambiado(idServicio, "Pagado");
            _ = EnviarComprobanteAsync(idServicio);
        }

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Pago registrado");
    }

    private async Task EnviarComprobanteAsync(long idServicio)
    {
        try
        {
            var rows = await DatabaseHelper.QueryAsync<object>("sp_servicio_Comprobante", new { idServicio });
            var first = System.Linq.Enumerable.FirstOrDefault(rows);
            var c = first as System.Collections.Generic.IDictionary<string, object>;
            if (c == null) return;

            string correo = c.ContainsKey("pasajero_correo") ? c["pasajero_correo"]?.ToString() : null;
            if (string.IsNullOrEmpty(correo)) return;

            string nombre = ((c.ContainsKey("pasajero_nombre") ? c["pasajero_nombre"]?.ToString() : "") + " " +
                             (c.ContainsKey("pasajero_appaterno") ? c["pasajero_appaterno"]?.ToString() : "")).Trim();
            string costo = (c.ContainsKey("costofinal") && c["costofinal"] != null)
                ? System.Convert.ToDecimal(c["costofinal"]).ToString("N2") : "0.00";
            string origen = c.ContainsKey("direccionorigen") ? c["direccionorigen"]?.ToString() : "";
            string destino = c.ContainsKey("direcciondestination") ? c["direcciondestination"]?.ToString() : "";
            string metodo = c.ContainsKey("metodopago") ? c["metodopago"]?.ToString() : "";
            string conductor = ((c.ContainsKey("conductor_nombre") ? c["conductor_nombre"]?.ToString() : "") + " " +
                                (c.ContainsKey("conductor_appaterno") ? c["conductor_appaterno"]?.ToString() : "")).Trim();
            string unidad = c.ContainsKey("unidad") ? c["unidad"]?.ToString() : "";
            string placas = c.ContainsKey("placas") ? c["placas"]?.ToString() : "";

            var html = "<div style=\"font-family:Arial,sans-serif;max-width:560px;margin:auto;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden\">"
                + "<div style=\"background:#14B8A6;color:#fff;padding:18px 22px\"><h2 style=\"margin:0\">Vaia Viajes</h2><div style=\"opacity:.9;font-size:13px\">Comprobante de viaje</div></div>"
                + "<div style=\"padding:20px 22px\">"
                + "<p style=\"margin:0 0 12px\">Hola " + nombre + ", gracias por viajar con nosotros.</p>"
                + "<table style=\"width:100%;border-collapse:collapse;font-size:14px\">"
                + "<tr><td style=\"padding:6px 0;color:#64748b\">Servicio</td><td style=\"text-align:right\"><b>#" + idServicio + "</b></td></tr>"
                + "<tr><td style=\"padding:6px 0;color:#64748b\">Origen</td><td style=\"text-align:right\">" + origen + "</td></tr>"
                + "<tr><td style=\"padding:6px 0;color:#64748b\">Destino</td><td style=\"text-align:right\">" + destino + "</td></tr>"
                + "<tr><td style=\"padding:6px 0;color:#64748b\">Conductor</td><td style=\"text-align:right\">" + conductor + " " + unidad + " " + placas + "</td></tr>"
                + "<tr><td style=\"padding:6px 0;color:#64748b\">Metodo de pago</td><td style=\"text-align:right\">" + metodo + "</td></tr>"
                + "<tr><td style=\"padding:10px 0;border-top:1px solid #e2e8f0;font-size:16px\"><b>Total</b></td><td style=\"text-align:right;border-top:1px solid #e2e8f0;font-size:18px\"><b>$" + costo + "</b></td></tr>"
                + "</table></div>"
                + "<div style=\"background:#f8fafc;padding:12px 22px;font-size:12px;color:#94a3b8\">Comprobante automatico, no requiere firma.</div>"
                + "</div>";

            await Email.EnviarAsync(correo, "Comprobante de viaje #" + idServicio + " - Vaia Viajes", html);
        }
        catch (Exception ex)
        {
            Console.WriteLine("[Conductor] Error enviando comprobante: " + ex.Message);
        }
    }

    /// <summary>Resumen del dia: ganancias, servicios realizados y tiempo conectado.</summary>
    [HttpGet("ResumenDia")]
    public async Task<IActionResult> ResumenDia(int idConductor)
    {
        return await SpExecutor.SingleAsync("sp_conductor_ResumenDia", new { idConductor }, "Resumen del dia");
    }

    // ─── DOCUMENTOS ──────────────────────────────────────────────

    [HttpGet("ListarTiposDocumento")]
    public async Task<IActionResult> ListarTiposDocumento(string para = "conductor")
    {
        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_ListarTiposDocumento", new { para });
        return ApiResultExtensions.VaiaFromSp((object)result, "Tipos de documento");
    }

    [HttpPost("AgregarDocumento")]
    public async Task<IActionResult> AgregarDocumento([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        return await SpExecutor.SingleAsync("sp_conductor_AgregarDocumento", d, "Documento cargado");
    }

    [HttpPost("EliminarDocumento")]
    public async Task<IActionResult> EliminarDocumento([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        return await SpExecutor.SingleAsync("sp_conductor_EliminarDocumento", d, "Documento eliminado");
    }

    [HttpGet("ListarDocumentos")]
    public async Task<IActionResult> ListarDocumentos(int idConductor)
    {
        return await SpExecutor.ListAsync("sp_conductor_ListarDocumentos", new { idConductor }, "Documentos");
    }

    [HttpGet("ObtenerDocumento")]
    public async Task<IActionResult> ObtenerDocumento(long idDocumento)
    {
        return await SpExecutor.SingleAsync("sp_conductor_ObtenerDocumento", new { idDocumento }, "Documento");
    }

    [HttpPost("AgregarDocumentoUnidad")]
    public async Task<IActionResult> AgregarDocumentoUnidad([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        return await SpExecutor.SingleAsync("sp_conductor_AgregarDocumentoUnidad", d, "Documento de unidad cargado");
    }

    [HttpGet("ListarDocumentosUnidad")]
    public async Task<IActionResult> ListarDocumentosUnidad(int idConductor, int idunidad)
    {
        return await SpExecutor.ListAsync("sp_conductor_ListarDocumentosUnidad", new { idConductor, idunidad }, "Documentos de la unidad");
    }

    [HttpGet("ListarUnidades")]
    public async Task<IActionResult> ListarUnidades(int idConductor)
    {
        return await SpExecutor.ListAsync("sp_conductor_ListarUnidades", new { idConductor }, "Unidades listadas");
    }

    [HttpPost("AgregarUnidad")]
    public async Task<IActionResult> AgregarUnidad([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        ParameterHelper.ApplyAliases(d,
            "aniofabricacion", "anio",
            "numeroasientos", "asientos",
            "capacidadmaxima", "capMax",
            "idtipocombustible", "idCombustible",
            "idtransmision", "idTransmision",
            "idsubmarca", "idSubmarca",
            "noserie", "serie");
        return await SpExecutor.SingleAsync("sp_conductor_AgregarUnidad", d, "Unidad agregada");
    }

    [HttpPost("SeleccionarUnidad")]
    public async Task<IActionResult> SeleccionarUnidad([FromBody] dynamic p)
    {
        return await SpExecutor.SingleAsync("sp_conductor_SeleccionarUnidad", p, "Unidad seleccionada");
    }

    [HttpPost("CalificarPasajero")]
    public async Task<IActionResult> CalificarPasajero([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        ParameterHelper.ApplyAliases(d, "calificacion", "calif", "comentarios", "coment");
        return await SpExecutor.SingleAsync("sp_conductor_CalificarPasajero", d, "Calificacion registrada");
    }

    [HttpGet("HistorialViajes")]
    public async Task<IActionResult> HistorialViajes(int idConductor, int pagina = 1, int tamano = 20, System.DateTime? fi = null, System.DateTime? ff = null)
    {
        return await SpExecutor.ListAsync("sp_conductor_HistorialViajes", new { idConductor, pagina, tamano, fi, ff }, "Historial obtenido");
    }

    [HttpGet("DetalleViaje")]
    public async Task<IActionResult> DetalleViaje(long idServicio, int idConductor)
    {
        return await SpExecutor.SingleRequiredAsync("sp_conductor_DetalleViaje", new { idServicio, idConductor }, "Viaje no encontrado", "Detalle del viaje");
    }

    [HttpGet("ObtenerSemanaCorte")]
    public async Task<IActionResult> ObtenerSemanaCorte(int idConductor)
    {
        return await SpExecutor.SingleAsync("sp_conductor_ObtenerCorteSemanal", new { idConductor }, "Semana de corte");
    }

    [HttpPost("EnviarMensajeChat")]
    public async Task<IActionResult> EnviarMensajeChat([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_EnviarMensajeChat", d);
        object boxed = result;

        var idServicio = d.ContainsKey("idServicio") ? System.Convert.ToInt64(d["idServicio"]) : 0L;
        var idConductor = d.ContainsKey("idConductor") ? System.Convert.ToInt32(d["idConductor"]) : 0;
        if (idServicio > 0)
        {
            var pasajeroId = await GetPasajeroIdFromService(idServicio);
            if (pasajeroId > 0)
            {
                var token = await Fcm.GetPasajeroTokenAsync(pasajeroId);
                var nombre = await Fcm.GetConductorNameAsync(idConductor);
                if (!string.IsNullOrEmpty(token))
                {
                    var msgPreview = (d.ContainsKey("mensaje") ? d["mensaje"]?.ToString() : "") ?? "";
                    if (msgPreview.Length > 80) msgPreview = msgPreview.Substring(0, 80) + "...";
                    _ = Fcm.SendToTokenAsync(token, $"Mensaje de {nombre}", msgPreview,
                        new System.Collections.Generic.Dictionary<string, string>
                        {
                            ["type"] = "chat_message",
                            ["idservicio"] = idServicio.ToString(),
                            ["emisor"] = "conductor",
                        });
                }
            }
            var nombreCond = await Fcm.GetConductorNameAsync(idConductor);
            await Notifier.NotificarMensajeChat(idServicio, new
            {
                idServicio,
                emisor = "conductor",
                mensaje = d.ContainsKey("mensaje") ? d["mensaje"]?.ToString() : "",
                nombreEmisor = nombreCond,
                fecha = System.DateTime.UtcNow.ToString("o")
            });
        }
        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Mensaje enviado");
    }

    [HttpGet("ObtenerMensajesChat")]
    public async Task<IActionResult> ObtenerMensajesChat(long idServicio, int idConductor)
    {
        return await SpExecutor.ListAsync("sp_conductor_ObtenerMensajesChat", new { idServicio, idConductor }, "Mensajes obtenidos");
    }

    [HttpPost("ActivarAlarmaSOS")]
    public async Task<IActionResult> ActivarAlarmaSOS([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_conductor_ActivarAlarmaSOS", d);
        object boxed = result;

        var idServicio = d.ContainsKey("idServicio") ? System.Convert.ToInt64(d["idServicio"]) : 0L;
        if (idServicio > 0)
        {
            var pasajeroId = await GetPasajeroIdFromService(idServicio);
            if (pasajeroId > 0)
            {
                var token = await Fcm.GetPasajeroTokenAsync(pasajeroId);
                if (!string.IsNullOrEmpty(token))
                {
                    _ = Fcm.SendToTokenAsync(token, "ALERTA SOS",
                        "El conductor ha activado la alarma de emergencia",
                        new System.Collections.Generic.Dictionary<string, string>
                        {
                            ["type"] = "sos_conductor",
                            ["idservicio"] = idServicio.ToString(),
                        });
                }
            }
        }
        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Alarma SOS activada");
    }

    [HttpPost("ReportarIncidente")]
    public async Task<IActionResult> ReportarIncidente([FromBody] dynamic p)
    {
        return await SpExecutor.SingleAsync("sp_conductor_ReportarIncidente", p, "Incidente reportado");
    }

    [HttpGet("ObtenerNotificaciones")]
    public async Task<IActionResult> ObtenerNotificaciones(int idConductor)
    {
        return await SpExecutor.ListAsync("sp_conductor_ObtenerNotificaciones", new { idConductor }, "Notificaciones obtenidas");
    }

    [HttpGet("ObtenerAvisos")]
    public async Task<IActionResult> ObtenerAvisos(short idCompania)
    {
        return await SpExecutor.ListAsync("sp_conductor_ObtenerAvisos", new { idCompania }, "Avisos obtenidos");
    }

    [HttpGet("ObtenerServicioActivo")]
    public async Task<IActionResult> ObtenerServicioActivo(int idConductor)
    {
        return await SpExecutor.SingleAsync("sp_conductor_ObtenerServicioActivo", new { idConductor }, "Servicio activo");
    }

    private async Task<long> GetPasajeroIdFromService(long idServicio)
    {
        try
        {
            var detalle = await DatabaseHelper.QueryAsync<object>("sp_conductor_DetalleViaje", new { idServicio, idConductor = 0 });
            foreach (var item in detalle)
            {
                var dict = item as System.Collections.Generic.IDictionary<string, object>;
                if (dict != null && dict.ContainsKey("idpasajero") && dict["idpasajero"] != null)
                    return System.Convert.ToInt64(dict["idpasajero"]);
            }
        }
        catch { }
        return 0;
    }
}