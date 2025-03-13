using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace server.Models
{
   public class Story
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int id { get; set; }
    public int user_id { get; set; }
    
    [Required]
    public string content { get; set; } //image or video url
    
    [Required]
    public DateTime created_at { get; set; } = DateTime.Now;
    
    [Required]
    public DateTime expires_at { get; set; }
    
    [ForeignKey("user_id")]
    public User user { get; set; }
    public ICollection<StoryReaction> story_reactions { get; set; }

    // Constructor mặc định
    public Story()
    {
        created_at = DateTime.UtcNow; // Thời gian hiện tại (UTC)
        expires_at = created_at.AddHours(24); // Hết hạn sau 24 giờ
    }

    
}
}