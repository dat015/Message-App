using System;
using System.Collections.Generic;
using System.Diagnostics.Eventing.Reader;
using System.Linq;
using System.Threading.Tasks;
using server.DTO;
using server.Models;

namespace server.Services.MessageService
{
    public interface IMessage
    {
        Task<List<MessageWithAttachment>> GetMessagesAsync(long conversationId, int user_id, DateTime? fromDate = null);
        Task addNewMessage(Message message);
        Task<bool> DeleteMessageConversationForMe(int conversation_id, int user_id);
        Task<bool> DeleteMessageForMe(int message_id);
        Task<bool> ReCallMessage(int message_id);
    }
}