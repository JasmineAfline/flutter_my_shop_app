import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_shop/models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;

  UserModel? get getUser {
    return _user;
  }

  bool get isLoggedIn {
    return _user != null;
  }

  String get role {
    return _user?.role ?? 'guest';
  }



  Future<void> fetchUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _user = null;
      notifyListeners();
      return;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        _user = UserModel.fromDocument(
          currentUser.uid,
          docSnapshot.data() as Map<String, dynamic>,
        );
      } else {
        _user = UserModel(
          uid: currentUser.uid,
          username: currentUser.displayName ?? '',
          email: currentUser.email ?? '',
          role: 'user', userCart: [], userWish: [], userImage: '', createdAt: Timestamp.now(),
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching user: $e");
      rethrow;
    }
  }


  Future<String?> login(String email, String password) async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // fetch Firestore user after login
    await fetchUser(); 
    return null; 
  } on FirebaseAuthException catch (e) {
    return e.message ?? "Login failed";
  } catch (e) {
    return e.toString();
  }
}
void setUser(UserModel user) {
  _user = user;
  notifyListeners();
}


  void clearUser() {
    _user = null;
    notifyListeners();
  }




  bool get isAdmin => _user?.role == 'admin';
  bool get isRegularUser => _user?.role == 'user';
}