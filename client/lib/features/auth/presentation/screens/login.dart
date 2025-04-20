import 'package:first_app/data/dto/login_response.dart';
import 'package:first_app/data/storage/storage_service.dart';
import 'package:first_app/features/auth/presentation/screens/forget_password.dart';
import 'package:first_app/features/auth/presentation/screens/register.dart';
import 'package:first_app/features/auth/presentation/widgets/custom_scaffold.dart';
import 'package:first_app/features/home/presentation/screens/home_screen/home_screen.dart';
import 'package:first_app/features/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/Auth/auth_repository.dart';
import '../../../../data/repositories/Auth/auth_repository_implement.dart';
import '../../../../theme/theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignInScreen> {
  final _formSignInKey = GlobalKey<FormState>();
  bool rememberPassword = false;
  bool _obscureText = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Hàm tạo tiêu đề
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Log In.",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            fontSize: 45.0,
          ),
        ),
        Text(
          "We missed you!",
          style: TextStyle(
            color: Colors.blue,
            fontSize: 18.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 40.0),
      ],
    );
  }
  
  Future<void> sendDataLogin() async {
    if (_formSignInKey.currentState!.validate()) {
      String email = _emailController.text;
      String password = _passwordController.text;

      final apiClient = ApiClient();
      final _authRepository = AuthRepositoryImpl(apiClient);

      try {
        final response = await _authRepository.login(email, password);

        final userData = {
          "user":
              response.user?.toJson(), // Giả sử user có phương thức `toJson()`
          "token": response.token,
        };
        var user_response = LoginResponse(
          user: response.user,
          token: response.token,
        );

        // 🌟 Lưu vào storage (Web + Mobile)
        await StorageService.saveUserData("user_data", userData);

        // 🔄 Chuyển hướng đến HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(user: user_response)),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    }
  }

  // Hàm tạo trường nhập email
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter Email';
        }
        return null;
      },
      decoration: InputDecoration(
        label: const Text('Email'),
        labelStyle: const TextStyle(fontSize: 14),
        hintText: 'Enter Email',
        hintStyle: const TextStyle(color: Colors.black26),
        prefixIcon: const Icon(Icons.email),
      ),
    );
  }

  // Hàm tạo trường nhập mật khẩu
  Widget _buildPasswordField() {
    return TextFormField(
      obscureText: _obscureText,
      controller: _passwordController,
      obscuringCharacter: '*',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter Password';
        }
        return null;
      },
      decoration: InputDecoration(
        label: const Text('Password'),
        labelStyle: const TextStyle(fontSize: 14),
        hintText: 'Enter Password',
        hintStyle: const TextStyle(color: Colors.black26),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
    );
  }

  // Hàm tạo phần "Remember me" và "Forget password"
  Widget _buildOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: rememberPassword,
              onChanged: (bool? value) {
                setState(() {
                  rememberPassword = value!;
                });
              },
              activeColor: lightColorScheme.primary,
            ),
            const Text('Remember me', style: TextStyle(color: Colors.black45)),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (e) => const ForgetPassword()),
            );
          },
          child: Text(
            'Forget password?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: lightColorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // Hàm tạo nút "Sign In"
  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_formSignInKey.currentState!.validate()) {
            sendDataLogin();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please agree to the processing of personal data',
                ),
              ),
            );
          }
        },
        child: const Text('SIGN IN'),
      ),
    );
  }

  // Hàm tạo phần phân cách "Sign up with"
  Widget _buildDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Divider(thickness: 0.7, color: Colors.grey.withOpacity(0.5)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
          child: Text('Sign up with', style: TextStyle(color: Colors.black45)),
        ),
        Expanded(
          child: Divider(thickness: 0.7, color: Colors.grey.withOpacity(0.5)),
        ),
      ],
    );
  }

  // Hàm tạo các biểu tượng mạng xã hội
  Widget _buildSocialIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Logo(Logos.facebook_f),
        Logo(Logos.twitter),
        Logo(Logos.google),
        Logo(Logos.apple),
      ],
    );
  }

  // Hàm tạo phần "Don't have an account?"
  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Don\'t have an account? ',
          style: TextStyle(color: Colors.black45),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (e) => const SignUpScreen()),
            );
          },
          child: Text(
            'Sign up',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: lightColorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          const Expanded(flex: 1, child: SizedBox(height: 10)),
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignInKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildEmailField(),
                      const SizedBox(height: 25.0),
                      _buildPasswordField(),
                      const SizedBox(height: 25.0),
                      _buildOptionsRow(),
                      const SizedBox(height: 25.0),
                      _buildSignInButton(),
                      const SizedBox(height: 25.0),
                      _buildDivider(),
                      const SizedBox(height: 25.0),
                      _buildSocialIcons(),
                      const SizedBox(height: 25.0),
                      _buildSignUpLink(),
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
