using System;
using System.Collections.Generic;
using System.Drawing.Printing;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Connections;
using server.DTO;
using StackExchange.Redis;

namespace server.Services.RedisService.ChatStorage
{
    public class ChatStorage : IChatStorage
    {
        private readonly IConnectionMultiplexer _redis;
        private readonly ILogger<ChatStorage> _logger;
        private static readonly JsonSerializerOptions _jsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        public ChatStorage(IConnectionMultiplexer redis, ILogger<ChatStorage> logger)
        {
            _redis = redis;
            _logger = logger;
        }

        public async Task SaveMessageAsync(MessageDTOForAttachment message, AttachmentDTOForAttachment? attachment)
        {
            var db = _redis.GetDatabase();
            var messageKey = $"message:{message.id}";
            var conversationKey = $"conversation:{message.conversation_id}:messages";

            try
            {
                // Kiểm tra trùng lặp
                if (await db.KeyExistsAsync(messageKey))
                {
                    _logger.LogInformation("Message {MessageId} already exists in Redis", message.id);
                    return;
                }

                // Lưu chi tiết tin nhắn và attachment vào Hash
                var messageHash = new[]
                {
                    new HashEntry("conversation_id", message.conversation_id),
                    new HashEntry("sender_id", message.sender_id),
                    new HashEntry("content", message.content ?? ""),
                    new HashEntry("created_at", message.created_at.ToString("O")),
                    new HashEntry("isFile", message.isFile ? "1" : "0"),
                    new HashEntry("type", message.type ?? ""),
                    new HashEntry("file_id", attachment?.id.ToString() ?? ""),
                    new HashEntry("file_url", attachment?.file_url ?? ""),
                    new HashEntry("fileSize", attachment?.fileSize.ToString() ?? ""),
                    new HashEntry("file_type", attachment?.file_type ?? ""),
                    new HashEntry("uploaded_at", attachment?.uploaded_at.ToString("O") ?? ""),
                    new HashEntry("is_temporary", attachment?.is_temporary.ToString() ?? "")
                };
                await db.HashSetAsync(messageKey, messageHash);
                await db.KeyExpireAsync(messageKey, TimeSpan.FromDays(7)); // TTL 7 ngày
                _logger.LogInformation("Saved message {MessageId} to Redis", message.id);

                // Thêm message_id vào Sorted Set
                var unixTimestamp = message.created_at.ToUnixTimeSeconds();
                await db.SortedSetAddAsync(conversationKey, message.id, unixTimestamp);
                _logger.LogInformation("Added message {MessageId} to conversation {ConversationId}", message.id, message.conversation_id);
            }
            catch (RedisConnectionException ex)
            {
                _logger.LogError(ex, "Failed to save message {MessageId}", message.id);
                throw;
            }
        }

        public async Task UpdateMessageConversationAsync(long messageId, long newConversationId)
        {
            var db = _redis.GetDatabase();
            var messageKey = $"message:{messageId}";
            var oldConversationKey = await db.HashGetAsync(messageKey, "conversation_id");
            var newConversationKey = $"conversation:{newConversationId}:messages";

            try
            {
                await db.HashSetAsync(messageKey, new[] { new HashEntry("conversation_id", newConversationId) });

                if (!oldConversationKey.IsNull)
                {
                    await db.SortedSetRemoveAsync($"conversation:{oldConversationKey}:messages", messageId);
                }
                var createdAt = DateTime.Parse(await db.HashGetAsync(messageKey, "created_at"));
                await db.SortedSetAddAsync(newConversationKey, messageId, createdAt.ToUnixTimeSeconds());
                _logger.LogInformation("Updated message {MessageId} to conversation {NewConversationId}", messageId, newConversationId);
            }
            catch (RedisConnectionException ex)
            {
                _logger.LogError(ex, "Failed to update message {MessageId}", messageId);
                throw;
            }
        }

        public async Task AddUserConversationAsync(long userId, long conversationId)
        {
            var db = _redis.GetDatabase();
            var userKey = $"user:{userId}:conversations";

            try
            {
                await db.SetAddAsync(userKey, conversationId);
                _logger.LogInformation("Added conversation {ConversationId} to user {UserId}", conversationId, userId);
            }
            catch (RedisConnectionException ex)
            {
                _logger.LogError(ex, "Failed to add conversation {ConversationId} to user {UserId}", conversationId, userId);
                throw;
            }
        }

        public async Task PublishMessageAsync(MessageWithAttachment message)
        {
            var subscriber = _redis.GetSubscriber();
            try
            {
                var messageJson = JsonSerializer.Serialize(message, _jsonOptions);
                await subscriber.PublishAsync($"conversation:{message.Message.conversation_id}", messageJson);
                _logger.LogInformation("Published message to channel conversation:{ConversationId}", message.Message.conversation_id);
            }
            catch (RedisConnectionException ex)
            {
                _logger.LogError(ex, "Failed to publish message to conversation {ConversationId}", message.Message.conversation_id);
                throw;
            }
        }

        public async Task<List<MessageWithAttachment>> GetMessagesAsync(long conversationId, DateTime? fromDate = null, long limit = 50)
        {
            var db = _redis.GetDatabase();
            var conversationKey = $"conversation:{conversationId}:messages";
            var messages = new List<MessageWithAttachment>();

            try
            {
                // Kiểm tra key tồn tại và đúng loại
                var keyType = await db.KeyTypeAsync(conversationKey);
                if (keyType != RedisType.SortedSet && keyType != RedisType.None)
                {
                    _logger.LogWarning("Redis key {ConversationKey} is not a SortedSet. Deleting key.", conversationKey);
                    await db.KeyDeleteAsync(conversationKey);
                }

                // Lấy message_id từ Sorted Set
                RedisValue[] messageIds;
                if (fromDate.HasValue)
                {
                    var maxScore = fromDate.Value.ToUnixTimeSeconds();
                    messageIds = await db.SortedSetRangeByScoreAsync(conversationKey, double.NegativeInfinity, maxScore, Exclude.None, Order.Descending, 0, limit);
                }
                else
                {
                    messageIds = await db.SortedSetRangeByRankAsync(conversationKey, 0, limit - 1, Order.Descending);
                }

                // Lấy chi tiết tin nhắn từ Hash
                foreach (var messageId in messageIds)
                {
                    var hash = await db.HashGetAllAsync($"message:{messageId}");
                    if (hash.Length == 0) continue;

                    var message = new MessageDTOForAttachment
                    {
                        id = (int)long.Parse(messageId),
                        conversation_id = (int)long.Parse(hash.FirstOrDefault(h => h.Name == "conversation_id").Value),
                        sender_id = (int)long.Parse(hash.FirstOrDefault(h => h.Name == "sender_id").Value),
                        content = hash.FirstOrDefault(h => h.Name == "content").Value,
                        created_at = DateTime.Parse(hash.FirstOrDefault(h => h.Name == "created_at").Value),
                        isFile = hash.FirstOrDefault(h => h.Name == "isFile").Value == "1",
                        type = hash.FirstOrDefault(h => h.Name == "type").Value
                    };

                    AttachmentDTOForAttachment attachment = null;
                    var fileId = hash.FirstOrDefault(h => h.Name == "file_id").Value;
                    if (!string.IsNullOrEmpty(fileId) && long.TryParse(fileId, out var attachmentId))
                    {
                        attachment = new AttachmentDTOForAttachment
                        {
                            id = (int)attachmentId,
                            file_url = hash.FirstOrDefault(h => h.Name == "file_url").Value,
                            fileSize = long.TryParse(hash.FirstOrDefault(h => h.Name == "fileSize").Value, out var size) ? size : 0,
                            file_type = hash.FirstOrDefault(h => h.Name == "file_type").Value,
                            uploaded_at = DateTime.TryParse(hash.FirstOrDefault(h => h.Name == "uploaded_at").Value, out var uploadedAt) ? uploadedAt : DateTime.MinValue,
                            is_temporary = bool.TryParse(hash.FirstOrDefault(h => h.Name == "is_temporary").Value, out var isTemp) && isTemp,
                            message_id = (int?)long.Parse(messageId)
                        };
                    }

                    messages.Add(new MessageWithAttachment
                    {
                        Message = message,
                        Attachment = attachment
                    });
                }

                _logger.LogInformation("Retrieved {MessageCount} messages from Redis for conversation {ConversationId}", messages.Count, conversationId);
                return messages;
            }
            catch (RedisConnectionException ex)
            {
                _logger.LogError(ex, "Failed to retrieve messages from Redis for conversation {ConversationId}", conversationId);
                throw;
            }
        }
        public async Task UpdateMessageRecallAsync(long messageId, long conversationId)
        {
            var db = _redis.GetDatabase();
            var messageKey = $"message:{messageId}";

            try
            {
                if (!await db.KeyExistsAsync(messageKey))
                {
                    _logger.LogWarning("Message {MessageId} not found in Redis", messageId);
                    return;
                }

                // Lấy thông tin tin nhắn hiện tại
                var hash = await db.HashGetAllAsync(messageKey);
                var message = new MessageDTOForAttachment
                {
                    id = (int)messageId,
                    conversation_id = (int)long.Parse(hash.FirstOrDefault(h => h.Name == "conversation_id").Value),
                    sender_id = (int)long.Parse(hash.FirstOrDefault(h => h.Name == "sender_id").Value),
                    content = "tin nhắn đã được thu hồi",
                    created_at = DateTime.Parse(hash.FirstOrDefault(h => h.Name == "created_at").Value),
                    isFile = hash.FirstOrDefault(h => h.Name == "isFile").Value == "1",
                    type = hash.FirstOrDefault(h => h.Name == "type").Value,
                    isRecalled = true
                };

                // Cập nhật content và isRecalled
                await db.HashSetAsync(messageKey, new[]
                {
                    new HashEntry("content", message.content),
                    new HashEntry("isRecalled", "1")
                });
                _logger.LogInformation("Updated message {MessageId} to recalled with content 'tin nhắn đã được thu hồi' in Redis", messageId);

                // Publish tin nhắn đã cập nhật
                var updatedMessage = new MessageWithAttachment
                {
                    Message = message,
                    Attachment = hash.Any(h => h.Name == "file_id" && !string.IsNullOrEmpty(h.Value))
                        ? new AttachmentDTOForAttachment
                        {
                            id = (int)long.Parse(hash.FirstOrDefault(h => h.Name == "file_id").Value),
                            file_url = hash.FirstOrDefault(h => h.Name == "file_url").Value,
                            fileSize = long.TryParse(hash.FirstOrDefault(h => h.Name == "fileSize").Value, out var size) ? size : 0,
                            file_type = hash.FirstOrDefault(h => h.Name == "file_type").Value,
                            uploaded_at = DateTime.TryParse(hash.FirstOrDefault(h => h.Name == "uploaded_at").Value, out var uploadedAt) ? uploadedAt : DateTime.MinValue,
                            is_temporary = bool.TryParse(hash.FirstOrDefault(h => h.Name == "is_temporary").Value, out var isTemp) && isTemp,
                            message_id = (int?)messageId
                        }
                        : null
                };
                await PublishMessageAsync(updatedMessage);
            }
            catch (RedisConnectionException ex)
            {
                _logger.LogError(ex, "Failed to update recall status for message {MessageId}", messageId);
                throw;
            }
        }

        public async Task DeleteMessageAsync(int conversation_id, int user_id)
        {
            var db = _redis.GetDatabase(); ;
            var conversationKey = $"conversation:{conversation_id}:messages";
            try
            {
                // Lấy tất cả message IDs từ Sorted Set của cuộc hội thoại
                var messageIds = await db.SortedSetRangeByRankAsync(conversationKey);
                // Xóa từng tin nhắn theo ID
                foreach (var messageId in messageIds)
                {
                    var messageKey = $"message:{messageId}";
                    await db.KeyDeleteAsync(messageKey);
                    _logger.LogInformation("Deleted message {MessageId} from Redis", messageId);

                    // Xóa Sorted Set của cuộc hội thoại
                    await db.KeyDeleteAsync(conversationKey);
                    _logger.LogInformation("Deleted all messages for conversation {ConversationId} from Redis", conversation_id);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to delete messages for conversation {ConversationId} from Redis", conversation_id);
                throw;
            }
        }
    }
    public static class DateTimeExtensions
    {
        public static long ToUnixTimeSeconds(this DateTime dateTime)
        {
            return (long)(dateTime.ToUniversalTime() - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalSeconds;
        }
    }
}