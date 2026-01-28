import 'package:shared_preferences/shared_preferences.dart';

/// 도안 잠금 해제 상태를 관리하는 서비스
/// 보상형 광고를 시청하면 해당 도안이 영구적으로 잠금 해제됩니다.
class PageUnlockService {
  static const String _unlockKeyPrefix = 'unlocked_page_';
  
  static SharedPreferences? _prefs;
  
  /// SharedPreferences 초기화
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  /// 도안이 잠금 해제되었는지 확인
  static Future<bool> isPageUnlocked(String pageId) async {
    await init();
    return _prefs?.getBool('$_unlockKeyPrefix$pageId') ?? false;
  }
  
  /// 도안 잠금 해제
  static Future<void> unlockPage(String pageId) async {
    await init();
    await _prefs?.setBool('$_unlockKeyPrefix$pageId', true);
  }
  
  /// 도안 잠금 (테스트용)
  static Future<void> lockPage(String pageId) async {
    await init();
    await _prefs?.remove('$_unlockKeyPrefix$pageId');
  }
  
  /// 모든 도안 잠금 해제 상태 초기화 (테스트용)
  static Future<void> resetAllUnlocks() async {
    await init();
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith(_unlockKeyPrefix)) {
        await _prefs?.remove(key);
      }
    }
  }
  
  /// 여러 도안의 잠금 해제 상태를 한번에 조회
  static Future<Map<String, bool>> getUnlockStatus(List<String> pageIds) async {
    await init();
    final Map<String, bool> status = {};
    for (final pageId in pageIds) {
      status[pageId] = _prefs?.getBool('$_unlockKeyPrefix$pageId') ?? false;
    }
    return status;
  }
}
