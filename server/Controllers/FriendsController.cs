using Microsoft.AspNetCore.Mvc;
using server.Services;
using System.Threading.Tasks;

namespace server.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FriendsController : ControllerBase
    {
        private readonly IFriendSV _friendService;

        public FriendsController(IFriendSV friendService)
        {
            _friendService = friendService;
        }

        // Gửi lời mời kết bạn
        [HttpPost("send-request")]
        public async Task<IActionResult> SendFriendRequest([FromBody] FriendRequestDto request)
        {
            await _friendService.SendFriendRequestAsync(request.SenderId, request.ReceiverId);
            return Ok(new { Message = "Friend request sent successfully" });
        }

        // Lấy danh sách lời mời kết bạn đang chờ
        [HttpGet("requests/{userId}")]
        public async Task<IActionResult> GetPendingRequests(int userId)
        {
            var requests = await _friendService.GetPendingRequestsAsync(userId);
            return Ok(requests);
        }

        // Chấp nhận lời mời kết bạn
        [HttpPost("accept-request/{requestId}")]
        public async Task<IActionResult> AcceptFriendRequest(int requestId)
        {
            await _friendService.AcceptFriendRequestAsync(requestId);
            return Ok(new { Message = "Friend request accepted" });
        }

        // Từ chối lời mời kết bạn
        [HttpPost("reject-request/{requestId}")]
        public async Task<IActionResult> RejectFriendRequest(int requestId)
        {
            await _friendService.RejectFriendRequestAsync(requestId);
            return Ok(new { Message = "Friend request rejected" });
        }

        // Lấy danh sách bạn bè
        [HttpGet("list/{userId}")]
        public async Task<IActionResult> GetFriends(int userId)
        {
            var friends = await _friendService.GetFriendsAsync(userId);
            return Ok(friends);
        }
    }
}