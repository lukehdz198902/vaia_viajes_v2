using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Dapper;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json.Linq;

public static class DatabaseHelper
{
    private static string ConnString;

    public static void Configure(IConfiguration config)
    {
        ConnString = config.GetConnectionString("VaiaViajes");
    }

    private static object NormalizeParams(object parameters)
    {
        if (parameters is JObject jobj)
        {
            var dict = new Dictionary<string, object>();
            foreach (var prop in jobj.Properties())
                dict[prop.Name] = prop.Value?.Type == JTokenType.Null ? null : ((JValue)prop.Value)?.Value ?? prop.Value;
            return dict;
        }
        return parameters;
    }

    public static async Task<IEnumerable<T>> QueryAsync<T>(string spName, object parameters = null)
    {
        using (var conn = new SqlConnection(ConnString))
        {
            return await conn.QueryAsync<T>(spName, NormalizeParams(parameters), commandType: CommandType.StoredProcedure);
        }
    }

    public static async Task<T> QuerySingleAsync<T>(string spName, object parameters = null)
    {
        using (var conn = new SqlConnection(ConnString))
        {
            return await conn.QuerySingleOrDefaultAsync<T>(spName, NormalizeParams(parameters), commandType: CommandType.StoredProcedure);
        }
    }

    public static async Task<int> ExecuteAsync(string spName, object parameters = null)
    {
        using (var conn = new SqlConnection(ConnString))
        {
            return await conn.ExecuteAsync(spName, NormalizeParams(parameters), commandType: CommandType.StoredProcedure);
        }
    }
}
