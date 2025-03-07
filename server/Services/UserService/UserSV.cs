using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.Models;
using server.Data;
using server.DTO;
using server.Helper;
using Microsoft.EntityFrameworkCore;


namespace server.Services.UserService
{
    public class UserSV(ApplicationDbContext context) : IUserSV
    {
        private readonly ApplicationDbContext _context = context;

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

        public Task<User> UpdateUserAsync(int id, UserDTO model)
        {
            throw new NotImplementedException();
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
        }
    }
}