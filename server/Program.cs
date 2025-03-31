using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using server.Data;
using server.InjectService;
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
app.UseCors("AllowAll");
app.MapControllers();
app.UseRouting();
app.UseWebSockets();
app.UseEndpoints(endpoints =>
{
    endpoints.MapControllers();
    endpoints.Map("/ws", async context =>
    {
        var webSocketService = context.RequestServices.GetRequiredService<webSocket>();
        if (context.WebSockets.IsWebSocketRequest)
        {
            Console.WriteLine("WebSocket request received");
            await webSocketService.HandleWebSocket(context);
        }
        else
        {
            Console.WriteLine("Received non-WebSocket request");
            Console.WriteLine($"Request Headers: {string.Join(", ", context.Request.Headers.Select(h => $"{h.Key}: {h.Value}"))}");
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
        }
    });
});
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.Run();