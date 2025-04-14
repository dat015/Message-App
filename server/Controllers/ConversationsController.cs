using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using server.Data;
using server.Services.ConversationService;

namespace server.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ConversationController : ControllerBase
    {
        private readonly IConversation _conversationService;
        public ConversationController(IConversation conversationService)
        {
            _conversationService = conversationService;
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