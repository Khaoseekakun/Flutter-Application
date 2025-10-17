import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test1/Models/inventory_product.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<InventoryProduct> _allProducts = <InventoryProduct>[];
  List<InventoryProduct> _visibleProducts = <InventoryProduct>[];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_applySearchFilter);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_applySearchFilter)
      ..dispose();
    super.dispose();
  }

  Future<void> _fetchProducts({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    }

    try {
      final String? apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null || apiUrl.isEmpty) {
        throw Exception('API_URL is not configured.');
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      final http.Response response = await http.get(
        Uri.parse('$apiUrl/api/products'),
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load products (${response.statusCode}).');
      }

      final dynamic body = jsonDecode(response.body);
      final List<dynamic> items = body is List
          ? body
          : (body['data'] as List<dynamic>? ?? <dynamic>[]);

      final List<InventoryProduct> products = items
          .map(
            (dynamic item) =>
                InventoryProduct.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _allProducts
          ..clear()
          ..addAll(products);
      });
      _applySearchFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _applySearchFilter() {
    final String query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _visibleProducts = List<InventoryProduct>.from(_allProducts);
      } else {
        _visibleProducts = _allProducts.where((InventoryProduct product) {
          final String name = (product.name ?? '').toLowerCase();
          final String sku = product.sku.toLowerCase();
          final String vendor = (product.vendor ?? '').toLowerCase();
          return name.contains(query) ||
              sku.contains(query) ||
              vendor.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _confirmAndDeleteProduct(InventoryProduct product) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove product'),
          content: Text(
            'Delete ${product.name ?? product.sku}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _deleteProduct(product);
  }

  Future<void> _deleteProduct(InventoryProduct product) async {
    try {
      final String? apiUrl = dotenv.env['API_URL'];
      if (apiUrl == null || apiUrl.isEmpty) {
        throw Exception('API_URL is not configured.');
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      final Uri endpoint = product.productId != null
          ? Uri.parse('$apiUrl/api/products/${product.productId}')
          : Uri.parse('$apiUrl/api/products/sku/${product.sku}');

      final http.Response response = await http.delete(
        endpoint,
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        String message = 'Failed to delete product.';
        try {
          final Map<String, dynamic> data =
              jsonDecode(response.body) as Map<String, dynamic>;
          message = data['message']?.toString() ?? message;
        } catch (_) {}
        throw Exception(message);
      }

      if (!mounted) return;
      setState(() {
        _allProducts.removeWhere(
          (InventoryProduct p) =>
              p.productId == product.productId && p.productId != null ||
              (product.productId == null && p.sku == product.sku),
        );
      });
      _applySearchFilter();

      Get.snackbar(
        'Product removed',
        '${product.name ?? product.sku} deleted.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green[400],
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Delete Failed',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[300],
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> _showEditDialog(InventoryProduct product) async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(
      text: product.name ?? '',
    );
    final TextEditingController shortDescController = TextEditingController(
      text: product.shortDesc ?? '',
    );
    final TextEditingController descController = TextEditingController(
      text: product.description ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: product.price != null ? product.price!.toStringAsFixed(2) : '',
    );
    final TextEditingController currencyController = TextEditingController(
      text: product.currency ?? 'THB',
    );
    final TextEditingController stockController = TextEditingController(
      text: product.stockQuantity.toString(),
    );
    final TextEditingController categoryController = TextEditingController(
      text: product.categoryId?.toString() ?? '',
    );
    final TextEditingController vendorController = TextEditingController(
      text: product.vendor ?? '',
    );
    final TextEditingController weightController = TextEditingController(
      text: product.weightKg?.toString() ?? '',
    );
    final TextEditingController dimensionsController = TextEditingController(
      text: product.dimensions ?? '',
    );
    final TextEditingController metadataController = TextEditingController(
      text: product.metadata ?? '',
    );
    final TextEditingController imagesController = TextEditingController(
      text: product.images.join('\n'),
    );

    bool isActive = product.isActive ?? true;
    bool isSubmitting = false;
    bool? dialogResult;

    void disposeControllers() {
      nameController.dispose();
      shortDescController.dispose();
      descController.dispose();
      priceController.dispose();
      currencyController.dispose();
      stockController.dispose();
      categoryController.dispose();
      vendorController.dispose();
      weightController.dispose();
      dimensionsController.dispose();
      metadataController.dispose();
      imagesController.dispose();
    }

    try {
      dialogResult = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setLocalState) {
              return AlertDialog(
                title: Text('Edit ${product.name ?? product.sku}'),
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
                          validator: (String? value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter product name'
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
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter price';
                            }
                            return double.tryParse(value.replaceAll(',', '')) ==
                                    null
                                ? 'Invalid price'
                                : null;
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
                            labelText: 'Stock Quantity',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter stock';
                            }
                            return int.tryParse(value) == null
                                ? 'Invalid quantity'
                                : null;
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
                        TextFormField(
                          controller: weightController,
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        TextFormField(
                          controller: dimensionsController,
                          decoration: const InputDecoration(
                            labelText: 'Dimensions',
                          ),
                        ),
                        TextFormField(
                          controller: metadataController,
                          decoration: const InputDecoration(
                            labelText: 'Metadata',
                          ),
                        ),
                        TextFormField(
                          controller: imagesController,
                          decoration: const InputDecoration(
                            labelText: 'Image URLs (one per line)',
                          ),
                          maxLines: 3,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active'),
                          value: isActive,
                          onChanged: (bool value) {
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
                              await _updateProduct(
                                product: product,
                                name: nameController.text.trim(),
                                shortDesc: shortDescController.text.trim(),
                                description: descController.text.trim(),
                                price: double.parse(
                                  priceController.text.replaceAll(',', ''),
                                ),
                                currency: currencyController.text.trim(),
                                stock: int.parse(stockController.text.trim()),
                                categoryId:
                                    categoryController.text.trim().isEmpty
                                    ? null
                                    : int.parse(categoryController.text.trim()),
                                vendor: vendorController.text.trim(),
                                weightKg: weightController.text.trim().isEmpty
                                    ? null
                                    : double.parse(
                                        weightController.text.trim(),
                                      ),
                                dimensions: dimensionsController.text.trim(),
                                metadata: metadataController.text.trim(),
                                images: _parseImages(imagesController.text),
                                isActive: isActive,
                              );

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
                        : const Text('Save changes'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        disposeControllers();
      });
    }

    if (dialogResult == true) {
      Get.snackbar(
        'Product updated',
        '${product.name ?? product.sku} saved.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green[400],
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> _updateProduct({
    required InventoryProduct product,
    required String name,
    required String shortDesc,
    required String description,
    required double price,
    required String currency,
    required int stock,
    required bool isActive,
    int? categoryId,
    String? vendor,
    double? weightKg,
    String? dimensions,
    String? metadata,
    required List<String> images,
  }) async {
    final String? apiUrl = dotenv.env['API_URL'];
    if (apiUrl == null || apiUrl.isEmpty) {
      throw Exception('API_URL is not configured.');
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final Map<String, dynamic> payload = <String, dynamic>{
      'sku': product.sku,
      'name': name,
      'description': description.isEmpty ? null : description,
      'shortDesc': shortDesc.isEmpty ? null : shortDesc,
      'price': price,
      'currency': currency.isEmpty ? 'THB' : currency,
      'stockQuantity': stock,
      'isActive': isActive,
      'categoryId': categoryId,
      'vendor': vendor?.isEmpty ?? true ? null : vendor,
      'weightKg': weightKg,
      'dimensions': dimensions?.isEmpty ?? true ? null : dimensions,
      'metadata': metadata?.isEmpty ?? true ? null : metadata,
      'images': images,
    }..removeWhere((String key, dynamic value) => value == null);

    final Uri endpoint = product.productId != null
        ? Uri.parse('$apiUrl/api/products/${product.productId}')
        : Uri.parse('$apiUrl/api/products/sku/${product.sku}');

    final http.Response response = await http.put(
      endpoint,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      String message = 'Failed to update product.';
      try {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        message = data['message']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    final Map<String, dynamic> updatedJson =
        jsonDecode(response.body) as Map<String, dynamic>;
    final InventoryProduct updatedProduct = InventoryProduct.fromJson(
      updatedJson['product'],
    );

    if (!mounted) return;

    setState(() {
      final int index = _allProducts.indexWhere((InventoryProduct item) {
        if (product.productId != null) {
          return item.productId == product.productId;
        }
        return item.sku == product.sku;
      });
      if (index != -1) {
        _allProducts[index] = updatedProduct;
      }
    });
    _applySearchFilter();
  }

  List<String> _parseImages(String raw) {
    if (raw.trim().isEmpty) return <String>[];
    final List<String> fragments = raw
        .split(RegExp(r'[\n,]'))
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList();
    return fragments;
  }

  String _formatUpdatedAt(InventoryProduct product) {
    final DateTime? updated = product.updatedAt ?? product.createdAt;
    if (updated == null) return '—';
    return DateFormat('d MMM yyyy · HH:mm').format(updated);
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search by name, SKU, or vendor',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _fetchProducts(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_visibleProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                _searchController.text.isEmpty
                    ? 'No products found.'
                    : 'No products matched “${_searchController.text}”.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchProducts(showLoader: false),
      child: ListView.builder(
        itemCount: _visibleProducts.length,
        padding: const EdgeInsets.only(bottom: 24),
        itemBuilder: (BuildContext context, int index) {
          final InventoryProduct product = _visibleProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(InventoryProduct product) {
    final String? imageUrl = product.images.isNotEmpty
        ? product.images.first
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                )
              : Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey[200],
                  child: const Icon(Icons.inventory_2_outlined),
                ),
        ),
        title: Text(product.name ?? product.sku),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SKU: ${product.sku}'),
              Text(
                'Price: ${product.price?.toStringAsFixed(2) ?? '-'} ${product.currency ?? ''}',
              ),
              Text('Stock: ${product.stockQuantity}'),
              Text('Updated: ${_formatUpdatedAt(product)}'),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String value) {
            switch (value) {
              case 'edit':
                _showEditDialog(product);
                break;
              case 'delete':
                _confirmAndDeleteProduct(product);
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Remove'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading || _isRefreshing
                ? null
                : () => _fetchProducts(),
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }
}
