using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using server.Models;

namespace server.DTO
{
    public class MessageDTOForAttachment
    {

        public int id { get; set; }
        public string content { get; set; }

        public int sender_id { get; set; }
        public bool is_read { get; set; } = false;
        public string? type { get; set; }
        public bool isFile { get; set; } = false;
        public DateTime created_at { get; set; } = DateTime.Now;
        public int conversation_id { get; set; }
        public bool isRecalled {get; set;} = false;
    }

    public class AttachmentDTOForAttachment
    {
        public int id { get; set; }
        public string file_url { get; set; }

        public float fileSize { get; set; }

        public string file_type { get; set; }
        public DateTime uploaded_at { get; set; } = DateTime.Now;
        public bool is_temporary { get; set; } = true;
        public int? message_id { get; set; }
    }

    public class MessageWithAttachment
    {
        public MessageDTOForAttachment Message { get; set; }
        public AttachmentDTOForAttachment? Attachment { get; set; }
    }
}