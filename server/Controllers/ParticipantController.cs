using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using server.Data;
using server.DTO;
using server.Filters;
using server.Services.ParticipantService;

namespace server.Controllers
{
    [ApiController]
[Authorize]
    [Route("api/[controller]")]
    public class ParticipantController : ControllerBase
    {
        private readonly IParticipant participantSV;
        public ParticipantController(IParticipant participantSV)
        {
            this.participantSV = participantSV;
        }

        [HttpDelete("remove_member/{participantId}")]
        public async Task<IActionResult> RemoveMember(int participantId)
        {
            if (participantId == 0)
            {
                return BadRequest("Invalid participant id");
            }
            try
            {
                var result = await participantSV.RemoveParticipantAsync(participantId);
                if (!result)
                {
                    return BadRequest(new
                    {
                        message = "Not found participant"
                    });
                }
                return Ok(new
                {
                    message = "Remove participant successfully",
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw;
            }
        }

        [HttpDelete("leave_group/{conversation_id}/{user_id}")]
        public async Task<IActionResult> LeaveGroup(int conversation_id, int user_id)
        {
            if (conversation_id == 0 || user_id == 0)
            {
                return BadRequest("Invalid conversation id or user id");
            }
            try
            {
                var result = await participantSV.LeaveGroupAsync(conversation_id, user_id);
                if (result == null)
                {
                    return BadRequest("Not found participant");
                }
                return Ok(new
                {
                    Success = true,
                    Participant = result
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw;
            }
        }

        [HttpPost("add_member/{conversation_id}/{user_id}")]
        public async Task<IActionResult> AddMember(int conversation_id, int user_id)
        {
            if (conversation_id == 0 || user_id == 0)
            {
                return BadRequest("Invalid conversation id or user id");
            }
            try
            {
                var result = await participantSV.AddParticipantAsync(conversation_id, user_id);
                if (result == null)
                {
                    return BadRequest("Not found participant");
                }
                return Ok(new
                {
                    Success = true,
                    Participant = result
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw;
            }
        }

        [HttpPut("update_nickname/{userId}/{conversation_id}")]
        public async Task<IActionResult> UpdateNickName(int userId, int conversation_id, [FromBody] NicknameUpdateRequest request)
        {
            Console.WriteLine($"userId: {userId}, conversation_id: {conversation_id}, nickname: {request.Nickname}");
            if (conversation_id == 0 || string.IsNullOrEmpty(request.Nickname))
            {
                return BadRequest("Invalid conversation id or nickname");
            }
            try
            {
                var result = await participantSV.updateNickName(userId, conversation_id, request.Nickname);
                if (!result)
                {
                    return BadRequest("Not found participant");
                }
                return Ok(new
                {
                    Success = true
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw;
            }
        }

        [HttpGet("get_participants/{conversation_id}")]
        public async Task<IActionResult> GetParticipants(int conversation_id)
        {
            if (conversation_id == 0)
            {
                return BadRequest("Invalid conversation id");
            }

            try
            {
                var result = await participantSV.GetParticipants(conversation_id);
                if (result == null)
                {
                    return BadRequest("Not found participant");
                }
                return Ok(
                    new
                    {
                        participants = result
                    }
                );
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }

    }
}