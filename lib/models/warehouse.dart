class WarehouseStockProduct {
  final String barcode;
  int? quantity;
  final String stockDate;
  final String stockingId; // Changed to match the new field `stockingId` in the request body
  final int status;

  WarehouseStockProduct({
    required this.barcode,
    this.quantity, // Nullable, so no "required"
    required this.stockDate,
    required this.stockingId, // Added this field
    required this.status,
  });

  // Corrected fromJson constructor
  factory WarehouseStockProduct.fromJson(Map<String, dynamic> json) {
    return WarehouseStockProduct(
      barcode: json['barcode'] as String,
      quantity: json['quantity'] as int?, // Handles potential null values
      stockDate: json['stockDate'] as String,
      stockingId: json['stockingId'] as String, // Parsing the new `stockingId` field
      status: json['status'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'quantity': quantity, // Will be null if not provided
      'stockDate': stockDate,
      'stockingId': stockingId, // Include the `stockingId` field in the output JSON
      'status': status,
    };
  }
}
