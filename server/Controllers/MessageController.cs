using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using server.DTO;
using server.Filters;
using server.Models;
using server.Services.MessageService;
using server.Services.ParticipantService;
using server.Services.RedisService;
using server.Services.UploadService;
using server.Services.WebSocketService;

namespace server.Controllers
{
    [ApiController]
[Authorize]
    [Route("api/[controller]")]
    public class MessageController : ControllerBase
    {
        private readonly IMessage _messageSV;
        private readonly webSocket _webSocketService;
        private readonly IServiceProvider _serviceProvider;
        private readonly IParticipant _participantSV;
        private readonly IUploadFileService _uploadFileSV;

        public MessageController(
            IMessage messageSV,
            webSocket webSocketService,
            IServiceProvider serviceProvider,
            IParticipant participantSV,
            IUploadFileService uploadFileService
            )
        {
            _messageSV = messageSV;
            _webSocketService = webSocketService;
            _serviceProvider = serviceProvider;
            _participantSV = participantSV;
            _uploadFileSV = uploadFileService;

        }

        [HttpDelete("DeleteMessageForMe/{conversation_id}/{user_id}")]
        public async Task<IActionResult> DeleteMessageConversationForMe(int conversation_id, int user_id)
        {
            try
            {
                var result = await _messageSV.DeleteMessageConversationForMe(conversation_id, user_id);
                if (!result)
                {
                    return BadRequest(
                        new
                        {
                            success = false,
                            Message = $"Xóa tin nhắn của conversation có ID {conversation_id} thất bại!"
                        }
                    );
                }

                return Ok(
                    new
                    {
                        success = true,
                        Message = $"Xóa tin nhắn có ID {conversation_id} thành công!"
                    }
                );
            }
            catch (Exception ex)
            {
                return BadRequest(
                        new
                        {
                            success = false,    
                            Message = $"Xóa tin nhắn có ID {conversation_id} thất bại!. Lỗi: " + ex.Message
                        }
                );
            }
        }


        [HttpPut("recall_message/{message_id}")]
        public async Task<IActionResult> recall_message(int message_id)
        {
            try
            {
                var result = await _messageSV.ReCallMessage(message_id);
                if (!result)
                {
                    return BadRequest(
                        new
                        {
                            Message = $"Thu hồi tin nhắn có ID {message_id} thất bại!"
                        }
                    );
                }

                return Ok(
                    new
                    {
                        Message = $"Thu hồi tin nhắn có ID {message_id} thành công!"
                    }
                );
            }
            catch (Exception ex)
            {
                return BadRequest(
                        new
                        {
                            Message = $"Thu hồi tin nhắn có ID {message_id} thất bại!. Lỗi: " + ex.Message
                        }
                );
            }
        }


        [HttpPost("uploadFile")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadFile([FromForm] UploadFileRequest file)
        {
            try
            {
                if (file.File == null || file.File.Length == 0)
                {
                    return BadRequest(new { Error = "No file uploaded." });
                }

                using var stream = file.File.OpenReadStream();
                var uploadResult = await _uploadFileSV.UploadFileAsync(stream, file.File.ContentType);

                // Thêm log để kiểm tra uploadResult
                Console.WriteLine($"Upload result: ID = {uploadResult.id}, URL = {uploadResult.file_url}");

                if (uploadResult == null || string.IsNullOrEmpty(uploadResult.file_url))
                {
                    return BadRequest(new { Error = "Failed to upload file to Cloudinary." });
                }

                return Ok(new
                {
                    fileID = uploadResult.id,
                    fileUrl = uploadResult.file_url,
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error in UploadFile: {ex.Message}");
                return BadRequest(new { Error = ex.Message });
            }
        }
        [HttpGet("getMessages/{conversation_id}/{user_id}")]
        public async Task<IActionResult> GetMessages(int conversation_id, int user_id)
        {
            if (conversation_id == 0)
            {
                return BadRequest("Invalid conversation id");
            }
            try
            {
                var result = await _messageSV.GetMessagesAsync((long)conversation_id, user_id);
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