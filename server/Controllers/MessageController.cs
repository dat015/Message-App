using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using server.DTO;
using server.Models;
using server.Services.MessageService;
using server.Services.ParticipantService;
using server.Services.RedisService;
using server.Services.WebSocketService;

namespace server.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MessageController : ControllerBase
    {
        private readonly IMessage _messageSV;
        private readonly webSocket _webSocketService;
        private readonly IServiceProvider _serviceProvider;
        private readonly IParticipant _participantSV;

        public MessageController(
            IMessage messageSV,
            webSocket webSocketService,
            IServiceProvider serviceProvider,
            IParticipant participantSV
            )
        {
            _messageSV = messageSV;
            _webSocketService = webSocketService;
            _serviceProvider = serviceProvider;
            _participantSV = participantSV;
            
        }

        [HttpGet("getMessages/{conversation_id}")]
        public async Task<IActionResult> GetMessages(int conversation_id)
        {
            if (conversation_id == 0)
            {
                return BadRequest("Invalid conversation id");
            }
            try
            {
                var result = await _messageSV.getMessages(conversation_id);
                if (result == null || !result.Any())
                {
                    return NotFound("No messages found for this conversation");
                }
                return Ok(result);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error fetching messages: {ex.Message}");
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // [HttpGet("connect")]
        // public async Task Connect()
        // {
        //     var context = _httpContextAccessor.HttpContext;
        //     if (context == null)
        //     {
        //         throw new InvalidOperationException("HttpContext is not available");
        //     }

        //     if (context.WebSockets.IsWebSocketRequest)
        //     {
        //         using var webSocket = await context.WebSockets.AcceptWebSocketAsync();
        //         await _webSocketService.HandleWebSocket(context); // Truyền context vào đây
        //     }
        //     else
        //     {
        //         context.Response.StatusCode = StatusCodes.Status400BadRequest;
        //     }
        // }

        // [HttpPost("sendMessage")]
        // public async Task<IActionResult> SendMessage([FromBody] MessageDTO model)
        // {
        //     if (model == null)
        //     {
        //         return BadRequest("Message data is null");
        //     }
        //     if (string.IsNullOrEmpty(model.content) || model.sender_id == 0 || model.conversation_id == 0)
        //     {
        //         return BadRequest("Invalid message properties (content, sender_id, or conversation_id)");
        //     }

        //     try
        //     {
        //         var sessionId = Guid.NewGuid().ToString("N");
        //         var message = new Message
        //         {
        //             sender_id = model.sender_id,
        //             content = model.content,
        //             conversation_id = model.conversation_id,
        //             created_at = DateTime.UtcNow,
        //             is_read = false
        //         };

        //         // Thêm tin nhắn vào database
        //         await _messageSV.addNewMessage(message);

        //         // Lấy danh sách participant (ngoại trừ sender)
        //         var participants = await _participantSV.GetParticipantsForSender(model.conversation_id, model.sender_id);
        //         var participantIds = participants.Select(p => p.id);

        //         // Chuẩn bị tin nhắn để gửi qua WebSocket
        //         var responseMessage = JsonSerializer.Serialize(new
        //         {
        //             type = "message",
        //             session_id = sessionId,
        //             sender_id = model.sender_id,
        //             conversation_id = model.conversation_id,
        //             content = model.content,
        //             created_at = message.created_at.ToString("o") // ISO 8601 format
        //         });

        //         // Gửi tin nhắn tới tất cả participant qua WebSocket
        //         foreach (var participantId in participantIds)
        //         {
        //             await _webSocketService.SendToUser(participantId, responseMessage);
        //         }

        //         return Ok(new { message = "Message sent successfully", message_id = message.id });
        //     }
        //     catch (Exception ex)
        //     {
        //         Console.WriteLine($"Error sending message: {ex.Message}");
        //         return StatusCode(500, $"An error occurred while sending the message: {ex.Message}");
        //     }
        // }
    }
}