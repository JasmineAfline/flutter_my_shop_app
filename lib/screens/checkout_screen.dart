import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_shop/providers/cart_provider.dart';
import 'package:my_shop/services/mpesa_service.dart';

class CheckoutScreen extends StatefulWidget {
  static const String routeName = '/checkout';

  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.cartItems.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    /// CART ITEMS
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartItems.length,
                      itemBuilder: (ctx, i) {
                        final item = cartItems[i];

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                                  ? Image.network(
                                      item.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image_not_supported),
                                    ),
                            ),
                          ),
                          title: Text(
                            item.title ?? "No title",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('KSH ${item.price} x ${item.quantity}'),
                          trailing: Text(
                            'KSH ${(item.price * item.quantity).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 30, thickness: 2),

                    /// TOTAL
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:',
                            style: TextStyle(fontSize: 18)),
                        Text(
                          'KSH ${cart.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    /// PAY BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _showMpesaDialog(
                                context,
                                cart.totalAmount.toInt(),
                              ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'PAY WITH M-PESA',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showMpesaDialog(BuildContext context, int amount) {
    final phoneController =
        TextEditingController(text: "254");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Lipa Na M-Pesa"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Enter your M-Pesa number to receive the payment prompt:"),
            const SizedBox(height: 15),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Phone Number",
                hintText: "2547XXXXXXXX",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              String phone = phoneController.text.trim();

              /// BASIC VALIDATION
              if (!phone.startsWith("254") || phone.length != 12) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          "Enter valid number e.g. 2547XXXXXXXX")),
                );
                return;
              }

              setState(() => _isLoading = true);

              try {
                await MpesaService().stkPush(phone, amount);

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("STK Push Sent! Check your phone.")),
                );
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Payment Error: ${e.toString()}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text("SEND PROMPT"),
          ),
        ],
      ),
    );
  }
}
