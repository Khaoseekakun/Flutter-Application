import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test1/Models/inventory_product.dart';

class AddProductsScreen extends StatefulWidget {
  const AddProductsScreen({super.key});

  @override
  State<AddProductsScreen> createState() => _AddProductsScreenState();
}

class _AddProductsScreenState extends State<AddProductsScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: true,
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
  );
  final TextEditingController _manualSkuController = TextEditingController();

  bool _isHandlingBarcode = false;
  InventoryProduct? _lastProduct;
  String? _lastSku;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualSkuController.dispose();
    super.dispose();
  }

  Future<void> _pauseCamera() async {
    try {
      await _scannerController.stop();
    } catch (_) {}
  }

  Future<void> _resumeCameraIfIdle() async {
    if (!mounted || _isHandlingBarcode) return;
    try {
      await _scannerController.start();
    } catch (_) {}
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!mounted || _isHandlingBarcode) return;

    Barcode? picked;
    for (final Barcode barcode in capture.barcodes) {
      final String? raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        picked = barcode;
        break;
      }
    }

    final String? rawValue = picked?.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) return;

    if (int.parse(rawValue).isNaN) return;

    setState(() {
      _isHandlingBarcode = true;
    });

    await _pauseCamera();

    try {
      await _handleScannedSku(rawValue);
    } catch (e) {
      Get.snackbar(
        'Scan Failed',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[300],
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isHandlingBarcode = false;
        });
        await _resumeCameraIfIdle();
      }
    }
  }

  Future<void> _handleScannedSku(String sku) async {
    setState(() {
      _lastSku = sku;
    });

    final InventoryProduct? product = await _fetchProductBySku(sku);

    if (!mounted) return;

    if (product == null) {
      final bool created = await _showCreateProductDialog(sku);
      if (created) {
        Get.snackbar(
          'Product Added',
          'New product $sku added successfully.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green[400],
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } else {
      final bool updated = await _showUpdateStockDialog(product);
      if (updated) {
        Get.snackbar(
          'Stock Updated',
          'Inventory for ${product.sku} updated.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green[400],
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }

  Future<InventoryProduct?> _fetchProductBySku(String sku) async {
    final String? apiUrl = dotenv.env['API_URL'];
    if (apiUrl == null || apiUrl.isEmpty) {
      throw Exception('API_URL is not configured.');
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    // Adjust the endpoint to match your API.
    final Uri uri = Uri.parse(
      '$apiUrl/api/products/lookup',
    ).replace(queryParameters: {'sku': sku});

    final http.Response response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 404) {
      setState(() => _lastProduct = null);
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('Lookup failed (${response.statusCode}).');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] == 'success' && data['product'] != null) {
      final InventoryProduct product = InventoryProduct.fromJson(
        data['product'],
      );
      setState(() => _lastProduct = product);
      return product;
    }

    return null;
  }

  Future<bool> _showCreateProductDialog(String sku) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final shortDescController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final currencyController = TextEditingController(text: 'THB');
    final stockController = TextEditingController(text: '0');
    final categoryController = TextEditingController();
    final vendorController = TextEditingController();

    bool isActive = true;
    bool isSubmitting = false;
    bool? dialogResult;

    await _pauseCamera();

    if (!mounted) {
      nameController.dispose();
      shortDescController.dispose();
      descController.dispose();
      priceController.dispose();
      currencyController.dispose();
      stockController.dispose();
      categoryController.dispose();
      vendorController.dispose();
      await _resumeCameraIfIdle();
      return false;
    }

    try {
      dialogResult = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setLocalState) {
              return AlertDialog(
                title: Text('New Product - $sku'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Product Name',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Please enter product name'
                              : null,
                        ),
                        TextFormField(
                          controller: shortDescController,
                          decoration: const InputDecoration(
                            labelText: 'Short Description',
                          ),
                        ),
                        TextFormField(
                          controller: descController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          maxLines: 3,
                        ),
                        TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'Price'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter price';
                            }
                            final double? parsed = double.tryParse(
                              value.replaceAll(',', ''),
                            );
                            if (parsed == null) {
                              return 'Invalid price';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: currencyController,
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                          ),
                        ),
                        TextFormField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Initial Stock Quantity',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter stock quantity';
                            }
                            final int? parsed = int.tryParse(value);
                            if (parsed == null || parsed < 0) {
                              return 'Invalid quantity';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Category Id',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                        ),
                        TextFormField(
                          controller: vendorController,
                          decoration: const InputDecoration(
                            labelText: 'Vendor',
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active'),
                          value: isActive,
                          onChanged: (value) {
                            setLocalState(() => isActive = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setLocalState(() => isSubmitting = true);

                            try {
                              final double price = double.parse(
                                priceController.text.replaceAll(',', ''),
                              );
                              final int stock = int.parse(
                                stockController.text.trim(),
                              );
                              final int? categoryId = int.tryParse(
                                categoryController.text.trim(),
                              );

                              final InventoryProduct
                              product = await _createProduct(
                                sku: sku,
                                name: nameController.text.trim(),
                                shortDesc:
                                    shortDescController.text.trim().isEmpty
                                    ? null
                                    : shortDescController.text.trim(),
                                description: descController.text.trim().isEmpty
                                    ? null
                                    : descController.text.trim(),
                                price: price,
                                currency: currencyController.text.trim().isEmpty
                                    ? 'THB'
                                    : currencyController.text.trim(),
                                stock: stock,
                                isActive: isActive,
                                categoryId: categoryId,
                                vendor: vendorController.text.trim().isEmpty
                                    ? null
                                    : vendorController.text.trim(),
                              );

                              if (mounted) {
                                setState(() => _lastProduct = product);
                              }

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext, true);
                              }
                            } catch (e) {
                              setLocalState(() => isSubmitting = false);
                              Get.snackbar(
                                'Create Failed',
                                e.toString(),
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: Colors.red[300],
                                colorText: Colors.white,
                                margin: const EdgeInsets.all(16),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      shortDescController.dispose();
      descController.dispose();
      priceController.dispose();
      currencyController.dispose();
      stockController.dispose();
      categoryController.dispose();
      vendorController.dispose();

      await _resumeCameraIfIdle();
    }

    return dialogResult ?? false;
  }

  Future<bool> _showUpdateStockDialog(InventoryProduct product) async {
    final TextEditingController addAmountController = TextEditingController(
      text: '1',
    );

    bool isSubmitting = false;
    bool? dialogResult;

    await _pauseCamera();

    if (!mounted) {
      addAmountController.dispose();
      await _resumeCameraIfIdle();
      return false;
    }

    try {
      dialogResult = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setLocalState) {
              return AlertDialog(
                title: Text('Update Stock - ${product.sku}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name ?? 'Unnamed product'),
                    const SizedBox(height: 8),
                    Text('Current stock: ${product.stockQuantity}'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Add quantity',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final int? toAdd = int.tryParse(
                              addAmountController.text.trim(),
                            );
                            if (toAdd == null || toAdd <= 0) {
                              Get.snackbar(
                                'Invalid quantity',
                                'Enter a positive amount to add.',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: Colors.orange[400],
                                colorText: Colors.white,
                                margin: const EdgeInsets.all(16),
                              );
                              return;
                            }

                            setLocalState(() => isSubmitting = true);

                            try {
                              final InventoryProduct updated =
                                  await _updateProductStock(
                                    product: product,
                                    newStock: product.stockQuantity + toAdd,
                                  );

                              if (mounted) {
                                setState(() => _lastProduct = updated);
                              }

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext, true);
                              }
                            } catch (e) {
                              setLocalState(() => isSubmitting = false);
                              Get.snackbar(
                                'Update Failed',
                                e.toString(),
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: Colors.red[300],
                                colorText: Colors.white,
                                margin: const EdgeInsets.all(16),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      addAmountController.dispose();
      await _resumeCameraIfIdle();
    }

    return dialogResult ?? false;
  }

  Future<InventoryProduct> _createProduct({
    required String sku,
    required String name,
    String? shortDesc,
    String? description,
    required double price,
    required String currency,
    required int stock,
    required bool isActive,
    int? categoryId,
    String? vendor,
  }) async {
    final String? apiUrl = dotenv.env['API_URL'];
    if (apiUrl == null || apiUrl.isEmpty) {
      throw Exception('API_URL is not configured.');
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final Map<String, dynamic> payload = {
      'sku': sku,
      'name': name,
      'shortDesc': shortDesc,
      'description': description,
      'price': price,
      'currency': currency,
      'stockQuantity': stock,
      'isActive': isActive,
      'categoryId': categoryId,
      'vendor': vendor,
    }..removeWhere((key, value) => value == null);

    final http.Response response = await http.post(
      Uri.parse('$apiUrl/api/products'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      String message = 'Create failed (${response.statusCode}).';
      try {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        message = data['message']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    return InventoryProduct.fromJson(data);
  }

  Future<InventoryProduct> _updateProductStock({
    required InventoryProduct product,
    required int newStock,
  }) async {
    final String? apiUrl = dotenv.env['API_URL'];
    if (apiUrl == null || apiUrl.isEmpty) {
      throw Exception('API_URL is not configured.');
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    Uri? uri;
    if (product.productId != null) {
      uri = Uri.parse('$apiUrl/api/products/${product.productId}/stock');
    } else {
      uri = Uri.parse('$apiUrl/api/products/sku/${product.sku}/stock');
    }

    final http.Response response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'stockQuantity': newStock}),
    );

    if (response.statusCode != 200) {
      String message = 'Update failed (${response.statusCode}).';
      try {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        message = data['message']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    return InventoryProduct.fromJson(data);
  }

  Future<void> _enterSkuManually() async {
    if (_isHandlingBarcode) return;

    _manualSkuController.text = _lastSku ?? '';

    setState(() {
      _isHandlingBarcode = true;
    });

    await _pauseCamera();

    if (!mounted) {
      return;
    }

    try {
      final bool? shouldLookup = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Enter SKU / Barcode'),
            content: TextField(
              controller: _manualSkuController,
              decoration: const InputDecoration(labelText: 'SKU'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );

      final String manualSku = _manualSkuController.text.trim();
      _manualSkuController.clear();

      if (shouldLookup == true && manualSku.isNotEmpty) {
        await _handleScannedSku(manualSku);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isHandlingBarcode = false;
        });
        await _resumeCameraIfIdle();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Products to Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Enter SKU manually',
            onPressed: _enterSkuManually,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),
                IgnorePointer(
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor:
                          0.8, // adjust to control square size relative to width
                      child: AspectRatio(
                        aspectRatio: 1, // keep it a square
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 3,
                    color: Colors.red,
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                  ),
                ),

                Positioned(
                  bottom: 60,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isHandlingBarcode
                              ? 'Processing...'
                              : 'Align barcode within the frame',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_lastSku != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last scanned: $_lastSku',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_lastProduct != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_lastProduct!.name ?? 'Unnamed product'),
                          const SizedBox(height: 4),
                          Text(
                            'Stock: ${_lastProduct!.stockQuantity}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          if (_lastProduct!.price != null)
                            Text(
                              'Price: ${_lastProduct!.price!.toStringAsFixed(2)} ${_lastProduct!.currency ?? ''}',
                            ),
                        ],
                      )
                    else
                      const Text('No product found.'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
