using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using VaiaViajes.Api.Helpers;

namespace VaiaViajes.Api.Helpers
{
    /// <summary>
    /// Ejecuta stored procedures y devuelve IActionResult con el formato estandar de la API.
    /// Encapsula el cast explicito a object para forzar binding estatico (evita RuntimeBinderException).
    /// </summary>
    public static class SpExecutor
    {
        public static async Task<IActionResult> SingleAsync(string spName, object parameters, string successMsg = "Operacion exitosa")
        {
            var result = await DatabaseHelper.QueryAsync<object>(spName, parameters);
            object boxed = result;
            return ApiResultExtensions.VaiaSingleFromSp(boxed, successMsg);
        }

        public static async Task<IActionResult> SingleAsync(string spName, string successMsg = "Operacion exitosa")
        {
            var result = await DatabaseHelper.QueryAsync<object>(spName);
            object boxed = result;
            return ApiResultExtensions.VaiaSingleFromSp(boxed, successMsg);
        }

        public static async Task<IActionResult> ListAsync(string spName, object parameters, string successMsg = "Operacion exitosa")
        {
            var result = await DatabaseHelper.QueryAsync<object>(spName, parameters);
            object boxed = result;
            return ApiResultExtensions.VaiaFromSp(boxed, successMsg);
        }

        public static async Task<IActionResult> ListAsync(string spName, string successMsg = "Operacion exitosa")
        {
            var result = await DatabaseHelper.QueryAsync<object>(spName);
            object boxed = result;
            return ApiResultExtensions.VaiaFromSp(boxed, successMsg);
        }

        public static async Task<IActionResult> SingleRequiredAsync(string spName, object parameters, string notFoundMsg, string successMsg = "Operacion exitosa")
        {
            var result = await DatabaseHelper.QueryAsync<object>(spName, parameters);
            object boxed = result;
            var list = boxed as System.Collections.IEnumerable;
            if (list != null)
            {
                bool any = false;
                foreach (var _ in list) { any = true; break; }
                if (!any) return notFoundMsg.VaiaNotFound();
            }
            return ApiResultExtensions.VaiaSingleFromSp(boxed, successMsg);
        }
    }
}