import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stateman/api_service.dart';
import 'package:stateman/models.dart';
import 'package:stateman/repository.dart';
import 'package:stateman/app_exception.dart';
import 'package:dartz/dartz.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SampleHomeScreen(),
    );
  }
}

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

// Helper to extract user-friendly error messages
defaultErrorMessage(Exception e) {
  if (e is AppException) {
    return '${e.runtimeType == AppException ? 'Error' : e.runtimeType}${e.statusCode != null ? ' (code: ${e.statusCode})' : ''}: ${e.message}';
  }
  return 'Unexpected error: ${e.toString()}';
}

// --- Riverpod API Patterns (Model-based) ---

// 1. API Call on Button Tap
class ProductsNotifier extends StateNotifier<AsyncValue<Either<Exception, ProductList>>> {
  final IApiRepository repo;
  ProductsNotifier(this.repo) : super(AsyncValue.data(Right(ProductList(products: []))));
  Future<void> fetchProducts() async {
    state = const AsyncValue.loading();
    final result = await repo.getProducts();
    state = AsyncValue.data(result);
  }
}
final productsNotifierProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<Either<Exception, ProductList>>>(
  (ref) => ProductsNotifier(ref.read(apiRepositoryProvider)),
);
class ApiOnTapScreen extends ConsumerWidget {
  const ApiOnTapScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productsNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('API on Tap')),
      body: productsState.when(
        data: (result) => result.fold(
          (err) => Center(child: Text(defaultErrorMessage(err), style: const TextStyle(color: Colors.red))),
          (productList) => productList.products.isEmpty
              ? const Center(child: Text('Press the button to load products'))
              : ListView.builder(
                  itemCount: productList.products.length,
                  itemBuilder: (context, idx) => ListTile(
                    title: Text(productList.products[idx].title),
                  ),
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(defaultErrorMessage(e is Exception ? e : Exception(e)), style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(productsNotifierProvider.notifier).fetchProducts(),
        child: const Icon(Icons.download),
      ),
    );
  }
}

// 2. API Call on Screen Open
final productsOnOpenProvider = FutureProvider<Either<Exception, ProductList>>((ref) {
  final repo = ref.read(apiRepositoryProvider);
  return repo.getProducts();
});
class ApiOnOpenScreen extends ConsumerWidget {
  const ApiOnOpenScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productsOnOpenProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('API on Open')),
      body: productsState.when(
        data: (result) => result.fold(
          (err) => Center(child: Text(defaultErrorMessage(err), style: const TextStyle(color: Colors.red))),
          (productList) => ListView.builder(
            itemCount: productList.products.length,
            itemBuilder: (context, idx) => ListTile(
              title: Text(productList.products[idx].title),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(defaultErrorMessage(e is Exception ? e : Exception(e)), style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

// 3. Mutation (Add Product)
class AddProductNotifier extends StateNotifier<AsyncValue<Either<Exception, Product>>> {
  final IApiRepository repo;
  AddProductNotifier(this.repo)
      : super(AsyncValue.data(Right(Product(id: 0, title: '', description: ''))));
  Future<void> addProduct(String title, String description) async {
    state = const AsyncValue.loading();
    final result = await repo.addProduct(title, description);
    state = AsyncValue.data(result);
  }
}
final addProductNotifierProvider = StateNotifierProvider<AddProductNotifier, AsyncValue<Either<Exception, Product>>>(
  (ref) => AddProductNotifier(ref.read(apiRepositoryProvider)),
);
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});
  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}
class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  @override
  Widget build(BuildContext context) {
    final addState = ref.watch(addProductNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Title'),
                    onChanged: (val) => _title = val,
                    validator: (val) => val == null || val.isEmpty ? 'Enter title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    onChanged: (val) => _description = val,
                    validator: (val) => val == null || val.isEmpty ? 'Enter description' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: addState.isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              ref.read(addProductNotifierProvider.notifier).addProduct(_title, _description);
                            }
                          },
                    child: const Text('Add Product'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: addState.when(
                data: (result) => result.fold(
                  (err) => Text(defaultErrorMessage(err), style: const TextStyle(color: Colors.red)),
                  (product) => product.id == 0
                      ? const Text('Fill the form and submit to add a product')
                      : Text('Product added: ${product.title}', style: const TextStyle(color: Colors.green)),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(defaultErrorMessage(e is Exception ? e : Exception(e)), style: const TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. Pagination (Load More Products)
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
    result.fold(
      (err) => state = AsyncValue.error(err, StackTrace.current),
      (productList) {
        if (productList.products.length < pageSize) _hasMore = false;
        _products.addAll(productList.products);
        _skip += productList.products.length;
        state = AsyncValue.data(List.from(_products));
      },
    );
  }
}
final paginationNotifierProvider = StateNotifierProvider<PaginationNotifier, AsyncValue<List<Product>>>(
  (ref) => PaginationNotifier(ref.read(apiRepositoryProvider)),
);
class PaginationScreen extends ConsumerWidget {
  const PaginationScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paginationNotifierProvider);
    final notifier = ref.read(paginationNotifierProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Pagination')),
      body: state.when(
        data: (products) => NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (notifier.hasMore &&
                scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
              notifier.fetchMore();
            }
            return false;
          },
          child: ListView.builder(
            itemCount: products.length + (notifier.hasMore ? 1 : 0),
            itemBuilder: (context, idx) {
              if (idx < products.length) {
                return ListTile(title: Text(products[idx].title));
              } else {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(defaultErrorMessage(e is Exception ? e : Exception(e)), style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

// 5. Chained Providers (select product, then fetch details)
final allProductsProvider = FutureProvider<ProductList>((ref) async {
  final repo = ref.read(apiRepositoryProvider);
  final result = await repo.getProducts();
  return result.fold((err) => ProductList(products: []), (products) => products);
});
final productDetailsProvider = FutureProvider.family<Either<Exception, Product>, int>((ref, id) {
  final repo = ref.read(apiRepositoryProvider);
  return repo.getProduct(id);
});
class ChainedProvidersScreen extends ConsumerStatefulWidget {
  const ChainedProvidersScreen({super.key});
  @override
  ConsumerState<ChainedProvidersScreen> createState() => _ChainedProvidersScreenState();
}
class _ChainedProvidersScreenState extends ConsumerState<ChainedProvidersScreen> {
  int? _selectedId;
  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(allProductsProvider);
    final productDetails = _selectedId == null ? null : ref.watch(productDetailsProvider(_selectedId!));
    return Scaffold(
      appBar: AppBar(title: const Text('Chained Providers')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            allProducts.when(
              data: (products) => DropdownButton<int>(
                hint: const Text('Select Product'),
                value: _selectedId,
                items: products.products.map<DropdownMenuItem<int>>((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.title),
                )).toList(),
                onChanged: (id) => setState(() => _selectedId = id),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text(defaultErrorMessage(e is Exception ? e : Exception(e))),
            ),
            const SizedBox(height: 24),
            if (productDetails != null)
              Expanded(
                child: productDetails.when(
                  data: (result) => result.fold(
                    (err) => Text(defaultErrorMessage(err)),
                    (product) => ListView(
                      children: [
                        Text('ID: ${product.id}'),
                        Text('Title: ${product.title}'),
                        Text('Description: ${product.description}'),
                      ],
                    ),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(defaultErrorMessage(e is Exception ? e : Exception(e)), style: const TextStyle(color: Colors.red))),
                ),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. Optimistic UI Update (edit product title in list, update UI immediately, reconcile with server)
class OptimisticUpdateNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final IApiRepository repo;
  OptimisticUpdateNotifier(this.repo) : super(const AsyncValue.loading()) {
    _fetchProducts();
  }
  List<Product> _products = [];
  Future<void> _fetchProducts() async {
    final result = await repo.getProducts();
    result.fold(
      (err) => state = AsyncValue.error(err, StackTrace.current),
      (products) {
        _products = products.products;
        state = AsyncValue.data(List.from(_products));
      },
    );
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
class OptimisticUpdateScreen extends ConsumerWidget {
  const OptimisticUpdateScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(optimisticUpdateNotifierProvider);
    final notifier = ref.read(optimisticUpdateNotifierProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Optimistic UI Update')),
      body: state.when(
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, idx) {
            final product = products[idx];
            return ListTile(
              title: Text(product.title),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final controller = TextEditingController(text: product.title);
                  final newTitle = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Edit Title'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
                      ],
                    ),
                  );
                  if (newTitle != null && newTitle.isNotEmpty && newTitle != product.title) {
                    notifier.updateProductTitle(product.id, newTitle);
                  }
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(defaultErrorMessage(e is Exception ? e : Exception(e)), style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

// --- UI Screens ---
class SampleHomeScreen extends StatelessWidget {
  const SampleHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod API Patterns')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Products (SOLID, Model, Exception)'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductsScreen()),
            ),
          ),
          ListTile(
            title: const Text('API Call on Button Tap'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ApiOnTapScreen()),
            ),
          ),
          ListTile(
            title: const Text('API Call on Screen Open'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ApiOnOpenScreen()),
            ),
          ),
          ListTile(
            title: const Text('Search Products (Parameterized Provider)'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchProductsScreen()),
            ),
          ),
          ListTile(
            title: const Text('Mutation (Add Product)'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProductScreen()),
            ),
          ),
          ListTile(
            title: const Text('Pagination (Load More Products)'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaginationScreen()),
            ),
          ),
          ListTile(
            title: const Text('Chained Providers'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChainedProvidersScreen()),
            ),
          ),
          ListTile(
            title: const Text('Optimistic UI Update'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OptimisticUpdateScreen()),
            ),
          ),
          ListTile(
            title: const Text('Product Details (SOLID)'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductDetailsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('To be implemented: $title', style: const TextStyle(fontSize: 18))),
    );
  }
}

// Shows all products using ProductList model
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Products (SOLID, Model, Exception)')),
      body: state.when(
        data: (result) => result.fold(
          (err) => Center(child: Text(defaultErrorMessage(err), style: const TextStyle(color: Colors.red))),
          (productList) => ListView.builder(
            itemCount: productList.products.length,
            itemBuilder: (context, idx) => ListTile(
              title: Text(productList.products[idx].title),
              subtitle: Text(productList.products[idx].description),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(defaultErrorMessage(e is Exception ? e : Exception(e)), style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

// Search products using ProductList model
class SearchProductsScreen extends ConsumerStatefulWidget {
  const SearchProductsScreen({super.key});
  @override
  ConsumerState<SearchProductsScreen> createState() => _SearchProductsScreenState();
}
class _SearchProductsScreenState extends ConsumerState<SearchProductsScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final searchResult = ref.watch(searchProductsProvider(_query));
    return Scaffold(
      appBar: AppBar(title: const Text('Search Products (SOLID)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
          Expanded(
            child: searchResult.when(
              data: (result) => result.fold(
                (err) => Center(child: Text(defaultErrorMessage(err), style: const TextStyle(color: Colors.red))),
                (productList) => productList.products.isEmpty
                    ? const Center(child: Text('No products found'))
                    : ListView.builder(
                        itemCount: productList.products.length,
                        itemBuilder: (context, idx) => ListTile(
                          title: Text(productList.products[idx].title),
                        ),
                      ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(defaultErrorMessage(e is Exception ? e : Exception(e)), style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}

// Show product details by ID using Product model
class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key});
  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}
class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int? _productId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details (SOLID)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Product ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() => _productId = int.tryParse(val)),
            ),
          ),
          if (_productId != null)
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(productProvider(_productId!));
                  return state.when(
                    data: (result) => result.fold(
                      (err) => Center(child: Text(defaultErrorMessage(err), style: const TextStyle(color: Colors.red))),
                      (product) => ListView(
                        children: [
                          Text('ID: ${product.id}'),
                          Text('Title: ${product.title}'),
                          Text('Description: ${product.description}'),
                        ],
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text(defaultErrorMessage(e is Exception ? e : Exception(e)), style: const TextStyle(color: Colors.red))),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
