using server.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace server.Services
{
    public interface IUserProfileSV
    {
        public Task<User> GetUserProfileAsync(int userId);
        public Task<User> GetUserProfileByIdAsync(int viewerId, int targetUserId);
    }
}