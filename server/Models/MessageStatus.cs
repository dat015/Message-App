using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace server.Models
{
    public class MessageStatus
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int id {get; set;}
        [ForeignKey("Message")]
        public int message_id {get; set;}
        [ForeignKey("User")]

        public int receiver_id {get; set;}
        [Required]
        [MaxLength(50)]
        public string status {get; set;}
        [Required]
        public DateTime updated_at {get; set;} = DateTime.Now;
    }
}