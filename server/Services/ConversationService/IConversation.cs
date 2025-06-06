using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.DTO;
using server.Models;

namespace server.Services.ConversationService
{
    public interface IConversation
    {
        Task<List<ConversationDto>> GetConversations(int userId);
        Task<Conversation> get_conversation(int conversation_id);
        Task<bool> isConnect(int user1, int user2);
        Task<ConversationDto> CreateConversation(int user1, int user2);
        Task<Participants> AddMemberToGroup(int conversation_id, int userId);
        Task<Conversation> UpdateConversationName(int conversation_id, string name);
        Task<ConversationDto?> GetConversationDto(int userId, int conversationId);
        Task<Conversation> UpdateConversationImage(int conversation_id, string image);
        Task<ConversationDto> CreateGroup(GroupDto groupDto);
    }
}