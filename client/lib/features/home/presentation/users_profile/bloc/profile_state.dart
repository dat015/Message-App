import 'package:first_app/data/models/user_profile.dart';

abstract class OtherProfileState {}

class OtherProfileLoading extends OtherProfileState {}

class OtherProfileLoaded extends OtherProfileState {
  final UserProfile profile;
  final String friendStatus;
  OtherProfileLoaded(this.profile, this.friendStatus);
}

class OtherProfileError extends OtherProfileState {
  final String message;
  OtherProfileError(this.message);
}