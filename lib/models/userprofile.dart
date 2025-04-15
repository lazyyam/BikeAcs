class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phonenum;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phonenum,
  });

  // Default constructor
  factory UserProfile.defaultInstance() {
    return UserProfile(
      uid: '',
      name: '',
      email: '',
      phonenum: '',
    );
  }

  // Factory method to create UserProfile from Firestore document
  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phonenum: data['phone'] ?? '',
    );
  }

  // Method to convert the model back to a map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phonenum,
    };
  }
}
