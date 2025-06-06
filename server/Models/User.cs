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
        [MaxLength(450)]
        public string email { get; set; }

        [Url(ErrorMessage = "Invalid URL format.")]
        public string avatar_url { get; set;}
        [Required]
        public DateOnly birthday { get; set; }
        public DateTime created_at { get; set; }
        [Required]
        public bool gender {get; set;}

        [StringLength(500, ErrorMessage = "Interests cannot exceed 500 characters.")]
        public string? interests { get; set; }

        [StringLength(100, ErrorMessage = "Location cannot exceed 100 characters.")]
        public string? location { get; set; } 

        [StringLength(500, ErrorMessage = "Bio cannot exceed 500 characters.")]
        public string? bio { get; set; } 
        
        [NotMapped]
        public int? MutualFriendsCount { get; set; }
        
        [NotMapped]
        public string RelationshipStatus { get; set; }
        public ICollection<Notification>? notifications { get; set; }
        public ICollection<Role_of_User>? role_of_users { get; set; }
        public ICollection<Message>? messages { get; set; }
        public ICollection<Participants>? participants { get; set; }
        public ICollection<GroupSettings>? groupSettings { get; set; }
        public ICollection<MessageStatus>? messageStatuses { get; set; }
        [InverseProperty("Sender")]
        public ICollection<FriendRequest>? SentFriendRequests { get; set; }

        [InverseProperty("Receiver")]
        public ICollection<FriendRequest>? ReceivedFriendRequests { get; set; }

        [InverseProperty("User1")]
        public ICollection<Friend>? FriendshipsAsUser1 { get; set; }

        [InverseProperty("User2")]
        public ICollection<Friend>? FriendshipsAsUser2 { get; set; }
    }
}