using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Dapper;
using Microsoft.Extensions.Configuration;

public static class DatabaseHelper
{
    private static string ConnString;

    public static void Configure(IConfiguration config)
    {
        ConnString = config.GetConnectionString("VaiaViajes");
    }

    public static async Task<IEnumerable<T>> QueryAsync<T>(string spName, object parameters = null)
    {
        using (var conn = new SqlConnection(ConnString))
        {
            return await conn.QueryAsync<T>(spName, parameters, commandType: CommandType.StoredProcedure);
        }
    }

    public static async Task<T> QuerySingleAsync<T>(string spName, object parameters = null)
    {
        using (var conn = new SqlConnection(ConnString))
        {
            return await conn.QuerySingleOrDefaultAsync<T>(spName, parameters, commandType: CommandType.StoredProcedure);
        }
    }

    public static async Task<int> ExecuteAsync(string spName, object parameters = null)
    {
        using (var conn = new SqlConnection(ConnString))
        {
            return await conn.ExecuteAsync(spName, parameters, commandType: CommandType.StoredProcedure);
        }
    }
}
