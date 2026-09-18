using System;
using System.Collections.Concurrent;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;

namespace VaiaViajes.Api.Hubs
{
    /// <summary>
    /// Hub principal para servicios: asignacion, reasignacion, cambios de estatus,
    /// ubicacion de conductores en tiempo real.
    ///
    /// Grupos:
    ///   servicio_{idServicio}   -> pasajero + conductor del servicio
    ///   conductor_{idConductor} -> app del conductor
    ///   pasajero_{idPasajero}   -> app del pasajero
    ///   conductores_disponibles -> todos los conductores conectados
    ///   admins                  -> portal web
    /// </summary>
    public class ServicioHub : Hub
    {
        // Mapa conexion -> { tipo, id } para poder limpiar al desconectar
        private static readonly ConcurrentDictionary<string, (string Tipo, long Id)> _conexiones
            = new ConcurrentDictionary<string, (string, long)>();

        public override async Task OnConnectedAsync()
        {
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception exception)
        {
            if (_conexiones.TryRemove(Context.ConnectionId, out var info))
            {
                if (info.Tipo == "conductor")
                    await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"conductor_{info.Id}");
                else if (info.Tipo == "pasajero")
                    await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"pasajero_{info.Id}");
            }
            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// El cliente se registra indicando su tipo (pasajero/conductor/admin) e id.
        /// </summary>
        public async Task RegistrarConexion(string tipo, long id)
        {
            _conexiones[Context.ConnectionId] = (tipo, id);
            if (tipo == "conductor")
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, $"conductor_{id}");
                await Groups.AddToGroupAsync(Context.ConnectionId, "conductores_disponibles");
                // Marcar como conectado (heartbeat inicial)
                try { await DatabaseHelper.ExecuteAsync("sp_conductor_Latido", new { idConductor = (int)id }); } catch { }
            }
            else if (tipo == "pasajero")
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, $"pasajero_{id}");
                try { await DatabaseHelper.ExecuteAsync("sp_pasajero_Latido", new { idPasajero = id }); } catch { }
            }
            else if (tipo == "admin")
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, "admins");
            }
            await Clients.Caller.SendAsync("RegistroConfirmado", new { tipo, id, connectionId = Context.ConnectionId });
        }

        /// <summary>
        /// Une la conexion al grupo de un servicio especifico.
        /// </summary>
        public async Task UnirseAServicio(long idServicio)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"servicio_{idServicio}");
            await Clients.Caller.SendAsync("UnidoAServicio", idServicio);
        }

        public async Task SalirDeServicio(long idServicio)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"servicio_{idServicio}");
        }

        /// <summary>
        /// El conductor reporta su ubicacion. Se persiste en BD (fuente canonica)
        /// y se retransmite al conductor, al servicio activo y a los admins.
        /// </summary>
        public async Task ActualizarUbicacion(int idConductor, string lat, string lng, long? idServicio)
        {
            try
            {
                await DatabaseHelper.ExecuteAsync("sp_conductor_ActualizarUbicacionGPS",
                    new { idConductor, lat, lng });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ServicioHub] Error persistiendo ubicacion conductor {idConductor}: {ex.Message}");
            }

            // Nota de escala: NO se difunde a los admins por cada reporte.
            // El portal consulta las posiciones por polling. Solo se envia al
            // conductor y al servicio activo (para el mapa del pasajero).
            var payload = new { idConductor, lat, lng, fecha = DateTime.UtcNow.ToString("o") };
            await Clients.Group($"conductor_{idConductor}").SendAsync("UbicacionActualizada", payload);
            if (idServicio.HasValue && idServicio.Value > 0)
                await Clients.Group($"servicio_{idServicio.Value}").SendAsync("UbicacionConductor", payload);
        }

        /// <summary>
        /// El conductor envia un latido para indicar que sigue conectado.
        /// Se persiste (heartbeat) y se avisa a los admins.
        /// </summary>
        public async Task LatidoConductor(int idConductor)
        {
            try
            {
                await DatabaseHelper.ExecuteAsync("sp_conductor_Latido", new { idConductor });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ServicioHub] Error registrando latido conductor {idConductor}: {ex.Message}");
            }
            await Clients.Group("admins").SendAsync("ConductorLatido", new { idConductor, fecha = DateTime.UtcNow.ToString("o") });
        }

        /// <summary>
        /// El pasajero envia un latido para indicar que sigue conectado.
        /// </summary>
        public async Task LatidoPasajero(long idPasajero)
        {
            try
            {
                await DatabaseHelper.ExecuteAsync("sp_pasajero_Latido", new { idPasajero });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ServicioHub] Error registrando latido pasajero {idPasajero}: {ex.Message}");
            }
            await Clients.Group("admins").SendAsync("PasajeroLatido", new { idPasajero, fecha = DateTime.UtcNow.ToString("o") });
        }
    }
}