namespace server.Services
{
    public interface IAIPostSV
    {
        public Task<string> GenerateFromPromptAsync(string prompt);
        Task<List<string>> GenerateCommentSuggestionsAsync(string postContent, string? imageUrl);
    }
}