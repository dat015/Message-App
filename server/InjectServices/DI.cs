using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using server.Data;
using server.Filters;
using server.Services.AuthService;
using server.Services.OTPsService;
using server.Services.UserService;

namespace server.InjectService
{
    public static class DI
    {
        public static void Inject(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddControllers();
            services.AddEndpointsApiExplorer();
            services.AddSwaggerGen();

            services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));
    
            services.AddScoped<IAuthSV, AuthSV>();
            services.AddScoped<IUserSV, UserSV>();
            services.AddScoped<IOTPsSV, OTPsSV>();
            services.AddScoped<AuthorizationJWT>();

        }

    }
}
