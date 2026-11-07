using System.ComponentModel.DataAnnotations;
using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.DTO;

public class SaveCommunityNoticeDTO
{
    [Required, StringLength(150, MinimumLength = 3)]
    public string Title { get; set; } = string.Empty;

    [Required, StringLength(3000, MinimumLength = 5)]
    public string Description { get; set; } = string.Empty;

    public NoticeCategory Category { get; set; } = NoticeCategory.General;
    public NoticeAudience Audience { get; set; } = NoticeAudience.All;
    public int? AreaId { get; set; }
    public int? WardId { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public bool IsActive { get; set; } = true;
}

public class CommunityNoticeResponseDTO
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public NoticeCategory Category { get; set; }
    public NoticeAudience Audience { get; set; }
    public int? AreaId { get; set; }
    public string? AreaName { get; set; }
    public int? WardId { get; set; }
    public string? WardName { get; set; }
    public int? CreatedByUserId { get; set; }
    public string? CreatedByName { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public bool IsActive { get; set; }
}
