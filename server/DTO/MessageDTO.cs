using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.DTO
{
    public class MessageDTO
    {
        public string content {get; set;}
        public int sender_id {get; set;}
        public int conversation_id {get; set;}
        public int? attachment_id {get; set;}
    }
}