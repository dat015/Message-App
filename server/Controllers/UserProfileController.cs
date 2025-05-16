using Microsoft.AspNetCore.Mvc;
using server.Models;
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

        [HttpPut("update/profile/{userId}")]
        public async Task<IActionResult> UpdateProfile(int userId, [FromBody] UpdateProfileDTO updateProfileDTO)
        {
            if (updateProfileDTO == null)
            {
                return BadRequest(new { message = "Invalid profile data" });
            }

            // 🔍 Log dữ liệu nhận được từ client
            Console.WriteLine("== Received UpdateProfileDTO ==");
            Console.WriteLine($"UserId: {userId}");
            Console.WriteLine($"Username: {updateProfileDTO.Username}");
            Console.WriteLine($"Bio: {updateProfileDTO.Bio}");
            Console.WriteLine($"Interests: {updateProfileDTO.Interests}");
            Console.WriteLine($"Location: {updateProfileDTO.Location}");
            Console.WriteLine($"Birthday: {updateProfileDTO.Birthday}");
            Console.WriteLine($"Gender: {updateProfileDTO.gender}");
            Console.WriteLine($"AvatarUrl: {updateProfileDTO.AvatarUrl}");

            var updatedUser = new User
            {
                id = userId,
                username = updateProfileDTO.Username,
                bio = updateProfileDTO.Bio,
                interests = updateProfileDTO.Interests,
                location = updateProfileDTO.Location,
                birthday = updateProfileDTO.Birthday,
                gender = updateProfileDTO.gender,
                avatar_url = updateProfileDTO.AvatarUrl
            };

            try
            {
                var user = await _userProfileService.UpdateProfile(userId, updatedUser);
                return Ok(new { message = "Profile updated successfully", user });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Error updating profile: {ex.Message}");
                return BadRequest(new { message = ex.Message });
            }
        }


        [HttpPost("upload")]
        public async Task<IActionResult> UploadImage(IFormFile file)
        {
            try
            {
                var fileUrl = await _userProfileService.UploadImageAsync(file, Request);
                return Ok(new { url = fileUrl });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error uploading image", error = ex.Message });
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