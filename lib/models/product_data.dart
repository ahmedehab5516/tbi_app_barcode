import 'package:get/get.dart';

class ProductResponse {
  final int status;
  final List<Product> data;

  ProductResponse({required this.status, required this.data});

  /// Factory method to create an instance from JSON
  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      status: json['status'] as int,
      data: (json['data'] as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert the instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}
class Product {
  final String id;
  final String itemLookupCode;
  final String description;
  final String categoryCode;
  final String categoryName;
  RxInt quantity;

  Product({
    required this.id,
    required this.itemLookupCode,
    required this.description,
    required this.categoryCode,
    required this.categoryName,
    required int quantity,
  }) : quantity = RxInt(quantity);

  // Update fromJson and toJson methods accordingly
  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        itemLookupCode: json['itemLookupCode'],
        description: json['description'],
        categoryCode: json['categoryCode'],
        categoryName: json['categoryName'],
        quantity: json['quantity'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemLookupCode': itemLookupCode,
        'description': description,
        'categoryCode': categoryCode,
        'categoryName': categoryName,
        'quantity': quantity.value,
      };
}