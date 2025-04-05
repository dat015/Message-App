using System;
using System.IO;
using System.Threading.Tasks;
using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using server.Data;
using server.Models;

namespace server.Services.UploadService
{
    public class UploadFileService : IUploadFileService
    {
        private readonly Cloudinary _cloudinary;
        private readonly IServiceProvider _serviceProvider;

        public UploadFileService(Cloudinary cloudinary, IServiceProvider serviceProvider)
        {
            _cloudinary = cloudinary ?? throw new ArgumentNullException(nameof(cloudinary));
            _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider));
        }


        // Upload từ Stream (dành cho IFormFile)
        public async Task<Attachment> UploadFileAsync(Stream fileStream, string fileType)
        {
            if (fileStream == null || fileStream.Length == 0)
            {
                throw new ArgumentException("File stream cannot be null or empty.");
            }

            try
            {
                if (fileStream.Length > 50 * 1024 * 1024) // Giới hạn 50MB
                {
                    throw new ArgumentException("File size exceeds 50MB limit.");
                }

                var uploadParams = new ImageUploadParams
                {
                    File = new FileDescription("file", fileStream),
                    PublicId = $"message_image_{Guid.NewGuid()}",
                    Folder = "message_images",
                    UseFilename = true,
                    UniqueFilename = true,
                    Overwrite = false,
                    AccessMode = "public" // Đảm bảo ảnh là public
                };

                var uploadResult = await _cloudinary.UploadAsync(uploadParams);

                if (uploadResult.Error != null)
                {
                    Console.WriteLine($"Cloudinary upload failed: {uploadResult.Error.Message}");
                    throw new Exception($"Cloudinary upload failed: {uploadResult.Error.Message}");
                }

                // Thêm log để kiểm tra kết quả từ Cloudinary
                Console.WriteLine($"Cloudinary upload success: URL = {uploadResult.SecureUrl.AbsoluteUri}");

                using var scope = _serviceProvider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

                var attachment = new Attachment
                {
                    file_url = uploadResult.SecureUrl.AbsoluteUri,
                    FileSize = fileStream.Length / (1024f * 1024f),
                    file_type = fileType,
                    uploaded_at = DateTime.UtcNow,
                    is_temporary = true
                };

                dbContext.Attachments.Add(attachment);
                await dbContext.SaveChangesAsync();

                // Thêm log để kiểm tra attachment sau khi lưu
                Console.WriteLine($"Attachment saved: ID = {attachment.id}, URL = {attachment.file_url}");

                return attachment;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error uploading image to Cloudinary: {ex.Message}");
                throw;
            }
        }

    }
}