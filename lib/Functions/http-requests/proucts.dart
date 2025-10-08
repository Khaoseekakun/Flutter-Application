import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:test1/Interfaces/interface.ProductsData.dart';

Future<Product> getProducts() async {
  final response = await http.get(
    Uri.parse('https://dummyjson.com/products'), // replace with your API
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return Product.fromJson(data);
  } else {
    throw Exception('Failed to load data');
  }
}
