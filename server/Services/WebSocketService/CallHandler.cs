using System;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using server.DTO;
using server.Services.WebSocketService;
using StackExchange.Redis;
using Client = server.Services.WebSocketService.Client;

public class CallHandler
{
    private readonly IDatabase _redis;
    private readonly webSocket _webSocketService;

    public CallHandler(IDatabase redis, webSocket webSocketService)
    {
        _redis = redis;
        _webSocketService = webSocketService;
    }

    public async Task HandleCallMessage(Client client, MessageDTO message)
    {
        switch (message.type)
        {
            case "startCall":
                if (message.name == null || message.offerType == null || message.sdp == null)
                {
                    Console.WriteLine("Invalid startCall message: missing required fields");
                    return;
                }
                await HandleStartCall(client, message);
                break;
            case "acceptCall":
                if (message.name == null || message.answerType == null || message.sdp == null)
                {
                    Console.WriteLine("Invalid acceptCall message: missing required fields");
                    return;
                }
                await HandleAcceptCall(client, message);
                break;
            case "offer":
                if (message.sdp == null)
                {
                    Console.WriteLine("Invalid offer message: missing sdp");
                    return;
                }
                await HandleOffer(client, message);
                break;
            case "answer":
                if (message.sdp == null)
                {
                    Console.WriteLine("Invalid answer message: missing sdp");
                    return;
                }
                await HandleAnswer(client, message);
                break;
            case "iceCandidate":
                if (message.data == null || message.data.candidate == null)
                {
                    Console.WriteLine("Invalid iceCandidate message: missing data or candidate");
                    return;
                }
                await HandleIceCandidate(client, message);
                break;
            case "endCall":
                await HandleEndCall(client, message);
                break;
            default:
                Console.WriteLine($"Unknown call message type: {message.type}");
                break;
        }
    }

    private async Task HandleStartCall(Client client, MessageDTO message)
    {
        var callKey = $"call:{message.conversation_id}";
        await _redis.HashSetAsync(callKey, new[]
        {
            new HashEntry("caller_id", message.sender_id),
            new HashEntry("status", "ringing"),
            new HashEntry("name", message.name),
            new HashEntry("offerType", message.offerType)
        });

        var receiveCallMessage = new MessageDTO
        {
            type = "receiveCall",
            sender_id = message.sender_id,
            conversation_id = message.conversation_id,
            name = message.name,
            offerType = message.offerType,
            sdp = message.sdp
        };

        var clients = GetClientsInConversation(message.conversation_id).ToList();
        Console.WriteLine($"Found {clients.Count} clients subscribed to conversation {message.conversation_id}: {string.Join(", ", clients.Select(c => c.UserId))}");
        if (clients.Count == 0 || clients.All(c => c.UserId == client.UserId))
        {
            Console.WriteLine($"No other users subscribed to conversation {message.conversation_id} to receive call.");
            await SendErrorToClient(client, "No other users in conversation to receive call.");
            await _redis.KeyDeleteAsync(callKey);
            return;
        }

        await BroadcastToConversation(client, message.conversation_id, receiveCallMessage);
    }

    private async Task HandleAcceptCall(Client client, MessageDTO message)
    {
        await _redis.HashSetAsync($"call:{message.conversation_id}", "status", "active");

        var callAcceptedMessage = new MessageDTO
        {
            type = "callAccepted",
            sender_id = message.sender_id,
            conversation_id = message.conversation_id,
            name = message.name,
            answerType = message.answerType,
            sdp = message.sdp
        };

        await SendToCaller(client, message.conversation_id, callAcceptedMessage);
    }

    private async Task HandleOffer(Client client, MessageDTO message)
    {
        await BroadcastToConversation(client, message.conversation_id, message);
    }

    private async Task HandleAnswer(Client client, MessageDTO message)
    {
        await SendToCaller(client, message.conversation_id, message);
    }

    private async Task HandleIceCandidate(Client client, MessageDTO message)
    {
        await BroadcastToConversation(client, message.conversation_id, message);
    }

    private async Task HandleEndCall(Client client, MessageDTO message)
    {
        await _redis.KeyDeleteAsync($"call:{message.conversation_id}");

        var endCallMessage = new MessageDTO
        {
            type = "callEnded",
            sender_id = message.sender_id,
            conversation_id = message.conversation_id
        };

        await BroadcastToConversation(client, message.conversation_id, endCallMessage);
    }

    private async Task BroadcastToConversation(Client sender, int conversationId, MessageDTO message)
    {
        var clients = GetClientsInConversation(conversationId).ToList();
        Console.WriteLine($"Broadcasting to {clients.Count} clients subscribed to conversation {conversationId}: {string.Join(", ", clients.Select(c => c.UserId))}");
        foreach (var client in clients)
        {
            if (client != sender && client.WebSocket.State == WebSocketState.Open)
            {
                try
                {
                    var json = JsonSerializer.Serialize(message);
                    await client.WebSocket.SendAsync(
                        new ArraySegment<byte>(Encoding.UTF8.GetBytes(json)),
                        WebSocketMessageType.Text,
                        true,
                        CancellationToken.None);
                    Console.WriteLine($"Sent message to client {client.UserId}: {json}");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error broadcasting to client {client.UserId}: {ex.Message}");
                }
            }
        }
    }

    private async Task SendToCaller(Client sender, int conversationId, MessageDTO message)
    {
        var callerId = await _redis.HashGetAsync($"call:{conversationId}", "caller_id");
        var caller = GetClientByUserId((int)callerId);
        if (caller != null && caller.WebSocket.State == WebSocketState.Open)
        {
            var json = JsonSerializer.Serialize(message);
            await caller.WebSocket.SendAsync(
                new ArraySegment<byte>(Encoding.UTF8.GetBytes(json)),
                WebSocketMessageType.Text,
                true,
                CancellationToken.None);
        }
    }

    private IEnumerable<Client> GetClientsInConversation(int conversationId)
    {
        return _webSocketService.GetClientsInConversation(conversationId);
    }

    private Client GetClientByUserId(int userId)
    {
        return _webSocketService.GetClient(userId);
    }

    private async Task SendErrorToClient(Client client, string errorMessage)
    {
        var error = new MessageDTO
        {
            type = "error",
            conversation_id = client.ConversationIds.FirstOrDefault(),
            sender_id = -1,
            content = errorMessage
        };
        var json = JsonSerializer.Serialize(error);
        await client.WebSocket.SendAsync(
            new ArraySegment<byte>(Encoding.UTF8.GetBytes(json)),
            WebSocketMessageType.Text,
            true,
            CancellationToken.None);
    }
}