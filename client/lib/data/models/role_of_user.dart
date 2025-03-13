import 'package:flutter/foundation.dart';

class RoleOfUser {
  final int id;
  final int userId;
  final int roleId;

  RoleOfUser({
    required this.id,
    required this.userId,
    required this.roleId,
  });

  factory RoleOfUser.fromJson(Map<String, dynamic> json) {
    return RoleOfUser(
      id: json['id'],
      userId: json['user_id'],
      roleId: json['role_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'role_id': roleId,
    };
  }
}
