using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.DTO
{
    public class MessageDTO
    {
        public string type { get; set; }
        public int sender_id { get; set; } 


        public int conversation_id { get; set; } // ID cuộc 


        public string content { get; set; } // Nội dung tin nhắn

        public DateTime created_at { get; set; } // Thời gian gửi

        public int? fileID { get; set; }
    }
}