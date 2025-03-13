using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using server.Data;
using server.InjectService;
using server.Services.ChatService;
using server.Services.WebSocketService;
using server.Services.UserService;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: true);

// Get JWT setting from appsettings.json
var jwtSetting = builder.Configuration.GetSection("JwtSettings");
var secretKey = jwtSetting.GetValue<string>("SecretKey");

builder.Services.AddAuthentication(option =>
{
    option.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    option.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(option =>
{
    option.RequireHttpsMetadata = false;
    option.SaveToken = true;
    option.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
        ValidateIssuer = true,
        ValidIssuer = jwtSetting["Issuer"],
        ValidateAudience = true,
        ValidAudience = jwtSetting["Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero // Không cho phép trễ thời gian
    };
});

builder.Services.Inject(builder.Configuration);
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin() // Cho phép tất cả nguồn gốc (thử nghiệm)
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Log setting
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .WriteTo.File("logs/log.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapControllers();
app.UseRouting();
app.MapHub<ChatHub>("/chatHub");
app.UseWebSockets(new WebSocketOptions
{
    KeepAliveInterval = TimeSpan.FromMinutes(2)
});
// Config WebSocket
// Khi client kết nối đến đường dẫn /ws thì sẽ gọi đến hàm HandleWebSocket trong WebSocketService
app.Map("/ws", async (HttpContext context, WebSocketService webSocketService, IServiceProvider serviceProvider) =>
{
    if (context.WebSockets.IsWebSocketRequest)
    {
        Console.WriteLine("WebSocket request received");
        using var webSocket = await context.WebSockets.AcceptWebSocketAsync();
        Console.WriteLine("WebSocket connection accepted");
        await webSocketService.HandleWebSocket(webSocket, serviceProvider);
        Console.WriteLine("WebSocket connection closed");
    }
    else
    {
        Console.WriteLine("Non-WebSocket request, returning 400");
        context.Response.StatusCode = 400;
    }
});

app.UseCors("AllowAll");
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.Run();