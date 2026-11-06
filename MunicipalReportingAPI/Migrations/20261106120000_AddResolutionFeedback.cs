using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using MunicipalReportingAPI.Data;

#nullable disable

namespace MunicipalReportingAPI.Migrations
{
    [DbContext(typeof(MunicipalDBContext))]
    [Migration("20261106120000_AddResolutionFeedback")]
    public partial class AddResolutionFeedback : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "FeedbackRating",
                table: "Reports",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "FeedbackComment",
                table: "Reports",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "FeedbackUpdatedAt",
                table: "Reports",
                type: "datetime2",
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FeedbackRating",
                table: "Reports");

            migrationBuilder.DropColumn(
                name: "FeedbackComment",
                table: "Reports");

            migrationBuilder.DropColumn(
                name: "FeedbackUpdatedAt",
                table: "Reports");
        }
    }
}
