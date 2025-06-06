using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace server.Models
{
        public class Participants
        {
                [Key]
                [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
                public int id { get; set; }
                [Required]
                public int conversation_id { get; set; }
                [Required]
                public int user_id { get; set; }
                public string? role { get; set; }
                public string? name { get; set; }
                [Required]
                public DateTime joined_at { get; set; } = DateTime.Now;
                public string adder { get; set; } = "NO";
                public string? img_url { get; set; } = null;
                [Required]
                public bool is_deleted { get; set; } = false;
                [ForeignKey("conversation_id")]
                public Conversation conversation { get; set; }
                [ForeignKey("user_id")]
                public User user { get; set; }
        }
}