import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/features/auth/presentation/widgets/custom_scaffold.dart';
import 'package:flutter/material.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/Auth/auth_repository.dart';
import '../../../../data/repositories/Auth/auth_repository_implement.dart';

class ChangePassword extends StatefulWidget {
  final String email;

  const ChangePassword({super.key, required this.email});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _formChangePasswordKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool _obscureNewPassword = true;

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Change Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            fontSize: 36.0,
          ),
        ),
        const Text(
          "Set your new password!",
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

  Future<void> _changePassword() async {
    if (_formChangePasswordKey.currentState!.validate()) {
      String newPassword = _newPasswordController.text;
      String confirmPassword = _confirmPasswordController.text;

      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu không khớp!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final AuthRepository authRepository = AuthRepositoryImpl(ApiClient());

      try {
        await authRepository.changePassword(widget.email, newPassword);

        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        throw Exception('Tải hồ sơ người dùng thất bại: $e');
      }
    }
  }

  Widget _buildNewPasswordField() {
    return TextFormField(
      controller: _newPasswordController,
      obscureText: _obscureNewPassword,
      obscuringCharacter: '*',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter Password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        if (!RegExp(r'^[A-Z]').hasMatch(value)) {
          return 'Password must start with an uppercase letter';
        }
        if (!RegExp(r'[0-9]').hasMatch(value)) {
          return 'Password must contain at least one digit';
        }
        if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
          return 'Password must contain at least one special character';
        }
        return null;
      },
      decoration: InputDecoration(
        label: const Text('New Password'),
        labelStyle: const TextStyle(fontSize: 14),
        hintText: 'Enter new password',
        hintStyle: const TextStyle(color: Colors.black26),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureNewPassword = !_obscureNewPassword;
            });
          },
        ),
      ),
    );
  }

  // Trường xác nhận mật khẩu
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureText,
      obscuringCharacter: '*',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        return null;
      },
      decoration: InputDecoration(
        label: const Text('Confirm Password'),
        labelStyle: const TextStyle(fontSize: 14),
        hintText: 'Confirm your password',
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

  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _changePassword,
        child: const Text('CHANGE PASSWORD'),
      ),
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
                  key: _formChangePasswordKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildNewPasswordField(),
                      const SizedBox(height: 25.0),
                      _buildConfirmPasswordField(),
                      const SizedBox(height: 25.0),
                      _buildChangePasswordButton(),
                      const SizedBox(height: 25.0),
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
