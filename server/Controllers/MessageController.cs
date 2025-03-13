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
using server.Services.WebSocketService;

namespace server.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MessageController : ControllerBase
    {
        private readonly IMessage messageSV;
        private readonly WebSocketService _webSocketService;
        private readonly IServiceProvider _serviceProvider;
        private readonly IParticipant _participantSV;
        public MessageController(IMessage messageSV,
                                WebSocketService webSocketService,
                                IServiceProvider serviceProvider,
                                IParticipant participantSV)
        {
            this.messageSV = messageSV;
            _webSocketService = webSocketService;
            _serviceProvider = serviceProvider;
            _participantSV = participantSV;
        }

        [HttpGet("getMessages/{conversation_id}")]
        public async Task<IActionResult> getMessages(int conversation_id)
        {
            if (conversation_id == 0)
            {
                return BadRequest("Invalid conversation id");
            }
            try
            {
                var result = await messageSV.getMessages(conversation_id);
                if (result == null)
                {
                    return BadRequest("Not found message");
                }
                return Ok(result);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                return BadRequest(ex.Message);
            }
        }

        [HttpGet("connect")]
        public async Task Connect()
        {
            if (HttpContext.WebSockets.IsWebSocketRequest)
            {
                using var webSocket = await HttpContext.WebSockets.AcceptWebSocketAsync();
                await _webSocketService.HandleWebSocket(webSocket, _serviceProvider);
            }
            else
            {
                HttpContext.Response.StatusCode = 400; // Bad Request nếu không phải WebSocket
            }
        }
        [HttpPost("sendMessage")]
        public async Task<IActionResult> sendMessage([FromBody] MessageDTO model)
        {
            if (model == null)
            {
                return BadRequest("Message invalid");
            }
            if (model.content == "" || model.sender_id == 0 || model.conversation_id == 0)
            {
                return BadRequest("Invalid properties");
            }
            try
            {
                var sessionId = Guid.NewGuid().ToString("N");
                var message = new Message
                {
                    sender_id = model.sender_id,
                    content = model.content,
                    conversation_id = model.conversation_id,
                    created_at = DateTime.UtcNow,
                    is_read = false
                };
                await messageSV.addNewMessage(message);
                // Lấy danh sách participant trong conversation (ngoại trừ sender)
                var participants = await _participantSV
                                        .GetParticipantsForSender(model.conversation_id, model.sender_id);

                var participants_id = participants.Select(p => p.id);
                                        
                // Chuẩn bị tin nhắn để gửi qua WebSocket
                var responseMessage = JsonSerializer.Serialize(new
                {
                    session_id = sessionId,
                    sender_id = model.sender_id.ToString(),
                    encrypted_message = model.content, // Nội dung đã mã hóa từ client
                    conversation_id = model.conversation_id.ToString(),
                });

                // Gửi tin nhắn tới tất cả participant qua WebSocket
                foreach (var participantId in participants_id)
                {
                    await _webSocketService.SendToUser(participantId, responseMessage);
                }

                return Ok(new { message = "Message sent successfully", message_id = message.id });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error sending message: {ex.Message}");
                return StatusCode(500, "An error occurred while sending the message");
            }
        }
    }
}