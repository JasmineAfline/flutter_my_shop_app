class CartItem {
  final String productId;
  final String title;
  final int quantity;
  final double price;
  final String imageUrl;

  CartItem({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'],
      title: map['title'],
      quantity: map['quantity'],
      price: map['price'].toDouble(),
      imageUrl: map['imageUrl'],
    );
  }
}