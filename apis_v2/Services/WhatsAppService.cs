using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;

namespace VaiaViajes.Api.Services
{
    /// <summary>
    /// Envio de mensajes por WhatsApp Cloud API (Meta Graph).
    /// Se usa para enviar el codigo de verificacion con la plantilla de autenticacion.
    /// Si no esta configurado, no falla: devuelve false.
    /// </summary>
    public class WhatsAppService
    {
        private readonly IConfiguration _config;
        private static readonly HttpClient _http = new HttpClient();

        public WhatsAppService(IConfiguration config)
        {
            _config = config;
        }

        public bool Configurado
        {
            get
            {
                return !string.IsNullOrEmpty(_config["WhatsApp:ApiKey"])
                    && !string.IsNullOrEmpty(_config["WhatsApp:PhoneNumberId"]);
            }
        }

        public async Task<bool> EnviarCodigoAsync(string telefono, string codigo)
        {
            try
            {
                var apiKey = _config["WhatsApp:ApiKey"];
                var phoneId = _config["WhatsApp:PhoneNumberId"];
                var plantilla = _config["WhatsApp:PlantillaAuth"];
                var urlTpl = _config["WhatsApp:Url"];
                if (string.IsNullOrEmpty(urlTpl)) urlTpl = "https://graph.facebook.com/v20.0/{0}/messages";
                if (string.IsNullOrEmpty(plantilla)) plantilla = "hello_world";
                if (string.IsNullOrEmpty(apiKey) || string.IsNullOrEmpty(phoneId)) return false;

                var to = NormalizarTelefono(telefono);
                if (string.IsNullOrEmpty(to)) return false;

                var url = string.Format(urlTpl, phoneId);

                var payload = new
                {
                    messaging_product = "whatsapp",
                    to,
                    type = "template",
                    template = new
                    {
                        name = plantilla,
                        language = new { code = "es_MX" },
                        components = new object[]
                        {
                            new { type = "body", parameters = new object[] { new { type = "text", text = codigo } } },
                            new { type = "button", sub_type = "url", index = "0", parameters = new object[] { new { type = "text", text = codigo } } }
                        }
                    }
                };

                var json = JsonConvert.SerializeObject(payload);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var req = new HttpRequestMessage(HttpMethod.Post, url);
                req.Headers.TryAddWithoutValidation("Authorization", "Bearer " + apiKey);
                req.Content = content;

                var resp = await _http.SendAsync(req);
                var body = await resp.Content.ReadAsStringAsync();
                if (!resp.IsSuccessStatusCode)
                {
                    Console.WriteLine("[WhatsApp] Error " + resp.StatusCode + ": " + body);
                    return false;
                }
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine("[WhatsApp] Excepcion: " + ex.Message);
                return false;
            }
        }

        /// <summary>Normaliza a formato internacional sin '+' (Mexico: 52 + 10 digitos).</summary>
        private string NormalizarTelefono(string telefono)
        {
            if (string.IsNullOrEmpty(telefono)) return null;
            var chars = telefono.ToCharArray();
            var digits = new string(Array.FindAll(chars, char.IsDigit));
            if (digits.Length == 10) return "52" + digits;
            return digits;
        }
    }
}
