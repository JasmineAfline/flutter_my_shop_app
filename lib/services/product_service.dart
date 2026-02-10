import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_shop/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'products';

  // 🔹 ADD PRODUCT
  Future<void> addProduct(Product product) async {
    await _firestore.collection(_collection).add(product.toMap());
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
    await _firestore
        .collection(_collection)
        .doc(product.id)
        .update(product.toMap());
  }

  // 🔹 DELETE PRODUCT
  Future<void> deleteProduct(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
