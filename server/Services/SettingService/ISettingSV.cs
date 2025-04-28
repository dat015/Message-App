using server.DTO;

namespace server.Services.SettingService
{
    public interface ISettingSV
    {
        Task ChangeEmailSetting(ChangeEmailDTO emailDTO);
        Task<ChangePasswordDTO> ChangePassSetting(ChangePasswordDTO changePasswordDTO);
        public Task VerifyOtp(VerifyOtpDTO dto);
    }
}