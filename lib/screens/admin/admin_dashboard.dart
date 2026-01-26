import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_shop/providers/user_provider.dart';
import 'package:my_shop/screens/admin/screens/manage_products.dart';
import 'package:my_shop/screens/admin/screens/manage_orders.dart';
import 'package:my_shop/screens/admin/screens/manage_users.dart';
import 'package:my_shop/screens/admin/widgets/stat_card.dart';
import 'package:my_shop/screens/admin/widgets/dashboard_tile.dart';
import 'package:my_shop/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatefulWidget {
  static const routeName = '/AdminDashboard';
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
      // Get total products
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();
      _totalProducts = productsSnapshot.docs.length;

      // Get total orders
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .get();
      _totalOrders = ordersSnapshot.docs.length;

      // Calculate total revenue
      double revenue = 0.0;
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        revenue += (data['total'] ?? 0.0).toDouble();
      }
      _totalRevenue = revenue;

      // Get total users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      _totalUsers = usersSnapshot.docs.length;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.clearUser();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, LoginScreen.routName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadDashboardData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                user?.username.isNotEmpty == true
                                    ? user!.username[0].toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back!',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.username ?? 'Admin',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    user?.email ?? '',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statistics Cards
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        StatCard(
                          title: 'Total Products',
                          value: _totalProducts.toString(),
                          icon: Icons.inventory_2_outlined,
                          color: Colors.blue,
                        ),
                        StatCard(
                          title: 'Total Orders',
                          value: _totalOrders.toString(),
                          icon: Icons.shopping_cart_outlined,
                          color: Colors.orange,
                        ),
                        StatCard(
                          title: 'Total Users',
                          value: _totalUsers.toString(),
                          icon: Icons.people_outline,
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

                    // Management Options
                    Text(
                      'Management',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DashboardTile(
                      title: 'Manage Products',
                      subtitle: 'Add, edit, or remove products',
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pushNamed(context, ManageProducts.routeName);
                      },
                    ),
                    const SizedBox(height: 12),
                    DashboardTile(
                      title: 'Manage Orders',
                      subtitle: 'View and process orders',
                      icon: Icons.shopping_bag,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pushNamed(context, ManageOrders.routeName);
                      },
                    ),
                    const SizedBox(height: 12),
                    DashboardTile(
                      title: 'Manage Users',
                      subtitle: 'View and manage user accounts',
                      icon: Icons.people,
                      color: Colors.green,
                      onTap: () {
                        Navigator.pushNamed(context, ManageUsers.routeName);
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
