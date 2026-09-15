using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
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

    private static readonly object _cacheLock = new object();
    private static readonly Dictionary<string, HashSet<string>> _spParamsCache =
        new Dictionary<string, HashSet<string>>(StringComparer.OrdinalIgnoreCase);

    private static readonly HashSet<string> SmallIntKeys = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
    {
        "idCompania", "idcompania", "idRol", "idrol", "idTipoPago", "idtipopago",
        "idTipoPromo", "idtipopromo", "idEst", "idest", "idEstatus", "idestatus",
        "idEstatusViaje", "idestatusviaje", "idEstatusIncidente", "idestatusincidente",
        "idTipoIncidente", "idtipoincidente", "idTipoComision", "idtipocomision",
        "idConductorEstatus", "idconductorestatus", "idZonaCobertura", "idzonacobertura",
        "idGenero", "idgenero", "idIdioma", "ididioma", "idMetodoPago", "idmetodopago",
        "idZona", "idzona", "idUnidad", "idunidad", "estatus", "Estatus",
        "idioma", "Idioma", "idiomapreferido", "Idiomapreferido", "idTipo", "idtipo",
    };

    private static HashSet<string> GetSpParameters(SqlConnection conn, string spName)
    {
        lock (_cacheLock)
        {
            if (_spParamsCache.TryGetValue(spName, out var cached)) return cached;
        }

        var simpleName = spName.Contains(".") ? spName.Substring(spName.LastIndexOf('.') + 1) : spName;
        HashSet<string> names;
        try
        {
            var query = "SELECT p.name FROM sys.parameters p INNER JOIN sys.objects o ON o.object_id = p.object_id WHERE o.name = @spName";
            var list = conn.Query<string>(query, new { spName = simpleName });
            names = new HashSet<string>(
                System.Linq.Enumerable.Select(list, n => n != null && n.StartsWith("@") ? n.Substring(1) : n),
                StringComparer.OrdinalIgnoreCase);
        }
        catch
        {
            names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        }

        lock (_cacheLock)
        {
            _spParamsCache[spName] = names;
        }
        return names;
    }

    private static object NormalizeParams(string spName, object parameters)
    {
        if (parameters == null) return null;

        Dictionary<string, object> dict;
        if (parameters is Dictionary<string, object> d)
        {
            dict = d;
        }
        else if (parameters is JObject jobj)
        {
            dict = new Dictionary<string, object>();
            foreach (var prop in jobj.Properties())
            {
                var value = prop.Value?.Type == JTokenType.Null
                    ? null
                    : ((JValue)prop.Value)?.Value ?? prop.Value;
                dict[prop.Name] = value;
            }
        }
        else
        {
            return parameters;
        }

        var result = new Dictionary<string, object>(dict.Count);
        foreach (var kvp in dict)
        {
            result[kvp.Key] = NormalizeValue(kvp.Key, kvp.Value);
        }

        return result;
    }

    private static object FilterParamsForSp(SqlConnection conn, string spName, object parameters)
    {
        if (parameters is Dictionary<string, object> dict)
        {
            var allowed = GetSpParameters(conn, spName);
            if (allowed.Count == 0) return dict;
            var filtered = new Dictionary<string, object>();
            foreach (var kvp in dict)
            {
                if (allowed.Contains(kvp.Key))
                    filtered[kvp.Key] = kvp.Value;
            }
            return filtered;
        }
        return parameters;
    }

    private static object NormalizeValue(string key, object value)
    {
        if (value == null) return null;

        if (SmallIntKeys.Contains(key))
        {
            if (value is string s && !string.IsNullOrEmpty(s))
            {
                if (short.TryParse(s, out var sv)) return sv;
                if (int.TryParse(s, out var iv)) return (short)iv;
                if (long.TryParse(s, out var lv)) return (short)lv;
            }
            if (value is long l) return (short)l;
            if (value is int i) return (short)i;
        }

        if (value is string str)
        {
            if (str.Length == 0) return str;
            if (long.TryParse(str, out var lv2)) return lv2;
            if (double.TryParse(str, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out var dv)) return dv;
            if (bool.TryParse(str, out var bv)) return bv;
        }

        return value;
    }

    public static async Task<IEnumerable<T>> QueryAsync<T>(string spName, object parameters = null)
    {
        using (var conn = new SqlConnection(ConnString))
        {
            conn.Open();
            var normalized = NormalizeParams(spName, parameters);
            var filtered = FilterParamsForSp(conn, spName, normalized);
            return await conn.QueryAsync<T>(spName, filtered, commandType: CommandType.StoredProcedure);
        }
    }

    public static async Task<T> QuerySingleAsync<T>(string spName, object parameters = null)
    {
        using (var conn = new SqlConnection(ConnString))
        {
            conn.Open();
            var normalized = NormalizeParams(spName, parameters);
            var filtered = FilterParamsForSp(conn, spName, normalized);
            return await conn.QuerySingleOrDefaultAsync<T>(spName, filtered, commandType: CommandType.StoredProcedure);
        }
    }

    public static async Task<int> ExecuteAsync(string spName, object parameters = null)
    {
        using (var conn = new SqlConnection(ConnString))
        {
            conn.Open();
            var normalized = NormalizeParams(spName, parameters);
            var filtered = FilterParamsForSp(conn, spName, normalized);
            return await conn.ExecuteAsync(spName, filtered, commandType: CommandType.StoredProcedure);
        }
    }
}