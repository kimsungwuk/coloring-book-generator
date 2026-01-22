import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_constants.dart';

/// 배너 광고 위젯 (skill.md 가이드 준수)
class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // 웹이나 지원하지 않는 플랫폼에서는 로드하지 않음
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && 
        defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 광고가 로드되지 않았거나 지원하지 않는 플랫폼인 경우 (레이아웃 깨짐 방지용 고정 높이)
    if (!_isLoaded || _bannerAd == null) {
      return SizedBox(
        height: widget.adSize.height.toDouble(),
        width: double.infinity,
        child: const Center(
          child: Text('Ad Placeholder', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: widget.adSize.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
