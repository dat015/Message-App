using System.Net.WebSockets;

namespace server.Services
{
    public interface IWebSocketFriendSV
    {
        Task SendFriendRequestNotificationAsync(int receiverId, string message);
        Task SendRequestAcceptedNotificationAsync(int senderId, string message);
        Task SendRequestRejectedNotificationAsync(int senderId, string message);
        Task HandleFriendWebSocket(WebSocket webSocket, int userId);
    }
}