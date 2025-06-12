// using System;
// using System.Collections.Generic;
// using System.Linq;
// using System.Threading.Tasks;
// using Serilog;
// using server.Services.WebSocketService;

// namespace server.Services.NotificationSevice
// {
//     public class NotiService : INotification
//     {
//         private readonly NotiWebsocket _NotiWebsocket;
//         private readonly ILogger<NotiService> _logger;
//         public NotiService(NotiWebsocket webSocket, ILogger<NotiService> logger)
//         {
//             _NotiWebsocket = webSocket;
//             _logger = logger;
//         }
//         public Task<bool> SendNotification(int sender_id, string title, string body, string type, int id, List<int> targetUser)
//         {
//             if (targetUser == null || targetUser.Count == 0)
//             {
//                 _logger.LogWarning("No target user provided for notification.");
//                 return Task.FromResult(false);
//             }

//             try
//             {
//                 _NotiWebsocket.SendNotification(sender_id,title, body, type, id, targetUser);
//                 _logger.LogInformation($"Notification sent: {title}, {body}, {type}, {id}, {string.Join(", ", targetUser)}");
//                 return Task.FromResult(true);
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "Error sending notification.");
//                 return Task.FromResult(false);
//             }
//         }
//     }
// }