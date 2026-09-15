using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using VaiaViajes.Api.Services;

namespace VaiaViajes.Api.BackgroundServices
{
    /// <summary>
    /// Servicio en background que materializa los servicios programados:
    ///   - Cada minuto busca programados cuya hora este dentro de su ventana de anticipacion.
    ///   - Crea el servicio real en tbservicios (estatus 'Solicitado').
    ///   - Inserta las paradas intermedias definidas en paradas_json.
    ///   - Marca el programado como 'EnCola' para que AssignmentService lo tome.
    /// </summary>
    public class SchedulerService : IHostedService, IDisposable
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<SchedulerService> _logger;
        private Timer _timer;
        private readonly TimeSpan _intervalo = TimeSpan.FromSeconds(60);

        public SchedulerService(IServiceScopeFactory scopeFactory, ILogger<SchedulerService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("[Vaia] SchedulerService iniciado (intervalo {Seg}s)", _intervalo.TotalSeconds);
            _timer = new Timer(Procesar, null, TimeSpan.FromSeconds(30), _intervalo);
            return Task.CompletedTask;
        }

        private async void Procesar(object state)
        {
            try
            {
                using (var scope = _scopeFactory.CreateScope())
                {
                    var notifier = scope.ServiceProvider.GetRequiredService<RealtimeNotifier>();

                    var pendientes = await DatabaseHelper.QueryAsync<object>("sp_sistema_ObtenerProgramadosPendientes");
                    foreach (var item in pendientes)
                    {
                        var p = item as IDictionary<string, object>;
                        if (p == null) continue;

                        long idProgramado = Convert.ToInt64(p["id"]);
                        long idPasajero = Convert.ToInt64(p["idpasajero"]);
                        short idCompania = p.ContainsKey("idcompania") && p["idcompania"] != null ? Convert.ToInt16(p["idcompania"]) : (short)1;

                        try
                        {
                            // 1. Crear el servicio real
                            var parametros = new
                            {
                                idPasajero,
                                idCompania,
                                dirOrigen = p["direccionorigen"]?.ToString(),
                                latOrigen = p["latorigen"]?.ToString(),
                                lngOrigen = p["lngorigen"]?.ToString(),
                                dirDestino = p["direcciondestination"]?.ToString(),
                                latDestino = p["latdestination"]?.ToString(),
                                lngDestino = p["lngdestination"]?.ToString(),
                                distanciaMetros = 1000, // se recalculara por el SP si aplica
                                idTipoPago = p.ContainsKey("idtipopago") && p["idtipopago"] != null ? Convert.ToInt16(p["idtipopago"]) : (short)1,
                                codigoPromocional = p.ContainsKey("codigo_promocional") ? p["codigo_promocional"]?.ToString() : null,
                                so = "scheduler",
                                tipoviaje = "PROGRAMADO"
                            };

                            var resultado = await DatabaseHelper.QueryAsync<object>("sp_pasajero_SolicitarServicio", parametros);
                            long idServicio = 0;
                            foreach (var r in resultado)
                            {
                                var dict = r as IDictionary<string, object>;
                                if (dict != null && dict.ContainsKey("idservicio") && dict["idservicio"] != null)
                                    idServicio = Convert.ToInt64(dict["idservicio"]);
                                break;
                            }

                            if (idServicio <= 0) continue;

                            // 2. Marcar como programado y asociar
                            await DatabaseHelper.QueryAsync<object>("sp_servicio_MarcarComoProgramado",
                                new { idservicio = idServicio, idprogramado = idProgramado, fechaprogramada = p["fechaprogramada"] });

                            // 3. Insertar paradas del JSON
                            var paradasJson = p.ContainsKey("paradas_json") ? p["paradas_json"]?.ToString() : null;
                            if (!string.IsNullOrEmpty(paradasJson))
                            {
                                try
                                {
                                    var arr = JArray.Parse(paradasJson);
                                    foreach (var parada in arr)
                                    {
                                        await DatabaseHelper.QueryAsync<object>("sp_servicio_AgregarParada", new
                                        {
                                            idservicio = idServicio,
                                            orden = parada.Value<int?>("orden") ?? 1,
                                            direccion = parada.Value<string>("dir") ?? parada.Value<string>("direccion") ?? "",
                                            lat = parada.Value<string>("lat") ?? "0",
                                            lng = parada.Value<string>("lng") ?? "0",
                                            referencia = parada.Value<string>("ref") ?? parada.Value<string>("referencia"),
                                            notas = parada.Value<string>("notas")
                                        });
                                    }
                                }
                                catch (Exception exJson)
                                {
                                    _logger.LogWarning(exJson, "[Vaia] Error parseando paradas del programado {Id}", idProgramado);
                                }
                            }

                            // 4. Marcar programado como materializado
                            await DatabaseHelper.QueryAsync<object>("sp_sistema_MaterializarProgramado",
                                new { id = idProgramado, idServicioGenerado = idServicio });

                            // 5. Notificar al pasajero
                            await notifier.NotificarPasajero(idPasajero, "ServicioProgramadoActivado", new
                            {
                                idProgramado,
                                idServicio,
                                mensaje = "Tu servicio programado esta en proceso de asignacion"
                            });

                            _logger.LogInformation("[Vaia] Programado {P} materializado como servicio {S}", idProgramado, idServicio);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "[Vaia] Error materializando programado {Id}", idProgramado);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[Vaia] SchedulerService error");
            }
        }

        public Task StopAsync(CancellationToken cancellationToken)
        {
            _timer?.Change(Timeout.Infinite, 0);
            return Task.CompletedTask;
        }

        public void Dispose() => _timer?.Dispose();
    }
}