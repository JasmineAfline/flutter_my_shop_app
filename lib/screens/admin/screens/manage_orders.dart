import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:my_shop/providers/user_provider.dart';

class ManageOrders extends StatefulWidget {
  static const routeName = '/ManageOrders';
  const ManageOrders({super.key});

  @override
  State<ManageOrders> createState() => _ManageOrdersState();
}

class _ManageOrdersState extends State<ManageOrders> {
  String _statusFilter = 'All';
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (!userProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Orders')),
        body: Center(child: Text('Unauthorized')), 
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _statusFilter = v),
            itemBuilder: (c) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'pending', child: Text('Pending')),
              PopupMenuItem(value: 'processing', child: Text('Processing')),
              PopupMenuItem(value: 'completed', child: Text('Completed')),
              PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
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
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;

          final filtered = _statusFilter == 'All'
              ? orders
              : orders.where((d) => ((d.data() as Map<String, dynamic>)['status'] ?? 'pending') == _statusFilter).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final order = filtered[index].data() as Map<String, dynamic>;
              final orderId = filtered[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(order['status']),
                    child: const Icon(Icons.shopping_bag, color: Colors.white),
                  ),
                  title: Text(
                    'Order #${orderId.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Total: KSH ${order['total']?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                  trailing: Chip(
                    label: Text(
                      order['status'] ?? 'pending',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: _getStatusColor(order['status']).withOpacity(0.2),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer: ${order['customerName'] ?? 'N/A'}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text('Email: ${order['customerEmail'] ?? 'N/A'}'),
                          const SizedBox(height: 4),
                          Text('Address: ${order['address'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          if ((order['paymentRef'] ?? '').toString().isNotEmpty)
                            Text('Payment Ref: ${order['paymentRef']}'),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _updateOrderStatus(orderId, 'processing');
                                },
                                child: const Text('Mark Processing'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _cancelOrder(orderId),
                                child: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  _updateOrderStatus(orderId, 'completed');
                                },
                                child: const Text('Mark Completed'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': status});
      // log admin action
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.isAdmin) {
          await FirebaseFirestore.instance.collection('admin_logs').add({
            'action': 'update_order_status',
            'orderId': orderId,
            'status': status,
            'adminId': userProvider.getUser?.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: $e')),
        );
      }
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    await _updateOrderStatus(orderId, 'cancelled');
  }
}
