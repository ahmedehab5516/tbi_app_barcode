class StoreDetails {
  final int status;
  final List<StoreData> data;

  StoreDetails({
    required this.status,
    required this.data,
  });

  StoreDetails.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        data = (json['data'] as List).map((v) => StoreData.fromJson(v)).toList();

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((v) => v.toJson()).toList(),
    };
  }
}








class StoreData {
  int id;
  String name;

  StoreData({required this.id, required this.name});

  StoreData.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  // CopyWith method
  StoreData copyWith({
    int? id,
    String? name,
  }) {
    return StoreData(
      id: id ?? this.id, // Use provided id or keep the current id
      name: name ?? this.name, // Use provided name or keep the current name
    );
  }
}
