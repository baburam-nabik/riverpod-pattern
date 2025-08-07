import 'package:dartz/dartz.dart';

import 'api_service.dart';
import 'models.dart';
// No direct dependency on AppException needed here

abstract class IApiRepository {
  Future<Either<Exception, ProductList>> getProducts();
  Future<Either<Exception, Product>> getProduct(int id);
  Future<Either<Exception, ProductList>> searchProducts(String query);
  Future<Either<Exception, Product>> addProduct(String title, String description);
  Future<Either<Exception, ProductList>> getProductsPaginated({required int limit, required int skip});
}

class ApiRepository implements IApiRepository {
  final IApiService api;
  ApiRepository(this.api);
  @override
  Future<Either<Exception, ProductList>> getProducts() =>
      api.request<ProductList>('products', parser: (json) => ProductList.fromJson(json));
  @override
  Future<Either<Exception, Product>> getProduct(int id) => api.request<Product>('products/$id', parser: (json) => Product.fromJson(json));
  @override
  Future<Either<Exception, ProductList>> searchProducts(String query) =>
      api.request<ProductList>('products/search', queryParameters: {'q': query}, parser: (json) => ProductList.fromJson(json));
  @override
  Future<Either<Exception, Product>> addProduct(String title, String description) => api.request<Product>(
    'products/add',
    method: HttpMethod.post,
    data: {'title': title, 'description': description},
    parser: (json) => Product.fromJson(json),
  );
  @override
  Future<Either<Exception, ProductList>> getProductsPaginated({required int limit, required int skip}) =>
      api.request<ProductList>('products', queryParameters: {'limit': limit, 'skip': skip}, parser: (json) => ProductList.fromJson(json));
}

abstract class IProductRepository extends IApiRepository {}

class ProductRepository extends ApiRepository implements IProductRepository {
  ProductRepository(IApiService api) : super(api);
}
