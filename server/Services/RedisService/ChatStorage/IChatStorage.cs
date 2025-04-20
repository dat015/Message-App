using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.DTO;

namespace server.Services.RedisService.ChatStorage
{
    public interface IChatStorage
    {
        Task SaveMessageAsync(MessageDTOForAttachment message, AttachmentDTOForAttachment? attachment);
        Task UpdateMessageConversationAsync(long messageId, long newConversationId);
        Task AddUserConversationAsync(long userId, long conversationId);
        Task PublishMessageAsync(MessageWithAttachment message);
        Task<List<MessageWithAttachment>> GetMessagesAsync(long conversationId, DateTime? fromDate = null, long limit = 50);
        Task UpdateMessageRecallAsync(long messageId, long conversationId);
        Task DeleteMessageAsync(int conversation_id, int user_id);
        // Task DeleteMessageForMeAsync(int message_id, int user_id);

    }
}