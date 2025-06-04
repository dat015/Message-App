using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using server.DTO;
using server.Filters;
using server.Services.GroupSettingService;

namespace server.Controllers
{
    [ApiController]
    [AuthorizationJWT]
    [Route("api/[controller]")]
    public class GroupSettingController : ControllerBase
    {
        private readonly IGroupSetting _groupSettingService;
        public GroupSettingController(IGroupSetting groupSettingService)
        {
            _groupSettingService = groupSettingService ?? throw new ArgumentNullException(nameof(groupSettingService), "Group setting service cannot be null");
        }
        [HttpGet("get/{conversationId}")]
        public async Task<IActionResult> GetGroupSetting(int conversationId)
        {
            if (conversationId <= 0)
            {
                return BadRequest(new
                {
                    message = "ConversationId must be a positive integer"
                });
            }

            try
            {
                var groupSetting = await _groupSettingService.GetGroupSettingByConversationIdAsync(conversationId);
                if (groupSetting == null)
                {
                    return NotFound(new
                    {
                        message = "Group setting not found"
                    });
                }
                return Ok(new
                {
                    data = groupSetting
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
        [HttpPost("create")]
        public async Task<IActionResult> CreateGroupSetting([FromBody] GroupSettingDTO dto)
        {
            if (dto == null)
            {
                return BadRequest(new
                {
                    message = "GroupSettingDTO cannot be null"
                });
            }

            try
            {
                var result = await _groupSettingService.CreateGroupSettingAsync(dto);
                if (result)
                {
                    return Ok(new
                    {
                        message = "Group setting created successfully",
                    });
                }
                else
                {
                    return StatusCode(500, "Failed to create group setting");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
        [HttpPut("update")]
        public async Task<IActionResult> UpdateGroupSetting([FromBody] GroupSettingDTO dto)
        {
            if (dto == null)
            {
                return BadRequest(new
                {
                    message = "GroupSettingDTO cannot be null"
                });
            }

            try
            {
                var result = await _groupSettingService.UpdateGroupSettingAsync(dto);
                if (result)
                {
                    return Ok(new
                    {
                        message = "Group setting updated successfully",
                    });
                }
                else
                {
                    return StatusCode(500, "Failed to update group setting");
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}