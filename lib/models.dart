// Models and custom exceptions for the app

abstract class AppException implements Exception {
  final int? statusCode;
  final String message;
  const AppException(this.message, {this.statusCode});
  @override
  String toString() => 'AppException($statusCode): $message';
}

class NetworkException extends AppException {
  const NetworkException(String message, {int? statusCode}) : super(message, statusCode: statusCode);
  @override
  String toString() => 'NetworkException($statusCode): $message';
}

class ParsingException extends AppException {
  const ParsingException(String message, {int? statusCode}) : super(message, statusCode: statusCode);
  @override
  String toString() => 'ParsingException($statusCode): $message';
}

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
      throw const ParsingException('Failed to parse Product');
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
      throw const ParsingException('Failed to parse ProductList');
    }
  }
}