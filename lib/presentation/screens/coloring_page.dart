import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import '../../core/services/flood_fill_service.dart';
import '../../core/services/progress_save_service.dart';
import '../../core/services/rewarded_ad_service.dart';
import '../../data/models/coloring_page_model.dart';
import '../providers/coloring_provider.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/color_palette.dart';
import '../widgets/coloring_canvas.dart';

/// 색칠 화면
class ColoringPage extends StatefulWidget {
  final ColoringPageModel page;

  const ColoringPage({super.key, required this.page});

  @override
  State<ColoringPage> createState() => _ColoringPageState();
}

class _ColoringPageState extends State<ColoringPage> {
  late ColoringProvider _coloringProvider;
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _coloringProvider = ColoringProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadImageWithProgress();
    });
  }

  Future<void> _loadImageWithProgress() async {
    // 먼저 저장된 진행상황이 있는지 확인
    final progress = await ProgressSaveService.loadProgress(widget.page.id);

    if (progress != null) {
      // 진행상황이 있으면 불러오기
      await _coloringProvider.loadImageFromProgress(
        widget.page.imagePath,
        progress.pixels,
        progress.width,
        progress.height,
      );
    } else {
      // 없으면 원본 이미지 로드
      await _coloringProvider.loadImage(widget.page.imagePath);
    }

    if (mounted) {
      setState(() {
        _isLoadingProgress = false;
      });
    }
  }

  @override
  void dispose() {
    _coloringProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ChangeNotifierProvider.value(
      value: _coloringProvider,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _showSaveDialog(context);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.coloringTitle),
            centerTitle: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => _showSaveDialog(context),
            ),
            actions: [
              // 갤러리에 저장 버튼
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _saveToGallery,
                tooltip: l10n.saveToGallery,
              ),
              // 배경화면 설정 버튼 (안드로이드 전용)
              if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
                IconButton(
                  icon: const Icon(Icons.wallpaper),
                  onPressed: _setAsWallpaper,
                  tooltip: l10n.setAsWallpaper,
                ),
              // 진행상황 저장 버튼
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveProgress,
                tooltip: l10n.saveProgress,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // 캔버스 영역
                Expanded(
                  child: Consumer<ColoringProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading || _isLoadingProgress) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (provider.displayImage == null) {
                        return Center(
                          child: Text(l10n.splashLoading),
                        );
                      }

                      return const ColoringCanvas();
                    },
                  ),
                ),
                // 도구 바
                _buildToolBar(context),
                // 색상 팔레트
                const ColorPalette(),
              ],
            ),
          ),
          bottomNavigationBar: const SafeArea(
            child: BannerAdWidget(),
          ),
        ),
      ),
    );
  }

  Widget _buildToolBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<ColoringProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Undo 버튼
              _ToolButton(
                icon: Icons.undo,
                label: l10n.undo,
                onPressed: provider.canUndo && !provider.isProcessing
                    ? provider.undo
                    : null,
              ),
              // Redo 버튼
              _ToolButton(
                icon: Icons.redo,
                label: l10n.redo,
                onPressed: provider.canRedo && !provider.isProcessing
                    ? provider.redo
                    : null,
              ),
              // Clear 버튼
              _ToolButton(
                icon: Icons.refresh,
                label: l10n.clear,
                onPressed: !provider.isProcessing ? provider.clear : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final navigator = Navigator.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveProgressTitle),
        content: Text(l10n.saveProgressMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(l10n.discard),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _saveProgress();
      if (!mounted) return;
      navigator.pop();
    } else if (result == 'discard') {
      if (!mounted) return;
      navigator.pop();
    }
    // 'cancel'이면 아무것도 하지 않음
  }

  Future<void> _saveProgress() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = _coloringProvider;

    final pixels = provider.getCurrentPixels();
    final size = provider.getImageSize();
    if (pixels == null || size == null) return;

    final success = await ProgressSaveService.saveProgress(
      pageId: widget.page.id,
      pixels: pixels,
      width: size.width.toInt(),
      height: size.height.toInt(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.progressSaved : l10n.saveError),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _saveToGallery() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = _coloringProvider;

    // 웹은 저장 기능 미지원
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveError)),
      );
      return;
    }

    // 모바일에서 권한 요청
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.storagePermissionRequired)),
            );
          }
          return;
        }
      }
    }

    // 이미지 저장
    final pixels = provider.getCurrentPixels();
    final size = provider.getImageSize();
    if (pixels == null || size == null) return;

    try {
      // PNG로 인코딩
      final ui.Image? image = await FloodFillService.pixelsToImage(
        pixels,
        size.width.toInt(),
        size.height.toInt(),
      );
      if (image == null) throw Exception('Failed to create image');

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) throw Exception('Failed to encode image');

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 갤러리에 저장
      await Gal.putImageBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imageSavedToGallery),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 배경화면으로 설정
  Future<void> _setAsWallpaper() async {
    final l10n = AppLocalizations.of(context)!;
    
    // 1. 먼저 확인 다이얼로그 표시
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.wallpaper, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.wallpaperAdTitle)),
          ],
        ),
        content: Text(l10n.wallpaperAdMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: Text(l10n.watchAd),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. 보상형 광고 표시
    if (mounted) {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    final adSuccess = await RewardedAdService.showAd(
      onRewarded: () async {
        // 광고 시청 완료 후 배경화면 설정 로직 실행
        await _applyWallpaper();
      },
      onAdDismissed: () {
        if (mounted) Navigator.pop(context); // 로딩 다이얼로그 닫기
      },
      onAdFailed: (error) {
        if (mounted) {
          Navigator.pop(context); // 로딩 다이얼로그 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      },
    );

    if (!adSuccess && mounted) {
      // 광고를 끝까지 보지 않았거나 실패한 경우 안내
    }
  }

  /// 실제 배경화면 적용 로직
  Future<void> _applyWallpaper() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = _coloringProvider;

    // 이미지 데이터 확인
    final pixels = provider.getCurrentPixels();
    final size = provider.getImageSize();
    if (pixels == null || size == null) return;

    // 로딩 표시 (이미 광고 로딩 다이얼로그가 떠있을 수 있으므로 스낵바만)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingWallpaper)),
      );
    }

    try {
      // 이미지 생성
      final ui.Image? image = await FloodFillService.pixelsToImage(
        pixels,
        size.width.toInt(),
        size.height.toInt(),
      );
      if (image == null) throw Exception('Failed to create image');

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) throw Exception('Failed to encode image');

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 임시 파일로 저장 (매번 다른 파일명을 사용하여 캐시 문제 방지)
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/wallpaper_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      // 배경화면 설정 (홈 화면 + 잠금 화면)
      final result = await AsyncWallpaper.setWallpaperFromFile(
        filePath: file.path,
        wallpaperLocation: AsyncWallpaper.BOTH_SCREENS,
        goToHome: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ? l10n.wallpaperSetSuccess : l10n.wallpaperSetError),
            backgroundColor: result ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error setting wallpaper: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.wallpaperSetError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// 도구 버튼 위젯
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ToolButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: isEnabled
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isEnabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
      ],
    );
  }
}
