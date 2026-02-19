import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_shop/providers/user_provider.dart';
import 'package:my_shop/providers/theme_provider.dart';
import 'package:my_shop/screens/auth/login_screen.dart';
import 'package:my_shop/screens/faq_screen.dart';
import 'package:my_shop/screens/messages_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 

class ProfileScreen extends StatefulWidget {
  static const routeName = "/ProfileScreen";
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserData());
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.getUser;
    
    if (user != null) {
      _nameController.text = userProvider.username;
      _emailController.text = userProvider.email;
      _loadAdditionalData(user.uid);
    }
  }

  Future<void> _loadAdditionalData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _phoneController.text = data?['phone'] ?? '';
          _addressController.text = data?['address'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading additional data: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final uid = userProvider.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'username': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      });

      await userProvider.refreshUser(); // Updated to match your UserProvider method
      if (mounted) setState(() => _isEditing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isGuest = userProvider.getUser == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!isGuest)
            Padding(
              padding: const EdgeInsets.only(right:12.0),
              child: TextButton.icon(
                onPressed: () => setState(() => _isEditing = !_isEditing),
                icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.black),
                label: Text(_isEditing ? 'Close' : 'Edit', style: const TextStyle(color: Colors.black)),
              ),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : isGuest ? _buildGuestView() : _buildProfileContent(userProvider),
    );
  }

  Widget _buildProfileContent(UserProvider userProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Avatar Section
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Text(
                userProvider.username[0].toUpperCase(),
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            
            // Editable Fields
            TextFormField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              enabled: false, // Email usually stays locked
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              enabled: _isEditing,
              decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _addressController,
              enabled: _isEditing,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Shipping Address', prefixIcon: Icon(Icons.location_on)),
            ),
            
            if (_isEditing) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('SAVE CHANGES'),
              ),
            ],
            
            const SizedBox(height: 24),

            // Theme Settings Section
            _buildThemeSettings(),

            const SizedBox(height: 20),

            // Quick Links Section
            _buildQuickLinks(),

            const SizedBox(height: 24),

            // Recent Orders header with View All
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/manageOrders'),
                  child: const Text('View All'),
                )
              ],
            ),
            const Divider(),
            _buildOrderHistory(userProvider.uid),

            const SizedBox(height: 24),
            // Logout as prominent action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => userProvider.logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistory(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final orders = snapshot.data!.docs;
        if (orders.isEmpty) return const Text("No orders found.");

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (ctx, i) {
            final data = orders[i].data() as Map<String, dynamic>;
            final orderDate = data['orderDate'] != null 
                ? (data['orderDate'] as Timestamp).toDate()
                : DateTime.now();
            
            // Get product details from order items
            final items = data['items'] as List<dynamic>? ?? [];
            final productNames = items.map((item) => item['title'] ?? 'Unknown').take(2).join(', ');
            final moreItems = items.length > 2 ? ' +${items.length - 2} more' : '';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Order #${orders[i].id.substring(0, 8)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        _buildStatusChip(data['status'] ?? 'pending'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Product: $productNames$moreItems',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Qty: ${data['totalQuantity'] ?? items.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Total: KSH ${data['totalAmount']?.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.green
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(orderDate)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered':
        color = Colors.green;
        break;
      case 'shipped':
        color = Colors.blue;
        break;
      case 'processing':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildThemeSettings() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.palette, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Theme Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Override Toggle
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Use My Theme',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            themeProvider.userOverrideEnabled
                                ? 'Your preference will be used'
                                : 'Using global theme (admin set)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: themeProvider.userOverrideEnabled,
                      onChanged: (value) => themeProvider.setUserOverrideEnabled(value),
                    ),
                  ],
                ),
                
                // Theme Toggle (only visible when user override is enabled)
                if (themeProvider.userOverrideEnabled) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Theme Mode:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.light_mode, size: 18),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.dark_mode, size: 18),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {themeProvider.isDarkTheme},
                        onSelectionChanged: (Set<bool> selected) {
                          themeProvider.setUserTheme(selected.first);
                        },
                      ),
                    ],
                  ),
                ],
                
                // Current theme preview
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkTheme 
                        ? Colors.grey.shade800 
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        themeProvider.isDarkTheme 
                            ? Icons.dark_mode 
                            : Icons.light_mode,
                        color: themeProvider.isDarkTheme 
                            ? Colors.amber 
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Currently using ${themeProvider.isDarkTheme ? "Dark" : "Light"} theme',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: themeProvider.isDarkTheme 
                              ? Colors.white 
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickLinks() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.blue),
            title: const Text('FAQ'),
            subtitle: const Text('Frequently asked questions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, FAQScreen.routeName),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.message_outlined, color: Colors.green),
            title: const Text('Messages'),
            subtitle: const Text('Notifications from admin'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, MessagesScreen.routeName),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 100, color: Colors.grey),
          const Text("You are browsing as a guest"),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, LoginScreen.routeName),
            child: const Text("Login / Sign Up"),
          )
        ],
      ),
    );
  }
}