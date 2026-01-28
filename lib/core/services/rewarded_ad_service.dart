import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_constants.dart';

/// 보상형 광고 서비스
/// 도안 잠금 해제를 위한 보상형 광고를 관리합니다.
class RewardedAdService {
  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;
  
  /// 보상형 광고 미리 로드
  static Future<void> loadAd() async {
    // 웹이나 지원하지 않는 플랫폼에서는 로드하지 않음
    if (kIsWeb || 
        (defaultTargetPlatform != TargetPlatform.android && 
         defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    
    if (_isLoading || _rewardedAd != null) {
      return;
    }
    
    _isLoading = true;
    
    await RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          debugPrint('RewardedAd loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }
  
  /// 보상형 광고가 준비되었는지 확인
  static bool get isAdReady => _rewardedAd != null;
  
  /// 보상형 광고 표시
  /// 광고 시청 완료 시 onRewarded 콜백 호출
  /// 성공 여부를 반환
  static Future<bool> showAd({
    required Function() onRewarded,
    Function()? onAdDismissed,
    Function(String error)? onAdFailed,
  }) async {
    // 웹이나 지원하지 않는 플랫폼에서는 바로 보상 지급
    if (kIsWeb || 
        (defaultTargetPlatform != TargetPlatform.android && 
         defaultTargetPlatform != TargetPlatform.iOS)) {
      onRewarded();
      return true;
    }
    
    if (_rewardedAd == null) {
      // 광고가 없으면 로드 시도 후 실패 알림
      await loadAd();
      if (_rewardedAd == null) {
        onAdFailed?.call('광고를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }
    }
    
    bool rewarded = false;
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        // 다음 광고 미리 로드
        loadAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadAd();
        onAdFailed?.call('광고 표시에 실패했습니다.');
      },
    );
    
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
        onRewarded();
      },
    );
    
    return rewarded;
  }
  
  /// 광고 리소스 해제
  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
