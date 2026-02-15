import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:my_shop/providers/user_provider.dart';
import 'package:my_shop/providers/cart_provider.dart';
import 'package:my_shop/utils/route_guard.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _categoryFilter = 'All';
  String _sortOption = 'newest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shop'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _categoryFilter,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
                        DropdownMenuItem(value: 'Clothing', child: Text('Clothing')),
                      ],
                      onChanged: (v) => setState(() => _categoryFilter = v ?? 'All'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _sortOption,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Newest')),
                        DropdownMenuItem(value: 'price_low', child: Text('Price: Low')),
                        DropdownMenuItem(value: 'price_high', child: Text('Price: High')),
                      ],
                      onChanged: (v) => setState(() => _sortOption = v ?? 'newest'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 400, child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return SizedBox(height: 400, child: Center(child: Text('Error: ${snapshot.error}')));
                }
                final docs = snapshot.data?.docs ?? [];
                var filtered = docs.where((d) {
                  final p = d.data() as Map<String, dynamic>;
                  final name = (p['title'] ?? p['name'] ?? '').toString().toLowerCase();
                  final cat = (p['category'] ?? '').toString();
                  final active = (p['active'] ?? true) == true;
                  return name.contains(_searchQuery) && (_categoryFilter == 'All' || cat == _categoryFilter) && active;
                }).toList();
                
                if (_sortOption == 'price_low') {
                  filtered.sort((a, b) => _parsePrice(a.data() as Map<String, dynamic>).compareTo(_parsePrice(b.data() as Map<String, dynamic>)));
                } else if (_sortOption == 'price_high') {
                  filtered.sort((a, b) => _parsePrice(b.data() as Map<String, dynamic>).compareTo(_parsePrice(a.data() as Map<String, dynamic>)));
                }
                
                if (filtered.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(24.0), child: Text('No products found'));
                }
                
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index].data() as Map<String, dynamic>;
                      final productId = filtered[index].id;
                      final imageUrl = (product['imageUrl'] ?? '').toString();
                      final name = (product['title'] ?? product['name'] ?? 'Product').toString();
                      final price = _parsePrice(product);
                      
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                                  color: Colors.grey.shade200,
                                ),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, fit: BoxFit.cover,
                                        errorBuilder: (c, e, st) => Center(child: Icon(Icons.image_not_supported, color: Colors.grey.shade400)))
                                    : Center(child: Icon(Icons.image, color: Colors.grey.shade400)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('KSH ${price.toStringAsFixed(2)}',
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _addToCart(context, productId, name, price, imageUrl),
                                      child: const Text('Add', style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  double _parsePrice(Map<String, dynamic> product) {
    final p = product['price'];
    if (p is num) return p.toDouble();
    if (p is String) return double.tryParse(p) ?? 0.0;
    return 0.0;
  }

  void _addToCart(BuildContext context, String productId, String name, double price, String imageUrl) {
    final up = Provider.of<UserProvider>(context, listen: false);
    if (!RouteGuard.isLoggedIn(up)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to add items')));
      return;
    }
    
    // Add item to cart using CartProvider
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addToCart(
      productId: productId,
      name: name,
      price: price,
      imageUrl: imageUrl,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $name to cart')));
  }
}
