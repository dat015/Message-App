using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using server.DTO;
using server.DTO.AuthDTO;
using server.Models;
using server.Services.OTPsService;
using server.Services.UserService;

namespace Message_app.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ForgetPasswordController : ControllerBase
    {
        private readonly IOTPsSV _OTPsSV;
        private readonly IUserSV _UserSV;

        public ForgetPasswordController(IUserSV userSV, IOTPsSV OTPsSV)
        {
            _UserSV = userSV ?? throw new ArgumentNullException(nameof(userSV));
            _OTPsSV = OTPsSV ?? throw new ArgumentNullException(nameof(OTPsSV));
            Console.WriteLine("_OTPsSV and _UserSV are initialized successfully");
        }

        [HttpPost("ForgetPass")]
        public async Task<IActionResult> ForgotPassword([FromBody] OTPsDTO dto)
        {
            if (dto == null || string.IsNullOrEmpty(dto.email))
            {
                return BadRequest(new { Message = "Email is required."});
            }

            var result = await _OTPsSV.SendOTPForgotPassword(dto.email);
            if (!result.Success)
            {
                return BadRequest(new { Message = result.Message });
            }

            return Ok(new { Message = $"An OTP has been sent to {dto.email}. Please check your email.", OTPCode = result.OTPCode });
        }

        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOTP([FromBody] OTPsRespose dto)
        {
            if (dto == null || string.IsNullOrEmpty(dto.email) || string.IsNullOrEmpty(dto.OTPCode))
            {
                return BadRequest(new { Message = "Email and OTP code are required." });
            }

            var result = await _OTPsSV.VerifyOTP(dto.email, dto.OTPCode);
            if (!result.Success)
            {
                return BadRequest(new { Message = result.Message });
            }
    
            return Ok(new { Message = "OTP verified successfully. Proceed to reset password.", UserId = result.UserId });
        }

        [HttpPost("ChangePassword")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePassDTO dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                var user = await _UserSV.GetUserByEmail(dto.Email);
                if (user == null)
                {
                    return BadRequest(new { message = "User not found" });
                }

                await _UserSV.UpdatePassword(dto.Email, dto.NewPassword);
                return Ok(new { message = "Password changed successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred", error = ex.Message });
            }
        }
    }
}