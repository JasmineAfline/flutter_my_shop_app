import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:my_shop/providers/user_provider.dart';

class ManageUsers extends StatefulWidget {
  static const routeName = '/ManageUsers';
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (!userProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Users')),
        body: const Center(child: Text('Unauthorized')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No users yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final role = user['role'] ?? 'user';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: role == 'admin' 
                        ? Colors.purple 
                        : Theme.of(context).colorScheme.primary,
                    child: Text(
                      (user['username']?.toString().isNotEmpty == true
                          ? user['username'][0].toUpperCase()
                          : user['email']?[0].toUpperCase() ?? 'U'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user['username'] ?? user['email'] ?? 'Unknown User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['email'] ?? 'No email'),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          role.toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: role == 'admin' 
                            ? Colors.purple.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'make_admin',
                        enabled: role != 'admin',
                        child: const Row(
                          children: [
                            Icon(Icons.admin_panel_settings, size: 20),
                            SizedBox(width: 8),
                            Text('Make Admin'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'make_user',
                        enabled: role == 'admin',
                        child: const Row(
                          children: [
                            Icon(Icons.person, size: 20),
                            SizedBox(width: 8),
                            Text('Make User'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'disable',
                        child: const Row(
                          children: [
                            Icon(Icons.block, size: 20, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Disable/Enable'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'view_orders',
                        child: const Row(
                          children: [
                            Icon(Icons.history, size: 20),
                            SizedBox(width: 8),
                            Text('View Orders'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'make_admin') {
                        _updateUserRole(userId, 'admin');
                      } else if (value == 'make_user') {
                        _updateUserRole(userId, 'user');
                      } else if (value == 'delete') {
                        _deleteUser(userId);
                      } else if (value == 'disable') {
                        _toggleDisableUser(userId, user['disabled'] == true);
                      } else if (value == 'view_orders') {
                        _showUserOrders(userId, user['email'] ?? '');
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'role': newRole});
      
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.isAdmin) {
          await FirebaseFirestore.instance.collection('admin_logs').add({
            'action': 'update_user_role',
            'targetUserId': userId,
            'newRole': newRole,
            'adminId': userProvider.getUser?.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User role updated to $newRole')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user role: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text(
          'Are you sure you want to delete this user? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();
        // log admin deletion
        try {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          if (userProvider.isAdmin) {
            await FirebaseFirestore.instance.collection('admin_logs').add({
              'action': 'delete_user',
              'targetUserId': userId,
              'adminId': userProvider.getUser?.uid,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleDisableUser(String userId, bool currentlyDisabled) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'disabled': !currentlyDisabled});
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.isAdmin) {
          await FirebaseFirestore.instance.collection('admin_logs').add({
            'action': !currentlyDisabled ? 'disable_user' : 'enable_user',
            'targetUserId': userId,
            'adminId': userProvider.getUser?.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(currentlyDisabled ? 'User enabled' : 'User disabled')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating user: $e')));
    }
  }

  Future<void> _showUserOrders(String userId, String userEmail) async {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Order History'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('customerId', isEqualTo: userId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Text('No orders found for this user');
              return ListView.builder(
                shrinkWrap: true,
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final o = docs[i].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text('Order #${docs[i].id.substring(0,8)}'),
                    subtitle: Text('Total: \$${(o['total'] ?? 0).toString()} - ${o['status'] ?? 'pending'}'),
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
      ),
    );
  }
}
