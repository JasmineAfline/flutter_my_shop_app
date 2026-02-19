import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class MpesaService {
  // Base URL for STK Push - Using local mpesa-server with ngrok
  // 
  // TO USE:
  // 1. Run local server: cd mpesa-server && node server.js
  // 2. Start ngrok: ngrok http 3001
  // 3. Copy the ngrok URL (e.g., https://abc123.ngrok-free.app) and update below
  // 
  // NOTE: ngrok URLs are temporary - you'll need to update this when ngrok restarts
  String baseUrl = "https://cac6-38-226-202-118.ngrok-free.app";

  Future<void> stkPush(String phone, int amount) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/stkpush"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "phone": phone,
          "amount": amount,
        }),
      );

      print("Backend Response: ${response.body}");
      // If backend returned STK response containing CheckoutRequestID, save a pending payment doc
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final checkoutId = data['CheckoutRequestID'] ?? data['checkoutRequestID'] ?? data['CheckoutRequestID'];
          final merchantId = data['MerchantRequestID'] ?? data['merchantRequestID'];

          if (checkoutId != null) {
            await FirebaseFirestore.instance.collection('payments').doc(checkoutId.toString()).set({
              'phone': phone,
              'amount': amount,
              'merchantRequestID': merchantId ?? '',
              'checkoutRequestID': checkoutId.toString(),
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } else {
            // fallback: add a short record
            await FirebaseFirestore.instance.collection('payments').add({
              'phone': phone,
              'amount': amount,
              'rawResponse': response.body,
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          print('Failed to write payment record: $e');
        }
      }

    } catch (e) {
      print("STK Push Error: $e");
    }
  }
}
