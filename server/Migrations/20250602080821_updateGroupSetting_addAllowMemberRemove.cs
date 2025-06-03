using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Message_app.Migrations
{
    /// <inheritdoc />
    public partial class updateGroupSetting_addAllowMemberRemove : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "AllowMemberRemove",
                table: "GroupSettings",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AllowMemberRemove",
                table: "GroupSettings");
        }
    }
}
