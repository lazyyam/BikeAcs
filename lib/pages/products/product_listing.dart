import 'package:BikeAcs/pages/products/product_model.dart';
import 'package:BikeAcs/routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'product_view_model.dart';

class ProductListing extends StatefulWidget {
  final String category;
  final bool
      isSearch; // New parameter to differentiate between search and category

  const ProductListing(
      {super.key, required this.category, required this.isSearch});

  @override
  State<ProductListing> createState() => _ProductListingState();
}

class _ProductListingState extends State<ProductListing> {
  final ProductViewModel _viewModel = ProductViewModel();
  final TextEditingController _searchController = TextEditingController();
  late Stream<List<Product>> _productsStream;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.isSearch
        ? widget.category
        : ""; // Pre-fill search bar if it's a search action
    _productsStream = _viewModel.getProductsStream(
      widget.category,
      widget.isSearch,
      _searchController.text,
    );
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _productsStream = _viewModel.getProductsStream(
        widget.category,
        widget.isSearch,
        _searchController.text,
      );
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: widget.isSearch
              ? "Search products..."
              : "Search ${widget.category}...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.productDetail,
        arguments: product,
      ),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with placeholder and error widget
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: product.images.isNotEmpty ? product.images[0] : '',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\RM${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFFFBA3B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.stock > 0 ? 'In Stock' : 'Out of Stock',
                    style: TextStyle(
                      color: product.stock > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products, String searchQuery) {
    final filteredProducts = searchQuery.isEmpty
        ? products
        : products
            .where(
                (p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    if (filteredProducts.isEmpty) {
      return const Expanded(
        child: Center(child: Text('No products found')),
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: filteredProducts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (ctx, i) => _buildProductItem(filteredProducts[i]),
        ),
      ),
    );
  }

  Future<void> _refreshProductListing() async {
    setState(() => _isRefreshing = true);
    _productsStream = _viewModel.getProductsStream(
      widget.category,
      widget.isSearch,
      _searchController.text,
    );
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isSearch ? "All Products" : widget.category), // Adjust title
        elevation: 0,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshProductListing,
            child: Column(
              children: [
                _buildSearchBar(),
                StreamBuilder<List<Product>>(
                  stream: _productsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Expanded(
                          child: Center(child: CircularProgressIndicator()));
                    }

                    if (snapshot.hasError) {
                      return Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}'),
                              TextButton(
                                onPressed: () => setState(() {}),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Expanded(
                        child: Center(child: Text('No products available')),
                      );
                    }

                    return _buildProductGrid(
                      snapshot.data!,
                      _searchController.text,
                    );
                  },
                ),
              ],
            ),
          ),
          if (_isRefreshing)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
