import 'dart:async';
import 'package:flutter/material.dart';
import 'package:first_app/data/repositories/Setting_Repo/setting_repo.dart';

class NewOtpScreen extends StatefulWidget {
  final String currentEmail;
  final String newEmail;

  const NewOtpScreen({
    super.key,
    required this.currentEmail,
    required this.newEmail,
  });

  @override
  State<NewOtpScreen> createState() => _NewOtpScreenState();
}

class _NewOtpScreenState extends State<NewOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  bool _isLoading = false;
  int _remainingTime = 60;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == 0) {
        setState(() => timer.cancel());
      } else {
        setState(() => _remainingTime--);
      }
    });
  }

  Future<void> _resendOtp() async {
    setState(() {
      _remainingTime = 60;
      _startTimer();
    });
    try {
      await SettingRepo().sendOtp(widget.currentEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP đã được gửi lại')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập OTP 6 chữ số')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SettingRepo().verifyOtp(widget.currentEmail, otp);
      await SettingRepo().changeEmail(widget.currentEmail, widget.newEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi email thành công')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác minh OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Nhập mã OTP được gửi đến email của bạn',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _otpControllers[index],
                    autofocus: index == 0,
                    onChanged: (value) {
                      if (value.length == 1 && index < 5) {
                        FocusScope.of(context).nextFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        FocusScope.of(context).previousFocus();
                      }
                    },
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counter: const Offstage(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Xác minh OTP'),
            ),
            const SizedBox(height: 16),
            _remainingTime > 0
                ? Text('Gửi lại OTP sau $_remainingTime giây')
                : TextButton(
                    onPressed: _resendOtp,
                    child: const Text('Gửi lại OTP'),
                  ),
          ],
        ),
      ),
    );
  }
}