import 'package:flutter/material.dart';
import '../../core/services/progress_save_service.dart';
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

  @override
  void initState() {
    super.initState();
    _pagesFuture = _repository.loadColoringPagesByCategory(widget.category.id);
    _loadProgressStatus();
  }

  Future<void> _loadProgressStatus() async {
    final pages = await _pagesFuture;
    final Map<String, bool> status = {};
    for (final page in pages) {
      status[page.id] = await ProgressSaveService.hasProgress(page.id);
    }
    if (mounted) {
      setState(() {
        _progressStatus = status;
      });
    }
  }

  String _getCategoryName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.category.id) {
      case 'animals':
        return l10n.categoryAnimals;
      case 'nature':
        return l10n.categoryNature;
      case 'fantasy':
        return l10n.categoryFantasy;
      case 'vehicles':
        return l10n.categoryVehicles;
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
                          return _ColoringPageThumbnail(
                            page: page,
                            hasProgress: hasProgress,
                            onTap: () => _navigateToColoringPage(context, page),
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

  Future<void> _navigateToColoringPage(
      BuildContext context, ColoringPageModel page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ColoringPage(page: page),
      ),
    );
    // 돌아왔을 때 진행상황 상태 새로고침
    _loadProgressStatus();
  }
}

/// 컬러링 페이지 썸네일 위젯
class _ColoringPageThumbnail extends StatelessWidget {
  final ColoringPageModel page;
  final bool hasProgress;
  final VoidCallback onTap;

  const _ColoringPageThumbnail({
    required this.page,
    required this.hasProgress,
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
                // 진행중 표시
                if (hasProgress)
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
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(128),
                        ],
                      ),
                    ),
                    child: Text(
                      page.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
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
