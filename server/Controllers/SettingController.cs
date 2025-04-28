using Microsoft.AspNetCore.Mvc;
using server.DTO;
using server.Services.OTPsService;
using server.Services.SettingService;
using server.Services.TempOTPStoreSV;

namespace server.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SettingController : ControllerBase
    {
        private readonly ISettingSV _settingSV;
        private readonly IOTPsSV _otpSV;
        private readonly TempOTPStore _tempOTPStoreSV;

        public SettingController(ISettingSV settingSV, TempOTPStore tempOTPStoreSV, IOTPsSV oTPsSV)
        {
            _settingSV = settingSV;
            _tempOTPStoreSV = tempOTPStoreSV;
            _otpSV = oTPsSV;
        }

        [HttpPost("otp/send")]
        public async Task<IActionResult> SendOtp([FromBody] SendOtpDTO dto)
        {
            if (dto == null || string.IsNullOrEmpty(dto.Email))
            {
                Console.WriteLine("Invalid input: Email is missing.");
                return BadRequest(new { Message = "Email is required." });
            }

            try
            {
                var otpResult = await _otpSV.SendOTPRegistration(dto.Email);
                if (!otpResult.Success)
                {
                    Console.WriteLine($"Failed to send OTP for email: {dto.Email}. Error: {otpResult.Message}");
                    return BadRequest(new { Message = otpResult.Message });
                }

                Console.WriteLine($"OTP {otpResult.OTPCode} sent for email: {dto.Email}");
                return Ok(new { Message = "OTP sent successfully.", OTPCode = otpResult.OTPCode });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error sending OTP for email {dto.Email}: {ex.Message}");
                return StatusCode(500, new { Message = "An error occurred while sending OTP." });
            }
        }

        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpDTO dto)
        {
            try
            {
                await _settingSV.VerifyOtp(dto);
                return Ok("OTP xác minh thành công.");
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("change-email")]
        public async Task<IActionResult> ChangeEmail([FromBody] ChangeEmailDTO dto)
        {
            try
            {
                await _settingSV.ChangeEmailSetting(dto);
                return Ok("Đổi email thành công.");
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDTO dto)
        {
            try
            {
                await _settingSV.ChangePassSetting(dto);
                return Ok("Đổi mật khẩu thành công.");
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }
    }
}