using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.Models;
using server.Data;
using server.DTO;
using server.Helper;
using Microsoft.EntityFrameworkCore;
using StackExchange.Redis;


namespace server.Services.UserService
{
    public class UserSV : IUserSV
    {
        private readonly ApplicationDbContext _context;
        private readonly IConnectionMultiplexer _redis;

        public UserSV(ApplicationDbContext context, IConnectionMultiplexer redis)
        {
            _context = context;
            _redis = redis;
        }

        public bool VerifyUser(UserDTO model)
        {
            if (model == null)
            {
                throw new ArgumentNullException(nameof(model));
            }
            if (string.IsNullOrEmpty(model.username)
              || string.IsNullOrEmpty(model.password)
              || string.IsNullOrEmpty(model.email)
              || string.IsNullOrEmpty(model.birthday.ToString())
              )

            {
                return false;
            }
            return true;
        }
        public async Task<User> AddUserAsync(UserDTO model)
        {
            Console.WriteLine("Received model: ok " + model);

            if (!VerifyUser(model))
            {
                throw new ArgumentNullException(nameof(model));
            }
            try
            {
                var salt = Hash.GenerateKey();
                var password = Hash.HashPassword(model.password, salt);
                var user = new User
                {
                    username = model.username,
                    password = password,
                    email = model.email,
                    avatar_url = model.avatar_url,
                    passwordSalt = salt,
                    birthday = model.birthday,
                    created_at = DateTime.Now,
                    gender = model.gender
                };
                _context.Users.Add(user);
                await _context.SaveChangesAsync();
                var db = _redis.GetDatabase();
                var userKey = $"user:by_username:{user.username}";
                await db.HashSetAsync(userKey, new HashEntry[]
                {
                    new HashEntry("id", user.id),
                    new HashEntry("username", user.username),
                    new HashEntry("avatarUrl", user.avatar_url ?? "")
                });
                return user;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public Task<User> GetUserByIdAsync(int id)
        {
            throw new NotImplementedException();
        }

        public Task<List<User>> GetUserByUsernameAsync(string username)
        {
            throw new NotImplementedException();
        }

        public async Task<User> UpdateUserAsync(int id, UserDTO model)
        {
            throw new NotImplementedException();
            // var user = await _context.Users.FindAsync(id);
            // if (user == null) throw new Exception("User not found");

            // if (!string.IsNullOrEmpty(model.username)) user.username = model.username;
            // if (!string.IsNullOrEmpty(model.email)) user.email = model.email;
            // if (!string.IsNullOrEmpty(model.avatar_url)) user.avatar_url = model.avatar_url;
            // if (model.birthday != default) user.birthday = model.birthday;
            // if (model.gender.HasValue) user.gender = model.gender.Value;

            // _context.Users.Update(user);
            // await _context.SaveChangesAsync();

            // // Đồng bộ với Redis
            // var db = _redis.GetDatabase();
            // var oldUserKey = $"user:by_username:{user.username}"; 
            // var newUserKey = $"user:by_username:{model.username ?? user.username}";
            // if (model.username != null && model.username != user.username)
            // {
            //     await db.KeyDeleteAsync(oldUserKey);
            // }
            // await db.HashSetAsync(newUserKey, new HashEntry[]
            // {
            //     new HashEntry("id", user.id),
            //     new HashEntry("username", user.username),
            //     new HashEntry("avatarUrl", user.avatar_url ?? "")
            // });

            // return user;
        }

        public Task<User> LockUserAsync(int id)
        {
            throw new NotImplementedException();
        }

        public Task<User> UnlockUserAsync(int id)
        {
            throw new NotImplementedException();
        }

        public async Task<User?> FindUserAsync(string email, string password)
        {
            if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(password))
            {
                throw new ArgumentNullException(nameof(email), "Username and password must not be empty.");
            }

            var user = await _context.Users.FirstOrDefaultAsync(x => x.email == email);
            if (user == null)
            {
                return null;
            }

            var passwordHash = Hash.HashPassword(password, user.passwordSalt);
            if (passwordHash != user.password)
            {
                return null;
            }

            return user;
        }

        public async Task<User> GetUserByEmail(string email)
        {
            return await _context.Users.FirstOrDefaultAsync(u => u.email == email);
        }

        public async Task SaveOTPAsync(OTPs otp)
        {
            _context.OTPs.Add(otp);
            await _context.SaveChangesAsync();
        }

        public async Task<OTPs> GetLatestOTPByUserIdAsync(int userId)
        {
            return await _context.OTPs
                .Where(o => o.UserId == userId)
                .OrderByDescending(o => o.ExpiryDate)
                .FirstOrDefaultAsync();
        }

        public async Task UpdateOTPAsync(OTPs otp)
        {
            _context.OTPs.Update(otp);
            await _context.SaveChangesAsync();
        }

        public async Task UpdatePassword(string email, string newPassword)
        {
            var user = await GetUserByEmail(email);
            if (user == null) throw new Exception("User not found");

            var latestOtp = await GetLatestOTPByUserIdAsync(user.id);
            if (latestOtp == null) throw new Exception("No valid OTP found");

            var allOtps = await _context.OTPs.Where(o => o.UserId == user.id).ToListAsync();
            if (allOtps.Any())
            {
                _context.OTPs.RemoveRange(allOtps);
            }

            var salt = Hash.GenerateKey();
            var passwordHash = Hash.HashPassword(newPassword, salt);

            user.password = passwordHash;
            user.passwordSalt = salt;

            _context.Users.Update(user);

            await _context.SaveChangesAsync();
            var db = _redis.GetDatabase();
            var userKey = $"user:by_username:{user.username}";
            await db.HashSetAsync(userKey, new HashEntry[]
            {
                new HashEntry("id", user.id),
                new HashEntry("username", user.username),
                new HashEntry("avatarUrl", user.avatar_url ?? "")
            });
        }

        public async Task<int> GetMutualFriendsCountAsync(int userId, int currentUserId)
        {
            // Lấy danh sách bạn bè của userId
            var friendsOfUser = await _context.Friends
                .Where(f => f.UserId1 == userId || f.UserId2 == userId)
                .Select(f => f.UserId1 == userId ? f.UserId2 : f.UserId1)
                .ToListAsync();

            // Lấy danh sách bạn bè của currentUserId
            var friendsOfCurrentUser = await _context.Friends
                .Where(f => f.UserId1 == currentUserId || f.UserId2 == currentUserId)
                .Select(f => f.UserId1 == currentUserId ? f.UserId2 : f.UserId1)
                .ToListAsync();

            // Tìm số bạn chung bằng cách giao hai danh sách
            var mutualFriendsCount = friendsOfUser.Intersect(friendsOfCurrentUser).Count();

            return mutualFriendsCount;
        }

        // Hàm mới: Xác định trạng thái quan hệ giữa hai người dùng
        public async Task<string> GetRelationshipStatusAsync(int userId, int currentUserId)
        {
            // Kiểm tra xem có yêu cầu kết bạn nào giữa hai người dùng không
            var friendRequest = await _context.FriendRequests
                .FirstOrDefaultAsync(fr => (fr.SenderId == userId && fr.ReceiverId == currentUserId) ||
                                           (fr.SenderId == currentUserId && fr.ReceiverId == userId));

            if (friendRequest != null)
            {
                if (friendRequest.Status == "Accepted") return "Friends";
                if (friendRequest.Status == "Rejected") return "Rejected";
                return friendRequest.SenderId == currentUserId ? "PendingSent" : "PendingReceived";
            }

            // Kiểm tra xem hai người dùng đã là bạn bè chưa
            var friendship = await _context.Friends
                .FirstOrDefaultAsync(f => (f.UserId1 == userId && f.UserId2 == currentUserId) ||
                                          (f.UserId1 == currentUserId && f.UserId2 == userId));

            if (friendship != null)
            {
                return "Friends";
            }

            // Nếu không có yêu cầu kết bạn và chưa là bạn bè
            return "NotFriends";
        }

        public async Task<User> ExistUser(int id)
        {
            try
            {
                var ExistUser = await _context.Users.FindAsync(id);
                return ExistUser;
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                throw e;
            }
        }
    }
}