import 'package:json_annotation/json_annotation.dart';
part 'interface.ProductsDimensions.g.dart';

@JsonSerializable()
class Dimensions {
  final double width;
  final double height;
  final double depth;

  Dimensions({required this.width, required this.height, required this.depth});

  factory Dimensions.fromJson(Map<String, dynamic> json) => _$DimensionsFromJson(json);
  Map<String, dynamic> toJson() => _$DimensionsToJson(this);
}