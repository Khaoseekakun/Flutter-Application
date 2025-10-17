// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interface.ProductsData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  productId: (json['productId'] as num).toInt(),
  sku: json['sku'] as String,
  name: json['name'] as String,
  price: json['price'] as num,
  currency: json['currency'] as String,
  stockQuantity: json['stockQuantity'] as num,
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  description: json['description'] as String?,
  shortDesc: json['shortDesc'] as String?,
  weightKg: json['weightKg'] as num?,
  dimensions: json['dimensions'],
  metadata: json['metadata'],
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'productId': instance.productId,
  'sku': instance.sku,
  'name': instance.name,
  'description': instance.description,
  'shortDesc': instance.shortDesc,
  'price': instance.price,
  'currency': instance.currency,
  'stockQuantity': instance.stockQuantity,
  'isActive': instance.isActive,
  'weightKg': instance.weightKg,
  'dimensions': instance.dimensions,
  'metadata': instance.metadata,
  'images': instance.images,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
