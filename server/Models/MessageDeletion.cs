using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace server.Models
{
    public class MessageDeletion // chỉ cần ẩn tất cả tin nhắn trước thời điểm xóa
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int id { get; set; }

        [Required]
        public int user_id { get; set; }

        [Required]
        public int conversation_id { get; set; }
        [Required]
        public DateTime cleared_at { get; set; } = DateTime.Now;
        [ForeignKey("user_id")]
        public User user { get; set; }

        [ForeignKey("conversation_id")]
        public Conversation conversation { get; set; }
    }
}