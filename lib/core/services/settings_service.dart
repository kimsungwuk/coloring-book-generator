import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 설정 서비스 (언어, 테마 등)
class SettingsService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme';
  static const String _lastCategoryKey = 'last_category';
  static const String _firstLaunchKey = 'first_launch';

  SharedPreferences? _prefs;
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.system;
  String _lastCategoryId = 'animals';
  bool _isFirstLaunch = true;
  bool _isInitialized = false;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  String get lastCategoryId => _lastCategoryId;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isInitialized => _isInitialized;

  /// 초기화
  Future<void> init() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();

    // 언어 설정 로드
    final languageCode = _prefs?.getString(_languageKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
    }

    // 테마 설정 로드
    final themeIndex = _prefs?.getInt(_themeKey);
    if (themeIndex != null && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    // 마지막 카테고리 로드
    _lastCategoryId = _prefs?.getString(_lastCategoryKey) ?? 'animals';

    // 첫 실행 여부 확인
    _isFirstLaunch = _prefs?.getBool(_firstLaunchKey) ?? true;

    _isInitialized = true;
    notifyListeners();
  }

  /// 언어 설정
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    await _prefs?.setString(_languageKey, locale.languageCode);
    notifyListeners();
  }

  /// 테마 모드 설정
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _prefs?.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  /// 마지막 선택 카테고리 저장
  Future<void> setLastCategory(String categoryId) async {
    _lastCategoryId = categoryId;
    await _prefs?.setString(_lastCategoryKey, categoryId);
  }

  /// 첫 실행 완료 표시
  Future<void> setFirstLaunchComplete() async {
    _isFirstLaunch = false;
    await _prefs?.setBool(_firstLaunchKey, false);
    notifyListeners();
  }

  /// 지원 언어 목록
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ko'),
  ];

  /// 언어 이름 가져오기
  static String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
      default:
        return 'English';
    }
  }

  /// 언어 국기 이모지 가져오기
  static String getLanguageFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return '🇰🇷';
      case 'en':
      default:
        return '🇺🇸';
    }
  }
}
