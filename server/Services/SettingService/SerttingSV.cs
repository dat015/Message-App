using server.Data;
using server.DTO;
using server.Services.TempOTPStoreSV;
using server.Services.UserService;
using Microsoft.EntityFrameworkCore;
using server.Helper;

namespace server.Services.SettingService
{
    public class SettingSV : ISettingSV
    {
        private readonly IUserSV _userSV;
        private readonly TempOTPStore _tempOTPStoreSV;
        private readonly ApplicationDbContext _context;

        public SettingSV(IUserSV userSV, TempOTPStore tempOTPStoreSV, ApplicationDbContext context)
        {
            _userSV = userSV;
            _tempOTPStoreSV = tempOTPStoreSV;
            _context = context;
        }

        public async Task ChangeEmailSetting(ChangeEmailDTO emailDTO)
        {
            var user = await _userSV.GetUserByEmail(emailDTO.CurrentEmail);
            if (user == null) throw new Exception("Người dùng không tồn tại.");

            user.email = emailDTO.NewEmail;
            _context.Users.Update(user);
            await _context.SaveChangesAsync();
        }

        public async Task<ChangePasswordDTO> ChangePassSetting(ChangePasswordDTO changePasswordDTO)
        {
            var user = await _userSV.FindUserAsync(changePasswordDTO.email, changePasswordDTO.currentPass);
            if (user == null) throw new Exception("Mật khẩu hiện tại không đúng.");

            var salt = Hash.GenerateKey();
            user.password = Hash.HashPassword(changePasswordDTO.newPass, salt);
            user.passwordSalt = salt;

            _context.Users.Update(user);
            await _context.SaveChangesAsync();

            return changePasswordDTO;
        }

        public async Task VerifyOtp(VerifyOtpDTO dto)
        {
            var otp = _tempOTPStoreSV.GetLatestValidOTP(dto.Email);
            if (otp == null || otp.OTPCode != dto.OtpCode) throw new Exception("Mã OTP không hợp lệ.");

            _tempOTPStoreSV.MarkOTPAsUsed(dto.Email, dto.OtpCode);
        }
    }
}