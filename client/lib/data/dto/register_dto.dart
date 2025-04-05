class RegisterDTO {
  String? username;
  String? password;
  String? email;
  String? avatarUrl;
  DateTime? birthday;
  bool? gender;

  RegisterDTO({
    this.username,
    this.password,
    this.email,
    this.avatarUrl,
    this.birthday,
    this.gender,
  });

  // Validation cho password
  void validatePassword() {
    if (password == null || password!.isEmpty) {
      throw Exception('Mật khẩu không được để trống.');
    }
    if (password!.length < 8) {
      throw Exception('Mật khẩu phải có ít nhất 8 ký tự.');
    }
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    if (!regex.hasMatch(password!)) {
      throw Exception(
          'Mật khẩu phải có ít nhất một chữ hoa, một chữ thường, một số và một ký tự đặc biệt.');
    }
  }

  // Chuyển từ JSON sang UserDTO
  factory RegisterDTO.fromJson(Map<String, dynamic> json) {
    return RegisterDTO(
      username: json['username'] as String?,
      password: json['password'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      birthday: json['birthday'] != null
          ? DateTime.parse(json['birthday'] as String)
          : null,
      gender: json['gender'] as bool?,
    );
  }

  // Chuyển từ UserDTO sang JSON
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'avatar_url': avatarUrl,
      'birthday': birthday?.toIso8601String().split('T')[0],
      'gender': gender,
    };
  }
}