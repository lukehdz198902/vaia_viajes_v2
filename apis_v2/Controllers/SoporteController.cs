using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using VaiaViajes.Api.Helpers;
using VaiaViajes.Api.Services;

[Route("api/[controller]")]
[ApiController]
public class SoporteController : ControllerBase
{
    private RealtimeNotifier Notifier => HttpContext.RequestServices.GetRequiredService<RealtimeNotifier>();
    private FcmService Fcm => HttpContext.RequestServices.GetRequiredService<FcmService>();

    /// <summary>
    /// Crea una solicitud de soporte referenciando un servicio.
    /// El tipoSolicitante puede ser 'pasajero' o 'conductor'.
    /// </summary>
    [HttpPost("CrearSolicitud")]
    public async Task<IActionResult> CrearSolicitud([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_soporte_CrearSolicitud", d);
        object boxed = result;

        // Extraer id y detectar si es nueva
        long idSolicitud = 0;
        bool esNueva = true;
        if (boxed is System.Collections.IEnumerable en)
        {
            foreach (var item in en)
            {
                var dict = item as IDictionary<string, object>;
                if (dict != null)
                {
                    if (dict.ContainsKey("id") && dict["id"] != null)
                        idSolicitud = Convert.ToInt64(dict["id"]);
                    if (dict.ContainsKey("existente") && dict["existente"] != null && Convert.ToInt32(dict["existente"]) == 1)
                        esNueva = false;
                }
                break;
            }
        }

        if (idSolicitud > 0 && esNueva)
        {
            var solicitud = await DatabaseHelper.QueryAsync<object>("sp_soporte_ObtenerSolicitud", new { id = idSolicitud });
            object solBoxed = solicitud;
            await Notifier.NotificarNuevaSolicitudSoporte(solBoxed);
        }

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Solicitud creada");
    }

    [HttpGet("ListarSolicitudes")]
    public async Task<IActionResult> ListarSolicitudes(string estatus = null, string tipoSolicitante = null, long? idservicio = null, int pagina = 1, int tamano = 50)
    {
        return await SpExecutor.ListAsync("sp_soporte_ListarSolicitudes",
            new { estatus, tipoSolicitante, idservicio, pagina, tamano }, "Solicitudes listadas");
    }

    [HttpGet("ObtenerSolicitud")]
    public async Task<IActionResult> ObtenerSolicitud(long id)
    {
        return await SpExecutor.SingleRequiredAsync("sp_soporte_ObtenerSolicitud", new { id }, "Solicitud no encontrada", "Solicitud obtenida");
    }

    /// <summary>
    /// Envia un mensaje en la solicitud. Emisor: 'pasajero', 'conductor' o 'soporte'.
    /// </summary>
    [HttpPost("EnviarMensaje")]
    public async Task<IActionResult> EnviarMensaje([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_soporte_EnviarMensaje", d);
        object boxed = result;

        long idSolicitud = d.ContainsKey("idsolicitud") ? Convert.ToInt64(d["idsolicitud"]) : 0;
        string emisor = d.ContainsKey("emisor") ? d["emisor"]?.ToString() : "";
        string mensaje = d.ContainsKey("mensaje") ? d["mensaje"]?.ToString() : "";
        string nombreEmisor = d.ContainsKey("nombreEmisor") ? d["nombreEmisor"]?.ToString() : "";

        if (idSolicitud > 0)
        {
            var payload = new
            {
                idSolicitud,
                emisor,
                idEmisor = d.ContainsKey("idemisor") && d["idemisor"] != null ? Convert.ToInt64(d["idemisor"]) : 0,
                nombreEmisor,
                mensaje,
                fecha = DateTime.UtcNow.ToString("o")
            };
            await Notifier.NotificarMensajeSoporte(idSolicitud, payload);

            // Si el emisor es usuario (pasajero/conductor), notificar a soporte por push tambien
            if (emisor != "soporte")
            {
                try
                {
                    var solicitud = await DatabaseHelper.QueryAsync<object>("sp_soporte_ObtenerSolicitud", new { id = idSolicitud });
                    foreach (var s in solicitud)
                    {
                        var dict = s as IDictionary<string, object>;
                        if (dict == null) break;
                        string servicio = dict.ContainsKey("idservicio") ? dict["idservicio"]?.ToString() : "";
                        // No hay tokens de admins en BD; el portal recibe por SignalR
                        break;
                    }
                }
                catch { }
            }
        }

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Mensaje enviado");
    }

    [HttpGet("ListarMensajes")]
    public async Task<IActionResult> ListarMensajes(long idsolicitud, string emisor = null)
    {
        return await SpExecutor.ListAsync("sp_soporte_ListarMensajes", new { idsolicitud, emisor }, "Mensajes listados");
    }

    [HttpPost("AsignarSoporte")]
    public async Task<IActionResult> AsignarSoporte([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_soporte_AsignarSoporte", d);
        object boxed = result;

        long id = d.ContainsKey("id") ? Convert.ToInt64(d["id"]) : 0;
        if (id > 0)
            await Notifier.NotificarSolicitudActualizada(id, "EnAtencion", new { idSolicitud = id, estatus = "EnAtencion" });

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Solicitud asignada");
    }

    [HttpPost("CerrarSolicitud")]
    public async Task<IActionResult> CerrarSolicitud([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_soporte_CerrarSolicitud", d);
        object boxed = result;

        long id = d.ContainsKey("id") ? Convert.ToInt64(d["id"]) : 0;
        if (id > 0)
            await Notifier.NotificarSolicitudActualizada(id, "Cerrado", new { idSolicitud = id, estatus = "Cerrado" });

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Solicitud cerrada");
    }

    [HttpPost("MarcarLeidos")]
    public async Task<IActionResult> MarcarLeidos([FromBody] dynamic p)
    {
        return await SpExecutor.SingleAsync("sp_soporte_MarcarLeidos", p, "Marcados como leidos");
    }

    [HttpGet("ContarNoLeidos")]
    public async Task<IActionResult> ContarNoLeidos(string paraEmisor = "soporte")
    {
        return await SpExecutor.SingleAsync("sp_soporte_ContarNoLeidos", new { paraEmisor }, "Conteo obtenido");
    }
}