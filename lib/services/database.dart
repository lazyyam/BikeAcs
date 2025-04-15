import 'package:BikeAcs/models/userprofile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  late final String uid;
  DatabaseService({required this.uid});
  DatabaseService.noParams();
  final CollectionReference User =
      FirebaseFirestore.instance.collection('User');

  Future setUserData(
      String uid, String name, String email, String phonenum) async {
    return await User.doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'phonenum': phonenum,
    });
  }

  Future updateUserData(String name, String email, String phonenum) async {
    return await User.doc(uid).update({
      'uid': uid,
      'name': name,
      'email': email,
      'phonenum': phonenum,
    });
  }

  Future<String?> getUserName(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          (await User.doc(uid).get()) as DocumentSnapshot<Map<String, dynamic>>;

      if (userDoc.exists) {
        return userDoc.data()?['name'];
      } else {
        return null; // User not found
      }
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

// Convert a single document snapshot to a UserProfile
  UserProfile _userProfileFromSnapshot(DocumentSnapshot snapshot) {
    var userData = snapshot.data() as Map<String, dynamic>;
    return UserProfile(
        uid: userData['uid'] ?? '',
        name: userData['name'] ?? '',
        email: userData['email'] ?? '',
        phonenum: userData['phonenum'] ?? '');
  }

  // get streams
  Stream<UserProfile> get useraccount {
    return User.doc(uid).snapshots().map(_userProfileFromSnapshot);
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot<Object?> snapshot = await User.doc(uid).get();
      return _userProfileFromSnapshot(snapshot);
    } catch (e) {
      // Handle errors here
      print("Error fetching user profile: $e");
      return null; // You might want to return a default or empty profile in case of an error
    }
  }

  String _getNameFromSnapshot(DocumentSnapshot snapshot) {
    var userData = snapshot.data() as Map<String, dynamic>;
    return userData['name'] ?? '';
  }
}
