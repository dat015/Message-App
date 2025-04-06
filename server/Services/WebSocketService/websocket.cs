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
    }


    public class webSocket : IDisposable
    {
        private readonly ConcurrentDictionary<Client, bool> _clients = new();// Danh sách client đang kết nối, thread-safe
        private readonly IConnectionMultiplexer _redis;
        private readonly IServiceProvider _serviceProvider;
        private readonly IConversation _conversation;
        private readonly WebSocketOptions _options;          // Cấu hình tùy chọn
        private readonly CancellationTokenSource _cts = new(); // Token để hủy các tác vụ bất đồng bộ
        private readonly Cloudinary _cloudinary;
        private readonly ILogger<webSocket> _logger;
        public webSocket(IConnectionMultiplexer redis, IServiceProvider serviceProvider, WebSocketOptions options = null, ILogger<webSocket> logger = null)
        {
            _redis = redis ?? throw new ArgumentNullException(nameof(redis));              // Redis không được null
            _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider)); // Service provider không được null
            _options = options ?? new WebSocketOptions();                                 // Sử dụng cấu hình mặc định nếu không cung cấp
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
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
                        else if (!string.IsNullOrEmpty(message.content))// Xử lý tin nhắn bình thường
                        {
                            await HandleMessage(client, message);
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
                   message.conversation_id > 0;
        }

        private async Task HandleBootup(Client client, MessageDTO message)
        {
            client.UserId = message.sender_id;
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            // Lấy conversation_ids từ database
            var conversationIds = await dbContext.Participants
                .Where(p => p.user_id == client.UserId && !p.is_deleted)
                .Select(p => p.conversation_id)
                .ToListAsync();

            client.ConversationIds = new HashSet<int>(conversationIds);
            Console.WriteLine($"Client mapped with user_id: {client.UserId}, Conversations: {string.Join(",", client.ConversationIds)}");

            var subscriber = _redis.GetSubscriber();
            var db = _redis.GetDatabase();
            foreach (var conversationId in client.ConversationIds)
            {
                // Đồng bộ dữ liệu từ DB lên Redis nếu Redis không có
                var recentKey = $"conversation:{conversationId}:recent";
                if (!await db.KeyExistsAsync(recentKey))
                {
                    var messages = await dbContext.Messages
                        .Where(m => m.conversation_id == conversationId)
                        .OrderByDescending(m => m.created_at)
                        .Take(50)
                        .ToListAsync();

                    var messagesJson = JsonSerializer.Serialize(messages);
                    await db.StringSetAsync(recentKey, messagesJson, TimeSpan.FromHours(24));// Lưu vào Redis với TTL 24h
                }

                try
                {
                    // Subscribe client vào kênh Redis để nhận tin nhắn real-time
                    await subscriber.SubscribeAsync($"conversation:{conversationId}", async (channel, value) =>
                    {
                        if (client.WebSocket.State == WebSocketState.Open)
                        {
                            var msg = JsonSerializer.Deserialize<Message>(value);
                            if (msg.sender_id != client.UserId) // Ngăn chặn vòng lặp vô hạn, Không gửi lại tin nhắn của chính client
                            {
                                var bytes = Encoding.UTF8.GetBytes(value);
                                await client.WebSocket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None);
                            }
                        }
                    });
                    Console.WriteLine($"User {client.UserId} subscribed to channel conversation:{conversationId}");

                    // Thông báo người dùng tham gia phòng
                    var joinMessage = new Message
                    {
                        type = "system",
                        content = $"User {client.UserId} joined the conversation",
                        sender_id = client.UserId,
                        conversation_id = conversationId,
                        created_at = DateTime.UtcNow
                    };
                    // await PublishMessage(joinMessage);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error subscribing to channel: {ex.Message}");
                    throw;
                }
            }
        }
        private async Task HandleMessage(Client client, MessageDTO message)
        {
            _logger.LogInformation($"Handling message: {message.content}");
            message.created_at = DateTime.UtcNow;
            Attachment existing_attachment = null;

            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var conversation = await dbContext.Conversations.FindAsync(message.conversation_id);
            if (conversation == null)
            {
                _logger.LogWarning($"Conversation with ID {message.conversation_id} not found!");
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
                    created_at = DateTime.UtcNow
                };

                dbContext.Messages.Add(new_message);
                await dbContext.SaveChangesAsync();
                _logger.LogInformation($"Message saved to DB: {new_message.id}");

                //Lưu thời gian tin nhắn mới nhất
                conversation.lastMessageTime = new_message.created_at;
                conversation.lastMessage = message.content;

                if (message.fileID != null)
                {
                    _logger.LogInformation($"Processing attachment with ID {message.fileID}");
                    existing_attachment = await dbContext.Attachments.FindAsync(message.fileID);

                    if (existing_attachment == null)
                    {
                        _logger.LogWarning($"Attachment with ID {message.fileID} not found!");
                        return;
                    }

                    existing_attachment.message_id = new_message.id;
                    existing_attachment.is_temporary = false;
                    new_message.isFile = true;

                    dbContext.Messages.Update(new_message);
                    dbContext.Attachments.Update(existing_attachment);
                    await dbContext.SaveChangesAsync();
                }

                await transaction.CommitAsync();
                _logger.LogInformation($"Transaction committed for message: {new_message.id}");

                var db = _redis.GetDatabase();

                // Convert sang DTO để tránh vòng lặp khi serialize
                var messageDTO = new MessageDTOForAttachment
                {
                    id = new_message.id,
                    content = new_message.content,
                    sender_id = new_message.sender_id,
                    is_read = new_message.is_read,
                    type = new_message.type,
                    isFile = new_message.isFile,
                    created_at = new_message.created_at,
                    conversation_id = new_message.conversation_id
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

                var messageDataGroup = new MessageWithAttachment
                {
                    Message = messageDTO,
                    Attachment = attachmentDTO
                };

                var redisKey = $"message:{message.conversation_id}:{new_message.id}";
                var messageJson = JsonSerializer.Serialize(messageDataGroup);
                await db.StringSetAsync(redisKey, messageJson);
                _logger.LogInformation($"Message saved to Redis: {messageJson}");

                if (message.type == "private" && message.content.Contains("recipient_id:"))
                {
                    int recipientId = ParseRecipentId(message.content);
                    if (recipientId <= 0) return;

                    var sender_id = message.sender_id;
                    var box = _conversation.CreateConversation(sender_id, recipientId);

                    if (box != null && new_message.conversation_id != box.Id)
                    {
                        new_message.conversation_id = box.Id;
                        dbContext.Messages.Update(new_message);
                        await dbContext.SaveChangesAsync();

                        messageDTO.conversation_id = new_message.conversation_id;

                        redisKey = $"message:{message.conversation_id}:{new_message.id}";
                        messageJson = JsonSerializer.Serialize(new MessageWithAttachment
                        {
                            Message = messageDTO,
                            Attachment = attachmentDTO
                        });

                        await db.StringSetAsync(redisKey, messageJson);
                    }

                    try
                    {
                        await HandlePrivateMessage(new_message, recipientId);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error in HandlePrivateMessage");
                    }
                }
                else
                {
                    try
                    {
                        await PublishMessage(messageDataGroup);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "PublishMessage failed");
                    }
                }

                var conversationKey = $"conversation:{message.conversation_id}:recent";
                await db.ListRightPushAsync(conversationKey, messageJson);
                await db.ListTrimAsync(conversationKey, -50, -1);
                await db.KeyExpireAsync(conversationKey, TimeSpan.FromHours(24));
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "Transaction failed while handling message.");
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
        private async Task PublishMessage(MessageWithAttachment message)
        {
            var subscriber = _redis.GetSubscriber();
            var messageJson = JsonSerializer.Serialize(message);
            await subscriber.PublishAsync($"conversation:{message.Message.conversation_id}", messageJson);
            Console.WriteLine($"Published to channel conversation:{message.Message.conversation_id}: {messageJson}");
        }

        private async Task CleanupClient(Client client)
        {
            var subscriber = _redis.GetSubscriber();
            foreach (var conversationId in client.ConversationIds)
            {
                try
                {
                    await subscriber.UnsubscribeAsync($"conversation:{conversationId}");
                    var leaveMessage = new Message
                    {
                        type = "system",
                        content = $"User {client.UserId} left the conversation",
                        sender_id = client.UserId,
                        conversation_id = conversationId,
                        created_at = DateTime.UtcNow
                    };
                    // await PublishMessage(leaveMessage);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error unsubscribing from channel: {ex.Message}");
                    throw;
                }
            }
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
    }

}