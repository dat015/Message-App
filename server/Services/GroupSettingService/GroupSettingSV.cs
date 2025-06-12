using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using server.Data;
using server.DTO;
using server.Models;
using server.Services.ConversationService;
using server.Services.UserService;

namespace server.Services.GroupSettingService
{
    public class GroupSettingSV : IGroupSetting
    {

        private readonly IUserSV _userService;
        private readonly ApplicationDbContext _context;
        private readonly IConversation _conversationService;
        public GroupSettingSV(IUserSV userService, ApplicationDbContext context, IConversation conversatironsv)

        {
            _userService = userService ?? throw new ArgumentNullException(nameof(userService), "User service cannot be null");
            _context = context ?? throw new ArgumentNullException(nameof(context), "ApplicationDbContext cannot be null");
            _conversationService = conversatironsv ?? throw new ArgumentNullException(nameof(conversatironsv), "Conversation service cannot be null");
        }
        public async Task<bool> CreateGroupSettingAsync(GroupSettingDTO dto)
        {
            var isValidGroupSetting = dto.CheckGroupSetting(dto);
            if (!isValidGroupSetting)
            {
                throw new ArgumentException("Invalid GroupSettingDTO", nameof(dto));
            }
            var existingUser = await _userService.GetUserByIdAsync(dto.CreatedBy);
            var existingConversation = await _conversationService.get_conversation(dto.ConversationId);

            if (existingUser == null || existingConversation == null)
            {
                throw new InvalidOperationException("User or Conversation does not exist");
            }

            var groupSetting = new GroupSettings
            {
                ConversationId = dto.ConversationId,
                AllowMemberInvite = dto.AllowMemberInvite,
                AllowMemberEdit = dto.AllowMemberEdit,
                CreatedBy = dto.CreatedBy,
                CreatedAt = DateTime.Now
            };

            try
            {
                _context.GroupSettings.Add(groupSetting);
                await _context.SaveChangesAsync();
                return true;
            }
            catch (Exception ex)
            {
                // Log the exception (not implemented here)
                Console.WriteLine($"Error creating group setting: {ex.Message}");
                return false;
            }

        }

        public async Task<GroupSettingDTO> GetGroupSettingByConversationIdAsync(int conversationId)
        {
            if (conversationId <= 0)
            {
                throw new ArgumentException("ConversationId must be a positive integer", nameof(conversationId));
            }
            try
            {
                var groupSetting = await _context.GroupSettings
                .Where(gs => gs.ConversationId == conversationId)
                .Select(gs => new GroupSettingDTO
                {
                    Id = gs.Id,
                    ConversationId = gs.ConversationId,
                    AllowMemberInvite = gs.AllowMemberInvite,
                    AllowMemberEdit = gs.AllowMemberEdit,
                    CreatedBy = gs.CreatedBy,
                    CreatedAt = gs.CreatedAt,
                    AllowMemberRemove = gs.AllowMemberRemove
                })
                .FirstOrDefaultAsync();

                return groupSetting ?? new GroupSettingDTO();
            }
            catch (Exception ex)
            {
                // Log the exception (not implemented here)
                Console.WriteLine($"Error retrieving group setting: {ex.Message}");
                throw new InvalidOperationException("Error retrieving group setting", ex);
            }


        }

        public async Task<bool> UpdateGroupSettingAsync(GroupSettingDTO dto)
        {
            var isValidGroupSetting = dto.CheckGroupSetting(dto);
            if (!isValidGroupSetting)
            {
                throw new ArgumentException("Invalid GroupSettingDTO", nameof(dto));
            }

            var existingGroupSetting = _context.GroupSettings.FirstOrDefault(gs => gs.Id == dto.Id);
            var existingUser = await _userService.GetUserByIdAsync(dto.CreatedBy);
            if (existingGroupSetting == null || existingUser == null)
            {
                throw new InvalidOperationException("GroupSetting or User does not exist");
            }

            existingGroupSetting.AllowMemberInvite = dto.AllowMemberInvite;
            existingGroupSetting.AllowMemberEdit = dto.AllowMemberEdit;

            try
            {
                _context.GroupSettings.Update(existingGroupSetting);
                _context.SaveChanges();
                return true;
            }
            catch (Exception ex)
            {
                // Log the exception (not implemented here)
                Console.WriteLine($"Error updating group setting: {ex.Message}");
                return false;
            }
        }
    }
}