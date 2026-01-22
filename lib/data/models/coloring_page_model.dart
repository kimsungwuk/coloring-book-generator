/// 컬러링북 페이지 데이터 모델
class ColoringPageModel {
  final String id;
  final String name;
  final String? nameKey;
  final String imagePath;
  final String thumbnailPath;
  final String categoryId;

  const ColoringPageModel({
    required this.id,
    required this.name,
    this.nameKey,
    required this.imagePath,
    String? thumbnailPath,
    required this.categoryId,
  }) : thumbnailPath = thumbnailPath ?? imagePath;

  factory ColoringPageModel.fromJson(Map<String, dynamic> json) {
    return ColoringPageModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameKey: json['nameKey'] as String?,
      imagePath: json['imagePath'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      categoryId: json['categoryId'] as String? ?? 'animals',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameKey': nameKey,
      'imagePath': imagePath,
      'thumbnailPath': thumbnailPath,
      'categoryId': categoryId,
    };
  }

  /// 샘플 컬러링 페이지 목록 (JSON 로딩 방식으로 전환 예정)
  static List<ColoringPageModel> getSamplePages() {
    return []; // 임시 비움
  }
}
