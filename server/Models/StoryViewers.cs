using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace server.Models
{
    public class StoryViewers
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int id { get; set; }
        public int story_id { get; set;}
        public int user_id { get; set; }
        public DateTime viewed_at { get; set; } = DateTime.Now;
        [ForeignKey("story_id")]
        public Story story { get; set; }
        [ForeignKey("user_id")]
        public User user { get; set; }
    }
}