using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace server.Models
{
    public class Friend
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required(ErrorMessage = "UserId1 is required.")]
        [ForeignKey("User1")]
        public int UserId1 { get; set; }

        [Required(ErrorMessage = "UserId2 is required.")]
        [ForeignKey("User2")]
        public int UserId2 { get; set; }

        [Required(ErrorMessage = "CreatedAt is required.")]
        public DateTime CreatedAt { get; set; }

        // Navigation properties
        public virtual User User1 { get; set; }
        public virtual User User2 { get; set; }
    }
}