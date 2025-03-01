using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;

namespace server.Filters
{
    public class AuthorizationJWT : Attribute, IAuthorizationFilter
    {
        private readonly string _secretKey;
        private readonly ILogger<AuthorizationJWT> _logger;

        public AuthorizationJWT(IConfiguration configuration, ILogger<AuthorizationJWT> logger)
        {
            _secretKey = configuration["Jwt:SecretKey"]; 
            _logger = logger;
        }

        public void OnAuthorization(AuthorizationFilterContext context)
        {
            var authHeader = context.HttpContext.Request.Headers["Authorization"].FirstOrDefault();

            if (string.IsNullOrEmpty(authHeader) || !authHeader.StartsWith("Bearer "))
            {
                _logger.LogWarning("Authorization header is missing or invalid.");
                context.Result = new UnauthorizedResult();
                return;
            }

            var token = authHeader.Split(" ").Last();

            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();
                var key = Encoding.UTF8.GetBytes(_secretKey);

                tokenHandler.ValidateToken(token, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidateIssuer = false, // Có thể thay đổi nếu cần
                    ValidateAudience = false, // Có thể thay đổi nếu cần
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero
                }, out SecurityToken validatedToken);
            }
            catch (SecurityTokenExpiredException)
            {
                _logger.LogWarning("Token has expired.");
                context.Result = new UnauthorizedResult();
            }
            catch (SecurityTokenException ex)
            {
                _logger.LogWarning($"Token validation failed: {ex.Message}");
                context.Result = new UnauthorizedResult();
            }
            catch (Exception ex)
            {
                _logger.LogError($"Unexpected error during token validation: {ex.Message}");
                context.Result = new StatusCodeResult(500); // Lỗi server
            }
        }
    }
}
