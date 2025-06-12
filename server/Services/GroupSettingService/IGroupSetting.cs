using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.DTO;

namespace server.Services.GroupSettingService
{
    public interface IGroupSetting
    {
        public Task<bool> CreateGroupSettingAsync(GroupSettingDTO dto);
        public Task<bool> UpdateGroupSettingAsync(GroupSettingDTO dto);
        public Task<GroupSettingDTO> GetGroupSettingByConversationIdAsync(int conversationId);
    }
}