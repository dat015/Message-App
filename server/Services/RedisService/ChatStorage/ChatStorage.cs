using System;
using System.Collections.Generic;
using System.Drawing.Printing;
using System.Globalization;
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
        private readonly IDatabase _redisDatabase;

        private static readonly JsonSerializerOptions _jsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        public ChatStorage(IConnectionMultiplexer redis, ILogger<ChatStorage> logger, IDatabase redisDatabase)
        {
            _redis = redis;
            _logger = logger;
            _redisDatabase = redisDatabase;

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
                    new HashEntry("id", message.id),
                    new HashEntry("conversation_id", message.conversation_id),
                    new HashEntry("sender_id", message.sender_id),
                    new HashEntry("content", message.content ?? ""),
                    new HashEntry("created_at", message.created_at.ToString("O")),
                    new HashEntry("isFile", message.isFile ? "true" : "false"),
                    new HashEntry("type", message.type ?? ""),
                    new HashEntry("is_read", message.is_read ? "true" : "false"), // Thêm is_read
                    new HashEntry("isrecalled", message.isRecalled ? "true" : "false"), // Thêm isRecalled
                    new HashEntry("file_id", attachment?.id.ToString() ?? ""),
                    new HashEntry("file_url", attachment?.file_url ?? ""),
                    new HashEntry("fileSize", attachment?.fileSize.ToString() ?? ""),
                    new HashEntry("file_type", attachment?.file_type ?? ""),
                    new HashEntry("uploaded_at", attachment?.uploaded_at.ToString("O") ?? ""),
                    new HashEntry("is_temporary", attachment?.is_temporary == true ? "true" : "false"),
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

        public async Task<List<MessageWithAttachment>> GetMessagesAsync(long conversationId, int user_id, DateTime? fromDate = null, long limit = 50)
        {
            try
            {
                var messagesKey = $"conversation:{conversationId}:messages";
                var clearedAtKey = $"user:{user_id}:conversation:{conversationId}:cleared_at";

                // Lấy cleared_at từ Redis (nếu có)
                long? clearedAtTimestamp = null;
                var clearedAtValue = await _redisDatabase.StringGetAsync(clearedAtKey);
                if (clearedAtValue.HasValue)
                {
                    clearedAtTimestamp = long.Parse(clearedAtValue);
                }

                // Lấy danh sách message_id từ Sorted Set
                var messageIds = await _redisDatabase.SortedSetRangeByRankWithScoresAsync(
                    messagesKey,
                    0,
                    -1,
                    Order.Descending
                );

                var messages = new List<MessageWithAttachment>();
                foreach (var entry in messageIds)
                {
                    var messageId = (int)entry.Element;
                    var messageTimestamp = entry.Score; // Unix timestamp của created_at

                    // Bỏ qua tin nhắn nếu nó trước cleared_at
                    if (clearedAtTimestamp.HasValue && messageTimestamp <= clearedAtTimestamp.Value)
                    {
                        continue;
                    }

                    // Lọc thêm theo fromDate nếu có
                    if (fromDate.HasValue)
                    {
                        var messageDateTime = DateTimeOffset.FromUnixTimeSeconds((long)messageTimestamp).UtcDateTime;
                        if (messageDateTime > fromDate.Value)
                        {
                            continue;
                        }
                    }

                    // Lấy chi tiết tin nhắn
                    var messageKey = $"message:{messageId}";
                    var messageHash = await _redisDatabase.HashGetAllAsync(messageKey);
                    if (messageHash.Length == 0)
                    {
                        _logger.LogWarning("Message {MessageId} not found in Redis", messageId);
                        continue;
                    }

                    // Kiểm tra các trường bắt buộc
                    var idEntry = messageHash.FirstOrDefault(h => h.Name == "id");
                    var conversationIdEntry = messageHash.FirstOrDefault(h => h.Name == "conversation_id");
                    var senderIdEntry = messageHash.FirstOrDefault(h => h.Name == "sender_id");
                    var contentEntry = messageHash.FirstOrDefault(h => h.Name == "content");
                    var createdAtEntry = messageHash.FirstOrDefault(h => h.Name == "created_at");
                    var isFileEntry = messageHash.FirstOrDefault(h => h.Name == "isFile");
                    var typeEntry = messageHash.FirstOrDefault(h => h.Name == "type");
                    var isReadEntry = messageHash.FirstOrDefault(h => h.Name == "is_read");

                    // Kiểm tra các trường bắt buộc
                    if (!idEntry.Value.HasValue || !conversationIdEntry.Value.HasValue || !senderIdEntry.Value.HasValue ||
                        !contentEntry.Value.HasValue || !createdAtEntry.Value.HasValue || !isFileEntry.Value.HasValue ||
                        !typeEntry.Value.HasValue || !isReadEntry.Value.HasValue)
                    {
                        _logger.LogWarning("Message {MessageId} has missing required fields: id={Id}, conversation_id={ConvId}, sender_id={SenderId}, content={Content}, created_at={CreatedAt}, isFile={IsFile}, type={Type}, is_read={IsRead}",
                            messageId, idEntry.Value, conversationIdEntry.Value, senderIdEntry.Value, contentEntry.Value,
                            createdAtEntry.Value, isFileEntry.Value, typeEntry.Value, isReadEntry.Value);
                        continue;
                    }

                    // Hàm hỗ trợ để parse Boolean từ "0", "1", "true", "false"
                    bool ParseBoolean(string value, bool defaultValue = false)
                    {
                        if (string.IsNullOrEmpty(value)) return defaultValue;
                        if (value == "1" || value.Equals("true", StringComparison.OrdinalIgnoreCase)) return true;
                        if (value == "0" || value.Equals("false", StringComparison.OrdinalIgnoreCase)) return false;
                        _logger.LogWarning("Invalid boolean value '{Value}' for message {MessageId}", value, messageId);
                        return defaultValue;
                    }

                    // Parse created_at với DateTimeOffset để hỗ trợ ISO 8601
                    DateTime createdAt;
                    if (!DateTimeOffset.TryParse(createdAtEntry.Value, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var dateTimeOffset))
                    {
                        _logger.LogWarning("Invalid created_at format '{Value}' for message {MessageId}", createdAtEntry.Value, messageId);
                        continue;
                    }
                    createdAt = dateTimeOffset.UtcDateTime;

                    var message = new MessageDTOForAttachment
                    {
                        id = int.TryParse(idEntry.Value, out var id) ? id : 0,
                        conversation_id = int.TryParse(conversationIdEntry.Value, out var convId) ? convId : 0,
                        sender_id = int.TryParse(senderIdEntry.Value, out var senderId) ? senderId : 0,
                        content = contentEntry.Value,
                        created_at = createdAt,
                        isFile = ParseBoolean(isFileEntry.Value, false),
                        type = typeEntry.Value,
                        is_read = ParseBoolean(isReadEntry.Value, false),
                        isRecalled = ParseBoolean(messageHash.FirstOrDefault(h => h.Name == "isrecalled").Value, false)
                    };

                    // Kiểm tra dữ liệu hợp lệ
                    if (message.id == 0 || message.conversation_id == 0 || message.sender_id == 0 || message.created_at == DateTime.MinValue)
                    {
                        _logger.LogWarning("Message {MessageId} has invalid data: id={Id}, conversation_id={ConvId}, sender_id={SenderId}, created_at={CreatedAt}",
                            messageId, message.id, message.conversation_id, message.sender_id, message.created_at);
                        continue;
                    }

                    AttachmentDTOForAttachment attachment = null;
                    var fileId = messageHash.FirstOrDefault(h => h.Name == "file_id").Value;
                    if (!string.IsNullOrEmpty(fileId) && long.TryParse(fileId, out var attachmentId))
                    {
                        var uploadedAt = DateTime.MinValue;
                        var uploadedAtValue = messageHash.FirstOrDefault(h => h.Name == "uploaded_at").Value;
                        if (!string.IsNullOrEmpty(uploadedAtValue))
                        {
                            if (DateTimeOffset.TryParse(uploadedAtValue, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var uploadedDateTimeOffset))
                            {
                                uploadedAt = uploadedDateTimeOffset.UtcDateTime;
                            }
                            else
                            {
                                _logger.LogWarning("Invalid uploaded_at format '{Value}' for message {MessageId}", uploadedAtValue, messageId);
                            }
                        }

                        attachment = new AttachmentDTOForAttachment
                        {
                            id = (int)attachmentId,
                            file_url = messageHash.FirstOrDefault(h => h.Name == "file_url").Value ,
                            fileSize = long.TryParse(messageHash.FirstOrDefault(h => h.Name == "fileSize").Value, out var size) ? size : 0,
                            file_type = messageHash.FirstOrDefault(h => h.Name == "file_type").Value ,
                            uploaded_at = uploadedAt,
                            is_temporary = ParseBoolean(messageHash.FirstOrDefault(h => h.Name == "is_temporary").Value, false),
                            message_id = message.id
                        };
                    }

                    messages.Add(new MessageWithAttachment
                    {
                        Message = message,
                        Attachment = attachment
                    });
                }

                _logger.LogInformation("Retrieved {MessageCount} messages from Redis for conversation {ConversationId}", messages.Count, conversationId);
                return messages.OrderByDescending(m => m.Message.created_at).Take((int)limit).ToList();
            }
            catch (RedisConnectionException ex)
            {
                _logger.LogError(ex, "Failed to retrieve messages from Redis for conversation {ConversationId}", conversationId);
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing messages for conversation {ConversationId}", conversationId);
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