using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace VaiaViajes.Api.BackgroundServices
{
    /// <summary>
    /// Marca como desconectados a los conductores cuyo latido (heartbeat) expiro.
    /// Se ejecuta cada 60 s. Un conductor que no reporta ubicacion ni latido durante
    /// SEGUNDOS_INACTIVO se considera caido (app cerrada, sin red, etc.).
    /// </summary>
    public class PresenceService : IHostedService, IDisposable
    {
        private readonly ILogger<PresenceService> _logger;
        private Timer _timer;
        private readonly TimeSpan _intervalo = TimeSpan.FromSeconds(60);
        private const int SEGUNDOS_INACTIVO = 120;

        public PresenceService(ILogger<PresenceService> logger)
        {
            _logger = logger;
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("[Vaia] PresenceService iniciado (intervalo {Seg}s, timeout {Timeout}s)",
                _intervalo.TotalSeconds, SEGUNDOS_INACTIVO);
            _timer = new Timer(Procesar, null, TimeSpan.FromSeconds(30), _intervalo);
            return Task.CompletedTask;
        }

        private async void Procesar(object state)
        {
            try
            {
                var result = await DatabaseHelper.QueryAsync<object>(
                    "sp_sistema_MarcarConductoresInactivos", new { segundos = SEGUNDOS_INACTIVO });

                var first = Enumerable.FirstOrDefault(result);
                var dict = first as IDictionary<string, object>;
                if (dict != null && dict.ContainsKey("afectados"))
                {
                    var afectados = Convert.ToInt32(dict["afectados"] ?? 0);
                    if (afectados > 0)
                        _logger.LogInformation("[Vaia] PresenceService: {N} conductores marcados como desconectados", afectados);
                }

                // Pasajeros: heartbeat cada 60 s -> timeout 180 s
                var resP = await DatabaseHelper.QueryAsync<object>(
                    "sp_sistema_MarcarPasajerosInactivos", new { segundos = 180 });
                var firstP = Enumerable.FirstOrDefault(resP);
                var dictP = firstP as IDictionary<string, object>;
                if (dictP != null && dictP.ContainsKey("afectados"))
                {
                    var afp = Convert.ToInt32(dictP["afectados"] ?? 0);
                    if (afp > 0)
                        _logger.LogInformation("[Vaia] PresenceService: {N} pasajeros marcados como desconectados", afp);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[Vaia] PresenceService error");
            }
        }

        public Task StopAsync(CancellationToken cancellationToken)
        {
            _timer?.Change(Timeout.Infinite, 0);
            return Task.CompletedTask;
        }

        public void Dispose()
        {
            _timer?.Dispose();
        }
    }
}
