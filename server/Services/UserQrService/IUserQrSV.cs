namespace server.Services.UserService
{
    public interface IUserQrService
    {
        Task<string> GenerateQrCodeAsync(int userId);
        Task<object> GetUserFromQrCodeAsync(string qrCodeContent, int currentUserId);
    }
}