using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
using Newtonsoft.Json.Linq;

public static class ParameterHelper
{
    public static Dictionary<string, object> ToDictionary(dynamic parameters)
    {
        if (parameters is Dictionary<string, object> dict)
            return dict;

        if (parameters is JObject jobj)
        {
            var result = new Dictionary<string, object>();
            foreach (var prop in jobj.Properties())
                result[prop.Name] = prop.Value?.Type == JTokenType.Null ? null : (prop.Value as JValue)?.Value ?? prop.Value;
            return result;
        }

        if (parameters is null)
            return null;

        return parameters;
    }

    public static string Sha256Hash(string input)
    {
        using (var sha = SHA256.Create())
        {
            var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(input ?? ""));
            var sb = new StringBuilder();
            foreach (var b in bytes)
                sb.Append(b.ToString("x2"));
            return sb.ToString();
        }
    }
}
