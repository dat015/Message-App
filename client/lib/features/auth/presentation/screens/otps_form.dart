import 'dart:async';
import 'package:first_app/core/utils/auth_utils.dart';
import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/repositories/Auth/auth_repository.dart';
import 'package:first_app/data/repositories/Auth/auth_repository_implement.dart';
import 'package:first_app/features/auth/presentation/screens/change_password.dart';
import 'package:first_app/features/auth/presentation/screens/forget_password.dart';
import 'package:first_app/theme/theme.dart';
import 'package:flutter/material.dart';

class Otp extends StatefulWidget {
  final String email;
  Otp({super.key, required this.email});
  @override
  _OtpState createState() => _OtpState();
}

class _OtpState extends State<Otp> {
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
    super.dispose();
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_remainingTime == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _remainingTime--;
          });
        }
      },
    );
  }

  Future<void> _resendOTP() async {
    setState(() {
      _remainingTime = 60; 
      _startTimer();
    });
    await sendOTPToServer(context, widget.email, navigate: false);
  }

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());

  Future<void> _verifyOTP(BuildContext context) async {
  final AuthRepository _authRepository =
      AuthRepositoryImpl(ApiClient());
  String otp = _otpControllers.map((controller) => controller.text).join();

  if (otp.length != 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
    );
    return;
  }

  try {
    final otpResponse = await _authRepository.verifyOtp(widget.email, otp);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP verified successfully!')),
    );
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChangePassword(email: widget.email,)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to verify OTP: $e')),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xfff7f6fb),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildBackButton(context),
                  const SizedBox(height: 16),
                  _buildOtpIllustration(context),
                  const SizedBox(height: 16),
                  _buildVerificationHeader(),
                  const SizedBox(height: 16),
                  _buildOtpInputFields(),
                  const SizedBox(height: 16),
                  _buildResendOtpSection(),
                  const SizedBox(height: 10),
                  _buildChangeEmailButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget nút quay lại
  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(
          Icons.arrow_back,
          size: 32,
          color: Colors.black54,
        ),
      ),
    );
  }

  // Widget hình ảnh OTP
  Widget _buildOtpIllustration(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth * 0.5,
      height: screenWidth * 0.5,
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        shape: BoxShape.circle,
      ),
      child: Image.asset(
        '../assets/images/illustration-3.png',
        fit: BoxFit.contain,
      ),
    );
  }

  // Widget tiêu đề xác thực
  Widget _buildVerificationHeader() {
    return const Column(
      children: [
        Text(
          'VERIFICATION',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Colors.blue,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Enter your OTP code number",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black38,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOtpInputFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              6,
              (index) => _buildOtpTextField(
                controller: _otpControllers[index],
                first: index == 0,
                last: index == 5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildVerifyButton(),
        ],
      ),
    );
  }

  Widget _buildOtpTextField({
    required TextEditingController controller,
    required bool first,
    required bool last,
  }) {
    return SizedBox(
      width: 40,
      child: TextField(
        controller: controller,
        autofocus: first,
        onChanged: (value) {
          if (value.length == 1 && !last) {
            FocusScope.of(context).nextFocus();
          }
          if (value.isEmpty && !first) {
            FocusScope.of(context).previousFocus();
          }
        },
        showCursor: false,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counter: const Offstage(),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 2, color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 2, color: Colors.purple),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // Widget nút xác nhận OTP
  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _verifyOTP(context),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: lightColorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(14),
        ),
        child: const Text(
          'Verify',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // Widget phần Resend OTP
  Widget _buildResendOtpSection() {
    return Column(
      children: [
        const Text(
          "Didn't you receive any code?",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black38,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        _remainingTime > 0
            ? Text(
                'Resend OTP in $_remainingTime seconds',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              )
            : GestureDetector(
                onTap: _resendOTP,
                child: Text(
                  'Resend New Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: lightColorScheme.primary,
                  ),
                ),
              ),
      ],
    );
  }

  // Widget nút thay đổi email
  Widget _buildChangeEmailButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (e) => const ForgetPassword()),
        );
      },
      child: Text(
        'Change email?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: lightColorScheme.primary,
        ),
      ),
    );
  }
}