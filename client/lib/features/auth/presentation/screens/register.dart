import 'package:first_app/features/auth/presentation/screens/login.dart';
import 'package:first_app/theme/theme.dart';
import 'package:first_app/features/auth/presentation/widgets/custom_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formSignupKey = GlobalKey<FormState>();
  bool agreePersonalData = false;
  bool _obscureText = true;
  int _genderRadioBtnVal = -1;
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();

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

  // Hàm tạo trường nhập tên
  Widget _buildNameField() {
    return TextFormField(
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

  // Hàm tạo trường xác nhận mật khẩu
  Widget _buildConfirmPasswordField() {
    return TextFormField(
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
        onPressed: () {
          if (_formSignupKey.currentState!.validate()) {
            if (_genderRadioBtnVal == -1) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select your gender')),
              );
            } else if (!agreePersonalData) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please agree to the processing of personal data',
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Processing Data')));
            }
          }
        },
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
