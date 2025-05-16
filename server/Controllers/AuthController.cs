using System;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using server.DTO;
using server.DTO.AuthDTO;
using server.Models;
using server.Services.AuthService;
using server.Services.OTPsService;
using server.Services.TempOTPStoreSV;

namespace Message_app.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthSV _authSV;
        private readonly IOTPsSV _OTPsSV;
        private readonly TempOTPStore _tempOTPStore;

        public AuthController(IAuthSV authSV, IOTPsSV OTPsSV, TempOTPStore tempOTPStore)
        {
            _authSV = authSV ?? throw new ArgumentNullException(nameof(authSV));
            _OTPsSV = OTPsSV ?? throw new ArgumentNullException(nameof(OTPsSV));
            _tempOTPStore = tempOTPStore ?? throw new ArgumentNullException(nameof(tempOTPStore));
            Console.WriteLine($"_authSV and _tempOTPStore initialized successfully. TempOTPStore instance: {_tempOTPStore.GetHashCode()}");
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register(UserDTO model)
        {
            if (model == null || string.IsNullOrEmpty(model.email))
            {
                Console.WriteLine("Invalid input: Model or email is missing.");
                return BadRequest(new { Message = "Email is required." });
            }

            // Validate email format
            if (!Regex.IsMatch(model.email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$"))
            {
                Console.WriteLine($"Invalid email format: {model.email}");
                return BadRequest(new { Message = "Invalid email format." });
            }

            Console.WriteLine($"Attempting to register with email: {model.email}");
            var otp = _tempOTPStore.GetLatestValidOTP(model.email);
            if (otp == null)
            {
                Console.WriteLine($"No valid OTP found for email: {model.email}");
                return BadRequest(new { Message = "Please verify your email with OTP first." });
            }
            if (otp.ExpiryDate < DateTime.UtcNow)
            {
                Console.WriteLine($"OTP {otp.OTPCode} for email {model.email} has expired.");
                return BadRequest(new { Message = "OTP has expired. Please request a new OTP." });
            }

            var user = await _authSV.RegisterUser(model);
            if (user == null)
            {
                Console.WriteLine($"Failed to register user with email: {model.email}");
                return BadRequest(new { Message = "Invalid client request." });
            }
            _tempOTPStore.MarkOTPAsUsed(model.email, otp.OTPCode);
            Console.WriteLine($"User registered successfully with email: {model.email}");
            return Ok(new { Message = "Registration successful.", User = user });
        }

        [HttpPost("send-otp-registration")]
        public async Task<IActionResult> SendOTPRegistration([FromBody] EmailDTO model)
        {
            if (model == null || string.IsNullOrEmpty(model.email))
            {
                Console.WriteLine("Invalid input: Email is missing.");
                return BadRequest(new { Message = "Email is required." });
            }

            try
            {
                var otpResult = await _OTPsSV.SendOTPRegistration(model.email);
                if (!otpResult.Success)
                {
                    Console.WriteLine($"Failed to send OTP for email: {model.email}. Error: {otpResult.Message}");
                    return BadRequest(new { Message = otpResult.Message });
                }

                Console.WriteLine($"OTP {otpResult.OTPCode} sent for email: {model.email}");
                return Ok(new { Message = "OTP sent successfully.", OTPCode = otpResult.OTPCode });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error sending OTP for email {model.email}: {ex.Message}");
                return StatusCode(500, new { Message = "An error occurred while sending OTP." });
            }
        }

        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOTP([FromBody] OTPsRespose dto)
        {
            if (dto == null || string.IsNullOrEmpty(dto.email) || string.IsNullOrEmpty(dto.OTPCode))
            {
                Console.WriteLine("Invalid input: Email or OTP code is missing.");
                return BadRequest(new { Message = "Email and OTP code are required." });
            }

            var otp = _tempOTPStore.GetLatestValidOTP(dto.email);
            if (otp == null)
            {
                Console.WriteLine($"No valid OTP found for email: {dto.email}");
                return BadRequest(new { Message = "No valid OTP found. Please request a new OTP." });
            }
            if (otp.IsUsed)
            {
                Console.WriteLine($"OTP {otp.OTPCode} for email {dto.email} is already used.");
                return BadRequest(new { Message = "OTP has already been used." });
            }
            if (otp.ExpiryDate < DateTime.UtcNow)
            {
                Console.WriteLine($"OTP {otp.OTPCode} for email {dto.email} has expired.");
                return BadRequest(new { Message = "OTP has expired. Please request a new OTP." });
            }
            if (otp.OTPCode != dto.OTPCode)
            {
                Console.WriteLine($"OTP {dto.OTPCode} does not match stored OTP {otp.OTPCode} for email: {dto.email}");
                return BadRequest(new { Message = "Invalid OTP." });
            }

            // _tempOTPStore.MarkOTPAsUsed(dto.email, dto.OTPCode);
            Console.WriteLine($"OTP {dto.OTPCode} for email {dto.email} verified and marked as used.");

            return Ok(new { Message = "OTP verified successfully." });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDTO model)
        {
            if (model == null)
            {
                return BadRequest("Invalid client request");
            }
            var user = await _authSV.VerifyUser(model);
            if (user == null)
            {
                return BadRequest("Invalid client request");
            }
            Console.Write("ok");
            return Ok(user);
        }
    }
}