using System;
using System.Threading.Tasks;
using StackExchange.Redis;

namespace server.Services.RedisService
{
    public class RedisService : IRedisService
    {
        private readonly IConnectionMultiplexer _redis;

        public RedisService(IConnectionMultiplexer redis)
        {
            _redis = redis ?? throw new ArgumentNullException(nameof(redis));
        }

        public async Task SetAsync(string key, string value, TimeSpan? expiry = null)
        {
            var db = _redis.GetDatabase();
            await db.StringSetAsync(key, value, expiry);
        }

        public async Task<string> GetAsync(string key)
        {
            var db = _redis.GetDatabase();
            var value = await db.StringGetAsync(key);
            return value.HasValue ? value.ToString() : null;
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
    }
}