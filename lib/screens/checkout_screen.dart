import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_shop/providers/user_provider.dart';
import 'package:my_shop/providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';
  final List<Map<String, dynamic>> cartItems;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.total,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isProcessing = false;

  // Local emulator endpoint for STK Push (update when deploying)
  // Using ngrok public forwarding for local mpesa-server during testing
  static const String _stkPushEndpoint = 'https://c81a-38-226-202-118.ngrok-free.app/stkpush';
  // Production URL (after deploying M-Pesa server):
  // static const String _stkPushEndpoint = 'https://your-deployed-server.com/stkpush';

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.getUser;
    if (user != null) {
      _nameController.text = user.username;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  Future<Map<String, dynamic>> _stkPush({required String phone, required double amount}) async {
    final uri = Uri.parse(_stkPushEndpoint);
    final body = {
      'phone': phone,
      'amount': amount,
    };

    final resp = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    throw Exception('STK Push request failed (${resp.statusCode})');
  }

  Future<void> _payWithMpesa(List<Map<String, dynamic>> items, double total) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    final phone = _phoneController.text.trim();

    try {
      final result = await _stkPush(phone: phone, amount: total);

      // Expecting result to contain success flag or transaction info
      final success = result['success'] == true || result['status'] == 'ok';

      if (!mounted) return;

      if (success) {
        // Create order in Firestore upon successful STK response
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not logged in');

        await FirebaseFirestore.instance.collection('orders').add({
          'userId': user.uid,
          'customerId': user.uid,
          'customerName': _nameController.text.trim(),
          'customerEmail': _emailController.text.trim(),
          'phone': phone,
          'address': _addressController.text.trim(),
          'items': items,
          'total': total,
          'status': 'pending',
          'paymentRef': result['paymentRef'] ?? result['checkoutRequestID'] ?? 'mpesa_${DateTime.now().millisecondsSinceEpoch}',
          'createdAt': FieldValue.serverTimestamp(),
        });

        Provider.of<CartProvider>(context, listen: false).clearCart();

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment initiated — check your phone'), backgroundColor: Colors.green));
        Navigator.pushReplacementNamed(context, '/root');
      } else {
        final message = result['message'] ?? 'Payment failed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('M-Pesa error: $message')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.cartItems[index];
                    return ListTile(
                      title: Text(item['name']),
                      subtitle: Text('Qty: ${item['quantity']}'),
                      trailing: Text('KSH ${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('KSH ${widget.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Delivery Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Delivery Address'),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter address' : null,
              ),
              const SizedBox(height: 24),
              const Text('Phone (M-Pesa)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone number (e.g., 254700000000)'),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter phone number';
                  final s = v.trim();
                  if (!RegExp(r'^\d{9,15}$').hasMatch(s)) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          final cart = Provider.of<CartProvider>(context, listen: false);
                          final items = cart.cartItems.isNotEmpty ? cart.cartItems : widget.cartItems;
                          final total = cart.cartItems.isNotEmpty ? cart.total : widget.total;
                          _payWithMpesa(items, total);
                        },
                  child: _isProcessing
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Pay with M-Pesa'),
                ),
              ),
              const SizedBox(height: 12),
              const Text('After tapping Pay, you will receive an M-Pesa prompt on your phone.'),
            ],
          ),
        ),
      ),
    );
  }
}
