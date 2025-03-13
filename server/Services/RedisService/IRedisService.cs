using System;
using System.Threading.Tasks;

namespace server.Services.RedisService
{
    public interface IRedisService
    {
        Task SetAsync(string key, string value, TimeSpan? expiry = null);
        Task<string> GetAsync(string key);
        Task PublishAsync(string channel, string message);
        Task SubscribeAsync(string channel, Action<string, string> handler);
    }
}