import 'package:flutter/material.dart';
import 'edit_product_screen.dart';

/// Wrapper screen that simply routes to the unified EditProductScreen for adding new products.
/// This maintains backward compatibility with existing navigation routes.
class AddProductScreen extends StatelessWidget {
  static const routeName = '/addProduct';

  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EditProductScreen();
  }
}
