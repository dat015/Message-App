using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using server.Data;
using server.DTO;
using server.Models;
using server.Services.ParticipantService;
using server.Services.RedisService;
using server.Services.UserService;
using server.Services.WebSocketService;

namespace server.Services.ConversationService
{
    public class ConversationSV : IConversation
    {
        private readonly ApplicationDbContext _context;
        private readonly IUserSV _userSV;
        private readonly IParticipant _participant;
        private readonly IRedisService _redisService;
        private readonly webSocket _webSocket; // Singleton
        public ConversationSV(ApplicationDbContext context, IUserSV userSV, IParticipant participant, IRedisService redisService, webSocket webSocket)
        {
            _webSocket = webSocket; // Inject the singleton instance
            _context = context;
            _userSV = userSV;
            _participant = participant;
            _redisService = redisService;
        }

        public async Task<Participants> AddMemberToGroup(int conversation_id, int userId)
        {
            if (conversation_id == 0 || userId == 0)
            {
                return null;
            }
            try
            {
                var conversation = await _context.Conversations.FindAsync(conversation_id);
                if (conversation == null || conversation.is_group == false)
                {
                    return null;
                }

                var participant = await _participant.AddParticipantAsync(conversation_id, userId);

                return participant;
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                throw e;
            }
        }

        public async Task<Conversation> CreateConversation(int user1, int user2)
        {
            try
            {
                if (user1 == 0 || user2 == 0)
                {
                    return null;
                }
                else if (user1 == user2)
                {
                    return null;
                }
                else if (_userSV.ExistUser(user1) == null || _userSV.ExistUser(user2) == null)
                {
                    return null;
                }

                // kiểm tra xem 2 user có box chat riêng chưa
                var exisConversation = await _context.Conversations
                    .Where(e => !e.is_group)
                    .Where(c => c.Participants.Count == 2 &&
                                c.Participants.Any(p => p.user_id == user1) &&
                                c.Participants.Any(u => u.user_id == user2))
                    .FirstOrDefaultAsync();

                if (exisConversation != null)
                {
                    return exisConversation;
                }


                var conversation = new Conversation
                {
                    is_group = false,
                    created_at = DateTime.Now,
                    name = ""
                };

                await _context.Conversations.AddAsync(conversation);
                await _context.SaveChangesAsync();
                Console.WriteLine("Conversation added success with id: " + conversation.id);

                var listUserId = new List<int> { user1, user2 };
                if (_participant.AddParticipantRangeAsync(conversation.id, listUserId) == null)
                {
                    return null;
                }
                return conversation;

            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                throw e;
            }
        }

        public Task<Conversation> CreateGroupConversation(int userId, List<int> userIds, string name)
        {
            throw new NotImplementedException();
        }

        public async Task<List<ConversationDto>> GetConversations(int userId)
        {
            try
            {
                // Key lưu danh sách conversation của user trong Redis
                string conversationKey = $"conversation:{userId}";
                // Lấy dữ liệu từ Redis
                var dataCache = await _redisService.GetAsync(conversationKey);
                if (!string.IsNullOrEmpty(dataCache))
                {
                    Console.WriteLine($"Tìm thấy cache trong Redis cho key: {conversationKey}");
                    // Chuyển đổi dữ liệu từ Redis thành List<ConversationDto>
                    var conversationsFromCache = JsonSerializer.Deserialize<List<ConversationDto>>(dataCache);
                    return conversationsFromCache ?? new List<ConversationDto>();
                }

                // Nếu không có trong Redis, lấy từ database
                Console.WriteLine($"Không tìm thấy cache cho key: {conversationKey}, lấy từ database...");
                var conversations = await _context.Conversations
                    .Where(c => c.Participants.Any(p => p.user_id == userId && !p.is_deleted))
                    .Select(c => new ConversationDto
                    {
                        Id = c.id,
                        Name = c.name,
                        IsGroup = c.is_group,
                        CreatedAt = c.created_at,
                        LastMessage = c.lastMessage,
                        LastMessageTime = c.lastMessageTime,
                        Participants = c.Participants
                            .Where(p => !p.is_deleted)
                            .Select(p => new ParticipantDto
                            {
                                Id = p.id,
                                UserId = p.user_id,
                                ConversationId = p.conversation_id,
                                Name = p.name,
                                IsDeleted = p.is_deleted
                            }).ToList()
                    })
                    .ToListAsync();

                // Lưu vào Redis để dùng sau
                if (conversations.Any())
                {
                    var conversationsJson = JsonSerializer.Serialize(conversations);
                    await _redisService.SetAsync(conversationKey, conversationsJson, TimeSpan.FromHours(24)); // TTL 24h
                    Console.WriteLine($"Lưu conversations vào Redis với key: {conversationKey}");
                }

                return conversations ?? new List<ConversationDto>();
            }
            catch (Exception e)
            {
                Console.WriteLine($"Lỗi trong GetConversations: {e.Message}");
                throw; // Ném lỗi để controller xử lý, tránh trả về dữ liệu không đầy đủ
            }
        }
        public async Task<Conversation> get_conversation(int conversation_id)
        {
            try
            {
                var conversation = await _context.Conversations.FindAsync(conversation_id);
                if (conversation == null)
                {
                    return null;
                }
                return conversation;
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }

        public async Task<bool> isConnect(int user1, int user2)
        {
            try
            {
                if (user1 == user2)
                {
                    return false;
                }
                var conversation = await _context.Conversations
                    .Where(c => c.Participants.Any(p => p.user_id == user1))
                    .Where(c => c.Participants.Any(p => p.user_id == user2))
                    .Where(c => c.is_group == false)
                    .FirstOrDefaultAsync();

                return conversation != null;
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                throw e;
            }
        }

        public async Task<Conversation> UpdateConversationName(int conversation_id, string name)
        {
            if (conversation_id == 0 || string.IsNullOrEmpty(name))
            {
                return null;
            }
            try
            {
                // Tìm conversation trong database
                var conversation = await _context.Conversations
                    .Include(c => c.Participants) // Bao gồm participants để giữ dữ liệu đầy đủ
                    .FirstOrDefaultAsync(c => c.id == conversation_id);

                if (conversation == null)
                {
                    return null;
                }

                // Cập nhật tên
                conversation.name = name;
                _context.Conversations.Update(conversation);
                await _context.SaveChangesAsync();

                // Cập nhật lại cache trong Redis
                // Lấy tất cả user_id từ participants để cập nhật cache cho từng user
                var participantUserIds = conversation.Participants
                    .Where(p => !p.is_deleted)
                    .Select(p => p.user_id)
                    .Distinct();

                foreach (var userId in participantUserIds)
                {
                    string conversationKey = $"conversation:{userId}";
                    await _redisService.DeleteDataAsync(conversationKey); // Xóa cache cũ           
                }
                var message = new MessageDTOForAttachment
                {
                    content = $"Đã đổi tên nhóm thành {name}",
                    type = "system",
                    conversation_id = conversation_id,
                    sender_id = 0,
                    created_at = DateTime.Now,
                };
                var messageWithAttachment = new MessageWithAttachment
                {
                    Message = message,
                    Attachment = null // Không có attachment trong trường hợp này
                };

                await _webSocket.PublishMessage(messageWithAttachment);
                return conversation;
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error in UpdateConversationName: {e.Message}");
                throw; // Ném lại ngoại lệ để caller xử lý
            }
        }

      
    }
}