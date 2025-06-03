using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace server.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RoomsController : ControllerBase
    {
        private static readonly Dictionary<string, List<string>> Rooms = new();

        [HttpPost("create")]
        public IActionResult CreateRoom([FromBody] RoomRequest request)
        {
            Rooms[request.RoomId] = new List<string> { request.UserName };
            return Ok();
        }

        [HttpPost("join")]
        public IActionResult JoinRoom([FromBody] RoomRequest request)
        {
            if (!Rooms.ContainsKey(request.RoomId))
                return NotFound("Phòng không tồn tại");

            Rooms[request.RoomId].Add(request.UserName);
            return Ok(Rooms[request.RoomId]);
        }

        [HttpPost("leave")]
        public IActionResult LeaveRoom([FromBody] RoomRequest request)
        {
            if (Rooms.ContainsKey(request.RoomId))
            {
                Rooms[request.RoomId].Remove(request.UserName);
                if (!Rooms[request.RoomId].Any())
                    Rooms.Remove(request.RoomId);
            }
            return Ok();
        }
    }

    public class RoomRequest
    {
        public string RoomId { get; set; }
        public string UserName { get; set; }
    }
}