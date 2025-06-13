using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace server.Services.NotificationSevice
{
    public interface INotification
    {
        Task<bool> SendNotification(int sender_id, string title, string body, string type, int id, List<int> targetUser);       
    }
}