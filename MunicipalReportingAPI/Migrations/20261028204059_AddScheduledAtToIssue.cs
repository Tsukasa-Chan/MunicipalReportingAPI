using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MunicipalReportingAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddScheduledAtToIssue : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "ScheduledAt",
                table: "Issues",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ScheduledAt",
                table: "Issues");
        }
    }
}
