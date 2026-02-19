import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_shop/providers/wishlist_provider.dart';
import 'package:my_shop/providers/cart_provider.dart';
import 'package:my_shop/models/product_model.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  static const accent = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final cart = context.read<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text('My Wishlist', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          if (wishlist.count > 0)
            IconButton(
              onPressed: () => wishlist.clear(),
              icon: const Icon(Icons.clear, color: Colors.black),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: wishlist.count == 0
            ? _buildEmpty(context)
            : ListView.separated(
                itemCount: wishlist.count,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final Product p = wishlist.items[index];
                  return _buildCard(context, p, wishlist, cart);
                },
              ),
      ),
      // Navigation is provided by RootScreen when this page is shown inside the app's PageView.
      // Do not include a local bottom navigation bar to avoid duplicates.
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 96, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text('Your wishlist is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Save items you love here', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/all-products'),
            style: ElevatedButton.styleFrom(backgroundColor: accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
              child: Text('Explore Products', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Product p, WishlistProvider wishlist, CartProvider cart) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(p.imageUrl, width: 78, height: 78, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(width:78,height:78,color:Colors.grey[200],child: const Icon(Icons.image))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('KSH ${p.currentPrice.toStringAsFixed(0)}', style: const TextStyle(color: accent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () {
                    wishlist.remove(p.id);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from wishlist')));
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: () {
                    cart.addToCart(p);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  child: const Text('Add', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Navigation is provided by RootScreen; no local bottom nav here.
}
