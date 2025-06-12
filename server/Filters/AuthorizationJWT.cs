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
        public void OnAuthorization(AuthorizationFilterContext context)
        {
            var config = context.HttpContext.RequestServices.GetService(typeof(IConfiguration)) as IConfiguration;
            var logger = context.HttpContext.RequestServices.GetService(typeof(ILogger<AuthorizationJWT>)) as ILogger;

            var jwtSettings = config.GetSection("JWTSettings");
            var secretKey = jwtSettings["SecretKey"];
            var issuer = jwtSettings["Issuer"];
            var audience = jwtSettings["Audience"];

            var authHeader = context.HttpContext.Request.Headers["Authorization"].FirstOrDefault();

            if (string.IsNullOrEmpty(authHeader) || !authHeader.StartsWith("Bearer "))
            {
                logger?.LogWarning("Authorization header is missing or invalid.");
                context.Result = new UnauthorizedResult();
                return;
            }

            var token = authHeader.Split(" ").Last();
            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();
                var key = Encoding.UTF8.GetBytes(secretKey);

                tokenHandler.ValidateToken(token, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidateIssuer = true,
                    ValidIssuer = issuer,
                    ValidateAudience = true,
                    ValidAudience = audience,
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero // Không cho phép thời gian lệch
                }, out SecurityToken validatedToken);
            }
            catch (SecurityTokenExpiredException)
            {
                logger?.LogWarning("Token has expired.");
                context.Result = new UnauthorizedResult();
            }
            catch (SecurityTokenException ex)
            {
                logger?.LogWarning($"Token validation failed: {ex.Message}");
                context.Result = new UnauthorizedResult();
            }
            catch (Exception ex)
            {
                logger?.LogError($"Unexpected error during token validation: {ex.Message}");
                context.Result = new StatusCodeResult(500);
            }
        }
    }
}
