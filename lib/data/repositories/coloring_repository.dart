import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/category_model.dart';
import '../models/coloring_page_model.dart';

/// 컬러링 페이지 데이터를 불러오는 저장소
class ColoringRepository {
  static const String _configPath = 'assets/data/coloring_pages.json';

  Map<String, dynamic>? _cachedData;

  /// JSON 데이터 로드 (캐싱)
  Future<Map<String, dynamic>> _loadJsonData() async {
    if (_cachedData != null) return _cachedData!;

    try {
      final String jsonString = await rootBundle.loadString(_configPath);
      _cachedData = json.decode(jsonString) as Map<String, dynamic>;
      return _cachedData!;
    } catch (e) {
      debugPrint('Error loading JSON data: $e');
      return {'categories': [], 'pages': []};
    }
  }

  /// 카테고리 목록 로드
  Future<List<CategoryModel>> loadCategories() async {
    try {
      final data = await _loadJsonData();
      final List<dynamic> categoriesJson = data['categories'] ?? [];

      return categoriesJson
          .map((data) => CategoryModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading categories: $e');
      return [];
    }
  }

  /// JSON 파일로부터 컬러링 페이지 목록 로드
  Future<List<ColoringPageModel>> loadColoringPages() async {
    try {
      final data = await _loadJsonData();
      final List<dynamic> pagesJson = data['pages'] ?? [];

      return pagesJson
          .map((data) => ColoringPageModel.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading coloring pages: $e');
      return [];
    }
  }

  /// 카테고리별 컬러링 페이지 로드
  Future<List<ColoringPageModel>> loadColoringPagesByCategory(String categoryId) async {
    final allPages = await loadColoringPages();
    return allPages.where((page) => page.categoryId == categoryId).toList();
  }
}
