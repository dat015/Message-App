using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Net.WebSockets;
using System.Threading.Tasks;

namespace server.Services.WebSocketService
{
    public class WebSocketConnectionManager
    {
        private readonly ConcurrentDictionary<int, Client> _userClients = new();
        private readonly ConcurrentDictionary<int, HashSet<int>> _conversationMembers = new();

        public bool AddClient(Client client)
        {
            if (client.UserId == 0) return false;
            return _userClients.TryAdd(client.UserId, client);
        }

        public bool RemoveClient(int userId)
        {
            return _userClients.TryRemove(userId, out _);
        }

        public Client GetClient(int userId)
        {
            _userClients.TryGetValue(userId, out var client);
            return client;
        }

        public IEnumerable<Client> GetClientsInConversation(int conversationId)
        {
            if (_conversationMembers.TryGetValue(conversationId, out var memberIds))
            {
                return memberIds
                    .Select(id => GetClient(id))
                    .Where(c => c != null && c.WebSocket.State == WebSocketState.Open);
            }
            return Enumerable.Empty<Client>();
        }

        public void AddToConversation(int conversationId, int userId)
        {
            _conversationMembers.AddOrUpdate(conversationId,
                new HashSet<int> { userId },
                (_, set) => { set.Add(userId); return set; });
        }

        public void RemoveFromConversation(int conversationId, int userId)
        {
            if (_conversationMembers.TryGetValue(conversationId, out var members))
            {
                members.Remove(userId);
                if (members.Count == 0)
                {
                    _conversationMembers.TryRemove(conversationId, out _);
                }
            }
        }

        public IEnumerable<int> GetConversationsForUser(int userId)
        {
            return _conversationMembers
                .Where(kvp => kvp.Value.Contains(userId))
                .Select(kvp => kvp.Key);
        }
    }
}