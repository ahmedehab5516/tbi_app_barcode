class WarehouseStockProduct {
  final String barcode;
  int? quantity;
  final String stockDate;
  final String stockingId;
  final int status;
  final String storeId;

  // Constructor including storeId
  WarehouseStockProduct({
    required this.barcode,
    this.quantity, // Nullable
    required this.stockDate,
    required this.stockingId,
    required this.status,
    required this.storeId,
  });

  // fromJson constructor
  factory WarehouseStockProduct.fromJson(Map<String, dynamic> json) {
    try {
      return WarehouseStockProduct(
        barcode: json['barcode'] as String,
        quantity:
            json['quantity'] as int? ?? 0, // Default to 0 if quantity is null
        stockDate: json['stockDate'] as String,
        stockingId: json['stockingId'] as String,
        status: json['status'] as int,
        storeId: json['storeId'] as String,
      );
    } catch (e) {
      print('Error parsing WarehouseStockProduct: $e');
      rethrow;
    }
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'quantity': quantity ?? 0, // Avoid `null` in the JSON output
      'stockDate': stockDate,
      'stockingId': stockingId,
      'status': status,
      'storeId': storeId,
    };
  }
}
