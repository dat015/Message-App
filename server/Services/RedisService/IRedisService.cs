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
        Task DeleteDataAsync(string key);
        Task<bool> ExistsAsync(string key);
        Task SetListAsync(string key, string value);
        Task<IEnumerable<string>> GetListAsync(string key);
        Task SetHashAsync(string key, string field, string value);
        Task<string> GetHashAsync(string key, string field);
        public  Task SortedSetAddKey(string key, string value, double expiry);
        public Task KeyExpireAsync(string key, TimeSpan timeSpan);
    }
}