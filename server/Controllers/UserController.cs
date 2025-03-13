using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using server.Data;
using server.Models;
using server.Services.UserService;

namespace server.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IUserSV userSV;
        public UserController(ApplicationDbContext context, IUserSV userSV)
        {
            _context = context;
            this.userSV = userSV;
        }
        [HttpGet("getUser/{user_id}")]
        public async Task<IActionResult> GetUser(int user_id){
            if(user_id == 0){
                return BadRequest("Invalid user id");
            }
            try{
                var result = await userSV.GetUserByIdAsync(user_id);
                if(result == null){
                    return BadRequest("Not found user");
                }
                return Ok(result);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
            }
            catch(Exception ex){
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }
    }
}