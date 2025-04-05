using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using server.Data;
using server.Models;
using server.Services.ParticipantService;
using server.Services.RedisService;
using server.Services.UserService;

namespace server.Services.ConversationService
{
    public class ConversationSV : IConversation
    {
        private readonly ApplicationDbContext _context;
        private readonly IUserSV _userSV;
        private readonly IParticipant _participant;
        private readonly IRedisService _redisService;
        public ConversationSV(ApplicationDbContext context, IUserSV userSV, IParticipant participant, IRedisService redisService)
        {
            _context = context;
            _userSV = userSV;
            _participant = participant;
            _redisService = redisService;
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


        public async Task<List<Conversation>> GetConversations(int userId)
        {
            try
            {
                // Key lưu danh sách conversation của user trong Redis
                string conversationKey = $"conversation:{userId}";

                // Lấy từ Redis
                var dataCache = await _redisService.GetListAsync(conversationKey);
                if (dataCache != null && dataCache.Any())
                {
                    Console.WriteLine("Cache data found in Redis:");
                    foreach (var item in dataCache)
                    {
                        Console.WriteLine(item);
                    }
                    // Chuyển đổi dữ liệu từ Redis thành List<Conversation>
                    var conversationsFromCache = JsonSerializer.Deserialize<List<Conversation>>(string.Join(",", dataCache));
                    return conversationsFromCache;
                }

                // Nếu không có trong Redis, lấy từ database
                var conversations = await _context.Participants
                    .Where(p => p.user_id == userId && !p.is_deleted)
                    .Select(p => p.conversation)
                    .ToListAsync();

                // Lưu vào Redis để dùng sau
                if (conversations != null && conversations.Any())
                {
                    var conversationsJson = JsonSerializer.Serialize(conversations);
                    await _redisService.SetAsync(conversationKey, conversationsJson, TimeSpan.FromHours(24)); // TTL 24h
                    Console.WriteLine($"Saved conversations to Redis with key: {conversationKey}");
                }

                return conversations ?? new List<Conversation>();
            }
            catch (Exception e)
            {
                Console.WriteLine($"Error in GetConversations: {e.Message}");
                // Fallback: Lấy từ database nếu Redis lỗi
                var conversations = await _context.Participants
                    .Where(p => p.user_id == userId && !p.is_deleted)
                    .Select(p => p.conversation)
                    .ToListAsync();
                return conversations ?? new List<Conversation>();
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
    }
}