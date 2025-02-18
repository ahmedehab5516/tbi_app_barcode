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
  final int id;
  final String itemLookupCode;
  final String description;
  final String categoryCode;
  final String categoryName;
  int quantity; // Added field (not required, defaults to 0)

  Product({
    required this.id,
    required this.itemLookupCode,
    required this.description,
    required this.categoryCode,
    required this.categoryName,
    this.quantity = 0, // Default value set to 0
  });

  // From JSON constructor to parse the data
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      itemLookupCode: json['itemLookupCode'] as String,
      description: json['description'] as String,
      categoryCode: json['categoryCode'] as String,
      categoryName: json['categoryName'] as String,
      quantity: json['quantity'] != null ? json['quantity'] as int : 0, // Handle null case
    );
  }

  // To JSON method to convert the object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemLookupCode': itemLookupCode,
      'description': description,
      'categoryCode': categoryCode,
      'categoryName': categoryName,
      'quantity': quantity, // Include quantity in JSON output
    };
  }
}
