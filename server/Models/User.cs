using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace server.Models
{
    public class User
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int id { get; set; }
        [Required(ErrorMessage = "Username is required.")]
        [StringLength(200, ErrorMessage = "Username cannot exceed 200 characters.")]
        [MinLength(3, ErrorMessage = "Username must be at least 3 characters.")]
        public string username { get; set; }

        [Required(ErrorMessage = "Password is required.")]
        [MinLength(6, ErrorMessage = "Password must be at least 6 characters.")]
        public string password { get; set; }

        public string passwordSalt { get; set; }

        [Required(ErrorMessage = "Email is required.")]
        [EmailAddress(ErrorMessage = "Invalid email format.")]
        public string email { get; set; }

        [Url(ErrorMessage = "Invalid URL format.")]
        public string avatar_url { get; set;}
        [Required]
        public DateOnly birthday { get; set; }
        public DateTime created_at { get; set; }
        [Required]
        public bool gender {get; set;}

        public ICollection<Story>? stories { get; set; }
        public ICollection<StoryReaction>? storyReactions { get; set; }
        public ICollection<Notification>? notifications { get; set; }
        public ICollection<Role_of_User>? role_of_users { get; set; }
        public ICollection<Message>? messages { get; set; }
        public ICollection<Participants>? participants { get; set; }
        public ICollection<StoryViewers>? storyViewers { get; set; }
        public ICollection<GroupSettings>? groupSettings { get; set; }
        public ICollection<MessageStatus>? messageStatuses { get; set; }

    }
}