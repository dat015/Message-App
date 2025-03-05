﻿// <auto-generated />
using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using server.Data;

#nullable disable

namespace Message_app.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20250304142412_upadateTables")]
    partial class upadateTables
    {
        /// <inheritdoc />
        protected override void BuildTargetModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "9.0.2")
                .HasAnnotation("Relational:MaxIdentifierLength", 128);

            SqlServerModelBuilderExtensions.UseIdentityColumns(modelBuilder);

            modelBuilder.Entity("server.Models.Attachment", b =>
                {
                    b.Property<int>("id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("id"));

                    b.Property<float>("FileSize")
                        .HasColumnType("real");

                    b.Property<string>("file_type")
                        .IsRequired()
                        .HasMaxLength(50)
                        .HasColumnType("nvarchar(50)");

                    b.Property<string>("file_url")
                        .IsRequired()
                        .HasMaxLength(255)
                        .HasColumnType("nvarchar(255)");

                    b.Property<DateTime>("uploaded_at")
                        .HasColumnType("datetime2");

                    b.HasKey("id");

                    b.ToTable("Attachments");
                });

            modelBuilder.Entity("server.Models.Conversation", b =>
                {
                    b.Property<int>("id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("id"));

                    b.Property<DateTime>("created_at")
                        .HasColumnType("datetime2");

                    b.Property<bool>("is_group")
                        .HasColumnType("bit");

                    b.Property<string>("name")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("nvarchar(100)");

                    b.HasKey("id");

                    b.ToTable("Conversations");
                });

            modelBuilder.Entity("server.Models.GroupSettings", b =>
                {
                    b.Property<int>("Id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("Id"));

                    b.Property<bool>("AllowMemberEdit")
                        .HasColumnType("bit");

                    b.Property<bool>("AllowMemberInvite")
                        .HasColumnType("bit");

                    b.Property<int>("ConversationId")
                        .HasColumnType("int");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("datetime2");

                    b.Property<int>("CreatedBy")
                        .HasColumnType("int");

                    b.Property<string>("ImageUrl")
                        .IsRequired()
                        .HasMaxLength(255)
                        .HasColumnType("nvarchar(255)");

                    b.Property<bool>("IsActive")
                        .HasColumnType("bit");

                    b.Property<bool>("Privacy")
                        .HasColumnType("bit");

                    b.HasKey("Id");

                    b.HasIndex("ConversationId");

                    b.HasIndex("CreatedBy");

                    b.ToTable("GroupSettings");
                });

            modelBuilder.Entity("server.Models.Message", b =>
                {
                    b.Property<int>("id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("id"));

                    b.Property<int>("attachment_id")
                        .HasColumnType("int");

                    b.Property<string>("content")
                        .IsRequired()
                        .HasMaxLength(500)
                        .HasColumnType("nvarchar(500)");

                    b.Property<int>("conversation_id")
                        .HasColumnType("int");

                    b.Property<DateTime>("created_at")
                        .HasColumnType("datetime2");

                    b.Property<bool>("is_read")
                        .HasColumnType("bit");

                    b.Property<int>("sender_id")
                        .HasColumnType("int");

                    b.HasKey("id");

                    b.HasIndex("attachment_id");

                    b.HasIndex("conversation_id");

                    b.HasIndex("sender_id");

                    b.ToTable("Messages");
                });

            modelBuilder.Entity("server.Models.MessageStatus", b =>
                {
                    b.Property<int>("id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("id"));

                    b.Property<int?>("Userid")
                        .HasColumnType("int");

                    b.Property<int>("message_id")
                        .HasColumnType("int");

                    b.Property<int>("receiver_id")
                        .HasColumnType("int");

                    b.Property<string>("status")
                        .IsRequired()
                        .HasMaxLength(50)
                        .HasColumnType("nvarchar(50)");

                    b.Property<DateTime>("updated_at")
                        .HasColumnType("datetime2");

                    b.HasKey("id");

                    b.HasIndex("Userid");

                    b.ToTable("MessageStatus");
                });

            modelBuilder.Entity("server.Models.Notification", b =>
                {
                    b.Property<int>("id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("id"));

                    b.Property<string>("content")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("created_at")
                        .HasColumnType("datetime2");

                    b.Property<bool>("is_seen")
                        .HasColumnType("bit");

                    b.Property<int>("related_id")
                        .HasColumnType("int");

                    b.Property<string>("related_type")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("user_id")
                        .HasColumnType("int");

                    b.HasKey("id");

                    b.HasIndex("user_id");

                    b.ToTable("Notifications");
                });

            modelBuilder.Entity("server.Models.Participants", b =>
                {
                    b.Property<int>("id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("id"));

                    b.Property<int>("conversation_id")
                        .HasColumnType("int");

                    b.Property<bool>("is_deleted")
                        .HasColumnType("bit");

                    b.Property<DateTime>("joined_at")
                        .HasColumnType("datetime2");

                    b.Property<int>("user_id")
                        .HasColumnType("int");

                    b.HasKey("id");

                    b.HasIndex("conversation_id");

                    b.HasIndex("user_id");

                    b.ToTable("Participants");
                });

            modelBuilder.Entity("server.Models.Role", b =>
                {
                    b.Property<int>("id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("id"));

                    b.Property<string>("role_name")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.HasKey("id");

                    b.ToTable("Role");
                });

            modelBuilder.Entity("server.Models.Role_of_User", b =>
                {
                    b.Property<int>("id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("id"));

                    b.Property<int>("role_id")
                        .HasColumnType("int");

                    b.Property<int>("user_id")
                        .HasColumnType("int");

                    b.HasKey("id");

                    b.HasIndex("role_id");

                    b.HasIndex("user_id");

                    b.ToTable("Role_of_User");
                });

            modelBuilder.Entity("server.Models.Story", b =>
                {
                    b.Property<int>("id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("id"));

                    b.Property<string>("content")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateTime>("created_at")
                        .HasColumnType("datetime2");

                    b.Property<DateTime>("expires_at")
                        .HasColumnType("datetime2");

                    b.Property<int>("user_id")
                        .HasColumnType("int");

                    b.HasKey("id");

                    b.HasIndex("user_id");

                    b.ToTable("Stories");
                });

            modelBuilder.Entity("server.Models.StoryReaction", b =>
                {
                    b.Property<int>("id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("id"));

                    b.Property<DateTime>("created_at")
                        .HasColumnType("datetime2");

                    b.Property<bool>("is_deleted")
                        .HasColumnType("bit");

                    b.Property<string>("reaction_type")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<int>("story_id")
                        .HasColumnType("int");

                    b.Property<int>("user_id")
                        .HasColumnType("int");

                    b.HasKey("id");

                    b.HasIndex("story_id");

                    b.HasIndex("user_id");

                    b.ToTable("StoryReactions");
                });

            modelBuilder.Entity("server.Models.StoryViewers", b =>
                {
                    b.Property<int>("id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("id"));

                    b.Property<int>("story_id")
                        .HasColumnType("int");

                    b.Property<int>("user_id")
                        .HasColumnType("int");

                    b.Property<DateTime>("viewed_at")
                        .HasColumnType("datetime2");

                    b.HasKey("id");

                    b.HasIndex("story_id");

                    b.HasIndex("user_id");

                    b.ToTable("StoryViewers");
                });

            modelBuilder.Entity("server.Models.User", b =>
                {
                    b.Property<int>("id")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("int");

                    SqlServerPropertyBuilderExtensions.UseIdentityColumn(b.Property<int>("id"));

                    b.Property<string>("avatar_url")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<DateOnly>("birthday")
                        .HasColumnType("date");

                    b.Property<DateTime>("created_at")
                        .HasColumnType("datetime2");

                    b.Property<string>("email")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<bool>("gender")
                        .HasColumnType("bit");

                    b.Property<string>("password")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("passwordSalt")
                        .IsRequired()
                        .HasColumnType("nvarchar(max)");

                    b.Property<string>("username")
                        .IsRequired()
                        .HasMaxLength(200)
                        .HasColumnType("nvarchar(200)");

                    b.HasKey("id");

                    b.ToTable("Users");
                });

            modelBuilder.Entity("server.Models.GroupSettings", b =>
                {
                    b.HasOne("server.Models.Conversation", "Conversation")
                        .WithMany("GroupSettings")
                        .HasForeignKey("ConversationId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("server.Models.User", "User")
                        .WithMany("groupSettings")
                        .HasForeignKey("CreatedBy")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("Conversation");

                    b.Navigation("User");
                });

            modelBuilder.Entity("server.Models.Message", b =>
                {
                    b.HasOne("server.Models.Attachment", "attachment")
                        .WithMany()
                        .HasForeignKey("attachment_id")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("server.Models.Conversation", "conversation")
                        .WithMany("Messages")
                        .HasForeignKey("conversation_id")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("server.Models.User", "sender")
                        .WithMany("messages")
                        .HasForeignKey("sender_id")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("attachment");

                    b.Navigation("conversation");

                    b.Navigation("sender");
                });

            modelBuilder.Entity("server.Models.MessageStatus", b =>
                {
                    b.HasOne("server.Models.User", null)
                        .WithMany("messageStatuses")
                        .HasForeignKey("Userid");
                });

            modelBuilder.Entity("server.Models.Notification", b =>
                {
                    b.HasOne("server.Models.User", "user")
                        .WithMany("notifications")
                        .HasForeignKey("user_id")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("user");
                });

            modelBuilder.Entity("server.Models.Participants", b =>
                {
                    b.HasOne("server.Models.Conversation", "conversation")
                        .WithMany()
                        .HasForeignKey("conversation_id")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("server.Models.User", "user")
                        .WithMany("participants")
                        .HasForeignKey("user_id")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("conversation");

                    b.Navigation("user");
                });

            modelBuilder.Entity("server.Models.Role_of_User", b =>
                {
                    b.HasOne("server.Models.Role", "role")
                        .WithMany("role_Of_Users")
                        .HasForeignKey("role_id")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("server.Models.User", "user")
                        .WithMany("role_of_users")
                        .HasForeignKey("user_id")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("role");

                    b.Navigation("user");
                });

            modelBuilder.Entity("server.Models.Story", b =>
                {
                    b.HasOne("server.Models.User", "user")
                        .WithMany("stories")
                        .HasForeignKey("user_id")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("user");
                });

            modelBuilder.Entity("server.Models.StoryReaction", b =>
                {
                    b.HasOne("server.Models.Story", "story")
                        .WithMany("story_reactions")
                        .HasForeignKey("story_id")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("server.Models.User", "user")
                        .WithMany("storyReactions")
                        .HasForeignKey("user_id")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("story");

                    b.Navigation("user");
                });

            modelBuilder.Entity("server.Models.StoryViewers", b =>
                {
                    b.HasOne("server.Models.Story", "story")
                        .WithMany()
                        .HasForeignKey("story_id")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.HasOne("server.Models.User", "user")
                        .WithMany("storyViewers")
                        .HasForeignKey("user_id")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("story");

                    b.Navigation("user");
                });

            modelBuilder.Entity("server.Models.Conversation", b =>
                {
                    b.Navigation("GroupSettings");

                    b.Navigation("Messages");
                });

            modelBuilder.Entity("server.Models.Role", b =>
                {
                    b.Navigation("role_Of_Users");
                });

            modelBuilder.Entity("server.Models.Story", b =>
                {
                    b.Navigation("story_reactions");
                });

            modelBuilder.Entity("server.Models.User", b =>
                {
                    b.Navigation("groupSettings");

                    b.Navigation("messageStatuses");

                    b.Navigation("messages");

                    b.Navigation("notifications");

                    b.Navigation("participants");

                    b.Navigation("role_of_users");

                    b.Navigation("stories");

                    b.Navigation("storyReactions");

                    b.Navigation("storyViewers");
                });
#pragma warning restore 612, 618
        }
    }
}
