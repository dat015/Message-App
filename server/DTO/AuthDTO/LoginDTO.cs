using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.DTO.AuthDTO
{
    public class LoginDTO
    {
        public string? email { get; set; }
        public string? password { get; set; }
    }
}