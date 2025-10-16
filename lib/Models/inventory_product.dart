class InventoryProduct {
  final int? productId;
  final String sku;
  final String? name;
  final String? description;
  final String? shortDesc;
  final double? price;
  final String? currency;
  final int stockQuantity;
  final bool? isActive;
  final int? categoryId;
  final String? vendor;
  final double? weightKg;
  final String? dimensions;
  final String? metadata;
  final List<String> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InventoryProduct({
    required this.productId,
    required this.sku,
    required this.name,
    required this.description,
    required this.shortDesc,
    required this.price,
    required this.currency,
    required this.stockQuantity,
    required this.isActive,
    required this.categoryId,
    required this.vendor,
    required this.weightKg,
    required this.dimensions,
    required this.metadata,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryProduct.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value.toString()) ?? 0;
    }

    DateTime? toDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    List<String> toImages(dynamic value) {
      if (value == null) return <String>[];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return <String>[];
    }

    return InventoryProduct(
      productId: json['productId'] as int? ??
          json['ProductId'] as int? ??
          int.tryParse(json['id']?.toString() ?? ''),
      sku: json['sku']?.toString() ?? json['Sku']?.toString() ?? '',
      name: json['name']?.toString() ?? json['Name']?.toString(),
      description:
          json['description']?.toString() ?? json['Description']?.toString(),
      shortDesc:
          json['shortDesc']?.toString() ?? json['ShortDesc']?.toString(),
      price: toDouble(json['price'] ?? json['Price']),
      currency: json['currency']?.toString() ?? json['Currency']?.toString(),
      stockQuantity: toInt(json['stockQuantity'] ?? json['StockQuantity']),
      isActive: json['isActive'] as bool? ?? json['IsActive'] as bool?,
      categoryId: json['categoryId'] as int? ?? json['CategoryId'] as int?,
      vendor: json['vendor']?.toString() ?? json['Vendor']?.toString(),
      weightKg: toDouble(json['weightKg'] ?? json['WeightKg']),
      dimensions:
          json['dimensions']?.toString() ?? json['Dimensions']?.toString(),
      metadata: json['metadata']?.toString() ?? json['Metadata']?.toString(),
      images: toImages(json['images'] ?? json['Images']),
      createdAt: toDate(json['createdAt'] ?? json['CreatedAt']),
      updatedAt: toDate(json['updatedAt'] ?? json['UpdatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'sku': sku,
      'name': name,
      'description': description,
      'shortDesc': shortDesc,
      'price': price,
      'currency': currency,
      'stockQuantity': stockQuantity,
      'isActive': isActive,
      'categoryId': categoryId,
      'vendor': vendor,
      'weightKg': weightKg,
      'dimensions': dimensions,
      'metadata': metadata,
      'images': images,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }

  InventoryProduct copyWith({
    int? productId,
    String? sku,
    String? name,
    String? description,
    String? shortDesc,
    double? price,
    String? currency,
    int? stockQuantity,
    bool? isActive,
    int? categoryId,
    String? vendor,
    double? weightKg,
    String? dimensions,
    String? metadata,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryProduct(
      productId: productId ?? this.productId,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      shortDesc: shortDesc ?? this.shortDesc,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      categoryId: categoryId ?? this.categoryId,
      vendor: vendor ?? this.vendor,
      weightKg: weightKg ?? this.weightKg,
      dimensions: dimensions ?? this.dimensions,
      metadata: metadata ?? this.metadata,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
