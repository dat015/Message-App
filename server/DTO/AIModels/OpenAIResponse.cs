namespace server.DTO
{
    public class OpenAIResponse
    {
        public List<CohereChoice> generations { get; set; }
    }

    public class CohereChoice
    {
        public string text { get; set; }
    }
}