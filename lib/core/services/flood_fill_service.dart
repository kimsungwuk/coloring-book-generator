import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Queue-based Flood Fill 알고리즘을 사용한 색칠 서비스
class FloodFillService {
  /// 이미지에서 지정된 좌표에 색상을 채우는 메서드
  /// Queue-based Flood Fill 알고리즘 사용
  static Future<Uint8List?> floodFill({
    required Uint8List imageBytes,
    required int width,
    required int height,
    required int startX,
    required int startY,
    required Color fillColor,
    int tolerance = 32,
  }) async {
    if (startX < 0 || startX >= width || startY < 0 || startY >= height) {
      return null;
    }

    // RGBA 형식의 픽셀 데이터 복사
    final Uint8List pixels = Uint8List.fromList(imageBytes);
    final int bytesPerPixel = 4;

    // 시작 픽셀의 색상 가져오기
    final int startIndex = (startY * width + startX) * bytesPerPixel;
    final int targetR = pixels[startIndex];
    final int targetG = pixels[startIndex + 1];
    final int targetB = pixels[startIndex + 2];
    final int targetA = pixels[startIndex + 3];

    // 채울 색상 (새로운 API 사용)
    final int fillR = (fillColor.r * 255.0).round().clamp(0, 255);
    final int fillG = (fillColor.g * 255.0).round().clamp(0, 255);
    final int fillB = (fillColor.b * 255.0).round().clamp(0, 255);
    final int fillA = (fillColor.a * 255.0).round().clamp(0, 255);

    // 이미 같은 색상이면 중단
    if (_colorsMatch(targetR, targetG, targetB, targetA, fillR, fillG, fillB, fillA, 0)) {
      return null;
    }

    // 검은색 경계선인 경우 채우지 않음
    if (_isBlackBoundary(targetR, targetG, targetB, targetA)) {
      return null;
    }

    // 방문 체크 배열
    final List<bool> visited = List.filled(width * height, false);

    // BFS Queue
    final Queue<int> queue = Queue<int>();
    queue.add(startY * width + startX);
    visited[startY * width + startX] = true;

    while (queue.isNotEmpty) {
      final int current = queue.removeFirst();
      final int x = current % width;
      final int y = current ~/ width;
      final int index = current * bytesPerPixel;

      // 현재 픽셀 채우기
      pixels[index] = fillR;
      pixels[index + 1] = fillG;
      pixels[index + 2] = fillB;
      pixels[index + 3] = fillA;

      // 4방향 인접 픽셀 확인
      final List<int> dx = [-1, 1, 0, 0];
      final List<int> dy = [0, 0, -1, 1];

      for (int i = 0; i < 4; i++) {
        final int nx = x + dx[i];
        final int ny = y + dy[i];

        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;

        final int neighborPos = ny * width + nx;
        if (visited[neighborPos]) continue;

        final int neighborIndex = neighborPos * bytesPerPixel;
        final int nR = pixels[neighborIndex];
        final int nG = pixels[neighborIndex + 1];
        final int nB = pixels[neighborIndex + 2];
        final int nA = pixels[neighborIndex + 3];

        // 검은색 경계선이면 건너뜀
        if (_isBlackBoundary(nR, nG, nB, nA)) continue;

        // 타겟 색상과 유사한 색상이면 큐에 추가
        if (_colorsMatch(targetR, targetG, targetB, targetA, nR, nG, nB, nA, tolerance)) {
          visited[neighborPos] = true;
          queue.add(neighborPos);
        }
      }
    }

    return pixels;
  }

  /// 두 색상이 허용 오차 내에서 일치하는지 확인
  static bool _colorsMatch(
    int r1, int g1, int b1, int a1,
    int r2, int g2, int b2, int a2,
    int tolerance,
  ) {
    return (r1 - r2).abs() <= tolerance &&
           (g1 - g2).abs() <= tolerance &&
           (b1 - b2).abs() <= tolerance &&
           (a1 - a2).abs() <= tolerance;
  }

  /// 검은색 경계선인지 확인 (알파값과 함께)
  static bool _isBlackBoundary(int r, int g, int b, int a) {
    // 검은색이고 불투명한 픽셀은 경계선으로 간주
    return r < 50 && g < 50 && b < 50 && a > 200;
  }

  /// Asset에서 이미지를 로드하고 RGBA 픽셀 데이터로 변환
  static Future<ImageData?> loadImageFromAsset(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;
      
      return ImageData(
        pixels: byteData.buffer.asUint8List(),
        width: image.width,
        height: image.height,
      );
    } catch (e) {
      debugPrint('Error loading image from asset: $e');
      return null;
    }
  }

  /// 로컬 파일에서 이미지를 로드하고 RGBA 픽셀 데이터로 변환
  static Future<ImageData?> loadImageFromFile(String filePath) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) return null;
      
      final Uint8List bytes = await file.readAsBytes();
      
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;
      
      return ImageData(
        pixels: byteData.buffer.asUint8List(),
        width: image.width,
        height: image.height,
      );
    } catch (e) {
      debugPrint('Error loading image from file: $e');
      return null;
    }
  }

  /// 경로 유형에 따라 적절한 로더 사용 (에셋 또는 파일)
  static Future<ImageData?> loadImageAuto(String path, {bool isFile = false}) async {
    if (isFile) {
      return await loadImageFromFile(path);
    } else {
      return await loadImageFromAsset(path);
    }
  }

  /// RGBA 픽셀 데이터를 ui.Image로 변환
  static Future<ui.Image?> pixelsToImage(Uint8List pixels, int width, int height) async {
    try {
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
      final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: width,
        height: height,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      final ui.Codec codec = await descriptor.instantiateCodec();
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } catch (e) {
      debugPrint('Error converting pixels to image: $e');
      return null;
    }
  }
}

/// 이미지 데이터 클래스
class ImageData {
  final Uint8List pixels;
  final int width;
  final int height;

  const ImageData({
    required this.pixels,
    required this.width,
    required this.height,
  });

  ImageData copyWith({
    Uint8List? pixels,
    int? width,
    int? height,
  }) {
    return ImageData(
      pixels: pixels ?? this.pixels,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
