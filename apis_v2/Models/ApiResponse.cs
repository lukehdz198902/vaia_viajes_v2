namespace VaiaViajes.Api.Models
{
    public class ApiError
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
        public string Details { get; set; } = string.Empty;
        public string Path { get; set; } = string.Empty;
        public string Timestamp { get; set; } = string.Empty;
    }

    public class ApiResponse<T>
    {
        public bool Success { get; set; }
        public T Data { get; set; }
        public string Message { get; set; }
        public int Code { get; set; }

        public static ApiResponse<T> Ok(T data, string message = null)
            => new ApiResponse<T> { Success = true, Data = data, Message = message };

        public static ApiResponse<T> Fail(string message, int code = 400, T data = default(T))
            => new ApiResponse<T> { Success = false, Message = message, Code = code, Data = data };
    }

    public class ApiResponse : ApiResponse<object>
    {
        public new static ApiResponse Ok(object data, string message = null)
            => new ApiResponse { Success = true, Data = data, Message = message };

        public new static ApiResponse Fail(string message, int code = 400, object data = null)
            => new ApiResponse { Success = false, Message = message, Code = code, Data = data };
    }
}