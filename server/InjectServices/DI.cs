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
using CloudinaryDotNet;
using server.Services.UploadService;
using System.Text.Json.Serialization;
using server.Services;
using server.Services.ImageDescriptionService;

namespace server.InjectService
{
    public static class DI
    {
        public static void Inject(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddCors(options =>
            {
                options.AddPolicy("AllowAll", builder =>
                {
                    builder.AllowAnyOrigin() // Cho phép tất cả origin (thay bằng origin cụ thể trong production)
                        .AllowAnyMethod() // Cho phép tất cả phương thức (GET, POST, OPTIONS, v.v.)
                        .AllowAnyHeader(); // Cho phép tất cả header
                });
            });
            services.AddControllers().AddJsonOptions(options =>
            {
                options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.Preserve;
            }); // Thêm JsonOptions để xử lý vòng lặp tham chiếu
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

            // Đăng ký WebSocketService
            services.AddSingleton<webSocket>(); // Singleton vì dịch vụ này quản lý trạng thái client
            services.Configure<Services.WebSocketService.WebSocketOptions>(options =>
            {
                options.MaxBufferSize = 8192; // 8KB
                options.HeartbeatInterval = 15; // 15 giây
            });

            var cloudinaryConfig = configuration.GetSection("Cloudinary");
            var account = new Account(
                            cloudinaryConfig["CloudName"],
                            cloudinaryConfig["ApiKey"],
                            cloudinaryConfig["ApiSecret"]
                        );
            var cloudinary = new Cloudinary(account);

            services.AddSingleton(cloudinary);
            services.AddHttpContextAccessor();
            services.AddSingleton<IRedisService, RedisService>();
            services.AddSingleton<DiffieHellman>();
            services.AddSingleton<IConnectionMultiplexer>(sp =>
            {
                var redisConfiguration = ConfigurationOptions.Parse(configuration["Redis:ConnectionString"]);
                return ConnectionMultiplexer.Connect(redisConfiguration);
            });
            services.AddSignalR();
            //scoped: tạo ra 1 instance cho mỗi request
            services.AddScoped<IUploadFileService, UploadFileService>();
            services.AddScoped<IAuthSV, AuthSV>();
            services.AddScoped<IUserSV, UserSV>();
            services.AddScoped<IConversation, ConversationSV>();
            services.AddScoped<IParticipant, ParticipantSV>();
            services.AddScoped<IMessage, MessagesV>();
            services.AddScoped<IOTPsSV, OTPsSV>();
            services.AddScoped<IFriendSV, FriendSV>();
            services.AddScoped<IUserQrService, UserQrService>();
            services.AddScoped<IUserProfileSV, UserProfileSV>();
            services.AddScoped<IWebSocketFriendSV, WebSocketFriendSV>();
            services.AddScoped<IAIPostSV, AIPostSV>();
            services.AddScoped<IImageDescriptionSV, ImageDescriptionService>();
            services.AddScoped<AuthorizationJWT>();
        }

    }
}
