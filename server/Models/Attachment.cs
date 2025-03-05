using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace server.Models
{
    public class Attachment
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int id { get; set; }
        [Required]
        [MaxLength(255), MinLength(1)]
        public string file_url { get; set; }
        [Required]
        [Range(0.01, 49.99)] // Áp dụng giới hạn nhỏ hơn 50MB (ví dụ, tối đa 49.99MB)
        public float FileSize { get; set; }
        [Required]
        [MaxLength(50)]        
        public string file_type { get; set; }
        [Required]
        public DateTime uploaded_at { get; set; } = DateTime.Now;
    }
}