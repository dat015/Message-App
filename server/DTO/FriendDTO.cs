using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.DTO
{
    public class FriendDTO
    {
        public string username { get; set; }
        public string avatar { get; set; }
        public int friendId { get; set; }
        public int userId { get; set; }
    }
}