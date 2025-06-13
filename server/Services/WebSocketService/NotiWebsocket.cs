// using System;
// using System.Collections.Concurrent;
// using System.Collections.Generic;
// using System.Linq;
// using System.Net.WebSockets;
// using System.Text;
// using System.Text.Json;
// using System.Threading;
// using System.Threading.Tasks;
// using Microsoft.Extensions.Logging;

// namespace server.Services.WebSocketService
// {
//     public class NotiWebsocket : IDisposable
//     {
//         private readonly ConcurrentDictionary<Client, bool> _clients = new(); // Danh sách client thread-safe
//         private readonly ILogger<NotiWebsocket> _logger;
//         private readonly CancellationTokenSource _cts = new(); // Token để hủy tác vụ
//         private readonly int _maxBufferSize; // Kích thước buffer tối đa

//         public NotiWebsocket(ILogger<NotiWebsocket> logger, int maxBufferSize = 1024 * 4)
//         {
//             _logger = logger ?? throw new ArgumentNullException(nameof(logger));
//             _maxBufferSize = maxBufferSize;
//         }

//         // Lớp Client đơn giản cho thông báo
//         public class Client
//         {
//             public WebSocket WebSocket { get; set; }
//             public int UserId { get; set; }
//         }

//         // Xử lý kết nối WebSocket
//         public async Task HandleWebSocket(HttpContext context)
//         {
//             if (!context.WebSockets.IsWebSocketRequest)
//             {
//                 context.Response.StatusCode = StatusCodes.Status400BadRequest;
//                 return;
//             }

//             var webSocket = await context.WebSockets.AcceptWebSocketAsync();
//             var client = new Client { WebSocket = webSocket };
//             _clients.TryAdd(client, true);

//             _logger.LogInformation($"New notification client connected. Total clients: {_clients.Count}, Remote: {context.Connection.RemoteIpAddress}");

//             _ = StartHeartbeat(client); // Bắt đầu heartbeat
//             await Receiver(client); // Xử lý tin nhắn từ client

//             await CleanupClient(client); // Dọn dẹp client
//             _clients.TryRemove(client, out _);
//             _logger.LogInformation($"Notification client disconnected: {context.Connection.RemoteIpAddress}");
//             await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Connection closed", CancellationToken.None);
//         }

//         // Nhận và xử lý tin nhắn từ client
//         private async Task Receiver(Client client)
//         {
//             var buffer = new byte[_maxBufferSize];
//             while (client.WebSocket.State == WebSocketState.Open)
//             {
//                 var receivedBytes = new List<byte>();
//                 WebSocketReceiveResult result;
//                 do
//                 {
//                     result = await client.WebSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
//                     receivedBytes.AddRange(buffer.Take(result.Count));
//                 } while (!result.EndOfMessage);

//                 if (result.CloseStatus.HasValue) break;

//                 var messageJson = Encoding.UTF8.GetString(receivedBytes.ToArray());
//                 _logger.LogInformation($"Received: {messageJson}");

//                 try
//                 {
//                     var message = JsonSerializer.Deserialize<MessageDTO>(messageJson, new JsonSerializerOptions
//                     {
//                         PropertyNameCaseInsensitive = true
//                     });

//                     if (IsValidMessage(message))
//                     {
//                         if (message.type == "bootup")
//                         {
                           
//                         }
//                         else if (message.type == "ping")
//                         {
//                             _logger.LogInformation($"Received ping from client {client.UserId}");
//                         }
//                         else
//                         {
//                             _logger.LogWarning($"Unknown message type: {message.type}");
//                         }
//                     }
//                 }
//                 catch (JsonException ex)
//                 {
//                     _logger.LogError(ex, $"Error deserializing message for client {client.UserId}");
//                     break;
//                 }
//             }
//         }

//         // Gửi thông báo đến các client đang kết nối
//         public async Task<bool> SendNotification(int senderId, string title, string body, string type, int id, List<int> targetUserIds)
//         {
//             if (targetUserIds == null || !targetUserIds.Any())
//             {
//                 _logger.LogWarning("No target users provided for notification.");
//                 return false;
//             }

//             var notification = new
//             {
//                 Event = "notification",
//                 SenderId = senderId,
//                 Title = title,
//                 Body = body,
//                 Type = type,
//                 Id = id
//             };

//             var json = JsonSerializer.Serialize(notification);
//             var buffer = Encoding.UTF8.GetBytes(json);
//             var segment = new ArraySegment<byte>(buffer);

//             var tasks = _clients.Keys
//                 .Where(client => targetUserIds.Contains(client.UserId) && client.WebSocket.State == WebSocketState.Open)
//                 .Select(client => client.WebSocket.SendAsync(segment, WebSocketMessageType.Text, true, CancellationToken.None)
//                     .ContinueWith(t =>
//                     {
//                         if (t.IsCompletedSuccessfully)
//                             _logger.LogInformation($"Sent notification to user {client.UserId}");
//                         else
//                             _logger.LogError(t.Exception, $"Failed to send notification to user {client.UserId}");
//                     }));

//             await Task.WhenAll(tasks);
//             return true;
//         }

//         // Gửi heartbeat để duy trì kết nối
//         private async Task StartHeartbeat(Client client)
//         {
//             while (client.WebSocket.State == WebSocketState.Open && !_cts.Token.IsCancellationRequested)
//             {
//                 try
//                 {
//                     var pingMessage = Encoding.UTF8.GetBytes("{\"type\":\"ping\"}");
//                     await client.WebSocket.SendAsync(
//                         new ArraySegment<byte>(pingMessage),
//                         WebSocketMessageType.Text,
//                         true,
//                         CancellationToken.None);
//                     await Task.Delay(TimeSpan.FromSeconds(30), _cts.Token);
//                 }
//                 catch (Exception ex)
//                 {
//                     _logger.LogError(ex, $"Error in heartbeat for client {client.UserId}");
//                     await CleanupClient(client);
//                     break;
//                 }
//             }
//         }

//         // Dọn dẹp client khi ngắt kết nối
//         private async Task CleanupClient(Client client)
//         {
//             if (client.WebSocket.State == WebSocketState.Open)
//             {
//                 try
//                 {
//                     await client.WebSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Cleanup", CancellationToken.None);
//                 }
//                 catch (Exception ex)
//                 {
//                     _logger.LogError(ex, $"Error closing WebSocket for client {client.UserId}");
//                 }
//             }
//         }

//         // Kiểm tra tính hợp lệ của tin nhắn
//         private bool IsValidMessage(MessageDTO message)
//         {
//             return message != null && !string.IsNullOrEmpty(message.type);
//         }

//         // Hàm xác thực token (giả định)
//         private bool ValidateToken(string token)
//         {
//             // Thêm logic xác thực token ở đây, ví dụ: kiểm tra JWT
//             return !string.IsNullOrEmpty(token); // Giả định đơn giản
//         }

//         // Giải phóng tài nguyên
//         public void Dispose()
//         {
//             _cts.Cancel();
//             foreach (var client in _clients.Keys)
//             {
//                 CleanupClient(client).GetAwaiter().GetResult();
//             }
//             _clients.Clear();
//             _cts.Dispose();
//         }
//     }

//     // Định nghĩa MessageDTO
    
// }