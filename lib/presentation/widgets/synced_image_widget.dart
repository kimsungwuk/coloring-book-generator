import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/repositories/coloring_repository.dart';

/// 동기화된 이미지(로컬 파일) 또는 번들 에셋을 자동으로 로드하는 위젯
class SyncedImageWidget extends StatefulWidget {
  final String assetPath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SyncedImageWidget({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<SyncedImageWidget> createState() => _SyncedImageWidgetState();
}

class _SyncedImageWidgetState extends State<SyncedImageWidget> {
  final ColoringRepository _repository = ColoringRepository();
  
  String? _resolvedPath;
  bool _isFile = false;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _resolveImagePath();
  }

  @override
  void didUpdateWidget(SyncedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _resolveImagePath();
    }
  }

  Future<void> _resolveImagePath() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final (path, isFile) = await _repository.resolveImagePath(widget.assetPath);
      if (mounted) {
        setState(() {
          _resolvedPath = path;
          _isFile = isFile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? 
          const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_hasError || _resolvedPath == null) {
      return widget.errorWidget ?? 
          const Center(child: Icon(Icons.broken_image, color: Colors.grey));
    }

    if (_isFile) {
      // 로컬 파일에서 로드
      return Image.file(
        File(_resolvedPath!),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) {
          // 파일 로드 실패 시 에셋으로 폴백
          return Image.asset(
            widget.assetPath,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            errorBuilder: (context, error, stackTrace) {
              return widget.errorWidget ?? 
                  const Center(child: Icon(Icons.broken_image, color: Colors.grey));
            },
          );
        },
      );
    } else {
      // 번들 에셋에서 로드
      return Image.asset(
        _resolvedPath!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? 
              const Center(child: Icon(Icons.broken_image, color: Colors.grey));
        },
      );
    }
  }
}
