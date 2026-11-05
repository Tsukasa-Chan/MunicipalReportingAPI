using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MunicipalReportingAPI.DTO;
using MunicipalReportingAPI.Services;
using System.Net;

namespace MunicipalReportingAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class BugReportsController : ControllerBase
    {
        private readonly IEmailService _emailService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<BugReportsController> _logger;

        public BugReportsController(
            IEmailService emailService,
            IConfiguration configuration,
            ILogger<BugReportsController> logger)
        {
            _emailService = emailService;
            _configuration = configuration;
            _logger = logger;
        }

        [HttpPost]
        public async Task<IActionResult> SubmitBugReport(
            [FromBody] BugReportDTO dto)
        {
            var supportEmail =
                _configuration["Email:BugReportRecipient"];

            if (string.IsNullOrWhiteSpace(supportEmail))
            {
                return StatusCode(500,
                    "Bug reporting is not configured.");
            }

            var name = WebUtility.HtmlEncode(dto.Name);
            var email = WebUtility.HtmlEncode(dto.Email);
            var description = WebUtility.HtmlEncode(dto.Description)
                .Replace("\r\n", "<br>")
                .Replace("\n", "<br>");

            var message = $"""
                <h2>New Bug Report - Fix My City</h2>

                <p><strong>Name:</strong> {name}</p>
                <p><strong>Email:</strong> {email}</p>

                <h3>Issue Description:</h3>
                <p>{description}</p>
                """;

            try
            {
                await _emailService.SendEmailAsync(
                    supportEmail,
                    "Fix My City - Bug Report",
                    message
                );

                return Ok(new
                {
                    message = "Bug report submitted successfully."
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Failed to send bug report email.");

                return StatusCode(500, new
                {
                    message = "Could not send bug report."
                });
            }
        }
    }
}