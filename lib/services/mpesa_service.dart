import 'dart:convert';
import 'package:http/http.dart' as http;

class MpesaService {
  // Base URL for STK Push - Update this to your ngrok URL when running locally
  // For production, use a fixed domain or deploy to a server
  String baseUrl = "https://d78e-38-226-202-118.ngrok-free.app";

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

    } catch (e) {
      print("STK Push Error: $e");
    }
  }
}
