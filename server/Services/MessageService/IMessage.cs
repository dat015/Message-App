using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.DTO;
using server.Models;

namespace server.Services.MessageService
{
    public interface IMessage
    {
        Task<List<MessageWithAttachment>> getMessages(int conversation_id, DateTime? fromDate = null);
        Task addNewMessage(Message message);
    }
}