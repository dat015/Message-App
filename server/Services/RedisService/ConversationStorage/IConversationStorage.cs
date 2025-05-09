using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.Services.RedisService.ConversationStorage
{
    public interface IConversationStorage
    {
        Task<bool> DeleteMemberAsync(int conversationId, int memberId);
        Task<bool> DeleteConversationByUserAsync(int conversationId, int userId);
        Task<bool> AddNewConversationAsync(int conversationId, List<int> members);
        Task<bool> UpdateConversationAsync(int conversationId, string lastMessage, DateTime lastMessageTime, List<int> memberIds);
        
    }
}