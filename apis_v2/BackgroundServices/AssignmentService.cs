using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using VaiaViajes.Api.Services;

namespace VaiaViajes.Api.BackgroundServices
{
    /// <summary>
    /// Servicio en background que asigna y reasigna conductores automaticamente
    /// a los servicios que estan en estatus 'Solicitado' sin conductor.
    ///
    /// Ciclo:
    ///   1. Cada N segundos busca servicios sin asignar.
    ///   2. Para cada uno, busca conductores disponibles cercanos.
    ///   3. Notifica al conductor mas cercano (que no haya sido notificado antes).
    ///   4. Registra el intento en tbservicioasignacionlog.
    ///   5. Si se agotan los intentos o expira el tiempo, cancela la solicitud.
    /// </summary>
    public class AssignmentService : IHostedService, IDisposable
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<AssignmentService> _logger;
        private Timer _timer;
        private readonly TimeSpan _intervalo = TimeSpan.FromSeconds(10);
        private const int MAX_INTENTOS = 30;
        private const int MINUTOS_EXPIRACION = 5;

        public AssignmentService(IServiceScopeFactory scopeFactory, ILogger<AssignmentService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("[Vaia] AssignmentService iniciado (intervalo {Seg}s)", _intervalo.TotalSeconds);
            _timer = new Timer(Procesar, null, TimeSpan.FromSeconds(15), _intervalo);
            return Task.CompletedTask;
        }

        private async void Procesar(object state)
        {
            try
            {
                using (var scope = _scopeFactory.CreateScope())
                {
                    var notifier = scope.ServiceProvider.GetRequiredService<RealtimeNotifier>();
                    var fcm = scope.ServiceProvider.GetRequiredService<FcmService>();

                    var pendientes = await DatabaseHelper.QueryAsync<object>("sp_sistema_ObtenerServiciosSinAsignar", new { limite = 20 });
                    foreach (var item in pendientes)
                    {
                        var s = item as IDictionary<string, object>;
                        if (s == null) continue;

                        long idServicio = Convert.ToInt64(s["id"]);
                        long idPasajero = Convert.ToInt64(s["idpasajero"]);
                        short idCompania = s.ContainsKey("idcompania") && s["idcompania"] != null ? Convert.ToInt16(s["idcompania"]) : (short)1;
                        int intentos = s.ContainsKey("intentosasignacion") && s["intentosasignacion"] != null ? Convert.ToInt32(s["intentosasignacion"]) : 0;
                        DateTime fecha = s.ContainsKey("fechacreacion") && s["fechacreacion"] != null
                            ? Convert.ToDateTime(s["fechacreacion"]) : DateTime.Now;

                        // Expirar si ya paso el tiempo maximo
                        if ((DateTime.Now - fecha).TotalMinutes >= MINUTOS_EXPIRACION)
                        {
                            await DatabaseHelper.QueryAsync<object>("sp_sistema_ExpirarSolicitud", new { idservicio = idServicio });
                            await notifier.NotificarServicioCancelado(idServicio, "Sin conductor disponible", "sistema");
                            await fcm.EnviarNotificacionPasajero(idPasajero, "Sin conductor disponible",
                                "No encontramos conductor para tu servicio. Intenta de nuevo.");
                            _logger.LogWarning("[Vaia] Servicio {Id} expirado sin conductor", idServicio);
                            continue;
                        }

                        // Si ya se intento demasiadas veces, expirar
                        if (intentos >= MAX_INTENTOS)
                        {
                            await DatabaseHelper.QueryAsync<object>("sp_sistema_ExpirarSolicitud", new { idservicio = idServicio });
                            await notifier.NotificarServicioCancelado(idServicio, "Sin conductor disponible", "sistema");
                            continue;
                        }

                        // Buscar conductores cercanos
                        string lat = s.ContainsKey("latorigen") ? s["latorigen"]?.ToString() : "0";
                        string lng = s.ContainsKey("lngorigen") ? s["lngorigen"]?.ToString() : "0";
                        var conductores = await DatabaseHelper.QueryAsync<object>("sp_pasajero_ConductoresDisponibles", new { lat, lng, idZona = (int?)null });

                        // Conductores ya notificados de este servicio (no repetir)
                        var notificados = new HashSet<int>();
                        var listaNotif = await DatabaseHelper.QueryAsync<object>("sp_sistema_ObtenerNotificados", new { idservicio = idServicio });
                        foreach (var n in listaNotif)
                        {
                            var dn = n as IDictionary<string, object>;
                            if (dn != null && dn.ContainsKey("idconductor") && dn["idconductor"] != null)
                                notificados.Add(Convert.ToInt32(dn["idconductor"]));
                        }

                        // Elegir el mas cercano que aun no haya sido notificado
                        IDictionary<string, object> elegido = null;
                        foreach (var c in conductores)
                        {
                            var dict = c as IDictionary<string, object>;
                            if (dict == null) continue;
                            int idC = Convert.ToInt32(dict["id"]);
                            if (notificados.Contains(idC)) continue;
                            elegido = dict;
                            break;
                        }

                        if (elegido == null)
                        {
                            // Todos los conductores cercanos ya fueron notificados
                            if (notificados.Count > 0)
                            {
                                await DatabaseHelper.QueryAsync<object>("sp_sistema_ExpirarSolicitud", new { idservicio = idServicio });
                                await notifier.NotificarServicioCancelado(idServicio, "Sin conductor disponible", "sistema");
                                await fcm.EnviarNotificacionPasajero(idPasajero, "Sin conductor disponible",
                                    "No encontramos conductor para tu servicio. Intenta de nuevo.");
                                _logger.LogWarning("[Vaia] Servicio {Id} expirado: se notificaron {N} conductores sin respuesta", idServicio, notificados.Count);
                            }
                            continue;
                        }

                        int idConductor = Convert.ToInt32(elegido["id"]);

                        // Tiempo de respuesta configurado por el administrador (tbcompania.segesperatomaservicio)
                        int segundosParaTomar = s.ContainsKey("segundosparatomar") && s["segundosparatomar"] != null
                            ? Convert.ToInt32(s["segundosparatomar"]) : 30;
                        if (segundosParaTomar <= 0) segundosParaTomar = 30;

                        var payload = new
                        {
                            idServicio,
                            idPasajero,
                            direccionOrigen = s.ContainsKey("direccionorigen") ? s["direccionorigen"]?.ToString() : "",
                            direccionDestino = s.ContainsKey("direcciondestination") ? s["direcciondestination"]?.ToString() : "",
                            latOrigen = lat,
                            lngOrigen = lng,
                            costoEstimado = s.ContainsKey("costoestimado") ? s["costoestimado"] : null,
                            distanciaMetros = s.ContainsKey("distanciametros") ? s["distanciametros"] : null,
                            intento = intentos + 1,
                            segundosParaTomar,
                            fecha = DateTime.UtcNow.ToString("o")
                        };

                        // Notificar por SignalR
                        await notifier.NotificarAsignacionConductor(idConductor, payload);
                        await notifier.NotificarNuevoServicioAdmin(payload);

                        // Notificar por FCM
                        try
                        {
                            var token = await fcm.GetConductorTokenAsync(idConductor);
                            if (!string.IsNullOrEmpty(token))
                                await fcm.SendToTokenAsync(token, "Nuevo servicio disponible",
                                    "Tienes una solicitud de viaje cerca", new Dictionary<string, string>
                                    {
                                        ["type"] = "new_ride",
                                        ["idservicio"] = idServicio.ToString()
                                    });
                        }
                        catch { }

                        // Registrar notificacion (inicia la ventana de respuesta) + log
                        await DatabaseHelper.QueryAsync<object>("sp_sistema_RegistrarNotificado",
                            new { idservicio = idServicio, idconductor = idConductor, segundos = segundosParaTomar });
                        await DatabaseHelper.QueryAsync<object>("sp_sistema_RegistrarAsignacionLog",
                            new { idservicio = idServicio, idconductor = idConductor, evento = "NOTIFICADO", detalle = $"Intento {intentos + 1}" });

                        _logger.LogInformation("[Vaia] Servicio {Id} ofrecido a conductor {C} ({S}s para responder)", idServicio, idConductor, segundosParaTomar);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[Vaia] AssignmentService error");
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