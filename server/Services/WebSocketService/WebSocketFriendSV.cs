using System;
using System.Collections.Concurrent;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

namespace server.Services
{
    public class WebSocketFriendSV : IWebSocketFriendSV
    {
        private readonly ConcurrentDictionary<int, WebSocket> _friendClients = new();
        private readonly ILogger<WebSocketFriendSV> _logger;

        public WebSocketFriendSV(ILogger<WebSocketFriendSV> logger)
        {
            _logger = logger;
            Task.Run(() => CleanupDeadConnections()); // Chạy tác vụ dọn dẹp kết nối chết
        }

        // Xử lý kết nối WebSocket từ client
        public async Task HandleFriendWebSocket(WebSocket webSocket, int userId)
        {
            _friendClients.TryAdd(userId, webSocket);
            _logger.LogInformation($"User {userId} connected to friend WebSocket.");

            var buffer = new byte[1024 * 4];
            while (webSocket.State == WebSocketState.Open)
            {
                var result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
                if (result.CloseStatus.HasValue)
                {
                    break;
                }
            }

            _friendClients.TryRemove(userId, out _);
            _logger.LogInformation($"User {userId} disconnected from friend WebSocket.");
            await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Connection closed", CancellationToken.None);
        }

        // Gửi thông báo lời mời kết bạn
        public async Task SendFriendRequestNotificationAsync(int receiverId, string message)
        {
            await SendMessageToUser(receiverId, message);
        }

        // Gửi thông báo chấp nhận lời mời
        public async Task SendRequestAcceptedNotificationAsync(int senderId, string message)
        {
            await SendMessageToUser(senderId, message);
        }

        // Gửi thông báo từ chối lời mời
        public async Task SendRequestRejectedNotificationAsync(int senderId, string message)
        {
            await SendMessageToUser(senderId, message);
        }

        public async Task SendRequestCancelledNotificationAsync(int userId, string message)
        {
            await SendMessageToUser(userId, message);
        }

        // Phương thức chung để gửi tin nhắn qua WebSocket
        private async Task SendMessageToUser(int userId, string message)
        {
            if (_friendClients.TryGetValue(userId, out var webSocket) && webSocket.State == WebSocketState.Open)
            {
                var bytes = Encoding.UTF8.GetBytes(message);
                try
                {
                    await webSocket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None);
                    _logger.LogInformation($"Sent message to user {userId}: {message}");
                }
                catch (Exception ex)
                {
                    _logger.LogError($"Failed to send message to user {userId}: {ex.Message}");
                    _friendClients.TryRemove(userId, out _);
                }
            }
            else
            {
                _logger.LogWarning($"User {userId} not connected or WebSocket closed.");
            }
        }

        // Dọn dẹp các kết nối chết
        private async Task CleanupDeadConnections()
        {
            while (true)
            {
                await Task.Delay(TimeSpan.FromMinutes(5));
                foreach (var client in _friendClients)
                {
                    if (client.Value.State != WebSocketState.Open)
                    {
                        _friendClients.TryRemove(client.Key, out _);
                        _logger.LogInformation($"Removed dead connection for user {client.Key}");
                    }
                }
            }
        }
    }
}