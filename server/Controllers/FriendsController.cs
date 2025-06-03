using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using server.Filters;
using server.Services;
using System.Threading.Tasks;

namespace server.Controllers
{
    [Route("api/[controller]")]
    [AuthorizationJWT]
    [ApiController]
    public class FriendsController : ControllerBase
    {
        private readonly IFriendSV _friendService;

        public FriendsController(IFriendSV friendService)
        {
            _friendService = friendService;
        }


        [HttpGet("GetAllFriends/{userId}")]
        public async Task<IActionResult> GetAllFriends(int userId)
        {
            try
            {
                var friends = await _friendService.GetAllFriendsAsync(userId);
                return Ok(new { success = true, friends });
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }

        // Gửi lời mời kết bạn
        [HttpPost("send-request")]
        public async Task<IActionResult> SendFriendRequest([FromBody] FriendRequestDto request)
        {
            try
            {
                await _friendService.SendFriendRequestAsync(request.SenderId, request.ReceiverId);
                return Ok(new { message = "Friend request sent successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred", details = ex.Message });
            }
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

        [HttpGet("list/{userId}")]
        public async Task<IActionResult> GetFriendsAsync(int userId)
        {
            try
            {
                var friends = await _friendService.GetFriendsAsync(userId);
                return Ok(new { success = true, friends });
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }
        
        [HttpGet("search")]
        public async Task<IActionResult> SearchUsers([FromQuery] string email, [FromQuery] int senderId)
        {
            try
            {
                var users = await _friendService.SearchUsersByEmailAsync(email, senderId);
                return Ok(users);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while searching users", details = ex.Message });
            }
        }

        [HttpPost("cancel-request")]
        public async Task<IActionResult> CancelFriendRequest([FromBody] CancelFriendDTO request)
        {
            var result = await _friendService.CancelFriendRequestAsync(request.SenderId, request.ReceiverId);
            return Ok(new { success = true, message = "Friend request cancelled" });
        }

        [HttpGet("requests/received/{userId}")]
        public async Task<IActionResult> GetReceivedFriendRequests(int userId)
        {
            try
            {
                var requests = await _friendService.GetReceivedFriendRequestsAsync(userId);
                return Ok(new { success = true, requests });
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }

        [HttpGet("suggestions/{userId}")]
        public async Task<IActionResult> GetFriendSuggestions(int userId)
        {
            try
            {
                var suggestions = await _friendService.GetFriendSuggestionsAsync(userId);
                return Ok(new { success = true, suggestions });
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }

        [HttpGet("get-sent-requests/{userId}")]
        public async Task<IActionResult> GetSentFriendRequests(int userId)
        {
            try
            {
                var sentRequests = await _friendService.GetSentFriendRequestsAsync(userId);
                return Ok(new { success = true, sentRequests });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("unfriend")]
        public async Task<IActionResult> Unfriend([FromBody] UnfriendDTO request)
        {
            try
            {
                var result = await _friendService.UnfriendAsync(request.UserId, request.FriendId);
                return Ok(new { success = true, message = "Successfully unfriended" });
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return NotFound(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = "Internal server error", error = ex.Message });
            }
        }
    }
}