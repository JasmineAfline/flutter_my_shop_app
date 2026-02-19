// lib/features/admin/screens/product_form_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.productData});

  static const String routeName = '/admin/product-form';

  final Map<String, dynamic>? productData;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CollectionReference productsCollection = FirebaseFirestore.instance
      .collection('products');

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;

  final ImagePicker _picker = ImagePicker();

  /// Mobile image
  Uint8List? _webImageBytes;
  XFile? _selectedImage;

  bool _isUploading = false;
  bool get isEditMode => widget.productData != null;

  // Cloudinary config
  static const String cloudName = 'ddvgqblf6';
  static const String uploadPreset = 'mobimart';

  // Predefined categories
  final List<String> _categories = [
    'Electronics',
    'Fashion',
    'Home',
    'Books',
    'Sports',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.productData?['name'] ?? '',
    );
    _priceController = TextEditingController(
      text: widget.productData?['price']?.toString() ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.productData?['category'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.productData?['description'] ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.productData?['imageUrl'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // ================= IMAGE PICKER =================
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (kIsWeb) {
      _webImageBytes = await picked.readAsBytes();
      _selectedImage = null;
    } else {
      _selectedImage = picked;
      _webImageBytes = null;
    }

    _imageUrlController.clear();
    setState(() {});
  }

  // ================= UPLOAD TO CLOUDINARY =================
  Future<String?> _uploadToCloudinary() async {
    try {
      setState(() => _isUploading = true);

      Uri url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      http.MultipartRequest request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;

      if (kIsWeb && _webImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _webImageBytes!,
            filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      } else if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', _selectedImage!.path),
        );
      } else {
        setState(() => _isUploading = false);
        return null;
      }

      http.StreamedResponse response = await request.send();
      final respStr = await response.stream.bytesToString();
      final Map<String, dynamic> data = json.decode(respStr);

      setState(() => _isUploading = false);

      if (response.statusCode == 200 && data.containsKey('secure_url')) {
        return data['secure_url'];
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cloudinary upload failed')),
          );
        }
        return null;
      }
    } catch (e) {
      setState(() => _isUploading = false);
      debugPrint('Cloudinary upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image upload failed')));
      }
      return null;
    }
  }

  // ================= SUBMIT FORM =================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    String imageUrl = _imageUrlController.text.trim();

    try {
      if (_selectedImage != null || _webImageBytes != null) {
        final uploadedUrl = await _uploadToCloudinary();
        if (uploadedUrl == null) return;
        imageUrl = uploadedUrl;
      }

      final product = {
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'category': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
      };

      if (isEditMode) {
        await productsCollection.doc(widget.productData!['id']).update(product);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Product updated')));
        }
      } else {
        await productsCollection.add(product);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Product added')));
        }
      }

      if (mounted) Navigator.pop(context, product);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ================= IMAGE PREVIEW =================
  Widget _buildImagePreview() {
    if (kIsWeb && _webImageBytes != null) {
      return Image.memory(_webImageBytes!, height: 150, fit: BoxFit.cover);
    }
    if (_selectedImage != null) {
      return Image.file(
        File(_selectedImage!.path),
        height: 150,
        fit: BoxFit.cover,
      );
    }
    if (_imageUrlController.text.isNotEmpty) {
      return Image.network(
        _imageUrlController.text,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
      );
    }
    return const SizedBox.shrink();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Product' : 'Add Product'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: 'KES ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Price is required' : null,
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _categoryController.text.isNotEmpty
                    ? _categoryController.text
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() => _categoryController.text = val ?? '');
                },
                validator: (v) =>
                    v == null || v.isEmpty ? 'Category is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Image URL input
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  prefixIcon: Icon(Icons.link),
                ),
                onChanged: (_) {
                  if (_imageUrlController.text.isNotEmpty) {
                    setState(() {
                      _selectedImage = null;
                      _webImageBytes = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Image pick button
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose Image from Gallery'),
              ),
              const SizedBox(height: 16),

              // Preview
              _buildImagePreview(),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: _isUploading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(isEditMode ? 'Save Changes' : 'Add Product'),
                  onPressed: _isUploading ? null : _submitForm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
