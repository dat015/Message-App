using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace server.DTO
{
    public class UserDTO
    {
        public string? username { get; set; }
        [Required]
        [MinLength(8, ErrorMessage = "Mật khẩu phải có ít nhất 8 ký tự.")]
        [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$",
       ErrorMessage = "Mật khẩu phải có ít nhất một chữ hoa, một chữ thường, một số và một ký tự đặc biệt.")]
        public string? password { get; set; }
        public string? email { get; set; }
        public string? avatar_url { get; set; }
        public DateOnly birthday { get; set; }
        public bool gender { get; set; }
    }
}