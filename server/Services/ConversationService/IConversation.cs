using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.Models;

namespace server.Services.ConversationService
{
    public interface IConversation
    {
        Task<List<Conversation>> GetConversations(int userId);
        Task<Conversation> get_conversation(int conversation_id);
    }
}