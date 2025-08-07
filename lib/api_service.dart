import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'models.dart';

abstract class IApiService {
  Future<Either<Exception, ProductList>> getProducts();
  Future<Either<Exception, Product>> getProduct(int id);
  Future<Either<Exception, ProductList>> searchProducts(String query);
  Future<Either<Exception, Product>> addProduct(String title, String description);
  Future<Either<Exception, ProductList>> getProductsPaginated({required int limit, required int skip});
  // TODO: ProductWithReviews model for chained example
}

class ApiService implements IApiService {
  final Dio _dio;
  ApiService([Dio? dio]) : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://dummyjson.com/'));

  @override
  Future<Either<Exception, ProductList>> getProducts() async {
    try {
      final response = await _dio.get('products');
      return right(ProductList.fromJson(response.data));
    } on DioException catch (e) {
      return left(NetworkException(e.message ?? 'Network error', statusCode: e.response?.statusCode));
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
      return left(NetworkException(e.message ?? 'Network error', statusCode: e.response?.statusCode));
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
      return left(NetworkException(e.message ?? 'Network error', statusCode: e.response?.statusCode));
    } on ParsingException catch (e) {
      return left(e);
    } catch (e) {
      return left(NetworkException(e.toString()));
    }
  }

  @override
  Future<Either<Exception, Product>> addProduct(String title, String description) async {
    try {
      final response = await _dio.post('products/add', data: {'title': title, 'description': description});
      return right(Product.fromJson(response.data));
    } on DioException catch (e) {
      return left(NetworkException(e.message ?? 'Network error', statusCode: e.response?.statusCode));
    } on ParsingException catch (e) {
      return left(e);
    } catch (e) {
      return left(NetworkException(e.toString()));
    }
  }

  @override
  Future<Either<Exception, ProductList>> getProductsPaginated({required int limit, required int skip}) async {
    try {
      final response = await _dio.get('products', queryParameters: {'limit': limit, 'skip': skip});
      return right(ProductList.fromJson(response.data));
    } on DioException catch (e) {
      return left(NetworkException(e.message ?? 'Network error', statusCode: e.response?.statusCode));
    } on ParsingException catch (e) {
      return left(e);
    } catch (e) {
      return left(NetworkException(e.toString()));
    }
  }
}

abstract class IProductRepository {
  Future<Either<Exception, ProductList>> getProducts();
  Future<Either<Exception, Product>> getProduct(int id);
  Future<Either<Exception, ProductList>> searchProducts(String query);
  Future<Either<Exception, Product>> addProduct(String title, String description);
  Future<Either<Exception, ProductList>> getProductsPaginated({required int limit, required int skip});
}

class ProductRepository implements IProductRepository {
  final IApiService api;
  ProductRepository(this.api);
  @override
  Future<Either<Exception, ProductList>> getProducts() => api.getProducts();
  @override
  Future<Either<Exception, Product>> getProduct(int id) => api.getProduct(id);
  @override
  Future<Either<Exception, ProductList>> searchProducts(String query) => api.searchProducts(query);
  @override
  Future<Either<Exception, Product>> addProduct(String title, String description) => api.addProduct(title, description);
  @override
  Future<Either<Exception, ProductList>> getProductsPaginated({required int limit, required int skip}) => api.getProductsPaginated(limit: limit, skip: skip);
}