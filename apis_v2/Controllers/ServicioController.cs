using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using VaiaViajes.Api.Helpers;
using VaiaViajes.Api.Services;

[Route("api/[controller]")]
[ApiController]
public class ServicioController : ControllerBase
{
    private RealtimeNotifier Notifier => HttpContext.RequestServices.GetRequiredService<RealtimeNotifier>();

    // ─── PARADAS INTERMEDIAS ─────────────────────────────────────────

    [HttpPost("AgregarParada")]
    public async Task<IActionResult> AgregarParada([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_servicio_AgregarParada", d);
        object boxed = result;

        long idServicio = d.ContainsKey("idservicio") ? Convert.ToInt64(d["idservicio"]) : 0;
        if (idServicio > 0)
            await Notifier.NotificarEstatusCambiado(idServicio, "ParadaAgregada", new { idServicio, parada = boxed });

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Parada agregada");
    }

    [HttpGet("ListarParadas")]
    public async Task<IActionResult> ListarParadas(long idservicio)
    {
        return await SpExecutor.ListAsync("sp_servicio_ListarParadas", new { idservicio }, "Paradas listadas");
    }

    [HttpPost("CompletarParada")]
    public async Task<IActionResult> CompletarParada([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_servicio_CompletarParada", d);
        object boxed = result;

        long idParada = d.ContainsKey("idParada") ? Convert.ToInt64(d["idParada"]) : 0;
        if (idParada > 0)
        {
            // Notificar a todos los involucrados
            long idServicio = 0;
            if (boxed is System.Collections.IEnumerable en)
            {
                foreach (var item in en)
                {
                    var dict = item as IDictionary<string, object>;
                    if (dict != null && dict.ContainsKey("idservicio") && dict["idservicio"] != null)
                        idServicio = Convert.ToInt64(dict["idservicio"]);
                    break;
                }
            }
            if (idServicio > 0)
                await Notifier.NotificarEstatusCambiado(idServicio, "ParadaCompletada", new { idServicio, idParada });
        }

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Parada completada");
    }

    [HttpPost("EliminarParada")]
    public async Task<IActionResult> EliminarParada([FromBody] dynamic p)
    {
        return await SpExecutor.SingleAsync("sp_servicio_EliminarParada", p, "Parada eliminada");
    }

    // ─── SERVICIOS PROGRAMADOS ───────────────────────────────────────

    [HttpPost("Programar")]
    public async Task<IActionResult> Programar([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_ProgramarServicio", d);
        object boxed = result;

        long idPasajero = d.ContainsKey("idPasajero") ? Convert.ToInt64(d["idPasajero"]) : 0;
        long idProgramado = 0;
        if (boxed is System.Collections.IEnumerable en)
        {
            foreach (var item in en)
            {
                var dict = item as IDictionary<string, object>;
                if (dict != null && dict.ContainsKey("id") && dict["id"] != null)
                    idProgramado = Convert.ToInt64(dict["id"]);
                break;
            }
        }

        if (idProgramado > 0 && idPasajero > 0)
        {
            await Notifier.NotificarPasajero(idPasajero, "ServicioProgramado", new
            {
                idProgramado,
                mensaje = "Servicio programado exitosamente"
            });
        }

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Servicio programado");
    }

    [HttpGet("ListarProgramados")]
    public async Task<IActionResult> ListarProgramados(long idPasajero, string estado = null)
    {
        return await SpExecutor.ListAsync("sp_pasajero_ListarServiciosProgramados", new { idPasajero, estado }, "Programados listados");
    }

    [HttpGet("ObtenerProgramado")]
    public async Task<IActionResult> ObtenerProgramado(long id, long idPasajero)
    {
        return await SpExecutor.SingleRequiredAsync("sp_pasajero_ObtenerServicioProgramado", new { id, idPasajero }, "Programado no encontrado", "Programado obtenido");
    }

    [HttpPost("CancelarProgramado")]
    public async Task<IActionResult> CancelarProgramado([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        var result = await DatabaseHelper.QueryAsync<object>("sp_pasajero_CancelarServicioProgramado", d);
        object boxed = result;

        long idPasajero = d.ContainsKey("idPasajero") ? Convert.ToInt64(d["idPasajero"]) : 0;
        long id = d.ContainsKey("id") ? Convert.ToInt64(d["id"]) : 0;
        if (idPasajero > 0)
            await Notifier.NotificarPasajero(idPasajero, "ServicioProgramadoCancelado", new { id });

        return ApiResultExtensions.VaiaSingleFromSp(boxed, "Programado cancelado");
    }
}