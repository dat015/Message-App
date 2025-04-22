import 'package:first_app/data/dto/MemberDTO.dart';
import 'package:first_app/data/repositories/User_Repo/user_repo.dart';
import 'package:flutter/material.dart';

class MemberProvider with ChangeNotifier {
  final UserRepo _userRepo = UserRepo();

  List<MemberDTO> _member = [];

  Future<void> FetchMemberByConversation(int conversation_id) async {
    try {
      var response = await _userRepo.GetAllMember(conversation_id);
      if (response == null || response.isEmpty) {
        print('No members found for conversation_id: $conversation_id');
        _member = []; // Xóa danh sách cũ nếu không có dữ liệu
        return;
      }

      _member = response;
      print(
        'Fetched ${_member.length} members: ${_member.map((m) => m.id).toList()}',
      );
    } catch (e) {
      print('Error fetching members: $e');
      _member = []; // Xóa danh sách nếu có lỗi
    }
  }
}
