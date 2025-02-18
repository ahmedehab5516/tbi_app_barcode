class WarehouseStockProduct {
  final String barcode;
  int? quantity;
  final String stockDate;
  final String stockingId;
  final int status;
  final int storeId; // Added `storeId` to the class

  // Constructor including storeId
  WarehouseStockProduct({
    required this.barcode,
    this.quantity, // Nullable, so no "required"
    required this.stockDate,
    required this.stockingId,
    required this.status,
    required this.storeId, // Added this field
  });

  // fromJson constructor
  factory WarehouseStockProduct.fromJson(Map<String, dynamic> json) {
    return WarehouseStockProduct(
      barcode: json['barcode'] as String,
      quantity: json['quantity'] as int?, // Handles potential null values
      stockDate: json['stockDate'] as String,
      stockingId: json['stockingId'] as String,
      status: json['status'] as int,
      storeId: json['storeId'] as int, // Parsing the `storeId` field
    );
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'quantity': quantity, // Will be null if not provided
      'stockDate': stockDate,
      'stockingId': stockingId, // Include the `stockingId` field in the output JSON
      'status': status,
      'storeId': storeId, // Including the `storeId` field in the output JSON
    };
  }
}
