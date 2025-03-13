using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.Models;

namespace server.Services.MessageService
{
    public interface IMessage
    {
        Task<List<Message>> getMessages(int conversation_id);
        Task addNewMessage(Message message);
    }
}