using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using server.Data;
using server.DTO;
using server.Models;
using server.Services.RedisService;
using StackExchange.Redis;

namespace server.Services.MessageService
{
    public class MessagesV : IMessage
    {

        private readonly ApplicationDbContext _context;
        private readonly IRedisService _redisService;
        private readonly IConnectionMultiplexer _redis;

        public MessagesV(IConnectionMultiplexer redis, ApplicationDbContext context, IRedisService redisService)
        {
            _context = context;
            _redisService = redisService;
            _redis = redis;
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

        // private async Task CacheMessage(Message message)
        // {
        //     var key = $"conversation:{message.conversation_id}:messages";
        //     await _redisService.SortedSetAddKey(key, System.Text.Json.JsonSerializer.Serialize(message), message.created_at.Ticks);
        //     await _redisService.KeyExpireAsync(key, TimeSpan.FromHours(24));
        // }
        public async Task<List<MessageWithAttachment>> getMessages(int conversation_id, DateTime? fromDate = null)
        {
            var db = _redis.GetDatabase();
            var conversationKey = $"conversation:{conversation_id}:recent";

            // Xử lý Redis key không đúng kiểu
            var keyType = await db.KeyTypeAsync(conversationKey);
            if (keyType != RedisType.List && keyType != RedisType.None)
            {
                Console.WriteLine($"Warning: Redis key {conversationKey} is not a List. Deleting key.");
                await db.KeyDeleteAsync(conversationKey);
            }

            // Lấy tin nhắn từ Redis nếu fromDate không có (trang đầu)
            if (!fromDate.HasValue)
            {
                var messagesJson = await db.ListRangeAsync(conversationKey, 0, -1);
                if (messagesJson.Length > 0)
                {
                    var messagesFromRedis = messagesJson
                        .Select(m =>
                        {
                            try
                            {
                                return JsonSerializer.Deserialize<MessageWithAttachment>(m!);
                            }
                            catch
                            {
                                return null;
                            }
                        })
                        .Where(m => m != null)
                        .OrderByDescending(o => o!.Message.created_at)
                        .ToList();

                    if (messagesFromRedis.Any())
                        return messagesFromRedis!;
                }
            }

            // Truy vấn từ DB
            var query = _context.Messages
                .Where(m => m.conversation_id == conversation_id);

            if (fromDate.HasValue)
            {
                query = query.Where(m => m.created_at <= fromDate.Value);
            }

            var messages = await query
                .OrderByDescending(m => m.created_at)
                .Include(m => m.Attachments)
                .Take(50)
                .ToListAsync();

            // Mapping sang DTO
            var messageWithAttachment = messages
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
                            FileSize = m.Attachments.First().FileSize,
                            file_type = m.Attachments.First().file_type,
                            uploaded_at = m.Attachments.First().uploaded_at,
                            is_temporary = m.Attachments.First().is_temporary,
                            message_id = m.Attachments.First().message_id
                        }
                        : null
                })
                .ToList();

            // Cache nếu là trang đầu
            if (messageWithAttachment.Any() && !fromDate.HasValue)
            {
                var serializedMessages = messageWithAttachment
                    .Select(m => (RedisValue)JsonSerializer.Serialize(m))
                    .ToArray();

                await db.ListRightPushAsync(conversationKey, serializedMessages);
                await db.ListTrimAsync(conversationKey, -50, -1); // giữ tối đa 50 tin nhắn
                await db.KeyExpireAsync(conversationKey, TimeSpan.FromHours(24));
            }

            return messageWithAttachment;
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