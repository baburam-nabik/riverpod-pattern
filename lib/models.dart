// Models only

class Product {
  final int id;
  final String title;
  final String description;
  Product({required this.id, required this.title, required this.description});
  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
      );
    } catch (e) {
      throw const FormatException('Failed to parse Product');
    }
  }
}

class ProductList {
  final List<Product> products;
  ProductList({required this.products});
  factory ProductList.fromJson(Map<String, dynamic> json) {
    try {
      final products = (json['products'] as List)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
      return ProductList(products: products);
    } catch (e) {
      throw const FormatException('Failed to parse ProductList');
    }
  }
}