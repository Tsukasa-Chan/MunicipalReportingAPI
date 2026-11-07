using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalReportingAPI.Data;
using MunicipalReportingAPI.DTO;
using MunicipalReportingAPI.Services;
using MunicipalReportingAPI.Helpers;
using MunicipalReportingAPI.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace MunicipalReportingAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly MunicipalDBContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly SignInManager<ApplicationUser> _signInManager;
        private readonly IConfiguration _config;
        private readonly IEmailService _emailService;
        private readonly IUserDeletionService _userDeletionService;

        public AuthController(
            MunicipalDBContext context,
            UserManager<ApplicationUser> userManager,
            SignInManager<ApplicationUser> signInManager,
            IConfiguration config,
            IEmailService emailService,
            IUserDeletionService userDeletionService)
        {
            _context = context;
            _userManager = userManager;
            _signInManager = signInManager;
            _config = config;
            _emailService = emailService;
            _userDeletionService = userDeletionService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register(RegisterDTO dto)
        {
            var existingUser = await _userManager.FindByEmailAsync(dto.Email);

            if (existingUser != null)
            {
                return BadRequest("Email already exists");
            }

            // Residents must pick their home Area (the Ward is derived from it)
            if (!await _context.Areas.AnyAsync(a => a.Id == dto.AreaId))
            {
                return BadRequest("The selected area does not exist");
            }

            var user = new ApplicationUser
            {
                FullName = dto.FullName,
                Email = dto.Email,
                UserName = dto.Email,
                AreaId = dto.AreaId,
                EmailConfirmed = false
            };

            var result = await _userManager.CreateAsync(user, dto.Password);

            if (!result.Succeeded)
            {
                var errors = result.Errors.Select(e => e.Description).ToList();
                return BadRequest(errors);
            }

            await _userManager.AddToRoleAsync(user, "User");

            var emailSent = true;

            try
            {
                var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);

                var confirmationUrl =
                    $"{_config["Email:ConfirmationUrl"]}" +
                    $"?userId={user.Id}" +
                    $"&token={Uri.EscapeDataString(token)}";

                await _emailService.SendEmailAsync(
                    user.Email,
                    "Verify your Fix My Area account",
                    $"""
            <h2>Welcome to Fix My Area</h2>

            <p>Hi {user.FullName},</p>

            <p>Thank you for registering.</p>

            <p>Please click the button below to verify your email address:</p>

            <p>
                <a href="{confirmationUrl}">
                    Verify Email Address
                </a>
            </p>

            <p>
                If you did not create this account, you can ignore this email.
            </p>
            """
                );
            }
            catch (Exception)
            {
                emailSent = false;
            }

            return Ok(new
            {
                emailSent,
                message = emailSent
                    ? "Registration successful. Please check your email to verify your account."
                    : "Registration successful, but we couldn't send the verification email. Please use 'Resend confirmation' to try again."
            });
        }

        [HttpGet("confirm-email")]
        public async Task<IActionResult> ConfirmEmail(
    [FromQuery] int userId,
    [FromQuery] string token)
        {
            // The link in the email opens in a browser, so send the person to a
            // proper page instead of showing plain text.
            var user = await _userManager.FindByIdAsync(
                userId.ToString());

            if (user == null)
            {
                return LocalRedirect("/email-confirmed.html?status=invalid");
            }

            // Clicking the link a second time: the token was already used,
            // but the account is fine.
            if (user.EmailConfirmed)
            {
                return LocalRedirect("/email-confirmed.html?status=already");
            }

            var result = await _userManager.ConfirmEmailAsync(
                user,
                token);

            if (!result.Succeeded)
            {
                return LocalRedirect("/email-confirmed.html?status=invalid");
            }

            return LocalRedirect("/email-confirmed.html?status=success");
        }

        [HttpPost("resend-confirmation")]
        public async Task<IActionResult> ResendConfirmation(
            ResendConfirmationDTO dto)
        {
            var user = await _userManager.FindByEmailAsync(dto.Email);

            if (user == null)
            {
                return Ok("If the account exists, a confirmation email has been sent.");
            }

            if (user.EmailConfirmed)
            {
                return BadRequest("Email is already verified.");
            }

            var token =
                await _userManager.GenerateEmailConfirmationTokenAsync(user);

            var confirmationUrl =
                $"{_config["Email:ConfirmationUrl"]}" +
                $"?userId={user.Id}" +
                $"&token={Uri.EscapeDataString(token)}";

            await _emailService.SendEmailAsync(
                user.Email!,
                "Verify your Fix My Area account",
                $"""
                <h2>Verify your email address</h2>

                <p>Click the link below to verify your account:</p>

                <p>
                    <a href="{confirmationUrl}">
                        Verify Email Address
                    </a>
                </p>
                """
            );

            return Ok("Confirmation email sent.");
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login(LoginDTO dto)
        {
            var user = await _userManager.FindByEmailAsync(dto.Email);

            if (user == null)
            {
                return Unauthorized("Invalid email or password");
            }

            if (!user.EmailConfirmed)
            {
                // The code lets the app offer a "resend confirmation" option
                return Unauthorized(new
                {
                    code = "email_not_verified",
                    message = "Please verify your email address before logging in."
                });
            }

            var result = await _signInManager.CheckPasswordSignInAsync(
                user,
                dto.Password,
                true);

            if (result.IsLockedOut)
            {
                return StatusCode(
                    StatusCodes.Status429TooManyRequests,
                    "Too many failed attempts. Please try again in 15 minutes.");
            }

            if (!result.Succeeded)
            {
                return Unauthorized("Invalid email or password");
            }

            var roles = await _userManager.GetRolesAsync(user);

            var accessToken = JWTHelper.GenerateToken(
                user,
                roles,
                _config);

            var refreshTokenValue =
                JWTHelper.GenerateRefreshToken();

            var refreshToken = new RefreshToken
            {
                Token = refreshTokenValue,
                UserId = user.Id,
                ExpiresAt = DateTime.UtcNow.AddDays(
                    double.Parse(
                        _config["Jwt:RefreshTokenExpiresInDays"]!))
            };

            _context.RefreshTokens.Add(refreshToken);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                token = accessToken,
                refreshToken = refreshTokenValue
            });
        }

        // Two refresh calls with the same token this close together are a client race
        // (e.g. parallel requests that all got a 401), not a stolen token.
        private const int RotationGraceSeconds = 10;

        [HttpPost("refresh")]
        public async Task<IActionResult> Refresh(
            RefreshTokenDTO dto)
        {
            var storedToken = await _context.RefreshTokens
                .FirstOrDefaultAsync(
                    rt => rt.Token == dto.RefreshToken);

            if (storedToken == null)
            {
                return Unauthorized(
                    "Invalid or expired refresh token");
            }

            if (storedToken.IsRevoked)
            {
                // A token that was already exchanged for a new one is back. Either the client
                // raced itself (harmless) or the token was copied, so end every session.
                if (storedToken.RotatedAt != null &&
                    storedToken.RotatedAt < DateTime.UtcNow.AddSeconds(-RotationGraceSeconds))
                {
                    var activeTokens = await _context.RefreshTokens
                        .Where(rt => rt.UserId == storedToken.UserId && !rt.IsRevoked)
                        .ToListAsync();

                    foreach (var t in activeTokens)
                    {
                        t.IsRevoked = true;
                    }

                    await _context.SaveChangesAsync();
                }

                return Unauthorized(
                    "Invalid or expired refresh token");
            }

            if (storedToken.ExpiresAt < DateTime.UtcNow)
            {
                return Unauthorized(
                    "Invalid or expired refresh token");
            }

            var user = await _userManager.FindByIdAsync(
                storedToken.UserId.ToString());

            if (user == null)
            {
                return Unauthorized("User not found");
            }

            var roles = await _userManager.GetRolesAsync(user);

            var newAccessToken = JWTHelper.GenerateToken(
                user,
                roles,
                _config);

            // Rotation: the old refresh token is used up and replaced by a new one
            var newRefreshTokenValue =
                JWTHelper.GenerateRefreshToken();

            storedToken.IsRevoked = true;
            storedToken.RotatedAt = DateTime.UtcNow;

            _context.RefreshTokens.Add(new RefreshToken
            {
                Token = newRefreshTokenValue,
                UserId = user.Id,
                ExpiresAt = DateTime.UtcNow.AddDays(
                    double.Parse(
                        _config["Jwt:RefreshTokenExpiresInDays"]!))
            });

            await _context.SaveChangesAsync();

            return Ok(new
            {
                token = newAccessToken,
                refreshToken = newRefreshTokenValue
            });
        }

        [Authorize]
        [HttpPost("logout")]
        public async Task<IActionResult> Logout(
            RefreshTokenDTO dto)
        {
            var storedToken = await _context.RefreshTokens
                .FirstOrDefaultAsync(
                    rt => rt.Token == dto.RefreshToken);

            if (storedToken != null)
            {
                storedToken.IsRevoked = true;
            }

            var jti = User.FindFirst(JwtRegisteredClaimNames.Jti)?.Value;
            var expClaim = User.FindFirst(JwtRegisteredClaimNames.Exp)?.Value;

            if (jti != null && expClaim != null)
            {
                var expiresAt = DateTimeOffset.FromUnixTimeSeconds(long.Parse(expClaim)).UtcDateTime;

                _context.RevokedTokens.Add(
                    new RevokedToken
                    {
                        Jti = jti,
                        ExpiresAt = expiresAt
                    }
                    );
            }

            await _context.SaveChangesAsync();

            return Ok("Logged out successfully");
        }

        [Authorize]
        [HttpGet("me")]
        public async Task<IActionResult> Me()
        {
            var userIdClaim =
                User.FindFirst(ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
            {
                return Unauthorized();
            }

            var user = await _userManager.FindByIdAsync(
                userIdClaim.Value);

            if (user == null)
            {
                return NotFound();
            }

            var roles = await _userManager.GetRolesAsync(user);

            // Registered/default location (null for Admin/Supervisor accounts without an Area)
            var area = user.AreaId == null
                ? null
                : await _context.Areas
                    .Include(a => a.Ward)
                    .FirstOrDefaultAsync(a => a.Id == user.AreaId);

            return Ok(new
            {
                id = user.Id,
                fullName = user.FullName,
                email = user.Email,
                role = roles.FirstOrDefault(),
                profilePictureUrl = user.ProfilePictureUrl,
                emailConfirmed = user.EmailConfirmed,
                areaId = user.AreaId,
                areaName = area?.Name,
                wardId = area?.WardId,
                wardName = area?.Ward?.Name
            });
        }

        [Authorize]
        [HttpPut("change-password")]
        public async Task<IActionResult> ChangePassword(
            ChangePasswordDTO dto)
        {
            var userIdClaim =
                User.FindFirst(ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
            {
                return Unauthorized();
            }

            var user = await _userManager.FindByIdAsync(
                userIdClaim.Value);

            if (user == null)
            {
                return NotFound();
            }

            var result = await _userManager.ChangePasswordAsync(
                user,
                dto.CurrentPassword,
                dto.NewPassword);

            if (!result.Succeeded)
            {
                var errors = result.Errors
                    .Select(e => e.Description)
                    .ToList();

                return BadRequest(errors);
            }

            var userTokens = await _context.RefreshTokens
                .Where(rt => rt.UserId == user.Id && !rt.IsRevoked)
                .ToListAsync();

            foreach (var t in userTokens)
            {
                t.IsRevoked = true;
            }

            await _context.SaveChangesAsync();

            return Ok("Password changed successfully");
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword(ForgotPasswordDTO dto)
        {
            var user = await _userManager.FindByEmailAsync(dto.Email);

            if (user == null || !user.EmailConfirmed)
            {
                return Ok("If the account exists, a password reset email has been sent");
            }

            var token = await _userManager.GeneratePasswordResetTokenAsync(user);

            var resetUrl =
                $"{_config["Email:ResetPasswordUrl"]}" +
                $"?email={Uri.EscapeDataString(user.Email!)}" +
                $"&token={Uri.EscapeDataString(token)}";

            await _emailService.SendEmailAsync(
                user.Email!,
                "Reset your password",
                $"""

                <h2>Reset your password</h2>

                <p>Hi {user.FullName},</p>

                <p>We received a request to reset your password. Click the link below to choose a new one:</p>

                <p><a href = "{resetUrl}">Reset Password</a></p>

                <p>If you did not request this, you can ignore this email</p>
                """
                );

            return Ok("If the account exists, a password reset email has been sent.");
        }

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword(ResetPasswordDTO dto)
        {
            var user = await _userManager.FindByEmailAsync(dto.Email);

            if (user == null)
            {
                return BadRequest("Invalid request");
            }

            var result = await _userManager.ResetPasswordAsync(
                user, dto.Token, dto.NewPassword
                );

            if (!result.Succeeded)
            {
                var errors = result.Errors
                    .Select(e => e.Description)
                    .ToList();

                return BadRequest(errors);
            }

            var userTokens = await _context.RefreshTokens
               .Where(rt => rt.UserId == user.Id && !rt.IsRevoked)
               .ToListAsync();

            foreach (var t in userTokens)
            {
                t.IsRevoked = true;
            }

            await _context.SaveChangesAsync();

            return Ok("Password reset successfully");
        }

        [Authorize]
        [HttpDelete("delete-account")]
        public async Task<IActionResult> DeleteAccount(DeleteAccountDTO dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
            {
                return Unauthorized();
            }

            var user = await _userManager.FindByIdAsync(userIdClaim.Value);

            if (user == null)
            {
                return NotFound();
            }

            // Same rule as the admin route: an Admin account can never be removed through the API
            if (await _userManager.IsInRoleAsync(user, "Admin"))
            {
                return BadRequest("Admin accounts cannot be deleted.");
            }

            var passwordValid = await _userManager.CheckPasswordAsync(user, dto.CurrentPassword);

            if (!passwordValid)
            {
                return BadRequest("Current password is incorrect");
            }

            if (!dto.Confirm)
            {
                return BadRequest("You must confirm account deletion");
            }

            // Reports, issues, supervisor assignments and files are cleaned up in the shared service
            var result = await _userDeletionService.DeleteUserAsync(user);

            if (!result.Succeeded)
            {
                var errors = result.Errors.Select(e => e.Description).ToList();
                return BadRequest(errors);
            }

            return Ok("Account Deleted successfully");
        }

    }
}