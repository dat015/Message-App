namespace server.Services
{
    public interface IAIPostSV
    {
        public Task<string> GenerateFromPromptAsync(string prompt);
    }
}