namespace server.DTO
{
    public class OpenAIRequest
    {
        public string model { get; set; }
        public string prompt { get; set; }
        public bool stream { get; set; } = false;
        public int max_tokens { get; set; } = 300;
        public float temperature { get; set; } = 0.7f;
    }
}