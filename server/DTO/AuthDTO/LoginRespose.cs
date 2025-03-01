using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.Models;

namespace server.DTO.AuthDTO
{
    public class LoginRespose
    {
        public User? user { get; set; }
        public string? token { get; set; }
    }
}