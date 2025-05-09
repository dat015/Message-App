using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Message_app.Migrations
{
    /// <inheritdoc />
    public partial class updateParticipantTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "adder",
                table: "Participants",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "adder",
                table: "Participants");
        }
    }
}
