using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using server.Data;
using server.InjectService;
using server.Services.ChatService;
using server.Services.WebSocketService;
using server.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: true);

// JWT configuration
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
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.Inject(builder.Configuration);
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });
});

// Logging
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .WriteTo.File("logs/log.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();

// Đăng ký WebSocketFriendSV
builder.Services.AddSingleton<IWebSocketFriendSV, WebSocketFriendSV>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var friendService = scope.ServiceProvider.GetRequiredService<IFriendSV>();
    await friendService.SyncUsersToRedisAsync();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseWebSockets(new WebSocketOptions
{
    KeepAliveInterval = TimeSpan.FromMinutes(2)
});

// Endpoint WebSocket cho kết bạn
app.Map("/ws", async (HttpContext context, IWebSocketFriendSV webSocketFriendSV) =>
{
    if (context.WebSockets.IsWebSocketRequest)
    {
        var userIdStr = context.Request.Query["userId"].ToString();
        if (!int.TryParse(userIdStr, out int userId))
        {
            context.Response.StatusCode = 400; // Bad Request nếu không có userId
            return;
        }

        using var webSocket = await context.WebSockets.AcceptWebSocketAsync();
        await webSocketFriendSV.HandleFriendWebSocket(webSocket, userId);
    }
    else
    {
        context.Response.StatusCode = 400;
    }
});

app.UseRouting();
app.MapHub<ChatHub>("/chatHub");
app.MapControllers();

app.UseCors("AllowAll");
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

app.Run();