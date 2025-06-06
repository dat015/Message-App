import 'dart:convert';
import 'dart:io';

import 'package:first_app/core/utils/auth_utils.dart';
import 'package:first_app/data/dto/register_dto.dart';
import 'package:first_app/features/auth/presentation/screens/login.dart';
import 'package:first_app/features/auth/presentation/screens/otps_form.dart';
import 'package:first_app/theme/theme.dart';
import 'package:first_app/features/auth/presentation/widgets/custom_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:first_app/data/api/api_client.dart';
import '../../../../data/repositories/Auth/auth_repository.dart';
import '../../../../data/repositories/Auth/auth_repository_implement.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formSignupKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dateController = TextEditingController();

  bool agreePersonalData = false;
  bool _obscureText = true;
  int _genderRadioBtnVal = -1;
  DateTime? _selectedDate;
  File? _avatarImage;
  final ImagePicker _picker = ImagePicker();

  // Khởi tạo ApiClient và AuthRepository
  final ApiClient apiClient = ApiClient();
  late final AuthRepository
  _authRepository; // Sử dụng 'late' để trì hoãn khởi tạo

  _SignUpScreenState() {
    _authRepository = AuthRepositoryImpl(
      apiClient,
    ); // Khởi tạo trong constructor
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Giảm chất lượng để tối ưu kích thước
      );
      if (pickedFile != null) {
        setState(() {
          _avatarImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi chọn ảnh: $e')));
    }
  }

  // Hàm xử lý thay đổi giới tính
  void _handleGenderChange(int? value) {
    setState(() {
      _genderRadioBtnVal = value ?? -1;
    });
  }

  // Hàm chọn ngày sinh
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Hàm gửi dữ liệu đăng ký
  Future<void> sendDataRegister() async {
    if (_formSignupKey.currentState!.validate()) {
      // Check if avatar image is selected
      if (_avatarImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ảnh đại diện'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu không khớp'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_genderRadioBtnVal == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn giới tính'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!agreePersonalData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đồng ý với việc xử lý dữ liệu cá nhân'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final registerDTO = RegisterDTO(
        username: _nameController.text,
        password: _passwordController.text,
        email: _emailController.text,
        avatarUrl: base64Encode(await _avatarImage!.readAsBytes()),
        birthday: _selectedDate,
        gender: _genderRadioBtnVal == 0,
      );
      debugPrint('RegisterDTO: ${jsonEncode(registerDTO.toJson())}');

      try {
        await sendOTPToServer(
          context,
          _emailController.text,
          isForRegistration: true,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => Otp(
                  email: _emailController.text,
                  registerDTO: registerDTO,
                  isForRegistration: true,
                ),
          ),
        );
      } catch (e) {
        throw Exception('Đăng ký người dùng thất bại: $e');
      }
    }
  }

  // Hàm tạo tiêu đề
  Widget _buildHeader() {
    return Text(
      "Tell us about you.",
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.black,
        fontSize: 30.0,
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [lightColorScheme.primary, lightColorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundImage:
                  _avatarImage != null
                      ? FileImage(_avatarImage!) // Sử dụng FileImage cho ảnh
                      : null,
              child:
                  _avatarImage == null
                      ? Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 24,
                  color: lightColorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm tạo trường nhập tên
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter Name';
        }
        return null;
      },
      decoration: InputDecoration(
        label: const Text('Name'),
        labelStyle: const TextStyle(fontSize: 14),
        hintText: 'Enter Name',
        hintStyle: const TextStyle(color: Colors.black26),
        prefixIcon: const Icon(Icons.person),
      ),
    );
  }

  // Hàm tạo trường nhập email
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter Email';
        }
        // Email format validation using regex
        if (!RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        ).hasMatch(value)) {
          return 'Please enter a valid email address';
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
      controller: _passwordController,
      obscureText: _obscureText,
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

  // Hàm tạo trường xác nhận mật khẩu
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureText,
      obscuringCharacter: '*',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter Confirm Password';
        }
        return null;
      },
      decoration: InputDecoration(
        label: const Text('Confirm Password'),
        labelStyle: const TextStyle(fontSize: 14),
        hintText: 'Enter Confirm Password',
        hintStyle: const TextStyle(color: Colors.black26),
        prefixIcon: const Icon(Icons.lock),
      ),
    );
  }

  // Hàm tạo trường ngày sinh
  Widget _buildDateOfBirthField() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter Date of Birth';
        }
        // Parse the date from DD/MM/YYYY format
        try {
          final parts = value.split('/');
          if (parts.length != 3) {
            return 'Invalid date format. Use DD/MM/YYYY';
          }
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final dob = DateTime(year, month, day);
          final today = DateTime.now();
          // Calculate age
          int age = today.year - dob.year;
          if (today.month < dob.month ||
              (today.month == dob.month && today.day < dob.day)) {
            age--;
          }
          if (age < 18) {
            return 'You must be at least 18 years old';
          }
        } catch (e) {
          return 'Invalid date format';
        }
        return null;
      },
      decoration: InputDecoration(
        label: const Text('Date of Birth'),
        labelStyle: const TextStyle(fontSize: 14),
        hintText: 'DD/MM/YYYY',
        hintStyle: const TextStyle(color: Colors.black26),
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: () => _selectDate(context),
        ),
      ),
      onTap: () => _selectDate(context),
    );
  }

  // Hàm tạo phần chọn giới tính
  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Gender',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 10.0),
        Row(
          children: <Widget>[
            Radio(
              value: 0,
              groupValue: _genderRadioBtnVal,
              onChanged: _handleGenderChange,
            ),
            const Text("Male"),
            Radio(
              value: 1,
              groupValue: _genderRadioBtnVal,
              onChanged: _handleGenderChange,
            ),
            const Text("Female"),
          ],
        ),
      ],
    );
  }

  // Hàm tạo phần đồng ý dữ liệu cá nhân
  Widget _buildPersonalDataCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: agreePersonalData,
          onChanged: (bool? value) {
            setState(() {
              agreePersonalData = value!;
            });
          },
          activeColor: lightColorScheme.primary,
        ),
        const Text(
          'I agree to the processing of ',
          style: TextStyle(color: Colors.black45, fontSize: 10),
        ),
        Text(
          'Personal data',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: lightColorScheme.primary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // Hàm tạo nút "Create Account"
  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: sendDataRegister,
        child: const Text('CREATE ACCOUNT'),
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

  // Hàm tạo liên kết "Already have an account?"
  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: Colors.black45),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (e) => const SignInScreen()),
            );
          },
          child: Text(
            'Sign in',
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
                  key: _formSignupKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatarPicker(),
                      const SizedBox(height: 20.0),
                      _buildHeader(),
                      const SizedBox(height: 40.0),
                      _buildNameField(),
                      const SizedBox(height: 25.0),
                      _buildEmailField(),
                      const SizedBox(height: 25.0),
                      _buildPasswordField(),
                      const SizedBox(height: 25.0),
                      _buildConfirmPasswordField(),
                      const SizedBox(height: 25.0),
                      _buildDateOfBirthField(),
                      const SizedBox(height: 25.0),
                      _buildGenderSection(),
                      const SizedBox(height: 25.0),
                      _buildPersonalDataCheckbox(),
                      const SizedBox(height: 25.0),
                      _buildCreateAccountButton(),
                      const SizedBox(height: 30.0),
                      _buildDivider(),
                      const SizedBox(height: 30.0),
                      _buildSocialIcons(),
                      const SizedBox(height: 25.0),
                      _buildSignInLink(),
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
