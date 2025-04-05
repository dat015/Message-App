class User {
  final int id;
  final String username;
  final String password;
  final String passwordSalt;
  final String email;
  final String avatarUrl;
  final DateTime birthday;
  final DateTime createdAt;
  final bool gender;
  final int mutualFriendsCount;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.passwordSalt,
    required this.email,
    required this.avatarUrl,
    required this.birthday,
    required this.createdAt,
    required this.gender,
    this.mutualFriendsCount = 0,
  });

  // Factory method để parse từ JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      password: json['password'] as String,
      passwordSalt: json['passwordSalt'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String, // Có thể null
      birthday: DateTime.parse(json['birthday'] as String), // Dart không có DateOnly, dùng DateTime
      createdAt: DateTime.parse(json['created_at'] as String),
      gender: json['gender'] as bool,
      mutualFriendsCount: json['mutualFriendsCount'] ?? 0,
    );
  }

  // Phương thức chuyển object thành JSON (nếu cần gửi dữ liệu lên server)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'passwordSalt': passwordSalt,
      'email': email,
      'avatar_url': avatarUrl,
      'birthday': birthday.toIso8601String().substring(0, 10), // Chỉ lấy ngày
      'created_at': createdAt.toIso8601String(),
      'gender': gender,
    };
  }

  // Phương thức kiểm tra tính hợp lệ (mô phỏng validation của C#)
  String? validate() {
    if (username.length > 200) {
      return "Username cannot exceed 200 characters.";
    }
    if (username.length < 3) {
      return "Username must be at least 3 characters.";
    }
    if (password.length < 6) {
      return "Password must be at least 6 characters.";
    }
    if (!_isValidEmail(email)) {
      return "Invalid email format.";
    }
    if (avatarUrl != null && !_isValidUrl(avatarUrl!)) {
      return "Invalid URL format.";
    }
    return null; // Hợp lệ
  }

  // Hàm kiểm tra email
  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegExp.hasMatch(email);
  }

  // Hàm kiểm tra URL
  bool _isValidUrl(String url) {
    final urlRegExp = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
    return urlRegExp.hasMatch(url);
  }
}