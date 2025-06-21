// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously

import 'package:BikeAcs/appUsers/users.dart';
import 'package:BikeAcs/constants/warningalert.dart';
import 'package:BikeAcs/pages/profile/userprofile_model.dart';
import 'package:BikeAcs/services/user_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/warningalert2.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch UserProfile based on the current user's UID
  Stream<UserProfile> getUserProfile(String uid) {
    print("Fetching profile for $uid");
    return FirebaseFirestore.instance
        .collection('User')
        .doc(uid)
        .snapshots()
        .map((doc) => UserProfile.fromFirestore(doc.data()!));
  }

  // create user object based on firebaseuser
  AppUsers? _userFromFirebaseUser(User? user) {
    return user != null ? AppUsers(uid: user.uid) : null;
  }

  // auth change user stream
  Stream<AppUsers?> get userStream {
    return _auth
        .authStateChanges()
        .map((User? user) => _userFromFirebaseUser(user!));
  }

  // sign in anon
  Future signInAnon() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? users = result.user;

      return _userFromFirebaseUser(users!);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // sign in with email & password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? users = result.user;
      return _userFromFirebaseUser(users!);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // register with email & password
  Future registerWithEmailAndPassword(
      String email, String password, String name, BuildContext context) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? users = result.user;

      if (users != null) {
        // Create a new document for the new user with the UID
        await UserDatabase(uid: users.uid)
            .setUserData(users.uid, name, email, '');
        return _userFromFirebaseUser(users);
      } else {
        throw FirebaseAuthException(
            code: 'USER_CREATION_FAILED', message: 'User creation failed');
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        showDialog(
          context: context, // Make sure to have access to the current context
          builder: (BuildContext context) {
            return WarningAlert(title: 'Error', subtitle: '${e.message}');
          },
        );
      }
      return null;
    }
  }

  Future<void> resetPassword(String email, BuildContext context) async {
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return WarningAlert2(
            title: 'Invalid Email',
            subtitle: 'Please enter a valid email address.',
          );
        },
      );
      return;
    }

    try {
      // // Check if the email is registered
      // final List<String> signInMethods =
      //     await _auth.fetchSignInMethodsForEmail(email);
      // if (signInMethods.isEmpty) {
      //   showDialog(
      //     context: context,
      //     builder: (BuildContext context) {
      //       return WarningAlert2(
      //         title: 'Error',
      //         subtitle: 'This email is not registered.',
      //       );
      //     },
      //   );
      //   return;
      // }

      // Send the reset password email
      await _auth.sendPasswordResetEmail(email: email);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return WarningAlert2(
            title: 'Success',
            subtitle: 'Password reset email sent successfully.',
          );
        },
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return WarningAlert2(
              title: 'Error',
              subtitle: e.message ??
                  'An error occurred while sending the reset email.',
            );
          },
        );
      }
    }
  }

  // sign out
  Future signOut(BuildContext context) async {
    try {
      await _auth.signOut();

      // Clear all Firestore listeners
      Provider.debugCheckInvalidValueType = null;
    } catch (e) {
      if (e is FirebaseAuthException) {
        showDialog(
          context: context, // Make sure to have access to the current context
          builder: (BuildContext context) {
            return WarningAlert(title: 'Error', subtitle: '${e.message}');
          },
        );
      }
    }
  }

  Future<void> deleteUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;

    // Define a list of collection names associated with the user
    List<String> collectionNames = ['user', 'payments'];

    // Iterate through the collections and delete documents by UID
    for (String collectionName in collectionNames) {
      await firestore.collection(collectionName).doc(uid).delete();
    }
  }

  Future deleteUserAccount(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await deleteUserData(user.uid); // Delete Firestore data first
        await user.delete(); // Delete the Authentication account
        Navigator.pop(context);
        showDialog(
          context: context, // Make sure to have access to the current context
          builder: (BuildContext context) {
            return WarningAlert(
              title: 'Deleted',
              subtitle: 'The account has been deleted',
            );
          },
        );
        return await FirebaseAuth.instance.signOut();
      } catch (e) {
        Navigator.pop(context);
        showDialog(
          context: context, // Make sure to have access to the current context
          builder: (BuildContext context) {
            return WarningAlert(
              title: 'Error',
              subtitle: e.toString(),
            );
          },
        );
        print("Error deleting user account: $e");
      }
    }
  }
}
