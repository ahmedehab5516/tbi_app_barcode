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
  final String id;
  final String serial;
  final bool isActive;
  final String? userNameAdded;
  final String createdDate;
  final String storeId;
  final String? stores;

  UserAuthData({
    required this.id,
    required this.serial,
    required this.isActive,
    this.userNameAdded,
    required this.createdDate,
    required this.storeId,
    this.stores,
  });

  factory UserAuthData.fromJson(Map<String, dynamic> json) {
    return UserAuthData(
      id: json["id"] is int ? json["id"].toString() : json["id"] ?? "0", // Handle int to String conversion
      serial: json["serial"] ?? "",
      isActive: json["isActive"] ?? false,
      userNameAdded: json["userNameAdded"] ?? "Unknown",
      createdDate: json["createdDate"] ?? "",
      storeId: json["storeId"] ?? "0",
      stores: json["stores"] ?? "N/A",
    );
  }
}
