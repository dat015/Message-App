using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using server.Data;
using server.Services.ParticipantService;

namespace server.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ParticipantController : ControllerBase
    {
        private readonly IParticipant participantSV;
        public ParticipantController(IParticipant participantSV)
        {
            this.participantSV = participantSV;
        }

        [HttpGet("get_participants/{conversation_id}")]
        public async Task<IActionResult> GetParticipants(int conversation_id){
            if(conversation_id == 0){
                return BadRequest("Invalid conversation id");
            }

            try{
                var result = await participantSV.GetParticipants(conversation_id);
                if(result == null){
                    return BadRequest("Not found participant");
                }
                return Ok(
                    new {
                        participants = result
                    }
                );
            }
            catch(Exception ex){
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }

    }
}