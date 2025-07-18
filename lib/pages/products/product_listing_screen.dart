import 'package:BikeAcs/pages/products/product_model.dart';
import 'package:BikeAcs/routes.dart';
import 'package:flutter/material.dart';

import 'product_view_model.dart';

class ProductListingScreen extends StatefulWidget {
  final String category;
  final bool
      isSearch; // New parameter to differentiate between search and category

  const ProductListingScreen(
      {super.key, required this.category, required this.isSearch});

  @override
  State<ProductListingScreen> createState() => _ProductListingState();
}

class _ProductListingState extends State<ProductListingScreen> {
  final ProductViewModel _viewModel = ProductViewModel();
  final TextEditingController _searchController = TextEditingController();
  late Stream<List<Product>> _productsStream;
  bool _isRefreshing = false;

  // Pagination variables
  int _currentPage = 1;
  final int _productsPerPage = 10; // Number of products per page
  int _totalPages = 1;

  // Price range variables
  double? _minPrice;
  double? _maxPrice;

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
        _searchController.text.trim(),
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.isSearch
                    ? "Search accessories..."
                    : "Search ${widget.category}...",
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(Icons.search, color: Color(0xFFFFBA3B), size: 22),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: Colors.grey[400], size: 20),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Colors.black12)),
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_alt,
                color: _isFilterActive
                    ? const Color(0xFFFFBA3B)
                    : Colors.grey[400],
                size: 22,
              ),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(int totalProducts) {
    _totalPages = (totalProducts / _productsPerPage).ceil();

    if (_totalPages <= 1)
      return const SizedBox.shrink(); // Don't show if only 1 page

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous page button
          if (_currentPage > 1)
            _buildPageButton(
              icon: Icons.chevron_left,
              onTap: () => setState(() => _currentPage--),
            ),

          // Page numbers
          for (int i = 1; i <= _totalPages; i++)
            if (i == 1 ||
                i == _totalPages ||
                (i >= _currentPage - 1 && i <= _currentPage + 1))
              _buildPageButton(
                text: i.toString(),
                isSelected: i == _currentPage,
                onTap: () => setState(() => _currentPage = i),
              )
            else if (i == _currentPage - 2 || i == _currentPage + 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('...', style: TextStyle(color: Colors.grey[600])),
              ),

          // Next page button
          if (_currentPage < _totalPages)
            _buildPageButton(
              icon: Icons.chevron_right,
              onTap: () => setState(() => _currentPage++),
            ),
        ],
      ),
    );
  }

  Widget _buildPageButton(
      {String? text,
      IconData? icon,
      bool isSelected = false,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFBA3B) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: icon != null
            ? Icon(icon,
                size: 18, color: isSelected ? Colors.black : Colors.grey[600])
            : Text(
                text!,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
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

    // Calculate start and end indices for current page
    final startIndex = (_currentPage - 1) * _productsPerPage;
    final endIndex = startIndex + _productsPerPage;

    final paginatedProducts = filteredProducts.sublist(
      startIndex,
      endIndex > filteredProducts.length ? filteredProducts.length : endIndex,
    );

    if (filteredProducts.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No accessories found',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                itemCount: paginatedProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (ctx, i) {
                  final product = paginatedProducts[i];
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      ctx,
                      AppRoutes.productDetail,
                      arguments: product,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Image.network(
                                product.images.first,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'RM${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFBA3B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: product.stock > 0
                                          ? Colors.green[50]
                                          : Colors.red[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      product.stock > 0
                                          ? 'In Stock'
                                          : 'Out of Stock',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: product.stock > 0
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Always show pagination controls if there are multiple pages
          _buildPaginationControls(filteredProducts.length),
        ],
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

  bool get _isFilterActive => _minPrice != null || _maxPrice != null;

  void _clearPriceFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _productsStream = _viewModel.getProductsStream(
        widget.category,
        widget.isSearch,
        _searchController.text.trim(),
      );
    });
  }

  void _showFilterDialog() {
    String? errorMessage;
    final TextEditingController minPriceController = TextEditingController(
      text: _minPrice?.toString() ?? '',
    );
    final TextEditingController maxPriceController = TextEditingController(
      text: _maxPrice?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool validatePrices() {
              final String minText = minPriceController.text.trim();
              final String maxText = maxPriceController.text.trim();

              final double? minPrice = double.tryParse(minText);
              final double? maxPrice = double.tryParse(maxText);

              if (minText.isNotEmpty && minPrice == null) {
                setState(
                    () => errorMessage = 'Please enter a valid minimum price');
                return false;
              }

              if (maxText.isNotEmpty && maxPrice == null) {
                setState(
                    () => errorMessage = 'Please enter a valid maximum price');
                return false;
              }

              if ((minPrice != null && minPrice < 0) ||
                  (maxPrice != null && maxPrice < 0)) {
                setState(() => errorMessage = 'Prices cannot be negative');
                return false;
              }

              if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
                setState(() => errorMessage =
                    'Minimum price cannot be greater than maximum price');
                return false;
              }

              setState(() => errorMessage = null);
              return true;
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.filter_list, color: Color(0xFFFFBA3B)),
                            SizedBox(width: 8),
                            Text(
                              'Filter Accessories',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Price Range Section
                    const Text(
                      'Price Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: errorMessage != null
                                    ? Colors.red
                                    : Colors.transparent,
                              ),
                            ),
                            child: TextField(
                              controller: minPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                prefixText: 'RM ',
                                hintText: 'Min',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              onChanged: (value) => validatePrices(),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child:
                              Text('to', style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: errorMessage != null
                                    ? Colors.red
                                    : Colors.transparent,
                              ),
                            ),
                            child: TextField(
                              controller: maxPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                prefixText: 'RM ',
                                hintText: 'Max',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              onChanged: (value) => validatePrices(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              _clearPriceFilters();
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: const Text(
                              "Reset",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (validatePrices()) {
                                final minPrice = double.tryParse(
                                    minPriceController.text.trim());
                                final maxPrice = double.tryParse(
                                    maxPriceController.text.trim());

                                this.setState(() {
                                  _minPrice = minPrice;
                                  _maxPrice = maxPrice;
                                  _productsStream =
                                      _viewModel.getProductsStream(
                                    widget.category,
                                    widget.isSearch,
                                    _searchController.text.trim(),
                                    minPrice: _minPrice,
                                    maxPrice: _maxPrice,
                                  );
                                });
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFBA3B),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Apply",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSearch && _searchController.text.isEmpty
            ? "All Accessories"
            : widget.category), // Adjust title
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.motorcycle,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Accessories Found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    }

                    return _buildProductGrid(
                      snapshot.data!,
                      _searchController.text,
                    );
                  },
                ),
                const SizedBox(height: 20),
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
