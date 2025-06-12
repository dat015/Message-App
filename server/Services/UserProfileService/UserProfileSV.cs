using Microsoft.EntityFrameworkCore;
using server.Data;
using server.Models;
using System.Text.Json;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using StackExchange.Redis;

namespace server.Services
{
    public class UserProfileSV : IUserProfileSV
    {
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _environment;

        public UserProfileSV(ApplicationDbContext context, IWebHostEnvironment environment)
        {
            _context = context;
            _environment = environment;
        }

        public async Task<User> GetUserProfileAsync(int userId)
        {
            var user = await _context.Users
                .Include(u => u.FriendshipsAsUser1)
                .Include(u => u.FriendshipsAsUser2)
                .FirstOrDefaultAsync(u => u.id == userId);

            if (user == null)
                throw new Exception("User not found");

            // Tính số bạn bè
            user.MutualFriendsCount = (user.FriendshipsAsUser1?.Count ?? 0) + (user.FriendshipsAsUser2?.Count ?? 0);
            return user;
        }

        public async Task<User> UpdateProfile(int userId, User updatedUser)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.id == userId);
            if (user == null)
            {
                throw new Exception("User not found");
            }
            var participants = await _context.Participants
               .Where(p => p.user_id == userId)
               .ToListAsync();
            foreach (var participant in participants)
            {
                if (participant.name != updatedUser.username)
                    participant.name = updatedUser.username;
                participant.img_url = updatedUser.avatar_url;
            }
            _context.Participants.UpdateRange(participants);
            await _context.SaveChangesAsync();

            user.username = updatedUser.username;
            user.bio = updatedUser.bio;
            user.interests = updatedUser.interests;
            user.location = updatedUser.location;
            user.birthday = updatedUser.birthday;
            user.gender = updatedUser.gender;
            user.avatar_url = updatedUser.avatar_url;

            _context.Users.Update(user);
            await _context.SaveChangesAsync();


            return user;
        }

        public async Task<User> GetUserProfileByIdAsync(int viewerId, int targetUserId)
        {
            var user = await _context.Users
                .Include(u => u.FriendshipsAsUser1)
                .Include(u => u.FriendshipsAsUser2)
                .FirstOrDefaultAsync(u => u.id == targetUserId);

            if (user == null)
                throw new Exception("User not found");

            var viewerFriends = await _context.Friends
                .Where(f => f.UserId1 == viewerId || f.UserId2 == viewerId)
                .Select(f => f.UserId1 == viewerId ? f.UserId2 : f.UserId1)
                .ToListAsync();

            var targetFriends = await _context.Friends
                .Where(f => f.UserId1 == targetUserId || f.UserId2 == targetUserId)
                .Select(f => f.UserId1 == targetUserId ? f.UserId2 : f.UserId1)
                .ToListAsync();

            user.MutualFriendsCount = viewerFriends.Intersect(targetFriends).Count();
            return user;
        }

        public async Task<string> UploadImageAsync(IFormFile file, HttpRequest request)
        {
            try
            {
                if (file == null || file.Length == 0)
                {
                    throw new Exception("No file uploaded");
                }

                if (string.IsNullOrEmpty(file.FileName))
                {
                    throw new Exception("File name is missing");
                }

                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif" };
                var fileExtension = Path.GetExtension(file.FileName).ToLower();
                if (!allowedExtensions.Contains(fileExtension))
                {
                    throw new Exception("Only image files (.jpg, .jpeg, .png, .gif) are allowed");
                }

                Console.WriteLine($"WebRootPath: {_environment.WebRootPath}"); // Thêm log
                var uploadsFolder = Path.Combine(_environment.WebRootPath, "uploads");
                Console.WriteLine($"UploadsFolder: {uploadsFolder}"); // Thêm log

                if (!Directory.Exists(uploadsFolder))
                {
                    Directory.CreateDirectory(uploadsFolder);
                }

                var fileName = Guid.NewGuid().ToString() + fileExtension;
                var filePath = Path.Combine(uploadsFolder, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                var fileUrl = $"{request.Scheme}://{request.Host}/uploads/{fileName}";
                return fileUrl;
            }
            catch (Exception ex)
            {
                throw new Exception($"Error uploading image: {ex.Message}", ex);
            }
        }
    }
}