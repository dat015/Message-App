using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using server.DTO;
using StackExchange.Redis;

namespace server.Services.RedisService.ConversationStorage
{
    public class ConversatonStorage : IConversationStorage
    {
        private readonly IConnectionMultiplexer _redis;
        private readonly ILogger<ConversatonStorage> _logger;
        private readonly IDatabase _redisDatabase;

        private static readonly JsonSerializerOptions _jsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };
        public ConversatonStorage(IConnectionMultiplexer redis, ILogger<ConversatonStorage> logger, IDatabase redisDatabase)
        {
            _redis = redis;
            _logger = logger;
            _redisDatabase = redisDatabase;

        }

        public Task<bool> DeleteMemberAsync(int conversationId, int memberId)
        {
            throw new NotImplementedException();

        }

        public async Task<bool> DeleteConversationByUserAsync(int conversationId, int userId)
        {
            try
            {
                var db = _redis.GetDatabase();
                var conversationUserKey = $"user:{userId}:conversations";
                var conversationDeleteKey = $"User:{userId}:conversation:{conversationId}";
                var conversationMessagesKey = $"conversation:{conversationId}:messages";
                var conversationChannel = $"conversation:{conversationId}";

                // Kiểm tra xem nhóm có tồn tại
                if (!await db.KeyExistsAsync(conversationMessagesKey))
                {
                    _logger.LogWarning("Cuộc trò chuyện {ConversationId} không tồn tại.", conversationId);
                    return false;
                }

                // Kiểm tra xem người dùng có trong nhóm
                if (!await db.SetContainsAsync(conversationUserKey, conversationId))
                {
                    _logger.LogInformation("Người dùng {UserId} không phải thành viên của nhóm {ConversationId}.", userId, conversationId);
                    return false;
                }

                // Xóa conversationId khỏi user:{userId}:conversations
                bool removed = await db.SetRemoveAsync(conversationUserKey, conversationId);

                // Xóa key lưu thông tin xóa tin nhắn
                await db.KeyDeleteAsync(conversationDeleteKey);

                return removed;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Lỗi khi xóa conversation khỏi Redis: {ex.Message}");
                return false;
            }
        }

        public async Task<bool> AddNewConversationAsync(int conversationId, List<int> members)
        {
            try
            {
                var db = _redis.GetDatabase();

                // Kiểm tra xem conversationId đã tồn tại
                var conversationMessagesKey = $"conversation:{conversationId}:messages";
                if (await db.KeyExistsAsync(conversationMessagesKey))
                {
                    _logger.LogWarning("Cuộc trò chuyện {ConversationId} đã tồn tại.", conversationId);
                    return false;
                }

                // Sử dụng transaction để đảm bảo tính nhất quán
                var transaction = db.CreateTransaction();

                // Thêm conversationId vào user:{user_id}:conversations cho từng thành viên
                foreach (var memberId in members)
                {
                    var conversationUserKey = $"user:{memberId}:conversations";
                    await transaction.SetAddAsync(conversationUserKey, conversationId);
                    // Lưu ý: Không khởi tạo User:{user_id}:conversation:{conversation_id} trừ khi cần
                }

                // Khởi tạo conversation:{conversation_id}:messages là Sorted Set rỗng
                // (Không cần tạo trước nếu SaveMessageAsync sẽ xử lý)

                // Lưu danh sách thành viên (nếu cần, ví dụ trong Set)
                var conversationMembersKey = $"conversation:{conversationId}:members";
                foreach (var memberId in members)
                {
                    await transaction.SetAddAsync(conversationMembersKey, memberId);
                }

                // Thực thi transaction
                bool committed = await transaction.ExecuteAsync();
                if (!committed)
                {
                    _logger.LogError("Không thể thực thi transaction khi tạo cuộc trò chuyện {ConversationId}.", conversationId);
                    return false;
                }

                // // Thông báo tạo conversation qua Pub/Sub
                // var conversationChannel = $"conversation:{conversationId}";
                // var systemMessage = new
                // {
                //     type = "system",
                //     content = $"Cuộc trò chuyện {conversationId} đã được tạo.",
                //     conversation_id = conversationId,
                //     created_at = DateTimeOffset.UtcNow.ToUnixTimeSeconds()
                // };
                // await db.PublishAsync(conversationChannel, System.Text.Json.JsonSerializer.Serialize(systemMessage));

                _logger.LogInformation("Tạo cuộc trò chuyện {ConversationId} với {MemberCount} thành viên: Thành công.",
                    conversationId, members.Count);

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tạo cuộc trò chuyện {ConversationId}.", conversationId);
                return false;
            }
        }

        public async Task<bool> UpdateConversationAsync(int conversationId, string lastMessage, DateTime lastMessageTime, List<int> memberIds)
        {
            try
            {
                var db = _redis.GetDatabase();

                if (memberIds == null || memberIds.Count == 0)
                {
                    _logger.LogWarning("Danh sách thành viên cho cuộc trò chuyện {ConversationId} rỗng.", conversationId);
                    return false;
                }

                var transaction = db.CreateTransaction();
                var updatedKeys = new List<string>();

                foreach (var userId in memberIds)
                {
                    string conversationKey = $"conversation:{userId}";
                    updatedKeys.Add(conversationKey);

                    var dataCache = await db.StringGetAsync(conversationKey);
                    List<ConversationDto> conversations;

                    if (!dataCache.IsNullOrEmpty)
                    {
                        conversations = JsonSerializer.Deserialize<List<ConversationDto>>(dataCache, _jsonOptions) ?? new List<ConversationDto>();
                        var targetConversation = conversations.FirstOrDefault(c => c.Id == conversationId);
                        if (targetConversation != null)
                        {
                            targetConversation.LastMessage = lastMessage;
                            targetConversation.LastMessageTime = lastMessageTime;
                            targetConversation.LastMessageSender = null; // Giữ null như dữ liệu mẫu
                        }
                        else
                        {
                            _logger.LogWarning("Cuộc trò chuyện {ConversationId} không có trong cache của user {UserId}.", conversationId, userId);
                            continue;
                        }
                    }
                    else
                    {
                        _logger.LogWarning("Không tìm thấy cache cho user {UserId}.", userId);
                        continue;
                    }

                    var conversationsJson = JsonSerializer.Serialize(conversations, _jsonOptions);
                    await transaction.StringSetAsync(conversationKey, conversationsJson, TimeSpan.FromHours(24));
                }

                bool committed = await transaction.ExecuteAsync();
                if (!committed)
                {
                    _logger.LogError("Không thể thực thi transaction khi cập nhật cuộc trò chuyện {ConversationId}.", conversationId);
                    return false;
                }

                _logger.LogInformation("Cập nhật lastMessage cho cuộc trò chuyện {ConversationId} thành công. Keys cập nhật: {UpdatedKeys}.",
                    conversationId, string.Join(", ", updatedKeys));
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật cuộc trò chuyện {ConversationId}.", conversationId);
                return false;
            }
        }
    }

}