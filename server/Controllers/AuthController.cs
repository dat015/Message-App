using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using server.DTO;
using server.DTO.AuthDTO;
using server.Models;
using server.Services.AuthService;

namespace Message_app.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthSV _authSV;
        public AuthController(IAuthSV authSV)
        {
            _authSV = authSV ?? throw new ArgumentNullException(nameof(authSV));
            Console.WriteLine("_authSV is initialized successfully");
        }
        [HttpPost("register")]
        public async Task<IActionResult> Register( UserDTO model)
        {
        
            Console.WriteLine("Received model: ok " + model.password);
            if (model == null)
            {
                return BadRequest("Invalid client request");
            }
            var user = await _authSV.RegisterUser(model);
            if (user == null)
            {
                return BadRequest("Invalid client request");
            }
            return Ok(user);
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDTO model)
        {
            if (model == null)
            {
                return BadRequest("Invalid client request");
            }
            var user = await _authSV.VerifyUser(model);
            if (user == null)
            {
                return BadRequest("Invalid client request");
            }
            Console.Write("ok");
            return Ok(user);
        }
    }
}