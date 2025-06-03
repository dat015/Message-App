using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace server.Models
{
    public class GroupSettings
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; } // Khóa chính, tự động tăng

        [Required]
        [ForeignKey("Conversation")]
        public int ConversationId { get; set; } // Khóa ngoại liên kết với Conversations


        [Required]
        public bool AllowMemberInvite { get; set; } = false;

        [Required]
        public bool AllowMemberEdit { get; set; } = false; // Tên rõ ràng hơn

        [Required]
        [ForeignKey("User")]
        public int CreatedBy { get; set; } // Khóa ngoại liên kết với Users
        [Required]
        public bool AllowMemberRemove { get; set; } = false; // Thêm trường cho phép thành viên rời nhóm

        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.Now; // Thời gian tạo, mặc định là hiện tại

        public Conversation Conversation { get; set; }
        public User User { get; set; }
    }
}