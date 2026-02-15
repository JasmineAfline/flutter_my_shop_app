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

    if (!userProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const Center(child: Text('Unauthorized')),
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
                        value: 'KSH ${_totalRevenue.toStringAsFixed(2)}',
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
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Total Orders: $_totalOrders'),
                          Text('Total Revenue: KSH ${_totalRevenue.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).limit(100).get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox.shrink();
                              final docs = snapshot.data!.docs;
                              // top products best-effort
                              final Map<String, int> counts = {};
                              for (var d in docs) {
                                final data = d.data() as Map<String, dynamic>;
                                final items = data['items'] as List<dynamic>?;
                                if (items != null) {
                                  for (var it in items) {
                                    try {
                                      final pid = it['productId']?.toString() ?? '';
                                      final qty = (it['quantity'] ?? 1) as int;
                                      if (pid.isNotEmpty) counts[pid] = (counts[pid] ?? 0) + qty;
                                    } catch (_) {}
                                  }
                                }
                              }
                              final top = counts.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  const Text('Top Products (approx)'),
                                  const SizedBox(height: 6),
                                  if (top.isEmpty) const Text('No product data'),
                                  for (var e in top.take(5)) Text('${e.key} — ${e.value} sold'),
                                ],
                              );
                            },
                          ),
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
