using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.Data
{
    public class MunicipalDBContext : IdentityDbContext<ApplicationUser, IdentityRole<int>, int>
    {
        public MunicipalDBContext(DbContextOptions<MunicipalDBContext> options)
            : base(options) { }

        public DbSet<Report> Reports { get; set; }

        public DbSet<Issue> Issues { get; set; }

        public DbSet<Ward> Wards { get; set; }

        public DbSet<Area> Areas { get; set; }

        public DbSet<RefreshToken> RefreshTokens { get; set; }

        public DbSet<RevokedToken> RevokedTokens { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<Report>()
                .HasOne(r => r.User)
                .WithMany()
                .HasForeignKey(r => r.UserId)
                .IsRequired(false)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<Report>()
                .Property(r => r.FeedbackComment)
                .HasMaxLength(1000);

            modelBuilder.Entity<Report>()
                .HasOne(r => r.Issue)
                .WithMany(i => i.Reports)
                .HasForeignKey(r => r.IssueId)
                .OnDelete(DeleteBehavior.Cascade);

            // A resident can only have one Report per Issue.
            // Reports kept after an account deletion have no user, so they are excluded.
            modelBuilder.Entity<Report>()
                .HasIndex(r => new { r.IssueId, r.UserId })
                .IsUnique()
                .HasFilter("[UserId] IS NOT NULL");

            modelBuilder.Entity<Issue>()
                .HasOne(i => i.Supervisor)
                .WithMany()
                .HasForeignKey(i => i.SupervisorId)
                .OnDelete(DeleteBehavior.Restrict); // SQL Server would reject SetNull here (multiple cascade paths); unassigned in code instead

            modelBuilder.Entity<Issue>()
                .HasIndex(i => new { i.IssueType, i.Status });

            // Location hierarchy: Ward 1 -> many Areas. IDs are the real ward numbers, never generated.
            modelBuilder.Entity<Ward>(e =>
            {
                e.Property(w => w.Id).ValueGeneratedNever();
                e.Property(w => w.Name).IsRequired().HasMaxLength(100);
                e.HasData(LocationSeedData.Wards);
            });

            modelBuilder.Entity<Area>(e =>
            {
                e.Property(a => a.Id).ValueGeneratedNever();
                e.Property(a => a.Name).IsRequired().HasMaxLength(150);

                e.HasOne(a => a.Ward)
                    .WithMany(w => w.Areas)
                    .HasForeignKey(a => a.WardId)
                    .OnDelete(DeleteBehavior.Restrict);

                e.HasIndex(a => new { a.WardId, a.Name }).IsUnique();

                e.HasData(LocationSeedData.Areas);
            });

            // An Area cannot be deleted while Users, Issues or Reports reference it (Restrict, no cascades).
            // AreaId on the user is optional: Admin/Supervisor accounts have no residential Area.
            modelBuilder.Entity<ApplicationUser>()
                .HasOne(u => u.Area)
                .WithMany(a => a.Users)
                .HasForeignKey(u => u.AreaId)
                .IsRequired(false)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Issue>()
                .HasOne(i => i.Area)
                .WithMany(a => a.Issues)
                .HasForeignKey(i => i.AreaId)
                .IsRequired()
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Report>()
                .HasOne(r => r.Area)
                .WithMany(a => a.Reports)
                .HasForeignKey(r => r.AreaId)
                .IsRequired()
                .OnDelete(DeleteBehavior.Restrict);

            // Area matching looks up open Issues by type + area
            modelBuilder.Entity<Issue>()
                .HasIndex(i => new { i.IssueType, i.AreaId, i.Status });

            modelBuilder.Entity<RefreshToken>()
                .HasOne(rt => rt.User)
                .WithMany()
                .HasForeignKey(rt => rt.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // Looked up on every refresh call (generated tokens are 88 characters)
            modelBuilder.Entity<RefreshToken>()
                .Property(rt => rt.Token)
                .HasMaxLength(200);

            modelBuilder.Entity<RefreshToken>()
                .HasIndex(rt => rt.Token)
                .IsUnique();

            // Looked up on every authenticated request (a jti is a 36 character GUID)
            modelBuilder.Entity<RevokedToken>()
                .Property(rt => rt.Jti)
                .HasMaxLength(64);

            modelBuilder.Entity<RevokedToken>()
                .HasIndex(rt => rt.Jti);
        }
    }
}