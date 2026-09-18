using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using VaiaViajes.Api.BackgroundServices;
using VaiaViajes.Api.Hubs;
using VaiaViajes.Api.Middleware;
using VaiaViajes.Api.Services;

namespace VaiaViajes.Api
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddCors(opts => opts.AddPolicy("AllowAll", p =>
                p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

            services.AddSingleton<FcmService>();
            services.AddSingleton<RealtimeNotifier>();
            services.AddSingleton<EmailService>();
            services.AddSingleton<WhatsAppService>();
            services.AddSingleton<MercadoPagoService>();
            services.AddSingleton<PayPalService>();

            // SignalR (WebSocket) para tiempo real
            services.AddSignalR(opts =>
            {
                opts.EnableDetailedErrors = true;
            });

            // Servicios en background
            services.AddSingleton<IHostedService, AssignmentService>();
            services.AddSingleton<IHostedService, SchedulerService>();
            services.AddSingleton<IHostedService, PresenceService>();

            services.AddMvc()
                .AddJsonOptions(opts =>
                {
                    opts.SerializerSettings.ReferenceLoopHandling = Newtonsoft.Json.ReferenceLoopHandling.Ignore;
                    opts.SerializerSettings.NullValueHandling = Newtonsoft.Json.NullValueHandling.Ignore;
                });
        }

        public void Configure(IApplicationBuilder app, Microsoft.AspNetCore.Hosting.IHostingEnvironment env)
        {
            DatabaseHelper.Configure(Configuration);

            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseVaiaErrorHandling();
            app.UseCors("AllowAll");

            // Hubs de SignalR
            app.UseSignalR(routes =>
            {
                routes.MapHub<ServicioHub>("/hubs/servicio");
                routes.MapHub<ChatHub>("/hubs/chat");
                routes.MapHub<SoporteHub>("/hubs/soporte");
            });

            app.UseMvc(routes =>
            {
                routes.MapRoute(
                    name: "DefaultApi",
                    template: "api/{controller}/{action}/{id?}");
            });
        }
    }
}