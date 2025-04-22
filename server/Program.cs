using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using server.Data;
using server.InjectService;
using server.Services.WebSocketService;
using server.Services;
using server.Services.UserService; // Thêm namespace cho UserQrService

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.UseUrls("http://localhost:5053");
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

builder.WebHost.UseKestrel(options =>
{
    options.ListenAnyIP(5053); // Lắng nghe tất cả IP trên cổng 5053
});

builder.Services.Inject(builder.Configuration);

// Logging
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .WriteTo.File("logs/log.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();

// Đăng ký các service
builder.Services.AddSingleton<IWebSocketFriendSV, WebSocketFriendSV>();
builder.Services.AddScoped<IUserSV, UserSV>();

builder.Services.AddMemoryCache();


var app = builder.Build();
app.UseWebSockets();

using (var scope = app.Services.CreateScope())
{
    var friendService = scope.ServiceProvider.GetRequiredService<IFriendSV>();
    await friendService.SyncUsersToRedisAsync();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "Message App API V1"));
}
app.UseCors("AllowAll");
app.MapControllers();
app.UseRouting();
// Chat websocket
app.Map("/ws/chat", async context =>
{
    if (context.WebSockets.IsWebSocketRequest)
    {
        var handler = context.RequestServices.GetRequiredService<webSocket>();
        await handler.HandleWebSocket(context);
    }
    else
    {
        context.Response.StatusCode = 400;
    }
});

// Friend websocket
app.Map("/ws/friend", async context =>
{
    if (context.WebSockets.IsWebSocketRequest)
    {
        var userIdStr = context.Request.Query["userId"];
        if (!int.TryParse(userIdStr, out int userId))
        {
            context.Response.StatusCode = 400;
            return;
        }

        var webSocket = await context.WebSockets.AcceptWebSocketAsync();
        var handler = context.RequestServices.GetRequiredService<IWebSocketFriendSV>();
        await handler.HandleFriendWebSocket(webSocket, userId);
    }
    else
    {
        context.Response.StatusCode = 400;
    }
});


app.UseRouting();
app.MapControllers();

app.UseCors("AllowAll");
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

app.Run();