using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace server.DTO
{
    public class AttachmentDTO
    {
        public string file_url { get; set; }
  
        public float FileSize { get; set; }
      
        public string file_type { get; set; }
        
    }
}