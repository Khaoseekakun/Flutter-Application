import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isRefreshing = false;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    getProducts();
    loadCartFromCache();
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

  List<Product> _computeFilteredProducts([List<Product>? source]) {
    Iterable<Product> items = (source ?? products);

    switch (_selectedFilter) {
      case 'In Stock':
        items = items.where((product) => product.stockQuantity > 0);
        break;
      case 'Low Stock':
        items = items.where(
          (product) => product.stockQuantity > 0 && product.stockQuantity <= 5,
        );
        break;
      default:
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((product) {
        final name = product.name.toLowerCase();
        final sku = (product.sku).toLowerCase();
        return name.contains(query) || sku.contains(query);
      });
    }

    return items.toList();
  }

  void _syncCartWithProducts() {
    if (!mounted || productCarts.isEmpty) return;

    final Map<String, Product> syncedCarts = {};
    final Map<String, int> syncedAmounts = {};

    productCarts.forEach((productId, cachedProduct) {
      final Product? latest = _findProductById(productId) ?? cachedProduct;
      final int amount = productAmounts[productId] ?? 0;
      if (amount <= 0) return;

      if (latest == null || latest.stockQuantity <= 0) {
        return;
      }

      final int cappedAmount = amount > latest.stockQuantity
          ? latest.stockQuantity.toInt()
          : amount;

      if (cappedAmount > 0) {
        syncedCarts[productId] = latest;
        syncedAmounts[productId] = cappedAmount;
      }
    });

    if (!mounted) return;
    setState(() {
      productCarts = syncedCarts;
      productAmounts = syncedAmounts;
    });
  }

  Product? _findProductById(String productId) {
    try {
      return products.firstWhere(
        (product) => product.productId.toString() == productId,
      );
    } catch (_) {
      return null;
    }
  }

  void _showCartMessage(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateCart(Product product, int delta) {
    if (!mounted) return;

    final String productId = product.productId.toString();
    final int currentQuantity = productAmounts[productId] ?? 0;

    if (delta > 0 && product.stockQuantity <= 0) {
      _showCartMessage('สินค้า ${product.name} หมดสต็อกแล้ว');
      return;
    }
    if (delta > 0 && currentQuantity >= product.stockQuantity) {
      _showCartMessage('จำนวนสินค้า ${product.name} มีไม่พอในสต็อก');
      return;
    }
    if (delta < 0 && currentQuantity == 0) {
      return;
    }

    int nextQuantity = currentQuantity + delta;
    if (nextQuantity < 0) nextQuantity = 0;
    if (product.stockQuantity > 0 && nextQuantity > product.stockQuantity) {
      nextQuantity = product.stockQuantity.toInt();
    }

    if (nextQuantity == currentQuantity) {
      return;
    }

    setState(() {
      if (nextQuantity == 0) {
        productAmounts.remove(productId);
        productCarts.remove(productId);
      } else {
        productAmounts[productId] = nextQuantity;
        productCarts[productId] = product;
      }
    });

    saveCartToCache();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      filteredProducts = _computeFilteredProducts();
    });
  }

  Future<void> loadCartFromCache() async {
    final cacheManager = DefaultCacheManager();
    final cachedFile = await cacheManager.getFileFromCache('cart.json');
    if (cachedFile == null) return;

    try {
      final jsonString = await cachedFile.file.readAsString();
      final Map<String, dynamic> data =
          jsonDecode(jsonString) as Map<String, dynamic>;

      final Map<String, dynamic> rawCarts = Map<String, dynamic>.from(
        data['carts'] ?? {},
      );
      final Map<String, dynamic> rawAmounts = Map<String, dynamic>.from(
        data['amounts'] ?? {},
      );

      final Map<String, Product> loadedCarts = {};
      rawCarts.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          loadedCarts[key] = Product.fromJson(value);
        } else if (value is Map) {
          loadedCarts[key] = Product.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });

      final Map<String, int> loadedAmounts = {};
      rawAmounts.forEach((key, value) {
        if (value is int && value > 0) {
          loadedAmounts[key] = value;
        } else if (value is num && value.toInt() > 0) {
          loadedAmounts[key] = value.toInt();
        } else if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null && parsed > 0) {
            loadedAmounts[key] = parsed;
          }
        }
      });

      if (!mounted) return;
      setState(() {
        productCarts = loadedCarts;
        productAmounts = loadedAmounts;
      });
      _syncCartWithProducts();
    } catch (e) {
      debugPrint('Failed to load cached cart: $e');
    }
  }

  Future<void> getProducts({bool showLoader = true}) async {
    if (!mounted) return;

    if (showLoader) {
      setState(() {
        isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/products'),
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Status code ${response.statusCode}');
      }

      final payload = json.decode(response.body);
      final List<dynamic> dataList = payload['data'] ?? [];

      // Parse list of products
      final fetchedProducts = dataList
          .map<Product?>((item) {
            try {
              final map = Map<String, dynamic>.from(item as Map);

              // normalize optional fields
              map['price'] ??= 0;
              map['stockQuantity'] ??= 0;

              // handle possible id variations
              if (map['productId'] == null && map['id'] != null) {
                map['productId'] = map['id'];
              }

              return Product.fromJson(map);
            } catch (e) {
              debugPrint('Error parsing product: $e');
              return null;
            }
          })
          .whereType<Product>()
          .toList();

      debugPrint('Fetched ${fetchedProducts.length} products');

      if (!mounted) return;
      setState(() {
        products = fetchedProducts;
        filteredProducts = _computeFilteredProducts(fetchedProducts);
      });

      _syncCartWithProducts();
    } catch (e) {
      debugPrint('Failed to load products: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'ไม่สามารถโหลดรายการสินค้าได้ กรุณาลองอีกครั้ง';
        filteredProducts = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = 0;
    double totalPrice = 0.0;

    if (productCarts.isNotEmpty) {
      productCarts.forEach((productId, product) {
        final quantity = productAmounts[productId] ?? 0;
        if (quantity <= 0) return;
        totalItems += quantity;
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
              Expanded(child: _buildContent()),
              _buildSummaryBar(totalItems, totalPrice),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(int totalItems, double totalPrice) {
    final theme = Theme.of(context);
    final formattedPrice = totalPrice.toStringAsFixed(2);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: totalItems <= 0
          ? const SizedBox.shrink()
          : Container(
              key: const ValueKey('summary-bar'),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(35, 15, 23, 42),
                    blurRadius: 20,
                    offset: Offset(0, -6),
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$totalItems รายการในตะกร้า',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ยอดรวม ${formattedPrice}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShadButton(
                    onPressed: () {
                      saveCartToCache();
                      Get.toNamed('/payment');
                    },
                    child: Text('ชำระเงิน ${formattedPrice}'),
                  ),
                ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: ShadInput(
              placeholder: const Text('ค้นหาชื่อสินค้า, SKU หรือผู้ผลิต'),
              decoration: ShadDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Colors.white],
                ),
                border: ShadBorder(
                  radius: BorderRadius.circular(16),
                  canMerge: false,
                ),
                disableSecondaryBorder: true,
              ),
              leading: const Icon(Icons.search),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              tooltip: 'รีเฟรชรายการสินค้า',
              onPressed: _isRefreshing
                  ? null
                  : () => getProducts(showLoader: false),
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading && !_isRefreshing) {
      return _buildLoading();
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    if (filteredProducts.isEmpty) {
      return _buildEmptyState();
    }
    return _buildGrid();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.store_mall_directory_outlined,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              'เกิดข้อผิดพลาด',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'ไม่สามารถโหลดข้อมูลสินค้าได้ กรุณาลองใหม่อีกครั้ง',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ShadButton(
              onPressed: () => getProducts(showLoader: true),
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 12),
            Text(
              'ไม่พบสินค้าที่ตรงกับการค้นหา',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'ลองปรับคำค้นหา หรือตรวจสอบตัวกรองที่เลือกอยู่',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return RefreshIndicator(
      onRefresh: () => getProducts(showLoader: false),
      displacement: 32,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final int crossAxisCount = width > 1024
              ? 5
              : width > 840
              ? 4
              : width > 600
              ? 3
              : 2;
          final double childAspectRatio = width > 600 ? 0.82 : 0.7;

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: filteredProducts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) =>
                _buildProductCard(filteredProducts[index]),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);
    final String productId = product.productId.toString();
    final int quantity = productAmounts[productId] ?? 0;
    final bool isOutOfStock = product.stockQuantity <= 0;
    final bool isSelected = quantity > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.6)
              : Colors.transparent,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.1 : 0.06),
            blurRadius: isSelected ? 18 : 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: const Color(0xFFF9FAFB),
                        alignment: Alignment.center,
                        child: product.images.isNotEmpty == true
                            ? Image.network(
                                product.images.first,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.broken_image,
                                      size: 44,
                                      color: Color(0xFF9CA3AF),
                                    ),
                              )
                            : const Icon(
                                Icons.inventory_2_outlined,
                                size: 44,
                                color: Color(0xFF9CA3AF),
                              ),
                      ),
                    ),
                  ),
                  if (isOutOfStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Out of stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  if (quantity > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'x$quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SKU ${product.sku}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${product.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'คงเหลือ ${product.stockQuantity}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOutOfStock
                        ? Colors.redAccent
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuantityControls(product, quantity, isOutOfStock),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(
    Product product,
    int quantity,
    bool isOutOfStock,
  ) {
    final bool canDecrease = quantity > 0;
    final bool canIncrease = !isOutOfStock && quantity < product.stockQuantity;

    return Row(
      children: [
        _buildQuantityButton(
          icon: Icons.remove,
          enabled: canDecrease,
          onTap: () => _updateCart(product, -1),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              quantity.toString().padLeft(2, '0'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildQuantityButton(
          icon: Icons.add,
          enabled: canIncrease,
          onTap: () => _updateCart(product, 1),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Material(
        color: enabled
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: enabled ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
