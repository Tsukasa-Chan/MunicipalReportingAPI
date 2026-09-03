using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using MunicipalReportingAPI.DTO;
using MunicipalReportingAPI.Models;
using System.Security.Claims;

namespace MunicipalReportingAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IWebHostEnvironment _env;

        public UsersController(
            UserManager<ApplicationUser> userManager,
            IWebHostEnvironment env)
        {
            _userManager = userManager;
            _env = env;
        }

        [Authorize]
        [HttpPut("profile-picture")]
        public async Task<IActionResult> UpdateProfilePicture(
            [FromForm] UpdateProfilePictureDTO dto)
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

            var allowedExtensions =
                new[] { ".jpg", ".jpeg", ".png" };

            var extension =
                Path.GetExtension(dto.Image.FileName).ToLower();

            if (!allowedExtensions.Contains(extension))
            {
                return BadRequest(
                    "Only JPG and PNG images are allowed");
            }

            if (dto.Image.Length > 5 * 1024 * 1024)
            {
                return BadRequest(
                    "Image must be smaller than 5MB");
            }

            var webRootPath =
                _env.WebRootPath ??
                Path.Combine(
                    Directory.GetCurrentDirectory(),
                    "wwwroot");

            var uploadsFolder =
                Path.Combine(
                    webRootPath,
                    "profile-pictures");

            Directory.CreateDirectory(uploadsFolder);

            var fileName =
                Guid.NewGuid() + extension;

            var filePath =
                Path.Combine(
                    uploadsFolder,
                    fileName);

            using (var stream =
                   new FileStream(
                       filePath,
                       FileMode.Create))
            {
                await dto.Image.CopyToAsync(stream);
            }

            user.ProfilePictureUrl =
                $"/profile-pictures/{fileName}";

            await _userManager.UpdateAsync(user);

            return Ok(new
            {
                profilePictureUrl =
                    user.ProfilePictureUrl
            });
        }
    }
}