using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MunicipalReportingAPI.Migrations
{
    /// <inheritdoc />
    public partial class PreserveReportsOnUserDeletion : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Reports.UserId becomes nullable so a report can outlive its user's account
            migrationBuilder.DropForeignKey(name: "FK_Reports_AspNetUsers_UserId", table: "Reports");
            migrationBuilder.DropIndex(name: "IX_Reports_IssueId_UserId", table: "Reports");
            migrationBuilder.DropIndex(name: "IX_Reports_UserId", table: "Reports");

            migrationBuilder.AlterColumn<int>(
                name: "UserId",
                table: "Reports",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.CreateIndex(
                name: "IX_Reports_UserId",
                table: "Reports",
                column: "UserId");

            // Kept reports (UserId NULL) must not collide with each other
            migrationBuilder.CreateIndex(
                name: "IX_Reports_IssueId_UserId",
                table: "Reports",
                columns: new[] { "IssueId", "UserId" },
                unique: true,
                filter: "[UserId] IS NOT NULL");

            migrationBuilder.AddForeignKey(
                name: "FK_Reports_AspNetUsers_UserId",
                table: "Reports",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            // Issues.SupervisorId: SET NULL would create multiple cascade paths on SQL Server
            // (Users -> Reports and Users -> Issues -> Reports). The API unassigns supervisors
            // in code before deleting the account instead.
            migrationBuilder.DropForeignKey(name: "FK_Issues_AspNetUsers_SupervisorId", table: "Issues");

            migrationBuilder.AddForeignKey(
                name: "FK_Issues_AspNetUsers_SupervisorId",
                table: "Issues",
                column: "SupervisorId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(name: "FK_Issues_AspNetUsers_SupervisorId", table: "Issues");

            migrationBuilder.AddForeignKey(
                name: "FK_Issues_AspNetUsers_SupervisorId",
                table: "Issues",
                column: "SupervisorId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.DropForeignKey(name: "FK_Reports_AspNetUsers_UserId", table: "Reports");
            migrationBuilder.DropIndex(name: "IX_Reports_IssueId_UserId", table: "Reports");
            migrationBuilder.DropIndex(name: "IX_Reports_UserId", table: "Reports");

            // Reports with no user cannot exist in the old shape
            migrationBuilder.Sql("DELETE FROM Reports WHERE UserId IS NULL");

            migrationBuilder.AlterColumn<int>(
                name: "UserId",
                table: "Reports",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reports_UserId",
                table: "Reports",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Reports_IssueId_UserId",
                table: "Reports",
                columns: new[] { "IssueId", "UserId" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Reports_AspNetUsers_UserId",
                table: "Reports",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
