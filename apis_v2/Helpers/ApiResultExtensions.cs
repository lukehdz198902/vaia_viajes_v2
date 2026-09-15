using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Microsoft.AspNetCore.Mvc;
using VaiaViajes.Api.Models;

namespace VaiaViajes.Api.Helpers
{
    public static class ApiResultExtensions
    {
        public static IActionResult VaiaOk(this object data, string message = null)
            => new OkObjectResult(ApiResponse.Ok(data, message));

        public static IActionResult VaiaCreated(this object data, string message = null)
            => new ObjectResult(ApiResponse.Ok(data, message)) { StatusCode = 201 };

        public static IActionResult VaiaBadRequest(this string message, string code = "BAD_REQUEST")
            => new BadRequestObjectResult(new ApiError
            {
                Success = false,
                Message = message,
                Code = code,
            });

        public static IActionResult VaiaNotFound(this string message)
            => new NotFoundObjectResult(new ApiError
            {
                Success = false,
                Message = message,
                Code = "NOT_FOUND",
            });

        public static IActionResult VaiaUnauthorized(this string message)
            => new UnauthorizedObjectResult(new ApiError
            {
                Success = false,
                Message = message,
                Code = "UNAUTHORIZED",
            });

        public static IActionResult VaiaServerError(this string message, string details = "")
            => new ObjectResult(new ApiError
            {
                Success = false,
                Message = message,
                Code = "INTERNAL_ERROR",
                Details = details,
            }) { StatusCode = 500 };

        public static IActionResult VaiaFromSp(this object spResult, string successMsg)
            => ProcessSpResult(spResult, successMsg, returnList: true);

        public static IActionResult VaiaFromSp(this object spResult)
            => ProcessSpResult(spResult, "Operacion exitosa", returnList: true);

        public static IActionResult VaiaSingleFromSp(this object spResult, string successMsg)
            => ProcessSpResult(spResult, successMsg, returnList: false);

        public static IActionResult VaiaSingleFromSp(this object spResult)
            => ProcessSpResult(spResult, "Operacion exitosa", returnList: false);

        private static IActionResult ProcessSpResult(object spResult, string successMsg, bool returnList)
        {
            if (spResult == null)
                return VaiaServerError("El procedimiento no devolvio resultado");

            var list = TryToList(spResult);
            if (list == null)
            {
                if (returnList)
                    return VaiaOk(new[] { spResult }, successMsg);
                return VaiaOk(spResult, successMsg);
            }

            if (list.Count == 0)
            {
                if (returnList)
                    return new OkObjectResult(new { success = true, message = "Sin resultados", data = new object[] { } });
                return VaiaOk(new { }, "Sin resultados");
            }

            var first = list[0];
            if (first is System.Collections.Generic.IDictionary<string, object> dict)
            {
                if (dict.TryGetValue("resultado", out var resObj) && resObj is int res && res < 0)
                {
                    var msg = GetMessage(dict) ?? "Operacion rechazada";
                    return VaiaBadRequest(msg, code: "SP_" + res);
                }
                if (dict.TryGetValue("id", out var idObj))
                {
                    if (idObj is int idInt && idInt < 0)
                        return VaiaBadRequest(GetMessage(dict) ?? "Operacion rechazada", code: "SP_" + idInt);
                    if (idObj is long idLong && idLong < 0)
                        return VaiaBadRequest(GetMessage(dict) ?? "Operacion rechazada", code: "SP_" + idLong);
                }
            }

            if (returnList)
                return VaiaOk(list, successMsg);
            return VaiaOk(first, successMsg);
        }

        private static List<object> TryToList(object spResult)
        {
            try
            {
                if (spResult is string) return null;
                if (spResult is IEnumerable enumerable)
                    return enumerable.Cast<object>().ToList();
                return null;
            }
            catch
            {
                return null;
            }
        }

        private static string GetMessage(System.Collections.Generic.IDictionary<string, object> dict)
        {
            if (dict.TryGetValue("mensaje", out var msgObj))
                return msgObj?.ToString();
            return null;
        }
    }
}