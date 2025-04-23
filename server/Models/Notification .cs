using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace server.Models
{
    public class Notification
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int id { get; set; }
        [Required]
        public string related_type { get; set; } 
        [Required]
        public string content { get; set; }
        [Required]
        public DateTime created_at { get; set; }= DateTime.Now;
        [Required]
        public int user_id { get; set; }
        [Required]
        public bool is_seen { get; set; } = false;
        [Required]
        public int related_id { get; set; } //id of related object
        [ForeignKey("user_id")]
        public User user { get; set; }
    }
}