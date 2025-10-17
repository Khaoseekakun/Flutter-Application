import 'package:json_annotation/json_annotation.dart';
import 'package:test1/Interfaces/interface.ProductsDimensions.dart';
import 'package:test1/Interfaces/interface.ProductsMeta.dart';
part 'interface.ProductsData.g.dart';

@JsonSerializable()
class Product {
  final int productId;
  final String sku;
  final String name;
  final String? description;
  final String? shortDesc;
  final num price;
  final String currency;
  final num stockQuantity;
  final bool isActive;
  final num? weightKg;
  final dynamic dimensions;
  final dynamic metadata;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.productId,
    required this.sku,
    required this.name,
    required this.price,
    required this.currency,
    required this.stockQuantity,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.shortDesc,
    this.weightKg,
    this.dimensions,
    this.metadata,
    this.images = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
