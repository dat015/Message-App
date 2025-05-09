using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Message_app.Migrations
{
    /// <inheritdoc />
    public partial class ConversationUpdate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "lastMessage",
                table: "Conversations",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "lastMessageSender",
                table: "Conversations",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "lastMessageTime",
                table: "Conversations",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "lastMessage",
                table: "Conversations");

            migrationBuilder.DropColumn(
                name: "lastMessageSender",
                table: "Conversations");

            migrationBuilder.DropColumn(
                name: "lastMessageTime",
                table: "Conversations");
        }
    }
}
