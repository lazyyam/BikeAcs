import 'package:BikeAcs/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/users.dart';
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
        title: const Text('My Cart',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        elevation: 0,
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
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
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
                                          ),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(item.image,
                                                width: 70,
                                                height: 70,
                                                fit: BoxFit.cover),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(item.name,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text(
                                                    'RM${item.price.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        color:
                                                            Color(0xFFFFBA3B),
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                const SizedBox(height: 4),
                                                Text('Stock: $displayedStock',
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black54)),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () async {
                                              await _cartViewModel
                                                  .confirmDelete(context,
                                                      currentUser.uid, item.id);
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove,
                                                    color: Colors.brown),
                                                onPressed: () async {
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
                                                  } else {
                                                    await _cartViewModel
                                                        .confirmDelete(
                                                            context,
                                                            currentUser.uid,
                                                            item.id);
                                                  }
                                                },
                                              ),
                                              Text('${item.quantity}',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              IconButton(
                                                icon: const Icon(Icons.add,
                                                    color: Color(0xFFFFBA3B)),
                                                onPressed: item.quantity <
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
                                                    : () {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                "Only $displayedStock items available in stock."),
                                                          ),
                                                        );
                                                      },
                                              ),
                                            ],
                                          ),
                                          Text(
                                              'Total: RM${(item.price * item.quantity).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black)),
                                        ],
                                      ),
                                      const SizedBox(height: 0),
                                      if (availableColors.isNotEmpty ||
                                          availableSizes.isNotEmpty)
                                        Row(
                                          children: [
                                            if (availableColors.isNotEmpty)
                                              SizedBox(
                                                width: 120, // Shrink width
                                                child: Row(
                                                  children: [
                                                    const Text("Color:",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    const SizedBox(width: 8),
                                                    DropdownButton<String>(
                                                      value: availableColors
                                                              .contains(
                                                                  item.color)
                                                          ? item.color
                                                          : null,
                                                      items: availableColors
                                                          .map((color) =>
                                                              DropdownMenuItem(
                                                                value: color,
                                                                child:
                                                                    Text(color),
                                                              ))
                                                          .toList(),
                                                      onChanged:
                                                          (newColor) async {
                                                        if (newColor != null) {
                                                          await _cartDatabase
                                                              .updateCartItem(
                                                            currentUser.uid,
                                                            item.id,
                                                            {'color': newColor},
                                                          );
                                                        }
                                                      },
                                                      hint:
                                                          const Text("Select"),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (availableSizes.isNotEmpty)
                                              SizedBox(
                                                width: 120, // Shrink width
                                                child: Row(
                                                  children: [
                                                    const Text("Size:",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    const SizedBox(width: 8),
                                                    DropdownButton<String>(
                                                      value: availableSizes
                                                              .contains(
                                                                  item.size)
                                                          ? item.size
                                                          : null,
                                                      items: availableSizes
                                                          .map((size) =>
                                                              DropdownMenuItem(
                                                                value: size,
                                                                child:
                                                                    Text(size),
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
                                                      hint:
                                                          const Text("Select"),
                                                    ),
                                                  ],
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
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total:",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(
                                "RM${_selectedItems.isEmpty ? '0.00' : cartItems.where((item) => _selectedItems.contains(item.id)).fold(0.0, (double total, item) => total + (item.price * item.quantity)).toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFFFBA3B),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFBA3B),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _selectedItems.isEmpty
                                ? null
                                : () {
                                    final selectedCartItems = cartItems
                                        .where((item) =>
                                            _selectedItems.contains(item.id))
                                        .toList(); // No need to map, as `cartItems` are already `CartItem` objects
                                    debugPrint(
                                        "Navigating to checkout with items: $selectedCartItems"); // Debug log
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.checkout,
                                      arguments:
                                          selectedCartItems, // Pass CartItem objects directly
                                    );
                                  },
                            child: const Text(
                              "Proceed to Checkout",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
