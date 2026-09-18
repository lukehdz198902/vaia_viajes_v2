using System;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;

namespace VaiaViajes.Api.Services
{
    /// <summary>
    /// Envio de correos por SMTP. La configuracion vive en appsettings.json
    /// (seccion "Smtp"). Si no esta configurado, no falla: simplemente no envia.
    /// </summary>
    public class EmailService
    {
        private readonly IConfiguration _config;

        public EmailService(IConfiguration config)
        {
            _config = config;
        }

        public bool Configurado
        {
            get { return !string.IsNullOrEmpty(_config["Smtp:Host"]); }
        }

        public async Task<bool> EnviarAsync(string para, string asunto, string html)
        {
            try
            {
                var host = _config["Smtp:Host"];
                if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(para)) return false;

                int puerto;
                if (!int.TryParse(_config["Smtp:Port"], out puerto) || puerto <= 0) puerto = 587;
                var usuario = _config["Smtp:User"];
                var pass = _config["Smtp:Password"];
                var desde = string.IsNullOrEmpty(_config["Smtp:From"]) ? usuario : _config["Smtp:From"];
                var nombreDesde = string.IsNullOrEmpty(_config["Smtp:FromName"]) ? "Vaia Viajes" : _config["Smtp:FromName"];
                var ssl = !string.Equals(_config["Smtp:Ssl"], "false", StringComparison.OrdinalIgnoreCase);

                if (string.IsNullOrEmpty(desde)) return false;

                using (var msg = new MailMessage())
                {
                    msg.From = new MailAddress(desde, nombreDesde);
                    msg.To.Add(para);
                    msg.Subject = asunto;
                    msg.Body = html;
                    msg.IsBodyHtml = true;

                    using (var client = new SmtpClient(host, puerto))
                    {
                        client.EnableSsl = ssl;
                        client.DeliveryMethod = SmtpDeliveryMethod.Network;
                        if (!string.IsNullOrEmpty(usuario))
                            client.Credentials = new NetworkCredential(usuario, pass);
                        await client.SendMailAsync(msg);
                    }
                }
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine("[EmailService] Error enviando a " + para + ": " + ex.Message);
                return false;
            }
        }
    }
}
