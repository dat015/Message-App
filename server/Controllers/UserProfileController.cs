using Microsoft.AspNetCore.Mvc;
using server.Services;
using System.Threading.Tasks;

namespace server.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserProfileController : ControllerBase
    {
        private readonly IUserProfileSV _userProfileService;

        public UserProfileController(IUserProfileSV userProfileService)
        {
            _userProfileService = userProfileService;
        }

        [HttpGet("{userId}/profile")]
        public async Task<IActionResult> GetUserProfile(int userId)
        {
            try
            {
                var user = await _userProfileService.GetUserProfileAsync(userId);
                return Ok(new
                {
                    user.id,
                    user.username,
                    user.email,
                    user.avatar_url,
                    user.birthday,
                    user.created_at,
                    user.gender,
                    user.interests,
                    user.location,
                    user.bio,
                    friendsCount = user.MutualFriendsCount
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("view/{targetUserId}")]
        public async Task<IActionResult> GetUserProfileById(int targetUserId, [FromQuery] int viewerId)
        {
            try
            {
                var user = await _userProfileService.GetUserProfileByIdAsync(viewerId, targetUserId);
                return Ok(new   
                {
                    user.id,
                    user.username,
                    user.email,
                    user.avatar_url,
                    user.birthday,
                    user.created_at,
                    user.gender,
                    user.interests,
                    user.location,
                    user.bio,
                    mutualFriendsCount = user.MutualFriendsCount
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}