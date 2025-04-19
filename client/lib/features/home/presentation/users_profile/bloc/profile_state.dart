import 'package:first_app/data/models/user.dart';
import 'package:first_app/data/models/user_profile.dart';

abstract class OtherProfileState {}

class OtherProfileLoading extends OtherProfileState {}

class OtherProfileLoaded extends OtherProfileState {
  final UserProfile profile;
  final String friendStatus;
  final List<User> friends;
  
  OtherProfileLoaded({
    required this.profile,
    required this.friendStatus,
    required this.friends,
  });

  @override
  List<Object?> get props => [profile, friendStatus, friends];
}

class OtherProfileError extends OtherProfileState {
  final String message;
  OtherProfileError(this.message);
}