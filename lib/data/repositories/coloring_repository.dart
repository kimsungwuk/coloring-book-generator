import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/category_model.dart';
import '../models/coloring_page_model.dart';
import '../../core/services/image_sync_service.dart';

/// 컬러링 페이지 데이터를 불러오는 저장소
/// GitHub에서 동기화된 데이터를 우선 사용하고, 없으면 번들 에셋 사용
class ColoringRepository {
  static const String _bundledConfigPath = 'assets/data/coloring_pages.json';
  
  final ImageSyncService _syncService = ImageSyncService();

  Map<String, dynamic>? _cachedData;

  /// JSON 데이터 로드 (동기화된 데이터 우선, 없으면 번들 사용)
  Future<Map<String, dynamic>> _loadJsonData({bool forceRefresh = false}) async {
    if (_cachedData != null && !forceRefresh) return _cachedData!;

    try {
      // 1. 먼저 동기화된 로컬 JSON 확인
      final syncedConfig = await _syncService.getLocalConfig();
      if (syncedConfig != null) {
        _cachedData = syncedConfig;
        debugPrint('Using synced config with ${(syncedConfig['pages'] as List?)?.length ?? 0} pages');
        return _cachedData!;
      }
      
      // 2. 없으면 번들된 에셋 사용
      final String jsonString = await rootBundle.loadString(_bundledConfigPath);
      _cachedData = json.decode(jsonString) as Map<String, dynamic>;
      debugPrint('Using bundled config');
      return _cachedData!;
    } catch (e) {
      debugPrint('Error loading JSON data: $e');
      return {'categories': [], 'pages': []};
    }
  }

  /// 카테고리 목록 로드
  Future<List<CategoryModel>> loadCategories({bool forceRefresh = false}) async {
    try {
      final data = await _loadJsonData(forceRefresh: forceRefresh);
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
  Future<List<ColoringPageModel>> loadColoringPages({bool forceRefresh = false}) async {
    try {
      final data = await _loadJsonData(forceRefresh: forceRefresh);
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
  Future<List<ColoringPageModel>> loadColoringPagesByCategory(
    String categoryId, {
    bool forceRefresh = false,
  }) async {
    final allPages = await loadColoringPages(forceRefresh: forceRefresh);
    return allPages.where((page) => page.categoryId == categoryId).toList();
  }

  /// 이미지 경로 해결 - 다운로드된 이미지 우선, 없으면 번들 에셋
  /// 반환값: (실제 경로, 파일인지 에셋인지)
  Future<(String path, bool isFile)> resolveImagePath(String assetPath) async {
    // 로컬에 다운로드된 이미지가 있는지 확인
    final localPath = await _syncService.getLocalImagePath(assetPath);
    if (localPath != null) {
      return (localPath, true);
    }
    // 없으면 번들된 에셋 경로 반환
    return (assetPath, false);
  }

  /// 캐시 초기화 (새로고침 시 사용)
  void clearCache() {
    _cachedData = null;
  }

  /// 이미지 동기화 실행
  Future<(int downloaded, int total)> syncImages({
    Function(int current, int total)? onProgress,
  }) async {
    final result = await _syncService.syncImages(onProgress: onProgress);
    if (result.$1 > 0) {
      clearCache(); // 새 이미지가 있으면 캐시 초기화
    }
    return result;
  }

  /// 동기화 필요 여부 확인
  Future<bool> needsSync() async {
    return await _syncService.needsSync();
  }
}
