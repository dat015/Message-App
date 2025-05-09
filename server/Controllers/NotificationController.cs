using server.Models;
using server.Services;
using Microsoft.AspNetCore.Mvc;

namespace FcmBackend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class NotificationController : ControllerBase
{
    private readonly IFcmService _fcmService;

    public NotificationController(IFcmService fcmService) => _fcmService = fcmService;

    [HttpPost("send")]
    public async Task<IActionResult> SendNotification([FromBody] NotificationRequest request)
    {
        if (string.IsNullOrEmpty(request.UserId) || string.IsNullOrEmpty(request.Title) || string.IsNullOrEmpty(request.Body))
            return BadRequest("Thiếu thông tin bắt buộc.");

        try
        {
            await _fcmService.SendNotificationAsync(request.UserId, request.Title, request.Body);
            return Ok("Gửi thông báo thành công.");
        }
        catch (Exception ex)
        {
            return StatusCode(500, ex.Message);
        }
    }
}