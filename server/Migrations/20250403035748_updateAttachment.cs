using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Message_app.Migrations
{
    /// <inheritdoc />
    public partial class updateAttachment : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Attachments_Messages_message_id",
                table: "Attachments");

            migrationBuilder.AlterColumn<int>(
                name: "message_id",
                table: "Attachments",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddForeignKey(
                name: "FK_Attachments_Messages_message_id",
                table: "Attachments",
                column: "message_id",
                principalTable: "Messages",
                principalColumn: "id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Attachments_Messages_message_id",
                table: "Attachments");

            migrationBuilder.AlterColumn<int>(
                name: "message_id",
                table: "Attachments",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Attachments_Messages_message_id",
                table: "Attachments",
                column: "message_id",
                principalTable: "Messages",
                principalColumn: "id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
