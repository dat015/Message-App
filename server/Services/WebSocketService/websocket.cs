using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Threading.Channels;
using System.Threading.Tasks;
using CloudinaryDotNet;
using Microsoft.EntityFrameworkCore;
using server.Data;
using server.DTO;
using server.Models;
using server.Services.ConversationService;
using server.Services.RedisService.ChatStorage;
using server.Services.RedisService.ConversationStorage;
using server.Services.UploadService;
using StackExchange.Redis;

namespace server.Services.WebSocketService
{
    public class WebSocketOptions
    {
        public int MaxBufferSize { get; set; } = 1024 * 4; // Kích thước bộ đệm tối đa mặc định (4KB)
        public int HeartbeatInterval { get; set; } = 30; // Khoảng thời gian gửi heartbeat (giây)
    }

    public class Client
    {
        public WebSocket WebSocket { get; set; }
        public int UserId { get; set; }
        public HashSet<int> ConversationIds { get; set; } = new HashSet<int>();// Danh sách ID các cuộc hội thoại client tham gia
        // Track active Redis subscriptions
        public ConcurrentDictionary<int, ChannelMessageQueue> ActiveSubscriptions { get; }
            = new ConcurrentDictionary<int, ChannelMessageQueue>();
    }


    public class webSocket : IDisposable
    {
        private readonly ConcurrentDictionary<Client, bool> _clients = new();// Danh sách client đang kết nối, thread-safe
        private readonly IConnectionMultiplexer _redis;
        private readonly IServiceProvider _serviceProvider;
        private readonly IConversation _conversation;
        private readonly WebSocketOptions _options;          // Cấu hình tùy chọn
        private readonly CancellationTokenSource _cts = new(); // Token để hủy các tác vụ bất đồng bộ
        private readonly ILogger<webSocket> _logger;
        private readonly IChatStorage _chatStorage;
        private readonly IConversationStorage _conversationStorage;
        private readonly CallHandler _callHandler;

        public webSocket(IConnectionMultiplexer redis, IServiceProvider serviceProvider,
                         IChatStorage chatStorage,
                            IConversationStorage conversation,
                         WebSocketOptions options = null,
                         ILogger<webSocket> logger = null)
        {
            _redis = redis ?? throw new ArgumentNullException(nameof(redis));              // Redis không được null
            _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider)); // Service provider không được null
            _options = options ?? new WebSocketOptions();                                 // Sử dụng cấu hình mặc định nếu không cung cấp
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _chatStorage = chatStorage;
            _callHandler = new CallHandler(_redis.GetDatabase(), this);
            _conversationStorage = conversation;
        }
        public IEnumerable<Client> GetClientsInConversation(int conversationId)
        {
            var clients = _clients.Keys
                .Where(c => c.ConversationIds.Contains(conversationId) && c.WebSocket.State == WebSocketState.Open)
                .ToList();
            Console.WriteLine($"GetClientsInConversation {conversationId}: Found {clients.Count} clients: {string.Join(", ", clients.Select(c => c.UserId))}");
            return clients;
        }
        public Client GetClient(int userId)
        {
            var client = _clients.Keys.FirstOrDefault(c => c.UserId == userId && c.WebSocket.State == WebSocketState.Open);
            Console.WriteLine($"GetClient {userId}: {(client != null ? "Found" : "Not found")}");
            return client;
        }
        public async Task ConnectUserToConversationChanelAsync(int userId, int conversationId)
        {
            var subscriber = _redis.GetSubscriber();
            var client = GetClient(userId);
            if (client == null)
            {
                _logger.LogWarning($"Client {userId} not found");
                return;
            }

            string channel = $"conversation:{conversationId}";

            // Check if already subscribed
            if (client.ActiveSubscriptions.ContainsKey(conversationId))
            {
                _logger.LogInformation($"User {userId} already subscribed to channel {channel}");
                return;
            }

            try
            {
                // Subscribe and store the ChannelMessageQueue
                var queue = await subscriber.SubscribeAsync(channel);
                client.ActiveSubscriptions[conversationId] = queue;

                queue.OnMessage(async channelMessage =>
                {
                    if (client.WebSocket.State == WebSocketState.Open)
                    {
                        var msg = JsonSerializer.Deserialize<Message>(channelMessage.Message);
                        if (msg.sender_id != client.UserId)
                        {
                            var bytes = Encoding.UTF8.GetBytes(channelMessage.Message);
                            await client.WebSocket.SendAsync(
                                new ArraySegment<byte>(bytes),
                                WebSocketMessageType.Text,
                                true,
                                CancellationToken.None);
                        }
                    }
                });

                client.ConversationIds.Add(conversationId);
                _logger.LogInformation($"User {userId} subscribed to channel {channel}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error subscribing user {userId} to channel {channel}");
                throw;
            }
        }
        public async Task UnsubscribeUserFromConversationChannelAsync(int userId, int conversationId)
        {
            var subscriber = _redis.GetSubscriber();
            var clients = _clients.Keys.Where(c => c.UserId == userId && c.WebSocket.State == WebSocketState.Open).ToList();

            if (!clients.Any())
            {
                _logger.LogWarning($"No active clients found for user {userId}");
                return;
            }

            string channelName = $"conversation:{conversationId}";
            var redisChannel = new RedisChannel(channelName, RedisChannel.PatternMode.Literal);

            foreach (var client in clients)
            {
                try
                {
                    // Remove from conversation tracking
                    client.ConversationIds.Remove(conversationId);

                    // Unsubscribe from Redis if we have an active subscription
                    if (client.ActiveSubscriptions.TryRemove(conversationId, out var queue))
                    {
                        // Proper way to unsubscribe using the ChannelMessageQueue
                        await queue.UnsubscribeAsync();

                        // Alternative if you prefer to use the channel directly:
                        // await subscriber.UnsubscribeAsync(redisChannel);

                        _logger.LogInformation($"Unsubscribed user {userId} from channel {channelName}");
                    }
                    else
                    {
                        _logger.LogWarning($"No active subscription found for user {userId} on channel {channelName}");
                    }

                    // Close WebSocket if no subscriptions remain
                    if (!client.ConversationIds.Any() && client.WebSocket.State == WebSocketState.Open)
                    {
                        await client.WebSocket.CloseAsync(
                            WebSocketCloseStatus.NormalClosure,
                            "No active subscriptions",
                            CancellationToken.None);
                        _logger.LogInformation($"Closed WebSocket for user {userId}");
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Error unsubscribing user {userId} from channel {channelName}");
                }
            }
        }
        // Xử lý yêu cầu WebSocket từ client
        public async Task HandleWebSocket(HttpContext context)
        {
            if (!context.WebSockets.IsWebSocketRequest) // kiểm tra xem có phải là websocket không
            {
                context.Response.StatusCode = StatusCodes.Status400BadRequest;
                return;
            }

            var webSocket = await context.WebSockets.AcceptWebSocketAsync();
            var client = new Client { WebSocket = webSocket };

            _clients.TryAdd(client, true);

            Console.WriteLine($"New client connected. Total clients: {_clients.Count}, Remote: {context.Connection.RemoteIpAddress}");

            //"_" là 1 biến bỏ qua (discard) 
            _ = StartHeartbeat(client);// Bắt đầu gửi heartbeat để duy trì kết nối (chạy nền)
            await Receiver(client);

            await CleanupClient(client);// Dọn dẹp khi client ngắt kết nối
            _clients.TryRemove(client, out _);// Xóa client khỏi danh sách
            Console.WriteLine($"Client disconnected: {context.Connection.RemoteIpAddress}");
            await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Connection closed", CancellationToken.None);
        }

        private async Task Receiver(Client client)
        {
            var buffer = new byte[_options.MaxBufferSize]; // bộ đệm để nhận dữ liệu
            while (client.WebSocket.State == WebSocketState.Open)
            {
                var receivedBytes = new List<byte>();
                WebSocketReceiveResult result;
                do // Nhận toàn bộ tin nhắn (có thể nhiều phần)
                {
                    result = await client.WebSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
                    receivedBytes.AddRange(buffer.Take(result.Count));
                } while (!result.EndOfMessage);

                if (result.CloseStatus.HasValue) break;// Thoát nếu client đóng kết nối

                var messageJson = Encoding.UTF8.GetString(receivedBytes.ToArray());
                Console.WriteLine($"Received: {messageJson}");

                try
                {
                    var message = JsonSerializer.Deserialize<MessageDTO>(messageJson, new JsonSerializerOptions
                    {
                        PropertyNameCaseInsensitive = true // Không phân biệt hoa thường trong tên thuộc tính
                    });

                    if (IsValidMessage(message))
                    {
                        if (message.type == "bootup")// Xử lý khi client khởi động
                        {
                            await HandleBootup(client, message);
                        }
                        else if (message.type == "startCall" ||
                         message.type == "acceptCall" ||
                         message.type == "offer" ||
                         message.type == "answer" ||
                         message.type == "iceCandidate" ||
                         message.type == "endCall")
                        {
                            await _callHandler.HandleCallMessage(client, message);
                        }
                        else if (!string.IsNullOrEmpty(message.content))// Xử lý tin nhắn bình thường
                        {
                            await HandleMessage(client, message);
                        }
                        else if (message.type == "system_addMember")// Xử lý thêm thành viên vào nhóm
                        {
                            var userId = message.sender_id;
                            var conversationId = message.conversation_id;
                            await AddMemberToConversation(conversationId, userId);
                        }
                        else if (message.type == "ping")// Xử lý heartbeat từ client
                        {
                            Console.WriteLine($"Received ping from client {client.UserId}");
                        }
                        else
                        {
                            Console.WriteLine($"Unknown message type: {message.type}");
                        }

                    }
                }
                catch (JsonException ex)
                {
                    Console.WriteLine($"Error deserializing message: {ex.Message}");
                    break; // Thoát vòng lặp nếu có lỗi nghiêm trọng
                }
            }
        }

        private bool IsValidMessage(MessageDTO message)
        {
            return message != null &&
                   !string.IsNullOrEmpty(message.type) &&
                   message.sender_id > 0 &&
                   message.conversation_id >= 0;
        }
        private Client GetClientByUserId(int userId)
        {
            return _clients.Keys.FirstOrDefault(c => c.UserId == userId && c.WebSocket.State == WebSocketState.Open);
        }


        private async Task HandleBootup(Client client, MessageDTO message)
        {
            client.UserId = message.sender_id;

            // Handle duplicate connections
            var existingClient = GetClientByUserId(client.UserId);
            if (existingClient != null && existingClient != client)
            {
                await existingClient.WebSocket.CloseAsync(
                    WebSocketCloseStatus.PolicyViolation,
                    "Another connection opened",
                    CancellationToken.None);
                _clients.TryRemove(existingClient, out _);
            }

            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

            var conversationIds = await dbContext.Participants
                .Where(p => p.user_id == client.UserId && !p.is_deleted)
                .Select(p => p.conversation_id)
                .ToListAsync();

            client.ConversationIds = new HashSet<int>(conversationIds);

            // Subscribe to all conversations
            foreach (var conversationId in client.ConversationIds)
            {
                await ConnectUserToConversationChanelAsync(client.UserId, conversationId);
            }
        }
        private async Task AddMemberToConversation(int conversationId, int userId)
        {
            using var scope = _serviceProvider.CreateScope();
            var conversationSV = scope.ServiceProvider.GetRequiredService<IConversation>();

            var participant = await conversationSV.AddMemberToGroup(conversationId, userId);
            if (participant == null)
            {
                throw new Exception($"Failed to add user {userId} to conversation {conversationId}");
            }

            var notification = new MessageDTOForAttachment
            {
                id = 0,
                type = "system",
                content = $"User {participant.name} has been added to the group.",
                sender_id = userId,
                conversation_id = conversationId,
                created_at = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time"))
            };
            var message = new MessageWithAttachment
            {
                Message = notification,
                Attachment = null
            };
            await _chatStorage.PublishMessageAsync(message);
        }
        private async Task HandleMessage(Client client, MessageDTO message)
        {
            _logger.LogInformation("Handling message from user {UserId}: {Content}", message.sender_id, message.content);
            message.created_at = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time"));

            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var conversation = await dbContext.Conversations.FindAsync(message.conversation_id);
            if (conversation == null)
            {
                _logger.LogWarning("Conversation with ID {ConversationId} not found", message.conversation_id);
                return;
            }

            using var transaction = await dbContext.Database.BeginTransactionAsync();
            try
            {
                var new_message = new Message
                {
                    type = message.type,
                    sender_id = message.sender_id,
                    conversation_id = message.conversation_id,
                    content = message.content,
                    created_at = message.created_at,
                    isFile = message.fileID != null
                };

                dbContext.Messages.Add(new_message);
                await dbContext.SaveChangesAsync();
                _logger.LogInformation("Message saved to DB with ID: {MessageId}", new_message.id);

                conversation.lastMessageTime = new_message.created_at;
                conversation.lastMessage = message.content;
                dbContext.Conversations.Update(conversation);

                Attachment existing_attachment = null;
                if (message.fileID != null)
                {
                    existing_attachment = await dbContext.Attachments.FindAsync(message.fileID);
                    if (existing_attachment == null)
                    {
                        _logger.LogWarning("Attachment with ID {FileId} not found", message.fileID);
                        await transaction.RollbackAsync();
                        return;
                    }

                    existing_attachment.message_id = new_message.id;
                    existing_attachment.is_temporary = false;
                    dbContext.Attachments.Update(existing_attachment);
                }

                await dbContext.SaveChangesAsync();
                await transaction.CommitAsync();
                _logger.LogInformation("Transaction committed for message: {MessageId}", new_message.id);

                // Lấy danh sách participantIds từ database
                var participantIds = await dbContext.Participants
                    .Where(p => p.conversation_id == conversation.id && !p.is_deleted)
                    .Select(p => p.user_id)
                    .ToListAsync();

                // Cập nhật lastMessage và lastMessageTime trong Redis
                // bool isSaved = await _conversationStorage.UpdateConversationAsync(conversation.id, conversation.lastMessage, conversation.lastMessageTime ?? DateTime.UtcNow, participantIds);
                // if (!isSaved)
                // {
                //     _logger.LogWarning("Failed to update conversation in Redis for conversation ID: {ConversationId}", conversation.id);
                //     return;
                // }
                var messageDTO = new MessageDTOForAttachment
                {
                    id = new_message.id,
                    content = new_message.content,
                    sender_id = new_message.sender_id,
                    is_read = new_message.is_read,
                    type = new_message.type,
                    isFile = new_message.isFile,
                    created_at = new_message.created_at,
                    conversation_id = new_message.conversation_id,
                    isRecalled = new_message.isRecalled
                };

                AttachmentDTOForAttachment attachmentDTO = null;
                if (existing_attachment != null)
                {
                    attachmentDTO = new AttachmentDTOForAttachment
                    {
                        id = existing_attachment.id,
                        file_url = existing_attachment.file_url,
                        fileSize = existing_attachment.FileSize,
                        file_type = existing_attachment.file_type,
                        uploaded_at = existing_attachment.uploaded_at,
                        is_temporary = existing_attachment.is_temporary,
                        message_id = existing_attachment.message_id
                    };
                }

                var messageWithAttachment = new MessageWithAttachment
                {
                    Message = messageDTO,
                    Attachment = attachmentDTO
                };

                // Lưu tin nhắn vào Redis
                await _chatStorage.SaveMessageAsync(messageDTO, attachmentDTO);

                if (message.type == "private" && message.content.Contains("recipient_id:"))
                {
                    int recipientId = ParseRecipentId(message.content);
                    if (recipientId <= 0)
                    {
                        _logger.LogWarning("Invalid recipient ID in private message");
                        return;
                    }

                    var box = _conversation.CreateConversation(new_message.sender_id, recipientId);
                    if (box != null && new_message.conversation_id != box.Id)
                    {
                        new_message.conversation_id = box.Id;
                        dbContext.Messages.Update(new_message);
                        await dbContext.SaveChangesAsync();

                        await _chatStorage.UpdateMessageConversationAsync(new_message.id, box.Id);
                        messageDTO.conversation_id = new_message.conversation_id;
                        messageWithAttachment.Message = messageDTO;

                        // Thêm user và recipient vào conversation mới
                        await _chatStorage.AddUserConversationAsync(new_message.sender_id, box.Id);
                        await _chatStorage.AddUserConversationAsync(recipientId, box.Id);
                    }

                    await HandlePrivateMessage(new_message, recipientId);
                }
                else
                {
                    await _chatStorage.PublishMessageAsync(messageWithAttachment);
                }
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "Transaction failed while handling message");
                throw;
            }
        }



        private int ParseRecipentId(string content)
        {
            try
            {
                var parts = content.Split("recipient_id:");
                if (parts.Length < 2) return -1;
                return int.Parse(parts[1].Split(",")[0]);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error parsing recipient_id: {ex.Message}");
                return -1;
            }
        }

        //nếu tin nhắn private thì dùng websocket để gửi
        private async Task HandlePrivateMessage(Message message, int recipientId)
        {
            var privateMessageJson = JsonSerializer.Serialize(message);
            foreach (var client in _clients.Keys)
            {
                if (client.UserId == message.sender_id || client.UserId == recipientId)
                {
                    if (client.WebSocket.State == WebSocketState.Open)
                    {
                        var bytes = Encoding.UTF8.GetBytes(privateMessageJson);
                        await client.WebSocket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None);
                        Console.WriteLine($"Sent private message to user {client.UserId}: {privateMessageJson}");
                    }
                }
            }
        }

        //nếu tin nhắn nhóm thì dùng redis để pub lên channel để các thành viên có thể nhận được
        public async Task PublishMessage(MessageWithAttachment message)
        {
            var subscriber = _redis.GetSubscriber();
            var messageJson = JsonSerializer.Serialize(message);
            await subscriber.PublishAsync($"conversation:{message.Message.conversation_id}", messageJson);
            Console.WriteLine($"Published to channel conversation:{message.Message.conversation_id}: {messageJson}");
        }

        private async Task CleanupClient(Client client)
        {
            var subscriber = _redis.GetSubscriber();
            var db = _redis.GetDatabase();
            foreach (var conversationId in client.ConversationIds)
            {
                await subscriber.UnsubscribeAsync($"conversation:{conversationId}");
                var callDataJson = await db.StringGetAsync($"call:{conversationId}");
                if (!callDataJson.IsNullOrEmpty)
                {
                    var callMessage = new MessageDTO
                    {
                        type = "endCall",
                        sender_id = client.UserId,
                        conversation_id = conversationId
                    };
                    await _callHandler.HandleCallMessage(client, callMessage);
                }
            }
            _clients.TryRemove(client, out _);
        }

        // Gửi heartbeat định kỳ để kiểm tra kết nối
        private async Task StartHeartbeat(Client client)
        {
            while (client.WebSocket.State == WebSocketState.Open)
            {
                try
                {
                    await Task.Delay(TimeSpan.FromSeconds(_options.HeartbeatInterval), _cts.Token);
                    await client.WebSocket.SendAsync(
                        new ArraySegment<byte>(Encoding.UTF8.GetBytes("ping")),
                        WebSocketMessageType.Text,
                        true,
                        _cts.Token
                    );
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Heartbeat error: {ex.Message}");
                    break;
                }
            }
        }

        private async Task ReconnectClient(Client client)
        {
            // Logic reconnect
        }

        // Giải phóng tài nguyên khi dịch vụ bị hủy
        public void Dispose()
        {
            _cts.Cancel(); // Hủy các tác vụ bất đồng bộ
            foreach (var client in _clients.Keys)
            {
                client.WebSocket?.Dispose(); // Đóng WebSocket
            }
            _clients.Clear(); // Xóa danh sách client
            _redis?.Dispose(); // Đóng kết nối Redis
        }

        public static implicit operator WebSocket(webSocket v)
        {
            throw new NotImplementedException();
        }
    }

}