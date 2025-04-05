public class FriendRequestDto
{
    public int Id { get; set; }
    public int SenderId { get; set; }
    public int ReceiverId { get; set; }
    public string Username { get; set; }
    public string AvatarUrl { get; set; }
    public string Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public int MutualFriendsCount { get; set; }
}