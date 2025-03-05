using Microsoft.EntityFrameworkCore;
using server.Models;

namespace server.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Attachment> Attachments { get; set; }
        public DbSet<Conversation> Conversations { get; set; }
        public DbSet<Message> Messages { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<GroupSettings> GroupSettings { get; set; }
        public DbSet<MessageStatus> MessageStatus { get; set; }
        public DbSet<Participants> Participants { get; set; }
        public DbSet<Role_of_User> Role_of_User { get; set; }
        public DbSet<Role> Role { get; set; }
        public DbSet<Story> Stories { get; set; }
        public DbSet<StoryReaction> StoryReactions { get; set; }
        public DbSet<StoryViewers> StoryViewers { get; set; }
    }
}
