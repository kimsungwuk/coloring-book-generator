import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GitHub에서 새로운 컬러링 페이지 이미지를 동기화하는 서비스
class ImageSyncService {
  // GitHub 설정 - 자신의 저장소에 맞게 수정하세요
  static const String _githubUser = 'kimsungwuk';
  static const String _githubRepo = 'coloring-book-generator';
  static const String _branch = 'main';
  
  // GitHub Raw URL 베이스
  static String get _rawBaseUrl => 
      'https://raw.githubusercontent.com/$_githubUser/$_githubRepo/$_branch';
  
  // 로컬 저장 경로 프리픽스
  static const String _localImagePrefix = 'synced_images';
  static const String _localJsonKey = 'synced_coloring_pages_json';
  static const String _lastSyncKey = 'last_image_sync_timestamp';

  /// 앱의 로컬 저장 디렉토리 가져오기
  Future<Directory> get _localDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/$_localImagePrefix');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  /// GitHub에서 최신 coloring_pages.json 가져오기
  Future<Map<String, dynamic>?> fetchRemoteConfig() async {
    try {
      final url = '$_rawBaseUrl/assets/data/coloring_pages.json';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to fetch remote config: $e');
    }
    return null;
  }

  /// 로컬에 저장된 JSON 가져오기
  Future<Map<String, dynamic>?> getLocalConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_localJsonKey);
      if (jsonString != null) {
        return json.decode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to get local config: $e');
    }
    return null;
  }

  /// 로컬에 JSON 저장
  Future<void> saveLocalConfig(Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localJsonKey, json.encode(config));
    } catch (e) {
      debugPrint('Failed to save local config: $e');
    }
  }

  /// 이미지가 로컬에 존재하는지 확인
  Future<bool> isImageDownloaded(String imagePath) async {
    try {
      final localDir = await _localDir;
      final fileName = imagePath.split('/').last;
      final localFile = File('${localDir.path}/$fileName');
      return await localFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// 이미지의 로컬 경로 가져오기 (다운로드된 경우)
  Future<String?> getLocalImagePath(String imagePath) async {
    try {
      final localDir = await _localDir;
      final fileName = imagePath.split('/').last;
      final localFile = File('${localDir.path}/$fileName');
      if (await localFile.exists()) {
        return localFile.path;
      }
    } catch (e) {
      debugPrint('Failed to get local image path: $e');
    }
    return null;
  }

  /// 단일 이미지 다운로드
  Future<bool> downloadImage(String imagePath) async {
    try {
      final url = '$_rawBaseUrl/$imagePath';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );
      
      if (response.statusCode == 200) {
        final localDir = await _localDir;
        final fileName = imagePath.split('/').last;
        final localFile = File('${localDir.path}/$fileName');
        await localFile.writeAsBytes(response.bodyBytes);
        debugPrint('Downloaded: $fileName');
        return true;
      }
    } catch (e) {
      debugPrint('Failed to download image $imagePath: $e');
    }
    return false;
  }

  /// 동기화 실행 - 새 이미지들만 다운로드
  /// 반환: (새로 다운로드한 이미지 수, 총 이미지 수)
  Future<(int downloaded, int total)> syncImages({
    Function(int current, int total)? onProgress,
  }) async {
    int downloadedCount = 0;
    int totalCount = 0;
    
    try {
      // 1. GitHub에서 최신 JSON 가져오기
      final remoteConfig = await fetchRemoteConfig();
      if (remoteConfig == null) {
        debugPrint('Failed to fetch remote config, skipping sync');
        return (0, 0);
      }
      
      // 2. 로컬에 JSON 저장
      await saveLocalConfig(remoteConfig);
      
      // 3. 페이지 목록에서 이미지 경로 추출
      final List<dynamic> pages = remoteConfig['pages'] ?? [];
      totalCount = pages.length;
      
      // 4. 없는 이미지만 다운로드
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i] as Map<String, dynamic>;
        final imagePath = page['imagePath'] as String?;
        
        if (imagePath != null) {
          final isDownloaded = await isImageDownloaded(imagePath);
          
          if (!isDownloaded) {
            final success = await downloadImage(imagePath);
            if (success) {
              downloadedCount++;
            }
          }
        }
        
        // 진행 상황 콜백
        onProgress?.call(i + 1, totalCount);
      }
      
      // 5. 마지막 동기화 시간 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('Sync completed: $downloadedCount new images downloaded');
      
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
    
    return (downloadedCount, totalCount);
  }

  /// 마지막 동기화 시간 가져오기
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('Failed to get last sync time: $e');
    }
    return null;
  }

  /// 동기화가 필요한지 확인 (마지막 동기화로부터 1시간 이상 경과)
  Future<bool> needsSync() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    
    final difference = DateTime.now().difference(lastSync);
    return difference.inHours >= 1;
  }

  /// 모든 로컬 이미지 삭제 (초기화용)
  Future<void> clearLocalImages() async {
    try {
      final localDir = await _localDir;
      if (await localDir.exists()) {
        await localDir.delete(recursive: true);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localJsonKey);
      await prefs.remove(_lastSyncKey);
    } catch (e) {
      debugPrint('Failed to clear local images: $e');
    }
  }
}
