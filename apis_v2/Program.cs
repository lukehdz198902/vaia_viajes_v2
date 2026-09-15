using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Hosting;
using System;
using System.Linq;
using System.Net;
using System.Net.NetworkInformation;

namespace VaiaViajes.Api
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var port = GetAvailablePort(5000);
            BuildWebHost(args, port).Run();
        }

        public static IWebHost BuildWebHost(string[] args, int port) =>
            WebHost.CreateDefaultBuilder(args)
                .UseStartup<Startup>()
                .UseUrls($"http://localhost:{port}")
                .Build();

        private static int GetAvailablePort(int preferred)
        {
            var used = IPGlobalProperties.GetIPGlobalProperties()
                .GetActiveTcpListeners()
                .Select(x => x.Port)
                .ToHashSet();
            if (!used.Contains(preferred)) return preferred;
            for (int p = 5001; p <= 5100; p++)
                if (!used.Contains(p)) return p;
            return preferred;
        }
    }
}
