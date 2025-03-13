using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using server.Data;
using server.Models;

namespace server.Services.MessageService
{
    public class MessagesV : IMessage
    {
        private readonly ApplicationDbContext _context;
        public MessagesV(ApplicationDbContext context)
        {
            _context = context;
        }
        public async Task addNewMessage(Message message)
        {
            try
            {
                await _context.Messages.AddAsync(message);
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }

        public async Task<List<Message>> getMessages(int conversation_id)
        {
            try
            {
                var messages = await _context.Messages
                                    .Where(m => m.conversation_id == conversation_id)
                                    .ToListAsync();
                return messages;
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }
    }
}