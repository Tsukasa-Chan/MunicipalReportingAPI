using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalReportingAPI.Data;
using MunicipalReportingAPI.DTO;
using MunicipalReportingAPI.Models;
using MunicipalReportingAPI.Services;
using System.Security.Claims;

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

        public UsersController(
            UserManager<ApplicationUser> userManager,
            IWebHostEnvironment env,
            MunicipalDBContext context,
            IConfiguration config,
            IEmailService emailService)
        {
            _userManager = userManager;
            _env = env;
            _context = context;
            _config = config;
            _emailService = emailService;
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

        // Change the signed-in resident's registered area only. Existing reports and
        // issues keep their original AreaId values and are not modified.
        [Authorize(Roles = "User")]
        [HttpPut("area")]
        public async Task<IActionResult> UpdateArea([FromBody] UpdateUserAreaDTO dto)
        {
            var user = await GetCurrentUserAsync();
            if (user == null) return Unauthorized();

            var area = await _context.Areas
                .Include(a => a.Ward)
                .FirstOrDefaultAsync(a => a.Id == dto.AreaId);

            if (area == null)
                return BadRequest(new { message = "Please select a valid area." });

            user.AreaId = area.Id;
            var result = await _userManager.UpdateAsync(user);
            if (!result.Succeeded)
                return BadRequest(result.Errors.Select(e => e.Description).ToList());

            return Ok(new
            {
                areaId = area.Id,
                areaName = area.Name,
                wardId = area.WardId,
                wardName = area.Ward?.Name
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

        // Step 2: the link from the email. The change is applied here.
        [AllowAnonymous]
        [HttpGet("confirm-email-change")]
        public async Task<IActionResult> ConfirmEmailChange(
            [FromQuery] int userId,
            [FromQuery] string newEmail,
            [FromQuery] string token)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString());

            if (user == null || await _userManager.IsInRoleAsync(user, "Admin"))
            {
                return BadRequest("Invalid or expired link");
            }

            // Also marks the new address as confirmed, and changes the security stamp
            var result = await _userManager.ChangeEmailAsync(user, newEmail, token);

            if (!result.Succeeded)
            {
                return BadRequest("Invalid or expired link");
            }

            // The app signs in with the email, so keep the username the same as the email
            var userNameResult = await _userManager.SetUserNameAsync(user, newEmail);

            if (!userNameResult.Succeeded)
            {
                return BadRequest(userNameResult.Errors.Select(e => e.Description).ToList());
            }

            // End refresh sessions (the changed security stamp already ends access tokens)
            var refreshTokens = await _context.RefreshTokens
                .Where(rt => rt.UserId == user.Id && !rt.IsRevoked)
                .ToListAsync();

            foreach (var t in refreshTokens)
            {
                t.IsRevoked = true;
            }

            await _context.SaveChangesAsync();

            return Ok("Email address changed successfully. Please log in again with your new email.");
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