using System;
using System.Collections.Concurrent;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using server.Data;
using server.Models;
using server.Services.RedisService;

namespace server.Services.WebSocketService
{
    public class WebSocketService
    {
        private readonly ConcurrentDictionary<int, WebSocket> _clients = new();
        private readonly ConcurrentDictionary<int, HashSet<int>> _conversationSubscriptions = new();

        public WebSocketService()
        {
            Task.Run(() => CleanupDeadConnections());
        }

        public async Task HandleWebSocket(WebSocket webSocket, IServiceProvider serviceProvider)
        {
            var redisService = serviceProvider.GetRequiredService<IRedisService>();
            var dbContext = serviceProvider.GetRequiredService<ApplicationDbContext>();
            var sessionId = Guid.NewGuid().ToString("N");

            var initMessage = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(new { session_id = sessionId }));
            await webSocket.SendAsync(new ArraySegment<byte>(initMessage), WebSocketMessageType.Text, true, CancellationToken.None);

            int userId = 0;
            var buffer = new byte[1024 * 4];
            WebSocketReceiveResult result = null;

            async Task SubscribeToConversations(int userId)
            {
                var conversations = await dbContext.Participants
                    .Where(p => p.user_id == userId && !p.is_deleted)
                    .Select(p => p.conversation_id)
                    .ToListAsync();

                if (!conversations.Any())
                {
                    Console.WriteLine($"No conversations found for user {userId}");
                    return;
                }

                _conversationSubscriptions.TryAdd(userId, new HashSet<int>());
                foreach (var conversationId in conversations)
                {
                    _conversationSubscriptions[userId].Add(conversationId);
                    await redisService.SubscribeAsync($"conversation:{conversationId}", async (channel, message) =>
                    {
                        Console.WriteLine($"Received from Redis channel {channel}: {message}");
                        if (webSocket.State == WebSocketState.Open)
                        {
                            Console.WriteLine($"Sending to WebSocket for user {userId}");
                            var bytes = Encoding.UTF8.GetBytes(message);
                            await webSocket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None);
                        }
                        else
                        {
                            Console.WriteLine($"WebSocket for user {userId} is closed. State: {webSocket.State}");
                        }
                    });
                    Console.WriteLine($"User {userId} subscribed to conversation {conversationId}");
                }
            }

            bool isSubscribed = false;
            while (webSocket.State == WebSocketState.Open)
            {
                var receivedBytes = new List<byte>();
                do
                {
                    result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
                    receivedBytes.AddRange(buffer.Take(result.Count));
                } while (!result.EndOfMessage);

                if (result.CloseStatus.HasValue) break;

                var message = Encoding.UTF8.GetString(receivedBytes.ToArray());
                Console.WriteLine($"Received message: {message}");
                Dictionary<string, string> json;
                try
                {
                    json = JsonSerializer.Deserialize<Dictionary<string, string>>(message);
                }
                catch (JsonException ex)
                {
                    Console.WriteLine($"Invalid JSON received: {ex.Message}");
                    continue;
                }

                if (userId == 0 && json.ContainsKey("user_id"))
                {
                    userId = int.Parse(json["user_id"]);
                    _clients.TryAdd(userId, webSocket);
                    Console.WriteLine($"Client {userId} connected.");
                    await SubscribeToConversations(userId);
                    isSubscribed = true; // Đánh dấu đã subscribe
                    continue; // Chờ subscription hoàn tất
                }

                if (!isSubscribed)
                {
                    Console.WriteLine($"Waiting for subscription to complete for user {userId}");
                    continue; // Bỏ qua tin nhắn nếu chưa subscribe
                }

                if (json.ContainsKey("message"))
                {
                    var messageText = json["message"];
                    var senderId = int.Parse(json["sender_id"]);
                    var conversationId = int.Parse(json["conversation_id"]);

                    var msg = new Message
                    {
                        sender_id = senderId,
                        content = messageText,
                        created_at = DateTime.UtcNow,
                        conversation_id = conversationId,
                        is_read = false
                    };
                    dbContext.Messages.Add(msg);
                    await dbContext.SaveChangesAsync();

                    var messageData = JsonSerializer.Serialize(new
                    {
                        sender_id = senderId.ToString(),
                        message = messageText,
                        conversation_id = conversationId.ToString(),
                        created_at = DateTime.UtcNow.ToString("o")
                    });
                    Console.WriteLine($"Publishing to Redis channel 'conversation:{conversationId}': {messageData}");
                    await redisService.PublishAsync($"conversation:{conversationId}", messageData);
                    Console.WriteLine($"Successfully published to conversation {conversationId}");
                }
            }

            if (userId != 0)
            {
                _clients.TryRemove(userId, out _);
                _conversationSubscriptions.TryRemove(userId, out _);
                Console.WriteLine($"Client {userId} disconnected.");
            }

            await webSocket.CloseAsync(result?.CloseStatus ?? WebSocketCloseStatus.NormalClosure, result?.CloseStatusDescription ?? "Connection closed", CancellationToken.None);
        }

        private async Task CleanupDeadConnections()
        {
            while (true)
            {
                await Task.Delay(TimeSpan.FromMinutes(5));
                foreach (var client in _clients)
                {
                    if (client.Value.State != WebSocketState.Open)
                    {
                        _clients.TryRemove(client.Key, out _);
                        _conversationSubscriptions.TryRemove(client.Key, out _);
                        Console.WriteLine($"Removed dead connection for user {client.Key}");
                    }
                }
            }
        }

        public async Task SendToUser(int userId, string message)
        {
            if (_clients.TryGetValue(userId, out var webSocket) && webSocket.State == WebSocketState.Open)
            {
                var bytes = Encoding.UTF8.GetBytes(message);
                try
                {
                    await webSocket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Failed to send to user {userId}: {ex.Message}");
                    _clients.TryRemove(userId, out _);
                    _conversationSubscriptions.TryRemove(userId, out _);
                }
            }
        }
    }
}