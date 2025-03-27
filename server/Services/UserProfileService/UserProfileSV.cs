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

        public UserProfileSV(ApplicationDbContext context)
        {
            _context = context;
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
    }
}