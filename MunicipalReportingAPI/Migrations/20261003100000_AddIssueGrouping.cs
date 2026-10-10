using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MunicipalReportingAPI.Migrations
{
    /// <inheritdoc />
    public partial class AddIssueGrouping : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Issues",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    IssueCategory = table.Column<int>(type: "int", nullable: false),
                    IssueType = table.Column<int>(type: "int", nullable: false),
                    Location = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Latitude = table.Column<double>(type: "float", nullable: false),
                    Longitude = table.Column<double>(type: "float", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    SupervisorId = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    LegacyReportId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Issues", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Issues_AspNetUsers_SupervisorId",
                        column: x => x.SupervisorId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            // Keep any existing reports: each one becomes its own Issue (1:1)
            migrationBuilder.Sql(@"
                INSERT INTO Issues (IssueCategory, IssueType, Location, Latitude, Longitude, Status, CreatedAt, UpdatedAt, LegacyReportId)
                SELECT IssueCategory, IssueType, Location, Latitude, Longitude, Status, CreatedAt, UpdatedAt, Id
                FROM Reports");

            migrationBuilder.AddColumn<int>(
                name: "IssueId",
                table: "Reports",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.Sql(@"
                UPDATE r SET r.IssueId = i.Id
                FROM Reports r
                INNER JOIN Issues i ON i.LegacyReportId = r.Id");

            migrationBuilder.DropColumn(name: "LegacyReportId", table: "Issues");
            migrationBuilder.DropColumn(name: "Status", table: "Reports");

            migrationBuilder.CreateIndex(
                name: "IX_Issues_IssueType_Status",
                table: "Issues",
                columns: new[] { "IssueType", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_Issues_SupervisorId",
                table: "Issues",
                column: "SupervisorId");

            migrationBuilder.CreateIndex(
                name: "IX_Reports_IssueId_UserId",
                table: "Reports",
                columns: new[] { "IssueId", "UserId" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Reports_Issues_IssueId",
                table: "Reports",
                column: "IssueId",
                principalTable: "Issues",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(name: "FK_Reports_Issues_IssueId", table: "Reports");
            migrationBuilder.DropIndex(name: "IX_Reports_IssueId_UserId", table: "Reports");

            migrationBuilder.AddColumn<int>(name: "Status", table: "Reports", type: "int", nullable: false, defaultValue: 0);

            migrationBuilder.Sql(@"
                UPDATE r SET r.Status = i.Status
                FROM Reports r
                INNER JOIN Issues i ON i.Id = r.IssueId");

            migrationBuilder.DropColumn(name: "IssueId", table: "Reports");
            migrationBuilder.DropTable(name: "Issues");
        }
    }
}
