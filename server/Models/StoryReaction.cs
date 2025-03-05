using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;

namespace server.Models
{
    public class StoryReaction
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int id { get; set; }
        public int user_id { get; set; }
        public int story_id { get; set; }
        [Required]
        public string reaction_type { get; set; } //like, love, haha, wow, sad, angry
        [Required]

        public DateTime created_at { get; set; } = DateTime.Now;
        [Required] 

        public bool is_deleted { get; set; } = false;
        [ForeignKey("user_id")]
        public User user { get; set; }
        [ForeignKey("story_id")]
        public Story story { get; set; }

    }
}