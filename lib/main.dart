import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:my_shop/constants/theme_data.dart';
import 'package:my_shop/firebase_options.dart';
import 'package:my_shop/providers/theme_provider.dart';
import 'package:my_shop/providers/user_provider.dart';

import 'package:my_shop/screens/auth/login_screen.dart';
import 'package:my_shop/screens/auth/register_screen.dart';
import 'package:my_shop/screens/home_screen.dart';
import 'package:my_shop/screens/profile_screen.dart';
import 'package:my_shop/screens/admin/admin_dashboard.dart';
import 'package:my_shop/screens/admin/screens/manage_products.dart';
import 'package:my_shop/screens/admin/screens/manage_orders.dart';
import 'package:my_shop/screens/admin/screens/manage_users.dart';
import 'package:my_shop/root_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Shop',
      theme: Styles.themeData(
        isDarkTheme: themeProvider.isDarkTheme,
        context: context,
      ),
      
      // Initial route based on auth state
      home: const AuthWrapper(),
      
      // Route definitions
      routes: {
        LoginScreen.routName: (context) => const LoginScreen(),
        RegisterScreen.routName: (context) => const RegisterScreen(),
        HomeScreen.routName: (context) => const HomeScreen(),
        ProfileScreen.routName: (context) => const ProfileScreen(),
        RootScreen.routName: (context) => const RootScreen(),
        AdminDashboard.routeName: (context) => const AdminDashboard(),
        ManageProducts.routeName: (context) => const ManageProducts(),
        ManageOrders.routeName: (context) => const ManageOrders(),
        ManageUsers.routeName: (context) => const ManageUsers(),
      },
      
      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Page Not Found'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '404',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Page not found',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, LoginScreen.routName);
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Auth Wrapper to handle initial routing based on authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // Fetch user data and navigate based on role
          return FutureBuilder(
            future: _fetchUserAndNavigate(context),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // Default to RootScreen if something goes wrong
              return const RootScreen();
            },
          );
        }

        // If no user is logged in, show login screen
        return const LoginScreen();
      },
    );
  }

  Future<void> _fetchUserAndNavigate(BuildContext context) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchUser();
      
      // Navigate based on role after fetching user data
      if (context.mounted) {
        if (userProvider.isAdmin) {
          // Admin users go to admin dashboard
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, AdminDashboard.routeName);
          });
        } else {
          // Regular users go to root screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, RootScreen.routName);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
  }
}
