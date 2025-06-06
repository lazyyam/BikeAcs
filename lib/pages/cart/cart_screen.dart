import 'package:BikeAcs/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../appUsers/users.dart';
import '../../services/cart_database.dart';
import 'cart_model.dart';
import 'cart_view_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartViewModel _cartViewModel = CartViewModel();
  final CartDatabase _cartDatabase = CartDatabase(); // Define _cartDatabase
  late Stream<List<CartItem>> _cartStream;
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    final currentUser = Provider.of<AppUsers?>(context, listen: false);
    if (currentUser != null) {
      _cartStream = _cartViewModel.getCartStream(currentUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AppUsers?>(context);
    if (currentUser == null) {
      return const Center(child: Text("Please log in to view your cart."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: _cartStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Your cart is empty!",
                  style: TextStyle(fontSize: 16, color: Colors.black54)),
            );
          }

          final cartItems = snapshot.data!;
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _cartStream =
                              _cartViewModel.getCartStream(currentUser.uid);
                        });
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        itemBuilder: (ctx, index) {
                          final item = cartItems[index];
                          return FutureBuilder<Map<String, dynamic>>(
                            future: _cartViewModel
                                .fetchProductDetails(item.productId),
                            builder: (context, productSnapshot) {
                              final productDetails = productSnapshot.data ?? {};
                              final availableColors =
                                  (productDetails['availableColors']
                                          as List<String>?) ??
                                      [];
                              final availableSizes =
                                  (productDetails['availableSizes']
                                          as List<String>?) ??
                                      [];
                              final stock = productDetails['stock'] ?? 0;
                              final variantStock =
                                  productDetails['variantStock']
                                          as Map<String, int>? ??
                                      {};

                              // Determine stock based on selected color/size
                              int displayedStock = stock;
                              if (availableColors.isNotEmpty ||
                                  availableSizes.isNotEmpty) {
                                if (item.color != null && item.size != null) {
                                  displayedStock = variantStock[
                                          '${item.color}-${item.size}'] ??
                                      0;
                                } else if (item.color != null) {
                                  displayedStock =
                                      variantStock[item.color] ?? 0;
                                } else if (item.size != null) {
                                  displayedStock = variantStock[item.size] ?? 0;
                                }
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[200]!),
                                ),
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Transform.scale(
                                            scale: 1.1,
                                            child: Checkbox(
                                              value: _selectedItems
                                                  .contains(item.id),
                                              onChanged: (isSelected) {
                                                setState(() {
                                                  if (isSelected == true) {
                                                    _selectedItems.add(item.id);
                                                  } else {
                                                    _selectedItems
                                                        .remove(item.id);
                                                  }
                                                });
                                              },
                                              activeColor:
                                                  const Color(0xFFFFBA3B),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              item.image,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'RM${item.price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFFFFBA3B),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 4),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: displayedStock > 0
                                                        ? Colors.green[50]
                                                        : Colors.red[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    'Stock: $displayedStock',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: displayedStock > 0
                                                          ? Colors.green[700]
                                                          : Colors.red[700],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline,
                                                color: Colors.red[300],
                                                size: 20),
                                            onPressed: () =>
                                                _cartViewModel.confirmDelete(
                                              context,
                                              currentUser.uid,
                                              item.id,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (availableColors.isNotEmpty ||
                                          availableSizes.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              if (availableColors.isNotEmpty)
                                                Expanded(
                                                  child: Container(
                                                    height: 36,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey[200]!),
                                                    ),
                                                    child:
                                                        DropdownButtonHideUnderline(
                                                      child: DropdownButton<
                                                          String>(
                                                        value: availableColors
                                                                .contains(
                                                                    item.color)
                                                            ? item.color
                                                            : null,
                                                        items: availableColors
                                                            .map((color) =>
                                                                DropdownMenuItem(
                                                                  value: color,
                                                                  child: Text(
                                                                    color,
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      color: Colors
                                                                          .black87,
                                                                    ),
                                                                  ),
                                                                ))
                                                            .toList(),
                                                        onChanged:
                                                            (newColor) async {
                                                          if (newColor !=
                                                              null) {
                                                            await _cartDatabase
                                                                .updateCartItem(
                                                              currentUser.uid,
                                                              item.id,
                                                              {
                                                                'color':
                                                                    newColor
                                                              },
                                                            );
                                                          }
                                                        },
                                                        hint: Text(
                                                          "Color",
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                        icon: Icon(
                                                          Icons.arrow_drop_down,
                                                          color:
                                                              Colors.grey[600],
                                                          size: 20,
                                                        ),
                                                        isExpanded: true,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              if (availableColors.isNotEmpty &&
                                                  availableSizes.isNotEmpty)
                                                const SizedBox(width: 8),
                                              if (availableSizes.isNotEmpty)
                                                Expanded(
                                                  child: Container(
                                                    height: 36,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey[200]!),
                                                    ),
                                                    child:
                                                        DropdownButtonHideUnderline(
                                                      child: DropdownButton<
                                                          String>(
                                                        value: availableSizes
                                                                .contains(
                                                                    item.size)
                                                            ? item.size
                                                            : null,
                                                        items: availableSizes
                                                            .map((size) =>
                                                                DropdownMenuItem(
                                                                  value: size,
                                                                  child: Text(
                                                                    size,
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      color: Colors
                                                                          .black87,
                                                                    ),
                                                                  ),
                                                                ))
                                                            .toList(),
                                                        onChanged:
                                                            (newSize) async {
                                                          if (newSize != null) {
                                                            await _cartDatabase
                                                                .updateCartItem(
                                                              currentUser.uid,
                                                              item.id,
                                                              {'size': newSize},
                                                            );
                                                          }
                                                        },
                                                        hint: Text(
                                                          "Size",
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                        icon: Icon(
                                                          Icons.arrow_drop_down,
                                                          color:
                                                              Colors.grey[600],
                                                          size: 20,
                                                        ),
                                                        isExpanded: true,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: Colors.grey[200]!),
                                              ),
                                              child: Row(
                                                children: [
                                                  _buildQuantityButton(
                                                      Icons.remove, () async {
                                                    if (item.quantity > 1) {
                                                      await _cartDatabase
                                                          .updateCartItem(
                                                        currentUser.uid,
                                                        item.id,
                                                        {
                                                          'quantity':
                                                              item.quantity - 1
                                                        },
                                                      );
                                                    }
                                                  }),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12),
                                                    child: Text(
                                                      '${item.quantity}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  _buildQuantityButton(
                                                    Icons.add,
                                                    item.quantity <
                                                            displayedStock
                                                        ? () async {
                                                            await _cartDatabase
                                                                .updateCartItem(
                                                              currentUser.uid,
                                                              item.id,
                                                              {
                                                                'quantity':
                                                                    item.quantity +
                                                                        1
                                                              },
                                                            );
                                                          }
                                                        : null,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              'RM${(item.price * item.quantity).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  _buildCheckoutSection(cartItems),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback? onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null ? Colors.grey : const Color(0xFFFFBA3B),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(List<CartItem> cartItems) {
    Future<bool> _isCheckoutEnabled() async {
      if (_selectedItems.isEmpty) return false;

      for (final item
          in cartItems.where((item) => _selectedItems.contains(item.id))) {
        final productDetails =
            await _cartViewModel.fetchProductDetails(item.productId);
        final stock = productDetails['stock'] ?? 0;
        final variantStock =
            productDetails['variantStock'] as Map<String, int>? ?? {};

        int availableStock = stock;
        if (item.color != null && item.size != null) {
          availableStock = variantStock['${item.color}-${item.size}'] ?? 0;
        } else if (item.color != null) {
          availableStock = variantStock[item.color] ?? 0;
        } else if (item.size != null) {
          availableStock = variantStock[item.size] ?? 0;
        }

        if (availableStock == 0) return false;
      }
      return true;
    }

    return FutureBuilder<bool>(
      future: _isCheckoutEnabled(),
      builder: (context, snapshot) {
        final isCheckoutEnabled = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Amount",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "RM${_selectedItems.isEmpty ? '0.00' : cartItems.where((item) => _selectedItems.contains(item.id)).fold(0.0, (total, item) => total + (item.price * item.quantity)).toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFFFFBA3B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCheckoutEnabled
                        ? const Color(0xFFFFBA3B)
                        : Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isCheckoutEnabled
                      ? () {
                          final selectedCartItems = cartItems
                              .where((item) => _selectedItems.contains(item.id))
                              .toList();
                          Navigator.pushNamed(
                            context,
                            AppRoutes.checkout,
                            arguments: selectedCartItems,
                          );
                        }
                      : null,
                  child: Text(
                    "Checkout",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isCheckoutEnabled ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
