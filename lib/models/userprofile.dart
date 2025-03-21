class UserProfile{
  final String uid;
  final String name;
  final String email;
  final String phonenum;
  final String address;

  UserProfile({ required this.uid, required this.name, required this.email, required this.phonenum,required this.address});
  factory UserProfile.defaultInstance() {
    return UserProfile(uid: '', name: '', email: '', phonenum: '', address: '');
  }
}