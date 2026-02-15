import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:my_shop/constants/theme_data.dart';
import 'package:my_shop/firebase_options.dart';
import 'package:my_shop/providers/theme_provider.dart';
import 'package:my_shop/providers/user_provider.dart';
import 'package:my_shop/providers/cart_provider.dart';

import 'package:my_shop/screens/auth/login_screen.dart';
import 'package:my_shop/screens/register_screen.dart';
import 'package:my_shop/screens/auth/forgot_password_screen.dart';
import 'package:my_shop/screens/home_screen.dart';
import 'package:my_shop/screens/profile_screen.dart';
import 'package:my_shop/screens/checkout_screen.dart';
import 'package:my_shop/screens/admin/admin_dashboard.dart';
import 'package:my_shop/screens/admin/screens/add_product_screen.dart';
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
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
      // Global scroll behavior for modern feel
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      theme: Styles.themeData(
        isDarkTheme: themeProvider.isDarkTheme,
        context: context,
      ),
      home: const AuthWrapper(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/root': (context) => const RootScreen(),
        CheckoutScreen.routeName: (context) => const CheckoutScreen(cartItems: [], total: 0),
        '/admin': (context) {
          final userProvider = Provider.of<UserProvider>(context);
          if (userProvider.isAdmin) return const AdminDashboard();
          return Scaffold(
            appBar: AppBar(title: const Text('Unauthorized')),
            body: const Center(child: Text('You are not authorized to view this page')),
          );
        },
        '/addProduct': (context) => const AddProductScreen(),
        '/manageProducts': (context) => const ManageProducts(),
        '/manageOrders': (context) => const ManageOrders(),
        '/manageUsers': (context) => const ManageUsers(),
      },

      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '404',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Page not found', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
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

// -------------------- AUTH WRAPPER --------------------
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder(
            future: _fetchUserAndNavigate(context),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return const RootScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }

  Future<void> _fetchUserAndNavigate(BuildContext context) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchUser();

      if (context.mounted) {
        if (userProvider.isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/admin');
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/root');
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
  }
}
