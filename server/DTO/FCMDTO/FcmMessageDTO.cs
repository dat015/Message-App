public class FcmMessage
{
    public string Token { get; set; } = string.Empty;
    public FcmNotification Notification { get; set; } = new FcmNotification();
    public Dictionary<string, string>? Data { get; set; }
}