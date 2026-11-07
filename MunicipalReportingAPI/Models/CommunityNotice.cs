using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.Models;

public enum NoticeAudience { All = 0, Ward = 1, Area = 2 }
public enum NoticeCategory { General = 0, Maintenance = 1, Emergency = 2 }

public class CommunityNotice
{
    public int Id { get; set; }
    [MaxLength(150)] public string Title { get; set; } = string.Empty;
    [MaxLength(3000)] public string Description { get; set; } = string.Empty;
    public NoticeCategory Category { get; set; } = NoticeCategory.General;
    public NoticeAudience Audience { get; set; } = NoticeAudience.All;
    public int? AreaId { get; set; }
    public Area? Area { get; set; }
    public int? WardId { get; set; }
    public Ward? Ward { get; set; }
    public int? CreatedByUserId { get; set; }
    public ApplicationUser? CreatedByUser { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public bool IsActive { get; set; } = true;
}
