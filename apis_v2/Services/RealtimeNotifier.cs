using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;
using VaiaViajes.Api.Hubs;

namespace VaiaViajes.Api.Services
{
    /// <summary>
    /// Servicio central para emitir eventos en tiempo real desde los controllers.
    /// Se registra como singleton y se inyecta en los controllers.
    /// </summary>
    public class RealtimeNotifier
    {
        private readonly IHubContext<ServicioHub> _servicioHub;
        private readonly IHubContext<ChatHub> _chatHub;
        private readonly IHubContext<SoporteHub> _soporteHub;

        public RealtimeNotifier(
            IHubContext<ServicioHub> servicioHub,
            IHubContext<ChatHub> chatHub,
            IHubContext<SoporteHub> soporteHub)
        {
            _servicioHub = servicioHub;
            _chatHub = chatHub;
            _soporteHub = soporteHub;
        }

        // ─── SERVICIOS ───────────────────────────────────────────────

        /// <summary>Notifica a los conductores disponibles que hay un nuevo servicio.</summary>
        public Task NotificarNuevoServicio(object servicio)
            => _servicioHub.Clients.Group("conductores_disponibles").SendAsync("NuevoServicio", servicio);

        /// <summary>Notifica a los admins que hay un nuevo servicio.</summary>
        public Task NotificarNuevoServicioAdmin(object servicio)
            => _servicioHub.Clients.Group("admins").SendAsync("NuevoServicio", servicio);

        /// <summary>Notifica a un conductor especifico que se le asigno un servicio.</summary>
        public Task NotificarAsignacionConductor(int idConductor, object payload)
            => _servicioHub.Clients.Group($"conductor_{idConductor}").SendAsync("ServicioAsignado", payload);

        /// <summary>Notifica al pasajero que su servicio fue aceptado.</summary>
        public Task NotificarServicioAceptado(long idServicio, long idPasajero, object payload)
            => Task.WhenAll(
                _servicioHub.Clients.Group($"servicio_{idServicio}").SendAsync("ServicioAceptado", payload),
                _servicioHub.Clients.Group($"pasajero_{idPasajero}").SendAsync("ServicioAceptado", payload),
                _servicioHub.Clients.Group("admins").SendAsync("ServicioAceptado", payload)
            );

        /// <summary>Notifica cambio de estatus a todos los involucrados.</summary>
        public Task NotificarEstatusCambiado(long idServicio, string estatus, object payload = null)
        {
            var data = payload ?? new { idServicio, estatus, fecha = DateTime.UtcNow.ToString("o") };
            return _servicioHub.Clients.Group($"servicio_{idServicio}").SendAsync("EstatusCambiado", data);
        }

        /// <summary>Notifica cancelacion del servicio.</summary>
        public Task NotificarServicioCancelado(long idServicio, string motivo, string canceladoPor)
        {
            var data = new { idServicio, motivo, canceladoPor, fecha = DateTime.UtcNow.ToString("o") };
            return _servicioHub.Clients.Group($"servicio_{idServicio}").SendAsync("ServicioCancelado", data);
        }

        /// <summary>Notifica a los admins el cambio de estatus (para el tablero).</summary>
        public Task NotificarEstatusAdmin(long idServicio, string estatus)
            => _servicioHub.Clients.Group("admins").SendAsync("EstatusCambiado", new { idServicio, estatus });

        // ─── CHAT PASAJERO <-> CONDUCTOR ─────────────────────────────

        public Task NotificarMensajeChat(long idServicio, object payload)
            => _chatHub.Clients.Group($"chat_{idServicio}").SendAsync("NuevoMensaje", payload);

        // ─── SOPORTE ─────────────────────────────────────────────────

        public Task NotificarNuevaSolicitudSoporte(object solicitud)
            => _soporteHub.Clients.Group("soporte").SendAsync("NuevaSolicitud", solicitud);

        public Task NotificarMensajeSoporte(long idSolicitud, object payload)
            => Task.WhenAll(
                _soporteHub.Clients.Group($"soporte_{idSolicitud}").SendAsync("NuevoMensajeSoporte", payload),
                _soporteHub.Clients.Group("soporte").SendAsync("MensajeEnSolicitud", payload)
            );

        public Task NotificarSolicitudActualizada(long idSolicitud, string estatus, object payload = null)
        {
            var data = payload ?? new { idSolicitud, estatus };
            return _soporteHub.Clients.Group("soporte").SendAsync("SolicitudActualizada", data);
        }

        // ─── COBRO / TAXIMETRO ───────────────────────────────────────

        /// <summary>Notifica el costo en vivo (taximetro) a los involucrados en el servicio.</summary>
        public Task NotificarCostoActualizado(long idServicio, decimal costo, int distanciaMetros, int duracionSegundos)
            => _servicioHub.Clients.Group($"servicio_{idServicio}").SendAsync("CostoActualizado",
                new { idServicio, costo, distanciaMetros, duracionSegundos, fecha = DateTime.UtcNow.ToString("o") });

        // ─── NOTIFICACIONES GENERICAS ────────────────────────────────

        public Task NotificarPasajero(long idPasajero, string evento, object payload)
            => _servicioHub.Clients.Group($"pasajero_{idPasajero}").SendAsync(evento, payload);

        public Task NotificarConductor(int idConductor, string evento, object payload)
            => _servicioHub.Clients.Group($"conductor_{idConductor}").SendAsync(evento, payload);
    }
}