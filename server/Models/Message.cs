using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace server.Models
{
    public class Message
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int id { get; set; }
        [Required]
        [MaxLength(500), MinLength(1)]
        public string content { get; set; }
        [Required]
        public int sender_id { get; set; }
        [Required]
        public bool is_read { get; set; } = false;
        public string? type { get; set; } 
        public bool isFile {get; set;} = false;
        public DateTime created_at { get; set; } = DateTime.Now;
        [Required]
        public int conversation_id { get; set; }
        [ForeignKey("sender_id")]
        public User? sender { get; set; }
      
        [ForeignKey("conversation_id")]
        public Conversation? conversation { get; set; }
        public List<Attachment>? Attachments { get; set; } = new List<Attachment>();

    }

    
}