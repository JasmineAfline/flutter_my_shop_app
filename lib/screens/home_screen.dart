import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:my_shop/models/product_model.dart';
import 'package:my_shop/providers/cart_provider.dart';
import 'package:my_shop/widgets/product_card.dart';
import 'package:my_shop/widgets/category_chip.dart';

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

  // --- UI HELPER METHODS ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      ),
    );
  }

  Widget _buildCategoryList() {
    final categories = ['All', 'Electronics', 'Clothing', 'Shoes', 'Home'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return CategoryChip(
            label: categories[index],
            isSelected: _categoryFilter == categories[index],
            onTap: () => setState(() => _categoryFilter = categories[index]),
          );
        },
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            "Sort by: ",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          DropdownButton<String>(
            value: _sortOption,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'newest', child: Text('Newest')),
              DropdownMenuItem(value: 'price_low', child: Text('Price: Low')),
              DropdownMenuItem(value: 'price_high', child: Text('Price: High')),
            ],
            onChanged: (v) => setState(() => _sortOption = v ?? 'newest'),
          ),
        ],
      ),
    );
  }

  // --- MAIN BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Shop',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) => Badge(
              // It should be cart.itemCount (matching the getter we just added)
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryList(),
          _buildSortDropdown(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                // 1. Filtering Logic
                var filteredDocs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString();

                  bool matchesSearch = title.contains(_searchQuery);
                  bool matchesCategory =
                      _categoryFilter == 'All' || category == _categoryFilter;

                  return matchesSearch && matchesCategory;
                }).toList();

                // 2. Sorting Logic
                if (_sortOption == 'price_low') {
                  filteredDocs.sort(
                    (a, b) => (a['price'] as num).toDouble().compareTo(
                      (b['price'] as num).toDouble(),
                    ),
                  );
                } else if (_sortOption == 'price_high') {
                  filteredDocs.sort(
                    (a, b) => (b['price'] as num).toDouble().compareTo(
                      (a['price'] as num).toDouble(),
                    ),
                  );
                }

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('No products found matching your search.'),
                  );
                }

                // 3. The Grid View
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68, // Adjusted for ProductCard content
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    final product = Product.fromFirestore(
                      data,
                      filteredDocs[index].id,
                    );

                    return ProductCard(product: product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
