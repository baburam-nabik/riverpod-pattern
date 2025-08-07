import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stateman/api_service.dart';
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

final apiServiceProvider = Provider<IApiService>((ref) => ApiService());

// --- SOLID/Model/Exception-based Providers ---
final productsProvider = FutureProvider<Either<Exception, ProductList>>((ref) {
  final api = ref.read(apiServiceProvider);
  return api.getProducts();
});

final productProvider = FutureProvider.family<Either<Exception, Product>, int>((ref, id) {
  final api = ref.read(apiServiceProvider);
  return api.getProduct(id);
});

final searchProductsProvider = FutureProvider.family<Either<Exception, ProductList>, String>((ref, query) {
  final api = ref.read(apiServiceProvider);
  return api.searchProducts(query);
});

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
            title: const Text('Search Products (SOLID)'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchProductsScreen()),
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

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Products (SOLID, Model, Exception)')),
      body: state.when(
        data: (result) => result.fold(
          (err) => Center(child: Text('Error: ${err.toString()}', style: const TextStyle(color: Colors.red))),
          (productList) => ListView.builder(
            itemCount: productList.products.length,
            itemBuilder: (context, idx) => ListTile(
              title: Text(productList.products[idx].title),
              subtitle: Text(productList.products[idx].description),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

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
                (err) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
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
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}

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
                      (err) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                      (product) => ListView(
                        children: [
                          Text('ID: ${product.id}'),
                          Text('Title: ${product.title}'),
                          Text('Description: ${product.description}'),
                        ],
                      ),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
