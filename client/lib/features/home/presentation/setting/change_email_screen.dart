import 'package:first_app/features/home/presentation/setting/otp_changeEmail_screen.dart';
import 'package:flutter/material.dart';
import 'package:first_app/data/repositories/Setting_Repo/setting_repo.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _currentEmailController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  bool _isLoading = false;

  void _sendOtpAndNavigate() async {
    final currentEmail = _currentEmailController.text.trim();
    final newEmail = _emailController.text.trim();
    final confirmEmail = _confirmEmailController.text.trim();

    if (currentEmail.isEmpty || !currentEmail.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email hiện tại hợp lệ')),
      );
      return;
    }
    if (newEmail.isEmpty || !newEmail.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email mới hợp lệ')),
      );
      return;
    }
    if (newEmail != confirmEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email xác nhận không khớp')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SettingRepo().sendOtp(currentEmail);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewOtpScreen(
            currentEmail: currentEmail,
            newEmail: newEmail,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentEmailController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thay đổi Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _currentEmailController,
              decoration: const InputDecoration(
                labelText: 'Email hiện tại',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email mới',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmEmailController,
              decoration: const InputDecoration(
                labelText: 'Xác nhận Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendOtpAndNavigate,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Gửi OTP'),
            ),
          ],
        ),
      ),
    );
  }
}