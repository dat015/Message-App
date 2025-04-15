using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using server.DTO;
using server.Services;

public class AIPostSV : IAIPostSV
{
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;

    public AIPostSV(IConfiguration configuration)
    {
        _httpClient = new HttpClient();
        _apiKey = configuration["Cohere:ApiKey"];
    }

    public async Task<string> GenerateFromPromptAsync(string prompt)
    {
        var cohereRequest = new OpenAIRequest
        {
            model = "command-r-plus",
            prompt = prompt,
            temperature = 0.7f,
            max_tokens = 300
        };

        var jsonRequest = JsonSerializer.Serialize(cohereRequest);
        var httpContent = new StringContent(jsonRequest, Encoding.UTF8, "application/json");
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);

        var response = await _httpClient.PostAsync("https://api.cohere.ai/v1/generate", httpContent);

        if (!response.IsSuccessStatusCode)
        {
            var err = await response.Content.ReadAsStringAsync();
            throw new Exception("Lỗi gọi Cohere: " + response.StatusCode + " - " + err);
        }

        var responseString = await response.Content.ReadAsStringAsync();
        var cohereResponse = JsonSerializer.Deserialize<OpenAIResponse>(responseString);

        var firstText = cohereResponse?.generations?.FirstOrDefault()?.text;

        return firstText?.Trim() ?? "Không có phản hồi từ Cohere.";
    }
}
