import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MpesaLogsScreen extends StatelessWidget {
  const MpesaLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('M-Pesa Logs')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('payments').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No payments recorded'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'unknown';
              final phone = data['phone'] ?? '-';
              final amount = data['amount'] ?? '-';
              final checkout = data['checkoutRequestID'] ?? doc.id;
              final resultDesc = data['resultDesc'] ?? '';

              Color statusColor;
              switch (status.toString().toLowerCase()) {
                case 'pending':
                  statusColor = Colors.orange;
                  break;
                case 'completed':
                case 'success':
                  statusColor = Colors.green;
                  break;
                case 'cancelled':
                case 'request cancelled by user.':
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              return Card(
                child: ListTile(
                  title: Text('KSH $amount • $phone'),
                  subtitle: Text('Checkout: $checkout\n${resultDesc.toString()}'),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, color: statusColor, size: 12),
                      const SizedBox(height: 6),
                      Text(status.toString(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
