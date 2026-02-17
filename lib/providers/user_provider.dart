import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  bool _isAdmin = false;
  String _displayName = 'Guest';
  bool _isLoading = true;

  // --- GETTERS ---
  User? get getUser => _user;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _isAdmin;
  bool get isRegularUser => _user != null && !_isAdmin;
  bool get isLoading => _isLoading;
  String get username => _displayName;
  String get email => _user?.email ?? 'No Email';
  String get uid => _user?.uid ?? '';

  UserProvider() {
    // Listen to Auth State (Login/Logout)
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _fetchUserData(user.uid);
      } else {
        _displayName = 'Guest';
        _isAdmin = false;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  // Fetch extra details from Firestore (Username and Role)
  Future<void> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _displayName = data['username'] ?? data['name'] ?? _user?.email?.split('@')[0] ?? 'User';
        
        // Checks if 'role' is admin OR 'isAdmin' boolean is true
        _isAdmin = (data['role'] == 'admin') || (data['isAdmin'] == true);
      } else {
        // Fallback if document doesn't exist yet
        _displayName = _user?.email?.split('@')[0] ?? 'User';
        _isAdmin = false;
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
    notifyListeners();
  }

  // Manual Refresh if needed
  Future<void> refreshUser() async {
    if (_user != null) {
      await _fetchUserData(_user!.uid);
    }
  }

  // Clear everything on Logout
  void clearUser() {
    _user = null;
    _isAdmin = false;
    _displayName = 'Guest';
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    clearUser();
  }
}