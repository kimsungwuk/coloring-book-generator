/// 카테고리 데이터 모델
class CategoryModel {
  final String id;
  final String nameKey;

  const CategoryModel({
    required this.id,
    required this.nameKey,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      nameKey: json['nameKey'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKey': nameKey,
    };
  }
}
