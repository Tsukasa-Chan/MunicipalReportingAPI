using System.Security.Claims;
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using MunicipalReportingAPI.Controllers;
using MunicipalReportingAPI.Data;
using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.Services;

/// <summary>Restricted help assistant: AI classification with authorised, read-only backend operations.</summary>
public sealed class ChatService
{
    private readonly MunicipalDBContext _db;
    private readonly AiIntentService _ai;
    public ChatService(MunicipalDBContext db, AiIntentService ai)
    {
        _db = db;
        _ai = ai;
    }


    private const string Unknown = "I can only help with Fix My Area. Ask me about registering, logging in, submitting or managing reports, your profile, downloads, or issue statistics in your area.";

    private const string Capabilities =
        "Hi! I'm the Fix My Area assistant. I can help you with:\n\n" +
        "1. Account management: Registering, logging in, verifying email, resetting passwords and updating your profile.\n" +
        "2. Municipal reports: Submitting, editing, deleting and viewing reports.\n" +
        "3. Area statistics: Checking potholes, water issues, electricity problems and other municipal issues in your registered area.\n" +
        "4. Downloads: Downloading submitted reports, area statistics, the Privacy Policy and Terms & Conditions.\n" +
        "5. Supervisor features: Explaining how supervisors view their schedules (schedule PDF downloads aren't currently available).\n" +
        "6. Support: Helping with common app problems and showing how to contact support.\n\n" +
        "What would you like help with?";

    // Match broad capability questions, not task-specific requests such as
    // 'Can you help me delete a report?'.
    private static bool IsCapabilitiesQuestion(string t) =>
        Has(t, "what can you help me with", "what can you help with",
            "what can you do", "what do you do", "how can you help me",
            "how can you help", "how can you assist me", "what are your features",
            "your features", "your capabilities", "what are you capable of",
            "what can i ask you", "what questions can i ask",
            "tell me what you can do", "what is this chatbot for") &&
        !Has(t, "report", "reports", "pothole", "issues", "issue", "statistics",
            "email", "password", "download", "privacy", "terms", "schedule",
            "supervisor", "profile", "registration", "register");

    private static readonly (IssueCategory Category, string[] Terms)[] Categories =
    {
        (IssueCategory.WaterAndSanitation, new[]{"water", "sanitation", "sewer", "sewage", "pipe", "leak"}),
        (IssueCategory.RoadsAndStormwater, new[]{"road", "roads", "stormwater", "traffic", "pothole", "drain", "sinkhole"}),
        (IssueCategory.Electricity, new[]{"electricity", "electrical", "power", "streetlight", "street light", "cable"}),
        (IssueCategory.WasteManagement, new[]{"waste", "rubbish", "trash", "garbage", "bin", "dumping", "refuse"})
    };
    private static readonly (IssueType Type, string[] Terms)[] Types =
    {
        (IssueType.Pothole, new[]{"pothole", "potholes"}),
        (IssueType.BurstPipe, new[]{"burst pipe", "burst pipes"}),
        (IssueType.LeakingPipe, new[]{"leaking pipe", "leaking pipes", "pipe leak"}),
        (IssueType.NoWaterSupply, new[]{"no water", "water outage"}),
        (IssueType.LowWaterPressure, new[]{"low water pressure"}),
        (IssueType.BlockedSewerOrManhole, new[]{"blocked sewer", "blocked manhole"}),
        (IssueType.SewageSpill, new[]{"sewage spill", "sewage spills"}),
        (IssueType.DiscoloredOrDirtyWater, new[]{"dirty water", "discolored water", "discoloured water"}),
        (IssueType.Sinkhole, new[]{"sinkhole", "sinkholes"}),
        (IssueType.BlockedStormDrain, new[]{"blocked drain", "blocked storm drain"}),
        (IssueType.FloodedRoad, new[]{"flooded road", "road flooding"}),
        (IssueType.TrafficLightNotWorking, new[]{"traffic light", "traffic lights"}),
        (IssueType.MissingOrDamagedRoadSign, new[]{"road sign", "road signs"}),
        (IssueType.FadedRoadMarkings, new[]{"road marking", "road markings"}),
        (IssueType.StreetLightNotWorking, new[]{"broken streetlight", "broken street light", "streetlight not working", "street light not working"}),
        (IssueType.StreetLightOnDuringDay, new[]{"streetlight on during day", "street light on during day"}),
        (IssueType.PowerOutage, new[]{"power outage", "power cut", "power failure"}),
        (IssueType.ExposedOrDamagedCable, new[]{"exposed cable", "damaged cable"}),
        (IssueType.DamagedElectricalBox, new[]{"electrical box", "electricity box"}),
        (IssueType.MissedBinCollection, new[]{"missed bin", "bin collection", "missed collection"}),
        (IssueType.IllegalDumping, new[]{"illegal dumping", "dumped rubbish"}),
        (IssueType.OverflowingPublicBin, new[]{"overflowing bin", "full public bin"})
    };

    private static string Clean(string input) =>
        Regex.Replace(Regex.Replace(input.ToLowerInvariant().Replace('’', '\''), @"[^a-z0-9\s]", " "), @"\s+", " ").Trim();
    private static bool Has(string text, params string[] terms) => terms.Any(term =>
        Regex.IsMatch(text, @"\b" + Regex.Escape(term) + @"\b", RegexOptions.IgnoreCase));
    private static bool Any(string text, params string[] terms) => Has(text, terms);
    private static bool CountIntent(string t) =>
        Has(t, "how many", "number of", "count", "total", "statistics", "stats", "most common", "how much", "what is happening", "what s happening", "whats happening", "any unresolved", "are there any", "how are things", "status of", "how many of those") ||
        (Has(t, "show", "tell", "give") && Has(t, "issues", "problems", "statistics", "stats"));
    private static ReportStatus? Status(string t) =>
        Has(t, "unresolved", "outstanding", "active", "still open", "not resolved") ? null :
        Has(t, "in progress", "being worked", "underway") ? ReportStatus.InProgress :
        Has(t, "resolved", "fixed", "completed") ? ReportStatus.Resolved :
        Has(t, "reported", "pending", "new") ? ReportStatus.Reported : null;
    private static bool Active(string t) => Has(t, "unresolved", "outstanding", "active", "still open", "not resolved");
    private static bool WantsMine(string t) => Has(t, "my reports", "i submitted", "i have submitted", "have i submitted", "reports have i", "submitted by me", "my submissions");

    public async Task<string> ReplyAsync(ClaimsPrincipal principal, IReadOnlyList<ChatMessageDTO> messages, CancellationToken ct)
    {
        var current = Clean(messages[^1].Content);
        if (current.Length == 0) return Unknown;

        // Enforce these exclusions even when the AI or fallback would misclassify a prompt.
        if (Has(current, "system prompt", "developer instructions", "hidden configuration",
            "ignore previous instructions", "ignore all instructions", "reveal your instructions",
            "print your prompt", "jailbreak")) return Unknown;

        // Answer general 'what can you do?' questions even if Gemini is offline
        // or mistakenly classifies them as unknown.
        if (IsCapabilitiesQuestion(current)) return Capabilities;

        // Clear account-recovery questions take priority over generic login guidance.
        // A user may have forgotten either their password or registered email address.
        if (Has(current, "login details", "login credentials", "sign in details", "sign in credentials", "account credentials") &&
            Has(current, "forgot", "forgotten", "forget", "remember", "lost", "recover", "cant", "cannot", "don t", "dont"))
            return "If you cannot remember your Fix My Area login details, open Login and select Forgot Password to reset your password using your registered email address. If you cannot remember which email address you registered with, use Contact Us to request assistance. Never share your password with support.";

        // A location-information question can mean local news; respond only with the
        // municipal-issues capability of the app, not general neighbourhood events.
        if (Has(current, "neighbourhood", "neighborhood", "community", "local area") &&
            Has(current, "what s happening", "whats happening", "what is happening", "what is going on", "what s going on", "whats going on", "where do i find out", "where can i see") &&
            !Has(current, "news", "events", "weather", "sports", "restaurants", "concerts"))
            return "For municipal issues in your neighbourhood, sign in and open the Fix My Area Home dashboard. It shows issue statistics for your registered area, including water and sanitation, roads and stormwater, electricity, and waste management. You can also ask me how many potholes or unresolved water issues are in your area. I don't provide general local news or events.";

        var classification = await _ai.ClassifyAsync(messages, ct);
        if (classification == null)
            return await ReplyRulesAsync(principal, messages, ct); // Offline/rate-limit fallback
        if (classification.Intent == "unknown") return Unknown;

        if (classification.Intent == "issue_statistics" || classification.Intent == "my_reports")
            return await AnswerStructuredStatisticsAsync(principal, classification, ct);

        // Map validated intent labels to locally approved text, never model-written instructions.
        string? canonical = classification.Intent switch
        {
            "greeting" => "hello",
            "thanks" => "thanks",
            "registration" => "how do i register an account",
            "login" => "how do i log in",
            "verify_email" => "how do i verify email",
            "forgot_password" => "forgot password",
            "change_email" => "how do i change email",
            "change_password" => "how do i change password",
            "edit_profile" => "how do i edit my name in profile",
            "delete_report" => "how do i delete my report",
            "edit_report" => "how do i edit my report",
            "submit_report" => "how do i submit a report",
            "privacy_policy" => "where do i download privacy policy",
            "terms_conditions" => "where do i download terms and conditions",
            "schedule_download" => "can i download supervisor schedule",
            "downloads" => "how do i download pdf reports",
            "report_status_help" => "what does report status mean",
            "issue_category_help" => "how do i choose issue category",
            "area_stats_help" => "how do i view area statistics",
            "supervisor_schedule" => "how do i view supervisor schedule",
            "support" => "how do i contact support",
            "capabilities" => "what can you help me with",
            _ => null
        };
        if (canonical == null) return Unknown;
        return await ReplyRulesAsync(principal,
            new[] { new ChatMessageDTO { Role = "user", Content = canonical } }, ct);
    }

    private async Task<string> AnswerStructuredStatisticsAsync(
        ClaimsPrincipal principal, ChatIntentResult intent, CancellationToken ct)
    {
        if (!int.TryParse(principal.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
            return "Please sign in to view statistics.";

        if (intent.Intent == "my_reports")
        {
            var reports = _db.Reports.AsNoTracking().Where(r => r.UserId == userId);
            reports = intent.Status switch
            {
                "reported" => reports.Where(r => r.Issue!.Status == ReportStatus.Reported),
                "in_progress" => reports.Where(r => r.Issue!.Status == ReportStatus.InProgress),
                "resolved" => reports.Where(r => r.Issue!.Status == ReportStatus.Resolved),
                "unresolved" => reports.Where(r => r.Issue!.Status != ReportStatus.Resolved),
                _ => reports
            };
            var reportCount = await reports.CountAsync(ct);
            return $"You have {reportCount} matching submitted {(reportCount == 1 ? "report" : "reports")}. Open Profile to view your reports.";
        }

        var profile = await _db.Users.AsNoTracking().Where(u => u.Id == userId)
            .Select(u => new { u.AreaId, AreaName = u.Area != null ? u.Area.Name : null })
            .FirstOrDefaultAsync(ct);
        if (profile?.AreaId == null)
            return "Your account does not have a registered area. Area statistics are available to users with an assigned area.";

        // Only predeclared enum values can reach these EF queries: no generated SQL or arbitrary areas.
        if (intent.Metric == "reports")
        {
            var reportQuery = _db.Reports.AsNoTracking().Where(r => r.AreaId == profile.AreaId.Value);
            if (intent.Category != "none" && Enum.TryParse<IssueCategory>(intent.Category, out var reportCategory))
                reportQuery = reportQuery.Where(r => r.Issue!.IssueCategory == reportCategory);
            if (intent.IssueType != "none" && Enum.TryParse<IssueType>(intent.IssueType, out var reportType))
                reportQuery = reportQuery.Where(r => r.Issue!.IssueType == reportType);
            reportQuery = intent.Status switch
            {
                "reported" => reportQuery.Where(r => r.Issue!.Status == ReportStatus.Reported),
                "in_progress" => reportQuery.Where(r => r.Issue!.Status == ReportStatus.InProgress),
                "resolved" => reportQuery.Where(r => r.Issue!.Status == ReportStatus.Resolved),
                "unresolved" => reportQuery.Where(r => r.Issue!.Status != ReportStatus.Resolved),
                _ => reportQuery
            };
            var reportCount = await reportQuery.CountAsync(ct);
            return $"There are {reportCount} matching resident reports in {profile.AreaName}. Several reports can refer to one municipal issue.";
        }

        var query = _db.Issues.AsNoTracking().Where(i => i.AreaId == profile.AreaId.Value);
        if (intent.IssueType != "none" && Enum.TryParse<IssueType>(intent.IssueType, out var type))
            query = query.Where(i => i.IssueType == type);
        else if (intent.Category != "none" && Enum.TryParse<IssueCategory>(intent.Category, out var cat))
            query = query.Where(i => i.IssueCategory == cat);
        query = intent.Status switch
        {
            "reported" => query.Where(i => i.Status == ReportStatus.Reported),
            "in_progress" => query.Where(i => i.Status == ReportStatus.InProgress),
            "resolved" => query.Where(i => i.Status == ReportStatus.Resolved),
            "unresolved" => query.Where(i => i.Status != ReportStatus.Resolved),
            _ => query
        };
        if (intent.Metric == "most_common")
        {
            var mostCommon = await query.GroupBy(i => i.IssueType)
                .Select(g => new { Type = g.Key, Count = g.Count() })
                .OrderByDescending(g => g.Count).FirstOrDefaultAsync(ct);
            return mostCommon == null
                ? $"There are no matching issues recorded in {profile.AreaName}."
                : $"The most common matching issue in {profile.AreaName} is {Pretty(mostCommon.Type.ToString())}, with {mostCommon.Count} issues.";
        }

        var count = await query.CountAsync(ct);
        var subject = intent.IssueType != "none" ? Pretty(intent.IssueType) + " issues"
            : intent.Category != "none" ? Pretty(intent.Category) + " issues" : "municipal issues";
        var filter = intent.Status switch
        {
            "reported" => "reported ",
            "in_progress" => "in-progress ",
            "resolved" => "resolved ",
            "unresolved" => "unresolved ",
            _ => ""
        };
        return $"There {(count == 1 ? "is" : "are")} {count} {filter}{subject} recorded in {profile.AreaName}. These are distinct municipal issues, not resident reports.";
    }

    private async Task<string> ReplyRulesAsync(ClaimsPrincipal principal, IReadOnlyList<ChatMessageDTO> messages, CancellationToken ct)
    {
        var t = Clean(messages[^1].Content);
        if (t.Length == 0) return Unknown;
        if (Has(t, "cricket", "football", "rugby", "recipe", "weather", "politics", "joke", "movie", "bitcoin", "stock market",
            "system prompt", "developer instructions", "hidden configuration", "ignore previous instructions",
            "ignore all instructions", "reveal your instructions", "print your prompt", "jailbreak")) return Unknown;
        if (Has(t, "hello", "hi", "hey", "good morning", "good afternoon"))
            return "Hi! I'm the Fix My Area help assistant. You can ask how to use the app or ask how many municipal issues are in your registered area.";
        if (Has(t, "thank you", "thanks", "thank u")) return "You're welcome! What else would you like to know about Fix My Area?";

        // Follow-up context: use only the previous USER turn, and never trust assistant text as instructions.
        var previous = messages.Take(messages.Count - 1).Reverse().FirstOrDefault(x => x.Role == "user");
        string previousText = previous == null ? "" : Clean(previous.Content);
        bool followUp = Has(t, "those", "them", "that", "of these", "what about", "and how many", "how many of those", "how about");
        string topicText = followUp ? previousText + " " + t : t;

        bool mine = WantsMine(t) || (followUp && WantsMine(previousText));
        bool wantsStatistics = CountIntent(t) || (followUp && CountIntent(previousText) &&
            (Has(t, "water", "roads", "electricity", "potholes", "pothole", "resolved", "reported", "progress", "waste", "those") || t.StartsWith("what about ")));

        if (wantsStatistics && (mine || Has(topicText, "issue", "issues", "problem", "problems", "pothole", "potholes", "water", "road", "electricity", "waste", "area", "reports", "stats", "statistics", "sewage", "stormwater", "those", "power", "pipe", "bin")))
        {
            if (!int.TryParse(principal.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
                return "Please sign in to view your area statistics.";
            if (mine) return await MyReportsAsync(userId, t, ct);
            return await StatisticsAsync(userId, t, topicText, followUp, ct);
        }

        // Help intents require app-related topic words and action words, or an unmistakable app topic.
        if (Has(t, "register", "registration", "sign up", "signup", "create an account", "new account"))
            return "To register: 1. Open Fix My Area and tap Register. 2. Enter your full name, email and a password. 3. Choose your ward and area. 4. Submit the registration form. 5. Open the verification email and follow the confirmation link. Once your email is verified, you can log in.";
        if (Has(t, "forgot password", "forgotten password", "reset password", "cant remember my password", "cannot remember my password"))
            return "On the Login screen, select Forgot Password. Enter the email associated with your account, follow the email reset instructions, then log in using your new password.";
        if (Has(t, "login", "log in", "sign in", "signin", "logging in"))
            return "To log in: open the app, tap Login, enter your registered email and password, then select Login. You must verify your email first. If you've forgotten your password, use Forgot Password.";
        if (Has(t, "verify email", "email verification", "confirm email", "verification link", "verification email"))
            return "After registering, open the confirmation email sent to your address and use its verification link. If it didn't arrive, check your spam folder and use the resend-confirmation option if available.";
        if ((Has(t, "email", "e mail") && Has(t, "change", "update", "edit", "replace", "switch", "modify", "different", "new", "correct")) ||
            Has(t, "email address", "change email", "update email", "edit email"))
            return "To change your email: open Profile, choose Edit Profile, and select the email-change option. Enter the new email and your current password, then confirm using the link sent to the new email address. Your email only changes after confirmation.";
        if (Has(t, "change password", "update password", "edit password", "my password"))
            return "To change your password while signed in, open your profile/account settings and choose Change Password. Enter your current password and your new password, then save. You may need to sign in again after changing it.";
        if (Has(t, "name", "profile", "picture", "photo") && Has(t, "edit", "change", "update", "modify", "how", "profile", "name"))
            return "To update your full name: open Profile, tap Edit Profile, change your full name and save. Your name may contain spaces, but not numbers. You can also update your profile picture from the profile editing section.";
        if (Has(t, "delete", "remove", "get rid of") && Has(t, "report", "complaint", "submission", "it"))
            return "To delete your submitted report, open Profile, find the report, open its details and select Delete. Confirm the action. Reports cannot be deleted while the issue is In Progress. You can only delete your own reports.";
        if (Has(t, "edit", "change", "update", "fix", "correct", "mistake", "modify") && Has(t, "report", "complaint", "submission", "it", "pothole"))
            return "To edit a report: open Profile, find the report under your reports, open its details and choose Edit. Update the details, then save. You can only edit your own reports while the associated issue is still Reported; editing is locked once work starts or the issue is resolved.";
        // Legal documents are downloadable PDFs in Settings, not report PDFs.
        if (Has(t, "privacy policy", "privacy notice", "privacy document") ||
            (Has(t, "privacy") && Has(t, "download", "print", "pdf", "view", "read", "find", "where", "get", "copy")))
            return "To view or download the Privacy Policy: 1. Open Settings. 2. Select Privacy Policy. 3. Read the policy in the dialog. 4. Tap Download to save a PDF, which you can then open or print.";
        if (Has(t, "terms and conditions", "terms conditions", "terms of conditions", "terms of service", "terms & conditions") ||
            (Has(t, "terms") && Has(t, "download", "print", "pdf", "view", "read", "find", "where", "get", "copy")))
            return "To view or download the Terms & Conditions: 1. Open Settings. 2. Select Terms & Conditions. 3. Read the terms in the dialog. 4. Tap Download to save a PDF, which you can then open or print.";
        if (Has(t, "download", "print", "pdf", "export", "save", "copy") && Has(t, "schedule", "supervisor schedule", "scheduled jobs"))
            return "Supervisors can view their assigned work in the Supervisor Dashboard and Schedule pages. The current app does not include a PDF download or print button for supervisor schedules.";
        if (Has(t, "download", "print", "pdf", "export", "save") && Has(t, "report", "reports", "statistics", "stats", "pdf"))
            return "Available PDF downloads include your submitted reports, your area statistics, the Privacy Policy and the Terms & Conditions. For a report, open its details in Profile and select Download PDF. For area statistics, use the dashboard's download option. For the legal documents, open Settings, select Privacy Policy or Terms & Conditions, and tap Download. Open a saved PDF in a compatible app if you want to print it. Supervisor schedules currently have no PDF download option.";
        if (Has(t, "status", "reported", "in progress", "resolved") && Has(t, "report", "issue", "status", "mean", "meaning"))
            return "Issue statuses: Reported means the issue has been received; In Progress means municipal work has started; Resolved means the issue has been completed. You can view the status of your reports in Profile or the reports section.";
        if (Has(t, "category", "choose", "select", "type") && Has(t, "issue", "report", "pothole", "water", "electricity", "waste", "road", "category"))
            return "Choose the category that matches the problem: Water and Sanitation (for pipes or sewage), Roads and Stormwater (for potholes or drains), Electricity (for outages or streetlights), or Waste Management (for bins and dumping). Then select the more specific issue type.";
        if (Has(t, "submit", "create", "make", "file", "report", "reporting", "complaint", "notify") &&
            Has(t, "report", "issue", "problem", "complaint", "pothole", "burst pipe", "streetlight", "municipality", "damage"))
            return "To submit an issue report: 1. Sign in to Fix My Area. 2. Open the Reporting page. 3. Select the ward/area and the issue category and type. 4. Enter the location and a description, and add an image if needed. 5. Review the information and submit. You can find your reports in your Profile.";
        if (Has(t, "area", "dashboard", "stats", "statistics") && Has(t, "view", "see", "find", "where", "look", "show", "how", "dashboard", "stats", "statistics"))
            return "To view statistics for your registered area, sign in and open the Home dashboard. The area statistics show municipal issues grouped by category and status. You can also ask me, for example, 'How many potholes are in my area?'";
        if (Has(t, "schedule", "supervisor", "assign", "assigned"))
            return "If you're a supervisor, use the Supervisor Dashboard and Schedule pages to view your assigned issues and scheduled work. The current app has no schedule PDF download option.";
        if (Has(t, "contact", "support", "help center", "bug", "error", "crash", "not working", "connection", "internet"))
            return "For an app problem, check your internet connection and try again. You can also use Contact Us or the Report a Bug feature in Settings to contact support. Do not include your password in a bug report.";
        if (IsCapabilitiesQuestion(t)) return Capabilities;
        if (Has(t, "help", "what can you do")) return Unknown;
        return Unknown;
    }

    private async Task<string> MyReportsAsync(int userId, string t, CancellationToken ct)
    {
        var q = _db.Reports.AsNoTracking().Where(r => r.UserId == userId);
        if (Has(t, "resolved", "fixed")) q = q.Where(r => r.Issue!.Status == ReportStatus.Resolved);
        else if (Has(t, "in progress")) q = q.Where(r => r.Issue!.Status == ReportStatus.InProgress);
        else if (Has(t, "unresolved", "outstanding")) q = q.Where(r => r.Issue!.Status != ReportStatus.Resolved);
        var count = await q.CountAsync(ct);
        return $"You have {count} matching submitted {(count == 1 ? "report" : "reports")}. Open Profile to view the details of your reports.";
    }

    private async Task<string> StatisticsAsync(int userId, string current, string topic, bool followUp, CancellationToken ct)
    {
        var profile = await _db.Users.AsNoTracking().Where(u => u.Id == userId)
            .Select(u => new { u.AreaId, AreaName = u.Area != null ? u.Area.Name : null }).FirstOrDefaultAsync(ct);
        if (profile?.AreaId == null)
            return "Your account does not have a registered area. Area statistics are available to users with an assigned area.";

        // Specific type takes precedence; override previous turn's type when the current message specifies another.
        var type = Types.FirstOrDefault(x => x.Terms.Any(term => Has(current, term)));
        if (type.Terms == null && followUp) type = Types.FirstOrDefault(x => x.Terms.Any(term => Has(topic, term)));
        var category = Categories.FirstOrDefault(x => x.Terms.Any(term => Has(current, term)));
        if (category.Terms == null && followUp) category = Categories.FirstOrDefault(x => x.Terms.Any(term => Has(topic, term)));
        var filterText = Has(current, "resolved", "in progress", "reported", "unresolved", "outstanding", "active", "fixed", "pending") ? current : (followUp ? topic : current);
        var status = Status(filterText);
        var active = Active(filterText);

        var q = _db.Issues.AsNoTracking().Where(i => i.AreaId == profile.AreaId.Value);
        if (type.Terms != null) q = q.Where(i => i.IssueType == type.Type);
        else if (category.Terms != null) q = q.Where(i => i.IssueCategory == category.Category);
        if (active) q = q.Where(i => i.Status != ReportStatus.Resolved);
        else if (status.HasValue) q = q.Where(i => i.Status == status.Value);

        if (Has(current, "how many reports", "number of reports", "total reports") && type.Terms == null && category.Terms == null)
        {
            var reports = await _db.Reports.AsNoTracking().CountAsync(r => r.AreaId == profile.AreaId.Value, ct);
            return $"There are {reports} resident reports submitted for {profile.AreaName}. Multiple reports may refer to the same municipal issue.";
        }
        if (Has(current, "most common"))
        {
            var byType = await q.GroupBy(i => i.IssueType)
                .Select(g => new { Type = g.Key, Count = g.Count() })
                .OrderByDescending(x => x.Count).FirstOrDefaultAsync(ct);
            return byType == null ? $"There are no matching issues recorded in {profile.AreaName}." :
                $"The most common matching issue in {profile.AreaName} is {Pretty(byType.Type.ToString())}, with {byType.Count} recorded issues.";
        }
        var count = await q.CountAsync(ct);
        var subject = type.Terms != null ? Pretty(type.Type.ToString()) + " issues" : category.Terms != null ? Pretty(category.Category.ToString()) + " issues" : "municipal issues";
        var state = active ? "unresolved " : status.HasValue ? Pretty(status.Value.ToString()).ToLowerInvariant() + " " : "";
        return $"There {(count == 1 ? "is" : "are")} {count} {state}{subject} recorded in {profile.AreaName}. These are distinct municipal issues, not the number of resident reports.";
    }

    private static string Pretty(string value) => Regex.Replace(value, "([a-z])([A-Z])", "$1 $2");
}
