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
            public DbSet<OTPs> OTPs { get; set; }
            public DbSet<FriendRequest> FriendRequests { get; set; }
            public DbSet<Friend> Friends { get; set; }
            public DbSet<MessageDeletion> messageDeletions { get; set; }
            protected override void OnModelCreating(ModelBuilder modelBuilder)
            {
                  modelBuilder.Entity<FriendRequest>(entity =>
                  {
                        entity.HasKey(fr => fr.Id);

                        entity.HasOne(fr => fr.Sender)
                        .WithMany(u => u.SentFriendRequests)
                        .HasForeignKey(fr => fr.SenderId)
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                        entity.HasOne(fr => fr.Receiver)
                        .WithMany(u => u.ReceivedFriendRequests)
                        .HasForeignKey(fr => fr.ReceiverId)
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                        entity.Property(fr => fr.Status)
                        .HasMaxLength(20)
                        .IsRequired();

                        entity.Property(fr => fr.CreatedAt)
                        .IsRequired();

                        entity.HasCheckConstraint("CK_FriendRequest_SenderReceiver", "[SenderId] != [ReceiverId]");
                  });

                  modelBuilder.Entity<Friend>(entity =>
                  {
                        entity.HasKey(f => f.Id);

                        entity.HasOne(f => f.User1)
                        .WithMany(u => u.FriendshipsAsUser1)
                        .HasForeignKey(f => f.UserId1)
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                        entity.HasOne(f => f.User2)
                        .WithMany(u => u.FriendshipsAsUser2)
                        .HasForeignKey(f => f.UserId2)
                        .OnDelete(DeleteBehavior.Restrict)
                        .IsRequired();

                        entity.Property(f => f.CreatedAt)
                        .IsRequired();

                        entity.HasCheckConstraint("CK_Friends_User1User2", "[UserId1] != [UserId2]");

                        entity.HasIndex(f => new { f.UserId1, f.UserId2 }).IsUnique();
                  });

                  base.OnModelCreating(modelBuilder);
            }
      }
}
