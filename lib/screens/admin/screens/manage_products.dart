import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:my_shop/providers/user_provider.dart';
import 'edit_product_screen.dart';

class ManageProducts extends StatefulWidget {
  static const routeName = '/ManageProducts';
  const ManageProducts({super.key});

  @override
  State<ManageProducts> createState() => _ManageProductsState();
}

class _ManageProductsState extends State<ManageProducts> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'newest';
  String _categoryFilter = 'All';
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  int _pageSize = 10;
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (!userProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 72, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Unauthorized', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('You do not have permission to view this page.'),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _openInlineSearch(context),
          ),
          IconButton(
            icon: Icon(_selectionMode ? Icons.close : Icons.check_box_outline_blank),
            onPressed: () {
              setState(() {
                _selectionMode = !_selectionMode;
                if (!_selectionMode) _selectedIds.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProductScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No products yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Add your first product to get started', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          // Work on a mutable list for client-side processing
          List<QueryDocumentSnapshot> list = List.from(docs);

          // Build categories set
          final categories = <String>{'All'};
          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;
            final cat = (data['category'] ?? '').toString();
            if (cat.isNotEmpty) categories.add(cat);
          }

          // Apply category filter
          if (_categoryFilter != 'All') {
            list = list.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return (data['category'] ?? '').toString().toLowerCase() == _categoryFilter.toLowerCase();
            }).toList();
          }

          // Apply search
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            list = list.where((d) {
              final data = d.data() as Map<String, dynamic>;
              final name = (data['title'] ?? data['name'] ?? '').toString().toLowerCase();
              return name.contains(q);
            }).toList();
          }

          // Apply sort
          if (_sortOption == 'price_low') {
            list.sort((a, b) => _parsePrice(a.data() as Map<String, dynamic>).compareTo(_parsePrice(b.data() as Map<String, dynamic>)));
          } else if (_sortOption == 'price_high') {
            list.sort((a, b) => _parsePrice(b.data() as Map<String, dynamic>).compareTo(_parsePrice(a.data() as Map<String, dynamic>)));
          } else {
            // newest
            list.sort((a, b) {
              final aTs = (a.data() as Map<String, dynamic>)['createdAt'];
              final bTs = (b.data() as Map<String, dynamic>)['createdAt'];
              if (aTs is Timestamp && bTs is Timestamp) return bTs.compareTo(aTs);
              return 0;
            });
          }

          // Pagination calculations
          final totalItems = list.length;
          final totalPages = (totalItems / _pageSize).ceil().clamp(1, 9999);
          final start = _currentPage * _pageSize;
          final paged = list.skip(start).take(_pageSize).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search products by name', border: OutlineInputBorder()),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sortOption,
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Newest')),
                        DropdownMenuItem(value: 'price_low', child: Text('Price ↑')),
                        DropdownMenuItem(value: 'price_high', child: Text('Price ↓')),
                      ],
                      onChanged: (v) => setState(() => _sortOption = v ?? 'newest'),
                    ),
                    const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _categoryFilter,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _categoryFilter = v ?? 'All'),
                  ),
                  ],
                ),
              ),
              if (_selectionMode && _selectedIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Text('${_selectedIds.length} selected'),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: _confirmBulkDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Selected'),
                    ),
                  ]),
                ),
              Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: paged.length,
                        itemBuilder: (context, index) {
                          final d = paged[index];
                          final product = d.data() as Map<String, dynamic>;
                          final productId = d.id;
                          final imageUrl = (product['imageUrl'] ?? '').toString();
                          final name = (product['title'] ?? product['name'] ?? 'Unnamed Product').toString();
                          final price = _parsePrice(product);
                          final active = (product['active'] ?? true) == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.image_not_supported),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.image),
                                    ),
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'KSH ${price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: _selectionMode
                                  ? Checkbox(
                                      value: _selectedIds.contains(productId),
                                      onChanged: (v) {
                                        setState(() {
                                          if (v == true) {
                                            _selectedIds.add(productId);
                                          } else {
                                            _selectedIds.remove(productId);
                                          }
                                        });
                                      },
                                    )
                                  : SizedBox(
                                      width: 160,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Switch(
                                            value: active,
                                            onChanged: (val) => _toggleProductActive(productId, val),
                                          ),
                                          PopupMenuButton(
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Edit'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            onSelected: (value) {
                                              if (value == 'delete') {
                                                _deleteProduct(productId);
                                              } else if (value == 'edit') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => EditProductScreen(
                                                      productId: productId,
                                                      existingData: product,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
              // Pagination controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('Showing ${start + 1}-${(start + paged.length)} of ${totalItems}'),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _pageSize,
                      items: const [5, 10, 20, 50].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _pageSize = v ?? 10;
                          _currentPage = 0;
                        });
                      },
                    ),
                    IconButton(
                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      onPressed: (_currentPage + 1) < totalPages ? () => setState(() => _currentPage++) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openInlineSearch(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use the search box to filter results')));
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('products').doc(productId).delete();
        // log admin action
        try {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          if (userProvider.isAdmin) {
            await FirebaseFirestore.instance.collection('admin_logs').add({
              'action': 'delete_product',
              'productId': productId,
              'adminId': userProvider.getUser?.uid,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        } catch (_) {}
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting product: $e')));
      }
    }
  }

  double _parsePrice(Map<String, dynamic> product) {
    final p = product['price'];
    if (p is num) return p.toDouble();
    if (p is String) return double.tryParse(p) ?? 0.0;
    return 0.0;
  }

  Future<void> _confirmBulkDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Delete ${_selectedIds.length} selected products?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        final ref = FirebaseFirestore.instance.collection('products').doc(id);
        batch.delete(ref);
      }
      await batch.commit();
      // log admin action
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.isAdmin) {
          await FirebaseFirestore.instance.collection('admin_logs').add({
            'action': 'bulk_delete_products',
            'productIds': _selectedIds.toList(),
            'adminId': userProvider.getUser?.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected products deleted')));
        setState(() {
          _selectedIds.clear();
          _selectionMode = false;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
    }
  }

  Future<void> _toggleProductActive(String productId, bool active) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).update({'active': active});
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.isAdmin) {
          await FirebaseFirestore.instance.collection('admin_logs').add({
            'action': active ? 'enable_product' : 'disable_product',
            'productId': productId,
            'adminId': userProvider.getUser?.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating product: $e')));
    }
  }
}
