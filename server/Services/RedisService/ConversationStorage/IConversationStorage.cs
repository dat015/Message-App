using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.Services.RedisService.ConversationStorage
{
    public interface IConversationStorage
    {
        Task<bool> DeleteMemberAsync(string conversationId, string memberId);
        
    }
}