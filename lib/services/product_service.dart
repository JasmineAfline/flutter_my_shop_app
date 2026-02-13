import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_shop/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'products';

  // 🔹 ADD PRODUCT
  Future<void> addProduct(Product product) async {
    try {
      await _firestore.collection(_collection).add({
        ...product.toMap(),
        'createdAt': Timestamp.now(),
      });

      print("✅ PRODUCT ADDED SUCCESSFULLY");
    } catch (e) {
      print("❌ ERROR ADDING PRODUCT: $e");
      rethrow;
    }
  }

  // 🔹 GET PRODUCTS STREAM
  Stream<List<Product>> getProducts() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // 🔹 UPDATE PRODUCT
  Future<void> updateProduct(Product product) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(product.id)
          .update(product.toMap());
    } catch (e) {
      print("❌ ERROR UPDATING PRODUCT: $e");
      rethrow;
    }
  }

  // 🔹 DELETE PRODUCT
  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print("❌ ERROR DELETING PRODUCT: $e");
      rethrow;
    }
  }
}
