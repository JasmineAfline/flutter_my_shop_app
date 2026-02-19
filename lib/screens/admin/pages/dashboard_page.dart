import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/sales_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>> _dashboardData;

  // Safe parsing helpers
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _dashboardData = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    try {
      final productsSnapshot = await FirebaseFirestore.instance.collection('products').get();
      final ordersSnapshot = await FirebaseFirestore.instance.collection('orders').get();
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

      int totalProducts = productsSnapshot.docs.length;
      int totalOrders = ordersSnapshot.docs.length;
      int totalUsers = usersSnapshot.docs.length;
      double totalRevenue = 0;
      double todayRevenue = 0;
      double thisMonthRevenue = 0;
      int lowStockCount = 0;
      List<Map<String, dynamic>> pendingOrders = [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisMonthStart = DateTime(now.year, now.month, 1);

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        final amount = _toDouble(data['total']);
        totalRevenue += amount;

        if (data['createdAt'] is Timestamp) {
          final orderDate = (data['createdAt'] as Timestamp).toDate();
          if (orderDate.isAfter(today)) {
            todayRevenue += amount;
          }
          if (orderDate.isAfter(thisMonthStart)) {
            thisMonthRevenue += amount;
          }
        }

        if ((data['status'] ?? '').toString().toLowerCase() != 'completed') {
          // ensure id is present and stringifiable
          final entry = Map<String, dynamic>.from(data);
          entry['id'] = entry['id'] ?? doc.id;
          pendingOrders.add(entry);
        }
      }

      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final stock = _toInt(data['stock']);
        if (stock < 10) lowStockCount++;
      }

      return {
        'totalProducts': totalProducts,
        'totalOrders': totalOrders,
        'totalUsers': totalUsers,
        'totalRevenue': totalRevenue,
        'todayRevenue': todayRevenue,
        'thisMonthRevenue': thisMonthRevenue,
        'lowStockCount': lowStockCount,
        'pendingOrders': pendingOrders.take(5).toList(),
      };
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stat Cards Row (responsive)
              Builder(builder: (context) {
                final width = MediaQuery.of(context).size.width;
                int crossAxis = 4;
                if (width < 800) {
                  crossAxis = 1;
                } else if (width < 1100) {
                  crossAxis = 2;
                } else if (width < 1400) {
                  crossAxis = 3;
                }

                return GridView.count(
                  crossAxisCount: crossAxis,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                  AdminStatCard(
                    title: 'Total Products',
                    value: '${data['totalProducts'] ?? 0}',
                    icon: Icons.shopping_bag,
                    color: const Color(0xFF6C63FF),
                  ),
                  AdminStatCard(
                    title: 'Total Orders',
                    value: '${data['totalOrders'] ?? 0}',
                    icon: Icons.receipt_long,
                    color: const Color(0xFF00B4DB),
                  ),
                  AdminStatCard(
                    title: 'Total Users',
                    value: '${data['totalUsers'] ?? 0}',
                    icon: Icons.people,
                    color: const Color(0xFF00D4AA),
                  ),
                  AdminStatCard(
                    title: 'Total Revenue',
                    value: 'KSH ${data['totalRevenue'] ?? 0}',
                    icon: Icons.trending_up,
                    color: const Color(0xFFFFB800),
                    subtitle: 'Month: KSH ${data['thisMonthRevenue'] ?? 0}',
                  ),
                  ],
                );
              }),
              const SizedBox(height: 32),
              // Sales Chart
              const Text('Sales Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: const SalesChart(),
              ),
              const SizedBox(height: 32),
              // Two Column Layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pending Orders
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pending Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          if ((data['pendingOrders'] as List?)?.isEmpty ?? true)
                            const Center(child: Text('No pending orders'))
                          else
                            ListView.builder(
                              itemCount: (data['pendingOrders'] as List?)?.length ?? 0,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final order = (data['pendingOrders'] as List?)?[index] ?? {};
                                final idStr = (order['id'] ?? '').toString();
                                final displayId = idStr.isNotEmpty ? (idStr.length > 8 ? idStr.substring(0, 8) : idStr) : 'N/A';
                                final customerName = (order['customerName'] ?? order['customer'] ?? '').toString();
                                final totalStr = _toDouble(order['total']);

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Order #$displayId', style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 4),
                                              Text(customerName.isNotEmpty ? customerName : 'Unknown', style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00B4DB).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('KSH ${totalStr.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00B4DB))),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (index < ((data['pendingOrders'] as List?)?.length ?? 0) - 1) const Divider(),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Low Stock Products
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: const Text('Low Stock Alert', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF0000).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${data['lowStockCount'] ?? 0} items', style: const TextStyle(color: Color(0xFFFF0000), fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if ((data['lowStockCount'] ?? 0) == 0)
                            const Center(child: Text('All products well stocked'))
                          else
                            Text('${data['lowStockCount'] ?? 0} products have less than 10 units in stock. Consider reordering.', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
