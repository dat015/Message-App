using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using server.Data;
using server.Filters;
using server.Services.AuthService;
using server.Services.UserService;
using StackExchange.Redis;

namespace server.InjectService
{
    public static class DI
    {
        public static void Inject(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddControllers();
            services.AddEndpointsApiExplorer();
            services.AddSwaggerGen();
            //config sqlserver
            services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));

            //config redis
            services.AddSingleton<IConnectionMultiplexer>(sp =>
            {
                var redisConfiguration = ConfigurationOptions.Parse(configuration["Redis:ConnectionString"]);
                return ConnectionMultiplexer.Connect(redisConfiguration);
            });
            services.AddSignalR();
            services.AddScoped<IAuthSV, AuthSV>();
            services.AddScoped<IUserSV, UserSV>();
            services.AddScoped<AuthorizationJWT>();
        }

    }
}
