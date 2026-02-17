import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final List<dynamic> items;
  final double totalAmount;
  final String status; // 'pending', 'paid', 'shipped'
  final String mpesaReceipt;
  final Timestamp orderDate;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.mpesaReceipt,
    required this.orderDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'items': items,
      'totalAmount': totalAmount,
      'status': status,
      'mpesaReceipt': mpesaReceipt,
      'orderDate': orderDate,
    };
  }
}