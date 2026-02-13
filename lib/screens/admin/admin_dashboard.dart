import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_shop/providers/user_provider.dart';
import 'package:my_shop/screens/admin/widgets/stat_card.dart';
import 'package:my_shop/screens/admin/widgets/dashboard_tile.dart';
import 'package:provider/provider.dart';
import 'package:my_shop/providers/theme_provider.dart';

class AdminDashboard extends StatefulWidget {
  static const routeName = '/admin';
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _totalProducts = 0;
  int _totalOrders = 0;
  int _totalUsers = 0;
  double _totalRevenue = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final productsSnapshot =
          await FirebaseFirestore.instance.collection('products').get();
      _totalProducts = productsSnapshot.docs.length;

      final ordersSnapshot =
          await FirebaseFirestore.instance.collection('orders').get();
      _totalOrders = ordersSnapshot.docs.length;

      double revenue = 0.0;
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        revenue += (data['total'] ?? 0.0).toDouble();
      }
      _totalRevenue = revenue;

      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      _totalUsers = usersSnapshot.docs.length;

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.clearUser();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadDashboardData();
            },
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkTheme
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      title: Text(user?.username ?? 'Admin'),
                      subtitle: Text(user?.email ?? ''),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StatCard(
                        title: 'Products',
                        value: _totalProducts.toString(),
                        icon: Icons.inventory,
                        color: Colors.blue,
                      ),
                      StatCard(
                        title: 'Orders',
                        value: _totalOrders.toString(),
                        icon: Icons.shopping_cart,
                        color: Colors.orange,
                      ),
                      StatCard(
                        title: 'Users',
                        value: _totalUsers.toString(),
                        icon: Icons.people,
                        color: Colors.green,
                      ),
                      StatCard(
                        title: 'Revenue',
                        value: '\$${_totalRevenue.toStringAsFixed(2)}',
                        icon: Icons.attach_money,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  DashboardTile(
                    title: 'Add Product',
                    subtitle: 'Add a new product',
                    icon: Icons.add_box,
                    color: Colors.teal,
                    onTap: () =>
                        Navigator.pushNamed(context, '/addProduct'),
                  ),
                  DashboardTile(
                    title: 'Manage Products',
                    subtitle: 'Edit products',
                    icon: Icons.inventory_2,
                    color: Colors.blue,
                    onTap: () =>
                        Navigator.pushNamed(context, '/manageProducts'),
                  ),
                  DashboardTile(
                    title: 'Manage Orders',
                    subtitle: 'View orders',
                    icon: Icons.shopping_bag,
                    color: Colors.orange,
                    onTap: () =>
                        Navigator.pushNamed(context, '/manageOrders'),
                  ),
                  DashboardTile(
                    title: 'Manage Users',
                    subtitle: 'Manage users',
                    icon: Icons.people,
                    color: Colors.green,
                    onTap: () =>
                        Navigator.pushNamed(context, '/manageUsers'),
                  ),
                ],
              ),
            ),
    );
  }
}
