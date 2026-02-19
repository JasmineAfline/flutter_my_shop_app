import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_shop/providers/cart_provider.dart';
import 'package:my_shop/models/cart_model.dart';
import 'package:my_shop/screens/checkout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartScreen extends StatelessWidget {
  static const String routeName = '/cart';
  const CartScreen({super.key});

  static const accent = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartList = cart.cartItems.values.toList();
    final productIds = cart.cartItems.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text('My Cart', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: cart.itemCount == 0
            ? _buildEmptyState(context)
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.itemCount,
                      itemBuilder: (ctx, i) {
                        return _buildCartItem(cartList[i], productIds[i], cart, context);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOrderSummary(cart, context),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 96, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Add items to start shopping', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/all-products'),
            style: ElevatedButton.styleFrom(backgroundColor: accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
              child: Text('Browse Products', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, String productId, CartProvider cart, BuildContext context) {
    return Dismissible(
      key: ValueKey(productId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        cart.removeItem(productId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from cart')));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(width: 84, height: 84, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('KSH ${item.price.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade600)),
                        Text('KSH ${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: accent)),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => cart.updateQuantity(productId, item.quantity + 1),
                    iconSize: 24,
                    color: Colors.grey,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => cart.updateQuantity(productId, item.quantity - 1),
                    iconSize: 24,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart, BuildContext context) {
    final subtotal = cart.totalAmount;
    final shipping = subtotal > 0 ? 200.0 : 0.0;
    final tax = subtotal * 0.16;
    final total = subtotal + shipping + tax;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [const Text('Subtotal'), const Spacer(), Text('KSH ${subtotal.toStringAsFixed(0)}')]),
            const SizedBox(height: 8),
            Row(children: [const Text('Shipping'), const Spacer(), Text('KSH ${shipping.toStringAsFixed(0)}')]),
            const SizedBox(height: 8),
            Row(children: [const Text('Tax'), const Spacer(), Text('KSH ${tax.toStringAsFixed(0)}')]),
            const Divider(height: 20, thickness: 1.0),
            Row(children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), const Spacer(), Text('KSH ${total.toStringAsFixed(0)}', style: const TextStyle(color: accent, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: subtotal <= 0
                    ? null
                    : () {
                        // Require user to be authenticated (no guests allowed to checkout)
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null || user.isAnonymous) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to proceed to checkout')));
                          Navigator.pushNamed(context, '/login');
                          return;
                        }
                        Navigator.pushNamed(context, CheckoutScreen.routeName);
                      },
                style: ElevatedButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 4),
                child: const Text('Proceed to Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
