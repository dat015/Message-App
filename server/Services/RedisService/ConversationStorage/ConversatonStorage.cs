using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.Services.RedisService.ConversationStorage
{
    public class ConversatonStorage : IConversationStorage
    {
        public Task<bool> DeleteMemberAsync(string conversationId, string memberId)
        {
            throw new NotImplementedException();
        }
    }

}