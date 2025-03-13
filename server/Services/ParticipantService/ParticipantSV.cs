using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using server.Data;
using server.Models;

namespace server.Services.ParticipantService
{
    public class ParticipantSV : IParticipant
    {
        private readonly ApplicationDbContext _context;
        public ParticipantSV(ApplicationDbContext context)
        {
            _context = context;
        }
        public async Task<List<Participants>> GetParticipants(int conversation_id)
        {
            try
            {
                var participants = await _context.Participants
                                        .Where(p => p.conversation_id == conversation_id)
                                        .ToListAsync();
                return participants;                                                         
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }

        public async Task<List<Participants>> GetParticipantsForSender(int conversation_id, int sender_id)
        {
              try
            {
                var participants = await _context.Participants
                                        .Where(p => p.conversation_id == conversation_id && p.user_id != sender_id)
                                        .ToListAsync();
                return participants;                                                         
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw ex;
            }
        }
    }
}