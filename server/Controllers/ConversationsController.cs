using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using server.Data;
using server.DTO;
using server.Filters;
using server.Services.ConversationService;

namespace server.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class ConversationController : ControllerBase
    {
        private readonly IConversation _conversationService;
        public ConversationController(IConversation conversationService)
        {
            _conversationService = conversationService;
        }

        [HttpPost("create_group")]
        public async Task<IActionResult> CreateGroup([FromBody] GroupDto groupDto)
        {
            if (groupDto == null || groupDto.userIds == null || groupDto.userIds.Count == 0)
            {
                return BadRequest("Invalid group data");
            }
            try
            {
                var result = await _conversationService.CreateGroup(groupDto);
                return Ok(result);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }

        [HttpPut("update_conversation_image/{conversation_id}")]
        public async Task<IActionResult> UpdateConversationImage(int conversation_id, [FromBody] string image)
        {
            if (conversation_id == 0 || string.IsNullOrEmpty(image))
            {
                return BadRequest("Invalid conversation id or image");
            }
            try
            {
                var result = await _conversationService.UpdateConversationImage(conversation_id, image);
                if (result == null)
                {
                    return BadRequest("Not found conversation");
                }
                return Ok(result);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }

        [HttpGet("open_conversation/{user1}/{user2}")]
        public async Task<IActionResult> OpenConversation(int user1, int user2)
        {
            if (user1 == 0 || user2 == 0)
            {
                return BadRequest("Invalid user id");
            }
            try
            {
                var result = await _conversationService.CreateConversation(user1, user2);
                return Ok(result);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw;
            }
        }
        [HttpGet("get_conversationDto/{userId}/{conversationId}")]
        public async Task<IActionResult> GetConversation(int userId, int conversationId)
        {
            try
            {
                var conversation = await _conversationService.GetConversationDto(userId, conversationId);
                if (conversation == null)
                {
                    return NotFound(new { message = "Conversation not found" });
                }
                return Ok(conversation);
            }
            catch (Exception e)
            {
                return StatusCode(500, new { message = "Internal server error", error = e.Message });
            }
        }

        [HttpPut("update_conversation_name/{conversation_id}")]
        public async Task<IActionResult> UpdateConversationName(int conversation_id, [FromBody] string name)
        {
            if (conversation_id == 0 || string.IsNullOrEmpty(name))
            {
                return BadRequest("Invalid conversation id or name");
            }
            try
            {
                var result = await _conversationService.UpdateConversationName(conversation_id, name);
                if (result == null)
                {
                    return BadRequest("Not found conversation");
                }
                return Ok(result);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }
        [HttpGet("get_conversations/{userId}")]
        public async Task<IActionResult> GetConversations(int userId)
        {
            if (userId == 0)
            {
                return BadRequest("Invalid user");
            }
            try
            {
                var conversations = await _conversationService.GetConversations(userId);

                return Ok(conversations);
            }
            catch (Exception e)
            {
                return BadRequest(e.Message);
            }
        }

        [HttpGet("get_first_conversation/{conversation_id}")]
        public async Task<IActionResult> GetFirstConversation(int conversation_id)
        {
            if (conversation_id == 0)
            {
                return BadRequest("Invalid conversation id");
            }
            try
            {
                var result = await _conversationService.get_conversation(conversation_id);
                if (result == null)
                {
                    return BadRequest("Not found conversation");
                }
                return Ok(result);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }

    }
}