import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 색칠 진행상황 저장/로드 서비스
class ProgressSaveService {
  static const String _progressPrefix = 'coloring_progress_';
  static const String _lastModifiedPrefix = 'coloring_lastmodified_';
  static const String _savedPagesKey = 'saved_coloring_pages';

  /// 진행상황 저장 디렉토리 가져오기
  static Future<Directory> _getProgressDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final progressDir = Directory('${appDir.path}/coloring_progress');
    if (!await progressDir.exists()) {
      await progressDir.create(recursive: true);
    }
    return progressDir;
  }

  /// 진행상황 저장
  static Future<bool> saveProgress({
    required String pageId,
    required Uint8List pixels,
    required int width,
    required int height,
  }) async {
    try {
      if (kIsWeb) return false;

      final progressDir = await _getProgressDirectory();
      final file = File('${progressDir.path}/$pageId.dat');

      // 메타데이터와 픽셀 데이터를 함께 저장
      final metadata = {
        'width': width,
        'height': height,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final metadataBytes = utf8.encode(json.encode(metadata));
      final metadataLength = metadataBytes.length;

      // [4바이트: 메타데이터 길이][메타데이터][픽셀 데이터]
      final buffer = BytesBuilder();
      buffer.add([
        (metadataLength >> 24) & 0xFF,
        (metadataLength >> 16) & 0xFF,
        (metadataLength >> 8) & 0xFF,
        metadataLength & 0xFF,
      ]);
      buffer.add(metadataBytes);
      buffer.add(pixels);

      await file.writeAsBytes(buffer.toBytes());

      // 저장된 페이지 목록 업데이트
      final prefs = await SharedPreferences.getInstance();
      final savedPages = prefs.getStringList(_savedPagesKey) ?? [];
      if (!savedPages.contains(pageId)) {
        savedPages.add(pageId);
        await prefs.setStringList(_savedPagesKey, savedPages);
      }

      // 마지막 수정 시간 저장
      await prefs.setString(
        '$_lastModifiedPrefix$pageId',
        DateTime.now().toIso8601String(),
      );

      return true;
    } catch (e) {
      debugPrint('Error saving progress: $e');
      return false;
    }
  }

  /// 진행상황 로드
  static Future<ProgressData?> loadProgress(String pageId) async {
    try {
      if (kIsWeb) return null;

      final progressDir = await _getProgressDirectory();
      final file = File('${progressDir.path}/$pageId.dat');

      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      if (bytes.length < 4) return null;

      // 메타데이터 길이 읽기
      final metadataLength = (bytes[0] << 24) |
          (bytes[1] << 16) |
          (bytes[2] << 8) |
          bytes[3];

      if (bytes.length < 4 + metadataLength) return null;

      // 메타데이터 파싱
      final metadataBytes = bytes.sublist(4, 4 + metadataLength);
      final metadata = json.decode(utf8.decode(metadataBytes)) as Map<String, dynamic>;

      // 픽셀 데이터 추출
      final pixels = Uint8List.fromList(bytes.sublist(4 + metadataLength));

      return ProgressData(
        pageId: pageId,
        pixels: pixels,
        width: metadata['width'] as int,
        height: metadata['height'] as int,
        timestamp: DateTime.parse(metadata['timestamp'] as String),
      );
    } catch (e) {
      debugPrint('Error loading progress: $e');
      return null;
    }
  }

  /// 진행상황 존재 여부 확인
  static Future<bool> hasProgress(String pageId) async {
    try {
      if (kIsWeb) return false;

      final progressDir = await _getProgressDirectory();
      final file = File('${progressDir.path}/$pageId.dat');
      return file.exists();
    } catch (e) {
      return false;
    }
  }

  /// 저장된 모든 페이지 ID 목록 가져오기
  static Future<List<String>> getSavedPageIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_savedPagesKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// 진행상황 삭제
  static Future<bool> deleteProgress(String pageId) async {
    try {
      if (kIsWeb) return false;

      final progressDir = await _getProgressDirectory();
      final file = File('${progressDir.path}/$pageId.dat');

      if (await file.exists()) {
        await file.delete();
      }

      // 저장된 페이지 목록에서 제거
      final prefs = await SharedPreferences.getInstance();
      final savedPages = prefs.getStringList(_savedPagesKey) ?? [];
      savedPages.remove(pageId);
      await prefs.setStringList(_savedPagesKey, savedPages);
      await prefs.remove('$_lastModifiedPrefix$pageId');

      return true;
    } catch (e) {
      debugPrint('Error deleting progress: $e');
      return false;
    }
  }

  /// 마지막 수정 시간 가져오기
  static Future<DateTime?> getLastModified(String pageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString('$_lastModifiedPrefix$pageId');
      if (timestamp == null) return null;
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }
}

/// 진행상황 데이터 클래스
class ProgressData {
  final String pageId;
  final Uint8List pixels;
  final int width;
  final int height;
  final DateTime timestamp;

  const ProgressData({
    required this.pageId,
    required this.pixels,
    required this.width,
    required this.height,
    required this.timestamp,
  });
}
