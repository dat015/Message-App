using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Message_app.Migrations
{
    /// <inheritdoc />
    public partial class ChangMessage : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Messages_Attachments_attachment_id",
                table: "Messages");

            migrationBuilder.DropIndex(
                name: "IX_Messages_attachment_id",
                table: "Messages");

            migrationBuilder.DropColumn(
                name: "attachment_id",
                table: "Messages");

            migrationBuilder.AddColumn<int>(
                name: "message_id",
                table: "Attachments",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_Attachments_message_id",
                table: "Attachments",
                column: "message_id");

            migrationBuilder.AddForeignKey(
                name: "FK_Attachments_Messages_message_id",
                table: "Attachments",
                column: "message_id",
                principalTable: "Messages",
                principalColumn: "id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Attachments_Messages_message_id",
                table: "Attachments");

            migrationBuilder.DropIndex(
                name: "IX_Attachments_message_id",
                table: "Attachments");

            migrationBuilder.DropColumn(
                name: "message_id",
                table: "Attachments");

            migrationBuilder.AddColumn<int>(
                name: "attachment_id",
                table: "Messages",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_Messages_attachment_id",
                table: "Messages",
                column: "attachment_id");

            migrationBuilder.AddForeignKey(
                name: "FK_Messages_Attachments_attachment_id",
                table: "Messages",
                column: "attachment_id",
                principalTable: "Attachments",
                principalColumn: "id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
