namespace server.Services;

public interface IFcmService
{
    Task SendNotificationAsync(string userId, string title, string body);
}