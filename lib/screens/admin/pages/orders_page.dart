import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownButton<String>(
              value: _statusFilter,
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Orders')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'processing', child: Text('Processing')),
                DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
              ],
              onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

                if (_statusFilter != 'All') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['status'] ?? '').toString().toLowerCase() == _statusFilter.toLowerCase();
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text('No orders found'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Order ID')),
                      DataColumn(label: Text('Customer')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Total')),
                      DataColumn(label: Text('Payment Status')),
                      DataColumn(label: Text('Order Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final id = doc.id;
                      final customer = data['customerName'] ?? 'Unknown';
                      final date = data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : DateTime.now();
                      final total = data['total'] ?? 0;
                      final paymentStatus = data['paymentStatus'] ?? 'Pending';
                      final orderStatus = data['status'] ?? 'Pending';

                      return DataRow(cells: [
                        DataCell(Text(id.substring(0, 8).toUpperCase())),
                        DataCell(Text(customer.toString())),
                        DataCell(Text('${date.day}/${date.month}/${date.year}')),
                        DataCell(Text('KSH ${total.toString()}')),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: paymentStatus.toString().toLowerCase() == 'completed'
                                ? const Color(0xFF00D4AA).withOpacity(0.1)
                                : const Color(0xFFFFB800).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(paymentStatus.toString(), style: TextStyle(color: paymentStatus.toString().toLowerCase() == 'completed' ? const Color(0xFF00D4AA) : const Color(0xFFFFB800), fontWeight: FontWeight.w600)),
                        )),
                        DataCell(DropdownButton<String>(
                          value: orderStatus.toString().toLowerCase(),
                          items: const [
                            DropdownMenuItem(value: 'pending', child: Text('Pending')),
                            DropdownMenuItem(value: 'processing', child: Text('Processing')),
                            DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
                            DropdownMenuItem(value: 'completed', child: Text('Completed')),
                          ],
                          onChanged: (v) async {
                            try {
                              await FirebaseFirestore.instance.collection('orders').doc(id).update({'status': v});
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order status updated')));
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                        )),
                        DataCell(ElevatedButton(
                          onPressed: () => _showOrderDetails(id, data),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 12)),
                        )),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showOrderDetails(String orderId, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${orderId.substring(0, 8).toUpperCase()}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${order['customerName'] ?? 'N/A'}'),
              const SizedBox(height: 12),
              Text('Email: ${order['customerEmail'] ?? 'N/A'}'),
              const SizedBox(height: 12),
              Text('Total: KSH ${order['total'] ?? 0}'),
              const SizedBox(height: 12),
              Text('Payment Status: ${order['paymentStatus'] ?? 'N/A'}'),
              const SizedBox(height: 12),
              Text('Order Status: ${order['status'] ?? 'N/A'}'),
              const SizedBox(height: 12),
              if (order['items'] is List)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(order['items'] as List).map((item) => Text('- ${item['title'] ?? 'N/A'} x${item['quantity'] ?? 1}')).toList(),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
