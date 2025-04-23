namespace server.Services.ImageDescriptionService
{
    public interface IImageDescriptionSV
    {
        Task<string> GenerateImageDescriptionAsync(string imageUrl);
    }
}