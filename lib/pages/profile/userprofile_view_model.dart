import 'package:BikeAcs/pages/profile/userprofile.dart';
import 'package:BikeAcs/services/user_database.dart';

class UserProfileViewModel {
  final UserDatabase _userDatabase;

  UserProfileViewModel(String uid) : _userDatabase = UserDatabase(uid: uid);

  Future<UserProfile?> fetchUserProfile() async {
    try {
      return await _userDatabase.getUserProfile(_userDatabase.uid);
    } catch (e) {
      throw Exception("Failed to fetch user profile: $e");
    }
  }

  Future<void> updateUserProfile(
      String name, String email, String phonenum) async {
    try {
      await _userDatabase.updateUserData(name, email, phonenum);
    } catch (e) {
      throw Exception("Failed to update user profile: $e");
    }
  }

  Stream<UserProfile?> getUserProfileStream() {
    return _userDatabase.useraccount;
  }
}
