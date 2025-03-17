using Microsoft.EntityFrameworkCore;
using server.Data;
using server.Models;
using System.Text.Json;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;

namespace server.Services
{
    public class FriendSV : IFriendSV
    {
        private readonly ApplicationDbContext _context;
        private readonly IWebSocketFriendSV _webSocketFriendSV;

        public FriendSV(ApplicationDbContext context, IWebSocketFriendSV webSocketFriendSV)
        {
            _context = context;
            _webSocketFriendSV = webSocketFriendSV;
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

        public async Task<List<FriendRequest>> GetPendingRequestsAsync(int userId)
        {
            return await _context.FriendRequests
                .Where(fr => fr.ReceiverId == userId && fr.Status == "Pending")
                .ToListAsync();
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
    }
}