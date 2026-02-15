import 'package:flutter/material.dart';
import 'package:my_shop/providers/user_provider.dart';

/// Centralized route guard utility for protecting routes based on auth and role
class RouteGuard {
  /// Check if user is logged in (not a guest and not anonymous)
  static bool isLoggedIn(UserProvider userProvider) {
    return userProvider.isLoggedIn && userProvider.getUser != null;
  }

  /// Check if user is admin
  static bool isAdmin(UserProvider userProvider) {
    return userProvider.isAdmin;
  }

  /// Check if user is regular user (not admin, not guest)
  static bool isUser(UserProvider userProvider) {
    return userProvider.isRegularUser;
  }

  /// Check if user is guest
  static bool isGuest(UserProvider userProvider) {
    return !userProvider.isLoggedIn;
  }

  /// Build an unauthorized screen
  static Widget buildUnauthorizedScreen(String title, String message) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 72, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Unauthorized',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                message,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
