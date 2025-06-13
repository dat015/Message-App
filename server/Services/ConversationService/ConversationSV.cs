using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using server.Data;
using server.DTO;
using server.Models;
using server.Services.GroupSettingService;
using server.Services.ParticipantService;
using server.Services.RedisService;
using server.Services.RedisService.ChatStorage;
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
        private readonly IChatStorage _chatStorage;
        private readonly Lazy<IGroupSetting> _groupSettingService;

        public ConversationSV(ApplicationDbContext context, IChatStorage chatStorage, IUserSV userSV, IParticipant participant, IRedisService redisService, webSocket webSocket, Lazy<IGroupSetting> groupSettingService)
        {
            _webSocket = webSocket; // Inject the singleton instance
            _context = context;
            _userSV = userSV;
            _participant = participant;
            _redisService = redisService;
            _chatStorage = chatStorage;
            _groupSettingService = groupSettingService ?? throw new ArgumentNullException(nameof(groupSettingService), "Group setting service cannot be null");
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


        public async Task<ConversationDto> CreateConversation(int user1, int user2)
        {
            try
            {
                if (user1 == 0 || user2 == 0)
                {
                    Console.WriteLine("Invalid user IDs: user1 or user2 is 0");
                    return null;
                }
                else if (user1 == user2)
                {
                    Console.WriteLine("Cannot create conversation with same user: {user1}");
                    return null;
                }
                else if (await _userSV.ExistUser(user1) == null || await _userSV.ExistUser(user2) == null)
                {
                    Console.WriteLine("One or both users do not exist: user1={user1}, user2={user2}");
                    return null;
                }

                // Kiểm tra xem 2 user có box chat riêng chưa
                var exisConversation = await _context.Conversations
                    .Where(e => !e.is_group)
                    .Where(c => c.Participants.Count == 2 &&
                                c.Participants.Any(p => p.user_id == user1) &&
                                c.Participants.Any(u => u.user_id == user2))
                    .Select(c => new ConversationDto
                    {
                        Id = c.id,
                        Name = c.name,
                        is_group = c.is_group,
                        CreatedAt = c.created_at,
                        LastMessage = c.lastMessage,
                        LastMessageTime = c.lastMessageTime,
                        img_url = c.img_url,
                        Participants = c.Participants
                            .Where(p => !p.is_deleted)
                            .Select(p => new ParticipantDto
                            {
                                Id = p.id,
                                user_id = p.user_id,
                                ConversationId = p.conversation_id,
                                Name = p.name,
                                IsDeleted = p.is_deleted,
                                img_url = p.img_url
                            }).ToList()
                    })
                    .FirstOrDefaultAsync();

                if (exisConversation != null)
                {
                    Console.WriteLine($"Existing conversation found: ID={exisConversation.Id} for users {user1} and {user2}");
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
                Console.WriteLine($"Conversation added successfully with ID: {conversation.id}");

                var listUserId = new List<int> { user1, user2 };
                if (await _participant.AddParticipantRangeAsync(conversation.id, listUserId) == null)
                {
                    Console.WriteLine($"Failed to add participants for conversation ID: {conversation.id}");
                    return null;
                }

                // Load lại conversation từ DB sau khi thêm participant
                var updatedConversation = await _context.Conversations
                    .Where(c => c.id == conversation.id)
                    .Select(c => new ConversationDto
                    {
                        Id = c.id,
                        Name = c.name,
                        is_group = c.is_group,
                        CreatedAt = c.created_at,
                        LastMessage = c.lastMessage,
                        LastMessageTime = c.lastMessageTime,
                        img_url = c.img_url,
                        Participants = c.Participants
                            .Where(p => !p.is_deleted)
                            .Select(p => new ParticipantDto
                            {
                                Id = p.id,
                                user_id = p.user_id,
                                ConversationId = p.conversation_id,
                                Name = p.name,
                                IsDeleted = p.is_deleted,
                                img_url = p.img_url
                            }).ToList()
                    })
                    .FirstOrDefaultAsync();

                if (updatedConversation == null)
                {
                    Console.WriteLine($"Failed to load updated conversation ID: {conversation.id}");
                    return null;
                }

                _ = _webSocket.ConnectUserToConversationChanelAsync(user1, conversation.id);
                _ = _webSocket.ConnectUserToConversationChanelAsync(user2, conversation.id);

                // Cập nhật Redis cho cả user1 và user2
                foreach (var userId in listUserId)
                {
                    string conversationKey = $"conversation:{userId}";
                    List<ConversationDto> conversations;

                    // Lấy danh sách conversation hiện tại từ Redis
                    var dataCache = await _redisService.GetAsync(conversationKey);
                    if (!string.IsNullOrEmpty(dataCache))
                    {
                        Console.WriteLine($"Found cache in Redis for key: {conversationKey}");
                        conversations = JsonSerializer.Deserialize<List<ConversationDto>>(dataCache) ?? new List<ConversationDto>();
                    }
                    else
                    {
                        Console.WriteLine($"No cache found for key: {conversationKey}, initializing new list");
                        conversations = new List<ConversationDto>();
                    }

                    // Thêm conversation mới vào danh sách
                    if (!conversations.Any(c => c.Id == updatedConversation.Id))
                    {
                        conversations.Add(updatedConversation);
                        var conversationsJson = JsonSerializer.Serialize(conversations);
                        await _redisService.SetAsync(conversationKey, conversationsJson, TimeSpan.FromHours(24));
                        Console.WriteLine($"Updated Redis cache for key: {conversationKey} with new conversation ID: {updatedConversation.Id}");
                    }
                    else
                    {
                        Console.WriteLine($"Conversation ID: {updatedConversation.Id} already exists in Redis for user {userId}, skipping update");
                    }
                }

                return updatedConversation;
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error in CreateConversation: {e.Message}");
                throw;
            }
        }

        public async Task<ConversationDto> CreateGroup(GroupDto groupDto)
        {
            var conversation = new Conversation
            {
                is_group = true,
                created_at = DateTime.Now,
                name = groupDto.groupName,
                lastMessage = "Đã tạo nhóm",
                lastMessageTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time")),
            };
            var participants = new List<Participants>();
            try
            {
                _context.Conversations.Add(conversation);
                await _context.SaveChangesAsync();
                Console.WriteLine($"Conversation added successfully with ID: {conversation.id}");
                foreach (var userId in groupDto.userIds)
                {
                    var user_existing = await _userSV.GetUserByIdAsync(userId);
                    participants.Add(new Participants
                    {
                        user_id = userId,
                        conversation_id = conversation.id,
                        is_deleted = false,
                        joined_at = DateTime.Now,
                        name = user_existing.username,
                        img_url = user_existing.avatar_url,
                        role = "member"
                    });
                }

                //add them userId
                var user = new Participants
                {
                    user_id = groupDto.userId,
                    conversation_id = conversation.id,
                    is_deleted = false,
                    joined_at = DateTime.Now,
                    name = _userSV.GetUserByIdAsync(groupDto.userId).Result.username,
                    img_url = _userSV.GetUserByIdAsync(groupDto.userId).Result.avatar_url,
                    role = "admin"
                };
                participants.Add(user);

                _context.Participants.AddRange(participants);
                await _context.SaveChangesAsync();

                foreach (var participant in groupDto.userIds)
                {
                    await _webSocket.ConnectUserToConversationChanelAsync(participant, conversation.id);
                }
                await _webSocket.ConnectUserToConversationChanelAsync(groupDto.userId, conversation.id);


                var message = new MessageDTOForAttachment
                {
                    content = $"Đã tạo nhóm {groupDto.groupName}",
                    type = "system",
                    conversation_id = conversation.id,
                    sender_id = groupDto.userId,
                    created_at = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time")),

                };
                var messageWithAttachment = new MessageWithAttachment
                {
                    Message = message,
                    Attachment = null // Không có attachment trong trường hợp này
                };
                await _chatStorage.SaveMessageAsync(message, null);
                await _webSocket.PublishMessage(messageWithAttachment);

                return new ConversationDto
                {
                    Id = conversation.id,
                    Name = conversation.name,
                    is_group = conversation.is_group,
                    CreatedAt = conversation.created_at,
                    LastMessage = conversation.lastMessage,
                    LastMessageTime = conversation.lastMessageTime,
                    img_url = conversation.img_url,
                    Participants = participants.Select(p => new ParticipantDto
                    {
                        Id = p.id,
                        user_id = p.user_id,
                        ConversationId = p.conversation_id,
                        Name = p.name,
                        IsDeleted = p.is_deleted,
                        img_url = p.img_url
                    }).ToList()
                };

            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                throw;
            }
        }


        public async Task<ConversationDto?> GetConversationDto(int userId, int conversationId)
        {
            try
            {
                // Key lưu thông tin conversation của user trong Redis
                string conversationKey = $"conversation:{userId}:{conversationId}";

                // Lấy dữ liệu từ Redis
                var dataCache = await _redisService.GetAsync(conversationKey);
                if (!string.IsNullOrEmpty(dataCache))
                {
                    Console.WriteLine($"Tìm thấy cache trong Redis cho key: {conversationKey}");
                    // Chuyển đổi dữ liệu từ Redis thành ConversationDto
                    var conversationFromCache = JsonSerializer.Deserialize<ConversationDto>(dataCache);
                    return conversationFromCache;
                }

                // Nếu không có trong Redis, lấy từ database
                Console.WriteLine($"Không tìm thấy cache cho key: {conversationKey}, lấy từ database...");
                var conversation = await _context.Conversations
                    .Where(c => c.id == conversationId && c.Participants.Any(p => p.user_id == userId))
                    .Select(c => new ConversationDto
                    {
                        Id = c.id,
                        Name = c.name,
                        is_group = c.is_group,
                        CreatedAt = c.created_at,
                        LastMessage = c.lastMessage,
                        LastMessageTime = c.lastMessageTime,
                        img_url = c.img_url,
                        Participants = c.Participants
                            .Where(p => !p.is_deleted)
                            .Select(p => new ParticipantDto
                            {
                                Id = p.id,
                                user_id = p.user_id,
                                ConversationId = p.conversation_id,
                                Name = p.name,
                                IsDeleted = p.is_deleted,
                                img_url = p.img_url
                            }).ToList()
                    })
                    .FirstOrDefaultAsync();

                // Nếu không tìm thấy trong database
                if (conversation == null)
                {
                    Console.WriteLine($"Không tìm thấy conversation với ID: {conversationId} cho user: {userId}");
                    return null;
                }

                // Lưu vào Redis để dùng sau
                var conversationJson = JsonSerializer.Serialize(conversation);
                await _redisService.SetAsync(conversationKey, conversationJson, TimeSpan.FromHours(24)); // TTL 24h
                Console.WriteLine($"Lưu conversation vào Redis với key: {conversationKey}");

                return conversation;
            }
            catch (Exception e)
            {
                Console.WriteLine($"Lỗi trong GetConversation: {e.Message}");
                throw; // Ném lỗi để controller xử lý, tránh trả về dữ liệu không đầy đủ
            }
        }

        public async Task<List<ConversationDto>> GetConversations(int userId)
        {
            try
            {
                // // Key lưu danh sách conversation của user trong Redis
                // string conversationKey = $"conversation:{userId}";
                // // Lấy dữ liệu từ Redis
                // var dataCache = await _redisService.GetAsync(conversationKey);
                // if (!string.IsNullOrEmpty(dataCache))
                // {
                //     Console.WriteLine($"Tìm thấy cache trong Redis cho key: {conversationKey}");
                //     // Chuyển đổi dữ liệu từ Redis thành List<ConversationDto>
                //     var conversationsFromCache = JsonSerializer.Deserialize<List<ConversationDto>>(dataCache);
                //     return conversationsFromCache ?? new List<ConversationDto>();
                // }

                // // Nếu không có trong Redis, lấy từ database
                // Console.WriteLine($"Không tìm thấy cache cho key: {conversationKey}, lấy từ database...");
                var conversations = await _context.Conversations
                    .Where(c => c.Participants.Any(p => p.user_id == userId))
                    .Select(c => new ConversationDto
                    {
                        Id = c.id,
                        Name = c.name,
                        is_group = c.is_group,
                        CreatedAt = c.created_at,
                        LastMessage = c.lastMessage,
                        LastMessageTime = c.lastMessageTime,
                        img_url = c.img_url,
                        Participants = c.Participants
                            .Select(p => new ParticipantDto
                            {
                                Id = p.id,
                                user_id = p.user_id,
                                ConversationId = p.conversation_id,
                                Name = p.name,
                                IsDeleted = p.is_deleted,
                                img_url = p.img_url
                            }).ToList()
                    })
                    .ToListAsync();

                // // Lưu vào Redis để dùng sau
                // if (conversations.Any())
                // {
                //     var conversationsJson = JsonSerializer.Serialize(conversations);
                //     await _redisService.SetAsync(conversationKey, conversationsJson, TimeSpan.FromHours(24)); // TTL 24h
                //     Console.WriteLine($"Lưu conversations vào Redis với key: {conversationKey}");
                // }

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
                var conversation = await _context.Conversations
                    .Include(c => c.Participants)
                    .FirstOrDefaultAsync(c => c.id == conversation_id);
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

        public async Task<Conversation> UpdateConversationImage(int conversation_id, string image)
        {
            if (conversation_id == 0 || string.IsNullOrEmpty(image))
            {
                return null;
            }
            try
            {
                var existing_conversation = await _context.Conversations.FindAsync(conversation_id);
                if (existing_conversation == null)
                {
                    throw new Exception("Conversation not found");
                }
                // var existing_groupSetting = await _groupSettingService.Value.GetGroupSettingByConversationIdAsync(conversation_id);

                // if (!existing_groupSetting.AllowMemberEdit)
                // {
                //     throw new Exception("Bạn không có quyền sửa ảnh nhóm này");
                // }
                existing_conversation.img_url = image;
                _context.Conversations.Update(existing_conversation);
                await _context.SaveChangesAsync();
                var message = new MessageDTOForAttachment
                {
                    content = $"Đã đổi ảnh nhóm {image}",
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
                await _chatStorage.SaveMessageAsync(message, null);
                await _webSocket.PublishMessage(messageWithAttachment);

                return existing_conversation;
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error in UpdateConversationImage: {e.Message}");
                throw; // Ném lại ngoại lệ để caller xử lý
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
                // var existing_groupSetting = await _groupSettingService.Value.GetGroupSettingByConversationIdAsync(conversation_id);

                // if (!existing_groupSetting.AllowMemberEdit)
                // {
                //     throw new Exception("Bạn không có quyền sửa tên nhóm này");
                // }

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


                await _chatStorage.SaveMessageAsync(message, null);
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