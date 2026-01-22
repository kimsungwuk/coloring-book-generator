import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../l10n/app_localizations.dart';
import '../../data/models/coloring_page_model.dart';
import '../../data/repositories/coloring_repository.dart';
import '../widgets/banner_ad_widget.dart';
import 'coloring_page.dart';

/// 홈 화면 - 컬러링 페이지 갤러리 (JSON 기반 로딩)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ColoringRepository _repository = ColoringRepository();
  late Future<List<ColoringPageModel>> _pagesFuture;

  @override
  void initState() {
    super.initState();
    _pagesFuture = _repository.loadColoringPages();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.homeTitle),
          centerTitle: true,
          elevation: 0,
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
                        return const Center(child: Text('No pages found.'));
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
                          return _ColoringPageThumbnail(
                            page: coloringPages[index],
                            onTap: () => _navigateToColoringPage(
                                context, coloringPages[index]),
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

  void _navigateToColoringPage(BuildContext context, ColoringPageModel page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ColoringPage(page: page),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exitTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.exitMessage),
            const SizedBox(height: 16),
            const BannerAdWidget(adSize: AdSize.banner),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}

/// 컬러링 페이지 썸네일 위젯
class _ColoringPageThumbnail extends StatelessWidget {
  final ColoringPageModel page;
  final VoidCallback onTap;

  const _ColoringPageThumbnail({
    required this.page,
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
                    child: Image.asset(
                      page.thumbnailPath,
                      fit: BoxFit.contain,
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
