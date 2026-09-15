using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;

namespace VaiaViajes.Api.Hubs
{
    /// <summary>
    /// Hub para el chat pasajero &lt;-&gt; conductor durante un servicio.
    /// Los mensajes tambien se persisten en tbserviciosmensaje desde el controller.
    /// </summary>
    public class ChatHub : Hub
    {
        public async Task UnirseAlChat(long idServicio)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"chat_{idServicio}");
            await Clients.Caller.SendAsync("UnidoAlChat", idServicio);
        }

        public async Task SalirDelChat(long idServicio)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"chat_{idServicio}");
        }

        public async Task EnviarMensaje(long idServicio, string emisor, string mensaje, string nombreEmisor)
        {
            var payload = new
            {
                idServicio,
                emisor,
                mensaje,
                nombreEmisor,
                fecha = DateTime.UtcNow.ToString("o")
            };
            await Clients.Group($"chat_{idServicio}").SendAsync("NuevoMensaje", payload);
        }

        public async Task Escribiendo(long idServicio, string emisor)
        {
            await Clients.OthersInGroup($"chat_{idServicio}").SendAsync("Escribiendo", new { idServicio, emisor });
        }
    }
}