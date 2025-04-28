import 'package:flutter/material.dart';
import 'package:first_app/features/home/presentation/setting/change_email_screen.dart';
import 'package:first_app/features/home/presentation/setting/change_password_screen.dart';

class SettingScreen extends StatelessWidget {
  final String email;
  const SettingScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Thay đổi Email'),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangeEmailScreen()),
                ),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Thay đổi Mật khẩu'),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangePasswordScreen(email: email),
                  ),
                ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () {
              // TODO: Thêm logic đăng xuất
            },
          ),
        ],
      ),
    );
  }
}
