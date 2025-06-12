using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.DTO
{
    public class GroupDto
    {
        public int userId { get; set; }
        public string groupName { get; set; }
        public List<int> userIds { get; set; }
    }
}