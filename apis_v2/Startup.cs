using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
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

            services.AddMvc()
                .AddJsonOptions(opts =>
                {
                    opts.SerializerSettings.ReferenceLoopHandling = Newtonsoft.Json.ReferenceLoopHandling.Ignore;
                    opts.SerializerSettings.NullValueHandling = Newtonsoft.Json.NullValueHandling.Ignore;
                });
        }

        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            DatabaseHelper.Configure(Configuration);

            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseVaiaErrorHandling();
            app.UseCors("AllowAll");
            app.UseMvc(routes =>
            {
                routes.MapRoute(
                    name: "DefaultApi",
                    template: "api/{controller}/{action}/{id?}");
            });
        }
    }
}
