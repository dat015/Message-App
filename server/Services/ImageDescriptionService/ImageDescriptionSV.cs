using System.Text;
using System.Text.Json;
using server.Services.ImageDescriptionService;

namespace server.Services.ImageDescriptionService   
{
    public class ImageDescriptionService : IImageDescriptionSV
    {
        private readonly HttpClient _httpClient;
        private readonly String _visionApiKey;

        public ImageDescriptionService(IConfiguration configuration)
        {
            _httpClient = new HttpClient();
            _visionApiKey = configuration["GoogleCloud:VisionApiKey"];
        }

        public async Task<string?> GenerateImageDescriptionAsync(string imageUrl)
        {
            var requestBody = new 
            {
                requests = new[]
                {
                    new
                    {
                        image = new {source = new {imageUri = imageUrl}},
                        features = new[] {new {type = "LABEL_DETECTION", maxResults = 5}}
                    }
                }
            };

            var jsonRequest = JsonSerializer.Serialize(requestBody);
            var httpContent = new StringContent(jsonRequest, Encoding.UTF8, "application/json");
            
            var response = await _httpClient.PostAsync(
                $"https://vision.googleapis.com/v1/images:annotate?key={_visionApiKey}", httpContent
            );

            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            var responseString = await response.Content.ReadAsStringAsync();
            var visionResponse = JsonSerializer.Deserialize<VisionApiResponse>(responseString);

            var labels = visionResponse?.Responses
                ?.FirstOrDefault()
                ?.LabelAnnotations
                ?.Select(label => label.Description)
                ?.ToList();

            return labels != null ? string.Join(", ", labels) : null;
        }
    }
}