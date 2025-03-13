using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using server.Data;
using server.Models;

namespace server.Services.ConversationService
{
    public class ConversationSV : IConversation
    {
        private readonly ApplicationDbContext _context;
        public ConversationSV(ApplicationDbContext context)
        {
            _context = context;
        }
        public async Task<List<Conversation>> GetConversations(int userId)
        {
            try{
                // Lấy danh sách conversation mà user_id tham gia
                var conversations = await _context.Participants
                    .Where(p => p.user_id == userId)
                    .Select(p => p.conversation)
                    .ToListAsync();

                return conversations ?? new List<Conversation>();
            }catch(Exception e){
                Console.WriteLine(e.Message);
                throw e;
            }
        }

        public async Task<Conversation> get_conversation(int conversation_id)
        {
            try{
                var conversation = await _context.Conversations.FindAsync(conversation_id);
                if(conversation == null){
                    return null;
                }
                return conversation;
            }catch(Exception ex){
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }
    }
}