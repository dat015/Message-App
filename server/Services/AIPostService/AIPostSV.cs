using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using server.DTO;
using server.Services;
using server.Services.ImageDescriptionService;

public class AIPostSV : IAIPostSV
{
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;
    private readonly IImageDescriptionSV _imageDescriptionService;

    public AIPostSV(IConfiguration configuration, IImageDescriptionSV imageDescriptionService)
    {
        _httpClient = new HttpClient();
        _apiKey = configuration["Cohere:ApiKey"];
        _imageDescriptionService = imageDescriptionService;
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

    public async Task<List<string>> GenerateCommentSuggestionsAsync(string postContent, string? imageUrl)
    {
        string? imageDescription = null;
        if (!string.IsNullOrWhiteSpace(imageUrl))
        {
            imageDescription = await _imageDescriptionService.GenerateImageDescriptionAsync(imageUrl);
        }

        var prompt = $"""
        Bạn là một trợ lý AI, nhiệm vụ là tạo ra 3 gợi ý bình luận ngắn gọn, phù hợp và tự nhiên bằng tiếng Việt dựa trên nội dung bài viết và mô tả ảnh (nếu có).
        Nội dung bài viết: "{postContent}"
        Mô tả ảnh (nếu có): "{imageDescription ?? "Không có ảnh"}"
        Hãy trả về các gợi ý bình luận dạng danh sách, mỗi gợi ý tối đa 50 ký tự, chỉ cần mỗi bình luận xuống dòng không cần kí tự hay số để phân biệt câu,ví dụ:
        Tuyệt vời!
        Nhìn thích quá!
        Chỗ này đẹp nè!
        """;

        var generatedText = await GenerateFromPromptAsync(prompt);

        var suggestions = generatedText
            .Split('\n', StringSplitOptions.RemoveEmptyEntries)
            .Select(line => line.Trim())
            .Where(line => !string.IsNullOrWhiteSpace(line))
            .Take(3)
            .ToList();

        return suggestions;
    }
}
