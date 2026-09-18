using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using VaiaViajes.Api.Helpers;
using VaiaViajes.Api.Services;

[Route("api/[controller]")]
[ApiController]
public class PagoController : ControllerBase
{
    private MercadoPagoService MP => HttpContext.RequestServices.GetRequiredService<MercadoPagoService>();
    private PayPalService PP => HttpContext.RequestServices.GetRequiredService<PayPalService>();
    private VaiaViajes.Api.Services.RealtimeNotifier Notifier => HttpContext.RequestServices.GetRequiredService<VaiaViajes.Api.Services.RealtimeNotifier>();

    private class InfoPago
    {
        public decimal Monto { get; set; }
        public string Email { get; set; }
        public string Descripcion { get; set; }
    }

    private async Task<InfoPago> ObtenerInfoPago(long idServicio)
    {
        var rows = await DatabaseHelper.QueryAsync<object>("sp_servicio_Comprobante", new { idServicio });
        var first = System.Linq.Enumerable.FirstOrDefault(rows);
        var c = first as System.Collections.Generic.IDictionary<string, object>;
        if (c == null) return null;

        decimal monto = 0;
        if (c.ContainsKey("costofinal") && c["costofinal"] != null)
            monto = Convert.ToDecimal(c["costofinal"]);
        else if (c.ContainsKey("costoestimado") && c["costoestimado"] != null)
            monto = Convert.ToDecimal(c["costoestimado"]);

        string origen = c.ContainsKey("direccionorigen") ? c["direccionorigen"]?.ToString() : "";
        string destino = c.ContainsKey("direcciondestination") ? c["direcciondestination"]?.ToString() : "";

        return new InfoPago
        {
            Monto = monto,
            Email = c.ContainsKey("pasajero_correo") ? c["pasajero_correo"]?.ToString() : null,
            Descripcion = "Vaia Viajes - Servicio #" + idServicio + " (" + origen + " -> " + destino + ")"
        };
    }

    private string BaseUrl()
    {
        var req = Request;
        if (req == null) return "";
        return req.Scheme + "://" + req.Host.Value;
    }

    /// <summary>Crea una preferencia de MercadoPago y devuelve el link de pago.</summary>
    [HttpPost("MercadoPagoPreferencia")]
    public async Task<IActionResult> MercadoPagoPreferencia([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        long idServicio = d.ContainsKey("idServicio") ? Convert.ToInt64(d["idServicio"]) : 0L;
        if (idServicio <= 0) return "idServicio requerido".VaiaBadRequest("EMPTY_BODY");

        var info = await ObtenerInfoPago(idServicio);
        if (info == null) return "Servicio no encontrado".VaiaNotFound();

        var pref = await MP.CrearPreferenciaAsync(idServicio, info.Monto, info.Descripcion, info.Email, BaseUrl());
        if (pref == null) return "No se pudo crear la preferencia de pago".VaiaBadRequest("MP_ERROR");

        await DatabaseHelper.QueryAsync<object>("sp_pago_Registrar",
            new { idServicio, monto = info.Monto, metodo = "MERCADOPAGO", referencia = pref.Id, estatus = "PENDING" });

        return new OkObjectResult(new
        {
            success = true,
            data = new
            {
                preferenceId = pref.Id,
                initPoint = pref.InitPoint,
                sandboxInitPoint = pref.SandboxInitPoint,
                publicKey = MP.PublicKey,
                monto = info.Monto
            },
            message = "Preferencia creada"
        });
    }

    /// <summary>Confirma manualmente el pago (consulta el estado en MercadoPago).</summary>
    [HttpPost("MercadoPagoConfirmar")]
    public async Task<IActionResult> MercadoPagoConfirmar([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        long idServicio = d.ContainsKey("idServicio") ? Convert.ToInt64(d["idServicio"]) : 0L;
        string paymentId = d.ContainsKey("paymentId") ? d["paymentId"]?.ToString() : null;
        if (idServicio <= 0 || string.IsNullOrEmpty(paymentId)) return "Datos incompletos".VaiaBadRequest("EMPTY_BODY");

        var estado = await MP.ObtenerEstadoPagoAsync(paymentId);
        if (estado != "approved") return ("Pago no aprobado: " + (estado ?? "desconocido")).VaiaBadRequest("MP_NOT_APPROVED");

        var info = await ObtenerInfoPago(idServicio);
        await DatabaseHelper.QueryAsync<object>("sp_pago_Registrar",
            new { idServicio, monto = info != null ? info.Monto : 0m, metodo = "MERCADOPAGO", referencia = paymentId, estatus = "PAID" });
        await Notifier.NotificarEstatusCambiado(idServicio, "Pagado");

        return new OkObjectResult(new { success = true, data = new { pagado = true }, message = "Pago confirmado" });
    }

    /// <summary>Webhook de MercadoPago (IPN).</summary>
    [HttpPost("MercadoPagoWebhook")]
    public async Task<IActionResult> MercadoPagoWebhook([FromQuery] string type, [FromQuery] string data_id, [FromBody] dynamic body)
    {
        try
        {
            string paymentId = data_id;
            if (string.IsNullOrEmpty(paymentId))
            {
                var d = ParameterHelper.ToDictionary(body);
                if (d != null && d.ContainsKey("data"))
                {
                    var dataObj = d["data"] as System.Collections.Generic.IDictionary<string, object>;
                    if (dataObj != null && dataObj.ContainsKey("id")) paymentId = dataObj["id"]?.ToString();
                }
            }
            if (string.IsNullOrEmpty(paymentId)) return Ok();

            var pago = await MP.ObtenerPagoAsync(paymentId);
            if (pago == null || pago.Estado != "approved") return Ok();

            // external_reference = idServicio (se fijo al crear la preferencia)
            long idServicio;
            if (!long.TryParse(pago.ExternalReference, out idServicio) || idServicio <= 0) return Ok();

            var info = await ObtenerInfoPago(idServicio);
            await DatabaseHelper.QueryAsync<object>("sp_pago_Registrar",
                new { idServicio, monto = info != null ? info.Monto : pago.Monto, metodo = "MERCADOPAGO", referencia = paymentId, estatus = "PAID" });
            await Notifier.NotificarEstatusCambiado(idServicio, "Pagado");
            return Ok();
        }
        catch
        {
            return Ok();
        }
    }

    /// <summary>Crea una orden de PayPal y devuelve el link de aprobacion.</summary>
    [HttpPost("PayPalCrearOrden")]
    public async Task<IActionResult> PayPalCrearOrden([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        long idServicio = d.ContainsKey("idServicio") ? Convert.ToInt64(d["idServicio"]) : 0L;
        if (idServicio <= 0) return "idServicio requerido".VaiaBadRequest("EMPTY_BODY");

        var info = await ObtenerInfoPago(idServicio);
        if (info == null) return "Servicio no encontrado".VaiaNotFound();

        var url = await PP.CrearOrdenAsync(idServicio, info.Monto);
        if (string.IsNullOrEmpty(url)) return "No se pudo crear la orden de PayPal".VaiaBadRequest("PAYPAL_ERROR");

        await DatabaseHelper.QueryAsync<object>("sp_pago_Registrar",
            new { idServicio, monto = info.Monto, metodo = "PAYPAL", referencia = (string)null, estatus = "PENDING" });

        return new OkObjectResult(new { success = true, data = new { approveUrl = url, monto = info.Monto }, message = "Orden creada" });
    }

    /// <summary>Captura una orden de PayPal aprobada.</summary>
    [HttpPost("PayPalCapturar")]
    public async Task<IActionResult> PayPalCapturar([FromBody] dynamic p)
    {
        var d = ParameterHelper.ToDictionary(p);
        if (d == null) return "Datos invalidos".VaiaBadRequest("EMPTY_BODY");

        long idServicio = d.ContainsKey("idServicio") ? Convert.ToInt64(d["idServicio"]) : 0L;
        string orderId = d.ContainsKey("orderId") ? d["orderId"]?.ToString() : null;
        if (idServicio <= 0 || string.IsNullOrEmpty(orderId)) return "Datos incompletos".VaiaBadRequest("EMPTY_BODY");

        var ok = await PP.CapturarOrdenAsync(orderId);
        if (!ok) return "No se pudo capturar el pago de PayPal".VaiaBadRequest("PAYPAL_CAPTURE_ERROR");

        var info = await ObtenerInfoPago(idServicio);
        await DatabaseHelper.QueryAsync<object>("sp_pago_Registrar",
            new { idServicio, monto = info != null ? info.Monto : 0m, metodo = "PAYPAL", referencia = orderId, estatus = "PAID" });
        await Notifier.NotificarEstatusCambiado(idServicio, "Pagado");

        return new OkObjectResult(new { success = true, data = new { pagado = true }, message = "Pago confirmado" });
    }
}
