using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.WebSockets;
using System.Threading.Tasks;

namespace server.DTO
{
    public class Client //Đại diện cho một client kết nối qua WebSocket.
    {
        public WebSocket WebSocket { get; set; }
        public int UserId { get; set; }
        public HashSet<int> ConversationIds { get; set; } = new HashSet<int>(); // Các phòng client tham gia
    }
}