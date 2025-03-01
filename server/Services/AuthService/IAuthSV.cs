using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.DTO;
using server.DTO.AuthDTO;
using server.Models;

namespace server.Services.AuthService
{
    public interface IAuthSV
    {
        Task<LoginRespose> VerifyUser(LoginDTO model);
        Task<User> RegisterUser(UserDTO model);
        
    }
}