import 'package:flutter/material.dart';
import '../../core/services/page_unlock_service.dart';
import '../../core/services/progress_save_service.dart';
import '../../core/services/rewarded_ad_service.dart';
import '../../l10n/app_localizations.dart';
import '../../data/models/category_model.dart';
import '../../data/models/coloring_page_model.dart';
import '../../data/repositories/coloring_repository.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/synced_image_widget.dart';
import 'coloring_page.dart';

/// 카테고리별 갤러리 화면
class GalleryPage extends StatefulWidget {
  final CategoryModel category;

  const GalleryPage({super.key, required this.category});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ColoringRepository _repository = ColoringRepository();
  late Future<List<ColoringPageModel>> _pagesFuture;
  Map<String, bool> _progressStatus = {};
  Map<String, bool> _unlockStatus = {};

  @override
  void initState() {
    super.initState();
    _pagesFuture = _repository.loadColoringPagesByCategory(widget.category.id);
    _loadStatuses();
    // 보상형 광고 미리 로드
    RewardedAdService.loadAd();
  }

  Future<void> _loadStatuses() async {
    final pages = await _pagesFuture;
    final Map<String, bool> progressStatus = {};
    final List<String> pageIds = [];
    
    for (final page in pages) {
      progressStatus[page.id] = await ProgressSaveService.hasProgress(page.id);
      pageIds.add(page.id);
    }
    
    final unlockStatus = await PageUnlockService.getUnlockStatus(pageIds);
    
    if (mounted) {
      setState(() {
        _progressStatus = progressStatus;
        _unlockStatus = unlockStatus;
      });
    }
  }

  String _getCategoryName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.category.id) {
      case 'forest':
        return l10n.categoryForest;
      case 'ocean':
        return l10n.categoryOcean;
      case 'fairy':
        return l10n.categoryFairy;
      case 'vehicles':
        return l10n.categoryVehicles;
      case 'dinosaurs':
        return l10n.categoryDinosaurs;
      case 'desserts':
        return l10n.categoryDesserts;
      default:
        return widget.category.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getCategoryName(context)),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 텍스트
                Text(
                  l10n.tapToColor,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 16),
                // 그리드 뷰
                Expanded(
                  child: FutureBuilder<List<ColoringPageModel>>(
                    future: _pagesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text(l10n.noPages));
                      }

                      final coloringPages = snapshot.data!;
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemCount: coloringPages.length,
                        itemBuilder: (context, index) {
                          final page = coloringPages[index];
                          final hasProgress = _progressStatus[page.id] ?? false;
                          final isUnlocked = _unlockStatus[page.id] ?? false;
                          
                          return _ColoringPageThumbnail(
                            page: page,
                            hasProgress: hasProgress,
                            isUnlocked: isUnlocked,
                            onTap: () => _handlePageTap(context, page, isUnlocked),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const SafeArea(
          child: BannerAdWidget(),
        ),
      ),
    );
  }

  /// 도안 탭 처리
  Future<void> _handlePageTap(
    BuildContext context,
    ColoringPageModel page,
    bool isUnlocked,
  ) async {
    if (isUnlocked) {
      // 이미 잠금 해제된 도안 - 바로 열기
      await _navigateToColoringPage(context, page);
    } else {
      // 잠긴 도안 - 광고 시청 다이얼로그 표시
      _showUnlockDialog(context, page);
    }
  }

  /// 잠금 해제 다이얼로그 표시
  void _showUnlockDialog(BuildContext context, ColoringPageModel page) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.amber.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.lockedPage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.watchAdToUnlock,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle_filled, color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.adDuration,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _watchAdAndUnlock(page);
            },
            icon: const Icon(Icons.play_arrow, size: 18),
            label: Text(l10n.watchAd),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 광고 시청 후 도안 잠금 해제
  Future<void> _watchAdAndUnlock(ColoringPageModel page) async {
    // 로딩 표시
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final success = await RewardedAdService.showAd(
      onRewarded: () async {
        // 잠금 해제 저장
        await PageUnlockService.unlockPage(page.id);
        
        if (mounted) {
          setState(() {
            _unlockStatus[page.id] = true;
          });
        }
      },
      onAdDismissed: () {
        // 로딩 다이얼로그 닫기
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      onAdFailed: (error) {
        // 로딩 다이얼로그 닫기
        if (mounted) {
          Navigator.of(context).pop();
          
          // 에러 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
    
    // 광고 시청 완료 후 도안 열기
    if (success && mounted) {
      // 잠금 해제 후 약간의 딜레이
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        await _navigateToColoringPage(context, page);
      }
    }
  }

  Future<void> _navigateToColoringPage(
      BuildContext context, ColoringPageModel page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ColoringPage(page: page),
      ),
    );
    // 돌아왔을 때 진행상황 상태 새로고침
    _loadStatuses();
  }
}

/// 컬러링 페이지 썸네일 위젯
class _ColoringPageThumbnail extends StatelessWidget {
  final ColoringPageModel page;
  final bool hasProgress;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _ColoringPageThumbnail({
    required this.page,
    required this.hasProgress,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade100,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SyncedImageWidget(
                      assetPath: page.thumbnailPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // 잠금 상태 오버레이
                if (!isUnlocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(100),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(230),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock,
                            color: Colors.amber.shade700,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                // 진행중 표시 (잠금 해제된 경우에만)
                if (hasProgress && isUnlocked)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withAlpha(100),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.continueDrawing,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
