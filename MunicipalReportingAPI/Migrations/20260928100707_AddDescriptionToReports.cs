using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MunicipalReportingAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddDescriptionToReports : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "Reports",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Description",
                table: "Reports");
        }
    }
}
