using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using VaiaViajes.Api.Helpers;
using VaiaViajes.Api.Services;

[Route("api/[controller]")]
[ApiController]
public class PasajeroController : ControllerBase
{
    private FcmService Fcm => HttpContext.RequestServices.GetRequiredService<FcmService>();
    private VaiaViajes.Api.Services.RealtimeNotifier Notifier => HttpContext.RequestServices.GetRequiredService<VaiaViajes.Api.Services.RealtimeNotifier>();
    private WhatsAppService WhatsApp => HttpContext.RequestServices.GetRequiredService<WhatsAppService>();
    private EmailService Email => HttpContext.RequestServices.GetRequiredService<EmailService>();

    [HttpPost("Registrar")]
    public async Task<IActionResult> Registrar([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        d["pass"] = ParameterHelper.Sha256Hash((string)d["pass"]);
        return await SpExecutor.SingleAsync("sp_pasajero_Registrar", d, "Registro exitoso");
    }

    [HttpPost("IniciarSesion")]
    public async Task<IActionResult> IniciarSesion([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        d["pass"] = ParameterHelper.Sha256Hash((string)d["pass"]);
        return await SpExecutor.SingleAsync("sp_pasajero_IniciarSesion", d, "Inicio de sesion exitoso");
    }

    [HttpPost("CerrarSesion")]
    public async Task<IActionResult> CerrarSesion([FromBody] dynamic p)
    {
        return await SpExecutor.SingleAsync("sp_pasajero_CerrarSesion", p, "Sesion cerrada");
    }

    [HttpPost("ActualizarPerfil")]
    public async Task<IActionResult> ActualizarPerfil([FromBody] dynamic p)
    {
        return await SpExecutor.SingleAsync("sp_pasajero_ActualizarPerfil", p, "Perfil actualizado");
    }

    [HttpGet("ObtenerPerfil")]
    public async Task<IActionResult> ObtenerPerfil(long idPasajero)
    {
        return await SpExecutor.SingleRequiredAsync("sp_pasajero_ObtenerPerfil", new { idPasajero }, "Pasajero no encontrado", "Perfil obtenido");
    }

    [HttpPost("CambiarPassword")]
    public async Task<IActionResult> CambiarPassword([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        d["pass"] = ParameterHelper.Sha256Hash((string)d["pass"]);
        return await SpExecutor.SingleAsync("sp_pasajero_CambiarPassword", d, "Contrasena actualizada");
    }

    /// <summary>Valida el codigo de verificacion enviado por WhatsApp.</summary>
    [HttpPost("ValidarCodigoVerificacion")]
    public async Task<IActionResult> ValidarCodigoVerificacion([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        return await SpExecutor.SingleAsync("sp_pasajero_ValidarCodigoVerificacion", d, "Codigo validado");
    }

    /// <summary>Actualiza el token de push (FCM) del pasajero.</summary>
    [HttpPost("ActualizarToken")]
    public async Task<IActionResult> ActualizarToken([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        return await SpExecutor.SingleAsync("sp_pasajero_ActualizarToken", d, "Token actualizado");
    }

    [HttpPost("EnviarCodigoVerificacion")]
    public async Task<IActionResult> EnviarCodigoVerificacion([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        if (d.ContainsKey("idPasajero") && !d.ContainsKey("codigopaistel"))
        {
            var idPas = System.Convert.ToInt64(d["idPasajero"]);
            var pas = await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerPerfil", new { idPasajero = idPas });
            foreach (var item in pas)
            {
                var dict = item as System.Collections.Generic.IDictionary<string, object>;
                if (dict != null)
                {
                    if (dict.ContainsKey("codigopaistel")) d["codigopaistel"] = dict["codigopaistel"]?.ToString();
                    if (dict.ContainsKey("telefono")) d["telefono"] = dict["telefono"]?.ToString();
                    break;
                }
            }
        }

        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_EnviarCodigoVerificacion", d);
        object boxed = result;

        // Enviar el codigo por WhatsApp (plantilla de autenticacion)
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

    /// <summary>Envia un codigo de verificacion al correo del pasajero (o al correo nuevo).</summary>
    [HttpPost("EnviarCodigoCorreo")]
    public async Task<IActionResult> EnviarCodigoCorreo([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_EnviarCodigoCorreo", d);
        object boxed = result;

        try
        {
            long idPas = d.ContainsKey("idPasajero") && d["idPasajero"] != null ? Convert.ToInt64(d["idPasajero"]) : 0;
            string correo = null, codigo = null, nombre = "Pasajero";

            var first = System.Linq.Enumerable.FirstOrDefault(result as System.Collections.Generic.IEnumerable<object>);
            var dict = first as System.Collections.Generic.IDictionary<string, object>;
            if (dict != null)
            {
                if (dict.ContainsKey("correo") && dict["correo"] != null) correo = dict["correo"].ToString();
                if (dict.ContainsKey("codigoverificacion") && dict["codigoverificacion"] != null) codigo = dict["codigoverificacion"].ToString();
            }

            if (!string.IsNullOrEmpty(correo) && !string.IsNullOrEmpty(codigo))
            {
                try
                {
                    var perfil = await DatabaseHelper.QueryAsync<object>("sp_pasajero_ObtenerPerfil", new { idPasajero = idPas });
                    var pf = System.Linq.Enumerable.FirstOrDefault(perfil as System.Collections.Generic.IEnumerable<object>) as System.Collections.Generic.IDictionary<string, object>;
                    if (pf != null && pf.ContainsKey("nombre") && pf["nombre"] != null) nombre = pf["nombre"].ToString();
                }
                catch { }

                _ = Email.EnviarAsync(correo, "Verifica tu correo - Vaia", EmailTemplates.CodigoVerificacionPasajero(nombre, codigo));
            }
        }
        catch { }

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Codigo enviado");
    }

    /// <summary>Valida el codigo de verificacion enviado por correo electronico.</summary>
    [HttpPost("ValidarCodigoCorreo")]
    public async Task<IActionResult> ValidarCodigoCorreo([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        return await SpExecutor.SingleAsync("sp_pasajero_ValidarCodigoCorreo", d, "Correo verificado");
    }

    /// <summary>Cambia el correo del pasajero validando el codigo enviado al correo nuevo.</summary>
    [HttpPost("CambiarCorreo")]
    public async Task<IActionResult> CambiarCorreo([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        return await SpExecutor.SingleAsync("sp_pasajero_CambiarCorreo", d, "Correo actualizado");
    }

    /// <summary>Inicia sesion o registra al pasajero con Google (valida el idToken).</summary>
    [HttpPost("IniciarSesionGoogle")]
    public async Task<IActionResult> IniciarSesionGoogle([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        string idToken = d.ContainsKey("idToken") && d["idToken"] != null ? d["idToken"].ToString() : null;
        if (string.IsNullOrEmpty(idToken)) return "Token de Google requerido".VaiaBadRequest("GOOGLE_TOKEN_REQUIRED");

        try
        {
            using (var http = new System.Net.Http.HttpClient())
            {
                http.Timeout = TimeSpan.FromSeconds(15);
                var resp = await http.GetAsync("https://oauth2.googleapis.com/tokeninfo?id_token=" + Uri.EscapeDataString(idToken));
                if (!resp.IsSuccessStatusCode)
                    return "No se pudo validar la cuenta de Google".VaiaBadRequest("GOOGLE_TOKEN_INVALID");

                var json = Newtonsoft.Json.Linq.JObject.Parse(await resp.Content.ReadAsStringAsync());
                string sub = (string)json["sub"];
                string email = (string)json["email"];
                string name = (string)json["name"];
                string picture = (string)json["picture"];

                if (string.IsNullOrEmpty(sub) || string.IsNullOrEmpty(email))
                    return "La cuenta de Google no tiene correo asociado".VaiaBadRequest("GOOGLE_NO_EMAIL");

                var parts = (name ?? string.Empty).Split(' ');
                string nombre = parts.Length > 0 && parts[0] != "" ? parts[0] : "Usuario";
                string appaterno = parts.Length > 1 ? parts[1] : "";
                string amaterno = parts.Length > 2 ? string.Join(" ", parts, 2, parts.Length - 2) : "";

                var args = new System.Collections.Generic.Dictionary<string, object>
                {
                    { "googleuserid", sub },
                    { "correo", email },
                    { "nombre", nombre },
                    { "appaterno", appaterno },
                    { "apmaterno", amaterno },
                    { "fotourl", picture },
                    { "idCompania", d.ContainsKey("idCompania") && d["idCompania"] != null ? d["idCompania"] : (object)1 },
                    { "googlekey", d.ContainsKey("googlekey") ? d["googlekey"] : null },
                    { "googlekeyso", d.ContainsKey("googlekeyso") ? d["googlekeyso"] : null },
                    { "dispositivoinfo", d.ContainsKey("dispositivoinfo") ? d["dispositivoinfo"] : null },
                    { "sistemaoperativo", d.ContainsKey("sistemaoperativo") ? d["sistemaoperativo"] : null },
                    { "ipaddress", HttpContext.Connection.RemoteIpAddress != null ? HttpContext.Connection.RemoteIpAddress.ToString() : null },
                    { "useragent", Request.Headers["User-Agent"].ToString() }
                };

                var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_IniciarSesionGoogle", args);
                return ApiResultExtensions.VaiaSingleFromSp((object)result, "Inicio de sesion exitoso");
            }
        }
        catch (Exception ex)
        {
            return ("Error al validar la cuenta de Google: " + ex.Message).VaiaBadRequest("GOOGLE_ERROR");
        }
    }

    [HttpPost("CambiarTelefono")]
    public async Task<IActionResult> CambiarTelefono([FromBody] dynamic p)
    {
        return await SpExecutor.SingleAsync("sp_pasajero_CambiarTelefono", p, "Telefono actualizado");
    }

    [HttpPost("ValidarCodigoPromocional")]
    public async Task<IActionResult> ValidarCodigoPromocional([FromBody] dynamic p)
    {
        return await SpExecutor.ListAsync("sp_pasajero_ValidarCodigoPromocional", p, "Codigo validado");
    }

    [HttpPost("SolicitarServicio")]
    public async Task<IActionResult> SolicitarServicio([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_SolicitarServicio", d);
        object boxed = result;

        long idServicioCreado = 0;
        var list = boxed as System.Collections.IEnumerable;
        if (list != null)
        {
            foreach (var item in list)
            {
                var dict = item as System.Collections.Generic.IDictionary<string, object>;
                if (dict != null)
                {
                    if (dict.ContainsKey("idservicio") && dict["idservicio"] != null)
                        idServicioCreado = System.Convert.ToInt64(dict["idservicio"]);
                    var idCompania = dict.ContainsKey("idcompania") ? dict["idcompania"] : (d.ContainsKey("idCompania") ? d["idCompania"] : null);
                    if (idCompania != null)
                    {
                        var tokens = await Fcm.GetAllConductorTokensAsync(System.Convert.ToInt32(idCompania));
                        if (tokens.Count > 0)
                        {
                            var data = new System.Collections.Generic.Dictionary<string, string>
                            {
                                ["type"] = "new_ride",
                                ["idservicio"] = idServicioCreado.ToString(),
                            };
                            _ = Fcm.SendToMultipleTokensAsync(tokens, "Nuevo servicio disponible",
                                "Hay un nuevo viaje solicitado cerca de tu ubicacion", data);
                        }
                    }
                    break;
                }
            }
        }

        // Notificar por WebSocket a conductores y admins
        if (idServicioCreado > 0)
        {
            // Nota: el origen ya se registra dentro de sp_pasajero_SolicitarServicio
            // (tbhistoriallatlngconsultadapasajero) para la analitica de zonas.
            var payload = new
            {
                idServicio = idServicioCreado,
                idPasajero = d.ContainsKey("idPasajero") ? d["idPasajero"] : null,
                direccionOrigen = d.ContainsKey("dirOrigen") ? d["dirOrigen"]?.ToString() : "",
                direccionDestino = d.ContainsKey("dirDestino") ? d["dirDestino"]?.ToString() : "",
                latOrigen = d.ContainsKey("latOrigen") ? d["latOrigen"]?.ToString() : "",
                lngOrigen = d.ContainsKey("lngOrigen") ? d["lngOrigen"]?.ToString() : "",
                fecha = System.DateTime.UtcNow.ToString("o")
            };
            await Notifier.NotificarNuevoServicio(payload);
            await Notifier.NotificarNuevoServicioAdmin(payload);
        }

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Servicio solicitado");
    }

    [HttpGet("ConductoresDisponibles")]
    public async Task<IActionResult> ConductoresDisponibles(string lat, string lng, int? idZona)
    {
        return await SpExecutor.ListAsync("sp_pasajero_ConductoresDisponibles", new { lat, lng, idZona }, "Conductores cercanos");
    }

    [HttpGet("ObtenerEstadoServicio")]
    public async Task<IActionResult> ObtenerEstadoServicio(long idServicio, long idPasajero)
    {
        return await SpExecutor.SingleRequiredAsync("sp_pasajero_ObtenerEstadoServicio", new { idServicio, idPasajero }, "Servicio no encontrado", "Estado del servicio");
    }

    [HttpPost("CancelarServicio")]
    public async Task<IActionResult> CancelarServicio([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_CancelarServicio", d);
        object boxed = result;

        var idServicio = d.ContainsKey("idServicio") ? System.Convert.ToInt64(d["idServicio"]) : 0L;
        var idPasajero = d.ContainsKey("idPasajero") ? System.Convert.ToInt64(d["idPasajero"]) : 0L;
        if (idServicio > 0)
        {
            var conductorId = await GetConductorIdFromService(idServicio);
            if (conductorId > 0)
            {
                var token = await Fcm.GetConductorTokenAsync(conductorId);
                var nombre = await Fcm.GetPasajeroNameAsync(idPasajero);
                if (!string.IsNullOrEmpty(token))
                {
                    _ = Fcm.SendToTokenAsync(token, "Servicio cancelado",
                        $"{nombre} ha cancelado el servicio #{idServicio}",
                        new System.Collections.Generic.Dictionary<string, string>
                        {
                            ["type"] = "ride_cancelled",
                            ["idservicio"] = idServicio.ToString(),
                        });
                }
            }
            // Notificar por WebSocket
            var motivo = d.ContainsKey("motivo") ? d["motivo"]?.ToString() : "";
            await Notifier.NotificarServicioCancelado(idServicio, motivo, "pasajero");
            await Notifier.NotificarEstatusAdmin(idServicio, "Cancelado por Pasajero");
        }
        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Servicio cancelado");
    }

    [HttpPost("CalificarViaje")]
    public async Task<IActionResult> CalificarViaje([FromBody] dynamic p)
    {
        return await SpExecutor.SingleAsync("sp_pasajero_CalificarViaje", p, "Calificacion registrada");
    }

    [HttpPost("IniciarServicio")]
    public async Task<IActionResult> IniciarServicio([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_IniciarServicio", d);
        object boxed = result;

        var idServicio = d.ContainsKey("idServicio") ? System.Convert.ToInt64(d["idServicio"]) : 0L;
        if (idServicio > 0)
        {
            var conductorId = await GetConductorIdFromService(idServicio);
            if (conductorId > 0)
            {
                var token = await Fcm.GetConductorTokenAsync(conductorId);
                if (!string.IsNullOrEmpty(token))
                {
                    _ = Fcm.SendToTokenAsync(token, "Servicio iniciado",
                        "El pasajero ha confirmado el inicio del viaje",
                        new System.Collections.Generic.Dictionary<string, string>
                        {
                            ["type"] = "ride_started",
                            ["idservicio"] = idServicio.ToString(),
                        });
                }
            }
        }
        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Servicio iniciado");
    }

    [HttpPost("ActivarAlarmaSOS")]
    public async Task<IActionResult> ActivarAlarmaSOS([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");
        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_ActivarAlarmaSOS", d);
        object boxed = result;

        var idServicio = d.ContainsKey("idServicio") ? System.Convert.ToInt64(d["idServicio"]) : 0L;
        if (idServicio > 0)
        {
            var conductorId = await GetConductorIdFromService(idServicio);
            if (conductorId > 0)
            {
                var token = await Fcm.GetConductorTokenAsync(conductorId);
                if (!string.IsNullOrEmpty(token))
                {
                    _ = Fcm.SendToTokenAsync(token, "ALERTA SOS",
                        "El pasajero ha activado la alarma de emergencia",
                        new System.Collections.Generic.Dictionary<string, string>
                        {
                            ["type"] = "sos_passenger",
                            ["idservicio"] = idServicio.ToString(),
                        });
                }
            }
        }
        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Alarma SOS activada");
    }

    [HttpPost("AgregarFavorito")]
    public async Task<IActionResult> AgregarFavorito([FromBody] dynamic p)
    {
        return await SpExecutor.SingleAsync("sp_pasajero_AgregarFavorito", p, "Favorito agregado");
    }

    [HttpGet("ListarFavoritos")]
    public async Task<IActionResult> ListarFavoritos(long idPasajero)
    {
        return await SpExecutor.ListAsync("sp_pasajero_ListarFavoritos", new { idPasajero }, "Favoritos listados");
    }

    [HttpPost("EliminarFavorito")]
    public async Task<IActionResult> EliminarFavorito([FromBody] dynamic p)
    {
        return await SpExecutor.SingleAsync("sp_pasajero_EliminarFavorito", p, "Favorito eliminado");
    }

    [HttpGet("HistorialViajes")]
    public async Task<IActionResult> HistorialViajes(long idPasajero, int pagina = 1, int tamano = 20, System.DateTime? fi = null, System.DateTime? ff = null)
    {
        return await SpExecutor.ListAsync("sp_pasajero_HistorialViajes", new { idPasajero, pagina, tamano, fi, ff }, "Historial obtenido");
    }

    [HttpGet("DetalleViaje")]
    public async Task<IActionResult> DetalleViaje(long idServicio, long idPasajero)
    {
        return await SpExecutor.SingleRequiredAsync("sp_pasajero_DetalleViaje", new { idServicio, idPasajero }, "Viaje no encontrado", "Detalle del viaje");
    }

    [HttpPost("ReportarIncidente")]
    public async Task<IActionResult> ReportarIncidente([FromBody] dynamic p)
    {
        return await SpExecutor.SingleAsync("sp_pasajero_ReportarIncidente", p, "Incidente reportado");
    }

    [HttpGet("ObtenerConfiguracionCostos")]
    public async Task<IActionResult> ObtenerConfiguracionCostos(short idCompania)
    {
        return await SpExecutor.ListAsync("sp_pasajero_ObtenerConfiguracionCostos", new { idCompania }, "Configuracion de costos");
    }

    [HttpGet("ObtenerAvisos")]
    public async Task<IActionResult> ObtenerAvisos(short idCompania)
    {
        return await SpExecutor.ListAsync("sp_pasajero_ObtenerAvisos", new { idCompania }, "Avisos obtenidos");
    }

    [HttpGet("ObtenerPromociones")]
    public async Task<IActionResult> ObtenerPromociones()
    {
        return await SpExecutor.ListAsync("sp_pasajero_ObtenerPromociones", "Promociones obtenidas");
    }

    [HttpGet("ObtenerPropagandas")]
    public async Task<IActionResult> ObtenerPropagandas()
    {
        return await SpExecutor.ListAsync("sp_pasajero_ObtenerPropagandas", "Propagandas obtenidas");
    }

    [HttpPost("EnviarMensajeChat")]
    public async Task<IActionResult> EnviarMensajeChat([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_EnviarMensajeChat", d);
        object boxed = result;

        var idServicio = d.ContainsKey("idServicio") ? System.Convert.ToInt64(d["idServicio"]) : 0L;
        var idPasajero = d.ContainsKey("idPasajero") ? System.Convert.ToInt64(d["idPasajero"]) : 0L;
        if (idServicio > 0)
        {
            var conductorId = await GetConductorIdFromService(idServicio);
            if (conductorId > 0)
            {
                var token = await Fcm.GetConductorTokenAsync(conductorId);
                var nombre = await Fcm.GetPasajeroNameAsync(idPasajero);
                if (!string.IsNullOrEmpty(token))
                {
                    var msgPreview = (d.ContainsKey("mensaje") ? d["mensaje"]?.ToString() : "") ?? "";
                    if (msgPreview.Length > 80) msgPreview = msgPreview.Substring(0, 80) + "...";
                    _ = Fcm.SendToTokenAsync(token, $"Mensaje de {nombre}", msgPreview,
                        new System.Collections.Generic.Dictionary<string, string>
                        {
                            ["type"] = "chat_message",
                            ["idservicio"] = idServicio.ToString(),
                            ["emisor"] = "pasajero",
                        });
                }
            }

            // Notificar por WebSocket al chat del servicio
            var nombrePasajero = await Fcm.GetPasajeroNameAsync(idPasajero);
            await Notifier.NotificarMensajeChat(idServicio, new
            {
                idServicio,
                emisor = "pasajero",
                mensaje = d.ContainsKey("mensaje") ? d["mensaje"]?.ToString() : "",
                nombreEmisor = nombrePasajero,
                fecha = System.DateTime.UtcNow.ToString("o")
            });
        }
        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Mensaje enviado");
    }

    [HttpGet("ObtenerMensajesChat")]
    public async Task<IActionResult> ObtenerMensajesChat(long idServicio, long idPasajero)
    {
        return await SpExecutor.ListAsync("sp_pasajero_ObtenerMensajesChat", new { idServicio, idPasajero }, "Mensajes obtenidos");
    }

    private async Task<int> GetConductorIdFromService(long idServicio)
    {
        try
        {
            var data = await DatabaseHelper.QueryAsync<object>("sp_conductor_DetalleViaje", new { idServicio, idConductor = 0 });
            foreach (var item in data)
            {
                var dict = item as System.Collections.Generic.IDictionary<string, object>;
                if (dict != null && dict.ContainsKey("idconductor") && dict["idconductor"] != null && dict["idconductor"].ToString() != "0")
                    return System.Convert.ToInt32(dict["idconductor"]);
            }
        }
        catch { }
        return 0;
    }
}