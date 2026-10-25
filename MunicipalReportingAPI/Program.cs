using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Localization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using MunicipalReportingAPI.Data;
using MunicipalReportingAPI.Models;
using MunicipalReportingAPI.Services;
using System.Globalization;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add controllers
builder.Services
    .AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter());
    });

// Swagger
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(options =>
{
    options.UseInlineDefinitionsForEnums();

    options.AddSecurityDefinition(
        "Bearer",
        new Microsoft.OpenApi.Models.OpenApiSecurityScheme
        {
            Name = "Authorization",
            Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
            Scheme = "Bearer",
            BearerFormat = "JWT",
            In = Microsoft.OpenApi.Models.ParameterLocation.Header,
            Description = "Enter your token below"
        });

    options.AddSecurityRequirement(
        new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
        {
            {
                new Microsoft.OpenApi.Models.OpenApiSecurityScheme
                {
                    Reference =
                        new Microsoft.OpenApi.Models.OpenApiReference
                        {
                            Type =
                                Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,

                            Id = "Bearer"
                        }
                },
                new string[] { }
            }
        });
});

// Database
builder.Services.AddDbContext<MunicipalDBContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString(
            "DefaultConnection")));

// ASP.NET Core Identity
builder.Services
    .AddIdentity<ApplicationUser, IdentityRole<int>>(options =>
    {
        // Password requirements
        options.Password.RequireDigit = true;
        options.Password.RequireLowercase = true;
        options.Password.RequireUppercase = true;
        options.Password.RequireNonAlphanumeric = false;
        options.Password.RequiredLength = 8;

        // Email confirmation
        options.SignIn.RequireConfirmedEmail = true;

        // User settings
        options.User.RequireUniqueEmail = true;

        // Lockout (brute-force protection)
        options.Lockout.AllowedForNewUsers = true;
        options.Lockout.MaxFailedAccessAttempts = 5;
        options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
    })
    .AddEntityFrameworkStores<MunicipalDBContext>()
    .AddDefaultTokenProviders();

// Email service
builder.Services.AddScoped<IEmailService, EmailService>();

// Shared account-deletion rules (used by self-service delete and by the admin)
builder.Services.AddScoped<IUserDeletionService, UserDeletionService>();

// Daily purge of expired revoked-token and refresh-token rows
builder.Services.AddHostedService<TokenCleanupService>();

// Issue grouping (radius comes from the "IssueGrouping" section in appsettings)
builder.Services.Configure<MunicipalReportingAPI.Options.IssueGroupingOptions>(
    builder.Configuration.GetSection(MunicipalReportingAPI.Options.IssueGroupingOptions.SectionName));
builder.Services.AddScoped<IIssueService, IssueService>();

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy(
        "AllowAll",
        policy =>
        {
            policy
                .AllowAnyOrigin()
                .AllowAnyMethod()
                .AllowAnyHeader();
        });
});

// JWT configuration
var jwtKey =
    builder.Configuration["Jwt:Key"];

var jwtIssuer =
    builder.Configuration["Jwt:Issuer"];

var jwtAudience =
    builder.Configuration["Jwt:Audience"];

builder.Services
    .AddAuthentication(
        options =>
        {
            options.DefaultAuthenticateScheme =
                JwtBearerDefaults.AuthenticationScheme;

            options.DefaultChallengeScheme =
                JwtBearerDefaults.AuthenticationScheme;
        })
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters =
            new TokenValidationParameters
            {
                ValidateIssuer = true,

                ValidateAudience = true,

                ValidateLifetime = true,

                ValidateIssuerSigningKey = true,

                ValidIssuer = jwtIssuer,

                ValidAudience = jwtAudience,

                IssuerSigningKey =
                    new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(
                            jwtKey!))
            };

        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var dbContext = context.HttpContext.RequestServices
                    .GetRequiredService<MunicipalDBContext>();

                // 1. Tokens revoked at logout are rejected
                var jti = context.Principal?.FindFirst(JwtRegisteredClaimNames.Jti)?.Value;

                if (jti != null && await dbContext.RevokedTokens.AnyAsync(rt => rt.Jti == jti))
                {
                    context.Fail("Token has been removed");
                    return;
                }

                // 2. The account must still exist, and the token must carry the user's current
                //    security stamp. The stamp changes when an admin changes the user's role or
                //    the password changes, so those sessions end immediately and the person has
                //    to sign in again. (A deleted account has no stamp, so it is rejected too.)
                var principal = context.Principal;
                var userIdValue = principal?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(userIdValue, out var userId))
                {
                    context.Fail("Invalid token");
                    return;
                }

                var currentStamp = await dbContext.Users
                    .Where(u => u.Id == userId)
                    .Select(u => u.SecurityStamp)
                    .FirstOrDefaultAsync();

                var tokenStamp = principal?.FindFirst("security_stamp")?.Value;

                if (currentStamp == null || tokenStamp != currentStamp)
                {
                    context.Fail("Session is no longer valid");
                }
            }
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

// Always parse form values (e.g. latitude/longitude in multipart requests) with the
// invariant culture, so "." is the decimal separator regardless of the server's
// regional settings (en-ZA uses a comma).
var invariantCultures = new[] { CultureInfo.InvariantCulture };

app.UseRequestLocalization(new RequestLocalizationOptions
{
    DefaultRequestCulture = new RequestCulture(CultureInfo.InvariantCulture),
    SupportedCultures = invariantCultures,
    SupportedUICultures = invariantCultures
});

// Swagger
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// In Development the http address (used by the Flutter emulator) must not be
// redirected to https, because the emulator cannot trust the local dev certificate.
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseStaticFiles();

app.UseCors("AllowAll");

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

await SeedRolesAsync(app);
await SeedAdminAsync(app);

app.Run();


static async Task SeedRolesAsync(WebApplication app)
{
    using var scope = app.Services.CreateScope();

    var roleManager =
        scope.ServiceProvider
            .GetRequiredService<
                RoleManager<IdentityRole<int>>>();

    string[] roles =
    {
        "User",
        "Admin",
        "Supervisor"
    };

    foreach (var role in roles)
    {
        if (!await roleManager.RoleExistsAsync(role))
        {
            await roleManager.CreateAsync(
                new IdentityRole<int>(role));
        }
    }
}


// Creates the first Admin from configuration (user secrets), so there is always
// someone who can use the admin endpoints. Does nothing when the settings are empty
// or when an account with that email already exists (existing accounts are never changed).
//   dotnet user-secrets set "SeedAdmin:Email" "admin@example.com"
//   dotnet user-secrets set "SeedAdmin:Password" "YourStrongPassword1"
//   dotnet user-secrets set "SeedAdmin:FullName" "System Admin"
static async Task SeedAdminAsync(WebApplication app)
{
    using var scope = app.Services.CreateScope();

    var config = scope.ServiceProvider.GetRequiredService<IConfiguration>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();

    var email = config["SeedAdmin:Email"];
    var password = config["SeedAdmin:Password"];

    if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
    {
        return;
    }

    if (await userManager.FindByEmailAsync(email) != null)
    {
        return;
    }

    var admin = new ApplicationUser
    {
        FullName = config["SeedAdmin:FullName"] ?? "Administrator",
        Email = email,
        UserName = email,
        EmailConfirmed = true
    };

    var result = await userManager.CreateAsync(admin, password);

    if (!result.Succeeded)
    {
        logger.LogError("Could not seed the admin account: {Errors}",
            string.Join("; ", result.Errors.Select(e => e.Description)));
        return;
    }

    await userManager.AddToRoleAsync(admin, "Admin");
}