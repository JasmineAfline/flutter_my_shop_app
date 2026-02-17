import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// Ensure these paths match your project structure exactly
import 'package:my_shop/providers/user_provider.dart';
import 'package:my_shop/providers/theme_provider.dart';
import 'package:my_shop/screens/admin/widgets/stat_card.dart';
import 'package:my_shop/screens/admin/widgets/dashboard_tile.dart';

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
      // 1. Fetch Products Count
      final productsSnapshot =
          await FirebaseFirestore.instance.collection('products').get();
      _totalProducts = productsSnapshot.docs.length;

      // 2. Fetch Orders and Calculate Revenue
      final ordersSnapshot =
          await FirebaseFirestore.instance.collection('orders').get();
      _totalOrders = ordersSnapshot.docs.length;

      double revenue = 0.0;
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        revenue += (data['total'] ?? 0.0).toDouble();
      }
      _totalRevenue = revenue;

      // 3. Fetch Users Count
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      _totalUsers = usersSnapshot.docs.length;

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await FirebaseAuth.instance.signOut();
    userProvider.clearUser(); // Resetting local provider state
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Safety Guard: Check if user is admin
    if (!userProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const Center(
          child: Text('Unauthorized: Admin access only.', 
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      );
    }

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
                  // Admin Profile Header
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.admin_panel_settings)),
                      title: Text(userProvider.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(userProvider.getUser?.email ?? 'No email associated'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.4,
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
                        value: 'KSH ${_totalRevenue.toStringAsFixed(0)}',
                        icon: Icons.payments,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Management Tiles
                  const Text('Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DashboardTile(
                    title: 'Add Product',
                    subtitle: 'Create a new store item',
                    icon: Icons.add_business,
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, '/addProduct'),
                  ),
                  DashboardTile(
                    title: 'Manage Products',
                    subtitle: 'Update prices or stock',
                    icon: Icons.edit_note,
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, '/manageProducts'),
                  ),
                  DashboardTile(
                    title: 'Manage Orders',
                    subtitle: 'View and process sales',
                    icon: Icons.local_shipping,
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, '/manageOrders'),
                  ),
                  DashboardTile(
                    title: 'Manage Users',
                    subtitle: 'Control user permissions',
                    icon: Icons.manage_accounts,
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/manageUsers'),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Theme Settings Card
                  Card(
                    color: themeProvider.isDarkTheme ? Colors.grey[900] : Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Theme Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Divider(),
                          Text(
                            'Set the default theme for all users. Users can override this in their profile.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Global Theme: ', style: TextStyle(fontWeight: FontWeight.w500)),
                              const Spacer(),
                              Switch(
                                value: themeProvider.isDarkTheme,
                                onChanged: (value) => themeProvider.setGlobalTheme(value),
                                activeColor: Colors.green,
                              ),
                              Text(
                                themeProvider.isDarkTheme ? 'Dark' : 'Light',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.isDarkTheme ? Colors.blue : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Simple Report Card
                  Card(
                    color: themeProvider.isDarkTheme ? Colors.grey[900] : Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quick Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Divider(),
                          Text('Average Order Value: KSH ${(_totalOrders > 0 ? _totalRevenue / _totalOrders : 0).toStringAsFixed(2)}'),
                          const SizedBox(height: 4),
                          Text('Platform Growth: ${_totalUsers} Total Members'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}