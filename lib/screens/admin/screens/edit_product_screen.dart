import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:my_shop/providers/user_provider.dart';

class EditProductScreen extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? existingData;

  const EditProductScreen({super.key, this.productId, this.existingData});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late TextEditingController _categoryController;
  bool _isLoading = false;
  bool _imageValid = true;
  static const String _fallbackImage = 'https://via.placeholder.com/800x600.png?text=No+Image';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingData?['title'] ?? widget.existingData?['name'] ?? '');
    _priceController = TextEditingController(
        text: widget.existingData?['price']?.toString() ?? '');
    _imageUrlController =
        TextEditingController(text: widget.existingData?['imageUrl'] ?? '');
    _categoryController = TextEditingController(text: widget.existingData?['category'] ?? '');

    // Update preview whenever the image URL changes
    _imageUrlController.addListener(() {
      _validateImageUrl(_imageUrlController.text.trim());
      setState(() {}); // Rebuild to update image preview
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    // Check image validity (best-effort)
    final imageUrl = _imageUrlController.text.trim();
    if (imageUrl.isNotEmpty) {
      final ok = await _checkImageExists(imageUrl);
      if (!ok) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Image not reachable'),
            content: const Text('The provided image URL could not be loaded. Use fallback image instead?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Edit URL')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Use Fallback')),
            ],
          ),
        );

        if (confirmed == true) {
          _imageUrlController.text = _fallbackImage;
        } else {
          return; // let user fix URL
        }
      }
    }

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final category = _categoryController.text.trim();

    try {
      final collection = FirebaseFirestore.instance.collection('products');

      final data = {
        'title': name,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.productId != null) {
        await collection.doc(widget.productId).update(data);
      } else {
        await collection.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.productId != null
                ? 'Product updated successfully'
                : 'Product added successfully'),
          ),
        );
        // Log admin action if possible
        try {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          if (userProvider.isAdmin) {
            await FirebaseFirestore.instance.collection('admin_logs').add({
              'action': widget.productId != null ? 'update_product' : 'create_product',
              'productId': widget.productId ?? 'new',
              'adminId': userProvider.getUser?.uid,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        } catch (_) {}
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateImageUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return false;
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkImageExists(String url) async {
    if (!_validateImageUrl(url)) return false;
    try {
      final image = NetworkImage(url);
      await precacheImage(image, context).timeout(const Duration(seconds: 5));
      if (mounted) setState(() => _imageValid = true);
      return true;
    } catch (_) {
      if (mounted) setState(() => _imageValid = false);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (!userProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unauthorized')),
        body: const Center(child: Text('You do not have permission to edit products')),
      );
    }
    final isEditing = widget.productId != null;
    final imageUrl = _imageUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Live image preview
                if (imageUrl.isNotEmpty || !_imageValid)
                  Container(
                    width: double.infinity,
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl.isNotEmpty && _imageValid ? imageUrl : _fallbackImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter price';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL (optional)'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return _validateImageUrl(value.trim()) ? null : 'Enter a valid image URL';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category (optional)'),
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProduct,
                          child: Text(isEditing ? 'Update Product' : 'Add Product'),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
