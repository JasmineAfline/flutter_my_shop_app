import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.login),
        label: const Text('Continue with Google'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => _signInWithGoogle(context),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      // Create GoogleAuthProvider
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Add scope
      googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
      
      // Sign in
      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithPopup(googleProvider);
      
      final User? user = userCredential.user;
      
      if (user != null && context.mounted) {
        Navigator.pushReplacementNamed(context, '/root');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in with Google: $e')),
        );
      }
    }
  }
}
