import 'package:flutter/material.dart';
import 'package:my_shop/models/product_model.dart';
import 'package:my_shop/services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

  bool isLoading = false;

  final ProductService _productService = ProductService();

  Future<void> addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final product = Product(
        id: '',
        title: titleController.text,
        description: descController.text,
        price: double.parse(priceController.text),
        imageUrl: imageController.text,
        category: categoryController.text,
        stock: int.parse(stockController.text),
        isOnSale: false,
      );

      await _productService.addProduct(product);

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextFormField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : addProduct,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
