using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.Models;

namespace server.DTO.AuthDTO
{
    public class OTPsRespose
    {
        public string email { get; set; }
        public string OTPCode { get; set; }
    }
}