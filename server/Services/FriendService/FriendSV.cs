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

            TimeZoneInfo vietnamTimeZone = TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time");

            var vietnamTime = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, vietnamTimeZone);

            var friendRequest = new FriendRequest
            {
                SenderId = senderId,
                ReceiverId = receiverId,
                Status = "Pending",
                CreatedAt = vietnamTime
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

            // Tạo bản ghi bạn bè
            var friendship = new Friend
            {
                UserId1 = request.SenderId,
                UserId2 = request.ReceiverId,
                CreatedAt = DateTime.UtcNow
            };
            _context.Friends.Add(friendship);

            // Xóa bản ghi FriendRequest
            _context.FriendRequests.Remove(request);

            await _context.SaveChangesAsync();

            // Gửi thông báo WebSocket
            var receiver = await _context.Users.FindAsync(request.ReceiverId);
            var message = JsonSerializer.Serialize(new
            {
                Type = "RequestAccepted",
                RequestId = request.Id,
                ReceiverId = request.ReceiverId,
                ReceiverUsername = receiver?.username,
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

            _context.FriendRequests.Remove(request);
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
            var friends = await _context.Friends
                .Where(f => f.UserId1 == userId || f.UserId2 == userId)
                .Select(f => f.UserId1 == userId ? f.User2 : f.User1)
                .ToListAsync();

            var userFriends = await _context.Friends
                .Where(f => f.UserId1 == userId || f.UserId2 == userId)
                .Select(f => f.UserId1 == userId ? f.UserId2 : f.UserId1)
                .ToListAsync();

            foreach (var friend in friends)
            {
                var friendFriends = await _context.Friends
                    .Where(f => f.UserId1 == friend.id || f.UserId2 == friend.id)
                    .Select(f => f.UserId1 == friend.id ? f.UserId2 : f.UserId1)
                    .ToListAsync();

                friend.MutualFriendsCount = userFriends.Intersect(friendFriends).Count();
            }

            return friends;
        }

        public async Task<List<User>> SearchUsersByEmailAsync(string email, int currentUserId)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                Console.WriteLine("SearchUsersByEmailAsync: Email is empty or whitespace");
                return new List<User>();
            }

            Console.WriteLine($"Starting search in database: email='{email}', currentUserId={currentUserId}");
            return await SearchUsersFromDatabaseAsync(email, currentUserId);
        }

        private async Task<List<User>> SearchUsersFromDatabaseAsync(string email, int currentUserId)
        {
            try
            {
                Console.WriteLine($"Searching database: email='{email}', excluding userId={currentUserId}");

                // Lấy danh sách bạn bè
                var friends = await _context.Friends
                    .Where(f => f.UserId1 == currentUserId || f.UserId2 == currentUserId)
                    .Select(f => f.UserId1 == currentUserId ? f.UserId2 : f.UserId1)
                    .ToListAsync();

                // Lấy danh sách lời mời đã gửi
                var sentRequests = await _context.FriendRequests
                    .Where(fr => fr.SenderId == currentUserId && fr.Status == "Pending")
                    .Select(fr => fr.ReceiverId)
                    .ToListAsync();

                // Lấy danh sách lời mời đã nhận
                var receivedRequests = await _context.FriendRequests
                    .Where(fr => fr.ReceiverId == currentUserId && fr.Status == "Pending")
                    .Select(fr => fr.SenderId)
                    .ToListAsync();

                // Tìm kiếm người dùng
                var users = await _context.Users
                    .Where(u => EF.Functions.Like(u.email, $"%{email}%") && u.id != currentUserId)
                    .OrderBy(u => u.email)
                    .Take(10)
                    .Select(u => new User
                    {
                        id = u.id,
                        username = u.username,
                        email = u.email,
                        avatar_url = u.avatar_url,
                        bio = u.bio,
                        location = u.location,
                        interests = u.interests,
                        birthday = u.birthday,
                        gender = u.gender,
                        created_at = u.created_at,
                        RelationshipStatus = friends.Contains(u.id) ? "Friend" :
                                            sentRequests.Contains(u.id) ? "SentRequest" :
                                            receivedRequests.Contains(u.id) ? "ReceivedRequest" : "None",
                        MutualFriendsCount = (
                            from f in _context.Friends
                            where (f.UserId1 == u.id || f.UserId2 == u.id)
                            select f.UserId1 == u.id ? f.UserId2 : f.UserId1
                        ).Intersect(
                            from f in _context.Friends
                            where (f.UserId1 == currentUserId || f.UserId2 == currentUserId)
                            select f.UserId1 == currentUserId ? f.UserId2 : f.UserId1
                        ).Count()
                    })
                    .ToListAsync();

                Console.WriteLine($"Database returned {users.Count} users");
                foreach (var user in users)
                {
                    Console.WriteLine($"Database user: id={user.id}, email={user.email}, username={user.username}, relationship={user.RelationshipStatus}, mutualFriends={user.MutualFriendsCount}");
                }

                return users;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Database search error: {ex.Message}");
                return new List<User>();
            }
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