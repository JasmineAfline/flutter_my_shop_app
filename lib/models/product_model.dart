class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final int stock;
  final bool isOnSale;
  final double? salePrice; // Added for sales

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stock,
    required this.isOnSale,
    this.salePrice,
  });

  // Calculate actual price
  double get currentPrice => isOnSale ? (salePrice ?? price) : price;

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      stock: _parseInt(data['stock']),
      isOnSale: data['isOnSale'] ?? false,
      salePrice: data['salePrice']?.toDouble(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'stock': stock,
      'isOnSale': isOnSale,
      'salePrice': salePrice,
    };
  }
}