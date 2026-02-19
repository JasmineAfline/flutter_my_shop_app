import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:my_shop/constants/theme_data.dart';
import 'package:my_shop/firebase_options.dart';
import 'package:my_shop/providers/theme_provider.dart';
import 'package:my_shop/providers/user_provider.dart';
import 'package:my_shop/providers/cart_provider.dart';
import 'package:my_shop/providers/wishlist_provider.dart';

import 'package:my_shop/screens/auth/login_screen.dart';
import 'package:my_shop/screens/register_screen.dart';
import 'package:my_shop/screens/auth/forgot_password_screen.dart';
import 'package:my_shop/screens/home_screen.dart';
import 'package:my_shop/screens/profile_screen.dart';
import 'package:my_shop/screens/checkout_screen.dart';
import 'package:my_shop/screens/cart_screen.dart' as cart;
import 'package:my_shop/screens/faq_screen.dart';
import 'package:my_shop/screens/messages_screen.dart';
import 'package:my_shop/screens/admin/admin_dashboard_modern.dart' as adminScreen;
import 'package:my_shop/screens/admin/screens/add_product_screen.dart';
import 'package:my_shop/screens/admin/screens/manage_products.dart';
import 'package:my_shop/screens/admin/screens/manage_orders.dart';
import 'package:my_shop/screens/admin/screens/manage_users.dart';
import 'package:my_shop/screens/product_details_screen.dart';
import 'package:my_shop/screens/all_products_screen.dart';
import 'package:my_shop/screens/admin/mpesa_logs.dart';
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
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
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
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      theme: Styles.themeData(
        isDarkTheme: themeProvider.isDarkTheme,
        context: context,
      ),
      darkTheme: Styles.themeData(
        isDarkTheme: true,
        context: context,
      ),
      themeMode: themeProvider.themeMode,
      // AuthWrapper handles the initial landing logic
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/root': (context) => const RootScreen(),
        '/cart': (context) => const cart.CartScreen(),
        '/faq': (context) => const FAQScreen(),
        '/messages': (context) => const MessagesScreen(),
        // FIX: Removed the cartItems and total parameters
        CheckoutScreen.routeName: (context) {
          final userProvider = Provider.of<UserProvider>(context);
          if (userProvider.isAdmin) return adminScreen.AdminDashboard(key: UniqueKey());
          return const CheckoutScreen();
        },
        '/admin': (context) {
          final userProvider = Provider.of<UserProvider>(context);
          if (userProvider.isAdmin) return adminScreen.AdminDashboard(key: UniqueKey());
          return const RootScreen(); // Redirect non-admins back to safety
        },
        '/addProduct': (context) {
          final userProvider = Provider.of<UserProvider>(context);
          if (userProvider.isAdmin) return const AddProductScreen();
          return const RootScreen();
        },
        '/manageProducts': (context) {
          final userProvider = Provider.of<UserProvider>(context);
          if (userProvider.isAdmin) return const ManageProducts();
          return const RootScreen();
        },
        '/manageOrders': (context) {
          final userProvider = Provider.of<UserProvider>(context);
          if (userProvider.isAdmin) return const ManageOrders();
          return const RootScreen();
        },
        '/manageUsers': (context) {
          final userProvider = Provider.of<UserProvider>(context);
          if (userProvider.isAdmin) return const ManageUsers();
          return const RootScreen();
        },
        '/all-products': (context) => const AllProductsScreen(),
        '/mpesa-logs': (context) => const MpesaLogsScreen(),
        ProductDetailsScreen.routeName: (context) => const ProductDetailsScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('404', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Page not found', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/root'),
                    child: const Text('Back to Home'),
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (userProvider.getUser != null) {
          // Check if user is admin and route accordingly
          if (userProvider.isAdmin) {
            return adminScreen.AdminDashboard(key: UniqueKey());
          }
          return const RootScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
