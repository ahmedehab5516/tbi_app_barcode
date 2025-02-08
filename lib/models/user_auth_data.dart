class UserAuth {
  final int status;
  final String message;
  final UserAuthData? data;

  UserAuth({
    required this.status,
    required this.message,
    this.data, // Corrected placement of nullable field
  });

  factory UserAuth.fromJson(Map<String, dynamic> json) {
    return UserAuth(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? UserAuthData.fromJson(json['data']) : null,
    );
  }

  // Map<String, dynamic> toJson() {
  //   return {
  //     'status': status,
  //     'message': message,
  //     'data': data?.toJson(), // Use null-safe operator
  //   };
  // }
}

class UserAuthData {
  final int id;
  final String serial;
  final bool isActive;
  final String? userNameAdded; // Nullable type
  final String createdDate;
  final int storeId;
  final String? stores; // Nullable type

  UserAuthData({
    required this.id,
    required this.serial,
    required this.isActive,
    this.userNameAdded, // Allow null
    required this.createdDate,
    required this.storeId,
    this.stores, // Allow null
  });

  factory UserAuthData.fromJson(Map<String, dynamic> json) {
    return UserAuthData(
      id: json["id"] ?? 0,
      serial: json["serial"] ?? "", // Ensure non-nullable fields have defaults
      isActive: json["isActive"] ?? false,
      userNameAdded: json["userNameAdded"] ?? "Unknown", // Handle null
      createdDate: json["createdDate"] ?? "",
      storeId: json["storeId"] ?? 0,
      stores: json["stores"] ?? "N/A", // Handle null
    );
  }
}
