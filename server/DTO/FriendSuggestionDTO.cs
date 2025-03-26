public class FriendSuggestionDto
{
    public int UserId { get; set; }
    public string Username { get; set; }
    public string AvatarUrl { get; set; }
    public int MutualFriendsCount { get; set; }
    public int CommonInterestsCount { get; set; }
    public bool SameLocation { get; set; }
    public string Bio { get; set; }
}