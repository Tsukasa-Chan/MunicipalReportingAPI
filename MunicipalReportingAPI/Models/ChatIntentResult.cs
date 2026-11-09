namespace MunicipalReportingAPI.Models;

// Only classifications in these allowlists can be used by the application.
public sealed class ChatIntentResult
{
    public string Intent { get; set; } = "unknown";
    public string Category { get; set; } = "none";
    public string IssueType { get; set; } = "none";
    public string Status { get; set; } = "all";
    public string Metric { get; set; } = "issues";

    public static readonly HashSet<string> AllowedIntents = new(StringComparer.Ordinal)
    {
        "unknown", "greeting", "thanks", "registration", "login", "verify_email",
        "forgot_password", "change_email", "change_password", "edit_profile",
        "delete_report", "edit_report", "submit_report", "privacy_policy",
        "terms_conditions", "schedule_download", "downloads", "report_status_help",
        "issue_category_help", "area_stats_help", "supervisor_schedule", "support",
        "issue_statistics", "my_reports", "capabilities",
        "app_about", "location_help", "view_reports_help"
    };
    public static readonly HashSet<string> AllowedCategories = new(StringComparer.Ordinal)
    {
        "none", "WaterAndSanitation", "RoadsAndStormwater", "Electricity", "WasteManagement"
    };
    public static readonly HashSet<string> AllowedIssueTypes = new(StringComparer.Ordinal)
    {
        "none", "Pothole", "BurstPipe", "LeakingPipe", "NoWaterSupply", "LowWaterPressure",
        "BlockedSewerOrManhole", "SewageSpill", "DiscoloredOrDirtyWater", "Sinkhole",
        "BlockedStormDrain", "FloodedRoad", "TrafficLightNotWorking", "MissingOrDamagedRoadSign",
        "FadedRoadMarkings", "StreetLightNotWorking", "StreetLightOnDuringDay", "PowerOutage",
        "ExposedOrDamagedCable", "DamagedElectricalBox", "MissedBinCollection",
        "IllegalDumping", "OverflowingPublicBin"
    };
    public static readonly HashSet<string> AllowedStatuses = new(StringComparer.Ordinal)
        { "all", "reported", "in_progress", "resolved", "unresolved" };
    public static readonly HashSet<string> AllowedMetrics = new(StringComparer.Ordinal)
        { "issues", "reports", "most_common" };

    public bool IsValid() => AllowedIntents.Contains(Intent)
        && AllowedCategories.Contains(Category)
        && AllowedIssueTypes.Contains(IssueType)
        && AllowedStatuses.Contains(Status)
        && AllowedMetrics.Contains(Metric);
}
