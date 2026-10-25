using Microsoft.EntityFrameworkCore;
using MunicipalReportingAPI.Data;

namespace MunicipalReportingAPI.Services
{
    // Deletes token rows that can no longer matter:
    //  - RevokedTokens: a revoked access token is only dangerous until it would have expired.
    //  - RefreshTokens: expired ones are refused anyway (revoked or not).
    // Runs shortly after startup and then every TokenCleanup:IntervalHours (default 24).
    public class TokenCleanupService : BackgroundService
    {
        // The JWT middleware tolerates 5 minutes of clock skew, so a token can still be
        // accepted a little after its expiry. Keep rows well past that before deleting.
        private static readonly TimeSpan Retention = TimeSpan.FromMinutes(10);

        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<TokenCleanupService> _logger;
        private readonly TimeSpan _interval;

        public TokenCleanupService(
            IServiceScopeFactory scopeFactory,
            ILogger<TokenCleanupService> logger,
            IConfiguration config)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;

            var hours = config.GetValue<double?>("TokenCleanup:IntervalHours") ?? 24;
            _interval = TimeSpan.FromHours(hours > 0 ? hours : 24);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            try
            {
                // Let startup (seeding, first requests) finish first
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);

                using var timer = new PeriodicTimer(_interval);

                do
                {
                    await CleanUpAsync(stoppingToken);
                }
                while (await timer.WaitForNextTickAsync(stoppingToken));
            }
            catch (OperationCanceledException)
            {
                // Application is shutting down
            }
        }

        private async Task CleanUpAsync(CancellationToken cancellationToken)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<MunicipalDBContext>();

                var cutoff = DateTime.UtcNow - Retention;

                var revoked = await db.RevokedTokens
                    .Where(t => t.ExpiresAt < cutoff)
                    .ExecuteDeleteAsync(cancellationToken);

                var refresh = await db.RefreshTokens
                    .Where(t => t.ExpiresAt < cutoff)
                    .ExecuteDeleteAsync(cancellationToken);

                _logger.LogInformation(
                    "Token cleanup removed {Revoked} revoked access tokens and {Refresh} expired refresh tokens",
                    revoked, refresh);
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch (Exception ex)
            {
                // A failed run must never take the app down; the next tick tries again
                _logger.LogError(ex, "Token cleanup failed");
            }
        }
    }
}
