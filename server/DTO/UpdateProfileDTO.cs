public class UpdateProfileDTO
{
    public string Username { get; set; }
    public string Bio { get; set; }
    public string? AvatarUrl { get; set; }
    public string Interests { get; set; }
    public string Location { get; set; }
    public DateOnly Birthday { get; set; }
    public bool gender { get; set; }
}
