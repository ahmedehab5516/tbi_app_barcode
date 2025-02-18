class CategoryResponse {
  final int status;
  final List<Category> data;

  CategoryResponse({required this.status, required this.data});

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      status: json['status'] as int,
      data: (json['data'] as List<dynamic>)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class Category {
  final String categoryCode;
  final String categoryName;

  Category({required this.categoryCode, required this.categoryName});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryCode: json['categoryCode'] as String,
      categoryName: json['categoryName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryCode': categoryCode,
      'categoryName': categoryName,
    };
  }
}
