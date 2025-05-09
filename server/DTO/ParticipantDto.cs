using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.DTO
{
    public class ParticipantDto
    {
        public int Id { get; set; }
        public int user_id { get; set; }
        public int ConversationId { get; set; }
        public string Name { get; set; }
        public bool IsDeleted { get; set; }
        public string img_url { get; set; } = null;
    }
}