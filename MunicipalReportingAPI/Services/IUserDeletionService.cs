using Microsoft.AspNetCore.Identity;
using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.Services
{
    public interface IUserDeletionService
    {
        // Removes a user and cleans up what they leave behind. Shared by
        // DELETE /api/auth/delete-account (self-service) and
        // DELETE /api/admin/users/{id} (admin).
        Task<IdentityResult> DeleteUserAsync(ApplicationUser user);
    }
}
