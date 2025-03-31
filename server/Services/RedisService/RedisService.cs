using System;
using System.Text.Json;
using System.Threading.Tasks;
using StackExchange.Redis;

namespace server.Services.RedisService
{
    public class RedisService : IRedisService
    {
        private readonly IConnectionMultiplexer _redis;
        private readonly IDatabase db;

        public RedisService(IConnectionMultiplexer redis)
        {
            _redis = redis ?? throw new ArgumentNullException(nameof(redis));
            _redis.ConnectionFailed += (sender, args) => Console.WriteLine($"Redis connection failed: {args.Exception.Message}");
            _redis.ConnectionRestored += (sender, args) => Console.WriteLine("Redis connection restored");
            db = redis.GetDatabase();
        }
        public async Task SortedSetAddKey(string key, string value, double expiry)
        {
            await db.SortedSetAddAsync(key, value, expiry);
        }
        public async Task KeyExpireAsync(string key, TimeSpan timeSpan)
        {
            await db.KeyExpireAsync(key, timeSpan);
        }
        public async Task SetAsync(string key, string value, TimeSpan? expiry = null)
        {
            await db.StringSetAsync(key, value, expiry);
        }

        public async Task<string> GetAsync(string key)
        {
            var value = await db.StringGetAsync(key);
            return value.HasValue ? value.ToString() : null;
        }
        public async Task DeleteDataAsync(string key)
        {
            await db.KeyDeleteAsync(key);
        }
        public async Task PublishAsync(string channel, string message)
        {
            var sub = _redis.GetSubscriber();
            await sub.PublishAsync(channel, message);
        }

        public async Task SubscribeAsync(string channel, Action<string, string> handler)
        {
            var sub = _redis.GetSubscriber();
            await sub.SubscribeAsync(channel, (ch, msg) => handler(ch, msg));
        }
        public async Task<bool> ExistsAsync(string key)
        {
            return await db.KeyExistsAsync(key);
        }

        public async Task SetListAsync(string key, List<string> values)
        {
            // Xóa danh sách cũ trước khi lưu mới
            await db.KeyDeleteAsync(key);
            if (values.Any())
            {
                await db.ListRightPushAsync(key, values.Select(v => (RedisValue)v).ToArray());
            }
        }

        public async Task<IEnumerable<string>> GetListAsync(string key)
        {
            if (!_redis.IsConnected)
            {
                Console.WriteLine("Redis is not connected. Skipping cache retrieval.");
                return null; // Trả về null để fallback về database
            }
            try
            {
                var db = _redis.GetDatabase();
                var value = await db.StringGetAsync(key);
                return value.HasValue ? JsonSerializer.Deserialize<List<string>>(value) : null;
            }
            catch (ObjectDisposedException ex)
            {
                Console.WriteLine($"Redis error: {ex.Message}");
                return null; // Fallback nếu Redis disposed
            }
        }

        public async Task SetHashAsync(string key, string field, string value)
        {
            await db.HashSetAsync(key, field, value);
        }

        public async Task<string> GetHashAsync(string key, string field)
        {
            return await db.HashGetAsync(key, field);
        }

        public async Task SetListAsync(string key, string value)
        {
            try
            {
                // Xóa key cũ nếu tồn tại (tùy chọn, có thể bỏ nếu không cần)
                await db.KeyDeleteAsync(key);

                // Lưu giá trị chuỗi vào Redis
                await db.StringSetAsync(key, value);

                // (Tùy chọn) Có thể thêm TTL nếu muốn cache có thời hạn
                // await db.StringSetAsync(key, value, TimeSpan.FromHours(24));
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error in SetListAsync: {ex.Message}");
                throw; // Ném lại exception để caller xử lý
            }
        }
    }
}