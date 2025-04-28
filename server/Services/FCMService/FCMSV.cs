using System.Text;
using System.Text.Json;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using server.Services;
namespace server.Services;
public class FcmService : IFcmService
{
    private readonly HttpClient _httpClient;
    private readonly string _fcmEndpoint;

    public FcmService(IConfiguration configuration, HttpClient httpClient)
    {
        _httpClient = httpClient;
        var projectId = configuration["Firebase:ProjectId"];
        _fcmEndpoint = $"https://fcm.googleapis.com/v1/projects/messageapps-dbc91/messages:send";
    }

    public async Task SendNotificationAsync(string userId, string title, string body)
    {
        var fcmToken = await GetFcmTokenForUser(userId);
        if (string.IsNullOrEmpty(fcmToken)) throw new Exception("Không tìm thấy FCM token.");

        var accessToken = await GetAccessTokenAsync();
        var message = new FcmRequest
        {
            Message = new FcmMessage
            {
                Token = fcmToken,
                Notification = new FcmNotification { Title = title, Body = body }
            }
        };

        var json = JsonSerializer.Serialize(message, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        _httpClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);
        var response = await _httpClient.PostAsync(_fcmEndpoint, content);
        if (!response.IsSuccessStatusCode)
            throw new Exception($"Gửi thất bại: {await response.Content.ReadAsStringAsync()}");
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
        return snapshot.Exists && snapshot.ContainsField("fcmToken") ? snapshot.GetValue<string>("fcmToken") : null;
    }
}