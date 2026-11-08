using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MunicipalReportingAPI.Services;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.RateLimiting;
using System.Text.RegularExpressions;

namespace MunicipalReportingAPI.Controllers;

public sealed class ChatMessageDTO
{
    [Required] public string Role { get; set; } = "";
    [Required][StringLength(1000)] public string Content { get; set; } = "";
}

public sealed class ChatRequestDTO
{
    [Required]
    [MinLength(1)]
    [MaxLength(20)]
    public List<ChatMessageDTO> Messages { get; set; } = new();
}

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class ChatController : ControllerBase
{
    private readonly ChatService _chat;
    public ChatController(ChatService chat) => _chat = chat;

    // Public account-access help. Does not call ChatService, Gemini or the database.
    // [AllowAnonymous] overrides the controller's [Authorize] only for this action.
    [HttpPost("public")]
    [AllowAnonymous]
    [EnableRateLimiting("public-chat")]
    public IActionResult Public([FromBody] ChatRequestDTO request)
    {
        // Public requests contain exactly one short user question; conversation
        // history, assistant messages and longer requests are not accepted.
        if (request?.Messages is not { Count: 1 } ||
            request.Messages[0] is null ||
            request.Messages[0].Role != "user" ||
            string.IsNullOrWhiteSpace(request.Messages[0].Content) ||
            request.Messages[0].Content.Length > 300)
        {
            return BadRequest(new
            {
                message = "Ask one account-access question (maximum 300 characters)."
            });
        }

        return Ok(new
        {
            reply = PublicHelpAnswer(request.Messages[0].Content),
            reportDraft = (object?)null
        });
    }

    private static string PublicHelpAnswer(string question)
    {
        var t = Regex.Replace(question.ToLowerInvariant().Replace('’', '\''),
            @"[^a-z0-9]+", " ").Trim();

        // Explicitly scoped to public access help. No generative model or
        // external service is used to interpret these inputs.
        bool Has(params string[] terms) => terms.Any(term =>
            Regex.IsMatch(t, @"\b" + Regex.Escape(term) + @"\b"));

        if (Has("forgot password", "forgotten password", "reset password",
                "recover password", "lost password", "forgot my password",
                "cant remember my password", "cannot remember my password",
                "change forgotten password"))
            return "On the Fix My Area Login screen, select Forgot Password. " +
                   "Enter your registered email address, then follow the reset " +
                   "link sent to that address. Choose a new password and log in. " +
                   "Never share your password or reset link with anyone.";

        if (Has("verification email", "confirmation email", "verification link",
                "confirmation link", "email verification", "verify my email",
                "verify email", "confirm my email", "confirm email",
                "not received email", "didnt receive email", "email not received"))
            return "After registering, open the verification email sent to " +
                   "your registered address and follow its link. If you cannot " +
                   "find it, check Spam or Junk and use Resend Confirmation " +
                   "on the email-verification screen.";

        if (Has("register", "registration", "sign up", "signup",
                "create account", "create an account", "make an account",
                "new account", "join fix my area"))
            return "On the Fix My Area welcome screen, select Register. " +
                   "Enter your full name, email address and password, choose " +
                   "your ward and area, and submit. Then confirm your email " +
                   "using the link sent to you before logging in.";

        if (Has("login", "log in", "sign in", "signin",
                "access my account", "enter my account", "get into my account"))
            return "On the Fix My Area welcome screen, select Login. " +
                   "Enter your registered email and password, then select " +
                   "Login. Your email must be verified first. If you cannot " +
                   "remember your password, select Forgot Password.";

        if (Has("what is fix my area", "what does fix my area do",
                "about fix my area", "what is this app", "what does this app do",
                "what can you help", "what can i ask", "help topics", "hello", "hi"))
            return "Fix My Area helps residents report municipal issues and " +
                   "follow their progress. Before logging in, I can explain " +
                   "registration, login, forgotten-password recovery and " +
                   "email verification. Sign in for report and area information.";

        return "I can help you register, log in, reset a forgotten password " +
               "or verify your email. Please sign in to ask about reports, " +
               "account changes or area statistics.";
    }

    [HttpPost]
    public async Task<IActionResult> Post([FromBody] ChatRequestDTO request, CancellationToken ct)
    {
        if (request.Messages.Count == 0 || request.Messages.Count > 20 ||
            request.Messages.Any(m => m.Role is not ("user" or "assistant") ||
                                      string.IsNullOrWhiteSpace(m.Content) || m.Content.Length > 1000) ||
            request.Messages[^1].Role != "user")
            return BadRequest(new { message = "Please send a valid chat message (maximum 1000 characters)." });

        var reply = await _chat.ReplyAsync(User, request.Messages, ct);
        // Preserve the existing Flutter response contract. No report submission is performed here.
        return Ok(new { reply, reportDraft = (object?)null });
    }
}
