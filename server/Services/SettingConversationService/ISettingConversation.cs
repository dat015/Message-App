using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;

namespace server.Services.SettingConversationService
{
    public interface ISettingConversation
    {
        Task<bool> SetConversationAsync(string userId, string conversationId, string conversationName, string conversationDescription, string conversationImageUrl);
        
    }
}