using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.DTO
{
    public class ConversationDto
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public bool IsGroup { get; set; }
        public DateTime CreatedAt { get; set; }
        public string LastMessage { get; set; }
        public int? LastMessageSender { get; set; }
        public DateTime? LastMessageTime { get; set; }
        public List<ParticipantDto> Participants { get; set; }
    }
}