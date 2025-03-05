using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using StackExchange.Redis;

namespace server.Services.RedisService
{
    public class RedisService : IRedisService
    {
        private readonly IConnectionMultiplexer _redis;

        public RedisService(IConnectionMultiplexer redis)
        {
            _redis = redis;
        }

        public IDatabase GetDatabase() => _redis.GetDatabase();
        public ISubscriber GetSubscriber() => _redis.GetSubscriber();
    }
}