import 'dart:math' as math;
import 'package:flutter/material.dart';

class SalesChart extends StatelessWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulated data - in production, fetch from Firestore
    final chartData = [
      {'day': 'Mon', 'sales': 15000},
      {'day': 'Tue', 'sales': 18000},
      {'day': 'Wed', 'sales': 12000},
      {'day': 'Thu', 'sales': 22000},
      {'day': 'Fri', 'sales': 25000},
      {'day': 'Sat', 'sales': 28000},
      {'day': 'Sun', 'sales': 20000},
    ];

    final salesList = chartData.map((d) => (d['sales'] as num).toDouble()).toList();
    final maxSales = salesList.isNotEmpty ? salesList.reduce(math.max) : 1.0;

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final count = chartData.length;
              final spacing = 12.0;
              final availableWidth = constraints.maxWidth;
              // compute ideal bar width but don't exceed 40
              final idealBarWidth = (availableWidth - (count - 1) * spacing) / (count == 0 ? 1 : count);
              final barWidth = math.min(40.0, math.max(20.0, idealBarWidth));

              final bars = chartData.map((data) {
                final sales = (data['sales'] as num).toDouble();
                final height = maxSales > 0 ? (sales / maxSales) * 200 : 0.0;
                return Padding(
                  padding: EdgeInsets.only(right: spacing),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: barWidth,
                        height: height,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(width: barWidth, child: Text(data['day'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                    ],
                  ),
                );
              }).toList();

              // If bars exceed available width, allow horizontal scrolling
              final totalNeeded = (barWidth * count) + (spacing * (count - 1));
              if (totalNeeded > availableWidth) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: bars),
                );
              }

              return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: bars);
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Sales: ${chartData.fold<int>(0, (sum, d) => sum + (d['sales'] as int))} KSH', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('Weekly Sales', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
