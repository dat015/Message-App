using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace server.Models
{
    public class OTPs
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        [StringLength(6, MinimumLength = 6)]
        public string OTPCode { get; set; }

        [Required]
        public DateTime ExpiryDate { get; set; }

        public bool IsUsed { get; set; } = false;

        // Quan hệ với bảng User
        [ForeignKey("UserId")]
        public virtual User User { get; set; }
    }
}