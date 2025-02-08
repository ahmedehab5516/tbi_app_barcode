class PosData {
  String? storeId;
  final String posSerial;
  String? name;
  String? phone;

  PosData({
    this.storeId,
    required this.posSerial,
    this.name,
    this.phone,
  });

  PosData.fromJson(Map<String, dynamic> json)
      : storeId = json['storeId'],
        posSerial = json['posSerial'],
        name = json['name'],
        phone = json['phone'];

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'posSerial': posSerial,
      'name': name,
      'phone': phone,
    };
  }
}
