class ProductData {
  final int status;
  final List<Product> data;

  ProductData({
    required this.status,
    required this.data,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      status: json['status'],
      data: (json['data'] as List).map((v) => Product.fromJson(v)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((v) => v.toJson()).toList(),
    };
  }

  ProductData copyWith({
    int? status,
    List<Product>? data,
  }) {
    return ProductData(
      status: status ?? this.status,
      data: data ?? this.data,
    );
  }
}

class Product {
  final int id;
  final String itemLookupCode;
  final String description;

  Product({
    required this.id,
    required this.itemLookupCode,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      itemLookupCode: json['itemLookupCode'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemLookupCode': itemLookupCode,
      'description': description,
    };
  }

  Product copyWith({
    int? id,
    String? itemLookupCode,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      itemLookupCode: itemLookupCode ?? this.itemLookupCode,
      description: description ?? this.description,
    );
  }
}
