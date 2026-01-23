/// 카테고리 데이터 모델
class CategoryModel {
  final String id;
  final String nameKey;
  final bool isFree;

  const CategoryModel({
    required this.id,
    required this.nameKey,
    this.isFree = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      nameKey: json['nameKey'] as String,
      isFree: json['isFree'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKey': nameKey,
      'isFree': isFree,
    };
  }
}
