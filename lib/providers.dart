import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stateman/app_exception.dart';

import 'api_service.dart';
import 'models.dart';
import 'repository.dart';

// Providers for SOLID/Model/Exception-based networking
final apiServiceProvider = Provider<IApiService>((ref) => ApiService());
final apiRepositoryProvider = Provider<IApiRepository>((ref) => ApiRepository(ref.read(apiServiceProvider)));
final productsProvider = FutureProvider<Either<Exception, ProductList>>((ref) {
  final repo = ref.read(apiRepositoryProvider);
  return repo.getProducts();
});
final productProvider = FutureProvider.family<Either<Exception, Product>, int>((ref, id) {
  final repo = ref.read(apiRepositoryProvider);
  return repo.getProduct(id);
});
final searchProductsProvider = FutureProvider.family<Either<Exception, ProductList>, String>((ref, query) {
  final repo = ref.read(apiRepositoryProvider);
  return repo.searchProducts(query);
});
final productsOnOpenProvider = FutureProvider<Either<Exception, ProductList>>((ref) {
  final repo = ref.read(apiRepositoryProvider);
  return repo.getProducts();
});
final allProductsProvider = FutureProvider<ProductList>((ref) async {
  final repo = ref.read(apiRepositoryProvider);
  final result = await repo.getProducts();
  return result.fold((err) => ProductList(products: []), (products) => products);
});
final productDetailsProvider = FutureProvider.family<Either<Exception, Product>, int>((ref, id) {
  final repo = ref.read(apiRepositoryProvider);
  return repo.getProduct(id);
});

// Notifiers
class ProductsNotifier extends StateNotifier<AsyncValue<Either<AppException, ProductList>>> {
  final IApiRepository repo;
  ProductsNotifier(this.repo) : super(AsyncValue.data(Right(ProductList(products: []))));
  Future<void> fetchProducts() async {
    state = const AsyncValue.loading();
    final result = await repo.getProducts();
    result.fold((err) => state = AsyncValue.error(err, StackTrace.current), (products) => state = AsyncValue.data(Right(products)));
  }
}

final productsNotifierProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<Either<Exception, ProductList>>>(
  (ref) => ProductsNotifier(ref.read(apiRepositoryProvider)),
);

class AddProductNotifier extends StateNotifier<AsyncValue<Either<Exception, Product>>> {
  final IApiRepository repo;
  AddProductNotifier(this.repo) : super(AsyncValue.data(Right(Product(id: 0, title: '', description: ''))));
  Future<void> addProduct(String title, String description) async {
    state = const AsyncValue.loading();
    final result = await repo.addProduct(title, description);
    state = AsyncValue.data(result);
  }
}

final addProductNotifierProvider = StateNotifierProvider<AddProductNotifier, AsyncValue<Either<Exception, Product>>>(
  (ref) => AddProductNotifier(ref.read(apiRepositoryProvider)),
);

class PaginationNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final IApiRepository repo;
  static const int pageSize = 10;
  int _skip = 0;
  bool _hasMore = true;
  List<Product> _products = [];
  PaginationNotifier(this.repo) : super(const AsyncValue.loading()) {
    fetchMore();
  }
  bool get hasMore => _hasMore;
  Future<void> fetchMore() async {
    if (!_hasMore) return;
    state = const AsyncValue.loading();
    final result = await repo.getProductsPaginated(limit: pageSize, skip: _skip);
    result.fold((err) => state = AsyncValue.error(err, StackTrace.current), (productList) {
      if (productList.products.length < pageSize) _hasMore = false;
      _products.addAll(productList.products);
      _skip += productList.products.length;
      state = AsyncValue.data(List.from(_products));
    });
  }
}

final paginationNotifierProvider = StateNotifierProvider<PaginationNotifier, AsyncValue<List<Product>>>(
  (ref) => PaginationNotifier(ref.read(apiRepositoryProvider)),
);

class OptimisticUpdateNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final IApiRepository repo;
  OptimisticUpdateNotifier(this.repo) : super(const AsyncValue.loading()) {
    _fetchProducts();
  }
  List<Product> _products = [];
  Future<void> _fetchProducts() async {
    final result = await repo.getProducts();
    result.fold((err) => state = AsyncValue.error(err, StackTrace.current), (products) {
      _products = products.products;
      state = AsyncValue.data(List.from(_products));
    });
  }

  Future<void> updateProductTitle(int id, String newTitle) async {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    final oldProduct = _products[idx];
    _products[idx] = Product(id: oldProduct.id, title: newTitle, description: oldProduct.description);
    state = AsyncValue.data(List.from(_products));
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

final optimisticUpdateNotifierProvider = StateNotifierProvider<OptimisticUpdateNotifier, AsyncValue<List<Product>>>(
  (ref) => OptimisticUpdateNotifier(ref.read(apiRepositoryProvider)),
);
