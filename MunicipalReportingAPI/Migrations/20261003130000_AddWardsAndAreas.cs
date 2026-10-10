using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using MunicipalReportingAPI.Data;

#nullable disable

namespace MunicipalReportingAPI.Migrations
{
    /// <inheritdoc />
    [DbContext(typeof(MunicipalDBContext))]
    [Migration("20261003130000_AddWardsAndAreas")]
    public partial class AddWardsAndAreas : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Wards",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Wards", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Areas",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    WardId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Areas", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Areas_Wards_WardId",
                        column: x => x.WardId,
                        principalTable: "Wards",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "Wards",
                columns: new[] { "Id", "Name" },
                columnTypes: new[] { "int", "nvarchar(100)" },
                values: new object[,]
                {
                    { 58, "Ward 58" },
                    { 61, "Ward 61" },
                    { 62, "Ward 62" }
                });

            migrationBuilder.InsertData(
                table: "Areas",
                columns: new[] { "Id", "Name", "WardId" },
                columnTypes: new[] { "int", "nvarchar(150)", "int" },
                values: new object[,]
                {
                    { 1, "Brake Village", 58 },
                    { 2, "Canelands", 58 },
                    { 3, "Casuarina", 58 },
                    { 4, "Desainagar", 58 },
                    { 5, "Ghandinagar", 58 },
                    { 6, "Hammonds Farm", 58 },
                    { 7, "King Shaka International Airport zone", 58 },
                    { 8, "La Mercy", 58 },
                    { 9, "Lungelani", 58 },
                    { 10, "Pholani", 58 },
                    { 11, "Sastri Circle / Belgate", 58 },
                    { 12, "Thuthukani", 58 },
                    { 13, "Tongaat Beach / Westbrook", 58 },
                    { 14, "Belvedere (including Belvedere North)", 61 },
                    { 15, "Buffelsdale", 61 },
                    { 16, "Chelmsford Heights", 61 },
                    { 17, "Emona Sunhill", 61 },
                    { 18, "Gwalas Farm", 61 },
                    { 19, "Mithangar", 61 },
                    { 20, "Plain Street", 61 },
                    { 21, "Sandfields", 61 },
                    { 22, "Umbhayi", 61 },
                    { 23, "Watsonia", 61 },
                    { 24, "Burbreeze", 62 },
                    { 25, "Fairbreeze", 62 },
                    { 26, "Flamingo Heights", 62 },
                    { 27, "Gandhi’s Hill", 62 },
                    { 28, "Hambanathi", 62 },
                    { 29, "Lauriston", 62 },
                    { 30, "Magwaveni", 62 },
                    { 31, "Maidstone Village", 62 },
                    { 32, "OThongathi CBD / Tongaat Central", 62 },
                    { 33, "Riverside AH", 62 },
                    { 34, "Tongaat Industrial / Trurolands", 62 },
                    { 35, "Vanrova", 62 }
                });

            migrationBuilder.AddColumn<int>(
                name: "AreaId",
                table: "AspNetUsers",
                type: "int",
                nullable: true);

            // Issues and Reports that already exist (test data) have no Area yet.
            // They are given Area 1 (Brake Village) so the new required FK can be created.
            migrationBuilder.AddColumn<int>(
                name: "AreaId",
                table: "Issues",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "AreaId",
                table: "Reports",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUsers_AreaId",
                table: "AspNetUsers",
                column: "AreaId");

            migrationBuilder.CreateIndex(
                name: "IX_Issues_AreaId",
                table: "Issues",
                column: "AreaId");

            migrationBuilder.CreateIndex(
                name: "IX_Issues_IssueType_AreaId_Status",
                table: "Issues",
                columns: new[] { "IssueType", "AreaId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_Reports_AreaId",
                table: "Reports",
                column: "AreaId");

            migrationBuilder.CreateIndex(
                name: "IX_Areas_WardId_Name",
                table: "Areas",
                columns: new[] { "WardId", "Name" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_AspNetUsers_Areas_AreaId",
                table: "AspNetUsers",
                column: "AreaId",
                principalTable: "Areas",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Issues_Areas_AreaId",
                table: "Issues",
                column: "AreaId",
                principalTable: "Areas",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Reports_Areas_AreaId",
                table: "Reports",
                column: "AreaId",
                principalTable: "Areas",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(name: "FK_AspNetUsers_Areas_AreaId", table: "AspNetUsers");
            migrationBuilder.DropForeignKey(name: "FK_Issues_Areas_AreaId", table: "Issues");
            migrationBuilder.DropForeignKey(name: "FK_Reports_Areas_AreaId", table: "Reports");

            migrationBuilder.DropTable(name: "Areas");
            migrationBuilder.DropTable(name: "Wards");

            migrationBuilder.DropIndex(name: "IX_AspNetUsers_AreaId", table: "AspNetUsers");
            migrationBuilder.DropIndex(name: "IX_Issues_AreaId", table: "Issues");
            migrationBuilder.DropIndex(name: "IX_Issues_IssueType_AreaId_Status", table: "Issues");
            migrationBuilder.DropIndex(name: "IX_Reports_AreaId", table: "Reports");

            migrationBuilder.DropColumn(name: "AreaId", table: "AspNetUsers");
            migrationBuilder.DropColumn(name: "AreaId", table: "Issues");
            migrationBuilder.DropColumn(name: "AreaId", table: "Reports");
        }
    }
}
