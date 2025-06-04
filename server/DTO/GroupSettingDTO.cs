using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace server.DTO
{
    public class GroupSettingDTO
    {
        
        [JsonPropertyName("id")]
        public int? Id { get; set; } // Khóa chính, tự động tăng
        [JsonPropertyName("conversationId")]
        public int ConversationId { get; set; } // Khóa ngoại liên kết với Conversations
        [JsonPropertyName("allowMemberInvite")]
        public bool AllowMemberInvite { get; set; }
        [JsonPropertyName("allowMemberEdit")]
        public bool AllowMemberEdit { get; set; }
        [JsonPropertyName("createdBy")]
        public int CreatedBy { get; set; } // Khóa ngoại liên kết với Users
        [JsonPropertyName("createdAt")]
        public DateTime CreatedAt { get; set; } = DateTime.Now; // Thời gian tạo, mặc định là hiện tại
        [JsonPropertyName("allowMemberRemove")]
        public bool AllowMemberRemove { get; set; }

        
        public bool CheckGroupSetting(GroupSettingDTO groupSetting)
        {
            if (groupSetting == null)
            {
                throw new ArgumentNullException(nameof(groupSetting), "GroupSettingDTO cannot be null");
            }

            // Kiểm tra các trường bắt buộc
            if (groupSetting.ConversationId <= 0 || groupSetting.CreatedBy <= 0)
            {
                throw new ArgumentException("ConversationId and CreatedBy must be positive integers", nameof(groupSetting));
            }

            return true;
        }

    }
}