using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MunicipalReportingAPI.Services;
using System.ComponentModel.DataAnnotations;

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
