using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.DTO;
using server.Models;

namespace server.Services.UserService
{
    public interface IUserSV
    {
        Task<User> AddUserAsync(UserDTO model);
        Task<User> GetUserByIdAsync(int id);
        Task<List<User>> GetUserByUsernameAsync(string username);
        Task<User> UpdateUserAsync(int id, UserDTO model);
        Task<User> LockUserAsync(int id);
        Task<User> UnlockUserAsync(int id);
        Task<User?> FindUserAsync(string username, string password);
        bool VerifyUser(UserDTO model);
        Task<User> GetUserByEmail(string email);
        Task SaveOTPAsync(OTPs otp);
        Task<OTPs> GetLatestOTPByUserIdAsync(int userId);
        Task UpdateOTPAsync(OTPs otp);
        Task UpdatePassword(string email, string password);
        Task<User> ExistUser(int id);
        Task<int> GetMutualFriendsCountAsync(int userId, int currentUserId);
        Task<string> GetRelationshipStatusAsync(int userId, int currentUserId);
    }
}