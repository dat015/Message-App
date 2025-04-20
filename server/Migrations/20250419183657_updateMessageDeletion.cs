using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Message_app.Migrations
{
    /// <inheritdoc />
    public partial class updateMessageDeletion : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_messageDeletions_Messages_message_id",
                table: "messageDeletions");

            migrationBuilder.RenameColumn(
                name: "message_id",
                table: "messageDeletions",
                newName: "conversation_id");

            migrationBuilder.RenameColumn(
                name: "deleted_at",
                table: "messageDeletions",
                newName: "cleared_at");

            migrationBuilder.RenameIndex(
                name: "IX_messageDeletions_message_id",
                table: "messageDeletions",
                newName: "IX_messageDeletions_conversation_id");

            migrationBuilder.AddForeignKey(
                name: "FK_messageDeletions_Conversations_conversation_id",
                table: "messageDeletions",
                column: "conversation_id",
                principalTable: "Conversations",
                principalColumn: "id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_messageDeletions_Conversations_conversation_id",
                table: "messageDeletions");

            migrationBuilder.RenameColumn(
                name: "conversation_id",
                table: "messageDeletions",
                newName: "message_id");

            migrationBuilder.RenameColumn(
                name: "cleared_at",
                table: "messageDeletions",
                newName: "deleted_at");

            migrationBuilder.RenameIndex(
                name: "IX_messageDeletions_conversation_id",
                table: "messageDeletions",
                newName: "IX_messageDeletions_message_id");

            migrationBuilder.AddForeignKey(
                name: "FK_messageDeletions_Messages_message_id",
                table: "messageDeletions",
                column: "message_id",
                principalTable: "Messages",
                principalColumn: "id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
