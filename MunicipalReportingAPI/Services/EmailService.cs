using System.Net;
using System.Net.Mail;

namespace MunicipalReportingAPI.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;

        public EmailService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public async Task SendEmailAsync(
            string recipient,
            string subject,
            string htmlMessage)
        {
            var smtpHost =
                _configuration["Email:SmtpHost"];

            var smtpPort =
                int.Parse(_configuration["Email:SmtpPort"]!);

            var username =
                _configuration["Email:Username"];

            var password =
                _configuration["Email:Password"];

            var fromEmail =
                _configuration["Email:FromEmail"];

            var fromName =
                _configuration["Email:FromName"];

            using var message = new MailMessage();

            message.From = new MailAddress(
                fromEmail!,
                fromName);

            message.To.Add(recipient);

            message.Subject = subject;

            message.Body = htmlMessage;

            message.IsBodyHtml = true;

            using var smtp = new SmtpClient(
                smtpHost,
                smtpPort);

            smtp.EnableSsl = true;

            smtp.Credentials = new NetworkCredential(
                username,
                password);

            await smtp.SendMailAsync(message);
        }
    }
}