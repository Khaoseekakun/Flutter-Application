import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:test1/Components/AppBar.dart';
import 'package:test1/Interfaces/interface.ProductsData.dart';
import 'package:test1/Screens/PaymentProcess.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    loadCartFromCache();
  }

  Future<void> loadCartFromCache() async {
    final cacheManager = DefaultCacheManager();
    final cachedFile = await cacheManager.getFileFromCache('cart.json');

    if (cachedFile != null) {
      final jsonString = await cachedFile.file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);

      productCarts = (data['carts'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Product.fromJson(value)),
      );

      productAmounts = (data['amounts'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> deleteCache() async {
    await DefaultCacheManager().removeFile('cart.json');
    setState(() {
      productCarts.clear();
      productAmounts.clear();
    });
  }

  Future<void> saveCartToCache() async {
    try {
      final Map<String, dynamic> data = {
        'carts': productCarts.map((k, v) {
          return MapEntry(k, v.toJson());
        }),
        'amounts': productAmounts,
      };
      final jsonString = jsonEncode(data);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      await DefaultCacheManager().putFile(
        'cart.json',
        bytes,
        fileExtension: 'json',
      );
    } catch (e) {
      print('Error saving cart to cache: $e');
    }
  }

  void _removeItem(String productId) {
    if (!productCarts.containsKey(productId)) return;
    setState(() {
      _lastRemovedId = productId;
      _lastRemovedProduct = productCarts.remove(productId);
      _lastRemovedAmount = productAmounts.remove(productId);
    });

    saveCartToCache();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // guard against calling setState after dispose
            if (!mounted) return;
            // restore
            if (_lastRemovedId != null && _lastRemovedProduct != null) {
              setState(() {
                productCarts[_lastRemovedId!] = _lastRemovedProduct!;
                productAmounts[_lastRemovedId!] = _lastRemovedAmount ?? 1;
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

  @override
  Widget build(BuildContext context) {
    double totalPrice = 0.0;

    if (productAmounts.isNotEmpty) {
      productAmounts.forEach((productId, quantity) {
        Product? product = productCarts[productId];
        if (product != null) {
          totalPrice += product.price * quantity;
        }
      });
    }

    return Scaffold(
      appBar: CustomAppBar(title: "Pos | Payment", showBackButton: true),
      body: SafeArea(
        bottom: false,
        child: Container(
          color: const Color.fromARGB(255, 242, 242, 242),
          child: Column(
            children: [
              Expanded(child: isLoading ? _buildLoading() : _buildGrid()),
              _buildSummaryBar(context, totalPrice),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildGrid() {
    if (productCarts.isEmpty) {
      return const Center(child: Text("Your cart is empty"));
    }

    final keys = productCarts.keys.toList();
    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, index) {
        String productId = keys[index];
        Product product = productCarts[productId]!;
        int quantity = productAmounts[productId] ?? 0;

        return Dismissible(
          key: ValueKey(productId),
          onDismissed: (direction) {
            _removeItem(productId);
          },
          child: Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (context) {
                    return DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.65,
                      minChildSize: 0.3,
                      maxChildSize: 0.95,
                      builder: (_, controller) {
                        int tempQuantity = productAmounts[productId] ?? 1;
                        return StatefulBuilder(
                          builder: (context, setModalState) {
                            return SingleChildScrollView(
                              controller: controller,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  if (product.images != null &&
                                      product.images!.isNotEmpty)
                                    Center(
                                      child: Image.network(
                                        product.images!.first,
                                        width: 180,
                                        height: 180,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 180),
                                  const SizedBox(height: 12),
                                  Text(
                                    product.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    product.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "\$${product.price.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Quantity: $quantity",
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Edit Order',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          if (tempQuantity > 1) {
                                            setModalState(() => tempQuantity--);
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          '$tempQuantity',
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setModalState(() => tempQuantity++);
                                        },
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            // Save quantity change
                                            setState(() {
                                              productAmounts[productId] =
                                                  tempQuantity;
                                            });
                                            saveCartToCache();
                                            Navigator.of(context).pop();
                                          },
                                          icon: const Icon(Icons.save),
                                          label: const Text('Save'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _removeItem(productId);
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          label: const Text('Remove'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
              child: ListTile(
                leading: product.images != null && product.images!.isNotEmpty
                    ? Image.network(
                        product.images!.first,
                        width: 50,
                        height: 50,
                      )
                    : const SizedBox(width: 50, height: 50),
                title: Text(
                  '${product.title.length > 18 ? '${product.title.substring(0, 18)}..' : product.title} (x$quantity)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Text(
                  " \$${(product.price * quantity).toStringAsFixed(2)} ",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: Text("\$${product.price.toStringAsFixed(2)}"),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isProcessing = false;
  String? _selectedPaymentMethod;
  Widget _buildSummaryBar(BuildContext context, double totalPrice) {
    final double tax = totalPrice * 0.07;
    final double subtotal = totalPrice - tax;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: MediaQuery.of(context).size.height * 0.5,
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text('\$${subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax', style: TextStyle(color: Colors.grey)),
                        Text('\$${tax.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildPaymentOption(
                      title: 'Cash',
                      icon: Icons.money,
                      value: 'cash',
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentOption(
                      title: 'QR PromptPay',
                      icon: Icons.qr_code,
                      value: 'promptpay',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blue,
                ),
                onPressed: (_selectedPaymentMethod == null || _isProcessing)
                    ? null
                    : () {
                        _handlePaymentProcessing(totalPrice);
                      },
                child: _isProcessing
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        'Confirm & Pay \$${totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required IconData icon,
    required String value,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedPaymentMethod == value
                ? Colors.blue
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            Radio<String>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: _selectedPaymentMethod,
              // ignore: deprecated_member_use
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPaymentMethod = newValue;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePaymentProcessing(double totalPrice) async {
    if (_selectedPaymentMethod == null) {
      Get.snackbar(
        'Error',
        'Please select a payment method.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[300],
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null || apiUrl.isEmpty) {
        throw Exception('API_URL is not configured');
      }

      // Load JWT token for authorized requests
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        setState(() => _isProcessing = false);
        Get.snackbar(
          'Not logged in',
          'Please login before making a payment.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[300],
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      // Build order IDs from cart
      final List<int> orderIds = [];
      productCarts.forEach((key, product) {
        final qty = productAmounts[key] ?? 0;
        if (qty > 0) {
          orderIds.add(product.id);
        }
      });

      final body = <String, dynamic>{
        'amount': totalPrice,
        'currency': 'thb',
        'order_ids': orderIds,
        'code': _selectedPaymentMethod,
        // 'email': ..., 'name': ... // add if you have them
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

      
        String message = 'Payment creation failed (${response.statusCode}).';
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['message'] != null) message = data['message'].toString();
        } catch (_) {}
        print("${message}");
        setState(() => _isProcessing = false);
        Get.snackbar(
          'Payment Error',
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
          'Payment Error',
          'Invalid response from server.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[300],
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      setState(() => _isProcessing = false);

      // Hand off to PaymentProcess screen with initial session + QR
      final finalCart = Map<String, Product>.from(productCarts);
      final finalAmounts = Map<String, int>.from(productAmounts);
      final finalPaymentMethod = _selectedPaymentMethod!;

      Get.to(
        () => PaymentProcessScreen(
          productCarts: finalCart,
          productAmounts: finalAmounts,
          totalPrice: totalPrice,
          selectedPaymentMethod: finalPaymentMethod,
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
        'Payment Error',
        'Failed to start payment. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[300],
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}
