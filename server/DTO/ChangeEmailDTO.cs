namespace server.DTO
{
    public class ChangeEmailDTO
    {
        public string CurrentEmail { get; set; }
        public string NewEmail { get; set; }
    }

    public class SendOtpDTO
    {
        public string Email { get; set; }
    }

    public class VerifyOtpDTO
    {
        public string Email { get; set; }
        public string OtpCode { get; set; }
    }
}