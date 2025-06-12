import 'package:first_app/data/api/api_client.dart';
import 'package:first_app/data/dto/group_setting_dto.dart';

class GroupSettingRepo {
  ApiClient _apiClient = ApiClient();

  Future<String> updateGroupSetting(
    int id,
    int conversationId,
    int createBy,
    allowMemberInvite,
    allowMemberEdit,
    allowMemberRemove,
  ) async {
    var response = await _apiClient.put(
      '/api/GroupSetting/update',
      data: {
        'id': id,
        'conversationId': conversationId,
        'createdBy': createBy,
        'allowMemberInvite': allowMemberInvite,
        'allowMemberEdit': allowMemberEdit,
        'allowMemberRemove': allowMemberRemove,
      },
    );
      return response['message'];
   
  }

  Future<String> createGroupSetting(
    int conversationId,
    int createBy,
    allowMemberInvite,
    allowMemberEdit,
    allowMemberRemove,
  ) async {
    var response = await _apiClient.post(
      '/api/GroupSetting/create',
      data: {
        'conversationId': conversationId,
        'createdBy': createBy,
        'allowMemberInvite': allowMemberInvite,
        'allowMemberEdit': allowMemberEdit,
        'allowMemberRemove': allowMemberRemove,
      },
    );
    
      return response['message'];

  }

  Future<GroupSettingDTO> getGroupSetting(int id) async {
    var response = await _apiClient.get('/api/GroupSetting/get/$id');
    return GroupSettingDTO.fromJson(response['data']);
  }
}
