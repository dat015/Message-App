using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using ZXing;
using ZXing.QrCode;
using server.Models;
using server.DTO;
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using server.Data;

namespace server.Services.UserService
{
    public class UserQrService : IUserQrService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMemoryCache _cache;
        private readonly IUserSV _userService;

        public UserQrService(ApplicationDbContext context, IMemoryCache cache, IUserSV userService)
        {
            _context = context;
            _cache = cache;
            _userService = userService;
        }

        public async Task<string> GenerateQrCodeAsync(int userId)
        {
            try
            {
                var user = await _context.Users.FindAsync(userId);
                if (user == null)
                {
                    throw new Exception("User not found");
                }

                // Sử dụng DTO thay vì anonymous type
                var qrData = new QrUserData
                {
                    Id = user.id,
                    Username = user.username,
                    Email = user.email,
                    AvatarUrl = user.avatar_url,
                    Birthday = user.birthday.ToString("yyyy-MM-dd"),
                    Gender = user.gender,
                    Interests = user.interests,
                    Location = user.location,
                    Bio = user.bio
                };

                string qrContent = JsonSerializer.Serialize(qrData);

                // Cấu hình QR code
                var qrCodeWriter = new QRCodeWriter();
                var qrCodeOptions = new QrCodeEncodingOptions
                {
                    Width = 300,
                    Height = 300,
                    Margin = 1
                };

                // Tạo QR code dưới dạng BitMatrix
                var matrix = qrCodeWriter.encode(qrContent, BarcodeFormat.QR_CODE, 300, 300, qrCodeOptions.Hints);

                // Chuyển BitMatrix thành hình ảnh
                var barcodeBitmap = new Bitmap(matrix.Width, matrix.Height);
                for (int x = 0; x < matrix.Width; x++)
                {
                    for (int y = 0; y < matrix.Height; y++)
                    {
                        barcodeBitmap.SetPixel(x, y, matrix[x, y] ? Color.Black : Color.White);
                    }
                }

                // Chuyển thành base64 string
                using (var ms = new MemoryStream())
                {
                    barcodeBitmap.Save(ms, ImageFormat.Png);
                    byte[] byteImage = ms.ToArray();
                    string base64String = Convert.ToBase64String(byteImage);
                    return $"data:image/png;base64,{base64String}";
                }
            }
            catch (Exception ex)
            {
                throw new Exception($"Error generating QR code: {ex.Message}");
            }
        }

        public async Task<object> GetUserFromQrCodeAsync(string qrCodeContent, int currentUserId)
        {
            try
            {
                if (string.IsNullOrEmpty(qrCodeContent))
                {
                    return null;
                }

                // Giải mã JSON từ nội dung QR sang QrUserData
                var qrData = JsonSerializer.Deserialize<QrUserData>(qrCodeContent);
                if (qrData == null || qrData.Id == 0)
                {
                    return null;
                }

                var user = await _context.Users.FindAsync(qrData.Id);
                if (user == null)
                {
                    return null;
                }

                // Tính số bạn chung và trạng thái mối quan hệ
                int mutualFriendsCount = await _userService.GetMutualFriendsCountAsync(qrData.Id, currentUserId);
                string relationshipStatus = await _userService.GetRelationshipStatusAsync(qrData.Id, currentUserId);

                // Trả về thông tin user kèm bạn chung và trạng thái mối quan hệ
                return new
                {
                    Id = user.id,
                    Username = user.username,
                    Email = user.email,
                    AvatarUrl = user.avatar_url,
                    Birthday = user.birthday.ToString("yyyy-MM-dd"),
                    Gender = user.gender,
                    Interests = user.interests,
                    Location = user.location,
                    Bio = user.bio,
                    MutualFriendsCount = mutualFriendsCount,
                    RelationshipStatus = relationshipStatus
                };
            }
            catch (Exception ex)
            {
                throw new Exception($"Error reading QR code: {ex.Message}");
            }
        }
    }
}