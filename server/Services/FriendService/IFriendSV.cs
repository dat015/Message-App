using server.DTO;
using server.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace server.Services
{
    public interface IFriendSV
    {
        Task SendFriendRequestAsync(int senderId, int receiverId);
        Task AcceptFriendRequestAsync(int requestId);
        Task RejectFriendRequestAsync(int requestId);
        Task<List<User>> GetFriendsAsync(int userId);
        Task<List<User>> SearchUsersByUsernameAsync(string usernameQuery, int currentUserId);
        Task<bool> CancelFriendRequestAsync(int senderId, int receiverId);
        Task<List<FriendRequestDto>> GetReceivedFriendRequestsAsync(int userId);
        Task<List<FriendSuggestionDto>> GetFriendSuggestionsAsync(int userId);
        Task<List<FriendRequestDto>> GetSentFriendRequestsAsync(int userId);
        Task<bool> UnfriendAsync(int userId, int friendId);
        Task SyncUsersToRedisAsync();
        Task<List<FriendDTO>> GetAllFriendsAsync(int userId);
    }
}