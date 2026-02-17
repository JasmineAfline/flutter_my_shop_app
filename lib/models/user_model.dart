import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String phoneNumber; // Added for M-Pesa
  final String userImage;
  final Timestamp createdAt;
  final List<dynamic> userCart; 
  final List<dynamic> userWish;
  final String role;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.userImage,
    required this.createdAt,
    required this.userCart,
    required this.userWish,
    required this.role,
  });

  factory UserModel.fromDocument(String uid, Map<String, dynamic> doc) {
    return UserModel(
      uid: uid,
      username: doc['username'] ?? '',
      email: doc['email'] ?? '',
      phoneNumber: doc['phoneNumber'] ?? '',
      role: doc['role'] ?? 'user',
      userImage: doc['userImage'] ?? '',
      createdAt: doc['createdAt'] ?? Timestamp.now(),
      userCart: doc['userCart'] ?? [],
      userWish: doc['userWish'] ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'userImage': userImage,
      'createdAt': createdAt,
      'userCart': userCart,
      'userWish': userWish,
      'role': role,
    };
  }
}