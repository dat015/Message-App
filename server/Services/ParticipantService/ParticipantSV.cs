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

        public async Task<List<Participants>> AddParticipantRangeAsync(int conversation_id, List<int> user_id)
        {
            if(conversation_id == 0 || user_id.Count == 0){
                return null;
            }
            try{
                var participants = new List<Participants>();
                foreach(var id in user_id){
                    var participant = new Participants
                    {
                        conversation_id = conversation_id,
                        user_id = id
                    };
                    participants.Add(participant);
                }
                await _context.Participants.AddRangeAsync(participants);
                await _context.SaveChangesAsync();
                return participants;
            }
            catch(Exception e){
                Console.WriteLine(e.Message);
                throw e;
            }
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