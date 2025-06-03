using System.Text;
using System.Text.Json;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using Serilog;
using server.Services;
namespace server.Services;

public class FcmService : IFcmService
{
    private readonly HttpClient _httpClient;
    private readonly string _fcmEndpoint;
    private bool _disposed;

    public FcmService(IConfiguration configuration, HttpClient httpClient)
    {
        _httpClient = httpClient;
        _httpClient.Timeout = TimeSpan.FromSeconds(30);
        var projectId = configuration["Firebase:ProjectId"];
        _fcmEndpoint = $"https://fcm.googleapis.com/v1/projects/{projectId}/messages:send";
    }

    public async Task SendNotificationAsync(string userId, string title, string body, string? postId = null)
    {
        var fcmToken = await GetFcmTokenForUser(userId);
        if (string.IsNullOrEmpty(fcmToken)) throw new Exception("Không tìm thấy FCM token.");

        var accessToken = await GetAccessTokenAsync();
        var message = new FcmRequest
        {
            Message = new FcmMessage
            {
                Token = fcmToken,
                Notification = new FcmNotification { Title = title, Body = body },
                Data = postId != null ? new Dictionary<string, string> { { "postId", postId } } : null
            }
        };

        var json = JsonSerializer.Serialize(message, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        _httpClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);
        var response = await _httpClient.PostAsync(_fcmEndpoint, content);
        if (!response.IsSuccessStatusCode)
        {
            var errorContent = await response.Content.ReadAsStringAsync();
            Log.Error("FCM request failed: Status {StatusCode}, Error: {Error}", response.StatusCode, errorContent);
            throw new Exception($"Gửi thất bại: {errorContent}");
        }
        Log.Information("Notification sent successfully to user {UserId}", userId);
    }

    private async Task<string> GetAccessTokenAsync()
    {
        var credential = GoogleCredential.FromFile("service-account.json")
            .CreateScoped("https://www.googleapis.com/auth/firebase.messaging");
        return await credential.UnderlyingCredential.GetAccessTokenForRequestAsync();
    }

    private async Task<string> GetFcmTokenForUser(string userId)
    {
        FirestoreDb db = FirestoreDb.Create("messageapps-dbc91");
        var userRef = db.Collection("users").Document(userId);
        var snapshot = await userRef.GetSnapshotAsync();
        if (snapshot.Exists && snapshot.ContainsField("fcmToken"))
        {
            var token = snapshot.GetValue<string>("fcmToken");
            Log.Information("Retrieved FCM token for user {UserId}", userId);
            return token;
        }
        Log.Warning("No FCM token found for user {UserId}", userId);
        return null;
    }
    
    public void Dispose()
    {
        if (!_disposed)
        {
            _httpClient.Dispose();
            _disposed = true;
        }
    }
}