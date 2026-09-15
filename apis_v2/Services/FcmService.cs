using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace VaiaViajes.Api.Services
{
    public class FcmService
    {
        private readonly string _serverKey;
        private static readonly HttpClient _http = new HttpClient();

        private const string FcmUrl = "https://fcm.googleapis.com/fcm/send";

        public FcmService(IConfiguration config)
        {
            _serverKey = config["FcmServerKey"] ?? config.GetSection("Fcm")["ServerKey"];
        }

        public async Task<bool> SendToTokenAsync(string token, string title, string body, object data = null)
        {
            if (string.IsNullOrEmpty(token)) return false;

            var payload = new Dictionary<string, object>
            {
                ["to"] = token,
                ["notification"] = new Dictionary<string, string>
                {
                    ["title"] = title,
                    ["body"] = body,
                    ["sound"] = "default",
                },
                ["data"] = data ?? new Dictionary<string, string>(),
                ["priority"] = "high",
            };

            return await SendAsync(payload);
        }

        public async Task<bool> SendToTopicAsync(string topic, string title, string body, object data = null)
        {
            return await SendToTokenAsync($"/topics/{topic}", title, body, data);
        }

        public async Task<bool> SendToMultipleTokensAsync(List<string> tokens, string title, string body, object data = null)
        {
            if (tokens == null || tokens.Count == 0) return false;

            var payload = new Dictionary<string, object>
            {
                ["registration_ids"] = tokens,
                ["notification"] = new Dictionary<string, string>
                {
                    ["title"] = title,
                    ["body"] = body,
                    ["sound"] = "default",
                },
                ["data"] = data ?? new Dictionary<string, string>(),
                ["priority"] = "high",
            };

            return await SendAsync(payload);
        }

        private async Task<bool> SendAsync(Dictionary<string, object> payload)
        {
            try
            {
                var json = JsonConvert.SerializeObject(payload);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var request = new HttpRequestMessage(HttpMethod.Post, FcmUrl);
                request.Headers.TryAddWithoutValidation("Authorization", $"key={_serverKey}");
                request.Content = content;

                var response = await _http.SendAsync(request);
                var body = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    System.Diagnostics.Debug.WriteLine($"FCM error {response.StatusCode}: {body}");
                    return false;
                }

                var result = JObject.Parse(body);
                var success = result["success"]?.Value<int>() ?? 0;
                return success > 0;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"FCM exception: {ex.Message}");
                return false;
            }
        }

        public async Task<string> GetPasajeroTokenAsync(long idPasajero)
        {
            try
            {
                var data = await DatabaseHelper.QueryAsync<Dictionary<string, object>>(
                    "sp_notificacion_ObtenerTokenPasajero", new { idPasajero });
                var first = data?.FirstOrDefault();
                return first?.ContainsKey("googlekey") == true ? first["googlekey"]?.ToString() : null;
            }
            catch { return null; }
        }

        public async Task<string> GetConductorTokenAsync(int idConductor)
        {
            try
            {
                var data = await DatabaseHelper.QueryAsync<Dictionary<string, object>>(
                    "sp_notificacion_ObtenerTokenConductor", new { idConductor });
                var first = data?.FirstOrDefault();
                return first?.ContainsKey("googlekey") == true ? first["googlekey"]?.ToString() : null;
            }
            catch { return null; }
        }

        public async Task<string> GetConductorNameAsync(int idConductor)
        {
            try
            {
                var data = await DatabaseHelper.QueryAsync<Dictionary<string, object>>(
                    "sp_notificacion_ObtenerNombreConductor", new { idConductor });
                var first = data?.FirstOrDefault();
                return first?.ContainsKey("nombreCompleto") == true ? first["nombreCompleto"]?.ToString() : "Conductor";
            }
            catch { return "Conductor"; }
        }

        public async Task<string> GetPasajeroNameAsync(long idPasajero)
        {
            try
            {
                var data = await DatabaseHelper.QueryAsync<Dictionary<string, object>>(
                    "sp_notificacion_ObtenerNombrePasajero", new { idPasajero });
                var first = data?.FirstOrDefault();
                return first?.ContainsKey("nombreCompleto") == true ? first["nombreCompleto"]?.ToString() : "Pasajero";
            }
            catch { return "Pasajero"; }
        }

        public async Task<List<string>> GetAllConductorTokensAsync(int idCompania)
        {
            try
            {
                var data = await DatabaseHelper.QueryAsync<Dictionary<string, object>>(
                    "sp_notificacion_ObtenerTokensConductoresCompania", new { idCompania });
                return data?
                    .Select(r => r.ContainsKey("googlekey") ? r["googlekey"]?.ToString() : null)
                    .Where(t => !string.IsNullOrEmpty(t))
                    .ToList() ?? new List<string>();
            }
            catch { return new List<string>(); }
        }
    }
}
