using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.Services.SettingConversationService
{
    public class SettingConversationSV : ISettingConversation   
    {
        public Task<bool> SetConversationAsync(string userId, string conversationId, string conversationName, string conversationDescription, string conversationImageUrl)
        {
            throw new NotImplementedException();
        }
    }
}