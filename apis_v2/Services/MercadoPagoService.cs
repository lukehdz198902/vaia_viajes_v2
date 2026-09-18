using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace VaiaViajes.Api.Services
{
    /// <summary>
    /// Integracion con MercadoPago (Checkout Pro).
    /// Crea una preferencia y devuelve el init_point para que el pasajero pague.
    /// </summary>
    public class MercadoPagoService
    {
        private readonly IConfiguration _config;
        private static readonly HttpClient _http = new HttpClient();

        public MercadoPagoService(IConfiguration config)
        {
            _config = config;
        }

        public string PublicKey
        {
            get { return _config["MercadoPago:PublicKey"]; }
        }

        public bool Sandbox
        {
            get { return string.Equals(_config["MercadoPago:SandboxMode"], "true", StringComparison.OrdinalIgnoreCase); }
        }

        public bool Configurado
        {
            get { return !string.IsNullOrEmpty(_config["MercadoPago:AccessToken"]); }
        }

        public async Task<MercadoPagoPreferencia> CrearPreferenciaAsync(long idServicio, decimal monto, string descripcion, string emailPasajero, string baseUrl)
        {
            try
            {
                var token = _config["MercadoPago:AccessToken"];
                if (string.IsNullOrEmpty(token)) return null;

                var payload = new Dictionary<string, object>
                {
                    ["items"] = new object[]
                    {
                        new Dictionary<string, object>
                        {
                            ["title"] = descripcion,
                            ["quantity"] = 1,
                            ["currency_id"] = "MXN",
                            ["unit_price"] = (double)monto
                        }
                    },
                    ["external_reference"] = idServicio.ToString(),
                    ["notification_url"] = (baseUrl ?? "").TrimEnd('/') + "/api/Pago/MercadoPagoWebhook",
                    ["back_urls"] = new Dictionary<string, string>
                    {
                        ["success"] = "vaia://pago/success",
                        ["failure"] = "vaia://pago/failure",
                        ["pending"] = "vaia://pago/pending"
                    }
                };
                if (!string.IsNullOrEmpty(emailPasajero))
                    payload["payer"] = new Dictionary<string, object> { ["email"] = emailPasajero };

                var json = JsonConvert.SerializeObject(payload);
                var req = new HttpRequestMessage(HttpMethod.Post, "https://api.mercadopago.com/checkout/preferences");
                req.Headers.TryAddWithoutValidation("Authorization", "Bearer " + token);
                var integrator = _config["MercadoPago:IntegratorId"];
                if (!string.IsNullOrEmpty(integrator)) req.Headers.TryAddWithoutValidation("X-Integrator-Id", integrator);
                req.Content = new StringContent(json, Encoding.UTF8, "application/json");

                var resp = await _http.SendAsync(req);
                var body = await resp.Content.ReadAsStringAsync();
                if (!resp.IsSuccessStatusCode)
                {
                    Console.WriteLine("[MercadoPago] " + resp.StatusCode + ": " + body);
                    return null;
                }
                var o = JObject.Parse(body);
                return new MercadoPagoPreferencia
                {
                    Id = o["id"]?.ToString(),
                    InitPoint = o["init_point"]?.ToString(),
                    SandboxInitPoint = o["sandbox_init_point"]?.ToString()
                };
            }
            catch (Exception ex)
            {
                Console.WriteLine("[MercadoPago] " + ex.Message);
                return null;
            }
        }

        /// <summary>Consulta el estado de un pago (approved / pending / rejected).</summary>
        public async Task<string> ObtenerEstadoPagoAsync(string paymentId)
        {
            var pago = await ObtenerPagoAsync(paymentId);
            return pago != null ? pago.Estado : null;
        }

        /// <summary>Consulta el detalle de un pago (estado, referencia y monto).</summary>
        public async Task<MercadoPagoPago> ObtenerPagoAsync(string paymentId)
        {
            try
            {
                var token = _config["MercadoPago:AccessToken"];
                var req = new HttpRequestMessage(HttpMethod.Get, "https://api.mercadopago.com/v1/payments/" + paymentId);
                req.Headers.TryAddWithoutValidation("Authorization", "Bearer " + token);
                var resp = await _http.SendAsync(req);
                var body = await resp.Content.ReadAsStringAsync();
                if (!resp.IsSuccessStatusCode) return null;
                var o = JObject.Parse(body);
                return new MercadoPagoPago
                {
                    Estado = o["status"]?.ToString(),
                    ExternalReference = o["external_reference"]?.ToString(),
                    Monto = o["transaction_amount"] != null ? o["transaction_amount"].Value<decimal>() : 0m
                };
            }
            catch { return null; }
        }
    }

    public class MercadoPagoPreferencia
    {
        public string Id { get; set; }
        public string InitPoint { get; set; }
        public string SandboxInitPoint { get; set; }
    }

    public class MercadoPagoPago
    {
        public string Estado { get; set; }
        public string ExternalReference { get; set; }
        public decimal Monto { get; set; }
    }
}
