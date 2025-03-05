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
        public bool Privacy { get; set; } = false;

        [Required]
        public bool AllowMemberInvite { get; set; } = true;

        [Required]
        public bool AllowMemberEdit { get; set; } = true; // Tên rõ ràng hơn

        [Required]
        [ForeignKey("User")]
        public int CreatedBy { get; set; } // Khóa ngoại liên kết với Users

        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.Now; // Thời gian tạo, mặc định là hiện tại

        [Required]
        public bool IsActive { get; set; } = true; // Trạng thái hoạt động

        [MaxLength(255)] // Giới hạn độ dài URL/hình ảnh
        public string ImageUrl { get; set; } // URL hoặc đường dẫn hình ảnh
        public Conversation Conversation { get; set; }
        public User User { get; set; }
    }
}