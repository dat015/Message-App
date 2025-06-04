using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.DTO
{
    public class NotificationDTO
    {
        public int sender_id { get; set; }
        public string title { get; set; }
        public string body { get; set; }
        public string type { get; set; }
        public int id { get; set; }
        public List<int> targetUser { get; set; }
    }
}