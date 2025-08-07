import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

// Custom Exceptions
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}

class ParsingException implements Exception {
  final String message;
  ParsingException(this.message);
  @override
  String toString() => 'ParsingException: $message';
}

// Models
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
      throw ParsingException('Failed to parse Product: $e');
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
      throw ParsingException('Failed to parse ProductList: $e');
    }
  }
}

// SOLID: Abstract interface
abstract class IApiService {
  Future<Either<Exception, ProductList>> getProducts();
  Future<Either<Exception, Product>> getProduct(int id);
  Future<Either<Exception, ProductList>> searchProducts(String query);
  Future<Either<String, Map<String, dynamic>>> addProduct({required String title, required String description});
  Future<Either<String, List<dynamic>>> getProductsPaginated({required int limit, required int skip});
  Future<Either<String, Map<String, dynamic>>> getProductWithReviews(int id);
  Future<Either<String, Map<String, dynamic>>> updateProduct(int id, Map<String, dynamic> data);
}

class ApiService implements IApiService {
  final Dio _dio;
  ApiService()
      : _dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com/')) {
    _dio.interceptors.add(TalkerDioLogger());
  }

  @override
  Future<Either<Exception, ProductList>> getProducts() async {
    try {
      final response = await _dio.get('products');
      return right(ProductList.fromJson(response.data));
    } on DioException catch (e) {
      return left(NetworkException(e.message ?? 'Network error'));
    } on ParsingException catch (e) {
      return left(e);
    } catch (e) {
      return left(NetworkException(e.toString()));
    }
  }

  @override
  Future<Either<Exception, Product>> getProduct(int id) async {
    try {
      final response = await _dio.get('products/$id');
      return right(Product.fromJson(response.data));
    } on DioException catch (e) {
      return left(NetworkException(e.message ?? 'Network error'));
    } on ParsingException catch (e) {
      return left(e);
    } catch (e) {
      return left(NetworkException(e.toString()));
    }
  }

  @override
  Future<Either<Exception, ProductList>> searchProducts(String query) async {
    try {
      final response = await _dio.get('products/search', queryParameters: {'q': query});
      return right(ProductList.fromJson(response.data));
    } on DioException catch (e) {
      return left(NetworkException(e.message ?? 'Network error'));
    } on ParsingException catch (e) {
      return left(e);
    } catch (e) {
      return left(NetworkException(e.toString()));
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> addProduct({required String title, required String description}) async {
    try {
      final response = await _dio.post('products/add', data: {
        'title': title,
        'description': description,
      });
      return right(response.data as Map<String, dynamic>);
    } catch (e) {
      return left(e.toString());
    }
  }

  @override
  Future<Either<String, List<dynamic>>> getProductsPaginated({required int limit, required int skip}) async {
    try {
      final response = await _dio.get('products', queryParameters: {'limit': limit, 'skip': skip});
      return right(response.data['products'] as List<dynamic>);
    } catch (e) {
      return left(e.toString());
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> getProductWithReviews(int id) async {
    try {
      final productResp = await _dio.get('products/$id');
      final reviewsResp = await _dio.get('products/$id/reviews'); // DummyJSON does not have this, but for demo, simulate
      final product = productResp.data as Map<String, dynamic>;
      product['reviews'] = reviewsResp.data['reviews'] ?? [];
      return right(product);
    } catch (e) {
      return left(e.toString());
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('products/$id', data: data);
      return right(response.data as Map<String, dynamic>);
    } catch (e) {
      return left(e.toString());
    }
  }
}