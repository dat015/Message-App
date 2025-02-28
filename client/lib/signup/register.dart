import 'package:first_app/signup/login.dart';
import 'package:first_app/theme/theme.dart';
import 'package:first_app/widgets/custom_scaffold.dart';
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

  void _handleGenderChange(int? value) { 
  setState(() {
    _genderRadioBtnVal = value ?? -1;
  });
}

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Ngày mặc định là hôm nay
      firstDate: DateTime(1900), // Giới hạn ngày sớm nhất
      lastDate: DateTime.now(), // Giới hạn ngày muộn nhất
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked); // Định dạng ngày
      });
    }
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
                // get started form
                child: Form(
                  key: _formSignupKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // get started text
                      Text(
                        "Tell us about you.",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontSize: 30.0,
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      // full name
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Name';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('Name'),
                          labelStyle: const TextStyle(
                            fontSize: 14,
                          ),
                          hintText: 'Enter Name',
                          hintStyle: const TextStyle(
                            color: Colors.black26,
                            ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      // email
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Email';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('Email'),
                          labelStyle: const TextStyle(
                            fontSize: 14,
                          ),
                          hintText: 'Enter Email',
                          hintStyle: const TextStyle(color: Colors.black26),
                          prefixIcon: const Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      // password
                      TextFormField(
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
                          labelStyle: const TextStyle(
                            fontSize: 14,
                          ),
                          hintText: 'Enter Password',
                          hintStyle: const TextStyle(color: Colors.black26),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText =
                                    !_obscureText; // Đảo ngược trạng thái
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 25.0),

                      TextFormField(
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
                          labelStyle: const TextStyle(
                            fontSize: 14,
                          ),
                          hintText: 'Enter Confirm Password',
                          hintStyle: const TextStyle(color: Colors.black26),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                      ),
                      
                      const SizedBox(height: 25.0),
                      // Trường nhập ngày sinh
                      TextFormField(
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
                      ),

                      const SizedBox(height: 25.0),
                      
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

                      const SizedBox(height: 10.0), // Khoảng cách giữa tiêu đề và Radio
                      
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

                      const SizedBox(height: 25.0),
                      // i agree to the processing
                      Row(
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
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 10,
                            ),
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
                      ),

                      const SizedBox(height: 25.0),
                      // signup button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Kiểm tra form và các điều kiện
                            if (_formSignupKey.currentState!.validate()) {
                              if (_genderRadioBtnVal == -1) {
                                // Nếu chưa chọn giới tính
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select your gender'),
                                  ),
                                );
                              } else if (!agreePersonalData) {
                                // Nếu chưa đồng ý với personal data
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please agree to the processing of personal data',
                                    ),
                                  ),
                                );
                              } else {
                                // Nếu tất cả đều hợp lệ
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Processing Data'),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('CREATE ACCOUNT'),
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      // sign up divider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 0.7,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 10,
                            ),
                            child: Text(
                              'Sign up with',
                              style: TextStyle(color: Colors.black45),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 0.7,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30.0),
                      // sign up social media logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Logo(Logos.facebook_f),
                          Logo(Logos.twitter),
                          Logo(Logos.google),
                          Logo(Logos.apple),
                        ],
                      ),
                      const SizedBox(height: 25.0),
                      // already have an account
                      Row(
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
                                MaterialPageRoute(
                                  builder: (e) => const SignInScreen(),
                                ),
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
                      ),
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
