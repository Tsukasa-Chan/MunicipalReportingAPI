using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalReportingAPI.Data;
using MunicipalReportingAPI.DTO;
using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CommunityNoticesController : ControllerBase
{
    private readonly MunicipalDBContext _db;
    public CommunityNoticesController(MunicipalDBContext db) => _db = db;

    private int? CurrentUserId =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : null;

    // Restrict the resident feed by the AreaId on their authenticated account,
    // not by a client-supplied area or ward ID.
    private async Task<IQueryable<CommunityNotice>?> VisibleNoticesAsync()
    {
        var userId = CurrentUserId;
        if (!userId.HasValue) return null;

        var area = await _db.Users.AsNoTracking()
            .Where(u => u.Id == userId.Value)
            .Select(u => new { u.AreaId, WardId = u.Area == null ? (int?)null : u.Area.WardId })
            .FirstOrDefaultAsync();
        if (area == null) return null;

        var now = DateTime.UtcNow;
        return _db.CommunityNotices.AsNoTracking()
            .Where(n => n.IsActive && (n.ExpiresAt == null || n.ExpiresAt > now))
            .Where(n => n.Audience == NoticeAudience.All ||
                        (area.AreaId.HasValue && n.Audience == NoticeAudience.Area && n.AreaId == area.AreaId) ||
                        (area.WardId.HasValue && n.Audience == NoticeAudience.Ward && n.WardId == area.WardId));
    }

    private static IQueryable<CommunityNoticeResponseDTO> ToResponse(IQueryable<CommunityNotice> query) =>
        query.Select(n => new CommunityNoticeResponseDTO
        {
            Id = n.Id,
            Title = n.Title,
            Description = n.Description,
            Category = n.Category,
            Audience = n.Audience,
            AreaId = n.AreaId,
            AreaName = n.Area == null ? null : n.Area.Name,
            WardId = n.WardId,
            WardName = n.Ward == null ? (n.Area == null || n.Area.Ward == null ? null : n.Area.Ward.Name) : n.Ward.Name,
            CreatedByUserId = n.CreatedByUserId,
            CreatedByName = n.CreatedByUser == null ? null : n.CreatedByUser.FullName,
            CreatedAt = n.CreatedAt,
            UpdatedAt = n.UpdatedAt,
            ExpiresAt = n.ExpiresAt,
            IsActive = n.IsActive
        });

    // Resident feed: area, ward and all-community notices only.
    [HttpGet]
    public async Task<IActionResult> GetVisible()
    {
        var query = await VisibleNoticesAsync();
        if (query == null) return Unauthorized();
        return Ok(await ToResponse(query.OrderByDescending(n => n.CreatedAt)).ToListAsync());
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var query = await VisibleNoticesAsync();
        if (query == null) return Unauthorized();
        var notice = await ToResponse(query.Where(n => n.Id == id)).FirstOrDefaultAsync();
        return notice == null ? NotFound() : Ok(notice);
    }

    // Admin sees active, inactive and expired notices for management.
    [Authorize(Roles = "Admin")]
    [HttpGet("manage")]
    public async Task<IActionResult> Manage()
    {
        var notices = await ToResponse(_db.CommunityNotices.AsNoTracking()
            .OrderByDescending(n => n.CreatedAt)).ToListAsync();
        return Ok(notices);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] SaveCommunityNoticeDTO input)
    {
        var error = await ValidateNoticeAsync(input);
        if (error != null) return BadRequest(new { message = error });
        if (CurrentUserId is not int userId) return Unauthorized();

        var notice = new CommunityNotice { CreatedByUserId = userId };
        CopyEditable(input, notice);
        _db.CommunityNotices.Add(notice);
        await _db.SaveChangesAsync();
        var saved = await ToResponse(_db.CommunityNotices.AsNoTracking()
            .Where(n => n.Id == notice.Id)).SingleAsync();
        return StatusCode(StatusCodes.Status201Created, saved);
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] SaveCommunityNoticeDTO input)
    {
        var error = await ValidateNoticeAsync(input);
        if (error != null) return BadRequest(new { message = error });
        var notice = await _db.CommunityNotices.FindAsync(id);
        if (notice == null) return NotFound();
        CopyEditable(input, notice);
        notice.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        var updated = await ToResponse(_db.CommunityNotices.AsNoTracking()
            .Where(n => n.Id == id)).SingleAsync();
        return Ok(updated);
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var notice = await _db.CommunityNotices.FindAsync(id);
        if (notice == null) return NotFound();
        _db.CommunityNotices.Remove(notice);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    private async Task<string?> ValidateNoticeAsync(SaveCommunityNoticeDTO input)
    {
        if (string.IsNullOrWhiteSpace(input.Title) || input.Title.Trim().Length < 3)
            return "Title must contain at least 3 characters.";
        if (string.IsNullOrWhiteSpace(input.Description) || input.Description.Trim().Length < 5)
            return "Description must contain at least 5 characters.";
        if (!Enum.IsDefined(input.Audience) || !Enum.IsDefined(input.Category))
            return "Invalid audience or category.";
        if (input.ExpiresAt.HasValue && input.ExpiresAt.Value.Kind == DateTimeKind.Unspecified)
            return "Expiry date must include a UTC offset (for example 2026-11-30T18:00:00Z).";
        if (input.ExpiresAt.HasValue && input.ExpiresAt.Value.ToUniversalTime() <= DateTime.UtcNow)
            return "Expiry must be in the future.";
        switch (input.Audience)
        {
            case NoticeAudience.All:
                return input.AreaId.HasValue || input.WardId.HasValue
                    ? "All-community notices cannot specify an area or ward." : null;
            case NoticeAudience.Ward:
                if (!input.WardId.HasValue || input.AreaId.HasValue)
                    return "Ward notices require WardId and must not specify AreaId.";
                return await _db.Wards.AnyAsync(w => w.Id == input.WardId.Value)
                    ? null : "Ward not found.";
            case NoticeAudience.Area:
                if (!input.AreaId.HasValue || input.WardId.HasValue)
                    return "Area notices require AreaId and must not specify WardId.";
                return await _db.Areas.AnyAsync(a => a.Id == input.AreaId.Value)
                    ? null : "Area not found.";
            default:
                return "Invalid audience.";
        }
    }

    private static void CopyEditable(SaveCommunityNoticeDTO input, CommunityNotice notice)
    {
        notice.Title = input.Title.Trim();
        notice.Description = input.Description.Trim();
        notice.Category = input.Category;
        notice.Audience = input.Audience;
        notice.AreaId = input.Audience == NoticeAudience.Area ? input.AreaId : null;
        notice.WardId = input.Audience == NoticeAudience.Ward ? input.WardId : null;
        notice.ExpiresAt = input.ExpiresAt?.ToUniversalTime();
        notice.IsActive = input.IsActive;
    }
}
