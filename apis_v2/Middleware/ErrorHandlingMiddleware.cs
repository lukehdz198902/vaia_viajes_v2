using System;
using System.Net;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using VaiaViajes.Api.Models;

namespace VaiaViajes.Api.Middleware
{
    public class ErrorHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ErrorHandlingMiddleware> _logger;

        public ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[Vaia] Excepcion no controlada en {Path}", context.Request.Path);
                await HandleExceptionAsync(context, ex);
            }
        }

        private static Task HandleExceptionAsync(HttpContext context, Exception ex)
        {
            int statusCode;
            string message;
            string code;

            if (ex is ArgumentException)
            {
                statusCode = (int)HttpStatusCode.BadRequest;
                message = "Datos invalidos: " + ex.Message;
                code = "ARGUMENT_ERROR";
            }
            else if (ex is UnauthorizedAccessException)
            {
                statusCode = (int)HttpStatusCode.Unauthorized;
                message = "No autorizado";
                code = "UNAUTHORIZED";
            }
            else if (ex is InvalidOperationException)
            {
                statusCode = (int)HttpStatusCode.BadRequest;
                message = "Operacion invalida: " + ex.Message;
                code = "INVALID_OPERATION";
            }
            else if (ex is TimeoutException)
            {
                statusCode = (int)HttpStatusCode.RequestTimeout;
                message = "La operacion tardo demasiado";
                code = "TIMEOUT";
            }
            else
            {
                statusCode = (int)HttpStatusCode.InternalServerError;
                message = "Error interno del servidor";
                code = "INTERNAL_ERROR";
            }

            var response = new ApiError
            {
                Success = false,
                Message = message,
                Code = code,
                Details = ex.GetType().Name + ": " + ex.Message,
                Path = context.Request.Path,
                Timestamp = DateTime.UtcNow.ToString("o"),
            };

            context.Response.ContentType = "application/json";
            context.Response.StatusCode = statusCode;
            return context.Response.WriteAsync(JsonConvert.SerializeObject(response));
        }
    }

    public static class ErrorHandlingMiddlewareExtensions
    {
        public static IApplicationBuilder UseVaiaErrorHandling(this IApplicationBuilder app)
            => app.UseMiddleware<ErrorHandlingMiddleware>();
    }
}