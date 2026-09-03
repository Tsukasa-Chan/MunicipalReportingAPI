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

        public DbSet<RefreshToken> RefreshTokens { get; set; }

        public DbSet<RevokedToken> RevokedTokens { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<Report>()
                .HasOne(r => r.User)
                .WithMany()
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<RefreshToken>()
                .HasOne(rt => rt.User)
                .WithMany()
                .HasForeignKey(rt => rt.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}