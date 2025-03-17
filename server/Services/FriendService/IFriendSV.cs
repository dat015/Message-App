using server.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace server.Services
{
    public interface IFriendSV
    {
        Task SendFriendRequestAsync(int senderId, int receiverId);
        Task<List<FriendRequest>> GetPendingRequestsAsync(int userId);
        Task AcceptFriendRequestAsync(int requestId);
        Task RejectFriendRequestAsync(int requestId);
        Task<List<User>> GetFriendsAsync(int userId);
    }
}