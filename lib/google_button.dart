import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_shop/models/user_model.dart';
import 'package:my_shop/providers/user_provider.dart';
import 'package:my_shop/root_screen.dart';
import 'package:my_shop/screens/admin/admin_dashboard.dart';
import 'package:my_shop/utils/app_functions.dart';
import 'package:provider/provider.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key});

  Future<void> _googleSignIn({required BuildContext context}) async {
    try {
      UserCredential authResults;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');

        authResults = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final googleProvider = GoogleAuthProvider();
        authResults = await FirebaseAuth.instance.signInWithProvider(googleProvider);
      }

      final isNewUser = authResults.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        final user = authResults.user!;
        final newUser = UserModel(
          uid: user.uid,
          username: user.displayName ?? '',
          email: user.email ?? '',
          userImage: user.photoURL ?? '',
          createdAt: Timestamp.now(),
          userWish: [],
          userCart: [],
          role: 'user',
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchUser();

      if (context.mounted) {
        if (userProvider.isAdmin) {
          Navigator.pushReplacementNamed(context, AdminDashboard.routeName);
        } else {
          Navigator.pushReplacementNamed(context, RootScreen.routeName);
        }
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'popup-closed-by-user') return;
      if (!context.mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.message ?? error.code,
        fct: () {},
      );
    } catch (error) {
      if (!context.mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Ionicons.logo_google, color: Colors.red, size: 24),
        label: const Text(
          "Continue with Google",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: () async => await _googleSignIn(context: context),
      ),
    );
  }
}
