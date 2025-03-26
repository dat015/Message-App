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
    public class FriendSV : IFriendSV
    {
        private readonly ApplicationDbContext _context;
        private readonly IWebSocketFriendSV _webSocketFriendSV;
        private readonly IConnectionMultiplexer _redis;

        public FriendSV(ApplicationDbContext context, IWebSocketFriendSV webSocketFriendSV, IConnectionMultiplexer redis)
        {
            _context = context;
            _webSocketFriendSV = webSocketFriendSV;
            _redis = redis;
        }

        public async Task SendFriendRequestAsync(int senderId, int receiverId)
        {
            if (senderId == receiverId)
                throw new ArgumentException("Cannot send friend request to yourself");

            var existingRequest = await _context.FriendRequests
                .FirstOrDefaultAsync(fr => fr.SenderId == senderId && fr.ReceiverId == receiverId && fr.Status == "Pending");
            if (existingRequest != null)
                throw new InvalidOperationException("Friend request already sent");

            var friendRequest = new FriendRequest
            {
                SenderId = senderId,
                ReceiverId = receiverId,
                Status = "Pending",
                CreatedAt = DateTime.UtcNow
            };

            _context.FriendRequests.Add(friendRequest);
            await _context.SaveChangesAsync();

            var sender = await _context.Users.FindAsync(senderId);
            var message = JsonSerializer.Serialize(new
            {
                Type = "FriendRequest",
                RequestId = friendRequest.Id,
                SenderId = senderId,
                SenderUsername = sender.username,
                CreatedAt = friendRequest.CreatedAt.ToString("o")
            });
            await _webSocketFriendSV.SendFriendRequestNotificationAsync(receiverId, message);
        }

        public async Task AcceptFriendRequestAsync(int requestId)
        {
            var request = await _context.FriendRequests
                .Include(fr => fr.Sender)
                .FirstOrDefaultAsync(fr => fr.Id == requestId);
            if (request == null || request.Status != "Pending")
                throw new InvalidOperationException("Invalid or already processed friend request");

            request.Status = "Accepted";
            var friendship = new Friend
            {
                UserId1 = request.SenderId,
                UserId2 = request.ReceiverId,
                CreatedAt = DateTime.UtcNow
            };

            _context.Friends.Add(friendship);
            await _context.SaveChangesAsync();

            var receiver = await _context.Users.FindAsync(request.ReceiverId);
            var message = JsonSerializer.Serialize(new
            {
                Type = "RequestAccepted",
                RequestId = request.Id,
                ReceiverId = request.ReceiverId,
                ReceiverUsername = receiver.username,
                CreatedAt = DateTime.UtcNow.ToString("o")
            });
            await _webSocketFriendSV.SendRequestAcceptedNotificationAsync(request.SenderId, message);
        }

        public async Task RejectFriendRequestAsync(int requestId)
        {
            var request = await _context.FriendRequests
                .Include(fr => fr.Sender)
                .FirstOrDefaultAsync(fr => fr.Id == requestId);
            if (request == null || request.Status != "Pending")
                throw new InvalidOperationException("Invalid or already processed friend request");

            request.Status = "Rejected";
            await _context.SaveChangesAsync();

            var receiver = await _context.Users.FindAsync(request.ReceiverId);
            var message = JsonSerializer.Serialize(new
            {
                Type = "RequestRejected",
                RequestId = request.Id,
                ReceiverId = request.ReceiverId,
                ReceiverUsername = receiver.username,
                CreatedAt = DateTime.UtcNow.ToString("o")
            });
            await _webSocketFriendSV.SendRequestRejectedNotificationAsync(request.SenderId, message);
        }

        public async Task<List<User>> GetFriendsAsync(int userId)
        {
            return await _context.Friends
                .Where(f => f.UserId1 == userId || f.UserId2 == userId)
                .Select(f => f.UserId1 == userId ? f.User2 : f.User1)
                .ToListAsync();
        }

        public async Task<List<User>> SearchUsersByUsernameAsync(string usernameQuery, int currentUserId)
        {
            if (string.IsNullOrWhiteSpace(usernameQuery))
                return new List<User>();

            try
            {
                var db = _redis.GetDatabase();

                var query = $"%{usernameQuery}% -@id:{currentUserId}";
                var result = await db.ExecuteAsync("FT.SEARCH", "user_idx", query, "SORTBY", "username", "ASC", "LIMIT", "0", "10");

                var users = new List<User>();
                var resultArray = (RedisResult[])result;
                int totalResults = (int)resultArray[0];
                if (totalResults == 0) return users;

                for (int i = 1; i < resultArray.Length; i += 2)
                {
                    var values = (RedisResult[])resultArray[i + 1];
                    var dict = new Dictionary<string, string>();
                    for (int j = 0; j < values.Length; j += 2)
                    {
                        dict[values[j].ToString()] = values[j + 1].ToString();
                    }

                    var userId = int.Parse(dict["id"]);
                    users.Add(new User
                    {
                        id = userId,
                        username = dict["username"],
                        avatar_url = dict["avatarUrl"]
                    });
                }

                return users;
            }
            catch (RedisConnectionException ex)
            {
                Console.WriteLine($"Redis error: {ex.Message}. Falling back to database.");
                return await SearchUsersFromDatabaseAsync(usernameQuery, currentUserId);
            }
            catch (RedisTimeoutException ex)
            {
                Console.WriteLine($"Redis timeout: {ex.Message}. Falling back to database.");
                return await SearchUsersFromDatabaseAsync(usernameQuery, currentUserId);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Unexpected Redis error: {ex.Message}. Falling back to database.");
                return await SearchUsersFromDatabaseAsync(usernameQuery, currentUserId);
            }
        }

        private async Task<List<User>> SearchUsersFromDatabaseAsync(string usernameQuery, int currentUserId)
        {
            return await _context.Users
                .Where(u => u.username.Contains(usernameQuery) && u.id != currentUserId)
                .Select(u => new User
                {
                    id = u.id,
                    username = u.username,
                    avatar_url = u.avatar_url
                })
                .Take(10)
                .ToListAsync();
        }

        public async Task<bool> CancelFriendRequestAsync(int senderId, int receiverId)
        {
            var request = await _context.FriendRequests
                .FirstOrDefaultAsync(fr => fr.SenderId == senderId && fr.ReceiverId == receiverId);

            if (request == null)
                throw new InvalidOperationException("No friend request found between these users.");

            if (request.Status != "Pending")
                throw new InvalidOperationException($"Cannot cancel request. Current status: {request.Status}");

            _context.FriendRequests.Remove(request);
            await _context.SaveChangesAsync();

            var receiver = await _context.Users.FindAsync(receiverId);
            if (receiver == null)
                throw new InvalidOperationException("Receiver not found.");

            var message = JsonSerializer.Serialize(new
            {
                Type = "RequestCancelled",
                RequestId = request.Id,
                SenderId = senderId,
                ReceiverId = receiverId,
                ReceiverUsername = receiver.username,
                CreatedAt = DateTime.UtcNow.ToString("o"),
                NewStatus = "NotSent"
            });

            await _webSocketFriendSV.SendRequestCancelledNotificationAsync(receiverId, message);
            await _webSocketFriendSV.SendRequestCancelledNotificationAsync(senderId, message);

            return true;
        }

        public async Task<List<FriendRequestDto>> GetReceivedFriendRequestsAsync(int userId)
        {
            var requestsQuery = await _context.FriendRequests
                .Where(fr => fr.ReceiverId == userId && fr.Status == "Pending")
                .Include(fr => fr.Sender)
                .Select(fr => new FriendRequestDto
                {
                    Id = fr.Id,
                    SenderId = fr.SenderId,
                    ReceiverId = fr.ReceiverId,
                    Username = fr.Sender.username,
                    AvatarUrl = fr.Sender.avatar_url,
                    Status = fr.Status,
                    CreatedAt = fr.CreatedAt,
                    MutualFriendsCount = 0
                })
                .ToListAsync();

            foreach (var request in requestsQuery)
            {
                var senderFriends = await _context.Friends
                    .Where(f => f.UserId1 == request.SenderId || f.UserId2 == request.SenderId)
                    .Select(f => f.UserId1 == request.SenderId ? f.UserId2 : f.UserId1)
                    .ToListAsync();

                var receiverFriends = await _context.Friends
                    .Where(f => f.UserId1 == userId || f.UserId2 == userId)
                    .Select(f => f.UserId1 == userId ? f.UserId2 : f.UserId1)
                    .ToListAsync();

                request.MutualFriendsCount = senderFriends.Intersect(receiverFriends).Count();
            }

            return requestsQuery.Take(1000).ToList();
        }

        public async Task<List<FriendSuggestionDto>> GetFriendSuggestionsAsync(int userId)
        {
            var currentUser = await _context.Users.FirstOrDefaultAsync(u => u.id == userId);
            if (currentUser == null)
            {
                throw new Exception("User not found");
            }

            var userInterests = currentUser.interests?.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList() ?? new List<string>();
            var userLocation = currentUser.location;

            var userFriends = await _context.Friends
                .Where(f => f.UserId1 == userId || f.UserId2 == userId)
                .Select(f => f.UserId1 == userId ? f.UserId2 : f.UserId1)
                .ToListAsync();

            var friendsOfFriends = new Dictionary<int, int>();
            foreach (var friendId in userFriends)
            {
                var fof = await _context.Friends
                    .Where(f => (f.UserId1 == friendId || f.UserId2 == friendId) && f.UserId1 != userId && f.UserId2 != userId)
                    .Select(f => f.UserId1 == friendId ? f.UserId2 : f.UserId1)
                    .ToListAsync();

                foreach (var fofId in fof)
                {
                    if (fofId != userId && !userFriends.Contains(fofId))
                    {
                        friendsOfFriends[fofId] = friendsOfFriends.ContainsKey(fofId) ? friendsOfFriends[fofId] + 1 : 1;
                    }
                }
            }

            var sentRequests = await _context.FriendRequests
                .Where(fr => fr.SenderId == userId)
                .Select(fr => fr.ReceiverId)
                .ToListAsync();

            var receivedRequests = await _context.FriendRequests
                .Where(fr => fr.ReceiverId == userId)
                .Select(fr => fr.SenderId)
                .ToListAsync();

            var excludedUserIds = userFriends
                .Concat(sentRequests)
                .Concat(receivedRequests)
                .Concat(new List<int> { userId })
                .Distinct()
                .ToList();

            var suggestions = new List<FriendSuggestionDto>();
            foreach (var fof in friendsOfFriends.Where(f => !excludedUserIds.Contains(f.Key)))
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => u.id == fof.Key);
                if (user != null)
                {
                    var fofInterests = user.interests?.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList() ?? new List<string>();
                    var commonInterests = userInterests.Intersect(fofInterests).Count();
                    var sameLocation = userLocation != null && user.location != null && userLocation == user.location ? 1 : 0;

                    var score = fof.Value * 0.5 + commonInterests * 0.3 + sameLocation * 0.2;

                    suggestions.Add(new FriendSuggestionDto
                    {
                        UserId = user.id,
                        Username = user.username,
                        AvatarUrl = user.avatar_url,
                        MutualFriendsCount = fof.Value,
                        CommonInterestsCount = commonInterests,
                        SameLocation = sameLocation == 1,
                        Bio = user.bio
                    });
                }
            }

            return suggestions
                .OrderByDescending(s => s.MutualFriendsCount * 0.5 + s.CommonInterestsCount * 0.3 + (s.SameLocation ? 1 : 0) * 0.2)
                .Take(50)
                .ToList();
        }

        public async Task<List<FriendRequestDto>> GetSentFriendRequestsAsync(int userId)
        {
            var requestsQuery = await _context.FriendRequests
                .Where(fr => fr.SenderId == userId && fr.Status == "Pending")
                .Include(fr => fr.Receiver)
                .Select(fr => new FriendRequestDto
                {
                    Id = fr.Id,
                    SenderId = fr.SenderId,
                    ReceiverId = fr.ReceiverId,
                    Username = fr.Receiver.username,
                    AvatarUrl = fr.Receiver.avatar_url,
                    Status = fr.Status,
                    CreatedAt = fr.CreatedAt,
                    MutualFriendsCount = 0 
                })
                .ToListAsync();

            foreach (var request in requestsQuery)
            {
                var senderFriends = await _context.Friends
                    .Where(f => f.UserId1 == userId || f.UserId2 == userId)
                    .Select(f => f.UserId1 == userId ? f.UserId2 : f.UserId1)
                    .ToListAsync();

                var receiverFriends = await _context.Friends
                    .Where(f => f.UserId1 == request.ReceiverId || f.UserId2 == request.ReceiverId)
                    .Select(f => f.UserId1 == request.ReceiverId ? f.UserId2 : f.UserId1)
                    .ToListAsync();

                request.MutualFriendsCount = senderFriends.Intersect(receiverFriends).Count();
            }

            return requestsQuery.Take(1000).ToList();
        }

        public async Task<bool> UnfriendAsync(int userId, int friendId)
        {
            if (userId == friendId)
                throw new ArgumentException("Cannot unfriend yourself");

            var friendship = await _context.Friends
                .FirstOrDefaultAsync(f =>
                    (f.UserId1 == userId && f.UserId2 == friendId) ||
                    (f.UserId1 == friendId && f.UserId2 == userId));

            if (friendship == null)
                throw new InvalidOperationException("Friendship not found");

            _context.Friends.Remove(friendship);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task SyncUsersToRedisAsync()
        {
            try
            {
                var db = _redis.GetDatabase();
                var users = await _context.Users
                    .Select(u => new { u.id, u.username, u.avatar_url })
                    .ToListAsync();

                await db.ExecuteAsync("FT.DROPINDEX", "user_idx", "DD");
                foreach (var user in users)
                {
                    var userKey = $"user:by_username:{user.username}";
                    await db.HashSetAsync(userKey, new HashEntry[]
                    {
                        new HashEntry("id", user.id),
                        new HashEntry("username", user.username),
                        new HashEntry("avatarUrl", user.avatar_url ?? "")
                    });
                }
                await db.ExecuteAsync("FT.CREATE", "user_idx", "ON", "HASH", "PREFIX", "1", "user:by_username:",
                    "SCHEMA", "username", "TEXT", "SORTABLE", "id", "NUMERIC", "SORTABLE", "avatarUrl", "TEXT");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Failed to sync users to Redis: {ex.Message}");
            }
        }
    }
}