import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test1/Components/AppBar.dart';
import 'package:test1/Interfaces/interface.ProductsData.dart';
import 'package:test1/Screens/PaymentProcess.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isLoading = true;

  Map<String, Product> productCarts = {};
  Map<String, int> productAmounts = {};

  String? _lastRemovedId;
  Product? _lastRemovedProduct;
  int? _lastRemovedAmount;

  bool _isProcessing = false;
  String? _selectedPaymentMethod;

  final List<_PaymentMethodOption> _paymentMethods = const [
    _PaymentMethodOption(
      code: 'cash',
      label: 'ชำระเงินสด',
      icon: Icons.payments_outlined,
      description: 'รับเงินสดจากลูกค้าที่หน้าร้าน',
    ),
    _PaymentMethodOption(
      code: 'promptpay',
      label: 'QR PromptPay',
      icon: Icons.qr_code_2_rounded,
      description: 'ลูกค้าสแกนจ่ายผ่าน PromptPay',
    ),
  ];

  @override
  void initState() {
    super.initState();
    loadCartFromCache();
  }

  Future<void> loadCartFromCache() async {
    try {
      final cacheManager = DefaultCacheManager();
      final cachedFile = await cacheManager.getFileFromCache('cart.json');

      if (cachedFile == null) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final jsonString = await cachedFile.file.readAsString();
      final cleaned = jsonString.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
      final Map<String, dynamic> data = jsonDecode(cleaned);

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
            Map<String, dynamic>.from(value as Map),
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
        _sanitizeCart();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load cached cart: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> deleteCache() async {
    await DefaultCacheManager().removeFile('cart.json');
    if (!mounted) return;
    setState(() {
      productCarts.clear();
      productAmounts.clear();
    });
  }

  Future<void> saveCartToCache() async {
    try {
      final payload = _serializeCartForCache();
      final jsonString = jsonEncode(payload);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      await DefaultCacheManager().putFile(
        'cart.json',
        bytes,
        fileExtension: 'json',
      );
    } catch (e) {
      debugPrint('Error saving cart to cache: $e');
    }
  }

  Map<String, dynamic> _serializeCartForCache() {
    final Map<String, dynamic> carts = {};
    final Map<String, int> amounts = {};

    productCarts.forEach((id, product) {
      final quantity = productAmounts[id] ?? 0;
      if (quantity > 0) {
        carts[id] = product.toJson();
        amounts[id] = quantity;
      }
    });

    return {'carts': carts, 'amounts': amounts};
  }

  void _sanitizeCart() {
    final Map<String, Product> sanitizedCarts = {};
    final Map<String, int> sanitizedAmounts = {};

    productCarts.forEach((id, product) {
      final quantity = productAmounts[id] ?? 0;
      if (quantity > 0) {
        sanitizedCarts[id] = product;
        sanitizedAmounts[id] = quantity;
      }
    });

    productCarts = sanitizedCarts;
    productAmounts = sanitizedAmounts;
  }

  void _removeItem(String productId) {
    if (!productCarts.containsKey(productId)) return;

    setState(() {
      _lastRemovedId = productId;
      _lastRemovedProduct = productCarts.remove(productId);
      _lastRemovedAmount = productAmounts.remove(productId);
      _sanitizeCart();
    });

    saveCartToCache();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('ลบสินค้าออกจากตะกร้าแล้ว'),
          action: SnackBarAction(
            label: 'ยกเลิก',
            onPressed: () {
              if (!mounted) return;
              if (_lastRemovedId != null && _lastRemovedProduct != null) {
                setState(() {
                  productCarts[_lastRemovedId!] = _lastRemovedProduct!;
                  productAmounts[_lastRemovedId!] = _lastRemovedAmount ?? 1;
                  _sanitizeCart();
                  _lastRemovedId = null;
                  _lastRemovedProduct = null;
                  _lastRemovedAmount = null;
                });
                saveCartToCache();
              }
            },
          ),
        ),
      );
  }

  void _changeQuantity(_CartLineItem item, int delta) {
    final productId = item.id;
    final currentQuantity = productAmounts[productId] ?? 0;
    final Product product = item.product;

    if (delta > 0 && product.stockQuantity <= 0) {
      _showMessage('สินค้า ${product.name} หมดสต็อกแล้ว');
      return;
    }
    if (delta > 0 &&
        product.stockQuantity > 0 &&
        currentQuantity >= product.stockQuantity) {
      _showMessage('จำนวนสินค้า ${product.name} มีไม่พอในสต็อก');
      return;
    }
    if (delta < 0 && currentQuantity == 0) {
      return;
    }

    final nextQuantity = currentQuantity + delta;

    setState(() {
      if (nextQuantity <= 0) {
        productAmounts.remove(productId);
        productCarts.remove(productId);
      } else {
        productAmounts[productId] = nextQuantity;
      }
      _sanitizeCart();
    });

    saveCartToCache();
  }

  void _showMessage(String message) {
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

  List<_CartLineItem> _cartLines() {
    final List<_CartLineItem> items = [];
    productCarts.forEach((id, product) {
      final quantity = productAmounts[id] ?? 0;
      if (quantity > 0) {
        items.add(_CartLineItem(id: id, product: product, quantity: quantity));
      }
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = _cartLines();
    final String currency = cartItems.isNotEmpty
        ? cartItems.first.product.currency
        : 'THB';
    final double totalPrice = cartItems.fold(
      0,
      (previousValue, element) => previousValue + element.lineTotal,
    );
    final int totalItems = cartItems.fold(
      0,
      (previousValue, element) => previousValue + element.quantity,
    );

    return Scaffold(
      appBar: CustomAppBar(title: 'Pos | Payment', showBackButton: true),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? _buildLoadingState()
                    : cartItems.isEmpty
                    ? _buildEmptyState()
                    : _buildCartContent(
                        cartItems,
                        currency,
                        totalItems,
                        totalPrice,
                      ),
              ),
            ),
            if (!isLoading && cartItems.isNotEmpty)
              _buildBottomSummary(currency, totalPrice),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(strokeWidth: 3));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_basket_outlined,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            Text(
              'ตะกร้าว่างเปล่า',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'ยังไม่มีสินค้าในตะกร้า ลองกลับไปเลือกสินค้าที่หน้าร้านค้าก่อนนะ',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  Get.offNamedUntil('/shop', (route) => route.isFirst),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('กลับไปเลือกสินค้า'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(
    List<_CartLineItem> items,
    String currency,
    int totalItems,
    double totalPrice,
  ) {
    final double tax = totalPrice * 0.07;
    final double subtotal = totalPrice - tax;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Text(
          'ตรวจสอบรายการชำระเงิน',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '$totalItems รายการ • ${_formatMoney(totalPrice, currency)}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCartItemCard(item),
          );
        }),
        _buildPricingBreakdown(subtotal, tax, totalPrice, currency),
        const SizedBox(height: 24),
        _buildPaymentMethodSection(),
      ],
    );
  }

  Widget _buildCartItemCard(_CartLineItem item) {
    final product = item.product;
    final theme = Theme.of(context);
    final hasImage = product.images?.isNotEmpty == true;
    final bool canDecrease = item.quantity > 0;
    final bool canIncrease = product.stockQuantity <= 0
        ? false
        : item.quantity < product.stockQuantity;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(25, 15, 23, 42),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: hasImage
                      ? Image.network(
                          product.images!.first,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _imageFallback(),
                        )
                      : _imageFallback(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (product.sku != null && product.sku!.isNotEmpty)
                            _buildInfoChip('SKU ${product.sku}'),
                          _buildInfoChip('คงเหลือ ${product.stockQuantity}'),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'นำออกจากตะกร้า',
                  onPressed: () => _removeItem(item.id),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.grey.shade500,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildQuantityButton(
                  icon: Icons.remove,
                  enabled: canDecrease,
                  onTap: () => _changeQuantity(item, -1),
                ),
                Container(
                  width: 60,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.quantity.toString().padLeft(2, '0'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildQuantityButton(
                  icon: Icons.add,
                  enabled: canIncrease,
                  onTap: () => _changeQuantity(item, 1),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatMoney(item.lineTotal, product.currency),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${item.quantity} × ${_formatMoney(product.price.toDouble(), product.currency)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: 80,
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey.shade500,
        size: 32,
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: enabled ? const Color(0xFF111827) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildPricingBreakdown(
    double subtotal,
    double tax,
    double total,
    String currency,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สรุปรายการ',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('ยอดสินค้ารวม', _formatMoney(subtotal, currency)),
          const SizedBox(height: 8),
          _buildSummaryRow('ภาษี (7%)', _formatMoney(tax, currency)),
          const Divider(height: 24),
          _buildSummaryRow(
            'ยอดรวมสุทธิ',
            _formatMoney(total, currency),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    final textStyle = isBold
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(child: Text(label, style: textStyle)),
        Text(value, style: textStyle),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ช่องทางการชำระเงิน',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ..._paymentMethods.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPaymentOptionTile(option),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptionTile(_PaymentMethodOption option) {
    final bool isSelected = _selectedPaymentMethod == option.code;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = option.code;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color.fromARGB(12, 15, 23, 42),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                option.icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (option.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      option.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Radio<String>(
              value: option.code,
              groupValue: _selectedPaymentMethod,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummary(String currency, double totalPrice) {
    final formattedTotal = _formatMoney(totalPrice, currency);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(30, 15, 23, 42),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ยอดรวมทั้งหมด',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              formattedTotal,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedPaymentMethod == null || _isProcessing)
                    ? null
                    : () => _handlePaymentProcessing(totalPrice),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'ยืนยันการชำระ $formattedTotal',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double amount, String currency) {
    final label = currency.isEmpty ? 'THB' : currency.toUpperCase();
    return '$label ${amount.toStringAsFixed(2)}';
  }

  Future<void> _handlePaymentProcessing(double totalPrice) async {
    if (_selectedPaymentMethod == null) {
      Get.snackbar(
        'เลือกช่องทางชำระเงิน',
        'กรุณาเลือกวิธีการชำระเงินก่อนทำรายการ',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange[300],
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final cartItems = _cartLines();
    if (cartItems.isEmpty) {
      Get.snackbar(
        'ตะกร้าว่าง',
        'ไม่พบสินค้าในตะกร้า กรุณาเพิ่มสินค้าใหม่อีกครั้ง',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[300],
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null || apiUrl.isEmpty) {
        throw Exception('API_URL is not configured');
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        setState(() => _isProcessing = false);
        Get.snackbar(
          'ยังไม่ได้เข้าสู่ระบบ',
          'กรุณาเข้าสู่ระบบก่อนทำรายการชำระเงิน',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[300],
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      final List<int> orderIds = cartItems
          .map((item) => item.product.productId)
          .toList();

      final body = <String, dynamic>{
        'amount': totalPrice,
        'currency': 'thb',
        'order_ids': orderIds,
        'code': _selectedPaymentMethod,
      };

      final response = await http.post(
        Uri.parse('$apiUrl/api/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        String message =
            'สร้างคำสั่งชำระเงินไม่สำเร็จ (${response.statusCode})';
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['message'] != null) {
            message = data['message'].toString();
          }
        } catch (_) {}

        setState(() => _isProcessing = false);
        Get.snackbar(
          'เกิดข้อผิดพลาด',
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[300],
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final qrUrl = (data['qrcode_url'] ?? data['qr_code_url'])?.toString();
      final sessionId = data['payment_session_id']?.toString();

      if (qrUrl == null || qrUrl.isEmpty || sessionId == null) {
        setState(() => _isProcessing = false);
        Get.snackbar(
          'ข้อมูลไม่ถูกต้อง',
          'ระบบไม่ได้รับ QR หรือ session สำหรับการชำระเงิน',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[300],
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      setState(() => _isProcessing = false);

      final finalCart = Map<String, Product>.from(productCarts);
      final finalAmounts = Map<String, int>.from(productAmounts);
      final finalMethod = _selectedPaymentMethod!;

      Get.to(
        () => PaymentProcessScreen(
          productCarts: finalCart,
          productAmounts: finalAmounts,
          totalPrice: totalPrice,
          selectedPaymentMethod: finalMethod,
          onPaymentSuccess: () async {
            await deleteCache();
          },
          initialQrCodeUrl: qrUrl,
          initialPaymentSessionId: sessionId,
        ),
        transition: Transition.downToUp,
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      Get.snackbar(
        'ไม่สามารถเริ่มการชำระเงินได้',
        'กรุณาลองใหม่อีกครั้ง',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[300],
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}

class _CartLineItem {
  const _CartLineItem({
    required this.id,
    required this.product,
    required this.quantity,
  });

  final String id;
  final Product product;
  final int quantity;

  double get lineTotal => product.price.toDouble() * quantity;
}

class _PaymentMethodOption {
  const _PaymentMethodOption({
    required this.code,
    required this.label,
    required this.icon,
    this.description,
  });

  final String code;
  final String label;
  final IconData icon;
  final String? description;
}
