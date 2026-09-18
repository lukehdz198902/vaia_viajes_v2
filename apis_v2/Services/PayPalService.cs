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
    /// Integracion con PayPal (Orders v2).
    /// Crea una orden y devuelve el link de aprobacion; luego captura el pago.
    /// </summary>
    public class PayPalService
    {
        private readonly IConfiguration _config;
        private static readonly HttpClient _http = new HttpClient();

        public PayPalService(IConfiguration config)
        {
            _config = config;
        }

        private bool UseSandbox
        {
            get { return string.Equals(_config["PayPal:UseSandbox"], "true", StringComparison.OrdinalIgnoreCase); }
        }

        private string BaseUrl
        {
            get { return UseSandbox ? "https://api-m.sandbox.paypal.com" : "https://api-m.paypal.com"; }
        }

        private string ClientId
        {
            get
            {
                return UseSandbox
                    ? (_config["PayPal:ClientIdSandbox"] ?? _config["PayPal:ClientId"])
                    : _config["PayPal:ClientId"];
            }
        }

        private string ClientSecret
        {
            get
            {
                return UseSandbox
                    ? (_config["PayPal:ClientSecretSandbox"] ?? _config["PayPal:ClientSecret"])
                    : _config["PayPal:ClientSecret"];
            }
        }

        public bool Configurado
        {
            get { return !string.IsNullOrEmpty(ClientId) && !string.IsNullOrEmpty(ClientSecret); }
        }

        private async Task<string> GetTokenAsync()
        {
            var creds = Convert.ToBase64String(Encoding.UTF8.GetBytes(ClientId + ":" + ClientSecret));
            var req = new HttpRequestMessage(HttpMethod.Post, BaseUrl + "/v1/oauth2/token");
            req.Headers.TryAddWithoutValidation("Authorization", "Basic " + creds);
            req.Content = new FormUrlEncodedContent(new Dictionary<string, string> { ["grant_type"] = "client_credentials" });
            var resp = await _http.SendAsync(req);
            var body = await resp.Content.ReadAsStringAsync();
            if (!resp.IsSuccessStatusCode)
            {
                Console.WriteLine("[PayPal token] " + resp.StatusCode + ": " + body);
                return null;
            }
            return JObject.Parse(body)["access_token"]?.ToString();
        }

        public async Task<string> CrearOrdenAsync(long idServicio, decimal monto)
        {
            try
            {
                var token = await GetTokenAsync();
                if (string.IsNullOrEmpty(token)) return null;

                var payload = new Dictionary<string, object>
                {
                    ["intent"] = "CAPTURE",
                    ["purchase_units"] = new object[]
                    {
                        new Dictionary<string, object>
                        {
                            ["reference_id"] = idServicio.ToString(),
                            ["amount"] = new Dictionary<string, string>
                            {
                                ["currency_code"] = "MXN",
                                ["value"] = monto.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture)
                            }
                        }
                    },
                    ["application_context"] = new Dictionary<string, object>
                    {
                        ["brand_name"] = "Vaia Viajes",
                        ["user_action"] = "PAY_NOW",
                        ["return_url"] = "vaia://pago/success",
                        ["cancel_url"] = "vaia://pago/cancel"
                    }
                };

                var json = JsonConvert.SerializeObject(payload);
                var req = new HttpRequestMessage(HttpMethod.Post, BaseUrl + "/v2/checkout/orders");
                req.Headers.TryAddWithoutValidation("Authorization", "Bearer " + token);
                req.Content = new StringContent(json, Encoding.UTF8, "application/json");

                var resp = await _http.SendAsync(req);
                var body = await resp.Content.ReadAsStringAsync();
                if (!resp.IsSuccessStatusCode)
                {
                    Console.WriteLine("[PayPal order] " + resp.StatusCode + ": " + body);
                    return null;
                }

                var o = JObject.Parse(body);
                foreach (var link in o["links"] ?? new JArray())
                {
                    if (link["rel"]?.ToString() == "approve") return link["href"]?.ToString();
                }
                return null;
            }
            catch (Exception ex)
            {
                Console.WriteLine("[PayPal] " + ex.Message);
                return null;
            }
        }

        public async Task<bool> CapturarOrdenAsync(string orderId)
        {
            try
            {
                var token = await GetTokenAsync();
                if (string.IsNullOrEmpty(token)) return false;

                var req = new HttpRequestMessage(HttpMethod.Post, BaseUrl + "/v2/checkout/orders/" + orderId + "/capture");
                req.Headers.TryAddWithoutValidation("Authorization", "Bearer " + token);
                req.Content = new StringContent("{}", Encoding.UTF8, "application/json");

                var resp = await _http.SendAsync(req);
                var body = await resp.Content.ReadAsStringAsync();
                if (!resp.IsSuccessStatusCode)
                {
                    Console.WriteLine("[PayPal capture] " + resp.StatusCode + ": " + body);
                    return false;
                }
                var status = JObject.Parse(body)["status"]?.ToString();
                return string.Equals(status, "COMPLETED", StringComparison.OrdinalIgnoreCase);
            }
            catch (Exception ex)
            {
                Console.WriteLine("[PayPal capture] " + ex.Message);
                return false;
            }
        }
    }
}
