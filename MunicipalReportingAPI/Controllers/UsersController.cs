using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalReportingAPI.Data;
using MunicipalReportingAPI.DTO;
using MunicipalReportingAPI.Models;
using MunicipalReportingAPI.Services;
using System.Security.Claims;
using System.Net;

namespace MunicipalReportingAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IWebHostEnvironment _env;
        private readonly MunicipalDBContext _context;
        private readonly IConfiguration _config;
        private readonly IEmailService _emailService;
        private readonly ILogger<UsersController> _logger;

        public UsersController(
            UserManager<ApplicationUser> userManager,
            IWebHostEnvironment env,
            MunicipalDBContext context,
            IConfiguration config,
            IEmailService emailService,
            ILogger<UsersController> logger)
        {
            _userManager = userManager;
            _env = env;
            _context = context;
            _config = config;
            _emailService = emailService;
            _logger = logger;
        }

        private async Task<ApplicationUser?> GetCurrentUserAsync()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
            {
                return null;
            }

            return await _userManager.FindByIdAsync(userIdClaim.Value);
        }

        // Change the display name. Does not end the user's session.
        [Authorize]
        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile(UpdateProfileDTO dto)
        {
            var user = await GetCurrentUserAsync();

            if (user == null)
            {
                return Unauthorized();
            }

            var name = dto.FullName.Trim();

            if (string.IsNullOrEmpty(name))
            {
                return BadRequest("Full name cannot be empty");
            }

            user.FullName = name;

            var result = await _userManager.UpdateAsync(user);

            if (!result.Succeeded)
            {
                return BadRequest(result.Errors.Select(e => e.Description).ToList());
            }

            return Ok(new
            {
                fullName = user.FullName,
                email = user.Email
            });
        }

        // Step 1 of an email change: check the password and email a confirmation link to the
        // NEW address. Nothing changes until the link is clicked.
        [Authorize]
        [HttpPost("change-email")]
        public async Task<IActionResult> ChangeEmail(ChangeEmailDTO dto)
        {
            var user = await GetCurrentUserAsync();

            if (user == null)
            {
                return Unauthorized();
            }

            // The seeded admin is found by its email at every startup, so it must not change
            if (await _userManager.IsInRoleAsync(user, "Admin"))
            {
                return BadRequest("Admin accounts cannot change their email address.");
            }

            if (!await _userManager.CheckPasswordAsync(user, dto.CurrentPassword))
            {
                return BadRequest("Current password is incorrect");
            }

            var newEmail = dto.NewEmail.Trim();

            if (string.Equals(newEmail, user.Email, StringComparison.OrdinalIgnoreCase))
            {
                return BadRequest("That is already your email address");
            }

            if (await _userManager.FindByEmailAsync(newEmail) != null)
            {
                return BadRequest("That email address is already in use");
            }

            var token = await _userManager.GenerateChangeEmailTokenAsync(user, newEmail);

            var confirmUrl =
                $"{_config["Email:ChangeEmailUrl"]}" +
                $"?userId={user.Id}" +
                $"&newEmail={Uri.EscapeDataString(newEmail)}" +
                $"&token={Uri.EscapeDataString(token)}";

            try
            {
                await _emailService.SendEmailAsync(
                    newEmail,
                    "Confirm your new email address",
                    $"""
                    <h2>Confirm your new email address</h2>

                    <p>Hi {user.FullName},</p>

                    <p>Click the link below to use this address for your Municipal Reporting account:</p>

                    <p><a href="{confirmUrl}">Confirm new email address</a></p>

                    <p>If you did not request this, you can ignore this email. Nothing will change.</p>
                    """);
            }
            catch (Exception)
            {
                return StatusCode(
                    StatusCodes.Status500InternalServerError,
                    "We couldn't send the confirmation email. Please try again later.");
            }

            return Ok("A confirmation link has been sent to your new email address. Your email will change once you click it.");
        }

        // Step 2: verify the link and show the same styled result as registration.
        [AllowAnonymous]
        [HttpGet("confirm-email-change")]
        public async Task<IActionResult> ConfirmEmailChange(
            [FromQuery] int userId,
            [FromQuery] string newEmail,
            [FromQuery] string token)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user == null || await _userManager.IsInRoleAsync(user, "Admin") ||
                string.IsNullOrWhiteSpace(newEmail) || string.IsNullOrWhiteSpace(token))
            {
                return LocalRedirect("/email-change-confirmed.html?status=invalid");
            }

            var oldEmail = user.Email;
            if (string.IsNullOrWhiteSpace(oldEmail) ||
                string.Equals(oldEmail, newEmail, StringComparison.OrdinalIgnoreCase))
            {
                return LocalRedirect("/email-change-confirmed.html?status=invalid");
            }

            // Avoid changing the email to an address that another account now owns.
            var existing = await _userManager.FindByEmailAsync(newEmail);
            if (existing != null && existing.Id != user.Id)
            {
                return LocalRedirect("/email-change-confirmed.html?status=invalid");
            }

            var result = await _userManager.ChangeEmailAsync(user, newEmail, token);
            if (!result.Succeeded)
            {
                return LocalRedirect("/email-change-confirmed.html?status=invalid");
            }

            // Keep the username synchronized with the email address.
            var userNameResult = await _userManager.SetUserNameAsync(user, newEmail);
            if (!userNameResult.Succeeded)
            {
                _logger.LogError("Email changed, but updating username failed for user {UserId}", user.Id);
                return LocalRedirect("/email-change-confirmed.html?status=error");
            }

            await RevokeRefreshTokensAsync(user.Id);

            // Generate only AFTER the change, so it is bound to the NEW security stamp.
            // A subsequent password/email/security-stamp change invalidates this link.
            const string purposePrefix = "FixMyArea:RevertEmailChange:";
            var purpose = purposePrefix + oldEmail.ToUpperInvariant() + ":" + newEmail.ToUpperInvariant();
            var recoveryToken = await _userManager.GenerateUserTokenAsync(
                user, TokenOptions.DefaultProvider, purpose);

            var configuredUrl = _config["Email:ChangeEmailUrl"];
            // Use the configured public backend host, not localhost or the mobile app URL.
            var publicBase = Uri.TryCreate(configuredUrl, UriKind.Absolute, out var parsed)
                ? parsed.GetLeftPart(UriPartial.Authority)
                : $"{Request.Scheme}://{Request.Host}";
            var recoveryUrl = $"{publicBase}/email-change-recovery.html" +
                $"?userId={user.Id}" +
                $"&oldEmail={Uri.EscapeDataString(oldEmail)}" +
                $"&currentEmail={Uri.EscapeDataString(newEmail)}" +
                $"&token={Uri.EscapeDataString(recoveryToken)}";

            try
            {
                await _emailService.SendEmailAsync(
                    oldEmail,
                    "Security alert: your Fix My Area email address changed",
                    $"""
                    <div style="font-family:Arial,sans-serif;max-width:560px;margin:auto;padding:24px;background:#FFF8F4;color:#292524">
                      <div style="background:#C94F1B;color:white;padding:18px 22px;border-radius:12px 12px 0 0;font-size:20px;font-weight:bold">Fix My Area</div>
                      <div style="background:white;padding:24px;border-radius:0 0 12px 12px">
                        <h2 style="margin-top:0">Your account email was changed</h2>
                        <p>Hi {WebUtility.HtmlEncode(user.FullName)},</p>
                        <p>The email address on your Fix My Area account was changed from <strong>{WebUtility.HtmlEncode(oldEmail)}</strong> to <strong>{WebUtility.HtmlEncode(newEmail)}</strong>.</p>
                        <p>If this was you, no action is needed.</p>
                        <p><strong>If you did not make this change,</strong> use the secure link below within 24 hours to restore your previous email address:</p>
                        <p style="margin:28px 0"><a href="{WebUtility.HtmlEncode(recoveryUrl)}" style="background:#C94F1B;color:white;padding:13px 20px;border-radius:8px;text-decoration:none;font-weight:bold">This wasn't me</a></p>
                        <p style="color:#78716C;font-size:13px">After restoring your email, reset your password immediately. This link can only be used while your account has not had another security change.</p>
                      </div>
                    </div>
                    """);
            }
            catch (Exception ex)
            {
                // The email change has already succeeded; do not report it as a failure.
                _logger.LogError(ex, "Failed to send old-address security alert for user {UserId}", user.Id);
            }

            return LocalRedirect("/email-change-confirmed.html?status=success");
        }

        // Step 3: POST only. Opening the email link alone must NOT change the account.
        // Identity's DataProtector token has a one-day lifespan by default and is tied
        // to the user's security stamp. Changing the stamp makes it single-use.
        [AllowAnonymous]
        [HttpPost("recover-email-change")]
        public async Task<IActionResult> RecoverEmailChange([FromBody] RecoverEmailChangeDTO dto)
        {
            if (dto.UserId <= 0 || string.IsNullOrWhiteSpace(dto.OldEmail) ||
                string.IsNullOrWhiteSpace(dto.CurrentEmail) || string.IsNullOrWhiteSpace(dto.Token))
            {
                return BadRequest(new { message = "Invalid or expired recovery link." });
            }

            var user = await _userManager.FindByIdAsync(dto.UserId.ToString());
            if (user == null || await _userManager.IsInRoleAsync(user, "Admin") ||
                !string.Equals(user.Email, dto.CurrentEmail, StringComparison.OrdinalIgnoreCase))
            {
                return BadRequest(new { message = "Invalid or expired recovery link." });
            }

            var purpose = "FixMyArea:RevertEmailChange:" +
                dto.OldEmail.ToUpperInvariant() + ":" + dto.CurrentEmail.ToUpperInvariant();
            var isValid = await _userManager.VerifyUserTokenAsync(
                user, TokenOptions.DefaultProvider, purpose, dto.Token);
            if (!isValid)
            {
                return BadRequest(new { message = "Invalid or expired recovery link." });
            }

            var owner = await _userManager.FindByEmailAsync(dto.OldEmail);
            if (owner != null && owner.Id != user.Id)
            {
                return Conflict(new { message = "The previous address is now in use. Contact support." });
            }

            // SetEmailAsync changes the security stamp, invalidating this recovery token.
            var emailResult = await _userManager.SetEmailAsync(user, dto.OldEmail);
            if (!emailResult.Succeeded)
            {
                return BadRequest(new { message = "We couldn't restore your email. Contact support." });
            }

            var usernameResult = await _userManager.SetUserNameAsync(user, dto.OldEmail);
            if (!usernameResult.Succeeded)
            {
                _logger.LogError("Recovery updated email but not username for user {UserId}", user.Id);
                return StatusCode(500, new { message = "Your email was restored, but sign-in needs support. Contact support." });
            }

            // The old address had been verified before this change; restore that state.
            user.EmailConfirmed = true;
            var confirmResult = await _userManager.UpdateAsync(user);
            if (!confirmResult.Succeeded)
            {
                _logger.LogError("Recovery could not confirm restored email for user {UserId}", user.Id);
                return StatusCode(500, new { message = "Your email was restored but verification needs support." });
            }

            await RevokeRefreshTokensAsync(user.Id);
            return Ok(new { message = "Your previous email address has been restored. Reset your password immediately." });
        }

        private async Task RevokeRefreshTokensAsync(int userId)
        {
            var refreshTokens = await _context.RefreshTokens
                .Where(rt => rt.UserId == userId && !rt.IsRevoked)
                .ToListAsync();
            foreach (var refreshToken in refreshTokens)
            {
                refreshToken.IsRevoked = true;
            }
            await _context.SaveChangesAsync();
        }

        public sealed class RecoverEmailChangeDTO
        {
            public int UserId { get; set; }
            public string OldEmail { get; set; } = string.Empty;
            public string CurrentEmail { get; set; } = string.Empty;
            public string Token { get; set; } = string.Empty;
        }

        [Authorize]
        [HttpPut("profile-picture")]
        public async Task<IActionResult> UpdateProfilePicture(
            [FromForm] UpdateProfilePictureDTO dto)
        {
            var user = await GetCurrentUserAsync();

            if (user == null)
            {
                return Unauthorized();
            }

            if (dto.Image == null)
            {
                return BadRequest("An image is required");
            }

            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png" };

            var extension = Path.GetExtension(dto.Image.FileName).ToLower();

            if (!allowedExtensions.Contains(extension))
            {
                return BadRequest("Only JPG and PNG images are allowed");
            }

            if (dto.Image.Length > 5 * 1024 * 1024)
            {
                return BadRequest("Image must be smaller than 5MB");
            }

            var webRootPath = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var uploadsFolder = Path.Combine(webRootPath, "profile-pictures");

            Directory.CreateDirectory(uploadsFolder);

            var fileName = Guid.NewGuid() + extension;
            var filePath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await dto.Image.CopyToAsync(stream);
            }

            var oldPictureUrl = user.ProfilePictureUrl;
            user.ProfilePictureUrl = $"/profile-pictures/{fileName}";

            var updateResult = await _userManager.UpdateAsync(user);

            if (!updateResult.Succeeded)
            {
                // Don't leave an orphaned file behind
                if (System.IO.File.Exists(filePath))
                {
                    System.IO.File.Delete(filePath);
                }

                return BadRequest(updateResult.Errors.Select(e => e.Description).ToList());
            }

            // Only after the save worked: remove the picture that was replaced
            if (!string.IsNullOrEmpty(oldPictureUrl))
            {
                var oldPath = Path.Combine(webRootPath, oldPictureUrl.TrimStart('/'));

                if (System.IO.File.Exists(oldPath))
                {
                    System.IO.File.Delete(oldPath);
                }
            }

            return Ok(new
            {
                profilePictureUrl = user.ProfilePictureUrl
            });
        }
    }
}