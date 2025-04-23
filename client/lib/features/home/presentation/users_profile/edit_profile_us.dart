import 'package:first_app/PlatformClient/config.dart';
import 'package:first_app/data/models/user_profile.dart';
import 'package:first_app/data/repositories/Chat/User_Profile_repo/us_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile user;
  final Function(UserProfile) onProfileUpdated;
  String get baseUrl => '${Config.baseUrl}api/UserProfile';

  const EditProfilePage({
    Key? key,
    required this.user,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _birthdayController;
  List<String> _selectedInterests = [];
  String? _selectedLocation;
  bool _gender = false;
  final UsProfileRepository _usProfileRepository = UsProfileRepository();

  final List<String> _interestsOptions = [
    'Đọc sách', 'Du lịch', 'Nấu ăn', 'Chơi thể thao', 'Nghe nhạc',
    'Xem phim', 'Vẽ tranh', 'Chụp ảnh', 'Viết lách', 'Học ngoại ngữ',
    'Chơi game', 'Tập yoga', 'Chạy bộ', 'Đạp xe', 'Bơi lội',
    'Cắm trại', 'Leo núi', 'Thiền', 'Làm đồ thủ công', 'Sưu tầm đồ vật',
    'Xem bóng đá', 'Chơi nhạc cụ', 'Tham gia tình nguyện', 'Khám phá công nghệ',
    'Làm vườn', 'Thử món ăn mới', 'Khác',
  ];

  final List<String> _locationOptions = [
    'An Giang', 'Bà Rịa - Vũng Tàu', 'Bắc Giang', 'Bắc Kạn', 'Bạc Liêu',
    'Bắc Ninh', 'Bến Tre', 'Bình Định', 'Bình Dương', 'Bình Phước',
    'Bình Thuận', 'Cà Mau', 'Cần Thơ', 'Cao Bằng', 'Đà Nẵng',
    'Đắk Lắk', 'Đắk Nông', 'Điện Biên', 'Đồng Nai', 'Đồng Tháp',
    'Gia Lai', 'Hà Giang', 'Hà Nam', 'Hà Nội', 'Hà Tĩnh',
    'Hải Dương', 'Hải Phòng', 'Hậu Giang', 'Hòa Bình', 'Hưng Yên',
    'Khánh Hòa', 'Kiên Giang', 'Kon Tum', 'Lai Châu', 'Lâm Đồng',
    'Lạng Sơn', 'Lào Cai', 'Long An', 'Nam Định', 'Nghệ An',
    'Ninh Bình', 'Ninh Thuận', 'Phú Thọ', 'Phú Yên', 'Quảng Bình',
    'Quảng Nam', 'Quảng Ngãi', 'Quảng Ninh', 'Quảng Trị', 'Sóc Trăng',
    'Sơn La', 'Tây Ninh', 'Thái Bình', 'Thái Nguyên', 'Thanh Hóa',
    'Thừa Thiên Huế', 'Tiền Giang', 'TP. Hồ Chí Minh', 'Trà Vinh', 'Tuyên Quang',
    'Vĩnh Long', 'Vĩnh Phúc', 'Yên Bái', 'Khác',
  ];

  // Theme colors
  late Color _primaryColor;
  late Color _secondaryColor;
  late Color _backgroundColor;
  late Color _errorColor;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio);
    _birthdayController = TextEditingController(text: widget.user.birthday);
    _gender = widget.user.gender;

    _selectedInterests = widget.user.interests != null
        ? widget.user.interests!.split(',').where((interest) => _interestsOptions.contains(interest)).toList()
        : [];
    _selectedLocation = widget.user.location != null &&
            _locationOptions.contains(widget.user.location)
        ? widget.user.location
        : _locationOptions.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize theme colors
    _primaryColor = Theme.of(context).primaryColor;
    _secondaryColor = Theme.of(context).colorScheme.secondary;
    _backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    _errorColor = Theme.of(context).colorScheme.error;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? selectedDate = DateTime.tryParse(widget.user.birthday);
    if (selectedDate == null) {
      selectedDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedUser = widget.user.copyWith(
          username: _usernameController.text,
          bio: _bioController.text,
          interests: _selectedInterests.join(','),
          location: _selectedLocation,
          birthday: _birthdayController.text,
          gender: _gender,
        );

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            );
          },
        );

        await _usProfileRepository.updateUserProfile(updatedUser);
        
        // Close loading indicator
        Navigator.pop(context);
        
        widget.onProfileUpdated(updatedUser);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Cập nhật thông tin thành công'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(8),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        // Close loading indicator if open
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Lỗi: $e')),
              ],
            ),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(8),
          ),
        );
      }
    } else {
      // Scroll to first error
      final formState = _formKey.currentState;
      if (formState != null) {
        formState.save();
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: _primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _errorColor),
          ),
          prefixIcon: Icon(icon, color: _primaryColor),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 0),
        ),
        style: TextStyle(fontSize: 16),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _saveProfile,
            icon: Icon(Icons.check, color: Colors.white),
            label: Text(
              'Lưu',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Profile Avatar Section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                
                // Basic Information Section
                _buildSectionHeader('Thông tin cơ bản', Icons.person_outline),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Tên người dùng', 
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập tên người dùng';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _bioController,
                          label: 'Giới thiệu',
                          icon: Icons.info_outline,
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Interests Section
                _buildSectionHeader('Sở thích', Icons.favorite),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hiển thị các sở thích đã chọn dưới dạng chip
                        _selectedInterests.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  child: Text(
                                    'Chưa có sở thích nào được chọn',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              )
                            : Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: _selectedInterests.map((interest) {
                                  return Chip(
                                    label: Text(interest),
                                    deleteIcon: Icon(Icons.close, size: 18),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedInterests.remove(interest);
                                      });
                                    },
                                    backgroundColor: _primaryColor.withOpacity(0.1),
                                    labelStyle: TextStyle(color: _primaryColor),
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: _primaryColor.withOpacity(0.3)),
                                    ),
                                  );
                                }).toList(),
                              ),
                        SizedBox(height: 16),
                        // Nút để mở dialog chọn sở thích
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) {
                                  return MultiSelectDialog(
                                    items: _interestsOptions
                                        .map((interest) => MultiSelectItem<String>(interest, interest))
                                        .toList(),
                                    initialValue: _selectedInterests,
                                    onConfirm: (results) {
                                      setState(() {
                                        _selectedInterests = results.cast<String>();
                                      });
                                    },
                                    title: Text("Chọn sở thích"),
                                    selectedColor: _primaryColor,
                                    searchable: true,
                                    searchHint: "Tìm kiếm sở thích...",
                                    cancelText: Text("Hủy"),
                                    confirmText: Text("Xác nhận"),
                                  );
                                },
                              );
                            },
                            icon: Icon(Icons.add, color: Colors.white,),
                            label: Text('Thêm sở thích'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ),
                        // Validator cho sở thích
                        if (_selectedInterests.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Center(
                              child: Text(
                                'Vui lòng chọn ít nhất một sở thích',
                                style: TextStyle(color: _errorColor, fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Location and Personal Info Section
                _buildSectionHeader('Địa điểm & Thông tin cá nhân', Icons.location_on),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedLocation,
                            decoration: InputDecoration(
                              labelText: 'Nơi sống',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.location_on, color: _primaryColor),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            items: _locationOptions.map((String location) {
                              return DropdownMenuItem<String>(
                                value: location,
                                child: Text(location),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedLocation = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Vui lòng chọn nơi sống';
                              }
                              return null;
                            },
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                            dropdownColor: Colors.white,
                          ),
                        ),
                        _buildTextField(
                          controller: _birthdayController,
                          label: 'Ngày sinh',
                          icon: Icons.cake,
                          readOnly: true,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today, color: _primaryColor),
                            onPressed: () => _selectDate(context),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng chọn ngày sinh';
                            }
                            return null;
                          },
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonFormField<bool>(
                            value: _gender,
                            decoration: InputDecoration(
                              labelText: 'Giới tính',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.person_outline, color: _primaryColor),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: true, 
                                child: Row(
                                  children: [
                                    Icon(Icons.male, color: Colors.blue, size: 20),
                                    SizedBox(width: 8),
                                    Text('Nam'),
                                  ],
                                )
                              ),
                              DropdownMenuItem(
                                value: false, 
                                child: Row(
                                  children: [
                                    Icon(Icons.female, color: Colors.pink, size: 20),
                                    SizedBox(width: 8),
                                    Text('Nữ'),
                                  ],
                                )
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _gender = value!;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Vui lòng chọn giới tính';
                              }
                              return null;
                            },
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                            dropdownColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, color: Colors.white,),
                      SizedBox(width: 8),
                      Text(
                        'Lưu thay đổi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}