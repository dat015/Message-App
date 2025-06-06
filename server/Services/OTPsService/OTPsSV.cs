using System;
using System.Linq;
using System.Threading.Tasks;
using server.DTO.AuthDTO;
using server.Services.UserService;
using server.Helper;
using server.Models;
using server.DTO;
using System.Net.Mail;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using server.Services.TempOTPStoreSV;

namespace server.Services.OTPsService
{
    public class OTPsSV : IOTPsSV
    {
        private readonly IUserSV _userSV;
        private readonly IConfiguration _configuration;
        private readonly ILogger<OTPsSV> _logger;
        private readonly TempOTPStore _tempOTPStore;

        public OTPsSV(IUserSV userSV, IConfiguration configuration, ILogger<OTPsSV> logger, TempOTPStore tempOTPStore)
        {
            _userSV = userSV;
            _configuration = configuration;
            _logger = logger;
            _tempOTPStore = tempOTPStore;
            Console.WriteLine($"OTPsSV initialized with TempOTPStore instance: {_tempOTPStore.GetHashCode()}");
        }

        public async Task<OTPsResult> SendOTPForgotPassword(string email)
        {
            if (string.IsNullOrEmpty(email) || !IsValidEmail(email))
            {
                return new OTPsResult { Success = false, Message = "Invalid email format." };
            }

            var user = await _userSV.GetUserByEmail(email);
            if (user == null)
            {
                return new OTPsResult { Success = false, Message = "Email does not exist." };
            }

            var latestOTP = await GetLatestOTPByUserIdAsync(user.id);
            if (latestOTP != null && latestOTP.ExpiryDate > DateTime.UtcNow)
            {
                return new OTPsResult { Success = false, Message = "An OTP is already active. Please wait for it to expire." };
            }

            string otpCode = GenerateRandomOTP();

            var otp = new OTPs
            {
                UserId = user.id,
                OTPCode = otpCode,
                ExpiryDate = DateTime.UtcNow.AddMinutes(1),
                IsUsed = false
            };
            await SaveOTPAsync(otp);

            try
            {
                await SendOTPByEmail(email, otpCode);
            }
            catch (Exception ex)
            {
                _logger.LogError($"Failed to send OTP email: {ex.Message}");
                return new OTPsResult { Success = false, Message = "Failed to send OTP. Please try again." };
            }

            return new OTPsResult
            {
                Success = true,
                Message = "OTP sent successfully",
                OTPCode = otpCode
            };
        }

        public async Task<OTPsResult> VerifyOTP(string email, string otpCode)
        {
            var user = await _userSV.GetUserByEmail(email);
            if (user == null)
            {
                return new OTPsResult { Success = false, Message = "Email does not exist." };
            }

            var otp = await GetLatestOTPByUserIdAsync(user.id);
            if (otp == null || otp.OTPCode != otpCode || otp.IsUsed == true || otp.ExpiryDate < DateTime.UtcNow)
            {
                return new OTPsResult { Success = false, Message = "Invalid or expired OTP." };
            }

            otp.IsUsed = true;
            await UpdateOTPAsync(otp);

            return new OTPsResult
            {
                Success = true,
                Message = "OTP verified successfully",
                UserId = user.id
            };
        }

        public async Task<OTPsResult> SendOTPRegistration(string email)
        {
            if (string.IsNullOrEmpty(email))
            {
                Console.WriteLine("Invalid input: Email is missing.");
                return new OTPsResult { Success = false, Message = "Email is required." };
            }

            try
            {
                var otpCode = new Random().Next(100000, 999999).ToString();
                await SendOTPByEmail(email, otpCode);
                _tempOTPStore.SaveOTP(email, otpCode, 10); // Tăng thời gian hết hạn lên 10 phút
                Console.WriteLine($"OTP {otpCode} sent and saved for email: {email}");
                return new OTPsResult { Success = true, OTPCode = otpCode, Message = "OTP sent successfully." };
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error sending OTP for {email}: {ex.Message}");
                return new OTPsResult { Success = false, Message = "Failed to send OTP." };
            }
        }

        public async Task<OTPsResult> VerifyOTPRegister(string email, string otpCode)
        {
            var otp = _tempOTPStore.GetLatestValidOTP(email);
            if (otp == null || otp.OTPCode != otpCode || otp.IsUsed || otp.ExpiryDate < DateTime.UtcNow)
            {
                return new OTPsResult { Success = false, Message = "Invalid or expired OTP." };
            }

            _tempOTPStore.MarkOTPAsUsed(email, otpCode);
            return new OTPsResult { Success = true, Message = "OTP verified successfully." };
        }

        private string GenerateRandomOTP()
        {
            Random random = new Random();
            return random.Next(100000, 999999).ToString();
        }

        private bool IsValidEmail(string email)
        {
            try
            {
                var addr = new MailAddress(email);
                return addr.Address == email;
            }
            catch
            {
                return false;
            }
        }

        public async Task SendOTPByEmail(string email, string otpCode)
        {
            var fromEmail = _configuration["EmailSettings:FromEmail"];
            var appPassword = _configuration["EmailSettings:AppPassword"];
            var displayName = _configuration["EmailSettings:DisplayName"];
            var smtpHost = _configuration["EmailSettings:SMTPHost"];
            var smtpPort = int.Parse(_configuration["EmailSettings:SMTPPort"]);

            var fromAddress = new MailAddress(fromEmail, displayName);
            var toAddress = new MailAddress(email);
            const string subject = "Your OTP for Password Reset";
            string body = $"Your OTP is: {otpCode}. It is valid for 5 minutes.";

            var smtp = new SmtpClient
            {
                Host = smtpHost,
                Port = smtpPort,
                EnableSsl = true,
                DeliveryMethod = SmtpDeliveryMethod.Network,
                UseDefaultCredentials = false,
                Credentials = new System.Net.NetworkCredential(fromAddress.Address, appPassword)
            };

            using var message = new MailMessage(fromAddress, toAddress)
            {
                Subject = subject,
                Body = body
            };

            await smtp.SendMailAsync(message);
        }

        private async Task SaveOTPAsync(OTPs otp)
        {
            await _userSV.SaveOTPAsync(otp);
        }

        private async Task<OTPs> GetLatestOTPByUserIdAsync(int userId)
        {
            return await _userSV.GetLatestOTPByUserIdAsync(userId);
        }

        private async Task UpdateOTPAsync(OTPs otp)
        {
            await _userSV.UpdateOTPAsync(otp);
        }
    }
}