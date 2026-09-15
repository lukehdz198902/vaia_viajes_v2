using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;

namespace VaiaViajes.Api.Hubs
{
    /// <summary>
    /// Hub para el chat de soporte entre el portal web (admins) y los usuarios
    /// (pasajeros/conductores) que solicitan ayuda referenciando un servicio.
    ///
    /// Grupos:
    ///   soporte            -> todos los admins de soporte conectados
    ///   soporte_{id}       -> una solicitud especifica
    ///   usuario_{tipo}_{id}-> el usuario solicitante
    /// </summary>
    public class SoporteHub : Hub
    {
        public async Task UnirseComoSoporte(int idUsuarioSoporte, string nombre)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, "soporte");
            await Clients.Caller.SendAsync("SoporteConectado", new { idUsuarioSoporte, nombre });
        }

        public async Task UnirseASolicitud(long idSolicitud)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"soporte_{idSolicitud}");
            await Clients.Caller.SendAsync("UnidoASolicitud", idSolicitud);
        }

        public async Task SalirDeSolicitud(long idSolicitud)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"soporte_{idSolicitud}");
        }

        /// <summary>
        /// Retransmite un mensaje dentro de una solicitud de soporte.
        /// El emisor puede ser 'pasajero', 'conductor' o 'soporte'.
        /// </summary>
        public async Task EnviarMensajeSoporte(long idSolicitud, string emisor, long idEmisor, string nombreEmisor, string mensaje)
        {
            var payload = new
            {
                idSolicitud,
                emisor,
                idEmisor,
                nombreEmisor,
                mensaje,
                fecha = DateTime.UtcNow.ToString("o")
            };
            await Clients.Group($"soporte_{idSolicitud}").SendAsync("NuevoMensajeSoporte", payload);
            // Tambien notificar a la bandeja general de soporte
            await Clients.Group("soporte").SendAsync("MensajeEnSolicitud", payload);
        }

        public async Task EscribiendoSoporte(long idSolicitud, string emisor)
        {
            await Clients.OthersInGroup($"soporte_{idSolicitud}").SendAsync("EscribiendoSoporte", new { idSolicitud, emisor });
        }
    }
}