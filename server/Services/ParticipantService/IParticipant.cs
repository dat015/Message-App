using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.Models;

namespace server.Services.ParticipantService
{
    public interface IParticipant
    {
        Task<List<Participants>> GetParticipants(int conversation_id);
        Task<List<Participants>> GetParticipantsForSender(int conversation_id, int sender_id);
        Task<List<Participants>> AddParticipantRangeAsync(int conversation_id, List<int> user_id);
        Task<Participants> AddParticipantAsync(int conversation_id, int user_id);
        Task<bool> updateNickName(int user_id, int conversation_id, string nickname);
        Task<Participants> LeaveGroupAsync(int conversation_id, int user_id);
        Task<bool> RemoveParticipantAsync(int participantId);

    }
}