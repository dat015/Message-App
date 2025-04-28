using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.DTO;
using server.Models;

namespace server.Services.OTPsService
{
    public interface IOTPsSV
    {
        Task<OTPsResult> SendOTPForgotPassword(string email);
        Task<OTPsResult> VerifyOTP(string email, string otpCode);
        Task<OTPsResult> SendOTPRegistration(string email);
        Task<OTPsResult> VerifyOTPRegister(string email, string otpCode);
    }

    // Kết quả trả về từ service
    public class OTPsResult
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public string OTPCode { get; set; }
        public int UserId { get; set; }
    }
}