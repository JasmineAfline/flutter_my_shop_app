import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:my_shop/providers/user_provider.dart';
import 'pages/dashboard_page.dart';
import 'pages/products_page.dart'; // Imports ProductsPage from export
import 'pages/orders_page.dart';
import 'pages/users_page.dart';
import 'pages/help_center_page.dart';
import 'pages/settings_page.dart';

class AdminDashboard extends StatefulWidget {
  static const routeName = '/admin';
  const AdminDashboard({required Key key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentPage = 0;
  final List<String> _pageNames = [
    'Dashboard',
    'Products',
    'Orders',
    'Users',
    'Help Center',
    'Settings'
  ];

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (!userProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'Admin access only',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 280,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                              child: Text('MS',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MyShop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Admin Panel', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        _sidebarItem(0, Icons.dashboard_outlined, 'Dashboard'),
                        _sidebarItem(1, Icons.shopping_bag_outlined, 'Products'),
                        _sidebarItem(2, Icons.receipt_long_outlined, 'Orders'),
                        _sidebarItem(3, Icons.people_outline, 'Users'),
                        _sidebarItem(4, Icons.help_outline, 'Help Center'),
                        _sidebarItem(5, Icons.settings_outlined, 'Settings'),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('Logout', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_pageNames[_currentPage], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.account_circle, size: 20),
                                const SizedBox(width: 8),
                                Text(userProvider.username, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: _buildPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    final isActive = _currentPage == index;
    return GestureDetector(
      onTap: () => setState(() => _currentPage = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6C63FF).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: const Color(0xFF6C63FF), width: 1.5) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? const Color(0xFF6C63FF) : Colors.grey.shade600, size: 22),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500, color: isActive ? const Color(0xFF6C63FF) : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (_currentPage) {
      case 0:
        return const DashboardPage();
      case 1:
        return const ProductsPage();
      case 2:
        return const OrdersPage();
      case 3:
        return const UsersPage();
      case 4:
        return const HelpCenterPage();
      case 5:
        return const SettingsPage();
      default:
        return const DashboardPage();
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Logout')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
