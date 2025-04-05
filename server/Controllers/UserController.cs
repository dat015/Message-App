using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using server.Data;
using server.Models;
using server.Services.UserService;

namespace server.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IUserSV userSV;
        private readonly IUserQrService _userQrService;
        public UserController(ApplicationDbContext context, IUserSV userSV, IUserQrService userQrService)
        {
            _context = context;
            this.userSV = userSV;
            _userQrService = userQrService;
        }
        [HttpGet("getUser/{user_id}")]
        public async Task<IActionResult> GetUser(int user_id)
        {
            if (user_id == 0)
            {
                return BadRequest("Invalid user id");
            }
            try
            {
                var result = await userSV.GetUserByIdAsync(user_id);
                if (result == null)
                {
                    return BadRequest("Not found user");
                }
                return Ok(result);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }

        [HttpGet("generate-qr/{userId}")]
        public async Task<IActionResult> GenerateQrCode(int userId)
        {
            try
            {
                var qrCodeBase64 = await _userQrService.GenerateQrCodeAsync(userId);
                return Ok(new { qrCode = qrCodeBase64 });
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("find-user-by-qr")]
        public async Task<IActionResult> FindUserByQrCode([FromBody] QrCodeRequest request)
        {
            if (string.IsNullOrEmpty(request?.QrCodeContent))
            {
                return BadRequest("QR code content is required");
            }

            try
            {
                // Giả sử currentUserId được gửi trong request hoặc lấy từ token
                int currentUserId = request.CurrentUserId; // Cần thêm logic xác thực để lấy currentUserId (ví dụ từ JWT token)
                var user = await _userQrService.GetUserFromQrCodeAsync(request.QrCodeContent, currentUserId);
                if (user == null)
                {
                    return NotFound("User not found from QR code");
                }
                return Ok(user);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }
    }
}
