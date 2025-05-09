public class MessageDTO
{
    public string type { get; set; }
    public int sender_id { get; set; }
    public int conversation_id { get; set; }
    public string content { get; set; }
    public DateTime created_at { get; set; }
    public int? fileID { get; set; }
    public int? recipient_id { get; set; }
    public string name { get; set; }
    public string offerType { get; set; }
    public object sdp { get; set; }
    public string answerType { get; set; }
    public IceCandidateData data { get; set; } // Thay iceCandidate bằng data
}

public class IceCandidateData
{
    public string candidate { get; set; }
    public string sdpMid { get; set; }
    public int sdpMLineIndex { get; set; }
}