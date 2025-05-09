using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace server.Models
{
    public class Conversation
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int id { get; set; }
        [Required]
        [MaxLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
        public string name {get; set;}
        [Required]
        public bool is_group {get; set;} = false;
        [Required]
        public DateTime created_at {get; set;}
        public DateTime? lastMessageTime {get; set;}= null;
        public string? lastMessage {get; set;}= null;
        public string? lastMessageSender {get; set;}= null;
        public string? img_url {get; set;}= null;
        public ICollection<Message>? Messages {get; set;}
        public ICollection<GroupSettings>? GroupSettings {get; set;}
        public ICollection<Participants>? Participants {get; set;}
    }
}