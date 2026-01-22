import 'dart:ui';

/// 앱 전체 상수 정의
class AppConstants {
  AppConstants._();

  /// 앱 이름
  static const String appName = 'My Coloring Book';

  /// 스플래시 화면 지속 시간 (초)
  static const int splashDuration = 2;

  /// 기본 색상 팔레트
  static const List<Color> defaultColors = [
    Color(0xFFE53935), // Red
    Color(0xFFD81B60), // Pink
    Color(0xFF8E24AA), // Purple
    Color(0xFF5E35B1), // Deep Purple
    Color(0xFF3949AB), // Indigo
    Color(0xFF1E88E5), // Blue
    Color(0xFF039BE5), // Light Blue
    Color(0xFF00ACC1), // Cyan
    Color(0xFF00897B), // Teal
    Color(0xFF43A047), // Green
    Color(0xFF7CB342), // Light Green
    Color(0xFFC0CA33), // Lime
    Color(0xFFFDD835), // Yellow
    Color(0xFFFFB300), // Amber
    Color(0xFFFB8C00), // Orange
    Color(0xFFF4511E), // Deep Orange
    Color(0xFF6D4C41), // Brown
    Color(0xFF757575), // Grey
    Color(0xFF546E7A), // Blue Grey
    Color(0xFF000000), // Black
    Color(0xFFFFFFFF), // White
  ];

  /// AdMob 배너 광고 ID (테스트용)
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
}
