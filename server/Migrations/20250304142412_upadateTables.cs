using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Message_app.Migrations
{
    /// <inheritdoc />
    public partial class upadateTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Conversations_Conversations_Conversationid",
                table: "Conversations");

            migrationBuilder.DropIndex(
                name: "IX_Conversations_Conversationid",
                table: "Conversations");

            migrationBuilder.DropColumn(
                name: "Conversationid",
                table: "Conversations");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Conversationid",
                table: "Conversations",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Conversations_Conversationid",
                table: "Conversations",
                column: "Conversationid");

            migrationBuilder.AddForeignKey(
                name: "FK_Conversations_Conversations_Conversationid",
                table: "Conversations",
                column: "Conversationid",
                principalTable: "Conversations",
                principalColumn: "id");
        }
    }
}
