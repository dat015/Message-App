using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using server.Data;
using server.DTO;
using server.Models;
using server.Services.RedisService;
using server.Services.WebSocketService;
using StackExchange.Redis;

namespace server.Services.ParticipantService
{
    public class ParticipantSV : IParticipant
    {
        private readonly ApplicationDbContext _context;
        private readonly IRedisService _redisService;
        private readonly IConnectionMultiplexer _redis;
        private readonly webSocket _webSocket; // Singleton

        public ParticipantSV(ApplicationDbContext context, IRedisService redisService, IConnectionMultiplexer redis, webSocket webSocket)
        {
            _context = context;
            _redisService = redisService;
            _redis = redis;
            _webSocket = webSocket; // Inject the singleton instance
        }


        public Task<Participants> AddParticipantAsync(int conversation_id, int user_id)
        {
            if (conversation_id == 0 || user_id == 0)
            {
                return null;
            }
            try
            {
                var existParticipant = _context.Participants
                    .Where(p => p.conversation_id == conversation_id && p.user_id == user_id)
                    .FirstOrDefault();
                if (existParticipant != null)
                {
                    return Task.FromResult(existParticipant);
                }
                var user = _context.Users
                    .Where(u => u.id == user_id)
                    .FirstOrDefault();
                if (user == null)
                {
                    return null;
                }
                var participant = new Participants
                {
                    conversation_id = conversation_id,
                    user_id = user_id,
                    role = "member",
                    name = user.username,
                    joined_at = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time")),
                    is_deleted = false,
                };
                _context.Participants.Add(participant);
                _context.SaveChanges();
                return Task.FromResult(participant);
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                throw e;
            }
        }

        public async Task<List<Participants>> AddParticipantRangeAsync(int conversation_id, List<int> user_id)
        {
            if (conversation_id == 0 || user_id.Count == 0)
            {
                return null;
            }
            try
            {
                var participants = new List<Participants>();
                foreach (var id in user_id)
                {
                    var participant = new Participants
                    {
                        conversation_id = conversation_id,
                        user_id = id
                    };
                    participants.Add(participant);
                }
                await _context.Participants.AddRangeAsync(participants);
                await _context.SaveChangesAsync();
                return participants;
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                throw e;
            }
        }

        public async Task<List<Participants>> GetParticipants(int conversation_id)
        {
            try
            {
                var participants = await _context.Participants
                                        .Where(p => p.conversation_id == conversation_id)
                                        .ToListAsync();
                return participants;
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }

        public async Task<List<Participants>> GetParticipantsForSender(int conversation_id, int sender_id)
        {
            try
            {
                var participants = await _context.Participants
                                        .Where(p => p.conversation_id == conversation_id && p.user_id != sender_id)
                                        .ToListAsync();
                return participants;
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }

        public async Task<bool> updateNickName(int user_id, int conversation_id, string nickname)
        {
            if (user_id == 0 || conversation_id == 0 || string.IsNullOrEmpty(nickname))
            {
                return false;
            }

            try
            {
                Console.WriteLine($"Cập nhật nickname cho user_id: {user_id}, conversation_id: {conversation_id}, nickname: {nickname}");
                // Tìm participant mà không tải thuộc tính điều hướng
                var participant = await _context.Participants
                    .FirstOrDefaultAsync(p => p.user_id == user_id && p.conversation_id == conversation_id && !p.is_deleted);
                string oldUserName = participant.name ?? $"Người dùng {user_id}";
                if (participant == null)
                {
                    return false;
                }

                // Cập nhật nickname
                participant.name = nickname;
                await _context.SaveChangesAsync();

                int currentUserId = await _context.Conversations
                    .Where(c => c.id == conversation_id)
                    .Select(c => c.Participants
                        .Where(p => p.user_id != user_id && !p.is_deleted)
                        .Select(p => p.user_id)
                        .FirstOrDefault())
                    .FirstOrDefaultAsync();

                 Console.WriteLine("currentUserId: " + currentUserId);
                 Console.WriteLine("user_id: " + user_id);
                _redisService.DeleteDataAsync($"conversation:{currentUserId}");
                _redisService.DeleteDataAsync($"conversation:{user_id}");

                var message_update_type = new MessageDTOForAttachment
                {
                    content = $"Đã đổi tên bạn thành {nickname}",
                    sender_id = currentUserId,
                    conversation_id = conversation_id,
                    type = "system",
                };
                var message_update = new MessageWithAttachment
                {
                    Message = message_update_type,
                    Attachment = null
                };  

                await _webSocket.PublishMessage(message_update);
                return true;
            }
            catch (Exception e)
            {
                Console.WriteLine($"Lỗi trong UpdateNickName: {e.Message}");
                throw;
            }
        }
    }
}