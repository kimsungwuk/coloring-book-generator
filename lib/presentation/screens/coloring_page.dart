import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import '../../core/services/flood_fill_service.dart';
import '../../core/services/progress_save_service.dart';
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
      if (mounted) Navigator.pop(context);
    } else if (result == 'discard') {
      if (mounted) Navigator.pop(context);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveError)),
        );
      }
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
