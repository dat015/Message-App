using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using server.DTO.AuthDTO;
using server.Services.UserService;
using server.Helper;
using server.Models;
using server.DTO;

namespace server.Services.AuthService
{
    public class AuthSV : IAuthSV
    {
        private readonly IUserSV _userSV;
        private readonly IConfiguration _configuration;
        private readonly ILogger logger;
        public AuthSV(IUserSV userSV, IConfiguration configuration, ILogger<AuthSV> logger)
        {
            _userSV = userSV;
            _configuration = configuration;
            this.logger = logger;
        }

       
        public Task<User> RegisterUser(UserDTO model)
        {

            if (model == null)
            {
                throw new ArgumentNullException(nameof(model));
            }

            if (!_userSV.VerifyUser(model))
            {
                Console.WriteLine("Received model: ok " + model);
                return null;
            }
            return _userSV.AddUserAsync(model);
        }

        public async Task<LoginRespose> VerifyUser(LoginDTO model)
        {
            if (model == null)
            {
                throw new ArgumentNullException(nameof(model));
            }
            if (string.IsNullOrEmpty(model.email)
              || string.IsNullOrEmpty(model.password))
            {
                return null;
            }
            var user = await _userSV.FindUserAsync(model.email, model.password);
            if (user == null)
            {
                return null;
            }
            return new LoginRespose
            {
                user = user,
                token = Helper.JWT.UseJWT.GenerateJwt(user.id, user.username, _configuration)
            };
        }
    }
}