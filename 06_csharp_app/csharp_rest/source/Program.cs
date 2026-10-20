using System.Text.Json;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<AppConfig>(new AppConfig
{
    Port = Environment.GetEnvironmentVariable("PORT") ?? "80",
    AppName = Environment.GetEnvironmentVariable("APP_NAME") ?? "CSharp Minimal API"
});

builder.WebHost.ConfigureKestrel(serverOptions =>
{
    var config = builder.Services.BuildServiceProvider().GetRequiredService<AppConfig>();
    serverOptions.ListenAnyIP(int.Parse(config.Port));
});

var app = builder.Build();

int requestCount = 0;
var startTime = DateTime.UtcNow;

app.MapGet("/", () =>
{
    Interlocked.Increment(ref requestCount);
    var config = app.Services.GetRequiredService<AppConfig>();
    return Results.Text("Hello from " + config.AppName + "!", "text/plain");
});

app.MapGet("/healthz", () =>
{
    Interlocked.Increment(ref requestCount);
    var config = app.Services.GetRequiredService<AppConfig>();
    
    var healthResponse = new HealthResponse
    {
        Status = "healthy",
        Timestamp = DateTime.UtcNow.ToString("o"),
        RequestCount = requestCount,
        Uptime = DateTime.UtcNow - startTime,
        AppName = config.AppName,
        Version = "1.0.0",
        Framework = ".NET Core 11"
    };
    
    return Results.Json(healthResponse);
});

app.MapGet("/readyz", () =>
{
    Interlocked.Increment(ref requestCount);
    var readinessResponse = new ReadinessResponse
    {
        Status = "ready",
        Timestamp = DateTime.UtcNow.ToString("o"),
        RequestCount = requestCount
    };
    
    return Results.Json(readinessResponse);
});

app.MapGet("/slow", (int n) =>
{
    Interlocked.Increment(ref requestCount);
    Thread.Sleep(n * 100);
    return Results.Text("Request #" + requestCount + ": Slow response after " + (n * 100) + "ms delay", "text/plain");
});

app.MapFallback(() =>
{
    Interlocked.Increment(ref requestCount);
    return Results.NotFound(new 
    {
        Status = "error",
        Message = "Route not found",
        Timestamp = DateTime.UtcNow.ToString("o"),
        RequestCount = requestCount
    });
});

app.Run();

public class AppConfig
{
    public string Port { get; set; } = "80";
    public string AppName { get; set; } = "CSharp Minimal API";
}

public class HealthResponse
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = "";
    
    [JsonPropertyName("timestamp")]
    public string Timestamp { get; set; } = "";
    
    [JsonPropertyName("request_count")]
    public int RequestCount { get; set; } = 0;
    
    [JsonPropertyName("uptime")]
    public TimeSpan Uptime { get; set; } = TimeSpan.Zero;
    
    [JsonPropertyName("app_name")]
    public string AppName { get; set; } = "";
    
    [JsonPropertyName("version")]
    public string Version { get; set; } = "";
    
    [JsonPropertyName("framework")]
    public string Framework { get; set; } = "";
}

public class ReadinessResponse
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = "";
    
    [JsonPropertyName("timestamp")]
    public string Timestamp { get; set; } = "";
    
    [JsonPropertyName("request_count")]
    public int RequestCount { get; set; } = 0;
}