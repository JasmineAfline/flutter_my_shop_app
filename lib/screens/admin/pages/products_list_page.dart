import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/add_product_screen.dart' as addProduct;

/// Products management page - displays list of products with edit/delete options
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Delete a product with confirmation dialog
  Future<void> _deleteProduct(String productId, String productName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore.collection('products').doc(productId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting product: $e')),
      );
    }
  }

  /// Navigate to ProductFormScreen for editing
  void _editProduct(String productId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => addProduct.ProductFormScreen(productData: data),
      ),
    );
  }

  /// Navigate to ProductFormScreen for creating new product
  void _addNewProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const addProduct.ProductFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Management'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewProduct,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('products').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No products yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _addNewProduct,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Product'),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final productId = product.id;
              final data = product.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Untitled';
              final price = data['price'] ?? 0.0;
              final imageUrl = data['imageUrl'];
              final category = data['category'] ?? 'Other';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: ListTile(
                  leading: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.image),
                        ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'KSH ${price.toStringAsFixed(2)} • $category',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editProduct(productId, data),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(productId, title),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
