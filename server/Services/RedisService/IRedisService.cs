using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using StackExchange.Redis;

namespace server.Services.RedisService
{
    public interface IRedisService
    {
        IDatabase GetDatabase();
        ISubscriber GetSubscriber();
    }
}