using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using StackExchange.Redis;

namespace server.Services.RedisService.ChatStorage
{
    public class ChatStorage
    {
        private readonly ConnectionMultiplexer _redis;
        private readonly IDatabase _db;
        public ChatStorage(String connectionString)
        {
            _redis = ConnectionMultiplexer.Connect(connectionString);
            _db = _redis.GetDatabase();
        }

        
    }
}