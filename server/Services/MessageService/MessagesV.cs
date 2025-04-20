using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking.Internal;
using Microsoft.IdentityModel.Tokens;
using server.Data;
using server.DTO;
using server.Models;
using server.Services.RedisService;
using server.Services.RedisService.ChatStorage;
using server.Services.WebSocketService;
using StackExchange.Redis;

namespace server.Services.MessageService
{
    public class MessagesV : IMessage
    {

        private readonly ApplicationDbContext _context;
        private readonly IRedisService _redisService;
        private readonly IConnectionMultiplexer _redis;
        private readonly ILogger<MessagesV> _logger;
        private readonly webSocket _webSocket;
        private readonly IChatStorage _chatStorage;
        private readonly IDatabase _redisDatabase;

        public MessagesV(IConnectionMultiplexer redis,
                            ApplicationDbContext context,
                            IRedisService redisService,
                            ILogger<MessagesV> logger,
                            webSocket webSocket,
                            IChatStorage chatStorage,
                            IDatabase redisDatabase)
        {
            _context = context;
            _redisService = redisService;
            _redis = redis;
            _logger = logger;
            _webSocket = webSocket;
            _chatStorage = chatStorage;
            _redisDatabase = redisDatabase;
        }
        public async Task addNewMessage(Message message)
        {
            try
            {
                await _context.Messages.AddAsync(message);
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }

        public async Task<bool> DeleteMessageConversationForMe(int conversation_id, int user_id)
        {
            if (conversation_id <= 0 || user_id <= 0)
            {
                throw new Exception("conversation id is not valid");
            }
            try
            {
                // Kiểm tra xem conversation và user có tồn tại không
                var existinConversation = await _context.Conversations.FindAsync(conversation_id);
                var existingUser = await _context.Users.FindAsync(user_id);

                if (existinConversation == null || existingUser == null)
                {
                    return false;
                }

                // Lấy thời điểm xóa hiện tại
                var clearedAt = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time"));
                var clearedAtTimestamp = ((DateTimeOffset)clearedAt).ToUnixTimeSeconds(); // Chuyển sang Unix timestamp

                // Kiểm tra xem đã có bản ghi xóa tin nhắn trong cơ sở dữ liệu chưa
                var existingDeletionMessage = await _context.messageDeletions
                    .Where(e => e.user_id == user_id && e.conversation_id == conversation_id)
                    .FirstOrDefaultAsync();

                // Nếu đã tồn tại, cập nhật thời gian
                if (existingDeletionMessage != null)
                {
                    existingDeletionMessage.cleared_at = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time"));;
                    _context.messageDeletions.Update(existingDeletionMessage);
                }
                else
                {
                    // Nếu chưa tồn tại, tạo bản ghi mới
                    var new_deletionMessage = new MessageDeletion
                    {
                        user_id = user_id,
                        conversation_id = conversation_id,
                        cleared_at = clearedAt
                    };
                    _context.messageDeletions.Add(new_deletionMessage);
                }

                // Lưu thay đổi vào cơ sở dữ liệu
                await _context.SaveChangesAsync();

                // Lưu cleared_at vào Redis
                var clearedAtKey = $"user:{user_id}:conversation:{conversation_id}:cleared_at";
                await _redisDatabase.StringSetAsync(clearedAtKey, clearedAtTimestamp);

                // Đặt TTL (7 ngày) để tiết kiệm bộ nhớ
                await _redisDatabase.KeyExpireAsync(clearedAtKey, TimeSpan.FromDays(7));

                // Xóa cache liên quan (nếu cần)
                await _chatStorage.DeleteMessageAsync(conversation_id, user_id);

                return true;
            }
            catch (Exception ex)
            {
                throw;
            }
        }



        public Task<bool> DeleteMessageForMe(int message_id)
        {
            throw new NotImplementedException();
        }


        public async Task<List<MessageWithAttachment>> GetMessagesAsync(long conversationId, int user_id, DateTime? fromDate = null)
        {
            try
            {
                // Lấy tin nhắn từ Redis qua ChatStorage
                var messages = await _chatStorage.GetMessagesAsync(conversationId, user_id, fromDate);
                if (messages.Any())
                {
                    _logger.LogInformation("Retrieved {MessageCount} messages from Redis for conversation {ConversationId} and user {UserId}", messages.Count, conversationId, user_id);
                    return messages;
                }
            }
            catch (RedisConnectionException ex)
            {
                _logger.LogError(ex, "Redis unavailable, falling back to database for conversation {ConversationId}", conversationId);
            }

            // Fallback sang cơ sở dữ liệu
            var clearedAt = await _context.messageDeletions
                .Where(md => md.user_id == user_id && md.conversation_id == conversationId)
                .Select(md => md.cleared_at)
                .FirstOrDefaultAsync();

            var query = _context.Messages
                .Where(m => m.conversation_id == conversationId);

            // Lọc tin nhắn có created_at > cleared_at
            if (clearedAt != default(DateTime))
            {
                query = query.Where(m => m.created_at > clearedAt);
            }

            if (fromDate.HasValue)
            {
                query = query.Where(m => m.created_at <= fromDate.Value);
            }

            var dbMessages = await query
                .OrderByDescending(m => m.created_at)
                .Include(m => m.Attachments)
                .Take(50)
                .ToListAsync();

            // Mapping sang DTO
            var messagesWithAttachment = dbMessages
                .Select(m => new MessageWithAttachment
                {
                    Message = new MessageDTOForAttachment
                    {
                        id = m.id,
                        content = m.content,
                        sender_id = m.sender_id,
                        is_read = m.is_read,
                        type = m.type,
                        isFile = m.isFile,
                        created_at = m.created_at,
                        conversation_id = m.conversation_id
                    },
                    Attachment = m.Attachments.FirstOrDefault() != null
                        ? new AttachmentDTOForAttachment
                        {
                            id = m.Attachments.First().id,
                            file_url = m.Attachments.First().file_url,
                            fileSize = m.Attachments.First().FileSize,
                            file_type = m.Attachments.First().file_type,
                            uploaded_at = m.Attachments.First().uploaded_at,
                            is_temporary = m.Attachments.First().is_temporary,
                            message_id = m.Attachments.First().message_id
                        }
                        : null
                })
                .ToList();

            // Cache vào Redis nếu là trang đầu
            if (messagesWithAttachment.Any() && !fromDate.HasValue)
            {
                try
                {
                    foreach (var msg in messagesWithAttachment)
                    {
                        await _chatStorage.SaveMessageAsync(msg.Message, msg.Attachment);
                    }
                    _logger.LogInformation("Cached {MessageCount} messages to Redis for conversation {ConversationId}", messagesWithAttachment.Count, conversationId);
                }
                catch (RedisConnectionException ex)
                {
                    _logger.LogError(ex, "Failed to cache messages to Redis for conversation {ConversationId}", conversationId);
                }
            }

            return messagesWithAttachment;
        }


        public async Task<bool> ReCallMessage(int message_id)
        {
            if (message_id <= 0)
            {
                throw new ArgumentException("Invalid message ID");
            }

            try
            {
                var existingMessage = await _context.Messages
                    .Where(e => e.id == message_id && !e.isRecalled)
                    .FirstOrDefaultAsync();

                if (existingMessage == null)
                {
                    _logger.LogWarning("Message {MessageId} not found or already recalled", message_id);
                    return false;
                }

                existingMessage.isRecalled = true;
                existingMessage.content = "Tin nhắn đã được thu hồi"; // Cập nhật content trong DB
                _context.Messages.Update(existingMessage);
                await _context.SaveChangesAsync();
                _logger.LogInformation("Message {MessageId} marked as recalled in database", message_id);

                await _chatStorage.UpdateMessageRecallAsync(message_id, existingMessage.conversation_id);
                _logger.LogInformation("Message {MessageId} recall status updated in Redis", message_id);

                return true;
            }
            catch (DbUpdateException ex)
            {
                _logger.LogError(ex, "Failed to update message {MessageId} in database", message_id);
                throw new Exception("Database error while recalling message", ex);
            }
            catch (RedisConnectionException ex)
            {
                _logger.LogError(ex, "Failed to update message {MessageId} in Redis", message_id);
                return true; // DB đã cập nhật, bỏ qua lỗi Redis
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error while recalling message {MessageId}", message_id);
                throw;
            }
        }





        //public async Task<List<Message>> getMessages(int conversation_id, int page = 1, int pageSize = 20)
        // {
        //     try
        //     {
        //         string messageKey = $"conversation:{conversation_id}:messages";
        //         var cacheData = await _redisService.GetListAsync(messageKey);

        //         if (cacheData != null && cacheData.Any())
        //         {
        //             Console.WriteLine("Cache data found:");
        //             foreach (var item in cacheData)
        //             {
        //                 Console.WriteLine(item);
        //             }

        //             try
        //             {
        //                 var json = JsonConvert.SerializeObject(cacheData); // Chuyển danh sách sang JSON hợp lệ
        //                 var result = JsonConvert.DeserializeObject<List<Message>>(json);


        //                 var messages = result
        //                     .Where(m => m != null)
        //                     .OrderByDescending(m => m.created_at) // Sửa created_at thành CreatedAt
        //                     .Skip((page - 1) * pageSize) // Áp dụng phân trang
        //                     .Take(pageSize)
        //                     .ToList();

        //                 return messages;
        //             }
        //             catch (Exception ex)
        //             {
        //                 Console.WriteLine($"Error in GetMessages: {ex.Message}");
        //                 throw;
        //             }
        //         }

        //         Console.WriteLine($"Fetching from DB for conversation_id: {conversation_id}");
        //         var messagesFromDb = await _context.Messages
        //             .Where(m => m.conversation_id == conversation_id)
        //             .OrderByDescending(m => m.created_at)
        //             .Skip((page - 1) * pageSize) // Áp dụng phân trang cho DB
        //             .Take(pageSize)
        //             .ToListAsync();

        //         if (messagesFromDb.Any())
        //         {
        //             var options = new JsonSerializerOptions
        //             {
        //                 NumberHandling = JsonNumberHandling.WriteAsString
        //             };

        //             // Serialize toàn bộ danh sách thành một chuỗi JSON
        //             string serializedMessages = System.Text.Json.JsonSerializer.Serialize(messagesFromDb, options);
        //             await _redisService.SetListAsync(messageKey, serializedMessages);
        //             Console.WriteLine($"Stored {messagesFromDb.Count} messages in cache");
        //         }

        //         return messagesFromDb;
        //     }
        //     catch (Exception ex)
        //     {
        //         Console.WriteLine($"Error in GetMessages: {ex.Message}");
        //         throw;
        //     }
        // }
    }
}