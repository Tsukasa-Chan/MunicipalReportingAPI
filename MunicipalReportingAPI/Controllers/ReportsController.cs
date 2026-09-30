using Microsoft.AspNetCore.Mvc;
using MunicipalReportingAPI.Data;
using MunicipalReportingAPI.DTO;
using MunicipalReportingAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace MunicipalReportingAPI.Controllers
{
    [Route("api/[Controller]")]
    [ApiController]
    public class ReportsController : ControllerBase
    {
        private readonly MunicipalDBContext _context;
        private readonly IWebHostEnvironment _env;

        public ReportsController(MunicipalDBContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        private int GetCurrentUserId()
        {
            var idClaim = User.FindFirst(ClaimTypes.NameIdentifier)!.Value;
            return int.Parse(idClaim);
        }

        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] ReportStatus? status,
            [FromQuery] IssueCategory? category,
            [FromQuery] IssueType? issueType)
        {
            var query = _context.Reports.Include(r => r.User).AsQueryable();

            if (status.HasValue)
            {
                query = query.Where(r => r.Status == status.Value);
            }

            if (category.HasValue)
            {
                query = query.Where(r => r.IssueCategory == category.Value);
            }

            if (issueType.HasValue)
            {
                query = query.Where(r => r.IssueType == issueType.Value);
            }

            var reports = await query.OrderByDescending(r => r.CreatedAt).ToListAsync();

            return Ok(reports);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var report = await _context.Reports.Include(r => r.User).FirstOrDefaultAsync(r => r.Id == id);

            if(report == null)
            {
                return NotFound();
            }

            return Ok(report);
        }


        [Authorize]
        [HttpGet("mine")]
        public async Task<IActionResult> GetMyReports()
        {
            var userId = GetCurrentUserId();

            var reports = await _context.Reports
                .Where(r => r.UserId == userId)
                .Include(r => r.User)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return Ok(reports);
        }

        [Authorize]
        [HttpPost]
        public async Task<IActionResult> CreateReport([FromForm] CreateReportDTO dto)
        {
            string? imageUrl = null;

            if (dto.Image != null)
            {
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
                var uploadsFolder = Path.Combine(webRootPath, "uploads");
                Directory.CreateDirectory(uploadsFolder);

                var fileName = Guid.NewGuid() + extension;
                var filePath = Path.Combine(uploadsFolder, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await dto.Image.CopyToAsync(stream);
                }

                imageUrl = $"/uploads/{fileName}";
            }

                var report = new Report
                {
                    IssueCategory = dto.IssueCategory,
                    IssueType = dto.IssueType,
                    Location = dto.Location,
                    Latitude = dto.Latitude,
                    Longitude = dto.Longitude,
                    Description = dto.Description,
                    ImageUrl = imageUrl,
                    Status = ReportStatus.Reported,
                    CreatedAt = DateTime.UtcNow,
                    UserId = GetCurrentUserId()
                };

                _context.Reports.Add(report);
                await _context.SaveChangesAsync();

                return Ok(report);
            
        }

        [Authorize]
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateReport(int id, [FromForm] UpdateReportDTO dto)
        {
            var report = await _context.Reports.FindAsync(id);
            if(report == null)
            {
                return NotFound();
            }

            if(report.UserId != GetCurrentUserId())
            {
                return Forbid();
            }

            report.IssueCategory = dto.IssueCategory;
            report.IssueType = dto.IssueType;
            report.Location = dto.Location;
            report.Latitude = dto.Latitude;
            report.Longitude = dto.Longitude;
            report.Description = dto.Description;
            report.UpdatedAt = DateTime.UtcNow;

            if(dto.Image != null)
            {
                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png" };
                var extension = Path.GetExtension(dto.Image.FileName).ToLower();

                if (!allowedExtensions.Contains(extension))
                {
                    return BadRequest("Only JPG and PNG images are allowed");
                }

                if(dto.Image.Length > 5 * 1024 * 1024)
                {
                    return BadRequest("Image must be smaller than 5MB");
                }

                var webRootPath = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
                var uploadsFolder = Path.Combine(webRootPath, "uploads");
                Directory.CreateDirectory(uploadsFolder);

                if (!string.IsNullOrEmpty(report.ImageUrl))
                {
                    var oldImagePath = Path.Combine(webRootPath, report.ImageUrl.TrimStart('/'));

                    if (System.IO.File.Exists(oldImagePath))
                    {
                        System.IO.File.Delete(oldImagePath);
                    }

                }

                var fileName = Guid.NewGuid() + Path.GetExtension(dto.Image.FileName);
                var filePath = Path.Combine(uploadsFolder, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await dto.Image.CopyToAsync(stream);
                }

                report.ImageUrl = $"/uploads/{fileName}";
            }

            await _context.SaveChangesAsync();
            return Ok(report);
        }

        [Authorize]
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteReport(int id)
        {
            var report = await _context.Reports.FindAsync(id);
            if(report == null)
            {
                return NotFound();
            }

            if (report.UserId != GetCurrentUserId())
            {
                return Forbid();
            }

            if (!string.IsNullOrEmpty(report.ImageUrl))
            {
                var imagePath = Path.Combine(Directory.GetCurrentDirectory(),
                    "wwwroot", report.ImageUrl.TrimStart('/'));

                if (System.IO.File.Exists(imagePath))
                {
                    System.IO.File.Delete(imagePath);
                }
            }

            _context.Reports.Remove(report);
            await _context.SaveChangesAsync();

            return Ok("Report deleted successfully");
        }


        [Authorize(Roles ="Admin,Supervisor")]
        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateStatus(int id, [FromQuery] ReportStatus status)
        {
            var report = await _context.Reports.FindAsync(id);
            if(report == null)
            {
                return NotFound();
            }

            report.Status = status;
            report.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return Ok(report);
        }
    }
}
