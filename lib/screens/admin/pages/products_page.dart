import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_shop/services/cloudinary_helper.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _searchQuery = '';
  String _categoryFilter = 'All';
  final List<String> _categories = ['All', 'Electronics', 'Clothing', 'Home', 'Sports', 'Books'];

  // parsing helpers to avoid NoSuchMethod when types come back as strings
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _categoryFilter,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _categoryFilter = v ?? 'All'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddProductDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Product', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Products Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

                // Filter by search
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final name = (data['title'] ?? data['name'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                // Filter by category
                if (_categoryFilter != 'All') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['category'] ?? '').toString() == _categoryFilter;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Image')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Stock')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final id = doc.id;
                      final imageUrl = (data['imageUrl'] ?? '').toString();
                      final name = (data['title'] ?? data['name'] ?? 'N/A').toString();
                        final price = _toDouble((data['price'] ?? 0));
                        final stock = _toInt((data['stock'] ?? 0));
                        final category = (data['category'] ?? 'N/A').toString();
                        final status = stock > 0 ? 'In Stock' : 'Out of Stock';

                      return DataRow(cells: [
                        DataCell(
                          imageUrl.isNotEmpty
                              ? SizedBox.square(
                                  dimension: 50,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                                  ),
                                )
                              : const Icon(Icons.image),
                        ),
                        DataCell(Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        DataCell(Text('KSH ${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}')),
                        DataCell(Text(stock.toString())),
                        DataCell(ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(category, maxLines: 1, overflow: TextOverflow.ellipsis),
                        )),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: stock > 0 ? const Color(0xFF00D4AA).withOpacity(0.1) : const Color(0xFFFF0000).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(status, style: TextStyle(color: stock > 0 ? const Color(0xFF00D4AA) : const Color(0xFFFF0000), fontWeight: FontWeight.w600)),
                          ),
                        ),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit, color: Color(0xFF6C63FF), size: 18),
                                onPressed: () => _showEditProductDialog(id, data),
                                tooltip: 'Edit',
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                onPressed: () => _showDeleteConfirm(id),
                                tooltip: 'Delete',
                              ),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
        String? uploadedUrl;
        bool isUploading = false;
        final itemsList = _categories.skip(1).toList();
    String categoryValue = 'Electronics';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
              const SizedBox(height: 12),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
                  // Image picker + upload
                  StatefulBuilder(builder: (context, setState) {
                    return Column(
                      children: [
                        if (uploadedUrl != null)
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(uploadedUrl!, height: 120, fit: BoxFit.cover))
                        else
                          Container(height: 120, color: Colors.grey[200], child: const Center(child: Icon(Icons.image, size: 40))),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                                if (file == null) return;
                                setState(() { isUploading = true; });
                                final url = await CloudinaryHelper.uploadImage(file.path);
                                setState(() { uploadedUrl = url; isUploading = false; });
                              },
                              icon: const Icon(Icons.upload_file),
                              label: Text(isUploading ? 'Uploading...' : 'Pick & Upload'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                            ),
                            const SizedBox(width: 12),
                            if (uploadedUrl != null)
                              TextButton(onPressed: () => setState(() { uploadedUrl = null; }), child: const Text('Remove'))
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),
              DropdownButtonFormField<String>(
                    value: itemsList.contains(categoryValue) ? categoryValue : (itemsList.isNotEmpty ? itemsList.first : null),
                    items: itemsList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => categoryValue = v ?? (itemsList.isNotEmpty ? itemsList.first : ''),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('products').add({
                  'title': nameController.text,
                  'name': nameController.text,
                  'price': double.parse(priceController.text),
                  'stock': int.parse(stockController.text),
                      'imageUrl': uploadedUrl ?? '',
                  'category': categoryValue,
                  'createdAt': Timestamp.now(),
                  'updatedAt': Timestamp.now(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(String id, Map<String, dynamic> product) {
    final nameController = TextEditingController(text: product['title'] ?? product['name'] ?? '');
    final priceController = TextEditingController(text: product['price']?.toString() ?? '');
    final stockController = TextEditingController(text: product['stock']?.toString() ?? '');
    String? uploadedUrl = (product['imageUrl'] ?? '')?.toString().isNotEmpty == true ? product['imageUrl'] : null;
    bool isUploading = false;
    final itemsList = _categories.skip(1).toList();
    String categoryValue = itemsList.contains(product['category']) ? product['category'] : (itemsList.isNotEmpty ? itemsList.first : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
              const SizedBox(height: 12),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              // Image picker + upload
              StatefulBuilder(builder: (context, setState) {
                return Column(
                  children: [
                    if (uploadedUrl != null)
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(uploadedUrl!, height: 120, fit: BoxFit.cover))
                    else
                      Container(height: 120, color: Colors.grey[200], child: const Center(child: Icon(Icons.image, size: 40))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                            if (file == null) return;
                            setState(() { isUploading = true; });
                            final url = await CloudinaryHelper.uploadImage(file.path);
                            setState(() { uploadedUrl = url; isUploading = false; });
                          },
                          icon: const Icon(Icons.upload_file),
                          label: Text(isUploading ? 'Uploading...' : 'Pick & Upload'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                        ),
                        const SizedBox(width: 12),
                        if (uploadedUrl != null)
                          TextButton(onPressed: () => setState(() { uploadedUrl = null; }), child: const Text('Remove'))
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
              DropdownButtonFormField<String>(
                value: itemsList.contains(categoryValue) ? categoryValue : (itemsList.isNotEmpty ? itemsList.first : null),
                items: itemsList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => categoryValue = v ?? (itemsList.isNotEmpty ? itemsList.first : ''),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('products').doc(id).update({
                  'title': nameController.text,
                  'name': nameController.text,
                  'price': double.parse(priceController.text),
                  'stock': int.parse(stockController.text),
                  'imageUrl': uploadedUrl ?? product['imageUrl'] ?? '',
                  'category': categoryValue,
                  'updatedAt': Timestamp.now(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('products').doc(id).delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
