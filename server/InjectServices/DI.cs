using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using server.Data;
using server.Filters;
using server.Helper;
using server.Services.AuthService;
using server.Services.ConversationService;
using server.Services.DiffieHellmanService;
using server.Services.MessageService;
using server.Services.ParticipantService;
using server.Services.RedisService;
using server.Services.OTPsService;
using server.Services.UserService;
using server.Services.WebSocketService;
using StackExchange.Redis;
using server.Services;

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
            //cấu hình cors
           
           

            //singleton: tạo ra intance hết vòng đời của ứng dụng
            services.AddSingleton<WebSocketService>();
            services.AddSingleton<IRedisService, RedisService>();
            services.AddSingleton<DiffieHellman>();
            services.AddSingleton<IConnectionMultiplexer>(sp =>
            {
                var redisConfiguration = ConfigurationOptions.Parse(configuration["Redis:ConnectionString"]);
                return ConnectionMultiplexer.Connect(redisConfiguration);
            });
            services.AddSignalR();
            //scoped: tạo ra 1 instance cho mỗi request
            services.AddScoped<IAuthSV, AuthSV>();
            services.AddScoped<IUserSV, UserSV>();
            services.AddScoped<IConversation, ConversationSV>();
            services.AddScoped<IParticipant, ParticipantSV>();
            services.AddScoped<IMessage,MessagesV>();
            services.AddScoped<IOTPsSV, OTPsSV>();
            services.AddScoped<IFriendSV, FriendSV>();
            services.AddScoped<IUserProfileSV, UserProfileSV>();
            services.AddScoped<IWebSocketFriendSV, WebSocketFriendSV>();
            services.AddScoped<AuthorizationJWT>();
        }

    }
}
