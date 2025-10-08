import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:http/http.dart' as http;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:test1/Components/AppBar.dart';
import 'package:test1/Interfaces/interface.ProductsData.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool isLoading = true;
  List<Product> products = [];
  List<Product> filteredProducts = [];
  Map<String, int> productAmounts = {};
  Map<String, Product> productCarts = {};
  @override
  void initState() {
    super.initState();
    getProducts();
  }

  Future<void> saveCartToCache() async {
    final cacheManager = DefaultCacheManager();

    // Combine data
    Map<String, dynamic> combinedData = {
      'carts': productCarts.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
      'amounts': productAmounts.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };

    String jsonString = jsonEncode(combinedData);

    // Save as a file in cache
    await cacheManager.putFile(
      'cart.json',
      Uint8List.fromList(jsonString.codeUnits),
    );

    print('Cart saved in cache');
  }

  Future<void> getProducts() async {
    final response = await http.get(
      Uri.parse('https://dummyjson.com/products'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (mounted) {
        setState(() {
          products = (data['products'] as List)
              .map((item) => Product.fromJson(item))
              .toList();
          filteredProducts = products;
          isLoading = false;
        });
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = 0;
    double totalPrice = 0.0;

    if (productAmounts.isNotEmpty) {
      totalItems = productAmounts.values.fold(0, (sum, item) => sum + item);
      productAmounts.forEach((productId, quantity) {
        final product = products.firstWhere(
          (p) => p.id.toString() == productId,
        );
        totalPrice += product.price * quantity;
      });
    }

    return Scaffold(
      appBar: CustomAppBar(title: "Pos | Shop", showBackButton: true),
      body: SafeArea(
        // ✅ Prevents bottom overflow safely
        bottom: false,
        child: Container(
          color: const Color.fromARGB(255, 242, 242, 242),
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(child: isLoading ? _buildLoading() : _buildGrid()),
              _buildSummaryBar(totalItems, totalPrice),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(int totalItems, double totalPrice) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: totalItems > 0 ? 100 : 0,
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: totalItems),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, value, child) => Text(
                      '$value Items',
                      style: ShadTheme.of(context).textTheme.muted,
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: totalPrice),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, value, child) => Text(
                      '\$${value.toStringAsFixed(2)}',
                      style: ShadTheme.of(context).textTheme.h4,
                    ),
                  ),
                ],
              ),

              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: totalPrice),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, child) {
                  return ShadButton(
                    child: Text("Pay \$${value.toStringAsFixed(2)}"),
                    onPressed: () {
                      saveCartToCache();
                      Get.toNamed("/payment");
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        height: 80,
        width: 80,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFF4F4F5),
            borderRadius: BorderRadius.all(Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(31, 221, 52, 52),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10, top: 10),
      child: ShadInput(
        placeholder: const Text('Search products...'),
        decoration: ShadDecoration(
          gradient: LinearGradient(colors: [Colors.white, Colors.white]),
          border: ShadBorder(
            radius: BorderRadius.circular(16),
            canMerge: false,
          ),
          disableSecondaryBorder: true,
        ),
        leading: const Icon(Icons.search),
        onChanged: (query) => {
          setState(() {
            filteredProducts = products
                .where(
                  (product) =>
                      product.title.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
          }),
        },
      ),
    );
  }

  Widget _buildGrid() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            double childAspectRatio = constraints.maxWidth > 600 ? 1 : 0.75;

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return _builderCard(product);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _builderCard(Product product) {
    final String productId = product.id.toString();
    final int amount = productAmounts[productId] ?? 0;

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(
              product.thumbnail ?? "https://via.placeholder.com/150",
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 50, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Center(child: ShadBadge(child: Text('\$${product.price}'))),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: amount > 0
                      ? () {
                          setState(() {
                            int newAmount = amount - 1;
                            if (newAmount > 0) {
                              productAmounts[productId] = newAmount;
                            } else {
                              productAmounts.remove(productId);
                              productCarts.remove(productId);
                            }
                          });
                        }
                      : null,
                ),
                Text(
                  '$amount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() {
                      productAmounts[productId] = amount + 1;
                      productCarts[productId] = product;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
