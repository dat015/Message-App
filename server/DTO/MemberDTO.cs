    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading.Tasks;
    using Microsoft.Identity.Client;

    namespace server.DTO
    {
        public class MemberDTO
        {
            
            public int id { get; set; }      
            public string username { get; set; }       
            public string avatar_url { get; set;}
            public string adder { get; set; } = "NO"; 
            public int user_id { get; set; }
            public int conversation_id { get; set; }

        }
    }